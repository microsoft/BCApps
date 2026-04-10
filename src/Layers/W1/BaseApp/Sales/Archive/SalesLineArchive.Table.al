// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Archive;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Reflection;

/// <summary>
/// Stores archived versions of sales document lines for historical reference and audit trails.
/// </summary>
table 5108 "Sales Line Archive"
{
    Caption = 'Sales Line Archive';
    PasteIsValid = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the type of the archived sales document, such as quote, order, invoice, or credit memo.
        /// </summary>
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of sales document.';
        }
        /// <summary>
        /// Specifies the customer who will receive the products and be billed by default for this line.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;
            ToolTip = 'Specifies the number of the customer who will receive the products and be billed by default.';
        }
        /// <summary>
        /// Specifies the number of the archived sales document that this line belongs to.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Sales Header Archive"."No." where("Document Type" = field("Document Type"),
                                                                "Version No." = field("Version No."));
            ToolTip = 'Specifies the document number.';
        }
        /// <summary>
        /// Specifies the sequential line number within the document that uniquely identifies this line.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the number of the line.';
        }
        /// <summary>
        /// Specifies the type of entity on this line, such as item, resource, or G/L account.
        /// </summary>
        field(5; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of entity that will be posted for this sales line, such as Item, Resource, or G/L Account.';
        }
        /// <summary>
        /// Specifies the number of the item, resource, or G/L account on the line.
        /// </summary>
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge";
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        /// <summary>
        /// Specifies the warehouse location from which the items on this line are shipped.
        /// </summary>
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
            ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
        }
        /// <summary>
        /// Specifies the posting group used to determine G/L accounts for posting inventory or fixed asset transactions.
        /// </summary>
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = if (Type = const(Item)) "Inventory Posting Group"
            else
            if (Type = const("Fixed Asset")) "FA Posting Group";
        }
        /// <summary>
        /// Specifies the code used for calculating quantity-based discounts.
        /// </summary>
        field(9; "Quantity Disc. Code"; Code[20])
        {
            Caption = 'Quantity Disc. Code';
        }
        /// <summary>
        /// Specifies the date when items on this line are scheduled to ship.
        /// </summary>
        field(10; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        /// <summary>
        /// Specifies a description of the item, resource, or G/L account on the line.
        /// </summary>
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the record.';
        }
        /// <summary>
        /// Specifies additional description text when the primary description field is not sufficient.
        /// </summary>
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies information in addition to the description.';
        }
        /// <summary>
        /// Specifies the name of the unit of measure for the item or resource.
        /// </summary>
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
            ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
        }
        /// <summary>
        /// Specifies the number of units being sold on this line.
        /// </summary>
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies how many units are being sold.';
        }
        /// <summary>
        /// Specifies the quantity that has not yet been shipped or received.
        /// </summary>
        field(16; "Outstanding Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Outstanding Quantity';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the quantity that remains to be invoiced for this line.
        /// </summary>
        field(17; "Qty. to Invoice"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity that remains to be invoiced. It is calculated as Quantity - Qty. Invoiced.';
        }
        /// <summary>
        /// Specifies the quantity scheduled to be shipped in the next posting.
        /// </summary>
        field(18; "Qty. to Ship"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity of items that remain to be shipped.';
        }
        /// <summary>
        /// Specifies the price of one unit of the item or resource on the line.
        /// </summary>
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FieldNo("Unit Price"));
            Caption = 'Unit Price';
            ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
        }
        /// <summary>
        /// Specifies the cost of one unit in the local currency.
        /// </summary>
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost (LCY)';
            ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
        }
        /// <summary>
        /// Specifies the VAT percentage used to calculate VAT amounts on this line.
        /// </summary>
        field(25; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the quantity-based discount percentage applied to this line.
        /// </summary>
        field(26; "Quantity Disc. %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity Disc. %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the line discount percentage granted for this line item.
        /// </summary>
        field(27; "Line Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
            ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
        }
        /// <summary>
        /// Specifies the discount amount subtracted from the line amount.
        /// </summary>
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
            ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
        }
        /// <summary>
        /// Specifies the total amount for the line excluding VAT.
        /// </summary>
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the sum of amounts in the Line Amount field on the sales lines.';
        }
        /// <summary>
        /// Specifies the total amount for the line including VAT.
        /// </summary>
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            ToolTip = 'Specifies the net amount, including VAT, for this line.';
        }
        /// <summary>
        /// Indicates whether this line is included in invoice discount calculations.
        /// </summary>
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;
            ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
        }
        /// <summary>
        /// Specifies the gross weight of one unit of the item for shipping calculations.
        /// </summary>
        field(34; "Gross Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the gross weight of one unit of the item. In the sales statistics window, the gross weight on the line is included in the total gross weight of all the lines for the particular sales document.';
        }
        /// <summary>
        /// Specifies the net weight of one unit of the item for shipping calculations.
        /// </summary>
        field(35; "Net Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the net weight of one unit of the item. In the sales statistics window, the net weight on the line is included in the total net weight of all the lines for the particular sales document.';
        }
        /// <summary>
        /// Specifies the number of units that fit in one parcel for shipping calculations.
        /// </summary>
        field(36; "Units per Parcel"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the number of units per parcel of the item. In the sales statistics window, the number of units per parcel on the line helps to determine the total number of units for all the lines for the particular sales document.';
        }
        /// <summary>
        /// Specifies the volume of one unit of the item for shipping calculations.
        /// </summary>
        field(37; "Unit Volume"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the volume of one unit of the item. In the sales statistics window, the volume of one unit of the item on the line is included in the total volume of all the lines for the particular sales document.';
        }
        /// <summary>
        /// Specifies the item ledger entry number to which this line is applied.
        /// </summary>
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';
            ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
        }
        /// <summary>
        /// Specifies the first global dimension code for analyzing this line.
        /// </summary>
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
        }
        /// <summary>
        /// Specifies the second global dimension code for analyzing this line.
        /// </summary>
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
        }
        /// <summary>
        /// Specifies the customer price group used to determine special prices for this line.
        /// </summary>
        field(42; "Price Group Code"; Code[10])
        {
            Caption = 'Price Group Code';
            TableRelation = "Customer Price Group";
        }
        /// <summary>
        /// Indicates whether quantity-based discounts are allowed for this line.
        /// </summary>
        field(43; "Allow Quantity Disc."; Boolean)
        {
            Caption = 'Allow Quantity Disc.';
            InitValue = true;
        }
        /// <summary>
        /// Specifies the project number that this sales line is linked to.
        /// </summary>
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
            ToolTip = 'Specifies the number of the related project.';
        }
        /// <summary>
        /// Specifies the work type code for resource lines to determine pricing and posting.
        /// </summary>
        field(52; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";
        }
        /// <summary>
        /// Specifies the customer and item specific discount percentage.
        /// </summary>
        field(55; "Cust./Item Disc. %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Cust./Item Disc. %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the monetary value of items that have not yet been shipped or invoiced.
        /// </summary>
        field(57; "Outstanding Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Outstanding Amount';
            Editable = false;
        }
        /// <summary>
        /// Specifies the quantity that has been shipped but not yet invoiced.
        /// </summary>
        field(58; "Qty. Shipped Not Invoiced"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Shipped Not Invoiced';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the monetary value of shipped items that have not yet been invoiced.
        /// </summary>
        field(59; "Shipped Not Invoiced"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced';
        }
        /// <summary>
        /// Specifies the total quantity that has been shipped for this line.
        /// </summary>
        field(60; "Quantity Shipped"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Quantity Shipped';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies how many units of the item on the line have been posted as shipped.';
        }
        /// <summary>
        /// Specifies the total quantity that has been invoiced for this line.
        /// </summary>
        field(61; "Quantity Invoiced"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
        }
        /// <summary>
        /// Specifies the number of the posted shipment document that this line was copied from.
        /// </summary>
        field(63; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';
        }
        /// <summary>
        /// Specifies the line number in the posted shipment document that this line was copied from.
        /// </summary>
        field(64; "Shipment Line No."; Integer)
        {
            Caption = 'Shipment Line No.';
        }
        /// <summary>
        /// Specifies the profit percentage for this line based on unit price and unit cost.
        /// </summary>
        field(67; "Profit %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Profit %';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the customer who receives the invoice for this line.
        /// </summary>
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the invoice discount amount calculated for this line.
        /// </summary>
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
        }
        /// <summary>
        /// Specifies the purchase order number for drop shipment items shipped directly from the vendor.
        /// </summary>
        field(71; "Purchase Order No."; Code[20])
        {
            Caption = 'Purchase Order No.';
            TableRelation = if ("Drop Shipment" = const(true)) "Purchase Header"."No." where("Document Type" = const(Order));
        }
        /// <summary>
        /// Specifies the purchase order line number for drop shipment items.
        /// </summary>
        field(72; "Purch. Order Line No."; Integer)
        {
            Caption = 'Purch. Order Line No.';
            TableRelation = if ("Drop Shipment" = const(true)) "Purchase Line"."Line No." where("Document Type" = const(Order),
                                                                                               "Document No." = field("Purchase Order No."));
        }
        /// <summary>
        /// Indicates whether the vendor ships items directly to the customer without passing through inventory.
        /// </summary>
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            ToolTip = 'Specifies if your vendor ships the items directly to your customer.';
        }
        /// <summary>
        /// Specifies the general business posting group for linking to G/L accounts based on business type.
        /// </summary>
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
        }
        /// <summary>
        /// Specifies the general product posting group for linking to G/L accounts based on product type.
        /// </summary>
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
        }
        /// <summary>
        /// Specifies how VAT is calculated for this line, such as normal VAT or reverse charge.
        /// </summary>
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
        }
        /// <summary>
        /// Specifies the Intrastat transaction type for EU trade reporting purposes.
        /// </summary>
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        /// <summary>
        /// Specifies the Intrastat transport method for EU trade reporting purposes.
        /// </summary>
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        /// <summary>
        /// Specifies the line number that this extended text or comment line is attached to.
        /// </summary>
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            TableRelation = "Sales Line Archive"."Line No." where("Document Type" = field("Document Type"),
                                                                   "Document No." = field("Document No."),
                                                                   "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                   "Version No." = field("Version No."));
        }
        /// <summary>
        /// Specifies the exit point for Intrastat reporting when goods leave the country.
        /// </summary>
        field(81; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        /// <summary>
        /// Specifies the destination area code for Intrastat reporting purposes.
        /// </summary>
        field(82; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        /// <summary>
        /// Specifies additional transaction details for Intrastat reporting purposes.
        /// </summary>
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        /// <summary>
        /// Specifies the tax area used to calculate and post sales tax for this line.
        /// </summary>
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
            ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
        }
        /// <summary>
        /// Indicates whether this transaction is subject to sales tax.
        /// </summary>
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
        }
        /// <summary>
        /// Specifies the tax group used to determine the sales tax rate for this line.
        /// </summary>
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
            ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
        }
        /// <summary>
        /// Specifies the VAT clause that explains the VAT treatment on printed documents.
        /// </summary>
        field(88; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        /// <summary>
        /// Specifies the VAT business posting group for linking to G/L accounts based on customer VAT status.
        /// </summary>
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
        }
        /// <summary>
        /// Specifies the VAT product posting group for linking to G/L accounts based on item VAT category.
        /// </summary>
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
        }
        /// <summary>
        /// Specifies the currency code for amounts on this line.
        /// </summary>
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        /// <summary>
        /// Specifies the outstanding amount in local currency for items not yet shipped or invoiced.
        /// </summary>
        field(92; "Outstanding Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Outstanding Amount (LCY)';
        }
        /// <summary>
        /// Specifies the amount in local currency for items shipped but not yet invoiced.
        /// </summary>
        field(93; "Shipped Not Invoiced (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Shipped Not Invoiced (LCY)';
        }
        /// <summary>
        /// Specifies whether and how items are reserved for this line.
        /// </summary>
        field(96; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Reserve';
            ToolTip = 'Specifies whether items will never, automatically (Always), or optionally be reserved for this customer. Optional means that you must manually reserve items for this customer.';
        }
        /// <summary>
        /// Specifies the blanket order number that this line originates from.
        /// </summary>
        field(97; "Blanket Order No."; Code[20])
        {
            Caption = 'Blanket Order No.';
            TableRelation = "Sales Header"."No." where("Document Type" = const("Blanket Order"));
            ToolTip = 'Specifies the number of the blanket order that the record originates from.';
        }
        /// <summary>
        /// Specifies the blanket order line number that this line originates from.
        /// </summary>
        field(98; "Blanket Order Line No."; Integer)
        {
            Caption = 'Blanket Order Line No.';
            TableRelation = "Sales Line"."Line No." where("Document Type" = const("Blanket Order"),
                                                           "Document No." = field("Blanket Order No."));
            ToolTip = 'Specifies the number of the blanket order line that the record originates from.';
        }
        /// <summary>
        /// Specifies the base amount used to calculate VAT for this line.
        /// </summary>
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
        }
        /// <summary>
        /// Specifies the cost of one unit in the document currency.
        /// </summary>
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
        }
        /// <summary>
        /// Indicates whether this line was created automatically by the system.
        /// </summary>
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
        }
        /// <summary>
        /// Specifies the net amount for products on this line excluding invoice discounts.
        /// </summary>
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Line Amount"));
            Caption = 'Line Amount';
            ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
        }
        /// <summary>
        /// Specifies the difference between calculated and manually entered VAT amounts.
        /// </summary>
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
        }
        /// <summary>
        /// Specifies the invoice discount amount that will be included when the line is invoiced.
        /// </summary>
        field(105; "Inv. Disc. Amount to Invoice"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Disc. Amount to Invoice';
        }
        /// <summary>
        /// Specifies the unique identifier for the VAT setup used on this line.
        /// </summary>
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
        }
        /// <summary>
        /// Specifies the type of reference used for intercompany transactions.
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
        }
        /// <summary>
        /// Specifies the item or account reference used by the intercompany partner.
        /// </summary>
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
        }
        /// <summary>
        /// Specifies the prepayment percentage required for this line.
        /// </summary>
        field(109; "Prepayment %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the prepayment amount for this line excluding VAT.
        /// </summary>
        field(110; "Prepmt. Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt. Line Amount"));
            Caption = 'Prepmt. Line Amount';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the prepayment amount that has been invoiced for this line.
        /// </summary>
        field(111; "Prepmt. Amt. Inv."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt. Amt. Inv."));
            Caption = 'Prepmt. Amt. Inv.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the invoiced prepayment amount including VAT.
        /// </summary>
        field(112; "Prepmt. Amt. Incl. VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amt. Incl. VAT';
            Editable = false;
        }
        /// <summary>
        /// Specifies the total prepayment amount for this line.
        /// </summary>
        field(113; "Prepayment Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepayment Amount';
            Editable = false;
        }
        /// <summary>
        /// Specifies the base amount used for calculating prepayment VAT.
        /// </summary>
        field(114; "Prepmt. VAT Base Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. VAT Base Amt.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the VAT percentage applied to prepayments for this line.
        /// </summary>
        field(115; "Prepayment VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepayment VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies how VAT is calculated for prepayments on this line.
        /// </summary>
        field(116; "Prepmt. VAT Calc. Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Prepmt. VAT Calc. Type';
            Editable = false;
        }
        /// <summary>
        /// Specifies the unique identifier for the VAT setup used for prepayments.
        /// </summary>
        field(117; "Prepayment VAT Identifier"; Code[20])
        {
            Caption = 'Prepayment VAT Identifier';
            Editable = false;
        }
        /// <summary>
        /// Specifies the tax area used for calculating prepayment sales tax.
        /// </summary>
        field(118; "Prepayment Tax Area Code"; Code[20])
        {
            Caption = 'Prepayment Tax Area Code';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether prepayments are subject to sales tax.
        /// </summary>
        field(119; "Prepayment Tax Liable"; Boolean)
        {
            Caption = 'Prepayment Tax Liable';
        }
        /// <summary>
        /// Specifies the tax group used for calculating prepayment sales tax rates.
        /// </summary>
        field(120; "Prepayment Tax Group Code"; Code[20])
        {
            Caption = 'Prepayment Tax Group Code';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Specifies the prepayment amount to be deducted when posting the final invoice.
        /// </summary>
        field(121; "Prepmt Amt to Deduct"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt Amt to Deduct"));
            Caption = 'Prepmt Amt to Deduct';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the prepayment amount that has already been deducted.
        /// </summary>
        field(122; "Prepmt Amt Deducted"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt Amt Deducted"));
            Caption = 'Prepmt Amt Deducted';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether this line represents a prepayment.
        /// </summary>
        field(123; "Prepayment Line"; Boolean)
        {
            Caption = 'Prepayment Line';
            Editable = false;
        }
        /// <summary>
        /// Specifies the invoiced prepayment amount including VAT.
        /// </summary>
        field(124; "Prepmt. Amount Inv. Incl. VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amount Inv. Incl. VAT';
            Editable = false;
        }
        /// <summary>
        /// Specifies the intercompany partner code for cross-company transactions.
        /// </summary>
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Specifies the item reference number used by the intercompany partner.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
        }
        /// <summary>
        /// Specifies the payment discount amount applicable to this line.
        /// </summary>
        field(145; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Amount';
        }
        /// <summary>
        /// Specifies the unique identifier for the set of dimension values on this line.
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
        /// Specifies the project task number that this line is linked to.
        /// </summary>
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            Editable = false;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            ToolTip = 'Specifies the number of the related project task.';
        }
        /// <summary>
        /// Specifies the entry number of the project planning line linked to this sales line.
        /// </summary>
        field(1002; "Job Contract Entry No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Contract Entry No.';
            ToolTip = 'Specifies the entry number of the project planning line that the sales line is linked to.';
        }
        /// <summary>
        /// Specifies the deferral template used for spreading revenue recognition over multiple periods.
        /// </summary>
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            TableRelation = "Deferral Template"."Deferral Code";
            ToolTip = 'Specifies the deferral template that governs how revenue earned with this sales document is deferred to the different accounting periods when the good or service was delivered.';
        }
        /// <summary>
        /// Specifies the starting date for return deferral period calculations.
        /// </summary>
        field(1702; "Returns Deferral Start Date"; Date)
        {
            Caption = 'Returns Deferral Start Date';
            ToolTip = 'Specifies the starting date of the returns deferral period.';
        }
        /// <summary>
        /// Specifies the version number of this archived line.
        /// </summary>
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        /// <summary>
        /// Specifies how many times the same document number has been archived.
        /// </summary>
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        /// <summary>
        /// Specifies the item variant code for tracking specific item configurations.
        /// </summary>
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
            ToolTip = 'Specifies the variant of the item on the line.';
        }
        /// <summary>
        /// Specifies the bin code where items are stored at the location.
        /// </summary>
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        /// <summary>
        /// Specifies the conversion factor between the unit of measure and the base unit.
        /// </summary>
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        /// <summary>
        /// Indicates whether this line has been included in planning calculations.
        /// </summary>
        field(5405; Planned; Boolean)
        {
            Caption = 'Planned';
        }
        /// <summary>
        /// Specifies the unit of measure code for this line.
        /// </summary>
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
        }
        /// <summary>
        /// Specifies the quantity expressed in the base unit of measure.
        /// </summary>
        field(5415; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the outstanding quantity expressed in the base unit of measure.
        /// </summary>
        field(5416; "Outstanding Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the quantity to invoice expressed in the base unit of measure.
        /// </summary>
        field(5417; "Qty. to Invoice (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the quantity to ship expressed in the base unit of measure.
        /// </summary>
        field(5418; "Qty. to Ship (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the shipped but not invoiced quantity in the base unit of measure.
        /// </summary>
        field(5458; "Qty. Shipped Not Invd. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Shipped Not Invd. (Base)';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the total shipped quantity expressed in the base unit of measure.
        /// </summary>
        field(5460; "Qty. Shipped (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the total invoiced quantity expressed in the base unit of measure.
        /// </summary>
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the posting date for fixed asset transactions on this line.
        /// </summary>
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
            ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';
        }
        /// <summary>
        /// Specifies the depreciation book used for fixed asset posting.
        /// </summary>
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
            ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
        }
        /// <summary>
        /// Indicates whether depreciation was calculated up to the fixed asset posting date.
        /// </summary>
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
            ToolTip = 'Specifies if depreciation was calculated until the FA posting date of the line.';
        }
        /// <summary>
        /// Specifies an additional depreciation book for duplicate posting.
        /// </summary>
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";
            ToolTip = 'Specifies a depreciation book code if you want the journal line to be posted to that depreciation book, as well as to the depreciation book in the Depreciation Book Code field.';
        }
        /// <summary>
        /// Indicates whether posting should duplicate to all depreciation books in the duplication list.
        /// </summary>
        field(5613; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
            ToolTip = 'Specifies, if the type is Fixed Asset, that information on the line is to be posted to all the assets defined depreciation books. ';
        }
        /// <summary>
        /// Specifies the responsibility center that manages this line.
        /// </summary>
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        /// <summary>
        /// Indicates whether this item was substituted due to stock unavailability.
        /// </summary>
        field(5701; "Out-of-Stock Substitution"; Boolean)
        {
            Caption = 'Out-of-Stock Substitution';
        }
        /// <summary>
        /// Indicates whether a substitute item is available for the item on this line.
        /// </summary>
        field(5702; "Substitution Available"; Boolean)
        {
            CalcFormula = exist("Item Substitution" where(Type = const(Item),
                                                           "No." = field("No."),
                                                           "Substitute Type" = const(Item)));
            Caption = 'Substitution Available';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies whether a substitute is available for the item.';
        }
        /// <summary>
        /// Specifies the item number that was originally ordered before substitution.
        /// </summary>
        field(5703; "Originally Ordered No."; Code[20])
        {
            Caption = 'Originally Ordered No.';
            TableRelation = if (Type = const(Item)) Item;
        }
        /// <summary>
        /// Specifies the variant code of the originally ordered item before substitution.
        /// </summary>
        field(5704; "Originally Ordered Var. Code"; Code[10])
        {
            Caption = 'Originally Ordered Var. Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("Originally Ordered No."));
        }
        /// <summary>
        /// Specifies the item category for classification and reporting purposes.
        /// </summary>
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        /// <summary>
        /// Indicates whether this is a catalog item not normally kept in inventory.
        /// </summary>
        field(5710; Nonstock; Boolean)
        {
            Caption = 'Catalog';
            ToolTip = 'Specifies that the item on the sales line is a catalog item, which means it is not normally kept in inventory.';
        }
        /// <summary>
        /// Specifies the purchasing code that determines special procurement methods.
        /// </summary>
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
            ToolTip = 'Specifies the code for a special procurement method, such as drop shipment.';
        }
        /// <summary>
        /// Indicates whether this is a special order item purchased specifically for this sale.
        /// </summary>
        field(5713; "Special Order"; Boolean)
        {
            Caption = 'Special Order';
            ToolTip = 'Specifies that the item on the sales line is a special-order item.';
        }
        /// <summary>
        /// Specifies the purchase order number for special order items.
        /// </summary>
        field(5714; "Special Order Purchase No."; Code[20])
        {
            Caption = 'Special Order Purchase No.';
            TableRelation = if ("Special Order" = const(true)) "Purchase Header"."No." where("Document Type" = const(Order));
        }
        /// <summary>
        /// Specifies the purchase order line number for special order items.
        /// </summary>
        field(5715; "Special Order Purch. Line No."; Integer)
        {
            Caption = 'Special Order Purch. Line No.';
            TableRelation = if ("Special Order" = const(true)) "Purchase Line"."Line No." where("Document Type" = const(Order),
                                                                                               "Document No." = field("Special Order Purchase No."));
        }
        /// <summary>
        /// Specifies the cross-reference or barcode number for the item.
        /// </summary>
        field(5725; "Item Reference No."; Code[50])
        {
            Caption = 'Item Reference No.';
            ToolTip = 'Specifies the referenced item number.';
        }
        /// <summary>
        /// Specifies the unit of measure associated with the item reference.
        /// </summary>
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            Caption = 'Reference Unit of Measure';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        /// <summary>
        /// Specifies the type of item reference, such as customer or vendor.
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
        /// Indicates whether all quantities on this line have been shipped.
        /// </summary>
        field(5752; "Completely Shipped"; Boolean)
        {
            Caption = 'Completely Shipped';
        }
        /// <summary>
        /// Specifies the date that the customer requested for delivery.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            ToolTip = 'Specifies the date that your customer has asked for the order to be delivered.';
        }
        /// <summary>
        /// Specifies the date that was promised to the customer for delivery.
        /// </summary>
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
            ToolTip = 'Specifies the date that you have promised to deliver the order, as a result of the Order Promising function.';
        }
        /// <summary>
        /// Specifies the time required to ship items from the warehouse to the customer.
        /// </summary>
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';
            ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
        }
        /// <summary>
        /// Specifies the time required for outbound warehouse handling before shipping.
        /// </summary>
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Outbound Whse. Handling Time';
            ToolTip = 'Specifies a date formula for the time it takes to get items ready to ship from this location. The time element is used in the calculation of the delivery date as follows: Shipment Date + Outbound Warehouse Handling Time = Planned Shipment Date + Shipping Time = Planned Delivery Date.';
        }
        /// <summary>
        /// Specifies the date when the shipment is planned to arrive at the customer.
        /// </summary>
        field(5794; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';
            ToolTip = 'Specifies the planned date that the shipment will be delivered at the customer''s address. If the customer requests a delivery date, the program calculates whether the items will be available for delivery on this date. If the items are available, the planned delivery date will be the same as the requested delivery date. If not, the program calculates the date that the items are available for delivery and enters this date in the Planned Delivery Date field.';
        }
        /// <summary>
        /// Specifies the date when the shipment is planned to leave the warehouse.
        /// </summary>
        field(5795; "Planned Shipment Date"; Date)
        {
            Caption = 'Planned Shipment Date';
            ToolTip = 'Specifies the date that the shipment should ship from the warehouse. If the customer requests a delivery date, the program calculates the planned shipment date by subtracting the shipping time from the requested delivery date. If the customer does not request a delivery date or the requested delivery date cannot be met, the program calculates the content of this field by adding the shipment time to the shipping date.';
        }
        /// <summary>
        /// Specifies the shipping agent responsible for transporting the items.
        /// </summary>
        field(5796; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
            ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
        }
        /// <summary>
        /// Specifies the shipping agent service level for delivery.
        /// </summary>
        field(5797; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
            ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
        }
        /// <summary>
        /// Indicates whether item charges can be assigned to this line.
        /// </summary>
        field(5800; "Allow Item Charge Assignment"; Boolean)
        {
            AccessByPermission = TableData "Item Charge" = R;
            Caption = 'Allow Item Charge Assignment';
            InitValue = true;
            ToolTip = 'Specifies that you can assign item charges to this line.';
        }
        /// <summary>
        /// Specifies the quantity of returned items to receive from the customer.
        /// </summary>
        field(5803; "Return Qty. to Receive"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Return Qty. to Receive';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the return quantity to receive in the base unit of measure.
        /// </summary>
        field(5804; "Return Qty. to Receive (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Return Qty. to Receive (Base)';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the returned quantity received but not yet invoiced.
        /// </summary>
        field(5805; "Return Qty. Rcd. Not Invd."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Return Qty. Rcd. Not Invd.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the returned quantity received but not invoiced in the base unit.
        /// </summary>
        field(5806; "Ret. Qty. Rcd. Not Invd.(Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Ret. Qty. Rcd. Not Invd.(Base)';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the return amount received but not yet invoiced.
        /// </summary>
        field(5807; "Return Amt. Rcd. Not Invd."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Return Amt. Rcd. Not Invd.';
        }
        /// <summary>
        /// Specifies the return amount received but not invoiced in local currency.
        /// </summary>
        field(5808; "Ret. Amt. Rcd. Not Invd. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Ret. Amt. Rcd. Not Invd. (LCY)';
        }
        /// <summary>
        /// Specifies the total quantity of returns received from the customer.
        /// </summary>
        field(5809; "Return Qty. Received"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Return Qty. Received';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the total returned quantity received in the base unit of measure.
        /// </summary>
        field(5810; "Return Qty. Received (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Return Qty. Received (Base)';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the item ledger entry that this return line is applied from.
        /// </summary>
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;
            ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied from.';
        }
        /// <summary>
        /// Specifies the parent item number when this line is a BOM component.
        /// </summary>
        field(5909; "BOM Item No."; Code[20])
        {
            Caption = 'BOM Item No.';
            TableRelation = Item;
        }
        /// <summary>
        /// Specifies the posted return receipt document number this line was copied from.
        /// </summary>
        field(6600; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
        }
        /// <summary>
        /// Specifies the line number in the posted return receipt this line was copied from.
        /// </summary>
        field(6601; "Return Receipt Line No."; Integer)
        {
            Caption = 'Return Receipt Line No.';
        }
        /// <summary>
        /// Specifies the code that explains why the item was returned.
        /// </summary>
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";
            ToolTip = 'Specifies the code explaining why the item was returned.';
        }
        /// <summary>
        /// Specifies the method used for calculating prices for this line.
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
        /// Specifies the customer discount group used to determine applicable discounts.
        /// </summary>
        field(7002; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.", "Line No.", "Doc. No. Occurrence", "Version No.")
        {
        }
        key(Key3; "Sell-to Customer No.")
        {
        }
        key(Key4; "Bill-to Customer No.")
        {
        }
        key(Key5; Type, "No.")
        {
        }
        key(Key6; "Document No.", "Document Type", "Doc. No. Occurrence", "Version No.")
        {
            IncludedFields = Amount, "Amount Including VAT", "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Document No.", "Line No.", "Version No.", "Sell-to Customer No.")
        {
        }
    }

    trigger OnDelete()
    var
        SalesCommentLineArchive: Record "Sales Comment Line Archive";
        DeferralHeaderArchive: Record "Deferral Header Archive";
    begin
        SalesCommentLineArchive.SetRange("Document Type", Rec."Document Type");
        SalesCommentLineArchive.SetRange("No.", Rec."Document No.");
        SalesCommentLineArchive.SetRange("Document Line No.", Rec."Line No.");
        SalesCommentLineArchive.SetRange("Doc. No. Occurrence", Rec."Doc. No. Occurrence");
        SalesCommentLineArchive.SetRange("Version No.", Rec."Version No.");
        if not SalesCommentLineArchive.IsEmpty() then
            SalesCommentLineArchive.DeleteAll();

        if Rec."Deferral Code" <> '' then
            DeferralHeaderArchive.DeleteHeader(
                "Deferral Document Type"::Sales.AsInteger(), Rec."Document Type".AsInteger(),
                Rec."Document No.", Rec."Doc. No. Occurrence", Rec."Version No.", Rec."Line No.");
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        DeferralUtilities: Codeunit "Deferral Utilities";

    /// <summary>
    /// Returns the caption class string for the specified field number based on whether prices include VAT.
    /// </summary>
    /// <param name="FieldNumber">Specifies the field number to get the caption class for.</param>
    /// <returns>The caption class string for the field.</returns>
    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        if not SalesHeaderArchive.Get("Document Type", "Document No.", "Doc. No. Occurrence", "Version No.") then begin
            SalesHeaderArchive."No." := '';
            SalesHeaderArchive.Init();
        end;
        if SalesHeaderArchive."Prices Including VAT" then
            exit(CopyStr('2,1,' + GetFieldCaption(FieldNumber), 1, 80));

        exit(CopyStr('2,0,' + GetFieldCaption(FieldNumber), 1, 80));
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Sales Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    /// <summary>
    /// Determines whether this line is an extended text line attached to another document line.
    /// </summary>
    /// <returns>True if the line is an extended text line; otherwise, false.</returns>
    procedure IsExtendedText(): Boolean
    begin
        exit((Type = Type::" ") and ("Attached to Line No." <> 0) and (Quantity = 0));
    end;

    /// <summary>
    /// Opens the Dimension Set Entries page to display the dimensions associated with this archived sales line.
    /// </summary>
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "Document No."));
    end;

    /// <summary>
    /// Opens the Sales Archive Comment Sheet page to display comments associated with this archived sales line.
    /// </summary>
    procedure ShowLineComments()
    var
        SalesCommentLineArch: Record "Sales Comment Line Archive";
        SalesArchCommentSheet: Page "Sales Archive Comment Sheet";
    begin
        SalesCommentLineArch.SetRange("Document Type", "Document Type");
        SalesCommentLineArch.SetRange("No.", "Document No.");
        SalesCommentLineArch.SetRange("Document Line No.", "Line No.");
        SalesCommentLineArch.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        SalesCommentLineArch.SetRange("Version No.", "Version No.");
        Clear(SalesArchCommentSheet);
        SalesArchCommentSheet.SetTableView(SalesCommentLineArch);
        SalesArchCommentSheet.RunModal();
    end;

    /// <summary>
    /// Opens the Deferral Schedule Archive page to display the deferral schedule for this archived sales line.
    /// </summary>
    procedure ShowDeferrals()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDeferrals(Rec, IsHandled);
        if IsHandled then
            exit;

        DeferralUtilities.OpenLineScheduleArchive(
            "Deferral Code", "Deferral Document Type"::Sales.AsInteger(),
            "Document Type".AsInteger(), "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.");
    end;

    /// <summary>
    /// Copies archived sales lines to a temporary sales line record set for use in document restoration.
    /// </summary>
    /// <param name="SalesHeaderArchive">Specifies the archived sales header from which to copy lines.</param>
    /// <param name="TempSalesLine">Returns the temporary sales line record set with the copied line data.</param>
    procedure CopyTempLines(SalesHeaderArchive: Record "Sales Header Archive"; var TempSalesLine: Record "Sales Line" temporary)
    var
        SalesLineArchive: Record "Sales Line Archive";
    begin
        DeleteAll();

        SalesLineArchive.SetRange("Document Type", SalesHeaderArchive."Document Type");
        SalesLineArchive.SetRange("Document No.", SalesHeaderArchive."No.");
        SalesLineArchive.SetRange("Version No.", SalesHeaderArchive."Version No.");
        SalesLineArchive.SetRange("Doc. No. Occurrence", SalesHeaderArchive."Doc. No. Occurrence");
        OnCopyTempLinesOnAfterSalesLineArchiveSetFilters(SalesLineArchive, SalesHeaderArchive);
        if SalesLineArchive.FindSet() then
            repeat
                Init();
                Rec := SalesLineArchive;
                Insert();
                TempSalesLine.TransferFields(SalesLineArchive);
                TempSalesLine.Insert();
            until SalesLineArchive.Next() = 0;
    end;

    /// <summary>
    /// Raises an event after setting filters on the sales line archive record for copying lines.
    /// </summary>
    /// <param name="SalesLineArchive">Specifies the sales line archive record with applied filters.</param>
    /// <param name="SalesHeaderArchive">Specifies the sales header archive used for filtering.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCopyTempLinesOnAfterSalesLineArchiveSetFilters(var SalesLineArchive: Record "Sales Line Archive"; SalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;

    /// <summary>
    /// Raises an event before displaying the deferral schedule for the archived sales line.
    /// </summary>
    /// <param name="SalesLineArchive">Specifies the sales line archive record.</param>
    /// <param name="IsHandled">Set to true to skip the default deferral display logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeferrals(var SalesLineArchive: Record "Sales Line Archive"; var IsHandled: Boolean)
    begin
    end;
}
