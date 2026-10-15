# Confirm Sales Quote

Prepare and send a populated Business Central sales quote to the customer for review and confirmation when the main agent instructions permit sending quotes.

## Required context and scope

- Use the sales quote created in the current conversation and the latest data on its current page.
- Quote population, any required internal quote review, and applicable inventory-notification handling must be complete. Do not proceed past an unresolved review or assistance request.
- Do not use this skill when the main instructions prohibit sending the quote. Sending a quote does not authorize converting it to an order.
- Apply the main instructions for tone, signature, safety, and simple HTML formatting.

## 1. Read the current quote

Read the most up-to-date quote data from the current page. It always takes precedence over the initial request and conversation history, including when lines have been added or existing lines modified.

Prepare a summary containing each line's item No., description, quantity, unit of measure, and price. Include "Variant Code" for each line where it is not blank; omit it for lines where it is blank.

## 2. Download the quote

Use "Download as PDF" on the sales quote after the required review and inventory handling are complete. Retain the actual file identifier returned by the tool. Do not invent a file identifier or claim that an unsuccessful download produced an attachment.

## 3. Send the confirmation request

Use `send_message` to reply with the current quote summary. Include the downloaded quote's actual file identifier in `filesToAttach` and set `requestsInformation` to true.

Ask the customer to review the quote and confirm whether they want to proceed with converting it into a sales order.

Include the applicable delivery and shipment information:

- If a requested delivery date was in the past, explain that it was not applied and invite the customer to share a new delivery date if needed. Still send the quote in the same reply.
- If several requested delivery dates were found, state which dates were found and which furthest date in the future was used. If all were in the past, state that they were ignored and no requested delivery date was applied. Still send the quote in the same reply.
- If quote inventory handling recalculated shipment dates, explicitly include the new shipment dates in the email.

## Completion

Record the message outcome only after `send_message` returns. A downloaded PDF, drafted reply, or updated todo is not evidence that the message was sent. Honor any pending review reported by the tools before advancing.

Return to the main instructions to handle the customer's response. Do not convert the quote as part of this skill; the main workflow decides whether conversion is enabled and authorized.
