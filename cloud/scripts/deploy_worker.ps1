param(
    [string]$Env = "production"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$projectRoot = (Resolve-Path (Join-Path $scriptDir ".." )).Path
$workerDir = Join-Path $projectRoot "edge_worker"
$wranglerConfig = Join-Path $workerDir "wrangler.toml"

if (-not (Get-Command wrangler -ErrorAction SilentlyContinue)) {
    Write-Error "wrangler CLI not found. Install it with 'npm install -g wrangler'."
    exit 1
}

if (-not (Test-Path $wranglerConfig)) {
    Write-Error "Expected wrangler.toml at $wranglerConfig"
    exit 1
}

Write-Host "Deploying Cloudflare Worker from $workerDir (env=$Env)..."

Push-Location $workerDir
try {
    if (Test-Path "package-lock.json") {
        Write-Host "Running npm ci..."
        npm ci --no-audit --no-fund | Out-Null
    } elseif (Test-Path "package.json") {
        Write-Host "Running npm install..."
        npm install --no-audit --no-fund | Out-Null
    }

    $deployArgs = @("deploy", "--config", $wranglerConfig)
    if ($Env) {
        $deployArgs += @("--env", $Env)
    }

    wrangler @deployArgs
}
finally {
    Pop-Location
}

Write-Host "Worker deployment script complete."