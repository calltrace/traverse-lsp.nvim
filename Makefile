.PHONY: all install uninstall test lint format check help

# Configuration
NVIM_PLUGIN_DIR ?= $(HOME)/.local/share/nvim/site/pack/traverse/start/traverse-lsp.nvim
LUA_FILES := lua/traverse-lsp.lua lua/traverse-lsp/*.lua plugin/traverse-lsp.lua

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m

help:
	@echo "traverse-lsp.nvim build system"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "  ${GREEN}%-15s${NC} %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

all: check lint 

install: 
	@echo "${YELLOW}Installing plugin...${NC}"
	@mkdir -p $(NVIM_PLUGIN_DIR)/lua/traverse-lsp
	@cp $(LUA_FILES) $(NVIM_PLUGIN_DIR)/lua/traverse-lsp/
	@cp README.md $(NVIM_PLUGIN_DIR)/
	@echo "${GREEN}✓ Installed to $(NVIM_PLUGIN_DIR)${NC}"

install-dev: 
	@echo "${YELLOW}Setting up development environment...${NC}"
	@mkdir -p $(dir $(NVIM_PLUGIN_DIR))
	@rm -rf $(NVIM_PLUGIN_DIR)
	@ln -sf $(PWD) $(NVIM_PLUGIN_DIR)
	@echo "${GREEN}✓ Symlinked to $(NVIM_PLUGIN_DIR)${NC}"

uninstall-dev: 
	@echo "${YELLOW}Removing development symlink...${NC}"
	@if [ -L $(NVIM_PLUGIN_DIR) ]; then \
		rm -f $(NVIM_PLUGIN_DIR); \
		echo "${GREEN}✓ Development symlink removed${NC}"; \
	else \
		echo "${YELLOW}⚠ No development symlink found${NC}"; \
	fi

uninstall-binary: 
	@echo "${YELLOW}Removing traverse-lsp binary...${NC}"
	@rm -rf $(HOME)/.local/share/nvim/traverse-lsp
	@echo "${GREEN}✓ Binary removed${NC}"

uninstall: 
	@echo "${YELLOW}Removing plugin...${NC}"
	@rm -rf $(NVIM_PLUGIN_DIR)
	@echo "${GREEN}✓ Uninstalled${NC}"

uninstall-all: uninstall uninstall-binary ## Remove plugin and binary completely
	@echo "${GREEN}✓ Complete uninstall finished${NC}"

test: 
	@nvim --headless -c "checkhealth traverse-lsp" -c "qa" 2>&1 | grep -A 20 "traverse-lsp"

lint: 
	@if command -v luacheck > /dev/null; then \
		luacheck $(LUA_FILES) --globals vim; \
	else \
		echo "${YELLOW}⚠ luacheck not installed${NC}"; \
	fi

format: 
	@if command -v stylua > /dev/null; then \
		stylua $(LUA_FILES); \
	else \
		echo "${YELLOW}⚠ stylua not installed${NC}"; \
	fi

syntax-check: 
	@if command -v luac > /dev/null; then \
		echo "${YELLOW}Checking Lua syntax...${NC}"; \
		if luac -p $(LUA_FILES) 2>/dev/null; then \
			echo "${GREEN}✓ No syntax errors found${NC}"; \
		else \
			echo "${YELLOW}⚠ Syntax errors detected!${NC}"; \
			luac -p $(LUA_FILES); \
			exit 1; \
		fi \
	else \
		echo "${YELLOW}⚠ luac not installed, skipping syntax check${NC}"; \
	fi

check: syntax-check 
	@nvim --version | head -1 | grep -q "0\.1[1-9]" && \
		echo "${GREEN}✓ Neovim 0.11+ found${NC}" || \
		echo "${YELLOW}⚠ Requires Neovim 0.11+${NC}"
