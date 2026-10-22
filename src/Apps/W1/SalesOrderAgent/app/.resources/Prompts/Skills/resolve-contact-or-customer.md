# Resolve Contact or Customer

Resolve supplied buyer information to an eligible Business Central contact or customer in the current company.

## Context and scope

Use whichever buyer details are available from the authorized request or conversation, such as the sender's email address, name, company name, or phone number, together with the current BC company's eligible contact/customer records. These details are alternatives, not a checklist of required fields. Respect the runtime's record filters and permissions. This skill selects an existing contact or customer; it does not require item search or create a document.

## Using available context and resuming

Search with the information available instead of requesting missing optional buyer details or a preselected Customer No. or Contact No. Use the search results and the single-record rules below. Request assistance only when no buyer information is available, no eligible record is found, or the actual results cannot distinguish eligible records. Do not guess a different legal entity.

If an eligible contact or customer has already been selected by the runtime or confirmed task progress, reuse it for the unchanged request without another identity-confirmation step. Search again when the request or selection has changed or a tool reports that the record is no longer usable.

## 1. Check that identity information is available

Any available buyer detail can be used for the search. Do not require an email address, name, company name, and phone number all to be present.

If there is no information related to the customer, contact, or company, request assistance. Do not proceed until this is resolved.

## 2. Find the contact

Navigate to the contact list page (page 5052).

If only one contact record is displayed, select it directly without searching.

If multiple contacts are displayed, search using the available conversation information one piece at a time, starting with the email address, sender's name, company name, phone number, and other relevant details. Do not select a contact from multiple records without first performing a search.

## 3. Find the customer if no contact was found

If the contact is not found, navigate to the customer list page (page 22).

If only one customer record is displayed, select it directly without searching.

If multiple customers are displayed, search using the available conversation information one piece at a time, starting with the email address, sender's name, company name, phone number, and other relevant details. Do not select a customer from multiple records without first performing a search.

If neither a contact nor a customer is found, request assistance.

## 4. Return the selected record

The selected contact or customer is authoritative, even if its name or email address does not exactly match the conversation history. Incoming emails can be mapped to another contact for response routing. Do not request assistance solely because of that mismatch.

## Completion

Complete with the selected record's identifier, whether it is a contact or customer, and the evidence used to select it. If selection remains unresolved, report the ambiguity and required assistance. Do not start quote creation as part of this skill.
