import Foundation

extension Rule<BlockState> {
    static var paragraph: Body {
        return { lines, state in
            let terminatorRules = state.ruler.rules(for: "paragraph")

            var ranges: [Range<Substring.Index>] = []
            while !lines.isEmpty {
                var line = lines.peek()

                guard !line.isEmpty else { break }

                ranges.append(line.range)
                defer { lines.consume() }

                if line.shouldBeCodeBlock(on: state.blockIndent) {
                    continue
                }

                func isTerminated() -> Bool {
                    var lines = lines
                    var state = state
                    for rule in terminatorRules {
                        if rule.body(&lines, &state) {
                            return true
                        }
                    }
                    return false
                }

                if isTerminated() {
                    break
                }
            }

            let content = lines.string(from: ranges).trimmed()

            state.push("paragraph_open", nesting: .opening)
            state.push("inline", nesting: .closing(self: true)) { token in
                token.content = content
            }
            state.push("paragraph_close", nesting: .closing())

            return true
        }
    }
}
