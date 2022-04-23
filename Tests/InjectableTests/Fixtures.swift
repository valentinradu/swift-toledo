//
//  File.swift
//
//
//  Created by Valentin Radu on 22/04/2022.
//

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
        a = A(with: container)
    }
}
