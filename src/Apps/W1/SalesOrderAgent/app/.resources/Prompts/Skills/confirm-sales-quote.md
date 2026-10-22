# Confirm Sales Quote

Prepare and send an authorized Business Central sales quote confirmation using current document data and the applicable review and communication settings.

## Context and scope

- Use the populated quote identified in task progress or on the current page, the current BC company, and the recipient established by the conversation or runtime routing. Do not require these values to be supplied again as separate inputs.
- Follow the active SOA confirmation step for sending authorization and the active workflow settings. Reuse recorded review outcomes, inventory-handling results, and delivery-date disclosures. Do not require a separate settings checklist or signature approval before starting this skill.
- Sending a quote does not authorize converting it to an order. Follow runtime permissions, safety policies, and required message reviews.

## Using available context and resuming

Continue from the current quote and available task context. Resolve document and recipient details from existing records and routing rather than asking the user to repeat them. Request assistance only if the target quote or recipient still cannot be determined, an actual operation fails, or the active workflow requires it. Do not invent a record or recipient.

Open the quote. For SOA, internal quote review is Required only when the corresponding review rule is present in the complete active workflow instructions; otherwise it is Not required by this setup. When not required, review completion is Not applicable: do not request review or ask whether it was completed. When explicitly required, reuse the recorded review outcome; if incomplete, use `request_review` and wait rather than asking for a separate statement of review status.

Follow the active availability instructions. If availability checking is enabled and unresolved low-inventory notifications remain, retrieve the complete "Handle Quote Inventory Warnings" skill through BusinessIQ and resolve them before continuing. If required guidance is unavailable or incomplete, request assistance. Retain the quote identifier and progress while resolving dependencies.

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

Retrieve the complete "Format Customer Emails" skill through BusinessIQ and supply the assembled message content and active communication instructions, including any available signature text. Use the signature handling already established by those instructions; do not ask for separately approved company-signature content or a duplicate signature-mode input. If that skill is unavailable or incomplete, request assistance and do not send.

Use `send_message` to reply with the formatted message. Include the downloaded quote's actual file identifier in `filesToAttach` and set `requestsInformation` to true.

## Completion

Record the message outcome only after `send_message` returns. A downloaded PDF, drafted reply, or updated todo is not evidence that the message was sent. Honor any pending review reported by the tools before advancing.

Complete with the quote identifier, PDF identifier, and confirmed message outcome. Report Awaiting review or Awaiting customer response when applicable, or Needs assistance when blocked. Do not convert the quote as part of this skill.
