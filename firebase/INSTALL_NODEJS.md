# Installing Node.js and npm on Windows

## Option 1: Using winget (Windows Package Manager) - RECOMMENDED

**Check if winget is available:**
```powershell
winget --version
```

**Install Node.js:**
```powershell
winget install OpenJS.NodeJS
```

**Or install Node.js LTS:**
```powershell
winget install OpenJS.NodeJS.LTS
```

After installation, **restart PowerShell** and verify:
```powershell
node --version
npm --version
```

## Option 2: Using Chocolatey

**Install Chocolatey (if not installed):**
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

**Install Node.js:**
```powershell
choco install nodejs
```

**Verify:**
```powershell
node --version
npm --version
```

## Option 3: Using Scoop

**Install Scoop (if not installed):**
```powershell
# Run in PowerShell (regular user, not admin)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

**Install Node.js:**
```powershell
scoop install nodejs
```

**Verify:**
```powershell
node --version
npm --version
```

## Option 4: Manual Download (Traditional Way)

1. Download Node.js installer from: https://nodejs.org/
2. Choose LTS version (recommended)
3. Run the .msi installer
4. Follow installation wizard
5. **Restart PowerShell**
6. Verify installation:
   ```powershell
   node --version
   npm --version
   ```

## After Installing Node.js and npm

### Install Firebase CLI:
```powershell
npm install -g firebase-tools
```

### Login to Firebase:
```powershell
firebase login
```

### Verify Firebase CLI:
```powershell
firebase --version
```

## Troubleshooting

### "npm not recognized"
**Solution:** Restart PowerShell or add to PATH manually:
```powershell
# Check if npm is in PATH
$env:Path -split ';' | Select-String -Pattern 'nodejs'

# If not found, add it (adjust path if needed):
$env:Path += ";C:\Program Files\nodejs"
```

### "execution of scripts is disabled"
**Solution:**
```powershell
# Run as Administrator
Set-ExecutionPolicy RemoteSigned
```

### Permission errors with npm
**Solution:** Use `-g` flag with admin rights or configure npm:
```powershell
# Configure npm to use a different directory
npm config set prefix "$env:APPDATA\npm"
```

## Recommended: winget Method

The fastest and cleanest way on Windows 10/11:

```powershell
# 1. Install Node.js
winget install OpenJS.NodeJS.LTS

# 2. Restart PowerShell

# 3. Verify
node --version
npm --version

# 4. Install Firebase CLI
npm install -g firebase-tools

# 5. Login
firebase login
```

## Quick Check Script

Run this to check what you have:

```powershell
Write-Host "`n=== Checking Installation ===" -ForegroundColor Cyan

# Check winget
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "✅ winget available" -ForegroundColor Green
} else {
    Write-Host "❌ winget not found" -ForegroundColor Red
}

# Check Node.js
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "✅ Node.js $(node --version)" -ForegroundColor Green
} else {
    Write-Host "❌ Node.js not installed" -ForegroundColor Red
}

# Check npm
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "✅ npm $(npm --version)" -ForegroundColor Green
} else {
    Write-Host "❌ npm not installed" -ForegroundColor Red
}

# Check Firebase CLI
if (Get-Command firebase -ErrorAction SilentlyContinue) {
    Write-Host "✅ Firebase CLI $(firebase --version)" -ForegroundColor Green
} else {
    Write-Host "❌ Firebase CLI not installed" -ForegroundColor Yellow
    Write-Host "   Install with: npm install -g firebase-tools" -ForegroundColor Gray
}
```

## Next Steps

After Node.js and npm are installed:

1. **Install Firebase CLI:**
   ```powershell
   npm install -g firebase-tools
   ```

2. **Login to Firebase:**
   ```powershell
   firebase login
   ```

3. **Deploy your app:**
   ```powershell
   .\firebase\build-and-deploy.ps1
   ```
