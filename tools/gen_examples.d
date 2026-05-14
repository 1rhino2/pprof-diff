import std.file;
import std.stdio;
import model;
import fixture;
import encode;
import gzip;

void main()
{
    auto before = makeHeapProfile([
        HeapEntry("main.leaky", 10L, 40960L),
        HeapEntry("main.stable", 4L, 1024L),
        HeapEntry("runtime.mallocgc", 2L, 512L),
    ]);

    auto after = makeHeapProfile([
        HeapEntry("main.leaky", 40L, 163840L),
        HeapEntry("main.stable", 4L, 1024L),
        HeapEntry("bufio.NewReaderSize", 6L, 24576L),
    ]);

    auto spike = makeHeapProfile([
        HeapEntry("main.leaky", 100L, 409600L),
        HeapEntry("main.stable", 4L, 1024L),
    ]);

    auto dir = "examples";
    if (!exists(dir))
        mkdir(dir);
    writeProfile(dir ~ "/before.prof", before);
    writeProfile(dir ~ "/after.prof", after);
    writeProfile(dir ~ "/spike.prof", spike);
    writeln("wrote examples/*.prof");
}

void writeProfile(string path, const Profile pf)
{
    std.file.write(path, compress(encodeProfile(pf)));
}
