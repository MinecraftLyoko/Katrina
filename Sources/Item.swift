//
//  Item.swift
//  SwiftMinecraftSlack
//
//  Created by Rhett Rogers on 10/16/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation



class Item {
    
    var name = ""
    var count: Int = 0
    //Number of items stacked in this inventory slot. Any item can be stacked, including tools, armor, and vehicles. Range is -128 to 127. Values of 1 are not displayed in-game. Values below 1 are displayed in red.[note 1]
    
    var slot: Int? // May not exist. The inventory slot the item is in.
    
    var damage: Int = 0
    //The data value for this item. The name "Damage" comes from when only tools used this value, now many other items use this value for other purposes. For blocks, it is the 4-bit "block data" tag that determines a variant of the block. Defaults to 0.
    
    var id: ItemId = .Stone
    // Item/Block ID (This is a Short tag prior to 1.8.) If not specified, Minecraft changes the item to stone (setting ID to 1 and Damage to 0, and ignoring any existing Damage value) when loading the chunk or summoning the item .
    
    var tag: NBTTag?
    // Additional information about the item, discussed in the below sections. This tag is optional for most items.

    init(newTag: NBTTag) {
        if let c = newTag.compoundValue {
            for x in c {
                if let name = x.tagName {
                    switch name {
                    case "Count":
                        if let b = x.byteValue {
                            count = b.toInt()
                        }
                    case "Slot":
                        if let b = x.byteValue {
                            slot = b.toInt()
                        }
                    case "Damage":
                        if let s = x.shortValue {
                            damage = s
                        }
                    case "id":
                        if let s = x.stringValue, let ID = ItemId(rawValue: s) {
                            id = ID
                        }
                    case "tag":
                        break
                    default: break
                    }
                }
            }
        }
    }
    
    
    var description: String {
        var s = "\(count) of \(id)"
        if let slot = slot {
            s = "\(s) in slot \(slot)"
        }
        s = "\(s) with damage \(damage)"
        return s
    }
}