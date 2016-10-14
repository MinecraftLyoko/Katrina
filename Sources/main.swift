//
//  main.swift
//  Katrina
//
//  Created by Rhett Rogers on 2/8/16.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation

DispatchQueue.global(qos: .background).async {
    MinecraftServer.runJava()
}

while true {
    sleep(10)
}
