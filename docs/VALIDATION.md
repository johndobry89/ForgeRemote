# Validation evidence

## VERIFIED — executed in Linux cloud

- Git fetched updated `main` and the existing project documentation; featurebranch created from that baseline.
- Node v24.19.0 / npm 11.9.0.
- `npm run build`: TypeScript check and Vite production build passed.
- `npm test`: 15 tests passed: protocol version/schema, letterboxing/Retina/portrait/invalid dimensions, connection negotiation, HTTPS enforcement, decode-before-ack, invalid binary, late ack/disconnect, explicit reconnect, outgoing congestion, manifest and service-worker request exclusions.
- `npx playwright test`: 2 actual Chromium UI tests passed at 390×844 and 1280×800. Shell/modes work, no horizontal overflow, HTTP pairing/reconnect refuses control. No mocked remote desktop was used.
- `npm audit --omit=dev --audit-level=high`: zero reported production dependency vulnerabilities at execution time. This is not a security audit.
- `git push`: featurebranch push succeeded. GitHub API access (`gh api`) returned Forbidden; no API/PR/Actions result is inferred from Git transport access.

## IMPLEMENTED, NOT TESTED

- Native SwiftUI menu bar, Vapor HTTP/WS, Keychain registry, local pairing and Stop/Resume/revoke.
- Swift test cases for pairing approval/expiry/single-use/rate, host command validation, session timers, credential randomness, authentication/revocation, input cleanup and Origin protection.
- ScreenCaptureKit capture/encoding, actual CGEvent injection, modifier/button cleanup.
- App bundle build/signing script and macOS GitHub Actions job.

## BLOCKED here

Swift/Xcode/Apple SDKs and a macOS desktop are absent. Native compilation/test execution and actual permissions/Keychain/ScreenCaptureKit/CGEvent runtime validation require a Mac. A physical iPhone and trusted private HTTPS are required for integration and PWA-install verification. Nothing in a passing web build establishes these outcomes.

GitHub API is unavailable to the supplied CLI authentication; draft PR creation (`gh pr create --draft`) and Actions status retrieval (`gh run list`) both returned Forbidden. No PR was created or CI result verified. No new token was requested or extracted from the Git proxy.

## Required physical acceptance run

Run Mac build/tests first, then follow SETUP. Record Mac/iOS/browser versions and actual results for:

1. Denied Screen Recording/Accessibility => no screen/control; granting them permits capture.
2. Wrong/expired/reused code, rejected local approval, missing cookie, bad Origin and revoked device => rejected.
3. Approved phone shows actual changing Mac pixels; image size/aspect/Retina mapping is correct.
4. Pointer, left/right click, scroll, desktop touch drag, text, arrows and modifier shortcuts affect the expected app.
5. Network loss, button/key held during disconnect, hidden/background PWA, Mac stop and revocation release input and stop capture. Reconnect requires user action; Stop blocks it until local Resume.
6. Resize/main-display geometry change safely ends session; reconnect maps the new geometry.
7. Frame consumer stalls => session closes; sustained stream memory remains bounded and performance is acceptable.
8. Safari home-screen install and launch, standalone cookie behavior, light/dark, landscape, keyboard viewport and supported Chrome install behavior.

Until these execute, the end-to-end MVP remains **NOT TESTED**, not production-ready.
