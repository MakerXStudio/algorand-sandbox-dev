ARG GO_VERSION=1.17.5
FROM golang:$GO_VERSION-bullseye as build

ENV HOME="/opt/algorand"
ENV BIN_DIR="$HOME/node"
ENV ALGORAND_DATA="$HOME/node/data"
ENV PATH="$BIN_DIR:${PATH}"

# Basic dependencies.
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y apt-utils curl git git-core bsdmainutils python3 patch

# Install algod binaries.
ARG URL="https://github.com/algorand/go-algorand"
ARG BRANCH="master"
RUN echo "Installing from source. ${URL} -- ${BRANCH}"

RUN git clone --single-branch --branch "${BRANCH}" "${URL}" /src
WORKDIR /src
RUN ./scripts/configure_dev.sh
COPY ["reach2.patch", "./"]
RUN patch -p1 < reach2.patch
RUN make build
RUN ./scripts/dev_install.sh -p ${BIN_DIR} 
WORKDIR $HOME
RUN rm -rf /src
RUN algod -v

# Configure network
ARG ALGOD_PORT="4001"
ARG KMD_PORT="4002"
ARG TOKEN="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
ARG TEMPLATE="DevModeNetwork.json"

COPY ["$TEMPLATE", "setup.py", "/tmp/"]

RUN /tmp/setup.py \
 --bin-dir "$BIN_DIR" \
 --data-dir "$ALGORAND_DATA" \
 --start-script "${HOME}/start_algod.sh" \
 --network-dir "${HOME}/testnetwork" \
 --network-template "/tmp/${TEMPLATE}" \
 --network-token "${TOKEN}" \
 --algod-port "${ALGOD_PORT}" \
 --kmd-port "${KMD_PORT}" \
 --bootstrap-url "" \
 --genesis-file ""

FROM debian:bullseye-slim

COPY --from=build /opt/algorand /opt/algorand

# Start algod
CMD ["/opt/algorand/start_algod.sh"]
