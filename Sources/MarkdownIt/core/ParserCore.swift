import Foundation

private let _rules: [Rule<StateCore>] = [
    .init(name: "block", body: Rule.block),
    .init(name: "inline", body: Rule.inline)
]

struct ParserCore {
    var ruler = Ruler<StateCore>(rules: _rules)

    init() {}

    func callAsFunction(_ source: Substring, md: MarkdownIt, tokens: inout [Token]) {
        var state = StateCore(source: source, md: md)
        let rules = ruler.rules(for: "")
        for rule in rules {
            _ = rule.body(&state, 0)
        }

        tokens = state.tokens
    }
}
