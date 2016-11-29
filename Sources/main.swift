//
//  main.swift
//  Katrina
//
//  Created by Rhett Rogers on 2/8/16.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation

DispatchQueue.global(qos: .background).async {
    SlackManager.shared.launch()
    MinecraftServer.runJava(forceDownload: false, useCraftbukkit: true)
}

while true {
    sleep(10)
}
