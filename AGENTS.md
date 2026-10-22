# CWSync

Regole comuni di infrastruttura e sviluppo: `/workspace/AGENTS.md`.

## Funzionamento
- Plugin KOReader derivato da CWNGSync: sincronizza progressi, annotazioni e inventario/consegna/cancellazione libri, conservando l'ordine manuale degli scaffali CWNG nelle Collezioni native. Sostituisce cwngsync, non gli si affianca.
- Codice base in `main.lua`, `CWNGSyncClient.lua`, `migration.lua`, `delivery.lua` e moduli device; personalizzazioni isolate in `shelf_order.lua` e `opds_shelves.lua`.
- L'ordine proviene dal feed OPDS (`BookShelf.order`), senza dipendere dagli endpoint inventory/collections. Baseline e aggiornamenti upstream in `UPSTREAM.md`.
- Nessun runtime NAS: installazione sul dispositivo in `koreader/plugins/`, rimuovendo il plugin originale secondo `README.md`. Banco di prova headless: `/workspace/koreader-source`.

## Zone delicate e verifica
- Progressi/annotazioni, consegna/cancellazione e migrazioni agiscono su dati del dispositivo/server: preservare isolamento dall'upstream e prova sintetica prima degli effetti reali.
- Test `tests/*_test.lua` dalla directory tests con Lua 5.1; sintassi `luac5.1 -p`. Elenco comandi nel workflow Lua manuale.
- Release GitHub/workflow release solo su richiesta; README e note pubbliche restano in inglese. Versioni e prossimi passi in `ROADMAP.md`, modifiche in `CHANGELOG.md`.
