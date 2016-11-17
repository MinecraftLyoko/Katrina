//
//  SlackManager.swift
//  Katrina
//
//  Created by Rhett Rogers on 16/11/16.
//
//

import Foundation
import Starscream

class SlackManager {

    enum SlackError: Error {
        case genericError
        case disconnected
    }
    
    struct Response {
        let error: SlackError?
        let data: [String: Any]?

        init(error: SlackError?) {
            self.init(error: error, data: nil)
        }

        init(error: SlackError?, data: [String: Any]?) {
            self.error = error
            self.data = data
        }
    }

    typealias Handler = (Response) -> Void
    static var shared = SlackManager()

    private var token: String?
    private var socket: WebSocket?
    var socketConnected: Bool {
        return socket?.isConnected == true
    }
    var channelList: [String: SlackChannel]?
    var userList: [String: SlackUser]?
    lazy var katrinaUser: SlackUser = {
        guard let userList = self.userList else { return SlackUser(id: "none", name: "katrina") }

        for (key, user) in userList {
            if user.name == "katrina" {
                return user
            }
            
        }
        return SlackUser(id: "none", name: "katrina")
    }()
    
    private var dispatchQueue = DispatchQueue(label: "Katrina")

    func channel(withName name: String) -> SlackChannel? {
        guard let channelList = channelList else { return nil }
        var channel: SlackChannel?
        for (_, value) in channelList {
            if value.name == name {
                channel = value
                break
            }
        }
        return channel
    }
    
    func launch() {

        if let token = UserDefaults.standard.string(forKey: "katrinaSlackToken") {
            launch(withToken: token)
        } else {
            print("What is your Slack Token?\n")
            if let token = readLine() {
                UserDefaults.standard.set(token, forKey: "katrinaSlackToken")
                UserDefaults.standard.synchronize()

                launch(withToken: token)
            } else {
                print("error getting slack token")
                exit(0)
            }
        }
    }

    private func launch(withToken token: String) {
        self.token = token
        print("starting rtm")
        rtmStart { response in
            print(response.error, response.data)

        }
    }

    func send(message: String, to user: SlackUser) {
        guard let channel = channelList?.filter({ $0.value.name == user.id }).first?.value else { return }

        send(message: message, to: channel)
    }

    func send(message: String, to channel: SlackChannel) {
        let object: [String: Any] = [
            "id": 1,
            "type": "message",
            "channel": channel.id,
            "text": message
        ]

        if let data = try? JSONSerialization.data(withJSONObject: object, options: []), let string = String(data: data, encoding: .utf8) {
            socket?.write(string: string)
        }
    }

    func send(log: MinecraftLog, to channel: SlackChannel) {
        let object: [[String: Any]] = [[
            "fallback": log.message,
            "text": log.message,
            "color": "#30A7EE"
        ]]

        send(attachments: object, to: channel)
    }

    func send(attachments: Any, to channel: SlackChannel) {
        guard let url = URL(string: "https://slack.com/api/chat.postMessage"), var components = URLComponents(url: url, resolvingAgainstBaseURL: false), let data = try? JSONSerialization.data(withJSONObject: attachments, options: []), let string = String(data: data, encoding: .utf8) else { return }

        components.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "channel", value: channel.id),
            URLQueryItem(name: "attachments", value: string),
            URLQueryItem(name: "username", value: "katrina"),
            URLQueryItem(name: "as_user", value: "false")
        ]

        guard let completeURL = components.url else { return }

        var request = URLRequest(url: completeURL)
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let object = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let ok = object?["ok"] as? Bool else { return }

            if !ok {
                print("Error sending request \(object)")
            }
            
        }.resume()
    }

    private func handleText(text: String) {
        if let data = text.data(using: .utf8), let object = (try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)) as? [String: Any] {
            if let message = SlackMessage(data: object) {
                if message.text.contains("<@\(katrinaUser.id)>") || message.isIM {
                    let formattedMessage = message.text.replacingOccurrences(of: "<@\(katrinaUser.id)>", with: "@katrina")

                    if message.channel.name == "serveradmin" {
                        switch formattedMessage {
                        case "@katrina stop":
                            if !MinecraftServer.defaultServer.ops.contains(where: { $0.name == message.user.name }) {
                                self.send(message: "<@\(message.user.id)> You aren't an op, no special privileges", to: message.channel)
                                return
                            }

                            Command.stop()
                            self.send(message: "Shutting down server...", to: message.channel)
                        default:
                            break
                        }
                    }

                    switch formattedMessage {
                    case "@katrina list", "list":
                        Command.list { attachments in
                            self.send(attachments: attachments, to: message.channel)
                        }
                    default:
                        self.send(message: "Not sure what you meant by \(message.text)", to: message.channel)
                    }
                }
                print(message)
            } else {
                print("Not parsable \(object)")
            }
        } else {
            print("got some text \(text)")
        }
    }

    private func connectSocket(with socketURL: URL, handler: @escaping Handler) {
        socket = WebSocket(url: socketURL)
        socket?.callbackQueue = dispatchQueue
        socket?.onConnect = {
            print("Socket Connected")

            handler(Response(error: nil))
        }
        socket?.onDisconnect = { error in
            handler(Response(error: .disconnected, data: ["error": error]))
        }

        socket?.onText = handleText

        socket?.onData = { data in
            if let object = (try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)) as? [String: Any] {
                print(object)
            } else {
                print("got non json object")
            }
        }

        print("Connecting to \(socketURL)")
        socket?.connect()
    }

    private func rtmStart(_ handler: @escaping Handler) {
        guard let token = token, let url = URL(string: "https://slack.com/api/rtm.start?token=\(token)") else {
            handler(Response(error: .genericError))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print(error)
            } else if let data = data, let object = (try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves)) as? [String: Any], let socketURL = (object["url"] as? String).flatMap({ URL(string: $0) }) {

                if let channels = object["channels"] as? [[String: Any]], let ims = object["ims"] as? [[String: Any]], let groups = object["groups"] as? [[String: Any]] {
                    self.channelList = [:]
                    let mpims = object["mpims"] as? [[String: Any]] ?? []
                    let channelClosure: ([String: Any]) -> Void = { channel in
                        guard let id = channel["id"] as? String, let name = channel["name"] as? String ?? channel["user"] as? String else { return }
                        self.channelList?[id] = SlackChannel(id: id, name: name)
                    }
                    [channels, ims, mpims, groups].forEach { items in
                        items.forEach(channelClosure)
                    }
                }

                if let users = object["users"] as? [[String: Any]] {
                    self.userList = users.reduce([:]) { result, current in
                        guard let id = current["id"] as? String, let name = current["name"] as? String else { return nil }

                        if var result = result {
                            result[id] = SlackUser(id: id, name: name)
                            return result
                        }
                        return result 
                    }
                }

                print(self.channelList!)
                print(self.userList!)
                self.connectSocket(with: socketURL, handler: handler)
                return
            }

            handler(Response(error: .genericError))
        }.resume()
        

        
    }
    
}
