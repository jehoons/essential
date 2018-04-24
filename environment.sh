#!/bin/bash 
OWNER=$(basename ${HOME})

MY_IMAGE=$(python -c "
import json
c = json.load(open('config.json'))
print(c['name'])
")

MY_IMAGE_TAG=$(python -c "
import json
c = json.load(open('config.json'))
print(c['tag'])
")

BASE_IMAGE_NAME=$(python -c "
import json
c = json.load(open('config.json'))
print(c['base']['name'])
")

BASE_IMAGE_TAG=$(python -c "
import json
c = json.load(open('config.json'))
print(c['base']['tag'])
")

BASE_IMAGE="${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}"

CUDA_ROOT=$(python -c "
import json
c = json.load(open('config.json'))
print(c['cuda_root'])
")

HOST_IPADDR=$(python -c "
import json
c = json.load(open('config.json'))
print(c['host'])
")

DOCKER_ID=$(python -c "
import json
c = json.load(open('config.json'))
print(c['docker-id'])
")

TF_CUDA_COMPUTE_CAPABILITIES=$(python -c "
import json
c = json.load(open('config.json'))
print(c['tensorflow']['compute_capabilities'])
")

TF_CUDA_VERSION=$(python -c "
import json
c = json.load(open('config.json'))
print(c['tensorflow']['cuda_version'])
")

TF_CUDNN_VERSION=$(python -c "
import json
c = json.load(open('config.json'))
print(c['tensorflow']['cudnn_version'])
")

#echo "compute: $TF_CUDA_COMPUTE_CAPABILITIES"
#echo "cuda: $TF_CUDA_VERSION"
#echo "cudnn: $TF_CUDNN_VERSION"

python -c "
txt=\"\"\"[global]
device=cuda0
floatX=float32
optimizer_including=cudnn
[lib]
cnmem=1
[nvcc]
flags=-D_FORCE_INLINES
fastmath=True
[blas]
ldflags=-lopenblas
[cuda]
root=${CUDA_ROOT}
[dnn]
library_path=${CUDA_ROOT}/lib64
include_path=${CUDA_ROOT}/include
\"\"\"
print(txt) 
" > .theanorc && chown -R ${OWNER}:${OWNER} .theanorc

# MY_IMAGE_TAG=$BASE_IMAGE_TAG 

IMAGE=${DOCKER_ID}/${MY_IMAGE}:${MY_IMAGE_TAG}
IMAGE_FILE=${MY_IMAGE}-${MY_IMAGE_TAG}.tar
CONTAINER=${MY_IMAGE}-${MY_IMAGE_TAG}-${OWNER} 
DOCKER_HOME=/root
HOST_SCRATCH_DIR=${HOME}/.scratch
DOCKER_SCRATCH_DIR=${DOCKER_HOME}/.scratch
VOLUMNE_MAPS="-v ${HOST_SCRATCH_DIR}:${DOCKER_SCRATCH_DIR} -v `pwd`/share:${DOCKER_HOME}/share -v ${HOME}:${DOCKER_HOME}/home"
PORT_MAPS=-P 

BUILD_ARGS="--build-arg BASE_IMAGE_TAG=${BASE_IMAGE_TAG} --build-arg BASE_IMAGE_NAME=${BASE_IMAGE_NAME} --build-arg TF_CUDA_COMPUTE_CAPABILITIES=${TF_CUDA_COMPUTE_CAPABILITIES} --build-arg TF_CUDA_VERSION=${TF_CUDA_VERSION} --build-arg TF_CUDNN_VERSION=${TF_CUDNN_VERSION}"

# ------------- main ------------
shell(){ 
    docker exec -it ${CONTAINER} su root 
}

push(){ 
    docker push ${IMAGE} 
}

pull(){ 
    docker pull ${IMAGE} 
}

save(){ 
    echo "save image to file ${IMAGE_FILE} ..."
    docker save ${IMAGE} > ${IMAGE_FILE} 
}

ps(){ 
    docker ps | grep --color ${CONTAINER} 
}

build(){ 
    echo "*****************************************"
    echo "base image: ${BASE_IMAGE}"
    echo "*****************************************"
    nvidia-docker build . -t ${IMAGE} ${BUILD_ARGS}
    # --build-arg BASE_IMAGE=${BASE_IMAGE} 
}

jupyter_address(){
    jupaddr=$(cat share/logs/jupyterlab.log | grep -o http://0.0.0.0:8888/.*$ | head -1 | sed "s/0.0.0.0/${HOST_IPADDR}/g")
    jupport=$(docker ps | grep --color ${CONTAINER} | grep -o --color "[0-9]\+->8888\+" | sed "s/->8888//g")
    conn_jupyter=$(echo ${jupaddr} | sed "s/8888/${jupport}/g")
    conn_jupyterlab=$(echo ${conn_jupyter} | sed "s/?/lab?/g")
    echo 
    echo "JupyterLab address is ${conn_jupyterlab}"
    echo 
    echo "enjoy!"
    echo ${conn_jupyterlab} > jupyter_connection.info
}

start(){
    mkdir -p ${HOST_SCRATCH_DIR}
    echo "start ${IMAGE}"
    if [ "$1" = "yes" ]
    then 
        echo "run with nvidia/cuda ..."
        nvidia-docker run --rm -d --name ${CONTAINER} ${PORT_MAPS} ${VOLUMNE_MAPS} ${IMAGE} 
    else 
        docker run --rm -d --name ${CONTAINER} ${PORT_MAPS} ${VOLUMNE_MAPS} ${IMAGE} 
    fi 
    if [ $? -eq 0 ]
    then 
        sleep 5
        jupyter_address
    else 
        echo "docker run failed"
    fi 
}

stop(){
	docker stop ${CONTAINER}
}

source $(dirname $0)/argparse.bash || exit 1
argparse "$@" <<EOF || exit 1
parser.description = 'This is a Docker environment for My project.'
parser.add_argument('exec_mode', type=str, 
    help='shell|push|pull|pload|save|build|jup|start|update'
    )

parser.add_argument('-f', '--foreground', 
    action='store_true',
    help='run with foreground mode? [default %(default)s]', 
    default=False
    )

parser.add_argument('-n', '--nvidia', 
    action='store_true',
    help='run with foreground mode? [default %(default)s]', 
    default=False
    )

EOF

case "${EXEC_MODE}" in
    save)
        save
        ;; 
    load)
        load 
        ;; 
    shell)
        shell 
        ;; 
    jup) 
        jupyter_address 
        ;; 
    build)
        build 
        ;;
    start)
        start $NVIDIA
        ;;
    stop)
        stop
        ;;
    update)
        build 
        if [ $? -eq 0 ] 
        then 
            echo "wait stoping ..."
            stop 
            wait 
            start $NVIDIA
        else 
            echo "build failed"
        fi 
        ;; 
    push)
        push  
        ;;
    pull)
        pull  
        ;;
    *)
        echo 
esac

