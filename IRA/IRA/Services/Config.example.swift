import Foundation
// Example config – real keys per ENV (Xcode Scheme → Environment Variables)
let ANTHROPIC_API_KEY = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
