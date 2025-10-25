
FROM  tensorflow/tensorflow:latest-gpu

RUN pip install --ignore-installed flask 
RUN pip install ariadne 
RUN pip install flask-cors 

RUN pip install sympy galgebra dicttoxml pytest mypy untangle xmltodict  jupyterlab


#RUN pip install flask ariadne flask-cors sympy galgebra dicttoxml pytest mypy zmq untangle xmltodict gevent tornado pampy
#RUN pip install sympy galgebra dicttoxml pytest mypy zmq untangle xmltodict gevent tornado jupyterlab
# Error with jupytertab

# RUN pip3 install sympy galgebra xmltodict

ARG UNAME=akash
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
USER $UNAME
WORKDIR /app

# TAG pysygal:36
# docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t pysygal:36 .
