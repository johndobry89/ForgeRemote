# Physical Mac / iPhone acceptance

Status: **NOT TESTED**. Passing CI proves compilation and automated assertions;
CGEvents captured by a test sink do not prove the OS accepted remote input.

Record the source commit, Actions run URL, macOS/Xcode/Swift versions, Mac display
size/scaling, iOS/browser versions and private HTTPS origin (no credentials).
Use your own unlocked Mac with a harmless TextEdit document and no sensitive
screen content. Follow SETUP first. Leave the local Stop control accessible.

For each case record PASS / FAIL / NOT TESTED with observed behavior. A failure
must include the trigger and symptom, never pairing codes, cookies or screenshots
containing private data.

| Case | Procedure | Required observation |
| --- | --- | --- |
| Permissions denied | Deny Screen Recording and Accessibility; attempt a paired session. | No desktop capture or remote input; actionable local status. |
| Pairing | Try a wrong/expired code, then a valid code and local Deny. Finally regenerate and Approve only your own phone. | Wrong/expired/consumed/denied pairing rejected; approved phone alone connects. |
| Real pixels and geometry | Move a TextEdit window locally; inspect the phone in portrait and landscape, including Retina letterboxing. | Actual changing desktop pixels; touches map to the displayed image, not the bars. |
| Pointer | Move, left-click, right-click, scroll, and drag a harmless window via Desktop touch. | Expected position, click, direction and drag; no continuing drag after release outside the image. |
| Keyboard | Send text, Enter, Tab, Backspace and Escape; use Copy/Paste/Select all/Undo in the test document. | Expected text/action; subsequent local typing and clicks have no unexpected modifiers. |
| Disconnect with mouse held | Begin a Desktop drag, interrupt network before lifting the finger. Reconnect explicitly, then move the cursor. Repeat with local Stop while dragging. | After the host detects loss/Stop, no continued drag or held button; no replay after reconnect. Test right-button release using a same-origin protocol test client if the UI cannot hold it. |
| Disconnect with modifier held | In a same-origin authenticated test client, send a valid key-down for Cmd (55), Shift (56), Option (58), Control (59), ordinary key C (8), and mouse-down. Close WSS before releasing. Repeat separately for each modifier and both mouse buttons. | Host cleanup emits button/key releases followed by modifier transitions with no remaining flags. Local typing, clicks and Keyboard Viewer show no stuck modifier or button. Automated tests alone cannot establish this OS behavior. |
| Local Stop / resume | While controlling, choose STOP REMOTE SESSION; attempt Reconnect; then Resume locally. | Capture/control end immediately; reconnect blocked until local Resume. No old pressed state in a new session. |
| Permission loss | While a harmless key/button is held through the authenticated test client, revoke Accessibility. Repeat separately for Screen Recording. | Host terminates session and attempts cleanup. Check locally for stuck state. macOS may reject CGEvent delivery once permission is revoked: if release is not accepted, record FAIL and the OS version; do not call that physically verified. |
| Expiry and revocation | Idle without input for >120 seconds (pings may continue); separately revoke the active device. | Session closes; no stuck input. Revoked device cannot reconnect or obtain frames. Full session lifetime is capped at 30 minutes. |
| Display changes | During control, change main-display geometry/resolution or active display. | Session ends safely; explicit reconnect captures the new geometry and maps input correctly. |
| Background / offline | Background or close the PWA; interrupt the private route; open the offline shell. | Session ends; no cached frames, queued input or automatic replay. |
| Slow consumer | Throttle/drop frame acknowledgements using the same-origin test client. | At most one frame awaits ack; session closes after ~10 seconds without ack. Measure process memory during a longer normal session. |
| Standalone install | Safari → Share → Add to Home Screen → Open as Web App where offered. Launch, pair again if storage differs, rotate and open the keyboard. Check supported Chrome installation separately. | Standalone UI remains usable with safe areas and keyboard; real capture/control still works on trusted HTTPS. Record exact OS/browser limitations. |

The protocol test client above is a **manual physical acceptance tool**, not an
implemented product feature or a completed test. It must use the same trusted
origin and existing authenticated cookie. Use `packages/protocol/README.md` for
message formats. Do not expose a new endpoint, bypass Origin checks, or make
production credentials readable to JavaScript just to run it.

Completion record:

- Source commit / Actions URL:
- Mac / Xcode / Swift:
- iPhone / iOS / browser:
- Private route configuration (without secrets):
- Result for each row:
- Remaining failures / NOT TESTED cases:
- Tester and date:
