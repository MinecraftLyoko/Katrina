//
//  Command.swift
//  Katrina
//
//  Created by Rhett Rogers on 10/12/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation

class Command {
    
    class func runCommand(command: String, responses: Int, runBlock: ((logs: [String]) -> Void)?) {
        let block = {
            guard let data = "\(command)\n".dataUsingEncoding(NSUTF8StringEncoding) else { return }
            
            let oldHandler = MinecraftServer.defaultServer.out🚿.fileHandleForReading.readabilityHandler
            var logs = [String]()
            
            MinecraftServer.defaultServer.out🚿.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
                    logs.append(string)
                }
                
                if logs.count >= responses {
                    MinecraftServer.defaultServer.out🚿.fileHandleForReading.readabilityHandler = oldHandler
                    runBlock?(logs: logs)
                }
            }
            MinecraftServer.defaultServer.in🚿.fileHandleForWriting.writeData(data)
        }

        if MinecraftServer.defaultServer.serverActive {
            block()
        } else {
            NSNotificationCenter.defaultCenter().addObserverForName("server is running", object: nil, queue: nil) { not in
                block()
            }
        }
    }

    class func list() {
        runCommand("list", responses: 2) { logs in
            var num = logs[0]
            var players = logs[1]

            let range = num.startIndex.advancedBy(43) ..< num.endIndex
            num = num.substringWithRange(range)
            num = num.stringByReplacingOccurrencesOfString(" players online:\n", withString: "")
            let numArr = num.characters.split { $0 == "/" }.map({String($0)})


            let playerRange = players.startIndex.advancedBy(33) ..< players.endIndex
            players = players.substringWithRange(playerRange)
            players = players.stringByReplacingOccurrencesOfString("\n", withString: "")

            if let playerCount = Int(numArr[0]), maxPlayers = Int(numArr[1]) {
                MinecraftServer.defaultServer.playerCount = playerCount
                MinecraftServer.defaultServer.maxPlayers = maxPlayers
            }
        }
    }

    class func stop() {
        runCommand("stop", responses: 0) { logs in
            print("stopping server")
        }
    }

    class func op(player: String) {
        runCommand("op \(player)", responses: 0, runBlock: nil)
    }

}