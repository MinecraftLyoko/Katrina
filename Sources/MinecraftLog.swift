//
//  MinecraftLog.swift
//  Katrina
//
//  Created by Rhett Rogers on 16/11/16.
//
//

import Foundation

struct MinecraftLog {

    enum Kind: String {
        case info = "INFO"
        case chat
        case none
    }

    enum Thread: String {
        case serverThread = "Server thread"
        case serverShutdownThread = "Server Shutdown Thread"
        case none
    }
    
    let timestamp: String
    let thread: Thread
    let kind: Kind
    let chatter: String?
    let message: String
    let metadata: [String: Any]?

    init?(logMessage: String) {
        guard let regex = try? NSRegularExpression(pattern: "\\[(.*)\\] \\[(.*)\\/(.*)\\]: (<.*>)?(.*)", options: .caseInsensitive) else { return nil }

        guard let match = regex.matches(in: logMessage, options: [], range: NSRange(location: 0, length: (logMessage as NSString).length)).first else { return nil }

        let nsLogMessage = logMessage as NSString
        timestamp = nsLogMessage.substring(with: match.rangeAt(1))
        let threadString = nsLogMessage.substring(with: match.rangeAt(2))
        let kindString = nsLogMessage.substring(with: match.rangeAt(3))
        if match.rangeAt(4).location < nsLogMessage.length {
            chatter = nsLogMessage.substring(with: match.rangeAt(4)).replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
            kind = .chat
        } else {
            chatter = nil
            kind = Kind(rawValue: kindString) ?? .none
        }
        message = nsLogMessage.substring(with: match.rangeAt(5))

        thread = Thread(rawValue: threadString) ?? .none

        metadata = nil
    }

}
