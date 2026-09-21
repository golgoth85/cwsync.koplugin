package.path = "../?.lua;" .. package.path

local Merge = require("metadata_merge")

local incoming = Merge.propsFromRecord({
    title = "Titolo nuovo",
    authors = { "Autore Uno", "Autore Due" },
    series = "Serie",
    series_index = 2,
    languages = { "ita" },
    tags = { "Narrativa", "Italia" },
    description = "Descrizione",
})
assert(incoming.authors == "Autore Uno\nAutore Due")
assert(incoming.keywords == "Narrativa\nItalia")
assert(incoming.language == "ita")
assert(incoming.series_index == "2")

-- First CWSync adoption: free fields become managed, a pre-existing user
-- override is preserved and not adopted.
local custom, managed, stats = Merge.plan({
    title = "Titolo scelto a mano",
}, {}, incoming)
assert(custom.title == "Titolo scelto a mano")
assert(managed.title == nil)
assert(custom.authors == "Autore Uno\nAutore Due")
assert(managed.authors == custom.authors)
assert(stats.skipped_unmanaged == 1)

-- A later server edit updates a field only while it still equals the last
-- value written by CWSync.
local incoming2 = {}
for k, v in pairs(incoming) do incoming2[k] = v end
incoming2.authors = "Autore Corretto"
local custom2, managed2, stats2 = Merge.plan(custom, managed, incoming2)
assert(custom2.authors == "Autore Corretto")
assert(managed2.authors == "Autore Corretto")
assert(stats2.written >= 1)

-- A local KOReader edit relinquishes CWSync ownership permanently for that
-- field instead of being overwritten.
custom2.authors = "Autore modificato su KOReader"
local incoming3 = {}
for k, v in pairs(incoming2) do incoming3[k] = v end
incoming3.authors = "Nuovo server"
local custom3, managed3, stats3 = Merge.plan(custom2, managed2, incoming3)
assert(custom3.authors == "Autore modificato su KOReader")
assert(managed3.authors == nil)
assert(stats3.relinquished == 1)

-- Empty server fields are real values: while managed they hide stale embedded
-- metadata instead of silently falling back to the EPUB's old value.
local c4, m4 = Merge.plan({ series = "Serie" }, { series = "Serie" }, {
    title = "", authors = "", series = "", series_index = "",
    language = "", keywords = "", description = "",
})
assert(c4.series == "")
assert(m4.series == "")

print("metadata_merge_test.lua: passed")
