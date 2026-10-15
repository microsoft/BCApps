# Resolve Contact or Customer

Identify the contact or customer to use for a Business Central sales quote after the requested items and any required item clarification have been resolved.

## Required context and scope

Use the conversation history, including the sender's email address, name, company name, and phone number. This skill selects an existing contact or customer; it does not create the sales quote.

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

Return the selected record and whether it is a contact or customer to the main workflow so quote creation can proceed.
