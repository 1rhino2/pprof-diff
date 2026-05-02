module gzip;

import etc.c.zlib;

enum : int
{
    Z_OK = 0,
    Z_STREAM_END = 1,
    Z_BUF_ERROR = -5
}

ubyte[] decompress(const(ubyte)[] input)
{
    if (input.length >= 2 && input[0] == 0x1F && input[1] == 0x8B)
        return gunzip(input);
    return input.dup;
}

ubyte[] compress(const(ubyte)[] plain)
{
    return gzipWrap(plain);
}

private ubyte[] gunzip(const(ubyte)[] input)
{
    size_t pos = 10;
    ubyte flg = input[3];
    if (flg & 4)
    {
        ushort xlen = cast(ushort)(input[pos] | (input[pos + 1] << 8));
        pos += 2 + xlen;
    }
    if (flg & 8)
        while (pos < input.length && input[pos++] != 0) {}
    if (flg & 16)
        while (pos < input.length && input[pos++] != 0) {}
    if (flg & 2)
        pos += 2;
    return inflateRawDeflate(input[pos .. input.length - 8]);
}

private ubyte[] gzipWrap(const(ubyte)[] plain)
{
    auto deflated = deflateRaw(plain);
    ubyte[] buf;
    buf ~= [0x1F, 0x8B, 8, 0];
    buf ~= [0, 0, 0, 0];
    buf ~= [0, 0xFF];
    buf ~= deflated;
    uint crc = crc32(plain);
    uint isize = cast(uint)plain.length;
    buf ~= cast(ubyte)(crc);
    buf ~= cast(ubyte)(crc >> 8);
    buf ~= cast(ubyte)(crc >> 16);
    buf ~= cast(ubyte)(crc >> 24);
    buf ~= cast(ubyte)(isize);
    buf ~= cast(ubyte)(isize >> 8);
    buf ~= cast(ubyte)(isize >> 16);
    buf ~= cast(ubyte)(isize >> 24);
    return buf;
}

private ubyte[] inflateRawDeflate(const(ubyte)[] src)
{
    ubyte[] buf;
    buf.length = src.length * 4 + 256;

    z_stream zs;
    zs.zalloc = null;
    zs.zfree = null;
    zs.opaque = null;
    zs.next_in = cast(ubyte*)src.ptr;
    zs.avail_in = cast(uint)src.length;
    zs.next_out = buf.ptr;
    zs.avail_out = cast(uint)buf.length;

    if (inflateInit2(&zs, -15) != Z_OK)
        throw new Exception("gzip: inflateInit2 failed");
    scope (exit) inflateEnd(&zs);

    for (;;)
    {
        int err = inflate(&zs, 0);
        if (err == Z_STREAM_END)
        {
            buf.length = buf.length - zs.avail_out;
            return buf;
        }
        if (err != Z_OK && err != Z_BUF_ERROR)
            throw new Exception("gzip: inflate failed");
        if (zs.avail_out == 0)
        {
            size_t used = buf.length;
            buf.length = buf.length * 2;
            zs.next_out = buf.ptr + used;
            zs.avail_out = cast(uint)(buf.length - used);
        }
    }
}

private ubyte[] deflateRaw(const(ubyte)[] src)
{
    ubyte[] buf;
    buf.length = src.length + 64;

    z_stream zs;
    zs.zalloc = null;
    zs.zfree = null;
    zs.opaque = null;
    zs.next_in = cast(ubyte*)src.ptr;
    zs.avail_in = cast(uint)src.length;
    zs.next_out = buf.ptr;
    zs.avail_out = cast(uint)buf.length;

    if (deflateInit2(&zs, 9, 8, -15, 8, 0) != Z_OK)
        throw new Exception("gzip: deflateInit2 failed");
    scope (exit) deflateEnd(&zs);
    if (deflate(&zs, 4) != 1)
        throw new Exception("gzip: deflate failed");
    buf.length = buf.length - zs.avail_out;
    return buf;
}

private uint crc32(const(ubyte)[] data)
{
    uint c = 0xFFFFFFFF;
    foreach (b; data)
    {
        c ^= b;
        foreach (_; 0 .. 8)
            c = (c >> 1) ^ (0xEDB88320 & (~(c & 1) + 1));
    }
    return ~c;
}
