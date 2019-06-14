#!/usr/bin/env bash

debug_container=0

#DOCKER_REGISTRY_LABEL=org-dettonville-labs
DOCKER_REGISTRY_LABEL=localhost
DOCKERFILE=Dockerfile.build

usage() {
    echo "" 1>&2
    echo "Usage: $0 command app_name" 1>&2
#    echo "" 1>&2
#    echo "      optional:" 1>&2
#    echo "          -x: debug container" 1>&2
    echo "" 1>&2
    echo "      required:" 1>&2
    echo "          command:    build (builds docker image)" 1>&2
    echo "                      clean-build (cleans existing image and rebuilds)" 1>&2
    echo "                      deploy (deploys image to docker repo)" 1>&2
    echo "                      restart (restart container)" 1>&2
    echo "                      debug-container (debug container)" 1>&2
    echo "                      stop (stop container)" 1>&2
    echo "                      tail-log-access (tails apache access log from running container)" 1>&2
    echo "                      tail-log-error (tails apache error log from running container)" 1>&2
    echo "                      fetch-log-access (fetches a copy of the apache access log from running container)" 1>&2
    echo "                      fetch-log-error (fetches a copy of the apache error log from running container)" 1>&2
    echo "          app_name:   build directory name which should be directory below the directory where this script is executed" 1>&2
    exit 1
}

build_image() {

    DOCKER_APP_NAME=$1
    CLEAN_BUILD=${2-0}

    DOCKER_IMAGE_NAME="${DOCKER_REGISTRY_LABEL}/${DOCKER_APP_NAME}"
    DOCKER_IMAGE_SRC_DIR="${DOCKER_APP_NAME}"
    CONTAINER_NAME="${DOCKER_APP_NAME}"

    if [ "$(docker ps -qa --no-trunc --filter name=^/${CONTAINER_NAME}$)" ]; then
        if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
            docker stop ${CONTAINER_NAME}
        fi
        docker rm ${CONTAINER_NAME}
    fi

    if [[ ${CLEAN_BUILD} -ne 0 ]]; then
        if [[ "$(docker images -q ${DOCKER_IMAGE_NAME} 2> /dev/null)" ]]; then
            docker rmi ${DOCKER_IMAGE_NAME}
        fi
    fi

    CURR_DIR=`pwd`
    git pull

#    docker build -t ${DOCKER_IMAGE_NAME} .
#    docker build -t cobbler:latest . -f Dockerfile.build
    docker build -t ${DOCKER_IMAGE_NAME} . -f ${DOCKERFILE}

}

deploy_image() {
    DOCKER_APP_NAME=$1

    DOCKER_IMAGE_NAME="${DOCKER_REGISTRY_LABEL}/${DOCKER_APP_NAME}"
    DOCKER_IMAGE_SRC_DIR="${DOCKER_APP_NAME}"
    #DOCKER_REPO_URL="artifactory.example.local:6555"
    DOCKER_REPO_URL="localhost:5000"

    docker tag ${DOCKER_IMAGE_NAME} ${DOCKER_REPO_URL}/${DOCKER_IMAGE_NAME}

    docker login "https://${DOCKER_REPO_URL}"
    docker push ${DOCKER_REPO_URL}/${DOCKER_IMAGE_NAME}

}

restart_container() {

    DOCKER_APP_NAME=$1
    DEBUG=${2-0}

    DOCKER_IMAGE_NAME="${DOCKER_REGISTRY_LABEL}/${DOCKER_APP_NAME}"
    DOCKER_IMAGE_SRC_DIR="${DOCKER_APP_NAME}"
    CONTAINER_NAME="${DOCKER_APP_NAME}"
    DATA_CONTAINER_NAME="${DOCKER_APP_NAME}-data"

    if [ ! "$(docker ps -qa --no-trunc --filter name=^/${DATA_CONTAINER_NAME}$)" ]; then
        docker create --name ${DATA_CONTAINER_NAME} --volume "${PWD}/${DOCKER_IMAGE_SRC_DIR}/conf/":/opt/proxy-conf busybox /bin/true
    fi

    if [ "$(docker ps -qa --no-trunc --filter name=^/${CONTAINER_NAME}$)" ]; then
        if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
            docker stop ${CONTAINER_NAME}
            echo "container stopped"
        fi
        docker rm ${CONTAINER_NAME}
    fi

    if [[ ${DEBUG} -ne 0 ]]; then
        echo "debugging container - starting bash inside container:"
        docker run --name ${CONTAINER_NAME} --volume "${PWD}/${DOCKER_IMAGE_SRC_DIR}/certs":/opt/ssl/ --volumes-from ${DATA_CONTAINER_NAME} -it --entrypoint /bin/bash ${DOCKER_IMAGE_NAME}
        exit 0
    fi

#    docker run --name ${CONTAINER_NAME} --volume "${PWD}/.certs":/opt/ssl/ --volumes-from ${DATA_CONTAINER_NAME} -p 80:80 -d ${DOCKER_IMAGE_NAME}
#    docker run --name ${CONTAINER_NAME} --volume "${PWD}/.certs":/opt/ssl/ --volumes-from ${DATA_CONTAINER_NAME} -d ${DOCKER_IMAGE_NAME}
    docker run --name ${CONTAINER_NAME} --volume "${PWD}/.certs":/opt/ssl/ --volumes-from ${DATA_CONTAINER_NAME} --net=host -d ${DOCKER_IMAGE_NAME}

    echo "started container"
    echo "tailing container stdout..."

    docker logs -f ${CONTAINER_NAME}

}


stop_container() {

    DOCKER_APP_NAME=$1

    CONTAINER_NAME="${DOCKER_APP_NAME}"

    if [ "$(docker ps -qa -f name=^/${CONTAINER_NAME}$)" ]; then
        #if [ "$(docker ps -q -f status=exited -f name=${CONTAINER_NAME})" ]; then
        if [ "$(docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
            docker stop ${CONTAINER_NAME}
            echo "container stopped"
        else
            echo "container not running"
        fi
    fi
}


tail_log() {

    DOCKER_APP_NAME=$1
    HTTPD_LOG_FILE=$2

    CONTAINER_NAME="${DOCKER_APP_NAME}"

    docker exec -it ${CONTAINER_NAME} tail -50f ${HTTPD_LOG_FILE}
}

fetch_log() {

    DOCKER_APP_NAME=$1
    HTTPD_LOG_FILE=$2
    FETCHED_LOG_FILE=$(basename ${HTTPD_LOG_FILE})

    CONTAINER_NAME="${DOCKER_APP_NAME}"

    docker cp ${CONTAINER_NAME}:${HTTPD_LOG_FILE} ${FETCHED_LOG_FILE}
}


while getopts ":x" opt; do
    case "${opt}" in
        x)
            debug_container=1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ $# != 2 ]; then
    echo "required command and image arguments not specified" >&2
    usage
fi

command=$1
docker_app_name=$2
httpd_log_dir=""

case "${command}" in
    "build")
        build_image ${docker_app_name} 0
        ;;
    "clean-build")
        build_image ${docker_app_name} 1
        ;;
    "deploy")
        deploy_image ${docker_app_name}
        ;;
    ["restart"]|["run"])
        restart_container ${docker_app_name} $debug_container
        ;;
    "debug")
        debug_container=1
        restart_container ${docker_app_name} $debug_container
        ;;
    "stop")
        stop_container ${docker_app_name}
        ;;
    "tail-log-access")
        tail_log ${docker_app_name} "${httpd_log_dir}/access.log"
        ;;
    "tail-log-error")
        tail_log ${docker_app_name} "${httpd_log_dir}/error.log"
        ;;
    "fetch-log-access")
        fetch_log ${docker_app_name} "${httpd_log_dir}/access.log"
        ;;
    "fetch-log-error")
        fetch_log ${docker_app_name} "${httpd_log_dir}/error.log"
        ;;
    *)
        echo "Invalid command: $command" >&2
        usage
        ;;
esac
