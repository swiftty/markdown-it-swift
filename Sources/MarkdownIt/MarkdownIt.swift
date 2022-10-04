import Foundation

public struct MarkdownIt {
    var inline = ParserInline()

    var core = ParserCore()

    var block = ParserBlock()

    public func parse(_ source: String) -> [Token] {
        var tokens: [Token] = []
        core(source[...], md: self, tokens: &tokens)
        return tokens
    }
}
