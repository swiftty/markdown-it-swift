import XCTest
@testable import MarkdownIt

private func parse(_ source: String) -> [Token] {
    let md = MarkdownIt()
    return md.parse(source)
}

class StateBlockTests: XCTestCase {
    func test_state() {
        func state(_ source: String) -> StateBlock {
            StateBlock(source: source[...], md: MarkdownIt())
        }

        let state1 = state("""
        abcdef
        ghijkl

        end
        """)
        XCTAssertEqual(state1.lines.map(\.string), [
            "abcdef",
            "ghijkl",
            "",
            "end"
        ])

        let state2 = state("""
        \tabc
          def
          \

        """)
        XCTAssertEqual(state2.lines[0].indent, 1)
        XCTAssertEqual(state2.lines[0].spaces, 4)
        XCTAssertEqual(state2.lines[1].indent, 2)
        XCTAssertEqual(state2.lines[1].spaces, 2)
        XCTAssertEqual(state2.lines[1].isEmpty, false)
        XCTAssertEqual(state2.lines[2].indent, 2)
        XCTAssertEqual(state2.lines[2].isEmpty, true)
    }

    func test_paragraph() {
        let tokens = parse("""
        abcdef
        ghijkl

        end
        """)

        XCTAssertEqual(tokens.map(\.type), [
            "paragraph_open",
            "inline",
            "paragraph_close",
            "paragraph_open",
            "inline",
            "paragraph_close"
        ])
    }

    func test_heading() {
        let tokens = parse("""
        # title
          ## subtitle
        """)

        XCTAssertEqual(tokens.map(\.type), [
            "heading_open",
            "inline",
            "heading_close",
            "heading_open",
            "inline",
            "heading_close"
        ])
    }

    func test_hr() {
        let tokens = parse("""
        - -  -
        """)

        XCTAssertEqual(tokens.map(\.type), ["hr"])
        XCTAssertEqual(tokens.first?.markup, "---")
    }
}
