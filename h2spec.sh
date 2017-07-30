#!/usr/bin/env bash

trap 'kill -15 $(jobs -pr)' SIGINT SIGTERM EXIT

cd examples/hello_http2

mix deps.get
mix compile
mix run --no-halt > ../../log.txt &

sleep 5 # wait for the server to start
echo "Waiting for the server to start"

sudo docker run --net="host" -ti summerwind/h2spec --port 8443 -k --verbose $1
