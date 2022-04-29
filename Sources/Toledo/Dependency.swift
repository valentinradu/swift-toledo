public protocol DependencyKey {
    associatedtype V
    static var defaultValue: V { get }
}

public struct SharedContainer {
    static var all: [AnyHashable: Any] = [:]

    private var _values: [ObjectIdentifier: Any] = [:]
    
    public init() {}
    
    public subscript<K>(_ key: K.Type) -> K.V where K: DependencyKey {
        get {
            _values[ObjectIdentifier(key)] as? K.V ?? key.defaultValue
        }
        set {
            _values[ObjectIdentifier(key)] = newValue
        }
    }
}

public class _AsyncThrowingDependencyProvider<V> where V: AsyncThrowingDependency {
    public typealias Provider = () async throws -> V
    private var _value: V?
    private var _provider: Provider?

    public init() {}

    public func getValue(container: SharedContainer) async throws -> V {
        if let value = _value {
            return value
        }
        let value: V
        if let provider = _provider {
            value = try await provider()
        } else {
            value = try await V(with: container)
        }
        _value = value
        return value
    }

    public func replaceProvider(_ provider: @escaping Provider) {
        _value = nil
        _provider = provider
    }
}

public class _ThrowingDependencyProvider<V> where V: ThrowingDependency {
    public typealias Provider = () throws -> V
    private var _value: V?
    private var _provider: Provider?

    public init() {}

    public func getValue(container: SharedContainer) throws -> V {
        if let value = _value {
            return value
        }
        let value: V
        if let provider = _provider {
            value = try provider()
        } else {
            value = try V(with: container)
        }
        _value = value
        return value
    }

    public func replaceProvider(_ provider: @escaping Provider) {
        _value = nil
        _provider = provider
    }
}

public class _DependencyProvider<V> where V: Dependency {
    public typealias Provider = () -> V
    private var _value: V?
    private var _provider: Provider?

    public init() {}

    public func getValue(container: SharedContainer) -> V {
        if let value = _value {
            return value
        }
        let value: V
        if let provider = _provider {
            value = provider()
        } else {
            value = V(with: container)
        }
        _value = value
        return value
    }

    public func replaceProvider(_ provider: @escaping Provider) {
        _value = nil
        _provider = provider
    }
}

public protocol AsyncThrowingDependency {
    init(with: SharedContainer) async throws
}

public protocol ThrowingDependency {
    init(with: SharedContainer) throws
}

public protocol Dependency {
    init(with: SharedContainer)
}
