import os
from worker.worker import worker
import json

# path1 = os.path.abspath("xmls/monge.xml")

path1 = os.path.abspath("xmls/1.xml")
# path2 = os.path.abspath("xmls/geogebra.xml")
# path1 = os.path.abspath("./solver/xmls/monge.xml")


obj = {
  "xml":path1,
  "appendage": 
"{\"ScalarConstraints\":[],\"ScalarProof\":[],\"ObjectProof\":[{\"name\":\"areIncident\",\"nestedArray\":[\"c\",\"D\"]}]}"

}
dmp = json.dumps(obj)

worker(dmp,False)
