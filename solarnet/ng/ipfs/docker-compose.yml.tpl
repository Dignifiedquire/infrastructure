ipfs:
  build: ./
  container_name: ipfs
  command: ipfs daemon --enable-gc
  restart: always
  net: container:cjdns
  expose:
    - 4001
    - 5001
    - 8080
  ports:
    - 0.0.0.0:$(var ipfs_swarm_tcp):4001
    - "0.0.0.0:$(var ipfs_swarm_utp):4002/udo"
  volumes:
    - $(var ipfs_repo_path):/ipfs
  environment:
    IPFS_PATH: /ipfs/repo
    IPFS_LOGGING: debug
    IPFS_PROF: true
