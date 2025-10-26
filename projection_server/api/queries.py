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

  geometry = problem.get("geometry_data") or problem.get("geometryData")
  scalar_constraints = problem.get("scalar_constraints") or problem.get("scalarConstraints")
  object_constraints = problem.get("object_constraints") or problem.get("objectConstraints")
  scalar_proof = problem.get("scalar_proof") or problem.get("scalarProof")
  object_proof = problem.get("object_proof") or problem.get("objectProof")
  proof_goal = problem.get("proof_goal") or problem.get("proofGoal")

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

  geometry = input.get("construction_data") or input.get("constructionData")
  scalar_constraints = input.get("scalar_constraints") or input.get("scalarConstraints")
  object_constraints = input.get("object_constraints") or input.get("objectConstraints")
  proof_goal = input.get("proof_goal") or input.get("proofGoal")

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
      "error_message": str(exc),
      "error_type": "SOLVER_ERROR",
      "scalar_proof": None,
      "object_proof": None,
      "constraint_results": [],
      "construction_steps": [],
      "computation_time": None,
    }


def solver_status_resolver(_obj, info):
  """Expose basic health information for the solver service."""
  del info
  uptime_ms = (time.time() - _SOLVER_START_TIME) * 1000.0
  version = current_app.config.get("SOLVER_VERSION", "local-dev")

  return {
    "online": True,
    "version": version,
    "uptime_ms": uptime_ms,
    "request_count": _SOLVER_REQUEST_COUNT,
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
    "scalar_constraints": _parse_json_like(scalar_constraints) or [],
    "object_constraints": _parse_json_like(object_constraints) or [],
    "scalar_proof": _parse_json_like(scalar_proof) or [],
    "object_proof": _parse_json_like(object_proof) or [],
    "proof_goal": proof_goal,
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
      "step_number": index,
      "command": None,
      "description": description,
      "theorem_applied": None,
      "justification": justification,
    })

  success = len(mapped_entries) > 0
  error_message = None if success else "Solver returned no solution steps"

  object_proof_payload = {"solutions": mapped_entries} if mapped_entries else None

  return {
    "success": success,
    "error_message": error_message,
    "error_type": None,
    "scalar_proof": None,
    "object_proof": object_proof_payload,
    "constraint_results": [],
    "construction_steps": construction_steps,
    "computation_time": None,
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