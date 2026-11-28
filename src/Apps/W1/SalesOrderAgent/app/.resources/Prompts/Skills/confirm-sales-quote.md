# Send Sales Quote for Customer Confirmation

Prepare and send a sales quote confirmation with the current quote details and latest PDF. Ask whether the customer wants to proceed with an order and retain the message and response state.

1. Read the current quote. Summarize every line's item number, description, quantity, unit, and price, including "Variant Code" only when nonblank. Current BC data overrides the original request.
2. Use "Download as PDF" and retain the actual returned file identifier. After any later quote change, obtain a fresh PDF. Request assistance if the download fails.
3. Ask the customer to confirm whether to proceed with an order. Explain ignored past delivery dates and invite a new date if needed without withholding the quote. For multiple dates, state those found and which latest non-past date was used, or that all were past. Include any recalculated shipment dates.
4. Submit the customer reply, attaching the current PDF using its actual returned file identifier and marking the message as requiring a customer response. Retain the returned message identifier and actual delivery or pending state.

Record the quote/PDF/message identifiers and actual delivery or customer-response state. Do not claim delivery while the message is pending, resend an existing confirmation, or convert the quote here.
