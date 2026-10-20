import SwiftUI
import Vapor
import ApplicationServices

@MainActor final class HostModel: ObservableObject {
    @Published var status = "Stopped"
    @Published var pairingCode = ""
    @Published var pendingName = ""
    @Published var devices: [Device] = []
    @Published var serving = false
    @Published var accepting = true
    @Published var origin = ProcessInfo.processInfo.environment["FORGE_ORIGIN"] ?? ""
    private var store: DeviceStore?
    private var service: LocalService?
    private let capture = ScreenCapture()
    private let input = InputController()
    private var socket: WebSocket?
    private var sessionID = UUID()
    private var deviceID: String?
    private var clock: SessionClock?
    private var rate = WindowRate()
    private var pairing = PairingFlow()
    private var frameID = 0, epoch = 1, lastBounds = CGRect.zero, lastSize = CGSize.zero
    private var awaiting: Int?, sentAt = Date.distantPast
    private var monitor: Task<Void,Never>?
    private var captureTask: Task<Void,Never>?
    private var ready = false
    init() {
        do { store = try DeviceStore(); devices = store?.devices ?? [] } catch { status = "Keychain unavailable — startup blocked" }
        capture.output = { [weak self] data,w,h,bounds in Task { @MainActor in self?.frame(data,w,h,bounds) } }
        capture.failure = { [weak self] in Task { @MainActor in self?.endSession("Screen capture stopped") } }
        monitor = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                if self.socket != nil && (self.clock?.valid() != true || !self.input.allowed || !CGPreflightScreenCaptureAccess() || (self.awaiting != nil && Date().timeIntervalSince(self.sentAt)>10)) { self.endSession("Session timed out or permission lost") }
                self.pairing.expire()
                self.pairingCode = self.pairing.code; self.pendingName = self.pairing.name
            }
        }
    }
    func requestPermissions() {
        CGRequestScreenCaptureAccess()
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        status = "Grant Screen Recording and Accessibility in System Settings, then restart app"
    }
    func start() {
        guard store != nil, !serving else { return }
        guard let url = URL(string: origin), url.scheme == "https", url.host != nil, url.path.isEmpty, url.query == nil, url.fragment == nil, url.user == nil, url.password == nil, !origin.hasSuffix("/") else { status = "FORGE_ORIGIN must be an exact HTTPS origin without trailing slash"; return }
        let path = ProcessInfo.processInfo.environment["FORGE_WEB_ROOT"] ?? (Bundle.main.resourceURL?.appendingPathComponent("web").path ?? "")
        guard FileManager.default.fileExists(atPath: path + "/index.html") else { status = "Set FORGE_WEB_ROOT to the built web dist directory"; return }
        service = LocalService(model: self, origin: origin, webRoot: path)
        serving = true; status = "Starting loopback service"
        service?.start { [weak self] message in Task { @MainActor in self?.status = message; if message.hasPrefix("Service failed") { self?.serving = false } } }
    }
    func newCode() {
        var value: UInt32 = 0
        guard SecRandomCopyBytes(kSecRandomDefault, MemoryLayout<UInt32>.size, &value) == errSecSuccess else { status = "Random generator failed"; return }
        pairing.issue(code: String(format: "%08u", value % 100_000_000))
        pairingCode = pairing.code; pendingName = ""
    }
    func requestPair(code: String, name: String) throws -> String {
        guard serving, accepting else { throw Abort(.unauthorized) }
        let ticket = try DeviceStore.randomToken()
        do { try pairing.request(code: code, name: name, ticket: ticket) }
        catch PairingFlow.Failure.rateLimited { throw Abort(.tooManyRequests) }
        catch { throw Abort(.unauthorized) }
        pendingName = pairing.name; pairingCode = pairing.code
        return ticket
    }
    func approve() {
        pairing.expire()
        guard pairing.pending else { pendingName = ""; return }
        do {
            let token = try DeviceStore.randomToken()
            let name = pairing.name
            try store?.add(token: token, name: name)
            try pairing.approve(token: token)
            devices = store?.devices ?? []; pendingName = ""
            status = "Device approved — waiting for connection"
        } catch { deny(); status = "Could not approve device or save it in Keychain" }
    }
    func deny() { pairing.deny(); pairingCode = ""; pendingName = "" }
    func pairStatus(_ candidate: String) throws -> String? {
        do { return try pairing.poll(ticket: candidate) }
        catch PairingFlow.Failure.rateLimited { throw Abort(.tooManyRequests) }
        catch { throw Abort(.unauthorized) }
    }
    func authorized(_ token: String?) -> Bool { token.flatMap { store?.find($0) } != nil }
    func attach(_ ws: WebSocket, token: String) {
        guard let device = store?.find(token), socket == nil, !stopping, accepting, input.allowed, CGPreflightScreenCaptureAccess() else { _ = ws.close(code: .policyViolation); return }
        let id = UUID(); sessionID = id; socket = ws; deviceID = device.id
        clock = SessionClock(created: Date(), activity: Date()); rate = WindowRate()
        status = "Connecting: \(device.name)"
        let (messages, continuation) = AsyncStream<String>.makeStream(bufferingPolicy: .bufferingOldest(32))
        ws.onText { ws,text in
            guard text.utf8.count <= 4096 else { _ = ws.close(code: .messageTooLarge); continuation.finish(); return }
            if case .dropped = continuation.yield(text) { _ = ws.close(code: .policyViolation); continuation.finish() }
        }
        ws.onBinary { ws,_ in _ = ws.close(code: .policyViolation); continuation.finish() }
        Task { [weak self] in
            for await text in messages { self?.receive(text, session: id) }
        }
        ws.onClose.whenComplete { [weak self] _ in
            continuation.finish()
            Task { @MainActor in if self?.sessionID == id { self?.endSession("Disconnected") } }
        }
        captureTask = Task {
            do {
                try await capture.start()
                guard sessionID == id, socket != nil else { return }
                ws.send("{\"type\":\"hello\",\"version\":1}", promise: nil)
                ready = true
                status = "Active: \(device.name) — remote control enabled"
            } catch { if sessionID == id { endSession("Screen capture failed — check permission") } }
        }
    }
    func disconnect(token: String) { if store?.find(token)?.id == deviceID { endSession("Disconnected by device") } }
    private func receive(_ text: String, session: UUID) {
        guard sessionID == session, socket != nil else { return }
        guard text.utf8.count <= 4096, rate.allow(limit: 240, interval: 1), clock?.valid() == true, input.allowed, CGPreflightScreenCaptureAccess(), let data = text.data(using: .utf8), let command = try? JSONDecoder().decode(Command.self, from: data), command.validate(epoch: epoch) else { endSession("Invalid command or expired session"); return }
        if command.type == "ack" {
            guard command.id == awaiting else { endSession("Invalid frame acknowledgement"); return }
            awaiting = nil
        } else if command.type != "ping" {
            // Input requires a delivered screen geometry, never the zero/default bounds.
            guard lastBounds.width > 0, lastBounds == CGDisplayBounds(CGMainDisplayID()) else { endSession("Screen not ready"); return }
            clock?.activity = Date(); input.apply(command)
        }
    }
    private func frame(_ data: Data, _ width: Int, _ height: Int, _ bounds: CGRect) {
        defer { capture.consumed() }
        guard ready, let socket, clock?.valid() == true, awaiting == nil else { return }
        let size = CGSize(width: width,height: height)
        if bounds != lastBounds || size != lastSize { epoch += 1; lastBounds = bounds; lastSize = size; input.releaseAll() }
        input.bounds = bounds; frameID += 1; awaiting = frameID; sentAt = Date()
        socket.send("{\"type\":\"frame\",\"id\":\(frameID),\"epoch\":\(epoch),\"width\":\(width),\"height\":\(height)}")
        socket.send(raw: data, opcode: .binary)
    }
    func endSession(_ reason: String = "Stopped locally") {
        ready = false
        let old = socket; socket = nil; deviceID = nil; sessionID = UUID(); clock = nil; awaiting = nil
        input.releaseAll(); lastBounds = .zero; lastSize = .zero
        _ = old?.close(code: .normalClosure)
        // Do not accept a replacement session until capture teardown completes.
        guard !stopping else { status = reason; return }
        stopping = true
        let starting = captureTask; captureTask = nil
        Task { await starting?.value; await capture.stop(); stopping = false }
        status = reason
    }
    private(set) var stopping = false
    func stopLocally() { accepting = false; deny(); endSession("Stopped locally — resume on this Mac to allow connections") }
    func resumeLocally() { accepting = true; status = "Remote connections enabled" }
    func revoke(_ id: String) {
        do { try store?.revoke(id); devices = store?.devices ?? []; if deviceID == id { endSession("Device revoked") } } catch { status = "Keychain update failed; revocation was not saved" }
    }
}
