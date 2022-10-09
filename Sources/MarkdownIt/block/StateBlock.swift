import Foundation

public struct StateBlock {
    public var blockIndent = 0

    public var ruler: Ruler<Cursors.Line, StateBlock>

    public var tokens = Tokens()
}

extension StateBlock {
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
