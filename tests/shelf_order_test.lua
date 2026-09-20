package.path = "../?.lua;" .. package.path

local ShelfOrder = require("shelf_order")
local OpdsShelves = require("opds_shelves")

local index = OpdsShelves.parseIndex([[
<feed>
<entry><title>Torre Nera</title><id>/opds/shelf/7</id>
<link rel="subsection" type="application/atom+xml" href="/opds/shelf/7"/></entry>
</feed>
]])
assert(#index == 1 and index[1].name == "Torre Nera" and index[1].id == "7")

local page = OpdsShelves.parseShelfPage([[
<feed>
<link rel="next" title="Next" href="/opds/shelf/7?offset=20" type="application/atom+xml"/>
<entry><title>Third</title><id>urn:uuid:c</id>
<link rel="http://opds-spec.org/acquisition" href="/opds/download/30/epub/" type="application/epub+zip"/></entry>
<entry><title>First</title><id>urn:uuid:a</id>
<link rel="http://opds-spec.org/acquisition" href="/opds/download/10/epub/" type="application/epub+zip"/></entry>
</feed>
]])
assert(page.book_ids[1] == 30 and page.book_ids[2] == 10)
assert(page.next_href == "/opds/shelf/7?offset=20")

local snapshot = {
    scope = "scope",
    revision = 4,
    collections = {{
        id = "uuid-shelf",
        name = "Torre Nera",
        books = {"a.epub", "b.epub", "c.epub", "unmatched.pdf"},
    }},
}
local ordered, stats = ShelfOrder.reorder(snapshot, {{
    id = "7",
    name = "Torre Nera",
    book_ids = {30, 10, 20},
}}, {
    ["a.epub"] = 10,
    ["b.epub"] = 20,
    ["c.epub"] = 30,
})
assert(stats.matched == 1)
assert(table.concat(ordered.collections[1].books, "|")
    == "c.epub|a.epub|b.epub|unmatched.pdf")

-- A pre-existing OPDS download is just another local lpath once its checksum
-- resolves to a Calibre book id; it does not need to have been delivered by CWSync.
local existing, existing_stats = ShelfOrder.reorder({
    scope = "scope", revision = 5,
    collections = {{ id = "s", name = "Reading", books = {"old-opds.epub"} }},
}, {{ id = "9", name = "Reading", book_ids = {99} }}, {
    ["old-opds.epub"] = 99,
})
assert(existing_stats.matched == 1 and existing.collections[1].books[1] == "old-opds.epub")

-- Ambiguous duplicate names must preserve the server snapshot rather than guess.
local ambiguous, ambiguous_stats = ShelfOrder.reorder(snapshot, {
    { id = "1", name = "Torre Nera", book_ids = {10,20,30} },
    { id = "2", name = "Torre Nera", book_ids = {10,20,30} },
}, { ["a.epub"] = 10, ["b.epub"] = 20, ["c.epub"] = 30 })
assert(ambiguous_stats.ambiguous == 1)
assert(ambiguous.collections[1].books[1] == "a.epub")

print("shelf_order_test.lua: passed")
