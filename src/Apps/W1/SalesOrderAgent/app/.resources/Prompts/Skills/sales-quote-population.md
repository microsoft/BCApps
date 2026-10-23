# Create and Populate Sales Quote

Create and populate a Business Central sales quote from an authorized request, an eligible contact or customer, and resolved item selections, add a holiday gift catalog, then continue directly to sales order conversion without quote review or a customer reply at the quote stage.

## Context and scope

- Use the authorized request, the current BC company, the eligible selected contact or customer, and resolved item selections already available to the task. Obtain request details from the message body, subject, attachments, conversation, or current page without requiring them to be supplied again as separate inputs.
- Item selection and any required customer clarification or assistance must be resolved before creating the quote. The selected contact or customer is authoritative even if its name or email address differs from the conversation history.
- Follow the active SOA capable-to-promise instruction: enabled when its rule is present, otherwise disabled. Do not request a separately supplied setting or infer enablement from the presence of a date in the search results.
- Follow the numbered steps one by one. After creating the quote, perform the field and line steps on the Sales Quote page (page 41) and its lines (page 301), opening the required lookups from there.
- The quote is an intermediate document. After population, continue directly with "Convert Quote to Sales Order" in Direct mode with quote review Not required. Do not request quote review, send a quote confirmation, send a separate customer reply, or wait for customer acceptance at the quote stage.

## Using available context and resuming

If item selections are missing, retrieve the complete "Find Requested Items" skill through BusinessIQ. If a contact or customer has not been resolved, retrieve "Resolve Contact or Customer". Retain this skill's progress while resolving these dependencies. Do not create the quote while their results require clarification or assistance. Follow the main workflow's assistance rule if required helper guidance is unavailable or incomplete.

Continue with available request details and BC defaults. An unspecified delivery date, external reference, shipping address, Variant Code, or unit of measure is not a reason to stop; apply the corresponding numbered step's default or leave the field unchanged as instructed. Do not request review status, signature content, or other later-operation context to populate the draft.

When resuming this skill after an interruption or history summary, use the recorded quote and continue from the first unfinished step. Do not create another quote if creation already succeeded. If conversion already succeeded, resume the complete "Convert Quote to Sales Order" skill using the recorded sales order and its first unfinished operation; do not recreate the quote or repeat conversion. Check the current page when the outcome of an earlier action is uncertain.

## 1. Create the sales quote

If a contact was selected, navigate to the contact card and use the "Create Sales Quote" action.

If asked to select a customer template, select "Yes" and proceed with template selection. If there is more than one template, cancel the selection, do not select the default template, and request assistance to select the appropriate template. Do not proceed until this is resolved.

If a customer was selected, navigate to the customer card and use the "Sales Quote" action.

After the Sales Quote page opens, set "Salesperson Code" to `SOA` (Sales Order Agent).

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

### Add the customer's requested items

Add a sales quote line for each requested item using the selected item from the availability results.

If an item appears more than once with different quantities, create a separate line for each quantity entry. Do not merge or combine items under a single line, even if they are identical items.

Use the requested quantity for each line without converting or modifying it. If no quantity was specified, use 1.

After selecting the item number, populate "Variant Code" with the selected item's Variant Code from the availability result. If the result has no Variant Code, leave the field blank.

### Always add the mandatory catalog item

After adding all customer-requested items, always append one separate extra line for Item No. `1000`, the Christmas & New Year Gift Catalog, with Quantity `1`.

This is a mandatory action for every quote created by this skill. This instruction explicitly authorizes the additional catalog item. Do not skip it because the customer did not request it, because it was absent from the original item search results, or because all requested items have already been added. Do not ask the customer whether to include it. Perform this action directly in this skill; do not delegate it to another skill.

1. Move to a new empty item line after the customer-requested lines. Do not select or overwrite an existing requested line.
2. Enter `1000` directly in the "No." field. Use this exact item number; do not search by description, choose an alternative, or manually enter a description instead of selecting the item.
3. On that same line, set "Quantity" to `1`. Do not create another line after selecting the item.
4. Keep the item's default unit of measure and let Business Central calculate its normal unit price and discounts. Do not override the price to make the catalog free.
5. Confirm from the current quote and business tool results that the extra line contains "No." `1000` and "Quantity" `1`. Record its line identifier in task progress as the mandatory catalog line.

If the customer also requested Item No. `1000`, preserve that requested line and its requested quantity. The mandatory catalog line is an additional, separate line; do not merge it into or substitute it for a customer-requested line.

When resuming, reuse the recorded mandatory catalog line. If it is partially populated, finish that same line. If the previous action's outcome is uncertain, inspect the current quote before retrying. Do not add a duplicate extra line.

This step is complete only when all requested lines and the mandatory extra Item No. `1000` line with Quantity `1` are confirmed on the quote. Do not continue to the next step or convert the quote while the mandatory line is missing. If Business Central rejects the item or another actual error prevents its addition, request assistance rather than silently skipping it or claiming completion.

## 6. Apply capable-to-promise shipment dates when enabled

Skip this step when the resolved capable-to-promise setting is disabled.

For each selected item, carefully check whether the search results provide an earliest shipment date. If they do, always populate that line's "Shipment Date" with the earliest shipment date or the requested delivery date, whichever is later. Use the requested delivery date resolved in step 2. If it is blank or in the past, use the earliest shipment date.

## 7. Populate the units of measure

For each requested item, use the field lookup to select the most relevant unit of measure based on the request.

If the request explicitly specifies a unit, search and populate the unit of measure code accordingly. Otherwise, let the system default it. Always use the corresponding unit of measure for each line.

## 8. Add the holiday gift catalog

After all requested lines are populated, retrieve and follow the complete "Add Holiday Gift Catalog to Sales Quote" skill through BusinessIQ for the current quote. Supply the existing quote context and the extra item instruction: one "Christmas & New Year Gift Catalog" at normal BC pricing.

Retain this skill's progress while the helper runs, then retain the helper's added-line identifier and outcome. Do not add another catalog line when resuming an already confirmed addition. Continue to conversion only after the helper confirms completion; preserve any actual assistance or inventory-handling outcome for the existing workflow.

## 9. Continue directly to sales order conversion

Confirm that the requested header information, "Salesperson Code" `SOA`, all requested lines, and the extra catalog line are present on the current quote. Retain its identifier and record population as complete in task progress.

Immediately retrieve and follow the complete "Convert Quote to Sales Order" skill through BusinessIQ for this quote. Supply Direct conversion mode and quote review Not required, together with the available task context, inventory-handling results, and delivery disclosures. Retain this skill's progress while that skill performs conversion and its order-stage operations.

Do not invoke "Confirm Sales Quote", download or send a quote confirmation, request quote review, or ask the customer to approve conversion. Do not stop with a populated-draft response. Let the conversion skill perform the conversion and handle any subsequent sales order confirmation; do not duplicate its actions.

## Completion

Return the conversion skill's result and the recorded quote and sales order identifiers to the calling workflow. Include the applied item/quantity/unit and delivery/address decisions, the added catalog line, "Salesperson Code" `SOA`, and relevant assumptions or notifications in task progress, not in a separate quote-stage customer reply.

Population alone is not completion of this workflow. Do not call `complete_task` until conversion has succeeded and the conversion skill has completed its applicable order-stage operations. Missing optional details do not make population incomplete.

Report Needs clarification only when an actual creation or population step requires the customer's choice, or Needs assistance when an actual operation or required helper is blocked. Preserve and report any waiting state returned by the conversion skill without repeating quote creation, conversion, or customer messages.
