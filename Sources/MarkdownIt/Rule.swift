import Foundation

// MARK: -
/// namespace
public enum Rules {}

// MARK: -
public protocol NewRule<Input>: CustomDebugStringConvertible {
    associatedtype Input
    associatedtype Context

    typealias Terminator<I> = (NewState<I>) -> Bool

    static var defaultContext: Context { get }

    var name: String { get }
    var isEnabled: Bool { get set }

    @discardableResult
    func apply(state: inout NewState<Input>, terminates: Terminator<Input>?) -> Bool
}

extension NewRule where Context == Never {
    public static var defaultContext: Context { fatalError() }
}

extension NewRule {
    public var debugDescription: String {
        #"Rule { name: "\#(name)", enable: \#(isEnabled) }"#
    }
}

extension NewRule {
    @discardableResult
    public func callAsFunction<I>(state: inout NewState<I>, terminates: Terminator<I>? = nil) -> Bool {
        guard var _state = state as? NewState<Input> else { return false }
        let ret = apply(state: &_state, terminates: terminates == nil ? nil : { state in
            guard let s = state as? NewState<I> else { return false }
            return terminates?(s) ?? false
        })
        state = _state as! NewState<I>
        return ret
    }
}

public struct RuleGraph {
    private var _rules: [(rule: any NewRule, terminates: [any NewRule.Type])] = []

    private var cache: [ObjectIdentifier?: [any NewRule]]?

    public init(rules: [(rule: any NewRule, terminates: [any NewRule.Type])]) {
        _rules = rules
    }

    public mutating func rules() -> [any NewRule] {
        if cache == nil {
            compile()
        }
        return cache?[nil] ?? []
    }

    public mutating func rules<R>(for rule: R.Type) -> [any NewRule] {
        if cache == nil {
            compile()
        }
        return cache?[ObjectIdentifier(rule)] ?? []
    }

    private mutating func compile() {
        cache = [:]
        var chains: Set<ObjectIdentifier?> = [nil]
        for (_, terminates) in _rules {
            chains.formUnion(terminates.lazy.map(ObjectIdentifier.init))
        }
        for chain in chains {
            for (rule, terminates) in _rules {
                guard rule.isEnabled else { continue }
                guard chain == nil || terminates.lazy.map(ObjectIdentifier.init).contains(chain) else { continue }
                cache?[chain, default: []].append(rule)
            }
        }
    }
}

public struct NewState<Input> {
    public var input: Input
    public var tokens: [Token]

    public let md: MarkdownIt

    public var indent = 0
    public var level = 0

    public subscript <R>(rule: R.Type) -> R.Context where R: NewRule {
        get {
            if let context = contexts[ObjectIdentifier(rule)] as? R.Context {
                return context
            }
            return rule.defaultContext
        }
        set {
            contexts[ObjectIdentifier(rule)] = newValue
        }
    }

    private var contexts: [ObjectIdentifier: Any] = [:]

    init(input: Input, tokens: [Token], md: MarkdownIt) {
        self.input = input
        self.tokens = tokens
        self.md = md
    }
}

private func foo() {
    struct Block: NewRule {
        var name: String { "block" }
        var isEnabled: Bool = true

        typealias Input = Source<Cursors.Line>
        typealias Context = Never
        func apply(state: inout NewState<Input>, terminates: Terminator<Input>?) -> Bool {
            true
        }
    }
    struct Block2: NewRule {
        var name: String { "block" }
        var isEnabled: Bool = true

        typealias Input = Source<Cursors.Line>
        typealias Context = Never
        func apply(state: inout NewState<Input>, terminates: Terminator<Input>?) -> Bool {
            true
        }
    }

    RuleGraph(rules: [
        (Block(), []),
        (Block2(), [Block.self])
    ])
}

public struct Rule<Cursor, State> {
    public typealias Body = (inout Source<Cursor>, inout State) -> Bool

    public var name: String
    public var terminates: Set<String> = []
    public var isEnabled: Bool = true
    public var body: Body
}

public struct Ruler<Cursor, State> {
    private var rules: [String: [Rule<Cursor, State>]] = [:]

    init(rules ruleList: [Rule<Cursor, State>]) {
        var chains: Set<String> = [""]
        ruleList.forEach {
            chains.formUnion($0.terminates)
        }

        for chain in chains {
            for rule in ruleList {
                guard rule.isEnabled else { continue }
                guard chain.isEmpty || rule.terminates.contains(chain) else { continue }
                rules[chain, default: []].append(rule)
            }
        }
    }

    public func rules(for name: String) -> [Rule<Cursor, State>] {
        return rules[name] ?? []
    }
}

