# algorand-sandbox-dev

## Overview

This repo is loosely based on [Algorand's official sandbox](https://github.com/algorand/sandbox), but solves the following problems which relate to local development and/or CI/CD.

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


### 2. Executing docker builds as part of CI/CD is slow
- building & pushing multi-arch builds to dockerhub

### 3. Other minor issues fixed
- indexer daemon needs to wait for postgres startup on init

## Alternatives

`reachsh/devnet-algo` - on DockerHub, but not always kept up to date, and only supports AMD64 images. Also, no access
to `kmd`.

## Outstanding Issues
- compact cert rounds (~258 rounds)
