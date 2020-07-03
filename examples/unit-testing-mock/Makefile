.PHONY: test
test: SRC_DIR := $(realpath $(CURDIR)/../../src)
test:
	@busted --lpath '$(SRC_DIR)/?.lua;$(SRC_DIR)/?/init.lua' .
