# Makefile — Kama-Shell automation

.PHONY: run check fmt help install-session

PREFIX ?= $(HOME)/.local
SESSION_DIR ?= $(PREFIX)/share/wayland-sessions
BIN_DIR ?= $(PREFIX)/bin

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  run    - Lancer le shell (via run.sh)"
	@echo "  check  - Vérifier la syntaxe QML (requiert qmllint)"
	@echo "  fmt    - Formater le code QML (requiert qmlformat)"

run:
	./run.sh

check:
	qmllint -I src src/shell.qml src/components/*.qml src/state/*.qml

fmt:
	qmlformat -i src/shell.qml src/

install-session:
	install -d "$(SESSION_DIR)" "$(BIN_DIR)"
	sed 's|@PREFIX@|$(PREFIX)|g' sessions/kama-shell.desktop > "$(SESSION_DIR)/kama-shell.desktop"
	install -m 755 sessions/start-kama-shell-session "$(BIN_DIR)/start-kama-shell-session"
	sed '0,/__KAMA_SHELL_APP_DIR__/s||$(CURDIR)|' sessions/kama-shell-session > "$(BIN_DIR)/kama-shell-session"
	chmod 755 "$(BIN_DIR)/kama-shell-session"
