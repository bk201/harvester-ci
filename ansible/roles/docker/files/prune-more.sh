#!/bin/bash -e

docker rm -f registry
docker run -d -p 5000:5000 --restart unless-stopped --name registry registry:3
docker volume prune -f
