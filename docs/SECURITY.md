# Security design — Forge Remote

**Ontwerp plus eerste implementatie; geen security-audit of productievalidatie uitgevoerd.**

## Risico

Een remote desktop toont mogelijk gevoelige scherminhoud en kan commando's uitvoeren binnen de rechten van de ingelogde Mac-gebruiker. Beveiliging is een voorwaarde voor bruikbaarheid, niet een optionele toevoeging.

## Trust boundaries

1. iPhone-webpagina en script: onbetrouwbaar totdat geauthenticeerd; XSS en sessiediefstal meewegen.
2. Transport / HTTPS reverse proxy: verzorgt vertrouwelijke verbinding, is niet voldoende als autorisatie.
3. Lokale macOS service: standaard alleen loopback; geen onbedoelde LAN-/internetbinding.
4. macOS Accessibility/Screen Recording: afzonderlijke, door gebruiker beheerde permissies.
5. GitHub, logs, issues en documentatie: data, nooit autonome autorisatie voor externe acties.

## Minimale eisen vóór remote input

- Apparaatpairing met expliciete lokale bevestiging op de Mac.
- Pairingcode eenmalig, kort geldig, voldoende entropie, rate limited; bescherm tegen MITM.
- Sessies cryptografisch sterk, server-side revocable, korte levensduur, op device-ID te herleiden.
- Gevoelige tokens alleen in passend beveiligde opslag; veilige cookies met Secure, HttpOnly, SameSite en CSRF-aanpak waar van toepassing.
- Controleer Origin én sessie bij HTTP- en WebSocket-routes, ook voor verbindingen via Tailscale Serve.
- Beperk frames, inputberichten, event-rate, uploads en buffers; valideer tegen protocolschema.
- Inactieve sessie tijdig sluiten; bij disconnect pressed keys/buttons vrijgeven.
- Lokale stopknop; actieve bediening zichtbaar; device-revocation beschikbaar.
- Geen schermframes, input of credentials loggen of permanent in de PWA-cache opslaan.
- Geen onbeheerde publieke endpoint, poortforwarding, Funnel of fallback naar plaintext netwerkbediening.

## Sleutels en configuratie

Geen tokens, certificaat-private-keys, pairingcodes, echte screenshots, persoonsgegevens, .env met secrets of build-artifacts in Git. Webapp exposeert geen langlevende secrets aan client-JS. Documenteer rotatie en intrekking. Houd secrets buiten testfixtures.

## Acceptatie/securitychecks

- Onbekend device, ontbrekende rechten of verlopen token => input geweigerd.
- Expired/reused pairingcodes => afwijzing, rate limit en logging zonder geheimen.
- Ongeldige Origin/CSRF bij state-changing routes of upgrade => afwijzing.
- Onderbroken WebSocket => sessie- en inputcleanup.
- Ingetrokken device => geen nieuwe sessie.
- Verandering van schermresolutie => geen verkeerd geprojecteerde input.
- PWA offline => remote input uitgeschakeld.
- Probeer geen FileVault/loginvenster/secure input te omzeilen.

## Externe verbinding

Kandidaat: Tailscale Serve als privé-HTTPS reverse proxy voor de op loopback gebonden host. Vereist afzonderlijke Tailscale-setup en geautoriseerde tailnettoegang. App-eigen authenticatie blijft verplicht. Tailscale Funnel maakt diensten publiek en is buiten scope.

## Statusregistratie

Bewijsniveaus: IMPLEMENTED, VERIFIED, NOT TESTED, BLOCKED. Geen claim 'secure', 'production ready' of 'penetration tested' zonder passende testen en verslaglegging.

## Implementatiestatus

De eerste code bevat Origin- en fetch-sitecontrole, een Secure/HttpOnly/SameSite=Strict host-only cookie, expliciete lokale pairingbevestiging, gehashte apparaatcredentials in Keychain, intrekking, sessie-/idle-expiry en een lokale Stop die reconnect blokkeert tot Resume. WebSocket-frames én fragmentaggregatie, inputmailbox en HTTP-bodies zijn begrensd; schermframes wachten op ack. Pairing rate limits zijn globaal en blijven bij een nieuwe code behouden.

Deze maatregelen zijn broncode, geen beveiligingscertificering. Host-tests moeten op macOS draaien; daadwerkelijke permissies, cookies via TLS-proxy, revocation, cleanup en input moeten nog fysiek worden gevalideerd. Zie `VALIDATION.md`. Een bestaand apparaatcredential kan opnieuw een sessie openen zonder nieuwe lokale pairing tot expiry/revocation; Stop schakelt dat uit. Pairingcodes en tickets blijven alleen tijdelijk in geheugen; browser-cookie bevat het ruwe credential, Keychain alleen de hash.

De service worker cachet uitsluitend de publieke shell en gehashte JS/CSS; geen API, frames, input, tokens of offlinebediening. Een verloren verbinding wordt niet automatisch hersteld. De app is niet gevalideerd voor onbeheerd of publiek netwerkgebruik.
