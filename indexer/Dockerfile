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
COPY ["fastFollowLoop.patch", "./"]
RUN patch -p1 < fastFollowLoop.patch
RUN make

FROM alpine:latest

# install runtime dependencies
RUN apk add --no-cache bash libstdc++
# copy build results
COPY --from=build /opt/indexer/cmd/algorand-indexer/algorand-indexer /tmp/

COPY ["start.sh", "/tmp/"]
CMD ["/tmp/start.sh"]
