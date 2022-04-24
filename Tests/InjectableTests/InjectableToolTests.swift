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
            struct Empty {}

            struct Struct0: Dependency {}
            struct Struct1: AsyncFailableDependency {}
            struct Struct2: FailableDependency {}

            class Class0: Dependency {}
            class Class1: AsyncFailableDependency {}
            class Class2: FailableDependency {}

            enum Enum0: Dependency {}
            enum Enum1: AsyncFailableDependency {}
            enum Enum2: FailableDependency {}

            actor Actor0: Dependency {}
            actor Actor1: AsyncFailableDependency {}
            actor Actor2: FailableDependency {}

            extension Extension0: Dependency {}
            extension Extension1: AsyncFailableDependency {}
            extension Extension2: FailableDependency {}

            protocol Protocol0: Dependency {}
            protocol Protocol1: AsyncFailableDependency {}
            protocol Protocol2: FailableDependency {}
        """

        let definitionsFinder = DefinitionsFinder()
        try definitionsFinder.parse(source: example)

        XCTAssertEqual(
            definitionsFinder.definitions,
            [
                DependencyDefinition(name: "Struct0", identifier: .dependency, isPublic: false),
                DependencyDefinition(name: "Struct1", identifier: .asyncFailableDependency, isPublic: false),
                DependencyDefinition(name: "Struct2", identifier: .failableDependency, isPublic: false),

                DependencyDefinition(name: "Class0", identifier: .dependency, isPublic: false),
                DependencyDefinition(name: "Class1", identifier: .asyncFailableDependency, isPublic: false),
                DependencyDefinition(name: "Class2", identifier: .failableDependency, isPublic: false),

                DependencyDefinition(name: "Enum0", identifier: .dependency, isPublic: false),
                DependencyDefinition(name: "Enum1", identifier: .asyncFailableDependency, isPublic: false),
                DependencyDefinition(name: "Enum2", identifier: .failableDependency, isPublic: false),

                DependencyDefinition(name: "Actor0", identifier: .dependency, isPublic: false),
                DependencyDefinition(name: "Actor1", identifier: .asyncFailableDependency, isPublic: false),
                DependencyDefinition(name: "Actor2", identifier: .failableDependency, isPublic: false),

                DependencyDefinition(name: "Extension0", identifier: .dependency, isPublic: false),
                DependencyDefinition(name: "Extension1", identifier: .asyncFailableDependency, isPublic: false),
                DependencyDefinition(name: "Extension2", identifier: .failableDependency, isPublic: false),

                DependencyDefinition(name: "Protocol0", identifier: .dependency, isPublic: false),
                DependencyDefinition(name: "Protocol1", identifier: .asyncFailableDependency, isPublic: false),
                DependencyDefinition(name: "Protocol2", identifier: .failableDependency, isPublic: false),
            ]
        )
    }

    func testBasicExtensionBuilder() async throws {
        let builder = ExtensionBuilder([
            DependencyDefinition(name: "Struct1", identifier: .dependency, isPublic: true),
            DependencyDefinition(name: "Struct2", identifier: .asyncFailableDependency, isPublic: true),
            DependencyDefinition(name: "Struct3", identifier: .failableDependency, isPublic: true),
        ])

        let result = try builder.build()

        let expectedResult = """

        import Injectable
        private struct Struct1DependencyProviderKey: DependencyKey {
            static var defaultValue = _DependencyProvider<Struct1>()
        }
        public extension SharedContainer {
            var struct1: ()  -> Struct1 {
                get { {  self[Struct1DependencyProviderKey.self].getValue(container: self) } }
                set { self[Struct1DependencyProviderKey.self].replaceProvider(newValue) }
            }
        }
        private struct Struct2AsyncFailableDependencyProviderKey: DependencyKey {
            static var defaultValue = _AsyncFailableDependencyProvider<Struct2>()
        }
        public extension SharedContainer {
            var struct2: () async throws -> Struct2 {
                get { { try await self[Struct2AsyncFailableDependencyProviderKey.self].getValue(container: self) } }
                set { self[Struct2AsyncFailableDependencyProviderKey.self].replaceProvider(newValue) }
            }
        }
        private struct Struct3FailableDependencyProviderKey: DependencyKey {
            static var defaultValue = _FailableDependencyProvider<Struct3>()
        }
        public extension SharedContainer {
            var struct3: () throws -> Struct3 {
                get { { try self[Struct3FailableDependencyProviderKey.self].getValue(container: self) } }
                set { self[Struct3FailableDependencyProviderKey.self].replaceProvider(newValue) }
            }
        }
        """
        XCTAssertEqual(expectedResult, result)
    }
}
