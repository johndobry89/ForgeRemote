import Foundation
import Security
import CryptoKit

struct Device: Codable, Identifiable {
    var id: String
    var name: String
    var expires: Date
}
struct DeviceStore {
    private static let service = "dev.forgeremote.devices.v1"
    private(set) var devices: [Device]
    private let write: ([Device]) throws -> Void
    init() throws { try self.init(load: Self.load, write: Self.persist) }
    init(load: () throws -> [Device], write: @escaping ([Device]) throws -> Void) throws {
        self.write = write; devices = try load()
    }
    private static func load() throws -> [Device] {
        var item: CFTypeRef?
        let status = SecItemCopyMatching([kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: "devices", kSecReturnData: true, kSecMatchLimit: kSecMatchLimitOne] as CFDictionary, &item)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let data = item as? Data else { throw StoreError.keychain }
        return try JSONDecoder().decode([Device].self, from: data)
    }
    static func randomToken() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { throw StoreError.random }
        return Data(bytes).base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    static func digest(_ token: String) -> String { SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined() }
    func find(_ token: String) -> Device? { guard token.count == 43 else { return nil }; return devices.first { $0.id == Self.digest(token) && $0.expires > Date() } }
    mutating func add(token: String, name: String) throws {
        var next = devices.filter { $0.expires > Date() }
        guard next.count < 16 else { throw StoreError.capacity }
        next.append(Device(id: Self.digest(token), name: name, expires: Date().addingTimeInterval(30*86400)))
        try save(next)
    }
    mutating func revoke(_ id: String) throws { try save(devices.filter { $0.id != id }) }
    private mutating func save(_ next: [Device]) throws {
        try write(next); devices = next
    }
    private static func persist(_ next: [Device]) throws {
        let data = try JSONEncoder().encode(next)
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: "devices"]
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData] = data
            add[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(add as CFDictionary, nil) == errSecSuccess else { throw StoreError.keychain }
        } else if status != errSecSuccess { throw StoreError.keychain }
    }
    enum StoreError: Error { case keychain, random, capacity }
}
