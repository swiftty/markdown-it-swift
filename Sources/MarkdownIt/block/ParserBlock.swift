import Foundation

private let _rules: [Rule<StateBlock>] = [
    .paragraph
]

struct ParserBlock {
    var ruler = Ruler<StateBlock>(rules: _rules)

    init() {}

    func callAsFunction(_ state: inout StateBlock) {
        tokenize(state: &state)
    }

    func tokenize(state: inout StateBlock, from startIndex: Int = 0) {
        let rules = ruler.rules(for: "")
        let endIndex = state.lines.endIndex

        var index = startIndex
        while index < endIndex {
            state.cursor = index
            defer { index += 1 }
            
            let line = state.lines[index]
            if line.isEmpty {
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

            index += 1
        }
    }
}