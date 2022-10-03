import Foundation

extension Rule where State == StateBlock {
    public static var heading: Self {
        self.init(name: "heading", alias: ["paragraph", "reference", "blockquote"]) { state, startCursor in
            var line = state.lines[startCursor]

            if line.spaces - state.blockIndent >= 4 {
                return false
            }

            line.normalize()
            guard line.consume() == "#" else { return false }

            var level = 1
            while line.peek() == "#" {
                level += 1
                _ = line.consume()
                if level > 6 {
                    return false
                }
            }

            // Let's cut tails like '    ###  ' from the end of string
            func trim(_ condition: (Character) -> Bool) {
                while condition(line.peek(reversed: true)) {
                    _ = line.consume(reversed: true)
                }
            }

            trim(\.isWhitespace)
            trim { $0 == "#" }

            state.cursor = startCursor + 1

            let markup = String(repeating: "#", count: level)
            state.push("heading_open", nesting: .opening) { token in
                token.markup = markup
            }
            state.push("inline", nesting: .closing(self: true)) { token in
                token.content = String(line.string)
            }
            state.push("heading_close", nesting: .closing()) { token in
                token.markup = markup
            }

            return true
        }
    }
}
