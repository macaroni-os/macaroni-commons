BACKEND?=dockerv3
CONCURRENCY?=1
PACKAGES?=

# Abs path only. It gets copied in chroot in pre-seed stages
LUET?=/usr/bin/luet-build
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DESTINATION?=$(ROOT_DIR)/output
COMPRESSION?=zstd
export TREE?=$(ROOT_DIR)/packages
REPO_CACHE?=quay.io/geaaru/macaroni-commons-amd64-cache
export REPO_CACHE
BUILD_ARGS?=--pull --no-spinner
GENIDX_ARGS?=--only-upper-level --compress=false
SUDO?=
VALIDATE_OPTIONS?=
ARCH?=amd64
REPO_NAME?=macaroni-commons
REPO_DESC?=Macaroni OS Commons
REPO_URL??=https://dl.macaronios.org/repos/macaroni-commons/
REPO_VALUES?=
export REPO_VALUES
CONFIG?=--config conf/luet.yaml

ifneq ($(strip $(REPO_CACHE)),)
  BUILD_ARGS+=--image-repository $(REPO_CACHE)
endif

ifneq ($(strip $(REPO_VALUES)),)
  BUILD_ARGS+=--values $(REPO_VALUES)
endif

ifneq ($(strip $(CONFIG)),)
  BUILD_ARGS+=$(CONFIG)
endif

.PHONY: all
all: build

.PHONY: clean
clean:
	rm -rf build/ *.tar *.metadata.yaml

.PHONY: build
build: clean
	mkdir -p $(ROOT_DIR)/build
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) $(PACKAGES) --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: build-all
build-all: clean
	mkdir -p $(ROOT_DIR)/build
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) --all --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)
	rm -rf $(ROOT_DIR)/build/*.image.tar

.PHONY: rebuild
rebuild:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) $(PACKAGES) --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild-all
rebuild-all:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --tree=$(TREE) --all --destination $(ROOT_DIR)/build --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: genidx
genidx:
	$(SUDO) $(LUET) tree genidx $(GENIDX_ARGS) --tree=$(TREE)

.PHONY: create-repo
create-repo: genidx
	$(LUET) create-repo $(CONFIG) --tree "$(TREE)" \
    --output $(DESTINATION) \
    --packages $(DESTINATION) \
    --name "$(REPO_NAME)" \
    --descr "$(REPO_DESC) $(ARCH)" \
    --urls "$(REPO_URL)" \
    --tree-compression $(COMPRESSION) \
    --tree-filename tree.tar.zst \
    --with-compilertree \
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

repository/macaroni-funtoo:
	git clone -b master --single-branch https://github.com/geaaru/luet-funtoo $(ROOT_DIR)/repository/macaroni-funtoo

.PHONY: validate
validate: repository repository/mottainai repository/macaroni-funtoo
	$(LUET) tree validate --tree $(ROOT_DIR)/repository --tree $(TREE) $(VALIDATE_OPTIONS)
