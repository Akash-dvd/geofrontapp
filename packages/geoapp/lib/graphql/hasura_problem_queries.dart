/// GraphQL queries and mutations for Problem CRUD operations
/// Compatible with Hasura backend structure (cloud/production)
/// Uses Firebase ID token for JWT authentication
library;

class HasuraProblemQueries {
  /// Fetch all problems with pagination support
  /// Note: Hasura uses different field naming and structure than Directus
  static const String getAllProblems = '''
    query GetProblems(\$limit: Int, \$offset: Int) {
      problems(
        limit: \$limit, 
        offset: \$offset, 
        order_by: {created_at: desc}
      ) {
        id
        title
        description
        difficulty
        category
        geometry_data
        solution
        scalar_constraints
        object_constraints
        scalar_proof
        object_proof
        thumbnail_id
        created_at
        updated_at
        user_id
      }
      problems_aggregate {
        aggregate {
          count
        }
      }
    }
  ''';

  /// Fetch a specific problem by ID
  static const String getProblemById = '''
    query GetProblem(\$id: uuid!) {
      problems_by_pk(id: \$id) {
        id
        title
        description
        difficulty
        category
        geometry_data
        solution
        scalar_constraints
        object_constraints
        scalar_proof
        object_proof
        thumbnail_id
        created_at
        updated_at
        user_id
      }
    }
  ''';

  /// Create a new problem
  /// Firebase ID token provides user_id via JWT claims
  static const String createProblem = '''
    mutation CreateProblem(
      \$title: String!
      \$description: String!
      \$difficulty: String!
      \$category: String!
      \$geometry_data: jsonb
      \$solution: String
      \$scalar_constraints: jsonb
      \$object_constraints: jsonb
      \$scalar_proof: jsonb
      \$object_proof: jsonb
      \$thumbnail_id: String
    ) {
      insert_problems_one(object: {
        title: \$title
        description: \$description
        difficulty: \$difficulty
        category: \$category
        geometry_data: \$geometry_data
        solution: \$solution
        scalar_constraints: \$scalar_constraints
        object_constraints: \$object_constraints
        scalar_proof: \$scalar_proof
        object_proof: \$object_proof
        thumbnail_id: \$thumbnail_id
      }) {
        id
        title
        description
        difficulty
        category
        geometry_data
        solution
        scalar_constraints
        object_constraints
        scalar_proof
        object_proof
        thumbnail_id
        created_at
        updated_at
        user_id
      }
    }
  ''';

  /// Update an existing problem
  static const String updateProblem = '''
    mutation UpdateProblem(
      \$id: uuid!
      \$title: String
      \$description: String
      \$difficulty: String
      \$category: String
      \$geometry_data: jsonb
      \$solution: String
      \$scalar_constraints: jsonb
      \$object_constraints: jsonb
      \$scalar_proof: jsonb
      \$object_proof: jsonb
      \$thumbnail_id: String
    ) {
      update_problems_by_pk(
        pk_columns: {id: \$id}
        _set: {
          title: \$title
          description: \$description
          difficulty: \$difficulty
          category: \$category
          geometry_data: \$geometry_data
          solution: \$solution
          scalar_constraints: \$scalar_constraints
          object_constraints: \$object_constraints
          scalar_proof: \$scalar_proof
          object_proof: \$object_proof
          thumbnail_id: \$thumbnail_id
        }
      ) {
        id
        title
        description
        difficulty
        category
        geometry_data
        solution
        scalar_constraints
        object_constraints
        scalar_proof
        object_proof
        thumbnail_id
        created_at
        updated_at
        user_id
      }
    }
  ''';

  /// Delete a problem
  static const String deleteProblem = '''
    mutation DeleteProblem(\$id: uuid!) {
      delete_problems_by_pk(id: \$id) {
        id
      }
    }
  ''';
}
