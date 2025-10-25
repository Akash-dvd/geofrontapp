$ErrorActionPreference = 'Stop'

$port = 8081

$existing = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
if ($existing) {
	Write-Host "[local-prod] Port $port is already in use. Nothing to start." -ForegroundColor Yellow
	foreach ($conn in $existing) {
		try {
			$proc = Get-Process -Id $conn.OwningProcess -ErrorAction Stop
			Write-Host "[local-prod] Listening process: $($proc.ProcessName) (PID $($proc.Id))" -ForegroundColor Yellow
		} catch {
			Write-Host "[local-prod] Unable to resolve process for PID $($conn.OwningProcess)." -ForegroundColor Yellow
		}
	}
	return
}

Write-Host "[local-prod] Serving build/web on http://localhost:$port" -ForegroundColor Green
npx serve -s build/web -l $port


# powershell -ExecutionPolicy Bypass -File cloud\scripts\local_prod.ps1