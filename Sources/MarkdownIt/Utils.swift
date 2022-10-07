import Foundation

prefix func ! <T>(lhs: KeyPath<T, Bool>) -> (T) -> Bool {
    return {
        !$0[keyPath: lhs]
    }
}

func && <T>(lhs: @escaping (T) -> Bool, rhs: @escaping (T) -> Bool) -> (T) -> Bool {
    return {
        lhs($0) && rhs($0)
    }
}

func || <T>(lhs: @escaping (T) -> Bool, rhs: @escaping (T) -> Bool) -> (T) -> Bool {
    return {
        lhs($0) || rhs($0)
    }
}

extension StringProtocol {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Substring {
    mutating func trim(after predicate: (Character) -> Bool) {
        while let last, predicate(last) {
            _ = popLast()
        }
    }
}
