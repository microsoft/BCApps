---
marp: true
title: Quantity Ready to Start
---

# Quantity Ready to Start
Helps teams create subcontracting orders only when upstream work is actually ready.

---

## The Problem
Subcontracted production steps often depend on output from earlier steps, but the current worksheet can suggest purchase lines for every subcontractor at once. That makes it easy to release work too early, creating avoidable supplier churn, manual follow-up, and a higher risk of ordering work that cannot start yet.

---

## The Solution
The feature adds a readiness quantity to each production routing step and keeps it updated as output is posted. Users can see that value on routing information, and the Subcontracting Worksheet now offers an optional **Only Ready Operations** switch so Suggest Lines includes only work that has enough completed upstream output. The direct **Create Subcontracting Order** action stays unchanged as a fallback path.

---

## Business Value
- Gives buyers and production planners a safer way to release subcontracting work.
- Reduces premature purchase lines for downstream suppliers in sequential or parallel routing flows.
- Preserves adoption flexibility because the new worksheet filter is off by default.
- Improves operational confidence for manufacturers using multiple subcontractors on the same order.

---

## What Shipped (and What's Still in Progress)
**Delivered**
- Added a readiness measure to production routing steps and surfaced it in routing information.
- Automatically recalculates readiness during output posting, routing changes, upgrades, and reopen scenarios.
- Added an optional worksheet filter so Suggest Lines can include only ready subcontracting operations.
- Covered the feature with targeted manufacturing and subcontracting tests.

**Not yet delivered**
- None recorded for this phase; all planned deliverables were reviewed.
- Deliberate scope boundary: the direct **Create Subcontracting Order** action still creates orders exactly as before and does not use the readiness filter.

---

## Rollout, Telemetry & Monitoring
- Rollout starts safely: the **Only Ready Operations** filter is opt-in and defaults to off, so existing customer behavior does not change until teams enable it.
- **QRTS-0001** tracks when readiness is recalculated after output posting, helping the team confirm the feature is updating live production progress as expected.
- **QRTS-0002** tracks completion of the one-time upgrade recalculation for open production orders, answering whether existing in-flight orders were backfilled successfully.
- **QRTS-0003** tracks when the worksheet skips not-ready routing lines while the filter is enabled, showing real adoption and how often early-release lines are being prevented.
- Validation summary: 8 targeted automated tests passed (5 manufacturing, 3 subcontracting), and the updated app set was publish/sync/upgrade validated on NST NAV.

---

## Demo
Screenshot/demo not yet captured - to be added before the readout.
