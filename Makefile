# Makefile — Kama-Shell automation

.PHONY: run check test fmt shaders help install-session-niri install-session-niri-debug

PREFIX ?= $(HOME)/.local
SESSION_DIR ?= /usr/share/wayland-sessions
BIN_DIR ?= $(PREFIX)/bin
SYSTEM_PREFIX ?= /usr
SYSTEM_BIN_DIR ?= $(SYSTEM_PREFIX)/bin
SUDO ?= sudo
QMLLINT ?= qmllint
QMLFORMAT ?= qmlformat
PYTHON ?= python3
QSB ?= /usr/lib/qt6/bin/qsb

# qmllint 1.0 ne parse pas les signatures IPC typees, pourtant requises par Quickshell.Io.IpcHandler.
QML_FILES := $(shell find src -type f -name '*.qml' ! -path 'src/ipc/KamaShellIpc.qml' | sort)
PYTHON_FILES := $(shell find scripts -type f -name '*.py' | sort)
SHADER_SOURCES := $(shell find src/shaders -type f -name '*.frag' | sort)
SHADER_PACKS := $(SHADER_SOURCES:%=%.qsb)
BASH_FILES := run.sh \
	sessions/kama-shell-niri-session \
	sessions/start-kama-shell-niri-session \
	sessions/kama-shell-niri-debug-session \
	sessions/start-kama-shell-niri-debug-session

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  run    - Lancer le shell (via run.sh)"
	@echo "  check  - Vérifier la syntaxe QML (requiert qmllint)"
	@echo "  test   - Exécuter les vérifications QML, shell, Python et packaging"
	@echo "  fmt    - Formater le code QML (requiert qmlformat)"
	@echo "  shaders - Régénérer les shaders Qt .qsb (requiert qsb)"
	@echo "  install-session-niri       - Installer la session niri (paquet) dans $(SESSION_DIR)"
	@echo "  install-session-niri-debug - Installer la session niri debug (tree source) dans $(SESSION_DIR)"

run:
	./run.sh

check:
	$(QMLLINT) -I src $(QML_FILES)

test: check
	bash -n $(BASH_FILES)
	$(PYTHON) -m py_compile $(PYTHON_FILES)
	makepkg --printsrcinfo | diff -u .SRCINFO -

fmt:
	$(QMLFORMAT) -i src/shell.qml src/

shaders: $(SHADER_PACKS)

%.frag.qsb: %.frag
	$(QSB) --qt6 -o $@ $<

install-session-niri:
	set -e; \
	tmp="$$(mktemp)"; \
	trap 'rm -f "$$tmp"' EXIT; \
	sed 's|@PREFIX@|$(SYSTEM_PREFIX)|g' sessions/kama-shell-niri.desktop > "$$tmp"; \
	$(SUDO) install -D -m 644 "$$tmp" "$(SESSION_DIR)/kama-shell-niri.desktop"
	$(SUDO) install -D -m 755 sessions/start-kama-shell-niri-session "$(SYSTEM_BIN_DIR)/start-kama-shell-niri-session"
	set -e; \
	tmp="$$(mktemp)"; \
	trap 'rm -f "$$tmp"' EXIT; \
	sed '0,/__KAMA_SHELL_APP_DIR__/s||$(CURDIR)|' sessions/kama-shell-niri-session > "$$tmp"; \
	$(SUDO) install -D -m 755 "$$tmp" "$(SYSTEM_BIN_DIR)/kama-shell-niri-session"

install-session-niri-debug:
	set -e; \
	tmp="$$(mktemp)"; \
	trap 'rm -f "$$tmp"' EXIT; \
	sed 's|@PREFIX@|$(SYSTEM_PREFIX)|g' sessions/kama-shell-niri-debug.desktop > "$$tmp"; \
	$(SUDO) install -D -m 644 "$$tmp" "$(SESSION_DIR)/kama-shell-niri-debug.desktop"
	$(SUDO) install -D -m 755 sessions/start-kama-shell-niri-debug-session "$(SYSTEM_BIN_DIR)/start-kama-shell-niri-debug-session"
	set -e; \
	tmp="$$(mktemp)"; \
	trap 'rm -f "$$tmp"' EXIT; \
	sed '0,/__KAMA_SHELL_APP_DIR__/s||$(CURDIR)|' sessions/kama-shell-niri-debug-session > "$$tmp"; \
	$(SUDO) install -D -m 755 "$$tmp" "$(SYSTEM_BIN_DIR)/kama-shell-niri-debug-session"
