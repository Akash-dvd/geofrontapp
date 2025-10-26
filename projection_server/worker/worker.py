from IGraph.codec.geogebra.geogebraCodec import geogebraCodec
from IGraph.SkeletonGraph import SkeletonGraph

from typing import Any, Dict, List

from IGraph.codec.geoapp.geoappcodec import GeoAppCodec


def worker(content: Any, signal: bool) -> List[Dict[str, Any]]:
  """Simple echo solver that returns the construction twice with copy text."""
  del signal
  parsed = GeoAppCodec.encoder(content)
  construction = parsed["construction"]
  proof_goal = parsed.get("proof_goal")

  geometry_payload = GeoAppCodec.decoder(construction)

  goal_label = "problem"
  if isinstance(proof_goal, str) and proof_goal.strip():
    goal_label = proof_goal.strip()

  messages = [
    f"Echo solution 1 for {goal_label}",
    f"Echo solution 2 exploring {goal_label}",
  ]

  solutions: List[Dict[str, Any]] = []
  for index, message in enumerate(messages, start=1):
    solutions.append({
      "description": message,
      "references": [f"echo-step-{index}"],
      "geometry": geometry_payload,
    })

  return solutions
  # Print results
