module fixture;

import model;

struct HeapEntry
{
    string name;
    long objects;
    long bytes;
}

Profile makeHeapProfile(const HeapEntry[] entries, string[] extraStrings = null)
{
    Profile pf;
    pf.stringTable ~= "";
    {
        ValueType vt;
        vt.typeIdx = 1;
        vt.unitIdx = 2;
        pf.sampleTypes ~= vt;
    }
    {
        ValueType vt;
        vt.typeIdx = 3;
        vt.unitIdx = 4;
        pf.sampleTypes ~= vt;
    }
    pf.stringTable ~= "objects";
    pf.stringTable ~= "count";
    pf.stringTable ~= "space";
    pf.stringTable ~= "bytes";

    if (extraStrings)
        foreach (s; extraStrings)
            pf.stringTable ~= s;

    long nextFn = 1;
    long nextLoc = 1;
    long[string] fnCache;

    foreach (e; entries)
    {
        long fnId = 0;
        if (e.name in fnCache)
            fnId = fnCache[e.name];
        if (fnId == 0)
        {
            fnId = nextFn++;
            fnCache[e.name] = fnId;
            PFunction fn;
            fn.id = fnId;
            fn.nameIdx = cast(long)pf.stringTable.length;
            pf.stringTable ~= e.name;
            pf.functions ~= fn;
        }

        PLocation loc;
        loc.id = nextLoc++;
        PLine ln;
        ln.functionId = fnId;
        loc.lines ~= ln;

        PSample s;
        s.locationIds ~= loc.id;
        s.values ~= e.objects;
        s.values ~= e.bytes;
        pf.samples ~= s;
        pf.locations ~= loc;
    }
    return pf;
}
