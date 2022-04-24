import Foundation
import PackagePlugin

enum InjectablePluginError: Error {
    case failedToListPackageDirectory
    case noFilesToProcess
    case wrongTargetType
}

@main
struct InjectablePlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext,
                             target: Target) async throws -> [Command]
    {
        let tool = try context.tool(named: "InjectableTool")

        guard let target = target as? SwiftSourceModuleTarget else {
            throw InjectablePluginError.wrongTargetType
        }

        let commands: [Command] = target
            .sourceFiles.map { $0.path }
            .compactMap {
                let filename = $0.lastComponent
                let outputName = $0.stem + "+Dependencies" + ".swift"
                let outputPath = context.pluginWorkDirectory.appending(outputName)

                return .buildCommand(displayName: "Processing \(filename)",
                                     executable: tool.path,
                                     arguments: [$0, outputPath],
                                     inputFiles: [$0],
                                     outputFiles: [outputPath])
            }

        return commands
    }
}
