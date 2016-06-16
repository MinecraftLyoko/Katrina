//
//  HttpServer.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpServer
{
    static let VERSION = "1.0.2";

    public typealias Handler = (HttpRequest) -> HttpResponse

    var handlers: [(expression: RegularExpression, handler: Handler)] = []
    var clientSockets: Set<CInt> = []
    let clientSocketsLock = 0
    var acceptSocket: CInt = -1

    let matchingOptions = RegularExpression.MatchingOptions(rawValue: 0)
    let expressionOptions = RegularExpression.Options(rawValue: 0)

    public init() { }

    public subscript (path: String) -> Handler? {
        get {
            return nil
        }
        set ( newValue ) {
            do {
                let regex = try RegularExpression(pattern: path, options: expressionOptions)
                if let newHandler = newValue {
                    handlers.append(expression: regex, handler: newHandler)
                }
            } catch {

            }
        }
    }

    public func routes() -> [String] { return handlers.map { $0.0.pattern } }

    public func start(_ listenPort: in_port_t = 8080, error: NSErrorPointer? = nil) -> Bool {
        stop()
        if let socket = Socket.tcpForListen(listenPort, error: error) {
            self.acceptSocket = socket
            DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosBackground).async(execute: {
                while let socket = Socket.acceptClientSocket(self.acceptSocket) {
                    HttpServer.lock(self.clientSocketsLock) {
                        self.clientSockets.insert(socket)
                    }
                    if self.acceptSocket == -1 { return }
                    let socketAddress = Socket.peername(socket)
                    DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosBackground).async(execute: {
                        let parser = HttpParser()
                        while let request = parser.nextHttpRequest(socket) {
                            let keepAlive = parser.supportsKeepAlive(request.headers)
                            if let (expression, handler) = self.findHandler(request.url) {
                                let capturedUrlsGroups = self.captureExpressionGroups(expression, value: request.url)
                                let updatedRequest = HttpRequest(url: request.url, urlParams: request.urlParams, method: request.method, headers: request.headers, body: request.body, capturedUrlGroups: capturedUrlsGroups, address: socketAddress)
                                HttpServer.respond(socket, response: handler(updatedRequest), keepAlive: keepAlive)
                            } else {
                                HttpServer.respond(socket, response: HttpResponse.notFound, keepAlive: keepAlive)
                            }
                            if !keepAlive { break }
                        }
                        Socket.release(socket)
                        HttpServer.lock(self.clientSocketsLock) {
                            self.clientSockets.remove(socket)
                        }
                    })
                }
                self.stop()
            })
            return true
        }
        return false
    }

    func findHandler(_ url:String) -> (RegularExpression, Handler)? {
        let u = URL(string: url)!
        let path = u.path!
        for handler in self.handlers {
            let regex = handler.0
            let matches = regex.numberOfMatches(in: path, options: self.matchingOptions, range: HttpServer.asciiRange(path)) > 0
            if matches {
                return handler;
            }
        }
        return nil
    }

    func captureExpressionGroups(_ expression: RegularExpression, value: String) -> [String] {
        let u = URL(string: value)!
        let path = u.path!
        var capturedGroups = [String]()
        if let result = expression.firstMatch(in: path, options: matchingOptions, range: HttpServer.asciiRange(path)) {
            let nsValue: NSString = path
            for i in 1...result.numberOfRanges {
                if let group = nsValue.substring(with: result.range(at: i)).removingPercentEncoding {
                    capturedGroups.append(group)
                }
            }
        }
        return capturedGroups
    }

    public func stop() {
        Socket.release(acceptSocket)
        acceptSocket = -1
        HttpServer.lock(self.clientSocketsLock) {
            for clientSocket in self.clientSockets {
                Socket.release(clientSocket)
            }
            self.clientSockets.removeAll(keepingCapacity: true)
        }
    }

    public class func asciiRange(_ value: String) -> NSRange {
        return NSMakeRange(0, value.lengthOfBytes(using: String.Encoding.ascii))
    }

    public class func lock(_ handle: AnyObject, closure: () -> ()) {
        objc_sync_enter(handle)
        closure()
        objc_sync_exit(handle)
    }

    public class func respond(_ socket: CInt, response: HttpResponse, keepAlive: Bool) {
        _ = Socket.writeUTF8(socket, string: "HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        if let body = response.body() {
            _ = Socket.writeASCII(socket, string: "Content-Length: \(body.count)\r\n")
        } else {
            _ = Socket.writeASCII(socket, string: "Content-Length: 0\r\n")
        }
        if keepAlive {
            _ = Socket.writeASCII(socket, string: "Connection: keep-alive\r\n")
        }
        for (name, value) in response.headers() {
            _ = Socket.writeASCII(socket, string: "\(name): \(value)\r\n")
        }
        _ = Socket.writeASCII(socket, string: "\r\n")
        if let body = response.body() {
            _ = Socket.writeData(socket, data: body)
        }
    }
}
