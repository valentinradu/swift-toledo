@MainActor
public protocol DependencyKey {
    associatedtype V
    static var defaultValue: V { get }
}

@MainActor
public struct SharedContainer {
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

@MainActor
public class _AsyncThrowingDependencyProvider<V> where V: AsyncThrowingDependency {
    public typealias Provider = () async throws -> V
    private var _value: V?
    private var _provider: Provider?
    private var _task: Task<V, Error>?

    public init() {}

    public func getValue(container: SharedContainer) async throws -> V {
        if let value = _value {
            return value
        }

        let value: V

        if let task = _task {
            value = try await task.value
        } else if let provider = _provider {
            let task = Task {
                try await provider()
            }
            _task = task
            value = try await task.value
        } else {
            let task = Task {
                try await V(with: container)
            }
            _task = task
            value = try await task.value
        }
        _value = value
        return value
    }

    public func replaceProvider(_ provider: @escaping Provider) {
        _task = nil
        _value = nil
        _provider = provider
    }
}

@MainActor
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

@MainActor
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
    @MainActor init(with: SharedContainer) async throws
}

public protocol ThrowingDependency {
    @MainActor init(with: SharedContainer) throws
}

public protocol Dependency {
    @MainActor init(with: SharedContainer)
}
