# Forge Remote

**Status: repository voorbereid voor Codex; applicatie nog niet gebouwd of getest.**

Forge Remote is een privéproject om een eigen Mac veilig vanaf een iPhone te bekijken en te bedienen.

## Productvisie

- **iPhone:** een mobiele webapp (PWA), te openen in Safari en als webapp op het beginscherm te zetten. Chrome-ondersteuning waar mogelijk.
- **Mac:** een native Swift/SwiftUI-companion die, met expliciete systeempermissies, schermbeelden beschikbaar maakt en geautoriseerde invoer verwerkt.
- **Verbinding:** eerst veilig via privétoegang en een vertrouwde HTTPS-origin; geen standaard publieke internetpoort.
- **GitHub:** centrale codebase en traceerbaar ontwikkelproces met branches en reviews.

Een PWA kan niet zelfstandig macOS besturen: de companion blijft noodzakelijk. De PWA-installatie is een gebruikersstap, niet een vervanging voor netwerktoegang of beveiliging.

## Repositorystatus

Deze repository bevat nu de **projectinstructies, architectuurafspraken, securitykaders en bouwvolgorde**. Er zijn nog geen draaiende Mac- of webapp, geen apparaatkoppeling en geen gevalideerde remote-controlfunctionaliteiten. Status mag pas wijzigen op basis van echte builds en tests.

## Voor Codex

1. Lees eerst [AGENTS.md](AGENTS.md), daarna [Architecture](docs/ARCHITECTURE.md), [Security](docs/SECURITY.md) en [Roadmap](docs/ROADMAP.md).
2. Inspecteer de werkelijke ontwikkelomgeving; veronderstel geen Xcode, Apple SDK, Mac-toegang of iPhone-testapparaat.
3. Bouw de eerste verticale keten: mobiele interface → lokale companion → geauthenticeerde sessie → echte schermframes → echte inputevents.
4. Zorg eerst voor een reproduceerbare lokale build. Breid pas uit na werkende basisbediening.
5. Documenteer in de PR wat **IMPLEMENTED**, **VERIFIED**, **NOT TESTED** of **BLOCKED** is.

## Beoogde repository-indeling

```text
apps/
  mac/       # Swift/SwiftUI macOS companion (door Codex te maken)
  web/       # TypeScript/React/Vite PWA (door Codex te maken)
packages/
  protocol/  # Versiebeheer van wire protocol en schema's
docs/
  ARCHITECTURE.md
  SECURITY.md
  ROADMAP.md
  SETUP.md
AGENTS.md
```

## iPhone-installatie (na implementatie)

Open de uiteindelijke vertrouwde HTTPS-URL op de iPhone in Safari; gebruik **Delen → Zet op beginscherm → Open als webapp → Voeg toe**. Het toevoegen aan het beginscherm maakt de Mac niet automatisch bereikbaar. De Mac moet draaien, gekoppeld zijn en via een veilige verbinding bereikbaar zijn.

## Ontwikkel- en veiligheidsregels

- Repository privé houden; geen sleutels, tokens, screenshots of persoonsgegevens committen.
- Geen automatische publieke deployment, Funnel, portforwarding of productie-release.
- Geen remote shell en geen onbeperkte externe command-executie.
- Geen toegang tot macOS zonder zichtbare toestemming en noodzakelijke Screen Recording- en Accessibility-permissies.
- Bewaar bewijs van uitgevoerde tests; noem een niet-uitgevoerde fysieke integratietest nooit PASS.

Zie ook [SETUP](docs/SETUP.md) voor de concrete startvolgorde.
