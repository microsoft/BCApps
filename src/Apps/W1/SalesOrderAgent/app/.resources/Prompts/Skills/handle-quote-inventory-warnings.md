# Handle Quote Inventory Warnings

Handle low-inventory warnings on the current sales quote using the active availability and capable-to-promise rules.

If availability checking is disabled or no low-inventory warning exists, return Not applicable without changing dates or requesting stock-related assistance.

Honor any configured quote review before handling inventory warnings. Beyond configured or runtime-enforced reviews, use assistance or document review only when an actual issue cannot be resolved using the rules below.

When availability checking is enabled but capable-to-promise is disabled, request assistance for the warning and wait.

When both are enabled, use the affected item's previously returned earliest shipment date, or recalculate it if none was returned. A known earliest date makes the item available; the warning alone is not a reason for assistance. If no date can be determined, request assistance naming the item and adding: "Please check the requested unit of measure and order promising setup."

Set each affected line's "Shipment Date" to the later of its earliest shipment date and valid requested delivery date. Use the earliest date when the requested date is blank or past. Apply this change before proceeding, including when resuming after assistance.

Return the quote, affected lines, confirmed changes, and shipment-date disclosures for the next customer email, or any pending issue-based assistance/review. Resume unfinished handling without repeating completed changes. Do not send or convert the quote here.
