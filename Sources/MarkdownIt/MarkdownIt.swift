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


public struct NewMarkdownIt {
    public func parse(_ source: String) -> [Token] {
        var source = Source(source)

        // tokenize as block
        let blockRuler = NewRuler<BlockState>(rules: [
            .init(name: "hr", terminatedBy: ["paragraph", "reference", "blockquote", "list"],
                  body: NewRule.horizontalRule),
            .init(name: "heading", terminatedBy: ["paragraph", "reference", "blockquote"],
                  body: NewRule.heading),
            .init(name: "paragraph", body: NewRule.paragraph)
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

struct BlockState {
    var blockIndent = 0
    var level = 0

    var ruler: NewRuler<BlockState>

    var tokens: [Token] = []
}

struct InlineState {
    var tokens: [Token] = []

    var level = 0

    var pending = ""
    var pendingLevel = 0
}

extension BlockState {
    mutating func push(_ type: String, nesting: Token.Nesting,
                       _ modify: (inout Token) -> Void = { _ in }) {
        var token = Token(type: type, nesting: nesting, level: level)
        token.block = true

        level += nesting.nextLevel

        modify(&token)
        tokens.append(token)
    }
}

private extension Token.Nesting {
    var nextLevel: Int {
        switch self {
        case .opening: return 1
        case .closing(let flag): return flag ? 0 : -1
        }
    }
}

extension InlineState {
    mutating func pushPending() {
        var token = Token(type: "text", nesting: .closing(self: true), level: pendingLevel)
        token.content = pending
        tokens.append(token)
        pending = ""
    }
}
