//
//  HttpResponse.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum HttpResponseBody {
    
    case json(AnyObject)
    case xml(AnyObject)
    case plist(AnyObject)
    case html(String)
    case string(String)
    
    func data() -> String? {
        switch self {
        case .json(let object):
            if JSONSerialization.isValidJSONObject(object) {
                do {
                    let json = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions.prettyPrinted)
                    if let nsString = NSString(data: json, encoding: String.Encoding.utf8.rawValue) {
                        return nsString as String
                    }
                } catch let serializationError as NSError {
                    return "Serialisation error: \(serializationError)"
                }
            }
            return "Invalid object to serialise."
        case .xml(_):
            return "XML serialization not supported."
        case .plist(let object):
            let format = PropertyListSerialization.PropertyListFormat.xmlFormat_v1_0
            if PropertyListSerialization.propertyList(object, isValidFor: format) {
                do {
                    let plist = try PropertyListSerialization.data(fromPropertyList: object, format: format, options: 0)
                    if let nsString = NSString(data: plist, encoding: String.Encoding.utf8.rawValue) {
                        return nsString as String
                    }
                } catch let serializationError as NSError {
                    return "Serialisation error: \(serializationError)"
                }
            }
            return "Invalid object to serialise."
        case .string(let body):
            return body
        case .html(let body):
            return "<html><body>\(body)</body></html>"
        }
    }
}

public enum HttpResponse {
    
    case ok(HttpResponseBody), created, accepted
    case movedPermanently(String)
    case badRequest, unauthorized, forbidden, notFound
    case internalServerError
    case raw(Int, String, [String:String]?, Data)
    
    func statusCode() -> Int {
        switch self {
        case .ok(_)                 : return 200
        case .created               : return 201
        case .accepted              : return 202
        case .movedPermanently      : return 301
        case .badRequest            : return 400
        case .unauthorized          : return 401
        case .forbidden             : return 403
        case .notFound              : return 404
        case .internalServerError   : return 500
        case .raw(let code,_,_,_)   : return code
        }
    }
    
    func reasonPhrase() -> String {
        switch self {
        case .ok(_)                 : return "OK"
        case .created               : return "Created"
        case .accepted              : return "Accepted"
        case .movedPermanently      : return "Moved Permanently"
        case .badRequest            : return "Bad Request"
        case .unauthorized          : return "Unauthorized"
        case .forbidden             : return "Forbidden"
        case .notFound              : return "Not Found"
        case .internalServerError   : return "Internal Server Error"
        case .raw(_,let pharse,_,_) : return pharse
        }
    }
    
    func headers() -> [String: String] {
        var headers = [String:String]()
        headers["Server"] = "Swifter \(HttpServer.VERSION)"
        switch self {
        case .ok(let body):
            switch body {
            case .json(_)   : headers["Content-Type"] = "application/json"
            case .plist(_)  : headers["Content-Type"] = "application/xml"
            case .xml(_)    : headers["Content-Type"] = "application/xml"
                // 'application/xml' vs 'text/xml'
                // From RFC: http://www.rfc-editor.org/rfc/rfc3023.txt - "If an XML document -- that is, the unprocessed, source XML document -- is readable by casual users,
                // text/xml is preferable to application/xml. MIME user agents (and web user agents) that do not have explicit
                // support for text/xml will treat it as text/plain, for example, by displaying the XML MIME entity as plain text.
                // Application/xml is preferable when the XML MIME entity is unreadable by casual users."
            case .html(_)   : headers["Content-Type"] = "text/html"
            default: break
            }
        case .movedPermanently(let location): headers["Location"] = location
        case .raw(_,_, let rawHeaders,_):
            if let rawHeaders = rawHeaders {
                for (k, v) in rawHeaders {
                    headers.updateValue(v, forKey: k)
                }
            }
        default: break
        }
        return headers
    }
    
    func body() -> Data? {
        switch self {
        case .ok(let body)          : return body.data()?.data(using: String.Encoding.utf8, allowLossyConversion: false)
        case .raw(_,_,_, let data)  : return data
        default                     : return nil
        }
    }
}

/**
Makes it possible to compare handler responses with '==', but
ignores any associated values. This should generally be what
you want. E.g.:

let resp = handler(updatedRequest)
if resp == .NotFound {
print("Client requested not found: \(request.url)")
}
*/

func ==(inLeft: HttpResponse, inRight: HttpResponse) -> Bool {
    return inLeft.statusCode() == inRight.statusCode()
}
