
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


- To debug a container with bash

    ./docker-utils.sh debug-container docker-cobbler

