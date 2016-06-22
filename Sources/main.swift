//
//  main.swift
//  Katrina
//
//  Created by Rhett Rogers on 2/8/16.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation

dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
    MinecraftServer.runJava()
}
while true {
    sleep(10)
}