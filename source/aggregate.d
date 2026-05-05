module aggregate;

import model;
import pprof;

struct Totals
{
    long bytes;
    long objects;
}

Totals[string] aggregateProfile(const Profile pf, string keyMode)
{
    Totals[string] map;
    auto cols = heapColumns(pf);

    foreach (s; pf.samples)
    {
        if (cols.objIdx >= s.values.length || cols.byteIdx >= s.values.length)
            continue;
        long objs = s.values[cols.objIdx];
        long bytes = s.values[cols.byteIdx];
        if (objs == 0 && bytes == 0)
            continue;

        string key;
        switch (keyMode)
        {
        case "type":
            key = sampleTypeKey(pf, s);
            break;
        case "leaf":
            key = sampleStackKey(pf, s, "leaf");
            break;
        default:
            key = sampleStackKey(pf, s, "stack");
            break;
        }
        if (!(key in map))
            map[key] = Totals();
        map[key].objects += objs;
        map[key].bytes += bytes;
    }
    return map;
}

Totals[string] aggregateProfileAuto(const Profile pf, string keyMode)
{
    return aggregateProfile(pf, keyMode);
}

struct HeapColumns
{
    size_t objIdx = size_t.max;
    size_t byteIdx = size_t.max;
}

private HeapColumns heapColumns(const Profile pf)
{
    HeapColumns c;
    foreach (i, vt; pf.sampleTypes)
    {
        auto t = lower(profileString(pf, vt.typeIdx));
        if (hasSubstr(t, "inuse") && hasSubstr(t, "object"))
            c.objIdx = i;
        if (hasSubstr(t, "inuse") && (hasSubstr(t, "space") || hasSubstr(t, "byte")))
            c.byteIdx = i;
    }
    if (c.objIdx == size_t.max || c.byteIdx == size_t.max)
    {
        foreach (i, vt; pf.sampleTypes)
        {
            auto t = lower(profileString(pf, vt.typeIdx));
            if (c.objIdx == size_t.max && hasSubstr(t, "object"))
                c.objIdx = i;
            if (c.byteIdx == size_t.max && (hasSubstr(t, "space") || hasSubstr(t, "byte")))
                c.byteIdx = i;
        }
    }
    if (pf.sampleTypes.length == 4)
    {
        if (c.objIdx == size_t.max)
            c.objIdx = 2;
        if (c.byteIdx == size_t.max)
            c.byteIdx = 3;
    }
    if (c.objIdx == size_t.max && pf.sampleTypes.length >= 2)
        c.objIdx = pf.sampleTypes.length - 2;
    if (c.byteIdx == size_t.max && pf.sampleTypes.length >= 1)
        c.byteIdx = pf.sampleTypes.length - 1;
    return c;
}

private string lower(string s)
{
    char[] buf = s.dup;
    foreach (ref c; buf)
        if (c >= 'A' && c <= 'Z')
            c = cast(char)(c - 'A' + 'a');
    return cast(string) buf;
}

private bool hasSubstr(string hay, string needle)
{
    return findIndex(hay, needle) >= 0;
}

private ptrdiff_t findIndex(string hay, string needle)
{
    if (needle.length == 0)
        return 0;
    if (needle.length > hay.length)
        return -1;
    foreach (i; 0 .. hay.length - needle.length + 1)
    {
        if (hay[i .. i + needle.length] == needle)
            return cast(ptrdiff_t)i;
    }
    return -1;
}
