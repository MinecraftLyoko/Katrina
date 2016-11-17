//
//  MinecraftServer.swift
//  Katrina
//
//  Created by Rhett Rogers on 10/12/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation

class MinecraftServer : NSObject, URLSessionDownloadDelegate {
    let out🚿 = Pipe()
    let in🚿 = Pipe()
    let error🚿 = Pipe()

    var playerCount: Int = 0
    var maxPlayers: Int = 0
    var serverActive = false
    lazy var ops: [MinecraftPlayer] = {
        let url = URL(fileURLWithPath: "\(MinecraftServer.bundlePath)/ops.json")
        if let data = try? Data(contentsOf: url), let object = (try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)) as? [[String: Any]] {
            return object.flatMap { item in
                guard let uuid = item["uuid"] as? String, let name = item["name"] as? String else { return nil }

                return MinecraftPlayer(uuid: uuid, name: name.lowercased())
            } 
        } else {
            print("ops file not accessible")
            return []
        }
    }()

    lazy var javaTask: Process = {
        let javaTask = Process()
        javaTask.currentDirectoryPath = MinecraftServer.bundlePath
        javaTask.launchPath = "/usr/bin/java"
        javaTask.arguments = ["-Xmx1024M", "-Xms1024M", "-jar", MinecraftServer.jarPath, "nogui"]

        javaTask.standardOutput = self.out🚿
        javaTask.standardInput = self.in🚿
        return javaTask
    }()

    static let bundlePath = Bundle.main.bundlePath + "/Contents/server"
    static let buildPath = "\(MinecraftServer.bundlePath)/build"
    static let jarPath = "\(MinecraftServer.bundlePath)/minecraft_download.jar"
    static let bukkitPath = "\(MinecraftServer.bundlePath)/craftbukkit_download.jar"

    static var defaultServer: MinecraftServer = {
        let server = MinecraftServer()
        server.setup🚿()
        return server
    }()

    class func runJava(forceDownload: Bool = false) {
        if forceDownload || !FileManager.default.fileExists(atPath: jarPath) || !FileManager.default.fileExists(atPath: bukkitPath) {
//            defaultServer.downloadVanillaServer()
            defaultServer.downloadCraftBukkitServer()
        } else if FileManager.default.fileExists(atPath: jarPath) {
            defaultServer.launch()
        } else {
            defaultServer.launchCraftBukkit()
        }
    }

    class func terminateServer() {
        defaultServer.javaTask.terminate()
    }

    func latestVersion(callback: ((String?)->Void)?) {
        guard let versionManifestURL = URL(string: "https://launchermeta.mojang.com/mc/game/version_manifest.json") else { callback?(nil)
            return
        }

        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: versionManifestURL) { data, response, error in
            guard error == nil, let data = data, let jsonData = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: AnyObject] else {
                callback?(nil)
                return
            }

            guard let latestObject = jsonData?["latest"] as? [String: String], let latestVersion = latestObject["release"] else {
                callback?(nil)
                return
            }

            callback?(latestVersion)
        }

        task.resume()
    }

    func makeServerPathIfNeeded() {
        if !FileManager.default.fileExists(atPath: MinecraftServer.bundlePath) {
            do {
                try FileManager.default.createDirectory(atPath: MinecraftServer.bundlePath, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print(error)
            }
        }

        if !FileManager.default.fileExists(atPath: MinecraftServer.buildPath) {
            do {
                try FileManager.default.createDirectory(atPath: MinecraftServer.buildPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print(error)
            }
        }

        if FileManager.default.fileExists(atPath: MinecraftServer.jarPath) {
            do {
                try FileManager.default.removeItem(atPath: MinecraftServer.jarPath)
            } catch let error as NSError {
                print(error)
            }
        }

        if FileManager.default.fileExists(atPath: MinecraftServer.bukkitPath) {
            do {
                try FileManager.default.removeItem(atPath: MinecraftServer.bukkitPath)
            } catch let error as NSError {
                print(error)
            }
        }

        if FileManager.default.fileExists(atPath: MinecraftServer.buildPath + "/BuildTools.jar") {
            do {
                try FileManager.default.removeItem(atPath: MinecraftServer.buildPath + "/BuildTools.jar")
            } catch let error as NSError {
                print(error)
            }
        }
    }

    func downloadVanillaServer(version: String = "latest") {
        if version == "latest" {
            latestVersion { version in
                guard let version = version else { return }

                self.makeServerPathIfNeeded()

                if FileManager.default.fileExists(atPath: MinecraftServer.jarPath) {
                    do {
                        try FileManager.default.removeItem(atPath: MinecraftServer.jarPath)
                    } catch let error as NSError {
                        print(error)
                    }
                }


                if let URL = URL(string: "https://s3.amazonaws.com/Minecraft.Download/versions/\(version)/minecraft_server.\(version).jar") {
                    print(URL)
                    let session = URLSession(configuration: .default)
                    let task = session.downloadTask(with: URL) { downloadedPath, response, error in
                        guard let downloadedPath = downloadedPath?.relativePath else {
                            print("error downloading \(error)")
                            return
                        }
                        do {
                            try FileManager.default.moveItem(atPath: downloadedPath, toPath: MinecraftServer.jarPath)
                            print("did finish")
                            self.launch()
                        } catch {
                            print("Couldn't move file \(error)")
                        }
                    }
                    task.resume()
                }

            }
        }
    }

    func downloadCraftBukkitServer(version: String = "latest") {
        if version == "latest" {
            downloadBuildToolsIfNedded {
                print(MinecraftServer.bukkitPath)
            }
        }
    }

    func downloadBuildToolsIfNedded(callback: @escaping (() -> Void)) {
        guard let url = URL(string: "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar") else {
            return
        }

        makeServerPathIfNeeded()
        
        URLSession.shared.downloadTask(with: url) { downloadedPath, response, error in
            guard let downloadedPath = downloadedPath?.relativePath else {
                print("error downloading \(error)")
                return
            }
            do {
                try FileManager.default.moveItem(atPath: downloadedPath, toPath: MinecraftServer.buildPath + "/BuildTools.jar")
                
                self.buildCraftBukkit(completion: callback)
            } catch {
                print("Couldn't move file \(error)")
            }
        }.resume()
    }

    func buildCraftBukkit(completion: @escaping (() -> Void)) {
        let environmentSetter = Process()
        environmentSetter.launchPath = "/bin/bash"
        environmentSetter.arguments = ["-c", ""]
        environmentSetter.launch()
        environmentSetter.waitUntilExit()
        
        let builder = Process()
        builder.launchPath = "/bin/bash"
        builder.arguments = ["-c", "cd \(MinecraftServer.buildPath) && export MAVEN_OPTS=\"-Xmx2g\" && /usr/bin/java -Xmx2G -jar \(MinecraftServer.buildPath)/BuildTools.jar"]
        let pipeReader = Pipe()
        guard let regex = try? NSRegularExpression(pattern: "Saved as (craftbukkit-.*\\.jar)", options: []) else { return }
        pipeReader.fileHandleForReading.readabilityHandler = { handle in
            guard let string = String(data: handle.availableData, encoding: .utf8) else { return }
            guard let match = regex.matches(in: string, options: [], range: NSRange(location: 0, length: (string as NSString).length)).first else { return }
            guard match.rangeAt(1).location < (string as NSString).length else { return }

            let craftbukkitFilePath = "\(MinecraftServer.buildPath)/\((string as NSString).substring(with: match.rangeAt(1)))"

            do {
                try FileManager.default.moveItem(atPath: craftbukkitFilePath, toPath: MinecraftServer.bukkitPath)
                try FileManager.default.removeItem(atPath: MinecraftServer.buildPath)
            } catch {
                print(error)
            }

            completion()


        }
        builder.standardOutput = pipeReader
        builder.launch()
    }

    func launch() {
        killPreviousServersIfTheyExist()

        let eulaPath = "\(MinecraftServer.bundlePath)/eula.txt"

        if !FileManager.default.fileExists(atPath: eulaPath) {
            let string = "eula=true"
            let data = string.data(using: String.Encoding.utf8)
            FileManager.default.createFile(atPath: eulaPath, contents: data, attributes: nil)
        }

        javaTask.launch()
        DispatchQueue.global(qos: .background).async {
            while true {
                if !self.javaTask.isRunning {
                    UserDefaults.standard.set(nil, forKey: "minecraft_task_id")
                    exit(0)
                }
            }
        }
        print("Starting java task with id \(javaTask.processIdentifier)")
        UserDefaults.standard.set(Int(javaTask.processIdentifier), forKey: "minecraft_task_id")
        
    }

    func launchCraftBukkit() {
        
    }

    func killPreviousServersIfTheyExist() {
        let taskID = UserDefaults.standard.integer(forKey: "minecraft_task_id")

        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "kill \(taskID)"]
        task.launch()
        task.waitUntilExit()

    }

    func serverDidLoad() {
        serverActive = true

        NotificationCenter.default.post(name: .serverRunning, object: nil)
    }

    func parse(log: MinecraftLog) {

        if let channel = SlackManager.shared.channel(withName: "serveradmin"), log.kind != .chat {
            SlackManager.shared.send(log: log, to: channel)
        }
        print(log, terminator: "")

        if log.thread == .serverThread && log.kind == .info {
            if log.message.contains("Done") {
                serverDidLoad()
            }

            if log.message.contains("joined the game\n") {
                let range = log.message.index(log.message.startIndex, offsetBy: 33) ..< log.message.endIndex
                _ = log.message.substring(with: range).replacingOccurrences(of: " joined the game\n", with: "")

            }
        }
    }

    func setup🚿() {
        out🚿.fileHandleForReading.readabilityHandler = { handle in
            if let string = String(data: handle.availableData, encoding: String.Encoding.utf8), let log = MinecraftLog(logMessage: string) {
                self.parse(log: log)
            }
        }

        FileHandle.standardInput.readabilityHandler = { handle in
            self.in🚿.fileHandleForWriting.write(handle.availableData)
        }
        
        error🚿.fileHandleForReading.readabilityHandler = { handle in
            if let string = String(data: handle.availableData, encoding: String.Encoding.utf8) {
                print("DEATH!", string, terminator: "")
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let data = NSData(contentsOf: location as URL) else { return }

        FileManager.default.createFile(atPath: MinecraftServer.jarPath, contents: data as Data, attributes: nil)
        launch()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("\rDownload Progress: \(Int((Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) * 100))%")
    }

    override var description: String {
        return "Server running with \(playerCount) of \(maxPlayers)"
    }
}
