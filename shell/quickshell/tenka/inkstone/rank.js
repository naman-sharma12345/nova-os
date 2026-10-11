.pragma library
// rank.js: the Inkstone's search order. Every word of the query must appear in a glyph's name; the
// glyphs then line up by how well the worst word fits: the whole name, a whole word ("bubble tea"),
// the start of a word ("teapot", "teacup"), and last a match inside a word ("steaming"). Ties go to
// the match nearer the front of the name, then the shorter name, then the shelf order.
// Pure JavaScript, so check-session runs it outside Qt as well.

function fit(name, words, t) {
    if (name === t) return 0
    let best = 9, at = 99
    for (let i = 0; i < words.length; i++) {
        const w = words[i]
        const r = w === t ? 1 : w.indexOf(t) === 0 ? 2 : -1
        if (r > 0 && (r < best || (r === best && i < at))) { best = r; at = i }
    }
    if (best < 9) return best * 100 + Math.min(at, 99)
    return name.indexOf(t) >= 0 ? 399 : -1
}

function rank(all, query, limit) {
    const terms = query.toLowerCase().split(/\s+/).filter(t => t !== "")
    if (!terms.length) return []
    const hits = []
    for (let k = 0; k < all.length; k++) {
        const n = (all[k].n || "").toLowerCase()
        const words = n.split(/[^a-z0-9\u00c0-\uffff]+/)
        let worst = 0, sum = 0, ok = true
        for (const t of terms) {
            const f = fit(n, words, t)
            if (f < 0) { ok = false; break }
            worst = Math.max(worst, f); sum += f
        }
        if (ok) hits.push({ x: all[k], w: worst, s: sum, l: n.length, k: k })
    }
    hits.sort((a, b) => (a.w - b.w) || (a.s - b.s) || (a.l - b.l) || (a.k - b.k))
    return hits.slice(0, limit || 360).map(h => h.x)
}
