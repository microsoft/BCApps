# Confirm Sales Quote

Prepare the latest sales quote PDF and customer confirmation email for outgoing-email review.

Use the current quote, established recipient, and existing request/workflow for authorization and communication settings. Do not ask for separate sending-authorization, document-review-status, or signature inputs. Honor any explicit no-send instruction.

1. If availability checking is enabled and low-inventory handling is unfinished, retrieve and follow the complete "Handle Quote Inventory Warnings" skill through Business Skills. Request quote review or assistance only for an actual unresolved issue, not as a routine checkpoint.
2. Read the current quote after any issue handling. Summarize every line's item number, description, quantity, unit, and price, including "Variant Code" only when nonblank. Current BC data overrides the original request.
3. Use "Download as PDF" and retain the actual returned file identifier. After any later quote change, obtain a fresh PDF. Request assistance if the download fails.
4. Ask the customer to confirm whether to proceed with an order. Explain ignored past delivery dates and invite a new date if needed without withholding the quote. For multiple dates, state those found and which latest non-past date was used, or that all were past. Include any recalculated shipment dates.
5. Retrieve and follow the complete "Format Customer Emails" skill through Business Skills. Use `send_message` with the formatted reply, the actual PDF identifier in `filesToAttach`, and `requestsInformation` set to true, submitting it through the normal outgoing-email review flow. Wait for its review/delivery outcome; do not use sales quote review as a substitute for email review.

Record the quote/PDF/message identifiers and actual outgoing-email review, delivery, or customer-response state. Do not claim delivery while email review is pending, resend an existing confirmation, bypass mandatory approvals, or convert the quote here.
