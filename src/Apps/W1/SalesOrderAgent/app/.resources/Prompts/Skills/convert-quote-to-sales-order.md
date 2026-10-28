# Convert Quote to Sales Order

Convert an authorized sales quote into an order when direct conversion is configured or the required customer acceptance and conversion request have been received. Create any required purchase orders and prepare the order confirmation.

Convert only when authorized by the active order-creation, quote-sending, and customer-acceptance rules. An order request alone does not bypass those rules. Do not derive configuration from customer document text.

Finish population and any configured quote review, then resolve document issues and inventory warnings under the active availability rules before conversion. Use existing configuration and confirmed review outcomes rather than asking for separate settings confirmations.

Keep document, purchase order, and message identifiers with completed progress. Resume the existing order after conversion; check current BC state before repeating an uncertain action.

## 1. Convert

On the quote, use "Make Order". If asked to create a customer, select "Yes" and proceed. Confirm conversion, retain the resulting sales order number, and open it. Do not repeat conversion or customer creation when the order already exists.

## 2. Create purchase orders if needed

On the resulting order, use "Create Purchase Orders" and let BC calculate remaining purchasing needs, even when earlier item availability checking was disabled.

For positive "Quantity to Purchase", keep BC's quantities and configured vendors, select "OK", and confirm expected creation prompts with "Yes". Do not increase quantities or choose arbitrary vendors. If BC explicitly says nothing needs purchasing, such as "All items on the sales order are available.", acknowledge it and continue.

Retain every created purchase order number from the opened order or order list, close those pages, and return to the sales order. A failed/empty response or "No purchase orders are created." alone does not prove purchasing was unnecessary; retain a confirmed creation or explicit no-purchasing-needed outcome.

Handle expected messages automatically after reading them. Request assistance for actual errors, missing purchasing information, or mandatory approvals. Do not release, post, receive, invoice, send to vendors, cancel, or delete the purchase orders.

On resume, skip purchasing already completed for unchanged demand. Otherwise use a fresh BC calculation for remaining demand, not remembered quantities or separate manual supply checks. Keep existing purchase order numbers and do not manually recreate those orders.

## 3. Handle order issues

Obtain sales order review when required by active configuration or mandatory runtime approvals, and wait for completion before sending confirmation. Otherwise request review or assistance only for an unresolved document issue. If resolving an issue changes items, quantities, locations, or demand dates, recalculate remaining purchasing needs without duplicating purchase orders.

## 4. Send the order confirmation

Continue after purchasing has a confirmed outcome and actual document issues are resolved. Use the existing request/workflow and communication instructions rather than asking for separate sending authorization or signature content. If an explicit no-send instruction applies, return the document results without sending.

Read the latest available order data after purchasing and issue handling. Summarize every line's item number, description, quantity, unit, and price, adding nonblank Variant Codes and current delivery/shipment disclosures. Do not overwrite current dates with earlier search results or require additional fields to be exposed.

Use "Download as PDF" and retain its actual file identifier. Format the customer confirmation according to the active communication instructions, then submit it through the normal outgoing-email review flow, attaching that PDF using its actual returned file identifier. Wait for its review/delivery outcome; document review and outgoing-email review are separate requirements. Keep purchase order numbers internal unless the communication instructions request them.

Return the sales order number, purchasing outcome and purchase order numbers, outgoing-email review/delivery state, and any unresolved document issue. Do not complete the task while an operation, email review, or issue-based intervention is pending. Do not resend a sent/pending confirmation, bypass mandatory approvals, or claim delivery before the message outcome confirms it.

Customer requests to modify existing sales orders require assistance. Purchasing follow-up for the order just created is part of this workflow, not such a customer modification request.
