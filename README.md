# pprof-diff

Diff two Go heap profiles and see what grew, what shrank, and what disappeared. One command, plain text (plus optional JSON and HTML).

```
pprof-diff before.prof after.prof --top 20 --by leaf
```

```
pprof-diff
==========

Top regressions (bytes)
-----------------------
  1  main.leaky                                        +120.0 KiB bytes       +30 objs

Top improvements (bytes)
------------------------
(none)

Disappeared since before
------------------------
  1  runtime.mallocgc                                    -512 B bytes        -2 objs

New since before
----------------
  1  bufio.NewReaderSize                               +24.0 KiB bytes        +6 objs
```

## Why this exists

`go tool pprof -base=before after` is the right tool for interactive investigation. **pprof-diff** is for when you want a **fixed report**: paste into a PR, gate CI on a text diff, or answer "what changed?" without opening the pprof TUI.

| | pprof-diff | `go tool pprof -base` |
|---|:---:|:---:|
| Text diff report | yes | via `top` / export |
| JSON / static HTML | yes | no |
| Flame graphs | no | yes |
| Single static binary | yes (D) | via Go install |

## Install

Requires [DMD](https://dlang.org/download.html) 2.111+ and [DUB](https://dub.pm/).

```powershell
git clone https://github.com/1rhino2/pprof-diff.git
cd pprof-diff
dub build --build=release
```

Binary: `.dub/pprof-diff.exe` (path varies by platform) or run with `dub run --`.

## Usage

```text
pprof-diff before.prof after.prof [options]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--top N` | 20 | Max rows per section |
| `--by stack` | stack | Group by full stack, `leaf`, or rough `type` |
| `--json path` | | Write machine-readable diff |
| `--html path` | | Write single-page HTML table |

### Synthetic examples (repo)

```powershell
dub run --config=gen-examples
dub run -- examples/before.prof examples/after.prof --top 10
dub run -- examples/before.prof examples/after.prof --html examples/report.html --json examples/diff.json
```

### Real Go heap profiles

```powershell
cd examples/go
go run leak.go
cd ../..
dub run -- examples/go/before.prof examples/go/after.prof --by leaf
```

From tests or production:

```bash
go test -memprofile=before.prof -run=YourBench .
# change code
go test -memprofile=after.prof -run=YourBench .
pprof-diff before.prof after.prof --top 30
```

Profiles must be **pprof protobuf** (gzip-compressed `.prof` from Go is supported).

## How it works

1. Gunzip if the file starts with `1F 8B`.
2. Decode the `Profile` message (subset of [google/pprof](https://github.com/google/pprof); unknown fields skipped).
3. Pick `inuse_objects` / `inuse_space` columns when present.
4. Aggregate by stack key, diff before vs after, sort by byte delta.

See `proto/profile.proto` for the wire schema.

## Development

```powershell
.\build.ps1          # release build, tests, regenerate examples
dub run --config=golden-test
```

## Limits

- Optimized for **heap** profiles (object count + bytes). CPU and other profile types are best-effort.
- Symbol quality depends on the profile (stripped binaries give weaker names).
- For deep dives, use `go tool pprof`.

## License

MIT. See [LICENSE](LICENSE).
