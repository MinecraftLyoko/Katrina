//
//  Block.swift
//  SwiftMinecraftSlack
//
//  Created by Rhett Rogers on 10/21/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation


class Block {
    var id: BlockId = .Air
    var blockData = 0
    var blockLight = 0
    var skyLight = 0
    var loc = (x: 0, y: 0, z: 0)
    
    var description: String {
        return "\(id) \(blockData) \(blockLight) \(skyLight) \(loc)"
    }
    init(tuple: (id: BlockId, data: Int, blockLight: Int, skyLight: Int, x: Int, y: Int, z: Int)) {
        id = tuple.id
        blockData = tuple.data
        blockLight = tuple.blockLight
        skyLight = tuple.skyLight
        loc.x = tuple.x
        loc.y = tuple.y
        loc.z = tuple.z
    }
    
}