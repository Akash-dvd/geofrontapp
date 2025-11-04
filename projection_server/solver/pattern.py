from libs.Sygal.GV import GV
from libs.Sygal.operators import (add,anticomm,comm,extp,inprdct,
lcntrct,mul,rcntrct)

class IRTOGB:
  @staticmethod
  def arecollinear(objlst,IR):
    if len(objlst)<3:
      raise
    lst = []
    for key in objlst:
      if key in IR.dag:
        lst.append(GV(key))
    
    if(len(lst)==3):
      lst.append(lst[0]._oo)
    arg1 = tuple(lst)
    

    sub1 = extp(*arg1)
    return sub1

  @staticmethod
  def areTangent(objlst,IR):
    raise

  @staticmethod
  def areConcyclic(objlst,IR):
    raise

  @staticmethod
  def areIncident(objlst,IR):
    raise

  @staticmethod
  def arePerpendicular(objlst,IR):
    raise

  
  @staticmethod
  def querytoGB(enquiry,IR):
    switcher = {
        'arecollinear': IRTOGB.arecollinear,
        'areTangent': IRTOGB.areTangent,
        'areConcyclic': IRTOGB.areConcyclic,
        'areIncident': IRTOGB.areIncident,
        'arePerpendicular': IRTOGB.arePerpendicular,
    }
    # Get the function from switcher dictionary
    func = switcher.get(enquiry['query'].lower(), lambda: "Invalid month")
    # Execute the function
    return func(enquiry['objects'],IR)
