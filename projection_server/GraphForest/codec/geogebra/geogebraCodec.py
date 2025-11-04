# Pass Elements and destroy stateMachine  
# Fill dict to make DAG sorted
import xml.etree.ElementTree as ET
import json
# import xmltodict
from GraphForest.codec.geogebra.dicttoxml import dicttoxml
from GraphForest.GraphForest import GraphForest
from xml.dom.minidom import parseString


from sympy import (
  Basic,diff, Rational, Symbol, S, Mul, Add, Expr,Pow,
  expand, simplify, eye, trigsimp,cos,sin,subsets,
  symbols, sqrt, Matrix, SympifyError, sympify
)

from functools import reduce
from collections.abc import Iterable
from collections import defaultdict

from Sygal.utils.util import *

from Sygal.strategies.rl import (rm_id, glom, flatten, unpack, sort, distribute,subs, rebuild)
from Sygal.strategies.core import (null_safe, exhaust, memoize, condition,chain, tryit, do_one, debug, switch, minimize)
from Sygal.strategies.tools import subs, typed ,canon
from Sygal.strategies.traverse import (top_down, bottom_up, bxsall, top_down_once,bottom_up_once,spe_traverse,gen_traverse)
from Sygal.strategies.tree import treeapply, greedy, allresults, brute
from Sygal.strategies.iters import higher_iter,canon_iter ,expand_iter,bx_typed

from Sygal.GAtom import GAtom,GExpr,Box

from Sygal.operators.assop.gadd import gadd
from Sygal.operators.assop.gextp import gextp
from Sygal.operators.assop.gmul import gmul

from Sygal.operators.binop.ganticomm import ganticomm
from Sygal.operators.binop.gcomm import gcomm
from Sygal.operators.binop.sclrprdct import sclrprdct
from Sygal.operators.binop.grcntrct import grcntrct
from Sygal.operators.binop.glcntrct import glcntrct
from Sygal.operators.binop.sclrprdct import sclrprdct


from Sygal.operators.binop.outermorphic.isomorphic.inversion import inversion
from Sygal.operators.binop.outermorphic.projection import projection
from Sygal.operators.binop.outermorphic.rejection import rejection

from Sygal.operators.binop.outermorphic.outermorphic import outermorphic


from Sygal.operators.binop.outermorphic.isomorphic.isomorphic import isomorphic

from Sygal.imports.import_util2 import *

# ONe bug 
# Handling this kind if case
# continue
# <command name="Intersect">
# 	<input a0="-0.8284531815830312x² + 4.201551991722711x y - 1.4136575271598555y² - 5.610185204345576x + 6.537659596482152y = 5.708744355923436" a1="c"/>
# 	<output a0="" a1="" a2="" a3=""/>
# </command>

class geogebraCodec:


  # def xmlencoder(self):
  #   with open(self.path) as fd:
  #     doc = xmltodict.parse(fd.read())
  #   print(doc)

  @staticmethod
  def encoder(content,signal) ->GraphForest:
    dct = json.loads(content)

    obj = dct["xml"]
    appendage = json.loads(dct["appendage"])

    if(signal):
      # from local file name
      root = ET.fromstring(obj)
    else :
      # from browser
      tree = ET.parse(obj)
      root = tree.getroot()
    
    symlst = {}
    symlst["_oo"] = GExpr._oo
    construction = root.find('construction') 

    # puzzle = self.Puzzle


    # Symlist
    for child in construction:
      if child.tag == 'element':
        match child.attrib['type'].lower() :

          case 'point':
            mtDt = {GExpr.I41:1}
            rlDt = relDt()
            rlDt.update({GExpr._oo:S(-1),"self":S(0)})
            symlst[child.attrib['label']] = GAtom(child.attrib['label'],mtDt,rlDt)

          case "line":
            mtDt = {GExpr.I41:1}
            rlDt = relDt()
            rlDt.update({GExpr._oo:S(0),"self":S(1)})
            symlst[child.attrib['label']] = GAtom(child.attrib['label'],mtDt,rlDt)

          case ("circle"| "conic"):
            # this case needs more attention
            mtDt = {GExpr.I41:1}
            rlDt = relDt()
            rlDt.update({GExpr._oo:S(-1),"self":S(1)})
            symlst[child.attrib['label']] = GAtom(child.attrib['label'],mtDt,rlDt)
        
    IrElementsDict = {}
    IrElementsDict[GExpr._oo] = {'type': 'point', 'dependency': [], 'command': '','extra': {'iter': 0}}

    for child in construction:
      match child.tag.lower() :
        case 'element':
          if symlst[child.attrib['label']] in IrElementsDict:
            pass 
            # Only independent elements are put here
          else :
            
            IrElementsDict[symlst[child.attrib['label']]]={'type':child.attrib['type'],'dependency':[],'command':'',
              'extra':{
              'coords':child.find('coords').attrib,
              'show':child.find('show').attrib
            }}
        case 'command':
          outputs = list(child.find('output').attrib.values())
          # To fix the <output a0="" a1="" a2="" a3=""/> issue
          if not reduce(lambda a,b:bool(a) and bool(b),outputs) :
            continue
          inputsObj =[symlst[ele] for ele in list(child.find('input').attrib.values())]



          name = child.attrib['name']
          # Intersect not fully supported
          nametype = "point" if name.lower() == "intersect" else name

          for key,output in enumerate(outputs):
            if output:
              IrElementsDict[symlst[output]]={'type':nametype,'dependency':inputsObj,'command':name,
                  'extra':{'iter':key}}
                  # The nth output is key number
    
    return GraphForest(symlst,IrElementsDict,appendage)

    # print(xml.decode("utf-8"))
    # xmlstr = ET.tostring(construction, encoding='utf8', method='xml')
    # print(xmlstr.decode("utf-8"))
  @staticmethod
  def decoder(IGdict) -> "str":
    Basic_dict = {
    "geogebra": {
      "@attrs": {
        "format": "5.0",
        "version": "5.0.600.0",
        "app":"geometry",
        "platform":"w",
        "xsi:noNamespaceSchemaLocation":"http://www.geogebra.org/apps/xsd/ggb.xsd",
        "xmlns":"",
        "xmlns:xsi":"http://www.w3.org/2001/XMLSchema-instance"
        },
        "construction":""
      }
    }

    IGdict.dag.pop(GExpr._oo, None)
    # remove {'element': {'@attrs': {'type': 'point', 'label': '_oo'}, 'iter': {'@attrs': 0}}}
    
    subEleCmd = ['input','output']
    lst = []
    for key, value in IGdict.dag.items():
      if(not value['dependency']):
        ele = {}
        ele["element"] = {
        "@attrs": {
          "type": value["type"],
          "label":key.mv.name
          },
        }
        xtr = {}
        for key in value['extra']:
          xtr[key]={"@attrs": value['extra'][key]}
        ele["element"].update(xtr)
        lst.append(ele)
      
      # tangent has 4 outputs
      # only 0 can be used for dependency injection
      # other elements can be used for output
      elif ( value['dependency'] and not(value['extra']['iter'])) :
        outlst = []
        cmd ={}
        for key1, value1 in IGdict.dag.items():
          if((value['dependency'] == value1['dependency']) and\
            (value['command'] == value1['command'])):
            outlst.append(key1.mv.name)
        # print('{}-{}'.format(value['dependency'],outlst))
        cmd["command"] = {
        "@attrs": {
          "name": value["command"]
        }}
        xtr = {}
        strarg = 'a'
        dpdlst = [ele1.mv.name for ele1 in value['dependency']]
        atrlst = [dpdlst,outlst]
        for index1,value1 in enumerate(atrlst):
          xtr1 = {}
          # a0,a1,a2 ...
          for index2,value2 in enumerate(value1):
            xtr1[(strarg+str(index2))]=value2
          xtr[subEleCmd[index1]]={"@attrs":xtr1}
        cmd["command"].update(xtr)
        lst.append(cmd)
      
      
      # mapp = defaultdict(list) 
      # for x, y in lst1: 
      #   mapp[x].append(y) 
      # lst2 = [(x, *y) for x, y in mapp.items()] 
      # print(lst2) 
      # [(_rx, 1, 2, 4, 6), (_oo, 3, 5)]


    
      # print(ele)
    # print(lst)
    Basic_dict['geogebra']['construction']=lst
    xml = dicttoxml(Basic_dict,attr_type=False,root=False)
    # print(xml)
    dom = parseString(xml)
    
    return dom.toprettyxml()



# test()
  # Dependency Injection in Elements
  # Should dependencies be set to avoid repetitive dependencies
    # for child in construction:
    #   if child.tag == 'command':
    #     output = list(child.find('output').attrib.values())[0]
    #     inputs = list(child.find('input').attrib.values())
    #     name = child.attrib['name']
    #     for element in elements:
    #       if output == element:
    #         elements[output]['dependency'].extend(inputs)
    #         elements[output]['command'] = name
    #         continue


  # Creating puzzle dict
    # for child1 in root.find('construction'):
    #   if child1.tag == 'command' and child1.attrib['name'] == 'Prove':
    #     input = list(child1.find('input').attrib.values())[0]
    #     for child2 in root.find('construction'):
    #       if child2.tag == 'command':
    #         output = list(child2.find('output').attrib.values())[0]
    #         if output == input:
    #           puzzle['command']=child2.attrib['name']
    #           puzzle['dependency']=list(child2.find('input').attrib.values())
    #           puzzle['name']='Prove'
    #           return