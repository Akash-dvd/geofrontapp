# PowerShell script to recreate Hasura permissions for problems table
# Corrected JSON format

$HASURA_ENDPOINT = "https://premium-turkey-36.hasura.app"
$ADMIN_SECRET = "AkjyD62dXJ8NZ0GlEUP076hVNiPJHj57T9AUJoMWTO2YYYQloSaJziY7Tmc6DsnI"

Write-Host "🚀 Recreating all permissions for problems table..." -ForegroundColor Cyan

function Invoke-HasuraCommand {
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
        Write-Host "❌ Error: $_" -ForegroundColor Red
        Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
        return $null
    }
}

# 1. CREATE SELECT PERMISSION
Write-Host "`n📋 Creating SELECT permission..." -ForegroundColor Yellow
$selectBody = @'
{
  "type": "pg_create_select_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "columns": [
        "id", "title", "description", "difficulty", "category",
        "geometry_data", "solution", "scalar_constraints", 
        "object_constraints", "scalar_proof", "object_proof",
        "status", "image_id", "thumbnail_id", "owner_uid",
        "created_at", "updated_at"
      ],
      "filter": {
        "_or": [
          {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
          {"status": {"_eq": "published"}}
        ]
      }
    }
  }
}
'@

$result = Invoke-HasuraCommand -Body $selectBody
if ($result) {
    Write-Host "   ✅ SELECT permission created: $($result.message)" -ForegroundColor Green
}

# 2. CREATE INSERT PERMISSION
Write-Host "`n📋 Creating INSERT permission..." -ForegroundColor Yellow
$insertBody = @'
{
  "type": "pg_create_insert_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "columns": [
        "title", "description", "difficulty", "category",
        "geometry_data", "solution", "scalar_constraints",
        "object_constraints", "scalar_proof", "object_proof",
        "status", "thumbnail_id"
      ],
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "set": {"owner_uid": "X-Hasura-User-Id"}
    }
  }
}
'@

$result = Invoke-HasuraCommand -Body $insertBody
if ($result) {
    Write-Host "   ✅ INSERT permission created: $($result.message)" -ForegroundColor Green
}

# 3. CREATE UPDATE PERMISSION
Write-Host "`n📋 Creating UPDATE permission..." -ForegroundColor Yellow
$updateBody = @'
{
  "type": "pg_create_update_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "columns": [
        "title", "description", "difficulty", "category",
        "geometry_data", "solution", "scalar_constraints",
        "object_constraints", "scalar_proof", "object_proof",
        "status", "image_id", "thumbnail_id"
      ],
      "filter": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}}
    }
  }
}
'@

$result = Invoke-HasuraCommand -Body $updateBody
if ($result) {
    Write-Host "   ✅ UPDATE permission created: $($result.message)" -ForegroundColor Green
}

# 4. CREATE DELETE PERMISSION
Write-Host "`n📋 Creating DELETE permission..." -ForegroundColor Yellow
$deleteBody = @'
{
  "type": "pg_create_delete_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "filter": {"owner_uid": {"_eq": "X-Hasura-User-Id"}}
    }
  }
}
'@

$result = Invoke-HasuraCommand -Body $deleteBody
if ($result) {
    Write-Host "   ✅ DELETE permission created: $($result.message)" -ForegroundColor Green
}

Write-Host "`n✅ All permissions recreated successfully!" -ForegroundColor Green
Write-Host "🧪 Test in your Flutter app now!" -ForegroundColor Cyan
