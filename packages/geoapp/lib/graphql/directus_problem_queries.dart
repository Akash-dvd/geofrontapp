/// GraphQL queries and mutations for Problem CRUD operations
/// Compatible with Directus backend structure (local development)
/// Uses Firebase ID token for authentication via Authorization header
library;

class DirectusProblemQueries {
  /// Fetch all problems with pagination support
  static const String getAllProblems = '''
    query GetProblems(\$limit: Int, \$offset: Int) {
      problems(limit: \$limit, offset: \$offset, sort: ["-date_created"]) {
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
        thumbnail {
          id
        }
        date_created
        date_updated
      }
      problems_aggregated {
        count {
          id
        }
      }
    }
  ''';

  /// Fetch a specific problem by ID
  static const String getProblemById = '''
    query GetProblem(\$id: ID!) {
      problems_by_id(id: \$id) {
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
        thumbnail {
          id
        }
        date_created
        date_updated
      }
    }
  ''';

  /// Create a new problem
  static const String createProblem = '''
    mutation CreateProblem(
      \$title: String!
      \$description: String!
      \$difficulty: String!
      \$category: String!
      \$geometry_data: JSON
      \$solution: String
      \$scalar_constraints: JSON
      \$object_constraints: JSON
      \$scalar_proof: JSON
      \$object_proof: JSON
      \$thumbnail: String
    ) {
      create_problems_item(data: {
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
        thumbnail: \$thumbnail
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
        thumbnail {
          id
        }
        date_created
        date_updated
      }
    }
  ''';

  /// Update an existing problem
  static const String updateProblem = '''
    mutation UpdateProblem(
      \$id: ID!
      \$title: String
      \$description: String
      \$difficulty: String
      \$category: String
      \$geometry_data: JSON
      \$solution: String
      \$scalar_constraints: JSON
      \$object_constraints: JSON
      \$scalar_proof: JSON
      \$object_proof: JSON
      \$thumbnail: String
    ) {
      update_problems_item(
        id: \$id
        data: {
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
          thumbnail: \$thumbnail
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
        thumbnail {
          id
        }
        date_created
        date_updated
      }
    }
  ''';

  /// Delete a problem
  static const String deleteProblem = '''
    mutation DeleteProblem(\$id: ID!) {
      delete_problems_item(id: \$id) {
        id
      }
    }
  ''';
}
