# Hasura Metadata Setup

This folder contains Hasura metadata configuration including permissions for the Supabase backend.

## Prerequisites

- Hasura CLI installed: `npm install -g hasura-cli`
- Admin secret for your Hasura instance

## Setup Instructions

### 1. Copy this folder to your Ubuntu machine

```bash
# From your Ubuntu terminal
cd ~
# Copy the hasura_metadata folder here
```

### 2. Set your admin secret

```bash
export HASURA_GRAPHQL_ADMIN_SECRET='your-hasura-admin-secret'
```

### 3. Make the script executable

```bash
chmod +x apply-permissions.sh
```

### 4. Run the script

```bash
./apply-permissions.sh
```

## What This Configures

### Problems Table Permissions (user role)
- **SELECT**: Users can read their own drafts OR published problems
- **INSERT**: Users can create problems (owner_uid auto-set, status=draft)
- **UPDATE**: Users can update only their own problems
- **DELETE**: Users can delete only their own problems

### Images Table Permissions (user role)
- **SELECT**: Users can read their own images OR images linked to accessible problems
- **INSERT**: Users can upload images (owner_uid auto-set)
- **UPDATE**: Users can update only their own images
- **DELETE**: Users can delete only their own images

### Relationships
- `problems.image` → Object relationship to images
- `images.problems` → Array relationship from images

## Manual Application (without script)

```bash
cd hasura_metadata
hasura metadata apply \
    --endpoint https://premium-turkey-36.hasura.app \
    --admin-secret YOUR_ADMIN_SECRET
```

## Verify Permissions

After applying, check Hasura Console:
1. Go to https://premium-turkey-36.hasura.app/console
2. Data → problems → Permissions
3. You should see "user" role configured

## Troubleshooting

### "connection refused" error
- Check if Hasura endpoint is correct
- Verify you can access the console in browser

### "unauthorized" error
- Check admin secret is correct
- Make sure environment variable is exported

### "database not found" error
- Ensure Supabase database is connected in Hasura
- Check database name is "supabase" in Hasura Console

## File Structure

```
hasura_metadata/
├── config.yaml                           # Hasura CLI config
├── metadata/
│   ├── version.yaml
│   └── databases/
│       ├── databases.yaml
│       └── supabase/
│           └── tables/
│               ├── tables.yaml
│               ├── public_problems.yaml  # Problems permissions
│               └── public_images.yaml    # Images permissions
├── apply-permissions.sh                  # Setup script
└── README.md                            # This file
```

## Next Steps

After applying permissions:
1. ✅ Test Firebase authentication with Hasura
2. ✅ Create a test problem via GraphQL
3. ✅ Verify owner_uid is auto-set
4. ✅ Test that users can only see their own drafts
