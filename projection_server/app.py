from api import app
from ariadne import load_schema_from_path, make_executable_schema, \
  graphql_sync, ObjectType, ScalarType
from ariadne.explorer import ExplorerGraphiQL
# from ariadne.constants import PLAYGROUND_HTML
from flask import request, jsonify
# from api.queries import listPosts_resolver
from api.queries import solve_problem_resolver, solve_constraints_resolver, solver_status_resolver

query = ObjectType("Query")
query.set_field("solverStatus", solver_status_resolver)

mutation = ObjectType("Mutation")
mutation.set_field("solveProblem", solve_problem_resolver)
mutation.set_field("solveConstraints", solve_constraints_resolver)

json_scalar = ScalarType("JSON")

@json_scalar.serializer
def serialize_json(value):
  return value


@json_scalar.value_parser
def parse_json(value):
  return value

type_defs = load_schema_from_path("schema.graphql")
schema = make_executable_schema(type_defs, query, mutation, json_scalar)

explorer_html = ExplorerGraphiQL().html(None)
@app.route("/graphql", methods=["GET"])
def graphql_explorer():
  return explorer_html, 200

@app.route("/graphql", methods=["POST"])
def graphql_server():
  data = request.get_json()
  success, result = graphql_sync(
    schema,
    data,
    context_value=request,
    debug=app.debug

  )
  status_code = 200 if success else 400
  return jsonify(result), status_code