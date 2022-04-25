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

enum InjectableToolError: Error {
    case failedToReadInputFile
}

@main
enum InjectableTool {
    public static func main() throws {
        guard let sourceData = FileManager.default
            .contents(atPath: CommandLine.arguments[1]),
            let source = String(data: sourceData, encoding: .utf8)
        else {
            throw InjectableToolError.failedToReadInputFile
        }

        let definitionsFinder = DefinitionsFinder()
        try definitionsFinder.parse(source: source)

        let extensionsBuilder = ExtensionBuilder(definitionsFinder.definitions)
        if let extensions = try extensionsBuilder.build() {
            FileManager.default.createFile(atPath: CommandLine.arguments[2],
                                           contents: extensions.data(using: .utf8))
        }
    }
}

enum DependencyIdentifier: String {
    case asyncFailableDependency = "AsyncFailableDependency"
    case failableDependency = "FailableDependency"
    case dependency = "Dependency"

    var signature: String {
        switch self {
        case .asyncFailableDependency:
            return "async throws"
        case .failableDependency:
            return "throws"
        case .dependency:
            return ""
        }
    }

    var prefix: String {
        switch self {
        case .asyncFailableDependency:
            return "try await"
        case .failableDependency:
            return "try"
        case .dependency:
            return ""
        }
    }
}

struct DependencyDefinition: Equatable {
    let name: String
    let identifier: DependencyIdentifier
    let isPublic: Bool
}

class DefinitionsFinder: SyntaxVisitor {
    private var _isScanning: Bool = false
    private var _isPublic: Bool = false
    private var _lastName: String?
    private(set) var definitions: [DependencyDefinition] = []

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        switch token.tokenKind {
        case .structKeyword, .classKeyword,
             .enumKeyword, .contextualKeyword("actor"),
             .extensionKeyword, .protocolKeyword:
            _isScanning = true
        case .publicKeyword:
            if _isScanning {
                _isPublic = true
            }
        case let .identifier(value):
            guard _isScanning else {
                break
            }

            if _lastName == nil {
                var localToken = token
                var localValue = value

                while let localNextToken = localToken.nextToken {
                    let shouldExit: Bool
                    switch localNextToken.tokenKind {
                    case let .identifier(nextValue):
                        localToken = localNextToken
                        localValue = nextValue
                        shouldExit = false
                    case .period:
                        localToken = localNextToken
                        shouldExit = false
                    default:
                        shouldExit = true
                    }

                    if shouldExit {
                        break
                    }
                }

                _lastName = localValue
            }

            if let dependencyIdentifier = DependencyIdentifier(rawValue: value),
               let lastName = _lastName, !definitions.map(\.name).contains(lastName)
            {
                let definition = DependencyDefinition(name: lastName,
                                                      identifier: dependencyIdentifier,
                                                      isPublic: _isPublic)
                definitions.append(definition)
            }
        case .leftBrace:
            _isScanning = false
            _lastName = nil
            _isPublic = false
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

struct RawSyntax: SyntaxBuildable, ExpressibleAsCodeBlockItem {
    let source: String

    func buildSyntax(format: Format, leadingTrivia: Trivia?) -> Syntax {
        do {
            let syntax = try Syntax(SyntaxParser.parse(source: source))
            if let leadingTrivia = leadingTrivia {
                return syntax.withLeadingTrivia(leadingTrivia)
            } else {
                return syntax
            }
        } catch {
            return CodeBlockItemList([])
                .buildSyntax(format: format, leadingTrivia: leadingTrivia)
        }
    }

    func createCodeBlockItem() -> CodeBlockItem {
        CodeBlockItem(item: self)
    }
}

extension String {
    func lowercasedFirstLetter() -> String {
        return prefix(1).lowercased() + lowercased().dropFirst()
    }
}

class ExtensionBuilder {
    private let _definitions: [DependencyDefinition]

    init(_ definitions: [DependencyDefinition]) {
        _definitions = definitions
    }

    func build() throws -> String? {
        if _definitions.count == 0 {
            return nil
        }

        let source = SourceFile(eofToken: .eof) {
            ImportDecl(pathBuilder: {
                AccessPathComponent(name: "Injectable")
            })
            for def in _definitions {
                RawSyntax(source: """
                private struct \(def.name)\(def.identifier.rawValue)ProviderKey: DependencyKey {
                    static var defaultValue = _\(def.identifier.rawValue)Provider<\(def.name)>()
                }
                \(def.isPublic ? "public" : "") extension SharedContainer {
                    var \(def.name.lowercasedFirstLetter()): () \(def.identifier.signature) -> \(def.name) {
                        get { { \(def.identifier.prefix) self[\(def.name)\(def.identifier.rawValue)ProviderKey.self].getValue(container: self) } }
                        set { self[\(def.name)\(def.identifier.rawValue)ProviderKey.self].replaceProvider(newValue) }
                    }
                }
                """)
            }
        }

        let syntax = source.buildSyntax(format: Format(indentWidth: 4))

        var content = ""
        syntax.write(to: &content)

        return content
    }
}
