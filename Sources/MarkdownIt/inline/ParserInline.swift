import Foundation

public class ParserInline {

    func parse(_ tokens: [Token]) -> [Token] {
        var tokens = tokens
        for (i, var token) in tokens.enumerated() where token.type == "inline" {
            var state = StateInline(tokens: token.children)
            var source = Source<Cursors.Character>(token.content)

            while !source.isEmpty {
                state.pending += String(source.consume())
            }

            if !state.pending.isEmpty {
                state.pushPending()
            }
            token.children = state.tokens
            tokens[i] = token
        }
        return tokens
    }
}
