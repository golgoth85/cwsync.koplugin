-- Build native KOReader collection snapshots directly from CWNG OPDS shelves.
-- This path intentionally depends only on APIs shipped by CWNG 4.1.43:
-- OPDS shelf feeds plus checksum -> Calibre book resolution.

local Snapshot = {}

local function normalizeBookId(value)
    local n = tonumber(value)
    return n and tostring(math.floor(n)) or nil
end

-- Stable account scope without exposing credentials/server text in collection names.
-- The hash is not security-sensitive; it only prevents one CWNG account from
-- overwriting collections managed for another account on the same KOReader device.
function Snapshot.accountScope(server, username)
    local value = tostring(server or "") .. "\0" .. tostring(username or "")
    local hash = 5381
    for i = 1, #value do
        hash = (hash * 33 + value:byte(i)) % 4294967296
    end
    return string.format("%08x", hash)
end

function Snapshot.build(scope, shelves, book_id_by_lpath)
    if type(scope) ~= "string" or scope == ""
            or type(shelves) ~= "table" or type(book_id_by_lpath) ~= "table" then
        return nil, { collections = 0, books = 0, mapped = 0 }
    end

    local paths_by_book = {}
    local mapped = 0
    for lpath, value in pairs(book_id_by_lpath) do
        local id = normalizeBookId(value)
        if id and type(lpath) == "string" and lpath ~= "" then
            paths_by_book[id] = paths_by_book[id] or {}
            paths_by_book[id][#paths_by_book[id] + 1] = lpath
            mapped = mapped + 1
        end
    end
    -- Multiple local formats for one Calibre book are uncommon, but deterministic
    -- ordering keeps repeated syncs stable without inventing a format preference.
    for _, paths in pairs(paths_by_book) do
        table.sort(paths)
    end

    local collections = {}
    local matched_books = 0
    for _, shelf in ipairs(shelves) do
        if type(shelf) == "table" and shelf.id ~= nil
                and type(shelf.name) == "string" and type(shelf.book_ids) == "table" then
            local books, seen = {}, {}
            for _, value in ipairs(shelf.book_ids) do
                local id = normalizeBookId(value)
                for _, lpath in ipairs((id and paths_by_book[id]) or {}) do
                    if not seen[lpath] then
                        seen[lpath] = true
                        books[#books + 1] = lpath
                        matched_books = matched_books + 1
                    end
                end
            end
            collections[#collections + 1] = {
                id = tostring(shelf.id),
                name = shelf.name,
                books = books,
            }
        end
    end

    return {
        scope = scope,
        revision = 1,
        collections = collections,
    }, {
        collections = #collections,
        books = matched_books,
        mapped = mapped,
    }
end

return Snapshot
