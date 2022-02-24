ARG GO_VERSION=1.17.5
FROM golang:$GO_VERSION-bullseye as build

ENV HOME="/opt/algorand"
ENV BIN_DIR="$HOME/node"
ENV ALGORAND_DATA="$HOME/node/data"
ENV PATH="$BIN_DIR:${PATH}"

# Basic dependencies.
ENV DEBIAN_FRONTEND noninteractive
# dependencies = patch + those listed here: https://github.com/algorand/go-algorand/blob/rel/stable/scripts/install_linux_deps.sh#L17
# Note that those get installed through configure_dev.sh anyway, but if we're rebuilding locally - for example to test out
# different branches -  it's faster to have them installed here and be cached
RUN apt-get update && apt-get install -y patch libtool libboost-math-dev expect jq autoconf shellcheck sqlite3 python3-venv

# Install algod binaries.
ARG URL="https://github.com/algorand/go-algorand"
ARG BRANCH="rel/stable"
RUN echo "Installing from source. ${URL} -- ${BRANCH}"

RUN git clone --single-branch --branch "${BRANCH}" "${URL}" /src
WORKDIR /src
RUN ./scripts/configure_dev.sh
RUN make build
RUN ./scripts/dev_install.sh -p ${BIN_DIR} 

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

ENV HOME="/opt/algorand"
ENV BIN_DIR="$HOME/node"
ENV ALGORAND_DATA="$HOME/node/data"
ENV PATH="$BIN_DIR:${PATH}"

COPY --from=build /opt/algorand /opt/algorand

# Start algod
CMD ["/opt/algorand/start_algod.sh"]
