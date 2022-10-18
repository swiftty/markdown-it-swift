import Foundation

// MARK: - token
public struct Token {
    public enum Depth: Equatable {
        case opening(String), closing(String), inline(String)
    }
    public var type: String { depth.type }
    public var depth: Depth
    public var level: Int

    public var block = false

    public var content = ""
    public var markup = ""

    public var children: [Token] = []
}

extension Token.Depth {
    var level: Int {
        switch self {
        case .opening: return 1
        case .closing: return -1
        case .inline: return 0
        }
    }

    var type: String {
        switch self {
        case .opening(let name): return "\(name)_open"
        case .closing(let name): return "\(name)_close"
        case .inline(let name): return name
        }
    }
}
