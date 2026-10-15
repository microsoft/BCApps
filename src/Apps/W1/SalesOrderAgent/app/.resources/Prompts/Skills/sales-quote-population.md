# Create and Populate Sales Quote

Create and populate a Business Central sales quote when a sales quote or sales order request is ready for quote creation. Use this skill after the requested items have been searched and selected and the contact or customer has been identified.

## Required context and scope

- Use the request, including its message body, subject, attachments, and conversation history; the selected contact or customer; and the selected item availability results.
- Item selection and any required customer clarification or assistance must be resolved before creating the quote. The selected contact or customer is authoritative even if its name or email address differs from the conversation history.
- Apply the capable-to-promise shipment-date rule below only when the current agent instructions explicitly state that capable-to-promise is enabled for this task. Otherwise, skip that rule; do not infer enablement from the presence of a date in the search results.
- Follow the numbered steps one by one. After creating the quote, perform the field and line steps on the Sales Quote page (page 41) and its lines (page 301), opening the required lookups from there.
- This skill covers quote creation and population only. It does not authorize sending the quote, converting it to an order, or bypassing the agent's review, inventory, safety, or communication requirements.

When resuming this skill after an interruption or history summary, use the recorded quote and continue from the first unfinished step. Do not create another quote if creation already succeeded. Check the current page when the outcome of an earlier action is uncertain.

## 1. Create the sales quote

If a contact was selected, navigate to the contact card and use the "Create Sales Quote" action.

If asked to select a customer template, select "Yes" and proceed with template selection. If there is more than one template, cancel the selection, do not select the default template, and request assistance to select the appropriate template. Do not proceed until this is resolved.

If a customer was selected, navigate to the customer card and use the "Sales Quote" action.

## 2. Populate the requested delivery date

If the request specifies a "Requested Delivery Date", populate that field accordingly. Use only an explicitly requested delivery date, not a document, order, issue, or creation date.

If several requested delivery dates are specified, use the furthest date in the future. Ignore dates in the past. If the requested delivery date is in the past, or every requested delivery date is in the past, leave the field empty and continue populating the rest of the quote. Do not stop or ask the customer for a revised date.

## 3. Populate the external document number

Populate "External Document No." whenever a unique identifier is available. Examples include document numbers, reference numbers, or identifiers in the message body, subject, or attachments.

## 4. Populate the shipping address

If the request does not mention a specific shipping address, leave the address unchanged.

If the requested address exactly matches the current "Ship-to" address on the page, do not make changes. If there is no "Ship-to" address on the page and the requested shipping address matches the "Sell-to" address, do not make changes.

In all other cases, first set "Ship-to" to "Alternate Shipping Addresses" and inspect the list. This is mandatory even when "Ship-to" already shows "Custom Address" and the address fields are directly editable. **Never** type the requested address into the "Shipping and Billing" address fields before completing this check.

Check the registered addresses using these rules:

- If the request is less specific than a registered address, for example it names only a city, region, site, or street such as "our warehouse in Austin, TX", treat this as a match and select the closest registered address even when only part of the address is given. Prefer a matching registered address to creating a new one.
- If the customer provided a complete address, meaning a street together with a postal code or a city, and it conflicts with every registered address, do not select a registered address. A different street, city, or postal code is a conflict. A shared country or region alone is not a match.

If no registered address matches, after opening and searching the list, select the row indicating that none of the other rows apply or cancel the list. Then set "Ship-to" to "Custom Address" and populate the customer's requested street, city, state, postal code, and country. Use a custom address for a complete unregistered address rather than shipping to a conflicting registered address.

## 5. Add the sales quote lines

Add a sales quote line for each requested item using the selected item from the availability results.

If an item appears more than once with different quantities, create a separate line for each quantity entry. Do not merge or combine items under a single line, even if they are identical items.

Use the requested quantity for each line without converting or modifying it. If no quantity was specified, use 1.

After selecting the item number, populate "Variant Code" with the selected item's Variant Code from the availability result. If the result has no Variant Code, leave the field blank.

## 6. Apply capable-to-promise shipment dates when enabled

Skip this step unless the current agent instructions explicitly enable capable-to-promise for this task.

For each selected item, carefully check whether the search results provide an earliest shipment date. If they do, always populate that line's "Shipment Date" with the earliest shipment date or the requested delivery date, whichever is later. Use the requested delivery date resolved in step 2. If it is blank or in the past, use the earliest shipment date.

## 7. Populate the units of measure

For each requested item, use the field lookup to select the most relevant unit of measure based on the request.

If the request explicitly specifies a unit, search and populate the unit of measure code accordingly. Otherwise, let the system default it. Always use the corresponding unit of measure for each line.

## Completion

Confirm that the requested header information and all requested lines are present on the current quote. Retain its identifier and the completed population step in the task's progress before returning control.

Return to the main agent instructions for the applicable quote review, low-inventory notification handling, PDF download, customer confirmation, and order-conversion steps. Do not proceed past a required review or unresolved assistance request.
