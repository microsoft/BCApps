// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Assembly.History;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Intercompany.Partner;
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
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.IO;
using System.Reflection;
using System.Security.User;

/// <summary>
/// Stores line-level details for posted sales shipments including items, quantities, and tracking information.
/// </summary>
table 111 "Sales Shipment Line"
{
    Caption = 'Sales Shipment Line';
    DrillDownPageID = "Posted Sales Shipment Lines";
    LookupPageID = "Posted Sales Shipment Lines";
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
        /// Specifies the document number of the posted shipment this line belongs to.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the shipment number.';
            TableRelation = "Sales Shipment Header";

            trigger OnValidate()
            begin
                UpdateDocumentId();
            end;
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
            ToolTip = 'Specifies the code for the location of the item on the shipment line which was posted.';
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
        /// Specifies the quantity of items shipped on the line.
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
            Caption = 'Unit Price';
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
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Indicates whether the line can be included in invoice discount calculation.
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
        /// Specifies the item ledger entry number to apply this line to.
        /// </summary>
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';
            ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
        }
        /// <summary>
        /// Specifies the item ledger entry number created by this shipment.
        /// </summary>
        field(39; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
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
        /// Contains the quantity shipped but not yet invoiced.
        /// </summary>
        field(58; "Qty. Shipped Not Invoiced"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Qty. Shipped Not Invoiced';
            ToolTip = 'Specifies the quantity of the shipped item that has been posted as shipped but that has not yet been posted as invoiced.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Specifies the quantity that has been invoiced.
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
        /// Specifies the sales order number from which this shipment was created.
        /// </summary>
        field(65; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        /// <summary>
        /// Specifies the line number from the original sales order.
        /// </summary>
        field(66; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        /// <summary>
        /// Specifies the customer number to whom the invoice will be sent.
        /// </summary>
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the purchase order number for drop shipments.
        /// </summary>
        field(71; "Purchase Order No."; Code[20])
        {
            Caption = 'Purchase Order No.';
        }
        /// <summary>
        /// Specifies the purchase order line number for drop shipments.
        /// </summary>
        field(72; "Purch. Order Line No."; Integer)
        {
            Caption = 'Purch. Order Line No.';
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
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// Specifies the general product posting group for determining G/L accounts.
        /// </summary>
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
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
        /// Specifies the line number this line is attached to for extended text.
        /// </summary>
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            TableRelation = "Sales Shipment Line"."Line No." where("Document No." = field("Document No."));
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
        /// Specifies the tax area code for sales tax calculation.
        /// </summary>
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the sale is liable for tax.
        /// </summary>
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        /// <summary>
        /// Specifies the tax group code for sales tax calculation.
        /// </summary>
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Specifies the VAT business posting group for VAT calculation.
        /// </summary>
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Specifies the VAT product posting group for VAT calculation.
        /// </summary>
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Specifies the currency code for amounts on the shipment.
        /// </summary>
        field(91; "Currency Code"; Code[10])
        {
            CalcFormula = lookup("Sales Shipment Header"."Currency Code" where("No." = field("Document No.")));
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency that is used on the entry.';
            Editable = false;
            FieldClass = FlowField;
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
        /// Specifies the type of intercompany partner reference.
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the intercompany partner reference code.
        /// </summary>
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
            DataClassification = CustomerContent;
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
        /// Indicates whether the shipment was authorized for credit card payment.
        /// </summary>
        field(826; "Authorized for Credit Card"; Boolean)
        {
            Caption = 'Authorized for Credit Card';
        }
        /// <summary>
        /// Specifies the project task number for project-related shipments.
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
            Editable = false;
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
            ToolTip = 'Specifies that the item on the sales line is a catalog item, which means it is not normally kept in inventory.';
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
        /// Specifies the date the customer requested delivery.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            ToolTip = 'Specifies the date that the customer has asked for the order to be delivered.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the date that was promised for delivery.
        /// </summary>
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
            ToolTip = 'Specifies the date that you have promised to deliver the order, as a result of the Order Promising function.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the time required for shipping from the shipping agent.
        /// </summary>
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';
            ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
        }
        /// <summary>
        /// Specifies the time required for outbound warehouse handling.
        /// </summary>
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Outbound Whse. Handling Time';
            ToolTip = 'Specifies a date formula for the time it takes to get items ready to ship from this location. The time element is used in the calculation of the delivery date as follows: Shipment Date + Outbound Warehouse Handling Time = Planned Shipment Date + Shipping Time = Planned Delivery Date.';
        }
        /// <summary>
        /// Specifies the planned delivery date calculated by the system.
        /// </summary>
        field(5794; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';
            ToolTip = 'Specifies the planned date that the shipment will be delivered at the customer''s address. If the customer requests a delivery date, the program calculates whether the items will be available for delivery on this date. If the items are available, the planned delivery date will be the same as the requested delivery date. If not, the program calculates the date that the items are available for delivery and enters this date in the Planned Delivery Date field.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the planned shipment date calculated by the system.
        /// </summary>
        field(5795; "Planned Shipment Date"; Date)
        {
            Caption = 'Planned Shipment Date';
            ToolTip = 'Specifies the date that the shipment should ship from the warehouse. If the customer requests a delivery date, the program calculates the planned shipment date by subtracting the shipping time from the requested delivery date. If the customer does not request a delivery date or the requested delivery date cannot be met, the program calculates the content of this field by adding the shipment time to the shipping date.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the external document number from the customer's system for reference.
        /// </summary>
        field(5798; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        /// <summary>
        /// Specifies the reference number provided by the customer for this shipment line.
        /// </summary>
        field(5799; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
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
        /// Specifies the base amount for item charge allocation.
        /// </summary>
        field(5812; "Item Charge Base Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Item Charge Base Amount';
        }
        /// <summary>
        /// Indicates whether this line is a correction entry.
        /// </summary>
        field(5817; Correction; Boolean)
        {
            Caption = 'Correction';
            ToolTip = 'Specifies that this sales shipment line has been posted as a corrective entry.';
            Editable = false;
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
        /// Stores the unique identifier for the parent document.
        /// </summary>
        field(8000; "Document Id"; Guid)
        {
            Caption = 'Document Id';
            trigger OnValidate()
            begin
                UpdateDocumentNo();
            end;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Order No.", "Order Line No.", "Posting Date")
        {
        }
        key(Key3; "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key4; "Item Shpt. Entry No.")
        {
        }
        key(Key5; "Sell-to Customer No.")
        {
        }
        key(Key6; "Bill-to Customer No.")
        {
        }
        key(Key7; "Document Id")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Document No.", "Line No.", "Sell-to Customer No.", Type, "No.", "Shipment Date")
        {
        }
    }

    trigger OnInsert()
    begin
        UpdateDocumentId();
    end;

    trigger OnDelete()
    var
        SalesDocLineComments: Record "Sales Comment Line";
    begin
        SalesDocLineComments.SetRange("Document Type", SalesDocLineComments."Document Type"::Shipment);
        SalesDocLineComments.SetRange("No.", "Document No.");
        SalesDocLineComments.SetRange("Document Line No.", "Line No.");
        if not SalesDocLineComments.IsEmpty() then
            SalesDocLineComments.DeleteAll();

        PostedATOLink.DeleteAsmFromSalesShptLine(Rec);
    end;

    var
        Currency: Record Currency;
        SalesShptHeader: Record "Sales Shipment Header";
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        DimMgt: Codeunit DimensionManagement;
        UOMMgt: Codeunit "Unit of Measure Management";
        CurrencyRead: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Shipment No. %1:';
#pragma warning restore AA0470
        Text001: Label 'The program cannot find this Sales line.';
#pragma warning restore AA0074

    /// <summary>
    /// Retrieves the currency code from the sales shipment header.
    /// </summary>
    /// <returns>The currency code for this shipment line.</returns>
    procedure GetCurrencyCode(): Code[10]
    begin
        if "Document No." = SalesShptHeader."No." then
            exit(SalesShptHeader."Currency Code");
        if SalesShptHeader.Get("Document No.") then
            exit(SalesShptHeader."Currency Code");
        exit('');
    end;

    /// <summary>
    /// Opens the dimension set entries page for this shipment line.
    /// </summary>
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    /// <summary>
    /// Opens the Item Tracking Lines page showing the tracking for this shipment line.
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

        ItemTrackingDocMgt.ShowItemTrackingForShptRcptLine(DATABASE::"Sales Shipment Line", 0, "Document No.", '', 0, "Line No.");
    end;

    /// <summary>
    /// Inserts a sales invoice line from this shipment line when creating an invoice from a shipment.
    /// </summary>
    /// <param name="SalesLine">Returns the created sales invoice line.</param>
    procedure InsertInvLineFromShptLine(var SalesLine: Record "Sales Line")
    var
        SalesInvHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        TranslationHelper: Codeunit "Translation Helper";
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        ExtTextLine: Boolean;
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCodeInsertInvLineFromShptLine(Rec, SalesLine, IsHandled);
        if IsHandled then
            exit;

        SetRange("Document No.", "Document No.");

        TempSalesLine := SalesLine;
        if SalesLine.Find('+') then
            NextLineNo := SalesLine."Line No." + 10000
        else
            NextLineNo := 10000;

        IsHandled := false;
        OnInsertInvLineFromShptLineOnBeforeSalesHeaderGet(SalesInvHeader, Rec, TempSalesLine, IsHandled);
        if not IsHandled then
            if SalesInvHeader."No." <> TempSalesLine."Document No." then
                SalesInvHeader.Get(TempSalesLine."Document Type", TempSalesLine."Document No.");

        if SalesLine."Shipment No." <> "Document No." then begin

            OnInsertInvLineFromShptLineOnBeforeInsertDescriptionLine(
                Rec, SalesLine, TempSalesLine, SalesInvHeader, NextLineNo);

            SalesLine.Init();
            SalesLine."Line No." := NextLineNo;
            SalesLine."Document Type" := TempSalesLine."Document Type";
            SalesLine."Document No." := TempSalesLine."Document No.";
            TranslationHelper.SetGlobalLanguageByCode(SalesInvHeader."Language Code");
            SalesLine.Description := StrSubstNo(Text000, "Document No.");
            TranslationHelper.RestoreGlobalLanguage();
            IsHandled := false;
            OnBeforeInsertInvLineFromShptLineBeforeInsertTextLine(Rec, SalesLine, NextLineNo, IsHandled, TempSalesLine, SalesInvHeader);
            if not IsHandled then begin
                SalesLine.Insert();
                OnAfterDescriptionSalesLineInsert(SalesLine, Rec, NextLineNo);
                NextLineNo := NextLineNo + 10000;
            end;
        end;

        TransferOldExtLines.ClearLineNumbers();

        repeat
            ExtTextLine := (Type = Type::" ") and ("Attached to Line No." <> 0) and (Quantity = 0);
            if ExtTextLine then
                TransferOldExtLines.GetNewLineNumber("Attached to Line No.")
            else
                "Attached to Line No." := 0;

            if (Type <> Type::" ") and SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, "Order No.", "Order Line No.")
            then begin
                if (SalesOrderHeader."Document Type" <> SalesOrderLine."Document Type"::Order) or
                   (SalesOrderHeader."No." <> SalesOrderLine."Document No.")
                then
                    SalesOrderHeader.Get(SalesOrderLine."Document Type"::Order, "Order No.");
                OnInsertInvLineFromShptLineOnAfterSalesOrderHeaderGet(SalesOrderHeader, SalesInvHeader, SalesOrderLine);

                PrepaymentMgt.TestSalesOrderLineForGetShptLines(SalesOrderLine);
                InitCurrency("Currency Code");

                if SalesInvHeader."Prices Including VAT" then begin
                    if not SalesOrderHeader."Prices Including VAT" then
                        SalesOrderLine."Unit Price" :=
                          Round(
                            SalesOrderLine."Unit Price" * (1 + SalesOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
                end else
                    if SalesOrderHeader."Prices Including VAT" then
                        SalesOrderLine."Unit Price" :=
                          Round(
                            SalesOrderLine."Unit Price" / (1 + SalesOrderLine."VAT %" / 100),
                            Currency."Unit-Amount Rounding Precision");
            end else begin
                SalesOrderHeader.Init();
                if ExtTextLine or (Type = Type::" ") then begin
                    SalesOrderLine.Init();
                    SalesOrderLine."Line No." := "Order Line No.";
                    SalesOrderLine.Description := Description;
                    SalesOrderLine."Description 2" := "Description 2";
                    OnInsertInvLineFromShptLineOnAfterAssignDescription(Rec, SalesOrderLine);
                end else
                    Error(Text001);
            end;

            OnInsertInvLineFromShptLineOnBeforeAssigneSalesLine(Rec, SalesInvHeader, SalesOrderHeader, SalesLine, SalesOrderLine, Currency);

            SalesLine := SalesOrderLine;
            SalesLine."Line No." := NextLineNo;
            SalesLine."Document Type" := TempSalesLine."Document Type";
            SalesLine."Document No." := TempSalesLine."Document No.";
            SalesLine."Variant Code" := "Variant Code";
            SalesLine."Location Code" := "Location Code";
            SalesLine."Drop Shipment" := "Drop Shipment";
            SalesLine."Shipment No." := "Document No.";
            SalesLine."Shipment Line No." := "Line No.";
            ClearSalesLineValues(SalesLine);
            if not ExtTextLine and (SalesLine.Type <> SalesLine.Type::" ") then begin
                IsHandled := false;
                OnInsertInvLineFromShptLineOnBeforeValidateQuantity(Rec, SalesLine, IsHandled, SalesInvHeader);
                if SalesLine."Deferral Code" <> '' then
                    SalesLine.Validate("Deferral Code");
                if not IsHandled then
                    SalesLine.Validate(Quantity, Quantity - "Quantity Invoiced");
                CalcBaseQuantities(SalesLine, "Quantity (Base)" / Quantity);

                OnInsertInvLineFromShptLineOnAfterCalcQuantities(SalesLine, SalesOrderLine);

                SalesLine.Validate("Unit Price", SalesOrderLine."Unit Price");
                SalesLine."Allow Line Disc." := SalesOrderLine."Allow Line Disc.";
                SalesLine."Allow Invoice Disc." := SalesOrderLine."Allow Invoice Disc.";
                SalesOrderLine."Line Discount Amount" :=
                  Round(
                    SalesOrderLine."Line Discount Amount" * SalesLine.Quantity / SalesOrderLine.Quantity,
                    Currency."Amount Rounding Precision");
                if SalesInvHeader."Prices Including VAT" then begin
                    if not SalesOrderHeader."Prices Including VAT" then
                        SalesOrderLine."Line Discount Amount" :=
                          Round(
                            SalesOrderLine."Line Discount Amount" *
                            (1 + SalesOrderLine."VAT %" / 100), Currency."Amount Rounding Precision");
                end else
                    if SalesOrderHeader."Prices Including VAT" then
                        SalesOrderLine."Line Discount Amount" :=
                          Round(
                            SalesOrderLine."Line Discount Amount" /
                            (1 + SalesOrderLine."VAT %" / 100), Currency."Amount Rounding Precision");
                SalesLine.Validate("Line Discount Amount", SalesOrderLine."Line Discount Amount");
                SalesLine."Line Discount %" := SalesOrderLine."Line Discount %";
                SalesLine.UpdatePrePaymentAmounts();
                OnInsertInvLineFromShptLineOnAfterUpdatePrepaymentsAmounts(SalesLine, SalesOrderLine, Rec);

                if SalesOrderLine.Quantity = 0 then
                    SalesLine.Validate("Inv. Discount Amount", 0)
                else begin
                    if not SalesLine."Allow Invoice Disc." then
                        if SalesLine."VAT Calculation Type" <> SalesLine."VAT Calculation Type"::"Full VAT" then
                            SalesLine."Allow Invoice Disc." := SalesOrderLine."Allow Invoice Disc.";
                    if SalesLine."Allow Invoice Disc." then
                        SalesLine.Validate(
                          "Inv. Discount Amount",
                          Round(
                            SalesOrderLine."Inv. Discount Amount" * SalesLine.Quantity / SalesOrderLine.Quantity,
                            Currency."Amount Rounding Precision"))
                    else
                        SalesLine.Validate("Inv. Discount Amount", 0);
                end;

                OnInsertInvLineFromShptLineOnAfterValidateInvDiscountAmount(SalesLine, SalesOrderLine, Rec, SalesInvHeader);
            end;

            SalesLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(
                SalesOrderLine."Line No.",
                NextLineNo,
                "Attached to Line No.");
            SalesLine."Bin Code" := "Bin Code";
            SalesLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
            SalesLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
            SalesLine."Dimension Set ID" := "Dimension Set ID";
            IsHandled := false;
            OnBeforeInsertInvLineFromShptLine(Rec, SalesLine, SalesOrderLine, IsHandled, TransferOldExtLines);
            if not IsHandled then
                SalesLine.Insert();
            OnAfterInsertInvLineFromShptLine(SalesLine, SalesOrderLine, NextLineNo, Rec);

            ItemTrackingMgt.CopyHandledItemTrkgToInvLine(SalesOrderLine, SalesLine);

            NextLineNo := NextLineNo + 10000;
            if "Attached to Line No." = 0 then begin
                SetRange("Attached to Line No.", "Line No.");
                SetRange(Type, Type::" ");
            end;
        until (Next() = 0) or ("Attached to Line No." = 0);
        IsHandled := false;
        OnInsertInvLineFromShptLineOnAfterInsertAllLines(Rec, SalesLine, IsHandled);
        if not IsHandled then
            if SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, "Order No.") then
                if not SalesOrderHeader."Get Shipment Used" then begin
                    SalesOrderHeader."Get Shipment Used" := true;
                    SalesOrderHeader.Modify();
                end;
    end;

    /// <summary>
    /// Retrieves invoice lines associated with this shipment line.
    /// </summary>
    /// <param name="TempSalesInvoiceLine">Returns the temporary sales invoice lines.</param>
    procedure GetSalesInvLines(var TempSalesInvoiceLine: Record "Sales Invoice Line" temporary)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
    begin
        TempSalesInvoiceLine.Reset();
        TempSalesInvoiceLine.DeleteAll();

        if Type <> Type::Item then
            exit;

        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_No, "Document No.");
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Type, Enum::"Item Ledger Document Type"::"Sales Shipment");
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Line_No, "Line No.");
        ValueItemLedgerEntries.SetFilter(Item_Ledg_Invoice_Quantity, '<>0');
        ValueItemLedgerEntries.SetRange(Value_Entry_Type, Enum::"Cost Entry Type"::"Direct Cost");
        ValueItemLedgerEntries.SetFilter(Value_Entry_Invoiced_Qty, '<>0');
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Type, Enum::"Item Ledger Document Type"::"Sales Invoice");
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do begin
            OnGetSalesInvLinesOnBeforeGetSalesInvoiceLine(SalesInvoiceLine);
            if SalesInvoiceLine.Get(ValueItemLedgerEntries.Value_Entry_Doc_No, ValueItemLedgerEntries.Value_Entry_Doc_Line_No) then begin
                TempSalesInvoiceLine.Init();
                TempSalesInvoiceLine := SalesInvoiceLine;
                if TempSalesInvoiceLine.Insert() then;
            end;
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
        ItemLedgEntry: Record "Item Ledger Entry";
        TotalCostLCY: Decimal;
        TotalQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcShippedSaleNotReturned(Rec, ShippedQtyNotReturned, RevUnitCostLCY, ExactCostReverse, IsHandled);
        if IsHandled then
            exit;

        ShippedQtyNotReturned := 0;
        if (Type <> Type::Item) or (Quantity <= 0) then begin
            RevUnitCostLCY := "Unit Cost (LCY)";
            exit;
        end;

        RevUnitCostLCY := 0;
        FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
        if ItemLedgEntry.FindSet() then
            repeat
                ShippedQtyNotReturned := ShippedQtyNotReturned - ItemLedgEntry."Shipped Qty. Not Returned";
                if ExactCostReverse then begin
                    ItemLedgEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
                    TotalCostLCY :=
                      TotalCostLCY + ItemLedgEntry."Cost Amount (Expected)" + ItemLedgEntry."Cost Amount (Actual)";
                    TotalQtyBase := TotalQtyBase + ItemLedgEntry.Quantity;
                end;
            until ItemLedgEntry.Next() = 0;

        if ExactCostReverse and (ShippedQtyNotReturned <> 0) and (TotalQtyBase <> 0) then
            RevUnitCostLCY := Abs(TotalCostLCY / TotalQtyBase) * "Qty. per Unit of Measure"
        else
            RevUnitCostLCY := "Unit Cost (LCY)";

        ShippedQtyNotReturned := CalcQty(ShippedQtyNotReturned);
    end;

    local procedure CalcQty(QtyBase: Decimal): Decimal
    begin
        if "Qty. per Unit of Measure" = 0 then
            exit(QtyBase);
        exit(Round(QtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
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
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Sales Shipment");
        ItemLedgEntry.SetRange("Document Line No.", "Line No.");
    end;

    /// <summary>
    /// Opens a page displaying the invoice lines for this shipment line.
    /// </summary>
    procedure ShowItemSalesInvLines()
    var
        TempSalesInvLine: Record "Sales Invoice Line" temporary;
    begin
        if Type = Type::Item then begin
            GetSalesInvLines(TempSalesInvLine);
            PAGE.RunModal(PAGE::"Posted Sales Invoice Lines", TempSalesInvLine);
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
    /// Opens a page displaying the comments for this shipment line.
    /// </summary>
    procedure ShowLineComments()
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.ShowComments(SalesCommentLine."Document Type"::Shipment.AsInteger(), "Document No.", "Line No.");
    end;

    /// <summary>
    /// Shows the posted assembly order linked to this shipment line.
    /// </summary>
    procedure ShowAsmToOrder()
    begin
        PostedATOLink.ShowPostedAsm(Rec);
    end;

    /// <summary>
    /// Retrieves the shortcut dimension codes for this shipment line.
    /// </summary>
    /// <param name="ShortcutDimCode">Returns the array of shortcut dimension codes.</param>
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    /// <summary>
    /// Checks if a posted assembly order exists for this shipment line.
    /// </summary>
    /// <param name="PostedAsmHeader">Returns the posted assembly header if found.</param>
    /// <returns>Returns true if a linked assembly order exists.</returns>
    procedure AsmToShipmentExists(var PostedAsmHeader: Record "Posted Assembly Header"): Boolean
    var
        PostedAssembleToOrderLink: Record "Posted Assemble-to-Order Link";
    begin
        if not PostedAssembleToOrderLink.AsmExistsForPostedShipmentLine(Rec) then
            exit(false);
        exit(PostedAsmHeader.Get(PostedAssembleToOrderLink."Assembly Document No."));
    end;

    /// <summary>
    /// Initializes the sales shipment line from a sales line when posting a shipment.
    /// </summary>
    /// <param name="SalesShptHeader">The sales shipment header to link to.</param>
    /// <param name="SalesLine">The sales line to copy data from.</param>
    procedure InitFromSalesLine(SalesShptHeader: Record "Sales Shipment Header"; SalesLine: Record "Sales Line")
    begin
        Init();
        TransferFields(SalesLine);
        if ("No." = '') and HasTypeToFillMandatoryFields() then
            Type := Type::" ";
        "Posting Date" := SalesShptHeader."Posting Date";
        "Document No." := SalesShptHeader."No.";
        Quantity := SalesLine."Qty. to Ship";
        "Quantity (Base)" := SalesLine."Qty. to Ship (Base)";
        if Abs(SalesLine."Qty. to Invoice") > Abs(SalesLine."Qty. to Ship") then begin
            "Quantity Invoiced" := SalesLine."Qty. to Ship";
            "Qty. Invoiced (Base)" := SalesLine."Qty. to Ship (Base)";
        end else begin
            "Quantity Invoiced" := SalesLine."Qty. to Invoice";
            "Qty. Invoiced (Base)" := SalesLine."Qty. to Invoice (Base)";
        end;
        "Qty. Shipped Not Invoiced" := Quantity - "Quantity Invoiced";
        if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin
            "Order No." := SalesLine."Document No.";
            "Order Line No." := SalesLine."Line No.";
            "External Document No." := SalesShptHeader."External Document No.";
            "Your Reference" := SalesShptHeader."Your Reference";
        end;

        OnAfterInitFromSalesLine(SalesShptHeader, SalesLine, Rec);
    end;

    /// <summary>
    /// Clears quantity, amount, and related fields on a sales line when copying from shipment.
    /// </summary>
    /// <param name="SalesLine">The sales line to clear values from.</param>
    procedure ClearSalesLineValues(var SalesLine: Record "Sales Line")
    begin
        SalesLine."Quantity (Base)" := 0;
        SalesLine.Quantity := 0;
        SalesLine."Outstanding Qty. (Base)" := 0;
        SalesLine."Outstanding Quantity" := 0;
        SalesLine."Quantity Shipped" := 0;
        SalesLine."Qty. Shipped (Base)" := 0;
        SalesLine."Quantity Invoiced" := 0;
        SalesLine."Qty. Invoiced (Base)" := 0;
        SalesLine.Amount := 0;
        SalesLine."Amount Including VAT" := 0;
        SalesLine."Purchase Order No." := '';
        SalesLine."Purch. Order Line No." := 0;
        SalesLine."Special Order Purchase No." := '';
        SalesLine."Special Order Purch. Line No." := 0;
        SalesLine."Special Order" := false;
        SalesLine."Appl.-to Item Entry" := 0;
        SalesLine."Appl.-from Item Entry" := 0;

        OnAfterClearSalesLineValues(Rec, SalesLine);
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
    /// Calculates base quantity fields on a sales line using the specified quantity factor.
    /// </summary>
    /// <param name="SalesLine">The sales line to update base quantities on.</param>
    /// <param name="QtyFactor">The factor to multiply quantities by (typically qty per unit of measure).</param>
    procedure CalcBaseQuantities(var SalesLine: Record "Sales Line"; QtyFactor: Decimal)
    begin
        SalesLine."Quantity (Base)" :=
          Round(SalesLine.Quantity * QtyFactor, UOMMgt.QtyRndPrecision());
        SalesLine."Qty. to Asm. to Order (Base)" :=
          Round(SalesLine."Qty. to Assemble to Order" * QtyFactor, UOMMgt.QtyRndPrecision());
        SalesLine."Outstanding Qty. (Base)" :=
          Round(SalesLine."Outstanding Quantity" * QtyFactor, UOMMgt.QtyRndPrecision());
        SalesLine."Qty. to Ship (Base)" :=
          Round(SalesLine."Qty. to Ship" * QtyFactor, UOMMgt.QtyRndPrecision());
        SalesLine."Qty. Shipped (Base)" :=
          Round(SalesLine."Quantity Shipped" * QtyFactor, UOMMgt.QtyRndPrecision());
        SalesLine."Qty. Shipped Not Invd. (Base)" :=
          Round(SalesLine."Qty. Shipped Not Invoiced" * QtyFactor, UOMMgt.QtyRndPrecision());
        SalesLine."Qty. to Invoice (Base)" :=
          Round(SalesLine."Qty. to Invoice" * QtyFactor, UOMMgt.QtyRndPrecision());
        SalesLine."Qty. Invoiced (Base)" :=
          Round(SalesLine."Quantity Invoiced" * QtyFactor, UOMMgt.QtyRndPrecision());
        SalesLine."Return Qty. to Receive (Base)" :=
          Round(SalesLine."Return Qty. to Receive" * QtyFactor, UOMMgt.QtyRndPrecision());
        SalesLine."Return Qty. Received (Base)" :=
          Round(SalesLine."Return Qty. Received" * QtyFactor, UOMMgt.QtyRndPrecision());
        SalesLine."Ret. Qty. Rcd. Not Invd.(Base)" :=
          Round(SalesLine."Return Qty. Rcd. Not Invd." * QtyFactor, UOMMgt.QtyRndPrecision());
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Sales Shipment Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    /// <summary>
    /// Retrieves the caption class for a specified field.
    /// </summary>
    /// <param name="FieldNumber">The field number to get the caption class for.</param>
    /// <returns>The caption class string for the field.</returns>
    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    begin
        case FieldNumber of
            FieldNo("No."):
                exit(StrSubstNo('3,%1', GetFieldCaption(FieldNumber)));
        end;
    end;

    /// <summary>
    /// Determines whether the line has a type that requires mandatory fields to be filled.
    /// </summary>
    /// <returns>Returns true if the line type is not blank.</returns>
    procedure HasTypeToFillMandatoryFields(): Boolean
    begin
        exit(Type <> Type::" ");
    end;

    local procedure UpdateDocumentId()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        if "Document No." = '' then begin
            Clear("Document Id");
            exit;
        end;

        SalesShipmentHeader.SetLoadFields("No.", SystemId);
        if not SalesShipmentHeader.Get("Document No.") then
            exit;

        "Document Id" := SalesShipmentHeader.SystemId;
    end;


    local procedure UpdateDocumentNo()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        if IsNullGuid(Rec."Document Id") then begin
            Clear(Rec."Document No.");
            exit;
        end;

        SalesShipmentHeader.SetLoadFields("No.", SystemId);
        if not SalesShipmentHeader.GetBySystemId(Rec."Document Id") then
            exit;

        "Document No." := SalesShipmentHeader."No.";
    end;

    /// <summary>
    /// Updates the referenced IDs such as Document Id for API integrations.
    /// </summary>
    procedure UpdateReferencedIds()
    begin
        UpdateDocumentId();
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
    /// Raised after clearing sales line values from the sales shipment line.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line record.</param>
    /// <param name="SalesLine">The sales line with cleared values.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterClearSalesLineValues(var SalesShipmentLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised after inserting a description sales line from the shipment line.
    /// </summary>
    /// <param name="SalesLine">The inserted description sales line.</param>
    /// <param name="SalesShipmentLine">The source sales shipment line.</param>
    /// <param name="NextLineNo">The next line number after insertion.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterDescriptionSalesLineInsert(var SalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line"; var NextLineNo: Integer)
    begin
    end;

    /// <summary>
    /// Raised after initializing the sales shipment line from a sales line.
    /// </summary>
    /// <param name="SalesShptHeader">The sales shipment header record.</param>
    /// <param name="SalesLine">The source sales line.</param>
    /// <param name="SalesShptLine">The sales shipment line being initialized.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesLine(SalesShptHeader: Record "Sales Shipment Header"; SalesLine: Record "Sales Line"; var SalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised after inserting an invoice line from a shipment line.
    /// </summary>
    /// <param name="SalesLine">The inserted sales invoice line.</param>
    /// <param name="SalesOrderLine">The related sales order line.</param>
    /// <param name="NextLineNo">The next line number after insertion.</param>
    /// <param name="SalesShipmentLine">The source sales shipment line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvLineFromShptLine(var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; var NextLineNo: Integer; var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised before calculating the shipped sales quantity not returned.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line record.</param>
    /// <param name="ShippedQtyNotReturned">The shipped quantity not returned.</param>
    /// <param name="RevUnitCostLCY">The reverse unit cost in local currency.</param>
    /// <param name="ExactCostReverse">Specifies whether exact cost reversing is enabled.</param>
    /// <param name="IsHandled">Set to true to skip default calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcShippedSaleNotReturned(var SalesShipmentLine: Record "Sales Shipment Line"; var ShippedQtyNotReturned: Decimal; var RevUnitCostLCY: Decimal; ExactCostReverse: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting an invoice line from a shipment line.
    /// </summary>
    /// <param name="SalesShptLine">The source sales shipment line.</param>
    /// <param name="SalesLine">The sales invoice line to be inserted.</param>
    /// <param name="SalesOrderLine">The related sales order line.</param>
    /// <param name="IsHandled">Set to true to skip default insertion.</param>
    /// <param name="TransferOldExtTextLines">The codeunit for transferring extended text lines.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromShptLine(var SalesShptLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean; var TransferOldExtTextLines: Codeunit "Transfer Old Ext. Text Lines")
    begin
    end;

    /// <summary>
    /// Raised before inserting a text line when inserting an invoice line from a shipment line.
    /// </summary>
    /// <param name="SalesShptLine">The source sales shipment line.</param>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="NextLineNo">The next line number to use.</param>
    /// <param name="Handled">Set to true to skip default text line insertion.</param>
    /// <param name="TempSalesLine">Temporary sales line buffer.</param>
    /// <param name="SalesInvHeader">The sales invoice header.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertInvLineFromShptLineBeforeInsertTextLine(var SalesShptLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line"; var NextLineNo: Integer; var Handled: Boolean; TempSalesLine: Record "Sales Line" temporary; SalesInvHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised before the code section of InsertInvLineFromShptLine executes.
    /// </summary>
    /// <param name="SalesShipmentLine">The source sales shipment line.</param>
    /// <param name="SalesLine">The sales invoice line to be created.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCodeInsertInvLineFromShptLine(var SalesShipmentLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after getting the sales order header during InsertInvLineFromShptLine.
    /// </summary>
    /// <param name="SalesOrderHeader">The sales order header record.</param>
    /// <param name="SalesInvHeader">The sales invoice header record.</param>
    /// <param name="SalesOrderLine">The sales order line record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnAfterSalesOrderHeaderGet(var SalesOrderHeader: Record "Sales Header"; var SalesInvHeader: Record "Sales Header"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised after assigning the description during InsertInvLineFromShptLine.
    /// </summary>
    /// <param name="SalesShipmentLine">The source sales shipment line.</param>
    /// <param name="SalesOrderLine">The sales order line with the assigned description.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnAfterAssignDescription(var SalesShipmentLine: Record "Sales Shipment Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised after calculating quantities during InsertInvLineFromShptLine.
    /// </summary>
    /// <param name="SalesLine">The sales invoice line with calculated quantities.</param>
    /// <param name="SalesOrderLine">The source sales order line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnAfterCalcQuantities(var SalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised after updating prepayment amounts during InsertInvLineFromShptLine.
    /// </summary>
    /// <param name="SalesLine">The sales invoice line with updated prepayment amounts.</param>
    /// <param name="SalesOrderLine">The source sales order line.</param>
    /// <param name="SalesShipmentLine">The sales shipment line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnAfterUpdatePrepaymentsAmounts(var SalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line"; var SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    /// <summary>
    /// Raised before validating quantity during InsertInvLineFromShptLine.
    /// </summary>
    /// <param name="SalesShipmentLine">The source sales shipment line.</param>
    /// <param name="SalesLine">The sales invoice line to validate.</param>
    /// <param name="IsHandled">Set to true to skip default quantity validation.</param>
    /// <param name="SalesInvHeader">The sales invoice header.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnBeforeValidateQuantity(var SalesShipmentLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var SalesInvHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised before inserting a description line during InsertInvLineFromShptLine.
    /// </summary>
    /// <param name="SalesShipmentLine">The source sales shipment line.</param>
    /// <param name="SalesLine">The sales invoice line.</param>
    /// <param name="TempSalesLine">Temporary sales line buffer.</param>
    /// <param name="SalesInvHeader">The sales invoice header.</param>
    /// <param name="NextLineNo">The next line number to use.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnBeforeInsertDescriptionLine(SalesShipmentLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line"; TempSalesLine: Record "Sales Line" temporary; var SalesInvHeader: Record "Sales Header"; var NextLineNo: integer)
    begin
    end;

    /// <summary>
    /// Raised after validating invoice discount amount during InsertInvLineFromShptLine.
    /// </summary>
    /// <param name="SalesLine">The sales invoice line with validated discount.</param>
    /// <param name="SalesOrderLine">The source sales order line.</param>
    /// <param name="SalesShipmentLine">The sales shipment line.</param>
    /// <param name="SalesInvHeader">The sales invoice header.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnAfterValidateInvDiscountAmount(var SalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line"; SalesInvHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised after inserting all lines during InsertInvLineFromShptLine.
    /// </summary>
    /// <param name="SalesShipmentLine">The source sales shipment line.</param>
    /// <param name="SalesLine">The last inserted sales invoice line.</param>
    /// <param name="IsHandled">Set to true to skip additional processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnAfterInsertAllLines(var SalesShipmentLine: Record "Sales Shipment Line"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before setting security filter on responsibility center for the sales shipment line.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line record.</param>
    /// <param name="IsHandled">Set to true to skip default security filter application.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before assigning the sales line during InsertInvLineFromShptLine.
    /// </summary>
    /// <param name="SalesShipmentLine">The source sales shipment line.</param>
    /// <param name="SalesHeaderInv">The sales invoice header.</param>
    /// <param name="SalesHeaderOrder">The sales order header.</param>
    /// <param name="SalesLine">The sales invoice line to be assigned.</param>
    /// <param name="SalesOrderLine">The source sales order line.</param>
    /// <param name="Currency">The currency record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnBeforeAssigneSalesLine(var SalesShipmentLine: Record "Sales Shipment Line"; SalesHeaderInv: Record "Sales Header"; SalesHeaderOrder: Record "Sales Header"; var SalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line"; Currency: Record Currency)
    begin
    end;

    /// <summary>
    /// Raised before getting the sales header during InsertInvLineFromShptLine.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="SalesShipmentLine">The source sales shipment line.</param>
    /// <param name="TempSalesLine">Temporary sales line buffer.</param>
    /// <param name="IsHandled">Set to true to skip default header retrieval.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertInvLineFromShptLineOnBeforeSalesHeaderGet(var SalesHeader: Record "Sales Header"; SalesShipmentLine: Record "Sales Shipment Line"; var TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before getting the sales invoice line during GetSalesInvLines.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line record with filters applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetSalesInvLinesOnBeforeGetSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line")
    begin
    end;

    /// <summary>
    /// Raised before showing item tracking lines for the sales shipment line.
    /// </summary>
    /// <param name="SalesShipmentLine">The sales shipment line record.</param>
    /// <param name="IsHandled">Set to true to skip default item tracking display.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemTrackingLines(var SalesShipmentLine: Record "Sales Shipment Line"; var IsHandled: Boolean)
    begin
    end;
}
