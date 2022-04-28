import Foundation
import PackagePlugin

enum ToledoPluginError: Error {
    case failedToListPackageDirectory
    case noFilesToProcess
    case wrongTargetType
}

@main
struct ToledoPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext,
                             target: Target) async throws -> [Command]
    {
        let tool = try context.tool(named: "ToledoTool")

        guard let target = target as? SwiftSourceModuleTarget else {
            throw ToledoPluginError.wrongTargetType
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
