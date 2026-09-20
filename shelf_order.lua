-- CWSync: reorder KOReader collection payloads using CWNG OPDS shelf order.

local ShelfOrder = {}

local function normalizeBookId(value)
    local n = tonumber(value)
    return n and tostring(math.floor(n)) or nil
end

function ShelfOrder.namesCompatible(snapshot_name, opds_name)
    if type(snapshot_name) ~= "string" or type(opds_name) ~= "string" then
        return false
    end
    if snapshot_name == opds_name then
        return true
    end
    if opds_name:sub(1, #snapshot_name) ~= snapshot_name then
        return false
    end
    local suffix = opds_name:sub(#snapshot_name + 1)
    return suffix:match("^ %b()$") ~= nil
end

local function candidateIndex(candidate)
    local positions, set = {}, {}
    for i, value in ipairs(candidate.book_ids or {}) do
        local id = normalizeBookId(value)
        if id and not positions[id] then
            positions[id] = i
            set[id] = true
        end
    end
    return positions, set
end

local function mappedIds(collection, book_id_by_lpath)
    local ids, seen = {}, {}
    for _, lpath in ipairs(collection.books or {}) do
        local id = normalizeBookId(book_id_by_lpath[lpath])
        if id and not seen[id] then
            seen[id] = true
            ids[#ids + 1] = id
        end
    end
    return ids
end

local function chooseCandidate(collection, candidates, book_id_by_lpath)
    local local_ids = mappedIds(collection, book_id_by_lpath)
    local matches = {}
    for _, candidate in ipairs(candidates) do
        if ShelfOrder.namesCompatible(collection.name or "", candidate.name or "") then
            local positions, set = candidateIndex(candidate)
            local complete = true
            for _, id in ipairs(local_ids) do
                if not set[id] then
                    complete = false
                    break
                end
            end
            if complete then
                matches[#matches + 1] = {
                    candidate = candidate,
                    positions = positions,
                    exact_name = candidate.name == collection.name,
                }
            end
        end
    end

    if #matches == 1 then
        return matches[1]
    end

    -- Prefer one unique exact-name candidate over decorated OPDS names such as
    -- "Shelf (Public)". If more than one exact match remains, do not guess.
    local exact
    for _, match in ipairs(matches) do
        if match.exact_name then
            if exact then
                return nil, "ambiguous"
            end
            exact = match
        end
    end
    if exact then
        return exact
    end
    if #matches > 1 then
        return nil, "ambiguous"
    end
    return nil, "not_found"
end

local function orderedBooks(collection, positions, book_id_by_lpath)
    local decorated = {}
    for index, lpath in ipairs(collection.books or {}) do
        local id = normalizeBookId(book_id_by_lpath[lpath])
        decorated[#decorated + 1] = {
            lpath = lpath,
            original = index,
            position = id and positions[id] or nil,
        }
    end
    table.sort(decorated, function(a, b)
        if a.position and b.position and a.position ~= b.position then
            return a.position < b.position
        elseif a.position and not b.position then
            return true
        elseif b.position and not a.position then
            return false
        end
        return a.original < b.original
    end)
    local result = {}
    for _, item in ipairs(decorated) do
        result[#result + 1] = item.lpath
    end
    return result
end

function ShelfOrder.reorder(snapshot, opds_shelves, book_id_by_lpath)
    if type(snapshot) ~= "table" or type(snapshot.collections) ~= "table"
            or type(opds_shelves) ~= "table" or type(book_id_by_lpath) ~= "table" then
        return snapshot, { matched = 0, ambiguous = 0, unresolved = 0 }
    end

    local result = {
        scope = snapshot.scope,
        revision = snapshot.revision,
        collections = {},
    }
    local stats = { matched = 0, ambiguous = 0, unresolved = 0 }

    for _, collection in ipairs(snapshot.collections) do
        local match, reason = chooseCandidate(collection, opds_shelves, book_id_by_lpath)
        local copy = {
            id = collection.id,
            name = collection.name,
            books = collection.books,
        }
        if match then
            copy.books = orderedBooks(collection, match.positions, book_id_by_lpath)
            stats.matched = stats.matched + 1
        elseif reason == "ambiguous" then
            stats.ambiguous = stats.ambiguous + 1
        else
            stats.unresolved = stats.unresolved + 1
        end
        result.collections[#result.collections + 1] = copy
    end

    return result, stats
end

return ShelfOrder
