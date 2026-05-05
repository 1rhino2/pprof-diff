module diff;

import aggregate;
import model;
import std.format;

struct Delta
{
    string key;
    long dBytes;
    long dObjects;
    long beforeBytes;
    long afterBytes;
    long beforeObjects;
    long afterObjects;
}

struct DiffResult
{
    Delta[] grew;
    Delta[] shrank;
    Delta[] vanished;
    Delta[] appeared;
}

DiffResult diffProfiles(const Profile before, const Profile after, string keyMode)
{
    auto a = aggregateProfileAuto(before, keyMode);
    auto b = aggregateProfileAuto(after, keyMode);
    DiffResult res;

    foreach (k, tb; a)
    {
        if (k !in b)
        {
            res.vanished ~= Delta(k, -tb.bytes, -tb.objects, tb.bytes, 0, tb.objects, 0);
            continue;
        }
        auto ta = b[k];
        long db = ta.bytes - tb.bytes;
        long dobj = ta.objects - tb.objects;
        if (db == 0 && dobj == 0)
            continue;
        auto d = Delta(k, db, dobj, tb.bytes, ta.bytes, tb.objects, ta.objects);
        if (db > 0 || dobj > 0)
            res.grew ~= d;
        else
            res.shrank ~= d;
    }

    foreach (k, ta; b)
    {
        if (k !in a)
            res.appeared ~= Delta(k, ta.bytes, ta.objects, 0, ta.bytes, 0, ta.objects);
    }

    sortByBytes(res.grew);
    sortByBytes(res.shrank);
    sortByBytes(res.vanished);
    sortByBytes(res.appeared);
    return res;
}

void sortByBytes(ref Delta[] list)
{
    import std.algorithm : sort;
    list.sort!((x, y) => abs64(x.dBytes) > abs64(y.dBytes));
}

long abs64(long v) @safe
{
    return v < 0 ? -v : v;
}

string formatBytes(long n) @safe
{
    string[] units = ["B", "KiB", "MiB", "GiB"];
    double v = cast(double)n;
    size_t u = 0;
    while (v >= 1024.0 && u + 1 < units.length)
    {
        v /= 1024.0;
        u++;
    }
    if (u == 0)
        return format("%d %s", n, units[0]);
    return format("%.1f %s", v, units[u]);
}

string formatDelta(long n) @safe
{
    if (n > 0)
        return "+" ~ formatBytes(n);
    if (n < 0)
        return "-" ~ formatBytes(-n);
    return "0 B";
}

string formatCount(long n) @safe
{
    if (n > 0)
        return "+" ~ format("%d", n);
    if (n < 0)
        return format("%d", n);
    return "0";
}

string renderText(in DiffResult res, size_t topN)
{
    string text;
    text ~= "pprof-diff\n";
    text ~= "==========\n\n";

    void section(string title, const(Delta)[] items, string sign)
    {
        text ~= title ~ "\n";
        text ~= replicate("-", title.length) ~ "\n";
        if (items.length == 0)
        {
            text ~= "(none)\n\n";
            return;
        }
        size_t n = topN == 0 ? items.length : topN;
        if (n > items.length)
            n = items.length;
        foreach (i; 0 .. n)
        {
            auto d = items[i];
            text ~= format("%3d  %-48s  %8s bytes  %8s objs\n",
                i + 1, trimKey(d.key, 48), formatDelta(d.dBytes), formatCount(d.dObjects));
        }
        if (items.length > n)
            text ~= format("... %d more\n", items.length - n);
        text ~= "\n";
    }

    section("Top regressions (bytes)", res.grew, "+");
    section("Top improvements (bytes)", res.shrank, "-");
    section("Disappeared since before", res.vanished, "-");
    section("New since before", res.appeared, "+");

    text ~= "Top regressions (object count)\n";
    text ~= "--------------------------------\n";
    Delta[] byObj = res.grew.dup;
    import std.algorithm : sort;
    byObj.sort!((x, y) => abs64(x.dObjects) > abs64(y.dObjects));
    size_t n2 = topN == 0 ? byObj.length : topN;
    if (n2 > byObj.length)
        n2 = byObj.length;
    foreach (i; 0 .. n2)
    {
        auto d = byObj[i];
        text ~= format("%3d  %-48s  %8s bytes  %8s objs\n",
            i + 1, trimKey(d.key, 48), formatDelta(d.dBytes), formatCount(d.dObjects));
    }
    text ~= "\n";
    return text;
}

private string trimKey(string k, size_t maxLen)
{
    if (k.length <= maxLen)
        return k;
    if (maxLen <= 3)
        return k[0 .. maxLen];
    return k[0 .. maxLen - 3] ~ "...";
}

private string replicate(string s, size_t n)
{
    string r;
    foreach (_; 0 .. n)
        r ~= s;
    return r;
}
