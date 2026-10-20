import SwiftUI

@main @MainActor struct ForgeRemoteApp: App {
    @StateObject private var host = HostModel()
    var body: some Scene {
        MenuBarExtra("Forge Remote", systemImage: "desktopcomputer") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Forge Remote").font(.headline)
                Text(host.status).font(.caption).fixedSize(horizontal: false, vertical: true)
                TextField("https://mac.private.example", text: $host.origin).disabled(host.serving)
                Button("Check / request system permissions") { host.requestPermissions() }
                Button("Start local service") { host.start() }.disabled(host.serving)
                Divider()
                Button("Generate pairing code (2 minutes)") { host.newCode() }.disabled(!host.serving)
                if !host.pairingCode.isEmpty { Text(host.pairingCode).font(.system(.title, design: .monospaced)).textSelection(.enabled) }
                if !host.pendingName.isEmpty {
                    Text("Pair request: \(host.pendingName)")
                    Text("Only approve if you just entered the code on your own iPhone.").font(.caption)
                    HStack { Button("Approve device") { host.approve() }; Button("Deny") { host.deny() } }
                }
                Button("STOP REMOTE SESSION", role: .destructive) { host.stopLocally() }
                if !host.accepting { Button("Resume remote connections") { host.resumeLocally() } }
                Divider()
                Text("Paired devices (30-day expiry)").font(.caption)
                ForEach(host.devices) { device in HStack { Text(device.name); Spacer(); Button("Revoke") { host.revoke(device.id) } } }
                Divider()
                Button("Quit Forge Remote") { host.endSession(); NSApplication.shared.terminate(nil) }
            }.padding().frame(width: 340)
        }.menuBarExtraStyle(.window)
    }
}
