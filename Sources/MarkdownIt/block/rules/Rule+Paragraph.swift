import Foundation

extension Rule<Cursors.Line, StateBlock> {
    public static var paragraph: Body {
        return { lines, state in
            let startIndex = lines.consume().cursor.index
            var endIndex = lines.cursor.endIndex

            while !lines.isEmpty {
                endIndex = lines.cursor.endIndex

                var line = lines.consume()
                guard !line.isEmpty else { break }

                if line.shouldBeCodeBlock(on: state.blockIndent) {
                    continue
                }

                if state.terminate("paragraph", source: lines) {
                    break
                }
            }

            let content = lines.content(in: startIndex..<endIndex).trimmed()

            state.tokens.push("paragraph_open", nesting: .opening)
            state.tokens.push("inline", nesting: .closing(self: true)) { token in
                token.content = content
            }
            state.tokens.push("paragraph_close", nesting: .closing())

            return true
        }
    }
}
