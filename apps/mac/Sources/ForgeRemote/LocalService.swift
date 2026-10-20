import Foundation
import Vapor

struct PairRequest: Content { let code: String; let name: String }
struct PollRequest: Content { let ticket: String }
struct PairResponse: Content { let ticket: String }
struct StatusResponse: Content { let status: String }

struct SecurityHeaders: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let response = try await next.respond(to: request)
        response.headers.replaceOrAdd(name: .cacheControl, value: "no-store")
        response.headers.replaceOrAdd(name: "X-Content-Type-Options", value: "nosniff")
        response.headers.replaceOrAdd(name: "Referrer-Policy", value: "no-referrer")
        response.headers.replaceOrAdd(name: "Content-Security-Policy", value: "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' blob:; connect-src 'self'; worker-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'")
        response.headers.replaceOrAdd(name: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()")
        return response
    }
}
struct OriginGuard: AsyncMiddleware {
    let origin: String
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let root = request.url.path.split(separator: "/").first
        if root == "api" || root == "socket" {
            guard request.headers["Origin"] == [origin] else { throw Abort(.forbidden) }
            guard request.headers["Sec-Fetch-Site"].first.map({ $0 == "same-origin" }) ?? true else { throw Abort(.forbidden) }
        }
        return try await next.respond(to: request)
    }
}
final class LocalService: @unchecked Sendable {
    private weak var model: HostModel?
    private let origin: String, webRoot: String
    @MainActor init(model: HostModel, origin: String, webRoot: String) { self.model = model; self.origin = origin; self.webRoot = webRoot }
    func start(report: @escaping @Sendable (String) -> Void) {
        // Vapor's blocking run never blocks the SwiftUI main actor.
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            do {
                let app = Application(.production)
                defer { app.shutdown() }
                app.http.server.configuration.hostname = "127.0.0.1"
                app.http.server.configuration.port = 9876
                app.http.server.configuration.requestDecompression = .disabled
                app.routes.defaultMaxBodySize = "4kb"
                // Never log request bodies, cookies, pairing codes or frame data.
                app.logger.logLevel = .warning
                app.middleware = .init()
                app.middleware.use(SecurityHeaders())
                app.middleware.use(ErrorMiddleware.default(environment: .production))
                app.middleware.use(OriginGuard(origin: origin))
                app.middleware.use(FileMiddleware(publicDirectory: webRoot, defaultFile: "index.html"))
                app.post("api", "pair") { [weak self] req async throws -> PairResponse in
                    let body = try req.content.decode(PairRequest.self)
                    guard let model = self?.model else { throw Abort(.serviceUnavailable) }
                    return try await PairResponse(ticket: model.requestPair(code: body.code, name: body.name))
                }
                app.post("api", "pair", "status") { [weak self] req async throws -> Response in
                    let body = try req.content.decode(PollRequest.self)
                    guard let model = self?.model else { throw Abort(.serviceUnavailable) }
                    let token = try await model.pairStatus(body.ticket)
                    let response = try await StatusResponse(status: token == nil ? "pending" : "approved").encodeResponse(for: req)
                    if let token {
                        response.cookies["__Host-forge_device"] = .init(string: token, maxAge: 30*86400, path: "/", isSecure: true, isHTTPOnly: true, sameSite: .strict)
                    }
                    return response
                }
                app.post("api", "disconnect") { [weak self] req async throws -> StatusResponse in
                    guard let model = self?.model, let token = req.cookies["__Host-forge_device"]?.string, await model.authorized(token) else { throw Abort(.unauthorized) }
                    await model.disconnect(token: token)
                    return StatusResponse(status: "disconnected")
                }
                app.get("api", "health") { _ in StatusResponse(status: "listening") }
                app.get("socket") { [weak self] req async throws -> Response in
                    guard req.method == .GET, let model = self?.model, let token = req.cookies["__Host-forge_device"]?.string,
                          await model.authorized(token) else { throw Abort(.unauthorized) }
                    let response = Response(status: .switchingProtocols)
                    response.upgrader = BoundedUpgrade { [weak self] ws in
                        Task { @MainActor in self?.model?.attach(ws, token: token) }
                    }
                    return response
                }
                try app.start()
                report("Listening on loopback:9876 — waiting for private HTTPS route")
                try app.running?.onStop.wait()
            } catch { report("Service failed: check port 9876 and configuration") }
        }
    }
}
