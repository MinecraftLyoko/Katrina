//
//  Command.swift
//  Katrina
//
//  Created by Rhett Rogers on 10/12/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation

class Command {
    class func runCommand(_ command: String, responses: Int, runBlock: ((logs: [String]) -> Void)?) {
        let block = {
            if let data = "\(command)\n".data(using: String.Encoding.utf8) {
                let oldHandler = MinecraftServer.instance.out🚿.fileHandleForReading.readabilityHandler
                var handledResponses = 0
                var logs = [String]()
                MinecraftServer.instance.out🚿.fileHandleForReading.readabilityHandler = { (handle) in

                    let data = handle.availableData
                    if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String {
                        logs.append(str)
                        handledResponses += 1

                    }

                    if handledResponses >= responses {
                        MinecraftServer.instance.out🚿.fileHandleForReading.readabilityHandler = oldHandler
                        if let block = runBlock {
                            block(logs: logs)
                        }
                    }
                }
                MinecraftServer.instance.in🚿.fileHandleForWriting.write(data)
            }
        }


        if MinecraftServer.instance.serverActive {
            block()
        } else {
            NotificationCenter.default().addObserver(forName: "server is running" as NSNotification.Name, object: nil, queue: nil, using: { (not) -> Void in
                block()
            })
        }
    }


    class func list() {
        runCommand("list", responses: 2) { (logs) -> Void in
            var num = logs[0]
            var players = logs[1]

            let range = (num.index(num.startIndex, offsetBy: 43) ..< num.endIndex)
            num = num.substring(with: range)
            num = num.replacingOccurrences(of: " players online:\n", with: "")
            let numArr = num.characters.split { $0 == "/" }.map({String($0)})


            let playerRange = (players.index(players.startIndex, offsetBy: 33) ..< players.endIndex)
            players = players.substring(with: playerRange)
            players = players.replacingOccurrences(of: "\n", with: "")


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

    class func op(_ player: String) {
        runCommand("op \(player)", responses: 0, runBlock: nil)
    }

}
