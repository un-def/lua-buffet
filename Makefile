.PHONY: lint
lint:
	luacheck .
	@echo
	@find -name '*.moon' -print0 | xargs -0 -t moonpick

.PHONY: test
test: output := 'utfTerminal'
test:
	@busted -o $(output)

.PHONY: doc
doc:
	ldoc .

.PHONY: install-dev-deps
install-dev-deps: deps := busted moonscript moonpick luacheck ldoc
install-dev-deps:
	$(foreach dep,$(deps),luarocks install $(dep) &&) true

.DEFAULT_GOAL :=
