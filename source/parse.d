module parse;

import model;
import wire;

Profile parseProfile(const(ubyte)[] raw)
{
    Profile pf;

    auto r = new PbReader(raw);
    uint fieldNum;
    ubyte wireType;
    while (r.readTag(fieldNum, wireType))
    {
        switch (fieldNum)
        {
        case 1:
            pf.sampleTypes ~= parseValueType(r.readLengthDelimited());
            break;
        case 2:
            pf.samples ~= parseSample(r.readLengthDelimited());
            break;
        case 3:
            r.skipField(wireType);
            break;
        case 4:
            pf.locations ~= parseLocation(r.readLengthDelimited());
            break;
        case 5:
            pf.functions ~= parseFunction(r.readLengthDelimited());
            break;
        case 6:
            pf.stringTable ~= parseStringEntry(r.readLengthDelimited());
            break;
        default:
            r.skipField(wireType);
            break;
        }
    }
    return pf;
}

private ValueType parseValueType(const(ubyte)[] buf)
{
    ValueType vt;
    auto r = new PbReader(buf);
    uint fieldNum;
    ubyte wireType;
    while (r.readTag(fieldNum, wireType))
    {
        switch (fieldNum)
        {
        case 1:
            vt.typeIdx = cast(long)r.readVarint();
            break;
        case 2:
            vt.unitIdx = cast(long)r.readVarint();
            break;
        default:
            r.skipField(wireType);
            break;
        }
    }
    return vt;
}

private PSample parseSample(const(ubyte)[] buf)
{
    PSample s;
    auto r = new PbReader(buf);
    uint fieldNum;
    ubyte wireType;
    while (r.readTag(fieldNum, wireType))
    {
        switch (fieldNum)
        {
        case 1:
            if (wireType == 2)
            {
                foreach (v; parsePackedVarints(r.readLengthDelimited()))
                    s.locationIds ~= cast(long)v;
            }
            else
                s.locationIds ~= cast(long)r.readVarint();
            break;
        case 2:
            if (wireType == 2)
            {
                foreach (v; parsePackedVarints(r.readLengthDelimited()))
                    s.values ~= cast(long)v;
            }
            else
                s.values ~= cast(long)r.readVarint();
            break;
        default:
            r.skipField(wireType);
            break;
        }
    }
    return s;
}

private ulong[] parsePackedVarints(const(ubyte)[] buf)
{
    ulong[] vals;
    auto r = new PbReader(buf);
    while (!r.empty)
        vals ~= r.readVarint();
    return vals;
}

private PLocation parseLocation(const(ubyte)[] buf)
{
    PLocation loc;
    auto r = new PbReader(buf);
    uint fieldNum;
    ubyte wireType;
    while (r.readTag(fieldNum, wireType))
    {
        switch (fieldNum)
        {
        case 1:
            loc.id = cast(long)r.readVarint();
            break;
        case 4:
            loc.lines ~= parseLine(r.readLengthDelimited());
            break;
        default:
            r.skipField(wireType);
            break;
        }
    }
    return loc;
}

private PLine parseLine(const(ubyte)[] buf)
{
    PLine ln;
    auto r = new PbReader(buf);
    uint fieldNum;
    ubyte wireType;
    while (r.readTag(fieldNum, wireType))
    {
        switch (fieldNum)
        {
        case 1:
            ln.functionId = cast(long)r.readVarint();
            break;
        default:
            r.skipField(wireType);
            break;
        }
    }
    return ln;
}

private PFunction parseFunction(const(ubyte)[] buf)
{
    PFunction fn;
    auto r = new PbReader(buf);
    uint fieldNum;
    ubyte wireType;
    while (r.readTag(fieldNum, wireType))
    {
        switch (fieldNum)
        {
        case 1:
            fn.id = cast(long)r.readVarint();
            break;
        case 2:
            fn.nameIdx = cast(long)r.readVarint();
            break;
        case 3:
            fn.systemNameIdx = cast(long)r.readVarint();
            break;
        case 4:
            fn.filenameIdx = cast(long)r.readVarint();
            break;
        default:
            r.skipField(wireType);
            break;
        }
    }
    return fn;
}

private string parseStringEntry(const(ubyte)[] buf)
{
    return cast(string) buf.idup;
}
