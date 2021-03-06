FROM arm64v8/golang:1.10-alpine AS go-builder

ENV DOCKER_GEN_VERSION=0.7.4

# Install build dependencies for docker-gen
RUN apk add --update \
    curl \
    gcc \
    git \
    make \
    musl-dev

# Build docker-gen
RUN go get github.com/jwilder/docker-gen \
    && cd /go/src/github.com/jwilder/docker-gen \
    && git checkout $DOCKER_GEN_VERSION \
    && make get-deps \
    && make all

FROM arm64v8/alpine:3.8

LABEL maintainer="Lukas Stiebellehner"

ENV DEBUG=false \
    DOCKER_HOST=unix:///var/run/docker.sock

# Install packages required by the image
RUN apk add --update \
    bash \
    ca-certificates \
    curl \
    jq \
    openssl \
    && rm /var/cache/apk/*

# Install docker-gen from build stage
COPY --from=go-builder /go/src/github.com/jwilder/docker-gen/docker-gen /usr/local/bin/

# Install 
COPY /install.sh /app/install.sh
RUN chmod +rx /app/install.sh \
    && sync \
    && /app/install.sh \
    && rm -f /app/install.sh

COPY /app/ /app/

WORKDIR /app

ENTRYPOINT [ "/bin/bash", "/app/entrypoint.sh" ]
CMD [ "/bin/bash", "/app/start.sh" ]
