import Foundation

extension Rule where State == StateBlock {
    public static var heading: Self {
        self.init(name: "heading") { state, startCursor in
//            let line = state.lines[startCursor]
//
//            if line.spaces - state.blockIndent >= 4 {
//                return false
//            }
//
//            let text = state.string(at: line)
//            var cursor = text.startIndex
//            guard text[cursor] == "#" else { return false }
//            cursor = text.index(after: cursor)
//
//            var level = 1
//            while text[cursor] == "#" {
//                level += 1
//                cursor = text.index(after: cursor)
//                if level > 6 {
//                    return false
//                }
//            }
//            guard text[cursor]
//
//            // Let's cut tails like '    ###  ' from the end of string
//            var endCursor = text.endIndex
//
//            state.cursor = startCursor + 1
//
//            state.push("heading_open", nesting: .opening) { token in
//
//            }
//            state.push("inline", nesting: .closing(self: true)) { token in
//                token.content =
//            }


            return true
        }
    }
}
