//
//  MinecraftPlayer.swift
//  Katrina
//
//  Created by Rhett Rogers on 16/11/16.
//
//

import Foundation

struct MinecraftPlayer: Equatable {

    let uuid: String
    let name: String
    var isOp: Bool {
        return MinecraftServer.defaultServer.ops.contains(where: { $0 == self })
    }

}

func == (lhs: MinecraftPlayer, rhs: MinecraftPlayer) -> Bool {
    return lhs.uuid == rhs.uuid
}
