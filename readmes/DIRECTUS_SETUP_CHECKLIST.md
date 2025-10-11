# Complete Directus Setup - Step-by-Step Guide

## ⏰ Time Required: 15-20 minutes total

This guide will help you complete the final 2 setup steps in Directus admin UI.

---

## 📋 Task 1: Add Thumbnail Field (10 minutes)

### Step 1: Access Directus Admin
1. Open your web browser
2. Navigate to: **http://192.168.1.3:8055/admin**
3. Log in with your admin credentials

### Step 2: Navigate to Problems Collection
1. Click the **Settings** icon (⚙️) in the left sidebar
2. Click **Data Model**
3. Find and click on **problems** collection in the list

### Step 3: Add Thumbnail Field
1. Click the **"+ Create Field"** button (top right)
2. Select **"Many to One"** (Relational field type)
3. Configure the relationship:
   - **Related Collection**: Select `directus_files` from dropdown
   - Click **Continue**

### Step 4: Configure Field Settings
In the Field configuration screen:

**Key tab:**
- **Field Name**: `thumbnail`
- Click **Continue**

**Schema tab:**
- Leave defaults (nullable should be checked)
- Click **Continue**

**Relationship tab:**
- Leave defaults
- Click **Continue**

**Interface tab:**
- **Interface**: Select "Image" from the dropdown
- **Folder**: (optional) You can create/select "thumbnails" folder
- **Accepted File Types**: `image/jpeg, image/png, image/webp`
- Click **Continue**

**Display tab:**
- Leave defaults
- Click **Finish**

### Step 5: Update Public Role Permissions

1. Go to **Settings** → **Access Control**
2. Click on **Public** role
3. Find **problems** collection:
   - Click to expand permissions
   - Under **Read** permissions:
     - Make sure **thumbnail** is checked/allowed
   - Click **Save** icon (💾)

4. Find **directus_files** collection:
   - Click to expand permissions
   - Under **Read** permissions:
     - Check/Enable **Read** access
     - Make sure all fields are readable (or at least id, filename, title)
   - Click **Save** icon (💾)

### Step 6: Verify Field Creation

Test with GraphQL:
1. Go to Directus admin → GraphQL (if available in UI)
2. Or use curl:

```bash
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { problems(limit: 1) { id title thumbnail } }"
  }'
```

✅ You should see the `thumbnail` field in the response (will be null for existing problems without thumbnails).

---

## 📋 Task 2: Add Constraint Fields (10 minutes)

### Step 1: Navigate to Problems Collection
1. In Directus admin, go to **Settings** → **Data Model**
2. Click on **problems** collection

### Step 2: Add scalar_constraints Field

1. Click **"+ Create Field"** button
2. Select **"Standard Field"**
3. Select **"JSON"** type
4. Configure:
   - **Key tab**: Field Name = `scalar_constraints`
   - **Schema tab**: Check "Allow NULL" (field is nullable)
   - **Interface tab**: Select "JSON" or "Code" interface
   - Click **Finish**

### Step 3: Add object_constraints Field

Repeat the same process:
1. Click **"+ Create Field"**
2. Select **"Standard Field"** → **"JSON"**
3. Configure:
   - **Key tab**: Field Name = `object_constraints`
   - **Schema tab**: Check "Allow NULL"
   - **Interface tab**: JSON interface
   - Click **Finish**

### Step 4: Add scalar_proof Field

Repeat again:
1. Click **"+ Create Field"**
2. Select **"Standard Field"** → **"JSON"**
3. Configure:
   - **Key tab**: Field Name = `scalar_proof`
   - **Schema tab**: Check "Allow NULL"
   - **Interface tab**: JSON interface
   - Click **Finish**

### Step 5: Add object_proof Field

Final field:
1. Click **"+ Create Field"**
2. Select **"Standard Field"** → **"JSON"**
3. Configure:
   - **Key tab**: Field Name = `object_proof`
   - **Schema tab**: Check "Allow NULL"
   - **Interface tab**: JSON interface
   - Click **Finish**

### Step 6: Update Public Role Permissions

1. Go to **Settings** → **Access Control** → **Public** role
2. Find **problems** collection
3. Under **Read** permissions, ensure these fields are checked:
   - ✅ scalar_constraints
   - ✅ object_constraints
   - ✅ scalar_proof
   - ✅ object_proof
4. Click **Save** icon (💾)

### Step 7: Verify All Fields

Test with GraphQL:

```bash
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { problems(limit: 1) { 
      id 
      title 
      scalar_constraints 
      object_constraints 
      scalar_proof 
      object_proof 
      thumbnail 
    } }"
  }'
```

✅ All 5 new fields should appear in the response!

---

## 🧪 Final Testing: End-to-End

### Test 1: Create Problem with Thumbnail

1. **Run the Flutter app:**
   ```bash
   flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8081
   ```

2. **Access via browser:**
   - From local: http://localhost:8081
   - From network: http://192.168.1.3:8081

3. **Create a new problem:**
   - Click "+" button in the app
   - Fill in:
     - Title: "Test Triangle"
     - Description: "A simple triangle construction"
     - Difficulty: Beginner
     - Category: Geometry
   - Click **"Open GeoDraw"** button
   
4. **Draw geometry:**
   - In GeoDraw, create some points and lines
   - Example: 3 points forming a triangle
   - Click **Save** in GeoDraw

5. **Save problem:**
   - Back in the form, click **"Save"** button
   - Watch for loading indicator (thumbnail being captured)
   - Should navigate back to problem list

6. **Verify thumbnail:**
   - ✅ See your new problem as a card
   - ✅ Card shows thumbnail image of your geometry
   - ✅ Title, description, and chips are visible

### Test 2: Verify in Directus

1. Open Directus: http://192.168.1.3:8055/admin
2. Go to **Content** → **problems**
3. Find your test problem
4. Click to view details
5. Verify:
   - ✅ `thumbnail` field has a file ID
   - ✅ Click thumbnail to preview image
   - ✅ Image shows your geometry

### Test 3: Test Constraints (Future)

These fields are ready for the solver system:

```bash
# Test creating problem with constraints
curl -X POST http://192.168.1.3:8055/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { 
      create_problems_item(data: { 
        title: \"Test Constraints\"
        description: \"Testing constraint fields\"
        difficulty: \"beginner\"
        category: \"geometry\"
        scalar_constraints: {\"l1-l2\": 0}
        object_constraints: {\"perpendicular\": [\"l1\", \"l2\"]}
      }) { 
        id 
        scalar_constraints 
        object_constraints 
      } 
    }"
  }'
```

---

## ✅ Completion Checklist

Mark each item when done:

### Thumbnail Field
- [ ] Logged into Directus admin
- [ ] Added `thumbnail` field (Many-to-One → directus_files)
- [ ] Configured as Image interface
- [ ] Updated Public role permissions for thumbnail
- [ ] Updated Public role permissions for directus_files
- [ ] Tested GraphQL query (field appears)

### Constraint Fields
- [ ] Added `scalar_constraints` field (JSON, nullable)
- [ ] Added `object_constraints` field (JSON, nullable)
- [ ] Added `scalar_proof` field (JSON, nullable)
- [ ] Added `object_proof` field (JSON, nullable)
- [ ] Updated Public role permissions for all 4 fields
- [ ] Tested GraphQL query (all fields appear)

### End-to-End Testing
- [ ] Created problem with GeoDraw geometry
- [ ] Saw loading indicator during save
- [ ] Thumbnail appears in problem list
- [ ] Thumbnail shows correct geometry
- [ ] Can click card to view details
- [ ] Verified thumbnail in Directus admin

---

## 🎉 Success!

Once all checkboxes are marked, you have:
- ✅ Fully functional thumbnail system
- ✅ Beautiful card-based problem list
- ✅ Automatic canvas capture
- ✅ Constraint/proof fields ready for solver
- ✅ Production-ready implementation

---

## 🆘 Troubleshooting

### Can't Access Directus Admin
**Problem**: http://192.168.1.3:8055/admin not loading  
**Solution**:
```bash
# Check if Directus is running
docker ps | grep directus

# If not running, start it
cd /path/to/directus
docker-compose up -d
```

### Field Not Appearing in GraphQL
**Problem**: Added field but not visible in queries  
**Solution**:
1. Check field was saved (refresh Data Model page)
2. Verify Public role has read permission
3. Try restarting Directus: `docker-compose restart`

### Thumbnail Upload Fails
**Problem**: Loading indicator but no thumbnail saved  
**Solution**:
1. Check browser console for errors (F12)
2. Verify Directus is accessible from Flutter app
3. Check Directus logs: `docker logs directus`
4. Ensure Public role can create files in directus_files

### Permission Denied Errors
**Problem**: 403 or permission errors  
**Solution**:
1. Go to Settings → Access Control → Public
2. For problems collection: Enable Read, Create, Update
3. For directus_files: Enable Read, Create
4. Save changes and retry

---

## 📞 Need Help?

If you encounter issues:
1. Check the error message in browser console (F12)
2. Check Directus logs: `docker logs directus`
3. Verify schema in Settings → Data Model
4. Review permissions in Settings → Access Control
5. See detailed docs: `directus/ADD_THUMBNAIL_FIELD.md` and `directus/ADD_CONSTRAINT_FIELDS.md`

---

**Estimated Time**: 15-20 minutes total  
**Difficulty**: Easy (just clicking through UI)  
**Result**: Fully functional thumbnail system! 🎨
