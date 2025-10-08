# -------- Settings --------
PROTOC ?= protoc

# Paths
GO_GEN_DIR   = ./gen/go
TS_GEN_DIR   = ./gen/ts

# Protos
PROTO_FILES := $(wildcard *.proto)
PROTO_PATH  := $(shell pwd)
PROTOC_GEN_TS_PROTO ?= /usr/lib/node_modules/ts-proto/protoc-gen-ts_proto

# -------- Targets --------
.PHONY: clean proto proto-go proto-ts

proto: clean proto-go proto-ts

proto-go:
	@mkdir -p $(GO_GEN_DIR)
	$(PROTOC) -I $(PROTO_PATH) \
	  --go_out=$(GO_GEN_DIR) \
	  --go_opt=module=protocdock \
	  --go-jrpc_out=$(GO_GEN_DIR) \
	  --go-jrpc_opt=module=protocdock \
	  $(PROTO_FILES)

proto-ts:
	@mkdir -p $(TS_GEN_DIR)
	$(PROTOC) -I $(PROTO_PATH) \
	  --plugin=$(PROTOC_GEN_TS_PROTO) \
	  --ts_proto_out=$(TS_GEN_DIR) \
	  --ts_proto_opt=esModuleInterop=true,useJsonName=true,outputServices=false,oneof=unions,exportCommonSymbols=false \
	  $(PROTO_FILES)

clean:
	rm -rf ./gen