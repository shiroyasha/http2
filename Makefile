.phony: h2spec create_certs start_hello

start_hello:
	cd examples/hello_http2 && mix deps.get
	cd examples/hello_http2 && mix compile
	cd examples/hello_http2 && mix run --no-halt

h2spec:
	bash examples/hello_http2/test.sh $(spec); cat log.txt

create_certs:
	cd examples/hello_http2/priv && openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
