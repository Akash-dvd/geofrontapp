from functools import reduce
from collections import OrderedDict
from typing import Any
from GraphForest.GraphForest import GraphForest
from Sygal.GAtom import GExpr


class ListDict(OrderedDict):
  def __setitem__(self, key, value):
    if key not in self:
      super().__setitem__(key, [])
    if isinstance(value, list):
      for item in value:
        if item not in self[key]:
          self[key].append(item)
    else:
      if value not in self[key]:
        self[key].append(value)
    
  def __getitem__(self, key):
    if key not in self:
      super().__setitem__(key, [])
    return super().__getitem__(key)

class DCG() :

  def __init__(self,graph_forest:GraphForest):
    """Initialize DCG and add it as an attribute to the GraphForest.
    
    This modifies the GraphForest object in place by adding a 'dcg' attribute.
    """
    graph_forest.dcg = self.DAGParser(graph_forest)
  
  def __call__(self, graph_forest: GraphForest) -> GraphForest:
    """Make DCG callable - modifies GraphForest and returns it.
    
    This allows DCG to be used as a function that modifies GraphForest in place.
    """
    graph_forest.dcg = self.DAGParser(graph_forest)
    return graph_forest


  def DAGParser(self,graph_forest:GraphForest):

    DCGraph = ListDict()
    for key, value in graph_forest.dag.items():
      match graph_forest.getType(key) :

        case "point":
        # p1 = [a1,a2,a3] =>
        # p1 = [a1,a2,a3]
        # a1 = [p1],a2 = [p1],a3 = [p1],
          DCGraph[key] = key
          # p1 = [a1,a2,a3]
          DCGraph[key] = graph_forest.getDependency(key)
          # a1 = [p1],a2 = [p1],a3 = [p1],
          for ele in graph_forest.getDependency(key):
            DCGraph[ele] = key 

        
        case "circle":
        # c1 = [p1,p2,p3] =>
        # c1 = [a1,a2,a3]
        # p1 = [c1],p2 = [c1],p3 = [c1],
          if len(graph_forest.getDependency(key)) == 3:
            bool_array = [graph_forest.getType(ele) == "point" for ele in graph_forest.getDependency(key)]
            if reduce(lambda x, y: x and y, bool_array) :
              # c1 = [a1,a2,a3]
              DCGraph[key] = graph_forest.getDependency(key)
              # p1 = [c1],p2 = [c1],p3 = [c1],
              for ele in graph_forest.getDependency(key):
                DCGraph[ele] = key 

          elif len(graph_forest.getDependency(key)) == 2:
            if graph_forest.getType(graph_forest.getDependency(key)[1]) == "point":
              DCGraph[key] = graph_forest.getDependency(key)[1]
              DCGraph[graph_forest.getDependency(key)[1]] = key

        case "line" :
          # l1 = [p1,p2] =>
          # l1 = [p1,p2]
          # p1 = [l1] ,p2 = [l1]
          if len(graph_forest.getDependency(key)) == 2:
            bool_array = [graph_forest.getType(ele) == "point" for ele in graph_forest.getDependency(key)]
            if reduce(lambda x, y: x and y, bool_array) :
              # l1 = [p1,p2]
              DCGraph[key] = graph_forest.getDependency(key)
              # l1 = [p1,p2,_oo]
              DCGraph[key] = GExpr._oo
              # _oo = [_oo,l1]
              DCGraph[GExpr._oo] = key
              # p1 = [l1] ,p2 = [l1]
              for ele in graph_forest.getDependency(key):
                DCGraph[ele] = key 

    return DCGraph
  

  def printElements(self):
    print("DCG DICT")
    for key, value in self.DCG.items():
      print(key,'->',value)


def create_dcg(current_output: GraphForest, *array_args: Any, **dict_kwargs: Any) -> GraphForest:
  """Function to create DCG and add it as an attribute to GraphForest.
  
  This is the preferred way to use DCG in the chain - it modifies GraphForest
  in place and returns it.
  
  Args:
    current_output: The DAG object to process
    *array_args: Additional positional arguments (unused)
    **dict_kwargs: Keyword arguments (may include 'print')
  """
  graph_forest = current_output
  print_flag = dict_kwargs.get("print", False)
  
  dcg_instance = DCG.__new__(DCG)  # Create instance without calling __init__
  graph_forest.dcg = dcg_instance.DAGParser(graph_forest)
  
  # Print DCG if print flag is True
  if print_flag:
    print("=" * 80)
    print("create_dcg: DCG CREATED")
    print("=" * 80)
    # Set DCG on the instance so printElements can access it
    dcg_instance.DCG = graph_forest.dcg
    dcg_instance.printElements()
    print("=" * 80)
  
  return graph_forest

