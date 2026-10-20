# Architectuur — Forge Remote

**Status:** eerste broncode-implementatie aanwezig. Webbuild/tests VERIFIED; native uitvoering en fysieke integratie NOT TESTED.

## Componenten

```text
iPhone Safari / Chrome
       |
  PWA: TypeScript + React + Vite
       | HTTPS + WSS (vertrouwde origin)
       v
   Privéroute / TLS termination
   (bijv. Tailscale Serve)
       |
   Loopback HTTP/WebSocket endpoint
       v
macOS Swift/SwiftUI companion
       +-- pairing / sessiebeheer / device revocation
       +-- ScreenCaptureKit -> encoder -> bounded frame stream
       +-- geautoriseerde remote input -> CGEvent / Accessibility
       +-- lokale menu bar / permissies / stopknop
```

Bij Tailscale Serve moet de iPhone binnen dezelfde tailnet toegang hebben; Serve is **niet** Funnel. TLS op de proxy verwijdert niet de noodzaak van app-eigen authenticatie en de vertrouwensgrens van loopback.

## Aanbevolen implementatie

- Web: TypeScript, React, Vite, responsive PWA. Vitest en browser-E2E wanneer beschikbaar.
- macOS: Swift, SwiftUI/AppKit, ScreenCaptureKit, Network.framework; gebruik ondersteunde APIs en verifieer deployment target.
- Protocol: geversioneerd, klein; typed control messages, separaat binary frames waar zinvol.
- Streaming MVP: begrensde adaptieve JPEG-frames, decode/render aan browserkant; geen oneindige buffering. Later hardware-encoder/WebRTC alleen met meetbaar voordeel.
- Transport: één geauthenticeerde sessie; controleer Origin, session cookie/credential, WebSocket upgrade, grootte, rate en toegestane commandtypen.
- Coördinaten: transporteer resolutie en zichtbaar gebied; schaal touch correct over zoom/letterbox/Retina en active monitor.
- State machine: DISCONNECTED, CONNECTING, PAIRING, AUTHENTICATING, CONNECTED, RECONNECTING, ERROR.
- Snelacties via expliciete allowlist; geen remote shell.

## Milestones

1. Web UI + manifest + offline shell zonder nepconnection status.
2. Swift companion en localhost service met health-/diagnostic endpoint.
3. Pairing, credential storage en sessieauthenticatie.
4. Werkende schermstream met echte ScreenCaptureKit output.
5. Werkende pointer, scroll, keyboard met disconnect cleanup.
6. Private HTTPS-bereikbaarheid op een echte iPhone.
7. End-to-end tests, security hardening, installatiehandleiding.

## Grootste integratierisico's

- Browser-JavaScript heeft geen native Mac-permissies of directe Bonjour-discovery.
- Tailscale Serve en lokale HTTP leveren niet automatisch browser-compatibele WebSocket/authenticatie; test Origin/cookie/upgrade.
- Safari toetsenbord-/gesturebeperkingen en background throttling.
- macOS schermopname- en Accessibility-toestemming vereisen echte gebruikersinteractie.
- Code signing, macOS-permissies, physical iPhone en VPN-configuratie zijn omgevingsafhankelijk.

## Bronnen om tijdens implementatie opnieuw te verifiëren

- Apple ScreenCaptureKit: https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-in-macos
- Apple webapps iPhone: https://support.apple.com/guide/iphone/open-as-web-app-iphea86e5236/ios
- Tailscale Serve: https://tailscale.com/docs/features/tailscale-serve
- Tailscale Serve CLI: https://tailscale.com/docs/reference/tailscale-cli/serve

Geen van deze links is uitvoeringsbewijs. Houd de werkelijke gebruikte SDK- en browserversies bij tijdens bouwen.

## Eerste implementatie

`apps/mac` is een Swift Package met SwiftUI-menubarapp. Vapor verzorgt HTTP en WebSocket-framing op 127.0.0.1:9876; een eigen begrensde upgrader stelt ook fragmentaggregatielimieten in. Dit vervangt de aanvankelijke Network.framework-voorkeur om HTTP/upgradeparsing niet zelf te implementeren. De trust boundary en loopbackbinding blijven hetzelfde.

`PairingFlow` beheert eenmalige code/ticket/approval; `DeviceStore` bewaart gehashte credentials in Keychain; `HostModel` serialiseert sessies op de main actor. `ScreenCapture` heeft een één-frame-mailbox, de sessie wacht op browser-ack en `InputController` houdt ingedrukte keys/buttons bij. Een geometriewijziging sluit veilig af; reconnect vernieuwt de captatie.

`apps/web` gebruikt dezelfde origin voor statische assets, API en WSS. Geen cloudrelay of credentialopslag in JavaScript. Browserstatus volgt de echte protocol-handshake; automatische reconnect/input replay is bewust uitgeschakeld. Trackpad beweegt relatief, Desktop ondersteunt directe touch-drag. Details: `packages/protocol/README.md`.
