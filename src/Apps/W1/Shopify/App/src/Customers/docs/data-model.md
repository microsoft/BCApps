# Data model

## Overview

The customer data model bridges Shopify's person-centric customer records with BC's account-centric Customer table. A Shopify customer has addresses, tags, and optional marketing consent. On the BC side, this maps to a Customer record plus whatever address and posting configuration the selected template provides.

## Customer records

`Shpfy Customer` (table 30105) holds the Shopify customer's identity: first name, last name, email, phone, marketing consent, tax exemption, verified email flag, and the `State` enum (Disabled/Invited/Enabled/Declined). The BC link is `Customer SystemId` -- a Guid pointing to the BC Customer record, with `Customer No.` as a FlowField resolved from it.

The `Shop Id` field is a Shopify-side integer identifying which shop the customer belongs to. This is indexed (`Idx2`) and used during BCToShopify mapping to scope customer lookups to the correct shop. It is not the same as `Shop Code` -- the customer table does not carry the shop code directly.

The `Note` field is a Blob storing arbitrary text notes. The `OnDelete` trigger cascades to addresses, tags, and metafields.

## Addresses

`Shpfy Customer Address` (table 30106) stores each address associated with a customer. Each address has its own Shopify BigInteger ID, plus company name, first/last name, two address lines, city, zip, country/region code, province code/name, and phone.

The `Default` Boolean flag marks the primary address. On insert, if no other address for that customer is marked as default, the new address automatically becomes default. The `OnInsert` trigger also implements a negative auto-increment pattern: when `Id` is 0 (meaning this is a locally-created address not yet synced to Shopify), it assigns `Min(-1, smallest existing Id - 1)`. This ensures locally-created addresses never collide with Shopify-assigned positive IDs.

The `CustomerSystemId` field and `Customer No.` FlowField provide a direct link from the address to the BC Customer, independent of the parent Shopify customer's mapping. This allows address-level resolution during order processing.

## Tax areas

`Shpfy Tax Area` (table 30109) maps Shopify's country + county combinations to BC tax configuration. Its composite primary key is `(Country/Region Code, County)`. Each row specifies a `Tax Area Code`, `Tax Liable` flag, `VAT Bus. Posting Group`, and `County Code`. A secondary index on `(Country/Region Code, County Code)` supports lookups where the province code is known but the full county name is not. This table is primarily relevant for US/CA tax scenarios where each state/province has distinct tax rules.

## Customer templates

`Shpfy Customer Template` (table 30107) drives auto-creation of BC Customers. Keyed by `(Shop Code, Country/Region Code)`, it specifies a `Customer Templ. Code` (BC's customer template) and a `Default Customer No.` (a fallback BC Customer for mapping strategies that use it). When a new Shopify customer arrives from a country that matches a template row, the connector applies that template to create the BC Customer with the correct posting groups, payment terms, and other defaults.

## Province (obsolete)

`Shpfy Province` (table 30108) was the original province-to-county mapping table but has been removed (ObsoleteState = Removed, tag 25.0) and replaced by `Shpfy Tax Area`. Code under `CLEANSCHEMA25` guards retains the schema for upgrade compatibility only.
