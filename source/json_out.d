module json_out;

import diff;

string toJson(const DiffResult res)
{
    string body = "{\n";
    body ~= `  "grew": [` ~ deltasJson(res.grew) ~ "],\n";
    body ~= `  "shrank": [` ~ deltasJson(res.shrank) ~ "],\n";
    body ~= `  "vanished": [` ~ deltasJson(res.vanished) ~ "],\n";
    body ~= `  "appeared": [` ~ deltasJson(res.appeared) ~ "]\n";
    body ~= "}\n";
    return body;
}

private string deltasJson(const Delta[] list)
{
    string[] parts;
    foreach (d; list)
    {
        parts ~= "    {\n" ~
            `      "key": "` ~ escapeJson(d.key) ~ `",` ~ "\n" ~
            `      "d_bytes": ` ~ formatLong(d.dBytes) ~ ",\n" ~
            `      "d_objects": ` ~ formatLong(d.dObjects) ~ ",\n" ~
            `      "before_bytes": ` ~ formatLong(d.beforeBytes) ~ ",\n" ~
            `      "after_bytes": ` ~ formatLong(d.afterBytes) ~ ",\n" ~
            `      "before_objects": ` ~ formatLong(d.beforeObjects) ~ ",\n" ~
            `      "after_objects": ` ~ formatLong(d.afterObjects) ~ "\n" ~
            "    }";
    }
    if (parts.length == 0)
        return "";
    string chunk;
    foreach (i, p; parts)
    {
        if (i)
            chunk ~= ",\n";
        chunk ~= p;
    }
    return "\n" ~ chunk ~ "\n  ";
}

private string escapeJson(string s)
{
    string o;
    foreach (c; s)
    {
        switch (c)
        {
        case '"': o ~= `\"`; break;
        case '\\': o ~= `\\`; break;
        case '\n': o ~= `\n`; break;
        case '\r': o ~= `\r`; break;
        case '\t': o ~= `\t`; break;
        default: o ~= c; break;
        }
    }
    return o;
}

private string formatLong(long v)
{
    import std.format : format;
    return format("%d", v);
}
