import Foundation

/// All transitions run on the host's main actor. Tokens are memory-only until approval.
struct PairingFlow {
    private(set) var code = ""
    private(set) var name = ""
    private(set) var ticket: String?
    private var token: String?
    private var codeExpiry = Date.distantPast, ticketExpiry = Date.distantPast
    private var requests = WindowRate(), polls = WindowRate()
    enum Failure: Error { case rateLimited, unauthorized }
    var pending: Bool { ticket != nil && !name.isEmpty && token == nil }
    mutating func issue(code: String, now: Date = Date()) {
        deny(); self.code = code; codeExpiry = now.addingTimeInterval(120)
    }
    mutating func request(code: String, name: String, ticket: String, now: Date = Date()) throws {
        guard requests.allow(limit: 5, interval: 60, now: now) else { throw Failure.rateLimited }
        expire(now: now)
        guard !self.code.isEmpty, self.code == code, !name.isEmpty, name.utf8.count <= 64,
              !name.unicodeScalars.contains(where: { $0.value < 32 }) else { throw Failure.unauthorized }
        self.code = ""; self.name = name; self.ticket = ticket; token = nil
        ticketExpiry = now.addingTimeInterval(120)
    }
    mutating func approve(token: String, now: Date = Date()) throws {
        expire(now: now)
        guard pending else { throw Failure.unauthorized }
        self.token = token; name = ""
    }
    mutating func poll(ticket: String, now: Date = Date()) throws -> String? {
        guard polls.allow(limit: 120, interval: 60, now: now) else { throw Failure.rateLimited }
        expire(now: now)
        guard ticket.count == 43, self.ticket == ticket else { throw Failure.unauthorized }
        guard let token else { return nil }
        deny(); return token
    }
    mutating func expire(now: Date = Date()) {
        if now >= codeExpiry { code = "" }
        if now >= ticketExpiry { ticket = nil; token = nil; name = "" }
    }
    mutating func deny() { code = ""; name = ""; ticket = nil; token = nil }
}
