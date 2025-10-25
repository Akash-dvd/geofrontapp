class QGraph:
  def __init__(self,igraph) -> None:
    
    self.symlist = igraph.symlist
    self.construction = igraph.construction 
    
    self.ScalarProof = igraph.appendage["ScalarProof"]
    
    self.ObjectProof = igraph.appendage["ObjectProof"]
    self.Qgraph = {"ScalarQGraphs":[],"ObjectQGraphs":[]}

    self.p2cMap=[]

    self.c2pMap=[]



  def CreateQGraph(self):
    self.CreateScalarQGraphs()
    self.CreateObjectQGraphs()

  def CreateObjectQGraphs(self):

    # self.Qgraph["ObjectQGraphs"] = [{}]
    for obj in self.ObjectProof:
      dct = dict({})
      dct["assertion"] = {'type': 'assertion', 'dependency': [self.symlist[ele] for ele in obj['nestedArray']], 'command': obj["name"], 'extra': {'iter': 0}}
      for dep in obj['nestedArray']:

        dct.update(self.get_subgraph_recursive(self.construction,self.symlist[dep]))
      self.Qgraph["ObjectQGraphs"].append(dct)
    


  def get_subgraph_recursive(self,graph, start_node, subgraph=None, visited=None):
    # Initialize the subgraph dictionary and visited set on the first call
    if subgraph is None:
      subgraph = {}
    if visited is None:
      visited = set()
    
    # Add the start node to visited set
    visited.add(start_node)
    
    # Add the current node and its dependencies to the subgraph
    subgraph[start_node] = dict(graph[start_node])
    # MULTIPLE MAPS NOT SUPPORTED
    if self.p2cMap[0].get(start_node ,False):
      subgraph[start_node]['dependency'] = []
    else :
    
    # Recursively visit each dependency
      dependencies = graph[start_node].get('dependency', [])
      for dep in dependencies:
        if dep not in visited:
          self.get_subgraph_recursive(graph, dep, subgraph, visited)
    
    return subgraph


  def getObjectProofDependency(self,idx,ele):
    return self.Qgraph["ObjectQGraphs"][idx][ele]["dependency"]

  def CreateScalarQGraphs(self):
    self.Qgraph["ScalarQGraphs"] = [{}]

  def printObjectProofElements(self):
    print("Q DICT")

    for dct in self.Qgraph["ObjectQGraphs"]:
      for key, value in dct.items():
        print(key,'->',value)

  def conf2ProbMap(self,isomorphism) :
    self.c2pMap.append(isomorphism)

  def Printconf2ProbMap(self) :
    print(self.c2pMap)

  def prob2ConfMap(self,isomorphism) :
    self.p2cMap.append({value: key for key, value in isomorphism.items()})

  def Printprob2ConfMap(self) :
    print(self.p2cMap)
  
  def isDependencyLimimed2Conf(self):
    DependLim2Conf = True

    for idx,dct in enumerate(self.Qgraph["ObjectQGraphs"]):
      for key, value in dct.items():
        # MULTIPLE MAPS NOT SUPPORTED
        if not value["dependency"] and not self.p2cMap[0].get(key ,False):
          DependLim2Conf = False
    

    return DependLim2Conf




