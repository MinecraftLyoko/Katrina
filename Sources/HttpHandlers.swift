//
//  Handlers.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpHandlers {
    
    public class func directory(_ dir: String) -> ( (HttpRequest) -> HttpResponse ) {
        return { request in
            if let localPath = request.capturedUrlGroups.first {
                let filesPath = dir.stringByExpandingTildeInPath.stringByAppendingPathComponent(localPath)
                if let fileBody = try? Data(contentsOf: URL(fileURLWithPath: filesPath)) {
                    return HttpResponse.raw(200, "OK", nil, fileBody)
                }
            }
            return HttpResponse.notFound
        }
    }
    
    public class func directoryBrowser(_ dir: String) -> ( (HttpRequest) -> HttpResponse ) {
        return { request in
            if let pathFromUrl = request.capturedUrlGroups.first {
                let filePath = dir.stringByExpandingTildeInPath.stringByAppendingPathComponent(pathFromUrl)
                let fileManager = FileManager.default()
                var isDir: ObjCBool = false;
                if ( fileManager.fileExists(atPath: filePath, isDirectory: &isDir) ) {
                    if ( isDir ) {
                        do {
                            let files = try fileManager.contentsOfDirectory(atPath: filePath)
                            var response = "<h3>\(filePath)</h3></br><table>"
                            response += files.map({ "<tr><td><a href=\"\(request.url)/\($0)\">\($0)</a></td></tr>"}).joined(separator: "")
                            response += "</table>"
                            return HttpResponse.ok(.html(response))
                        } catch  {
                            return HttpResponse.notFound
                        }
                    } else {
                        if let fileBody = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
                            return HttpResponse.raw(200, "OK", nil, fileBody)
                        }
                    }
                }
            }
            return HttpResponse.notFound
        }
    }
}

private extension String {
    var stringByExpandingTildeInPath: String {
        return (self as NSString).expandingTildeInPath
    }
    
    func stringByAppendingPathComponent(_ str: String) -> String {
        return (self as NSString).appendingPathComponent(str)
    }
}
