# PowerShell script to drop all permissions for 'user' role

$HASURA_ENDPOINT = "https://premium-turkey-36.hasura.app"
$ADMIN_SECRET = "AkjyD62dXJ8NZ0GlEUP076hVNiPJHj57T9AUJoMWTO2YYYQloSaJziY7Tmc6DsnI"

Write-Host "🗑️  Dropping all permissions for 'user' role..." -ForegroundColor Yellow

function Invoke-HasuraDrop {
    param([string]$Body)
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri "$HASURA_ENDPOINT/v1/metadata" `
            -Headers @{
                "x-hasura-admin-secret" = $ADMIN_SECRET
                "Content-Type" = "application/json"
            } `
            -Body $Body
        
        return $response
    } catch {
        return $null
    }
}

Write-Host "`n🗑️  Dropping permissions for problems table..." -ForegroundColor Cyan

Write-Host "  - SELECT permission..."
Invoke-HasuraDrop -Body '{"type":"pg_drop_select_permission","args":{"source":"supabase","table":{"schema":"public","name":"problems"},"role":"user"}}' | Out-Null

Write-Host "  - INSERT permission..."
Invoke-HasuraDrop -Body '{"type":"pg_drop_insert_permission","args":{"source":"supabase","table":{"schema":"public","name":"problems"},"role":"user"}}' | Out-Null

Write-Host "  - UPDATE permission..."
Invoke-HasuraDrop -Body '{"type":"pg_drop_update_permission","args":{"source":"supabase","table":{"schema":"public","name":"problems"},"role":"user"}}' | Out-Null

Write-Host "  - DELETE permission..."
Invoke-HasuraDrop -Body '{"type":"pg_drop_delete_permission","args":{"source":"supabase","table":{"schema":"public","name":"problems"},"role":"user"}}' | Out-Null

Write-Host "`n🗑️  Dropping permissions for images table..." -ForegroundColor Cyan

Write-Host "  - SELECT permission..."
Invoke-HasuraDrop -Body '{"type":"pg_drop_select_permission","args":{"source":"supabase","table":{"schema":"public","name":"images"},"role":"user"}}' | Out-Null

Write-Host "  - INSERT permission..."
Invoke-HasuraDrop -Body '{"type":"pg_drop_insert_permission","args":{"source":"supabase","table":{"schema":"public","name":"images"},"role":"user"}}' | Out-Null

Write-Host "  - UPDATE permission..."
Invoke-HasuraDrop -Body '{"type":"pg_drop_update_permission","args":{"source":"supabase","table":{"schema":"public","name":"images"},"role":"user"}}' | Out-Null

Write-Host "  - DELETE permission..."
Invoke-HasuraDrop -Body '{"type":"pg_drop_delete_permission","args":{"source":"supabase","table":{"schema":"public","name":"images"},"role":"user"}}' | Out-Null

Write-Host "`n✅ All permissions dropped!" -ForegroundColor Green
