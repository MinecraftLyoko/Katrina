//
//  Command.swift
//  Katrina
//
//  Created by Rhett Rogers on 10/12/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation

class Command {

    class func runCommand(command: String, responses: Int, runBlock: ((_ logs: [String]) -> Void)?) {
        let block = {
            guard let data = "\(command)\n".data(using: String.Encoding.utf8) else { return }
            
            let oldHandler = MinecraftServer.defaultServer.out🚿.fileHandleForReading.readabilityHandler
            var logs = [String]()
            
            MinecraftServer.defaultServer.out🚿.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String {
                    logs.append(string)
                }
                
                if logs.count >= responses {
                    MinecraftServer.defaultServer.out🚿.fileHandleForReading.readabilityHandler = oldHandler
                    runBlock?(logs)
                }
            }
            MinecraftServer.defaultServer.in🚿.fileHandleForWriting.write(data)
        }

        if MinecraftServer.defaultServer.serverActive {
            block()
        } else {
            NotificationCenter.default.addObserver(forName: .serverRunning, object: nil, queue: nil) { not in
                block()
            }
        }
    }

    class func list() {
        runCommand(command: "list", responses: 2) { logs in
            var num = logs[0]
            var players = logs[1]

            let range = num.index(num.startIndex, offsetBy: 43) ..< num.endIndex
            num = num.substring(with: range)
            num = num.replacingOccurrences(of: " players online:\n", with: "")
            let numArr = num.characters.split { $0 == "/" }.map({String($0)})


            let playerRange = players.index(players.startIndex, offsetBy: 33) ..< players.endIndex
            players = players.substring(with: playerRange)
            players = players.replacingOccurrences(of: "\n", with: "")

            if let playerCount = Int(numArr[0]), let maxPlayers = Int(numArr[1]) {
                MinecraftServer.defaultServer.playerCount = playerCount
                MinecraftServer.defaultServer.maxPlayers = maxPlayers
            }
        }
    }

    class func stop() {
        runCommand(command: "stop", responses: 0) { logs in
            print("stopping server")
        }
    }

    class func op(player: String) {
        runCommand(command: "op \(player)", responses: 0, runBlock: nil)
    }

}

