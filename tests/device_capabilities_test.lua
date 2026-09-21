package.path = "../?.lua;" .. package.path

local Delivery = require("delivery")
local Actions = require("device_actions")
local Collections = require("device_collections")

local downloads = 0
local removed = {}
local installed, reason = Delivery.install({
    id = 1, filename = "Large.epub", size = 2 * 1024 * 1024,
}, "/library", {
    attributes = function() return nil end,
    digest = function() return nil end,
    sanitize = function(name) return name end,
    remove = function(path) removed[#removed + 1] = path end,
    persist_receipt = function() return true end,
    rename = function() return true end,
    available_space = function() return 1024 end,
    download = function()
        downloads = downloads + 1
        return true
    end,
})
assert(installed == nil, "a book larger than free space must not install")
assert(reason == "insufficient storage",
    "the refusal must name insufficient storage, got: " .. tostring(reason))
assert(downloads == 0, "space refusal must happen before opening the download")
assert(#removed == 0, "space refusal must not create or clean a partial file")

local files = { ["/library/Books/Named.epub"] = true }
local deleted, delete_reason = Actions.deleteNamed({
    lpath = "Books/Named.epub",
    checksum = "0123456789abcdef0123456789abcdef",
}, "/library", {
    attributes = function(path) return files[path] and { mode = "file" } or nil end,
    digest = function() return "0123456789abcdef0123456789abcdef" end,
    remove = function(path) files[path] = nil return true end,
})
assert(deleted and delete_reason == nil,
    "a named delete of a matching file must succeed: " .. tostring(delete_reason))
assert(files["/library/Books/Named.epub"] == nil,
    "a confirmed named delete must actually remove the file")

files["/library/Books/Replacement.epub"] = true
local mismatch, mismatch_reason = Actions.deleteNamed({
    lpath = "Books/Replacement.epub",
    checksum = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
}, "/library", {
    attributes = function(path) return files[path] and { mode = "file" } or nil end,
    digest = function() return "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" end,
    remove = function(path) files[path] = nil return true end,
})
assert(not mismatch and mismatch_reason == "checksum mismatch",
    "a file whose digest does not match the named one must NOT be deleted: "
    .. tostring(mismatch_reason))
assert(files["/library/Books/Replacement.epub"],
    "the refused delete must leave the mismatching file in place")

local escaped = Actions.deleteNamed({
    lpath = "../Outside.epub", checksum = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
}, "/library", {
    attributes = function() return { mode = "file" } end,
    digest = function() return "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" end,
    remove = function() error("escaped delete") end,
})
assert(not escaped,
    "a path escaping the library root must be refused before any remove() call")

local fake = { collections = {}, coll_settings = {} }
function fake:addCollection(name)
    self.collections[name] = {}
    self.coll_settings[name] = { order = 1 }
end
function fake:removeCollection(name)
    self.collections[name] = nil
    self.coll_settings[name] = nil
end
function fake:addItem(path, name) self.collections[name][path] = true end
function fake:write() return true end

local state = {}
local applied, apply_reason = Collections.apply({
    scope = "account-one", revision = 1, collections = {
        { id = "shelf-1", name = "Reading", books = { "First.epub" } },
    },
}, "/library", fake, state)
assert(applied, "first collection sync should succeed: " .. tostring(apply_reason))
assert(state["account-one"].names["shelf-1"] == "Reading",
    "visible collection name must exactly match the CWNG shelf name")
assert(fake.collections["Reading"]["/library/First.epub"],
    "the shelf's book must land in the cleanly named collection")

-- Upgrade migration: a name stored by <=1.0.2 with the old account suffix is
-- removed and replaced by the plain shelf name on the next successful sync.
fake.collections["Legacy [CWNG deadbeef]"] = { ["/library/Old.epub"] = true }
fake.coll_settings["Legacy [CWNG deadbeef]"] = { order = 2 }
state["legacy-account"] = {
    revision = 1,
    names = { legacy = "Legacy [CWNG deadbeef]" },
}
local migrated, migrated_reason = Collections.apply({
    scope = "legacy-account", revision = 2, collections = {
        { id = "legacy", name = "Legacy", books = { "New.epub" } },
    },
}, "/library", fake, state)
assert(migrated, "legacy suffix migration should succeed: " .. tostring(migrated_reason))
assert(fake.collections["Legacy [CWNG deadbeef]"] == nil,
    "the old suffixed collection must be removed during migration")
assert(fake.collections["Legacy"]["/library/New.epub"],
    "the migrated collection must use the exact shelf name")

-- Never merge two CWSync accounts into one visible collection.
local collided, collision_reason = Collections.apply({
    scope = "account-two", revision = 1, collections = {
        { id = "shelf-2", name = "Reading", books = { "Second.epub" } },
    },
}, "/library", fake, state)
assert(not collided and collision_reason:match("another account"),
    "same-name shelves from different accounts must be rejected safely")
assert(fake.collections["Reading"]["/library/First.epub"],
    "a rejected second account must not modify the first account's collection")

-- Never overwrite a user-created KOReader collection with the same name.
fake.collections["Personal"] = { ["/library/User.epub"] = true }
fake.coll_settings["Personal"] = { order = 3 }
local unmanaged, unmanaged_reason = Collections.apply({
    scope = "account-three", revision = 1, collections = {
        { id = "shelf-3", name = "Personal", books = { "Server.epub" } },
    },
}, "/library", fake, state)
assert(not unmanaged and unmanaged_reason:match("already exists in KOReader"),
    "an unmanaged KOReader name collision must be rejected")
assert(fake.collections["Personal"]["/library/User.epub"],
    "the user's existing collection must be preserved")

-- Duplicate shelf names inside one CWNG account cannot be represented as two
-- native KOReader collections without changing their visible names.
local duplicate, duplicate_reason = Collections.apply({
    scope = "account-four", revision = 1, collections = {
        { id = "a", name = "Duplicate", books = {} },
        { id = "b", name = "Duplicate", books = {} },
    },
}, "/library", fake, state)
assert(not duplicate and duplicate_reason:match("duplicate CWNG shelf name"),
    "duplicate server shelf names must fail instead of being silently merged")

Collections.apply({ scope = "account-one", revision = 2, collections = {
    { id = "shelf-1", name = "Reading", books = { "Replacement.epub" } },
}}, "/library", fake, state)
assert(not fake.collections["Reading"]["/library/First.epub"],
    "a book removed from a shelf must leave its managed collection")
assert(fake.collections["Reading"]["/library/Replacement.epub"],
    "a refreshed shelf must contain its new membership")

Collections.apply({ scope = "account-one", revision = 3, collections = {
    { id = "shelf-1", name = "Finished", books = { "Replacement.epub" } },
}}, "/library", fake, state)
assert(fake.collections["Reading"] == nil,
    "renaming a shelf must remove the collection under its old name")
assert(fake.collections["Finished"]["/library/Replacement.epub"],
    "the renamed collection must carry the membership over")

-- Name swaps are safe because all previously owned names are removed before
-- any new collection is created.
Collections.apply({ scope = "swap-account", revision = 1, collections = {
    { id = "a", name = "Alpha", books = { "A.epub" } },
    { id = "b", name = "Beta", books = { "B.epub" } },
}}, "/library", fake, state)
Collections.apply({ scope = "swap-account", revision = 2, collections = {
    { id = "a", name = "Beta", books = { "A2.epub" } },
    { id = "b", name = "Alpha", books = { "B2.epub" } },
}}, "/library", fake, state)
assert(fake.collections["Beta"]["/library/A2.epub"],
    "shelf A must survive a visible-name swap")
assert(fake.collections["Alpha"]["/library/B2.epub"],
    "shelf B must survive a visible-name swap")

Collections.apply({ scope = "account-one", revision = 4, collections = {} },
    "/library", fake, state)
assert(fake.collections["Finished"] == nil,
    "a shelf removed on the server must remove its managed collection")
assert(fake.collections["Legacy"]["/library/New.epub"],
    "one account's refresh must not remove another account's differently named collections")

print("device_capabilities_test.lua: 1 suite passed")
