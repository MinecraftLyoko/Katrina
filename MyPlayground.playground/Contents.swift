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