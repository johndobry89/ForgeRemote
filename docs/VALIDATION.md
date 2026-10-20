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

## Input cleanup repair — current follow-up

The owner reports that the first macOS Actions run compiled Swift and executed
13 tests, with the two InputTests failing. This cloud has not independently read
that run's exact logs or PR #1's new analysis: the egress proxy rejects CONNECT
to api.github.com with HTTP 403. The required domain addition was saved to the
environment draft; saving it does not apply the runtime network policy.

Source-level findings:

- The old tests expected keyUp / keyDown for Command (55) and Shift (56).
  CoreGraphics keyboard events for modifiers are flagsChanged; ordinary keys
  must still produce keyDown / keyUp. The assertions now distinguish these and
  also check keycode and logical modifier flags.
- InputController.releaseAll previously traversed an unordered Set and posted
  release events without setting their flags. That made cleanup order and flags
  dependent on native CGEvent defaults / local state. Production cleanup now
  releases buttons and ordinary keys first, then each held modifier after removing
  it from tracked state. All emitted events receive explicit logical flags.
- Regression tests cover all four supported modifiers, both buttons, normal
  keys, deterministic release order, zero final modifier flags, permission loss,
  repeated cleanup, clean next-session state, and HostModel.endSession / local
  Stop's synchronous cleanup boundary. Their post sink captures genuine CGEvents
  without injecting into the runner's desktop. They do not test OS acceptance
  after Accessibility revocation or a physical socket/desktop integration.

Current Swift test suite: 18 test methods. These additions remain **NOT TESTED**
until the macOS runner executes them. CI preserves XCTest XML, test/release logs
and the actual Package.resolved in a run artifact. Release compilation is attempted
also when assertions fail, without masking the failed test step. The full web job
still includes production build, Vitest and Chromium browser checks.

For authorized pushes to feature/forge-remote-mvp, the report-pr job updates only
PR #1's marked validation section using the runner's scoped GITHUB_TOKEN. It checks
the exact PR head SHA, reports actual job/step conclusions and XML counts, and
never changes draft state or merges. This automation has not yet been observed
executing from this cloud. A missing report/API result is not a passing workflow.

The resolved lockfile must come from SwiftPM on a runner; no dependency revisions
have been guessed. Download the mac-validation artifact, place Package.resolved
at apps/mac/Package.resolved, and commit it on this featurebranch after reviewing
it. Physical acceptance is explicitly tracked in PHYSICAL_ACCEPTANCE.md.
