BACKEND?=dockerv2
CONCURRENCY?=1

# Abs path only. It gets copied in chroot in pre-seed stages
LUET?=/usr/bin/luet-build
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DESTINATION?=$(ROOT_DIR)/output
COMPRESSION?=zstd
REPO_NAME?=macaroni-commons
REPO_EXTRA?=
CLEAN?=true
TREE?=./packages
BUILD_ARGS?= --pull --image-repository quay.io/geaaru/macaroni-commons-amd64-cache --only-target-package
CONFIG?= --config conf/luet.yaml
export LUET_BIN?=$(LUET)

.PHONY: all
all: build

.PHONY: clean
clean:
	rm -rf build/ *.tar *.metadata.yaml

.PHONY: build
build: clean
	mkdir -p $(ROOT_DIR)/build
	$(LUET) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) $(PACKAGES) --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: build-all
build-all: clean
	mkdir -p $(ROOT_DIR)/build
	$(LUET) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) --all --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)
	rm -rf $(ROOT_DIR)/build/*.image.tar

.PHONY: rebuild
rebuild:
	$(LUET) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) $(PACKAGES) --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild-all
rebuild-all:
	$(LUET) build $(BUILD_ARGS) $(CONFIG) --tree=$(TREE) --all --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: create-repo
create-repo:
	$(LUET) create-repo $(CONFIG) --tree "$(TREE)" \
    --output $(ROOT_DIR)/build \
    --packages $(ROOT_DIR)/build \
    --name "$(REPO_NAME)" \
    --descr "Macaroni Commons $(EXTRA)Official Repository" \
    --urls "https://cdn.macaroni.funtoo.org/mottainai/$(REPO)" \
    --tree-compression $(COMPRESSION) \
    --tree-filename tree.tar \
    --meta-compression $(COMPRESSION) \
    --type http

.PHONY: serve-repo
serve-repo:
	LUET_NOLOCK=true $(LUET) serve-repo --port 8000 --dir $(ROOT_DIR)/build

.PHONY: autobump
autobump:
	TREE_DIR=$(ROOT_DIR) $(LUET) autobump-github
	
.PHONY: auto-bump
auto-bump: autobump

repository:
	mkdir -p $(ROOT_DIR)/repository

repository/mottainai:
	git clone -b master --single-branch https://github.com/MottainaiCI/repo-stable $(ROOT_DIR)/repository/mottainai

repository/geaaru:
	git clone -b master --single-branch https://github.com/geaaru/luet-specs $(ROOT_DIR)/repository/geaaru

repository/macaroni-funtoo:
	git clone -b systemd --single-branch https://github.com/geaaru/luet-funtoo $(ROOT_DIR)/repository/macaroni-funtoo

.PHONY: validate
validate: repository repository/mottainai repository/geaaru repository/macaroni-funtoo
	$(LUET) tree validate --tree $(ROOT_DIR)/repository --tree $(TREE) $(VALIDATE_OPTIONS)
