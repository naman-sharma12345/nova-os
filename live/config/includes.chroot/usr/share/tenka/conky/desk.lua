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
-- the season (tenka-hour writes it to ~/.config/tenka/hour.json; by month otherwise), in its own ink:
-- the same lean toward the season's colour the flagship desk uses (Theme.seasonInk)
local SEASON_LIGHT = {
    samurai = { plum = '#b8577a', lotus = '#e8a0b0', maple = '#c4532d', snow = '#dfe3e6' },
    xianxia = { plum = '#c97a9b', lotus = '#f0a3b8', maple = '#d9763a', snow = '#d8e2e6' },
}
local function season_of(d)
    local f = io.open(os.getenv('HOME') .. '/.config/tenka/hour.json')
    local s = f and f:read('*a') or ''
    if f then f:close() end
    local v = s:match('"season"%s*:%s*"(%a+)"')
    if v and v ~= '' then return v end
    local m = d.month
    if m >= 3 and m <= 5 then return 'plum' elseif m >= 6 and m <= 8 then return 'lotus'
    elseif m >= 9 and m <= 11 then return 'maple' else return 'snow' end
end
-- The Almanac (Tianxia: The Heavenly Calendar): the solar term and tonight's moon from tenka-almanac,
-- read once every ten minutes (the term turns every ~15 days; the moon by the hour)
local alm, alm_at = nil, -1000
local function almanac()
    local now = os.time()
    if now - alm_at < 600 then return alm end
    alm_at = now
    local f = io.popen('tenka-almanac json 2>/dev/null')
    local s = f and f:read('*a') or ''
    if f then f:close() end
    local term = s:match('"term"%s*:%s*"([^"]*)"')
    local e = tonumber(s:match('"elongation"%s*:%s*([%d%.]+)') or '')
    alm = term and { term = term, e = e or 0, phase = s:match('"phase"%s*:%s*"([^"]*)"') or '' } or nil
    return alm
end
-- the moon drawn flat: faint unlit disc, hairline gold rim, the lit part in the desk's text colour
local function moon(cr, cx, cy, r, e, tr, tg, tb, gr, gg, gb)
    cairo_new_path(cr); cairo_arc(cr, cx, cy, r, 0, 2 * math.pi)
    cairo_set_source_rgba(cr, tr, tg, tb, 0.12); cairo_fill(cr)
    local side = e < 180 and 1 or -1
    local c = math.cos(math.rad(e)) * side
    local N = 32
    cairo_new_path(cr)
    for i = 0, N do
        local f = -math.pi / 2 + math.pi * i / N
        local x, y = cx + side * r * math.cos(f), cy + r * math.sin(f)
        if i == 0 then cairo_move_to(cr, x, y) else cairo_line_to(cr, x, y) end
    end
    for i = N, 0, -1 do
        local f = -math.pi / 2 + math.pi * i / N
        cairo_line_to(cr, cx + c * r * math.cos(f), cy + r * math.sin(f))
    end
    cairo_close_path(cr); cairo_set_source_rgba(cr, tr, tg, tb, 0.88); cairo_fill(cr)
    cairo_new_path(cr); cairo_arc(cr, cx, cy, r, 0, 2 * math.pi)
    cairo_set_source_rgba(cr, gr, gg, gb, 0.5); cairo_set_line_width(cr, 1); cairo_stroke(cr)
end
-- The Pillow Book (Tianxia: The Jade Record): today's page from tenka-journal's own file, read every 20 s
local pg, pg_at = '', -1000
local function page()
    local now = os.time()
    if now - pg_at < 20 then return pg end
    pg_at = now
    local dir = os.getenv('TENKA_JOURNAL_DIR')
    if not dir or dir == '' then
        local xd = os.getenv('XDG_DATA_HOME')
        dir = ((xd and xd ~= '') and xd or (os.getenv('HOME') .. '/.local/share')) .. '/tenka/journal'
    end
    local f = io.open(dir .. '/' .. (os.getenv('TENKA_TODAY') or os.date('%Y-%m-%d')) .. '.txt')
    local s = f and f:read('*a') or ''
    if f then f:close() end
    pg = (s:match('^%s*([^\n]*)') or ''):gsub('%s+$', '')
    return pg
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
    local lw = text(cr, os.date('%B %Y'):upper() .. '   ·   ' .. hour, X + 8, Y + 268, 19, tr, tg, tb, 0.82, 9)
    local season = season_of(d)
    local light = (SEASON_LIGHT[t.name] or SEASON_LIGHT.samurai)[season]
    if light then
        local lr, lg, lb = hex(light)
        local sr, sg, sb = gr + (lr - gr) * 0.6, gg + (lg - gg) * 0.6, gb + (lb - gb) * 0.6
        -- its own short line under the date (the art behind the end of the date line is often bright)
        local word = (season .. ' season'):upper()
        text(cr, word, X + 9, Y + 300 + 1.5, 13, 0, 0, 0, 0.5, 6)
        local sw = text(cr, word, X + 8, Y + 300, 13, sr, sg, sb, 1, 6)
        -- the solar term after it, then the moon
        local a = almanac()
        if a then
            local tw = '   ·   ' .. a.term:upper()
            text(cr, tw, X + 9 + sw, Y + 300 + 1.5, 13, 0, 0, 0, 0.5, 6)
            local w2 = text(cr, tw, X + 8 + sw, Y + 300, 13, tr, tg, tb, 0.8, 6)
            moon(cr, X + 8 + sw + w2 + 22, Y + 295, 8, a.e, tr, tg, tb, gr, gg, gb)
        end
    end
    -- the day's proverb (one a day, the same line the flagship desk and lock show), wrapped at ~560 px
    local pend = Y + 312
    if #t.proverbs > 0 then
        local p = t.proverbs[(d.yday % #t.proverbs) + 1]
        local line, yy = '', Y + 342
        for w in p:gmatch('%S+') do
            local try = (line == '' and w) or (line .. ' ' .. w)
            if width(cr, try, 22) > 560 and line ~= '' then
                text(cr, line, X + 9, yy + 1.5, 22, 0, 0, 0, 0.5); text(cr, line, X + 8, yy, 22, tr, tg, tb, 0.75)
                line, yy = w, yy + 30
            else line = try end
        end
        if line ~= '' then text(cr, line, X + 9, yy + 1.5, 22, 0, 0, 0, 0.5); text(cr, line, X + 8, yy, 22, tr, tg, tb, 0.75) end
        pend = yy
    end
    -- today's page in the Pillow Book (mirrors the flagship desk's MONTH row): its first words marked TODAY,
    -- or the book's name marked UNWRITTEN; Super+K opens it
    do
        local first = page()
        local words = first ~= '' and first or (t.name == 'xianxia' and 'The Jade Record' or 'The Pillow Book')
        local tag = first ~= '' and 'TODAY' or 'UNWRITTEN'
        if width(cr, words, 18) > 440 then
            local cut = ''
            for ch in words:gmatch(utf8.charpattern) do
                if width(cr, cut .. ch .. '…', 18) > 440 then break end
                cut = cut .. ch
            end
            words = cut:gsub('%s+$', '') .. '…'
        end
        local ry = pend + 52
        cairo_rectangle(cr, X + 8, ry - 6, 22, 1); cairo_set_source_rgba(cr, gr, gg, gb, 0.7); cairo_fill(cr)
        text(cr, words, X + 41, ry + 1.5, 18, 0, 0, 0, 0.5)
        local ww2 = text(cr, words, X + 40, ry, 18, tr, tg, tb, first ~= '' and 0.9 or 0.6)
        text(cr, tag, X + 40 + ww2 + 19, ry - 1 + 1.5, 10, 0, 0, 0, 0.5, 4)
        text(cr, tag, X + 40 + ww2 + 18, ry - 1, 10, gr, gg, gb, first ~= '' and 1 or 0.7, 4)
        pend = ry
    end
    -- the slip (the flagship's note to self, ~/.config/tenka/slip.txt; Super+N): a flat ink plate under the proverb
    local sf = io.open(os.getenv('HOME') .. '/.config/tenka/slip.txt')
    if sf then
        local note = (sf:read('*a') or ''):gsub('%s+', ' '):gsub('^ ', ''):gsub(' $', '')
        sf:close()
        if note ~= '' then
            local lines, line = {}, ''
            for w in note:gmatch('%S+') do
                local try = (line == '' and w) or (line .. ' ' .. w)
                if width(cr, try, 18) > 420 and line ~= '' then table.insert(lines, line); line = w else line = try end
            end
            if line ~= '' then table.insert(lines, line) end
            while #lines > 4 do table.remove(lines) end
            local px, py, pw = X + 8, math.max(Y + 470, pend + 30), 468
            local ph = 58 + #lines * 25
            local br, bg, bb = hex(t.base or '#14110f')
            cairo_rectangle(cr, px + 0.5, py + 0.5, pw - 1, ph - 1)
            cairo_set_source_rgba(cr, br, bg, bb, 0.74); cairo_fill_preserve(cr)
            cairo_set_source_rgba(cr, gr, gg, gb, 0.3); cairo_set_line_width(cr, 1); cairo_stroke(cr)
            local lw2 = text(cr, 'A NOTE TO SELF', px + 22, py + 30, 10, gr, gg, gb, 1, 4)
            cairo_rectangle(cr, px + 34 + lw2, py + 26, 48, 1); cairo_set_source_rgba(cr, gr, gg, gb, 0.45); cairo_fill(cr)
            for i, l in ipairs(lines) do text(cr, l, px + 22, py + 36 + i * 25, 18, tr, tg, tb, 0.92) end
        end
    end
    cairo_destroy(cr); cairo_surface_destroy(cs)
end
