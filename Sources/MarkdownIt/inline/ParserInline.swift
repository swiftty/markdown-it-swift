import Foundation

public class ParserInline {
    let ruler = Ruler<Cursors.Character, StateInline>(rules: [
        .init(name: "newline", body: Rule.newline)
    ])

    func parse(_ tokens: [Token]) -> [Token] {
        let rules = ruler.rules(for: "")
        var tokens = tokens
        for (i, var token) in tokens.enumerated() where token.type == "inline" {
            var state = StateInline(tokens: token.children)
            var source = Source<Cursors.Character>(token.content)

            while !source.isEmpty {
                func applyRules() -> Bool {
                    let cursor = source.cursor
                    for rule in rules {
                        let ok = rule.body(&source, &state)
                        if ok {
                            precondition(source.cursor != cursor,
                                         "inline rule didn't increment state.cursor")
                            return true
                        }
                    }
                    return false
                }

                let ok = applyRules()
                if ok && source.isEmpty {
                    continue
                }

                state.pending += String(source.consume())
            }

            if !state.pending.isEmpty {
                state.pushPending()
            }
            token.children = Array(state.tokens)
            tokens[i] = token
        }
        return tokens
    }
}
