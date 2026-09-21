-- Merge CWNG metadata into KOReader custom metadata without trampling
-- user-owned overrides. Pure planner: filesystem/DocSettings writes live in main.lua.

local MetadataMerge = {}

MetadataMerge.PROPS = {
    "title",
    "authors",
    "series",
    "series_index",
    "language",
    "keywords",
    "description",
}

local function join(values)
    if type(values) ~= "table" then return "" end
    local clean = {}
    for _, value in ipairs(values) do
        if value ~= nil and tostring(value) ~= "" then
            clean[#clean + 1] = tostring(value)
        end
    end
    return table.concat(clean, "\n")
end

function MetadataMerge.propsFromRecord(record)
    record = type(record) == "table" and record or {}
    return {
        title = tostring(record.title or ""),
        authors = join(record.authors),
        series = tostring(record.series or ""),
        series_index = record.series_index ~= nil and tostring(record.series_index) or "",
        language = type(record.languages) == "table"
            and tostring(record.languages[1] or "") or "",
        keywords = join(record.tags),
        description = tostring(record.description or ""),
    }
end

local function copyTable(source)
    local out = {}
    for key, value in pairs(source or {}) do out[key] = value end
    return out
end

-- Returns:
--   custom_props, managed_props, stats
-- A managed field is updated only while its current KOReader value still
-- equals the value CWSync last wrote. A user edit therefore automatically
-- relinquishes CWSync ownership of that field.
function MetadataMerge.plan(custom_props, managed_props, incoming_props)
    local custom = copyTable(custom_props)
    local managed = copyTable(managed_props)
    local stats = {
        written = 0,
        unchanged = 0,
        skipped_unmanaged = 0,
        relinquished = 0,
    }

    for _, prop in ipairs(MetadataMerge.PROPS) do
        local incoming = incoming_props[prop]
        if incoming == nil then incoming = "" end
        local previous = managed[prop]
        local current = custom[prop]

        if previous ~= nil then
            if current == previous then
                if current ~= incoming then
                    custom[prop] = incoming
                    stats.written = stats.written + 1
                else
                    stats.unchanged = stats.unchanged + 1
                end
                managed[prop] = incoming
            else
                -- The user changed a value after CWSync wrote it. Stop managing
                -- that field instead of overwriting the local decision.
                managed[prop] = nil
                stats.relinquished = stats.relinquished + 1
            end
        elseif current == nil then
            custom[prop] = incoming
            managed[prop] = incoming
            stats.written = stats.written + 1
        else
            -- Existing KOReader custom metadata predates CWSync ownership.
            stats.skipped_unmanaged = stats.skipped_unmanaged + 1
        end
    end

    return custom, managed, stats
end

return MetadataMerge
