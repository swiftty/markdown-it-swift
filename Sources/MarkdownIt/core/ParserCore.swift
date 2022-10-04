import Foundation

private let _rules: [Rule<StateCore>] = [
    .init(name: "block", body: Rule.block)
]

struct ParserCore {
    var ruler = Ruler<StateCore>(rules: _rules)

    init() {}

    func callAsFunction(_ state: inout StateCore) {
        let rules = ruler.rules(for: "")
        for rule in rules {
            _ = rule.body(&state, 0)
        }
    }
}
