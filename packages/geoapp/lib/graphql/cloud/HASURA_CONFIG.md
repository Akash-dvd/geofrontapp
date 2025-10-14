# Hasura Configuration for Firebase JWT

Configuration for connecting Hasura GraphQL Engine to Supabase Postgres with Firebase authentication.

---

## Environment Variables

Add to Hasura Cloud Console → Settings → Env vars:

### HASURA_GRAPHQL_JWT_SECRET

```json
{
  "type": "RS256",
  "jwk_url": "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  "audience": "aksharaintelligence-41f4a",
  "issuer": "https://securetoken.google.com/aksharaintelligence-41f4a",
  "claims_map": {
    "x-hasura-default-role": "user",
    "x-hasura-allowed-roles": ["user"],
    "x-hasura-user-id": "user_id"
  }
}
```

### HASURA_GRAPHQL_DATABASE_URL

Get from Supabase → Settings → Database → Connection String:

```
postgresql://postgres:[YOUR-PASSWORD]@db.ahcndokbcggdymszuhpn.supabase.co:5432/postgres
```

---

## Track Tables

1. Go to Hasura Console → Data
2. Click **"Track"** on `problems` table
3. Click **"Track"** on `images` table
4. Track relationship: `problems.image_id → images.id`

---

## Configure Permissions - Problems Table

### Role: "user"

#### SELECT Permission

**Row select permission:**
```json
{
  "_or": [
    { "owner_uid": { "_eq": "X-Hasura-User-Id" } },
    { "status": { "_eq": "published" } }
  ]
}
```

**Column permissions:** All columns

---

#### INSERT Permission

**Row insert permission:**
```json
{
  "owner_uid": { "_eq": "X-Hasura-User-Id" }
}
```

**Column permissions:**
- title
- description
- difficulty
- category
- geometry_data
- solution
- scalar_constraints
- object_constraints
- scalar_proof
- object_proof
- image_id

**Column presets:**
- `owner_uid`: `X-Hasura-User-Id`
- `status`: `"draft"`

---

#### UPDATE Permission

**Row update permission:**
```json
{
  "owner_uid": { "_eq": "X-Hasura-User-Id" }
}
```

**Row update check (post-update):**
```json
{
  "owner_uid": { "_eq": "X-Hasura-User-Id" }
}
```

**Column permissions:**
- title
- description
- difficulty
- category
- geometry_data
- solution
- scalar_constraints
- object_constraints
- scalar_proof
- object_proof
- status
- image_id

---

#### DELETE Permission

**Row delete permission:**
```json
{
  "owner_uid": { "_eq": "X-Hasura-User-Id" }
}
```

---

## Configure Permissions - Images Table

### Role: "user"

#### SELECT Permission

**Row select permission:**
```json
{
  "_or": [
    { "owner_uid": { "_eq": "X-Hasura-User-Id" } },
    {
      "_exists": {
        "_table": { "schema": "public", "name": "problems" },
        "_where": {
          "_and": [
            { "image_id": { "_eq": "$.id" } },
            {
              "_or": [
                { "owner_uid": { "_eq": "X-Hasura-User-Id" } },
                { "status": { "_eq": "published" } }
              ]
            }
          ]
        }
      }
    }
  ]
}
```

**Column permissions:** All columns

---

#### INSERT Permission

**Row insert permission:**
```json
{
  "owner_uid": { "_eq": "X-Hasura-User-Id" }
}
```

**Column permissions:**
- storage_key
- filename
- mime
- size
- width
- height
- thumb_key
- title
- description

**Column presets:**
- `owner_uid`: `X-Hasura-User-Id`

---

#### UPDATE Permission

**Row update permission:**
```json
{
  "owner_uid": { "_eq": "X-Hasura-User-Id" }
}
```

**Row update check:**
```json
{
  "owner_uid": { "_eq": "X-Hasura-User-Id" }
}
```

**Column permissions:**
- storage_key
- filename
- mime
- size
- width
- height
- thumb_key
- title
- description

---

#### DELETE Permission

**Row delete permission:**
```json
{
  "owner_uid": { "_eq": "X-Hasura-User-Id" }
}
```

---

## Testing

### Test Query with Firebase Token

```bash
curl -X POST https://premium-turkey-36.hasura.app/v1/graphql \
  -H "Authorization: Bearer <firebase_id_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { problems { id title owner_uid status } }"
  }'
```

### Expected Response

```json
{
  "data": {
    "problems": [
      {
        "id": "uuid",
        "title": "My Problem",
        "owner_uid": "firebase_uid",
        "status": "draft"
      }
    ]
  }
}
```

---

## Troubleshooting

### "JWTInvalid" Error

Check:
1. JWT secret matches Firebase project ID
2. Token not expired (1 hour lifetime)
3. Issuer and audience correct

### "permission denied" Error

Check:
1. Hasura permissions configured
2. `owner_uid` matches Firebase UID
3. Token contains `user_id` claim

### No data returned

Check:
1. RLS policies in Supabase
2. User owns the data or it's published
3. Query syntax correct

Done! ✅
