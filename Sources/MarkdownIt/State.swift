import Foundation

public protocol StateContext {
    associatedtype Context

    static var defaultValue: Context { get }
}

extension StateContext where Context == Never {
    public static var defaultValue: Context { fatalError() }
}

public struct State<Input> {
    public var input: Input
    public var tokens: [Token]

    public let md: MarkdownIt

    public subscript <C>(container: C.Type) -> C.Context where C: StateContext {
        get {
            if let context = contexts[ObjectIdentifier(container)] as? C.Context {
                return context
            }
            return container.defaultValue
        }
        set {
            contexts[ObjectIdentifier(container)] = newValue
        }
    }

    private var contexts: [ObjectIdentifier: Any] = [:]

    init(input: Input, tokens: [Token], md: MarkdownIt) {
        self.input = input
        self.tokens = tokens
        self.md = md
    }
}
