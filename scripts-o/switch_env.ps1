# Environment switcher for GeoFront hybrid backend (PowerShell version)
# Usage:
#   .\scripts\switch_env.ps1 local run    - Switch to local Directus and run
#   .\scripts\switch_env.ps1 cloud run    - Switch to cloud Hasura+Supabase and run
#   .\scripts\switch_env.ps1 cloud build web -release  - Build for web with cloud config

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("local", "cloud")]
    [string]$Mode,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("run", "build")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$BuildTarget,
    
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$AdditionalArgs
)

$ErrorActionPreference = "Stop"

# Get project root (parent of scripts directory)
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "🔧 Switching to $Mode mode..." -ForegroundColor Cyan

# Copy appropriate env file
if ($Mode -eq "local") {
    if (-not (Test-Path ".env.local")) {
        Write-Host "❌ .env.local not found. Create it first with your local Directus config." -ForegroundColor Red
        exit 1
    }
    Copy-Item .env.local .env -Force
    $UseDirectus = "true"
    Write-Host "✅ Copied .env.local → .env (USE_DIRECTUS=true)" -ForegroundColor Green
}
else {
    if (-not (Test-Path ".env.cloud")) {
        Write-Host "❌ .env.cloud not found. Create it first with your Hasura+Supabase config." -ForegroundColor Red
        exit 1
    }
    Copy-Item .env.cloud .env -Force
    $UseDirectus = "false"
    Write-Host "✅ Copied .env.cloud → .env (USE_DIRECTUS=false)" -ForegroundColor Green
}

# Run pub get to refresh dependencies
Write-Host "📦 Running flutter pub get..." -ForegroundColor Cyan
flutter pub get

# Execute requested action
if ($Action -eq "run") {
    Write-Host "🚀 Running app with USE_DIRECTUS=$UseDirectus..." -ForegroundColor Cyan
    flutter run --dart-define=USE_DIRECTUS=$UseDirectus
}
elseif ($Action -eq "build") {
    if ([string]::IsNullOrEmpty($BuildTarget)) {
        Write-Host "❌ Build target required. Example: web, apk, ios" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "🏗️  Building $BuildTarget with USE_DIRECTUS=$UseDirectus..." -ForegroundColor Cyan
    
    # For production builds, always force USE_DIRECTUS=false regardless of mode
    if ($Mode -eq "cloud") {
        $dartDefine = "--dart-define=USE_DIRECTUS=false"
    }
    else {
        $dartDefine = "--dart-define=USE_DIRECTUS=$UseDirectus"
    }
    
    # Build command with additional args
    $buildArgs = @("build", $BuildTarget, $dartDefine) + $AdditionalArgs
    & flutter $buildArgs
    
    Write-Host "✅ Build complete!" -ForegroundColor Green
}
