import Foundation

public struct StateCore {
    public var source: Substring
    public var tokens: [Token] = []
    public var md: MarkdownIt

    public var inlineMode = false
}
