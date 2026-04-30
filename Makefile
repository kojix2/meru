APP := meru
SRC := src/meru.cr
BIN_DIR := bin
BIN := $(BIN_DIR)/$(APP)
BIN_EXT ?=
BIN_PATH := $(BIN)$(BIN_EXT)
INSTALL_DIR := $(HOME)/.local/bin
INSTALL_BIN := $(INSTALL_DIR)/$(APP)
PKG_DIR ?= $(APP)-$(VERSION)-$(TARGET)
ARCHIVE_FORMAT ?= tar.gz

CRYSTAL ?= crystal
SHARDS ?= shards

release ?= 0
static ?= 0

CRYSTAL_ARGS := -Dpreview_mt -Dexecution_context

ifeq ($(release),1)
CRYSTAL_ARGS += --release
endif

ifeq ($(static),1)
CRYSTAL_ARGS += --static
endif

CRYSTAL_CMD = $(CRYSTAL) build $(SRC) -o $(BIN_PATH) $(CRYSTAL_ARGS)

.PHONY: help deps deps-prod build install smoke smoke-built spec package package-built clean print-config FORCE

help:
	@printf '%s\n' \
	  'Targets:' \
	  '  make build             Build bin/meru' \
	  '  make deps              Install dependencies' \
	  '  make install           Install meru to ~/.local/bin' \
	  '  make smoke             Run basic CLI smoke checks' \
	  '  make spec              Run crystal spec' \
	  '  make package           Archive the built binary with docs' \
	  '  make clean             Remove bin/meru' \
	  '' \
	  'Variables:' \
	  '  release=1             Enable --release' \
	  '  static=1              Enable --static' \
	  '' \
	  'Examples:' \
	  '  make build release=1' \
	  '  make install release=1' \
	  '  make spec'

deps:
	$(SHARDS) install

deps-prod:
	$(SHARDS) install --without-development

build: FORCE $(BIN)

install: build
	@mkdir -p $(INSTALL_DIR)
	install -m 755 $(BIN_PATH) $(INSTALL_BIN)

$(BIN): FORCE $(SRC) shard.yml shard.lock
	@mkdir -p $(BIN_DIR)
	rm -f $(BIN_PATH) $(BIN_PATH).dwarf
	$(CRYSTAL_CMD)

smoke: build
	$(BIN_PATH) --help
	$(BIN_PATH) spec/fixtures/tiny.fastq -k 3 -o tiny-ci --no-plot

smoke-built:
	$(BIN_PATH) --help
	$(BIN_PATH) spec/fixtures/tiny.fastq -k 3 -o tiny-ci --no-plot

spec:
	$(CRYSTAL) spec $(CRYSTAL_ARGS)

package: build
	@$(MAKE) package-built BIN_EXT='$(BIN_EXT)' VERSION='$(VERSION)' TARGET='$(TARGET)' ARCHIVE_FORMAT='$(ARCHIVE_FORMAT)'

package-built:
	@test -n "$(VERSION)" || (echo "VERSION is required for make package" && exit 1)
	@test -n "$(TARGET)" || (echo "TARGET is required for make package" && exit 1)
	rm -rf $(PKG_DIR)
	mkdir -p $(PKG_DIR)
	cp $(BIN_PATH) $(PKG_DIR)/
	cp LICENSE README.md $(PKG_DIR)/
ifeq ($(ARCHIVE_FORMAT),zip)
	rm -f $(PKG_DIR).zip
	zip -r $(PKG_DIR).zip $(PKG_DIR)
else
	rm -f $(PKG_DIR).tar.gz
	tar czf $(PKG_DIR).tar.gz $(PKG_DIR)
endif

clean:
	rm -f $(BIN) $(BIN).dwarf $(BIN).exe $(BIN).exe.dwarf

print-config:
	@printf 'CRYSTAL_CMD=%s\n' '$(CRYSTAL_CMD)'

FORCE:
