module encode;

import model;

ubyte[] encodeProfile(const Profile pf)
{
    ubyte[] buf;
    foreach (vt; pf.sampleTypes)
        writeMsg(buf, 1, encodeValueType(vt));
    foreach (s; pf.samples)
        writeMsg(buf, 2, encodeSample(s));
    foreach (loc; pf.locations)
        writeMsg(buf, 4, encodeLocation(loc));
    foreach (fn; pf.functions)
        writeMsg(buf, 5, encodeFunction(fn));
    foreach (str; pf.stringTable)
        writeMsg(buf, 6, cast(ubyte[]) str);
    return buf;
}

private ubyte[] encodeValueType(const ValueType vt)
{
    ubyte[] b;
    writeVarintField(b, 1, vt.typeIdx);
    writeVarintField(b, 2, vt.unitIdx);
    return b;
}

private ubyte[] encodeSample(const PSample s)
{
    ubyte[] b;
    writePackedVarints(b, 1, s.locationIds);
    writePackedVarints(b, 2, s.values);
    return b;
}

private ubyte[] encodeLocation(const PLocation loc)
{
    ubyte[] b;
    writeVarintField(b, 1, loc.id);
    foreach (ln; loc.lines)
        writeMsg(b, 4, encodeLine(ln));
    return b;
}

private ubyte[] encodeLine(const PLine ln)
{
    ubyte[] b;
    writeVarintField(b, 1, ln.functionId);
    return b;
}

private ubyte[] encodeFunction(const PFunction fn)
{
    ubyte[] b;
    writeVarintField(b, 1, fn.id);
    writeVarintField(b, 2, fn.nameIdx);
    return b;
}

private void writeMsg(ref ubyte[] dest, uint fieldNum, const(ubyte)[] payload)
{
    ubyte[] tag;
    writeVarint(tag, (fieldNum << 3) | 2);
    ubyte[] len;
    writeVarint(len, payload.length);
    dest ~= tag;
    dest ~= len;
    dest ~= payload;
}

private void writeVarintField(ref ubyte[] dest, uint fieldNum, long v)
{
    ubyte[] tag;
    writeVarint(tag, (fieldNum << 3) | 0);
    ubyte[] val;
    writeVarint(val, v);
    dest ~= tag;
    dest ~= val;
}

private void writePackedVarints(ref ubyte[] dest, uint fieldNum, const(long)[] vals)
{
    ubyte[] payload;
    foreach (v; vals)
        writeVarint(payload, v);
    writeMsg(dest, fieldNum, payload);
}

private void writeVarint(ref ubyte[] dest, long v)
{
    ulong u = v >= 0 ? cast(ulong)v : cast(ulong)v;
    while (u >= 0x80)
    {
        dest ~= cast(ubyte)((u & 0x7F) | 0x80);
        u >>= 7;
    }
    dest ~= cast(ubyte)u;
}
