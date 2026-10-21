# BCApps extensibility backports - user guide

## 1. Overview

A **backport** copies a change from `main` to a release branch, so customers need not wait for the next major version. The workflow creates draft pull requests (PRs) containing the code and a shared issue tracking the work.

Introduced in [microsoft/BCApps#12987](https://github.com/microsoft/BCApps/pull/12987). Scheduled processing requires the workflow to be merged and a maintainer to enable it.

## 2. Why It Exists

Reduce manual copying and tracking, while leaving review and merging to people.

## 3. How It Works

**When:** Sundays at **21:10, Europe/Copenhagen time**, checking PRs merged into `main` in the previous **15 days**. This overlap helps catch a missed week. It does not run immediately after merges or scan all history.

**Which requests qualify automatically:**

| Label | Request |
| --- | --- |
| `event-request` | Add events that extensions can subscribe to. |
| `request-for-external` | Make existing functionality accessible to extensions. |

Either or both types are allowed. Other categories, including enum requests, extensibility bugs and enhancements, are excluded, even in mixed PRs. Linked original issues must also qualify. No extra trigger label is needed.

**Processing:**

1. Select eligible, unprocessed main PRs and the latest numbered release branch, such as `releases/29.x`. Maintainers can override the branch.
2. Select the exact milestone from that branch's configured version (`repoVersion`). For example, `29.1` selects **Version 29.1**, even if **Version 29.2** already exists.
3. Copy whole PRs, oldest first, normally combining each team's clean changes into one draft backport PR per run.
4. Create or update **one tracking Task per branch and milestone**, shared across teams and runs.

New code branches are named `bc-extrequest-backport/backport_11166` for original
PR 11166, or `bc-extrequest-backport/scm-2026-10-21` for a weekly SCM batch.
The team date uses Copenhagen time. If another backport already uses the name,
add `-2`, `-3`, etc. Retries keep the same branch; existing branches are not renamed.

Example tracker title:

```text
[Backporting][releases/29.x][Extensibility Requests][Version 29.1]
```

Its table contains **Original issue + short summary | Original PR | Team | Backport PR**. New runs add entries without duplicating earlier ones.

Team backport PRs use team/date titles, link the original work and reference the shared Task using `Fixes`. Both new objects inherit original labels, excluding `ext-ready-to-implement`, and add `ext-backporting`. The shared Task omits team/ownership labels; teams appear in its table.

Original issues remain unchanged. The only label added to a main PR is `ext-backport-processed`, once its backport PR exists: **created**, not **merged**.

## 4. Usage / Scenarios

**Automatic weekly processing:** every Sunday, the workflow finds eligible extensibility-request PRs already merged into `main` during the last 15 days and excludes those labeled `ext-backport-processed`. It prepares their backports and updates the shared tracker. No manual start or extra label is needed; people only review and merge the resulting backport PRs through normal release procedures.

**Manual use:** after deployment, open **BCApps > Actions > Extensibility Request Backport > Run workflow**. Select `main` in **Use workflow from** to run the deployed workflow definition. This does not select the backport destination; the target remains the release branch.

- Leave `source_pr` blank for normal 15-day selection and team batching.
- Enter a merged main **PR number**, not an issue number, for a specific request. This can override the normal selection filters, but never creates another copy of an existing backport. An interrupted run can resume to finish missing tracking updates.

Both modes reuse the same milestone tracker. **Manual runs make real changes; there is no preview mode.**

## 5. Edge Cases

| What if... | Result |
| --- | --- |
| Nothing qualifies? | No new backport PR or tracker. |
| The PR is older than 15 days? | Select its number manually. |
| It was already backported? | Skip it; do not backport it again. PRs labeled `ext-backport-processed` are excluded from automatic selection. |
| Team information is missing or inconsistent? | Process separately, without guessing a team. |
| Changes conflict with the release? | Record manual attention; no partial source change or automatic retry. Unrelated clean work continues; related changes may be held. |
| Changes are already present? | Record that outcome; create no empty PR. |
| The tracker is closed? | Reopen it when adding work, only while its milestone is open. |
| The configured version changes? | New work uses a new tracker; existing requests keep their original version. |
| The milestone is missing or closed? | Stop for maintainer attention; do not guess another milestone. |
| A run fails partway through? | Existing records support recovery. An uncertain creation outcome needs maintainer inspection before retrying. |

## 6. Limitations

The workflow does not resolve conflicts with AI, merge PRs, or automatically close the shared tracker when release PRs merge. People review, merge and close tracking work.

It targets one release branch, not every supported release. Only normal code files under `src/` are supported, up to 250 changed file paths per source PR; workflow/build changes and unsafe content stop processing.

Maintainers must enable scheduled runs with `EXT_REQ_BACKPORT_ENABLED=true` and provide the required GitHub App permissions. Manual publication still requires those permissions, even when scheduling is disabled.
