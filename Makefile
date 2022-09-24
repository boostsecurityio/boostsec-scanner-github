#
# Makefile config
#
MAKEFLAGS       += --warn-undefined-variables
SHELL           := /usr/bin/env bash
.DEFAULT_GOAL   := help
.SHELLFLAGS     := -e -o pipefail -c
.DELETE_ON_ERROR:
.SUFFIXES:
.NOTPARALLEL:


#
# Makefile help page
#
define HELP_USAGE
	@echo Usage: make help
endef

define HELP_ERROR
@echo
	@if [ -n "$(ERROR)" ]; then \
	printf "\033[31m%s\033[0m\n" "$(ERROR)"; \
	echo; \
	exit 1; \
	fi
endef

# @echo Variables:
# @echo
# @printf "  \033[36m%-15s\033[0m %-35s %s\n" "VARNAME" "VAR DESCRIPTION" "VALUE"
define HELP_PREFIX
	@echo
	@echo Variables:
	@echo
endef

define HELP_TARGETS
	@echo
	@echo Targets:
	@echo
	@grep -hE '^[a-zA-Z_\-\.]+(.%)?:.*?## .*$$' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
endef

define usage
	$(HELP_USAGE)
	$(HELP_PREFIX)
	$(HELP_TARGETS)
	$(HELP_ERROR)
endef

#
# Default variables
#
CI           ?=
COMMIT       ?= $(shell git rev-parse HEAD)
ERROR        ?=
PROJECT_ROOT ?= $(shell git rev-parse --show-toplevel)
PROJECT_NAME ?= $(shell basename ${PROJECT_ROOT})

TEST_IMAGE   ?= ${PROJECT_NAME}:test

#
# Targets
#
.PHONY: .phony
.phony:

help:  ## Display usage information
help: .phony
	$(usage)


test:  ## Run test suite
test: jobs := 4
test: args :=
test:
	@docker run --rm -ti -v $${PWD}:/app ${TEST_IMAGE} --jobs ${jobs} ${args} tests

test.build:  ## Build test image
test.build:
	@docker build -f tests/Dockerfile -t ${TEST_IMAGE} .

test.shell:  ## Execute shell in test image
test.shell: test.build
	docker run --rm -ti -v $${PWD}:/app --entrypoint bash ${TEST_IMAGE}
