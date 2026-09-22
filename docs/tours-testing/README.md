# Exploratory tours testing for Business Central

How to stand up a local BC container, drive the web client with Playwright, and run **exploratory
tours** against it — with SQL as the oracle.

These are reference documents, loaded on demand. They are not auto-applied instructions.

| Document | Read it for |
| --- | --- |
| [`exploratory-tours.instructions.md`](./exploratory-tours.instructions.md) | The method: charters, the two tour catalogs, **§5 "Starting a new tour"**, oracle discipline, session sheet template, anti-patterns |
| [`bc-test-environment.instructions.md`](./bc-test-environment.instructions.md) | Creating the container non-interactively, web client URL, credentials, cold start, clean-up |
| [`playwright-bc.instructions.md`](./playwright-bc.instructions.md) | Driving the client: the iframe rule, locator traps, keyboard over pointer, SQL oracle recipes |
| [`harness/`](./harness/README.md) | Runnable code — container script, `bc.js` helpers, probe runner |

Start here:

1. `harness/New-TourContainer.ps1` — ~20 minutes, no prompts.
2. §5 of the tours document — pick a charter, aim it at boundaries named in the AL source.
3. Write a session sheet; file anything real in [`../tours-testing-issues.md`](../tours-testing-issues.md).

Completed session sheets live in [`../tours/`](../tours/) and are the best illustration of what a
finished tour looks like.

## The two things that matter most

- **Assert against the database, not the screen.** Page text has produced false successes and false
  failures in this repo's own sessions.
- **Read the configuration before filing "it let me do X."** Twice in one tour, dramatic-looking
  behaviour turned out to be a setting working as designed.
