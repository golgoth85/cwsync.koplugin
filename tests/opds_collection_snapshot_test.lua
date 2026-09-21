package.path = "../?.lua;" .. package.path

local Snapshot = require("opds_collection_snapshot")

local scope1 = Snapshot.accountScope("https://books.example", "marco")
local scope2 = Snapshot.accountScope("https://books.example", "other")
assert(type(scope1) == "string" and #scope1 == 8)
assert(scope1 == Snapshot.accountScope("https://books.example", "marco"))
assert(scope1 ~= scope2)

local snapshot, stats = Snapshot.build(scope1, {
    { id = "7", name = "Torre Nera", book_ids = { 30, 10, 20 } },
    { id = "9", name = "Vuota", book_ids = { 999 } },
}, {
    ["King/Primo.epub"] = 10,
    ["King/Secondo.epub"] = 20,
    ["King/Terzo.epub"] = 30,
    ["Altro.epub"] = 55,
})
assert(snapshot.scope == scope1)
assert(snapshot.revision == 1)
assert(#snapshot.collections == 2)
assert(snapshot.collections[1].id == "7")
assert(snapshot.collections[1].name == "Torre Nera")
assert(table.concat(snapshot.collections[1].books, "|")
    == "King/Terzo.epub|King/Primo.epub|King/Secondo.epub")
assert(#snapshot.collections[2].books == 0)
assert(stats.collections == 2)
assert(stats.books == 3)
assert(stats.mapped == 4)

-- If more than one local format resolves to the same Calibre book, keep all of
-- them adjacent at that book's OPDS position, in deterministic path order.
local multi = Snapshot.build(scope1, {
    { id = "x", name = "Multi", book_ids = { 42 } },
}, {
    ["B/book.pdf"] = 42,
    ["A/book.epub"] = 42,
})
assert(table.concat(multi.collections[1].books, "|") == "A/book.epub|B/book.pdf")

print("opds_collection_snapshot_test.lua: passed")
