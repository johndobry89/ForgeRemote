# Setup — Forge Remote

## Requirements and current limits

Mac: macOS 14+, Xcode 16+ with command-line tools selected and a compatible Swift toolchain (5.10+; Swift 6 recommended for current transitive packages). Node.js 22+ / npm. iPhone: recent iOS/Safari and an approved private route to the Mac. A trusted HTTPS certificate is mandatory.

The cloud environment used for this implementation is Linux with Node 24.19.0, npm 11.9.0 and Chromium. It cannot compile Apple frameworks, request macOS permissions or validate a physical iPhone. The commands below are the implemented build/start path, **not a claim that a Mac build has passed**. Transitive Swift dependencies still need resolution on a Mac; commit `apps/mac/Package.resolved` after successful resolution to freeze them.

## 1. Get the featurebranch and run checks on your Mac

```sh
git clone https://github.com/johndobry89/ForgeRemote.git
cd ForgeRemote
git switch feature/forge-remote-mvp
xcodebuild -version
swift --version
node --version
npm ci
npm run build
npm test
(cd apps/mac && swift test --jobs 3)
bash scripts/build-mac.sh
open "build/Forge Remote.app"
```

The script builds the web assets and release executable, bundles them and applies ad-hoc signing by default. It creates no public release. For a stable development signing identity, set `FORGE_SIGN_IDENTITY` to an existing local Apple signing identity before building; this script does not create certificates. Ad-hoc rebuilds may invalidate permissions and prompt again. Not notarized or App Store distributed.

If Swift compilation fails, preserve the exact diagnostics; native code has not been compiled in the cloud. Do not bypass permissions or signature checks.

## 2. Permissions and local service

Open the Forge Remote menu bar icon. Choose **Check / request system permissions**. In macOS System Settings → Privacy & Security, allow Screen Recording (or Screen & System Audio Recording, depending on OS version) and Accessibility for the app. Quit and reopen the app if prompted.

Enter your exact trusted HTTPS origin in the menu, e.g. `https://your-mac.your-tailnet.ts.net`, **without a trailing slash or path**, then choose **Start local service**. The service listens only on `127.0.0.1:9876`. This does not configure TLS or make the Mac reachable from the phone.

Alternatively run the built bundle executable from Terminal with `FORGE_ORIGIN` set; built-in web assets are discovered in the bundle. For direct `swift run` development also set `FORGE_WEB_ROOT` to the absolute `apps/web/dist` path. Do not use Vite as the remote-control production server.

## 3. Private HTTPS route (manual, optional Tailscale)

No VPN or external network software was installed or enabled by this implementation. Only configure it yourself after deciding to use it.

Candidate: Tailscale on Mac and iPhone, signed into your own tailnet, with device access constrained by your tailnet policy. Tailscale Serve terminates trusted HTTPS and proxies HTTP/WebSocket to the loopback service. It is optional; another trusted **private** reverse proxy preserving `Origin`, cookies and WebSocket upgrades can serve the same role.

For an already installed/authorized Tailscale CLI, check your installed version and `tailscale serve --help`; the expected modern command is:

```sh
tailscale serve --bg http://127.0.0.1:9876
tailscale serve status
```

Use the exact HTTPS URL reported by Serve as the companion origin and iPhone URL. Enable tailnet HTTPS if the tool requests it through its official setup flow. Do not use Funnel, public port forwarding, an untrusted certificate or `http://<LAN-IP>`. To undo this optional route: `tailscale serve reset` (removes this device's Serve configuration; inspect it first if you already serve other apps).

Official references: https://tailscale.com/docs/features/tailscale-serve and https://tailscale.com/docs/reference/tailscale-cli/serve. Current documentation retrieval from this cloud returned HTTP 403; no Tailscale command or private route was executed/tested here. Verify CLI syntax against your installed version.

## 4. Pair and control from iPhone

1. Keep the Mac unlocked/awake and the app running. On the private HTTPS route, open Forge Remote in Safari.
2. Generate a pairing code in the Mac menu; enter the eight digits on your phone within two minutes.
3. Check the pending request on the Mac, then choose **Approve device**. Do not approve unsolicited requests. The code is single-use; the pending approval also expires after two minutes.
4. After approval the browser receives an HttpOnly device cookie and opens a session. Real frames should appear only after macOS permissions and capture succeed.
5. Desktop: touch/drag directly on the image. Trackpad: slide to move, Click and Scroll buttons. Keyboard: send short text, Enter/Backspace/Tab/Escape. Actions: allowlisted shortcuts and a labelled center right-click.
6. Disconnect closes the session. Backgrounding the PWA also closes it. Reconnect is explicit and never replays input. A stored pairing lasts up to 30 days; sessions last up to 30 minutes and expire after 120 seconds without input.
7. **STOP REMOTE SESSION** on the Mac releases keys/buttons and blocks new sessions until **Resume remote connections**. Revoke removes a device credential and ends its active session.

Changing display geometry ends the session safely. Reconnect to recapture the display. Only the main display is supported. Sleep/FileVault login, secure-input bypass, multi-monitor, audio, clipboard sync and remote shell are unsupported.

## 5. Install the PWA

Safari: open the trusted HTTPS URL → **Share / Delen → Add to Home Screen / Zet op beginscherm → Open as Web App** if offered → Add. Standalone installation may have separate cookie storage; pair again inside the installed webapp if necessary.

Chrome on iPhone uses the OS's available webapp installation flow; on supporting versions look in Share for Add to Home Screen, or open the URL in Safari to install. Available options vary by iOS/Chrome version. No Chrome install prompt or API is assumed. Safari and Chrome installation/standalone behavior remain NOT TESTED on a real iPhone.

Offline mode caches only the public static shell and hashed JS/CSS. It provides no desktop view/control, queued input or automatic session resumption. Frames, API calls, tokens and input are never in the service-worker cache.

## Web-only development and browser tests

```sh
npm ci
npm run dev -w apps/web
```

Loopback Vite serves the real UI, with pairing disabled over HTTP. Cloud Chromium path is `/usr/bin/chromium`. For other machines, `npx playwright install chromium` installs a project test browser; use `CI=1 npm run test:browser` to select Playwright's managed browser or set `CHROMIUM_PATH` to your existing executable. This does not validate Mac integration.
