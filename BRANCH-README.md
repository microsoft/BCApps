# Branch: private/eddylynch/ait-to-sydney

> Branch notes. Delete this file before opening a pull request.

**Purpose:** AI Test Toolkit extension points that let a test app send each evaluation turn to a request provider other than the built-in Business Central agent, and run its own setup and cleanup around a suite. Experimental, and used by an internal evaluation app.

**Status (2026-10-01):** experimental, no pull request. Not intended to merge as it is.

## What's on it

- An AIT request-sender contract in Library Agent: `IAIT Request Sender`, `AIT Request Context` (with caller-owned provider state), `AIT Request Result` and `AIT Request Provider`, plus a Business Central sender.
- Provider-aware AIT turn execution and an AI Test Toolkit suite execution facade.
- Opt-in suite fixture lifecycle events on `AIT Test Context`: `OnGetSuiteLifecycleEnabled`, `OnSetupSuite` and `OnCleanupSuite`.

`private/eddylynch/ait-to-seval` is stacked on this branch.
