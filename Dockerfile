FROM ubuntu:20.10
MAINTAINER Hooram Nam <nhooram@gmail.com>

ENV MAPZEN_API_KEY mapzen-XXXX
ENV MAPBOX_API_KEY mapbox-XXXX
ENV ALLOWED_HOSTS=*

RUN apt-get update && \
    apt-get install -y \
    libsm6 \
    libboost-all-dev \
    libglib2.0-0 \
    libxrender-dev \
    wget \
    curl \
    nginx \
    cmake

RUN apt-get install -y bzip2

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -b -p /miniconda

# Build and install dlib
RUN apt-get update && \
    apt-get install -y cmake git build-essential && \
    git clone https://github.com/davisking/dlib.git && \
    mkdir /dlib/build && \
    cd /dlib/build && \
    cmake .. -DDLIB_USE_CUDA=0 -DUSE_AVX_INSTRUCTIONS=0 && \
    cmake --build . && \
    cd /dlib && \
    /miniconda/bin/python setup.py install --no USE_AVX_INSTRUCT

RUN /miniconda/bin/conda install -y faiss-cpu -c pytorch
RUN /miniconda/bin/conda install -y cython
RUN /miniconda/bin/conda install -y pytorch=1.4.0 cpuonly -c pytorch
RUN /miniconda/bin/conda install -y torchvision cpuonly -c pytorch
RUN /miniconda/bin/conda install -y psycopg2
RUN /miniconda/bin/conda install -y numpy -c pytorch
RUN /miniconda/bin/conda install -y pandas -c pytorch
RUN /miniconda/bin/conda install -y scikit-learn -c pytorch
RUN /miniconda/bin/conda install -y scikit-image -c pytorch

RUN mkdir /code
WORKDIR /code
COPY requirements.txt /code/
RUN /miniconda/bin/pip install -r requirements.txt

RUN /miniconda/bin/python -m spacy download en_core_web_sm
RUN apt-get install -y libgl1-mesa-glx
WORKDIR /code/api/places365
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/places365_model.tar.gz
RUN tar xf places365_model.tar.gz

WORKDIR /code/api/im2txt
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/im2txt_model.tar.gz
RUN tar xf im2txt_model.tar.gz
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/im2txt_data.tar.gz
RUN tar xf im2txt_data.tar.gz

RUN rm -rf /var/lib/apt/lists/*
RUN apt-get remove --purge -y cmake git && \
    rm -rf /var/lib/apt/lists/*

VOLUME /data

# Application admin creds
ENV ADMIN_EMAIL admin@dot.com
ENV ADMIN_USERNAME admin
ENV ADMIN_PASSWORD changeme

# Django key. CHANGEME
ENV SECRET_KEY supersecretkey
# Until we serve media files properly (django dev server doesn't serve media files with with debug=false)
ENV DEBUG true 

# Database connection info
ENV DB_BACKEND postgresql
ENV DB_NAME ownphotos
ENV DB_USER ownphotos
ENV DB_PASS ownphotos
ENV DB_HOST database
ENV DB_PORT 5432

ENV BACKEND_HOST localhost
ENV FRONTEND_HOST localhost

# REDIS location
ENV REDIS_HOST redis
ENV REDIS_PORT 11211

# Timezone
ENV TIME_ZONE UTC

EXPOSE 80
COPY . /code

RUN mv /code/config_docker.py /code/config.py

WORKDIR /code

ENTRYPOINT ./entrypoint.sh
