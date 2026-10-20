import XCTVapor
@testable import ForgeRemote

final class OriginTests: XCTestCase {
    func testProtectedRoutesRequireExactOrigin() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.middleware.use(OriginGuard(origin: "https://mac.example"))
        app.post("api", "pair") { _ in HTTPStatus.ok }
        for origin in [nil, "https://evil.example", "null", "https://mac.example.evil.test"] as [String?] {
            try app.test(.POST, "/api/pair", beforeRequest: { req in
                if let origin { req.headers.replaceOrAdd(name: "Origin", value: origin) }
            }, afterResponse: { response in XCTAssertEqual(response.status, .forbidden) })
        }
        try app.test(.POST, "/api/pair", beforeRequest: { req in
            req.headers.replaceOrAdd(name: "Origin", value: "https://mac.example")
        }, afterResponse: { response in XCTAssertEqual(response.status, .ok) })
    }
    func testSocketOriginAndFetchSite() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.middleware.use(OriginGuard(origin: "https://mac.example"))
        app.get("socket") { _ in HTTPStatus.ok }
        for path in ["/socket", "//socket", "/socket/"] {
            try app.test(.GET, path, afterResponse: { XCTAssertEqual($0.status, .forbidden) })
        }
        try app.test(.GET, "/socket", beforeRequest: { req in
            req.headers.replaceOrAdd(name: "Origin", value: "https://mac.example")
            req.headers.replaceOrAdd(name: "Sec-Fetch-Site", value: "cross-site")
        }, afterResponse: { XCTAssertEqual($0.status, .forbidden) })
    }
}
