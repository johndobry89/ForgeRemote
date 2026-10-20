# Wire protocol v1

Same-origin HTTPS only. All `/api/*` and `/socket` requests require exactly the configured Origin. No cross-origin credentials or CORS. Browser tokens never appear in URLs, localStorage or JavaScript: a host-only Secure/HttpOnly/SameSite=Strict `__Host-forge_device` cookie authenticates WebSocket upgrades.

1. Mac generates an eight-digit code, valid for 120 seconds.
2. `POST /api/pair {code,name}` consumes that code, returns a cryptographically random memory-only ticket. Five attempts per minute globally, including wrong codes. Name <=64 UTF-8 bytes.
3. Mac explicitly approves or denies the request. Approval persists only the credential hash and device metadata in Keychain.
4. Client polls `POST /api/pair/status {ticket}` (120 requests/minute global). Pending => `{status:"pending"}`; approved => `{status:"approved"}` and cookie. Ticket expires after 120 seconds and is consumed on redemption. Denied/expired/wrong ticket => 401.
5. `/socket` upgrade verifies Origin and cookie; host rechecks device, permissions, local stop state and single-session limit. After capture starts, server sends `{type:"hello",version:1}`.
6. Each JPEG is preceded by `{type:"frame",id,epoch,width,height}`. Browser decodes and displays it, then sends `{type:"ack",id}`. Only one frame may await acknowledgement. Frames <=2MB; source 8fps, width <=1280. Acknowledgement must arrive within 10 seconds. No image caching.
7. Pointer messages: `{type:"pointer",x,y,action,button,epoch}` with finite normalized x/y in [0,1], action `move|down|up`, button 0 left / 1 right. Epoch must match the displayed geometry. Coordinates map to the main display's global Quartz bounds. A display geometry change ends capture safely; reconnect to recapture it.
8. Scroll: `{type:"scroll",dx,dy}`, finite, each [-1000,1000]. Text: `{type:"text",text}` <=256 UTF-16 units; no control characters. Keys: `{type:"key",code,down}` with explicit Mac keycode allowlist in both implementations. No shell command messages.
9. `{type:"ping"}` preserves transport liveness, NOT user activity. Session expires after 120 seconds without input or after 30 minutes total. Device credential expires after 30 days. No automatic reconnect or replay.
10. `POST /api/disconnect {}` ends only that device's session. Local Stop blocks all new sessions until local Resume. Revoking a device in the Mac UI updates Keychain and terminates its active session.

Inbound HTTP body and WebSocket message <=4KB; fragment aggregation <=4KB / 4 fragments. Main-actor input mailbox <=32 messages, maximum 240 commands/sec. Invalid input/overflow closes the connection; disconnect releases every tracked key/button. Client congestion also closes instead of dropping key-up silently.

Protocol tests exercise browser validation/mapping/lifecycle. Swift tests cover host validation, pairing transitions, Origin guards and clocks, but require a Mac toolchain to run. Neither set replaces real device integration or a security review.
