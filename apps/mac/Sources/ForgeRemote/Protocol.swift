import Foundation

struct Command: Decodable {
    let type: String
    let x: Double?, y: Double?, action: String?, button: Int?, epoch: Int?
    let dx: Double?, dy: Double?, text: String?, code: Int?, down: Bool?, id: Int?
    static let keys: Set<Int> = [0,6,8,9,36,48,51,53,55,56,58,59,123,124,125,126]
    func validate(epoch current: Int) -> Bool {
        switch type {
        case "ping": return true
        case "ack": return (id ?? 0) > 0
        case "pointer":
            guard let x, let y, x.isFinite, y.isFinite, (0...1).contains(x), (0...1).contains(y), epoch == current else { return false }
            return ["move", "down", "up"].contains(action ?? "") && [0,1].contains(button ?? -1)
        case "scroll": return [dx,dy].allSatisfy { v in guard let v else { return false }; return v.isFinite && abs(v) <= 1000 }
        case "text": return text.map { !$0.isEmpty && $0.utf16.count <= 256 && !$0.unicodeScalars.contains(where: { $0.value < 32 || $0.value == 127 }) } ?? false
        case "key": return code.map { Self.keys.contains($0) } == true && down != nil
        default: return false
        }
    }
}
struct WindowRate {
    var since = Date.distantPast
    var count = 0
    mutating func allow(limit: Int, interval: TimeInterval, now: Date = Date()) -> Bool {
        if now.timeIntervalSince(since) >= interval { since = now; count = 0 }
        count += 1
        return count <= limit
    }
}
struct SessionClock {
    let created: Date
    var activity: Date
    func valid(now: Date = Date()) -> Bool { now.timeIntervalSince(created) < 1800 && now.timeIntervalSince(activity) < 120 }
}
