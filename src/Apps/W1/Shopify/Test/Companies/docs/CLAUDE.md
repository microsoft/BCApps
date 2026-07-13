# Companies

Tests for the Shopify B2B company sync -- importing, exporting, mapping, and managing company locations. This module is separate from the Customer tests because Shopify's B2B model treats companies as distinct entities with their own locations, payment terms, tax registration IDs, and contact roles. The boundary is anything involving the "Shpfy Company" and "Shpfy Company Location" records and their mapping to BC Customer records.

## How it works

ShpfyCompanyInitialize is the shared data factory. It creates company and location records, builds GraphQL result strings from resource files (CompanyCreateRequest.txt, CompanyUpdateRequest.txt, etc.), and provides helper methods for constructing JSON location responses. The `ModifyFields` method uses RecordRef to generically prepend "!" to all text fields on any record, which is used to simulate field changes for update tests.

ShpfyCompanyAPITest validates GraphQL query generation for create and update operations, including payment terms and tax registration IDs. It also tests field extraction from Shopify JSON responses (UpdateShopifyCustomerFields, UpdateShopifyCompanyFields). The HTTP-level tests for update operations use a simple handler that returns empty JSON and tracks which queries were executed.

ShpfyCompanyExportTest covers converting a BC Customer into Shopify company and location records via FillInShopifyCompany/FillInShopifyCompanyLocation, verifying address field mapping, payment terms propagation, and county/province handling (provinces are only sent for countries that have them -- tested by switching between US and DE).

ShpfyCompanyImportTest tests the inbound flow: importing a company with locations from Shopify (including payment terms and tax registration IDs), creating customers from companies, and updating customers from companies. It verifies all location fields are correctly imported from a dictionary-driven mock response.

ShpfyCompanyMappingTest is the most comprehensive file. It tests two mapping strategies -- DefaultCompany and "By Tax Id" -- across multiple scenarios: pre-existing customer SystemId, random/empty GUIDs, existing Shopify customers, and tax ID matching via both Registration No. and VAT Registration No. fields.

ShpfyCompanyLocationsTest tests creating company locations from customers, including sell-to/bill-to propagation and skip logic when a customer is already exported as a company or location (verified via Shpfy Skipped Record entries). ShpfyTaxIdMappingTest validates the tax registration ID mapping interface for both Registration No. and VAT Registration No. implementations, including get/set/filter operations and an event subscriber to bypass localization-specific VAT validation.

## Things to know

- B2B features are now unconditionally available on all Shopify plans. The old `Shop."B2B Enabled" := true` assignments have been removed from `ShpfyCompanyExportTest`, `ShpfyCompanyImportTest`, and `ShpfyCompanyLocationsTest`. Tests no longer need to set any plan-gating flag for B2B functionality.

*Updated: 2026-04-08 -- B2B Enabled removed from company tests; B2B features now unconditional*
- ShpfyCompanyInitialize.ModifyFields uses RecordRef/FieldRef reflection to generically modify all text fields, so tests can detect whether update queries include changed fields without manually setting each one.
- ShpfyTaxIdMappingTest uses manual event subscriber binding (BindSubscription) on `OnBeforeValidateVATRegistrationNo` to bypass localization-specific VAT validation that would otherwise reject test data.
- Company mapping tests exercise two distinct code paths: FindMapping (inbound -- does this Shopify company match a BC customer?) and DoMapping (outbound -- which customer should this company sync to?).
- The CompanyImport HTTP handler builds location responses dynamically from a Dictionary of [Text, Text] via `CompanyInitialize.CreateLocationResponse`, which constructs a nested JSON structure with billing address, payment terms, and tax registration ID.
- ShpfyCompanyLocationsTest verifies skip behavior by checking `Shpfy Skipped Record` entries with expected reason text, rather than asserting on error messages.
