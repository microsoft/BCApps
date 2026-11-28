# Handle Quote Inventory Warnings

Resolve low-inventory warnings by finding earliest shipment dates and updating the affected sales quote lines. Return the confirmed date changes and any warnings that remain unresolved.

Inspect the current quote and identify the affected items and lines. If no low-inventory warning exists, return Not applicable without changing dates.

Read each affected line's current item, Variant Code, quantity, unit, location, and requested-delivery-date context. Reuse a previously returned earliest shipment date only when it was calculated for that same context. If any value has changed, the original calculation context cannot be verified, or no date was returned, recalculate using the current line values. If no date can be determined, return the affected item and unresolved warning without inventing a date.

Set each affected line's "Shipment Date" to the later of its earliest shipment date and valid requested delivery date. Use the earliest date when the requested date is blank or past. Apply this change before proceeding, including when resuming after assistance.

Return the quote, affected lines, confirmed changes, shipment-date disclosures, and any unresolved warnings. Resume unfinished handling without repeating completed changes. Do not send or convert the quote here.
