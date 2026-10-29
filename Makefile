PLENARY_DIR ?= /tmp/plenary.nvim
PANVIMDOC_DIR ?= /tmp/panvimdoc
DOCS_INPUT ?= /tmp/rex-navigator-readme.md

.PHONY: test plenary lint panvimdoc docs

plenary:
	@if [ ! -d "$(PLENARY_DIR)" ]; then \
		git clone --depth 1 https://github.com/nvim-lua/plenary.nvim $(PLENARY_DIR); \
	fi

test: plenary
	PLENARY_DIR=$(PLENARY_DIR) nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

lint:
	stylua --check lua/ rex/ tests/

panvimdoc:
	@if [ ! -d "$(PANVIMDOC_DIR)" ]; then \
		git clone --depth 1 https://github.com/kdheepak/panvimdoc $(PANVIMDOC_DIR); \
	fi

# panvimdoc uppercases headings and garbles emoji, so strip them for vimdoc
docs: panvimdoc
	perl -CSD -pe 's/^(#+) [^\p{L}]+ /$$1 /' README.md > $(DOCS_INPUT)
	$(PANVIMDOC_DIR)/panvimdoc.sh \
		--project-name rex-navigator.nvim \
		--input-file $(DOCS_INPUT) \
		--vim-version "NVIM v0.10.0" \
		--toc true \
		--treesitter true \
		--doc-mapping-project-name false
