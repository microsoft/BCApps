// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Enum Shpfy GraphQL Type (ID 30111).
/// Each value maps to a .graphql resource file in .resources/graphql/{Area}/{QueryName}.graphql.
/// The value name must follow the convention: {Area}_{QueryName} (e.g., Customers_GetCustomer).
///
/// To add a new query:
///   1. Create a .graphql file at .resources/graphql/{Area}/{QueryName}.graphql
///      Line 1: # cost: N   (expected Shopify API cost)
///      Line 2+: the JSON query body (e.g., {"query":"{ ... }"})
///   2. Add a new enum value below with the name {Area}_{QueryName}.
/// </summary>
enum 30111 "Shpfy GraphQL Type"
{
    Access = Internal;
    Caption = 'Shopify GraphQL Type';
    Extensible = false;

    value(0; Base_GetApiKey)
    {
        Caption = 'Get API Key';
    }
    value(1; Customers_GetCustomerIds)
    {
        Caption = 'Get Customer Ids';
    }
    value(2; Customers_GetNextCustomerIds)
    {
        Caption = 'Get Next Customer Ids';
    }
    value(3; Customers_GetCustomer)
    {
        Caption = 'Get Customer';
    }
    value(4; Orders_GetOrdersToImport)
    {
        Caption = 'Get Orders to Import';
    }
    value(5; "Orders_GetNextOrdersToImport")
    {
        Caption = 'Get Next Orders to Import';
    }
    value(6; Orders_OrderRisks)
    {
        Caption = 'Order Risks';
    }
    value(7; Orders_UpdateOrderAttributes)
    {
        Caption = 'Update Order Attributes';
    }
    value(8; Orders_GetOrderFulfillment)
    {
        Caption = 'Get Order Fulfillment';
    }
    value(9; Orders_GetNextOrderFulfillmentLines)
    {
        Caption = 'Get Next Order Fulfillment Lines';
    }
    value(10; Products_GetProductImages)
    {
        Caption = 'Get Product Images';
    }
    value(11; Products_GetNextProductImages)
    {
        Caption = 'Get Product Images';
    }
    value(12; Products_GetProductVariantImages)
    {
        Caption = 'Get Next Product Variant Images';
    }
    value(13; Products_GetNextProductVariantImages)
    {
        Caption = 'Get Next Product Variant Images';
    }
    value(14; Customers_FindCustomerIdByEMail)
    {
        Caption = 'Find Customer Id By E-Mail';
    }
    value(15; Customers_FindCustomerIdByPhone)
    {
        Caption = 'Find Customer Id By Phone';
    }
    value(16; Inventory_GetInventoryEntries)
    {
        Caption = 'Get Inventory Entries';
    }
    value(17; Inventory_GetNextInventoryEntries)
    {
        Caption = 'Get Next Inventory Entries';
    }
    value(18; Products_GetProductById)
    {
        Caption = 'Get Product By Id';
    }
    value(19; Products_GetProductIds)
    {
        Caption = 'Get Product Ids';
    }
    value(20; Products_GetNextProductIds)
    {
        Caption = 'Get Next Product Ids';
    }
    value(21; Products_FindVariantByBarcode)
    {
        Caption = 'Find Variant by Barcode';
    }
    value(22; Products_FindVariantBySKU)
    {
        Caption = 'Find Variant by SKU';
    }
    value(23; Products_GetProductVariantIds)
    {
        Caption = 'Get Product Variant Ids';
    }
    value(24; Products_GetNextProductVariantIds)
    {
        Caption = 'Get Next Product Variant Ids';
    }
    value(25; Products_GetVariantById)
    {
        Caption = 'Get Variant by Id';
    }
#if not CLEAN28
    value(26; GetLocationOfOrderLines)
    {
        Caption = 'Get Location of the Order Lines';
        ObsoleteReason = 'This request is no longer used.';
        ObsoleteState = Pending;
        ObsoleteTag = '28.0';
    }
#endif
    value(27; Inventory_ModifyInventory)
    {
        Caption = 'Modify Inventory';
    }
    value(28; Inventory_GetLocations)
    {
        Caption = 'Get Locations';
    }
    value(29; Inventory_GetNextLocations)
    {
        Caption = 'Get Next Locations';
    }
    value(30; Orders_GetOpenOrdersToImport)
    {
        Caption = 'Get Open Orders to Import';
    }
    value(31; "Orders_GetNextOpenOrdersToImport")
    {
        Caption = 'Get Next Open Orders to Import';
    }
    value(32; Orders_GetOrderHeader)
    {
        Caption = 'Get Order Header';
    }
    value(33; Orders_GetOrderLines)
    {
        Caption = 'Get Order Lines';
    }
    value(34; Orders_GetNextOrderLines)
    {
        Caption = 'Get Next Order Lines';
    }
    value(35; Shipping_GetShipmentLines)
    {
        Caption = 'Get Shipment Lines';
    }
    value(36; Shipping_GetNextShipmentLines)
    {
        Caption = 'Get Next Order Lines';
    }
    value(37; Orders_CloseOrder)
    {
        Caption = 'Close Order';
    }
    value(38; Products_CreateUploadUrl)
    {
        Caption = 'Create Upload URL';
    }
    value(39; Products_AddProductImage)
    {
        Caption = 'Add Product Image';
    }
    value(40; Products_UpdateProductImage)
    {
        Caption = 'Update Product Image';
    }
    value(41; Fulfillments_CreateFulfillmentService)
    {
        Caption = 'Create Fullfilment Service';
    }
    value(44; Fulfillments_GetOpenFulfillmentOrderLines)
    {
        Caption = 'Get Open Fullfilment Orders Lines';
    }
    value(45; Fulfillments_GetNextOpenFulfillmentOrderLines)
    {
        Caption = 'Get Open Fullfilment Orders Lines';
    }
    value(46; Customers_GetAllCustomerIds)
    {
        Caption = 'Get All Customer Ids';
    }
    value(47; Customers_GetNextAllCustomerIds)
    {
        Caption = 'Get Next All Customer Ids';
    }
    value(48; Fulfillments_GetFulfillmentOrdersFromOrder)
    {
        Caption = 'Get Fulfillment Orders From Order';
    }
    value(49; Fulfillments_GetNextFulfillmentOrdersFromOrder)
    {
        Caption = 'Get Next Fulfillment Orders From Order';
    }
    value(50; Returns_NextOrderReturns)
    {
        Caption = 'Next Order Returns';
    }
    value(51; Returns_GetReturnHeader)
    {
        Caption = 'Get Return Header';
    }
    value(52; Returns_GetReturnLines)
    {
        Caption = 'Get Return Lines';
    }
    value(53; Returns_GetNextReturnLines)
    {
        Caption = 'Get Next Return Lines';
    }
    value(54; Refunds_GetRefundHeader)
    {
        Caption = 'Get Refund Header';
    }
    value(55; Refunds_GetRefundLines)
    {
        Caption = 'Get Refund Lines';
    }
    value(56; Refunds_GetNextRefundLines)
    {
        Caption = 'Get Next Refund Lines';
    }
    value(58; BulkOperations_RunBulkOperationMutation)
    {
        Caption = 'Run Bulk Operation Mutation';
    }
    value(59; BulkOperations_GetBulkOperation)
    {
        Caption = 'Get Bulk Operation';
    }
    value(60; Companies_CompanyAssignCustomerAsContact)
    {
        Caption = 'Company Assign Customer As Contact';
    }
    value(61; Companies_CompanyAssignMainContact)
    {
        Caption = 'Company Assign Main Contact';
    }
    value(62; Companies_CompanyAssignContactRole)
    {
        Caption = 'Company Assign Contact Role';
    }
    value(63; Catalogs_GetCatalogs)
    {
        Caption = 'Get Catalogs';
    }
    value(64; Catalogs_GetNextCatalogs)
    {
        Caption = 'Next Get Catalogs';
    }
    value(65; Catalogs_CreateCatalog)
    {
        Caption = 'Create Catalog';
    }
    value(66; Catalogs_CreatePublication)
    {
        Caption = 'Create Publication';
    }
    value(67; Catalogs_GetCatalogPrices)
    {
        Caption = 'Get Catalog Prices';
    }
    value(68; Catalogs_GetNextCatalogPrices)
    {
        Caption = 'Get Next Catalog Prices';
    }
    value(69; Catalogs_UpdateCatalogPrices)
    {
        Caption = 'Update Catalog Prices';
    }
    value(70; Companies_GetCompanyIds)
    {
        Caption = 'Get Company Ids';
    }
    value(71; Companies_GetNextCompanyIds)
    {
        Caption = 'Get Next Company Ids';
    }
    value(72; Companies_GetCompany)
    {
        Caption = 'Get Company';
    }
    value(73; Orders_MarkOrderAsPaid)
    {
        Caption = 'Mark Order As Paid';
    }
    value(74; Orders_OrderCancel)
    {
        Caption = 'Order Cancel';
    }
    value(75; Catalogs_CreatePriceList)
    {
        Caption = 'Create Price List';
    }
    value(76; Catalogs_GetCatalogProducts)
    {
        Caption = 'Get Catalog Products';
    }
    value(77; Catalogs_GetNextCatalogProducts)
    {
        Caption = 'Get Next Catalog Products';
    }
    value(78; Payments_GetOrderTransactions)
    {
        Caption = 'Get Order Transactions';
    }
    value(80; Orders_DraftOrderComplete)
    {
        Caption = 'Draft Order Complete';
    }
    value(81; Fulfillments_FulfillOrder)
    {
        Caption = 'Fulfill Order';
    }
    value(82; Payments_GetPaymentTerms)
    {
        Caption = 'Get Payment Terms';
    }
    value(83; Fulfillments_GetFulfillmentOrderIds)
    {
        Caption = 'Get Fulfillments';
    }
    value(84; Fulfillments_GetNextFulfillmentOrderIds)
    {
        Caption = 'Get Next Fulfillments';
    }
    value(86; Products_GetProductOptions)
    {
        Caption = 'Get Product Options';
    }
    value(87; Returns_GetReverseFulfillmentOrders)
    {
        Caption = 'Get Reverse Fulfillment Orders';
    }
    value(88; Returns_GetNextReverseFulfillmentOrders)
    {
        Caption = 'Get Next Reverse Fulfillment Orders';
    }
    value(89; Returns_GetReverseFulfillmentOrderLines)
    {
        Caption = 'Get Reverse Fulfillment Order Lines';
    }
    value(90; Returns_GetNextReverseFulfillmentOrderLines)
    {
        Caption = 'Get Next Reverse Fulfillment Order Lines';
    }
    value(91; Base_TranslationsRegister)
    {
        Caption = 'Translations Register';
    }
    value(92; Base_ShopLocales)
    {
        Caption = 'Shop Locales';
    }
    value(93; Base_GetTranslResource)
    {
        Caption = 'Get Transl Resource';
    }
    value(94; Metafields_MetafieldSet)
    {
        Caption = 'MetfieldSet';
    }
    value(95; Metafields_ProductMetafieldIds)
    {
        Caption = 'Product Metafield Ids';
    }
    value(96; Metafields_VariantMetafieldIds)
    {
        Caption = 'Variant Metafield Ids';
    }
    value(97; Products_GetProductImage)
    {
        Caption = 'Get Product Image';
    }
    value(98; Companies_CreateCompanyLocationTaxId)
    {
        Caption = 'Create Company Location Tax Id';
    }
    value(99; Companies_UpdateCompanyLocationPaymentTerms)
    {
        Caption = 'Update Company Location Payment Terms';
    }
    value(100; Companies_GetCompanyLocations)
    {
        Caption = 'Company Locations';
    }
    value(101; Base_GetSalesChannels)
    {
        Caption = 'Get Sales Channels';
    }
    value(102; Base_GetNextSalesChannels)
    {
        Caption = 'Get Next Sales Channels';
    }
    value(103; Metafields_CustomerMetafieldIds)
    {
        Caption = 'Customer Metafield Ids';
    }
    value(104; Metafields_CompanyMetafieldIds)
    {
        Caption = 'Company Metafield Ids';
    }
    value(105; Shipping_GetDeliveryProfiles)
    {
        Caption = 'Get Delivery Profiles';
    }
    value(106; Shipping_GetNextDeliveryProfiles)
    {
        Caption = 'Get Next Delivery Profiles';
    }
    value(107; Inventory_GetLocationGroups)
    {
        Caption = 'Get Location Groups';
    }
    value(108; Shipping_GetDeliveryMethods)
    {
        Caption = 'Get Delivery Methods';
    }
    value(109; Shipping_GetNextDeliveryMethods)
    {
        Caption = 'Get Next Delivery Methods';
    }
    value(110; Metafields_GetMetafieldDefinitions)
    {
        Caption = 'Get Metafield Definitions';
    }
    value(111; Inventory_InventoryActivate)
    {
        Caption = 'Inventory Activate';
    }
    value(112; Payments_GetPaymentTransactions)
    {
        Caption = 'Get Payment Transactions';
    }
    value(113; Payments_GetNextPaymentTransactions)
    {
        Caption = 'Get Next Payment Transactions';
    }
    value(114; Payments_GetDisputes)
    {
        Caption = 'Get Disputes';
    }
    value(115; Payments_GetNextDisputes)
    {
        Caption = 'Get Next Disputes';
    }
    value(116; Payments_GetPayouts)
    {
        Caption = 'Get Payouts';
    }
    value(117; Payments_GetNextPayouts)
    {
        Caption = 'Get Next Payouts';
    }
    value(118; Payments_GetDisputeById)
    {
        Caption = 'Get Dispute By Id';
    }
    value(119; Base_CreateWebhookSubscription)
    {
        Caption = 'Create Webhook Subscription';
    }
    value(120; Base_GetWebhookSubscriptions)
    {
        Caption = 'Get Webhook Subscriptions';
    }
    value(121; Base_DeleteWebhookSubscription)
    {
        Caption = 'Delete Webhook Subscription';
    }
    value(122; Shipping_GetShipToCountries)
    {
        Caption = 'Get Ship To Countries';
    }
    value(123; Refunds_GetRefundShippingLines)
    {
        Caption = 'Get Refund Shipping Lines';
    }
    value(124; Refunds_GetNextRefundShippingLines)
    {
        Caption = 'Get Next Refund Shipping Lines';
    }
    value(125; Companies_GetNextCompanyLocations)
    {
        Caption = 'Next Get Company Locations';
    }
    value(126; Products_UpdateProductOption)
    {
        Caption = 'Update Product Option';
    }
    value(127; Base_GetStaffMembers)
    {
        Caption = 'Get Staff Members';
    }
    value(128; Base_GetNextStaffMembers)
    {
        Caption = 'Get Next Staff Members';
    }
    value(129; Catalogs_GetMarketCatalogs)
    {
        Caption = 'Get Market Catalogs';
    }
    value(130; Catalogs_GetNextMarketCatalogs)
    {
        Caption = 'Next Get Market Catalogs';
    }
    value(131; Catalogs_GetCatalogMarkets)
    {
        Caption = 'Get Catalog Markets';
    }
    value(132; Catalogs_GetNextCatalogMarkets)
    {
        Caption = 'Next Get Catalog Markets';
    }
    value(133; Companies_GetCompanyLocation)
    {
        Caption = 'Get Company Location';
    }
    value(134; Fulfillments_UpdateFulfillmentService)
    {
        Caption = 'Update Fulfillment Service';
    }
    value(135; Inventory_GetLocation)
    {
        Caption = 'Get Location';
    }
    value(136; Fulfillments_GetAssignedFulfillmentOrders)
    {
        Caption = 'Get Assigned Fulfillment Orders';
    }
    value(137; Fulfillments_GetNextAssignedFulfillmentOrders)
    {
        Caption = 'Get Next Assigned Fulfillment Orders';
    }
    value(138; Fulfillments_AcceptFulfillmentRequest)
    {
        Caption = 'Accept Fulfillment Request';
    }
    value(139; Products_GetCustomProductCollections)
    {
        Caption = 'Get Custom Product Collections';
    }
    value(140; Products_GetNextCustomProductCollections)
    {
        Caption = 'Get Next Custom Product Collections';
    }
    value(141; Products_GetVariantImage)
    {
        Caption = 'Get Variant Image';
    }
    value(142; Products_AddVariantImage)
    {
        Caption = 'Add Variant Image';
    }
    value(143; Products_UpdateProdWithImage)
    {
        Caption = 'Update Product With Image';
    }
    value(144; Products_SetVariantImage)
    {
        Caption = 'Set Variant Image';
    }

    value(145; Payments_GetPaymTransByIds)
    {
        Caption = 'Get Payment Transactions By Ids';
    }
    value(146; Payments_GetPayoutsByIds)
    {
        Caption = 'Get Payouts By Ids';
    }
    value(147; Fulfillments_HasFulfillmentService)
    {
        Caption = 'Has Fulfillment Service';
    }
}
