# Forge Remote

A private iPhone PWA and native macOS menu bar companion for viewing and controlling your own Mac. **First implementation; Mac/iPhone integration is NOT TESTED.** No public deployment or remote relay.

## Implemented

- React/TypeScript/Vite PWA: Desktop, Trackpad, Keyboard and Actions, touch drag, scroll, text and shortcut controls; standalone manifest, raster icons, light/dark mode, safe areas and static-only service worker.
- macOS 14+ SwiftUI companion: loopback-only Vapor service, temporary pairing code + explicit local approval, Keychain device registry, credential revocation, local Stop/Resume.
- ScreenCaptureKit JPEG pipeline (8fps, 1280px maximum width, one frame awaiting acknowledgement), CGEvent pointer/button/scroll/text/key input, bounds/epoch validation and disconnect cleanup.
- Same-origin HTTPS authentication with Secure/HttpOnly/SameSite cookies, origin checks, bounded messages/mailboxes, expiry and rate limits. No plaintext remote-control fallback.

## Actually verified here

Linux, Node 24.19.0: `npm run build`, 15 Vitest tests and 2 Chromium browser tests passed. Browser tests cover the actual shell at mobile/desktop sizes and refusal of plaintext; they do **not** prove remote control or iOS compatibility. Production dependency audit reported no vulnerabilities.

Swift/macOS build, system permissions, Keychain integration, real capture/input, trusted private HTTPS and physical iPhone installation: **NOT TESTED / BLOCKED by the Linux execution environment**. CI includes a macOS build/test job; its presence does not establish that it passed. See [validation](docs/VALIDATION.md).

## Develop

```sh
npm ci
npm run build
npm test
npm run test:browser  # local Chromium; see SETUP for other machines
npm run dev -w apps/web
```

Frontend development binds only `127.0.0.1:5173`. It has no simulated Mac backend. Pairing requires the companion serving the built assets through a trusted private HTTPS origin.

On your Mac, follow [SETUP](docs/SETUP.md) to build the app bundle, configure private HTTPS and pair your iPhone. The first step is to run the Mac build/tests, since that toolchain was unavailable here.

[Architecture](docs/ARCHITECTURE.md) · [Security](docs/SECURITY.md) · [Protocol](packages/protocol/README.md) · [Roadmap](docs/ROADMAP.md)
