// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
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
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.IO;
using System.Security.User;

/// <summary>
/// Stores line-level details for posted sales return receipts including returned items and quantities.
/// </summary>
table 6661 "Return Receipt Line"
{
    Caption = 'Return Receipt Line';
    LookupPageID = "Posted Return Receipt Lines";
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Value Entry" = r;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the customer number who returned the items.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            ToolTip = 'Specifies the number of the customer.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the document number of the posted return receipt header.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the related document.';
            TableRelation = "Return Receipt Header";
        }
        /// <summary>
        /// Specifies the sequential line number within the return receipt.
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
        /// Specifies the location where returned items were received.
        /// </summary>
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
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
        /// Specifies the date when items were shipped or received.
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
            ToolTip = 'Specifies either the name of or the description of the item, general ledger account or item charge.';
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
        /// Specifies the quantity received for the return.
        /// </summary>
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the number of units of the item, general ledger account, or item charge on the line.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the unit price of the item or resource on the line.
        /// </summary>
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Unit Price';
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
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Indicates whether the line is included in invoice discount calculations.
        /// </summary>
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
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
        /// Specifies the item ledger entry to apply this return to.
        /// </summary>
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';
            ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
        }
        /// <summary>
        /// Specifies the item receipt entry number created by posting.
        /// </summary>
        field(39; "Item Rcpt. Entry No."; Integer)
        {
            Caption = 'Item Rcpt. Entry No.';
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
        /// Specifies the quantity that has been invoiced for this return.
        /// </summary>
        field(61; "Quantity Invoiced"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity Invoiced';
            ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
            DecimalPlaces = 0 : 5;
            Editable = false;
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
        /// Specifies the general business posting group for the line.
        /// </summary>
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// Specifies the general product posting group for the line.
        /// </summary>
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
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
            TableRelation = "Return Receipt Line"."Line No." where("Document No." = field("Document No."));
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
        /// Specifies the tax area code for sales tax calculations.
        /// </summary>
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the line is subject to sales tax.
        /// </summary>
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        /// <summary>
        /// Specifies the tax group code for sales tax calculations.
        /// </summary>
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Specifies the VAT business posting group for tax calculations.
        /// </summary>
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Specifies the VAT product posting group for tax calculations.
        /// </summary>
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Specifies the currency code used for the return receipt line amounts.
        /// </summary>
        field(91; "Currency Code"; Code[10])
        {
            CalcFormula = lookup("Return Receipt Header"."Currency Code" where("No." = field("Document No.")));
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency that is used on the entry.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the blanket order number this line is linked to.
        /// </summary>
        field(97; "Blanket Order No."; Code[20])
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Blanket Order No.';
            ToolTip = 'Specifies the number of the blanket order that the record originates from.';
            TableRelation = "Sales Header"."No." where("Document Type" = const("Blanket Order"));
        }
        /// <summary>
        /// Specifies the blanket order line number this line is linked to.
        /// </summary>
        field(98; "Blanket Order Line No."; Integer)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
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
        /// Specifies the posting date of the return receipt line.
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
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        /// <summary>
        /// Specifies the project contract entry number for project billing.
        /// </summary>
        field(1002; "Job Contract Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Project Contract Entry No.';
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
        /// Specifies the bin code where returned items were placed.
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
        /// Specifies the invoiced quantity in the base unit of measure.
        /// </summary>
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
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
            ValidateTableRelation = true;
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
        /// Specifies the return quantity received but not yet invoiced.
        /// </summary>
        field(5805; "Return Qty. Rcd. Not Invd."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Return Qty. Rcd. Not Invd.';
            ToolTip = 'Specifies the quantity from the line that has been posted as received but that has not yet been posted as invoiced.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Specifies the item ledger entry this return was applied from.
        /// </summary>
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied from.';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the base amount for item charge allocation.
        /// </summary>
        field(5812; "Item Charge Base Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Item Charge Base Amount';
        }
        /// <summary>
        /// Indicates whether this is a correcting entry that reverses a previous posting.
        /// </summary>
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
            Editable = false;
        }
        /// <summary>
        /// Specifies the return order number that this line was created from.
        /// </summary>
        field(6602; "Return Order No."; Code[20])
        {
            Caption = 'Return Order No.';
            ToolTip = 'Specifies the return order number this line is associated with.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the return order line number that this line was created from.
        /// </summary>
        field(6603; "Return Order Line No."; Integer)
        {
            Caption = 'Return Order Line No.';
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
        }
        key(Key2; "Return Order No.", "Return Order Line No.")
        {
        }
        key(Key3; "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key4; "Item Rcpt. Entry No.")
        {
        }
        key(Key5; "Bill-to Customer No.")
        {
        }
        key(Key6; "Sell-to Customer No.")
        {
        }
        key(Key7; "Appl.-from Item Entry")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        SalesDocLineComments: Record "Sales Comment Line";
    begin
        SalesDocLineComments.SetRange("Document Type", SalesDocLineComments."Document Type"::"Posted Return Receipt");
        SalesDocLineComments.SetRange("No.", "Document No.");
        SalesDocLineComments.SetRange("Document Line No.", "Line No.");
        if not SalesDocLineComments.IsEmpty() then
            SalesDocLineComments.DeleteAll();
    end;

    var
        Currency: Record Currency;
        ReturnRcptHeader: Record "Return Receipt Header";
        TranslationHelper: Codeunit "Translation Helper";
        CurrencyRead: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Return Receipt No. %1:';
#pragma warning restore AA0470
        Text001: Label 'The program cannot find this purchase line.';
#pragma warning restore AA0074

    /// <summary>
    /// Retrieves the currency code from the return receipt header.
    /// </summary>
    /// <returns>The currency code for this return receipt line.</returns>
    procedure GetCurrencyCode(): Code[10]
    begin
        if "Document No." = ReturnRcptHeader."No." then
            exit(ReturnRcptHeader."Currency Code");
        if ReturnRcptHeader.Get("Document No.") then
            exit(ReturnRcptHeader."Currency Code");
        exit('');
    end;

    /// <summary>
    /// Opens the dimension set entries page for this return receipt line.
    /// </summary>
    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    /// <summary>
    /// Opens the Item Tracking Lines page showing the tracking for this return receipt line.
    /// </summary>
    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingDocMgt.ShowItemTrackingForShptRcptLine(DATABASE::"Return Receipt Line", 0, "Document No.", '', 0, "Line No.");
    end;

    /// <summary>
    /// Inserts a sales credit memo line from this return receipt line.
    /// </summary>
    /// <param name="SalesLine">Returns the created sales line.</param>
    procedure InsertInvLineFromRetRcptLine(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExtTextLine: Boolean;
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInsertInvLineFromRetRcptLine(Rec, SalesLine, IsHandled);
        if IsHandled then
            exit;

        SetRange("Document No.", "Document No.");

        TempSalesLine := SalesLine;
        if SalesLine.Find('+') then
            NextLineNo := SalesLine."Line No." + 10000
        else
            NextLineNo := 10000;

        IsHandled := false;
        OnInsertInvLineFromRetRcptLineOnBeforeSalesHeaderGet(SalesHeader, Rec, TempSalesLine, IsHandled);
        if not IsHandled then
            if SalesHeader."No." <> TempSalesLine."Document No." then
                SalesHeader.Get(TempSalesLine."Document Type", TempSalesLine."Document No.");

        OnInsertInvLineFromRetRcptLineOnAfterSalesHeaderGet(Rec, SalesHeader, SalesLine);

        if SalesLine."Return Receipt No." <> "Document No." then begin
            OnInsertInvLineFromRetRcptLineOnBeforeInitSalesLine(Rec, SalesLine);
            SalesLine.Init();
            SalesLine."Line No." := NextLineNo;
            SalesLine."Document Type" := TempSalesLine."Document Type";
            SalesLine."Document No." := TempSalesLine."Document No.";
            TranslationHelper.SetGlobalLanguageByCode(SalesHeader."Language Code");
            SalesLine.Description := StrSubstNo(Text000, "Document No.");
            TranslationHelper.RestoreGlobalLanguage();
            IsHandled := false;
            OnBeforeInsertInvLineFromRetRcptLineBeforeInsertTextLine(Rec, SalesLine, NextLineNo, IsHandled);
            if not IsHandled then begin
                SalesLine.Insert();
                OnAfterDescriptionSalesLineInsert(SalesLine, Rec, NextLineNo);
                NextLineNo := NextLineNo + 10000;
            end;
        end;

        TransferOldExtLines.ClearLineNumbers();
        SalesSetup.Get();
        repeat
            ExtTextLine := (Type = Type::" ") and ("Attached to Line No." <> 0) and (Quantity = 0);
            if ExtTextLine then
                TransferOldExtLines.GetNewLineNumber("Attached to Line No.")
            else
                "Attached to Line No." := 0;

            if not SalesOrderLine.Get(
                 SalesOrderLine."Document Type"::"Return Order", "Return Order No.", "Return Order Line No.")
            then begin
                if ExtTextLine then begin
                    SalesOrderLine.Init();
                    SalesOrderLine."Line No." := "Return Order Line No.";
                    SalesOrderLine.Description := Description;
                    SalesOrderLine."Description 2" := "Description 2";
                end else begin
                    OnInsertInvLineFromRetRcptLineOnBeforeNoExtTextLineError(Rec);
                    Error(Text001);
                end
            end else begin
                if (SalesHeader2."Document Type" <> SalesOrderLine."Document Type"::"Return Order") or
                   (SalesHeader2."No." <> SalesOrderLine."Document No.")
                then
                    SalesHeader2.Get(SalesOrderLine."Document Type"::"Return Order", "Return Order No.");

                InitCurrency("Currency Code");

                if SalesHeader."Prices Including VAT" then begin
                    if not SalesHeader2."Prices Including VAT" then
                        SalesOrderLine."Unit Price" :=
                          Round(
                            SalesOrderLine."Unit Price" * (1 + SalesOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
                end else
                    if SalesHeader2."Prices Including VAT" then
                        SalesOrderLine."Unit Price" :=
                          Round(
                            SalesOrderLine."Unit Price" / (1 + SalesOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
            end;
            OnInsertInvLineFromRetRcptLineOnAfterCalcUnitPrice(Rec, SalesHeader, SalesHeader2, SalesLine, SalesOrderLine, Currency);

            SalesLine := SalesOrderLine;
            SalesLine."Line No." := NextLineNo;
            SalesLine."Document Type" := TempSalesLine."Document Type";
            SalesLine."Document No." := TempSalesLine."Document No.";
            SalesLine."Variant Code" := "Variant Code";
            SalesLine."Location Code" := "Location Code";
            SalesLine."Return Reason Code" := "Return Reason Code";
            SalesLine."Quantity (Base)" := 0;
            SalesLine.Quantity := 0;
            SalesLine."Outstanding Qty. (Base)" := 0;
            SalesLine."Outstanding Quantity" := 0;
            SalesLine."Return Qty. Received" := 0;
            SalesLine."Return Qty. Received (Base)" := 0;
            SalesLine."Quantity Invoiced" := 0;
            SalesLine."Qty. Invoiced (Base)" := 0;
            SalesLine."Drop Shipment" := false;
            SalesLine."Return Receipt No." := "Document No.";
            SalesLine."Return Receipt Line No." := "Line No.";
            SalesLine."Appl.-to Item Entry" := 0;
            SalesLine."Appl.-from Item Entry" := 0;
            OnAfterCopyFieldsFromReturnReceiptLine(Rec, SalesLine);

            if not ExtTextLine then begin
                IsHandled := false;
                OnInsertInvLineFromRetRcptLineOnBeforeValidateSalesLineQuantity(Rec, SalesLine, IsHandled, SalesHeader);
                if not IsHandled then
                    SalesLine.Validate(Quantity, Quantity - "Quantity Invoiced");

                CopySalesLinePriceAndDiscountFromSalesOrderLine(SalesLine, SalesOrderLine);
                OnOnInsertInvLineFromRetRcptLineOnAfterCopySalesLinePriceAndDiscount(SalesLine, SalesOrderLine, Rec, SalesHeader);
            end;
            SalesLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                SalesOrderLine."Line No.",
                NextLineNo,
                "Attached to Line No.");
            SalesLine."Shortcut Dimension 1 Code" := SalesOrderLine."Shortcut Dimension 1 Code";
            SalesLine."Shortcut Dimension 2 Code" := SalesOrderLine."Shortcut Dimension 2 Code";
            SalesLine."Dimension Set ID" := SalesOrderLine."Dimension Set ID";

            IsHandled := false;
            OnBeforeInsertInvLineFromRetRcptLine(SalesLine, SalesOrderLine, Rec, IsHandled, NextLineNo);
            if not IsHandled then
                SalesLine.Insert();
            IsHandled := false;
            OnAftertInsertInvLineFromRetRcptLine(SalesLine, SalesOrderLine, Rec, IsHandled);
            if not IsHandled then
                ItemTrackingMgt.CopyHandledItemTrkgToInvLine(SalesOrderLine, SalesLine);

            NextLineNo := NextLineNo + 10000;
            if "Attached to Line No." = 0 then begin
                SetRange("Attached to Line No.", "Line No.");
                SetRange(Type, Type::" ");
            end;

        until (Next() = 0) or ("Attached to Line No." = 0);

        IsHandled := false;
        OnInsertInvLineFromRetRcptLineOnAfterInsertAllLines(Rec, SalesLine, IsHandled);
        if IsHandled then
            exit;

        if SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, "Return Order No.") then
            if not SalesOrderHeader."Get Shipment Used" then begin
                SalesOrderHeader."Get Shipment Used" := true;
                SalesOrderHeader.Modify();
            end;
    end;

    local procedure CopySalesLinePriceAndDiscountFromSalesOrderLine(var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopySalesLinePriceAndDiscountFromSalesOrderLine(SalesLine, SalesOrderLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Validate("Unit Price", SalesOrderLine."Unit Price");
        SalesLine."Allow Line Disc." := SalesOrderLine."Allow Line Disc.";
        SalesLine."Allow Invoice Disc." := SalesOrderLine."Allow Invoice Disc.";
        SalesLine.Validate("Line Discount %", SalesOrderLine."Line Discount %");
        if SalesOrderLine.Quantity = 0 then
            SalesLine.Validate("Inv. Discount Amount", 0)
        else
            SalesLine.Validate(
              "Inv. Discount Amount",
              Round(
                SalesOrderLine."Inv. Discount Amount" * SalesLine.Quantity / SalesOrderLine.Quantity,
                Currency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// Retrieves credit memo lines associated with this return receipt line.
    /// </summary>
    /// <param name="TempSalesCrMemoLine">Returns the temporary sales credit memo lines.</param>
    procedure GetSalesCrMemoLines(var TempSalesCrMemoLine: Record "Sales Cr.Memo Line" temporary)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
    begin
        TempSalesCrMemoLine.Reset();
        TempSalesCrMemoLine.DeleteAll();

        if Type <> Type::Item then
            exit;

        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_No, "Document No.");
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Type, Enum::"Item Ledger Document Type"::"Sales Return Receipt");
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Line_No, "Line No.");
        ValueItemLedgerEntries.SetFilter(Item_Ledg_Invoice_Quantity, '<>0');
        ValueItemLedgerEntries.SetRange(Value_Entry_Type, Enum::"Cost Entry Type"::"Direct Cost");
        ValueItemLedgerEntries.SetFilter(Value_Entry_Invoiced_Qty, '<>0');
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Type, Enum::"Item Ledger Document Type"::"Sales Credit Memo");
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do
            if SalesCrMemoLine.Get(ValueItemLedgerEntries.Value_Entry_Doc_No, ValueItemLedgerEntries.Value_Entry_Doc_Line_No) then begin
                TempSalesCrMemoLine.Init();
                TempSalesCrMemoLine := SalesCrMemoLine;
                if TempSalesCrMemoLine.Insert() then;
            end;
    end;

    /// <summary>
    /// Applies filters to item ledger entries to retrieve entries for this posted document line.
    /// </summary>
    /// <param name="ItemLedgEntry">The item ledger entry record to apply filters to.</param>
    procedure FilterPstdDocLnItemLedgEntries(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Document No.");
        ItemLedgEntry.SetRange("Document No.", "Document No.");
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Sales Return Receipt");
        ItemLedgEntry.SetRange("Document Line No.", "Line No.");
    end;

    /// <summary>
    /// Opens a page displaying the credit memo lines for this return receipt line.
    /// </summary>
    procedure ShowItemSalesCrMemoLines()
    var
        TempSalesCrMemoLine: Record "Sales Cr.Memo Line" temporary;
    begin
        if Type = Type::Item then begin
            GetSalesCrMemoLines(TempSalesCrMemoLine);
            PAGE.RunModal(0, TempSalesCrMemoLine);
        end;
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    begin
        if (Currency.Code = CurrencyCode) and CurrencyRead then
            exit;

        if CurrencyCode <> '' then
            Currency.Get(CurrencyCode)
        else
            Currency.InitRoundingPrecision();
        CurrencyRead := true;
    end;

    /// <summary>
    /// Opens a page displaying the comments for this return receipt line.
    /// </summary>
    procedure ShowLineComments()
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.ShowComments(
            SalesCommentLine."Document Type"::"Posted Return Receipt".AsInteger(), "Document No.", "Line No.");
    end;

    /// <summary>
    /// Initializes the return receipt line from a sales line when posting a sales return.
    /// </summary>
    /// <param name="ReturnRcptHeader">The return receipt header to link to.</param>
    /// <param name="SalesLine">The sales line to copy data from.</param>
    procedure InitFromSalesLine(ReturnRcptHeader: Record "Return Receipt Header"; SalesLine: Record "Sales Line")
    begin
        Init();
        TransferFields(SalesLine);
        if ("No." = '') and HasTypeToFillMandatoryFields() then
            Type := Type::" ";
        "Posting Date" := ReturnRcptHeader."Posting Date";
        "Document No." := ReturnRcptHeader."No.";
        Quantity := SalesLine."Return Qty. to Receive";
        "Quantity (Base)" := SalesLine."Return Qty. to Receive (Base)";
        if Abs(SalesLine."Qty. to Invoice") > Abs(SalesLine."Return Qty. to Receive") then begin
            "Quantity Invoiced" := SalesLine."Return Qty. to Receive";
            "Qty. Invoiced (Base)" := SalesLine."Return Qty. to Receive (Base)";
        end else begin
            "Quantity Invoiced" := SalesLine."Qty. to Invoice";
            "Qty. Invoiced (Base)" := SalesLine."Qty. to Invoice (Base)";
        end;
        "Return Qty. Rcd. Not Invd." :=
          Quantity - "Quantity Invoiced";
        if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then begin
            "Return Order No." := SalesLine."Document No.";
            "Return Order Line No." := SalesLine."Line No.";
        end;

        OnAfterInitFromSalesLine(ReturnRcptHeader, SalesLine, Rec);
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
    /// Applies a security filter based on the user's responsibility center setup.
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

    /// <summary>
    /// Raised after copying fields from the return receipt line to a sales line.
    /// </summary>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="SalesLine">The target sales line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsFromReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised after initializing the return receipt line from a sales line.
    /// </summary>
    /// <param name="ReturnRcptHeader">The return receipt header record.</param>
    /// <param name="SalesLine">The source sales line record.</param>
    /// <param name="ReturnRcptLine">The return receipt line being initialized.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesLine(ReturnRcptHeader: Record "Return Receipt Header"; SalesLine: Record "Sales Line"; var ReturnRcptLine: Record "Return Receipt Line")
    begin
    end;

    /// <summary>
    /// Raised after inserting an invoice line from a return receipt line.
    /// </summary>
    /// <param name="SalesLine">The inserted sales line record.</param>
    /// <param name="SalesOrderLine">The related sales order line record.</param>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="IsHandled">Set to true to skip additional processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAftertInsertInvLineFromRetRcptLine(var SalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line"; var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before copying price and discount from a sales order line to a sales line.
    /// </summary>
    /// <param name="SalesLine">The target sales line record.</param>
    /// <param name="SalesOrderLine">The source sales order line record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesLinePriceAndDiscountFromSalesOrderLine(var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting an invoice line from a return receipt line.
    /// </summary>
    /// <param name="SalesLine">The sales line to be inserted.</param>
    /// <param name="SalesOrderLine">The related sales order line record.</param>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    /// <param name="NextLineNo">The next line number to be used.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromRetRcptLine(var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean; NextLineNo: Integer)
    begin
    end;

    /// <summary>
    /// Raised before inserting a text line when inserting an invoice line from a return receipt line.
    /// </summary>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="NextLineNo">The next line number to be used.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromRetRcptLineBeforeInsertTextLine(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line"; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before initializing the sales line during InsertInvLineFromRetRcptLine.
    /// </summary>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="SalesLine">The sales line record being initialized.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnBeforeInitSalesLine(var ReturnReceiptLine: Record "Return Receipt Line"; SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised after inserting all lines during InsertInvLineFromRetRcptLine.
    /// </summary>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="IsHandled">Set to true to skip additional processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnAfterInsertAllLines(ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before validating the sales line quantity during InsertInvLineFromRetRcptLine.
    /// </summary>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnBeforeValidateSalesLineQuantity(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised after inserting the description sales line.
    /// </summary>
    /// <param name="SalesLine">The inserted sales line record.</param>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="NextLineNo">The next line number after insertion.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterDescriptionSalesLineInsert(var SalesLine: Record "Sales Line"; ReturnReceiptLine: Record "Return Receipt Line"; var NextLineNo: Integer)
    begin
    end;

    /// <summary>
    /// Raised during the insertion of an invoice line from a return receipt line.
    /// </summary>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="SalesLine">The sales line being inserted.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLine(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after copying sales line price and discount during InsertInvLineFromRetRcptLine.
    /// </summary>
    /// <param name="SalesLine">The target sales line record.</param>
    /// <param name="SalesOrderLine">The source sales order line record.</param>
    /// <param name="ReturnReceiptLine">The return receipt line record.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnOnInsertInvLineFromRetRcptLineOnAfterCopySalesLinePriceAndDiscount(var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; ReturnReceiptLine: Record "Return Receipt Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised after getting the sales header during InsertInvLineFromRetRcptLine.
    /// </summary>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="SalesLine">The sales line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnAfterSalesHeaderGet(var ReturnReceiptLine: Record "Return Receipt Line"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised before raising the no extended text line error during InsertInvLineFromRetRcptLine.
    /// </summary>
    /// <param name="ReturnReceiptLine">The return receipt line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnBeforeNoExtTextLineError(var ReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    /// <summary>
    /// Raised after calculating the unit price during InsertInvLineFromRetRcptLine.
    /// </summary>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="SalesHeader2">The secondary sales header record.</param>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="SalesOrderLine">The sales order line record.</param>
    /// <param name="Currency">The currency record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnAfterCalcUnitPrice(var ReturnReceiptLine: Record "Return Receipt Line"; SalesHeader: Record "Sales Header"; SalesHeader2: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line"; Currency: Record Currency)
    begin
    end;

    /// <summary>
    /// Raised before setting the security filter on responsibility center for the return receipt line.
    /// </summary>
    /// <param name="ReturnReceiptLine">The return receipt line record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before getting the sales header during InsertInvLineFromRetRcptLine.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="ReturnReceiptLine">The source return receipt line record.</param>
    /// <param name="TempSalesLine">The temporary sales line buffer.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromRetRcptLineOnBeforeSalesHeaderGet(var SalesHeader: Record "Sales Header"; ReturnReceiptLine: Record "Return Receipt Line"; var TempSalesLine: Record "Sales Line" temporary; var IsHandled: boolean)
    begin
    end;

    /// <summary>
    /// Raised before showing item tracking lines for the return receipt line.
    /// </summary>
    /// <param name="ReturnReceiptLine">The return receipt line record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemTrackingLines(var ReturnReceiptLine: Record "Return Receipt Line"; var IsHandled: Boolean)
    begin
    end;
}
