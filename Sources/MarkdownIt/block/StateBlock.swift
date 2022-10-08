import Foundation

struct BlockState {
    var blockIndent = 0

    var ruler: Ruler<Cursors.Line, BlockState>

    var tokens = Tokens()
}

extension BlockState {
    func terminate(_ name: String, source: Source<Cursors.Line>) -> Bool {
        var source = source
        var state = self
        for rule in ruler.rules(for: name) {
            if rule.body(&source, &state) {
                return true
            }
        }
        return false
    }
}
