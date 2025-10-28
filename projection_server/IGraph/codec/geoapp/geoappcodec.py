"""Codec helpers for the GeoApp JSON construction format."""

from __future__ import annotations

import json
from typing import Any, Dict


class GeoAppCodec:
  """Utility codec that mirrors the GeoDraw encoder on the Flutter side."""

  @staticmethod
  def encoder(content: Any, signal: bool = True) -> Dict[str, Any]:
    """Decode incoming solver payload into a normalized python dict."""
    del signal

    if isinstance(content, (bytes, bytearray)):
      content = content.decode("utf-8")

    if isinstance(content, str):
      payload = json.loads(content)
    elif isinstance(content, dict):
      payload = content
    else:
      raise TypeError("Unsupported GeoApp payload type")

    def _pick(*names: str) -> Any:
      for name in names:
        if name in payload and payload[name] is not None:
          return payload[name]
      return None

    construction = _pick("construction", "geometry", "geometryData", "geometry_data")

    if construction is None:
      raise ValueError("GeoApp payload missing construction data")

    proof_goal = _pick("proofGoal", "proof_goal")
    scalar_constraints = _pick("scalarConstraints", "scalar_constraints")
    object_constraints = _pick("objectConstraints", "object_constraints")
    scalar_proof = _pick("scalarProof", "scalar_proof")
    object_proof = _pick("objectProof", "object_proof")

    return {
      "construction": construction,
      "scalarConstraints": scalar_constraints,
      "objectConstraints": object_constraints,
      "scalarProof": scalar_proof,
      "objectProof": object_proof,
      "proofGoal": proof_goal,
      "raw": payload,
    }

  @staticmethod
  def decoder(construction: Any, *, pretty: bool = False) -> str:
    """Encode a construction dictionary back to a JSON string."""
    if pretty:
      return json.dumps(construction, indent=2, ensure_ascii=True)
    return json.dumps(construction, separators=(",", ":"), ensure_ascii=True)
