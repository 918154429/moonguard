param(
  [string]$Moon,
  [switch]$Offline
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not $Moon) {
  $workspaceMoon = Join-Path (Split-Path $repoRoot -Parent) '.toolchain\bin\moon.exe'
  if (Test-Path -LiteralPath $workspaceMoon) {
    $Moon = $workspaceMoon
  } else {
    $moonCommand = Get-Command moon -ErrorAction SilentlyContinue
    if ($moonCommand) {
      $Moon = $moonCommand.Source
    }
  }
}
if (-not (Test-Path -LiteralPath $Moon)) {
  throw "MoonBit executable not found: $Moon"
}

$fixtureRoot = Join-Path $repoRoot 'fixtures\evolution'
$reportRoot = Join-Path $repoRoot 'docs\evidence\generated'
New-Item -ItemType Directory -Force -Path $fixtureRoot,$reportRoot | Out-Null

function Write-Utf8Lines {
  param(
    [string]$Path,
    [string[]]$Lines
  )

  $text = ($Lines -join "`n").TrimEnd("`r", "`n") + "`n"
  [System.IO.File]::WriteAllText(
    $Path,
    $text,
    [System.Text.UTF8Encoding]::new($false)
  )
}

$cases = @(
  [pscustomobject]@{
    Name = 'moonbitlang-async-http'
    Repository = 'moonbitlang/async'
    Path = 'src/http/pkg.generated.mbti'
    Old = 'b2169b7e4226d44808c9eee31e9b21e091efdc6c'
    New = 'ff2885666e02859735331f4035b668cc957b1b6e'
    OldHash = '04d291da8c964895ca953b7f81021101149509868e1040ccde2add4e8791ee0d'
    NewHash = '606f65550279310d7dad5349c70edb80b0d41c825e8955b834d90535632c932b'
  },
  [pscustomobject]@{
    Name = 'moonbitlang-quickcheck'
    Repository = 'moonbitlang/quickcheck'
    Path = 'src/pkg.generated.mbti'
    Old = '6d97a1cc1e4f3be5ae9ef0d15b5d269977362f6d'
    New = '9648749c3b0272d561d7c7bbb5f71550b737026d'
    OldHash = 'f80db77ca3f79bca8c1c668df83df7fe6e340f4af1bf0b359fd744a2996aeec6'
    NewHash = '651b06fe5cc43941860f988410eb6817a721e50087471b68b42db2734d00777e'
  },
  [pscustomobject]@{
    Name = 'oboard-mocket'
    Repository = 'oboard/mocket'
    Path = 'pkg.generated.mbti'
    Old = '8f4a8e9a8b04f2e4b5bf1b4c613890e137c09b5a'
    New = '544178cef3fe611ac1c8ac91671c246510668cd9'
    OldHash = 'cc90be41f488c0671b5d0cffac3b2fc7cd9e48ede647d73f5b477f6eec5c9ca2'
    NewHash = '53ab40196e84cfed2d3b5dc7c2b3fb53e9d2563036b508f1b833b1182f1ad9ad'
  }
)

function Get-PinnedFixture {
  param(
    [pscustomobject]$Case,
    [string]$Commit,
    [string]$ExpectedHash,
    [string]$Destination
  )

  $url = "https://raw.githubusercontent.com/$($Case.Repository)/$Commit/$($Case.Path)"
  if ($Offline) {
    if (-not (Test-Path -LiteralPath $Destination)) {
      throw "Offline fixture not found: $Destination"
    }
  } else {
    curl.exe -4 -L --fail --silent --show-error --retry 5 --retry-delay 2 --connect-timeout 10 --max-time 300 -o $Destination $url
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to download $url"
    }
  }
  $actualHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actualHash -ne $ExpectedHash) {
    throw "SHA-256 mismatch for $Destination`: expected $ExpectedHash, got $actualHash"
  }
}

Push-Location $repoRoot
try {
  $selfDir = Join-Path $fixtureRoot 'moonguard'
  New-Item -ItemType Directory -Force -Path $selfDir | Out-Null
  $selfOld = Join-Path $selfDir 'v0.1.0.mbti'
  $selfOldLines = git show 'v0.1.0:pkg.generated.mbti'
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to extract MoonGuard v0.1.0 interface'
  }
  Write-Utf8Lines -Path $selfOld -Lines $selfOldLines
  $selfNew = Join-Path $repoRoot 'pkg.generated.mbti'
  $selfMarkdown = & $Moon run --target js cmd/main -- check $selfOld $selfNew --current 0.1.0 --next 0.2.0 --format markdown
  Write-Utf8Lines -Path (Join-Path $reportRoot 'moonguard-v0.1.0-to-v0.2.0.md') -Lines $selfMarkdown
  $selfJson = & $Moon run --target js cmd/main -- check $selfOld $selfNew --current 0.1.0 --next 0.2.0 --format json
  Write-Utf8Lines -Path (Join-Path $reportRoot 'moonguard-v0.1.0-to-v0.2.0.json') -Lines $selfJson

  foreach ($case in $cases) {
    $caseDir = Join-Path $fixtureRoot $case.Name
    New-Item -ItemType Directory -Force -Path $caseDir | Out-Null
    $oldFile = Join-Path $caseDir 'old.mbti'
    $newFile = Join-Path $caseDir 'new.mbti'
    Get-PinnedFixture -Case $case -Commit $case.Old -ExpectedHash $case.OldHash -Destination $oldFile
    Get-PinnedFixture -Case $case -Commit $case.New -ExpectedHash $case.NewHash -Destination $newFile
    $markdown = & $Moon run --target js cmd/main -- report $oldFile $newFile --format markdown
    Write-Utf8Lines -Path (Join-Path $reportRoot "$($case.Name).md") -Lines $markdown
    $json = & $Moon run --target js cmd/main -- report $oldFile $newFile --format json
    Write-Utf8Lines -Path (Join-Path $reportRoot "$($case.Name).json") -Lines $json
  }
} finally {
  Pop-Location
}

Write-Output "Evolution evidence regenerated under $reportRoot"
