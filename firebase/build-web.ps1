# PowerShell script to just build Flutter web app (no deployment)

Write-Host "🚀 Building Flutter Web App for Production..." -ForegroundColor Cyan
Write-Host ""

# Navigate to project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Clean previous builds
Write-Host "📦 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
Write-Host "✅ Clean complete" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Build web app in release mode with cloud configuration
Write-Host "🔨 Building web app (release mode, cloud backend)..." -ForegroundColor Yellow
Write-Host "   Using: --dart-define=USE_DIRECTUS=false" -ForegroundColor Gray
Write-Host ""

flutter build web --release --dart-define=USE_DIRECTUS=false

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Build complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 Output location: build/web/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📊 Build stats:" -ForegroundColor Yellow
    $buildSize = (Get-ChildItem -Path "build/web" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "   Total size: $([math]::Round($buildSize, 2)) MB" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Test locally: flutter run -d chrome --release" -ForegroundColor White
    Write-Host "  2. Deploy: .\firebase\build-and-deploy.ps1" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}
