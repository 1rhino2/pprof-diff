import std.file : read;
import std.stdio;
import model;
import fixture;
import encode;
import parse;
import aggregate;
import diff;
import pprof;

void main()
{
    runRoundTrip();
    runGoldenDiff();
    writeln("ok: all tests passed");
}

void runRoundTrip()
{
    auto pf = makeHeapProfile([
        HeapEntry("alpha.fn", 3L, 300L),
        HeapEntry("beta.fn", 1L, 100L),
    ]);
    auto back = parseProfile(encodeProfile(pf));
    auto map = aggregateProfileAuto(back, "leaf");
    assert(map["alpha.fn"].objects == 3);
    assert(map["alpha.fn"].bytes == 300);
}

void runGoldenDiff()
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

    auto res = diffProfiles(before, after, "leaf");
    auto text = renderText(res, 20);
    auto expected = cast(string) read("test/golden_expected.txt");
    assert(text == expected, "golden text mismatch");

    auto grewTop = res.grew[0];
    assert(grewTop.key == "main.leaky");
    assert(grewTop.dBytes == 122880);
    assert(grewTop.dObjects == 30);
}
