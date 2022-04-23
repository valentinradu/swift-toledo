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

class DefinitionsProvider: SyntaxVisitor {
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
