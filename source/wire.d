module wire;

struct PbReader
{
    const(ubyte)[] data;
    size_t pos;

    this(const(ubyte)[] buf)
    {
        data = buf;
        pos = 0;
    }

    bool empty() const @safe
    {
        return pos >= data.length;
    }

    bool readTag(out uint fieldNum, out ubyte wireType) @safe
    {
        if (empty)
            return false;
        ulong v = readVarint();
        if (v == ulong.max)
            return false;
        fieldNum = cast(uint)(v >> 3);
        wireType = cast(ubyte)(v & 7);
        return true;
    }

    ulong readVarint() @safe
    {
        ulong result = 0;
        uint shift = 0;
        while (pos < data.length && shift < 64)
        {
            ubyte b = data[pos++];
            result |= (cast(ulong)(b & 0x7F) << shift);
            if ((b & 0x80) == 0)
                return result;
            shift += 7;
        }
        return ulong.max;
    }

    const(ubyte)[] readLengthDelimited() @safe
    {
        ulong len = readVarint();
        if (len == ulong.max || pos + len > data.length)
            return null;
        auto slice = data[pos .. pos + cast(size_t)len];
        pos += cast(size_t)len;
        return slice;
    }

    void skipField(ubyte wireType) @safe
    {
        switch (wireType)
        {
        case 0:
            readVarint();
            break;
        case 1:
            pos += 8;
            break;
        case 2:
            readLengthDelimited();
            break;
        case 5:
            pos += 4;
            break;
        default:
            pos = data.length;
            break;
        }
    }
}
