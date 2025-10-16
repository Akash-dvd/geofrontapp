# PowerShell script to build Flutter web app for production and deploy to Firebase

Write-Host "Building Flutter Web App for Production..." -ForegroundColor Cyan
Write-Host ""

# Navigate to project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Step 1: Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter clean failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Clean complete" -ForegroundColor Green
Write-Host ""

# Step 2: Get dependencies
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Pub get failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Dependencies installed" -ForegroundColor Green
Write-Host ""

# Step 3: Build web app in release mode with cloud configuration
Write-Host "Building web app (release mode, cloud backend)..." -ForegroundColor Yellow
flutter build web --release --dart-define=USE_DIRECTUS=false
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Build complete!" -ForegroundColor Green
Write-Host ""

# Step 4: Show build output location
Write-Host "Build output location:" -ForegroundColor Cyan
Write-Host "   build/web/" -ForegroundColor White
Write-Host ""

# Step 5: Check if Firebase CLI is installed
Write-Host "Checking Firebase CLI..." -ForegroundColor Yellow
$firebaseInstalled = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseInstalled) {
    Write-Host "Firebase CLI not installed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Firebase CLI:" -ForegroundColor Yellow
    Write-Host "  npm install -g firebase-tools" -ForegroundColor White
    Write-Host ""
    Write-Host "Then login:" -ForegroundColor Yellow
    Write-Host "  firebase login" -ForegroundColor White
    Write-Host ""
    Write-Host "Build is complete, but deployment skipped." -ForegroundColor Yellow
    exit 0
}
Write-Host "Firebase CLI found" -ForegroundColor Green
Write-Host ""

# Step 6: Check Firebase login status
Write-Host "Checking Firebase login status..." -ForegroundColor Yellow
firebase projects:list 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged in to Firebase!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please login:" -ForegroundColor Yellow
    Write-Host "  firebase login" -ForegroundColor White
    Write-Host ""
    Write-Host "Build is complete, but deployment skipped." -ForegroundColor Yellow
    exit 0
}
Write-Host "Firebase authenticated" -ForegroundColor Green
Write-Host ""

# Step 7: Deploy to Firebase Hosting
Write-Host "Deploying to Firebase Hosting..." -ForegroundColor Cyan
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Your app is live at:" -ForegroundColor Cyan
Write-Host "   https://aksharaintelligence-41f4a.web.app" -ForegroundColor White
Write-Host "   https://aksharaintelligence-41f4a.firebaseapp.com" -ForegroundColor White
