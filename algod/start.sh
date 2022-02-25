#!/bin/bash

set -eu

# run kmd in the background
kmd -d $KMD_DATA -t 0 &
# switch to running algod as main process
exec algod
