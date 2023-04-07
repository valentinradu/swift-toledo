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

enum ToledoToolError: Error {
    case failedToReadInputFile
}

@main
enum ToledoTool {
    public static func main() throws {
        guard CommandLine.arguments.count > 1 else {
            fatalError("You have to pass a file to parse")
        }

        let path = String(CommandLine.arguments[1])

        guard path.hasSuffix("swift") else {
            FileManager.default.createFile(atPath: CommandLine.arguments[2],
                                           contents: nil)
            return
        }

        guard let sourceData = FileManager.default
            .contents(atPath: path),
            let source = String(data: sourceData, encoding: .utf8)
        else {
            throw ToledoToolError.failedToReadInputFile
        }

        let definitionsFinder = DefinitionsLookup(viewMode: .sourceAccurate)
        try definitionsFinder.parse(source: source)

        let extensionsBuilder = ExtensionBuilder(definitionsFinder.data)
        if let extensions = try extensionsBuilder.build() {
            FileManager.default.createFile(atPath: CommandLine.arguments[2],
                                           contents: extensions.data(using: .utf8))
        } else {
            FileManager.default.createFile(atPath: CommandLine.arguments[2],
                                           contents: nil)
        }
    }
}

enum DependencyIdentifier: String {
    case asyncThrowingDependency = "AsyncThrowingDependency"
    case throwingDependency = "ThrowingDependency"
    case dependency = "Dependency"

    var signature: String {
        switch self {
        case .asyncThrowingDependency:
            return "async throws"
        case .throwingDependency:
            return "throws"
        case .dependency:
            return ""
        }
    }

    var prefix: String {
        switch self {
        case .asyncThrowingDependency:
            return "try await"
        case .throwingDependency:
            return "try"
        case .dependency:
            return ""
        }
    }
}

struct DependencyDefinition: Equatable {
    let name: String
    let identifier: DependencyIdentifier
}

struct DependencyData {
    var definitions: [DependencyDefinition] = []
    var imports: [String] = []
}

class DefinitionsLookup: SyntaxVisitor {
    private var _isScanning: Bool = false
    private var _lastName: String?
    private(set) var data: DependencyData = .init()

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        switch token.tokenKind {
        case .structKeyword, .classKeyword,
             .enumKeyword, .contextualKeyword("actor"),
             .extensionKeyword:
            _isScanning = true
        case .importKeyword:
            let identifiers = nextFullyQualifiedIdentifier(initialToken: token)
            data.imports.append(identifiers.joined(separator: "."))
        case let .identifier(value):
            guard _isScanning else {
                break
            }

            if _lastName == nil {
                let identifiers = nextFullyQualifiedIdentifier(initialToken: token,
                                                               initialValue: value)
                _lastName = identifiers.joined(separator: "")
            }

            if let dependencyIdentifier = DependencyIdentifier(rawValue: value),
               let lastName = _lastName, !data.definitions.map(\.name).contains(lastName) {
                let definition = DependencyDefinition(name: lastName,
                                                      identifier: dependencyIdentifier)
                data.definitions.append(definition)
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

    private func nextFullyQualifiedIdentifier(initialToken token: TokenSyntax,
                                              initialValue value: String? = nil) -> [String] {
        var localToken = token
        var localValues = [value].compactMap { $0 }

        while let localNextToken = localToken.nextToken {
            let shouldExit: Bool
            switch localNextToken.tokenKind {
            case let .identifier(nextValue):
                // fixes issue with SwiftSyntax
                if nextValue == "final" {
                    shouldExit = true
                } else {
                    localToken = localNextToken
                    localValues.append(nextValue)
                    shouldExit = false
                }
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

        return localValues
    }
}

extension String {
    func lowercasedFirstLetter() -> String {
        prefix(1).lowercased() + dropFirst()
    }
}

class ExtensionBuilder {
    private let _data: DependencyData

    init(_ data: DependencyData) {
        _data = data
    }

    func build() throws -> String? {
        if _data.definitions.isEmpty {
            return nil
        }

        let source = SourceFile(eofToken: .eof) {
            for forwardImport in _data.imports {
                DeclSyntax("import \(raw: forwardImport)")
            }
            for def in _data.definitions {
                StructDecl("public struct \(def.name)\(def.identifier.rawValue)ProviderKey: DependencyKey") {
                    DeclSyntax(
                        "public static let defaultValue = _\(raw: def.identifier.rawValue)Provider<\(raw: def.name)>()"
                    )
                }
                ExtensionDecl("public extension SharedContainer") {
                    let name = def.name.lowercasedFirstLetter()
                    let signature = def.identifier.signature
                    FunctionDecl("func \(name)() \(signature) -> \(def.name).ResolvedTo") {
                        Stmt(
                            stringLiteral: "return \(def.identifier.prefix) self[\(def.name)\(def.identifier.rawValue)ProviderKey.self].getValue(container: self)"
                        )
                    }
                }
            }
        }

        let syntax = source.formatted()

        var content = ""
        syntax.write(to: &content)

        return content
    }
}
