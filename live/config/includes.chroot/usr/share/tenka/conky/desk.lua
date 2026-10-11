-- Tenka Lite desk: cairo drawing for conky. Mirrors shell/quickshell/tenka/Desk.qml.
require 'cairo'
pcall(require, 'cairo_xlib')
pcall(require, 'cairo_imlib2_helper')

local theme, loaded_at = nil, -1
local function hex(c, a)
    c = c:gsub('#', '')
    return tonumber(c:sub(1,2),16)/255, tonumber(c:sub(3,4),16)/255, tonumber(c:sub(5,6),16)/255, a or 1
end
local function load_theme()
    local now = os.time()
    if theme and now - loaded_at < 10 then return theme end
    local f = io.open(os.getenv('HOME') .. '/.config/tenka/shell-theme.json')
    local s = f and f:read('*a') or ''
    if f then f:close() end
    local t = { proverbs = {} }
    for k, v in s:gmatch('"([%w_]+)"%s*:%s*"([^"]*)"') do t[k] = v end
    local pv = s:match('"proverbs"%s*:%s*%[(.-)%]')
    if pv then for p in pv:gmatch('"([^"]*)"') do table.insert(t.proverbs, p) end end
    t.name = t.name or 'samurai'; t.text = t.text or '#efe6d6'; t.gold = t.gold or '#c9a35a'
    t.accent = t.accent or '#d8412f'; t.ink = t.ink or '#fff8ec'
    theme, loaded_at = t, now
    return t
end
local HOURS = { 'Rat','Ox','Tiger','Rabbit','Dragon','Snake','Horse','Goat','Monkey','Rooster','Dog','Pig' }

local function text(cr, s, x, y, size, r, g, b, a, track)
    cairo_select_font_face(cr, 'Marcellus', CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    cairo_set_source_rgba(cr, r, g, b, a)
    if not track or track == 0 then
        cairo_move_to(cr, x, y); cairo_show_text(cr, s)
        local ext = cairo_text_extents_t:create(); cairo_text_extents(cr, s, ext); return ext.x_advance
    end
    local cx = x
    for ch in s:gmatch(utf8.charpattern) do
        cairo_move_to(cr, cx, y); cairo_show_text(cr, ch)
        local ext = cairo_text_extents_t:create(); cairo_text_extents(cr, ch, ext)
        cx = cx + ext.x_advance + track
    end
    return cx - x
end
local function width(cr, s, size)
    cairo_select_font_face(cr, 'Marcellus', CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    local ext = cairo_text_extents_t:create(); cairo_text_extents(cr, s, ext); return ext.x_advance
end

function conky_tenka_desk()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)
    local t = load_theme()
    local d = os.date('*t')
    local X, Y = 136, 150
    local tr, tg, tb = hex(t.text)
    local gr, gg, gb = hex(t.gold)
    -- the clock
    local h = d.hour % 12; if h == 0 then h = 12 end
    local clock = string.format('%d:%02d', h, d.min)
    -- soft shadow
    for i = 1, 4 do text(cr, clock, X + 1, Y + 214 + i * 1.5, 268, 0, 0, 0, 0.07) end
    local cw = text(cr, clock, X, Y + 214, 268, tr, tg, tb, 1)
    -- AM/PM and the seal
    local sx = X + cw + 30
    text(cr, d.hour < 12 and 'AM' or 'PM', sx + 14, Y + 96, 22, tr, tg, tb, 0.75, 5)
    -- the day: a thin ruled tag in the accent (mirrors Desk.qml; was a filled stamp)
    local ar, ag, ab = hex(t.accent)
    local tx, ty, tw, th = sx + 6, Y + 112, 72, 92
    cairo_rectangle(cr, tx + 0.5, ty + 0.5, tw - 1, th - 1)
    cairo_set_source_rgba(cr, 0, 0, 0, 0.18); cairo_fill_preserve(cr)
    cairo_set_source_rgba(cr, ar, ag, ab, 0.85); cairo_set_line_width(cr, 1); cairo_stroke(cr)
    local wd = os.date('%a'):upper()
    local ww = width(cr, wd, 14) + 4 * (#wd - 1)
    text(cr, wd, tx + tw / 2 - ww / 2, ty + 34, 14, ar, ag, ab, 1, 4)
    local dn = tostring(d.day)
    text(cr, dn, tx + tw / 2 - width(cr, dn, 38) / 2, ty + 74, 38, tr, tg, tb, 1)
    -- the month and the hour's old name
    local hour = 'HOUR OF THE ' .. HOURS[math.floor(((d.hour + 1) % 24) / 2) + 1]:upper()
    text(cr, os.date('%B %Y'):upper() .. '   ·   ' .. hour, X + 8, Y + 268, 19, tr, tg, tb, 0.82, 9)
    -- the day's proverb (one a day, the same line the flagship desk and lock show), wrapped at ~560 px
    if #t.proverbs > 0 then
        local p = t.proverbs[(d.yday % #t.proverbs) + 1]
        local line, yy = '', Y + 330
        for w in p:gmatch('%S+') do
            local try = (line == '' and w) or (line .. ' ' .. w)
            if width(cr, try, 22) > 560 and line ~= '' then
                text(cr, line, X + 9, yy + 1.5, 22, 0, 0, 0, 0.5); text(cr, line, X + 8, yy, 22, tr, tg, tb, 0.75)
                line, yy = w, yy + 30
            else line = try end
        end
        if line ~= '' then text(cr, line, X + 9, yy + 1.5, 22, 0, 0, 0, 0.5); text(cr, line, X + 8, yy, 22, tr, tg, tb, 0.75) end
    end
    cairo_destroy(cr); cairo_surface_destroy(cs)
end
