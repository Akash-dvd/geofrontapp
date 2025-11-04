"""Codec helpers for the GeoApp JSON construction format."""

from __future__ import annotations

import json
from collections import OrderedDict
from typing import Any, Dict
from sympy import S

from GraphForest.GraphForest import GraphForest
from Sygal.GAtom import GAtom, GExpr
from Sygal.relDt.relDt import relDt


class GeoAppCodec:
  """Utility codec that mirrors the GeoDraw encoder on the Flutter side.
  
  Follows the same pattern as geogebraCodec:
  1. Creates symlist (mapping id -> GAtom)
  2. Creates construction dict (with type, dependency, command, extra)
  3. Extracts constraints/proofs into appendage
  4. Returns DAG(symlist, construction, appendage)
  """

  # Type mapping: GeoApp types -> canonical types
  POINT_TYPES = {
    'GeoPointer', 'GeoMidpoint', 'GeoCenter', 'GeoInvPoint', 'GeoTransPoint'
  }
  LINE_TYPES = {
    'GeoLine2P', 'GeoPerpendicularLine', 'GeoParallelLine', 
    'GeoPerpendicularBisector', 'GeoPolarLine', 'GeoInvLine', 'GeoAngleBisector3P', 'GeoTransLine'
  }
  CIRCLE_TYPES = {
    'GeoCircle2P', 'GeoCircle3P', 'GeoInvCircle', 'GeoTransCircle'
  }
  SEGMENT_TYPES = {
    'GeoSegment', 'GeoSegment2P', 'GeoTransSegment'
  }
  ARC_TYPES = {
    'GeoArc', 'GeoArc3P', 'GeoTransArc'
  }
  UNION_TYPES = {
    'GeoPolygon', 'GeoTriangle', 'GeoRectangle', 'GeoRegularPolygon', 
    'GeoRegularPolygon2P', 'GeoRegularPolygonSegment', 'GeoPolyLine', 
    'GeoPolyArc', 'GeoPolyArcGon', 'GeoTransUnionGeometryObjectList'
  }

  @staticmethod
  def _mapTypeToCanonical(obj_type: str) -> str:
    """Map GeoApp type to canonical type (point, line, circle, segment, arc, union)."""
    if obj_type in GeoAppCodec.POINT_TYPES:
      return 'point'
    elif obj_type in GeoAppCodec.LINE_TYPES:
      return 'line'
    elif obj_type in GeoAppCodec.CIRCLE_TYPES:
      return 'circle'
    elif obj_type in GeoAppCodec.SEGMENT_TYPES:
      return 'segment'
    elif obj_type in GeoAppCodec.ARC_TYPES:
      return 'arc'
    elif obj_type in GeoAppCodec.UNION_TYPES:
      return 'union'
    else:
      return 'unknown'  # Fallback for unmapped types

  @staticmethod
  def _createGAtom(label: str, obj_type: str) -> GAtom:
    """Create GAtom from GeoApp object data."""
    canonical_type = GeoAppCodec._mapTypeToCanonical(obj_type)
    mtDt = {GExpr.I41: 1}  # Default for now, might need to be dynamic
    rlDt = relDt()
    
    if canonical_type == 'point':
      rlDt.update({GExpr._oo: S(-1), "self": S(0)})
    elif canonical_type == 'line':
      rlDt.update({GExpr._oo: S(0), "self": S(1)})
    elif canonical_type == 'circle':
      rlDt.update({GExpr._oo: S(-1), "self": S(1)})
    # For segment, arc, union, default relDt for now
    
    return GAtom(label, mtDt, rlDt)
  
  @staticmethod
  def _topological_sort(construction: OrderedDict) -> OrderedDict:
    """Topologically sort construction dict so parents (dependencies) come before children.
    
    This ensures that when traversing the dict, every parent has already been processed.
    
    Args:
      construction: OrderedDict mapping GAtom -> construction data
      
    Returns:
      OrderedDict with nodes in topological order (dependencies before dependents)
    """
    # Build graph for topological sort
    in_degree = {}  # Count of incoming edges (dependencies)
    graph = {}      # Adjacency list: node -> list of nodes that depend on it
    
    # Initialize
    for node in construction.keys():
      in_degree[node] = 0
      graph[node] = []
    
    # Build graph and calculate in-degrees
    for node, data in construction.items():
      dependencies = data.get('dependency', [])
      for dep in dependencies:
        if dep in graph:  # Only process if dependency is in construction
          graph[dep].append(node)  # dep -> node (dep is parent of node)
          in_degree[node] += 1
    
    # Kahn's algorithm for topological sort
    queue = [node for node, degree in in_degree.items() if degree == 0]
    sorted_nodes = []
    
    while queue:
      # Process nodes with no remaining dependencies
      node = queue.pop(0)
      sorted_nodes.append(node)
      
      # Reduce in-degree of dependents
      for dependent in graph[node]:
        in_degree[dependent] -= 1
        if in_degree[dependent] == 0:
          queue.append(dependent)
    
    # Build ordered dict in topological order
    ordered_construction = OrderedDict()
    for node in sorted_nodes:
      ordered_construction[node] = construction[node]
    
    # Include any nodes that weren't in the sort (shouldn't happen, but safety)
    for node, data in construction.items():
      if node not in ordered_construction:
        ordered_construction[node] = data
    
    return ordered_construction
  
  @staticmethod
  def encoder(current_output: Any, *array_args: Any, **dict_kwargs: Any) -> GraphForest:
    """Encode GeoApp JSON payload into DAG format.
    
    Follows geogebraCodec pattern:
    1. Parse construction JSON
    2. Build symlist (id -> GAtom)
    3. Build construction dict
    4. Extract appendage (constraints, proofs)
    
    Args:
      current_output: Input payload (JSON string, dict, or bytes)
      *array_args: Additional positional arguments (unused)
      **dict_kwargs: Keyword arguments (may include 'signal')
    """
    # Extract signal and print flag from kwargs
    signal = dict_kwargs.get("signal", True)
    print_flag = dict_kwargs.get("print", False)
    del signal  # Not used currently

    # Use current_output as content
    content = current_output

    # Parse input
    if isinstance(content, (bytes, bytearray)):
      content = content.decode("utf-8")
    
    if isinstance(content, str):
      payload = json.loads(content)
    elif isinstance(content, dict):
      payload = content
    else:
      raise TypeError("Unsupported GeoApp payload type")

    # Print JSON received if print flag is True
    if print_flag:
      print("=" * 80)
      print("GeoAppCodec.encoder: JSON RECEIVED")
      print("=" * 80)
      print(json.dumps(payload, indent=2, ensure_ascii=True))
      print("=" * 80)

    # Extract construction data
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
    
    # Extract objects array
    objects = construction_data.get('objects', [])
    if not isinstance(objects, list):
      raise ValueError("Construction objects must be a list")

    # Extract appendage data
    appendage = {
      "ScalarConstraints": _pick("scalarConstraints", "scalar_constraints") or [],
      "ScalarProof": _pick("scalarProof", "scalar_proof") or [],
      "ObjectProof": _pick("objectProof", "object_proof") or [],
      "ObjectConstraints": _pick("objectConstraints", "object_constraints") or [],
    }

    # Initialize symlist and construction dict (OrderedDict for topological ordering)
    symlst = OrderedDict()
    symlst["_oo"] = GExpr._oo
    construction = OrderedDict()
    construction[GExpr._oo] = {
      'type': 'point',  # Canonical type for origin
      'dependency': [],
      'command': 'origin',  # Specific command for origin
      'extra': {'iter': 0}
    }

    # First pass: build symlist (all GAtoms) and store object data
    objects_by_id = {}
    for obj_data in objects:
      if not isinstance(obj_data, dict):
        continue
      
      obj_id = obj_data.get('id')
      obj_type = obj_data.get('type', '')  # This is the exact GeoApp type
      obj_label = obj_data.get('label', obj_id)
      dependencies = obj_data.get('dependencies', [])
      style_overrides = obj_data.get('style', {})
      
      if not obj_id:
        continue

      # Create GAtom for symlist
      gatom = GeoAppCodec._createGAtom(obj_label, obj_type)
      symlst[obj_id] = gatom

      # Determine canonical type
      canonical_type = GeoAppCodec._mapTypeToCanonical(obj_type)
      
      # The command is the exact GeoApp type
      command = obj_type 
      
      # Handle GenSimpleGeometryObjectList types (intersections, tangents)
      if obj_type in ['GeoIntersection', 'GeoTangent']:
        objects_list = obj_data.get('objects', [])
        if isinstance(objects_list, list) and len(objects_list) > 0:
          # Create construction entries for each list item
          for idx, list_obj in enumerate(objects_list):
            list_obj_id = list_obj.get('id') if isinstance(list_obj, dict) else f"{obj_id}_{idx}"
            list_obj_label = list_obj.get('label') if isinstance(list_obj, dict) else f"{obj_label}_{idx}"
            list_obj_type = list_obj.get('type', canonical_type) if isinstance(list_obj, dict) else canonical_type
            
            # Create GAtom for list item
            list_gatom = GeoAppCodec._createGAtom(list_obj_label, list_obj_type)
            symlst[list_obj_id] = list_gatom
            
            # Determine canonical type for list item
            list_canonical_type = GeoAppCodec._mapTypeToCanonical(list_obj_type)
            
            # Dependencies are the same as parent object
            dependency_gatoms = [symlst[dep_id] for dep_id in dependencies if dep_id in symlst]
            
            # Style from list item or parent
            list_style = list_obj.get('style', style_overrides) if isinstance(list_obj, dict) else style_overrides
            
            extra_data = {
              'iter': idx,
              'style': list_style
            }
            
            # Add properties if present
            list_properties = list_obj.get('properties', {}) if isinstance(list_obj, dict) else {}
            if list_properties:
              extra_data.update(list_properties)
            
            construction[list_gatom] = {
              'type': list_canonical_type,  # Canonical type for list item
              'dependency': dependency_gatoms,
              'command': list_obj_type,  # Exact type for list item
              'extra': extra_data
            }
        else:
          # Empty list - create parent entry with iter 0
          dependency_gatoms = [symlst[dep_id] for dep_id in dependencies if dep_id in symlst]
          
          extra_data = {
            'iter': 0,
            'style': style_overrides
          }
          
          properties = obj_data.get('properties', {})
          if properties:
            extra_data.update(properties)
          
          construction[gatom] = {
            'type': canonical_type,
            'dependency': dependency_gatoms,
            'command': command,
            'extra': extra_data
          }
      else:
        # Simple or complex object - iter 0
        dependency_gatoms = [symlst[dep_id] for dep_id in dependencies if dep_id in symlst]
        
        extra_data = {
          'iter': 0,
          'style': style_overrides
        }
        
        properties = obj_data.get('properties', {})
        if properties:
          extra_data.update(properties)
        
        construction[gatom] = {
          'type': canonical_type,
          'dependency': dependency_gatoms,
          'command': command,
          'extra': extra_data
        }
    
    # Topologically sort construction to ensure parents are before children
    construction = GeoAppCodec._topological_sort(construction)
    
    graph_forest = GraphForest(symlst, construction, appendage)

    # Print construction if print flag is True
    if print_flag:
      print("=" * 80)
      print("GeoAppCodec.encoder: CONSTRUCTION CREATED")
      print("=" * 80)
      graph_forest.printElements()
      print("=" * 80)

    return graph_forest

  @staticmethod
  def decoder(current_output: GraphForest, *array_args: Any, **dict_kwargs: Any) -> str:
    """Decode DAG back to GeoApp JSON format.
    
    Reverses the encoder process:
    1. Extract objects from symlist and construction
    2. Rebuild GeoApp JSON structure
    3. Reconstruct constraints/proofs from appendage
    
    Args:
      current_output: The DAG object to decode
      *array_args: Additional positional arguments (unused)
      **dict_kwargs: Keyword arguments (may include 'pretty')
    """
    dag = current_output
    pretty = dict_kwargs.get("pretty", False)
    print_flag = dict_kwargs.get("print", False)
    
    # Print construction (DAG) before decoder if print flag is True
    if print_flag:
      print("=" * 80)
      print("GeoAppCodec.decoder: CONSTRUCTION (DAG) BEFORE DECODER")
      print("=" * 80)
      dag.printElements()
      
      # # Print DCG if available
      # if hasattr(dag, 'dcg') and dag.dcg is not None:
      #   print("\nDCG (Directed Cyclic Graph):")
      #   from GraphForest.DCG import DCG
      #   dcg_instance = DCG.__new__(DCG)
      #   dcg_instance.DCG = dag.dcg
      #   dcg_instance.printElements()
      
      print("=" * 80)

    result = {
      'type': 'construction',
      'version': '1.0',
      'objects': [],
      'constraints': [],
      'proofs': []
    }

    # Create reverse mapping: GAtom -> id
    gatom_to_id = {gatom: obj_id for obj_id, gatom in dag.symlist.items()}
    
    # Process construction dict to rebuild objects
    processed_ids = set()
    
    for gatom, cons_data in dag.dag.items():
      if gatom == GExpr._oo:
        continue  # Skip origin
      
      obj_id = gatom_to_id.get(gatom)
      if not obj_id or obj_id in processed_ids:
        continue
      
      processed_ids.add(obj_id)
      
      # Use 'command' from cons_data directly as the GeoApp type
      obj_type = cons_data.get('command', 'GeoUnknown') 
      dependencies = cons_data.get('dependency', [])
      extra = cons_data.get('extra', {})
      iter_val = extra.get('iter', 0)
      
      # Reconstruct object JSON
      obj_json = {
        'id': obj_id,
        'type': obj_type,  # Use command directly as type
        'dependencies': [gatom_to_id.get(dep) for dep in dependencies if dep in gatom_to_id],
        'visible': True,
      }
      
      # Get label from GAtom if available
      if hasattr(gatom, 'mv') and hasattr(gatom.mv, 'name'):
        obj_json['label'] = gatom.mv.name
      else:
        obj_json['label'] = obj_id
      
      # Add style if present
      style = extra.get('style', {})
      if style:
        obj_json['style'] = style
      
      # Add properties if present
      properties = {k: v for k, v in extra.items() if k not in ['iter', 'style']}
      if properties:
        obj_json['properties'] = properties

      # Handle multivector if available (requires Sygal-specific logic)
      # For now, we'll assume multivector is not directly reconstructed here
      # as it's derived from properties/dependencies in Flutter.
      
      # For GenSimpleObjectList types, we need to group them.
      # This decoder currently flattens them. A more sophisticated decoder
      # would re-aggregate list items under a parent GeoIntersection/GeoTangent.
      # For now, each list item is treated as a top-level object.
      
      result['objects'].append(obj_json)

    # Reconstruct constraints and proofs from appendage
    if dag.appendage.get('ScalarConstraints'):
      result['constraints'].extend(dag.appendage['ScalarConstraints'])
    
    if dag.appendage.get('ObjectConstraints'):
      result['constraints'].extend(dag.appendage['ObjectConstraints'])

    if dag.appendage.get('ScalarProof'):
      result['proofs'].extend(dag.appendage['ScalarProof'])
    
    if dag.appendage.get('ObjectProof'):
      result['proofs'].extend(dag.appendage['ObjectProof'])

    # Print JSON created if print flag is True
    if print_flag:
      print("=" * 80)
      print("GeoAppCodec.decoder: JSON CREATED")
      print("=" * 80)
      print(json.dumps(result, indent=2, ensure_ascii=True))
      print("=" * 80)
    
    # Return JSON (respect pretty flag for return value)
    if pretty:
      json_output = json.dumps(result, indent=2, ensure_ascii=True)
    else:
      json_output = json.dumps(result, separators=(",", ":"), ensure_ascii=True)

    return json_output
