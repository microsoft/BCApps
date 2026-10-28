# Confirm Sales Quote

Send the current sales quote for customer confirmation when quote sending is enabled, attaching its latest PDF and requesting acceptance before order conversion.

Use the current quote, established recipient, and existing request/workflow for authorization and communication settings. Do not ask for separate sending-authorization, document-review-status, or signature inputs. Honor any explicit no-send instruction.

1. Complete any configured quote review, then resolve outstanding inventory warnings under the active availability rules. Wait for required review or assistance to be resolved before proceeding.
2. Read the current quote after any issue handling. Summarize every line's item number, description, quantity, unit, and price, including "Variant Code" only when nonblank. Current BC data overrides the original request.
3. Use "Download as PDF" and retain the actual returned file identifier. After any later quote change, obtain a fresh PDF. Request assistance if the download fails.
4. Ask the customer to confirm whether to proceed with an order. Explain ignored past delivery dates and invite a new date if needed without withholding the quote. For multiple dates, state those found and which latest non-past date was used, or that all were past. Include any recalculated shipment dates.
5. Format the customer reply according to the active communication instructions. Submit the formatted reply through the normal outgoing-email review flow, attaching the current PDF using its actual returned file identifier and marking the message as requiring a customer response. Wait for its review/delivery outcome; document review and outgoing-email review are separate requirements.

Record the quote/PDF/message identifiers and actual outgoing-email review, delivery, or customer-response state. Do not claim delivery while email review is pending, resend an existing confirmation, bypass mandatory approvals, or convert the quote here.
