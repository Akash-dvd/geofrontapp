from libs.Sygal.GV import GV
from libs.Sygal.operators import (add,anticomm,comm,extp,inprdct,
lcntrct,mul,rcntrct)

class invocation:

  @staticmethod
  def point(ele,IR):
    raise

  @staticmethod
  def circle(ele,IR):
    raise

  @staticmethod
  def intersect(ele,IR):

    Dnlst = IR.getDependency( ele )
    print(Dnlst)

    #####
    # iNPUT AND OUTPUT ALWAYS IN TERMS OF SYMBOLS NOT DICT EVER
    ####
    if (not len(Dnlst)==2):
      return ele
    
    if(IR.getType( Dnlst[0] ) == 'tangent' and \
      IR.getType( Dnlst[1] ) == 'tangent'):
      if(IR.getDependency( Dnlst[0] ) == \
      IR.getDependency( Dnlst[1]) ):
        if(len( IR.getDependency( Dnlst[0] )) ==2 ):
          if(( IR.getExtIter( Dnlst[0] ) + \
            IR.getExtIter( Dnlst[1] ) ) ==1):
            o1 = GV(IR.getDependency( Dnlst[0] )[0])
            o2 = GV(IR.getDependency( Dnlst[0] )[1])
            return GV._rx<(o1^o2)

    # elif():
    
    # elif():
    
    # else:
      
    ###


  @staticmethod
  def querySubs(qGB,IR):
  
    if(not qGB.func ==extp):
      return qGB
    print('nqGB')
    nqGB = qGB
    args = qGB.args
    switcher = {
      'intersect': invocation.intersect,
      'circle': invocation.circle,
      'point': invocation.point,
    }
    for arg in args:
      if arg.name in IR.construction:
        func = switcher[IR.getType(arg.name)]
        nqGB = nqGB.sSubs((arg,func(arg.name,IR)))
    
    return nqGB

# func = switcher.get(IR.getType(arg.name), arg)