FROM  ubuntu:latest

RUN apt-get update && apt-get install -y \
        software-properties-common
#RUN apt-get autoremove --purge
RUN apt-get remove python3.10 -y
#RUN apt-get autoremove --purge -y

RUN apt-get update && apt-get install -y \
        software-properties-common

RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update && apt-get install -y \
    python3.7 \
    python3-pip

#RUN python3.7 -m pip install pip
RUN python3 -m pip install pip
RUN pip install sympy galgebra dicttoxml pytest mypy zmq untangle xmltodict gevent tornado pampy


# RUN apt-get update && apt-get install -y \
#     python3-distutils \
#     python3-setuptools

# TAG pyth:37
# docker build -t pyub:37  .
