import Foundation

public class ParserBlock {
    let ruler = Ruler<Cursors.Line, BlockState>(rules: [
        .init(name: "hr", terminates: ["paragraph", "reference", "blockquote", "list"],
              body: Rule.horizontalRule),
        .init(name: "heading", terminates: ["paragraph", "reference", "blockquote"],
              body: Rule.heading),
        .init(name: "paragraph", body: Rule.paragraph)
    ])

    func parse(_ source: Source<Cursors.Line>) -> [Token] {
        let rules = ruler.rules(for: "")

        var source = source
        var state = BlockState(ruler: ruler)
        while !source.isEmpty {
            let line = source.peek()
            if line.isEmpty {
                source.consume()
                continue
            }

            func applyRules() -> Bool {
                let cursor = source.cursor
                for rule in rules {
                    let ok = rule.body(&source, &state)
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

        return Array(state.tokens)
    }
}
