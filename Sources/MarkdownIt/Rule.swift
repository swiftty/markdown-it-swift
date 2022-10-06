import Foundation

public struct Rule<State> {
    public typealias Body = (inout Source.Lines, inout State) -> Bool

    public var name: String
    public var terminatedBy: Set<String> = []
    public var isEnabled: Bool = true
    public var body: Body
}

public struct Ruler<State> {
    private var rules: [String: [Rule<State>]] = [:]

    init(rules ruleList: [Rule<State>]) {
        var chains: Set<String> = [""]
        ruleList.forEach {
            chains.formUnion($0.terminatedBy)
        }

        for chain in chains {
            for rule in ruleList {
                guard rule.isEnabled else { continue }
                guard chain.isEmpty || rule.terminatedBy.contains(chain) else { continue }
                rules[chain, default: []].append(rule)
            }
        }
    }

    public func rules(for name: String) -> [Rule<State>] {
        return rules[name] ?? []
    }
}

