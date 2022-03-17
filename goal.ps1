# Goal is the Algorand CLI: https://developer.algorand.org/docs/clis/goal/goal/
# This is the equivalent of ./sandbox.sh goal ..., but it works cross-platform, and faster
# The container name is as per docker-compose.yml
docker-compose exec algod goal @args

# GOAL is the CLI for interacting Algorand software instance. The binary 'goal' is installed alongside the algod binary and is considered an integral part of the complete installation. The binaries should be used in tandem - you should not try to use a version of goal with a different version of algod.
#
# Usage:
#   goal [flags]
#   goal [command]
#
# Available Commands:
#   account     Control and manage Algorand accounts
#   app         Manage applications
#   asset       Manage assets
#   clerk       Provides the tools to control transactions
#   completion  Shell completion helper
#   help        Help about any command
#   kmd         Interact with kmd, the key management daemon
#   ledger      Access ledger-related details
#   license     Display license information
#   logging     Control and manage Algorand logging
#   network     Create and manage private, multi-node, locally-hosted networks
#   node        Manage a specified algorand node
#   protocols
#   report
#   version     The current version of the Algorand daemon (algod)
#   wallet      Manage wallets: encrypted collections of Algorand account keys
#
# Flags:
#   -d, --datadir stringArray   Data directory for the node
#   -h, --help                  help for goal
#   -k, --kmddir string         Data directory for kmd
#   -v, --version               Display and write current build version and exit
#
# Use "goal [command] --help" for more information about a command.
