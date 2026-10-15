# Format Customer Emails

Format customer-facing emails in simple HTML when Sales Order Agent prepares an item clarification, sales quote confirmation, sales order confirmation, or another customer reply.

## Required context and scope

- Use the message content required by the calling workflow and the active signature instruction from the main instructions.
- This skill controls presentation only. Preserve the required facts, line details, disclosures, and customer questions. Do not change the business outcome or bypass a review or assistance requirement.
- The main instructions remain authoritative for safety, commitments, unsupported requests, and whether a signature must be included.

## 1. Use a formal tone

Use a formal tone when replying to customers. Preserve the meaning of the message and follow the main communication policies.

## 2. Format the message as simple HTML

Use simple HTML for the email body, including its paragraphs and tables. Do not use Markdown tables or Markdown formatting in the outgoing email.

## 3. Format tables professionally

- Format all tables in HTML with a professional appearance.
- Ensure there is clear spacing before and after each table.
- Give each column enough width to fully display its content, with extra padding between columns for readability.
- Align every table column to the left, including numeric columns.
- Use clean, minimal styling.

Preserve every row and column required by the calling workflow. Do not replace required line details with totals, a sample of lines, or a reference to an attachment.

## 4. Apply the active signature instruction

If the main instructions say never to add a signature, add none. Otherwise, use the signature supplied in the main instructions. Do not invent or substitute another signature.

## Completion

Return the formatted email to the calling workflow. Do not send it as part of this skill or change its attachments, confirmation-request flag, or review requirements.
