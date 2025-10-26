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

		construction = (
			payload.get("construction")
			or payload.get("geometry")
			or payload.get("geometry_data")
			or payload.get("geometryData")
		)

		if construction is None:
			raise ValueError("GeoApp payload missing construction data")

		proof_goal = payload.get("proof_goal")
		if proof_goal is None and "proofGoal" in payload:
			proof_goal = payload.get("proofGoal")

		scalar_constraints = payload.get("scalar_constraints")
		if scalar_constraints is None and "scalarConstraints" in payload:
			scalar_constraints = payload.get("scalarConstraints")

		object_constraints = payload.get("object_constraints")
		if object_constraints is None and "objectConstraints" in payload:
			object_constraints = payload.get("objectConstraints")

		scalar_proof = payload.get("scalar_proof")
		if scalar_proof is None and "scalarProof" in payload:
			scalar_proof = payload.get("scalarProof")

		object_proof = payload.get("object_proof")
		if object_proof is None and "objectProof" in payload:
			object_proof = payload.get("objectProof")

		return {
			"construction": construction,
			"scalar_constraints": scalar_constraints,
			"object_constraints": object_constraints,
			"scalar_proof": scalar_proof,
			"object_proof": object_proof,
			"proof_goal": proof_goal,
			"raw": payload,
		}

	@staticmethod
	def decoder(construction: Any, *, pretty: bool = False) -> str:
		"""Encode a construction dictionary back to a JSON string."""
		if pretty:
			return json.dumps(construction, indent=2, ensure_ascii=True)
		return json.dumps(construction, separators=(",", ":"), ensure_ascii=True)
