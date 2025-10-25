from dicttoxml import dicttoxml
from xml.dom.minidom import parseString
def test():

  my_dict={'element':
            {
              '@attrs':{'type': 'point', 'label': 'B'}, 
              'coords':{'@attrs': {'x': '-1.56', 'y': '1.56', 'z': '1'}}, 
              'show':{'@attrs': {'object': 'true', 'label': 'true'}}
            }
          }

  # my_dict=        {'element': 
          #   {
          #     '@attrs':{'type': 'point', 'label': 'B'}
          #   }, 
          #     'coords':{'@attrs': {'x': '-1.56', 'y': '1.56', 'z': '1'}}, 
          #     'show':{'@attrs': {'object': 'true', 'label': 'true'}}
          # }
  # my_dict = {
  #   "geogebra": [
  #     {"element":{
  #     "@attrs": {
  #       "format": "5.0",
  #       "version": "5.0.600.0",
  #       "app":"geometry",
  #       "platform":"w",
  #       "xsi:noNamespaceSchemaLocation":"http://www.geogebra.org/apps/xsd/ggb.xsd",
  #       "xmlns":"",
  #       "xmlns:xsi":"http://www.w3.org/2001/XMLSchema-instance"
  #     },
  #     "construction":""
  #   }},
  #   {"element":{
  #     "@attrs": {
  #       "format": "5.0",
  #       "version": "5.0.600.0",
  #       "app":"geometry",
  #       "platform":"w",
  #       "xsi:noNamespaceSchemaLocation":"http://www.geogebra.org/apps/xsd/ggb.xsd",
  #       "xmlns":"",
  #       "xmlns:xsi":"http://www.w3.org/2001/XMLSchema-instance"
  #     },
  #     "construction":""
  #   }}
  #   ]
  # }

  xml = dicttoxml(my_dict,attr_type=False,root=False)
  # xml = dicttoxml(my_dict,root=False)
  dom = parseString(xml)
  print(dom.toprettyxml())

test()