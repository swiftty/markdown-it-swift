import Foundation

extension Rule where State == StateCore {
    public static var block: Body {
        return { state, cursor in
            var stateBlock = StateBlock(source: state.source, md: state.md)
            state.md.block(&stateBlock)
            state.tokens = stateBlock.tokens
            return true
        }
    }
}
