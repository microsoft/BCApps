# Resolve Requested Items

Resolve every requested item when processing a sales inquiry or preparing a sales quote. Search and evaluate items under the active availability settings, obtain customer selections when needed, and return resolved items or a waiting/assistance state.

## Search

Use the body, every attachment, and relevant conversation history. If none identifies an item, product, or service, request BC assistance stating this and adding: "Please make such items available or stop the task and handle manually." Do not ask the customer to resend attachments or claim they were missing or unreadable.

Open "Item Availability" (page 4410) and search every requested item:

1. Include any item number, SKU, vendor code, or other identifier exactly as supplied, with descriptive names, features, and variants. Preserve identifier spelling and punctuation; singularize and correct spelling only in descriptive keywords. Keep quantities, dates, and units out of the search text.
2. Explicitly set "Quantity filter" to the requested amount in its requested unit without conversion, or 1 if unspecified.
3. Set "Date Filter" through the latest non-past explicitly requested delivery date, including the entire period before it. Do not use document/order dates or quote the date filter. Set it blank if no valid delivery date was requested.
4. Set "UOM filter" to the requested unit or packaging code, or blank if unspecified.
5. Preserve "Customer No.", "Contact No.", and "Location filter" exactly as they are, including blank values and `''`. They are not prerequisites; do not resolve a buyer or request these fields before searching.
6. Invoke Search last, after preparing every filter for this item. Do not reuse stale filters from another item.

## Results and availability

For a price-calculation error, request assistance with the full notification error and wait.

Treat a characteristic as a specific variant only when search metadata resolves a Variant Code or identifies an unresolved variant for a variant-using item. An empty `Variants` array means descriptive colors/sizes are not missing variants; do not infer variants from code naming.

If a requested specific variant has no result, obtain customer clarification as described below. Do not request assistance for that missing result or missing shipment date, select another variant, or create a quote. For other missing items, request assistance naming the item and adding: "Please make such items available or stop the task and handle manually."

Follow the active SOA availability settings without asking for separate flags. Capable-to-promise applies only when its active rule and availability checking are enabled; returned dates do not enable it.

- Availability disabled: ignore stock quantities, availability levels, earliest shipment dates, and inventory notifications, but still handle missing items/variants.
- Availability enabled with capable-to-promise: an unavailable item with an earliest shipment date is available for this workflow. If no date is available, request assistance naming the item and adding: "Please check the requested unit of measure and order promising setup."
- Availability enabled without capable-to-promise: for insufficient quantity, request assistance naming the item and adding: "Please make such items available or stop the task and handle manually."

Do not proceed past unresolved assistance or select an unconfirmed alternative.

## Delivery-date disclosures

Ignore past requested dates without asking for replacements. Across body and attachments, choose the latest non-past delivery date; if all are past, use none. Carry a disclosure for the next customer reply explaining ignored dates and, for multiple dates, which was used. Do not stop processing because of these dates.

## Resolve customer selections

Skip customer clarification only when every requested item has exactly one matching result or the customer has already confirmed a selection from the current results. Never select an unconfirmed alternative. Ordinary missing-item and pricing errors require user assistance rather than customer clarification.

For a requested specific variant with no result, say the requested item and variant are unavailable and no suitable alternative variant is available. Ask whether the customer wants to revise the item or variant. Do not offer another product or variant.

For multiple or non-matching results, show all options in separate matching-item and alternative tables, including descriptions, discounted prices, units, and availability levels when checking is enabled. When disabled, omit availability and do not reject options because of stock.

For a same-product variant alternative, explain that the product was found but the requested variant is unavailable or unspecified, and offer the available variant. For a different-product alternative, explain that the queried item was not found.

When capable-to-promise is active, also show unavailable items that can ship later, with descriptions, earliest shipment dates, discounted prices, and units.

## Send clarification and wait

When clarification is needed, include the delivery-date disclosures in the customer reply. Submit the reply to the established recipient, marking the message as requiring a customer response.

Retain the returned message identifier and wait for any required review/customer response; do not resend an existing pending or sent clarification. Record the customer's choice and search revised items again as needed. Do not treat a sent question as a resolved selection.

## Return the results

Return every item's matching status, identifiers, description, Variant Code, quantity, unit, discounted price, and applicable availability/shipment dates, along with delivery-date disclosures and any clarification message identifier. Distinguish resolved selections, pending review/customer response, and assistance.

Reuse retained results and confirmed selections only while item, quantity, unit, date, and pricing/location context are unchanged. Resume unfinished work without repeating a completed search or clarification. Do not create sales documents here.
