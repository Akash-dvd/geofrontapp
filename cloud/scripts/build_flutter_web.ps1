param(
    [string]$Renderer = "auto",
    [switch]$SkipClean,
    [switch]$SkipPubGet,
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'

function Write-Info($message) {
    if ($VerboseOutput) { Write-Host $message -ForegroundColor Cyan }
}

function Assert-Command($commandName) {
    if (-not (Get-Command $commandName -ErrorAction SilentlyContinue)) {
        throw "Required command '$commandName' is not available on PATH."
    }
}

Assert-Command flutter

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptRoot '..\..')
Set-Location $projectRoot

Write-Host "[build] Building Flutter web bundle" -ForegroundColor Green

if (-not $SkipClean) {
    Write-Info "Running flutter clean..."
    flutter clean | Out-Null
}

if (-not $SkipPubGet) {
    Write-Info "Fetching pub dependencies..."
    flutter pub get | Out-Null
}

$rendererArgs = @()
$helpText = flutter build web -h 2>&1
if ($helpText -match "--web-renderer") {
    $rendererArgs = @("--web-renderer=$Renderer")
} else {
    Write-Info "Current flutter version does not expose --web-renderer; using default renderer."
}

Write-Info "Building release bundle (renderer = $Renderer)..."
flutter build web --release @rendererArgs | Out-Null

$buildPath = Join-Path $projectRoot 'build\web'
if (-not (Test-Path $buildPath)) {
    throw "Expected build output at $buildPath was not created."
}

$sizeMB = [Math]::Round(((Get-ChildItem -Path $buildPath -Recurse | Measure-Object Length -Sum).Sum / 1MB), 2)

Write-Host "[build] Build complete" -ForegroundColor Green
Write-Host "[build] Output: $buildPath" -ForegroundColor Yellow
Write-Host "[build] Approx bundle size: $sizeMB MB" -ForegroundColor Yellow



# powershell -ExecutionPolicy Bypass -File .\cloud\scripts\build_flutter_web.ps1 -Renderer auto
