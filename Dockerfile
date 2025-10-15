# Use debian stable as the base image
FROM debian:stable-slim

# Avoid prompts from apt during build
ARG DEBIAN_FRONTEND=noninteractive

# Define default versions for tools needed to install Golang, Protoc, Plugins and the PATH
# https://packages.debian.org/stable/curl
# renovate: release=stable depName=curl
ARG CURL_VERSION=8.14.1-2
# https://packages.debian.org/stable/git
# renovate: release=stable depName=git
ARG GIT_VERSION=1:2.47.3-0+deb13u1
# https://packages.debian.org/stable/make
# renovate: release=stable depName=make
ARG MAKE_VERSION=4.4.1-2
# https://packages.debian.org/stable/upzip
# renovate: release=stable depName=unzip
ARG UNZIP_VERSION=6.0-29
# https://packages.debian.org/stable/ca-certificates
# renovate: release=stable depName=ca-certificates
ARG CA_CERTIFICATES_VERSION=20250419
# https://packages.debian.org/stable/gnupg
# renovate: release=stable depName=gnupg
ARG GNUPG_VERSION=2.4.7-21
# https://deb.nodesource.com/
# renovate: datasource=node-version depName=node packageName=node
ARG NODE_SETUP_VERSION=22.x
# https://packages.debian.org/stable/nodejs
# renovate: release=stable depName=nodejs
ARG NODE_VERSION=22.13.1-1nodesource1
# https://github.com/golang/go/tags
# renovate: datasource=golang-version depName=go packageName=go
ARG GO_VERSION=1.25.0

# Defined default version for Protoc and Plugins
# https://github.com/protocolbuffers/protobuf
# renovate: datasource=github-releases depName=protoc packageName=protocolbuffers/protobuf
ARG PROTOC_VERSION=v33.0
# https://pkg.go.dev/google.golang.org/protobuf/cmd/protoc-gen-go?tab=versions
# renovate: datasource=go depName=protoc-gen-go packageName=google.golang.org/protobuf/cmd/protoc-gen-go
ARG PROTOC_GEN_GO_VERSION=1.36.8
# https://pkg.go.dev/google.golang.org/grpc/cmd/protoc-gen-go-grpc?tab=versions
# renovate: datasource=go depName=protoc-gen-go-grpc packageName=google.golang.org/grpc/cmd/protoc-gen-go-grpc
ARG PROTOC_GEN_GO_GRPC_VERSION=1.5.1
# https://pkg.go.dev/github.com/valentin-kaiser/protoc-gen-jrpc?tab=versions
# renovate: datasource=go depName=protoc-gen-jrpc packageName=github.com/valentin-kaiser/protoc-gen-jrpc
ARG PROTOC_GEN_GO_JRPC_VERSION=0.0.4
# https://github.com/protocolbuffers/protobuf-javascript/releases
# renovate: datasource=github-releases depName=protobuf-javascript packageName=protocolbuffers/protobuf-javascript
ARG PROTOBUF_JAVASCRIPT_VERSION=3.21.4
# https://github.com/grpc/grpc-web/releases
# renovate: datasource=github-releases depName=grpc-web packageName=grpc/grpc-web
ARG GRPC_WEB_VERSION=2.0.0
# https://www.npmjs.com/package/ts-proto
# renovate: datasource=npm depName=ts-proto packageName=ts-proto
ARG TS_PROTO_VERSION=2.4.0
# https://github.com/pseudomuto/protoc-gen-doc/releases
# renovate: datasource=github-releases depName=protoc-gen-doc packageName=pseudomuto/protoc-gen-doc
ARG PROTOC_GEN_DOC_VERSION=1.5.1

# Set environment variables for Golang, Protoc, Plugins and the PATH
ENV INSTALL_DIR=/usr/local
ENV GOPATH=$INSTALL_DIR
ENV GOROOT=$INSTALL_DIR/go
ENV GO111MODULE=on 
ENV PATH=$PATH:$INSTALL_DIR:$GOROOT/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mkdir -p /app && \
    mkdir -p $INSTALL_DIR/bin && \
    mkdir -p /etc/apt/keyrings/

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl=${CURL_VERSION} git=${GIT_VERSION} make=${MAKE_VERSION} unzip=${UNZIP_VERSION} ca-certificates=${CA_CERTIFICATES_VERSION} gnupg=${GNUPG_VERSION}

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_SETUP_VERSION} | bash - && \
    apt-get install -y --no-install-recommends nodejs=${NODE_VERSION}

RUN rm -rf /var/lib/apt/lists/*

# Install Golang
RUN curl -O https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -xzf go${GO_VERSION}.linux-amd64.tar.gz -C /usr/local && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

# Install Protocol Buffers Compiler
RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION#v}/protoc-${PROTOC_VERSION#v}-linux-x86_64.zip && \
    unzip protoc-${PROTOC_VERSION#v}-linux-x86_64.zip -d $INSTALL_DIR && \
    rm protoc-${PROTOC_VERSION#v}-linux-x86_64.zip

# Install ProtoC-Gen-Go plugins
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v${PROTOC_GEN_GO_VERSION} && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v${PROTOC_GEN_GO_GRPC_VERSION} && \
    go install github.com/valentin-kaiser/protoc-gen-jrpc/cmd/protoc-gen-go-jrpc@v${PROTOC_GEN_GO_JRPC_VERSION}

# Install GRPC-Web
RUN curl -LO https://github.com/grpc/grpc-web/releases/download/${GRPC_WEB_VERSION}/protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 && \
    chmod +x protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 && \
    mv protoc-gen-grpc-web-${GRPC_WEB_VERSION}-linux-x86_64 $INSTALL_DIR/bin/protoc-gen-grpc-web

# Install Protobuf for JavaScript
RUN curl -LO https://github.com/protocolbuffers/protobuf-javascript/releases/download/v${PROTOBUF_JAVASCRIPT_VERSION}/protobuf-javascript-${PROTOBUF_JAVASCRIPT_VERSION}-linux-x86_64.tar.gz && \
    tar -xzf protobuf-javascript-${PROTOBUF_JAVASCRIPT_VERSION}-linux-x86_64.tar.gz -C $INSTALL_DIR && \
    rm protobuf-javascript-${PROTOBUF_JAVASCRIPT_VERSION}-linux-x86_64.tar.gz

# Install ts-proto globally
RUN npm install -g ts-proto@${TS_PROTO_VERSION}

# Install Protoc-Gen-Doc
RUN curl -LO https://github.com/pseudomuto/protoc-gen-doc/releases/download/v${PROTOC_GEN_DOC_VERSION}/protoc-gen-doc_${PROTOC_GEN_DOC_VERSION}_linux_amd64.tar.gz && \
    tar -xzf protoc-gen-doc_${PROTOC_GEN_DOC_VERSION}_linux_amd64.tar.gz -C $INSTALL_DIR/bin && \
    chmod +x $INSTALL_DIR/bin/protoc-gen-doc && \
    rm protoc-gen-doc_${PROTOC_GEN_DOC_VERSION}_linux_amd64.tar.gz

# # Define a basic healthcheck (Example: For a web server, replace with actual server check command)
HEALTHCHECK --interval=10s --timeout=10s --start-period=5s CMD [ "protoc", "--version" ]

#checkov:skip=CKV_DOCKER_3:USER is not supported with github actions

# Set the working directory
WORKDIR /app

# Define the entrypoint
ENTRYPOINT ["/bin/bash", "-l", "-c"]
