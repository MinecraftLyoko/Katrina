
import SwiftZlib
import Foundation

// extension NSData {
//   func zlibInflate() -> NSData? {
//     if length == 0 { return self }
//
//     let fullLength = length
//     let halfLength = length / 2
//
//     var decompressed = NSMutableData(length: fullLength + halfLength)
//     var done = false
//     var status = -1
//     var stream = z_stream()
//
//
//     stream.next_in = UnsafeMutablePointer<Bytef>(bytes)
//     stream.avail_in = UInt32(length)
//     stream.total_out = 0
//     stream.zalloc = nil
//     stream.zfree = nil
//
//     guard inflateInit_(&stream, ZLIB_VERSION, z_stream.si) == Z_OK else { return nil }
//
//     return nil
//   }
//
//   func zlibDeflate() -> NSData? {
//     return nil
//   }
//
//   func gzipInflate() -> NSData? {
//     return nil
//   }
//
//   func gzipDeflate() -> NSData? {
//     return nil
//   }
// }
