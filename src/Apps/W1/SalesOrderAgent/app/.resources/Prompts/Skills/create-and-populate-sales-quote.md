# Create or Update Sales Quote

Create a sales quote or update an existing quote's header and item lines. Use this procedure to add items, change quantities, units or variants, remove requested lines, and populate the quote used for a sales order.

Use the current request, company, resolved items, and selected contact/customer for a new quote. For changes, use the identified existing quote and its buyer. The selected buyer remains authoritative even if their name or email differs from the conversation. Do not invent buyer or item selections.

Work on the Sales Quote page and its lines. Resume the first unfinished step on the recorded quote. If conversion already succeeded, return the recorded order and its actual state instead of creating or converting again.

## 1. Create or open the quote

If a quote identifier is supplied or a quote already exists for this request, open that quote instead of creating another. If the identified quote cannot be found, request assistance rather than creating a replacement.

Otherwise, from the contact card use "Create Sales Quote"; from the customer card use "Sales Quote". If asked to use a customer template, select "Yes". If several templates exist, cancel and request assistance rather than choosing the default.

## 2. Fill the header

On an existing quote, preserve header values unless a change was explicitly requested. For a new quote, use BC defaults for missing optional details.

Use only an explicitly requested delivery date, not a document or order date. Choose the latest non-past requested date. Ignore past requested dates without asking for replacements; on a new quote leave "Requested Delivery Date" blank if all are past, and on an existing quote do not clear a valid date solely because a past date was requested.

Set "External Document No." when a unique reference is available in the subject, body, or attachments and the header is being populated or that change was requested.

## 3. Set the shipping address

Leave the address unchanged if none was requested, it matches "Ship-to", or "Ship-to" is empty and it matches "Sell-to".

Otherwise, first set "Ship-to" to "Alternate Shipping Addresses" and inspect the opened list before editing any shipping address fields, even if "Custom Address" is already selected and the fields are editable. For a partial address, prefer the closest matching registered address. For a complete address (street plus city or postal code), a different street, city, or postal code is a conflict; a shared country or region alone is not a match.

If no registered address matches, select the none-applicable row or cancel the lookup, choose "Custom Address", and enter the requested street, city, state, postal code, and country.

## 4. Add, change, or remove requested lines

Read the current lines before editing. For a change or removal, identify the intended line using its item number, variant, unit, quantity, or explicit line reference. If several lines remain indistinguishable and the request does not identify which to change, obtain clarification rather than changing them all.

Change only the requested fields on the matched line; a quantity change is not a request for an additional line. Remove only lines the customer explicitly asked to remove. Preserve unrelated lines and values.

For additions, create a separate line for each requested item/quantity entry, even when item numbers repeat. Do not merge entries. Use the selected item number and exact requested quantity without conversion; default an unspecified quantity to 1 only for a new line. For an existing line, preserve quantity when no quantity change was requested.

For a newly selected or replaced item, apply its resolved "Variant Code", or leave it blank when none was returned. For an unchanged item, preserve its variant unless a variant change was requested.

For each explicitly requested unit, use the unit-of-measure lookup to search for that unit and select the most relevant corresponding code. Otherwise keep the default on a new line and preserve the unit on an existing line.

On resume, compare the current lines with completed changes before adding, changing, or removing anything. Do not add a line twice or remove another occurrence because an earlier removal already succeeded.

## 5. Apply shipment dates

When applying an earliest shipment date to a line, set "Shipment Date" to the later of that date and the valid requested delivery date. If the requested date is blank or past, use the earliest shipment date. Do not invent a missing shipment date.

## 6. Return the quote and changes

Read the resulting quote to confirm its header and lines. Return the quote identifier, added/changed/removed lines, delivery disclosures, and any unresolved issues. Do not send or convert the quote here.
