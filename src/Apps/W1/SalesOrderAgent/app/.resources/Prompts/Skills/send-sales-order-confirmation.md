# Send Sales Order Confirmation

Prepare and send a customer confirmation for an existing sales order using its current details and latest PDF. Retain the document and message identifiers and return the actual delivery or pending state without creating or converting sales documents.

Use the identified sales order and relevant delivery-date disclosures. Keep order, PDF, and message identifiers with completed progress. If a confirmation for the current request is already sent or pending, return its actual state without submitting it again. Check current BC state before retrying an uncertain submission.

## 1. Read the current order

Open the identified sales order. If it cannot be found, request assistance rather than creating a replacement. Inspect it for unresolved document errors and request assistance for actual blockers. After an issue is resolved or the order changes, reread its current lines and dates.

Summarize every line's item number, description, quantity, unit, and price, adding nonblank Variant Codes and current delivery/shipment disclosures. Do not overwrite current dates with earlier search results or require additional fields to be exposed.

## 2. Obtain the current PDF

Use "Download as PDF" and retain its actual returned file identifier. After any later order change, reread the order and obtain a fresh PDF. Request assistance if the download fails.

## 3. Send the confirmation

Submit the customer confirmation, attaching the current PDF using its actual returned file identifier. Retain the returned message identifier and actual delivery or pending state.

## 4. Return the result

Return the sales order number, PDF and message identifiers, actual delivery or pending state, and any unresolved document issue. Do not resend a sent/pending confirmation or claim delivery before the actual result confirms it. Do not create or convert sales documents here.
