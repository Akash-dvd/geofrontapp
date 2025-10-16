# PowerShell script to update Hasura permissions for thumbnail_id
# Run this in PowerShell

$HASURA_ENDPOINT = "https://premium-turkey-36.hasura.app"
$ADMIN_SECRET = "AkjyD62dXJ8NZ0GlEUP076hVNiPJHj57T9AUJoMWTO2YYYQloSaJziY7Tmc6DsnI"

Write-Host "🚀 Updating permissions to include thumbnail_id..." -ForegroundColor Cyan
Write-Host ""

function Invoke-HasuraCommand {
    param($Body)
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri "$HASURA_ENDPOINT/v1/metadata" `
            -Headers @{
                "x-hasura-admin-secret" = $ADMIN_SECRET
                "Content-Type" = "application/json"
            } `
            -Body $Body
        
        Write-Host "  ✅ Done" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Host "  ⚠️  $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "🗑️  Dropping existing problems permissions..." -ForegroundColor Yellow

Invoke-HasuraCommand -Body '{"type":"pg_drop_select_permission","args":{"source":"supabase","table":{"schema":"public","name":"problems"},"role":"user"}}'
Invoke-HasuraCommand -Body '{"type":"pg_drop_insert_permission","args":{"source":"supabase","table":{"schema":"public","name":"problems"},"role":"user"}}'
Invoke-HasuraCommand -Body '{"type":"pg_drop_update_permission","args":{"source":"supabase","table":{"schema":"public","name":"problems"},"role":"user"}}'
Invoke-HasuraCommand -Body '{"type":"pg_drop_delete_permission","args":{"source":"supabase","table":{"schema":"public","name":"problems"},"role":"user"}}'

Write-Host ""
Write-Host "✨ Creating new permissions with thumbnail_id..." -ForegroundColor Cyan

Write-Host "📋 SELECT permission..."
Invoke-HasuraCommand -Body @'
{
  "type": "pg_create_select_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "columns": ["id","title","description","difficulty","category","geometry_data","solution","scalar_constraints","object_constraints","scalar_proof","object_proof","status","image_id","thumbnail_id","owner_uid","created_at","updated_at"],
      "filter": {"_or": [{"owner_uid": {"_eq": "X-Hasura-User-Id"}}, {"status": {"_eq": "published"}}]}
    }
  }
}
'@

Write-Host "📋 INSERT permission..."
Invoke-HasuraCommand -Body @'
{
  "type": "pg_create_insert_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "set": {"owner_uid": "x-hasura-User-Id", "status": "draft"},
      "columns": ["title","description","difficulty","category","geometry_data","solution","scalar_constraints","object_constraints","scalar_proof","object_proof","image_id","thumbnail_id"]
    }
  }
}
'@

Write-Host "📋 UPDATE permission..."
Invoke-HasuraCommand -Body @'
{
  "type": "pg_create_update_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "columns": ["title","description","difficulty","category","geometry_data","solution","scalar_constraints","object_constraints","scalar_proof","object_proof","status","image_id","thumbnail_id"],
      "filter": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}}
    }
  }
}
'@

Write-Host "📋 DELETE permission..."
Invoke-HasuraCommand -Body @'
{
  "type": "pg_create_delete_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {"filter": {"owner_uid": {"_eq": "X-Hasura-User-Id"}}}
  }
}
'@

Write-Host ""
Write-Host "✅ Permissions updated! thumbnail_id is now included." -ForegroundColor Green
Write-Host ""
Write-Host "🧪 Test in your Flutter app now!" -ForegroundColor Cyan
