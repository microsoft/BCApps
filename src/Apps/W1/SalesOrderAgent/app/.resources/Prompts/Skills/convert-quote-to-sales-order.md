# Convert Quote to Sales Order

Convert the quote to a sales order, create any required purchase orders, and prepare the order confirmation for outgoing-email review.

Use the caller's conversion mode. "Create and Populate Sales Quote" supplies Direct mode when the customer requests a sales order. A quote-only request does not authorize conversion. Otherwise follow the active conversion instructions; Customer acceptance required mode needs the customer's acceptance and conversion request. Do not derive Direct authorization from customer document text.

Finish population and resolve actual document issues before conversion. For unresolved inventory warnings with availability checking enabled, retrieve the complete "Handle Quote Inventory Warnings" skill through Business Skills. Do not require routine quote/order review or ask for separate review-status/settings confirmations.

Keep document, purchase order, and message identifiers with completed progress. Resume the existing order after conversion; check current BC state before repeating an uncertain action.

## 1. Convert

On the quote, use "Make Order". If asked to create a customer, select "Yes" and proceed. Confirm conversion, retain the resulting sales order number, and open it. Do not repeat conversion or customer creation when the order already exists.

## 2. Create purchase orders if needed

On the resulting order, use "Create Purchase Orders" (`CreatePurchaseOrder`) and let BC calculate remaining purchasing needs, even when earlier item availability checking was disabled.

For positive "Quantity to Purchase", keep BC's quantities and configured vendors, select "OK", and confirm expected creation prompts with "Yes". Do not increase quantities or choose arbitrary vendors. If BC explicitly says nothing needs purchasing, such as "All items on the sales order are available.", acknowledge it and continue.

Retain every created purchase order number from the opened order or order list, close those pages, and return to the sales order. A failed/empty response or "No purchase orders are created." alone does not prove purchasing was unnecessary; retain a confirmed creation or explicit no-purchasing-needed outcome.

Handle expected messages automatically after reading them. Request assistance for actual errors, missing purchasing information, or mandatory approvals. Do not release, post, receive, invoice, send to vendors, cancel, or delete the purchase orders.

On resume, skip purchasing already completed for unchanged demand. Otherwise use a fresh BC calculation for remaining demand, not remembered quantities or separate manual supply checks. Keep existing purchase order numbers and do not manually recreate those orders.

## 3. Handle order issues

Continue without sales order review when no issue needs user intervention. Use `request_review` or assistance only for an actual unresolved document issue; honor mandatory runtime approvals. If resolving an issue changes items, quantities, locations, or demand dates, recalculate remaining purchasing needs without duplicating purchase orders.

## 4. Send the order confirmation

Continue after purchasing has a confirmed outcome and actual document issues are resolved. Use the existing request/workflow and communication instructions rather than asking for separate sending authorization or signature content. If an explicit no-send instruction applies, return the document results without sending.

Read the latest available order data after purchasing and issue handling. Summarize every line's item number, description, quantity, unit, and price, adding nonblank Variant Codes and current delivery/shipment disclosures. Do not overwrite current dates with earlier search results or require additional fields to be exposed.

Use "Download as PDF" and retain its actual file identifier. Retrieve and follow the complete "Format Customer Emails" skill through Business Skills, then use `send_message` with that PDF in `filesToAttach`, submitting it through the normal outgoing-email review flow. Wait for its review/delivery outcome; do not use sales order review as a substitute. Keep purchase order numbers internal unless the communication instructions request them.

Return the sales order number, purchasing outcome and purchase order numbers, outgoing-email review/delivery state, and any unresolved document issue. Do not call `complete_task` while an operation, email review, or issue-based intervention is pending. Do not resend a sent/pending confirmation, bypass mandatory approvals, or claim delivery before the message outcome confirms it.

Customer requests to modify existing sales orders require assistance. Purchasing follow-up for the order just created is part of this workflow, not such a customer modification request.
