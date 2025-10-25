# from .models import Post
from ariadne import convert_kwargs_to_snake_case

from worker.worker import worker


@convert_kwargs_to_snake_case
def getSolution_resolver(obj, info, content):
  try:
 
    result = worker(content,True)
    # igraph = geogebraCodec.encoder(content,True)
    # print("@@@@@@@@@@@@@@@@@@@@@@")
    # igraph.printElements()

    # IGstr = (geogebraCodec.decoder(igraph))
    # print(IGstr)
    # print("######################")
    # sol = [{
    #   "description": "DESCRIPTION1",
    #   "references" : "ref1",
    #   "xml" : IGstr
    # },
    # {
    #   "description": "DESCRIPTION2",
    #   "references" : "ref2",
    #   "xml" :IGstr
    # }]
    
    # print("############")

    payload = {
      "success": True,
      "solution": result
    }

  except AttributeError:  # todo not found
    payload = {
      "success": False,
      "errors": ["Solution not done"]
    }
  return payload

# @convert_kwargs_to_snake_case
# def getPost_resolver(obj, info, id):
#   try:
#       post = Post.query.get(id)
#       payload = {
#         "success": True,
#         "post": post.to_dict()
#       }
#   except AttributeError:  # todo not found
#       payload = {
#         "success": False,
#         "errors": ["Post item matching {id} not found"]
#       }
#   return payload


# def listPosts_resolver(obj, info):
#   try:
#     posts = [post.to_dict() for post in Post.query.all()]
#     print(posts)
#     payload = {
#       "success": True,
#       "posts": posts
#     }
#   except Exception as error:
#     payload = {
#       "success": False,
#       "errors": [str(error)]
#     }
#   return payload