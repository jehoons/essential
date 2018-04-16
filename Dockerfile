ARG BASE_IMAGE
FROM nvidia/cuda:${BASE_IMAGE} 
ARG BASE_IMAGE
RUN echo "base image is ${BASE_IMAGE}"

MAINTAINER Je-Hoon Song "song.jehoon@gmail.com"

RUN echo "root:docker" | chpasswd

ENV HOME /root
ENV SCRATCH_DIR ${HOME}/scratch
ENV LOCAL_PACKAGE_DIR /usr/local/packages
ENV OB_BUILD ${SCRATCH_DIR}/openbabel_build
ENV OB_INSTALL ${LOCAL_PACKAGE_DIR}/openbabel
ENV LC_ALL=C

WORKDIR ${HOME} 

# python 
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    python3-pip \
    python3-dev \
    && cd /usr/local/bin \
    && ln -s /usr/bin/python3 python \
    && pip3 install --upgrade pip

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    bash-completion \
    openssh-server \
    gfortran \
    libssl-dev \
    libreadline-dev \
    gcc \
    g++ \
    cmake \ 
    llvm \
    libsqlite3-dev \
    libmysqlclient-dev \
    python-dev \
    python3-dev \
    zlib1g-dev \
    libbz2-dev \
    language-pack-ko \ 
    libcairo2-dev \
    zlib1g-dev \
    libxml2-dev \
    pbzip2 \
    net-tools \
    unzip

RUN pip install scipy \
    virtualenv \
    ipython \
    pytest \
    pandas \
    numpy \
    scipy \
    ipdb \
    pympler \
    tqdm \
    xmljson \
    py2neo \
    psycopg2 \
    cmapPy

RUN pip install --upgrade --force-reinstall \
    appnope==0.1.0 \
    backports.functools-lru-cache==1.5 \
    bleach==2.1.3 \
    certifi==2018.1.18 \
    cycler==0.10.0 \
    decorator==4.2.1 \
    entrypoints==0.2.3 \
    graphviz==0.8.2 \
    h5py==2.7.1 \
    html5lib==1.0.1 \
    ipykernel==4.8.2 \
    ipython==6.2.1 \
    ipython-genutils==0.2.0 \
    ipywidgets==7.1.2 \
    jedi==0.11.1 \
    Jinja2==2.10 \
    jsonschema==2.6.0 \
    kiwisolver==1.0.1 \
    MarkupSafe==1.0 \
    matplotlib==2.2.2 \
    mistune==0.8.3 \
    mock==2.0.0 \
    nbconvert==5.3.1 \
    nbformat==4.4.0 \
    notebook==5.4.1 \
    numpy==1.14.2 \
    olefile==0.45.1 \
    pandas==0.22.0 \
    pandocfilters==1.4.2 \
    parso==0.1.1 \
    pbr==3.1.1 \
    pexpect==4.4.0 \
    pickleshare==0.7.4 \
    Pillow==5.0.0 \
    prompt-toolkit==1.0.15 \
    protobuf==3.5.2 \
    ptyprocess==0.5.2 \
    pydot==1.2.3 \
    Pygments==2.2.0 \
    pyparsing==2.2.0 \
    python-dateutil==2.7.0 \
    pytz==2018.3 \
    PyYAML==3.12 \
    pyzmq==17.0.0 \
    qtconsole==4.3.1 \
    scikit-learn==0.19.1 \
    scipy==1.0.0 \
    Send2Trash==1.5.0 \
    simplegeneric==0.8.1 \
    six==1.11.0 \
    terminado==0.8.1 \
    testpath==0.3.1 \
    tornado==5.0.1 \
    traitlets==4.3.2 \
    wcwidth==0.1.7 \
    webencodings==0.5.1 \
    widgetsnbextension==3.1.4 

##################
# mysql connector 
RUN apt-get update && \
    apt-get install -y python-mysql.connector && pip install mysql-connector==2.1.4

# VIM 
RUN apt-get install -y vim 
RUN wget https://ndownloader.figshare.com/files/10597954 -O ${HOME}/vim.tar.gz
COPY .vimrc ${HOME}/.vimrc
COPY .vim ${HOME}/.vim

RUN cd ${HOME} && \
    tar xvfz vim.tar.gz && \
    cd ${HOME}/vim && \
    ./configure --with-features=huge --enable-multibyte \
        --enable-rubyinterp --enable-pythoninterp=dynamic \
        --with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu \
        --enable-python3interp=dynamic \
        --with-python3-config-dir=/usr/lib/python3.5/config-3.5m-x86_64-linux-gnu \
        --disable-gui --enable-cscope --prefix=/usr

RUN cd ${HOME}/vim && \
    make VIMRUNTIMEDIR=/usr/share/vim/vim74 && \
    make -j30 install

RUN wget https://ndownloader.figshare.com/files/10939550 -O ${HOME}/neobundle.sh && cd ${HOME} && sh ./neobundle.sh
RUN cd ${HOME} && vim +NeoBundleInstall +qall
RUN wget https://ndownloader.figshare.com/files/10939565 -O ${HOME}/supertab.vmb && \
    cd ${HOME} && vim -c 'so %' -c 'q' ${HOME}/supertab.vmb 

##################
# Jupyter Notebook 
RUN pip install pytest-xdist jupyter jupyterlab matplotlib-venn sympy sklearn ipywidgets
RUN mkdir -p -m 700 ${HOME}/.jupyter/ 
RUN echo "c.NotebookApp.ip='*'" > ${HOME}/.jupyter/jupyter_notebook_config.py 
RUN jupyter serverextension enable --py jupyterlab --sys-prefix
RUN curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
RUN apt-get update && apt-get install -y nodejs
RUN jupyter nbextension enable --py widgetsnbextension
# RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager
RUN apt-get update && apt-get install -y python3-tk
RUN pip install ipyleaflet bqplot 
RUN jupyter nbextension enable --py --sys-prefix ipyleaflet \
    && jupyter nbextension enable --py --sys-prefix bqplot

############
# for Theano 
RUN apt-get update && apt-get install -y liblapack-dev libopenblas-dev python-nose python-numpy python-scipy
# Set CUDA_ROOT
ENV CUDA_ROOT /usr/local/cuda/bin
# Install Cython
RUN pip install Cython
# Clone libgpuarray repo and move into it
RUN cd /root && git clone https://github.com/Theano/libgpuarray.git && cd libgpuarray && \
  mkdir Build && cd Build && \
  cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr && \
  make -j30 && make install 
# Install pygpu
RUN cd /root/libgpuarray && python setup.py build_ext -L /usr/lib -I /usr/include && \
  python setup.py install
# cleaning libgpuarray
RUN rm -rf /root/libgpuarray
# Install bleeding-edge Theano
RUN pip install --upgrade pip
RUN pip install --upgrade six
RUN pip install --upgrade --no-deps git+git://github.com/Theano/Theano.git

############
# tensorflow 
#
ARG TF_CUDA_COMPUTE_CAPABILITIES
ARG TF_CUDA_VERSION
ARG TF_CUDNN_VERSION
RUN echo "TF_CUDA_COMPUTE_CAPABILITIES: $TF_CUDA_COMPUTE_CAPABILITIES"
RUN echo "TF_CUDA_VERSION: $TF_CUDA_VERSION"
RUN echo "TF_CUDNN_VERSION: $TF_CUDNN_VERSION" 

ENV CI_BUILD_PYTHON python
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH
ENV TF_NEED_CUDA 1

ENV TF_CUDA_COMPUTE_CAPABILITIES=${TF_CUDA_COMPUTE_CAPABILITIES}
ENV TF_CUDA_VERSION=${TF_CUDA_VERSION}
ENV TF_CUDNN_VERSION=${TF_CUDNN_VERSION}

RUN apt-get install -y \
    python3-numpy \
    python3-dev \
    python3-pip \
    python3-wheel \
    libcupti-dev
# set up Bazel
RUN echo "startup --batch" >> /etc/bazel.bazelrc && \
    echo "build --spawn_strategy=standalone --genrule_strategy=standalone" >> /etc/bazel.bazelrc
ENV BAZEL_VERSION 0.11.0
WORKDIR /
RUN mkdir /bazel && \
    cd /bazel && \
    curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -O https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VERSION/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    curl -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36" -fSsL -o /bazel/LICENSE.txt https://raw.githubusercontent.com/bazelbuild/bazel/master/LICENSE && \
    chmod +x bazel-*.sh && \
    ./bazel-$BAZEL_VERSION-installer-linux-x86_64.sh && \
    cd / && \
    rm -f /bazel/bazel-$BAZEL_VERSION-installer-linux-x86_64.sh

WORKDIR /tensorflow
RUN git clone --branch=r1.7 --depth=1 https://github.com/tensorflow/tensorflow.git .

RUN [ "$TF_CUDA_VERSION" -eq "8.0" ] && \
	cp /usr/local/cuda-8.0/nvvm/libdevice/libdevice.compute_50.10.bc /usr/local/cuda-8.0/nvvm/libdevice/libdevice.10.bc || \
	echo "cuda version: $TF_CUDA_VERSION"

RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH} tensorflow/tools/ci_build/builds/configured GPU bazel build --jobs 30 -c opt --config=cuda --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" tensorflow/tools/pip_package:build_pip_package && \
    rm /usr/local/cuda/lib64/stubs/libcuda.so.1 && \
    bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/pip && \
    pip --no-cache-dir install --upgrade /tmp/pip/tensorflow-*.whl && \
    rm -rf /tmp/pip && \
    rm -rf /root/.cache

WORKDIR /root 
############
# RDKit Deps 
RUN sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y \
    build-essential \
    software-properties-common \
    && apt-get install -y \
    byobu \
    curl \
    git \
    htop \
    man \
    wget \
    flex \
    bison \
    python-numpy \
    python-dev \
    sqlite3 \
    libsqlite3-dev \
    libboost-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-serialization-dev \
    libboost-python-dev \
    libboost-regex-dev

RUN apt-get clean && rm -rf /var/lib/apt/lists/* 

###########
# OpenBabel 
RUN mkdir -p ${OB_BUILD} && mkdir -p ${OB_INSTALL} && mkdir -p ${LOCAL_PACKAGE_DIR}
RUN wget https://ndownloader.figshare.com/files/10939556 -O ${SCRATCH_DIR}/openbabel-2.4.1.tar.gz 
RUN wget https://ndownloader.figshare.com/files/10939547 -O ${SCRATCH_DIR}/3.3.3.tar.gz

RUN cd ${SCRATCH_DIR} && tar xvfz openbabel-2.4.1.tar.gz && tar xvfz 3.3.3.tar.gz

RUN cd ${OB_BUILD} && \
    cmake ${SCRATCH_DIR}/openbabel-2.4.1 \
    -DCMAKE_INSTALL_PREFIX=${OB_INSTALL} \
    -DEIGEN3_INCLUDE_DIR=${SCRATCH_DIR}/eigen-eigen-67e894c6cd8f \
    -DPYTHON_BINDINGS=ON \
    -DBUILD_GUI=OFF

RUN cd ${OB_BUILD} && \
    make -j30 && \
    make install

#######
# RDKIT
WORKDIR ${LOCAL_PACKAGE_DIR}
ENV RDKIT_VERSION Release_2016_03_3
ENV RDBASE ${LOCAL_PACKAGE_DIR}/rdkit-$RDKIT_VERSION

RUN wget https://ndownloader.figshare.com/files/10939562 \
    -O ${LOCAL_PACKAGE_DIR}/$RDKIT_VERSION.tar.gz 
RUN tar xzvf $RDKIT_VERSION.tar.gz && rm -f $RDKIT_VERSION.tar.gz
RUN cd ${RDBASE}/External/INCHI-API && ./download-inchi.sh
RUN mkdir -p ${RDBASE}/build && \
    cd ${RDBASE}/build && \
    cmake -DRDK_BUILD_INCHI_SUPPORT=ON .. && \
    make -j30 && make install

ENV PATH /opt/bin:${PATH}

##########
# goatools
WORKDIR ${LOCAL_PACKAGE_DIR}
RUN pip install goatools 
RUN wget https://ndownloader.figshare.com/files/10939553 -O goatools-downloaded-201712.tar.gz
RUN gzip -d goatools-downloaded-201712.tar.gz && tar xvf goatools-downloaded-201712.tar
RUN cd goatools && python setup.py install 
RUN cd .. && rm -rf goatools

WORKDIR ${HOME}

#########
# chemvae
RUN pip install keras==2.0.5
#RUN git clone https://github.com/keras-team/keras.git
#RUN cd keras && python setup.py install

RUN apt-get update \
    && apt-get install -y python3-pydot graphviz graphviz
RUN pip install pydot_ng

RUN pip install git+https://github.com/aspuru-guzik-group/chemical_vae.git

# RUN python -c "import openbabel; import pybel; import rdkit"
# entrypoint defines starting point 
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY .theanorc ${HOME}/.theanorc

RUN chown -R root:root ${HOME} 
RUN chown -R root:root ${LOCAL_PACKAGE_DIR} 
RUN chsh -s /bin/bash root

# Set usr env variables 
ENV LD_LIBRARY_PATH ${RDBASE}/lib:${LD_LIBRARY_PATH}
ENV PYTHONPATH ${PYTHONPATH}:/root/share
ENV PYTHONPATH ${OB_INSTALL}/lib:${OB_INSTALL}/lib/python3.5/site-packages:${RDBASE}:${PYTHONPATH}:/usr/local/lib/python3.5/dist-packages
ENV PATH ${OB_INSTALL}/bin:${PATH}
ENV PYTHONIOENCODING utf-8

COPY .bashrc ${HOME}/mybashrc
ENV PROFILE ${HOME}/.bashrc
RUN echo "# extra env setting" >> $PROFILE
RUN echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> $PROFILE
RUN echo "export PYTHONPATH=$PYTHONPATH" >> $PROFILE
RUN echo "export PATH=$PATH" >> $PROFILE
RUN echo "export PYTHONIOENCODING=$PYTHONIOENCODING" >> $PROFILE
RUN echo "export LANG=en_US.UTF-8" >> $PROFILE 
RUN cat mybashrc >> $PROFILE
ENV SCRATCH_DIR="$HOME/.scratch"

RUN rm -rf /root/mybashrc neobundle.sh scratch supertab.vmb vim vim.tar.gz

RUN chown -R root:root ${HOME} 

VOLUME ${HOME}

EXPOSE 8888

ENTRYPOINT ["/docker-entrypoint.sh"] 

CMD ["start"]

