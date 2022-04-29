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

public struct C: AsyncThrowingDependency {
    let a: A
    public init(with container: SharedContainer) async throws {
        a = container.a()
    }
}

extension MusicDeviceGroupID: Dependency {
    public init(with _: SharedContainer) {
        self = 2
    }
}
