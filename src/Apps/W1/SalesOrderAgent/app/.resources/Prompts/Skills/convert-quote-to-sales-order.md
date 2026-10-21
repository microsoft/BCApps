# Convert Quote to Sales Order

Convert a sales quote from the current Business Central conversation after customer acceptance and send the resulting sales order confirmation.

## Workflow policy

Follow the default SOA workflow: convert when the customer accepts the current quote and requests to proceed. A request to create an order starts with a quote; it is not acceptance of a quote that has not yet been sent. This skill does not request an additional document review.

If a quote has not yet been prepared and sent, retrieve and follow "Create and Populate Sales Quote" through Business IQ. If the customer requests item changes, use that skill to update and resend the quote, then wait for acceptance of the updated quote. If a required skill cannot be retrieved, request assistance instead of inventing its procedure.

Retain the quote, resulting order, and confirmation message identifiers. Resume from the first unfinished action; never repeat conversion or sending because an earlier step was summarized. If the outcome of an action is uncertain, inspect current records before retrying.

Requests to modify an existing sales order are unsupported; request assistance instead.

## 1. Convert the accepted quote

Identify the accepted quote from the current conversation. If acceptance or a request to proceed is missing, wait for the customer's response rather than converting.

1. Navigate to that sales quote and use "Make Order".
2. If asked to create a customer during conversion, choose "Yes" and proceed.
3. Open the resulting sales order and retain its number once conversion succeeds. If conversion fails or no resulting order can be found, request assistance.

When conversion already succeeded, open the recorded order rather than attempting to convert the original quote again.

## 2. Send the sales order confirmation

Read the most up-to-date data from the current sales order page. It takes precedence over the original request and history, including added or changed lines.

1. Use "Download as PDF" on the order and retain the actual returned file identifier. If downloading fails, request assistance rather than inventing an attachment.
2. Summarize every current line with item No., description, quantity, unit of measure, and price. Include Variant Code only for lines where it is not blank.
3. Include the delivery-date handling disclosures carried forward from the quote.
4. Format the reply as formal, simple HTML. Use left-aligned tables with adequate column width, padding, spacing before and after, and minimal styling. Apply the agent's signature guidance.
5. Use `send_message` with the downloaded order's actual file identifier in `filesToAttach` and `requestsInformation` set to false.

Finish only after the order exists and its confirmation message has been sent. A downloaded PDF or drafted reply is not a sent confirmation. If a tool reports a pending message review, retain that state and wait for its outcome. Do not claim completion while assistance or sending is unresolved.
