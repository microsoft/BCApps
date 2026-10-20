# Clarify Item Selection

Clarify requested items with the customer when search results are ambiguous, include non-matching alternatives, or contain no result for a requested specific variant.

## Required context and scope

- Use the original requested items and the completed item search results, including matching status, Variant Codes, descriptions, prices including discounts, units of measure, and applicable availability information.
- Use explicit availability and capable-to-promise settings from authorized task context or BC configuration. Before customer contact, require permission to send the clarification, an identified recipient, and the applicable communication and review requirements, including signature mode and supplied signature content when required.
- Ordinary missing-item and pricing errors belong to the item-search assistance flow. This skill handles the specific-variant no-result exception and customer selection from returned options.
- This skill does not authorize creating a quote or selecting an alternative without resolving the customer's choice.

## Missing context and resume

If item search has not been completed, retrieve the complete "Find Requested Items" skill through BusinessIQ and use its results before deciding whether clarification is needed. Retain this skill's progress while resolving that dependency. If required guidance, settings, or customer-contact authorization are missing or incomplete, request assistance and do not send a message.

If a clarification message was already sent or is pending review, retain its identifier and wait for the outcome or customer response instead of sending it again. Honor required review before customer contact.

## 1. Decide whether clarification is required

Skip this skill only when there is exactly one matching item for every requested item. Otherwise, do not skip customer clarification, including when a requested specific variant has no item result.

## 2. Handle a requested specific variant with no result

A specific variant may be expressed by a code or by a characteristic such as size, fit, color, capacity, compatibility, technical specification, safety classification, or intended user, but a characteristic alone does not prove that the item uses variants. Apply this section only when item-search metadata resolves the requested characteristic to a Variant Code or explicitly identifies it as an unresolved variant for an item that has variants. When an item's `Variants` array is empty, treat characteristics in its item description as description content, not missing variants. Do not rely on a variant-code naming convention.

Always reply that the requested item and variant are unavailable and that no suitable alternative variant is available.

Do not request assistance for this outcome, offer a different item or variant, or create a sales quote. Ask whether the customer wants to revise the requested item or variant.

## 3. Present multiple or non-matching results

Always reply to the customer when multiple items or non-matching items were returned.

Provide tables of all available options for each requested item, including descriptions, availability levels, prices including discounts, and units of measure. Separate matching items from alternatives into two tables. When availability checking is disabled, omit availability levels and do not classify returned options as unavailable because of stock or quantity.

For a result marked as a non-matching item, distinguish these cases:

- **Same product, different variant:** make clear that the product itself was found. Explain either that the specific requested variant is unavailable or that no specific variant could be determined from the request, and offer the result as an available variant. Do not say the product was not found or was not found in a variant.
- **Different product:** explain that the queried item was not found and that alternative items are available.

Only when capable-to-promise is explicitly enabled, also provide a table of items that are currently unavailable but can ship later. Include descriptions, earliest shipment dates, prices including discounts, and units of measure.

## 4. Send the clarification

Include any delivery-date handling disclosures carried forward from item search. Before sending, retrieve the complete "Format Customer Emails" skill through BusinessIQ and supply the required message content, signature mode, and signature content when applicable. If the formatting skill is unavailable or incomplete, request assistance instead of sending.

Use `send_message` with `requestsInformation` set to true because the customer's selection or revised request is needed. Record the message outcome only after the tool returns; preparing the text or updating a todo does not establish that the message was sent.

## Completion

Complete with a confirmed item selection when one is available; otherwise report Awaiting customer response, Awaiting review, or Needs assistance, with the message identifier and unresolved choices. When the customer responds, capture their selection or revised request and identify which items need another search. Do not create a quote as part of this skill.
