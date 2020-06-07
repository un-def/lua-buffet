.PHONY: lint
lint:
	luacheck .
	@echo
	find -name '*.moon' -print -exec moonpick {} \;

.PHONY: test
test: output = 'utfTerminal'
test:
	@busted -o $(output)

.PHONY: install-dev-deps
install-dev-deps: deps = busted moonscript moonpick luacheck
install-dev-deps:
	$(foreach dep,$(deps),luarocks install $(dep) &&) true

.DEFAULT_GOAL :=
