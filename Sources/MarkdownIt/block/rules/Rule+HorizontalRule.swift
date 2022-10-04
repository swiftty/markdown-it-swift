import Foundation

extension Rule where State == StateBlock {
    public static var horizontalRule: Body {
        return { state, startCursor in
            var line = state.lines[startCursor]

            guard !line.shouldBeCodeBlock(on: state.blockIndent) else { return false }

            line.normalize()

            let marker = line.consume()
            guard ["*", "-", "_"].contains(marker) else { return false }

            // markers can be mixed with spaces, but there should be at least 3 of them
            var cnt = 1
            while !line.isEmpty {
                let ch = line.consume()
                guard ch.isWhitespace || ch == marker else { return false }
                cnt += ch == marker ? 1 : 0
            }

            guard cnt >= 3 else { return false }

            state.cursor = startCursor + 1

            state.push("hr", nesting: .closing(self: true)) { token in
                token.markup = .init(repeating: marker, count: cnt)
            }

            return true
        }
    }
}
