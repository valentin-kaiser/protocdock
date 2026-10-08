# Define default versions for Golang, Protoc and Plugins
# https://github.com/golang/go/tags
# renovate: datasource=golang-version depName=go packageName=go
ARG GO_VERSION=1.27.2
ARG ALPINE_VERSION=3.24

# Defined default version for Protoc and Plugins
# https://github.com/protocolbuffers/protobuf
# renovate: datasource=github-releases depName=protoc packageName=protocolbuffers/protobuf
ARG PROTOC_VERSION=v36.2
# https://pkg.go.dev/google.golang.org/protobuf/cmd/protoc-gen-go?tab=versions
# renovate: datasource=go depName=protoc-gen-go packageName=google.golang.org/protobuf/cmd/protoc-gen-go
ARG PROTOC_GEN_GO_VERSION=1.36.12
# https://pkg.go.dev/google.golang.org/grpc/cmd/protoc-gen-go-grpc?tab=versions
# renovate: datasource=go depName=protoc-gen-go-grpc packageName=google.golang.org/grpc/cmd/protoc-gen-go-grpc
ARG PROTOC_GEN_GO_GRPC_VERSION=1.6.2
# https://pkg.go.dev/github.com/valentin-kaiser/protoc-gen-jrpc?tab=versions
# renovate: datasource=go depName=protoc-gen-jrpc packageName=github.com/valentin-kaiser/protoc-gen-jrpc
ARG PROTOC_GEN_GO_JRPC_VERSION=v1.1.1
# https://pkg.go.dev/github.com/valentin-kaiser/protoc-gen-xrpc?tab=versions
# renovate: datasource=go depName=protoc-gen-xrpc packageName=github.com/valentin-kaiser/protoc-gen-xrpc
ARG PROTOC_GEN_GO_XRPC_VERSION=v0.0.1
# https://github.com/protocolbuffers/protobuf-javascript/releases
# renovate: datasource=github-releases depName=protobuf-javascript packageName=protocolbuffers/protobuf-javascript
ARG PROTOBUF_JAVASCRIPT_VERSION=4.0.3
# https://github.com/grpc/grpc-web/releases
# renovate: datasource=github-releases depName=grpc-web packageName=grpc/grpc-web
ARG GRPC_WEB_VERSION=2.1.1
# https://www.npmjs.com/package/ts-proto
# renovate: datasource=npm depName=ts-proto packageName=ts-proto
ARG TS_PROTO_VERSION=2.13.0
# https://github.com/pseudomuto/protoc-gen-doc/releases
# renovate: datasource=github-releases depName=protoc-gen-doc packageName=pseudomuto/protoc-gen-doc
ARG PROTOC_GEN_DOC_VERSION=1.5.1

# Stage 1: build the Go plugins as static, stripped binaries
FROM golang:${GO_VERSION}-alpine AS go-plugins
ARG PROTOC_GEN_GO_VERSION
ARG PROTOC_GEN_GO_GRPC_VERSION
ARG PROTOC_GEN_GO_JRPC_VERSION
ARG PROTOC_GEN_GO_XRPC_VERSION
ENV CGO_ENABLED=0 GOBIN=/out
RUN apk add --no-cache git && \
    go install -trimpath -ldflags="-s -w" google.golang.org/protobuf/cmd/protoc-gen-go@v${PROTOC_GEN_GO_VERSION} && \
    go install -trimpath -ldflags="-s -w" google.golang.org/grpc/cmd/protoc-gen-go-grpc@v${PROTOC_GEN_GO_GRPC_VERSION} && \
    go install -trimpath -ldflags="-s -w" github.com/valentin-kaiser/protoc-gen-jrpc/cmd/protoc-gen-go-jrpc@${PROTOC_GEN_GO_JRPC_VERSION} && \
    go install -trimpath -ldflags="-s -w" github.com/valentin-kaiser/protoc-gen-xrpc/cmd/protoc-gen-go-xrpc@${PROTOC_GEN_GO_XRPC_VERSION}

# Stage 2: download the prebuilt release binaries and install ts-proto
FROM node:26-alpine AS downloads
ARG PROTOC_VERSION
ARG PROTOBUF_JAVASCRIPT_VERSION
ARG GRPC_WEB_VERSION
ARG TS_PROTO_VERSION
ARG PROTOC_GEN_DOC_VERSION
RUN apk add --no-cache curl unzip
WORKDIR /dl

# Protocol Buffers Compiler (binary and well-known type includes only)
RUN curl -fsSLO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION#v}/protoc-${PROTOC_VERSION#v}-linux-x86_64.zip && \
    unzip -q protoc-${PROTOC_VERSION#v}-linux-x86_64.zip -d /out && \
    rm -f /out/readme.txt && \
    ls /out/bin/protoc /out/include/google/protobuf/any.proto

# GRPC-Web
RUN curl -fsSL -o /out/bin/protoc-gen-grpc-web https://github.com/grpc/grpc-web/releases/download/${GRPC_WEB_VERSION}/protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 && \
    chmod +x /out/bin/protoc-gen-grpc-web

# Protobuf for JavaScript (only the plugin binary is needed)
RUN curl -fsSL https://github.com/protocolbuffers/protobuf-javascript/releases/download/v${PROTOBUF_JAVASCRIPT_VERSION}/protobuf-javascript-${PROTOBUF_JAVASCRIPT_VERSION}-linux-x86_64.tar.gz | \
    tar -xz -C /out bin/protoc-gen-js

# Protoc-Gen-Doc
RUN curl -fsSL https://github.com/pseudomuto/protoc-gen-doc/releases/download/v${PROTOC_GEN_DOC_VERSION}/protoc-gen-doc_${PROTOC_GEN_DOC_VERSION}_linux_amd64.tar.gz | \
    tar -xz -C /out/bin protoc-gen-doc && \
    chmod +x /out/bin/protoc-gen-doc

# ts-proto (installed to its own prefix, caches and docs removed)
RUN npm install -g --prefix /opt/node ts-proto@${TS_PROTO_VERSION} && \
    npm cache clean --force && \
    find /opt/node -type f \( -name "*.md" -o -name "*.map" -o -name "*.d.ts" -o -name "*.ts.map" \) ! -path "*/ts-proto/build/*" -delete && \
    ln -sf ../lib/node_modules/ts-proto/protoc-gen-ts_proto /opt/node/bin/protoc-gen-ts_proto

# Stage 3: minimal runtime image
FROM alpine:${ALPINE_VERSION}

# bash is required for the login shell entrypoint, gcompat/libstdc++ run the glibc based release binaries,
# nodejs is needed at runtime by ts-proto, git and make are kept for user commands
RUN apk add --no-cache bash git make nodejs gcompat libstdc++

COPY --from=downloads /out/bin/ /usr/local/bin/
COPY --from=downloads /out/include/ /usr/local/include/
COPY --from=downloads /opt/node/lib/node_modules /usr/lib/node_modules
COPY --from=go-plugins /out/ /usr/local/bin/

ENV GOPATH=/usr/local

# Keep ts-proto at the conventional global path /usr/lib/node_modules and expose it on the PATH
RUN ln -s /usr/lib/node_modules/ts-proto/protoc-gen-ts_proto /usr/local/bin/protoc-gen-ts_proto

# Define a basic healthcheck
HEALTHCHECK --interval=10s --timeout=10s --start-period=5s CMD [ "protoc", "--version" ]

#checkov:skip=CKV_DOCKER_3:USER is not supported with github actions

# Set the working directory
WORKDIR /app

# Define the entrypoint
ENTRYPOINT ["/bin/bash", "-l", "-c"]
