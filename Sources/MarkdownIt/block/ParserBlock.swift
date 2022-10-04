import Foundation

private let _rules: [Rule<StateBlock>] = [
    .init(name: "hr", alias: ["paragraph", "reference", "blockquote", "list"], body: Rule.horizontalRule),
    .init(name: "heading", alias: ["paragraph", "reference", "blockquote"], body: Rule.heading),
    .init(name: "paragraph", body: Rule.paragraph)
]

struct ParserBlock {
    var ruler = Ruler<StateBlock>(rules: _rules)

    init() {}

    func callAsFunction(_ source: Substring, md: MarkdownIt, tokens: inout [Token]) {
        var state = StateBlock(source: source, md: md)
        tokenize(state: &state)
        tokens = state.tokens
    }

    func tokenize(state: inout StateBlock, from startIndex: Int = 0) {
        let rules = ruler.rules(for: "")
        let endIndex = state.lines.endIndex

        var index = startIndex
        while index < endIndex {
            state.cursor = index
            
            let line = state.lines[index]
            if line.isEmpty {
                index += 1
                continue
            }

            if line.spaces < state.blockIndent {
                break
            }

            func applyRules() -> Bool {
                let cursor = state.cursor
                for rule in rules {
                    let ok = rule.body(&state, index)
                    if ok {
                        precondition(state.cursor != cursor,
                                    "block rule didn't increment state.cursor")
                        return true
                    }
                }
                return false
            }

            let ok = applyRules()
            assert(ok, "none of the block rules matched")

            index = state.cursor
        }
    }
}
