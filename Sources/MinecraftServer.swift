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
    static let jarPath = "\(MinecraftServer.bundlePath)/minecraft_download.jar"

    static var defaultServer: MinecraftServer = {
        let server = MinecraftServer()
        server.setup🚿()
        return server
    }()

    class func runJava(forceDownload: Bool = false) {
        if forceDownload || !FileManager.default.fileExists(atPath: jarPath) {
            defaultServer.downloadServer()
        } else {
            defaultServer.launch()
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

    func downloadServer(version: String = "latest") {
        if version == "latest" {
            latestVersion { version in
                guard let version = version else { return }

                if !FileManager.default.fileExists(atPath: MinecraftServer.bundlePath) {
                    do {
                        try FileManager.default.createDirectory(atPath: MinecraftServer.bundlePath, withIntermediateDirectories: true, attributes: nil)
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

    func launch() {
        killPreviousServersIfTheyExist()

        let eulaPath = "\(MinecraftServer.bundlePath)/eula.txt"

        if !FileManager.default.fileExists(atPath: eulaPath) {
            let string = "eula=true"
            let data = string.data(using: String.Encoding.utf8)
            FileManager.default.createFile(atPath: eulaPath, contents: data, attributes: nil)
        }

        javaTask.launch()
        print("Starting java task with id \(javaTask.processIdentifier)")
        UserDefaults.standard.set(Int(javaTask.processIdentifier), forKey: "minecraft_task_id")
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

    func parseLog(log: String) {
        if log.contains("[Server thread/INFO]: ") {
            if log.contains("Done") {
                serverDidLoad()
            }

            if log.contains("joined the game\n") {
                let range = log.index(log.startIndex, offsetBy: 33) ..< log.endIndex
                _ = log.substring(with: range).replacingOccurrences(of: " joined the game\n", with: "")

            }
        }
    }

    func setup🚿() {
        out🚿.fileHandleForReading.readabilityHandler = { handle in
            if let string = String(data: handle.availableData, encoding: String.Encoding.utf8) {
                self.parseLog(log: string)
                print(string, terminator: "")
            }
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
