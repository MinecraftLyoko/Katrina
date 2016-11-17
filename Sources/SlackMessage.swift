//
//  SlackMessage.swift
//  Katrina
//
//  Created by Rhett Rogers on 16/11/16.
//
//

import Foundation

struct SlackMessage {

    let channel: SlackChannel
    let user: SlackUser
    let text: String
    let timeStamp: String
    let edited: (userID: String, timeStamp: String)?
    var isIM: Bool {
        return channel.name == user.id
    }

    init?(data: [String: Any]) {
        guard data["type"] as? String == "message", let channelID = data["channel"] as? String, let userID = data["user"] as? String, let text = data["text"] as? String, let timeStamp = data["ts"] as? String else { return nil }

        if let edited = data["edited"] as? [String: String], let userID = edited["user"], let timeStamp = edited["ts"] {
            self.edited = (userID: userID, timeStamp: timeStamp)
        } else {
            self.edited = nil
        }

        channel = SlackManager.shared.channelList?[channelID] ?? SlackChannel(id: channelID, name: "unknown")
        user = SlackManager.shared.userList?[userID] ?? SlackUser(id: userID, name: "unknown")
        self.text = text
        self.timeStamp = timeStamp
    }
    
}
