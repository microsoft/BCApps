# Create and Populate Sales Quote

Create or update a Business Central sales quote for the current conversation, resolve its buyer and requested items, and send the populated quote to the customer for acceptance.

## Workflow policy

Follow the default SOA workflow: send the populated sales quote as a PDF and ask the customer to accept it before converting it to an order, including when the original request asks for a sales order. This skill does not request an additional document review.

The default workflow does not check inventory availability or use capable-to-promise. The detailed search and clarification procedure is in "Find Requested Items"; retrieve it through Business IQ when results are missing or the requested items have changed. Wait for unresolved item clarification or assistance before preparing the quote. If a required skill cannot be retrieved, request assistance instead of inventing its procedure.

Retain the quote identifier and completed work. Resume an existing quote rather than creating another one. Item-line changes are supported only for quotes created in this conversation. For an accepted quote, use "Convert Quote to Sales Order" instead. Do not modify an existing sales order.

## 1. Resolve the buyer and create or open the quote

For a quote already created in this conversation, open it and continue with the requested changes. Do not create another document or repeat buyer selection.

For a new quote, use the customer's or contact's email address, name, company, phone number, and other details from the request and conversation. If none is available, request assistance.

1. Open the Contact List (page 5052). If one record is displayed, select it directly. If multiple records are displayed, search using the available details one at a time, starting with email address, sender name, company name, and phone number. Do not select from multiple records without searching.
2. If no contact is found, open the Customer List (page 22) and follow the same selection and search rules.
3. If neither a contact nor a customer is found, request assistance.
4. Treat the selected record as authoritative even if its name or email differs from the conversation: incoming mail may be mapped to another contact for routing. Do not request assistance solely for that mismatch.
5. From the contact card, use "Create Sales Quote". If asked for a customer template, choose "Yes". If more than one template is offered, cancel selection and request assistance; do not choose the default template.
6. From a selected customer card, use "Sales Quote" instead.

Retain the created quote identifier. Continue on the Sales Quote page (41) and its lines (301).

## 2. Populate the header

Use only explicitly requested delivery dates, not document, order, issue, or creation dates. If several delivery dates are requested, use the furthest date in the future. Ignore past dates; if none remains, leave "Requested Delivery Date" empty and continue. Do not stop or ask for a replacement date.

Populate "External Document No." whenever the subject, message, or attachments contain a unique identifier such as a document or reference number.

For a requested shipping address:

- Leave it unchanged when it matches the current "Ship-to" address, or when no "Ship-to" address is present and it matches the "Sell-to" address.
- Otherwise, first set "Ship-to" to "Alternate Shipping Addresses" and inspect the registered addresses. Do this even when "Custom Address" already makes address fields editable. Never type an address before checking the registered list.
- A partial address, such as a city, region, site, or street ("our warehouse in Austin, TX"), can match a more specific registered address. Prefer the closest matching registered address.
- A complete street plus city or postal code that conflicts with every registered address is not a match. A shared country or region alone does not justify selecting a conflicting address.
- If none matches, select the row indicating that none applies or cancel the list. Then choose "Custom Address" and populate the requested street, city, state, postal code, and country.

For an update, preserve existing header values unless the customer requested a change.

## 3. Populate or update the lines

Add a line for every requested item using its confirmed item-search result. If an item appears multiple times with different quantities, create separate lines; do not merge them.

Use each quantity exactly as requested, without conversion; default to 1 only if unspecified. After choosing the item number, populate its Variant Code from the selected result, or leave the field blank if none was returned.

Use the field lookup to select the requested unit or packaging code. Otherwise let the system default the unit. Always apply the corresponding unit to each line.

Ignore low-inventory notifications and do not recalculate or set shipment dates based on inventory or capable-to-promise results. Do not request assistance solely because of stock or quantity.

For a modification, update or remove only the requested lines, preserve unrelated lines, and add new requested lines once. Reuse the current quote, but search again for any changed item, quantity, unit, or delivery date before applying the change.

## 4. Send the quote for acceptance

Read the current quote data after population and updates. Current page data takes precedence over the initial request and history, including added or changed lines.

1. Use "Download as PDF" and retain the actual returned file identifier. If downloading fails, request assistance rather than inventing an attachment.
2. Summarize every current line with item No., description, quantity, unit, and price. Include Variant Code only for lines where it is not blank.
3. Ask the customer to review the quote and confirm whether they want it converted into a sales order.
4. Explain any ignored past requested delivery date and invite a new date if needed, without withholding the quote. If multiple requested dates were found, state which dates were found and which furthest future date was used. If all were in the past, state that none was applied.
5. Format the reply as formal, simple HTML. Use left-aligned tables with adequate column width, padding, spacing before and after, and minimal styling. Apply the agent's signature guidance.
6. Use `send_message` with the downloaded quote's actual file identifier in `filesToAttach` and `requestsInformation` set to true.

Retain the quote and message identifiers and wait for the customer's response. Do not resend a quote already sent for the same document state. If a tool reports a pending message review, wait for its outcome; this is not customer acceptance. When the customer requests line changes, update and send the same quote again. Convert only after the customer accepts the current quote and asks to proceed.
