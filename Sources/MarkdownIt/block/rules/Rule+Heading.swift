import Foundation

extension Rule<Cursors.Line, StateBlock> {
    public static var heading: Body {
        return { lines, state in
            var line = lines.peek()

            guard !line.shouldBeCodeBlock(on: state.blockIndent) else { return false }
            guard line.consume() == "#" else { return false }

            var level = 1
            while line.peek() == "#" {
                level += 1
                line.consume()
                if level > 6 {
                    return false
                }
            }

            guard line.consume().isSpace else { return false }

            // Let's cut tails like '    ###  ' from the end of string
            var content = line.content
            content.trim(after: \.isWhitespace)
            content.trim(after: { $0 == "#" })

            lines.consume()

            let markup = String(repeating: "#", count: level)
            state.tokens.push("heading_open", nesting: .opening) { token in
                token.markup = markup
            }
            state.tokens.push("inline", nesting: .closing(self: true)) { token in
                token.content = String(content)
            }
            state.tokens.push("heading_close", nesting: .closing()) { token in
                token.markup = markup
            }

            return true
        }
    }
}
