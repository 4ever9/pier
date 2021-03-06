
SHELL := /bin/bash
CURRENT_PATH = $(shell pwd)
APP_NAME = pier
APP_VERSION = 0.4.8

# build with verison infos
VERSION_DIR = github.com/meshplus/${APP_NAME}
BUILD_DATE = $(shell date +%FT%T)
GIT_COMMIT = $(shell git log --pretty=format:'%h' -n 1)
GIT_BRANCH = $(shell git rev-parse --abbrev-ref HEAD)

LDFLAGS += -X "${VERSION_DIR}.BuildDate=${BUILD_DATE}"
LDFLAGS += -X "${VERSION_DIR}.CurrentCommit=${GIT_COMMIT}"
LDFLAGS += -X "${VERSION_DIR}.CurrentBranch=${GIT_BRANCH}"
LDFLAGS += -X "${VERSION_DIR}.CurrentVersion=${APP_VERSION}"

STATIC_LDFLAGS += ${LDFLAGS}
STATIC_LDFLAGS += -linkmode external -extldflags -static

GO = GO111MODULE=on go
TEST_PKGS := $(shell $(GO) list ./... | grep -v 'contracts' | grep -v 'mock_*')

RED=\033[0;31m
GREEN=\033[0;32m
BLUE=\033[0;34m
NC=\033[0m

.PHONY: test

help: Makefile
	@echo "Choose a command run:"
	@sed -n 's/^##//p' $< | column -t -s ':' | sed -e 's/^/ /'

## make test: Run go unittest
test:
	go generate ./...
	@$(GO) test ${TEST_PKGS} -count=1

## make test-cover: Test project with cover
test-cover:
	@$(GO) test -coverprofile cover.out ${TEST_PKGS}
	$(GO) tool cover -html=cover.out -o cover.html

packr:
	cd internal/repo && packr

prepare:
	cd scripts && bash prepare.sh

## make install: Go install the project (hpc)
install: packr
	$(GO) install -ldflags '${LDFLAGS}' ./cmd/${APP_NAME}
	@printf "${GREEN}Build pier successfully${NC}\n"

docker-build: packr
	$(GO) install -ldflags '${STATIC_LDFLAGS}' ./cmd/${APP_NAME}
	@echo "Build pier successfully"

## make build-linux: Go build linux executable file
build-linux:
	cd scripts && bash cross_compile.sh linux-amd64 ${CURRENT_PATH}

## make linter: Run golanci-lint
linter:
	golangci-lint run -E goimports --skip-dirs-use-default -D staticcheck
