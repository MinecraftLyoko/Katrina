//: Playground - noun: a place where people can play

import Foundation

var str = "Hello, playground"


let range = Range<String.Index>(start: str.startIndex.advancedBy(3), end: str.endIndex)
var sub = str.substringWithRange(range)

class Bob {
    let name = "Bob"
}

let b = Bob()

sizeofValue(b)

let c = "51bae5ec-6df7-40f9-8765-f94e9bf1287b.dat"

let playerId = c.characters.split { $0 == "." }.map({String($0)})[0]
playerId


extension NSData {
    func toBool() -> Bool {
        var a: Int = -1
        self.getBytes(&a, length: 1)
        if a < 0 {
            a = 0
        }
        return Bool(a)
    }
    
    func toInt() -> Int {
        var a = Int()
        self.getBytes(&a, length: 1)
        return a
    }
    
}

func nibble(index: Int, data: [NSData]) -> Int {
    if index % 2 == 0 {
        return data[index / 2].toInt()&0x0F
    } else {
        return (data[index / 2].toInt()>>4)&0x0F
    }
}

var i = 64
var mon = NSData(bytes: &i, length: 1)
var da = [mon]

let tuple = (nibble(1, data: da), nibble(0, data: da))


func location(index: Int) -> (x: Int, y: Int, z: Int) {
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

func reverse(x: Int, y: Int, z: Int) -> Int {
    return (y*16*16)+(z*16) + x
}

reverse(1, y: 2, z: 3)
location(561)

reverse(150, y: 223, z: -145)
location(4095)

