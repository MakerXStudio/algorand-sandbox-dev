# algorand-sandbox-dev

This repo is loosely based on [Algorand's official sandbox](https://github.com/algorand/sandbox), but solves some performance and experience problems which impact local development and CI/CD usage.

The key problems we resolve are:

* Long build times for CI/CD
* Slow devnet + indexer performance
* Ability to use cross-platform (e.g. on Windows)

This project was developed by [MakerX](https://makerx.com.au/) to help us with our initiatives, but we are happily providing it for the Algorand community to use as Open Source.

[![MakerX logo](logo.png)](https://makerx.com.au/)

## How to use

You'll need [Docker installed](https://docs.docker.com/get-docker/). The following examples also use `docker compose`, which ships with Docker Desktop on Windows and macOS - for Linux users, see the [installation instructions](https://docs.docker.com/compose/install/).

### Option A: With pre-built images from DockerHub

Either save the following as `docker-compose.yaml` locally, or if you've already got a compose setup, just copy in the
services:

```yaml
version: '3'

services:
  algod:
    image: makerxau/algorand-sandbox-dev:latest
    ports:
      - "4001:4001"
      - "4002:4002"
      - "9392:9392"

  indexer:
    image: makerxau/algorand-indexer-dev:latest
    ports:
      - "8980:8980"
    restart: unless-stopped
    environment:
      ALGOD_HOST: "algod"
      POSTGRES_HOST: "indexer-db"
      POSTGRES_PORT: "5432"
      POSTGRES_USER: algorand
      POSTGRES_PASSWORD: algorand
      POSTGRES_DB: indexer_db
    depends_on:
      - indexer-db
      - algod

  indexer-db:
    image: "postgres:13-alpine"
    container_name: "algorand-sandbox-postgres"
    ports:
      - "5433:5432"
    user: postgres
    environment:
      POSTGRES_USER: algorand
      POSTGRES_PASSWORD: algorand
      POSTGRES_DB: indexer_db
```

Then run `docker compose up` in the directory of your compose file. This will pull the pre-built images down from DockerHub.

Currently, the only tags being pushed are `latest`, which are manually triggered builds based on the latest stable 
releases of both [go-algorand](https://github.com/algorand/go-algorand/) and [indexer](https://github.com/algorand/indexer).

Note that when using the `latest` tag, if a new build gets pushed to DockerHub but you have an existing stack,
`docker compose` won't check to see if there's a new build available. To update, stop the running stack and:

    docker compose down
    docker compose pull

This should fetch the latest images and you can start your stack again.

Note in particular that we need to use `down` here, and not just `stop` (which is what ctrl-c will do if you're not running docker compose with the `-d` flag),
a new build will generate a new network genesis, but the database container will still contain data from the previous network.
If you don't remove the container before restarting (e.g. through the `down` command  above), you'll get errors like the following:

    algorand-sandbox-indexer   | {"error":"genesis hash not matching","level":"error","msg":"importer.EnsureInitialImport() error","time":"2022-02-25T01:33:59Z"}
    algorand-sandbox-indexer exited with code 1

### Option B: From this repo

If you want to test out a newer version (e.g. the latest beta version of `go-algorand`), you can check out this repo,
and run your `docker compose` commands from here, the `BRANCH` args in `docker-compose.yaml` control which git branches
of their respective repos get checked out and built.

Also, be careful of the `indexer-db` container persisting after a rebuild, as noted above in Option A, this is even 
more important if you're building/re-building locally.

## Replicating sandbox.sh functionality

There are a number of things that you can do with `sandbox.sh` within the [Algorand Sandbox](https://github.com/algorand/sandbox#algorand-sandbox) that we have created cross-platform equivalents of using [PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/overview?view=powershell-7.2).

### Status

In order to check the status of the running environment, copy [status.ps1](./status.ps1) into your project wherever you put your `docker-compose.yml` file and execute it via `./status.ps1`.

### Reset

In order to reset the environment, copy [reset.ps1](./reset.ps1) into your project wherever you put your `docker-compose.yml` file and execute it via `./reset.ps1`.

### Goal

In order to run a goal command against your algod instance, copy [reset.ps1](./reset.ps1) into your project wherever you put your `docker-compose.yml` file and execute it via `./goal.ps1 {command}` e.g. `./goal.ps1 account list`.

## Getting access to the private key of the faucet account

If you want to use the sandbox then you need to get the private key of the initial wallet so you can transfer ALGOs out of it to other accounts you create. There are two ways to do this:

### Option 1: Manually via goal

> ./goal.ps1 account list
> ./goal.ps1 account export -a {address_from_online_account_from_above_command}

### Option 2: Autoamtically vis kmd API

Needing to do this manual step every time you spin up a new development environment or reset your Sandbox is frustrating. Instead, it's useful to have code that uses the Sandbox APIs to automatically retrieve the private key of the default account. The following `getSandboxDefaultAccount` function (in TypeScript, but equivalent will work with algosdk in other languages) will help you achieve that:

```typescript
// account.ts
import algosdk, { Account, Algodv2 } from 'algosdk'
import { getKmdClient } from './client'

export async function isSandbox(client: Algodv2): Promise<boolean> {
  const params = await client.getTransactionParams().do()

  return params.genesisID === 'devnet-v1' || params.genesisID === 'sandnet-v1'
}

export async function isReachSandbox(client: Algodv2): Promise<boolean> {
  const params = await client.getTransactionParams().do()

  return params.genesisHash === 'lgTq/JY/RNfiTJ6ZcZ/Er8uR775Hk76c7MvHVWjvjCA='
}

export function getAccountFromMnemonic(mnemonic: string): Account {
  return algosdk.mnemonicToSecretKey(mnemonic)
}

export async function getSandboxDefaultAccount(client: Algodv2): Promise<Account> {
  if (!(await isSandbox(client))) {
    throw "Can't get default account from non Sandbox network"
  }

  if (await isReachSandbox(client)) {
    // https://github.com/reach-sh/reach-lang/blob/master/scripts/devnet-algo/algorand_network/FAUCET.mnemonic
    return getAccountFromMnemonic(
      'frown slush talent visual weather bounce evil teach tower view fossil trip sauce express moment sea garbage pave monkey exercise soap lawn army above dynamic'
    )
  }

  const kmd = getKmdClient()
  const wallets = await kmd.listWallets()

  // Sandbox starts with a single wallet called 'unencrypted-default-wallet', with heaps of tokens
  const defaultWalletId = wallets.wallets.filter((w: any) => w.name === 'unencrypted-default-wallet')[0].id

  const defaultWalletHandle = (await kmd.initWalletHandle(defaultWalletId, '')).wallet_handle_token
  const defaultKeyIds = (await kmd.listKeys(defaultWalletHandle)).addresses

  // When you create accounts using goal they get added to this wallet so check for an account that's actually a default account
  let i = 0
  for (i = 0; i < defaultKeyIds.length; i++) {
    const key = defaultKeyIds[i]
    const account = await client.accountInformation(key).do()
    if (account.status !== 'Offline' && account.amount > 1000_000_000) {
      break
    }
  }

  const defaultAccountKey = (await kmd.exportKey(defaultWalletHandle, '', defaultKeyIds[i])).private_key

  const defaultAccountMnemonic = algosdk.secretKeyToMnemonic(defaultAccountKey)
  return getAccountFromMnemonic(defaultAccountMnemonic)
}
```

To get the `Kmd` instance you can use something like this (tweak it based on where you retrieve your ALGOD token and server from):

```typescript
// client.ts
import {Kmd} from 'algosdk'

// KMD client allows you to export private keys, which is useful to get the default account in a sandbox network
export function getKmdClient(): Kmd {
  // We can only use Kmd on the Sandbox otherwise it's not exposed so this makes some assumptions (e.g. same token and server as algod and port 4002)
  return new Kmd(process.env.ALGOD_TOKEN!, process.env.ALGOD_SERVER!, '4002')
}


```

## Motivation

### 1. DevMode and indexer do not play nicely together
Even though Algorand rounds take only a few seconds in normal operations to commit, 
this is too slow for unit testing purposes. Running a local Algorand node (e.g. through ) 
in `DevMode` solves the problem, as outlined [by this comment from go-algorand source code](https://github.com/algorand/go-algorand/blob/d2289a52d517b1e7e0a23b6936305520895d36d5/data/bookkeeping/genesis.go#L78) :

    DevMode defines whether this network operates in a developer mode or not. Developer mode networks
	are a single node network, that operates without the agreement service being active. In lieu of the
	agreement service, a new block is generated each time a node receives a transaction group.

However, currently the `indexer` daemon is unaware of this - regardless of `DevMode` being specified as part of the network genesis 
or not, it executes the [GET /v/2/status/wait-for-block-after/{round}](https://developer.algorand.org/docs/rest-apis/algod/v2/#get-v2statuswait-for-block-afterround) 
API call as part of it's [run-loop](https://github.com/algorand/indexer/blob/4997285179bb1559112c61dbe15ea479176b2c4a/fetcher/fetcher.go#L143).
This is handled by `algod` [here](https://github.com/algorand/go-algorand/blob/d2289a52d517b1e7e0a23b6936305520895d36d5/daemon/algod/api/server/v2/handlers.go#L429) - the key lines are the following:

```go
    // Wait
    select {
    case <-v2.Shutdown:
        return internalError(ctx, err, errServiceShuttingDown, v2.Log)
    case <-time.After(1 * time.Minute):
    case <-ledger.Wait(basics.Round(round + 1)):
    }

    // Return status after the wait
    return v2.GetStatus(ctx)
```

Here, the `round` parameters comes directly from the `GET` route. It thus waits not just for `round` to be committed durably,
but the following round. So the indexer remains one round behind the node it is following. This presents a problem in `DevMode`,
because rounds are not regularly committed every handful of seconds - so if no new transactions are sent, 
then the API call will not return for 1 minute. This is obviously too long when, for example, running unit tests that
rely on querying the indexer.

*Side note: there are other issues here as well, in that once the request returns after 1 minute, it will receive an error
attempting to fetch the next block if no new transactions come in, but that doesn't impact the functionality of the indexer
other than filling up the logs with error messages.*

Inspired by [this patch](https://github.com/reach-sh/reach-lang/blob/4b5f7e48ffc0fac5f77358f9120daa10820fd796/scripts/devnet-algo/reach2.patch#L5) 
in `reachsh` (which they apply as part of building their `devnet-algo` [docker image](https://hub.docker.com/r/reachsh/devnet-algo)),
we apply something similar, but to the `indexer` run-loop (linked above):

```go
--- a/fetcher/fetcher.go	(revision 4997285179bb1559112c61dbe15ea479176b2c4a)
+++ b/fetcher/fetcher.go	(date 1645693170829)
@@ -140,7 +140,7 @@
    aclient := bot.Algod()
    for {
        for retries := 0; retries < 3; retries++ {
-           _, err = aclient.StatusAfterBlock(bot.nextRound).Do(ctx)
+           _, err = aclient.StatusAfterBlock(bot.nextRound - 1).Do(ctx)
            if err != nil {
                // If context has expired.
                if ctx.Err() != nil {
```

This means the indexer is only waiting for the current block to be committed, not the next block.

A more robust solution to the above would be to have the indexer check the genesis file for the devmode flag and 
do the above if so, but that would be a larger patch file which is more likely to require updating that the above one-liner.
The downside to this is if you point the indexer at an Alogrand node that is not running in DevMode, you might get some
unexpected behaviour - this won't be an issue running with our pre-built images though, since the network is hard-coded
to run in `DevMode`. 

### 2. Executing docker builds as part of CI/CD is slow
Building the official algorand sandbox as part of CI/CD takes quite some time, so we do this as part of a separate pipeline
(see `azure-pipelines.yml` in this repo for the configuration), and push the results to DockerHub. As outlined above, 
we've also made these builds public, which saves time locally when updating to new versions.

We've also optimised the docker images to minimise their size by utilising multi-stage builds, and building for multiple
architectures (AMD64 and ARM64 - so M1 Macs are supported).

### 3. Other minor issues fixed
There was a potential race condition in the sandbox setup, where the `indexer` might start up before `postgres` comes alive,
particularly on first run when the database is being initialised. This is solved in the sandbox by specifying the `indexer`
service to have `restart: unless-stopped`, which we've also retained here, but to prevent potentially confusing error
messages and/or container restarts, we've made the `indexer` wait on startup until the `postgres` daemon is responding
to network requests.

## Alternatives

`reachsh/devnet-algo` - on DockerHub, but not always kept up to date, and only supports AMD64 images. Also, no access
to `kmd`.

## Outstanding Issues
There appears to be an issue with `DevMode` enabled, where after ~258 rounds, a Compact Cert is generated, and the 
indexer can't determine the signature type for it:

    algorand-sandbox-indexer   | {"level":"info","msg":"adding block 259","time":"2022-02-25T04:38:44Z"}
    algorand-sandbox-indexer   | {"error":"AddBlock() err: TxWithRetry() err: attemptTx() err: AddBlock() err: AddBlock() err: getSigTypeDelta() err: unable to determine the signature type","level":"error","msg":"adding block 259 to database failed","time":"2022-02-25T04:38:44Z"}

At this point, the only way to resolve the issue is to re-create the containers by stopping the stack and running `docker compose down`
before restarting it.
