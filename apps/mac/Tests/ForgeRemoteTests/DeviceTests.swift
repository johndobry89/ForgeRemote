import XCTest
@testable import ForgeRemote

final class DeviceTests: XCTestCase {
    func testAuthenticationRevocationAndPersistence() throws {
        let token = try DeviceStore.randomToken()
        var saved: [Device] = []
        var store = try DeviceStore(load: { [] }, write: { saved = $0 })
        XCTAssertNil(store.find(token))
        try store.add(token: token, name: "Test phone")
        XCTAssertNotNil(store.find(token)); XCTAssertEqual(saved.count,1)
        let restored = try DeviceStore(load: { saved }, write: { _ in })
        XCTAssertNotNil(restored.find(token))
        try store.revoke(DeviceStore.digest(token))
        XCTAssertNil(store.find(token)); XCTAssertTrue(saved.isEmpty)
    }
    func testExpiredCredentialsAndFailedPersistenceFailClosed() throws {
        let token = try DeviceStore.randomToken()
        let expired = Device(id: DeviceStore.digest(token),name: "Expired",expires: Date.distantPast)
        var store = try DeviceStore(load: { [expired] }, write: { _ in throw DeviceStore.StoreError.keychain })
        XCTAssertNil(store.find(token))
        XCTAssertThrowsError(try store.add(token: token,name: "Unsaved phone"))
        XCTAssertNil(store.find(token))
    }
}
