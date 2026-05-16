$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
go run leak.go
Write-Host "Wrote before.prof and after.prof in examples/go/"
Write-Host "From repo root:"
Write-Host "  dub run -- examples/go/before.prof examples/go/after.prof --top 20 --by leaf"
