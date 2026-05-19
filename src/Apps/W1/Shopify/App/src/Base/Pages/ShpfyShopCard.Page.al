// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Setup;
using System.DateTime;
using System.Environment;
using System.Telemetry;

/// <summary>
/// Page Shpfy Shop Card (ID 30101).
/// </summary>
page 30101 "Shpfy Shop Card"
{
    Caption = 'Shopify Shop Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Related,Synchronization';
    SourceTable = "Shpfy Shop";
    UsageCategory = None;
    AboutTitle = 'About Shopify shop details';
    AboutText = 'Set up your Shopify shop and integrate it with Business Central. Specify which data to synchronize back and forth, such as items, inventory status, customers and orders.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    AboutTitle = 'Name your shop';
                    AboutText = 'Give your shop a name that will make it easy to find in Business Central. For example, a name might reflect what a shop sells, such as Furniture or Coffee, or the country or region it serves.';
                }
                field("Shopify URL"; Rec."Shopify URL")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    Importance = Promoted;
                    AboutTitle = 'Get people to your shop';
                    AboutText = 'Provide the URL that people will use to access your shop. For example, *https://myshop.myshopify.com*.';

                    trigger OnValidate()
                    begin
                        Rec.TestField(Enabled, false);
                        if Rec."Code" <> '' then
                            CurrPage.SaveRecord();
                    end;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    Importance = Promoted;
                    AboutTitle = 'Ready to connect the shop';
                    AboutText = 'We just need the shop name and URL to connect it to Shopify. When you have checked all shop settings, enable the connection here.';

                    trigger OnValidate()
                    var
                        FeatureTelemetry: Codeunit "Feature Telemetry";
                        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
                    begin
                        if not Rec.Enabled then
                            exit;
                        Rec.RequestAccessToken();
                        BulkOperationMgt.EnableBulkOperations(Rec);
                        Rec.GetShopSettings();
                        Rec.SyncCountries();
                        FeatureTelemetry.LogUptake('0000HUT', 'Shopify', Enum::"Feature Uptake Status"::"Set up");
                    end;
                }
                field(HasAccessKey; Rec.HasAccessToken())
                {
                    ApplicationArea = All;
                    Caption = 'Has access token';
                    Importance = Additional;
                    ShowMandatory = true;
                    ToolTip = 'Specifies if an API access token is available for this store. The token allows the connector to access your shop''s data as long as the app is installed. To acquire a token, turn on the Enabled toggle or use the Request Access action.';
                }
                field(CurrencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field(LanguageCode; Rec."Language Code")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field(LoggingMode; Rec."Logging Mode")
                {
                    ApplicationArea = All;
                }
                field(AllowBackgroudSyncs; Rec."Allow Background Syncs")
                {
                    ApplicationArea = All;
                }
                field("Allow Outgoing Requests"; Rec."Allow Outgoing Requests")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field("Shopify Admin API Version"; ApiVersion)
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    Caption = 'Shopify Admin API Version';
                    ToolTip = 'Specifies the version of Shopify Admin API used by current version of the Shopify connector.';
                    Editable = false;
                }
                field("API Version Expiry Date"; ApiVersionExpiryDate)
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    Caption = 'Update API Version Before';
                    ToolTip = 'Specifies the date on which Business Central will no longer support Shopify Admin API version. To continue to use your integration, upgrade to the latest version of Business Central before this date.';
                    Editable = false;
                }
            }
            group(ItemSync)
            {
                Caption = 'Item/Product Synchronization';
                AboutTitle = 'Set up synchronization for items';
                AboutText = '**Products** in Shopify are called **Items** in Business Central. Define how to synchronize items in *this* shop with Business Central. If one of the apps doesn''t have this data, you can quickly export items from Business Central to Shopify and vice versa.';

                field(SyncItem; Rec."Sync Item")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                }
                field(AutoCreateUnknownItems; Rec."Auto Create Unknown Items")
                {
                    ApplicationArea = All;
                }
                field(ShopifyCanUpdateItems; Rec."Shopify Can Update Items")
                {
                    ApplicationArea = All;
                }
                field(CanUpdateShopifyProducts; Rec."Can Update Shopify Products")
                {
                    ApplicationArea = All;
                    Editable = Rec."Sync Item" = rec."Sync Item"::"To Shopify";
                }
                field(ItemTemplCode; Rec."Item Templ. Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    Editable = Rec."Auto Create Unknown Items";
                }
                field(SyncItemImages; Rec."Sync Item Images")
                {
                    ApplicationArea = All;
                }
                field(SyncItemExtendedText; Rec."Sync Item Extended Text")
                {
                    ApplicationArea = All;
                }
                field(SyncItemMarketingText; Rec."Sync Item Marketing Text")
                {
                    ApplicationArea = All;
                }
                field(SyncItemAttributes; Rec."Sync Item Attributes")
                {
                    ApplicationArea = All;
                }
                field(SyncHSCodeAndCountry; Rec."Sync HS Code and Country")
                {
                    ApplicationArea = All;
                }
                field(UOMAsVariant; Rec."UoM as Variant")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(OptionNameForUOM; Rec."Option Name for UoM")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(VariantPrefix; Rec."Variant Prefix")
                {
                    ApplicationArea = All;
                    Editable = (Rec."SKU Mapping" = Rec."SKU Mapping"::"Variant Code") or (Rec."SKU Mapping" = Rec."SKU Mapping"::"Item No. + Variant Code");
                }
                field(SKUType; Rec."SKU Mapping")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                }
                field(SKUFieldSeparator; Rec."SKU Field Separator")
                {
                    ApplicationArea = All;
                    Editable = Rec."SKU Mapping" = Rec."SKU Mapping"::"Item No. + Variant Code";
                }
                field(FindMappingByBarcode; Rec."Find Mapping by Barcode")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(InventoryTracket; Rec."Inventory Tracked")
                {
                    ApplicationArea = All;
                }
                field(DefaultInventoryPolicy; Rec."Default Inventory Policy")
                {
                    ApplicationArea = All;
                }
                field(CreateProductStatusValue; Rec."Status for Created Products")
                {
                    ApplicationArea = All;
                }
                field(RemoveProductAction; Rec."Action for Removed Products")
                {
                    ApplicationArea = All;
                }
#if not CLEAN26
                field("Items Mapped to Products"; Rec."Items Mapped to Products")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ObsoleteReason = 'This setting is not used.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '26.0';
                }
#endif
                field(WeightUnit; Rec."Weight Unit")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field("Product Metafields To Shopify"; Rec."Product Metafields To Shopify")
                {
                    ApplicationArea = All;
                }
            }
            group(PriceSynchronization)
            {
                Caption = 'Price Synchronization';
                field(CustomerPriceGroup; Rec."Customer Price Group")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                }
                field(CustomerDiscountGroup; Rec."Customer Discount Group")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    Editable = Rec."Prices Including VAT";
                }
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("VAT Country/Region Code"; Rec."VAT Country/Region Code")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Sync Prices"; Rec."Sync Prices")
                {
                    ApplicationArea = All;
                }
            }
            group(CustomerSync)
            {
                Caption = 'Customer Synchronization';
                AboutTitle = 'Set up synchronization for customers';
                AboutText = 'Specify how to synchronize customers between Shopify and Business Central. You can auto-create Shopify customers on Business Central or use the same customer entity for every sales order. When connected, Business Central can also update customer information in Shopify.';
                field(CustomerImportFromShopify; Rec."Customer Import From Shopify")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                }
                field(CustomerMappingType; Rec."Customer Mapping Type")
                {
                    ApplicationArea = All;
                }
                field(AutoCreateUnknownCustomers; Rec."Auto Create Unknown Customers")
                {
                    ApplicationArea = All;
                }
                field(CustomerTemplCode; Rec."Customer Templ. Code")
                {
                    ShowMandatory = true;
                    ApplicationArea = All;
                }
                field(DefaultCustomer; Rec."Default Customer No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                }
                field(ShopifyCanUpdateCustomer; Rec."Shopify Can Update Customer")
                {
                    ApplicationArea = All;
                }
                field(CanUpdateShopifyCustomer; Rec."Can Update Shopify Customer")
                {
                    ApplicationArea = All;
                }

                field(NameSource; Rec."Name Source")
                {
                    ApplicationArea = All;
                }
                field(Name2Source; Rec."Name 2 Source")
                {
                    ApplicationArea = All;
                }
                field(ContactSource; Rec."Contact Source")
                {
                    ApplicationArea = All;
                }
                field(CountySource; Rec."County Source")
                {
                    ApplicationArea = All;
                }
                field("Customer Metafields To Shopify"; Rec."Customer Metafields To Shopify")
                {
                    ApplicationArea = All;
                }
            }
            group("B2B Company Synchronization")
            {
                field("Company Import From Shopify"; Rec."Company Import From Shopify")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                }
                field("Company Mapping Type"; Rec."Company Mapping Type")
                {
                    ApplicationArea = All;
                }
                field("Shpfy Comp. Tax Id Mapping"; Rec."Shpfy Comp. Tax Id Mapping")
                {
                    ApplicationArea = All;
                }
                field("Auto Create Unknown Companies"; Rec."Auto Create Unknown Companies")
                {
                    ApplicationArea = All;
                }
                field("Default Company No."; Rec."Default Company No.")
                {
                    ApplicationArea = All;
                }
                field("Shopify Can Update Companies"; Rec."Shopify Can Update Companies")
                {
                    ApplicationArea = All;
                }
                field("Can Update Shopify Companies"; Rec."Can Update Shopify Companies")
                {
                    ApplicationArea = All;
                }
                field("Default Customer Permission"; Rec."Default Contact Permission")
                {
                    ApplicationArea = All;
                }
                field("Auto Create Catalog"; Rec."Auto Create Catalog")
                {
                    ApplicationArea = All;
                    Visible = Rec."Advanced Shopify Plan";
                }
                field("Company Metafields To Shopify"; Rec."Company Metafields To Shopify")
                {
                    ApplicationArea = All;
                }
            }
            group(OrderProcessing)
            {
                Caption = 'Order Synchronization and Processing';
                AboutTitle = 'Set up your order flow';
                AboutText = 'Define how new orders in Shopify flow into Business Central. For example, you can require that Shopify orders are approved before they become a sales order or invoice in Business Central. You can also define how to post shipping revenue, and the address that determines where you pay taxes.';
                field(AutoSyncOrders; Rec."Order Created Webhooks")
                {
                    ApplicationArea = All;
                    Editable = Rec.Enabled;
                }
                field(SyncOrderJobQueueUser; Rec."Order Created Webhook User")
                {
                    ApplicationArea = All;
                }
                field(ShippingCostAccount; Rec."Shipping Charges Account")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    Importance = Promoted;
                }
                field(SoldGiftCardAccount; Rec."Sold Gift Card Account")
                {
                    ApplicationArea = All;
                }
                field(TipAccount; Rec."Tip Account")
                {
                    ApplicationArea = All;
                }
                field(CashRoundingsAccount; Rec."Cash Roundings Account")
                {
                    ApplicationArea = All;
                }
                field(AutoCreateOrders; Rec."Auto Create Orders")
                {
                    ApplicationArea = All;
                }
                field("Create Invoices From Orders"; Rec."Create Invoices From Orders")
                {
                    ApplicationArea = All;
                }
                field(UseShopifyOrderNo; Rec."Use Shopify Order No.")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        NoSeries: Record "No. Series";
                        ManualNosNotEnabledQst: Label 'The number series %1 does not have Manual Nos. enabled. Do you want to continue?', Comment = '%1 = No. Series Code';
                    begin
                        if not Rec."Use Shopify Order No." then
                            exit;

                        SalesReceivablesSetup.Get();

                        if NoSeries.Get(SalesReceivablesSetup."Order Nos.") then
                            if not NoSeries."Manual Nos." then
                                if Confirm(ManualNosNotEnabledQst, false, SalesReceivablesSetup."Order Nos.") then
                                    exit
                                else begin
                                    Rec."Use Shopify Order No." := false;
                                    exit;
                                end;

                        if Rec."Create Invoices From Orders" then
                            if NoSeries.Get(SalesReceivablesSetup."Invoice Nos.") then
                                if not NoSeries."Manual Nos." then
                                    if not Confirm(ManualNosNotEnabledQst, false, SalesReceivablesSetup."Invoice Nos.") then begin
                                        Rec."Use Shopify Order No." := false;
                                        exit;
                                    end;
                    end;
                }
                field(ShopifyOrderNoOnDocLine; Rec."Shopify Order No. on Doc. Line")
                {
                    ApplicationArea = All;
                }
                field("Order Attributes To Shopify"; Rec."Order Attributes To Shopify")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Allow Outgoing Requests" or Rec."Order Attributes To Shopify";
                }
                field(TaxAreaSource; Rec."Tax Area Priority")
                {
                    ApplicationArea = All;
                }
                field("Currency Handling"; Rec."Currency Handling")
                {
                    ApplicationArea = All;
                }
                field(AutoReleaseSalesOrders; Rec."Auto Release Sales Orders")
                {
                    ApplicationArea = All;
                }
                field(ArchiveProcessOrders; Rec."Archive Processed Orders")
                {
                    ApplicationArea = All;
                }
                field(SendShippingConfirmation; Rec."Send Shipping Confirmation")
                {
                    ApplicationArea = All;
                }
                field("Posted Invoice Sync"; Rec."Posted Invoice Sync")
                {
                    ApplicationArea = All;
                }
            }
            group(ReturnsAndRefunds)
            {
                Caption = 'Return and Refund Processing';
                AboutText = 'Define how Returns and Refunds in Shopify flow into Business Central.';

                field("Return and Refund Process"; Rec."Return and Refund Process")
                {
                    ApplicationArea = All;
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                group(HandlingOfReturns)
                {
                    ShowCaption = false;
                    Visible = IsReturnRefundsVisible;

                    field("Return Location Priority"; Rec."Return Location Priority")
                    {
                        ApplicationArea = All;
                    }
                    field("Process Returns As"; Rec."Process Returns As")
                    {
                        ApplicationArea = All;
                    }
                    field("Location Code of Returns"; Rec."Return Location")
                    {
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;
                    }

                    field("G/L Account Instead of Item"; Rec."Refund Acc. non-restock Items")
                    {
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;
                    }
                    field("G/L Account for Amt. diff."; Rec."Refund Account")
                    {
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            CurrPage.Update(true);
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Locations)
            {
                ApplicationArea = All;
                Caption = 'Locations';
                Image = Bins;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = page "Shpfy Shop Locations Mapping";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'View the Shopify Shop locations and link them with the related location(s).';
            }
            action(Products)
            {
                ApplicationArea = All;
                Caption = 'Products';
                Image = Item;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = page "Shpfy Products";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'Add, view or edit detailed information for the products that you trade in through Shopify. ';
            }
            action(ShipmentMethods)
            {
                ApplicationArea = All;
                Caption = 'Shipment Method Mapping';
                Image = Translate;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Maps the Shopify shipment methods to the related shipment methods.';

                trigger OnAction()
                var
                    ShipmentMethod: Record "Shpfy Shipment Method Mapping";
                    Shop: Record "Shpfy Shop";
                    ShipmentMethods: Codeunit "Shpfy Shipping Methods";
                begin
                    CurrPage.SaveRecord();
                    Shop := Rec;
                    Shop.SetRecFilter();
                    ShipmentMethods.GetShippingMethods(Shop);
                    ShipmentMethod.SetRange("Shop Code", Rec.Code);
                    Page.Run(Page::"Shpfy Shipment Methods Mapping", ShipmentMethod);
                end;
            }
            action(PaymentMethods)
            {
                ApplicationArea = All;
                Caption = 'Payment Method Mapping';
                Image = SetupPayment;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = page "Shpfy Payment Methods Mapping";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'Maps the Shopify payment methods to the related payment methods and prioritize them.';
            }
            action(PaymentTerms)
            {
                ApplicationArea = All;
                Caption = 'Payment Terms Mapping';
                Image = SuggestPayment;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = page "Shpfy Payment Terms Mapping";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'Maps the Shopify payment terms to the related payment terms and prioritize them.';
            }
            action(Orders)
            {
                ApplicationArea = All;
                Caption = 'Orders';
                Image = OrderList;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'View your Shopify agreements with customers to sell certain products on certain delivery and payment terms.';

                trigger OnAction()
                var
                    OrderHeader: Record "Shpfy Order Header";
                    Orders: Page "Shpfy Orders";
                begin
                    OrderHeader.SetRange("Shop Code", Rec.Code);
                    Orders.SetTableView(OrderHeader);
                    Orders.Run();
                end;
            }
            action(Refunds)
            {
                ApplicationArea = All;
                Caption = 'Refunds';
                Image = OrderList;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'View your Shopify refunds.';

                trigger OnAction()
                var
                    RefundHeader: Record "Shpfy Refund Header";
                    RefundHeaders: Page "Shpfy Refunds";
                begin
                    RefundHeader.SetRange("Shop Code", Rec.Code);
                    RefundHeaders.SetTableView(RefundHeader);
                    RefundHeaders.Run();
                end;
            }
            action(Returns)
            {
                ApplicationArea = All;
                Caption = 'Returns';
                Image = OrderList;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'View your Shopify returns.';

                trigger OnAction()
                var
                    ReturnHeader: Record "Shpfy Return Header";
                    ReturnHeaders: Page "Shpfy Returns";
                begin
                    ReturnHeader.SetRange("Shop Code", Rec.Code);
                    ReturnHeaders.SetTableView(ReturnHeader);
                    ReturnHeaders.Run();
                end;
            }
            action(Customers)
            {
                ApplicationArea = All;
                Caption = 'Customers';
                Image = Customer;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Shpfy Customers";
                RunPageLink = "Shop Id" = field("Shop Id");
                ToolTip = 'Add, view or edit detailed information for the customers. ';
            }
            action(CustomerTemplates)
            {
                ApplicationArea = All;
                Caption = 'Customer Setup by Country/Region';
                Image = Template;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = page "Shpfy Customer Templates";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'Set up default customer accounts or templates per country or regions. The designated default customer account for a specific country or region will take precedence over the value in the Shopify Shop card page. When a missing customer is created, the appropriate template according to the customer''s address is selected. Additionally, you may specify tax settings by county or province to ensure more accurate tax calculations.';
            }
            action(Companies)
            {
                ApplicationArea = All;
                Caption = 'Companies';
                Image = Company;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Shpfy Companies";
                RunPageLink = "Shop Id" = field("Shop Id");
                ToolTip = 'Add, view or edit detailed information for the companies.';
            }
            action(Catalogs)
            {
                ApplicationArea = All;
                Caption = 'B2B Catalogs';
                Image = ItemGroup;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Shpfy Catalogs";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'View a list of Shopify B2B catalogs for the shop.';
                Visible = Rec."Advanced Shopify Plan";
            }
            action(MarketCatalogs)
            {
                ApplicationArea = All;
                Caption = 'Market Catalogs';
                Image = ItemGroup;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Shpfy Market Catalogs";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'View a list of Shopify market catalogs for the shop.';
            }
            action(Languages)
            {
                ApplicationArea = All;
                Caption = 'Languages';
                Image = Translations;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Shpfy Languages";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'View a list of Shopify Languages for the shop.';
            }
            action(SalesChannels)
            {
                ApplicationArea = All;
                Caption = 'Sales Channels';
                Image = List;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Shpfy Sales Channels";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'View a list of Shopify Sales Channels for the shop and choose ones used for new product publishing.';
            }
            action(ProductCollections)
            {
                ApplicationArea = All;
                Caption = 'Custom Product Collections';
                Image = ItemGroup;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Shpfy Product Collections";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'View a list of Shopify Custom Product Collections for the shop and choose ones used for new product publishing.';
            }
            action(BulkOperations)
            {
                ApplicationArea = All;
                Caption = 'Bulk Operations';
                Image = Administration;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Shpfy Bulk Operations";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'View a list of Shopify Bulk Operations for the shop.';
            }
            action(StaffMembers)
            {
                ApplicationArea = All;
                Caption = 'Staff Members Mapping';
                Image = Users;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Shpfy Staff Mapping";
                RunPageLink = "Shop Code" = field(Code);
                ToolTip = 'View a list of Shopify Staff Members for the shop.';
                Visible = Rec."Advanced Shopify Plan";
            }
        }
        area(Processing)
        {
            group(Access)
            {
                action(RequestAccessNew)
                {
                    ApplicationArea = All;
                    Image = EncryptionKeys;
                    Caption = 'Request Access';
                    ToolTip = 'Request access to your Shopify store. Use this to fix connection issues, after connector updates that require new permissions, or when rotating security tokens for this shop.';
                    Enabled = Rec.Enabled;

                    trigger OnAction()
                    begin
                        Rec.RequestAccessToken();
                    end;
                }
                action(TestConnection)
                {
                    ApplicationArea = All;
                    Image = Setup;
                    Caption = 'Test Connection';
                    ToolTip = 'Test connection to your Shopify store.';
                    Enabled = Rec.Enabled;

                    trigger OnAction()
                    var
                        WebhooksMgt: Codeunit "Shpfy Webhooks Mgt.";
                    begin
                        if Rec.TestConnection() then
                            if not Rec."Order Created Webhooks" then begin
                                Message(ConnectionSuccessfulMsg);
                                exit;
                            end else
                                if WebhooksMgt.TestOrderCreatedWebhookConnection(Rec) then
                                    Message(ConnectionAndWebhooksSuccessfulMsg)
                                else
                                    Message(OrderCreatedWebhookNotConfiguredMsg);
                    end;
                }
                action(ClearApiVersionExpiryDateCache)
                {
                    ApplicationArea = All;
                    Image = ClearLog;
                    Caption = 'Clear API Version Expiry Date Cache';
                    ToolTip = 'Clears the API version expiry date cache for this Shopify Shop. This will force the API version to be re-evaluated the next time the API is called.';
                    Enabled = Rec.Enabled;

                    trigger OnAction()
                    var
                        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
                    begin
                        CommunicationMgt.ClearApiVersionCache();
                    end;
                }
                action(LeaveReview)
                {
                    ApplicationArea = All;
                    Caption = 'Leave a Review';
                    Image = CustomerRating;
                    ToolTip = 'Open the Shopify App Store to leave a review for the Shopify connector.';

                    trigger OnAction()
                    var
                        ShopReview: Codeunit "Shpfy Shop Review";
                    begin
                        ShopReview.OpenReviewLinkFromShop(Rec.GetStoreName());
                    end;
                }
            }
            group(Sync)
            {
                action(SyncProducts)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Products';
                    Image = ImportExport;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Synchronize products for this Shopify Shop. The direction depends on the settings in the Shopify Shop Card.';

                    trigger OnAction()
                    var
                        BackgroundSyncs: Codeunit "Shpfy Background Syncs";
                    begin
                        BackgroundSyncs.ProductsSync(Rec.Code);
                    end;
                }
                action(SyncImages)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Product Images';
                    Image = ImportExport;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Synchronize product images for this Shopify Shop. The direction depends on the settings in the Shopify Shop Card.';

                    trigger OnAction()
                    var
                        BackgroundSyncs: Codeunit "Shpfy Background Syncs";
                    begin
                        BackgroundSyncs.ProductImagesSync(Rec.Code, '');
                    end;
                }
                action(SyncProductPrices)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Prices';
                    Image = ImportExport;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Synchronize prices to Shopify. The standard price calculation is followed for determining the price.';

                    trigger OnAction()
                    var
                        BackgroundSyncs: Codeunit "Shpfy Background Syncs";
                    begin
                        BackgroundSyncs.ProductPricesSync(Rec.Code);
                    end;
                }
                action(SyncInventory)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Inventory';
                    Image = ImportExport;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Synchronize the inventory to Shopify.';

                    trigger OnAction()
                    var
                        BackgroundSyncs: Codeunit "Shpfy Background Syncs";
                    begin
                        BackgroundSyncs.InventorySync(Rec.Code);
                    end;
                }
                action(SyncCustomers)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Customers';
                    Image = ImportExport;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Synchronize the customers from Shopify. The way customers are imported depends on the settings in the Shopify Shop Card.';

                    trigger OnAction()
                    var
                        BackgroundSyncs: Codeunit "Shpfy Background Syncs";
                    begin
                        BackgroundSyncs.CustomerSync(Rec.Code);
                    end;
                }
                action(SyncCompanies)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Companies';
                    Image = ImportExport;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Synchronize the companies with Shopify. The way companies are synchronized depends on the B2B settings in the Shopify Shop Card.';

                    trigger OnAction()
                    var
                        BackgroundSyncs: Codeunit "Shpfy Background Syncs";
                    begin
                        BackgroundSyncs.CompanySync(Rec.Code);
                    end;
                }
                action(SyncPayouts)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Payouts';
                    Image = PaymentHistory;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Synchronize all movements of money between a Shopify Payment account balance and a connected bank account.';

                    trigger OnAction()
                    var
                        BackgroundSyncs: Codeunit "Shpfy Background Syncs";
                    begin
                        BackgroundSyncs.PayoutsSync(Rec.Code);
                    end;
                }
                action(SyncOrders)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Orders';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Synchronize orders from Shopify.';

                    trigger OnAction();
                    var
                        Shop: Record "Shpfy Shop";
                        BackgroundSyncs: Codeunit "Shpfy Background Syncs";
                    begin
                        Shop.SetFilter(Code, Rec.Code);
                        BackgroundSyncs.OrderSync(Shop);
                    end;
                }
                action(SyncShipments)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Shipments';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Synchronize shipments to Shopify.';

                    trigger OnAction();
                    begin
                        Report.Run(Report::"Shpfy Sync Shipm. to Shopify");
                    end;
                }
                action(SyncPostedSalesInvoices)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Posted Sales Invoices';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Synchronize posted sales invoices to Shopify. Synchronization will be performed only if the Posted Invoice Sync field is enabled in the Shopify shop.';

                    trigger OnAction();
                    var
                        ExportInvoicetoShpfy: Report "Shpfy Sync Invoices to Shpfy";
                    begin
                        ExportInvoicetoShpfy.SetShop(Rec.Code);
                        ExportInvoicetoShpfy.Run();
                    end;
                }
                action(SyncDisputes)
                {
                    ApplicationArea = All;
                    Caption = 'Sync Disputes';
                    Image = ErrorLog;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Synchronize dispute information with related payment transactions.';

                    trigger OnAction()
                    var
                        BackgroundSyncs: Codeunit "Shpfy Background Syncs";
                    begin
                        BackgroundSyncs.DisputesSync(Rec.Code);
                    end;
                }
                action(SyncAll)
                {
                    ApplicationArea = All;
                    Caption = 'Sync All';
                    Image = ImportExport;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Execute all synchronizations (Products, Product images, Inventory, Customers and payouts) in batch.';

                    trigger OnAction()
                    var
                        BackgroundSyncs: Codeunit "Shpfy Background Syncs";
                    begin
                        BackgroundSyncs.CustomerSync(Rec);
                        BackgroundSyncs.ProductsSync(Rec);
                        BackgroundSyncs.InventorySync(Rec);
                        BackgroundSyncs.ProductImagesSync(Rec, '');
                        BackgroundSyncs.ProductPricesSync(Rec);
                        BackgroundSyncs.CompanySync(Rec);
                        BackgroundSyncs.CatalogPricesSync(Rec, '', "Shpfy Catalog Type"::" ");
                    end;
                }
            }

            group(SyncReset)
            {
                Caption = 'Reset Sync';
                Image = ImportExcel;

                action(ResetProducts)
                {
                    ApplicationArea = All;
                    Caption = 'Reset Products Sync';
                    Image = ClearFilter;
                    Tooltip = 'Ensure all products are synced when executing the sync, not just the changes since last sync.';

                    trigger OnAction()
                    begin
                        Rec.SetLastSyncTime("Shpfy Synchronization Type"::Products, GetResetSyncTo(Rec.GetLastSyncTime("Shpfy Synchronization Type"::Products)));
                    end;
                }
                action(ResetCustomers)
                {
                    ApplicationArea = All;
                    Caption = 'Reset Customer Sync';
                    Image = ClearFilter;
                    Tooltip = 'Ensure all customers are synced when executing the sync, not just the changes since last sync.';

                    trigger OnAction()
                    begin
                        Rec.SetLastSyncTime("Shpfy Synchronization Type"::Customers, GetResetSyncTo(Rec.GetLastSyncTime("Shpfy Synchronization Type"::Customers)));
                    end;
                }
                action(ResetOrders)
                {
                    ApplicationArea = All;
                    Caption = 'Reset Orders Sync';
                    Image = ClearFilter;
                    Tooltip = 'Ensure all orders are synced when executing the sync, not just the changes since last sync.';

                    trigger OnAction()
                    begin
                        Rec.SetLastSyncTime("Shpfy Synchronization Type"::Orders, GetResetSyncTo(Rec.GetLastSyncTime("Shpfy Synchronization Type"::Orders)));
                    end;
                }
                action(ResetCompanies)
                {
                    ApplicationArea = All;
                    Caption = 'Reset Company Sync';
                    Image = ClearFilter;
                    Tooltip = 'Ensure all companies are synced when executing the sync, not just the changes since last sync.';

                    trigger OnAction()
                    begin
                        Rec.SetLastSyncTime("Shpfy Synchronization Type"::Companies, GetResetSyncTo(Rec.GetLastSyncTime("Shpfy Synchronization Type"::Companies)));
                    end;
                }
            }
            action(CreateFulfillmentService)
            {
                ApplicationArea = All;
                Caption = 'Create Shopify Fulfillment Service';
                Image = CreateInventoryPickup;
                ToolTip = 'Create Shopify Fulfillment Service';

                trigger OnAction()
                var
                    FullfillmentOrdersAPI: Codeunit "Shpfy Fulfillment Orders API";
                begin
                    FullfillmentOrdersAPI.RegisterFulfillmentService(Rec);
                end;
            }
            action(ProvideFeedback)
            {
                ApplicationArea = All;
                Caption = 'Provide Feedback';
                ToolTip = 'Provide feedback on Shopify Connector.';
                Image = Comment;

                trigger OnAction()
                var
                    ShopMgt: Codeunit "Shpfy Shop Mgt.";
                begin
                    ShopMgt.RequestFeedback();
                end;
            }
        }
    }

    var
        IsReturnRefundsVisible: Boolean;
        ApiVersion: Text;
        ApiVersionExpiryDate: Date;
        ScopeChangeConfirmLbl: Label 'The access scope of shop %1 for the Shopify connector has changed. Do you want to request a new access token?', Comment = '%1 - Shop Code';
        ConnectionSuccessfulMsg: Label 'Connection successful.';
        ConnectionAndWebhooksSuccessfulMsg: Label 'Connection successful and auto synchronize orders is configured correctly.';
        OrderCreatedWebhookNotConfiguredMsg: Label 'Connection successful, but auto synchronize orders is misconfigured. Reactivate Auto Sync Orders setting.';

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        ShopReview: Codeunit "Shpfy Shop Review";
        ApiVersionExpiryDateTime: DateTime;
    begin
        FeatureTelemetry.LogUptake('0000HUU', 'Shopify', Enum::"Feature Uptake Status"::Discovered);
        if Rec.Enabled then begin
            ApiVersion := CommunicationMgt.GetApiVersion();
            ApiVersionExpiryDateTime := CommunicationMgt.GetApiVersionExpiryDate();
            ApiVersionExpiryDate := DT2Date(ApiVersionExpiryDateTime);
            Rec.CheckApiVersionExpiryDate(ApiVersion, ApiVersionExpiryDateTime);

            if AuthenticationMgt.CheckScopeChange(Rec) then
                if Confirm(StrSubstNo(ScopeChangeConfirmLbl, Rec.Code)) then begin
                    Rec.RequestAccessToken();
                    Rec.GetShopSettings();
                    Rec.Modify();
                end else begin
                    Rec.Enabled := false;
                    Rec.Modify();
                end;
#if not CLEAN28
            Rec.UpdateFulfillmentService();
#endif
            ShopReview.MaybeShowReviewReminder(Rec.GetStoreName());
        end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CheckReturnRefundsVisible();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if EnvironmentInformation.IsSandbox() or CompanyInformationMgt.IsDemoCompany() then
            Rec."Allow Background Syncs" := false;
    end;

    local procedure GetResetSyncTo(InitDateTime: DateTime): DateTime
    var
        DateTimeDialog: Page "Date-Time Dialog";
        ResetSyncLbl: Label 'Reset Sync to';
    begin
        DateTimeDialog.SetDateTime(InitDateTime);
        DateTimeDialog.Caption := ResetSyncLbl;
        DateTimeDialog.LookupMode := true;
        if DateTimeDialog.RunModal() = Action::LookupOK then
            exit(DateTimeDialog.GetDateTime());
        exit(InitDateTime);
    end;

    local procedure CheckReturnRefundsVisible()
    begin
        IsReturnRefundsVisible := Rec."Return and Refund Process" <> "Shpfy ReturnRefund ProcessType"::" ";
    end;

}
