# Changelog

All notable changes to CWSync are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and CWSync uses semantic versioning for its own releases.

## [Unreleased]

### Added

- Nothing yet.

## [1.0.2] - 2026-09-21

### Fixed

- Stopped the automatic `NetworkConnected` hook from calling the newer
  queued-book delivery pipeline on CWNG 4.1.43.
- Removed the remaining automatic probe of
  `PUT /kosync/syncs/inventory` on stable CWNG servers, preventing silent
  HTTP 405 responses in the KOReader log.
- Automatic network synchronization now refreshes shelves through the
  stable OPDS-based path instead.

### Changed

- Queued-book delivery remains available as an explicit manual action for
  CWNG servers that implement the newer device-capability endpoints.

## [1.0.1] - 2026-09-21

### Fixed

- Fixed shelf synchronization against the actual CWNG 4.1.43 stable release.
  CWSync 1.0.0 had inherited device-capability calls from an upstream `main`
  commit that still reported plugin version 4.1.43 but contained server APIs
  added after the 4.1.43 release.
- Shelf sync no longer depends on the unreleased
  `/kosync/syncs/inventory` or `/kosync/syncs/collections` endpoints.
- Added the correct HTTPS transport for OPDS requests.

### Added

- Direct construction of native KOReader Collections from CWNG OPDS shelves.
- Local library scanning for books already present on the device, including
  books previously downloaded through OPDS.
- Checksum-to-`calibre_book_id` resolution using read-only endpoints already
  available in CWNG 4.1.43.
- Read-only annotations lookup as a fallback for known books that have never
  produced a reading-progress record.
- Local `checksum -> calibre_book_id` caching to avoid repeating resolved
  lookups on later shelf syncs.
- Regression tests for OPDS collection snapshot construction and manual order.

### Changed

- CWNG OPDS became the authoritative source for shelf membership and manual
  order.
- Shelf synchronization was decoupled from device inventory, queued-book
  delivery and server-side collection snapshots.
- Reader startup no longer requires an inventory report before shelves can be
  synchronized.
- The inventory error shown for HTTP 405 now explains that shelf sync still
  works and that only newer device-capability features require a newer server.

### Compatibility

- Shelf synchronization works with CWNG 4.1.43.
- Device inventory, queued-book delivery and named deletion remain dependent on
  newer CWNG server capability endpoints when those features are invoked.

## [1.0.0] - 2026-09-21

### Added

- First standalone CWSync release, derived from Calibre-Web NextGen's
  `cwngsync.koplugin`.
- Preservation of Calibre-Web NextGen manual shelf order in native KOReader
  Collections.
- OPDS shelf parsing with pagination support.
- Conservative shelf matching and ordered reconciliation.
- Support for books that were already present on the device rather than
  requiring a fresh download.
- Native KOReader manual collection ordering through per-item `order` values
  instead of filename prefixes, fake series numbers or physical file moves.
- Reuse of the existing `cwngsync` settings namespace so configured server,
  username, password and sync preferences survive migration.
- Conflict detection preventing CWSync from running alongside
  `cwngsync.koplugin` or `cwasync.koplugin`.
- Lua 5.1 syntax and unit-test CI.
- Automated GitHub release packaging as `cwsync.koplugin.zip`.

### Changed

- CWSync became a replacement for the upstream KOReader plugin rather than a
  companion plugin.
- CWNG was defined as the source of truth for CWSync-managed collection
  membership and ordering.

### Known issues in this release

- Shelf synchronization depended on device inventory and server-side collection
  capability routes present in the upstream development branch but not in the
  actual CWNG 4.1.43 stable server. On 4.1.43 this could fail with
  `Device library report failed: 405 not expected`.
- OPDS fetching used the HTTP LuaSocket transport directly and therefore did
  not correctly select the TLS transport for HTTPS URLs.

Both issues were fixed in 1.0.1, with the remaining automatic inventory probe
removed in 1.0.2.

[Unreleased]: https://github.com/golgoth85/cwsync.koplugin/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/golgoth85/cwsync.koplugin/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/golgoth85/cwsync.koplugin/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/golgoth85/cwsync.koplugin/releases/tag/v1.0.0
