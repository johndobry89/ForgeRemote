import XCTest
@testable import ForgeRemote

final class ProtocolTests: XCTestCase {
    private func command(_ json: String) throws -> Command { try JSONDecoder().decode(Command.self, from: Data(json.utf8)) }
    func testPointerGeometryAndEpoch() throws {
        let good = try command(#"{"type":"pointer","x":0.5,"y":1,"action":"down","button":0,"epoch":2}"#)
        XCTAssertTrue(good.validate(epoch: 2)); XCTAssertFalse(good.validate(epoch: 3))
        XCTAssertFalse(try command(#"{"type":"pointer","x":-1,"y":0,"action":"down","button":0,"epoch":2}"#).validate(epoch: 2))
    }
    func testRejectUnknownAndOversizedInput() throws {
        XCTAssertFalse(try command(#"{"type":"shell","text":"id"}"#).validate(epoch: 1))
        XCTAssertFalse(try command(#"{"type":"key","code":999,"down":true}"#).validate(epoch: 1))
        XCTAssertFalse(try command(#"{"type":"scroll","dx":1001,"dy":0}"#).validate(epoch: 1))
        let text = String(repeating: "a", count: 257)
        XCTAssertFalse(try command("{\"type\":\"text\",\"text\":\"\(text)\"}").validate(epoch: 1))
    }
    func testRateAndTimeout() {
        let now = Date(); var rate = WindowRate()
        XCTAssertTrue(rate.allow(limit: 1, interval: 60, now: now))
        XCTAssertFalse(rate.allow(limit: 1, interval: 60, now: now))
        XCTAssertTrue(rate.allow(limit: 1, interval: 60, now: now.addingTimeInterval(61)))
        let clock = SessionClock(created: now, activity: now)
        XCTAssertTrue(clock.valid(now: now.addingTimeInterval(119)))
        XCTAssertFalse(clock.valid(now: now.addingTimeInterval(121)))
    }
    func testDeviceTokenAndRevocation() throws {
        let token = try DeviceStore.randomToken(), other = try DeviceStore.randomToken()
        XCTAssertEqual(token.count,43); XCTAssertNotEqual(token,other)
        XCTAssertNotEqual(DeviceStore.digest(token),DeviceStore.digest(other))
    }
}
