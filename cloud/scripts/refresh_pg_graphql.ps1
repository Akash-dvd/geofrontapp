param(
    [Parameter(Mandatory = $true)][string]$ProjectRef,
    [Parameter(Mandatory = $true)][string]$ServiceRoleKey,
    [string]$Schema = "public"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRef)) {
    throw "ProjectRef cannot be empty."
}

if ([string]::IsNullOrWhiteSpace($ServiceRoleKey)) {
    throw "ServiceRoleKey cannot be empty."
}

$baseUri = "https://$ProjectRef.supabase.co"
$rpcEndpoint = "$baseUri/rest/v1/rpc/graphql_rebuild_schema"
$body = if ([string]::IsNullOrWhiteSpace($Schema)) { '{}' } else { "{""schema"":""$Schema""}" }

Write-Host "Triggering pg_graphql schema rebuild for '$Schema' on project '$ProjectRef'..."

try {
    $response = Invoke-RestMethod -Method Post -Uri $rpcEndpoint -Headers @{
        "apikey"        = $ServiceRoleKey
        "Authorization" = "Bearer $ServiceRoleKey"
        "Content-Type"  = "application/json"
    } -Body $body

    if ($null -ne $response) {
        Write-Host "Received response:" -ForegroundColor Cyan
        $response | ConvertTo-Json -Depth 5 | Write-Host
    }

    Write-Host "pg_graphql schema rebuild request completed successfully." -ForegroundColor Green
} catch {
    $errResponse = $null
    $errBody = $null

    if ($_.Exception.PSObject.Properties.Name -contains 'Response') {
        $errResponse = $_.Exception.Response
    }

    if ($errResponse -and $errResponse.GetResponseStream()) {
        $reader = New-Object System.IO.StreamReader($errResponse.GetResponseStream())
        $errBody = $reader.ReadToEnd()
        $reader.Dispose()
    }

    if ($errBody) {
        Write-Error "Failed to rebuild pg_graphql schema: $($errResponse.StatusCode) $($errResponse.StatusDescription) - $errBody"
    } else {
        Write-Error "Failed to rebuild pg_graphql schema: $_"
    }

    throw
}
