-- Apply CWNG shelves as native KOReader collections.
-- Visible collection names mirror the CWNG shelf names exactly. Account scope
-- remains internal state only and is used to prevent cross-account collisions.

local Collections = {}

local function cleanName(name)
    return type(name) == "string" and name ~= "" and name or "Shelf"
end

local function join(root, relative)
    return root:gsub("/+$", "") .. "/" .. relative
end

local function previousOwnedNames(previous)
    local owned = {}
    for _, name in pairs(previous.names or {}) do
        if type(name) == "string" and name ~= "" then
            owned[name] = true
        end
    end
    return owned
end

local function otherScopeOwnsName(state, current_scope, wanted)
    for scope, scoped_state in pairs(state) do
        if scope ~= current_scope and type(scoped_state) == "table" then
            for _, name in pairs(scoped_state.names or {}) do
                if name == wanted then
                    return true
                end
            end
        end
    end
    return false
end

local function collectionExists(read_collection, name)
    return type(read_collection.coll) == "table"
        and read_collection.coll[name] ~= nil
end

function Collections.apply(snapshot, root, read_collection, state)
    if type(snapshot) ~= "table" or type(snapshot.scope) ~= "string"
            or snapshot.scope == "" or type(snapshot.revision) ~= "number"
            or type(snapshot.collections) ~= "table" or type(root) ~= "string"
            or type(read_collection) ~= "table" or type(state) ~= "table" then
        return false, "invalid collection snapshot"
    end

    local previous = state[snapshot.scope] or { names = {} }
    local owned_before = previousOwnedNames(previous)
    local next_names = {}
    local desired_seen = {}

    -- Preflight every visible name before changing KOReader state. This is what
    -- lets us drop the old "[CWNG xxxx]" suffix without risking an overwrite of
    -- a user's own collection or a collection managed for another account.
    for _, shelf in ipairs(snapshot.collections) do
        if type(shelf) ~= "table" or type(shelf.id) ~= "string"
                or type(shelf.books) ~= "table" then
            return false, "invalid collection"
        end

        local name = cleanName(shelf.name)
        if desired_seen[name] then
            return false, "duplicate CWNG shelf name: " .. name
        end
        desired_seen[name] = true
        next_names[shelf.id] = name

        if otherScopeOwnsName(state, snapshot.scope, name) then
            return false, "collection name is already managed by another account: " .. name
        end
        if collectionExists(read_collection, name) and not owned_before[name] then
            return false, "collection name already exists in KOReader: " .. name
        end
    end

    local updated = {}

    -- Remove all collections previously owned by this account first. Besides
    -- migrating old suffixed names to clean names, this also makes shelf-name
    -- swaps safe (A->B and B->A cannot overwrite one another mid-update).
    for _, old_name in pairs(previous.names or {}) do
        if type(old_name) == "string" and old_name ~= "" then
            read_collection:removeCollection(old_name)
            updated[old_name] = true
        end
    end

    for _, shelf in ipairs(snapshot.collections) do
        local name = next_names[shelf.id]
        read_collection:addCollection(name)

        -- Native KOReader manual collection sorting is represented by a nil
        -- collate setting plus each item's numeric order. addItem assigns that
        -- order in insertion sequence.
        if read_collection.coll_settings and read_collection.coll_settings[name] then
            read_collection.coll_settings[name].collate = nil
            read_collection.coll_settings[name].collate_reverse = nil
        end

        updated[name] = true
        for _, lpath in ipairs(shelf.books) do
            if type(lpath) == "string" and lpath ~= "" and not lpath:find("..", 1, true)
                    and lpath:sub(1, 1) ~= "/" then
                read_collection:addItem(join(root, lpath), name)
            end
        end
    end

    local written, reason = read_collection:write(updated)
    if written == false then return false, reason or "collection write failed" end
    state[snapshot.scope] = { revision = snapshot.revision, names = next_names }
    return true
end

return Collections
