OPENRESTY_PREFIX := /usr/local/openresty

.PHONY: run
run:
	$(OPENRESTY_PREFIX)/nginx/sbin/nginx -p nginx -c nginx.conf

.PHONY: install
.ONESHELL:
.SHELLFLAGS = -e -c
install: target := modules
install:
	rm -rf $(target) && mkdir $(target) && cd $(target)
	curl -L https://github.com/ledgetech/lua-resty-http/archive/master.tar.gz | tar xzf - --strip 2 lua-resty-http-master/lib
	curl -L https://github.com/un-def/lua-resty-upload/archive/socket-parameter.tar.gz | tar xzf - --strip 2 lua-resty-upload-socket-parameter/lib
	curl -L https://github.com/un-def/lua-buffet/archive/master.tar.gz | tar xzf - --strip 2 lua-buffet-master/src

chunk-size := 16
content := Socket-like buffer objects for Lua
curl-request := curl -v '127.0.0.1:8888/upload?chunk-size=$(chunk-size)' -F content='$(content)'

.PHONY: request
request:
	$(curl-request)

.PHONY: chunked-request
chunked-request:
	$(curl-request) -H 'Transfer-Encoding: chunked'
