//
//  File.swift
//
//
//  Created by Valentin Radu on 23/04/2022.
//

import Foundation
@testable import InjectableTool
import XCTest

final class InjectableToolTests: XCTestCase {
    func testBasicDefinitionFinder() async throws {
        let example = """
            struct Test {}
            struct Test0: Dependency, AsyncFailableDependency, FailableDependency {}
            class Test1: Dependency, AsyncFailableDependency, FailableDependency {}
            enum Test2: Dependency, AsyncFailableDependency, FailableDependency {}
            actor Test3: Dependency, AsyncFailableDependency, FailableDependency {}
            extension Test4: Dependency, AsyncFailableDependency, FailableDependency {}
        """

        let definitionsFinder = DefinitionsFinder()
        try definitionsFinder.parse(source: example)

        print(definitionsFinder.definitions)

        XCTAssertEqual(definitionsFinder.definitions,
                       [
                           DependencyDefinition(name: "Test0", identifier: .dependency),
                           DependencyDefinition(name: "Test0", identifier: .asyncFailableDependency),
                           DependencyDefinition(name: "Test0", identifier: .failableDependency),

                           DependencyDefinition(name: "Test1", identifier: .dependency),
                           DependencyDefinition(name: "Test1", identifier: .asyncFailableDependency),
                           DependencyDefinition(name: "Test1", identifier: .failableDependency),

                           DependencyDefinition(name: "Test2", identifier: .dependency),
                           DependencyDefinition(name: "Test2", identifier: .asyncFailableDependency),
                           DependencyDefinition(name: "Test2", identifier: .failableDependency),

                           DependencyDefinition(name: "Test3", identifier: .dependency),
                           DependencyDefinition(name: "Test3", identifier: .asyncFailableDependency),
                           DependencyDefinition(name: "Test3", identifier: .failableDependency),

                           DependencyDefinition(name: "Test4", identifier: .dependency),
                           DependencyDefinition(name: "Test4", identifier: .asyncFailableDependency),
                           DependencyDefinition(name: "Test4", identifier: .failableDependency),
                       ])
    }

    func testBasicExtensionBuilder() async throws {
        let builder = ExtensionBuilder()
        let result = builder.buildExtensions(for: [
            DependencyDefinition(name: "Test", identifier: .dependency),
            DependencyDefinition(name: "Test", identifier: .asyncFailableDependency),
            DependencyDefinition(name: "Test", identifier: .failableDependency),
        ])

        print(result)
    }
}
