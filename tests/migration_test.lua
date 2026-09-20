package.path = "../?.lua;" .. package.path

local Migration = require("migration")

local ok = Migration.canStart({
    enabled_plugins = {{ name = "cwsync" }},
    disabled_plugins = {},
    loaded_plugins = {},
})
assert(ok, "CWSync must not conflict with itself")

local allowed, message = Migration.canStart({
    enabled_plugins = {{ name = "cwngsync" }},
    disabled_plugins = {},
    loaded_plugins = {},
})
assert(not allowed and message, "upstream cwngsync must block CWSync")

allowed = Migration.canStart({
    enabled_plugins = {},
    disabled_plugins = {{ name = "cwasync" }},
    loaded_plugins = {},
})
assert(not allowed, "legacy cwasync must block CWSync")

local saved
local settings = {
    readSetting = function(_, key)
        if key == "cwngsync" then return { server = "https://example.invalid" } end
    end,
    saveSetting = function(_, key, value) saved = { key = key, value = value } end,
}
local current, migrated = Migration.migrateSettings(settings)
assert(current.server == "https://example.invalid" and migrated == false)
assert(saved == nil, "existing cwngsync settings must be reused, not rewritten")

print("migration_test.lua: passed")
