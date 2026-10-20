import XCTest
import CoreGraphics
@testable import ForgeRemote

final class InputTests: XCTestCase {
    private let modifierMask: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]
    private func command(_ value: String) throws -> Command {
        try JSONDecoder().decode(Command.self, from: Data(value.utf8))
    }
    private func key(_ code: Int, down: Bool) throws -> Command {
        try command("{\"type\":\"key\",\"code\":\(code),\"down\":\(down)}")
    }
    private func pointer(button: Int, action: String) throws -> Command {
        try command("{\"type\":\"pointer\",\"x\":0.5,\"y\":0.5,\"action\":\"\(action)\",\"button\":\(button),\"epoch\":1}")
    }
    private func assertKey(_ event: CGEvent, code: Int, type: CGEventType, flags: CGEventFlags,
                           file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(event.type, type, file: file, line: line)
        XCTAssertEqual(event.getIntegerValueField(.keyboardEventKeycode), Int64(code), file: file, line: line)
        XCTAssertEqual(event.flags.intersection(modifierMask), flags, file: file, line: line)
    }

    @MainActor func testDisconnectReleasesTrackedModifierAndButton() throws {
        var events: [CGEvent] = []
        let input = InputController(permission: { true }, post: { events.append($0) })
        input.bounds = CGRect(x: 100, y: 200, width: 1000, height: 500)
        input.apply(try key(55, down: true))
        input.apply(try pointer(button: 0, action: "down"))
        XCTAssertEqual(events.count, 2)
        assertKey(try XCTUnwrap(events.first), code: 55, type: .flagsChanged, flags: .maskCommand)
        XCTAssertEqual(events.last?.flags.intersection(modifierMask), .maskCommand)
        XCTAssertEqual(events.last?.location.x, 599.5)
        XCTAssertEqual(events.last?.location.y, 449.5)

        input.releaseAll()
        XCTAssertEqual(events.count, 4)
        XCTAssertEqual(events[2].type, .leftMouseUp)
        XCTAssertEqual(events[2].flags.intersection(modifierMask), .maskCommand)
        assertKey(events[3], code: 55, type: .flagsChanged, flags: [])
        let count = events.count
        input.releaseAll()
        XCTAssertEqual(events.count, count, "Repeated cleanup must not post duplicate releases")
    }

    @MainActor func testPermissionLossReleasesWithoutApplyingNewInput() throws {
        var permitted = true
        var events: [CGEvent] = []
        let input = InputController(permission: { permitted }, post: { events.append($0) })
        input.apply(try key(56, down: true))
        input.apply(try key(8, down: true))
        input.apply(try pointer(button: 0, action: "down"))
        input.apply(try pointer(button: 1, action: "down"))
        let beforeLoss = events.count
        permitted = false
        input.apply(try key(55, down: true))

        let released = Array(events.dropFirst(beforeLoss))
        XCTAssertEqual(released.count, 4)
        XCTAssertEqual(released.map(\.type), [.leftMouseUp, .rightMouseUp, .keyUp, .flagsChanged])
        for event in released.prefix(3) {
            XCTAssertEqual(event.flags.intersection(modifierMask), .maskShift)
        }
        assertKey(released[2], code: 8, type: .keyUp, flags: .maskShift)
        assertKey(released[3], code: 56, type: .flagsChanged, flags: [])
        let count = events.count
        input.apply(try pointer(button: 0, action: "down"))
        input.releaseAll()
        XCTAssertEqual(events.count, count, "Permission loss must block new input and empty tracked state")
    }

    @MainActor func testAllModifiersReleaseAfterButtonsAndOrdinaryKeys() throws {
        var events: [CGEvent] = []
        let input = InputController(permission: { true }, post: { events.append($0) })
        for code in [59, 8, 56, 0, 58, 55] { input.apply(try key(code, down: true)) }
        for button in [1, 0] { input.apply(try pointer(button: button, action: "down")) }
        events.removeAll()
        input.releaseAll()

        XCTAssertEqual(events.count, 8)
        XCTAssertEqual(events.map(\.type), [.leftMouseUp, .rightMouseUp, .keyUp, .keyUp,
                                           .flagsChanged, .flagsChanged, .flagsChanged, .flagsChanged])
        XCTAssertEqual(events[0].flags.intersection(modifierMask), modifierMask)
        XCTAssertEqual(events[1].flags.intersection(modifierMask), modifierMask)
        assertKey(events[2], code: 0, type: .keyUp, flags: modifierMask)
        assertKey(events[3], code: 8, type: .keyUp, flags: modifierMask)
        assertKey(events[4], code: 55, type: .flagsChanged, flags: [.maskShift, .maskAlternate, .maskControl])
        assertKey(events[5], code: 56, type: .flagsChanged, flags: [.maskAlternate, .maskControl])
        assertKey(events[6], code: 58, type: .flagsChanged, flags: .maskControl)
        assertKey(events[7], code: 59, type: .flagsChanged, flags: [])
        input.releaseAll()
        XCTAssertEqual(events.count, 8)
    }

    @MainActor func testExplicitModifierUpAndOrdinaryKeyUpHaveDifferentEventTypes() throws {
        for (code, flag) in [(55, CGEventFlags.maskCommand), (56, .maskShift), (58, .maskAlternate), (59, .maskControl)] {
            var events: [CGEvent] = []
            let input = InputController(permission: { true }, post: { events.append($0) })
            input.apply(try key(code, down: true))
            input.apply(try key(code, down: false))
            XCTAssertEqual(events.count, 2)
            assertKey(events[0], code: code, type: .flagsChanged, flags: flag)
            assertKey(events[1], code: code, type: .flagsChanged, flags: [])
            input.apply(try key(8, down: true))
            input.apply(try key(8, down: false))
            assertKey(events[2], code: 8, type: .keyDown, flags: [])
            assertKey(events[3], code: 8, type: .keyUp, flags: [])
            input.releaseAll()
            XCTAssertEqual(events.count, 4)
        }
    }

    @MainActor func testCleanupDoesNotLeakModifiersOrDragIntoNextSession() throws {
        var events: [CGEvent] = []
        let input = InputController(permission: { true }, post: { events.append($0) })
        input.apply(try key(55, down: true))
        input.apply(try pointer(button: 0, action: "down"))
        input.releaseAll()
        input.apply(try pointer(button: 0, action: "move"))
        XCTAssertEqual(events.last?.type, .mouseMoved)
        XCTAssertEqual(events.last?.flags.intersection(modifierMask), [])
        input.apply(try key(8, down: true))
        assertKey(try XCTUnwrap(events.last), code: 8, type: .keyDown, flags: [])
        input.releaseAll()
    }
}
