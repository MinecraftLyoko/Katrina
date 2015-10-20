//
//  Command.swift
//  SwiftMinecraftSlack
//
//  Created by Rhett Rogers on 10/12/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation

class Command {
    class func runCommand(command: String, responses: Int, runBlock: ((logs: [String]) -> Void)?) {
        let block = {
            if let data = "\(command)\n".dataUsingEncoding(NSUTF8StringEncoding) {
                let oldHandler = MinecraftServer.instance.out🚿.fileHandleForReading.readabilityHandler
                var handledResponses = 0
                var logs = [String]()
                MinecraftServer.instance.out🚿.fileHandleForReading.readabilityHandler = { (handle) in

                    let data = handle.availableData
                    if let str = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                        logs.append(str)
                        handledResponses++
                        
                    }
                    
                    if handledResponses >= responses {
                        MinecraftServer.instance.out🚿.fileHandleForReading.readabilityHandler = oldHandler
                        if let block = runBlock {
                            block(logs: logs)
                        }
                    }
                }
                MinecraftServer.instance.in🚿.fileHandleForWriting.writeData(data)
            }
        }
        
        
        if MinecraftServer.instance.serverActive {
            block()
        } else {
            NSNotificationCenter.defaultCenter().addObserverForName("server is running", object: nil, queue: nil, usingBlock: { (not) -> Void in
                block()
            })
        }
    }
    
    
    class func list() {
        runCommand("list", responses: 2) { (logs) -> Void in
            var num = logs[0]
            var players = logs[1]
            
            let range = Range<String.Index>(start: num.startIndex.advancedBy(43), end: num.endIndex)
            num = num.substringWithRange(range)
            num = num.stringByReplacingOccurrencesOfString(" players online:\n", withString: "")
            let numArr = num.characters.split { $0 == "/" }.map({String($0)})
            
            
            let playerRange = Range<String.Index>(start: players.startIndex.advancedBy(33), end: players.endIndex)
            players = players.substringWithRange(playerRange)
            players = players.stringByReplacingOccurrencesOfString("\n", withString: "")
            
            
            MinecraftServer.instance.playerCount = Int(numArr[0])!
            MinecraftServer.instance.maxPlayers = Int(numArr[1])!
            print(MinecraftServer.instance)
        }
    }
    
    class func stop() {
        runCommand("stop", responses: 0) { (logs) -> Void in
            print("stopping server")
            
        }
    }
    
    class func op(player: String) {
        runCommand("op \(player)", responses: 0, runBlock: nil)
    }
    
}