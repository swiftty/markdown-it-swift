import Foundation

extension Rule where State == StateBlock {
    public static var paragraph: Self {
        self.init(name: "paragraph") { state, startCursor in
            let terminatorRules = state.md.block.ruler.rules(for: "paragraph")

            let oldParentType = state.parentType
            state.parentType = "paragraph"
            defer { state.parentType = oldParentType }

            var endCursor = startCursor + 1
            for cursor in state.lines.indices.dropFirst(endCursor) {
                endCursor = cursor
                let line = state.lines[cursor]
                if line.isEmpty {
                    break
                }
                if line.spaces - state.blockIndent > 3 {
                    continue
                }

                if line.spaces < 0 {
                    continue
                }

                var terminate = false
                for rule in terminatorRules {
                    if rule.body(&state, cursor) {
                        terminate = true
                        break
                    }
                }
                if terminate {
                    break
                }
            }

            let content = state.string(in: startCursor..<endCursor, indent: state.blockIndent)
            state.cursor = endCursor

            state.push("paragraph_open", nesting: .opening) { token in

            }
            state.push("inline", nesting: .closing(self: true)) { token in
                token.content = content
            }
            state.push("paragraph_close", nesting: .closing())

            return true
        }
    }
}
