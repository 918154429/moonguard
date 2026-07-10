param(
  [switch]$Json
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$fixtureRoot = Join-Path $repoRoot 'fixtures\real'
$cli = Join-Path $repoRoot '_build\js\debug\build\cmd\main\main.js'

if (-not (Test-Path -LiteralPath $cli)) {
  throw "MoonGuard JS CLI not found at $cli. Build it with: moon run --target js cmd/main -- --help"
}

$rows = foreach ($directory in Get-ChildItem -LiteralPath $fixtureRoot -Directory | Sort-Object Name) {
  $fixture = Join-Path $directory.FullName 'pkg.generated.mbti'
  $output = & node $cli inventory-dir $directory.FullName --format json 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "inventory-dir failed for $($directory.Name): $($output -join [Environment]::NewLine)"
  }

  $inventory = ($output -join [Environment]::NewLine) | ConvertFrom-Json
  $unknown = $inventory.kind_counts |
    Where-Object kind -eq 'unknown' |
    Select-Object -ExpandProperty count -ErrorAction SilentlyContinue
  if ($null -eq $unknown) {
    $unknown = 0
  }

  $lines = Get-Content -LiteralPath $fixture
  $unqualified = ($lines | Where-Object {
    $_ -match '^(?:fn(?:\[| )|async fn(?:\[| )|impl(?:\[| ))'
  }).Count

  [PSCustomObject]@{
    sample = $directory.Name
    items = $inventory.item_count
    unknown = $unknown
    diagnostics = $inventory.diagnostic_summary.total
    unqualified_fn_impl = $unqualified
    bytes = (Get-Item -LiteralPath $fixture).Length
  }
}

if ($Json) {
  $rows | ConvertTo-Json -Depth 4
} else {
  $rows | Format-Table -AutoSize
  $total = $rows | Measure-Object items, unknown, diagnostics, unqualified_fn_impl, bytes -Sum
  $total | Format-Table Property, Sum -AutoSize
}
