# Create and Populate Sales Quote

Create and populate a sales quote when a sales request requires one, including the intermediate quote needed for a sales order.

Use the current request, company, selected contact/customer, and resolved items. The selected buyer remains authoritative even if their name or email differs from the conversation. Resolve unfinished item or buyer selection and pending clarification or assistance before creating the quote. Use BC defaults for missing optional details.

Work on Sales Quote page 41 and lines page 301. Resume the first unfinished step on the recorded quote. If conversion already succeeded, return the recorded order and its actual state instead of creating or converting again.

## 1. Create the quote

From the contact card, use "Create Sales Quote"; from the customer card, use "Sales Quote". If asked to use a customer template, select "Yes". If several templates exist, cancel and request assistance rather than choosing the default.

## 2. Fill the header

Use only an explicitly requested delivery date, not a document or order date. Choose the latest non-past requested date. If all requested dates are past, leave "Requested Delivery Date" blank and continue without asking for a replacement date.

Set "External Document No." when a unique reference is available in the subject, body, or attachments. Leave unspecified information at its default.

**Set "Salesperson Code" to `SOA` - Sales Order Agent.**

## 3. Set the shipping address

Leave the address unchanged if none was requested, it matches "Ship-to", or "Ship-to" is empty and it matches "Sell-to".

Otherwise, always inspect "Alternate Shipping Addresses" before editing address fields, even if "Custom Address" is already selected. For a partial address, prefer the closest matching registered address. For a complete address (street plus city or postal code), a different street, city, or postal code is a conflict; a shared country or region alone is not a match.

If no registered address matches, select the none-applicable row or cancel the lookup, choose "Custom Address", and enter the requested street, city, state, postal code, and country.

## 4. Add requested lines

Add a separate line for each requested item/quantity entry, even when item numbers repeat. Use the selected item number and exact requested quantity without conversion; default an unspecified quantity to 1. Apply the selected "Variant Code", or leave it blank when none was returned.

Use the unit-of-measure lookup for an explicitly requested unit; otherwise keep the default.

## 5. Apply shipment dates

For SOA, capable-to-promise is enabled when its active rule is present, otherwise disabled. Do not infer it from returned dates.

When enabled and an earliest shipment date was returned, set the line's "Shipment Date" to the later of that date and the valid requested delivery date. If the requested date is blank or past, use the earliest shipment date.

## 6. Return the populated quote

Confirm the header and lines are populated. Return the quote identifier, delivery disclosures, and any unresolved issues. Population does not authorize sending, conversion, or task completion; the active configuration determines the next business action and required reviews.
