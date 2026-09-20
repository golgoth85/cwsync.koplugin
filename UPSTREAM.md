# Upstream tracking

CWSync is derived from:

- Repository: `new-usemame/Calibre-Web-NextGen`
- Subtree: `koreader/plugins/cwngsync.koplugin/`
- Baseline commit: `097bb78f954739f76c888d50bf9033c5a2f17871`
- CWNG plugin version at baseline: `4.1.43`

CWSync-specific logic is intentionally isolated primarily in:

- `shelf_order.lua`
- `opds_shelves.lua`
- small integration changes in `main.lua`, `CWNGSyncClient.lua`, `migration.lua`, and `_meta.lua`

This keeps future upstream rebases limited to the plugin subtree instead of the full CWNG repository.
