import os
from worker.worker import worker
import json

# Test with GeoApp JSON format
# path1 = os.path.abspath("json/test1.json")
# path2 = os.path.abspath("json/test2.json")

path1 = os.path.abspath("json/test1.json")

# Read JSON file
with open(path1, 'r', encoding='utf-8') as f:
  construction_data = json.load(f)

# Build GeoApp payload format
obj = {
  "construction": construction_data,
  "scalarConstraints": [],
  "scalarProof": [],
  "objectProof": [{"name": "areIncident", "nestedArray": ["c1", "l1"]}],
  "objectConstraints": [],
  "proofGoal": "Prove incidence"
}

dmp = json.dumps(obj)

print("Testing with GeoApp JSON format:")
print(f"File: {path1}")
print("=" * 80)

worker(dmp, True)
