import XCTest
@testable import ForgeRemote

final class PairingTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1000)
    let ticket = String(repeating: "t", count: 43)
    func testCodeConsumedAndLocalApprovalRequired() throws {
        var flow = PairingFlow()
        flow.issue(code: "12345678", now: now)
        try flow.request(code: "12345678", name: "Test phone", ticket: ticket, now: now)
        XCTAssertNil(try flow.poll(ticket: ticket, now: now))
        XCTAssertThrowsError(try flow.request(code: "12345678", name: "Another", ticket: ticket, now: now))
        try flow.approve(token: "ephemeral-test-token", now: now)
        XCTAssertEqual(try flow.poll(ticket: ticket, now: now), "ephemeral-test-token")
        XCTAssertThrowsError(try flow.poll(ticket: ticket, now: now))
    }
    func testWrongExpiredAndDeniedPairing() throws {
        var flow = PairingFlow()
        flow.issue(code: "12345678", now: now)
        XCTAssertThrowsError(try flow.request(code: "87654321", name: "Phone", ticket: ticket, now: now))
        XCTAssertThrowsError(try flow.request(code: "12345678", name: "Phone", ticket: ticket, now: now.addingTimeInterval(120)))
        flow.issue(code: "12345678", now: now)
        try flow.request(code: "12345678", name: "Phone", ticket: ticket, now: now)
        flow.deny()
        XCTAssertThrowsError(try flow.approve(token: "test", now: now))
        XCTAssertThrowsError(try flow.poll(ticket: ticket, now: now))
    }
    func testTicketExpiresAndRateLimitSurvivesNewCodes() throws {
        var flow = PairingFlow()
        flow.issue(code: "12345678", now: now)
        try flow.request(code: "12345678", name: "Phone", ticket: ticket, now: now)
        XCTAssertThrowsError(try flow.approve(token: "test", now: now.addingTimeInterval(121)))
        for _ in 0..<4 { XCTAssertThrowsError(try flow.request(code: "bad", name: "Phone", ticket: ticket, now: now)) }
        flow.issue(code: "12345678", now: now)
        XCTAssertThrowsError(try flow.request(code: "12345678", name: "Phone", ticket: ticket, now: now)) { error in
            guard case PairingFlow.Failure.rateLimited = error else { return XCTFail("Expected rate limit") }
        }
    }
}
