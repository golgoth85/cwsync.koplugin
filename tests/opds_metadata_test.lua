package.path = "../?.lua;" .. package.path

local OpdsMetadata = require("opds_metadata")

local xml = [[
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:dcterms="http://purl.org/dc/terms/"
      xmlns:calibre="http://calibre.kovidgoyal.net/2009/metadata">
  <entry>
    <title>L&apos;ultimo cavaliere &amp; altro</title>
    <id>urn:uuid:abc-123</id>
    <updated>2026-09-21T01:02:03+00:00</updated>
    <author><name>Stephen King</name></author>
    <author><name>Altro Autore</name></author>
    <publisher><name>Sperling &amp; Kupfer</name></publisher>
    <published>2003-01-01T00:00:00+00:00</published>
    <dcterms:language>ita</dcterms:language>
    <category term="Fantasy" label="Fantasy"/>
    <category term="Western" label="Western"/>
    <calibre:series>La Torre Nera</calibre:series>
    <calibre:series_index>1.00</calibre:series_index>
    <content type="text">Descrizione &#39;italiana&#39;.</content>
    <link type="image/jpeg" href="/cover/42" rel="http://opds-spec.org/image"/>
    <link rel="http://opds-spec.org/acquisition" href="/opds/download/42/epub/" type="application/epub+zip"/>
  </entry>
  <link rel="next" href="/opds/books/letter/00?offset=20" />
</feed>
]]

local page = OpdsMetadata.parseBookPage(xml)
assert(#page.books == 1)
local b = page.books[1]
assert(b.book_id == 42)
assert(b.uuid == "abc-123")
assert(b.title == "L'ultimo cavaliere & altro")
assert(#b.authors == 2 and b.authors[1] == "Stephen King")
assert(b.publisher == "Sperling & Kupfer")
assert(b.series == "La Torre Nera")
assert(tonumber(b.series_index) == 1)
assert(b.languages[1] == "ita")
assert(table.concat(b.tags, "|") == "Fantasy|Western")
assert(b.description == "Descrizione 'italiana'.")
assert(b.cover_href == "/cover/42")
assert(page.next_href == "/opds/books/letter/00?offset=20")

print("opds_metadata_test.lua: passed")
