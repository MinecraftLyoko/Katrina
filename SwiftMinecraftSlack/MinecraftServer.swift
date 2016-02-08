//
//  MinecraftServer.swift
//  SwiftMinecraftSlack
//
//  Created by Rhett Rogers on 10/12/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation

class MinecraftServer : NSObject, NSURLSessionDownloadDelegate {
    let out🚿 = NSPipe()
    let in🚿 = NSPipe()
    let error🚿 = NSPipe()
    
    var playerCount: Int = 0
    var maxPlayers: Int = 0
    
    var players = [String: Player]()
    var region: Region? = nil
    
    var serverActive = false
    static let bundlePath = NSBundle.mainBundle().bundlePath + "/Contents/server"
    static let jarPath = "\(MinecraftServer.bundlePath)/minecraft_download.jar"
    
    let javaTask = NSTask()
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
        if !NSFileManager.defaultManager().fileExistsAtPath(jarPath) {
            instance.downloadServer()
            return
        }
        instance.launch()
    }
    
    
    class func terminateServer() {
        instance.javaTask.terminate()
    }
    
    func downloadServer(version: String = "latest") {
        if version == "latest" {
            if !NSFileManager.defaultManager().fileExistsAtPath(MinecraftServer.bundlePath) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(MinecraftServer.bundlePath, withIntermediateDirectories: false, attributes: nil)
                } catch let error as NSError {
                    print(error)
                }
            }
            
            if !NSFileManager.defaultManager().fileExistsAtPath(MinecraftServer.jarPath) {
                let URL = NSURL(string: "https://s3.amazonaws.com/Minecraft.Download/versions/1.8.8/minecraft_server.1.8.8.jar")!
                let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)
                let task = session.downloadTaskWithURL(URL)
                task.resume()
            }
        }
    }
    
    func getChunkAtBlockCoords(coords: (x:Int, z:Int)) -> RegionChunk {
        func reduceToChunk(i: Int) -> Int {
            return Int(round(Double(i) / 16))
        }
        
        func reduceToRegion(i: Int) -> Int {
            return Int(round(Double(i) / 32))
        }
        
        let chunkCoords = (x: reduceToChunk(coords.x), z:reduceToChunk(coords.z))
        let regionCoords = (x: reduceToRegion(chunkCoords.x), z: reduceToRegion(chunkCoords.z))
        
        let region = Region(regionCoordinates: regionCoords)
        let chunk = region.chunkAtCoords(chunkCoordinates: chunkCoords)
        
        return chunk
    }
    
    
    
    func launch() {
        let eulaPath = "\(MinecraftServer.bundlePath)/eula.txt"
        if !NSFileManager.defaultManager().fileExistsAtPath(eulaPath) {
            let string = "eula=true"
            let data = string.dataUsingEncoding(NSUTF8StringEncoding)
            NSFileManager.defaultManager().createFileAtPath(eulaPath, contents: data, attributes: nil)
        }
        players = Player.loadPlayersFromFile()
        print(players)
        javaTask.launch()
    }
    
    func standardOut() {
        let data = out🚿.fileHandleForReading.availableData
        if let string: String = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
            print(string, terminator: "")
        }
    }
    
    func standardErr() {
        let data = error🚿.fileHandleForReading.readDataOfLength(10)
        if let string: String = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
            print(string, terminator: "")
        }
    }

    func serverDidLoad() {
        serverActive = true
        NSNotificationCenter.defaultCenter().postNotificationName("server is running", object: nil)
    }
    
    func parseLog(log: String) {
//        print(log)
        if log.containsString("[Server thread/INFO]: ") {

            if log.containsString("Done") {
                serverDidLoad()
            }
            
            if log.containsString("joined the game\n") {
                let range = Range<String.Index>(start: log.startIndex.advancedBy(33), end: log.endIndex)
                var l = log.substringWithRange(range)
                l = l.stringByReplacingOccurrencesOfString(" joined the game\n", withString: "")
//                NSNotificationCenter.defaultCenter().postNotificationName(NotificationString.UserJoinedGame.rawValue, object: nil, userInfo: ["Player": Player(name: l)])
            }
            
            if log.containsString("left the game") {
                let words = log.characters.split { $0 == " " }.map({String($0)})
                let playerName = words[3]
                for (_, player) in players {
                    if player.username == playerName {
                        player.didLogOff()
                        break
                    }
                }
            }

            
        }
        
        if log.containsString("[User Authenticator") {
            if log.containsString("UUID of player") {
                let words = log.characters.split { $0 == " " }.map({String($0)})
                let playerName = words[7]
                let playerUUID = words[9].stringByReplacingOccurrencesOfString("\n", withString: "")

                players[playerUUID]?.username = playerName
                players[playerUUID]?.didLogOn()
            }
        }
    }
    
    func setup🚿() {
        out🚿.fileHandleForReading.readabilityHandler = {(handle) in
            let data = handle.availableData
            if let string: String = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                self.parseLog(string)
                print(string, terminator: "")
                
            }
        }
        
        error🚿.fileHandleForReading.readabilityHandler = {(handle) in
            let data = handle.availableData
            if let string: String = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                print("DEATH!", string, terminator: "")
            }
        }
        
//        in🚿.fileHandleForWriting.writeabilityHandler = {(handle) in
//        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let data = NSData(contentsOfURL: location)
        NSFileManager.defaultManager().createFileAtPath(MinecraftServer.jarPath, contents: data, attributes: nil)
        launch()
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print(bytesWritten, totalBytesExpectedToWrite)
    }
    
    func addPlayer(player: Player) {
        players[player.UUID] = player
        playerCount = players.count
    }
    
    override var description: String {
        return "Server running with \(playerCount) of \(maxPlayers)"
    }
}