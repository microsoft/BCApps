# Data model

## Overview

The order data model is a two-tier staging system. Lightweight "Orders to Import" records serve as a preview/filter layer, while the full Order Header/Line structure holds the complete Shopify order data for processing into BC sales documents. The design deliberately denormalizes address data and duplicates every monetary field in two currencies.

## Staging: Orders to Import

The `Shpfy Orders to Import` table (`ShpfyOrdersToImport.Table.al`) is a polling cache. It is keyed by an auto-incrementing Entry No. and carries the Shopify Order Id plus summary fields: order amount, financial status, fulfillment status, risk level, tags, and country codes for all three address types. The `Import Action` field (New or Update) tells the user whether this order already exists as an Order Header.

This table is intentionally disposable. Records here are created during the API poll and consumed when the user triggers import. The `Has Error` flag with a Blob error message captures import failures without blocking other orders.

## Order Header

The `Shpfy Order Header` table (`ShpfyOrderHeader.Table.al`) is the central order record, keyed by `Shopify Order Id` (BigInteger). It contains three complete inline address blocks -- sell-to, ship-to, and bill-to -- each with first name, last name, full name, address 1/2, city, post code, country/region code, country/region name, and county. The ship-to block additionally carries latitude/longitude. This denormalization exists because Shopify orders can have different addresses for each role, and they need to be preserved exactly as received.

Every monetary amount exists in two versions: shop currency and presentment currency. Fields like `Total Amount` / `Presentment Total Amount`, `Subtotal Amount` / `Presentment Subtotal Amount`, `VAT Amount` / `Presentment VAT Amount`, etc. run in parallel. The `Currency Code` and `Presentment Currency Code` fields identify which currencies these represent. The `Processed Currency Handling` field records which currency set was actually used when the sales document was created, so the system knows how to interpret amounts on already-processed orders.

The processing lifecycle is tracked via `Sales Order No.` (or `Sales Invoice No.`), `Processed` (boolean), `Has Error`, `Error Message`, and `Has Order State Error`. The `Processed` flag is set when a sales document is successfully created. `Has Order State Error` is set when a re-imported order differs from what was already processed -- this is a conflict that the user must resolve manually.

B2B orders carry additional Company fields (`Company Id`, `Company Location Id`, `Company Main Contact Id`, email, phone) that feed into the B2B customer mapping flow.

## Order Lines

The `Shpfy Order Line` table (`ShpfyOrderLine.Table.al`) is keyed by `(Shopify Order Id, Line Id)`. Each line carries the Shopify Product Id and Variant Id for mapping, plus `Item No.`, `Variant Code`, and `Unit of Measure Code` which are populated during order mapping. The `Gift Card` and `Tip` boolean flags control routing: gift card lines go to the Sold Gift Card Account, tip lines go to the Tip Account, and regular lines become Item-type sales lines.

Lines also have dual-currency pricing: `Unit Price` / `Presentment Unit Price` and `Discount Amount` / `Presentment Discount Amount`. The `Location Id` field links to a Shopify location for warehouse mapping via Shop Locations.

## Supporting tables

`Shpfy Order Attribute` and `Shpfy Order Line Attribute` store Shopify custom attributes as key-value pairs. `Shpfy Order Tax Line` stores tax breakdowns keyed by a Parent Id (which can be either an Order Header Id or an Order Line Id, making it polymorphic). `Shpfy Order Shipping Charges` holds per-shipping-line amounts. `Shpfy Order Discount Application` tracks discount allocations. `Shpfy Order Payment Gateway` records which payment gateway was used.

## BC document extensions

Table extensions on Sales Header, Sales Line, and their posted/archived counterparts add `Shpfy Order Id`, `Shpfy Order No.`, `Shpfy Order Line Id`, and `Shpfy Refund Id` fields. A separate `Shpfy Doc. Link To Doc.` table tracks the many-to-one relationship between Shopify documents (orders, refunds) and BC documents (sales orders, credit memos), enabling the processed-order detection logic.
