import Foundation

public struct MarkdownIt {
    public let block = ParserBlock()

    public let inline = ParserInline()

    public func parse(_ source: String) -> [Token] {
        var tokens = block.parse(.init(source), md: self)
        tokens = inline.parse(tokens)

        return tokens
    }
}
