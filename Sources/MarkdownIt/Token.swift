import Foundation

public struct Token {
    public enum Nesting {
        case opening, closing(`self`: Bool = false)
    }
    public var type: String
    public var nesting: Nesting
    public var level: Int

    public var block = false

    public var content = ""
    public var markup = ""
}
