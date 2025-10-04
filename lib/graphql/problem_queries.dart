/// GraphQL queries and mutations for Problem CRUD operations
/// Compatible with Strapi backend structure

class ProblemQueries {
  /// Fetch all problems with pagination support
  static const String getAllProblems = '''
    query GetProblems(\$start: Int, \$limit: Int) {
      problems(
        pagination: { start: \$start, limit: \$limit }
        sort: ["createdAt:desc"]
      ) {
        data {
          id
          attributes {
            title
            description
            difficulty
            category
            geometryData
            solution
            createdAt
            updatedAt
          }
        }
        meta {
          pagination {
            start
            limit
            total
          }
        }
      }
    }
  ''';

  /// Fetch a specific problem by ID
  static const String getProblemById = '''
    query GetProblem(\$id: ID!) {
      problem(id: \$id) {
        data {
          id
          attributes {
            title
            description
            difficulty
            category
            geometryData
            solution
            createdAt
            updatedAt
          }
        }
      }
    }
  ''';

  /// Create a new problem
  static const String createProblem = '''
    mutation CreateProblem(\$data: ProblemInput!) {
      createProblem(data: \$data) {
        data {
          id
          attributes {
            title
            description
            difficulty
            category
            geometryData
            solution
            createdAt
            updatedAt
          }
        }
      }
    }
  ''';

  /// Update an existing problem
  static const String updateProblem = '''
    mutation UpdateProblem(\$id: ID!, \$data: ProblemInput!) {
      updateProblem(id: \$id, data: \$data) {
        data {
          id
          attributes {
            title
            description
            difficulty
            category
            geometryData
            solution
            createdAt
            updatedAt
          }
        }
      }
    }
  ''';

  /// Delete a problem
  static const String deleteProblem = '''
    mutation DeleteProblem(\$id: ID!) {
      deleteProblem(id: \$id) {
        data {
          id
        }
      }
    }
  ''';
}