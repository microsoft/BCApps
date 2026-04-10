// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Reflection;
using System.Security.User;

/// <summary>
/// Stores line-level details for posted sales invoices including items, quantities, prices, and amounts.
/// </summary>
table 113 "Sales Invoice Line"
{
    Caption = 'Sales Invoice Line';
    DrillDownPageID = "Posted Sales Invoice Lines";
    LookupPageID = "Posted Sales Invoice Lines";
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Value Entry" = r;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the customer number who received the shipped items.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            ToolTip = 'Specifies the number of the customer.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the document number of the posted invoice this line belongs to.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number.';
            TableRelation = "Sales Invoice Header";
        }
        /// <summary>
        /// Specifies the line number within the document.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Specifies the type of entity on the line such as Item, G/L Account, or Resource.
        /// </summary>
        field(5; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the line type.';
        }
        /// <summary>
        /// Specifies the number of the item, G/L account, resource, or other entity on the line.
        /// </summary>
        field(6; "No."; Code[20])
        {
            CaptionClass = GetCaptionClass(FieldNo("No."));
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge";
        }
        /// <summary>
        /// Specifies the warehouse location from which items were shipped.
        /// </summary>
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location in which the invoice line was registered.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        /// <summary>
        /// Specifies the posting group that determines G/L accounts for inventory or fixed assets.
        /// </summary>
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = if (Type = const(Item)) "Inventory Posting Group"
            else
            if (Type = const("Fixed Asset")) "FA Posting Group";
        }
        /// <summary>
        /// Specifies the date when the items were shipped.
        /// </summary>
        field(10; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        /// <summary>
        /// Specifies a description of the item or service on the line.
        /// </summary>
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the name of the item or general ledger account, or some descriptive text.';
        }
        /// <summary>
        /// Specifies additional description text for the line.
        /// </summary>
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies information in addition to the description.';
        }
        /// <summary>
        /// Specifies the name of the unit of measure for the line.
        /// </summary>
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
            ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
        }
        /// <summary>
        /// Specifies the quantity of items or resources invoiced on the line.
        /// </summary>
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the number of units of the item specified on the line.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the price per unit of the item or resource.
        /// </summary>
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FieldNo("Unit Price"));
            Caption = 'Unit Price';
            ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
        }
        /// <summary>
        /// Specifies the unit cost in local currency.
        /// </summary>
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost (LCY)';
        }
        /// <summary>
        /// Specifies the VAT percentage applied to the line.
        /// </summary>
        field(25; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            ToolTip = 'Specifies the VAT %.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Specifies the line discount percentage applied.
        /// </summary>
        field(27; "Line Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Line Discount %';
            ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the line discount amount in document currency.
        /// </summary>
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
            ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
        }
        /// <summary>
        /// Specifies the line amount excluding VAT.
        /// </summary>
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the line''s net amount.';
        }
        /// <summary>
        /// Specifies the line amount including VAT.
        /// </summary>
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            ToolTip = 'Specifies the net amount, including VAT, for this line.';
        }
        /// <summary>
        /// Indicates whether the line can be included in invoice discount calculation.
        /// </summary>
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
            InitValue = true;
        }
        /// <summary>
        /// Specifies the gross weight of the items on the line.
        /// </summary>
        field(34; "Gross Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Gross Weight';
            ToolTip = 'Specifies the gross weight of one unit of the item. In the sales statistics window, the gross weight on the line is included in the total gross weight of all the lines for the particular sales document.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the net weight of the items on the line.
        /// </summary>
        field(35; "Net Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Net Weight';
            ToolTip = 'Specifies the net weight of one unit of the item. In the sales statistics window, the net weight on the line is included in the total net weight of all the lines for the particular sales document.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the number of units per parcel for shipping.
        /// </summary>
        field(36; "Units per Parcel"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Units per Parcel';
            ToolTip = 'Specifies the number of units per parcel of the item. In the sales statistics window, the number of units per parcel on the line helps to determine the total number of units for all the lines for the particular sales document.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the volume of a single unit of the item.
        /// </summary>
        field(37; "Unit Volume"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit Volume';
            ToolTip = 'Specifies the volume of one unit of the item. In the sales statistics window, the volume of one unit of the item on the line is included in the total volume of all the lines for the particular sales document.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the item ledger entry number to apply this line to.
        /// </summary>
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';
            ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
        }
        /// <summary>
        /// Specifies the first global dimension code for analysis.
        /// </summary>
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Specifies the second global dimension code for analysis.
        /// </summary>
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Specifies the customer price group used for pricing.
        /// </summary>
        field(42; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        /// <summary>
        /// Specifies the project number associated with the line.
        /// </summary>
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project.';
            TableRelation = Job;
        }
        /// <summary>
        /// Specifies the work type code for resource pricing.
        /// </summary>
        field(52; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";
        }
        /// <summary>
        /// Specifies the shipment document number from which this line was invoiced.
        /// </summary>
        field(63; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the line number from the shipment document.
        /// </summary>
        field(64; "Shipment Line No."; Integer)
        {
            Caption = 'Shipment Line No.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the sales order number from which this invoice was created.
        /// </summary>
        field(65; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            ToolTip = 'Specifies the order number this line is associated with.';
        }
        /// <summary>
        /// Specifies the line number from the original sales order.
        /// </summary>
        field(66; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        /// <summary>
        /// Specifies the customer number to whom the invoice was sent.
        /// </summary>
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the invoice discount amount allocated to this line.
        /// </summary>
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
        }
        /// <summary>
        /// Indicates whether the items were shipped directly from the vendor to the customer.
        /// </summary>
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
        }
        /// <summary>
        /// Specifies the general business posting group for determining G/L accounts.
        /// </summary>
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// Specifies the general product posting group for determining G/L accounts.
        /// </summary>
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// Specifies the method used to calculate VAT for this line.
        /// </summary>
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
        }
        /// <summary>
        /// Specifies the transaction type for Intrastat reporting.
        /// </summary>
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        /// <summary>
        /// Specifies the transport method for Intrastat reporting.
        /// </summary>
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        /// <summary>
        /// Specifies the line number this line is attached to for extended text or comments.
        /// </summary>
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            TableRelation = "Sales Invoice Line"."Line No." where("Document No." = field("Document No."));
        }
        /// <summary>
        /// Specifies the exit point for Intrastat reporting.
        /// </summary>
        field(81; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        /// <summary>
        /// Specifies the area code for Intrastat reporting.
        /// </summary>
        field(82; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        /// <summary>
        /// Specifies additional transaction details for Intrastat reporting.
        /// </summary>
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        /// <summary>
        /// Specifies the tax category code for tax reporting.
        /// </summary>
        field(84; "Tax Category"; Code[10])
        {
            Caption = 'Tax Category';
        }
        /// <summary>
        /// Specifies the tax area code for sales tax calculation.
        /// </summary>
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the sale is liable for tax.
        /// </summary>
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
        }
        /// <summary>
        /// Specifies the tax group code for sales tax calculation.
        /// </summary>
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Specifies the VAT clause code for additional VAT information on documents.
        /// </summary>
        field(88; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        /// <summary>
        /// Specifies the VAT business posting group for VAT calculation.
        /// </summary>
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Specifies the VAT product posting group for VAT calculation.
        /// </summary>
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Specifies the blanket order number this line originated from.
        /// </summary>
        field(97; "Blanket Order No."; Code[20])
        {
            Caption = 'Blanket Order No.';
            ToolTip = 'Specifies the number of the blanket order that the record originates from.';
            TableRelation = "Sales Header"."No." where("Document Type" = const("Blanket Order"));
        }
        /// <summary>
        /// Specifies the line number from the blanket order.
        /// </summary>
        field(98; "Blanket Order Line No."; Integer)
        {
            Caption = 'Blanket Order Line No.';
            ToolTip = 'Specifies the number of the blanket order line that the record originates from.';
            TableRelation = "Sales Line"."Line No." where("Document Type" = const("Blanket Order"),
                                                           "Document No." = field("Blanket Order No."));
        }
        /// <summary>
        /// Specifies the amount used as the base for VAT calculation.
        /// </summary>
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        /// <summary>
        /// Specifies the unit cost in document currency.
        /// </summary>
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether the line was created automatically by the system.
        /// </summary>
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        /// <summary>
        /// Specifies the net amount for the line before invoice discount.
        /// </summary>
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Line Amount"));
            Caption = 'Line Amount';
            ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
        }
        /// <summary>
        /// Specifies the difference between calculated and posted VAT amounts.
        /// </summary>
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Difference';
        }
        /// <summary>
        /// Specifies the VAT identifier for grouping VAT entries.
        /// </summary>
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        /// <summary>
        /// Specifies the type of intercompany partner reference.
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
        }
        /// <summary>
        /// Specifies the intercompany partner reference code.
        /// </summary>
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
        }
        /// <summary>
        /// Indicates whether this is a prepayment line.
        /// </summary>
        field(123; "Prepayment Line"; Boolean)
        {
            Caption = 'Prepayment Line';
            Editable = false;
        }
        /// <summary>
        /// Specifies the intercompany partner code for intercompany transactions.
        /// </summary>
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Specifies the date when the line was posted.
        /// </summary>
        field(131; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Specifies the item reference number for intercompany transactions.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
        }
        /// <summary>
        /// Specifies the payment discount amount for the line.
        /// </summary>
        field(145; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Amount';
        }
        /// <summary>
        /// Specifies how the line discount was calculated.
        /// </summary>
        field(180; "Line Discount Calculation"; Option)
        {
            Caption = 'Line Discount Calculation';
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        /// <summary>
        /// Specifies the unique identifier for the dimension set applied to this line.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        /// <summary>
        /// Specifies the project task number for project-related invoices.
        /// </summary>
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the number of the related project task.';
            Editable = false;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        /// <summary>
        /// Specifies the project contract entry number for billing.
        /// </summary>
        field(1002; "Job Contract Entry No."; Integer)
        {
            Caption = 'Project Contract Entry No.';
            ToolTip = 'Specifies the entry number of the project planning line that the sales line is linked to.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the deferral template code for revenue deferral.
        /// </summary>
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            ToolTip = 'Specifies the deferral template that governs how revenue earned with this sales document is deferred to the different accounting periods when the good or service was delivered.';
            TableRelation = "Deferral Template"."Deferral Code";
        }
        /// <summary>
        /// Specifies the allocation account number for distributing amounts.
        /// </summary>
        field(2678; "Allocation Account No."; Code[20])
        {
            Caption = 'Allocation Account No.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Stores the system ID of the allocation sales line.
        /// </summary>
        field(2679; "Alloc. Sales Line SystemId"; Guid)
        {
            Caption = 'Allocation Sales Line SystemId';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the item variant code for items with variants.
        /// </summary>
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        /// <summary>
        /// Specifies the warehouse bin code where items were stored.
        /// </summary>
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the bin where the items are picked or put away.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"),
                                            "Item Filter" = field("No."),
                                            "Variant Filter" = field("Variant Code"));
        }
        /// <summary>
        /// Specifies the quantity per unit of measure for conversion.
        /// </summary>
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Specifies the unit of measure code for the line.
        /// </summary>
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";
        }
        /// <summary>
        /// Specifies the quantity in the base unit of measure.
        /// </summary>
        field(5415; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the posting date for fixed asset transactions.
        /// </summary>
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        /// <summary>
        /// Specifies the depreciation book for fixed asset posting.
        /// </summary>
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        /// <summary>
        /// Indicates whether to calculate depreciation until the FA posting date.
        /// </summary>
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
        }
        /// <summary>
        /// Specifies a depreciation book to duplicate the entry to.
        /// </summary>
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";
        }
        /// <summary>
        /// Indicates whether to use the duplication list for fixed asset posting.
        /// </summary>
        field(5613; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
        }
        /// <summary>
        /// Specifies the responsibility center for the line.
        /// </summary>
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        /// <summary>
        /// Specifies the item category code for categorization.
        /// </summary>
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = if (Type = const(Item)) "Item Category";
        }
        /// <summary>
        /// Indicates whether the item is a catalog item.
        /// </summary>
        field(5710; Nonstock; Boolean)
        {
            Caption = 'Catalog';
            ToolTip = 'Specifies that this item is a catalog item.';
        }
        /// <summary>
        /// Specifies the purchasing code for special order handling.
        /// </summary>
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        /// <summary>
        /// Specifies the item reference number used by the customer.
        /// </summary>
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
            ToolTip = 'Specifies the referenced item number.';
        }
        /// <summary>
        /// Specifies the unit of measure associated with the item reference.
        /// </summary>
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure (Item Ref.)';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        /// <summary>
        /// Specifies the type of item reference such as customer or vendor.
        /// </summary>
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
        }
        /// <summary>
        /// Specifies the number associated with the item reference type.
        /// </summary>
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
        }
        /// <summary>
        /// Specifies the item ledger entry to apply from for cost tracking.
        /// </summary>
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied from.';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the reason code if items were returned.
        /// </summary>
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            ToolTip = 'Specifies the code explaining why the item was returned.';
            TableRelation = "Return Reason";
        }
        /// <summary>
        /// Specifies the method used for price calculation.
        /// </summary>
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        /// <summary>
        /// Indicates whether line discounts are allowed for this line.
        /// </summary>
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
        }
        /// <summary>
        /// Specifies the customer discount group for line discount calculation.
        /// </summary>
        field(7002; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        /// <summary>
        /// Contains a formatted description of the price calculation.
        /// </summary>
        field(7004; "Price description"; Text[80])
        {
            Caption = 'Price description';
        }
        /// <summary>
        /// Contains the name of the sell-to customer.
        /// </summary>
        field(7012; "Sell-to Customer Name"; Text[100])
        {
            CalcFormula = lookup(Customer.Name where("No." = field("Sell-to Customer No.")));
            Caption = 'Sell-to Customer Name';
            ToolTip = 'Specifies the name of the customer.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key3; "Sell-to Customer No.")
        {
        }
        key(Key5; "Shipment No.", "Shipment Line No.")
        {
        }
        key(Key6; "Job Contract Entry No.")
        {
        }
        key(Key7; "Bill-to Customer No.")
        {
        }
        key(Key8; "Order No.", "Order Line No.", "Posting Date")
        {
        }
        key(Key9; "Document No.", "Location Code")
        {
            IncludedFields = Amount, "Amount Including VAT", "Inv. Discount Amount";
        }
        key(Key10; Type, "No.")
        {
            IncludedFields = "Quantity (Base)";
        }
        key(Key11; "Job No.", "Job Task No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "No.", Description, "Line Amount", "Price description", Quantity, "Unit of Measure Code")
        {
        }
    }

    trigger OnDelete()
    var
        SalesDocLineComments: Record "Sales Comment Line";
        PostedDeferralHeader: Record "Posted Deferral Header";
    begin
        SalesDocLineComments.SetRange("Document Type", SalesDocLineComments."Document Type"::"Posted Invoice");
        SalesDocLineComments.SetRange("No.", "Document No.");
        SalesDocLineComments.SetRange("Document Line No.", "Line No.");
        if not SalesDocLineComments.IsEmpty() then
            SalesDocLineComments.DeleteAll();

        PostedDeferralHeader.DeleteHeader(
            "Deferral Document Type"::Sales.AsInteger(), '', '',
            SalesDocLineComments."Document Type"::"Posted Invoice".AsInteger(), "Document No.", "Line No.");
    end;

    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Currency: Record Currency;
        DimMgt: Codeunit DimensionManagement;
        UOMMgt: Codeunit "Unit of Measure Management";
        DeferralUtilities: Codeunit "Deferral Utilities";
        PriceDescriptionTxt: Label 'x%1 (%2%3/%4)', Locked = true;
        PriceDescriptionWithLineDiscountTxt: Label 'x%1 (%2%3/%4) - %5%', Locked = true;

    /// <summary>
    /// Retrieves the currency code from the sales invoice header.
    /// </summary>
    /// <returns>The currency code for this invoice line.</returns>
    procedure GetCurrencyCode(): Code[10]
    begin
        GetHeader();
        exit(SalesInvoiceHeader."Currency Code");
    end;

    /// <summary>
    /// Opens the dimension set entries page for this invoice line.
    /// </summary>
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    /// <summary>
    /// Opens the Item Tracking Lines page showing the tracking for this invoice line.
    /// </summary>
    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine(RowID1());
    end;

    /// <summary>
    /// Calculates VAT amount lines for the invoice based on the invoice lines.
    /// </summary>
    /// <param name="SalesInvHeader">The invoice header to calculate VAT for.</param>
    /// <param name="TempVATAmountLine">Returns the calculated VAT amount lines.</param>
    procedure CalcVATAmountLines(SalesInvHeader: Record "Sales Invoice Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcVATAmountLines(Rec, SalesInvHeader, TempVATAmountLine, IsHandled);
        if IsHandled then
            exit;

        TempVATAmountLine.DeleteAll();
        SetRange("Document No.", SalesInvHeader."No.");
        if Find('-') then
            repeat
                TempVATAmountLine.Init();
                TempVATAmountLine.CopyFromSalesInvLine(Rec);
                TempVATAmountLine.InsertLine();
            until Next() = 0;
    end;

    /// <summary>
    /// Calculates the line amount excluding VAT.
    /// </summary>
    /// <returns>The line amount excluding VAT.</returns>
    procedure GetLineAmountExclVAT(): Decimal
    begin
        GetHeader();
        if not SalesInvoiceHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" / (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// Calculates the line amount including VAT.
    /// </summary>
    /// <returns>The line amount including VAT.</returns>
    procedure GetLineAmountInclVAT(): Decimal
    begin
        GetHeader();
        if SalesInvoiceHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" * (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// Retrieves the sales invoice header record for this line.
    /// </summary>
    /// <returns>The sales invoice header record.</returns>
    procedure GetInvoiceHeader(): Record "Sales Invoice Header"
    begin
        GetHeader();
        exit(SalesInvoiceHeader);
    end;

    local procedure GetHeader()
    begin
        if SalesInvoiceHeader."No." = "Document No." then
            exit;
        if not SalesInvoiceHeader.Get("Document No.") then
            SalesInvoiceHeader.Init();

        if SalesInvoiceHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            if not Currency.Get(SalesInvoiceHeader."Currency Code") then
                Currency.InitRoundingPrecision();
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Sales Invoice Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    /// <summary>
    /// Retrieves the caption class for a specified field to handle VAT-inclusive pricing display.
    /// </summary>
    /// <param name="FieldNumber">The field number to get the caption class for.</param>
    /// <returns>The caption class string for the field.</returns>
    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    begin
        GetHeader();
        case FieldNumber of
            FieldNo("No."):
                exit(StrSubstNo('3,%1', GetFieldCaption(FieldNumber)));
            else begin
                if SalesInvoiceHeader."Prices Including VAT" then
                    exit('2,1,' + GetFieldCaption(FieldNumber));
                exit('2,0,' + GetFieldCaption(FieldNumber));
            end
        end;
    end;

    /// <summary>
    /// Generates a unique row identifier for item tracking purposes.
    /// </summary>
    /// <returns>The row identifier string.</returns>
    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Sales Invoice Line",
            0, "Document No.", '', 0, "Line No."));
    end;

    /// <summary>
    /// Retrieves the sales shipment lines associated with this invoice line.
    /// </summary>
    /// <param name="TempSalesShipmentLine">Returns the temporary sales shipment lines.</param>
    procedure GetSalesShptLines(var TempSalesShipmentLine: Record "Sales Shipment Line" temporary)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
    begin
        TempSalesShipmentLine.Reset();
        TempSalesShipmentLine.DeleteAll();

        if Type <> Type::Item then
            exit;

        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_No, "Document No.");
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Type, Enum::"Item Ledger Document Type"::"Sales Invoice");
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Line_No, "Line No.");
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Type, Enum::"Item Ledger Document Type"::"Sales Shipment");
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do
            if SalesShipmentLine.Get(ValueItemLedgerEntries.Item_Ledg_Document_No, ValueItemLedgerEntries.Item_Ledg_Document_Line_No) then begin
                TempSalesShipmentLine.Init();
                TempSalesShipmentLine := SalesShipmentLine;
                if TempSalesShipmentLine.Insert() then;
            end;
    end;

    /// <summary>
    /// Calculates the shipped sales quantity that has not been returned.
    /// </summary>
    /// <param name="ShippedQtyNotReturned">Returns the quantity shipped but not returned.</param>
    /// <param name="RevUnitCostLCY">Returns the reverse unit cost in local currency.</param>
    /// <param name="ExactCostReverse">Specifies whether to use exact cost reversing.</param>
    procedure CalcShippedSaleNotReturned(var ShippedQtyNotReturned: Decimal; var RevUnitCostLCY: Decimal; ExactCostReverse: Boolean)
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TotalCostLCY: Decimal;
        TotalQtyBase: Decimal;
    begin
        ShippedQtyNotReturned := 0;
        if (Type <> Type::Item) or (Quantity <= 0) then begin
            RevUnitCostLCY := "Unit Cost (LCY)";
            exit;
        end;

        RevUnitCostLCY := 0;
        GetItemLedgEntries(TempItemLedgEntry, false);
        if TempItemLedgEntry.FindSet() then
            repeat
                ShippedQtyNotReturned := ShippedQtyNotReturned - TempItemLedgEntry."Shipped Qty. Not Returned";
                if ExactCostReverse then begin
                    TempItemLedgEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
                    TotalCostLCY :=
                      TotalCostLCY + TempItemLedgEntry."Cost Amount (Expected)" + TempItemLedgEntry."Cost Amount (Actual)";
                    TotalQtyBase := TotalQtyBase + TempItemLedgEntry.Quantity;
                end;
            until TempItemLedgEntry.Next() = 0;

        if ExactCostReverse and (ShippedQtyNotReturned <> 0) and (TotalQtyBase <> 0) then
            RevUnitCostLCY := Abs(TotalCostLCY / TotalQtyBase) * "Qty. per Unit of Measure"
        else
            RevUnitCostLCY := "Unit Cost (LCY)";
        ShippedQtyNotReturned := CalcQty(ShippedQtyNotReturned);

        if ShippedQtyNotReturned > Quantity then
            ShippedQtyNotReturned := Quantity;

        OnAfterCalcShippedSaleNotReturned(Rec, ShippedQtyNotReturned, RevUnitCostLCY, ExactCostReverse);
    end;

    local procedure CalcQty(QtyBase: Decimal) Result: Decimal
    begin
        if "Qty. per Unit of Measure" = 0 then
            Result := QtyBase
        else
            Result := Round(QtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        OnAfterCalcQty(Rec, QtyBase, Result);
    end;

    /// <summary>
    /// Retrieves item ledger entries associated with this invoice line.
    /// </summary>
    /// <param name="TempItemLedgEntry">Returns the temporary item ledger entries.</param>
    /// <param name="SetQuantity">Indicates whether to set quantities from value entries.</param>
    procedure GetItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SetQuantity: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemLedgEntries(Rec, TempItemLedgEntry, SetQuantity, IsHandled);
        if IsHandled then
            exit;

        if SetQuantity then begin
            TempItemLedgEntry.Reset();
            TempItemLedgEntry.DeleteAll();

            if Type <> Type::Item then
                exit;
        end;

        FilterPstdDocLineValueEntries(ValueEntry);
        ValueEntry.SetFilter("Invoiced Quantity", '<>0');
        if ValueEntry.FindSet() then
            repeat
                ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                TempItemLedgEntry := ItemLedgEntry;
                if SetQuantity then begin
                    TempItemLedgEntry.Quantity := ValueEntry."Invoiced Quantity";
                    if Abs(TempItemLedgEntry."Shipped Qty. Not Returned") > Abs(TempItemLedgEntry.Quantity) then
                        TempItemLedgEntry."Shipped Qty. Not Returned" := TempItemLedgEntry.Quantity;
                end;
                OnGetItemLedgEntriesOnBeforeTempItemLedgEntryInsert(TempItemLedgEntry, ValueEntry, SetQuantity);
                if TempItemLedgEntry.Insert() then;
            until ValueEntry.Next() = 0;
    end;

    /// <summary>
    /// Applies filters to value entries to retrieve entries for this posted document line.
    /// </summary>
    /// <param name="ValueEntry">The value entry record to apply filters to.</param>
    procedure FilterPstdDocLineValueEntries(var ValueEntry: Record "Value Entry")
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", "Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.SetRange("Document Line No.", "Line No.");
    end;

    /// <summary>
    /// Opens a page displaying the shipment lines for this invoice line.
    /// </summary>
    procedure ShowItemShipmentLines()
    var
        TempSalesShptLine: Record "Sales Shipment Line" temporary;
    begin
        if Type = Type::Item then begin
            GetSalesShptLines(TempSalesShptLine);
            PAGE.RunModal(0, TempSalesShptLine);
        end;
    end;

    /// <summary>
    /// Opens a page displaying the comments for this invoice line.
    /// </summary>
    procedure ShowLineComments()
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.ShowComments(SalesCommentLine."Document Type"::"Posted Invoice".AsInteger(), "Document No.", "Line No.");
    end;

    /// <summary>
    /// Retrieves the shortcut dimension codes for this invoice line.
    /// </summary>
    /// <param name="ShortcutDimCode">Returns the array of shortcut dimension codes.</param>
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    /// <summary>
    /// Initializes the sales invoice line from a sales line when posting an invoice.
    /// </summary>
    /// <param name="SalesInvHeader">The sales invoice header to link to.</param>
    /// <param name="SalesLine">The sales line to copy data from.</param>
    procedure InitFromSalesLine(SalesInvHeader: Record "Sales Invoice Header"; SalesLine: Record "Sales Line")
    begin
        Init();
        TransferFields(SalesLine);
        if ("No." = '') and HasTypeToFillMandatoryFields() then
            Type := Type::" ";
        "Posting Date" := SalesInvHeader."Posting Date";
        "Document No." := SalesInvHeader."No.";
        Quantity := SalesLine."Qty. to Invoice";
        "Quantity (Base)" := SalesLine."Qty. to Invoice (Base)";

        OnAfterInitFromSalesLine(Rec, SalesInvHeader, SalesLine);
    end;

    /// <summary>
    /// Opens a page displaying the deferral schedule for this invoice line.
    /// </summary>
    procedure ShowDeferrals()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDeferrals(Rec, IsHandled);
        if IsHandled then
            exit;

        DeferralUtilities.OpenLineScheduleView(
            "Deferral Code", "Deferral Document Type"::Sales.AsInteger(), '', '',
            GetDocumentType(), "Document No.", "Line No.");
    end;

    /// <summary>
    /// Updates the price description field based on current line values.
    /// </summary>
    procedure UpdatePriceDescription()
    var
        Currency: Record Currency;
    begin
        "Price description" := '';
        if Type in [Type::"Charge (Item)", Type::"Fixed Asset", Type::Item, Type::Resource] then
            if "Line Discount %" = 0 then
                "Price description" := StrSubstNo(
                    PriceDescriptionTxt, Quantity, Currency.ResolveGLCurrencySymbol(GetCurrencyCode()),
                    "Unit Price", "Unit of Measure")
            else
                "Price description" := StrSubstNo(
                    PriceDescriptionWithLineDiscountTxt, Quantity, Currency.ResolveGLCurrencySymbol(GetCurrencyCode()),
                    "Unit Price", "Unit of Measure", "Line Discount %");
    end;

    /// <summary>
    /// Formats the line type for display, handling blank types specially.
    /// </summary>
    /// <returns>Returns the formatted type text.</returns>
    procedure FormatType(): Text
    var
        SalesLine: Record "Sales Line";
    begin
        if Type = Type::" " then
            exit(SalesLine.FormatType());

        exit(Format(Type));
    end;

    /// <summary>
    /// Retrieves the document type integer for this posted invoice line.
    /// </summary>
    /// <returns>Returns the document type value as an integer.</returns>
    procedure GetDocumentType(): Integer
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        exit(SalesCommentLine."Document Type"::"Posted Invoice".AsInteger())
    end;

    /// <summary>
    /// Determines whether the line has a type that requires mandatory fields to be filled.
    /// </summary>
    /// <returns>Returns true if the line type is not blank.</returns>
    procedure HasTypeToFillMandatoryFields(): Boolean
    begin
        exit(Type <> Type::" ");
    end;

    /// <summary>
    /// Checks if the line type supports invoice cancellation.
    /// </summary>
    /// <returns>Returns true if the line type can be cancelled.</returns>
    procedure IsCancellationSupported(): Boolean
    begin
        exit(Type in [Type::" ", Type::Item, Type::"G/L Account", Type::"Charge (Item)", Type::Resource]);
    end;

    /// <summary>
    /// Applies a security filter based on the user's responsibility center setup.
    /// </summary>
    procedure SetSecurityFilterOnRespCenter()
    var
        UserSetupManagement: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupManagement.GetSalesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupManagement.GetSalesFilter());
            FilterGroup(0);
        end;
    end;

    /// <summary>
    /// Retrieves the date to use for calculations, defaulting to work date if posting date is not set.
    /// </summary>
    /// <returns>The calculation date.</returns>
    procedure GetDateForCalculations() CalculationDate: Date;
    begin
        CalculationDate := Rec."Posting Date";
        if CalculationDate = 0D then
            CalculationDate := WorkDate();
    end;

    internal procedure GetVATPct() VATPct: Decimal
    begin
        VATPct := "VAT %";
        OnAfterGetVATPct(Rec, VATPct);
    end;

    /// <summary>
    /// Raised after calculating the quantity for the sales invoice line.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line record.</param>
    /// <param name="QtyBase">The base quantity used in the calculation.</param>
    /// <param name="Result">The calculated result quantity.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQty(var SalesInvoiceLine: Record "Sales Invoice Line"; QtyBase: Decimal; var Result: Decimal)
    begin
    end;

    /// <summary>
    /// Raised after initializing the sales invoice line from a sales line.
    /// </summary>
    /// <param name="SalesInvLine">The sales invoice line being initialized.</param>
    /// <param name="SalesInvHeader">The sales invoice header record.</param>
    /// <param name="SalesLine">The source sales line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesLine(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised before getting item ledger entries for the sales invoice line.
    /// </summary>
    /// <param name="SalesInvLine">The sales invoice line record.</param>
    /// <param name="TempItemLedgEntry">The temporary item ledger entry buffer.</param>
    /// <param name="SetQuantity">Specifies whether to set the quantity.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemLedgEntries(var SalesInvLine: Record "Sales Invoice Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SetQuantity: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before calculating VAT amount lines for the sales invoice.
    /// </summary>
    /// <param name="SalesInvLine">The sales invoice line record.</param>
    /// <param name="SalesInvHeader">The sales invoice header record.</param>
    /// <param name="TempVATAmountLine">The temporary VAT amount line buffer.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcVATAmountLines(SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting the temporary item ledger entry during GetItemLedgEntries.
    /// </summary>
    /// <param name="TempItemLedgerEntry">The temporary item ledger entry being inserted.</param>
    /// <param name="ValueEntry">The source value entry record.</param>
    /// <param name="SetQuantity">Specifies whether to set the quantity.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetItemLedgEntriesOnBeforeTempItemLedgEntryInsert(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; ValueEntry: Record "Value Entry"; SetQuantity: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before showing deferrals for the sales invoice line.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeferrals(SalesInvoiceLine: Record "Sales Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before setting the security filter on responsibility center for the sales invoice line.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesInvoiceLine: Record "Sales Invoice Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after getting the VAT percentage for the sales invoice line.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line record.</param>
    /// <param name="VATPct">The VAT percentage value.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPct(var SalesInvoiceLine: Record "Sales Invoice Line"; var VATPct: Decimal)
    begin
    end;

    /// <summary>
    /// Raised after calculating the shipped sales quantity not returned.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line record.</param>
    /// <param name="ShippedQtyNotReturned">The shipped quantity that has not been returned.</param>
    /// <param name="RevUnitCostLCY">The reverse unit cost in local currency.</param>
    /// <param name="ExactCostReverse">Specifies whether exact cost reversing is enabled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcShippedSaleNotReturned(var SalesInvoiceLine: Record "Sales Invoice Line"; var ShippedQtyNotReturned: Decimal; var RevUnitCostLCY: Decimal; ExactCostReverse: Boolean)
    begin
    end;
}
