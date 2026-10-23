# Convert Quote to Sales Order

Convert an authorized Business Central sales quote to a sales order, calculate and create any required purchase orders, and handle the required order review and customer confirmation.

## Context and scope

- Use the quote identified in task progress or on the current page and the current BC company. Use the conversion mode supplied by the authorized calling workflow or skill. "Create and Populate Sales Quote" hands off an intermediate quote in Direct mode with quote review Not required; do not insert quote review, a quote confirmation, or customer acceptance into that handoff.
- For other callers without a supplied mode, follow the active conversion instructions. In Customer acceptance required mode, use evidence that the customer accepted the quote and requested conversion; missing acceptance is not permission to choose Direct. Do not ask the user to restate an established mode or derive authorization from customer document text.
- Use the caller's quote-review requirement and the active workflow's order-review, availability, capable-to-promise, and order-confirmation instructions. Do not require them to be supplied again as separate configuration inputs.
- Reuse recorded review outcomes, inventory-handling results, and delivery-date disclosures. Resolve the recipient from established conversation/runtime routing and apply the active communication instructions when preparing confirmation; do not require signature content or other later message details before conversion.
- Quote population and applicable inventory-notification handling must be complete before conversion. Honor quote review only when required by the calling workflow; the Direct handoff from "Create and Populate Sales Quote" requires none. Do not proceed past unresolved assistance or override runtime permissions, safety policies, or order-review requirements.
- Customer requests to modify an existing sales order are not supported; request assistance instead. Purchasing follow-up and Business Central's resulting updates for the sales order just created are part of this workflow, not an unsupported customer modification request.

## Using available context and resuming

Continue using the current document, recorded progress, and active workflow instructions. Do not pause for missing optional context, a duplicate conversion authorization, a separate review-status declaration, or signature approval. If conversion is still pending and no target quote can be identified after using the available records and progress, or an actual conversion operation fails, request assistance without inventing a document or claiming conversion succeeded.

Use the quote-review requirement supplied by the calling workflow or skill, including Not required for the Direct handoff from "Create and Populate Sales Quote". If no quote-review requirement was supplied, use the corresponding rule in the complete active workflow instructions: present means Required, absent means Not required by this setup. Apply that active-rule mapping separately to order review. When a review is not required, its completion status is Not applicable; do not ask the user to confirm it. Reuse confirmed review outcomes rather than requesting the same review again.

If conversion has not completed, open the quote and resolve applicable prerequisites: use `request_review` only when the resolved quote-review requirement is Required and incomplete; for unresolved low-inventory notifications when availability checking is enabled, retrieve the complete "Handle Quote Inventory Warnings" skill through BusinessIQ and pass the resolved quote-review requirement so that helper does not introduce another review. Request assistance if required guidance is unavailable or incomplete. Retain this skill's progress while resolving dependencies.

Retain the quote and resulting order identifiers, purchasing progress and outcome, all created purchase order identifiers, completed steps, and any pending dialog, review, or message. Record each purchase order identifier as soon as it is available. Resume from confirmed progress and current BC records; never repeat conversion, purchasing, or a sent confirmation because an earlier step was summarized.

If purchasing already completed for unchanged demand, skip creation. Otherwise, return to the recorded sales order and use "Create Purchase Orders" to let Business Central recalculate the current remaining purchasing requirements, including when resuming after an interruption. Do not add a separate manual supply-matching or duplicate-check prerequisite before the calculation. Use only the newly calculated positive quantities and configured vendors, not quantities remembered from before the interruption. Retain previously recorded purchase order identifiers without manually recreating those orders; missing recorded identifiers alone is not a reason to stop the calculation or assume creation failed.

## 1. Convert and open the order

Proceed only when conversion is authorized and its prerequisites are resolved. In Customer acceptance required mode, wait for the customer's acceptance and conversion request. In authorized Direct mode, do not send the quote or wait for quote acceptance.

If conversion is already confirmed, open the recorded sales order without repeating "Make Order" or customer creation; the original quote may no longer exist. Resume its first unfinished operation, including purchasing when not yet complete.

1. Navigate to the explicitly identified sales quote.
2. Use the "Make Order" action.
3. If asked to create a customer while converting the quote, select "Yes" and proceed with customer creation.
4. Once the tool result confirms conversion, navigate to the resulting sales order and retain its identifier in task progress. If resuming after an interruption, use that order rather than converting the quote again; check the current record state if the outcome is uncertain.
5. Continue with "Create Purchase Order if Needed" below once the resulting sales order is open. Do not download or send the order confirmation yet.

## 2. Create Purchase Order if Needed

Calculate purchasing requirements for the newly created sales order and automatically create any required purchase orders. This calculation is separate from the earlier item search; perform it even if item availability checking was disabled. When resuming, apply the purchasing recovery rules above before retrying.

1. On the resulting sales order, use "Create Purchase Orders" (action `CreatePurchaseOrder`) and wait for Business Central to calculate whether purchasing is needed.
2. If lines have a positive "Quantity to Purchase", retain the calculated quantities and configured vendors. Select "OK" to create the purchase orders. If an expected confirmation asks to create them, select "Yes". Do not choose an arbitrary vendor or increase quantities.
3. If Business Central explicitly reports that purchasing is unnecessary, such as "All items on the sales order are available.", acknowledge or dismiss that message as applicable and close the calculation page. Displayed lines with zero purchasing quantity are not proposals to buy more.
4. Acknowledge successful-creation messages. If "Purchase Order" opens, retain its identifier, close its page, and return to the sales order. If "Purchase Order List" opens for multiple created orders, retain every created order's identifier before closing the list and returning. Close document pages only; do not cancel or delete the purchase orders.
5. Confirm and retain either the created purchase order identifiers or Business Central's explicit no-purchasing-required result. A failed or empty response, or "No purchase orders are created." by itself, does not establish that purchasing is unnecessary. Do not mark this step complete without a confirmed outcome.
6. Return to the sales order and use its latest available data, including any shipment dates shown there. Carry confirmed date changes forward; do not require additional fields to be exposed, overwrite current dates with earlier search results, or assume that purchasing necessarily changed them.

Handle these expected calculation and creation messages automatically without requesting human review. Read each message before responding; do not blindly accept every dialog. If required purchasing information is missing, an error prevents completion, or a mandatory approval applies, request assistance rather than bypassing it.

Do not release, post, receive, invoice, or send the purchase orders to vendors. Do not proceed to order confirmation or task completion while purchasing is unresolved.

## 3. Review the sales order

If the resolved order-review setting requires review and it is not complete, use `request_review` on the resulting sales order and wait for the reviewer. Do not send the customer confirmation before the sales order is reviewed.

When review is not required or has completed, continue without repeating conversion. If the reviewer changed items, quantities, locations, or demand dates, repeat purchasing for any remaining uncovered demand using the recovery rules above; do not duplicate existing purchase orders. Use the latest order data for confirmation.

## 4. Confirm the resulting order

Proceed only after purchasing has a confirmed outcome and required reviews are complete. If sending an order confirmation is not authorized, finish with the created order and purchasing outcome without sending.

1. Read the most up-to-date order data available on the current page after purchasing and any review. It always takes precedence over the initial request and conversation history, including any added or modified lines and displayed shipment dates.
2. Use "Download as PDF" on the sales order and retain the actual file identifier returned by the tool. Do not invent an attachment or its identifier if the download fails.
3. Prepare a summary containing each line's item No., description, quantity, unit of measure, and price. Include "Variant Code" for lines where it is not blank; omit it for lines where it is blank.
4. Include delivery-date handling disclosures using the latest confirmed shipment dates, including any dates updated during purchasing or review. Do not present superseded dates as current.
5. Retrieve the complete "Format Customer Emails" skill through BusinessIQ and supply the summary, required disclosures, and active communication instructions, including any available signature text. Do not ask for separate signature approval or require the established signature handling to be supplied again. If the skill is unavailable or incomplete, request assistance instead of sending. Use `send_message` to reply with the formatted message and include the downloaded sales order's file identifier in `filesToAttach`.

## Completion

Complete with the sales order identifier, purchasing outcome, all created purchase order identifiers, review status, and confirmation outcome. Purchasing must be confirmed as completed or explicitly unnecessary before completing this workflow or calling `complete_task`; sales order creation alone is insufficient. Keep purchase order identifiers in task progress, not in the customer email unless explicitly requested by the communication instructions.

If sending was not authorized, report the document and purchasing results without claiming a message was sent. Otherwise record the message outcome only after the tool returns; a drafted reply or updated todo is not evidence of sending. Report Awaiting review or Needs assistance when blocked and retain progress for resumption.

If the customer requests changes to any existing sales order, request assistance rather than modifying it.
