//
//  Player.swift
//  SwiftMinecraftSlack
//
//  Created by Rhett Rogers on 10/12/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation


class Player : Entity {
    enum GameMode: Int {
        case Survival = 0
        case Creative = 1
        case Adventure = 2
        case Spectator = 3
    }
    
    enum PlayerError: ErrorType {
        case NonValidPlayerData
    }
    
    var gameMode: GameMode = .Survival
    var score: Int = 0
    
    var selectedItemSlot = 0
    var selectedItem: Item?
    
    var inventory = [Int: Item]()
    var enderItems = [Int: Item]()
    
    var spawnPoint: (x: Int?, y: Int?, z: Int?) = (nil, nil, nil)
    var spawnForced: Bool = false
    
    var sleeping: Bool = false
    var sleepTimer: Int = 0

    var foodLevel: Int = 20
    var foodExhaustionLevel: Float = 0
    var foodSaturationLevel: Float = 0
    var foodTickTimer: Int = 0
    
    var xpLevel: Int = 0
    var xpProgress: Float = 0
    var xpTotal: Int = 0
    var xpSeed: Int = 0
    
    var UUID: String
    var username: String = ""
    
    var walkSpeed: Float = 0.1 //The walking speed, always 0.1.
    var flySpeed: Float = 0.05 //The flying speed, always 0.05.
    var mayfly: Bool = false // true if the player can fly.
    var flying: Bool = false //true if the player is currently flying.
    var invulnerable: Bool = false //true if the player is immune to all damage and harmful effects except for void damage. (damage caused by the /kill command is void damage)
    var mayBuild: Bool = true //true if the player can place and destroy blocks.
    var instabuild: Bool = false //true if the player can instantly destroy blocks.
    
    var isOnline: Bool = false
    var chunk: RegionChunk?
    
    override var description: String {
       return "Player \(username): \(self.UUID)"
    }
    
    init(data: NSData, playerId: String) throws {
        UUID = playerId
        if let d = data.gzipInflate() {
            let nbt = NBTTag(data: d)
            try super.init(tag: nbt)
            parsePlayerData(nbt)
        } else {
            do {
                try super.init(tag: NBTTag())
            } catch {
                throw PlayerError.NonValidPlayerData
            }
            
            
        }
        
    }
    
    func parsePlayerData(tag: NBTTag) {
        if let c = tag.compoundValue {
            for x in c {
                if let name = x.tagName {
//                    print(x.description)
                    switch name {
                    case "playerGameType":
                        if let i = x.intValue, let g = GameMode(rawValue: i) {
                            gameMode = g
                        }
                    case "Score":
                        if let i = x.intValue {
                            score = i
                        }
                    case "SelectedItemSlot":
                        if let i = x.intValue {
                            selectedItemSlot = i
                        }
                    case "SelectedItem":
                        if let c = x.compoundValue, let i = c.first {
                            selectedItem = Item(newTag: i)
                        }
                    case "SpawnX":
                        if let i = x.intValue {
                            spawnPoint.x = i
                        }
                    case "SpawnY":
                        if let i = x.intValue {
                            spawnPoint.y = i
                        }
                    case "SpawnZ":
                        if let i = x.intValue {
                            spawnPoint.z = i
                        }
                    case "SpawnForced":
                        if let b = x.byteValue {
                            spawnForced = b.toBool()
                        }
                    case "Sleeping":
                        if let b = x.byteValue {
                            sleeping = b.toBool()
                        }
                    case "SleepTimer":
                        if let s = x.shortValue {
                            sleepTimer = s
                        }
                    case "foodLevel":
                        if let i = x.intValue {
                            foodLevel = i
                        }
                    case "foodExhaustionLevel":
                        if let f = x.floatValue {
                            foodExhaustionLevel = f
                        }
                    case "foodSaturationLevel":
                        if let f = x.floatValue {
                            foodSaturationLevel = f
                        }
                    case "foodTickTimer":
                        if let i = x.intValue {
                            foodTickTimer = i
                        }
                    case "XpLevel":
                        if let i = x.intValue {
                            xpLevel = i
                        }
                        
                    case "XpP":
                        if let f = x.floatValue {
                            xpProgress = f
                        }
                    case "XpTotal":
                        if let i = x.intValue {
                            xpTotal = i
                        }
                    case "XpSeed":
                        if let i = x.intValue {
                            xpSeed = i
                        }
                    case "Inventory":
                        if let l = x.listValue {
                            for item in l {
                                inventory[inventory.count] = Item(newTag: item)
                            }

                        }
                    case "EnderItems":
                        if let l = x.listValue {
                            for item in l {
                                enderItems[enderItems.count] = Item(newTag: item)
                            }
                        }
                    case "abilities":
                        if let c = x.compoundValue {
                            parseAbilities(c)
                        }
//                    case "RootVehicle": Not sure how to do this one either
                    default: break
                    }
                    
                }
            }
        }
    }
    
    private var updateTimer: NSTimer = NSTimer()
    
    func didLogOn() {
        print("did log on \(username)")
        
//        updateTimer = NSTimer(timeInterval: 1, target: self, selector: "updatePlayer:", userInfo: nil, repeats: true)
//        isOnline = true
//        NSRunLoop.mainRunLoop().addTimer(updateTimer, forMode: NSDefaultRunLoopMode)
    }
    
    func didLogOff() {
        isOnline = false
//        updateTimer.invalidate()
    }
    
    func parseAbilities(c: [NBTTag]) {
        for x in c {
            if let name = x.tagName {
                switch name {
                case "walkSpeed":
                    if let f = x.floatValue {
                        walkSpeed = f
                    }
                case "flySpeed":
                    if let f = x.floatValue {
                        flySpeed = f
                    }
                case "mayfly":
                    if let b = x.byteValue {
                        mayfly = b.toBool()
                    }
                case "flying":
                    if let b = x.byteValue {
                        flying = b.toBool()
                    }
                case "invulnerable":
                    if let b = x.byteValue {
                        invulnerable = b.toBool()
                    }
                case "mayBuild":
                    if let b = x.byteValue {
                        mayBuild = b.toBool()
                    }
                case "instabuild":
                    if let b = x.byteValue {
                        instabuild = b.toBool()
                    }
                default: break
                }
            }
        }
    }
    
    func updatePlayer(timer: NSTimer) {
        print("updating player \(username) \(pos)")
        let filename = "\(MinecraftServer.bundlePath)/world/playerdata/\(UUID).dat"
        if let c = NSData(contentsOfURL: NSURL(fileURLWithPath: filename)) {
            do {
//                let oldPos = self.pos
                
                if let d = c.gzipInflate() {
                    let nbt = NBTTag(data: d)
                    try self.parseEntityData(nbt)
                    self.parsePlayerData(nbt)
                } else {
                    throw PlayerError.NonValidPlayerData
                }
            } catch {
                print("error updating player")
            }
        }
    }
    
    class func loadPlayersFromFile() -> [String: Player] {
        var players = [String: Player]()
        
        let playerDataPath = "\(MinecraftServer.bundlePath)/world/playerdata"
        do {
            let filePaths = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(playerDataPath)
            for path in filePaths {
                if let c = NSData(contentsOfURL: NSURL(fileURLWithPath: "\(playerDataPath)/\(path)")) {
                    let playerId = path.characters.split { $0 == "." }.map({String($0)})[0]
                    
                    do {
                        try players[playerId] = Player(data: c, playerId: playerId)
                    } catch {
                        print("player data incorrect")
                    }
                }
            }
        } catch {
            print("error loading files")
        }
        
        
        return players
    }
    
    
}