# Field Permissions vs Field Presets in Directus

## 🎯 Quick Answer: Use BOTH!

- **Field Permissions** → Controls which fields users can read/write
- **Field Presets** → Automatically sets field values (like `user_owner`)
- **Filter** → Controls which items users can access

---

## 📋 The Three Concepts Explained

### 1. Filter (Item Permissions)
**What it does:** Controls **WHICH items** the user can access

**Example:**
```
user_owner Equal To $CURRENT_USER
```
**Meaning:** User can only access problems where they are the owner.

---

### 2. Field Permissions
**What it does:** Controls **WHICH fields** the user can read/write

**Example for CREATE:**
- ✅ Allow: title, description, difficulty, category, geometry_data, solution, etc.
- ❌ Block: id, date_created, date_updated

**Meaning:** User can write to most fields, but not system fields.

---

### 3. Field Presets ⭐ (THIS IS WHAT YOU NEED!)
**What it does:** **Automatically sets field values** when creating items

**Example:**
```
user_owner = $CURRENT_USER
```
**Meaning:** When user creates a problem, Directus automatically sets `user_owner` to their Firebase user ID!

---

## ✅ Correct Configuration for CREATE Permission

You need **ALL THREE**:

### Filter (Item Permissions)
```
user_owner Equal To $CURRENT_USER
```
**Why:** Ensures user can only create items that will belong to them.

### Field Permissions
```
✅ Allow: All fields
❌ Except: id, date_created, date_updated
```
**Why:** User can set problem data, but not system fields.

### Field Presets ⭐
```
user_owner = $CURRENT_USER
```
**Why:** Automatically fills `user_owner` with the user's Firebase ID!

---

## 🎨 Visual Example

### Without Presets (❌ Won't Work):
```dart
// Flutter app creates problem
final response = await http.post(
  Uri.parse('http://192.168.1.3:8055/items/problems'),
  headers: {'Authorization': 'Bearer $firebaseToken'},
  body: json.encode({
    'title': 'Test Problem',
    'description': 'Test',
    // ❌ Missing user_owner!
  }),
);
```

**Result:** ❌ **Permission denied!** Filter says `user_owner` must equal `$CURRENT_USER`, but field is empty!

---

### With Presets (✅ Works):
```dart
// Flutter app creates problem
final response = await http.post(
  Uri.parse('http://192.168.1.3:8055/items/problems'),
  headers: {'Authorization': 'Bearer $firebaseToken'},
  body: json.encode({
    'title': 'Test Problem',
    'description': 'Test',
    // ✅ No need to send user_owner!
  }),
);
```

**Result:** ✅ **Success!** Directus automatically adds:
```json
{
  "title": "Test Problem",
  "description": "Test",
  "user_owner": "wPeibNo8zydCSPGvi8q5ECELQZI3"  // ← Auto-filled!
}
```

---

## 📋 Step-by-Step: How to Configure Presets

### In Directus Admin UI:

1. Go to **Settings** → **Roles & Permissions**
2. Click on your **User** role
3. Click on **problems** collection
4. Click **CREATE** tab

You'll see three sections:

#### Section 1: Item Permissions (Filter)
```
user_owner Equal To $CURRENT_USER
```

#### Section 2: Field Permissions
```
✅ All fields
❌ Except: id, date_created, date_updated
```

#### Section 3: Field Presets ⭐
Click **"+ Add Preset"**

**Add these presets:**

| Field | Value |
|-------|-------|
| `user_owner` | `$CURRENT_USER` |
| `status` | `draft` |

**How to add:**
1. Click **"+ Add Preset"**
2. Select field: `user_owner`
3. Select value: `$CURRENT_USER` (from dropdown)
4. Click **"+ Add Preset"** again
5. Select field: `status`
6. Type value: `draft`

Click **Save** (checkmark icon)

---

## 🎯 Complete CREATE Configuration

Here's what your CREATE permission should look like:

```
┌─────────────────────────────────────────────────────────┐
│ CREATE Permission for "problems" collection            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ 📋 Item Permissions (Filter)                           │
│    user_owner Equal To $CURRENT_USER                   │
│                                                         │
│ 📝 Field Permissions                                    │
│    ✅ All fields                                        │
│    ❌ Except: id, date_created, date_updated           │
│                                                         │
│ ⭐ Field Presets                                        │
│    user_owner = $CURRENT_USER                          │
│    status = draft                                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🔍 Why All Three Are Needed

### Scenario: User Creates a Problem

1. **Filter checks:** "Can user create this?"
   - If `user_owner` would be `$CURRENT_USER` → ✅ Yes
   - If `user_owner` would be someone else → ❌ No

2. **Field Presets apply:** Directus automatically adds:
   - `user_owner` = Firebase user ID
   - `status` = "draft"

3. **Field Permissions check:** "Can user write these fields?"
   - `title`, `description`, etc. → ✅ Yes
   - `id`, `date_created` → ❌ No

4. **Result:** Problem created with correct owner!

---

## 📋 Complete Permissions Guide

### CREATE Permission
```
Filter:         user_owner = $CURRENT_USER
Permissions:    All except (id, date_created, date_updated)
Presets:        user_owner = $CURRENT_USER
                status = draft
```

### READ Permission
```
Filter:         user_owner = $CURRENT_USER 
                OR 
                status = published
Permissions:    All fields
Presets:        (none needed for read)
```

### UPDATE Permission
```
Filter:         user_owner = $CURRENT_USER
Permissions:    All except (id, user_owner, date_created, date_updated)
Presets:        (none - user already owns it)
```

### DELETE Permission
```
Filter:         user_owner = $CURRENT_USER
Permissions:    (not applicable for delete)
Presets:        (not applicable for delete)
```

---

## 🧪 Testing

### Test 1: Create Without Sending user_owner

```dart
// In your Flutter app
final response = await http.post(
  Uri.parse('http://192.168.1.3:8055/items/problems'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $firebaseToken',
  },
  body: json.encode({
    'title': 'Test Problem',
    'description': 'Testing auto user_owner',
    'difficulty': 'beginner',
    'category': 'Geometry',
    // ✅ NO user_owner sent!
  }),
);

print(response.statusCode); // Should be 200!

// Check the response
final data = json.decode(response.body);
print(data['data']['user_owner']); // Should be your Firebase UID!
print(data['data']['status']); // Should be "draft"!
```

### Test 2: Verify in Directus Admin

1. Go to **Content** → **problems**
2. Find your test problem
3. Check fields:
   - ✅ `user_owner` should be your Firebase user ID
   - ✅ `status` should be "draft"
   - ✅ Both fields auto-filled by presets!

---

## 🚨 Common Mistakes

### ❌ Mistake 1: Filter without Preset
```
Filter: user_owner = $CURRENT_USER
Presets: (none)
```
**Result:** ❌ Permission denied! Field is empty, doesn't match filter.

### ❌ Mistake 2: Preset without Filter
```
Filter: (none)
Presets: user_owner = $CURRENT_USER
```
**Result:** ⚠️ Works, but insecure! User could manually set `user_owner` to someone else!

### ✅ Correct: Both Filter AND Preset
```
Filter: user_owner = $CURRENT_USER
Presets: user_owner = $CURRENT_USER
```
**Result:** ✅ Secure AND automatic!

---

## 🎉 Benefits of Using Presets

1. ✅ **Automatic ownership** - No need to send `user_owner` from Flutter
2. ✅ **Simpler Flutter code** - Less data to manage
3. ✅ **Security** - User can't fake ownership
4. ✅ **Default values** - Like `status = draft`
5. ✅ **Cleaner API** - Server handles user context

---

## 📚 Summary

| Feature | Purpose | Example |
|---------|---------|---------|
| **Filter** | Controls which items can be accessed | `user_owner = $CURRENT_USER` |
| **Field Permissions** | Controls which fields can be read/written | All except system fields |
| **Field Presets** ⭐ | Auto-fills field values | `user_owner = $CURRENT_USER` |

**Use all three for secure, automatic ownership tracking!** 🎯
