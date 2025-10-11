# Directus Migration Summary

## Overview
Successfully migrated from Strapi to Directus backend. All Dart files have been updated to work with Directus's GraphQL API structure.

---

## Key Differences: Strapi vs Directus

### Query Structure

**Strapi (Old):**
```graphql
query {
  problems {
    data {
      id
      attributes {
        title
        description
      }
    }
    meta {
      pagination {
        total
      }
    }
  }
}
```

**Directus (New):**
```graphql
query {
  problems {
    id
    title
    description
  }
  problems_aggregated {
    count {
      id
    }
  }
}
```

### Mutation Structure

**Strapi (Old):**
```graphql
mutation {
  createProblem(data: { title: "..." }) {
    data {
      id
      attributes {
        title
      }
    }
  }
}
```

**Directus (New):**
```graphql
mutation {
  create_problems_item(data: { title: "..." }) {
    id
    title
  }
}
```

### Field Naming Conventions

| Strapi | Directus |
|--------|----------|
| `createdAt` | `date_created` |
| `updatedAt` | `date_updated` |
| `geometryData` | `geometry_data` |
| `start` (pagination) | `offset` (pagination) |

---

## Files Updated

### 1. `/lib/graphql/problem_queries.dart`

**Changes:**
- ✅ Removed nested `data.attributes` structure
- ✅ Changed `start` → `offset` for pagination
- ✅ Changed sort syntax: `["createdAt:desc"]` → `["-date_created"]`
- ✅ Added `problems_aggregated` for total count
- ✅ Updated mutation names:
  - `createProblem` → `create_problems_item`
  - `updateProblem` → `update_problems_item`
  - `deleteProblem` → `delete_problems_item`
- ✅ Changed field names: `geometryData` → `geometry_data`, `createdAt` → `date_created`, etc.
- ✅ Flattened mutation variables (no nested `data` object)

### 2. `/lib/models/problem.dart`

**Changes:**
- ✅ Updated `fromJson()` to parse flat Directus structure (no `attributes` wrapper)
- ✅ Changed field names in parsing: `geometry_data`, `date_created`, `date_updated`
- ✅ Updated `toJson()` to use Directus field names
- ✅ Updated `ProblemList.fromJson()` to parse Directus pagination format
- ✅ Added `offset` field to `ProblemList` (maintains `start` getter for compatibility)
- ✅ Updated `hasMore` calculation for Directus pagination

### 3. `/lib/bloc/problem_bloc.dart`

**Changes:**
- ✅ Renamed `_currentStart` → `_currentOffset`
- ✅ Updated `_onFetchProblems()` to use `offset` instead of `start`
- ✅ Changed GraphQL response parsing: `result.data!['problems']` → `result.data!`
- ✅ Updated `_onLoadMoreProblems()` pagination logic for offset-based system
- ✅ Updated `_onCreateProblem()`:
  - Flattened variables (removed nested `data` object)
  - Changed response path: `result.data!['createProblem']['data']` → `result.data!['create_problems_item']`
  - Changed field name: `geometryData` → `geometry_data`
- ✅ Updated `_onUpdateProblem()`:
  - Flattened variables
  - Changed response path: `result.data!['updateProblem']['data']` → `result.data!['update_problems_item']`
  - Changed field name: `geometryData` → `geometry_data`
- ✅ Updated `_onFetchProblemById()`:
  - Changed response path: `result.data!['problem']['data']` → `result.data!['problems_by_id']`

### 4. `/lib/config/graphql_config.dart`

**Already Updated:**
- ✅ Endpoint: `http://192.168.1.3:8055/graphql`
- ✅ Comment updated to "Directus backend"

---

## Testing Checklist

### Backend Setup
- [x] Directus running on http://192.168.1.3:8055
- [x] PostgreSQL database connected
- [x] `problems` collection created with all fields
- [x] Public role permissions set (CRUD enabled)
- [x] GraphQL endpoint accessible

### Field Verification
- [x] `title` (String, required)
- [x] `description` (Text, required)
- [x] `difficulty` (Dropdown: beginner/intermediate/advanced/expert)
- [x] `category` (Dropdown: geometry/algebra/trigonometry/calculus/proofs)
- [x] `geometry_data` (JSON, optional)
- [x] `solution` (Rich text, optional)
- [x] `date_created` (Timestamp, auto)
- [x] `date_updated` (Timestamp, auto)

### CRUD Operations (curl tested)
- [x] Create problem
- [x] Read all problems
- [x] Read one problem by ID
- [x] Update problem
- [x] Delete problem

### Flutter Integration (To Test)
- [ ] Fetch problems list
- [ ] Pagination (load more)
- [ ] Create new problem
- [ ] Update existing problem
- [ ] Delete problem
- [ ] Fetch single problem details

---

## Next Steps

1. **Run Flutter app** and test CRUD operations
2. **Monitor GraphQL queries** for any parsing errors
3. **Test pagination** by creating multiple problems
4. **Verify timestamp formatting** in UI displays
5. **Test geometry_data** JSON serialization

---

## Rollback Plan (if needed)

If issues arise, you can quickly rollback by:

1. Switch back to Strapi docker-compose
2. Revert these Git commits:
   - `lib/graphql/problem_queries.dart`
   - `lib/models/problem.dart`
   - `lib/bloc/problem_bloc.dart`
   - `lib/config/graphql_config.dart`

---

## Benefits of Directus

✅ **Simpler structure** - No nested `data.attributes`  
✅ **Built-in GraphQL** - No plugin installation  
✅ **Better Docker support** - No version issues  
✅ **Modern admin UI** - Intuitive and fast  
✅ **Automatic timestamps** - `date_created`, `date_updated`  
✅ **Better pagination** - Offset-based with aggregation  

---

## Contact

If you encounter any issues:
1. Check Directus logs: `docker compose logs directus`
2. Verify GraphQL queries in GraphiQL playground
3. Check Public role permissions in Directus admin

**Directus Admin:** http://192.168.1.3:8055  
**Login:** admin@example.com / geofrontapp_admin_2025  
**GraphQL Endpoint:** http://192.168.1.3:8055/graphql
