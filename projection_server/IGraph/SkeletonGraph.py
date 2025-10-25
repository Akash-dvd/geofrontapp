from functools import reduce
from IGraph.IGraph import IGraph
from Sygal.GAtom import GExpr


class ListDict(dict):
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

class SkeletonGraph() :

  def __init__(self,igraph:IGraph):
    self.SkeletonGraph = self.IGraphParser(igraph)

  def IGraphParser(self,igraph:IGraph):

    SKGraph = ListDict()
    for key, value in igraph.construction.items():
      match igraph.getType(key) :

        case "point":
        # p1 = [a1,a2,a3] =>
        # p1 = [a1,a2,a3]
        # a1 = [p1],a2 = [p1],a3 = [p1],
          SKGraph[key] = key
          # p1 = [a1,a2,a3]
          SKGraph[key] = igraph.getDependency(key)
          # a1 = [p1],a2 = [p1],a3 = [p1],
          for ele in igraph.getDependency(key):
            SKGraph[ele] = key 

        
        case "circle":
        # c1 = [p1,p2,p3] =>
        # c1 = [a1,a2,a3]
        # p1 = [c1],p2 = [c1],p3 = [c1],
          if len(igraph.getDependency(key)) == 3:
            bool_array = [igraph.getType(ele) == "point" for ele in igraph.getDependency(key)]
            if reduce(lambda x, y: x and y, bool_array) :
              # c1 = [a1,a2,a3]
              SKGraph[key] = igraph.getDependency(key)
              # p1 = [c1],p2 = [c1],p3 = [c1],
              for ele in igraph.getDependency(key):
                SKGraph[ele] = key 

          elif len(igraph.getDependency(key)) == 2:
            if igraph.getType(igraph.getDependency(key)[1]) == "point":
              SKGraph[key] = igraph.getDependency(key)[1]
              SKGraph[igraph.getDependency(key)[1]] = key

        case "line" :
          # l1 = [p1,p2] =>
          # l1 = [p1,p2]
          # p1 = [l1] ,p2 = [l1]
          if len(igraph.getDependency(key)) == 2:
            bool_array = [igraph.getType(ele) == "point" for ele in igraph.getDependency(key)]
            if reduce(lambda x, y: x and y, bool_array) :
              # l1 = [p1,p2]
              SKGraph[key] = igraph.getDependency(key)
              # l1 = [p1,p2,_oo]
              SKGraph[key] = GExpr._oo
              # _oo = [_oo,l1]
              SKGraph[GExpr._oo] = key
              # p1 = [l1] ,p2 = [l1]
              for ele in igraph.getDependency(key):
                SKGraph[ele] = key 

    return SKGraph
  

  def printElements(self):
    print("SkeletonGraph DICT")
    for key, value in self.SkeletonGraph.items():
      print(key,'->',value)

