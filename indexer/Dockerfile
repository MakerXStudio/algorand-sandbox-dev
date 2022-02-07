ARG GO_VERSION=1.17.5
FROM golang:$GO_VERSION-alpine as build

ENV HOME /opt/indexer
WORKDIR /opt/indexer

# Basic dependencies.
ENV DEBIAN_FRONTEND noninteractive
RUN apk add --no-cache git bzip2 make bash libtool boost-dev autoconf automake g++

# Install indexer binaries.
ARG URL="https://github.com/algorand/indexer"
ARG BRANCH="develop"

RUN echo "Installing from source. ${URL} -- ${BRANCH}"
RUN git clone --single-branch --branch "${BRANCH}" "${URL}" /opt/indexer
RUN make

FROM golang:$GO_VERSION-alpine

# install runtime dependencies
ENV DEBIAN_FRONTEND noninteractive
RUN apk add --no-cache bash libstdc++
# copy build results
COPY --from=build /opt/indexer/cmd/algorand-indexer/algorand-indexer /tmp/

COPY ["start.sh", "/tmp/"]
CMD ["/tmp/start.sh"]
