# Find Requested Items

Find and evaluate every item requested in a Business Central sales inquiry, sales quote request, or sales order request before proceeding to item selection or quote creation.

## Context and scope

- Use the message body, every attachment, and relevant conversation history. An item identifier can be an item number, SKU, product code, vendor item number, catalog number, or another identifying code.
- Use the current BC company and the pricing/location context already on the item availability page. "Customer No.", "Contact No.", and "Location filter" are optional search context, not prerequisites. Preserve their existing values, including blanks; do not ask the user to supply them or resolve a customer/contact before searching.
- Follow the active SOA availability and capable-to-promise instructions without requiring separately supplied configuration flags. For SOA, capable-to-promise is enabled when its active rule is present, otherwise disabled. Apply it only when availability checking is also enabled; never infer enablement from the presence of an earliest shipment date.
- This skill searches and evaluates items. It does not authorize selecting an unconfirmed alternative, creating a quote, or replying outside the agent's communication rules.

## Using available context and resuming

Begin searching with the request information and page values available. Do not introduce a pre-search checklist or assistance request for missing optional pricing/location context, a separately stated company, or repeated confirmation of active settings. Let the search run with the page's existing context and handle actual errors or results using the steps below. Do not replace a designated customer, contact, or location to obtain a result.

Reuse confirmed search results only while the requested item, quantity, unit, date, and pricing/location context are unchanged. Search changed items again; do not duplicate results already retained by the runtime.

## 1. Identify every requested item

Search for every item in the message body and every attachment. Never skip a requested item.

If neither the message body nor any attachment identifies an item, product, or service, request assistance stating that the customer has not specified any item, product, or service, and add: "Please make such items available or stop the task and handle manually." Do this instead of replying to the customer. Do not ask the customer to resend or re-attach a document, and do not state that an attachment was missing or could not be read: an attachment may have been received and set aside as not relevant before it reached you.

## 2. Open item availability and prepare the search text

Use the "Item Availability" action to open the item availability page (page 4410). Perform the following search preparation on that page for each requested item.

Build the search text from all available identification and descriptive information:

- Always include any item identifier exactly as provided, together with the item name, features, variants, attributes, and other relevant keywords. For item "BK-2048" described as "Red Kids Mountain Bicycles", search for "BK-2048 red kid mountain bicycle". Never search by description alone when an identifier is available.
- Preserve letters, numbers, hyphens, and other punctuation in identifiers. Do not correct their spelling or rewrite them.
- Use singular forms for descriptive keywords, such as "bicycle" rather than "bicycles".
- Correct spelling errors only in descriptive keywords, such as "tennsi" to "tennis".
- Do not include quantity, date, or unit of measure in the search text. Use their dedicated filters.

## 3. Set every filter before searching

For the current item, explicitly set all three request filters before invoking search:

- **Quantity filter:** use the requested amount in the requested unit of measure, without converting or modifying it. If no quantity was specified, set it to 1.
- **Date Filter:** use only a date on or by which the customer explicitly requests delivery of this item. Include the entire period before that date, including dates before today. Do not infer delivery from a document, order, issue, creation, or other unrelated date. If several delivery dates are requested, use the furthest date in the future. Ignore past dates; if no delivery date remains, explicitly set the filter to blank. Use the standard date filter without single quotes.
- **UOM filter:** set the requested unit of measurement or packaging/grouping method code. If none was requested, explicitly set the filter to blank.

Preserve the designated pricing and availability context:

- If "Customer No." is not empty, always use it in the search. Never modify it.
- If "Contact No." is not empty, always use it in the search. Never modify it.
- If "Location filter" is not empty, including when it is two single quotes (`''`), always use it in the search. Never modify it.

If any of these pricing/location fields is blank, leave it blank and continue searching. Their absence is not an error and does not require assistance.

## 4. Invoke search last

Confirm that Quantity filter, Date Filter, and UOM filter have all been explicitly set for the current item. Do not reuse an untouched filter from another item. Use 1 for an unspecified quantity and blank for an unspecified date or unit.

Invoke search only after all search text and filters are ready. Search must be the final preparation action for the current item. Do not proceed without performing it.

## 5. Handle errors and missing results

If a notification says that price calculation for the customer ran with an error, always request assistance showing the full error from the notification. Do not proceed until it is resolved.

Do not infer a requested specific variant from a descriptive characteristic alone. Treat a characteristic as a specific variant only when item-search metadata resolves it to a Variant Code or explicitly identifies it as an unresolved variant for an item that has variants. When an item's `Variants` array is empty, colors, sizes, and similar characteristics in its item description are description content, not missing variants. An otherwise matching item does not need a Variant Code in this case.

If a search returns no result for a customer-requested specific variant, do not request assistance for the missing result or lack of an earliest shipment date. Mark that requested item and variant as needing customer clarification with no safe alternative. Include this outcome in the results for use by "Clarify Item Selection"; do not choose another item or variant, contact the customer, or create a quote as part of this search skill.

For any other requested item with no search result, request assistance mentioning the item and adding: "Please make such items available or stop the task and handle manually."

Do not proceed past an unresolved assistance request.

## 6. Evaluate quantity availability using the active settings

If item availability checking is disabled, ignore requested quantity availability, availability levels, earliest shipment dates, and inventory notifications. Never treat a returned item as unavailable or request assistance because of stock or quantity. This does not resolve missing item results or change the variant-specific no-result routing in step 5.

If item availability checking is enabled:

- When capable-to-promise is enabled and an unavailable item has an earliest shipment date, treat it as available and proceed without requesting assistance for its current availability.
- When capable-to-promise is enabled and an unavailable item has no earliest shipment date, always request assistance mentioning the item and adding: "Please check the requested unit of measure and order promising setup." Do not proceed until resolved. The specific-variant no-result exception in step 5 still applies.
- Otherwise, if a requested item is unavailable in the requested quantity, request assistance mentioning the item and adding: "Please make such items available or stop the task and handle manually."

## 7. Carry the results and delivery-date decisions forward

Return the results for every requested item, including matching status, identifiers, descriptions, Variant Codes, quantities, units of measure, prices including discounts, and any applicable availability and earliest shipment dates. Preserve which items need customer clarification and which need assistance.

Ignore past requested delivery dates and continue as if they had not been requested. Do not stop, call the request unsupported, or ask for a revised date because of a past date. For multiple requested delivery dates, including dates split between the message and attachments, use the furthest date in the future; do not ask which date to use. If all are in the past, proceed as if no delivery date was requested.

Whenever the agent next replies to the customer, it must explain that a past requested delivery date was ignored or, when several dates were found, which date was used. Do not withhold a reply or stop processing for this reason.

## Completion

Complete with the results for every requested item, the effective filters/settings, and required delivery-date disclosures. Distinguish resolved matches, items needing customer clarification, and items blocked on assistance. An unresolved result is not authorization to substitute an item or create a document.
