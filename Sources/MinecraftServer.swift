//
//  MinecraftServer.swift
//  Katrina
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
    var serverActive = false
    
    lazy var javaTask: NSTask = {
        let javaTask = NSTask()
        javaTask.currentDirectoryPath = MinecraftServer.bundlePath
        javaTask.launchPath = "/usr/bin/java"
        javaTask.arguments = ["-Xmx1024M", "-Xms1024M", "-jar", MinecraftServer.jarPath, "nogui"]
        
        javaTask.standardOutput = self.out🚿
        javaTask.standardInput = self.in🚿
        return javaTask
    }()
    
    static let bundlePath = NSBundle.mainBundle().bundlePath + "/Contents/server"
    static let jarPath = "\(MinecraftServer.bundlePath)/minecraft_download.jar"

    static var defaultServer: MinecraftServer = {
        let server = MinecraftServer()
        server.setup🚿()
        return server
    }()

    class func runJava(forceDownload: Bool = false) {
        if forceDownload || !NSFileManager.defaultManager().fileExistsAtPath(jarPath) {
            defaultServer.downloadServer()
        } else {
            defaultServer.launch()
        }
    }

    class func terminateServer() {
        defaultServer.javaTask.terminate()
    }

    func latestVersion(callback: ((String?)->Void)?) {
        guard let versionManifestURL = NSURL(string: "https://launchermeta.mojang.com/mc/game/version_manifest.json") else { callback?(nil)
            return
        }
        
        let session = NSURLSession(configuration: .defaultSessionConfiguration())
        let task = session.dataTaskWithURL(versionManifestURL) { data, response, error in
            guard error == nil, let data = data, jsonData = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as? [String: AnyObject] else {
                callback?(nil)
                return
            }
            
            guard let latestObject = jsonData?["latest"] as? [String: String], latestVersion = latestObject["release"] else {
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
                
                if !NSFileManager.defaultManager().fileExistsAtPath(MinecraftServer.bundlePath) {
                    do {
                        try NSFileManager.defaultManager().createDirectoryAtPath(MinecraftServer.bundlePath, withIntermediateDirectories: true, attributes: nil)
                    } catch let error as NSError {
                        print(error)
                    }
                }
                
                if NSFileManager.defaultManager().fileExistsAtPath(MinecraftServer.jarPath) {
                    do {
                        try NSFileManager.defaultManager().removeItemAtPath(MinecraftServer.jarPath)
                    } catch let error as NSError {
                        print(error)
                    }
                }
                
                
                if let URL = NSURL(string: "https://s3.amazonaws.com/Minecraft.Download/versions/\(version)/minecraft_server.\(version).jar") {
                    let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)
                    let task = session.downloadTaskWithURL(URL)
                    task.resume()
                }
                
            }
        }
    }

    func launch() {
        killPreviousServersIfTheyExist()
        
        let eulaPath = "\(MinecraftServer.bundlePath)/eula.txt"
        
        if !NSFileManager.defaultManager().fileExistsAtPath(eulaPath) {
            let string = "eula=true"
            let data = string.dataUsingEncoding(NSUTF8StringEncoding)
            NSFileManager.defaultManager().createFileAtPath(eulaPath, contents: data, attributes: nil)
        }

        javaTask.launch()
        print("Starting java task with id \(javaTask.processIdentifier)")
        NSUserDefaults.standardUserDefaults().setInteger(Int(javaTask.processIdentifier), forKey: "minecraft_task_id")
    }
    
    func killPreviousServersIfTheyExist() {
        let taskID = NSUserDefaults.standardUserDefaults().integerForKey("minecraft_task_id")
        
        let task = NSTask()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "kill \(taskID)"]
        task.launch()
        task.waitUntilExit()
        
    }

    func serverDidLoad() {
        serverActive = true
        
        NSNotificationCenter.defaultCenter().postNotificationName("server is running", object: nil)
    }

    func parseLog(log: String) {
        if log.containsString("[Server thread/INFO]: ") {
            if log.containsString("Done") {
                serverDidLoad()
            }

            if log.containsString("joined the game\n") {
                let range = log.startIndex.advancedBy(33) ..< log.endIndex
                _ = log.substringWithRange(range).stringByReplacingOccurrencesOfString(" joined the game\n", withString: "")
                
            }
        }
    }

    func setup🚿() {
        out🚿.fileHandleForReading.readabilityHandler = { handle in
            if let string = String(data: handle.availableData, encoding: NSUTF8StringEncoding) {
                self.parseLog(string)
                print(string, terminator: "")
            }
        }

        error🚿.fileHandleForReading.readabilityHandler = { handle in
            if let string = String(data: handle.availableData, encoding: NSUTF8StringEncoding) {
                print("DEATH!", string, terminator: "")
            }
        }
    }

    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        guard let data = NSData(contentsOfURL: location) else { return }
        
        NSFileManager.defaultManager().createFileAtPath(MinecraftServer.jarPath, contents: data, attributes: nil)
        launch()
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("\rDownload Progress: \(Int((Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) * 100))%")
    }

    override var description: String {
        return "Server running with \(playerCount) of \(maxPlayers)"
    }
}
