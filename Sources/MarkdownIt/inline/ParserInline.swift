import Foundation

public class ParserInline {
    let ruler = RuleSet(rules: [
        Rules.Newline()
    ])

    func parse(_ tokens: [Token], md: MarkdownIt) -> [Token] {
        let rules = ruler.rules()
        var tokens = tokens
        for (i, var token) in tokens.enumerated() where token.type == "inline" {
            var state = State(input: Source<Cursors.Character>(token.content), tokens: token.children, md: md)

            while !state.input.isEmpty {
                func applyRules() -> Bool {
                    let cursor = state.input.cursor
                    for rule in rules {
                        let ok = rule(state: &state)
                        if ok {
                            precondition(state.input.cursor != cursor,
                                         "inline rule didn't increment state.cursor")
                            return true
                        }
                    }
                    return false
                }

                let ok = applyRules()
                if ok && state.input.isEmpty {
                    continue
                }

                state.inline.pending += String(state.input.consume())
            }

            state.pushPendingIfNeeded()
            token.children = Array(state.tokens)
            tokens[i] = token
        }
        return tokens
    }
}
