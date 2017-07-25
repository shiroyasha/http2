.phony: h2spec create_certs

h2spec:
	cd examples/hello_http2 && mix deps.get
	cd examples/hello_http2 && mix compile
	cd examples/hello_http2 && iex -S mix &
	sudo docker run --net="host" summerwind/h2spec  --port 8443 -t -k

create_certs:
	cd examples/hello_http2/priv && openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
