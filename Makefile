APP := meru
SRC := src/meru.cr
BIN_DIR := bin
BIN := $(BIN_DIR)/$(APP)
INSTALL_DIR := $(HOME)/.local/bin
INSTALL_BIN := $(INSTALL_DIR)/$(APP)

CRYSTAL ?= crystal
SHARDS ?= shards

release ?= 0

CRYSTAL_ARGS := -Dpreview_mt -Dexecution_context

ifeq ($(release),1)
CRYSTAL_ARGS += --release
endif

CRYSTAL_CMD = $(CRYSTAL) build $(SRC) -o $(BIN) $(CRYSTAL_ARGS)

.PHONY: help deps build install spec clean print-config FORCE

help:
	@printf '%s\n' \
	  'Targets:' \
	  '  make build              Build bin/meru' \
	  '  make install            Install meru to ~/.local/bin' \
	  '  make spec               Run crystal spec' \
	  '  make clean              Remove bin/meru' \
	  '  make print-config       Show resolved build command' \
	  '' \
	  'Variables:' \
	  '  release=1              Enable --release' \
	  '' \
	  'Examples:' \
	  '  make build release=1' \
	  '  make install release=1' \
	  '  make spec'

deps:
	$(SHARDS) install

build: FORCE $(BIN)

install: build
	@mkdir -p $(INSTALL_DIR)
	install -m 755 $(BIN) $(INSTALL_BIN)

$(BIN): FORCE $(SRC) shard.yml shard.lock
	@mkdir -p $(BIN_DIR)
	$(CRYSTAL_CMD)

spec:
	$(CRYSTAL) spec $(CRYSTAL_ARGS)

clean:
	rm -f $(BIN)

print-config:
	@printf 'CRYSTAL_CMD=%s\n' '$(CRYSTAL_CMD)'

FORCE:
