# PowerShell script to apply all permissions with thumbnail_id

$HASURA_ENDPOINT = "https://premium-turkey-36.hasura.app"
$ADMIN_SECRET = "AkjyD62dXJ8NZ0GlEUP076hVNiPJHj57T9AUJoMWTO2YYYQloSaJziY7Tmc6DsnI"

Write-Host "🚀 Applying permissions via Metadata API..." -ForegroundColor Cyan

function Invoke-HasuraCommand {
    param([string]$Body)
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri "$HASURA_ENDPOINT/v1/metadata" `
            -Headers @{
                "x-hasura-admin-secret" = $ADMIN_SECRET
                "Content-Type" = "application/json"
            } `
            -Body $Body
        
        if ($response.message -eq "success") {
            Write-Host "  ✅ Applied" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Error: $($response.error)" -ForegroundColor Red
        }
        return $response
    } catch {
        Write-Host "  ❌ Error: $_" -ForegroundColor Red
        return $null
    }
}

Write-Host "`n📋 Creating SELECT permission for problems table..." -ForegroundColor Yellow
Invoke-HasuraCommand -Body @'
{
  "type": "pg_create_select_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "columns": ["id","title","description","difficulty","category","geometry_data","solution","scalar_constraints","object_constraints","scalar_proof","object_proof","status","image_id","thumbnail_id","owner_uid","created_at","updated_at"],
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

Write-Host "`n📋 Creating INSERT permission for problems table..." -ForegroundColor Yellow
Invoke-HasuraCommand -Body @'
{
  "type": "pg_create_insert_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "problems"},
    "role": "user",
    "permission": {
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "set": {"owner_uid": "X-Hasura-User-Id", "status": "draft"},
      "columns": ["title","description","difficulty","category","geometry_data","solution","scalar_constraints","object_constraints","scalar_proof","object_proof","image_id","thumbnail_id"]
    }
  }
}
'@

Write-Host "`n📋 Creating UPDATE permission for problems table..." -ForegroundColor Yellow
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

Write-Host "`n📋 Creating DELETE permission for problems table..." -ForegroundColor Yellow
Invoke-HasuraCommand -Body @'
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

Write-Host "`n📋 Creating SELECT permission for images table..." -ForegroundColor Yellow
Invoke-HasuraCommand -Body @'
{
  "type": "pg_create_select_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user",
    "permission": {
      "columns": ["id","storage_key","filename","mime","size","width","height","thumb_key","title","description","owner_uid","created_at","updated_at"],
      "filter": {
        "_or": [
          {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
          {"problems": {"_or": [{"owner_uid": {"_eq": "X-Hasura-User-Id"}}, {"status": {"_eq": "published"}}]}}
        ]
      }
    }
  }
}
'@

Write-Host "`n📋 Creating INSERT permission for images table..." -ForegroundColor Yellow
Invoke-HasuraCommand -Body @'
{
  "type": "pg_create_insert_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user",
    "permission": {
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "set": {"owner_uid": "X-Hasura-User-Id"},
      "columns": ["storage_key","filename","mime","size","width","height","thumb_key","title","description"]
    }
  }
}
'@

Write-Host "`n📋 Creating UPDATE permission for images table..." -ForegroundColor Yellow
Invoke-HasuraCommand -Body @'
{
  "type": "pg_create_update_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user",
    "permission": {
      "columns": ["storage_key","filename","mime","size","width","height","thumb_key","title","description"],
      "filter": {"owner_uid": {"_eq": "X-Hasura-User-Id"}},
      "check": {"owner_uid": {"_eq": "X-Hasura-User-Id"}}
    }
  }
}
'@

Write-Host "`n📋 Creating DELETE permission for images table..." -ForegroundColor Yellow
Invoke-HasuraCommand -Body @'
{
  "type": "pg_create_delete_permission",
  "args": {
    "source": "supabase",
    "table": {"schema": "public", "name": "images"},
    "role": "user",
    "permission": {
      "filter": {"owner_uid": {"_eq": "X-Hasura-User-Id"}}
    }
  }
}
'@

Write-Host "`n✅ Done! All permissions applied." -ForegroundColor Green
