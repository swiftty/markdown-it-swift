import Foundation

private extension Rule {
    func terminates(to values: [any Rule.Type]) -> (Self, [any Rule.Type]) {
        return (self, values)
    }
}

public class ParserBlock {
    public var ruler = RuleGraph(rules: [
        Rules.Fence().terminates(to: [
            Rules.Paragraph.self]),
        Rules.HorizontalRule().terminates(to: [
            Rules.Paragraph.self]),
        Rules.Heading().terminates(to: [
            Rules.Paragraph.self]),
        Rules.Paragraph().terminates(to: [])
    ])

    public func tokenize(state: inout State<Source<Cursors.Line>>,
                         terminates: ((State<Source<Cursors.Line>>) -> Bool)? = nil) -> [Token] {
        let rules = ruler.rules()

        while !state.input.isEmpty {
            let line = state.input.peek()
            if line.isEmpty {
                state.input.consume()
                continue
            }

            func applyRules() -> Bool {
                let cursor = state.input.cursor
                for rule in rules {
                    var newState = state
                    let ok = rule(state: &newState, terminates: terminates)
                    if ok {
                        precondition(newState.input.cursor != cursor,
                                     "block rule didn't increment state.cursor")
                        state = newState
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
        var state = State(input: source, tokens: [], md: md)
        return tokenize(state: &state)
    }
}
