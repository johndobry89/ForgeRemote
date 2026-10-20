# Roadmap en acceptatie — Forge Remote

**Huidige status (2026-10-20):** alleen repositoryvoorbereiding. Alle functionele tests: **NOT TESTED**. Er is nog geen werkende app.

## Fase 1 — Foundation

- [ ] Toolchain en OS/SDK inspecteren.
- [ ] Webapp skeleton met Vite/React/TypeScript en bruikbare scripts.
- [ ] Swift macOS project met menubar en echte runtime-status.
- [ ] Eenvoudig geversioneerd protocol + unit tests.
- [ ] Werkende builds op beschikbare toolchains.

## Fase 2 — Secure link

- [ ] Loopback service en PWA connect UI.
- [ ] Pairing met expliciete Mac-confirmatie en time-out.
- [ ] Authenticatie, Keychain/secure device registry, revoke en timeout.
- [ ] Gevalideerde websocket upgrade / origin check.
- [ ] Private HTTPS-route op echt apparaat documenteren.

## Fase 3 — Werkende verticale slice

- [ ] macOS screen capture permission.
- [ ] Echte schermframes verschijnen in iPhone-browser.
- [ ] Touch mapping naar cursor.
- [ ] Linker- en rechterklik, scrollen, drag.
- [ ] Toetsenbord en modifier cleanup.
- [ ] Disconnection, resume en revoked-device tests.

## Fase 4 — PWA & polish

- [ ] Manifest, icons en veilige static asset cache.
- [ ] Safari toevoegen aan beginscherm en zelfstandige launch testen.
- [ ] Chrome-gedrag valideren; beperking documenteren.
- [ ] Landscape, viewport/keyboard, zoom/letterbox/safe area.
- [ ] Diagnostiek, foutmeldingen en gebruikersdocumentatie.

## Fase 5 — Quality gate

- [ ] Typecheck/lint/build/unit tests.
- [ ] Protocol/securitytests.
- [ ] macOS-build en tests op echte toolchain.
- [ ] Fysieke iPhone ↔ Mac E2E in privé-HTTPS omgeving.
- [ ] README en setup bijgewerkt met werkelijke resultaten.

## Niet voor MVP

Cloudrelay, publieke tunneling, remote shell, file transfer, clipboard, audio, multi-monitor, wake-on-LAN, native iOS-wrapper, App Store release.

## Rapportformat per oplevering

| Onderdeel | Status | Bewijs / beperking |
| --- | --- | --- |
| Mac build | NOT TESTED | Nog geen broncode |
| Web build | NOT TESTED | Nog geen broncode |
| Pairing | NOT TESTED | Nog niet geïmplementeerd |
| Live screen | NOT TESTED | Nog niet geïmplementeerd |
| Pointer input | NOT TESTED | Nog niet geïmplementeerd |
| iPhone PWA | NOT TESTED | Nog niet geïmplementeerd |

Gebruik PASS/FAIL/NOT TESTED/BLOCKED voor concrete tests; geen impliciete succesclaim op basis van plannen.
