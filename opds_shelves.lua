-- Minimal parser for the CWNG OPDS 1.x shelf feeds.
-- It intentionally handles only the controlled Atom shape emitted by CWNG.

local OpdsShelves = {}

local function unescape(value)
    if type(value) ~= "string" then return value end
    return (value
        :gsub("&lt;", "<")
        :gsub("&gt;", ">")
        :gsub("&quot;", '"')
        :gsub("&apos;", "'")
        :gsub("&amp;", "&"))
end

local function attrs(text)
    local result = {}
    for key, value in (text or ""):gmatch("([%w:_%-]+)%s*=%s*"([^"]*)"") do
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

local function links(block)
    local result = {}
    for raw in (block or ""):gmatch("<link%s+([^>]-)/>") do
        result[#result + 1] = attrs(raw)
    end
    return result
end

function OpdsShelves.parseIndex(xml)
    local result = {}
    for _, block in ipairs(entries(xml)) do
        local title = firstText(block, "title")
        local id = firstText(block, "id")
        local href
        for _, link in ipairs(links(block)) do
            if link.rel == "subsection"
                    or link.rel == "http://opds-spec.org/subsection" then
                href = link.href
                break
            end
        end
        if title and href then
            result[#result + 1] = {
                id = (href:match("/opds/shelf/(%d+)") or id or href),
                name = title,
                href = href,
            }
        end
    end
    return result
end

function OpdsShelves.parseShelfPage(xml)
    local book_ids = {}
    for _, block in ipairs(entries(xml)) do
        local book_id
        for _, link in ipairs(links(block)) do
            if link.rel and link.rel:match("^http://opds%-spec%.org/acquisition") then
                book_id = link.href and link.href:match("/opds/download/(%d+)/")
                if book_id then break end
            end
        end
        if book_id then
            book_ids[#book_ids + 1] = tonumber(book_id)
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
        book_ids = book_ids,
        next_href = next_href,
    }
end

return OpdsShelves
