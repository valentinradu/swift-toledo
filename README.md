# Toledo

təˈliːdoʊ - The former Spanish capital. A city famous for its art, metalwork and marzipan.

[![Swift](https://img.shields.io/badge/Swift-5.6-orange.svg?style=for-the-badge&logo=swift)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-13-blue.svg?style=for-the-badge&logo=Xcode&logoColor=white)](https://developer.apple.com/xcode)
[![MIT](https://img.shields.io/badge/license-MIT-black.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

 Toledo is a dependency injection library for Swift that uses code generation to guarantee that all dependencies can be resolved at runtime.  

## Index
* [Features](#features)
* [Installation](#installation)
* [Usage](#usage)
* [License](#license)

## Features

- once it compiles, it works
- multiple containers (no singleton)
- makes no assumption about your code
- conformance can be provided in extensions
- works great with SwiftUI for view model DI
- simple installation process via SPM 

## Installation

Using Swift Package Manager:
```swift
dependencies: [
    .package(
        name: "Toledo",
        url: "https://github.com/valentinradu/Toledo.git",
        from: "0.0.1"
    )
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: ["Toledo"],
        plugins: [
            .plugin(name: "ToledoPlugin", package: "Toledo")
        ]
    )
]
```

Notice the plugin. It should be applied to all targets that use the library.

## Usage 

Toledo has 3 types of dependencies: regular, throwing and async throwing. Each has its own protocol that needs to be implemented for a type to be available in the dependency container. For example the conformance for a final class `IdentityModel` would look like this:

```swift
extension IdentityModel: AsyncThrowingDependency {
    public convenience init(with container: SharedContainer) async throws {
        await self.init(renderer: try await container.renderer(),
                        scheduler: container.scheduler(),
                        settings: container.settings())
    }
}
```

At compile time, Toledo will look for types conforming to `Dependency`, `ThrowingDependency` and `AsyncThrowingDependency` and add members, storing shared instances of each, to `SharedContainer`. The members are named by switching the first letter of the type name to lowercase.

This means that the `IdentityModel` above will be available as `try await container.identityModel()`. Notice how an async throwing dependency requires `try await` to resolve. If `IdentityModel` would have been a regular dependency, `container.identityModel()` would have been enough.

### Shared instances vs new instances

Calling `container.identityModel()` always returns the same instance. If you wish to create a new instance within a given container, use the `init(with:)` directly:

```swift
let newInstance = IdentityModel(with: container)
``` 

### Multithreading

Toledo is not thread safe and it assumes all shared instances will be fetched on the same thread. You can however easily wrap `SharedContainer` in an actor to achive thread safety.

### Limitations

For this initial version, all dependency conformances have to be public. This will likely change in the future.

## License
[MIT License](LICENSE)
