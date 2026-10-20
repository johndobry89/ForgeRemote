import XCTest
import CoreGraphics
@testable import ForgeRemote

/// Captures real CGEvents without posting to the runner's desktop. This verifies
/// HostModel's cleanup boundary, not ScreenCaptureKit or OS acceptance of input.
final class SessionCleanupTests: XCTestCase {
    private func command(_ value: String) throws -> Command {
        try JSONDecoder().decode(Command.self, from: Data(value.utf8))
    }
    @MainActor private func exerciseEnding(stopLocally: Bool) throws {
        var events: [CGEvent] = []
        let input = InputController(permission: { true }, post: { events.append($0) })
        let store = try DeviceStore(load: { [] }, write: { _ in })
        let host = HostModel(input: input, deviceStore: store, startMonitor: false)
        input.apply(try command(#"{"type":"key","code":55,"down":true}"#))
        input.apply(try command(#"{"type":"key","code":8,"down":true}"#))
        for button in [0, 1] {
            input.apply(try command("{\"type\":\"pointer\",\"x\":0.5,\"y\":0.5,\"action\":\"down\",\"button\":\(button),\"epoch\":1}"))
        }
        events.removeAll()
        if stopLocally { host.stopLocally() } else { host.endSession("Disconnected") }
        // Cleanup is synchronous, before socket/capture shutdown can suspend.
        XCTAssertEqual(events.map(\.type), [.leftMouseUp, .rightMouseUp, .keyUp, .flagsChanged])
        XCTAssertEqual(events[2].getIntegerValueField(.keyboardEventKeycode), 8)
        XCTAssertEqual(events[3].getIntegerValueField(.keyboardEventKeycode), 55)
        XCTAssertFalse(events[3].flags.contains(.maskCommand))
        XCTAssertEqual(host.accepting, !stopLocally)
        host.endSession("Repeated teardown")
        XCTAssertEqual(events.count, 4)
    }
    @MainActor func testDisconnectCleanupBoundaryReleasesAllInputSynchronously() throws {
        try exerciseEnding(stopLocally: false)
    }
    @MainActor func testLocalSessionStopReleasesAllInputAndBlocksReconnect() throws {
        try exerciseEnding(stopLocally: true)
    }
}
