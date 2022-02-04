ARG GO_VERSION=1.17.5
FROM golang:$GO_VERSION-alpine

ENV HOME /opt/indexer
WORKDIR /opt/indexer

ENV DEBIAN_FRONTEND noninteractive
RUN apk add --no-cache git bzip2 make bash libtool boost-dev autoconf automake g++

# Install indexer binaries.
RUN git clone --single-branch --branch "develop" "https://github.com/algorand/indexer" /opt/indexer
RUN make && cp cmd/algorand-indexer/algorand-indexer /tmp

COPY ["start.sh", "/tmp/"]
CMD ["/tmp/start.sh"]
