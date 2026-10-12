.pragma library
// The old names of colours, for the Loupe (Tianxia: The Mirror): the nearest name from the old dye books, in English.
// Tenka reads the Japanese book, Tianxia the Chinese one. Matching is by distance in CIE L*a*b* (D65), so the name is
// the one the eye would call closest, not the nearest number. Values follow the commonly published tables.
var BOOKS = {
    samurai: [
        ["Cherry blossom", "#fedfe1"], ["Wild pink", "#dc9fb4"], ["Peach blossom", "#f596aa"], ["Crimson", "#cb1b45"],
        ["Cochineal", "#9f353a"], ["Madder red", "#cb4042"], ["Scarlet", "#cc543a"], ["Red ochre", "#9a5034"],
        ["Glazed persimmon", "#c46243"], ["Coral", "#fb966e"], ["Fallen leaf", "#e2943b"], ["Amber", "#ca7a2c"],
        ["Golden tea", "#c7802d"], ["Mulberry dye", "#c99833"], ["White tea", "#b4a582"], ["Kerria yellow", "#ffb11b"], ["Gardenia", "#f6c555"], ["Eggshell paper", "#dac9a6"],
        ["Unbleached silk", "#fbf8e8"], ["Raw silk white", "#fcfaf2"], ["Shell white", "#fffffb"],
        ["Willow underleaf", "#b5caa0"], ["Sprout green", "#7ba23f"], ["Young bamboo", "#5dac81"], ["Verdigris", "#24936e"],
        ["Pine needle", "#42602d"], ["Moss", "#838a2d"], ["Bush warbler", "#6c6a2d"], ["Rust blue-green", "#6a8372"],
        ["Water blue", "#a5dee4"], ["Pale indigo", "#33a6b8"], ["Dayflower blue", "#006284"], ["Indigo", "#0d5661"],
        ["Lapis", "#005caf"], ["Sky", "#58b2dc"], ["Forget-me-not", "#7db9de"], ["Ultramarine", "#51a8dd"],
        ["Indigo grey", "#566c73"], ["Rust celadon", "#86a697"], ["Blue-grey", "#535953"], ["Deep indigo", "#0f2540"], ["Wisteria", "#8b81c3"], ["Bellflower", "#6a4c9c"],
        ["Gromwell purple", "#77428d"], ["Kite brown", "#72483a"], ["Scorched tea", "#563f2e"], ["Mouse grey", "#787878"],
        ["Dull grey", "#656765"], ["Ink", "#1c1c1c"], ["Lacquer black", "#0c0c0c"]
    ],
    xianxia: [
        ["Peach", "#f47983"], ["Crabapple", "#db5a6b"], ["Lotus root", "#e4c6d0"], ["Silver red", "#f05654"],
        ["Pomegranate", "#f20c00"], ["Cinnabar", "#ff461f"], ["Scarlet", "#c83c23"], ["Rouge", "#9d2933"],
        ["Plum purple", "#8c4356"], ["Rosewood", "#4c221b"], ["Chestnut", "#60281e"], ["Sandalwood", "#b36d61"],
        ["Tea", "#b35c44"], ["Ochre", "#9c5333"], ["Amber", "#ca6924"], ["Apricot", "#ffa631"], ["Gosling yellow", "#fff143"],
        ["Autumn fragrance", "#d9b611"], ["Gold", "#eacd76"], ["Black gold", "#a78e44"], ["Undyed silk", "#f2ecde"],
        ["Ivory", "#fffbf0"], ["Lead white", "#f0f0f4"], ["Frost", "#e9f1f6"], ["Moon white", "#d6ecf0"],
        ["Duck egg", "#e0eee8"], ["Celadon", "#ace1af"], ["Bean green", "#96ce54"], ["Bamboo green", "#789262"],
        ["Pine pollen", "#057748"], ["Jade green", "#1bd1a5"], ["Jadeite", "#3de1ad"], ["Blue-green jade", "#48c0a3"],
        ["Sky over water", "#5aa4ae"], ["Azurite", "#1685a9"], ["Indigo", "#177cb0"], ["Navy", "#2e4e7e"],
        ["Kohl", "#4a4266"], ["Kohl blue", "#425066"], ["Blue-grey", "#a1afc9"], ["Slate", "#2b333e"], ["Lilac", "#cca4e3"], ["Weathered grey", "#75878a"], ["Ink", "#50616d"], ["Lacquer black", "#161823"]
    ]
};

function lab(r, g, b) {
    function lin(v) { v /= 255; return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4) }
    var R = lin(r), G = lin(g), B = lin(b)
    var x = (R * 0.4124 + G * 0.3576 + B * 0.1805) / 0.95047
    var y = (R * 0.2126 + G * 0.7152 + B * 0.0722)
    var z = (R * 0.0193 + G * 0.1192 + B * 0.9505) / 1.08883
    function f(t) { return t > 0.008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116 }
    return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))]
}
function rgbOf(hex) { return [parseInt(hex.substr(1, 2), 16), parseInt(hex.substr(3, 2), 16), parseInt(hex.substr(5, 2), 16)] }

// nearest(theme, [r, g, b]) -> { name, hex, de, word }: word is EXACT (dE < 3), NEAR (< 10) or LIKE
function nearest(theme, rgb) {
    var book = BOOKS[theme] || BOOKS.samurai, p = lab(rgb[0], rgb[1], rgb[2]), best = null
    for (var i = 0; i < book.length; i++) {
        var q = rgbOf(book[i][1]), l = lab(q[0], q[1], q[2])
        var d = Math.sqrt(Math.pow(p[0] - l[0], 2) + Math.pow(p[1] - l[1], 2) + Math.pow(p[2] - l[2], 2))
        if (!best || d < best.de) best = { name: book[i][0], hex: book[i][1], de: d }
    }
    best.word = best.de < 3 ? "EXACT" : best.de < 10 ? "NEAR" : "LIKE"
    return best
}
