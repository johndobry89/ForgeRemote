# Roadmap en acceptatie — Forge Remote

**Huidige status:** eerste implementatie op featurebranch; webchecks geslaagd, Mac/iPhone-integratie NOT TESTED.

## Voortgang eerste implementatie

| Onderdeel | Status | Bewijs / beperking |
| --- | --- | --- |
| Toolchain-inspectie | VERIFIED | Linux, Node 24; geen Swift/Xcode |
| Web/PWA, typed protocol | IMPLEMENTED + VERIFIED | Productiebuild, 15 unittests en 2 Chromium UI-tests |
| Native menubar/service/pairing | IMPLEMENTED, NOT TESTED | Swift-broncode en XCTest-cases aanwezig; Mac vereist |
| Capture/pointer/keyboard | IMPLEMENTED, NOT TESTED | ScreenCaptureKit/CGEvent-code; fysieke validatie ontbreekt |
| TLS en iPhone installatie | NOT TESTED | Handmatige private HTTPS-route en echte iPhone nodig |
| CI | IMPLEMENTED, NOT TESTED | Web- en macOS-jobs toegevoegd; remote resultaten niet vastgesteld |

## Nog vereist voor end-to-end acceptatie

- Swift dependencies resolven, lockfile vastleggen en Mac build/tests uitvoeren; eventuele compiler-/SDK-fouten herstellen.
- App-signing/permissies, Keychain, screen capture, input en cleanup op echte Mac verifiëren.
- Private HTTPS-proxy en echte iPhone koppelen; beeld, klik, scroll, drag, tekst en shortcuts testen.
- Stop/revoke/expiry, geometriewijziging, reconnect en netwerkuitval fysiek testen.
- Safari/Chrome/standalone installatie, toetsenbordviewport en rotatie valideren.
- Security review en performance-/geheugenmeting van een langdurige echte sessie.

Zie `VALIDATION.md` voor het concrete acceptatiescript. Een webtest of aanwezige Swift-test is geen bewijs van Mac-bediening.

## Buiten de eerste implementatie

Cloudrelay, publieke tunneling, remote shell, file transfer, clipboard, audio, multi-monitor, wake-on-LAN, native iOS-wrapper en App Store-release.
