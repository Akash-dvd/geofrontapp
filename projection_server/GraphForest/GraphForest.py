from Sygal.GAtom import GExpr

class GraphForest():
  # def __init__(self, *args, **kwargs):
  #   super(IR, self).__init__(*args, **kwargs)
  #   self.__dict__ = self

  symlist = {}
  dag = {}

  def __init__(self,symlst,dag,appendage):
    self.symlist = symlst
    self.dag = dag
    self.appendage = appendage
  
  def printElements(self):
    print("PRIMARY SYMBOL LIST")
    print(self.symlist)
    print("RELATIONAL DICT")
    # print(self.dag)
    # print(self.dag[GExpr._oo])
    for key, value in self.dag.items():
      print(key,'->',value)
    print("APPENDAGE DICT")
    print("ScalarConstraints -> ",self.appendage["ScalarConstraints"])
    print("ScalarProof -> ",self.appendage["ScalarProof"])
    print("ObjectConstraints =>")
    for ele in self.appendage["ObjectConstraints"]:
      print(ele["name"]," -> ", ele["nestedArray"])
    print("ObjectProof =>")
    # print(self.appendage["ObjectProof"])
    for ele in self.appendage["ObjectProof"]:
      print(ele["name"]," -> ", ele["nestedArray"])

  def printSymbols(self):
    print("PRIMARY SYMBOL LIST")
    print(self.symlist)

  def printGraph(self):
    print("RELATIONAL DICT")
    for key, value in self.dag.items():
      print(key,'->',value)


  def printQuery(self):
    print("QUERY (APPENDAGE) DICT")
    print("ScalarConstraints -> ",self.appendage["ScalarConstraints"])
    print("ScalarProof -> ",self.appendage["ScalarProof"])
    print("ObjectProof =>")
    for ele in self.appendage["ObjectProof"]:
      print(ele["name"]," -> ", ele["nestedArray"])

  def getElement(self,ele):
    return self.dag[ele]

  def getDependency(self,ele):
    return self.dag[ele]["dependency"]

  def getType(self,ele):
    return self.dag[ele]["type"].lower()

  def getExtIter(self,ele):
    return self.dag[ele]["extra"]["iter"]
  
  def sygalEleList(self) -> "list": 
    return []
  
  def sygalEle(self,ele:"str")->"GAtom":
    return self.symlist[ele]
  
  def isIndependent(self,ele):
    return False if self.getDependency(ele) else True
  
  def getIndependentElements(self) ->list :
    return [v for v in self.symlist if self.isIndependent(v)]


    
  # def __init__(self, cons):
  #   self.construction = cons

  # def printElements(self):
  #   for key, value in self.construction.items():
  #     print(key,'->',value)

  # def getElement(self,ele):
  #   return self.construction[ele]

  # def getDependency(self,ele):
  #   return self.construction[ele]["dependency"]

  # def getType(self,ele):
  #   return self.construction[ele]["type"].lower()

  # def getExtIter(self,ele):
  #   return self.construction[ele]["extra"]["iter"]
  
  # def sygalEleList(self) -> "list": 
  #   return []
  
  # def sygalEle(self,)

