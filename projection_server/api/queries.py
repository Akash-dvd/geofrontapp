import json
import time
from typing import Any, Dict, Iterable, List

from ariadne import convert_kwargs_to_snake_case
from flask import current_app

from worker.worker import worker

_SOLVER_START_TIME = time.time()
_SOLVER_REQUEST_COUNT = 0


@convert_kwargs_to_snake_case
def solve_problem_resolver(_obj, info, problem: Dict[str, Any]):
  """Handle solveProblem mutation."""
  del info
  global _SOLVER_REQUEST_COUNT
  _SOLVER_REQUEST_COUNT += 1

  geometry = problem.get("geometryData") or problem.get("geometry_data")
  scalar_constraints = problem.get("scalarConstraints") or problem.get("scalar_constraints")
  object_constraints = problem.get("objectConstraints") or problem.get("object_constraints")
  scalar_proof = problem.get("scalarProof") or problem.get("scalar_proof")
  object_proof = problem.get("objectProof") or problem.get("object_proof")
  proof_goal = problem.get("proofGoal") or problem.get("proof_goal")

  try:
    payload = _build_worker_payload(
      geometry=geometry,
      scalar_constraints=scalar_constraints,
      object_constraints=object_constraints,
      scalar_proof=scalar_proof,
      object_proof=object_proof,
      proof_goal=proof_goal,
    )
    raw_result = worker(payload, True)
    solutions = [_map_solution_entry(entry) for entry in raw_result]

    return {
      "success": True,
      "solutions": solutions,
      "errors": [],
    }
  except Exception as exc:  # pylint: disable=broad-except
    current_app.logger.exception("Failed to solve problem")
    return {
      "success": False,
      "solutions": [],
      "errors": [str(exc)],
    }


@convert_kwargs_to_snake_case
def solve_constraints_resolver(_obj, info, input: Dict[str, Any]):
  """Handle solveConstraints mutation expected by the Flutter client."""
  del info
  global _SOLVER_REQUEST_COUNT
  _SOLVER_REQUEST_COUNT += 1

  geometry = input.get("constructionData") or input.get("construction_data")
  scalar_constraints = input.get("scalarConstraints") or input.get("scalar_constraints")
  object_constraints = input.get("objectConstraints") or input.get("object_constraints")
  proof_goal = input.get("proofGoal") or input.get("proof_goal")

  try:
    payload = _build_worker_payload(
      geometry=geometry,
      scalar_constraints=scalar_constraints,
      object_constraints=object_constraints,
      scalar_proof=None,
      object_proof=None,
      proof_goal=proof_goal,
    )
    raw_result = worker(payload, True)
    return _map_worker_result_to_constraint_response(raw_result)
  except Exception as exc:  # pylint: disable=broad-except
    current_app.logger.exception("Failed to solve constraints")
    return {
      "success": False,
      "errorMessage": str(exc),
      "errorType": "SOLVER_ERROR",
      "scalarProof": None,
      "objectProof": None,
      "constraintResults": [],
      "constructionSteps": [],
      "computationTime": None,
    }


def solver_status_resolver(_obj, info):
  """Expose basic health information for the solver service."""
  del info
  uptime_ms = (time.time() - _SOLVER_START_TIME) * 1000.0
  version = current_app.config.get("SOLVER_VERSION", "local-dev")

  return {
    "online": True,
    "version": version,
    "uptimeMs": uptime_ms,
    "requestCount": _SOLVER_REQUEST_COUNT,
  }


def _build_worker_payload(
  *,
  geometry: Any,
  scalar_constraints: Any = None,
  object_constraints: Any = None,
  scalar_proof: Any = None,
  object_proof: Any = None,
  proof_goal: Any = None,
) -> str:
  construction = _parse_json_like(geometry)
  if construction is None:
    raise ValueError("geometryData is required")

  worker_payload = {
    "construction": construction,
    "scalarConstraints": _parse_json_like(scalar_constraints) or [],
    "objectConstraints": _parse_json_like(object_constraints) or [],
    "scalarProof": _parse_json_like(scalar_proof) or [],
    "objectProof": _parse_json_like(object_proof) or [],
    "proofGoal": proof_goal,
  }

  return json.dumps(worker_payload)


def _parse_json_like(value: Any) -> Any:
  if value is None:
    return None
  if isinstance(value, (dict, list)):
    return value
  if isinstance(value, str):
    stripped = value.strip()
    if not stripped:
      return None
    try:
      return json.loads(stripped)
    except json.JSONDecodeError:
      return stripped
  return value


def _map_worker_result_to_constraint_response(raw_result: Any) -> Dict[str, Any]:
  entries: List[Any] = []
  if isinstance(raw_result, list):
    entries = raw_result
  elif raw_result is not None:
    entries = [raw_result]

  mapped_entries = [_map_solution_entry(entry) for entry in entries]
  construction_steps = []
  for index, mapped in enumerate(mapped_entries, start=1):
    justification = None
    if mapped["references"]:
      justification = ", ".join(mapped["references"])

    description = mapped["text"] if mapped["text"] else f"Step {index}"

    construction_steps.append({
      "stepNumber": index,
      "command": None,
      "description": description,
      "theoremApplied": None,
      "justification": justification,
    })

  success = len(mapped_entries) > 0
  error_message = None if success else "Solver returned no solution steps"

  object_proof_payload = {"solutions": mapped_entries} if mapped_entries else None

  return {
    "success": success,
    "errorMessage": error_message,
    "errorType": None,
    "scalarProof": None,
    "objectProof": object_proof_payload,
    "constraintResults": [],
    "constructionSteps": construction_steps,
    "computationTime": None,
  }


def _map_solution_entry(entry: Any) -> Dict[str, Any]:
  if isinstance(entry, dict):
    text = str(entry.get("description") or entry.get("text") or "").strip()
    geometry = _parse_solution_geometry(entry.get("xml") or entry.get("geometry"))
    references = _normalize_references(entry.get("references"))
    return {
      "text": text,
      "geometry": geometry,
      "references": references,
    }

  return {
    "text": str(entry),
    "geometry": None,
    "references": [],
  }


def _parse_solution_geometry(value: Any) -> Any:
  if value is None:
    return None
  if isinstance(value, (dict, list)):
    return value
  if isinstance(value, str):
    stripped = value.strip()
    if not stripped:
      return None
    try:
      return json.loads(stripped)
    except json.JSONDecodeError:
      return stripped
  return value


def _normalize_references(value: Any) -> List[str]:
  if value is None:
    return []
  if isinstance(value, str):
    stripped = value.strip()
    return [stripped] if stripped else []
  if isinstance(value, Iterable):
    return [str(item) for item in value if str(item).strip()]
  return [str(value)]