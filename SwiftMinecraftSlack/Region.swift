//
//  Region.swift
//  minecraftReader
//
//  Created by Rhett Rogers on 10/5/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation


class Region {
    let header: RegionHeader
    var chunks: [RegionChunk] = [RegionChunk]()
    var filename: String
    
    init(data: NSData, regionFileName: String) {
        header = RegionHeader(data: data.subdataWithRange(NSRange(location: 0, length: 8192)))
        chunks = RegionChunk.translateDataToChunks(data, header: header, region: regionFileName)
        filename = regionFileName
    }
    
    convenience init(regionFileName: String) {
        if NSFileManager.defaultManager().fileExistsAtPath(regionFileName) {
            if let data = NSData(contentsOfURL: NSURL(fileURLWithPath: regionFileName)) {
                self.init(data:data, regionFileName: regionFileName)
            } else {
                self.init(data:NSData(), regionFileName: "")
            }
        } else {
            self.init(data: NSData(), regionFileName: "")
        }
    }
    
    convenience init(regionCoordinates coords: (x: Int, z: Int)) {
        let tempFilename = "\(MinecraftServer.bundlePath)/world/region/r.\(coords.x).\(coords.z).mca"
        if NSFileManager.defaultManager().fileExistsAtPath(tempFilename) {
            if let data = NSData(contentsOfURL: NSURL(fileURLWithPath: tempFilename)) {
                self.init(data:data, regionFileName: tempFilename)
            } else {
                self.init(data:NSData(), regionFileName: "")
            }
        } else {
            self.init(data: NSData(), regionFileName: "")
        }
    }
    
    func chunkAtCoords(chunkCoordinates coords: (x: Int, z: Int)) -> RegionChunk {
        var selectedChunk: RegionChunk = chunks[0] // CHANGE THIS
        for chunk in chunks {
            if let loc = chunk.chunkLocation where loc.x == coords.x && loc.z == coords.z {
                selectedChunk = chunk
            }
        }
        return selectedChunk
    }
}