import Dispatch
public protocol DependencyKey {
    associatedtype V
    static var defaultValue: V { get }
}

public class SharedContainer {
    public init() {}

    public subscript<K>(_ key: K.Type) -> K.V
        where K: DependencyKey
    {
        key.defaultValue
    }

    public func replaceProvider<K, V>(
        _ key: K.Type,
        value: @escaping K.V.Provider
    )
        where K: DependencyKey, K.V == _DependencyProvider<V>
    {
        self[key.self].replaceProvider(value)
    }

    public func replaceProvider<K, V>(
        _ key: K.Type,
        value: @escaping K.V.Provider
    )
        where K: DependencyKey, K.V == _ThrowingDependencyProvider<V>
    {
        self[key.self].replaceProvider(value)
    }

    public func replaceProvider<K, V>(
        _ key: K.Type,
        value: @escaping K.V.Provider
    ) async
        where K: DependencyKey, K.V == _AsyncThrowingDependencyProvider<V>
    {
        await self[key.self].replaceProvider(value)
    }
}

public actor _AsyncThrowingDependencyProvider<V> where V: AsyncThrowingDependency {
    public typealias Provider = (SharedContainer) async throws -> V
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
                try await provider(container)
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

    fileprivate func replaceProvider(_ provider: @escaping Provider) {
        _task = nil
        _value = nil
        _provider = provider
    }
}

public class _ThrowingDependencyProvider<V> where V: ThrowingDependency {
    public typealias Provider = (SharedContainer) throws -> V
    private var _value: V?
    private var _provider: Provider?
    private let _sem = DispatchSemaphore(value: 1)

    public init() {}

    public func getValue(container: SharedContainer) throws -> V {
        _sem.wait()
        defer { _sem.signal() }

        if let value = _value {
            return value
        }
        let value: V
        if let provider = _provider {
            value = try provider(container)
        } else {
            value = try V(with: container)
        }
        _value = value
        return value
    }

    fileprivate func replaceProvider(_ provider: @escaping Provider) {
        _sem.wait()
        defer { _sem.signal() }

        _value = nil
        _provider = provider
    }
}

public class _DependencyProvider<V> where V: Dependency {
    public typealias Provider = (SharedContainer) -> V
    private var _value: V?
    private var _provider: Provider?
    private let _sem = DispatchSemaphore(value: 1)

    public init() {}

    public func getValue(container: SharedContainer) -> V {
        _sem.wait()
        defer { _sem.signal() }

        if let value = _value {
            return value
        }
        let value: V
        if let provider = _provider {
            value = provider(container)
        } else {
            value = V(with: container)
        }
        _value = value
        return value
    }

    fileprivate func replaceProvider(_ provider: @escaping Provider) {
        _sem.wait()
        defer { _sem.signal() }

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
