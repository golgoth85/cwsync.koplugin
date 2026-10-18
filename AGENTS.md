# CWSync

Regole generali (infrastruttura, GitHub, deploy, zone delicate): `/workspace/AGENTS.md`. Ambiente di sviluppo e collaudo headless: repo `koreader` (`/workspace/koreader-source`).

## Scopo
Plugin KOReader derivato da `cwngsync.koplugin` di Calibre-Web NextGen (CWNG). Mantiene la sincronizzazione di progressi di lettura, annotazioni e inventario/consegna/cancellazione di libri, e aggiunge la **conservazione dell'ordine manuale** degli scaffali CWNG quando diventano Collezioni native di KOReader. È un sostituto di `cwngsync`, non un plugin affiancato.

## Funzionamento
- Parte originale in `main.lua`, `CWNGSyncClient.lua`, `migration.lua`, `delivery.lua` e moduli `device_*`; la logica propria è isolata in `shelf_order.lua` e `opds_shelves.lua`. Tracciamento dell'upstream (baseline CWNG `4.1.43`, commit `097bb78`) in `UPSTREAM.md`.
- Gli scaffali si costruiscono dal feed OPDS, che emette i libri nell'ordine manuale (`BookShelf.order`): non servono gli endpoint `/kosync/syncs/inventory` e `/collections`, quindi funziona con il CWNG stabile `4.1.43` e con i più recenti. Il server CWNG gira sul NAS come container `calibre-web-nextgen`.
- Versione corrente: `1.1.1` (release GitHub `v1.1.1`, 2026-09-21). Non gira sul NAS: si installa sul dispositivo copiando la cartella in `koreader/plugins/` dopo aver rimosso `cwngsync.koplugin` (istruzioni nel `README.md`).
- Test unitari in `tests/*_test.lua`, lanciati con `lua5.1` dalla cartella `tests` (elenco in `.github/workflows/lua-ci.yml`, solo manuale); sintassi con `luac5.1 -p`.
- Rilascio: `.github/workflows/release.yml`; note e README in inglese.

## Regole
- Sviluppo su branch e PR; mantenere isolate le modifiche proprie rispetto all'upstream per facilitare gli aggiornamenti.
- Local CI: profilo `profile-pending` (vedi `LOCAL_CI.md`), facoltativa e non bloccante; nessuna CI GitHub-hosted automatica. Il codice non attendibile non gira su runner persistenti con credenziali.

## Zone delicate
- Sincronizzazione di progressi e annotazioni, consegna e cancellazione di libri sul dispositivo (`delivery.lua`, `migration.lua`): agisce sul dispositivo e sul server reali.
- Pubblicazione di una release (la scaricano i dispositivi).
- Separazione dal codice upstream di CWNG (`UPSTREAM.md`): mescolarli rende difficili gli aggiornamenti futuri.

## Documenti
`README.md`, `CHANGELOG.md`, `UPSTREAM.md`, `ROADMAP.md`, `LOCAL_CI.md`.
