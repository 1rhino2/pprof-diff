module html_out;

import diff;
import std.format : format;

string toHtml(const DiffResult res, string beforePath, string afterPath)
{
    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>pprof-diff report</title>
<style>
body { font-family: ui-sans-serif, system-ui, sans-serif; margin: 24px; color: #111; background: #f6f6f4; }
h1 { font-size: 1.4rem; margin: 0 0 8px; }
.meta { color: #444; margin-bottom: 20px; font-size: 0.9rem; }
section { margin-bottom: 28px; background: #fff; border: 1px solid #ccc; border-radius: 6px; padding: 12px 16px; }
h2 { font-size: 1rem; margin: 0 0 10px; }
table { width: 100%; border-collapse: collapse; font-size: 0.88rem; }
th, td { text-align: left; padding: 6px 8px; border-bottom: 1px solid #e5e5e2; }
th { color: #333; font-weight: 600; }
.num { text-align: right; font-variant-numeric: tabular-nums; }
.pos { color: #9a3412; }
.neg { color: #166534; }
</style>
</head>
<body>
<h1>pprof-diff</h1>
<div class="meta">before: ` ~ escape(beforePath) ~ ` &nbsp;|&nbsp; after: ` ~ escape(afterPath) ~ `</div>
` ~ section("Grew (bytes)", res.grew) ~
section("Shrank", res.shrank) ~
section("Vanished", res.vanished) ~
section("Appeared", res.appeared) ~
`</body></html>
`;
}

private string section(string title, const Delta[] rows)
{
    string h = `<section><h2>` ~ escape(title) ~ `</h2><table>
<thead><tr><th>#</th><th>Key</th><th class="num">Δ bytes</th><th class="num">Δ objs</th></tr></thead><tbody>`;
    if (rows.length == 0)
        return h ~ `<tr><td colspan="4">(none)</td></tr></tbody></table></section>`;
    string body;
    foreach (i, d; rows)
    {
        string bc = d.dBytes >= 0 ? "pos" : "neg";
        string oc = d.dObjects >= 0 ? "pos" : "neg";
        body ~= `<tr><td>` ~ format("%d", i + 1) ~ `</td><td>` ~ escape(d.key) ~
            `</td><td class="num ` ~ bc ~ `">` ~ escape(formatDelta(d.dBytes)) ~
            `</td><td class="num ` ~ oc ~ `">` ~ escape(formatCount(d.dObjects)) ~ `</td></tr>`;
    }
    return h ~ body ~ `</tbody></table></section>`;
}

private string escape(string s)
{
    string o;
    foreach (c; s)
    {
        switch (c)
        {
        case '<': o ~= "&lt;"; break;
        case '>': o ~= "&gt;"; break;
        case '&': o ~= "&amp;"; break;
        default: o ~= c; break;
        }
    }
    return o;
}
