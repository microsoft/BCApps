// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using System.DataAdministration;
using System.Globalization;
using System.IO;
using System.Privacy;
using System.Security.AccessControl;
using System.Telemetry;
using System.Threading;

/// <summary>
/// Table Shpfy Shop (ID 30102).
/// </summary>
table 30102 "Shpfy Shop"
{
    Caption = 'Shopify Shop';
    DataClassification = SystemMetadata;
    DrillDownPageId = "Shpfy Shops";
    LookupPageId = "Shpfy Shops";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code to identify this Shopify Shop.';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(2; "Shopify URL"; Text[250])
        {
            Caption = 'Shopify Admin URL';
            ToolTip = 'Specifies the URL of the Shopify Admin you are connecting to. Use the format: "https://{store ID}.myshopify.com". You can build the URL by combining the store ID from the admin URL, e.g., "admin.shopify.com/store/{store ID}" and ".myshopify.com". Simply copy the URL from the Shopify Admin, and the connector will convert it to the required format. Ensure you copy the URL from the Shopify Admin, not the online store, as the online store may display a redirect URL.';
            Access = Internal;
            DataClassification = SystemMetadata;
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
            begin
                if ("Shopify URL" <> '') then begin
                    AuthenticationMgt.CorrectShopUrl("Shopify URL");
                    AuthenticationMgt.AssertValidShopUrl("Shopify URL");
                end;
                Rec.CalcShopId();
            end;
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'Specifies whether this Shopify shop connection is active. When enabled, the connector requests an access token, imports shop settings, and syncs countries. Ensure the Shopify Admin URL is configured first.';

            trigger OnValidate()
            var
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
                WebhooksMgt: Codeunit "Shpfy Webhooks Mgt.";
                AuditLog: Codeunit "Audit Log";
            begin
                if Rec."Enabled" then begin
                    Rec.TestField("Code");
                    Rec.TestField("Shopify URL");
                    Rec."Enabled" := CustomerConsentMgt.ConfirmUserConsent();
                    if Rec.Enabled then
                        AuditLog.LogAuditMessage(StrSubstNo(ShopifyConsentProvidedLbl, UserSecurityId(), CompanyName()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);
                end else begin
                    Rec.Enabled := true;
                    Rec.Validate("Order Created Webhooks", false);
                    WebhooksMgt.DisableBulkOperationsWebhook(Rec);
                    Rec.Enabled := false;
                end;
            end;
        }
#if not CLEANSCHEMA26
        field(5; "Log Enabled"; Boolean)
        {
            Caption = 'Log Enabled';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced with field "Logging Mode"';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(6; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            ToolTip = 'Specifies which Customer Price Group is used to calculate the prices in Shopify.';
            DataClassification = SystemMetadata;
            TableRelation = "Customer Price Group";
            ValidateTableRelation = true;
        }
        field(7; "Customer Discount Group"; Code[20])
        {
            Caption = 'Customer Discount Group';
            ToolTip = 'Specifies which Customer Discount Group is used to calculate the prices in Shopify.';
            DataClassification = SystemMetadata;
            TableRelation = "Customer Discount Group";
            ValidateTableRelation = true;
        }
        field(8; "Shipping Charges Account"; Code[20])
        {
            Caption = 'Shipping Charges Account';
            ToolTip = 'Specifies the G/L Account for posting the shipping cost.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account"."No.";
            ValidateTableRelation = true;

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if GLAccount.Get("Shipping Charges Account") then
                    CheckGLAccount(GLAccount);
            end;
        }
        field(9; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language of the Shopify Shop.';
            DataClassification = SystemMetadata;
            TableRelation = Language;
            ValidateTableRelation = true;
        }
        field(10; "Sync Item"; Option)
        {
            Caption = 'Sync Item';
            ToolTip = 'Specifies in which direction items are synchronized.';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,To Shopify,From Shopify';
            OptionMembers = " ","To Shopify","From Shopify";
        }
#if not CLEANSCHEMA25
        field(11; "Item Template Code"; Code[10])
        {
            Caption = 'Item Template Code';
            DataClassification = SystemMetadata;
            TableRelation = "Config. Template Header".Code where("Table Id" = const(27));
            ValidateTableRelation = true;
            ObsoleteReason = 'Replaced by Item Templ. Code';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(12; "Sync Item Images"; Option)
        {
            Caption = 'Sync Item Images';
            ToolTip = 'Specifies whether you want to synchronize item images and in which direction.';
            DataClassification = SystemMetadata;
            OptionCaption = 'Disabled,To Shopify,From Shopify';
            OptionMembers = " ","To Shopify","From Shopify";
        }
        field(13; "Sync Item Extended Text"; boolean)
        {
            Caption = 'Sync Item Extended Text';
            ToolTip = 'Specifies whether you want to synchronize extended texts to Shopify.';
            DataClassification = SystemMetadata;
        }
        field(14; "Sync Item Attributes"; boolean)
        {
            Caption = 'Sync Item Attributes';
            ToolTip = 'Specifies whether you want to synchronize item attributes to Shopify.';
            DataClassification = SystemMetadata;
        }
        field(15; "Sync Item Marketing Text"; Boolean)
        {
            Caption = 'Sync Item Marketing Text';
            ToolTip = 'Specifies whether you want to synchronize marketing texts to Shopify.';
            DataClassification = SystemMetadata;
        }
        field(21; "Auto Create Orders"; Boolean)
        {
            Caption = 'Auto Create Sales Documents';
            ToolTip = 'Specifies whether sales documents, such as orders and invoices, will be created automatically after import.';
            DataClassification = SystemMetadata;
            trigger OnValidate()
            var
                ErrorInfo: ErrorInfo;
            begin
                if Rec."Return and Refund Process" = "Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo" then
                    if not Rec."Auto Create Orders" then begin
                        ErrorInfo.FieldNo(Rec.FieldNo("Auto Create Orders"));
                        ErrorInfo.ErrorType := ErrorType::Client;
                        ErrorInfo.RecordId := Rec.RecordId;
                        ErrorInfo.Message := StrSubstNo(AutoCreateErrorMsg, Rec.FieldCaption("Auto Create Orders"), Rec.FieldCaption("Return and Refund Process"), Rec."Return and Refund Process");
                        Error(ErrorInfo);
                    end;
            end;
        }
        field(22; "Auto Create Unknown Items"; Boolean)
        {
            Caption = 'Auto Create Unknown Items';
            ToolTip = 'Specifies if unknown items are automatically created in Business Central when synchronizing from Shopify.';
            DataClassification = SystemMetadata;
        }
        field(23; "Auto Create Unknown Customers"; Boolean)
        {
            Caption = 'Auto Create Unknown Customers';
            ToolTip = 'Specifies if unknown customers are automatically created in Business Central when synchronizing from Shopify.';
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA25
        field(24; "Customer Template Code"; Code[10])
        {
            Caption = 'Customer Template Code';
            DataClassification = SystemMetadata;
            TableRelation = "Config. Template Header".Code where("Table Id" = const(18));
            ValidateTableRelation = true;
            ObsoleteReason = 'Replaced by  "Customer Templ. Code"';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(25; "Product Collection"; Option)
        {
            Caption = 'Product Collection';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Tax Group,VAT Prod. Posting Group';
            OptionMembers = " ","Tax Group","VAT Prod. Posting Group";
        }
        field(27; "Shopify Order No. on Doc. Line"; Boolean)
        {
            Caption = 'Shopify Order No. on Doc. Line';
            ToolTip = 'Specifies whether the Shopify Order No. is shown in the document line.';
            DataClassification = CustomerContent;
        }
        field(28; "Customer Import From Shopify"; enum "Shpfy Customer Import Range")
        {
            Caption = 'Customer Import from Shopify';
            ToolTip = 'Specifies how Shopify customers are synced to Business Central. If you choose none and there exists no mapping for that customer, the default customer will be used if exists.';
            DataClassification = CustomerContent;
            InitValue = WithOrderImport;
        }
#if not CLEANSCHEMA27
        field(29; "Export Customer To Shopify"; Boolean)
        {
            Caption = 'Export Customer to Shopify';
            DataClassification = CustomerContent;
            InitValue = true;
            ObsoleteReason = 'Replaced with action "Add Customer to Shopify" in Shopify Customers page.';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
        }
#endif
        field(30; "Shopify Can Update Customer"; Boolean)
        {
            Caption = 'Shopify Can Update Customers';
            ToolTip = 'Specifies whether Shopify can update customers when synchronizing from Shopify.';
            DataClassification = CustomerContent;
            InitValue = false;

            trigger OnValidate()
            begin
                if "Shopify Can Update Customer" then
                    "Can Update Shopify Customer" := false;
            end;
        }
        field(31; "Can Update Shopify Customer"; Boolean)
        {
            Caption = 'Can Update Shopify Customers';
            ToolTip = 'Specifies whether Business Central can update customers when synchronizing to Shopify.';
            DataClassification = CustomerContent;
            InitValue = false;

            trigger OnValidate()
            begin
                if "Can Update Shopify Customer" then
                    "Shopify Can Update Customer" := false;
            end;
        }
        field(32; "Name Source"; enum "Shpfy Name Source")
        {
            Caption = 'Name Source';
            ToolTip = 'Specifies how to synchronize the name of the customer. If the value is empty then the value of Name 2 is taken, and Name 2 will be empty.';
            DataClassification = CustomerContent;
            InitValue = CompanyName;
        }
        field(33; "Name 2 Source"; enum "Shpfy Name Source")
        {
            Caption = 'Name 2 Source';
            ToolTip = 'Specifies how to synchronize Name 2 of the customer.';
            DataClassification = CustomerContent;
            InitValue = FirstAndLastName;
        }
        field(34; "Contact Source"; enum "Shpfy Name Source")
        {
            Caption = 'Contact Source';
            ToolTip = 'Specifies how to synchronize the contact of the customer.';
            DataClassification = CustomerContent;
            InitValue = FirstAndLastName;
            ValuesAllowed = FirstAndLastName, LastAndFirstName, None;
        }
        field(35; "County Source"; enum "Shpfy County Source")
        {
            Caption = 'County Source';
            ToolTip = 'Specifies how to synchronize the county of the customer/company.';
            DataClassification = CustomerContent;
            InitValue = Code;
        }
        field(36; "Default Customer No."; Code[20])
        {
            Caption = 'Default Customer No.';
            ToolTip = 'Specifies the default customer when not creating a customer for each webshop user.';
            DataClassification = CustomerContent;
            TableRelation = Customer;
        }
        field(37; "UoM as Variant"; Boolean)
        {
            Caption = 'UoM as Variant';
            ToolTip = 'Specifies if you want to have the different unit of measures as an variant in Shopify.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "UoM as Variant" then
                    VerifyNoItemAttributesAsOptions();

                if "UoM as Variant" and ("Option Name for UoM" = '') then
                    "Option Name for UoM" := 'Unit of Measure';
            end;
        }
        field(38; "Option Name for UoM"; Text[50])
        {
            Caption = 'Variant Option Name for UoM';
            ToolTip = 'Specifies the variant option name for the unit of measure.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Option Name for UoM" = '' then
                    "UoM as Variant" := false;
            end;
        }
        field(39; "Shopify Can Update Items"; Boolean)
        {
            Caption = 'Shopify Can Update Items';
            ToolTip = 'Specifies whether Shopify can update items when synchronizing from Shopify.';
            DataClassification = CustomerContent;
            InitValue = false;

            trigger OnValidate()
            begin
                if "Shopify Can Update Items" then
                    "Can Update Shopify Products" := false;
            end;
        }
        field(40; "Can Update Shopify Products"; Boolean)
        {
            Caption = 'Can Update Shopify Products';
            ToolTip = 'Specifies whether Business Central can update products when synchronizing to Shopify.';
            DataClassification = CustomerContent;
            InitValue = false;

            trigger OnValidate()
            begin
                if "Can Update Shopify Products" then
                    "Shopify Can Update Items" := false;
            end;
        }
        field(41; "Variant Prefix"; Code[5])
        {
            Caption = 'Variant Prefix';
            ToolTip = 'Specifies the prefix for variants. The variants you have defined in Shopify are created in Business Central based on an increasing number.';
            DataClassification = CustomerContent;
            InitValue = 'V_';
        }
        field(42; "Inventory Tracked"; Boolean)
        {
            Caption = 'Inventory Tracked';
            ToolTip = 'Specifies if you want to manage your inventory in Shopify based on Business Central.';
            DataClassification = CustomerContent;
        }
        field(43; "Default Inventory Policy"; Enum "Shpfy Inventory Policy")
        {
            Caption = 'Default Inventory Policy';
            ToolTip = 'Specifies if you want to prevent negative inventory. With "continue" the inventory can go negative, with "Deny" you want to prevent negative inventory.';
            DataClassification = CustomerContent;
            InitValue = CONTINUE;
        }
        field(44; "Allow Background Syncs"; Boolean)
        {
            Caption = 'Run Syncs in Background';
            ToolTip = 'Specifies whether synchronization runs in the background. When enabled, you can continue working while large data sets synchronize. Disable for demos or troubleshooting to see real-time progress and receive detailed error messages.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(47; "Tip Account"; Code[20])
        {
            Caption = 'Tip Account';
            ToolTip = 'Specifies the G/L Account for post the received tip amount.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account"."No.";
            ValidateTableRelation = true;

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if GLAccount.Get("Tip Account") then
                    CheckGLAccount(GLAccount);
            end;
        }
        field(48; "Sold Gift Card Account"; Code[20])
        {
            Caption = 'Sold Gift Card Account';
            ToolTip = 'Specifies the G/L Account for to post the sold gift card amounts.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account"."No.";
            ValidateTableRelation = true;

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if GLAccount.Get("Sold Gift Card Account") then
                    CheckGLAccount(GLAccount);
            end;
        }
        field(49; "Customer Mapping Type"; enum "Shpfy Customer Mapping")
        {
            Caption = 'Customer Mapping Type';
            ToolTip = 'Specifies how to map customers.';
            DataClassification = CustomerContent;
        }
        field(50; "Status for Created Products"; Enum "Shpfy Cr. Prod. Status Value")
        {
            Caption = 'Status for Created Products';
            ToolTip = 'Specifies the status of a product in Shopify when an item is create in Shopify via the sync.';
            DataClassification = CustomerContent;
        }
        field(51; "Action for Removed Products"; Enum "Shpfy Remove Product Action")
        {
            Caption = 'Action for Removed Products and Blocked Items';
            ToolTip = 'Specifies the status of a product in Shopify via the sync when an item is blocked or removed from the Shopify Product in Business Central.';
            DataClassification = CustomerContent;
        }
        field(52; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency used by your Shopify store. Leave blank if it matches the local currency (LCY). When set, exchange rates must be configured. This currency is used when calculating product prices to sync to Shopify and works together with the "Currency Handling" field in the Order section, which determines how order currencies are processed.';
            DataClassification = CustomerContent;
            TableRelation = Currency.Code;

            trigger OnValidate()
            var
                CurrencyExchangeRate: Record "Currency Exchange Rate";
            begin
                if "Currency Code" <> '' then begin
                    CurrencyExchangeRate.SetRange("Currency Code", "Currency Code");
                    if CurrencyExchangeRate.IsEmpty() then
                        Error(CurrencyExchangeRateNotDefinedErr);
                end;
            end;
        }
        field(53; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies which Gen. Bus. Posting Group is used to calculate the prices in Shopify.';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Business Posting Group";
        }
        field(54; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies which VAT. Bus. Posting Group is used to calculate the prices in Shopify.';
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group";
        }
        field(55; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            ToolTip = 'Specifies which Tax Area Code is used to calculate the prices in Shopify.';
            DataClassification = CustomerContent;
            TableRelation = "Tax Area";
        }
        field(56; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if Tax Liable is used to calculate the prices in Shopify.';
            DataClassification = CustomerContent;
        }
        field(57; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            ToolTip = 'Specifies which VAT Country/Region Code is used to calculate the prices in Shopify.';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(58; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            ToolTip = 'Specifies which Customer Posting Group is used to calculate the prices in Shopify.';
            DataClassification = CustomerContent;
            TableRelation = "Customer Posting Group";
        }
        field(59; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
            ToolTip = 'Specifies if the prices calculate for Shopify are Including VAT.';
            DataClassification = CustomerContent;
        }
        field(60; "Auto Release Sales Orders"; Boolean)
        {
            Caption = 'Auto Release Sales Documents';
            ToolTip = 'Specifies if a sales document, such as order or invoice, should be released after creation.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(61; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            ToolTip = 'Specifies if line discount is allowed while calculating prices for Shopify.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(62; "Customer Templ. Code"; Code[20])
        {
            Caption = 'Customer/Company Template Code';
            ToolTip = 'Specifies which customer template to use when creating unknown customers.';
            DataClassification = SystemMetadata;
            TableRelation = "Customer Templ.".Code;
            ValidateTableRelation = true;
        }
        field(63; "Item Templ. Code"; Code[20])
        {
            Caption = 'Item Template Code';
            ToolTip = 'Specifies which item template to use when creating unknown items.';
            DataClassification = SystemMetadata;
            TableRelation = "Item Templ.".Code;
            ValidateTableRelation = true;
        }
        field(70; "Return and Refund Process"; Enum "Shpfy ReturnRefund ProcessType")
        {
            Caption = 'Process Type';
            ToolTip = 'Specifies how returns and refunds from Shopify are handles in Business Central. The import process is always done within the import of a Shopify order.';
            DataClassification = CustomerContent;
            InitValue = "Import Only";

            trigger OnValidate()
            var
                ErrorInfo: ErrorInfo;
                AutoCreateErrorMsg: Label 'You need to turn "%1" on if you want to set "%2" to the value of "%3".', Comment = '%1 = Field Caption of "Auto Create Orders", %2 = Field Caption of "Return and Refund Process", %3 = Field Value of "Return and Refund Process"';
            begin
                if Rec."Return and Refund Process" = "Shpfy ReturnRefund ProcessType"::"Auto Create Credit Memo" then
                    if not Rec."Auto Create Orders" then begin
                        ErrorInfo.FieldNo(Rec.FieldNo("Return and Refund Process"));
                        ErrorInfo.ErrorType := ErrorType::Client;
                        ErrorInfo.RecordId := Rec.RecordId;
                        ErrorInfo.Message := StrSubstNo(AutoCreateErrorMsg, Rec.FieldCaption("Auto Create Orders"), Rec.FieldCaption("Return and Refund Process"), Rec."Return and Refund Process");
                        Error(ErrorInfo);
                    end;
            end;
        }
        field(73; "Return Location"; Code[10])
        {
            Caption = 'Default Return Location';
            ToolTip = 'Specifies location code for returned goods.';
            DataClassification = CustomerContent;
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(75; "Refund Acc. non-restock Items"; Code[20])
        {
            Caption = 'Refund Account non-restock Items';
            ToolTip = 'Specifies a G/L Account No. for goods where you don''t want to have an inventory correction.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if GLAccount.Get("Refund Acc. non-restock Items") then
                    CheckGLAccount(GLAccount);
            end;
        }
        field(76; "Refund Account"; Code[20])
        {
            Caption = 'Refund Account';
            ToolTip = 'Specifies a G/L Account No. for the difference in the total refunded amount and the total amount of the items.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if GLAccount.Get("Refund Account") then
                    CheckGLAccount(GLAccount);
            end;
        }
#pragma warning disable AS0004
        field(104; "SKU Mapping"; Enum "Shpfy SKU Mapping")
#pragma warning restore AS0004
        {
            Caption = 'SKU Mapping';
            ToolTip = 'Specifies if and based on what you want to create variants in Business Central.';
            DataClassification = SystemMetadata;

        }
        field(105; "SKU Field Separator"; Code[10])
        {
            Caption = 'SKU Field Separator';
            ToolTip = 'Specifies a field separator for the SKU if you use "Item. No + Variant Code" to create a variant.';
            DataClassification = SystemMetadata;
            InitValue = '|';
        }
        field(106; "Tax Area Priority"; Enum "Shpfy Tax By")
        {
            Caption = 'Tax Area Priority';
            ToolTip = 'Specifies the tax area source and the sequence to be followed.';
            DataClassification = CustomerContent;
            Description = 'Choose in which order the system try to find the county for the tax area.';
        }
        field(107; "Allow Outgoing Requests"; Boolean)
        {
            Caption = 'Allow Data Sync to Shopify';
            ToolTip = 'Specifies whether syncing data to Shopify is enabled.';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(108; "Order Created Webhooks"; Boolean)
        {
            Caption = 'Auto Sync Orders';
            ToolTip = 'Specifies whether to automatically synchronize orders when they''re created in Shopify. Shopify will notify Business Central that orders are ready. Business Central will schedule the Sync Orders from Shopify job on the Job Queue Entries page. The user account of the person who turns on this toggle will be used to run the job. That user must have permission to create background tasks in the job queue.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                ShpfyWebhooksMgt: Codeunit "Shpfy Webhooks Mgt.";
            begin
                if "Order Created Webhooks" then
                    ShpfyWebhooksMgt.EnableOrderCreatedWebhook(Rec)
                else
                    ShpfyWebhooksMgt.DisableOrderCreatedWebhook(Rec);
            end;
        }
        field(109; "Order Created Webhook User"; Code[50])
        {
            Caption = 'Sync Order Job Queue User';
            ToolTip = 'Specifies the user who will run the Sync Orders from Shopify job on the Job Queue Entries page. This is the user who turned on the Auto Import Orders from Shopify toggle.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(110; "Fulfillment Service Activated"; Boolean)
        {
            Caption = 'Fulfillment Service Activated';
            DataClassification = SystemMetadata;
            Description = 'Indicates whether the Shopify Fulfillment Service is activated.';
        }
        field(111; "Order Created Webhook User Id"; Guid)
        {
            Caption = 'Order Created Webhook User Id';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User;

            trigger OnValidate()
            var
                User: Record User;
            begin
                if User.Get("Order Created Webhook User Id") then
                    "Order Created Webhook User" := User."User Name";
            end;
        }
        field(112; "Order Created Webhook Id"; Text[500])
        {
            Caption = 'Order Created Webhook Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(113; "Logging Mode"; Enum "Shpfy Logging Mode")
        {
            Caption = 'Logging Mode';
            ToolTip = 'Specifies whether the log is activated.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if "Logging Mode" = "Logging Mode"::All then
                    EnableShopifyLogRetentionPolicySetup();
            end;
        }
        field(114; "Bulk Operation Webhook User Id"; Guid)
        {
            Caption = 'Bulk Operation Webhook User Id';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User;
        }
        field(115; "Bulk Operation Webhook Id"; Text[500])
        {
            Caption = 'Bulk Operation Webhook Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(116; "Sync Prices"; Boolean)
        {
            Caption = 'Sync Prices with Products';
            ToolTip = 'Specifies if prices are synchronized to Shopify with product sync.';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
#if not CLEANSCHEMA32
        field(117; "B2B Enabled"; Boolean)
        {
            Caption = 'B2B Enabled';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'B2B features are now available on all Shopify plans.';
#if CLEAN29
            ObsoleteState = Removed;
            ObsoleteTag = '32.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '29.0';
#endif
        }
#endif
        field(118; "Can Update Shopify Companies"; Boolean)
        {
            Caption = 'Can Update Shopify Companies';
            ToolTip = 'Specifies whether Business Central can update companies when synchronizing to Shopify.';
            DataClassification = CustomerContent;
            InitValue = false;

            trigger OnValidate()
            begin
                if "Can Update Shopify Companies" then
                    "Shopify Can Update Companies" := false;
            end;
        }
        field(119; "Default Contact Permission"; Enum "Shpfy Default Cont. Permission")
        {
            Caption = 'Default Contact Permission';
            ToolTip = 'Specifies the default customer permission for new companies.';
            DataClassification = CustomerContent;
            InitValue = "Ordering Only";
        }
        field(120; "Auto Create Catalog"; Boolean)
        {
            Caption = 'Auto Create Catalog';
            ToolTip = 'Specifies whether a catalog is automatically created for new companies.';
            DataClassification = CustomerContent;
        }
        field(121; "Company Import From Shopify"; Enum "Shpfy Company Import Range")
        {
            Caption = 'Company Import from Shopify';
            ToolTip = 'Specifies how Shopify companies are synced to Business Central.';
            DataClassification = CustomerContent;
            InitValue = WithOrderImport;
        }
        field(122; "Shopify Can Update Companies"; Boolean)
        {
            Caption = 'Shopify Can Update Companies';
            ToolTip = 'Specifies whether Shopify can update companies when synchronizing from Shopify.';
            DataClassification = CustomerContent;
            InitValue = false;

            trigger OnValidate()
            begin
                if "Shopify Can Update Companies" then
                    "Can Update Shopify Companies" := false;
            end;
        }
        field(123; "Auto Create Unknown Companies"; Boolean)
        {
            Caption = 'Auto Create Unknown Companies';
            ToolTip = 'Specifies if unknown companies are automatically created in Business Central when synchronizing from Shopify.';
            DataClassification = CustomerContent;
        }
        field(124; "Send Shipping Confirmation"; Boolean)
        {
            Caption = 'Send Shipping Confirmation';
            ToolTip = 'Specifies whether the customer is notified when the shipment is synchronized to Shopify.';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(125; "Default Company No."; Code[20])
        {
            Caption = 'Default Company No.';
            ToolTip = 'Specifies the default customer when not creating a company for each B2B company.';
            DataClassification = CustomerContent;
            TableRelation = Customer;
        }
        field(126; "Company Mapping Type"; Enum "Shpfy Company Mapping")
        {
            Caption = 'Company Mapping Type';
            ToolTip = 'Specifies how to map companies.';
            DataClassification = CustomerContent;
        }
#if not CLEANSCHEMA27
        field(127; "Replace Order Attribute Value"; Boolean)
        {
            Caption = 'Replace Order Attribute Value';
            DataClassification = SystemMetadata;
            InitValue = true;
            ObsoleteReason = 'This feature will be enabled by default with version 27.0.';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
        }
#endif
        field(128; "Return Location Priority"; Enum "Shpfy Return Location Priority")
        {
            Caption = 'Return Location Priority';
            ToolTip = 'Specifies the priority of the return location.';
            DataClassification = CustomerContent;
        }
        field(129; "Weight Unit"; Enum "Shpfy Weight Unit")
        {
            Caption = 'Weight Unit';
            ToolTip = 'Specifies the weight unit of the Shopify Shop.';
            DataClassification = CustomerContent;
        }
        field(130; "Product Metafields To Shopify"; Boolean)
        {
            Caption = 'Sync Product/Variant Metafields to Shopify';
            ToolTip = 'Specifies whether product/variant metafields are synchronized to Shopify.';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(131; "Customer Metafields To Shopify"; Boolean)
        {
            Caption = 'Sync Customer Metafields';
            ToolTip = 'Specifies whether customer metafields are synchronized to Shopify.';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(132; "Company Metafields To Shopify"; Boolean)
        {
            Caption = 'Sync Company Metafields';
            ToolTip = 'Specifies whether company metafields are synchronized to Shopify.';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(133; "Order Attributes To Shopify"; Boolean)
        {
            Caption = 'Sync Business Central Doc. No. as Attribute';
            ToolTip = 'Specifies if Business Central document no. is synchronized to Shopify as order attribute.';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(134; "Shpfy Comp. Tax Id Mapping"; Enum "Shpfy Comp. Tax Id Mapping")
        {
            Caption = 'Company Tax Id Mapping';
            ToolTip = 'Specifies how to map Shopify Tax Id with Business Central.';
            DataClassification = CustomerContent;
        }
        field(135; "Currency Handling"; Enum "Shpfy Currency Handling")
        {
            Caption = 'Currency Handling';
            ToolTip = 'Specifies which currency is used in Shopify orders processing. Using presentment currency may cause differences between amounts in LCY after posting documents.';
            InitValue = "Shop Currency";
        }
        field(136; "Use Shopify Order No."; Boolean)
        {
            Caption = 'Use Shopify Order No.';
            ToolTip = 'Specifies whether the Shopify order number is used as the document number on the created Sales Order or Sales Invoice. You can overwrite the selection for the specific Shopify Order.';
        }
        field(137; "Process Returns As"; Enum "Sales Document Type")
        {
            Caption = 'Process Returns as';
            ToolTip = 'Specifies what type of document to create when processing returns. Credit Memo creates a sales credit memo. Return Order creates a sales return order.';
            DataClassification = CustomerContent;
            ValuesAllowed = "Credit Memo", "Return Order";
            InitValue = "Credit Memo";
        }
        field(200; "Shop Id"; Integer)
        {
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA29
        field(201; "Items Mapped to Products"; Boolean)
        {
            Caption = 'Items Must be Mapped to Products';
            ToolTip = 'Specifies if only the items that are mapped to Shopify products/Shopify variants are synchronized from Posted Sales Invoices to Shopify.';
            ObsoleteReason = 'This setting is not used';
#if not CLEAN26
            ObsoleteState = Pending;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#endif
        }
#endif
        field(202; "Posted Invoice Sync"; Boolean)
        {
            Caption = 'Posted Invoice Sync';
            ToolTip = 'Specifies whether the posted sales invoices can be synchronized to Shopify.';
        }
        field(203; "Cash Roundings Account"; Code[20])
        {
            Caption = 'Cash Roundings Account';
            ToolTip = 'Specifies the general ledger account to use when you post cash rounding differences from Shopify POS transactions.';
            TableRelation = "G/L Account"."No.";
        }
        field(204; "Archive Processed Orders"; Boolean)
        {
            Caption = 'Archive Processed Shopify Orders';
            ToolTip = 'Specifies whether Shopify orders are automatically archived when they are paid, fulfilled, and have associated sales documents with all lines shipped.';
            InitValue = true;
        }
        field(205; "Create Invoices From Orders"; Boolean)
        {
            Caption = 'Create Fulfilled Orders as Invoices';
            ToolTip = 'Specifies if fully fulfilled Shopify orders should be created as sales invoices.';
            InitValue = true;
        }
#if not CLEANSCHEMA31
        field(206; "Fulfillment Service Updated"; Boolean)
        {
            Caption = 'Fulfillment Service Updated';
            DataClassification = SystemMetadata;
            Description = 'Indicates whether the Shopify Fulfillment Service has been updated to the latest version.';
            ObsoleteReason = 'This field is no longer used.';
#if CLEAN28
            ObsoleteState = Removed;
            ObsoleteTag = '31.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#endif
        }
#endif
        field(207; "Advanced Shopify Plan"; Boolean)
        {
            Caption = 'Advanced Shopify Plan';
            DataClassification = SystemMetadata;
        }
        field(208; "Find Mapping by Barcode"; Boolean)
        {
            Caption = 'Find Mapping by Barcode';
            ToolTip = 'Specifies whether to use the barcode as a fallback when the primary SKU mapping strategy does not find a match.';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
        key(Idx1; "Shop Id") { }
        key(Idx2; "Shopify URL") { }
        key(Idx3; Enabled) { }
    }

    trigger OnDelete()
    var
        ShpfyWebhooksMgt: Codeunit "Shpfy Webhooks Mgt.";
    begin
        ShpfyWebhooksMgt.DisableOrderCreatedWebhook(Rec);
        ShpfyWebhooksMgt.DisableBulkOperationsWebhook(Rec);
    end;

    var
        CurrencyExchangeRateNotDefinedErr: Label 'The specified currency must have exchange rates configured. If your online shop uses the same currency as Business Central then leave the field empty.';
        AutoCreateErrorMsg: Label 'You cannot turn "%1" off if "%2" is set to the value of "%3".', Comment = '%1 = Field Caption of "Auto Create Orders", %2 = Field Caption of "Return and Refund Process", %3 = Field Value of "Return and Refund Process"';
        ExpirationNotificationTxt: Label 'Shopify API version 30 days before expiry notification sent.', Locked = true;
        BlockedNotificationTxt: Label 'Shopify API version expired notification sent.', Locked = true;
        CategoryTok: Label 'Shopify Integration', Locked = true;
        ShopifyConsentProvidedLbl: Label 'Shopify - consent provided by UserSecurityId %1 for company %2.', Comment = '%1 - User Security ID, %2 - Company name', Locked = true;

    internal procedure RequestAccessToken()
    var
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
        Store: Text;
    begin
        Store := GetStoreName();
        if Store <> '' then
            AuthenticationMgt.InstallShopifyApp(Store, Rec);
    end;

    internal procedure HasAccessToken(): Boolean
    var
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
        Store: Text;
    begin
        Store := GetStoreName();
        if Store <> '' then
            exit(AuthenticationMgt.AccessTokenExist(Store));
    end;

    internal procedure TestConnection(): Boolean
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
    begin
        CommunicationMgt.SetShop(Rec);
        CommunicationMgt.ExecuteGraphQL('{"query":"query { app { id } }"}');
        exit(true);
    end;

    internal procedure GetStoreName() Store: Text
    begin
        Store := "Shopify URL".ToLower();
        if Store.Contains(':') then
            Store := Store.Split(':').Get(2);
        Store := Store.TrimStart('/').TrimEnd('/');
    end;

    internal procedure SetStoreName(Store: Text)
    begin
        Rec.Validate("Shopify URL", Store);
    end;

    /// <summary>
    /// Calc Shop Id.
    /// </summary>
    internal procedure CalcShopId()
    var
        Shop: Record "Shpfy Shop";
        Hash: Codeunit "Shpfy Hash";
    begin
        if "Shopify URL" = '' then
            "Shop Id" := 0;

        "Shop Id" := Hash.CalcHash("Shopify URL");
        Shop.SetRange("Shop Id", "Shop Id");
        Shop.SetFilter("Shopify URL", '<>%1', "Shopify URL");
        Shop.SetCurrentKey("Shop Id");
        while not Shop.IsEmpty do begin
            "Shop Id" += 1;
            Shop.SetRange("Shop Id", "Shop Id");
        end;
    end;

    internal procedure GetEmptySyncTime(): DateTime
    begin
        exit(CreateDateTime(20040101D, 0T));
    end;

    internal procedure GetLastSyncTime(Type: Enum "Shpfy Synchronization Type"): DateTime
    var
        SynchronizationInfo: Record "Shpfy Synchronization Info";
    begin
        if Type = "Shpfy Synchronization Type"::Orders then begin
            if Rec."Shop Id" = 0 then begin
                Rec.CalcShopId();
                Rec.Modify();
            end;
            if SynchronizationInfo.Get(Format(Rec."Shop Id"), Type) then
                if SynchronizationInfo."Last Sync Time" = 0DT then
                    exit(GetEmptySyncTime())
                else
                    exit(SynchronizationInfo."Last Sync Time");
        end;
        if SynchronizationInfo.Get(Rec.Code, Type) then
            if SynchronizationInfo."Last Sync Time" = 0DT then
                exit(GetEmptySyncTime())
            else
                exit(SynchronizationInfo."Last Sync Time");
        exit(GetEmptySyncTime());
    end;

    internal procedure SetLastSyncTime(Type: Enum "Shpfy Synchronization Type")
    begin
        SetLastSyncTime(Type, CurrentDateTime);
    end;

    internal procedure SetLastSyncTime(Type: Enum "Shpfy Synchronization Type"; ToDateTime: DateTime)
    var
        SynchronizationInfo: Record "Shpfy Synchronization Info";
        ShopCode: Code[20];
    begin
        if Type = "Shpfy Synchronization Type"::Orders then
            ShopCode := Format(Rec."Shop Id")
        else
            ShopCode := Rec.Code;
        if SynchronizationInfo.Get(ShopCode, Type) then begin
            SynchronizationInfo."Last Sync Time" := ToDateTime;
            SynchronizationInfo.Modify();
        end else begin
            Clear(SynchronizationInfo);
            SynchronizationInfo."Shop Code" := ShopCode;
            SynchronizationInfo."Synchronization Type" := Type;
            SynchronizationInfo."Last Sync Time" := ToDateTime;
            SynchronizationInfo.Insert();
        end;
    end;

    internal procedure CheckGLAccount(GLAccount: Record "G/L Account")
    begin
        GLAccount.TestField("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.TestField("Direct Posting", true);
        GLAccount.TestField(Blocked, false);
    end;


    local procedure EnableShopifyLogRetentionPolicySetup()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not TaskScheduler.CanCreateTask() then
            exit;

        if not (JobQueueEntry.ReadPermission() and JobQueueEntry.WritePermission()) then
            exit;

        if not RetentionPolicySetup.Get(Database::"Shpfy Log Entry") then
            exit;

        if RetentionPolicySetup.Enabled then
            exit;

        RetentionPolicySetup.Validate(Enabled, true);
        RetentionPolicySetup.Modify(true);
    end;

    internal procedure GetShopSettings()
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        JsonHelper: Codeunit "Shpfy Json Helper";
        JResponse: JsonToken;
        JItem: JsonToken;
    begin
        CommunicationMgt.SetShop(Rec);
        JResponse := CommunicationMgt.ExecuteGraphQL('{"query":"query { shop { name plan { publicDisplayName partnerDevelopment shopifyPlus } weightUnit } }"}');
        if JResponse.SelectToken('$.data.shop.plan', JItem) then
            if JItem.IsObject then
                Rec."Advanced Shopify Plan" := JsonHelper.GetValueAsBoolean(JItem, 'shopifyPlus') or
                                                (JsonHelper.GetValueAsText(JItem, 'publicDisplayName') in ['Plus Trial', 'Development', 'Advanced']);
        Rec."Weight Unit" := ConvertToWeightUnit(JsonHelper.GetValueAsText(JResponse, 'data.shop.weightUnit'));
    end;

    internal procedure GetShopWeightUnit(): Enum "Shpfy Weight Unit"
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        JsonHelper: Codeunit "Shpfy Json Helper";
        JResponse: JsonToken;
    begin
        CommunicationMgt.SetShop(Rec);
        JResponse := CommunicationMgt.ExecuteGraphQL('{"query":"query { shop { weightUnit } }"}');
        exit(ConvertToWeightUnit(JsonHelper.GetValueAsText(JResponse, 'data.shop.weightUnit')));
    end;

    internal procedure SyncCountries()
    begin
        Codeunit.Run(Codeunit::"Shpfy Sync Countries", Rec);
    end;

    local procedure ConvertToWeightUnit(Value: Text): Enum "Shpfy Weight Unit"
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
    begin
        Value := CommunicationMgt.ConvertToCleanOptionValue(Value);
        if Enum::"Shpfy Weight Unit".Names().Contains(Value) then
            exit(Enum::"Shpfy Weight Unit".FromInteger(Enum::"Shpfy Weight Unit".Ordinals().Get(Enum::"Shpfy Weight Unit".Names().IndexOf(Value))))
        else
            exit(Enum::"Shpfy Weight Unit"::" ");
    end;

    internal procedure CheckApiVersionExpiryDate(ApiVersion: Text; ApiVersionExpiryDateTime: DateTime)
    var
        ShopMgt: Codeunit "Shpfy Shop Mgt.";
    begin
        if CurrentDateTime() > ApiVersionExpiryDateTime then begin
            ShopMgt.SendBlockedNotification();
            Session.LogMessage('0000KNZ', BlockedNotificationTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        end else
            if Round((ApiVersionExpiryDateTime - CurrentDateTime()) / 1000 / 3600 / 24, 1) <= 30 then begin
                ShopMgt.SendExpirationNotification(DT2Date(ApiVersionExpiryDateTime));
                Session.LogMessage('0000KO0', ExpirationNotificationTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            end;
    end;

#if not CLEAN28
#pragma warning disable AL0432
    internal procedure UpdateFulfillmentService()
    var
        SyncShopLocations: Codeunit "Shpfy Sync Shop Locations";
    begin
        if Rec."Fulfillment Service Updated" then
            exit;

        if Rec."Fulfillment Service Activated" then begin
            SyncShopLocations.SetShop(Rec);
            SyncShopLocations.UpdateFulfillmentServiceCallbackUrl();
        end;

        Rec."Fulfillment Service Updated" := true;
        Rec.Modify();
    end;
#pragma warning restore AL0432
#endif

    local procedure VerifyNoItemAttributesAsOptions()
    var
        ItemAttribute: Record "Item Attribute";
        UoMVariantUnavailableErr: Label 'You cannot enable this setting because one or more Item Attributes are configured with "Incl. in Product Sync" set to "As Option".';
    begin
        ItemAttribute.SetRange("Shpfy Incl. in Product Sync", "Shpfy Incl. in Product Sync"::"As Option");
        if not ItemAttribute.IsEmpty() then
            Error(UoMVariantUnavailableErr);
    end;
}
