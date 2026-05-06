module app;

import std.conv : to;
import std.file;
import std.stdio;
import model;
import pprof;
import diff;
import json_out;
import html_out;

int main(string[] args)
{
    if (args.length < 3)
    {
        stderr.writeln("usage: pprof-diff before.prof after.prof [--top N] [--by stack|leaf|type] [--json out.json] [--html out.html]");
        return 1;
    }

    string beforePath = args[1];
    string afterPath = args[2];
    size_t topN = 20;
    string keyMode = "stack";
    string jsonPath;
    string htmlPath;

    foreach (i; 2 .. args.length)
    {
        if (args[i] == "--top" && i + 1 < args.length)
        {
            topN = cast(size_t) to!ulong(args[++i]);
            continue;
        }
        if (args[i] == "--by" && i + 1 < args.length)
        {
            keyMode = args[++i];
            continue;
        }
        if (args[i] == "--json" && i + 1 < args.length)
        {
            jsonPath = args[++i];
            continue;
        }
        if (args[i] == "--html" && i + 1 < args.length)
        {
            htmlPath = args[++i];
            continue;
        }
    }

    if (keyMode != "stack" && keyMode != "leaf" && keyMode != "type")
    {
        stderr.writeln("--by must be stack, leaf, or type");
        return 1;
    }

    Profile before;
    Profile after;
    try
    {
        before = loadProfile(beforePath);
        after = loadProfile(afterPath);
    }
    catch (Exception e)
    {
        stderr.writeln("error: ", e.msg);
        return 1;
    }

    auto result = diffProfiles(before, after, keyMode);
    auto text = renderText(result, topN);
    write(text);

    if (jsonPath.length)
        std.file.write(jsonPath, toJson(result));
    if (htmlPath.length)
        std.file.write(htmlPath, toHtml(result, beforePath, afterPath));

    return 0;
}
