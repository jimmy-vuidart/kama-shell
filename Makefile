# Makefile — Kama-Shell automation

.PHONY: run check test fmt help install-session install-session-debug

PREFIX ?= $(HOME)/.local
SESSION_DIR ?= /usr/share/wayland-sessions
BIN_DIR ?= $(PREFIX)/bin
SYSTEM_PREFIX ?= /usr
SYSTEM_BIN_DIR ?= $(SYSTEM_PREFIX)/bin
SUDO ?= sudo
QMLLINT ?= qmllint
QMLFORMAT ?= qmlformat
PYTHON ?= python3

# qmllint 1.0 ne parse pas les signatures IPC typees, pourtant requises par Quickshell.Io.IpcHandler.
QML_FILES := $(shell find src -type f -name '*.qml' ! -path 'src/ipc/KamaShellIpc.qml' | sort)
PYTHON_FILES := $(shell find scripts -type f -name '*.py' | sort)
BASH_FILES := run.sh \
	scripts/copy-screenshot-to-clipboard.sh \
	sessions/kama-shell-session-common.sh \
	sessions/kama-shell-session \
	sessions/kama-shell-debug-session \
	sessions/start-kama-shell-session \
	sessions/start-kama-shell-debug-session

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  run    - Lancer le shell (via run.sh)"
	@echo "  check  - Vérifier la syntaxe QML (requiert qmllint)"
	@echo "  test   - Exécuter les vérifications QML, shell, Python et packaging"
	@echo "  fmt    - Formater le code QML (requiert qmlformat)"
	@echo "  install-session        - Installer la session Wayland standard dans $(SESSION_DIR)"
	@echo "  install-session-debug  - Installer la session Wayland debug dans $(SESSION_DIR)"

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

install-session:
	install -d "$(BIN_DIR)"
	set -e; \
	tmp="$$(mktemp)"; \
	trap 'rm -f "$$tmp"' EXIT; \
	sed 's|@PREFIX@|$(PREFIX)|g' sessions/kama-shell.desktop > "$$tmp"; \
	$(SUDO) install -D -m 644 "$$tmp" "$(SESSION_DIR)/kama-shell.desktop"
	install -m 755 sessions/start-kama-shell-session "$(BIN_DIR)/start-kama-shell-session"
	install -m 644 sessions/kama-shell-session-common.sh "$(BIN_DIR)/kama-shell-session-common.sh"
	sed '0,/__KAMA_SHELL_APP_DIR__/s||$(CURDIR)|' sessions/kama-shell-session > "$(BIN_DIR)/kama-shell-session"
	chmod 755 "$(BIN_DIR)/kama-shell-session"

install-session-debug:
	set -e; \
	tmp="$$(mktemp)"; \
	trap 'rm -f "$$tmp"' EXIT; \
	sed 's|@PREFIX@|$(SYSTEM_PREFIX)|g' sessions/kama-shell-debug.desktop > "$$tmp"; \
	$(SUDO) install -D -m 644 "$$tmp" "$(SESSION_DIR)/kama-shell-debug.desktop"
	$(SUDO) install -D -m 755 sessions/start-kama-shell-debug-session "$(SYSTEM_BIN_DIR)/start-kama-shell-debug-session"
	$(SUDO) install -D -m 644 sessions/kama-shell-session-common.sh "$(SYSTEM_BIN_DIR)/kama-shell-session-common.sh"
	set -e; \
	tmp="$$(mktemp)"; \
	trap 'rm -f "$$tmp"' EXIT; \
	sed '0,/__KAMA_SHELL_APP_DIR__/s||$(CURDIR)|' sessions/kama-shell-debug-session > "$$tmp"; \
	$(SUDO) install -D -m 755 "$$tmp" "$(SYSTEM_BIN_DIR)/kama-shell-debug-session"
