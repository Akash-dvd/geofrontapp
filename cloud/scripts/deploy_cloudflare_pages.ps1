param(
    [Parameter(Mandatory = $true)][string]$ProjectName,
    [string]$BuildDirectory = "build\web",
    [string]$Branch = "main",
    [switch]$DryRun,
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

Assert-Command wrangler

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptRoot '..\..')
Set-Location $projectRoot

$buildPath = Resolve-Path -Path $BuildDirectory -ErrorAction SilentlyContinue
if (-not $buildPath) {
    throw "Build directory '$BuildDirectory' not found. Run build_flutter_web.ps1 first."
}

Write-Host "[deploy] Deploying to Cloudflare Pages project '$ProjectName'" -ForegroundColor Green

$arguments = @('pages', 'deploy', $buildPath.Path, '--project-name', $ProjectName)

$arguments += @('--branch', $Branch)

if ($DryRun) {
    $arguments += '--dry-run'
}

Write-Info "wrangler " + ($arguments -join ' ')

& wrangler @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Wrangler deploy failed with exit code $LASTEXITCODE."
}

Write-Host "[deploy] Deployment finished" -ForegroundColor Green
