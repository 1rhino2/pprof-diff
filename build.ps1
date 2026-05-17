$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
dub build --build=release
dub build --config=golden-test --build=release
dub build --config=gen-examples --build=release
dub run --config=gen-examples --build=release
dub run --config=golden-test --build=release
Write-Host "built: dub run -- examples/before.prof examples/after.prof"
