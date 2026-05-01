module model;

struct ValueType
{
    long typeIdx;
    long unitIdx;
}

struct PFunction
{
    long id;
    long nameIdx;
    long systemNameIdx;
    long filenameIdx;
}

struct PLine
{
    long functionId;
}

struct PLocation
{
    long id;
    PLine[] lines;
}

struct PSample
{
    long[] locationIds;
    long[] values;
}

struct Profile
{
    ValueType[] sampleTypes;
    string[] stringTable;
    PSample[] samples;
    PLocation[] locations;
    PFunction[] functions;
}
