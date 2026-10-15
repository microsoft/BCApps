# Convert Quote to Sales Order

Convert a sales quote from the current conversation to a Business Central sales order and prepare its confirmation in two separate phases controlled by the main agent instructions.

## Required context and scope

- Conversion must be explicitly authorized by the main instructions. When the quote is sent to the customer, wait until the customer accepts it and requests conversion. When the main instructions authorize direct conversion without sending the quote, do not send it or wait for customer quote acceptance.
- Quote population, any required quote review, and inventory-notification handling must be complete. Do not proceed past unresolved assistance.
- The main instructions control whether an internal order review is required. This skill must return control after conversion so that review can occur before confirmation.
- Requests to modify an existing sales order are not supported; request assistance instead.

## Phase 1: Convert and open the order

Execute only this phase when the main workflow authorizes conversion.

1. Navigate to the sales quote created as part of the current conversation.
2. Use the "Make Order" action.
3. If asked to create a customer while converting the quote, select "Yes" and proceed with customer creation.
4. Once the tool result confirms conversion, navigate to the resulting sales order and retain its identifier in task progress. If resuming after an interruption, use that order rather than converting the quote again; check the current record state if the outcome is uncertain.
5. Stop and return to the main instructions. Do not download, send, or automatically proceed to the confirmation phase before the main workflow handles any required order review.

## Phase 2: Confirm the resulting order

Resume only this phase when the main workflow explicitly instructs you to do so, after any required order review is complete. Do not repeat the conversion.

1. Read the most up-to-date order data from the current page. It always takes precedence over the initial request and conversation history, including any added or modified lines.
2. Use "Download as PDF" on the sales order and retain the actual file identifier returned by the tool. Do not invent an attachment or its identifier if the download fails.
3. Prepare a summary containing each line's item No., description, quantity, unit of measure, and price. Include "Variant Code" for lines where it is not blank; omit it for lines where it is blank.
4. Retrieve and follow the "Format Customer Emails" skill for the reply, preserving the summary and required disclosures and following the main instructions for signature and safety. Then use `send_message` to reply and include the downloaded order's file identifier in `filesToAttach`.
5. Include delivery-date handling disclosures and any recalculated shipment dates carried forward from earlier workflow steps.

## Completion

Record the message outcome only after the tool returns; a drafted reply or updated todo is not evidence that the message was sent. Honor any pending review reported by the tools, then return to the main workflow. If the customer requests changes to any existing sales order, request assistance rather than modifying it.
