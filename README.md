# CWSync for KOReader

CWSync is a standalone fork of Calibre-Web NextGen's `cwngsync.koplugin`.
It keeps the upstream synchronization features and adds preservation of the
manual order of Calibre-Web NextGen shelves when they are materialized as
native KOReader Collections.

## What it keeps from cwngsync

- KOReader reading-progress synchronization
- device inventory
- queued-book delivery and deletion
- annotation/highlight synchronization
- CWNG shelf -> native KOReader Collection synchronization

## What CWSync adds

CWNG already stores a manual `BookShelf.order`, and the CWNG OPDS shelf feed
already emits books in that order. The KOSync collection snapshot, however,
currently sorts the local paths alphabetically before sending them to KOReader.

CWSync reconciles the two sources:

1. it reports the current KOReader library to CWNG;
2. it receives the normal KOSync collection snapshot;
3. it reads the same shelves through CWNG OPDS using the existing Basic/app-password credentials;
4. for each local file in a shelf it resolves the authoritative
   `calibre_book_id` through the existing KOSync checksum lookup;
5. it reorders the snapshot to the OPDS/CWN shelf order;
6. it creates/rebuilds the native KOReader Collection in manual-sort mode.

No filename prefixes, fake series indexes, copied books, or server patch are
needed.

## Existing OPDS downloads

Existing books are supported. A book does **not** need to have been downloaded
by CWSync.

On shelf sync, CWSync scans the normal KOReader library through the upstream
inventory code. CWNG resolves each file by the same checksum mechanism already
used by KOSync. CWSync then caches `checksum -> calibre_book_id` locally and
uses that identity to position the existing file in the correct shelf.

Files are not renamed, moved, replaced, or re-downloaded. Existing `.sdr`
sidecars and reading progress are left in place.

If CWNG cannot identify a particular local file by checksum, CWSync leaves that
file in the Collection but does not guess its position; unresolved items remain
after the books whose CWNG order is known.

## Installation / migration from cwngsync

CWSync is a **replacement**, not a companion plugin.

1. In the KOReader data directory, remove or move out
   `plugins/cwngsync.koplugin`. Also remove the obsolete
   `cwasync.koplugin` if it still exists.
2. Install this repository as `plugins/cwsync.koplugin`.
3. Restart KOReader.
4. Open **CWSync for Calibre-Web NextGen**.
5. Existing CWNG settings are reused automatically because CWSync intentionally
   keeps the upstream `cwngsync` settings/state namespace.
6. Run **Sync CWNG shelves to KOReader Collections now** once if you want an
   immediate inventory + shelf refresh.

CWSync refuses to start while `cwngsync.koplugin` or `cwasync.koplugin` is
still installed, preventing duplicate progress/inventory/collection operations.

## Source of truth

For shelf membership and order, Calibre-Web NextGen is the source of truth.
Each sync rebuilds the managed KOReader Collection from the server state.
Local manual reordering of a CWSync-managed Collection can therefore be
overwritten by the next sync.

Only local books that CWNG reports as members of a shelf are included. A book
may belong to multiple Collections without duplicating the underlying file.

## Ambiguous shelves

The KOSync collection snapshot identifies a shelf by CWNG UUID, while OPDS
addresses it by numeric shelf ID. CWSync matches the two conservatively using
the shelf name plus the set of locally resolved CWNG book IDs. If duplicate
shelf names remain ambiguous, CWSync does not guess and falls back to the
ordinary server-provided order for that shelf.

## Upstream

Current baseline:

- Calibre-Web NextGen plugin: `cwngsync.koplugin` 4.1.43
- upstream commit: `097bb78f954739f76c888d50bf9033c5a2f17871`
- upstream subtree: `koreader/plugins/cwngsync.koplugin/`

See [UPSTREAM.md](UPSTREAM.md) for the intentionally small CWSync delta.

## License

GPL-3.0, matching Calibre-Web NextGen.
