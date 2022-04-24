public protocol DependencyKey {
    associatedtype V
    static var defaultValue: V { get }
}

@MainActor
public struct SharedContainer {
    static var all: [AnyHashable: Any] = [:]

    private var _values: [ObjectIdentifier: Any] = [:]
    public subscript<K>(_ key: K.Type) -> K.V where K: DependencyKey {
        get {
            _values[ObjectIdentifier(key)] as? K.V ?? key.defaultValue
        }
        set {
            _values[ObjectIdentifier(key)] = newValue
        }
    }
}

public actor _AsyncFailableDependencyProvider<V> {
    public typealias ProviderFunc = (SharedContainer) async throws -> V
    private var _value: V?
    private var _closure: ProviderFunc

    public init(_ closure: @escaping ProviderFunc) {
        _closure = closure
    }

    public func getValue(container: SharedContainer) async throws -> V {
        if let value = _value {
            return value
        }
        let value = try await _closure(container)
        _value = value
        return value
    }

    public func replaceProvider(_ closure: @escaping ProviderFunc) {
        _value = nil
        _closure = closure
    }
}

public class _FailableDependencyProvider<V> {
    public typealias ProviderFunc = (SharedContainer) throws -> V
    private var _value: V?
    private var _closure: ProviderFunc

    public init(_ closure: @escaping ProviderFunc) {
        _closure = closure
    }

    public func getValue(container: SharedContainer) throws -> V {
        if let value = _value {
            return value
        }
        let value = try _closure(container)
        _value = value
        return value
    }

    public func replaceProvider(_ closure: @escaping ProviderFunc) {
        _value = nil
        _closure = closure
    }
}

public class _DependencyProvider<V> {
    public typealias ProviderFunc = (SharedContainer) -> V
    private var _value: V?
    private var _closure: ProviderFunc

    public init(_ closure: @escaping ProviderFunc) {
        _closure = closure
    }

    public func getValue(container: SharedContainer) -> V {
        if let value = _value {
            return value
        }
        let value = _closure(container)
        _value = value
        return value
    }

    public func replaceProvider(_ closure: @escaping ProviderFunc) {
        _value = nil
        _closure = closure
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
