ARG GO_VERSION=1.17.5
FROM golang:$GO_VERSION-alpine as build

ENV HOME /opt/indexer
WORKDIR /opt/indexer

# Basic dependencies.
RUN apk add --no-cache git bzip2 make bash libtool boost-dev autoconf automake g++ patch

# Install indexer binaries.
ARG URL="https://github.com/algorand/indexer"
ARG BRANCH="master"

RUN echo "Installing from source. ${URL} -- ${BRANCH}"
RUN git clone --single-branch --branch "${BRANCH}" "${URL}" /opt/indexer
RUN make

FROM alpine:latest

# install runtime dependencies
RUN apk add --no-cache bash libstdc++
# copy build results
COPY --from=build /opt/indexer/cmd/algorand-indexer/algorand-indexer /tmp/

ARG INDEXER_PORT="8980"
ARG ALGOD_PORT="4001"
ARG TOKEN="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

ENV INDEXER_PORT=${INDEXER_PORT} \
    ALGOD_PORT=${ALGOD_PORT} \
    ALGOD_TOKEN=${TOKEN} \
    INDEXER_ENABLE_ALL_PARAMETERS=true \
    INDEXER_DATA=/tmp/indexer-data

RUN mkdir -p ${INDEXER_DATA}

EXPOSE $INDEXER_PORT

COPY ["start.sh", "/tmp/"]
CMD ["/tmp/start.sh"]
