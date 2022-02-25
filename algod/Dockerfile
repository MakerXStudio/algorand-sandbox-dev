ARG GO_VERSION=1.17.5
FROM golang:$GO_VERSION-bullseye as build

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

ENV BASE_DIR="/opt/algorand"
ENV BIN_DIR="$BASE_DIR/bin"
ENV PATH="$BIN_DIR:${PATH}"

RUN ./scripts/dev_install.sh -p ${BIN_DIR}

# Configure network
ARG ALGOD_PORT="4001"
ARG KMD_PORT="4002"
ARG TOKEN="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
ARG TEMPLATE="DevModeNetwork.json"

COPY ["$TEMPLATE", "${BASE_DIR}/"]

ENV NETWORK_DIR="$BASE_DIR/testnetwork"
ENV NODE_DIR="${NETWORK_DIR}/Node"
ENV KMD_DATA="${NODE_DIR}/kmd-v0.5"
RUN goal network create -n sandnet -r "${NETWORK_DIR}" -t "${BASE_DIR}/${TEMPLATE}"
RUN echo $TOKEN > "${NODE_DIR}/algod.token"
RUN echo $TOKEN > "${KMD_DATA}/kmd.token"
RUN echo "{ \"Version\": 12, \"GossipFanout\": 1, \"EndpointAddress\": \"0.0.0.0:${ALGOD_PORT}\", \"DNSBootstrapID\": \"\", \"IncomingConnectionsLimit\": 0, \"Archival\":false, \"isIndexerActive\":false, \"EnableDeveloperAPI\":true}" > "${NODE_DIR}/config.json"
RUN echo "{ \"address\":\"0.0.0.0:${KMD_PORT}\",  \"allowed_origins\":[\"*\"]}" > "${KMD_DATA}/kmd_config.json"

COPY ["start.sh", "${BIN_DIR}/"]
RUN chmod +x "${BIN_DIR}/start.sh"


FROM debian:bullseye-slim

ENV PATH="/opt/algorand/bin:${PATH}" \
    ALGORAND_DATA="/opt/algorand/testnetwork/Node" \
    KMD_DATA="/opt/algorand/testnetwork/Node/kmd-v0.5"

COPY --from=build /opt/algorand /opt/algorand

# 9392 = default port for tealdbg
EXPOSE $ALGOD_PORT $KMD_PORT 9392

# Start algod
CMD ["start.sh"]
