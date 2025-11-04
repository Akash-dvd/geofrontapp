"""Worker function that orchestrates sequential tasks using Chain pattern."""

from typing import Any, Dict, List
import json

from worker.chain import Chain
from GraphForest.codec.geoapp.geoappcodec import GeoAppCodec
from GraphForest.DCG import create_dcg
from solver.QGraph import QGraph


def worker(content: Any, signal: bool) -> List[Dict[str, Any]]:
  """Worker function that orchestrates sequential tasks.
  
  Tasks executed:
  1. Encoder - Convert GeoApp JSON to GraphForest
  2. DCG Creator - Create Directed Cyclic Graph from GraphForest
  3. Solver - Solve the graph (QGraph creation)
  4. Solution Creator - Create solutions based on results
  
  Args:
    content: Input payload (JSON string, dict, or bytes)
    signal: Signal flag (unused for now)
  
  Returns:
    List of solution dictionaries
  """
  del signal
  
  # Parse input payload first to extract construction and proof_goal
  if isinstance(content, (bytes, bytearray)):
    content = content.decode("utf-8")
  
  if isinstance(content, str):
    payload = json.loads(content)
  elif isinstance(content, dict):
    payload = content
  else:
    raise TypeError("Unsupported GeoApp payload type")
  
  # Extract construction data from payload
  def _pick(*names: str) -> Any:
    for name in names:
      if name in payload and payload[name] is not None:
        return payload[name]
    return None
  
  construction_data = _pick("construction", "geometry", "geometryData", "geometry_data")
  if construction_data is None:
    raise ValueError("GeoApp payload missing construction data")
  
  # Handle different construction formats
  if isinstance(construction_data, str):
    construction_data = json.loads(construction_data)
  
  proof_goal = _pick("proofGoal", "proof_goal")
  
  # Define chain of tasks
  # Each task processes the data and passes it to the next
  # Using direct callable references instead of strings
  tasks = [
    {
      "class_name": GeoAppCodec.encoder,
      "array": [],
      "dictionary": {"signal": True, "print": True}
    },
    {
      "class_name": create_dcg,
      "array": [],
      "dictionary": {"print": True}
    },
    {
      "class_name": QGraph.create_qgraph_on_dag,
      "array": [],
      "dictionary": {"print": True}
    },
    {
      "class_name": GeoAppCodec.decoder,
      "array": [],
      "dictionary": {"pretty": False, "print": True}
    }
  ]
  
  # Execute chain
  chain = Chain(tasks)
  chain_result = chain.execute(initial_input=content)
  
  # Check for errors
  if chain_result["errors"]:
    # Log errors but continue with echo response for now
    for error in chain_result["errors"]:
      print(f"Chain error in task {error['task_index']} ({error['class_name']}): {error['error']}")
      print(f"Traceback: {error.get('traceback', 'N/A')}")
  
  # Log successful execution
  print(f"Chain executed {len(chain_result['results'])} tasks")
  for idx, result in enumerate(chain_result["results"]):
    if result.get("success"):
      print(f"Task {idx} ({result['class_name']}) completed successfully")
  
  # Extract decoded geometry from the chain result
  # The final output from the chain should be the decoded JSON string
  final_output = chain_result.get("final_output")
  
  if isinstance(final_output, str):
    # Decoder returns JSON string, parse it
    try:
      geometry_payload = json.loads(final_output)
    except json.JSONDecodeError:
      # Fallback to original construction if parsing fails
      print("Warning: Failed to parse decoded JSON, using original construction")
      geometry_payload = construction_data
  else:
    # Fallback to original construction if output is not as expected
    print("Warning: Chain output is not a JSON string, using original construction")
    geometry_payload = construction_data
  
  goal_label = "problem"
  if isinstance(proof_goal, str) and proof_goal.strip():
    goal_label = proof_goal.strip()

  return [
    {
      "description": f"Solution for {goal_label}",
      "references": ["solution-step-1"],
      "geometry": geometry_payload,
    },
    {
      "description": f"Solution for {goal_label} (alternative)",
      "references": ["solution-step-2"],
      "geometry": geometry_payload,
    }
  ]
