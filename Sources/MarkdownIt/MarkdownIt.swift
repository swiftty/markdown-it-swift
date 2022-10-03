import Foundation

public struct MarkdownIt {
    var core = ParserCore()

    var block = ParserBlock()

    public func parse(_ source: String) -> [Token] {
        var state = StateCore(source: source[...], md: self)
        core(&state)
        return state.tokens
    }
}
