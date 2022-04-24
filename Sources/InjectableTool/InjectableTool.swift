//
//  File.swift
//
//
//  Created by Valentin Radu on 22/04/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxParser

@main
enum InjectableTool {
    public static func main() throws {
        print("-------------------")
        FileManager.default.createFile(atPath: CommandLine.arguments[2],
                                       contents: nil)
    }
}

enum DependencyIdentifier: String {
    case asyncFailableDependency = "AsyncFailableDependency"
    case failableDependency = "FailableDependency"
    case dependency = "Dependency"
}

struct DependencyDefinition: Equatable {
    let name: String
    let identifier: DependencyIdentifier
}

class DefinitionsFinder: SyntaxVisitor {
    private var _isScanning: Bool = false
    private var _lastName: String?
    private(set) var definitions: [DependencyDefinition] = []

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        switch token.tokenKind {
        case .structKeyword, .classKeyword,
             .enumKeyword, .contextualKeyword("actor"),
             .extensionKeyword:
            _isScanning = true
        case let .identifier(value):
            assert(_isScanning)

            if _lastName == nil {
                _lastName = value
            }

            if let dependencyIdentifier = DependencyIdentifier(rawValue: value),
               let lastName = _lastName
            {
                let definition = DependencyDefinition(name: lastName,
                                                      identifier: dependencyIdentifier)
                definitions.append(definition)
            }
        case .leftBrace:
            _isScanning = false
            _lastName = nil
        default:
            break
        }

        if _isScanning {
            return .visitChildren
        } else {
            return .skipChildren
        }
    }

    func parse(source: String) throws {
        let sourceFile = try SyntaxParser.parse(source: source)
        walk(sourceFile)
    }
}

class ExtensionBuilder {
    func buildExtensions(for _: [DependencyDefinition]) -> String {
        let source = SourceFile(eofToken: .eof) {
            ImportDecl(pathBuilder: {
                AccessPathComponent(name: "Injectable")
            })
            StructDecl(
                modifiers: ModifierList([TokenSyntax.private]),
                structKeyword: .struct,
                identifier: .identifier("TestDependencyProviderKey"),
                inheritanceClause: TypeInheritanceClause {
                    InheritedType(typeName: "DependencyKey")
                },
                members: MemberDeclBlock {
                    VariableDecl(
                        modifiers: ModifierList([TokenSyntax.static]),
                        letOrVarKeyword: .var,
                        bindings: PatternBindingList([
                            PatternBinding(
                                pattern: IdentifierPattern("defaultValue"),
                                typeAnnotation: SimpleTypeIdentifier(
                                    name: .identifier("_DependencyProvider"),
                                    genericArgumentClause: GenericArgumentClause(leftAngleBracket: .leftAngle.withoutTrivia(),
                                                                                 arguments: GenericArgument(argumentType: "Test"),
                                                                                 rightAngleBracket: .rightAngle.withoutTrivia())

                                ),
                                initializer: InitializerClause(
                                    value: FunctionCallExpr(
                                        "_DependencyProvider",
                                        trailingClosure: ClosureExpr(
                                            leftBrace: .leftBrace
                                                .withLeadingTrivia(.spaces(1))
                                                .withTrailingTrivia(.spaces(1)),
                                            signature: ClosureSignature(
                                                input: ClosureParam(name: .identifier("container")),
                                                inTok: .in.withLeadingTrivia(.spaces(1))
                                            ),
                                            statementsBuilder: {
                                                FunctionCallExpr(
                                                    "Test",
                                                    leftParen: .leftParen,
                                                    rightParen: .rightParen,
                                                    argumentListBuilder: {
                                                        TupleExprElement(label: .identifier("with"),
                                                                         colon: .colon,
                                                                         expression: IdentifierExpr("container"))
                                                    }
                                                )
                                            }
                                        )
                                    )
                                )
                            ),
                        ])
                    )
                }
            )
            ExtensionDecl(
                modifiers: ModifierList([TokenSyntax.public]),
                extensionKeyword: .extension,
                extendedType: "SharedContainer",
                members: MemberDeclBlock {
                    
                }
            )
        }
        
        VariableDecl(
            modifiers: ModifierList([TokenSyntax.static]),
            letOrVarKeyword: .var,
            bindings: PatternBindingList([
                PatternBinding(
                    pattern: IdentifierPattern("test"),
                    typeAnnotation: TypeAnnotation())
            ])
        )

        let syntax = source.buildSyntax(format: Format(indentWidth: 4))

        var content = ""
        syntax.write(to: &content)

        return content
    }
}

//
// public extension SharedContainer {
//    var test: () -> Test {
//        get { { self[TestDependencyProviderKey.self].getValue(container: self) } }
//        set { self[TestDependencyProviderKey.self].replaceProvider { _ in newValue() } }
//    }
// }
