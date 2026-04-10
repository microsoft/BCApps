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
/// Stores line-level details for posted sales credit memos including credited items, quantities, and amounts.
/// </summary>
table 115 "Sales Cr.Memo Line"
{
    Caption = 'Sales Cr.Memo Line';
    DrillDownPageID = "Posted Sales Credit Memo Lines";
    LookupPageID = "Posted Sales Credit Memo Lines";
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Value Entry" = r;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the customer number who received the credited items.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            ToolTip = 'Specifies the number of the customer.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the document number of the posted credit memo header.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number.';
            TableRelation = "Sales Cr.Memo Header";
        }
        /// <summary>
        /// Specifies the sequential line number within the credit memo.
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
        /// Specifies the location from which items were shipped or returned.
        /// </summary>
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location in which the credit memo line was registered.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        /// <summary>
        /// Specifies the posting group used to post the line to the general ledger.
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
        /// Specifies the date when items were shipped related to this line.
        /// </summary>
        field(10; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        /// <summary>
        /// Specifies the description of the item, account, or resource on the line.
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
        /// Specifies the unit of measure description for the line item.
        /// </summary>
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
            ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
        }
        /// <summary>
        /// Specifies the credited quantity on the line.
        /// </summary>
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the number of units of the item specified on the line.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the unit price of the item or resource on the line.
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
        /// Specifies the unit cost in local currency for the line item.
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
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Specifies the line discount percentage applied to the line.
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
        /// Specifies the line discount amount applied to the line.
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
        /// Indicates whether the line is included in invoice discount calculations.
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
        /// Specifies the item ledger entry to apply this credit to.
        /// </summary>
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';
            ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
        }
        /// <summary>
        /// Specifies the first global dimension code used for analysis.
        /// </summary>
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Specifies the second global dimension code used for analysis.
        /// </summary>
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Specifies the customer price group used for pricing on this line.
        /// </summary>
        field(42; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        /// <summary>
        /// Specifies the project number associated with this line.
        /// </summary>
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project.';
            TableRelation = Job;
        }
        /// <summary>
        /// Specifies the work type code for resource billing.
        /// </summary>
        field(52; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";
        }
        /// <summary>
        /// Specifies the original return order number for this line.
        /// </summary>
        field(65; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            ToolTip = 'Specifies the order number this line is associated with.';
        }
        /// <summary>
        /// Specifies the original return order line number.
        /// </summary>
        field(66; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        /// <summary>
        /// Specifies the customer number who receives the credit memo for billing.
        /// </summary>
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the invoice discount amount applied to this line.
        /// </summary>
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
        }
        /// <summary>
        /// Specifies the general business posting group for the line.
        /// </summary>
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// Specifies the general product posting group for the line.
        /// </summary>
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// Specifies the method used to calculate VAT on the line.
        /// </summary>
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
        }
        /// <summary>
        /// Specifies the transaction type code for Intrastat reporting.
        /// </summary>
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        /// <summary>
        /// Specifies the transport method code for Intrastat reporting.
        /// </summary>
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        /// <summary>
        /// Specifies the parent line number for attached lines such as extended text.
        /// </summary>
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            TableRelation = "Sales Cr.Memo Line"."Line No." where("Document No." = field("Document No."));
        }
        /// <summary>
        /// Specifies the exit point for goods leaving the country for Intrastat.
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
        /// Specifies the transaction specification code for Intrastat reporting.
        /// </summary>
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        /// <summary>
        /// Specifies the tax category for electronic document reporting.
        /// </summary>
        field(84; "Tax Category"; Code[10])
        {
            Caption = 'Tax Category';
        }
        /// <summary>
        /// Specifies the tax area code for sales tax calculations.
        /// </summary>
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the line is subject to sales tax.
        /// </summary>
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
        }
        /// <summary>
        /// Specifies the tax group code for sales tax calculations.
        /// </summary>
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Specifies the VAT clause code for legal reporting requirements.
        /// </summary>
        field(88; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        /// <summary>
        /// Specifies the VAT business posting group for tax calculations.
        /// </summary>
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Specifies the VAT product posting group for tax calculations.
        /// </summary>
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Specifies the blanket order number this line is linked to.
        /// </summary>
        field(97; "Blanket Order No."; Code[20])
        {
            Caption = 'Blanket Order No.';
            ToolTip = 'Specifies the number of the blanket order that the record originates from.';
            TableRelation = "Sales Header"."No." where("Document Type" = const("Blanket Order"));
        }
        /// <summary>
        /// Specifies the blanket order line number this line is linked to.
        /// </summary>
        field(98; "Blanket Order Line No."; Integer)
        {
            Caption = 'Blanket Order Line No.';
            ToolTip = 'Specifies the number of the blanket order line that the record originates from.';
            TableRelation = "Sales Line"."Line No." where("Document Type" = const("Blanket Order"),
                                                           "Document No." = field("Blanket Order No."));
        }
        /// <summary>
        /// Specifies the base amount used for VAT calculations.
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
        /// Specifies the total line amount before invoice discount.
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
        /// Specifies the difference between calculated and manually entered VAT.
        /// </summary>
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Difference';
        }
        /// <summary>
        /// Specifies the VAT identifier used to group VAT setup combinations.
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
        /// Specifies the intercompany partner reference for cross-company transactions.
        /// </summary>
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
        }
        /// <summary>
        /// Indicates whether this is a prepayment credit memo line.
        /// </summary>
        field(123; "Prepayment Line"; Boolean)
        {
            Caption = 'Prepayment Line';
            Editable = false;
        }
        /// <summary>
        /// Specifies the intercompany partner code for cross-company transactions.
        /// </summary>
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Specifies the posting date of the credit memo line.
        /// </summary>
        field(131; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Specifies the intercompany item reference number for cross-company transactions.
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
        /// Specifies the project task number associated with this line.
        /// </summary>
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the number of the related project task.';
            Editable = false;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        /// <summary>
        /// Specifies the project contract entry number for project billing.
        /// </summary>
        field(1002; "Job Contract Entry No."; Integer)
        {
            Caption = 'Project Contract Entry No.';
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
        /// Specifies the item variant code for the item on the line.
        /// </summary>
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        /// <summary>
        /// Specifies the bin code where the item is stored or was returned to.
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
        /// Specifies the unit of measure code for the line item.
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
        /// Specifies the fixed asset posting date for depreciation.
        /// </summary>
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        /// <summary>
        /// Specifies the depreciation book code for fixed asset posting.
        /// </summary>
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        /// <summary>
        /// Indicates whether depreciation is calculated until the FA posting date.
        /// </summary>
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
        }
        /// <summary>
        /// Specifies another depreciation book to duplicate the posting to.
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
        /// Specifies the responsibility center that processed this line.
        /// </summary>
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        /// <summary>
        /// Specifies the item category code for the item on the line.
        /// </summary>
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = if (Type = const(Item)) "Item Category";
        }
        /// <summary>
        /// Indicates whether the item is a catalog item not in regular inventory.
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
        /// Specifies the item reference number for cross-reference lookup.
        /// </summary>
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
            ToolTip = 'Specifies the referenced item number.';
        }
        /// <summary>
        /// Specifies the unit of measure from the item reference.
        /// </summary>
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure (Item Ref.)';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        /// <summary>
        /// Specifies the type of item reference used.
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
        /// Specifies the item ledger entry this credit was applied from.
        /// </summary>
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied from.';
        }
        /// <summary>
        /// Specifies the return receipt document number this line was created from.
        /// </summary>
        field(6600; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the return receipt line number this line was created from.
        /// </summary>
        field(6601; "Return Receipt Line No."; Integer)
        {
            Caption = 'Return Receipt Line No.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the reason code for the return.
        /// </summary>
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            ToolTip = 'Specifies the code explaining why the item was returned.';
            TableRelation = "Return Reason";
        }
        /// <summary>
        /// Specifies the method used to calculate prices on the line.
        /// </summary>
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        /// <summary>
        /// Indicates whether line discounts are allowed on this line.
        /// </summary>
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
        }
        /// <summary>
        /// Specifies the customer discount group for line discount calculations.
        /// </summary>
        field(7002; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        /// <summary>
        /// Specifies the name of the sell-to customer from the customer record.
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
            MaintainSIFTIndex = false;
        }
        key(Key2; "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key3; "Sell-to Customer No.")
        {
        }
        key(Key4; "Return Receipt No.", "Return Receipt Line No.")
        {
        }
        key(Key5; "Job Contract Entry No.")
        {
        }
        key(Key6; "Bill-to Customer No.")
        {
        }
        key(Key7; "Order No.", "Order Line No.", "Posting Date")
        {
        }
        key(Key8; "Document No.", "Location Code")
        {
            MaintainSQLIndex = false;
            SumIndexFields = Amount, "Amount Including VAT", "Inv. Discount Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        SalesDocLineComments: Record "Sales Comment Line";
        PostedDeferralHeader: Record "Posted Deferral Header";
    begin
        SalesDocLineComments.SetRange("Document Type", SalesDocLineComments."Document Type"::"Posted Credit Memo");
        SalesDocLineComments.SetRange("No.", "Document No.");
        SalesDocLineComments.SetRange("Document Line No.", "Line No.");
        if not SalesDocLineComments.IsEmpty() then
            SalesDocLineComments.DeleteAll();

        PostedDeferralHeader.DeleteHeader(
            "Deferral Document Type"::Sales.AsInteger(), '', '',
            SalesDocLineComments."Document Type"::"Posted Credit Memo".AsInteger(), "Document No.", "Line No.");
    end;

    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Currency: Record Currency;
        DimMgt: Codeunit DimensionManagement;
        DeferralUtilities: Codeunit "Deferral Utilities";

    /// <summary>
    /// Retrieves the currency code from the sales credit memo header.
    /// </summary>
    /// <returns>The currency code for this credit memo line.</returns>
    procedure GetCurrencyCode(): Code[10]
    begin
        GetHeader();
        exit(SalesCrMemoHeader."Currency Code");
    end;

    /// <summary>
    /// Opens a page displaying the dimensions associated with this credit memo line.
    /// </summary>
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    /// <summary>
    /// Opens a page displaying the item tracking lines for this credit memo line.
    /// </summary>
    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine(RowID1());
    end;

    /// <summary>
    /// Calculates VAT amount lines for all lines in the credit memo.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The sales credit memo header to calculate VAT for.</param>
    /// <param name="TempVATAmountLine">Returns the calculated VAT amount lines.</param>
    procedure CalcVATAmountLines(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcVATAmountLines(Rec, SalesCrMemoHeader, TempVATAmountLine, IsHandled);
        if IsHandled then
            exit;

        TempVATAmountLine.DeleteAll();
        SetRange("Document No.", SalesCrMemoHeader."No.");
        if Find('-') then
            repeat
                TempVATAmountLine.Init();
                TempVATAmountLine.CopyFromSalesCrMemoLine(Rec);
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
        if not SalesCrMemoHeader."Prices Including VAT" then
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
        if SalesCrMemoHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" * (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// Retrieves the sales credit memo header for this line.
    /// </summary>
    /// <returns>The sales credit memo header record.</returns>
    procedure GetCreditMemoHeader(): Record "Sales Cr.Memo Header"
    begin
        GetHeader();
        exit(SalesCrMemoHeader);
    end;

    local procedure GetHeader()
    begin
        if SalesCrMemoHeader."No." = "Document No." then
            exit;
        if not SalesCrMemoHeader.Get("Document No.") then
            SalesCrMemoHeader.Init();

        if SalesCrMemoHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            if not Currency.Get(SalesCrMemoHeader."Currency Code") then
                Currency.InitRoundingPrecision();
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Sales Cr.Memo Line", FieldNumber);
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
                if SalesCrMemoHeader."Prices Including VAT" then
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
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Sales Cr.Memo Line",
            0, "Document No.", '', 0, "Line No."));
    end;

    /// <summary>
    /// Retrieves the return receipt lines associated with this credit memo line.
    /// </summary>
    /// <param name="TempReturnReceiptLine">Returns the temporary return receipt lines.</param>
    procedure GetReturnRcptLines(var TempReturnReceiptLine: Record "Return Receipt Line" temporary)
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
    begin
        TempReturnReceiptLine.Reset();
        TempReturnReceiptLine.DeleteAll();

        if Type <> Type::Item then
            exit;

        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_No, "Document No.");
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Type, Enum::"Item Ledger Document Type"::"Sales Credit Memo");
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Line_No, "Line No.");
        ValueItemLedgerEntries.SetFilter(Value_Entry_Invoiced_Qty, '<>0');
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Type, Enum::"Item Ledger Document Type"::"Sales Return Receipt");
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do
            if ReturnReceiptLine.Get(ValueItemLedgerEntries.Item_Ledg_Document_No, ValueItemLedgerEntries.Item_Ledg_Document_Line_No) then begin
                TempReturnReceiptLine.Init();
                TempReturnReceiptLine := ReturnReceiptLine;
                if TempReturnReceiptLine.Insert() then;
            end;
    end;

    /// <summary>
    /// Retrieves item ledger entries associated with this credit memo line.
    /// </summary>
    /// <param name="TempItemLedgEntry">Returns the temporary item ledger entries.</param>
    /// <param name="SetQuantity">Indicates whether to set quantities from value entries.</param>
    procedure GetItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SetQuantity: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
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

    internal procedure GetSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesCreditMemoHeader: Record "Sales Cr.Memo Header";
        ValueEntry: Record "Value Entry";
    begin
        CheckApplFromItemLedgEntry(ItemLedgerEntry);

        if ItemLedgerEntry."Entry No." = 0 then
            FindItemLedgerEntryFromItemApplicationEntry(ItemLedgerEntry);

        ValueEntry.SetLoadFields("Item Ledger Entry No.", "Item Ledger Entry Type", "Document Type", "Document No.", "Document Line No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntry."Entry Type");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        if ValueEntry.FindFirst() then begin
            SalesInvoiceLine.Get(ValueEntry."Document No.", ValueEntry."Document Line No.");
            exit;
        end;

        if ItemLedgerEntry."Entry No." = 0 then begin
            SalesCreditMemoHeader.Get("Document No.");
            if SalesCreditMemoHeader."Applies-to Doc. Type" <> SalesCrMemoHeader."Applies-to Doc. Type"::Invoice then
                exit;

            SalesInvoiceLine.Reset();
            SalesInvoiceLine.SetRange("Document No.", SalesCreditMemoHeader."Applies-to Doc. No.");
            SalesInvoiceLine.SetRange(Type, Type);
            SalesInvoiceLine.SetRange("No.", "No.");
            if SalesInvoiceLine.FindFirst() then;
        end;
    end;

    local procedure CheckApplFromItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        if "Appl.-from Item Entry" = 0 then
            exit;

        TestField(Type, Type::Item);
        TestField(Quantity);
        ItemLedgerEntry.Get("Appl.-from Item Entry");
        ItemLedgerEntry.TestField(Positive, false);
        ItemLedgerEntry.TestField("Item No.", "No.");
        ItemLedgerEntry.TestField("Variant Code", "Variant Code");
        ItemLedgerEntry.CheckTrackingDoesNotExist(RecordId, FieldCaption("Appl.-from Item Entry"));
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
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Credit Memo");
        ValueEntry.SetRange("Document Line No.", "Line No.");
    end;

    /// <summary>
    /// Opens a page displaying the return receipt lines for this credit memo line.
    /// </summary>
    procedure ShowItemReturnRcptLines()
    var
        TempReturnRcptLine: Record "Return Receipt Line" temporary;
    begin
        if Type = Type::Item then begin
            GetReturnRcptLines(TempReturnRcptLine);
            PAGE.RunModal(0, TempReturnRcptLine);
        end;
    end;

    /// <summary>
    /// Opens a page displaying the comments for this credit memo line.
    /// </summary>
    procedure ShowLineComments()
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.ShowComments(SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger(), "Document No.", "Line No.");
    end;

    /// <summary>
    /// Retrieves the shortcut dimension codes for this credit memo line.
    /// </summary>
    /// <param name="ShortcutDimCode">Returns the array of shortcut dimension codes.</param>
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    /// <summary>
    /// Initializes the credit memo line from a sales line during posting.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The sales credit memo header.</param>
    /// <param name="SalesLine">The source sales line to initialize from.</param>
    procedure InitFromSalesLine(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesLine: Record "Sales Line")
    begin
        Init();
        TransferFields(SalesLine);
        if ("No." = '') and HasTypeToFillMandatoryFields() then
            Type := Type::" ";
        "Posting Date" := SalesCrMemoHeader."Posting Date";
        "Document No." := SalesCrMemoHeader."No.";
        Quantity := SalesLine."Qty. to Invoice";
        "Quantity (Base)" := SalesLine."Qty. to Invoice (Base)";

        OnAfterInitFromSalesLine(Rec, SalesCrMemoHeader, SalesLine);
    end;

    /// <summary>
    /// Opens a page displaying the deferral schedule for this credit memo line.
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
    /// Retrieves the document type integer for this posted credit memo line.
    /// </summary>
    /// <returns>The document type value as an integer.</returns>
    procedure GetDocumentType(): Integer
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        exit(SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger())
    end;

    /// <summary>
    /// Determines whether the line has a type that requires mandatory fields to be filled.
    /// </summary>
    /// <returns>True if the line type requires mandatory fields, otherwise false.</returns>
    procedure HasTypeToFillMandatoryFields(): Boolean
    begin
        exit(Type <> Type::" ");
    end;

    /// <summary>
    /// Formats the line type for display, handling blank types specially.
    /// </summary>
    /// <returns>The formatted type text.</returns>
    procedure FormatType(): Text
    var
        SalesLine: Record "Sales Line";
    begin
        if Type = Type::" " then
            exit(SalesLine.FormatType());

        exit(Format(Type));
    end;

    /// <summary>
    /// Applies security filters based on the user's responsibility center setup.
    /// </summary>
    procedure SetSecurityFilterOnRespCenter()
    var
        UserSetupMgt: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupMgt.GetSalesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetSalesFilter());
            FilterGroup(0);
        end;
    end;

    local procedure FindItemLedgerEntryFromItemApplicationEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemApplicationEntry: Record "Item Application Entry";
        TempItemLedEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingDocMgmt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgmt.RetrieveEntriesFromPostedInvoice(TempItemLedEntry, RowID1());
        if TempItemLedEntry.IsEmpty then
            exit;

        TempItemLedEntry.FindFirst();
        if ItemApplicationEntry.AppliedFromEntryExists(TempItemLedEntry."Entry No.") then
            ItemLedgerEntry.Get(ItemApplicationEntry."Outbound Item Entry No.");
    end;

    internal procedure GetVATPct() VATPct: Decimal
    begin
        VATPct := "VAT %";
        OnAfterGetVATPct(Rec, VATPct);
    end;

    /// <summary>
    /// Raised after initializing a sales credit memo line from a sales line.
    /// </summary>
    /// <param name="SalesCrMemoLine">The sales credit memo line being initialized.</param>
    /// <param name="SalesCrMemoHeader">The sales credit memo header.</param>
    /// <param name="SalesLine">The source sales line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised before calculating VAT amount lines for the sales credit memo.
    /// </summary>
    /// <param name="SalesCrMemoLine">The sales credit memo line being processed.</param>
    /// <param name="SalesCrMemoHeader">The sales credit memo header.</param>
    /// <param name="TempVATAmountLine">Temporary VAT amount lines to be calculated.</param>
    /// <param name="IsHandled">Set to true to skip default VAT calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcVATAmountLines(SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before showing the deferral schedule for the sales credit memo line.
    /// </summary>
    /// <param name="SalesCrMemoLine">The sales credit memo line.</param>
    /// <param name="IsHandled">Set to true to skip default deferral display.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeferrals(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a temporary item ledger entry when retrieving item ledger entries.
    /// </summary>
    /// <param name="TempItemLedgerEntry">The temporary item ledger entry to be inserted.</param>
    /// <param name="ValueEntry">The source value entry.</param>
    /// <param name="SetQuantity">Indicates whether quantity should be set from the value entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetItemLedgEntriesOnBeforeTempItemLedgEntryInsert(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; ValueEntry: Record "Value Entry"; SetQuantity: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before setting security filter on responsibility center for sales credit memo lines.
    /// </summary>
    /// <param name="SalesCrMemoLine">The sales credit memo line to apply filters to.</param>
    /// <param name="IsHandled">Set to true to skip default security filter application.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after retrieving the VAT percentage for the sales credit memo line.
    /// </summary>
    /// <param name="SalesCrMemoLine">The sales credit memo line.</param>
    /// <param name="VATPct">The VAT percentage value.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPct(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var VATPct: Decimal)
    begin
    end;
}
