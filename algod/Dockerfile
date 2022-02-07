ARG GO_VERSION=1.17.5
FROM golang:$GO_VERSION

RUN echo "Installing from source. ${URL} -- ${BRANCH}"
ENV BIN_DIR="$HOME/node"
ENV ALGORAND_DATA="/opt/data"

# Basic dependencies.
ENV HOME /opt
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y apt-utils curl git git-core bsdmainutils python3 patch

# Install algod binaries.
ARG URL="https://github.com/algorand/go-algorand"
ARG BRANCH="master"
ARG SHA=

RUN git clone --single-branch --branch "${BRANCH}" "${URL}" /tmp/go-algorand
WORKDIR /tmp/go-algorand
RUN ./scripts/configure_dev.sh
COPY ["reach2.patch", "./"]
RUN patch -p1 < reach2.patch
RUN make build
RUN ./scripts/dev_install.sh -p ${BIN_DIR} 
RUN $BIN_DIR/algod -v

# RUN /tmp/install.sh \
#     -d "${BIN_DIR}" \
#     -u "${URL}" \
#     -b "${BRANCH}" \
#     -s "${SHA}"

# Configure network
ARG ALGOD_PORT="4001"
ARG KMD_PORT="4002"
ARG TOKEN="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
ARG TEMPLATE="DevModeNetwork.json"

COPY ["$TEMPLATE", "setup.py", "/tmp/"]

RUN /tmp/setup.py \
 --bin-dir "$BIN_DIR" \
 --data-dir "$ALGORAND_DATA" \
 --start-script "/opt/start_algod.sh" \
 --network-dir "/opt/testnetwork" \
 --network-template "/tmp/${TEMPLATE}" \
 --network-token "${TOKEN}" \
 --algod-port "${ALGOD_PORT}" \
 --kmd-port "${KMD_PORT}" \
 --bootstrap-url "" \
 --genesis-file ""

ENV PATH="$BIN_DIR:${PATH}"
WORKDIR /opt/data

# Start algod
CMD ["/opt/start_algod.sh"]
