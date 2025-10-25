from IGraph.codec.geogebra.geogebraCodec import geogebraCodec
from IGraph.SkeletonGraph import SkeletonGraph

from Sygal.GExpr import GExpr

from prob.prob import prob

from cirFramework.nptConf.nptConf import nptConf
from PattMat.pattmatt import pattmatt

from PattMat.propertymirror import propertyMirror

from solver.QGraph import QGraph

def worker(content,signal):
  

  igraph = geogebraCodec.encoder(content,signal)

  prob1 = prob(igraph)
  prob1.skeletonGraph = SkeletonGraph(igraph)

  prob1.IGraph.printElements()
  prob1.skeletonGraph.printElements()

  nptConf.IGraph.printGraph()
  nptConf.skeletonGraph.printElements()

  initial_map = {GExpr._oo:GExpr._oo}

  isomorphisms = pattmatt.find_subgraph_isomorphisms(prob1.skeletonGraph.SkeletonGraph, nptConf.skeletonGraph.SkeletonGraph,initial_map)

  qgraph = QGraph(igraph)

  # Print results
  print("Subgraph isomorphisms (pattern -> target):")
  
  for mapping in isomorphisms:
    print(mapping)
  

  match len(isomorphisms) :
    case 0:
      mess1 = "Subgraph Isomorphic returned Zero matching"
      mess2 = "Subgraph Isomorphic returned Zero matching"
      return defsol(prob1,mess1,mess2)

    case _:

      setOfSets = set()

      for mapping in isomorphisms:
        
        setOfSets.add(frozenset(mapping.values()))



      mess1 = "Matched subgraphs with unique mapping" + str(len(setOfSets))

      mess2 = "Matched subgraphs with infinity invariant" + str(len(isomorphisms))

      match len(setOfSets):
        case 1:
          pM = propertyMirror(isomorphisms[0])

          pM.embed(nptConf,prob1)


          prob1.PrintScalarMap() 

          prob1.PrintValueMap() 

          prob1.PrintObjectMap()

          prob1.PrintQuery()
          
          prob1.prob2ConfMap(isomorphisms[0])
          prob1.conf2ProbMap(isomorphisms[0])

          qgraph.prob2ConfMap(isomorphisms[0])
          qgraph.conf2ProbMap(isomorphisms[0])

          qgraph.CreateObjectQGraphs()

          if qgraph.isDependencyLimimed2Conf():

            mess1 = "SUCCEDED to limit the dependecy within the conf"

            mess2 = "SUCCEDED to limit the dependecy within the conf"

            qgraph.printObjectProofElements()          
            return defsol(prob1,mess1,mess2)
          
          else :
            mess1 = "Failed to limit the dependecy within the conf"

            mess2 = "Failed to limit the dependecy within the conf"

            return defsol(prob1,mess1,mess2)
          
        case _:
          return defsol(prob1,mess1,mess2)





      








def defsol(prob1,message1,message2):
    
  IGstr = (geogebraCodec.decoder(prob1.IGraph))
    # print(IGstr)

  sol = [{
    "description": message1,
    "references" : "",
    "xml" : IGstr
    },
    {
    "description": message2,
    "references" : "ref2",
    "xml" :IGstr
  }]

  return sol
