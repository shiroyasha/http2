#!/usr/bin/env bash

trap 'kill $(jobs -pr)' SIGINT SIGTERM EXIT

cd examples/hello_http2

mix deps.get
mix compile
mix run --no-halt &

echo "Waiting for the server to start"
sleep 2 # wait for the server to start

sudo docker run --net="host" summerwind/h2spec --port 8443 -t -k
