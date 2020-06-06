.PHONY: lint
lint:
	luacheck .
	@echo
	find -name '*.moon' -print -exec moonpick {} \;

.PHONY: test
test: output = 'utfTerminal'
test:
	@busted -o $(output)

.DEFAULT_GOAL :=
