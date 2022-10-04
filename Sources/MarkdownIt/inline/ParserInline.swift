import Foundation

public struct ParserInline {
    init() {}

    func callAsFunction(_ source: Substring, md: MarkdownIt, tokens: inout [Token]) {
        var state = StateInline(source: source, md: md, tokens: tokens)
        tokenize(state: &state)
        tokens = state.tokens
    }

    func tokenize(state: inout StateInline) {
        while !state.line.isEmpty {
            state.pending += String(state.line.consume())
        }

        if !state.pending.isEmpty {
            state.pushPending()
        }
    }
}
