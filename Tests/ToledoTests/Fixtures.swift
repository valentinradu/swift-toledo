//
//  File.swift
//
//
//  Created by Valentin Radu on 22/04/2022.
//

import AudioUnit
import Foundation
import Toledo

public struct A: Dependency {
    let id: UUID
    
    public init(id: UUID) {
        self.id = id
    }
    
    public init(with _: SharedContainer) {
        id = UUID()
    }
}

public struct B: Dependency {
    let a: A
    public init(with container: SharedContainer) {
        a = container.a()
    }
}

public struct C: AsyncThrowingDependency, SomeProtocol {
    public typealias ResolvedTo = SomeProtocol
    let a: A
    public init(with container: SharedContainer) async throws {
        a = container.a()
    }
}

public struct MockD: AsyncThrowingDependency, SomeProtocol {
    public typealias ResolvedTo = SomeProtocol
    public init(with container: SharedContainer) async throws {}
}

public struct LongLastingAsyncInit: AsyncThrowingDependency {
    let id: UUID
    public init(with container: SharedContainer) async throws {
        id = UUID()
        try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
    }
}

public struct LongLastingSyncInit: Dependency {
    let id: UUID
    public init(with container: SharedContainer) {
        id = UUID()
        Thread.sleep(forTimeInterval: 1)
    }
}

public protocol SomeProtocol {}

extension MusicDeviceGroupID: Dependency {
    public init(with _: SharedContainer) {
        self = 2
    }
}

class Ref<V> {
    var ref: V
    init(_ ref: V) {
        self.ref = ref
    }
}
