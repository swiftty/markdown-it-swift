import Foundation

extension Rule<Cursors.Line, StateBlock> {
    public static var horizontalRule: Body {
        return { lines, state in
            var line = lines.peek()

            guard !line.shouldBeCodeBlock(on: state.blockIndent) else { return false }

            let marker = line.consume()
            guard ["*", "-", "_"].contains(marker) else { return false }

            // markers can be mixed with spaces, but there should be at least 3 of them
            var cnt = 1
            while !line.isEmpty {
                let ch = line.consume()
                guard ch.isSpace || ch == marker else { return false }
                cnt += ch == marker ? 1 : 0
            }

            guard cnt >= 3 else { return false }

            lines.consume()
            
            state.tokens.push("hr", nesting: .closing(self: true)) { token in
                token.markup = .init(repeating: marker, count: cnt)
            }

            return true
        }
    }
}
