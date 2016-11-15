//
//  NotificationString.swift
//  Katrina
//
//  Created by Rhett Rogers on 10/12/15.
//  Copyright © 2015 Rhett Rogers. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let userJoinedGame = Notification.Name(rawValue: "userJoinedGame")
    static let updatedInfo = Notification.Name(rawValue: "updatedInfo")
    static let serverRunning = Notification.Name(rawValue: "serverRunning")
}
