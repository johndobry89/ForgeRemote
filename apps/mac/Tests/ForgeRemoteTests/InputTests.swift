import XCTest
import CoreGraphics
@testable import ForgeRemote

final class InputTests: XCTestCase {
    private func command(_ value: String) throws -> Command { try JSONDecoder().decode(Command.self, from: Data(value.utf8)) }
    @MainActor func testDisconnectReleasesTrackedModifierAndButton() throws {
        var events: [CGEvent] = []
        let input = InputController(permission: { true }, post: { events.append($0) })
        input.bounds = CGRect(x: 100,y: 200,width: 1000,height: 500)
        input.apply(try command(#"{"type":"key","code":55,"down":true}"#))
        input.apply(try command(#"{"type":"pointer","x":0.5,"y":0.5,"action":"down","button":0,"epoch":1}"#))
        XCTAssertEqual(events.count,2)
        XCTAssertTrue(events.last?.flags.contains(.maskCommand) == true)
        XCTAssertEqual(events.last?.location.x,599.5)
        XCTAssertEqual(events.last?.location.y,449.5)
        input.releaseAll()
        XCTAssertEqual(events.filter { $0.type == .keyUp }.count,1)
        XCTAssertEqual(events.filter { $0.type == .leftMouseUp }.count,1)
        let count = events.count
        input.releaseAll(); XCTAssertEqual(events.count,count)
    }
    @MainActor func testPermissionLossReleasesWithoutApplyingNewInput() throws {
        var permitted = true
        var events: [CGEvent] = []
        let input = InputController(permission: { permitted }, post: { events.append($0) })
        input.apply(try command(#"{"type":"key","code":56,"down":true}"#))
        permitted = false
        input.apply(try command(#"{"type":"key","code":55,"down":true}"#))
        XCTAssertEqual(events.map(\.type),[.keyDown,.keyUp])
    }
}
