# Clarify Item Selection

Ask the customer to resolve ambiguous items, alternatives, or a requested specific variant with no result.

Use existing search results, or retrieve the complete "Find Requested Items" skill through Business Skills first. Skip clarification only when every requested item has exactly one matching result. Ordinary missing-item and pricing errors stay in the search assistance flow.

## Prepare the choices

For a specific variant with no result, say the requested item and variant are unavailable and no suitable alternative variant is available. Ask whether the customer wants to revise the item or variant. Do not offer another product/variant or request assistance for this outcome.

Apply that exception only when search metadata identifies the requested variant; descriptive characteristics alone and an empty `Variants` array do not prove a missing variant. Do not infer variants from code naming.

For multiple or non-matching results, show all options in separate matching-item and alternative tables, including descriptions, discounted prices, units, and availability levels when checking is enabled. When disabled, omit availability and do not reject options because of stock.

For a same-product variant alternative, explain that the product was found but the requested variant is unavailable or unspecified, and offer the available variant. For a different-product alternative, explain that the queried item was not found.

When capable-to-promise is active, also show unavailable items that can ship later, with descriptions, earliest shipment dates, discounted prices, and units.

## Send and wait

Include the search's delivery-date disclosures. Retrieve the complete "Format Customer Emails" skill through Business Skills, then use `send_message` with `requestsInformation` set to true and the established recipient.

Retain the returned message identifier and wait for any required review/customer response; do not resend an existing pending or sent clarification. Record the customer's choice and search revised items again as needed.

Return the selection or waiting/assistance state. Do not create a quote or choose an unconfirmed alternative here.
