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
            throw InjectableToolError.failedToReadInputFile
        }

        let definitionsFinder = DefinitionsLookup()
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

struct DependencyData {
    var definitions: [DependencyDefinition] = []
    var imports: [String] = []
}

class DefinitionsLookup: SyntaxVisitor {
    private var _isScanning: Bool = false
    private var _isPublic: Bool = false
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
        case .publicKeyword:
            if _isScanning {
                _isPublic = true
            }
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
               let lastName = _lastName, !data.definitions.map(\.name).contains(lastName)
            {
                let definition = DependencyDefinition(name: lastName,
                                                      identifier: dependencyIdentifier,
                                                      isPublic: _isPublic)
                data.definitions.append(definition)
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

    private func nextFullyQualifiedIdentifier(initialToken token: TokenSyntax,
                                              initialValue value: String? = nil) -> [String]
    {
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
        return prefix(1).lowercased() + dropFirst()
    }
}

class ExtensionBuilder {
    private let _data: DependencyData

    init(_ data: DependencyData) {
        _data = data
    }

    func build() throws -> String? {
        if _data.definitions.count == 0 {
            return nil
        }

        let source = SourceFile(eofToken: .eof) {
            for forwardImport in _data.imports {
                ImportDecl(pathBuilder: {
                    AccessPathComponent(name: forwardImport)
                })
            }
            for def in _data.definitions {
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
