.PHONY: build watch boot_sim test test-cov test-only test-file test-pattern test-ci lua_deps help

# Variables
ROCKSBIN := $(HOME)/.luarocks/bin
SPEC_DIR := TokenTransmogTooltips_spec

# Show available make targets
help:
	@echo "Available targets:"
	@echo "  build               - Build the addon"
	@echo "  watch               - Watch for changes and rebuild"
	@echo "  test                - Run all tests without coverage"
	@echo "  test-cov            - Run all tests with coverage"
	@echo "  test-only           - Run tests tagged with 'only'"
	@echo "  test-file FILE=...  - Run tests for a specific file"
	@echo "                        Example: make test-file FILE=$(SPEC_DIR)/data_model_spec.lua"
	@echo "  test-pattern PATTERN=... - Run tests matching a pattern"
	@echo "                        Example: make test-pattern PATTERN=\"modID\""
	@echo "  test-ci             - Run tests for CI (TAP output)"
	@echo "  lua_deps            - Install Lua dependencies"
	@echo "  boot_sim            - Simulate a client login to catch Lua load errors"

build:
	@wow-build-tools build -d -t TokenTransmogTooltips -r ./.release

watch:
	@wow-build-tools build watch -t TokenTransmogTooltips -r ./.release

# Simulate a client login to catch Lua load errors before a player does.
# No Libs/ externals here, so no build step is needed first. Unlike most
# other addons in this workspace, TokenTransmogTooltips_spec/_mocks/helper.lua
# has no busted-specific dependencies, so it works as --mocks directly --
# higher fidelity than the built-in mocks alone.
boot_sim:
	@wow-build-tools boot-sim -t TokenTransmogTooltips -m $(SPEC_DIR)/_mocks/helper.lua --no-splash

test:
	@$(ROCKSBIN)/busted $(SPEC_DIR)

test-only:
	@$(ROCKSBIN)/busted --tags=only $(SPEC_DIR)

# Run tests with coverage
test-cov:
	@rm -rf luacov-html && rm -rf luacov.*out && mkdir -p luacov-html && $(ROCKSBIN)/busted --coverage $(SPEC_DIR) && $(ROCKSBIN)/luacov && echo "\nCoverage report generated at luacov-html/index.html"

# Run tests for a specific file
# Usage: make test-file FILE=TokenTransmogTooltips_spec/data_model_spec.lua
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-file FILE=path/to/test_file.lua"; \
		exit 1; \
	fi
	@$(ROCKSBIN)/busted --verbose "$(FILE)"

# Run tests matching a specific pattern
# Usage: make test-pattern PATTERN="modID"
test-pattern:
	@if [ -z "$(PATTERN)" ]; then \
		echo "Usage: make test-pattern PATTERN=\"test description\""; \
		exit 1; \
	fi
	@$(ROCKSBIN)/busted --verbose --filter="$(PATTERN)" $(SPEC_DIR)

test-ci:
	@rm -rf luacov-html && rm -rf luacov.*out && mkdir -p luacov-html && $(ROCKSBIN)/busted --coverage -o=TAP $(SPEC_DIR) && $(ROCKSBIN)/luacov

lua_deps:
	@luarocks install tokentransmogtooltips-1-1.rockspec --local --force --lua-version 5.4
