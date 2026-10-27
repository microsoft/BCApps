# Create and Populate Sales Quote

Create and populate a sales quote, call the holiday catalog helper, then prepare the quote email or convert to an order according to the customer's request.

Use the current request, company, selected contact/customer, and resolved items. The selected buyer remains authoritative even if their name or email differs from the conversation. If selection is unfinished, retrieve the complete "Find Requested Items" or "Resolve Contact or Customer" skill through Business Skills and resolve pending clarification or assistance before creating the quote. Use BC defaults for missing optional details.

Work on Sales Quote page 41 and lines page 301. Resume the first unfinished step on the recorded quote. If conversion already succeeded, resume "Convert Quote to Sales Order" for the recorded order instead of creating or converting again.

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

## 6. Call the catalog helper

Retrieve and follow the complete "Add Holiday Gift Catalog to Sales Quote" skill through Business Skills for this quote. This is mandatory after the requested lines are populated. Retain its added-line identifier and wait for confirmed completion before continuing; do not repeat a completed addition.

## 7. Continue according to the customer's request

Confirm the header and lines are populated. Use the order path only when the customer asks to place a sales order now; otherwise use the quote path. Do not infer the request from an attachment's title or document type.

Review outgoing customer emails, not sales quotes or orders as a routine step. Request document review or assistance only when an actual issue needs a user's decision. Do not bypass runtime-enforced approvals or sending restrictions.

**Quote requested:** Keep the document as a quote. Retrieve and follow the complete "Confirm Sales Quote" skill through Business Skills using the recorded quote, inventory results, delivery disclosures, and existing communication instructions. Prepare the outgoing quote email for review. Do not convert unless the customer later accepts the quote and asks to place the order.

**Order requested:** Retrieve and follow the complete "Convert Quote to Sales Order" skill through Business Skills. Supply Direct mode and the recorded quote, inventory results, and delivery disclosures. Do not send a quote-stage reply or wait for quote acceptance. Let the conversion skill handle purchasing and the outgoing order email review.

Return the document identifiers and actual state. An order request is not complete at the draft-quote stage. Do not call `complete_task` while an operation, outgoing-email review, customer response, or issue-based assistance/review is pending.
