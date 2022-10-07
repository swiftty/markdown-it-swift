import Foundation

extension Rule<Cursors.Line, BlockState> {
    static var paragraph: Body {
        return { lines, state in
            let terminatorRules = state.ruler.rules(for: "paragraph")

            let startIndex = lines.consume().cursor.index
            var endIndex = lines.cursor.endIndex

            while !lines.isEmpty {
                endIndex = lines.cursor.endIndex

                var line = lines.consume()
                guard !line.isEmpty else { break }

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

            let content = lines.content(in: startIndex..<endIndex).trimmed()

            state.push("paragraph_open", nesting: .opening)
            state.push("inline", nesting: .closing(self: true)) { token in
                token.content = content
            }
            state.push("paragraph_close", nesting: .closing())

            return true
        }
    }
}
