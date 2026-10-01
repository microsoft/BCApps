# Branch: private/eddylynch/ait-to-seval

> Branch notes. Delete this file before opening a pull request.

**Purpose:** experiments in handing an AI Test Toolkit suite to a remote batch evaluation service instead of running it in-process. It is stacked on `private/eddylynch/ait-to-sydney`.

**Status (2026-10-01):** experimental, no pull request, and superseded for execution: remote runs are now orchestrated outside Business Central. The suite-backend extension point may still be worth proposing on its own. The token facade is not intended to merge.

## What's on it, beyond ait-to-sydney

- An extensible AIT suite backend: the `AIT Suite Backend` enum and interface, with a local adapter that keeps today's behavior (`Suite Backend = Local`).
- The `AIT SEVAL Token` facade.
