# Setup Firebase CLI - Run this after restarting PowerShell

Write-Host "Verifying Node.js installation..." -ForegroundColor Cyan
Write-Host ""

# Check Node.js
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersion = node --version
    Write-Host "Node.js $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "Node.js not found! Please restart PowerShell." -ForegroundColor Red
    Write-Host "If still not working, close ALL PowerShell windows and open a new one." -ForegroundColor Yellow
    exit 1
}

# Check npm
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $npmVersion = npm --version
    Write-Host "npm $npmVersion" -ForegroundColor Green
} else {
    Write-Host "npm not found!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Installing Firebase CLI globally..." -ForegroundColor Cyan
npm install -g firebase-tools

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Firebase CLI installed successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Verify Firebase CLI
    $firebaseVersion = firebase --version
    Write-Host "Firebase CLI $firebaseVersion" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Next step: Login to Firebase" -ForegroundColor Cyan
    Write-Host "Run: firebase login" -ForegroundColor White
    Write-Host ""
    Write-Host "After logging in, you can deploy with:" -ForegroundColor Cyan
    Write-Host ".\firebase\build-and-deploy.ps1" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Firebase CLI installation failed!" -ForegroundColor Red
    Write-Host "Try running PowerShell as Administrator" -ForegroundColor Yellow
}
