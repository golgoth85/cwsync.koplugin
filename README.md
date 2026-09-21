# CWSync for KOReader

CWSync is a standalone derivative of Calibre-Web NextGen's `cwngsync.koplugin`.
It keeps the upstream synchronization features and adds preservation of the
manual order of Calibre-Web NextGen shelves when they are materialized as
native KOReader Collections.

See [CHANGELOG.md](CHANGELOG.md) for release-by-release changes and compatibility notes.

## What it keeps from cwngsync

- KOReader reading-progress synchronization
- annotation/highlight synchronization
- device inventory, queued-book delivery and named deletion when the connected
  CWNG server exposes those newer capability endpoints

## What CWSync adds

CWNG already stores a manual `BookShelf.order`, and its OPDS shelf feed emits
books in that order. CWSync uses that stable OPDS representation directly to
build native KOReader Collections in manual-sort mode.

Shelf synchronization deliberately does **not** require the newer
`/kosync/syncs/inventory` or `/kosync/syncs/collections` endpoints. This
makes the feature work with the current stable CWNG 4.1.43 server as well as
newer builds.

The shelf-sync path is:

1. scan supported books under the configured KOReader library root;
2. compute the same partial-MD5 document checksum used by KOSync;
3. resolve each checksum to its authoritative `calibre_book_id` using
   read-only KOSync endpoints already shipped by CWNG 4.1.43;
4. read shelves through CWNG OPDS with the existing Basic/app-password
   credentials;
5. map local books to shelf membership in the exact OPDS/CWNG manual order;
6. create or rebuild the native KOReader Collections with manual sorting.

No filename prefixes, fake series indexes, copied books, re-downloads, or
server patch are required.

## Existing OPDS downloads

Existing books are supported. A book does **not** need to have been downloaded
by CWSync.

CWSync scans the local KOReader library and first attempts the ordinary KOSync
progress lookup for checksum-to-book resolution. If a known book has no reading
progress yet, it falls back to CWNG's read-only annotations endpoint, which
returns `calibre_book_id` even when that book has zero annotations. Successful
`checksum -> calibre_book_id` mappings are cached locally.

Files are not renamed, moved, replaced, or re-downloaded. Existing `.sdr`
sidecars and reading progress are left in place.

A local file that CWNG cannot identify by checksum is simply not inserted into
a CWNG-managed Collection; CWSync does not guess its identity.

## CWNG server compatibility

Shelf synchronization is compatible with **CWNG 4.1.43**.

CWNG's device inventory, queued-book delivery, named deletion, and server-side
collection snapshot APIs were added to upstream `main` after the 4.1.43
release. On a 4.1.43 server those newer routes may return HTTP 405. CWSync does
not use them for shelf synchronization. Queued-book delivery remains available
as a manual action for servers that implement the newer capability endpoints.

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
6. Run **Sync CWNG shelves to KOReader Collections now** for an immediate
   shelf refresh.

CWSync refuses to start while `cwngsync.koplugin` or `cwasync.koplugin` is
still installed, preventing duplicate synchronization operations.

## Source of truth

For shelf membership and order, Calibre-Web NextGen is the source of truth.
Each shelf sync rebuilds the managed KOReader Collection from the current OPDS
state. Local manual reordering of a CWSync-managed Collection can therefore be
overwritten by the next sync.

The visible KOReader Collection name is exactly the CWNG shelf name. CWSync
keeps account scope internally and does not append an account identifier. If a
same-name unmanaged KOReader Collection, another CWSync account, or duplicate
same-name CWNG shelves would collide, the sync is refused rather than merging
or overwriting Collections.

Only locally present books whose checksum CWNG can resolve are inserted. A book
may belong to multiple Collections without duplicating the underlying file.
Shelves removed from CWNG are removed from the set of CWSync-managed
Collections on the next successful sync.

## Upstream

The initial imported plugin code came from:

- Calibre-Web NextGen plugin reporting version 4.1.43
- upstream commit: `097bb78f954739f76c888d50bf9033c5a2f17871`
- upstream subtree: `koreader/plugins/cwngsync.koplugin/`

That upstream commit was on `main` after the released 4.1.43 server commit and
already contained newer device-capability APIs. CWSync 1.0.3 explicitly removes
those unreleased APIs from the shelf-sync dependency chain so it interoperates
with the actual 4.1.43 release.

See [UPSTREAM.md](UPSTREAM.md) for the CWSync delta.

## License

GPL-3.0, matching Calibre-Web NextGen.
