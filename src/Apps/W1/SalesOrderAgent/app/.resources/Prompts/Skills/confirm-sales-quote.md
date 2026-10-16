# Confirm Sales Quote

Prepare and send an authorized Business Central sales quote confirmation using current document data and the applicable review and communication settings.

## Required context and scope

- Required inputs are an explicitly identified, populated quote in the current company, authorization to send it, the recipient, and applicable quote-review, availability, capable-to-promise, and communication settings.
- Obtain review status, inventory-handling results, delivery-date disclosures, and signature mode/content from authorized task context or available BC records and configuration. Do not assume another procedure has already completed them.
- Sending a quote does not authorize converting it to an order. Follow runtime permissions, safety policies, and required message reviews.

## Missing context and resume

If the target quote, sending authorization, recipient, or required settings cannot be determined, request assistance without sending. Do not interpret missing settings as disabled.

Open the quote. If an internal quote review is required and incomplete, request it and wait. If availability checking is enabled and unresolved low-inventory notifications remain, retrieve the complete "Handle Quote Inventory Warnings" skill through BusinessIQ and resolve them before continuing. If required guidance is unavailable or incomplete, request assistance. Retain the quote identifier and progress while resolving dependencies.

If a confirmation message was already sent or is pending review, report that state and its identifier instead of sending a duplicate. After a review changes the quote, read its current data and obtain an updated PDF.

## 1. Read the current quote

Read the most up-to-date quote data from the current page. It always takes precedence over the initial request and conversation history, including when lines have been added or existing lines modified.

Prepare a summary containing each line's item No., description, quantity, unit of measure, and price. Include "Variant Code" for each line where it is not blank; omit it for lines where it is blank.

## 2. Download the quote

Use "Download as PDF" on the sales quote after the required review and inventory handling are complete. Retain the actual file identifier returned by the tool. Do not invent a file identifier or claim that an unsuccessful download produced an attachment.

## 3. Send the confirmation request

Prepare the reply with the current quote summary and the following confirmation request and disclosures.

Ask the customer to review the quote and confirm whether they want to proceed with converting it into a sales order.

Include the applicable delivery and shipment information:

- If a requested delivery date was in the past, explain that it was not applied and invite the customer to share a new delivery date if needed. Still send the quote in the same reply.
- If several requested delivery dates were found, state which dates were found and which furthest date in the future was used. If all were in the past, state that they were ignored and no requested delivery date was applied. Still send the quote in the same reply.
- If quote inventory handling recalculated shipment dates, explicitly include the new shipment dates in the email.

Retrieve the complete "Format Customer Emails" skill through BusinessIQ and supply the assembled message content, signature mode, and signature content when applicable. If that skill is unavailable or incomplete, request assistance and do not send.

Use `send_message` to reply with the formatted message. Include the downloaded quote's actual file identifier in `filesToAttach` and set `requestsInformation` to true.

## Completion

Record the message outcome only after `send_message` returns. A downloaded PDF, drafted reply, or updated todo is not evidence that the message was sent. Honor any pending review reported by the tools before advancing.

Complete with the quote identifier, PDF identifier, and confirmed message outcome. Report Awaiting review or Awaiting customer response when applicable, or Needs assistance when blocked. Do not convert the quote as part of this skill.
