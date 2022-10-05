import XCTest
@testable import MarkdownIt

private func flattenTypes(_ tokens: [Token], level: Int = 0) -> [String] {
    tokens.flatMap {
        [String(repeating: "  ", count: level) + (level > 0 ? "└ " : "") + $0.type]
        + flattenTypes($0.children, level: level + 1)
    }
}

private func parse(_ source: String) -> [Token] {
    let md = NewMarkdownIt()
    return md.parse(source)
}

class StateBlockTests: XCTestCase {
    func test_paragraph() {
        let tokens = parse("""
        abcdef
        ghijkl

        end
        """)

        XCTAssertEqual(flattenTypes(tokens), [
            "paragraph_open",
            "inline",
            "  └ text",
            "paragraph_close",
            "paragraph_open",
            "inline",
            "  └ text",
            "paragraph_close"
        ])
    }

    func test_heading() {
        let tokens = parse("""
        # title
          ## subtitle
        """)

        XCTAssertEqual(flattenTypes(tokens), [
            "heading_open",
            "inline",
            "  └ text",
            "heading_close",
            "heading_open",
            "inline",
            "  └ text",
            "heading_close"
        ])
    }

    func test_hr() {
        let tokens = parse("""
        - -  -
        """)

        XCTAssertEqual(flattenTypes(tokens), [
            "hr"
        ])
        XCTAssertEqual(tokens.first?.markup, "---")
    }
}
