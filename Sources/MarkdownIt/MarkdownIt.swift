import Foundation

public struct MarkdownIt {
    public func parse(_ source: String) -> [Token] {
        var source = Source(source)

        // tokenize as block
        let blockRuler = Ruler<BlockState>(rules: [
            .init(name: "hr", terminatedBy: ["paragraph", "reference", "blockquote", "list"],
                  body: Rule.horizontalRule),
            .init(name: "heading", terminatedBy: ["paragraph", "reference", "blockquote"],
                  body: Rule.heading),
            .init(name: "paragraph", body: Rule.paragraph)
        ])
        let blockRules = blockRuler.rules(for: "")
        var blockState = BlockState(ruler: blockRuler)
        var lines = source.lines()
        while !lines.isEmpty {
            let line = lines.peek()
            if line.isEmpty {
                lines.consume()
                continue
            }

            func applyRules() -> Bool {
                let cursor = lines.cursor
                for rule in blockRules {
                    let ok = rule.body(&lines, &blockState)
                    if ok {
                        precondition(lines.cursor != cursor,
                                    "block rule didn't increment state.cursor")
                        return true
                    }
                }
                return false
            }

            let ok = applyRules()
            assert(ok, "none of the block rules matched")
            if !ok {
                lines.consume()
            }
        }

        var tokens = blockState.tokens

        // tokenize inline elements
        for (i, var token) in tokens.enumerated() where token.type == "inline" {
            var state = InlineState(tokens: token.children)
            var source = Source(token.content)

            while !source.isEmpty {
                state.pending += String(source.consume())
            }

            if !state.pending.isEmpty {
                state.pushPending()
            }
            token.children = state.tokens
            tokens[i] = token
        }

        // finalize
        return tokens
    }
}
