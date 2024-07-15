#!/usr/bin/make -f

include .env

KEY_GEN = false
BINDIR ?= $(GOPATH)/bin
ETHERMINT_BINARY = ethermintd
ETHERMINT_DIR = ethermint
BUILDDIR ?= $(CURDIR)/build



WORKDIR ?= $(CURDIR)/work_dir
SUDO := $(shell which sudo)



# This version must the same as in docker-compose-full.yml
# TODO add check
KMS_DEV_VERSION ?= v0.7.1

FHEVM_SOLIDITY_REPO ?= fhevm
FHEVM_SOLIDITY_PATH ?= $(WORKDIR)/$(FHEVM_SOLIDITY_REPO)
FHEVM_SOLIDITY_PATH_EXISTS := $(shell test -d $(FHEVM_SOLIDITY_PATH)/.git && echo "true" || echo "false")
FHEVM_SOLIDITY_VERSION ?= V0.5.1

export GO111MODULE = on

# Default target executed when no arguments are given to make.
default_target: all

.PHONY: default_target

# process build tags



###############################################################################
###                                Single validator                         ###
###############################################################################


$(WORKDIR)/:
	$(info WORKDIR)
	mkdir -p $(WORKDIR)

clone-fhevm-solidity: $(WORKDIR)/
	$(info Cloning fhevm-solidity version $(FHEVM_SOLIDITY_VERSION))
	cd $(WORKDIR) && git clone https://github.com/zama-ai/fhevm.git
	cd $(FHEVM_SOLIDITY_PATH) && git checkout $(FHEVM_SOLIDITY_VERSION)

check-fhevm-solidity: $(WORKDIR)/
	$(info check-fhevm-solidity)
ifeq ($(FHEVM_SOLIDITY_PATH_EXISTS), true)
	@echo "fhevm-solidity exists in $(FHEVM_SOLIDITY_PATH)"
	@if [ ! -d $(WORKDIR)/fhevm ]; then \
        echo 'fhevm-solidity is not available in $(WORKDIR)'; \
        echo "FHEVM_SOLIDITY_PATH is set to a custom value"; \
    else \
        echo 'fhevm-solidity is already available in $(WORKDIR)'; \
    fi
else
	@echo "fhevm-solidity does not exist"
	echo "We clone it for you!"
	echo "If you want your own version please update FHEVM_SOLIDITY_PATH pointing to your fhevm-solidity folder!"
	$(MAKE) clone-fhevm-solidity
endif


check-all-test-repo: check-fhevm-solidity

generate-fhe-keys:
	@bash ./scripts/copy_fhe_keys.sh $(KMS_DEV_VERSION) $(PWD)/network-fhe-keys $(PWD)/kms-fhe-keys

run-full:
	$(MAKE) generate-fhe-keys
	@docker compose  -f docker-compose/docker-compose-full.yml  up --detach
	@echo 'sleep a little to let the docker start up'
	sleep 10

stop-full:
	@docker compose  -f docker-compose/docker-compose-full.yml down

TEST_FILE := run_tests.sh
TEST_IF_FROM_REGISTRY := 

run-e2e-test: check-all-test-repo
	@cd $(FHEVM_SOLIDITY_PATH) && npm ci
	@sleep 5
	@./scripts/fund_test_addresses_docker.sh
	@cd $(FHEVM_SOLIDITY_PATH) && cp .env.example .env
	@cd $(FHEVM_SOLIDITY_PATH) && npm i
	@cd $(FHEVM_SOLIDITY_PATH) && ./setup-local-fhevm.sh
	@cd $(FHEVM_SOLIDITY_PATH) && npx hardhat test


prepare-e2e-test: check-all-test-repo
	@cd $(FHEVM_SOLIDITY_PATH) && npm ci
	@sleep 5
	@./scripts/fund_test_addresses_docker.sh
	@cd $(FHEVM_SOLIDITY_PATH) && cp .env.example .env
	@cd $(FHEVM_SOLIDITY_PATH) && npm i
	@cd $(FHEVM_SOLIDITY_PATH) && ./setup-local-fhevm.sh

run-async-test:
	@cd $(FHEVM_SOLIDITY_PATH) && npx hardhat test --grep 'test async decrypt uint8' 

run-true-input-async-test:
	@cd $(FHEVM_SOLIDITY_PATH) && npx hardhat test --grep 'test async decrypt uint64 non-trivial' 

e2e-test:
	@$(MAKE) check-all-test-repo
	$(MAKE) run-full
	$(MAKE) run-e2e-test
	$(MAKE) stop-full

clean:
	$(MAKE) stop-full
	rm -rf $(BUILDDIR)/
	rm -rf $(WORKDIR)/ 
	rm -rf network-fhe-keys
	rm -rf kms-fhe-keys


print-info:
	@echo 'KMS_DEV_VERSION: $(KMS_DEV_VERSION) for KEY_GEN---extracted from Makefile'
	@echo 'FHEVM_SOLIDITY_VERSION: $(FHEVM_SOLIDITY_VERSION) ---extracted from Makefile'
	@bash scripts/get_repository_info.sh fhevm $(FHEVM_SOLIDITY_PATH)