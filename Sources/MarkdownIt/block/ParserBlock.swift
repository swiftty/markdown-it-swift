import Foundation

private extension NewRule {
    func terminates(to values: [any NewRule.Type]) -> (Self, [any NewRule.Type]) {
        return (self, values)
    }
}

public class ParserBlock {
    let ruler = Ruler<Cursors.Line, StateBlock>(rules: [
        .init(name: "fence", terminates: ["paragraph", "reference", "blockquote", "list"],
              body: Rule.fence),
        .init(name: "hr", terminates: ["paragraph", "reference", "blockquote", "list"],
              body: Rule.horizontalRule),
        .init(name: "heading", terminates: ["paragraph", "reference", "blockquote"],
              body: Rule.heading),
        .init(name: "paragraph", body: Rule.paragraph)
    ])

    public var ruleGraph = RuleGraph(rules: [
        Rules.Fence().terminates(to: [
            Rules.Paragraph.self]),
        Rules.HorizontalRule().terminates(to: [
            Rules.Paragraph.self]),
        Rules.Heading().terminates(to: [
            Rules.Paragraph.self]),
        Rules.Paragraph().terminates(to: [])
    ])

    public func tokenize(state: inout NewState<Source<Cursors.Line>>) -> [Token] {
        let rules = ruleGraph.rules()

        while !state.input.isEmpty {
            let line = state.input.peek()
            if line.isEmpty {
                state.input.consume()
                continue
            }

            func applyRules() -> Bool {
                let cursor = state.input.cursor
                for rule in rules {
                    let ok = rule(state: &state)
                    if ok {
                        precondition(state.input.cursor != cursor,
                                     "block rule didn't increment state.cursor")
                        return true
                    }
                }
                return false
            }

            let ok = applyRules()
            assert(ok, "none of the block rules matched")
            if !ok {
                state.input.consume()
            }
        }

        return Array(state.tokens)
    }

    public func parse(_ source: Source<Cursors.Line>, md: MarkdownIt) -> [Token] {
        var state = NewState(input: source, tokens: [], md: md)
        return tokenize(state: &state)
    }
}
