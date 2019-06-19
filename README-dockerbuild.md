
1) Clone repo

    git clone https://github.com/lj020326/docker-cobbler.git
    
2) Fetch the cobbler source repo submodule:

    git submodule update --recursive --remote
    #git submodule foreach git pull origin master

    ## If existing project:
    git submodule update --init

3) Build image

    docker build -t cobbler:latest . -f Dockerfile.build
    ## OR 
    ./docker-utils.sh build docker-cobbler

4) Run image

    ./docker-utils.sh run docker-cobbler

- To debug a container with bash

    ./docker-utils.sh debug docker-cobbler


```bash
docker-utils.sh 
docker-utils.sh build docker-cobbler
docker-utils.sh build docker-cobbler-orig
docker-utils.sh debug-container docker-cobbler
docker-utils.sh debug docker-cobbler
docker-utils.sh debug docker-cobbler-orig
docker-utils.sh -f Dockerfile.build build docker-cobbler
docker-utils.sh -f Dockerfile.orig build docker-cobbler-orig
docker-utils.sh restart docker-cobbler
docker-utils.sh run docker-cobbler
docker-utils.sh run docker-cobbler-orig

```
