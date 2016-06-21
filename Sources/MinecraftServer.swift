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

//    var players = [String: Player]()
//    var region: Region? = nil

    var serverActive = false
    static let bundlePath = Bundle.main().bundlePath + "/Contents/server"
    static let jarPath = "\(MinecraftServer.bundlePath)/minecraft_download.jar"

    let javaTask = Task()
    static var instance: MinecraftServer = {
        let server = MinecraftServer()
        server.javaTask.currentDirectoryPath = bundlePath
        server.javaTask.launchPath = "/usr/bin/java"
        server.javaTask.arguments = ["-Xmx1024M", "-Xms1024M", "-jar", jarPath, "nogui"]

        server.javaTask.standardOutput = server.out🚿
        server.javaTask.standardInput = server.in🚿
        server.setup🚿()
        return server
    }()


    class func runJava() {
        if !FileManager.default().fileExists(atPath: jarPath) {
            instance.downloadServer()
            return
        }
        instance.launch()
    }


    class func terminateServer() {
        instance.javaTask.terminate()
    }

    func downloadServer(_ version: String = "latest") {
        if version == "latest" {
            if !FileManager.default().fileExists(atPath: MinecraftServer.bundlePath) {
                do {
                    try FileManager.default().createDirectory(atPath: MinecraftServer.bundlePath, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    print(error)
                }
            }

            if !FileManager.default().fileExists(atPath: MinecraftServer.jarPath) {
                let URL = Foundation.URL(string: "https://s3.amazonaws.com/Minecraft.Download/versions/1.8.8/minecraft_server.1.8.8.jar")!
                let session = Foundation.URLSession(configuration: URLSessionConfiguration.default(), delegate: self, delegateQueue: nil)
                let task = session.downloadTask(with: URL)
                task.resume()
            }
        }
    }
//
//    func getChunkAtBlockCoords(_ coords: (x:Int, z:Int)) -> RegionChunk {
//        func reduceToChunk(_ i: Int) -> Int {
//            return Int(round(Double(i) / 16))
//        }
//
//        func reduceToRegion(_ i: Int) -> Int {
//            return Int(round(Double(i) / 32))
//        }
//
//        let chunkCoords = (x: reduceToChunk(coords.x), z:reduceToChunk(coords.z))
//        let regionCoords = (x: reduceToRegion(chunkCoords.x), z: reduceToRegion(chunkCoords.z))
//
//        let region = Region(regionCoordinates: regionCoords)
//        let chunk = region.chunkAtCoords(chunkCoordinates: chunkCoords)
//
//        return chunk
//    }



    func launch() {
        let eulaPath = "\(MinecraftServer.bundlePath)/eula.txt"


        if !FileManager.default().fileExists(atPath: eulaPath) {
            let string = "eula=true"
            let data = string.data(using: String.Encoding.utf8)
            FileManager.default().createFile(atPath: eulaPath, contents: data, attributes: nil)
        }
//        players = Player.loadPlayersFromFile()
        
        javaTask.launch()
    }

    func standardOut() {
        let data = out🚿.fileHandleForReading.availableData
        if let string: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String {
            print(string, terminator: "")
        }
    }

    func standardErr() {
        let data = error🚿.fileHandleForReading.readData(ofLength: 10)
        if let string: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String {
            print(string, terminator: "")
        }
    }

    func serverDidLoad() {
        serverActive = true
        NotificationCenter.default().post(name: Notification.Name(rawValue: "server is running"), object: nil)
    }

    func parseLog(_ log: String) {
        //        print(log)
        if log.contains("[Server thread/INFO]: ") {

            if log.contains("Done") {
                serverDidLoad()
            }

            if log.contains("joined the game\n") {
                let range = (log.characters.index(log.startIndex, offsetBy: 33) ..< log.endIndex)
                var l = log.substring(with: range)
                l = l.replacingOccurrences(of: " joined the game\n", with: "")
            }

        }

    }

    func setup🚿() {
        out🚿.fileHandleForReading.readabilityHandler = {(handle) in
            let data = handle.availableData
            if let string: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String {
                self.parseLog(string)
                print(string, terminator: "")

            }
        }

        error🚿.fileHandleForReading.readabilityHandler = {(handle) in
            let data = handle.availableData
            if let string: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String {
                print("DEATH!", string, terminator: "")
            }
        }

        //        in🚿.fileHandleForWriting.writeabilityHandler = {(handle) in
        //        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let data = try? Data(contentsOf: location)
        FileManager.default().createFile(atPath: MinecraftServer.jarPath, contents: data, attributes: nil)
        launch()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // print(bytesWritten, totalBytesExpectedToWrite)
    }

//    func addPlayer(_ player: Player) {
//        players[player.UUID] = player
//        playerCount = players.count
//    }

    override var description: String {
        return "Server running with \(playerCount) of \(maxPlayers)"
    }
}
