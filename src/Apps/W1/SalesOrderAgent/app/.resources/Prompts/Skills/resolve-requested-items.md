# Resolve Requested Items

Resolve requested items for sales inquiries and sales quote creation or changes. Search for products, resolve item and variant matches, obtain customer selections for ambiguous results, and return resolved items or outstanding questions.

## Search

Identify the requested items from the supplied request and context. If no item, product, or service can be identified, return that item information is missing without searching or inventing items.

Use the "Item Availability" action to open the Item Availability page and search every requested item. Never skip a requested item or proceed to item evaluation before performing its search:

1. Build the search text from all available identification and descriptive information: item number, SKU, product code, vendor item number, catalog number, item name, features, variants, attributes, and other relevant keywords. Always include any supplied identifier exactly as provided; never search by description alone when an identifier is available. Preserve identifier letters, numbers, hyphens, and other punctuation without correcting spelling or changing singular/plural forms. Singularize and correct spelling only in descriptive keywords. For example, search for item "BK-2048", described as "Red Kids Mountain Bicycles", using "BK-2048 red kid mountain bicycle"; correct a descriptive typo such as "tennsi" to "tennis". Keep quantities, dates, and units out of the search text; use their dedicated filters.
2. Explicitly set "Quantity filter" to the requested amount in its requested unit without conversion, or 1 if unspecified.
3. Set "Date Filter" only from an explicitly requested delivery-on or delivery-by date for the current item that is not in the past. Ignore past dates and use the latest remaining requested delivery date, including the entire period before it, even dates before today. Do not infer delivery dates from document, order, issue, creation, or other dates that do not explicitly request delivery. Use the standard date filter without single quotes. If no valid delivery date was requested, use the page's default availability period: either a blank filter or a system-generated availability-period range is valid. Clear a filter inherited from another item's requested delivery date once, then accept any default range restored by the page. Do not repeatedly clear or recheck it, try alternative filter syntax, or request assistance solely because it is not blank. Continue normal result handling even when no items match. The internal availability period is not a requested delivery date; do not copy it to the quote's "Requested Delivery Date".
4. Set "UOM filter" to the requested unit or packaging code, or blank if unspecified.
5. Preserve "Customer No." and "Contact No." used for prices and discounts, and "Location filter" used for availability, exactly as they are, including blank values and `''`. Always use the designated nonblank customer/contact filters and any nonblank location filter, including `''`; do not modify them. Do not require these fields to be populated before searching.
6. Invoke Search last, after setting Quantity and UOM and handling Date Filter as above. Before searching, confirm Quantity uses the requested amount or its instructed default, and explicitly set UOM blank when unspecified. A blank Date Filter or the page's default availability-period range satisfies the date requirement when no valid delivery date was requested. Do not require an explicitly set or persistently blank Date Filter, or reuse another item's requested delivery date.

## Evaluate results

For a price-calculation error, request assistance with the full notification error and wait.

Use availability and shipment data supplied by search. In a known available-items-only search mode, returned items and variants have passed the requested-quantity check for the searched quantity, unit, date, location, and variant context. That result is sufficient quantity-availability evidence only for that unchanged context.

In other modes, use explicit returned availability status and shipment dates. If neither the returned data nor a known available-only search establishes availability, report it as unknown. Do not infer search mode or insufficient stock from missing fields, invent availability levels or shipment dates, or substitute raw Item Card Inventory for contextual availability. Missing fields alone do not require another stock check, navigation to inventory pages, or assistance.

Treat a characteristic as a specific variant only when search metadata resolves a Variant Code or identifies an unresolved variant for a variant-using item. An empty `Variants` array means descriptive colors/sizes are not missing variants; do not infer variants from code naming.

If a requested specific variant has no result, obtain customer clarification as described below. Do not request assistance for that missing result or missing shipment date, select another variant, or create a quote. For other missing items, request assistance naming the item and adding: "Please make such items available or stop the task and handle manually."

Do not proceed past unresolved assistance or select an unconfirmed alternative.

## Delivery-date disclosures

Ignore past requested dates without asking for replacements. Across the supplied request and context, choose the latest non-past delivery date; if all are past, use none. Carry a disclosure for the next customer reply explaining ignored dates and, for multiple dates, which was used. Do not stop processing because of these dates.

## Resolve customer selections

Skip customer clarification only when every requested item has exactly one matching result or the customer has already confirmed a selection from the current results. Never select an unconfirmed alternative. Ordinary missing-item and pricing errors require user assistance rather than customer clarification.

For a requested specific variant with no result, say the requested item and variant are unavailable and no suitable alternative variant is available. Ask whether the customer wants to revise the item or variant. Do not offer another product or variant.

For multiple or non-matching results, show all options in separate matching-item and alternative tables, including descriptions, discounted prices, and units.

For a same-product variant alternative, explain that the product was found but the requested variant is unavailable or unspecified, and offer the available variant. For a different-product alternative, explain that the queried item was not found.

## Send clarification and wait

When clarification is needed, include the delivery-date disclosures in the customer reply. Submit the reply, marking the message as requiring a customer response.

Retain the returned message identifier and actual message state, and wait for delivery and the customer's response. Do not resend an existing pending or sent clarification. Record the customer's choice and search revised items again as needed. Do not treat a sent question as a resolved selection.

## Return the results

Return every item's matching status, identifiers, description, Variant Code, quantity, unit, discounted price, and search-provided availability/shipment data, along with delivery-date disclosures and any clarification message identifier. Distinguish resolved selections, pending delivery/customer response, and assistance.

Keep item matching separate from availability. Identify availability supported by explicit returned data or available-only filtering, and otherwise report unknown availability.

Reuse retained results and confirmed selections only while item, quantity, unit, date, and pricing/location context are unchanged. Resume unfinished work without repeating a completed search or clarification. Do not create sales documents here.
