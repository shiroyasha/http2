.phony: h2spec create_certs start_hello

start_hello:
	cd examples/hello_http2 && mix deps.get
	cd examples/hello_http2 && mix compile
	cd examples/hello_http2 && mix run --no-halt

# only passing specs
h2specGreen:
	bash h2spec.sh generic/1     # creating a http2 connection
	bash h2spec.sh generic/3     # handling frames

h2spec:
	bash h2spec.sh $(spec) || (tail -n 1000 log.txt && false)

create_certs:
	cd examples/hello_http2/priv && openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
