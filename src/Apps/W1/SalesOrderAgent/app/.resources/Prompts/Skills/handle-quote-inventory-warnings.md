# Handle Quote Inventory Warnings

Handle low-inventory notifications on a specified Business Central sales quote using the applicable availability and capable-to-promise policies.

## Context and scope

- Use the quote identified in task progress or on the current page, the current BC company, and its lines and notifications (pages 41 and 301). Do not require these values to be supplied again as separate inputs.
- Follow the active SOA availability and capable-to-promise instructions. Use any item availability results obtained before quote creation and the requested delivery date resolved for the quote. Do not request repeated configuration confirmation or infer capable-to-promise enablement from a date in the results.
- This skill does not authorize sending or converting the quote.

## Using available context and resuming

Check whether inventory handling applies before gathering any additional context. Use the current quote and available task progress rather than asking the user to restate the quote identity, settings, or review status. Request assistance for an actual handling failure or an applicable condition described below, not because an optional input or separate configuration flag was omitted.

Retain affected line identifiers, any recalculated shipment dates, and pending assistance. When resuming, check the current quote and finish unresolved handling rather than repeating completed changes.

## 1. Check whether inventory handling applies

If item availability checking is disabled, finish with Not applicable. Ignore inventory notifications, availability levels, and earliest shipment dates; do not request assistance because of stock or quantity.

If there is no low-inventory notification, finish with Not applicable without changing shipment dates as part of this skill.

Before changing an affected quote, use the quote-review requirement supplied by the authorized calling workflow or skill. The Direct handoff from "Create and Populate Sales Quote" requires no quote review; do not introduce one during inventory handling. If no requirement was supplied, use the active workflow's corresponding rule; its absence in the complete active instructions means Not required by this setup. When not required, review completion is Not applicable. Reuse a recorded completed review; use `request_review` on the quote and wait only when the resolved requirement is Required and incomplete. Do not request a review or confirmation of its status solely because this skill was invoked.

## 2. Handle the notification without capable-to-promise

If availability checking is enabled but the resolved capable-to-promise setting is disabled, request assistance for the low-inventory notification. Do not proceed while the assistance request is unresolved.

## 3. Handle the notification with capable-to-promise

Apply this step only when both availability checking and capable-to-promise are enabled.

Ignore the low-inventory notification as a reason by itself to request assistance. For each affected item, check whether an earliest shipment date was already provided in the item availability search results before the sales quote was created.

If no such date was provided, recalculate the earliest shipment date and carry the new shipment date forward for inclusion in the subsequent customer email. Do not invent a date. If no earliest shipment date can be determined, request assistance mentioning the item and adding: "Please check the requested unit of measure and order promising setup." Do not proceed until this is resolved.

Treat the item as available once the earliest shipment date is known. Set "Shipment Date" on the affected quote line to the earliest shipment date or the requested delivery date, whichever is later. If the requested delivery date is blank or in the past, use the earliest shipment date.

If assistance was already requested for this notification and the user asks you to continue, set the line's "Shipment Date" as described above before proceeding.

## Completion

Complete with the quote identifier, affected lines, confirmed shipment-date changes, and required customer disclosures. Otherwise report Not applicable, Awaiting review, or Needs assistance. Include recalculated shipment dates in the result so they can be stated in the next customer email. Do not send or convert the quote as part of this skill.
