# Clarify Item Selection

Clarify requested items with the customer when search results are ambiguous, include non-matching alternatives, or contain no result for a requested specific variant.

## Required context and scope

- Use the original requested items and the completed item search results, including matching status, Variant Codes, descriptions, prices including discounts, units of measure, and applicable availability information.
- Use the current agent instructions for availability and capable-to-promise settings and customer communication rules.
- Ordinary missing-item and pricing errors belong to the item-search assistance flow. This skill handles the specific-variant no-result exception and customer selection from returned options.
- This skill does not authorize creating a quote or selecting an alternative without resolving the customer's choice.

## 1. Decide whether clarification is required

Skip this skill only when there is exactly one matching item for every requested item. Otherwise, do not skip customer clarification, including when a requested specific variant has no item result.

## 2. Handle a requested specific variant with no result

Always reply that the requested item and variant are unavailable and that no suitable alternative variant is available.

Do not request assistance for this outcome, offer a different item or variant, or create a sales quote. Ask whether the customer wants to revise the requested item or variant.

A specific variant may be expressed by a code or by a characteristic such as size, fit, color, capacity, compatibility, technical specification, safety classification, or intended user. Do not rely on a variant-code naming convention.

## 3. Present multiple or non-matching results

Always reply to the customer when multiple items or non-matching items were returned.

Provide tables of all available options for each requested item, including descriptions, availability levels, prices including discounts, and units of measure. Separate matching items from alternatives into two tables. When availability checking is disabled, omit availability levels and do not classify returned options as unavailable because of stock or quantity.

For a result marked as a non-matching item, distinguish these cases:

- **Same product, different variant:** make clear that the product itself was found. Explain either that the specific requested variant is unavailable or that no specific variant could be determined from the request, and offer the result as an available variant. Do not say the product was not found or was not found in a variant.
- **Different product:** explain that the queried item was not found and that alternative items are available.

Only when capable-to-promise is explicitly enabled, also provide a table of items that are currently unavailable but can ship later. Include descriptions, earliest shipment dates, prices including discounts, and units of measure.

## 4. Send the clarification and return to the main workflow

Include any delivery-date handling disclosures carried forward from item search. Before sending, retrieve and follow the "Format Customer Emails" skill for tone and HTML table formatting, using the active signature instruction from the main instructions.

Use `send_message` with `requestsInformation` set to true because the customer's selection or revised request is needed. Record the message outcome only after the tool returns; preparing the text or updating a todo does not establish that the message was sent.

Do not advance to quote creation while item selection is unresolved. When the customer responds, return their selection or revised request to the main workflow for any necessary item search and subsequent processing.
