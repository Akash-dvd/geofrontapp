from typing import Any, Dict, List

from IGraph.codec.geoapp.geoappcodec import GeoAppCodec


def worker(content: Any, signal: bool) -> List[Dict[str, Any]]:
  """Echo solver that returns the supplied construction as geometry."""
  del signal
  parsed = GeoAppCodec.encoder(content)
  construction = parsed["construction"]
  proof_goal = parsed.get("proofGoal")

  # Keep geometry structured so the Flutter canvases can render it directly.
  geometry_payload = construction

  goal_label = "problem"
  if isinstance(proof_goal, str) and proof_goal.strip():
    goal_label = proof_goal.strip()

  return [
    {
      "description": f"Echo solution for {goal_label}",
      "references": ["echo-step-1"],
      "geometry": geometry_payload,
    },
    {
      "description": f"Echo solution for {goal_label} (repeat)",
      "references": ["echo-step-2"],
      "geometry": geometry_payload,
    }
  ]
