//
//  Section.swift
//  minecraftReader
//
//  Created by Rhett Rogers on 10/7/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation


class Section {
    //The Y index (not coordinate) of this section.
    //Range 0 to 15 (bottom to top), with no duplicates but some sections may be missing if empty.
    var y: Int = -1
    
    var blocks = [String : Block]()
    
    //4096 bytes of block IDs defining the terrain.
    //8 bits per block, plus the bits from the below Add tag.
    var blockData: [NSData] = [NSData]()
    
    //May not exist. 2048 bytes of additional block ID data.
    //The value to add to (combine with) the above block ID to form the true block ID in the range 0 to 4095.
    //4 bits per block. Combining is done by shifting this value to the left 8 bits and then adding it to the block ID from above.
    var addData: [NSData] = [NSData]()
    
    
    
    //2048 bytes of block data additionally defining parts of the terrain. 4 bits per block.
    var data: [NSData] = [NSData]()
    
    //2048 bytes recording the amount of block-emitted light in each block.
    //Makes load times faster compared to recomputing at load time. 4 bits per block.
    var blockLight: [NSData] = [NSData]()
    
    // 2048 bytes recording the amount of sunlight or moonlight hitting each block. 4 bits per block.
    var skyLight: [NSData] = [NSData]()
    
    
    init(tag: NBTTag) {
        if let c = tag.compoundValue {
            for x in c {
                if let name = x.tagName {
                    switch name {
                    case "Y":
                        if let b = x.byteValue {
                            y = b.toInt()
                        }
                    case "Blocks":
                        if let b = x.byteArrayValue {
                            blockData = b
                        }
                    case "Add":
                        if let b = x.byteArrayValue {
                            addData = b
                        }
                    case "Data":
                        if let b = x.byteArrayValue {
                            data = b
                        }
                    case "BlockLight":
                        if let b = x.byteArrayValue {
                            blockLight = b
                        }
                    case "SkyLight":
                        if let b = x.byteArrayValue {
                            skyLight = b
                        }
                    default: break
                    }
                }
                
            }
            processBlocks()
        }
    }
    
    private func location(index: Int) -> (x: Int, y: Int, z: Int) {
        //    (y * 16 * 16) + (z * 16) + x = index
        func upscale(original: Int, scale: Int) -> (Int, Int) {
            let newOrig = original % scale
            var ret = original - newOrig
            ret /= scale
            return (ret, newOrig)
        }
        
        var orig = index
        var tuple = (x: -1, y: -1, z:-1)
        (tuple.y, orig) = upscale(orig, scale: 256)
        (tuple.z, orig) = upscale(orig, scale: 16)
        tuple.x = orig
        
        return tuple
    }
    
    func processBlocks() {
        func nibble(index: Int, data: [NSData]) -> Int {
            if index % 2 == 0 {
                return data[index / 2].toInt()&0x0F
            } else {
                return (data[index / 2].toInt()>>4)&0x0F
            }
        }
        
        

        for var x = 0; x < blockData.count; x++ {
            var tuple = (BlockId.Air,0,0,0, x:-1,y:-1,z:-1)
            if let blockID = BlockId(rawValue: blockData[x].toInt()) {
                tuple.0 = blockID
            }
            
            tuple.1 = nibble(x, data: self.data)
            tuple.2 = nibble(x, data: self.blockLight)
            tuple.3 = nibble(x, data: self.skyLight)
            
            let loc = location(x) as (x: Int, y: Int, z: Int)
            tuple.x = loc.x
            tuple.y = loc.y
            tuple.z = loc.z
            
            let block = Block(tuple: tuple)

            blocks["\(loc.x),\(loc.y),\(loc.z)"] = block
        }
        
    }
}


