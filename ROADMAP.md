# Roadmap e cose da fare

Ultimo aggiornamento: 2026-10-15 (fase: manutenzione; versione `1.1.1`). Nessun PR aperta; esiste un branch vecchio `ops/nas-bridge-bootstrap` (settembre, 19 commit indietro).

## Ora
- [ ] Nessun lavoro in corso: `CHANGELOG.md` non ha modifiche in `[Unreleased]`.

## Prossimo
- [ ] Verificare la compatibilità con il CWNG in esecuzione sul NAS (`calibre-web-nextgen`, immagine `latest`) rispetto alla baseline `4.1.43`, e aggiornare `UPSTREAM.md` se l'upstream è cambiato.
- [ ] Completare il profilo Local CI (oggi `profile-pending`) e decidere dove far girare i test Lua.

## Più avanti
- [ ] Valutare gli endpoint più recenti (`inventory`, `collections`) del server come ottimizzazione opzionale.
- [ ] Decidere se eliminare il branch `ops/nas-bridge-bootstrap`.

## Fatto di recente
- Release `v1.1.1` (2026-09-21).
