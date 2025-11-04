from __future__ import annotations
from collections import OrderedDict
from typing import Any
from GraphForest.GraphForest import GraphForest


class QGraph:
  def __init__(self,graph_forest) -> None:
    """Initialize QGraph and add it as attributes to the GraphForest.
    
    This modifies the GraphForest object in place by adding 'qgraph', 'p2cMap', 'c2pMap',
    'ScalarProof', and 'ObjectProof' attributes, and returns the modified GraphForest object.
    """
    # Store references to GraphForest data
    graph_forest.qgraph = {"ScalarQGraphs":[],"ObjectQGraphs":[]}
    graph_forest.p2cMap = []
    graph_forest.c2pMap = []
    graph_forest.ScalarProof = graph_forest.appendage["ScalarProof"]
    graph_forest.ObjectProof = graph_forest.appendage["ObjectProof"]
    
    # Store reference to graph_forest for methods
    self.graph_forest = graph_forest
  
  def __call__(self, graph_forest) -> "GraphForest":
    """Make QGraph callable - modifies GraphForest and returns it.
    
    This allows QGraph to be used as a function that modifies GraphForest in place.
    """
    graph_forest.qgraph = {"ScalarQGraphs":[],"ObjectQGraphs":[]}
    graph_forest.p2cMap = []
    graph_forest.c2pMap = []
    graph_forest.ScalarProof = graph_forest.appendage["ScalarProof"]
    graph_forest.ObjectProof = graph_forest.appendage["ObjectProof"]
    self.graph_forest = graph_forest
    return graph_forest



  def CreateQGraph(self):
    """Create QGraph structure and populate graph_forest.qgraph."""
    if hasattr(self, 'graph_forest'):
      graph_forest = self.graph_forest
    else:
      # Fallback for old usage pattern
      graph_forest = self
    self.CreateScalarQGraphs(graph_forest)
    self.CreateObjectQGraphs(graph_forest)
  
  @staticmethod
  def create_qgraph_on_dag(current_output: "GraphForest", *array_args: Any, **dict_kwargs: Any) -> "GraphForest":
    """Static method to create QGraph on GraphForest and return it.
    
    This method modifies GraphForest in place and returns it.
    
    Args:
      current_output: The GraphForest object to process
      *array_args: Additional positional arguments (unused)
      **dict_kwargs: Keyword arguments (may include 'print')
    """
    graph_forest = current_output
    print_flag = dict_kwargs.get("print", False)
    
    # Initialize QGraph attributes on GraphForest
    graph_forest.qgraph = {"ScalarQGraphs":[],"ObjectQGraphs":[]}
    graph_forest.p2cMap = []
    graph_forest.c2pMap = []
    graph_forest.ScalarProof = graph_forest.appendage["ScalarProof"]
    graph_forest.ObjectProof = graph_forest.appendage["ObjectProof"]
    
    # Create QGraphs - use instance methods via a temporary instance
    qgraph_instance = QGraph.__new__(QGraph)  # Create instance without calling __init__
    qgraph_instance.graph_forest = graph_forest
    qgraph_instance.CreateScalarQGraphs(graph_forest)
    qgraph_instance.CreateObjectQGraphs(graph_forest)
    
    # Print QGraph if print flag is True
    if print_flag:
      print("=" * 80)
      print("QGraph.create_qgraph_on_dag: QGRAPH CREATED")
      print("=" * 80)
      import json
      print("QGraph:")
      print(json.dumps(graph_forest.qgraph, indent=2, ensure_ascii=True, default=str))
      print(f"p2cMap length: {len(graph_forest.p2cMap)}")
      print(f"c2pMap length: {len(graph_forest.c2pMap)}")
      print(f"ScalarProof length: {len(graph_forest.ScalarProof)}")
      print(f"ObjectProof length: {len(graph_forest.ObjectProof)}")
      print("=" * 80)
    
    return graph_forest

  def CreateObjectQGraphs(self, graph_forest=None):
    """Create object QGraphs and add to graph_forest.qgraph.
    
    Each ObjectQGraph is an OrderedDict to ensure topological ordering (parents before children).
    """
    if graph_forest is None:
      graph_forest = getattr(self, 'graph_forest', self)
    
    # graph_forest.qgraph["ObjectQGraphs"] = [{}]
    for obj in graph_forest.ObjectProof:
      dct = OrderedDict()  # Use OrderedDict for topological ordering
      dct["assertion"] = {'type': 'assertion', 'dependency': [graph_forest.symlist[ele] for ele in obj['nestedArray']], 'command': obj["name"], 'extra': {'iter': 0}}
      for dep in obj['nestedArray']:
        dct.update(self.get_subgraph_recursive(graph_forest.dag, graph_forest.symlist[dep], graph_forest))
      # Topologically sort the subgraph to ensure parents before children
      dct = QGraph._topological_sort_subgraph(dct)
      graph_forest.qgraph["ObjectQGraphs"].append(dct)
    


  def get_subgraph_recursive(self,graph, start_node, graph_forest=None, subgraph=None, visited=None):
    """Get subgraph recursively, supporting both old and new patterns.
    
    Returns OrderedDict to maintain topological ordering.
    """
    if graph_forest is None:
      graph_forest = getattr(self, 'graph_forest', self)
    
    # Initialize the subgraph OrderedDict and visited set on the first call
    if subgraph is None:
      subgraph = OrderedDict()
    if visited is None:
      visited = set()
    
    # Add the start node to visited set
    visited.add(start_node)
    
    # Add the current node and its dependencies to the subgraph
    subgraph[start_node] = dict(graph[start_node])
    # MULTIPLE MAPS NOT SUPPORTED
    if graph_forest.p2cMap and len(graph_forest.p2cMap) > 0 and graph_forest.p2cMap[0].get(start_node ,False):
      subgraph[start_node]['dependency'] = []
    else:
      # Recursively visit each dependency (parents first)
      # Note: We process dependencies recursively, so they get added before the current node
      # This naturally maintains topological order if we process parents first
      dependencies = graph[start_node].get('dependency', [])
      for dep in dependencies:
        if dep not in visited:
          self.get_subgraph_recursive(graph, dep, graph_forest, subgraph, visited)
    
    return subgraph
  
  @staticmethod
  def _topological_sort_subgraph(subgraph: OrderedDict) -> OrderedDict:
    """Topologically sort a subgraph OrderedDict to ensure parents before children.
    
    Args:
      subgraph: OrderedDict mapping GAtom -> construction data (may include "assertion" key)
      
    Returns:
      OrderedDict with nodes in topological order
    """
    # Separate assertion from graph nodes
    assertion = None
    if "assertion" in subgraph:
      assertion = subgraph["assertion"]
    
    # Build graph for topological sort (only GAtom nodes, not assertion)
    in_degree = {}
    graph = {}
    node_list = []
    
    # Initialize - only process GAtom nodes (skip "assertion")
    for node in subgraph.keys():
      if node == "assertion":
        continue
      node_list.append(node)
      in_degree[node] = 0
      graph[node] = []
    
    # Build graph and calculate in-degrees
    for node in node_list:
      data = subgraph[node]
      dependencies = data.get('dependency', [])
      for dep in dependencies:
        if dep in graph:  # Only if dependency is in subgraph
          graph[dep].append(node)
          in_degree[node] += 1
    
    # Kahn's algorithm for topological sort
    queue = [node for node, degree in in_degree.items() if degree == 0]
    sorted_nodes = []
    
    while queue:
      node = queue.pop(0)
      sorted_nodes.append(node)
      
      for dependent in graph[node]:
        in_degree[dependent] -= 1
        if in_degree[dependent] == 0:
          queue.append(dependent)
    
    # Build ordered dict in topological order
    ordered_subgraph = OrderedDict()
    
    # Add assertion first if it exists
    if assertion is not None:
      ordered_subgraph["assertion"] = assertion
    
    # Add nodes in topological order
    for node in sorted_nodes:
      ordered_subgraph[node] = subgraph[node]
    
    # Include any nodes that weren't in the sort (safety)
    for node in node_list:
      if node not in ordered_subgraph:
        ordered_subgraph[node] = subgraph[node]
    
    return ordered_subgraph


  def getObjectProofDependency(self,idx,ele, graph_forest=None):
    """Get object proof dependency, supporting both old and new patterns."""
    if graph_forest is None:
      graph_forest = getattr(self, 'graph_forest', self)
    return graph_forest.qgraph["ObjectQGraphs"][idx][ele]["dependency"]

  def CreateScalarQGraphs(self, graph_forest=None):
    """Create scalar QGraphs and add to graph_forest.qgraph."""
    if graph_forest is None:
      graph_forest = getattr(self, 'graph_forest', self)
    graph_forest.qgraph["ScalarQGraphs"] = [{}]

  def printObjectProofElements(self, graph_forest=None):
    """Print object proof elements, supporting both old and new patterns."""
    if graph_forest is None:
      graph_forest = getattr(self, 'graph_forest', self)
    print("Q DICT")

    for dct in graph_forest.qgraph["ObjectQGraphs"]:
      for key, value in dct.items():
        print(key,'->',value)

  def conf2ProbMap(self,isomorphism, graph_forest=None) :
    """Add conf2ProbMap, supporting both old and new patterns."""
    if graph_forest is None:
      graph_forest = getattr(self, 'graph_forest', self)
    graph_forest.c2pMap.append(isomorphism)

  def Printconf2ProbMap(self, graph_forest=None) :
    """Print conf2ProbMap, supporting both old and new patterns."""
    if graph_forest is None:
      graph_forest = getattr(self, 'graph_forest', self)
    print(graph_forest.c2pMap)

  def prob2ConfMap(self,isomorphism, graph_forest=None) :
    """Add prob2ProbMap, supporting both old and new patterns."""
    if graph_forest is None:
      graph_forest = getattr(self, 'graph_forest', self)
    graph_forest.p2cMap.append({value: key for key, value in isomorphism.items()})

  def Printprob2ConfMap(self, graph_forest=None) :
    """Print prob2ConfMap, supporting both old and new patterns."""
    if graph_forest is None:
      graph_forest = getattr(self, 'graph_forest', self)
    print(graph_forest.p2cMap)
  
  def isDependencyLimimed2Conf(self, graph_forest=None):
    """Check dependency limit, supporting both old and new patterns."""
    if graph_forest is None:
      graph_forest = getattr(self, 'graph_forest', self)
    DependLim2Conf = True

    for idx,dct in enumerate(graph_forest.qgraph["ObjectQGraphs"]):
      for key, value in dct.items():
        # MULTIPLE MAPS NOT SUPPORTED
        if not value["dependency"] and graph_forest.p2cMap and len(graph_forest.p2cMap) > 0 and not graph_forest.p2cMap[0].get(key ,False):
          DependLim2Conf = False
    

    return DependLim2Conf




