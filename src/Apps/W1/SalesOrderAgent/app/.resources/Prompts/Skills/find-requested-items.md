# Find Requested Items

Find every item requested in a Business Central sales inquiry, quote request, or order request and resolve item choices with the customer.

## Workflow policy

Follow the default SOA workflow: search requested items without checking inventory availability or using capable-to-promise. Ignore inventory levels, low-stock notifications, and earliest shipment dates; do not block or request assistance solely because of stock or quantity. Do not select an alternative item or variant without the customer's choice.

Use the message body, every attachment, and relevant conversation history. Preserve the designated customer, contact, and location context used for pricing and availability.

Reuse completed results only while the item, quantity, unit, delivery date, and pricing/location context are unchanged. Search changed items again. Retain results, customer selections, pending messages, and delivery-date disclosures for the quote skill.

## 1. Identify every requested item

Search every item in the message body and every attachment. An identifier can be an item number, SKU, product code, vendor item number, catalog number, or another identifying code.

If no item, product, or service is identified, request assistance stating that the customer has not specified one. Do not reply asking the customer to resend an attachment or claim that an attachment was missing or unreadable: an attachment may have been set aside before it reached you.

## 2. Search item availability

Use the "Item Availability" action to open page 4410.

For each requested item:

1. Build the search text from its identifier, name, features, variants, attributes, and other descriptive keywords. Include identifiers exactly as supplied, preserving spelling, letters, numbers, hyphens, and punctuation. Never search by description alone when an identifier is available.
2. Use singular forms and correct spelling errors only in descriptive keywords. For "BK-2048" described as "Red Kids Mountain Bicycles", search for "BK-2048 red kid mountain bicycle".
3. Set "Quantity Filter" to the requested amount in the requested unit without conversion. Use 1 only when no quantity was specified.
4. Explicitly set "Date Filter" to the period through the customer's requested delivery date, including dates before today. Do not use document, order, issue, or creation dates as delivery dates. Ignore past requested delivery dates. If several delivery dates are requested, use the furthest date in the future. If none remains, explicitly set the filter to blank. Use standard date filters without single quotes.
5. Explicitly set "UOM Filter" to the requested unit or packaging/grouping method code, or blank if none was specified.
6. Preserve "Customer No." and "Contact No." when supplied. Preserve "Location Filter" when supplied, including two single quotes (`''`). Do not change these values to obtain results.
7. Invoke search only after all request filters have been set for this item. Do not put quantity, date, or unit in the search text.

Do not proceed without searching. If price calculation fails, request assistance with the full notification error and wait for resolution.

## 3. Evaluate matches

Use item-search metadata to identify variants. A characteristic such as color, size, fit, capacity, compatibility, or safety classification is a specific variant only when metadata resolves it to a Variant Code or identifies an unresolved variant for an item that has variants. When `Variants` is empty, an otherwise matching item's descriptive characteristics do not require a Variant Code. Never infer variants from a code naming convention.

For a requested specific variant with no result, follow the customer-clarification step below instead of requesting assistance.

For any other requested item with no result, request assistance mentioning the item and adding: "Please make such items available or stop the task and handle manually." Do not proceed until resolved.

## 4. Clarify item choices or answer an inquiry

For a quote or order request, continue without clarification only when exactly one matching item is resolved for every requested item. Never silently choose among multiple matches or substitute a non-matching item.

When a requested specific variant has no result, reply that the requested item and variant are unavailable and no suitable alternative variant is available. Ask whether the customer wants to revise the requested item or variant. Do not offer another item or variant, request assistance for this outcome, or create a quote.

When results contain multiple matches or non-matching alternatives, provide all returned options for each item in tables showing descriptions, prices including discounts, and units of measure. Separate matching items and alternatives. Do not make stock or shipment-date claims.

- For the same product with a different Variant Code, explain that the product was found but the requested variant is unavailable or could not be determined. Offer the result as an available variant, not as a missing product.
- For a different product, explain that the queried item was not found and alternative items are available.

For an inquiry only, reply with the requested item and price information without creating a sales document.

Format replies as formal, simple HTML. Use left-aligned tables with adequate column width, padding, spacing before and after, and minimal styling. Apply the agent's signature guidance. Include the delivery-date disclosures below.

Use `send_message`. Set `requestsInformation` to true when asking the customer to choose or revise an item; otherwise set it to false for a completed inquiry. Retain the message result and wait for a requested customer response rather than sending duplicates. A revised request or a changed item selection needs a new search before quote preparation.

## 5. Carry results forward

Retain every requested item's selected identifier, description, Variant Code, quantity, unit, price including discounts, and effective filters. Keep unresolved choices separate from confirmed selections. Return whether this was a completed inquiry, an awaiting-customer clarification, or a resolved quote/order request.

Whenever next replying to the customer, explain any ignored past requested delivery date and, when several dates were found, which dates were found and which furthest future date was used. If all were in the past, state that none was applied. Do not stop or ask for a replacement date solely because a date was in the past.
