PYTHON = python3

VENV = .venv
VENV_PIP = $(VENV)/bin/pip
VENV_PYTHON = $(VENV)/bin/python
VENV_DONE = $(VENV)/.done
VENV_PIP_INSTALL = '.[dev, test]'

PACKAGE_SCRIPT = 'from configparser import RawConfigParser; p = RawConfigParser(); p.read("setup.cfg"); print(p["metadata"]["name"]);'
PACKAGE = $(shell $(PYTHON) -c $(PACKAGE_SCRIPT))

.PHONY: venv
venv: $(VENV_DONE)

.PHONY: pipx
pipx:
	pipx install --editable .

.PHONY: pipx-site-packages
pipx-site-packages:
	pipx install --system-site-packages --editable .

.PHONY: check
check: lint test

.PHONY: lint
lint: lint-flake8 lint-mypy lint-isort

LINT_SOURCES = $(wildcard *.py) tests/

.PHONY: lint-flake8
lint-flake8: $(VENV_DONE)
	$(VENV_PYTHON) -m flake8 $(LINT_SOURCES)

.PHONY: lint-mypy
lint-mypy: $(VENV_DONE)
	$(VENV_PYTHON) -m mypy --show-column-numbers $(LINT_SOURCES)

.PHONY: lint-isort
lint-isort: $(VENV_DONE)
	$(VENV_PYTHON) -m isort --check $(LINT_SOURCES)

.PHONY: test
test: $(VENV_DONE)
	$(VENV_PYTHON) -m pytest $(PYTEST_FLAGS) tests/

.PHONY: readme
readme: INTERACTIVE=$(shell [ -t 0 ] && echo --interactive)
readme: $(VENV_DONE)
	PATH="$(CURDIR)/$(VENV)/bin:$$PATH" \
	$(VENV_PYTHON) cram-noescape.py --indent=4 $(INTERACTIVE) README.md

.PHONY: dist
dist: $(VENV_DONE)
	rm -rf dist/
	$(VENV_PYTHON) -m pep517.build --source --binary --out-dir dist .

.PHONY: twine-upload
twine-upload: dist
	$(VENV_PYTHON) -m twine upload $(wildcard dist/*)

.PHONY: clean
clean:
	git clean -ffdX

$(VENV_DONE): $(MAKEFILE_LIST) setup.py setup.cfg pyproject.toml
	$(PYTHON) -m venv --system-site-packages $(VENV)
	$(VENV_PIP) install -e $(VENV_PIP_INSTALL)
	touch $@
