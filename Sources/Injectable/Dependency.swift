public protocol SharedContainerKey {
    associatedtype V
    static var defaultValue: V { get }
}

public struct SharedContainer {
    static var all: [AnyHashable: Any] = [:]

    private var _values: [ObjectIdentifier: Any] = [:]
    public subscript<K>(_ key: K.Type) -> K.V where K: SharedContainerKey {
        get {
            _values[ObjectIdentifier(key)] as? K.V ?? key.defaultValue
        }
        set {
            _values[ObjectIdentifier(key)] = newValue
        }
    }
}

public protocol AsyncFailableDependency {
    init(with: SharedContainer) async throws
}

public protocol FailableDependency {
    init(with: SharedContainer) throws
}

public protocol Dependency {
    init(with: SharedContainer)
}

public protocol LocalDependency {}
