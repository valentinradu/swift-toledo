//
//  File.swift
//
//
//  Created by Valentin Radu on 22/04/2022.
//

import AudioUnit
import Foundation
import Injectable

struct A: Dependency {
    let id: UUID
    init(with _: SharedContainer) {
        id = UUID()
    }
}

struct B: Dependency {
    let a: A
    init(with container: SharedContainer) {
        a = container.a()
    }
}

extension MusicDeviceGroupID: Dependency {
    public init(with _: SharedContainer) {
        self = 2
    }
}
