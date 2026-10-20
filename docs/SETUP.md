# Starten met Codex — Forge Remote

Dit document beschrijft wat nu klaarstaat en wat Codex nog moet bouwen.

## Repository

- GitHub: https://github.com/johndobry89/ForgeRemote
- Visibility: private (gecontroleerd bij initiële inrichting)
- Default branch: main
- Inrichtingsbestanden: README, AGENTS, docs en .gitignore
- Appcode: nog niet aanwezig

## Begin met Codex

1. Open deze repository in Codex of clone hem op je Mac.
2. Laat Codex eerst `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/SECURITY.md` en `docs/ROADMAP.md` lezen.
3. Laat Codex de echte toolchain bepalen voordat versies worden vastgepind.
4. Werk vanaf een `feature/...` branch; bouw code en tests; open een PR ter review.
5. Gebruik de afzonderlijk aangeleverde Codex-startprompt voor de concrete opdracht.

Lokaal clonen, als de Mac toegang tot de privé-repository heeft:

```sh
git clone https://github.com/johndobry89/ForgeRemote.git
cd ForgeRemote
git switch -c feature/initial-implementation
```

## Voor daadwerkelijke ingebruikname

Nog nodig, en niet reeds door de repositorysetup gedaan:

- Een Mac met geschikte macOS/Xcode/Swift-ontwikkelomgeving.
- Screen Recording en Accessibility-permissies voor de later gebouwde companion.
- Een iPhone waarop de PWA in Safari kan worden getest.
- Een door browser vertrouwde HTTPS-URL voor de webapp.
- Eventueel Tailscale op Mac/iPhone en een private Tailscale Serve-configuratie, na afzonderlijke toestemming.

### Safari-webapp

Op de iPhone: open de HTTPS-URL in Safari, kies **Delen → Zet op beginscherm → Open als webapp → Voeg toe**. Safari-interface kan per iOS-versie verschillen. Een icoon toevoegen is geen garantie dat de achterliggende Mac bereikbaar is.

## Aanpassingen aan deze handleiding

Codex moet concrete build-, start-, signing-, netwerk- en testcommando's toevoegen nadat de programma's echt bestaan. Verzin hier geen installatiestappen of werkende endpoint-URL's voordat de implementatie die ondersteunt.
