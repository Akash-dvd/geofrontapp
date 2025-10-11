# Adding Constraint and Proof Fields to Directus

## Step 1: Access Directus Admin

1. Open browser: `http://192.168.1.3:8055/admin`
2. Login with:
   - Email: `admin@example.com`
   - Password: `geofrontapp_admin_2025`

## Step 2: Navigate to Problems Collection

1. Click on **Settings** (gear icon) in left sidebar
2. Click on **Data Model**
3. Find and click on **problems** collection

## Step 3: Add New Fields

### Field 1: scalar_constraints

1. Click **"+ Create Field"** button
2. Select **JSON** type
3. Configure:
   - **Key:** `scalar_constraints`
   - **Field Name:** Scalar Constraints
   - **Note:** Numerical constraints (distances, angles, ratios)
   - **Interface:** Input (JSON)
   - **Allow NULL:** ✓ (checked)
4. Click **Save**

### Field 2: object_constraints

1. Click **"+ Create Field"** button
2. Select **JSON** type
3. Configure:
   - **Key:** `object_constraints`
   - **Field Name:** Object Constraints
   - **Note:** Geometric constraints (parallel, perpendicular, tangent)
   - **Interface:** Input (JSON)
   - **Allow NULL:** ✓ (checked)
4. Click **Save**

### Field 3: scalar_proof

1. Click **"+ Create Field"** button
2. Select **JSON** type
3. Configure:
   - **Key:** `scalar_proof`
   - **Field Name:** Scalar Proof
   - **Note:** Algebraic/numerical proof as JSON (e.g., {len12: "2*len2"})
   - **Interface:** Input (JSON)
   - **Allow NULL:** ✓ (checked)
4. Click **Save**

### Field 4: object_proof

1. Click **"+ Create Field"** button
2. Select **JSON** type
3. Configure:
   - **Key:** `object_proof`
   - **Field Name:** Object Proof
   - **Note:** Geometric proof as JSON (e.g., {arecollinear: ["c1","c2","c3"]})
   - **Interface:** Input (JSON)
   - **Allow NULL:** ✓ (checked)
4. Click **Save**

## Step 4: Update Public Role Permissions

1. Go to **Settings** → **Roles & Permissions**
2. Click on **Public** role
3. Find **problems** collection
4. Ensure new fields have permissions:
   - Read: ✓
   - Create: ✓
   - Update: ✓

## Step 5: Verify Schema

Run this query in GraphQL Playground (`http://192.168.1.3:8055/graphql`):

```graphql
query {
  problems {
    id
    title
    scalar_constraints
    object_constraints
    scalar_proof
    object_proof
  }
}
```

Should return without errors (even if values are null).

## Step 6: Test Insert

```graphql
mutation {
  create_problems_item(data: {
    title: "Test Constraint Problem"
    description: "Testing constraint fields"
    difficulty: "beginner"
    category: "geometry"
    scalar_constraints: {
      "l1-l2": 0
    }
    object_constraints: {
      "C1|C2": 0
    }
    scalar_proof: {
      "len12": "2*len2"
    }
    object_proof: {
      "arecollinear": ["c1", "c2", "c3"]
    }
  }) {
    id
    title
    scalar_constraints
    object_constraints
    scalar_proof
    object_proof
  }
}
```

## Done!

The database is now ready to store constraints and proofs.
