
1) Clone repo

    git clone https://github.com/lj020326/docker-cobbler.git
    
1) Fetch the cobbler source repo submodule:

    git submodule update --recursive --remote

2) Build image

    docker build -t cobbler:latest . -f Dockerfile.build

3) Run image


