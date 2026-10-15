# Handle Quote Inventory Warnings

Handle low-inventory notifications on a populated Business Central sales quote before the workflow sends the quote or converts it to an order.

## Required context and scope

- Use the current sales quote and its lines (pages 41 and 301), the item availability results obtained before quote creation, and the requested delivery date resolved for the quote.
- Use the current agent instructions to determine whether item availability checking and capable-to-promise are enabled. Do not infer capable-to-promise enablement from a date in the results.
- Complete any quote review required by the main instructions before this step. This skill does not authorize sending or converting a quote.

## 1. Check whether inventory handling applies

If item availability checking is disabled, ignore inventory notifications, availability levels, and earliest shipment dates. Do not request assistance because of stock or quantity.

If there is no low-inventory notification, return to the main workflow without changing shipment dates as part of this skill.

## 2. Handle the notification without capable-to-promise

If availability checking is enabled but capable-to-promise is not explicitly enabled, request assistance for the low-inventory notification. Do not proceed while the assistance request is unresolved.

## 3. Handle the notification with capable-to-promise

Apply this step only when both availability checking and capable-to-promise are enabled.

Ignore the low-inventory notification as a reason by itself to request assistance. For each affected item, check whether an earliest shipment date was already provided in the item availability search results before the sales quote was created.

If no such date was provided, recalculate the earliest shipment date and carry the new shipment date forward for inclusion in the subsequent customer email. Do not invent a date. If no earliest shipment date can be determined, request assistance mentioning the item and adding: "Please check the requested unit of measure and order promising setup." Do not proceed until this is resolved.

Treat the item as available once the earliest shipment date is known. Set "Shipment Date" on the affected quote line to the earliest shipment date or the requested delivery date, whichever is later. If the requested delivery date is blank or in the past, use the earliest shipment date.

If assistance was already requested for this notification and the user asks you to continue, set the line's "Shipment Date" as described above before proceeding.

## Completion

Return to the main workflow after the applicable handling is complete. Carry any recalculated shipment dates forward so they are explicitly included in the next customer email. Do not send or convert the quote as part of this skill.
