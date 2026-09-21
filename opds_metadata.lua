-- Parse the book entries emitted by Calibre-Web NextGen's OPDS 1.x feeds.
-- Kept deliberately small and dependency-free for KOReader/Lua 5.1.

local OpdsMetadata = {}

local function codepointToUtf8(cp)
    if cp <= 0x7F then
        return string.char(cp)
    elseif cp <= 0x7FF then
        return string.char(
            0xC0 + math.floor(cp / 0x40),
            0x80 + (cp % 0x40)
        )
    elseif cp <= 0xFFFF then
        return string.char(
            0xE0 + math.floor(cp / 0x1000),
            0x80 + (math.floor(cp / 0x40) % 0x40),
            0x80 + (cp % 0x40)
        )
    elseif cp <= 0x10FFFF then
        return string.char(
            0xF0 + math.floor(cp / 0x40000),
            0x80 + (math.floor(cp / 0x1000) % 0x40),
            0x80 + (math.floor(cp / 0x40) % 0x40),
            0x80 + (cp % 0x40)
        )
    end
    return ""
end

local function unescape(value)
    if type(value) ~= "string" then return value end
    value = value:gsub("&#x([0-9A-Fa-f]+);", function(hex)
        return codepointToUtf8(tonumber(hex, 16) or 0)
    end)
    value = value:gsub("&#([0-9]+);", function(dec)
        return codepointToUtf8(tonumber(dec, 10) or 0)
    end)
    return (value
        :gsub("&lt;", "<")
        :gsub("&gt;", ">")
        :gsub("&quot;", '"')
        :gsub("&apos;", "'")
        :gsub("&amp;", "&"))
end

local function attrs(text)
    local result = {}
    for key, value in (text or ""):gmatch('([%w:_%-]+)%s*=%s*"([^"]*)"') do
        result[key] = unescape(value)
    end
    return result
end

local function entries(xml)
    local result = {}
    for block in (xml or ""):gmatch("<entry>(.-)</entry>") do
        result[#result + 1] = block
    end
    return result
end

local function firstText(block, tag)
    local value = block:match("<" .. tag .. "[^>]*>(.-)</" .. tag .. ">")
    return value and unescape(value) or nil
end

local function allText(block, outer_tag, inner_tag)
    local result = {}
    for outer in (block or ""):gmatch("<" .. outer_tag .. "[^>]*>(.-)</" .. outer_tag .. ">") do
        local value = firstText(outer, inner_tag)
        if value and value ~= "" then result[#result + 1] = value end
    end
    return result
end

local function repeatedText(block, tag)
    local result = {}
    for value in (block or ""):gmatch("<" .. tag .. "[^>]*>(.-)</" .. tag .. ">") do
        value = unescape(value)
        if value and value ~= "" then result[#result + 1] = value end
    end
    return result
end

local function links(block)
    local result = {}
    for raw in (block or ""):gmatch("<link%s+([^>]-)/>") do
        result[#result + 1] = attrs(raw)
    end
    return result
end

local function bookIdFromLinks(book_links)
    for _, link in ipairs(book_links) do
        if link.rel and link.rel:match("^http://opds%-spec%.org/acquisition") then
            local id = link.href and link.href:match("/opds/download/(%d+)/")
            if id then return tonumber(id) end
        end
    end
end

local function coverFromLinks(book_links)
    for _, link in ipairs(book_links) do
        if link.rel == "http://opds-spec.org/image" and link.href then
            return link.href
        end
    end
end

function OpdsMetadata.parseBookPage(xml)
    local books = {}
    for _, block in ipairs(entries(xml)) do
        local book_links = links(block)
        local book_id = bookIdFromLinks(book_links)
        if book_id then
            local tags = {}
            for raw in block:gmatch("<category%s+([^>]-)/>") do
                local category = attrs(raw)
                local value = category.label or category.term
                if value and value ~= "" then tags[#tags + 1] = value end
            end

            local publisher_block = block:match("<publisher[^>]*>(.-)</publisher>")
            local publisher = publisher_block and firstText(publisher_block, "name") or nil
            local series = firstText(block, "calibre:series")
                or firstText(block, "dcterms:isPartOf")
            local series_index = firstText(block, "calibre:series_index")
            if series_index then series_index = tonumber(series_index) or series_index end

            books[#books + 1] = {
                book_id = book_id,
                uuid = (firstText(block, "id") or ""):match("^urn:uuid:(.+)$"),
                title = firstText(block, "title") or "",
                authors = allText(block, "author", "name"),
                series = series or "",
                series_index = series_index or "",
                languages = repeatedText(block, "dcterms:language"),
                tags = tags,
                description = firstText(block, "content")
                    or firstText(block, "summary") or "",
                publisher = publisher or "",
                published = firstText(block, "published") or "",
                updated = firstText(block, "updated") or "",
                cover_href = coverFromLinks(book_links),
            }
        end
    end

    local next_href
    for raw in (xml or ""):gmatch("<link%s+([^>]-)/>") do
        local link = attrs(raw)
        if link.rel == "next" and link.href then
            next_href = link.href
            break
        end
    end

    return {
        books = books,
        next_href = next_href,
    }
end

return OpdsMetadata
