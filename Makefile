# Makefile — Kama-Shell automation

.PHONY: run check fmt help

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
	qmllint shell.qml src/

fmt:
	qmlformat -i shell.qml src/
