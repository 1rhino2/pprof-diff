module pprof;

import model;
import parse;
import gzip;
import std.file : read;

Profile loadProfile(string path)
{
    auto raw = cast(ubyte[]) read(path);
    auto plain = decompress(raw);
    return parseProfile(plain);
}

string profileString(const Profile pf, long idx)
{
    if (idx < 0 || cast(size_t)idx >= pf.stringTable.length)
        return "<unknown>";
    return pf.stringTable[cast(size_t)idx];
}

string functionName(const Profile pf, long functionId)
{
    foreach (fn; pf.functions)
    {
        if (fn.id != functionId)
            continue;
        auto n = pickName(pf, fn.nameIdx);
        if (n.length)
            return n;
        n = pickName(pf, fn.systemNameIdx);
        if (n.length)
            return n;
        n = pickName(pf, fn.filenameIdx);
        if (n.length)
            return shortSymbol(n);
        return "<unnamed>";
    }
    return "<fn?>";
}

private string pickName(const Profile pf, long idx)
{
    if (idx <= 0)
        return "";
    return profileString(pf, idx);
}

private string shortSymbol(string path)
{
    auto p = findChar(path, '/');
    while (p >= 0)
    {
        auto next = findChar(path, '/', cast(size_t)(p + 1));
        if (next < 0)
            break;
        p = next;
    }
    if (p >= 0 && p + 1 < path.length)
        return path[cast(size_t)(p + 1) .. $];
    return path;
}

string locationFrame(const Profile pf, long locationId)
{
    foreach (loc; pf.locations)
    {
        if (loc.id != locationId)
            continue;
        if (loc.lines.length == 0)
            return "<unknown>";
        auto leaf = loc.lines[$ - 1].functionId;
        auto n = functionName(pf, leaf);
        return n.length ? n : "<unknown>";
    }
    return "<loc?>";
}

string sampleStackKey(const Profile pf, in PSample s, string mode)
{
    if (s.locationIds.length == 0)
        return "<empty>";

    if (mode == "leaf")
        return locationFrame(pf, s.locationIds[0]);

    string key;
    foreach (lid; s.locationIds)
    {
        if (key.length)
            key ~= " <- ";
        key ~= locationFrame(pf, lid);
    }
    return key;
}

string sampleTypeKey(const Profile pf, in PSample s)
{
    auto leaf = locationFrame(pf, s.locationIds.length ? s.locationIds[0] : 0);
    auto t = extractTypeName(leaf);
    return t.length ? t : leaf;
}

private string extractTypeName(string sym)
{
    auto p = findChar(sym, '[');
    if (p >= 0)
    {
        auto q = findChar(sym, ']', cast(size_t)(p + 1));
        if (q > p)
            return sym[cast(size_t)(p + 1) .. cast(size_t)q];
    }
    p = findStr(sym, "::");
    if (p >= 0)
        return sym[cast(size_t)(p + 2) .. $];
    p = findChar(sym, '.');
    if (p >= 0 && p + 1 < sym.length)
        return sym[cast(size_t)(p + 1) .. $];
    return sym;
}

private ptrdiff_t findChar(string s, dchar c, size_t start = 0)
{
    foreach (i; start .. s.length)
        if (s[i] == c)
            return cast(ptrdiff_t)i;
    return -1;
}

private ptrdiff_t findStr(string hay, string needle)
{
    if (needle.length > hay.length)
        return -1;
    foreach (i; 0 .. hay.length - needle.length + 1)
        if (hay[i .. i + needle.length] == needle)
            return cast(ptrdiff_t)i;
    return -1;
}
