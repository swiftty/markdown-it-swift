import Foundation

public struct MarkdownIt {
    public func parse(_ source: String) -> [Token] {
        var source = Source<Cursors.Line>(source)

        // tokenize as block
        let blockRuler = Ruler<Cursors.Line, BlockState>(rules: [
            .init(name: "hr", terminatedBy: ["paragraph", "reference", "blockquote", "list"],
                  body: Rule.horizontalRule),
            .init(name: "heading", terminatedBy: ["paragraph", "reference", "blockquote"],
                  body: Rule.heading),
            .init(name: "paragraph", body: Rule.paragraph)
        ])
        let blockRules = blockRuler.rules(for: "")
        var blockState = BlockState(ruler: blockRuler)
        while !source.isEmpty {
            let line = source.peek()
            if line.isEmpty {
                source.consume()
                continue
            }

            func applyRules() -> Bool {
                let cursor = source.cursor
                for rule in blockRules {
                    let ok = rule.body(&source, &blockState)
                    if ok {
                        precondition(source.cursor != cursor,
                                     "block rule didn't increment state.cursor")
                        return true
                    }
                }
                return false
            }

            let ok = applyRules()
            assert(ok, "none of the block rules matched")
            if !ok {
                source.consume()
            }
        }

        var tokens = Array(blockState.tokens)

        // tokenize inline elements
        for (i, var token) in tokens.enumerated() where token.type == "inline" {
            var state = InlineState(tokens: token.children)
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

        // finalize
        return tokens
    }
}
