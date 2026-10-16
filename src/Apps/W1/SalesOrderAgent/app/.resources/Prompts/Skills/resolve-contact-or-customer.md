# Resolve Contact or Customer

Resolve supplied buyer information to an eligible Business Central contact or customer in the current company.

## Required context and scope

Use buyer information from the authorized request or conversation, including the sender's email address, name, company name, and phone number, together with the current company's eligible contact/customer records. Respect the runtime's record filters and permissions. This skill selects an existing contact or customer; it does not require item search or create a document.

## Missing context and resume

Request assistance when required identity information is unavailable or the available evidence cannot distinguish eligible records. Do not guess a different legal entity.

If resuming with an already confirmed selection, verify that the record is still eligible for the unchanged request and reuse it. Search again when the request or selection has changed.

## 1. Check that identity information is available

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
