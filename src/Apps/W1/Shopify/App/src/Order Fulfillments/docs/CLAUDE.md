# Order fulfillments

Two parallel data models for fulfillment tracking. Fulfillment orders represent Shopify's intent (what needs to be shipped from which location), while order fulfillments represent actual shipments with tracking information.

## How it works

`ShpfyFulfillmentOrdersAPI.Codeunit.al` imports fulfillment orders from Shopify, either for a specific order or by querying for orders assigned to BC's fulfillment service. Each fulfillment order header records the assigned location, status, delivery method type, and request status. Lines carry product/variant IDs, total quantity, and remaining quantity. The API auto-registers a fulfillment service with Shopify on first use (if `Allow Outgoing Requests` is enabled), and checks on subsequent calls whether it still exists. It also supports accepting fulfillment requests, which transitions the request status to ACCEPTED.

`ShpfyOrderFulfillments.Codeunit.al` handles actual fulfillment records (shipments). It imports fulfillment data including tracking info (number, URL, company) with support for multiple tracking entries per fulfillment -- the first entry goes into dedicated fields, and all entries are concatenated into comma-separated list fields. Fulfillment lines link back to order lines and track quantities. If a fulfillment contains gift card line items (detected via a FlowField), the gift card codes are fetched in a separate call.

## Things to know

- Fulfillment order headers use `Updated At` as a change-detection mechanism -- if the timestamp matches, only the lines are re-fetched, skipping the header update.
- The fulfillment service is lazily registered: `RegisterFulfillmentService` is called on the first fulfillment order sync if `Fulfillment Service Activated` is false. If Shopify no longer has the service (detected by `HasFulfillmentService`), the flag is reset to false on the shop.
- Fulfillment line items are paginated separately from the fulfillment itself -- after importing the main fulfillment, the code loops to fetch additional pages of `fulfillmentLineItems` using `GetNextOrderFulfillmentLines`.
- Both fulfillment order headers and order fulfillments clean up their associated `ShpfyDataCapture` records and child lines on delete.
- The `Request Status` enum (`ShpfyFFRequestStatus`) tracks the fulfillment service handshake: UNSUBMITTED, SUBMITTED, ACCEPTED, etc. Only assigned fulfillment orders with appropriate request status should be processed by BC.
