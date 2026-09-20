-- SPDX-License-Identifier: GPL-3.0-or-later

-- CWSync is a replacement for cwngsync, not a companion plugin. Keep the
-- settings key compatible, but refuse to start when either the legacy cwasync
-- or the upstream cwngsync plugin is still installed.
local Migration = {}

local CONFLICTING_PLUGIN_NAMES = {
    cwasync = true,
    cwngsync = true,
}
local LEGACY_SETTINGS_KEY = "cwasync"
local SETTINGS_KEY = "cwngsync"

Migration.BLOCKED_ERROR = "cwsync startup blocked by conflicting NextGen sync plugin"
Migration.BLOCKED_MESSAGE = [[CWSync replaces cwngsync.koplugin. Remove cwngsync.koplugin (and the older cwasync.koplugin if present), then restart KOReader. CWSync is disabled until the conflicting plugin is removed to prevent duplicate sync operations.]]

local function listContainsConflict(plugins)
    for _, plugin in ipairs(plugins or {}) do
        if CONFLICTING_PLUGIN_NAMES[plugin.name] then
            return true
        end
    end
    return false
end

function Migration.canStart(plugin_loader)
    if not plugin_loader then
        return true
    end

    local is_loaded = false
    for name in pairs(CONFLICTING_PLUGIN_NAMES) do
        if type(plugin_loader.isPluginLoaded) == "function" then
            is_loaded = is_loaded or plugin_loader:isPluginLoaded(name)
        elseif plugin_loader.loaded_plugins then
            is_loaded = is_loaded or plugin_loader.loaded_plugins[name] ~= nil
        end
    end

    -- Discovery lists matter independently of loaded_plugins: a conflicting
    -- plugin can be installed but not instantiated yet, or merely disabled and
    -- later re-enabled. Both cases are unsafe because both plugins share the
    -- cwngsync settings/state namespace.
    local is_installed = listContainsConflict(plugin_loader.enabled_plugins)
        or listContainsConflict(plugin_loader.disabled_plugins)

    if is_loaded or is_installed then
        return false, Migration.BLOCKED_MESSAGE
    end
    return true
end

local function copyTable(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, item in pairs(value) do
        copy[copyTable(key, seen)] = copyTable(item, seen)
    end
    return copy
end

function Migration.migrateSettings(reader_settings)
    -- Deliberately keep using the upstream cwngsync settings key. Replacing the
    -- plugin therefore preserves server URL, username/password, auto-sync and
    -- sync-direction preferences without asking the user to configure again.
    local current = reader_settings:readSetting(SETTINGS_KEY)
    if current ~= nil then
        return current, false
    end

    local legacy = reader_settings:readSetting(LEGACY_SETTINGS_KEY)
    if legacy == nil then
        return nil, false
    end

    local migrated = copyTable(legacy)
    reader_settings:saveSetting(SETTINGS_KEY, migrated)
    return migrated, true
end

return Migration
