// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Reflection;

table 5110 "Purchase Line Archive"
{
    Caption = 'Purchase Line Archive';
    PasteIsValid = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Purchase Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of purchase document.';
        }
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            ToolTip = 'Specifies the name of the vendor who delivered the items.';
            TableRelation = Vendor;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number.';
            TableRelation = "Purchase Header Archive"."No." where("Document Type" = field("Document Type"),
                                                                   "Version No." = field("Version No."));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the number of the line.';
        }
        field(5; Type; Enum "Purchase Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the line type.';
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge";
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = if (Type = const(Item)) "Inventory Posting Group"
            else
            if (Type = const("Fixed Asset")) "FA Posting Group";
        }
        field(10; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            ToolTip = 'Specifies the date you expect the items to be available in your warehouse. If you leave the field blank, it will be calculated as follows: Planned Receipt Date + Safety Lead Time + Inbound Warehouse Handling Time = Expected Receipt Date.';
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the record.';
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies information in addition to the description.';
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
            ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
        }
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity of the record.';
            DecimalPlaces = 0 : 5;
        }
        field(16; "Outstanding Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Outstanding Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Qty. to Invoice"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Invoice';
            ToolTip = 'Specifies the quantity that remains to be invoiced. It is calculated as Quantity - Qty. Invoiced.';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Qty. to Receive"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Qty. to Receive';
            ToolTip = 'Specifies the quantity of items that remains to be received.';
            DecimalPlaces = 0 : 5;
        }
        field(22; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FieldNo("Direct Unit Cost"));
            Caption = 'Direct Unit Cost';
            ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost (LCY)';
        }
        field(25; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
        }
        field(26; "Quantity Disc. %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity Disc. %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(27; "Line Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Line Discount %';
            ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
            ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the sum of amounts in the Line Amount field on the purchase lines.';
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            ToolTip = 'Specifies the net amount, including VAT, for this line.';
        }
        field(31; "Unit Price (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Price (LCY)';
        }
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
            InitValue = true;
        }
        field(34; "Gross Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Gross Weight';
            ToolTip = 'Specifies the gross weight of one unit of the item. In the purchase statistics window, the gross weight on the line is included in the total gross weight of all the lines for the particular purchase document.';
            DecimalPlaces = 0 : 5;
        }
        field(35; "Net Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Net Weight';
            ToolTip = 'Specifies the net weight of one unit of the item. In the purchase statistics window, the net weight on the line is included in the total net weight of all the lines for the particular purchase document.';
            DecimalPlaces = 0 : 5;
        }
        field(36; "Units per Parcel"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Units per Parcel';
            ToolTip = 'Specifies the number of units per parcel of the item. In the purchase statistics window, the number of units per parcel on the line helps to determine the total number of units for all the lines for the particular purchase document.';
            DecimalPlaces = 0 : 5;
        }
        field(37; "Unit Volume"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit Volume';
            ToolTip = 'Specifies the volume of one unit of the item. In the purchase statistics window, the volume of one unit of the item on the line is included in the total volume of all the lines for the particular purchase document.';
            DecimalPlaces = 0 : 5;
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';
            ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the project number that the archived document was linked to.';
            TableRelation = Job;
        }
        field(54; "Indirect Cost %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Indirect Cost %';
            ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(57; "Outstanding Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Outstanding Amount';
        }
        field(58; "Qty. Rcd. Not Invoiced"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Rcd. Not Invoiced';
            DecimalPlaces = 0 : 5;
        }
        field(59; "Amt. Rcd. Not Invoiced"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amt. Rcd. Not Invoiced';
        }
        field(60; "Quantity Received"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Quantity Received';
            ToolTip = 'Specifies how many units of the item on the line have been posted as received.';
            DecimalPlaces = 0 : 5;
        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity Invoiced';
            ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
            DecimalPlaces = 0 : 5;
        }
        field(63; "Receipt No."; Code[20])
        {
            Caption = 'Receipt No.';
        }
        field(64; "Receipt Line No."; Integer)
        {
            Caption = 'Receipt Line No.';
        }
        field(67; "Profit %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Profit %';
            DecimalPlaces = 0 : 5;
        }
        field(68; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            TableRelation = Vendor;
        }
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
        }
        field(70; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(71; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            TableRelation = if ("Drop Shipment" = const(true)) "Sales Header"."No." where("Document Type" = const(Order));
        }
        field(72; "Sales Order Line No."; Integer)
        {
            Caption = 'Sales Order Line No.';
            TableRelation = if ("Drop Shipment" = const(true)) "Sales Line"."Line No." where("Document Type" = const(Order),
                                                                                            "Document No." = field("Sales Order No."));
        }
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            ToolTip = 'Specifies if your vendor ships the items directly to your customer.';
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Business Posting Group";
        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
        }
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
            TableRelation = "Purchase Line Archive"."Line No." where("Document Type" = field("Document Type"),
                                                                      "Document No." = field("Document No."),
                                                                      "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                      "Version No." = field("Version No."));
        }
        field(81; "Entry Point"; Code[10])
        {
            Caption = 'Entry Point';
            TableRelation = "Entry/Exit Point";
        }
        field(82; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
            TableRelation = "Tax Area";
        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if this vendor charges you sales tax for purchases.';
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
            TableRelation = "Tax Group";
        }
        field(88; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';
            ToolTip = 'Specifies a U.S. sales tax that is paid on items purchased by a company that are used by the company, instead of being sold to a customer.';
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Business Posting Group";
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Product Posting Group";
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(92; "Outstanding Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Outstanding Amount (LCY)';
        }
        field(93; "Amt. Rcd. Not Invoiced (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amt. Rcd. Not Invoiced (LCY)';
        }
        field(97; "Blanket Order No."; Code[20])
        {
            Caption = 'Blanket Order No.';
            ToolTip = 'Specifies the number of the blanket order that the record originates from.';
            TableRelation = "Purchase Header"."No." where("Document Type" = const("Blanket Order"));
        }
        field(98; "Blanket Order Line No."; Integer)
        {
            Caption = 'Blanket Order Line No.';
            ToolTip = 'Specifies the number of the blanket order line that the record originates from.';
            TableRelation = "Purchase Line"."Line No." where("Document Type" = const("Blanket Order"),
                                                              "Document No." = field("Blanket Order No."));
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
        }
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Line Amount"));
            Caption = 'Line Amount';
            ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
        }
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
        }
        field(105; "Inv. Disc. Amount to Invoice"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Disc. Amount to Invoice';
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
        }
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
        }
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
        }
        field(109; "Prepayment %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(110; "Prepmt. Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt. Line Amount"));
            Caption = 'Prepmt. Line Amount';
            MinValue = 0;
        }
        field(111; "Prepmt. Amt. Inv."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt. Amt. Inv."));
            Caption = 'Prepmt. Amt. Inv.';
            Editable = false;
        }
        field(112; "Prepmt. Amt. Incl. VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amt. Incl. VAT';
            Editable = false;
        }
        field(113; "Prepayment Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepayment Amount';
            Editable = false;
        }
        field(114; "Prepmt. VAT Base Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. VAT Base Amt.';
            Editable = false;
        }
        field(115; "Prepayment VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepayment VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(116; "Prepmt. VAT Calc. Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Prepmt. VAT Calc. Type';
            Editable = false;
        }
        field(117; "Prepayment VAT Identifier"; Code[20])
        {
            Caption = 'Prepayment VAT Identifier';
            Editable = false;
        }
        field(118; "Prepayment Tax Area Code"; Code[20])
        {
            Caption = 'Prepayment Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(119; "Prepayment Tax Liable"; Boolean)
        {
            Caption = 'Prepayment Tax Liable';
        }
        field(120; "Prepayment Tax Group Code"; Code[20])
        {
            Caption = 'Prepayment Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(121; "Prepmt Amt to Deduct"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt Amt to Deduct"));
            Caption = 'Prepmt Amt to Deduct';
            MinValue = 0;
        }
        field(122; "Prepmt Amt Deducted"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt Amt Deducted"));
            Caption = 'Prepmt Amt Deducted';
            Editable = false;
        }
        field(123; "Prepayment Line"; Boolean)
        {
            Caption = 'Prepayment Line';
            Editable = false;
        }
        field(124; "Prepmt. Amount Inv. Incl. VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amount Inv. Incl. VAT';
            Editable = false;
        }
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
        }
        field(145; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Amount';
        }
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
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the number of the related project task.';
            Editable = false;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(1002; "Job Line Type"; Enum "Job Line Type")
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Line Type';
            ToolTip = 'Specifies the type of planning line that was created when the project ledger entry is posted from the purchase line. If the field is empty, no planning lines were created for this entry.';
        }
        field(1003; "Job Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = "Job Currency Code";
            AccessByPermission = TableData Job = R;
            Caption = 'Project Unit Price';
            ToolTip = 'Specifies the sales price per unit that applies to the item or general ledger expense that will be posted.';
        }
        field(1004; "Job Total Price"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Job Currency Code";
            AccessByPermission = TableData Job = R;
            Caption = 'Project Total Price';
            ToolTip = 'Specifies the gross amount of the line that the purchase line applies to.';
        }
        field(1005; "Job Line Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            AutoFormatExpression = "Job Currency Code";
            Caption = 'Project Line Amount';
            ToolTip = 'Specifies the line amount of the project ledger entry that is related to the purchase line.';
        }
        field(1006; "Job Line Discount Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            AutoFormatExpression = "Job Currency Code";
            Caption = 'Project Line Discount Amount';
            ToolTip = 'Specifies the line discount amount of the project ledger entry that is related to the purchase line.';
        }
        field(1007; "Job Line Discount %"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData Job = R;
            Caption = 'Project Line Discount %';
            ToolTip = 'Specifies the line discount percentage of the project ledger entry that is related to the purchase line.';
            DecimalPlaces = 0 : 5;
        }
        field(1008; "Job Unit Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Unit Price (LCY)';
            AutoFormatType = 2;
            AutoFormatExpression = '';
        }
        field(1009; "Job Total Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Total Price (LCY)';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(1010; "Job Line Amount (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Line Amount (LCY)';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(1011; "Job Line Disc. Amount (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Line Disc. Amount (LCY)';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(1012; "Job Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Project Currency Factor';
        }
        field(1013; "Job Currency Code"; Code[20])
        {
            Caption = 'Project Currency Code';
        }
        field(1019; "Job Planning Line No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Planning Line No.';
            ToolTip = 'Specifies the project planning line number to which the usage should be linked when the Project Journal is posted. You can only link to Project Planning Lines that have the Apply Usage Link option enabled.';
        }
        field(1030; "Job Remaining Qty."; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData Job = R;
            Caption = 'Project Remaining Qty.';
            DecimalPlaces = 0 : 5;
        }
        field(1031; "Job Remaining Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Project Remaining Qty. (Base)';
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            ToolTip = 'Specifies the deferral template that governs how expenses paid with this purchase document are deferred to the different accounting periods when the expenses were incurred.';
            TableRelation = "Deferral Template"."Deferral Code";
        }
        field(1702; "Returns Deferral Start Date"; Date)
        {
            Caption = 'Returns Deferral Start Date';
            ToolTip = 'Specifies the starting date of the returns deferral period.';
        }
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";
        }
        field(5415; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5416; "Outstanding Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5417; "Qty. to Invoice (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5418; "Qty. to Receive (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Receive (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5458; "Qty. Rcd. Not Invoiced (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Rcd. Not Invoiced (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5460; "Qty. Received (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Received (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        field(5601; "FA Posting Type"; Enum "Purchase FA Posting Type")
        {
            Caption = 'FA Posting Type';
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(5603; "Salvage Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Salvage Value';
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
        }
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            Caption = 'Depr. Acquisition Cost';
        }
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;
        }
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;
        }
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            TableRelation = "Fixed Asset";
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5710; Nonstock; Boolean)
        {
            Caption = 'Catalog';
            ToolTip = 'Specifies that this item is a catalog item.';
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;
        }
        field(5713; "Special Order"; Boolean)
        {
            Caption = 'Special Order';
        }
        field(5714; "Special Order Sales No."; Code[20])
        {
            Caption = 'Special Order Sales No.';
            TableRelation = if ("Special Order" = const(true)) "Sales Header"."No." where("Document Type" = const(Order));
        }
        field(5715; "Special Order Sales Line No."; Integer)
        {
            Caption = 'Special Order Sales Line No.';
            TableRelation = if ("Special Order" = const(true)) "Sales Line"."Line No." where("Document Type" = const(Order),
                                                                                            "Document No." = field("Special Order Sales No."));
        }
        field(5725; "Item Reference No."; Code[50])
        {
            Caption = 'Item Reference No.';
            ToolTip = 'Specifies the referenced item number.';
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            Caption = 'Reference Unit of Measure';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
        }
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
        }
        field(5752; "Completely Received"; Boolean)
        {
            Caption = 'Completely Received';
        }
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
            ToolTip = 'Specifies the requested date of receipt for the purchase return order.';
        }
        field(5791; "Promised Receipt Date"; Date)
        {
            Caption = 'Promised Receipt Date';
            ToolTip = 'Specifies the date that the vendor has promised to deliver the order.';
        }
        field(5792; "Lead Time Calculation"; DateFormula)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lead Time Calculation';
            ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
        }
        field(5793; "Inbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Inbound Whse. Handling Time';
            ToolTip = 'Specifies the time it takes to make items part of available inventory, after the items have been posted as received.';
        }
        field(5794; "Planned Receipt Date"; Date)
        {
            Caption = 'Planned Receipt Date';
            ToolTip = 'Specifies the date when the item is planned to arrive in inventory. Forward calculation: planned receipt date = order date + vendor lead time (per the vendor calendar and rounded to the next working day in first the vendor calendar and then the location calendar). If no vendor calendar exists, then: planned receipt date = order date + vendor lead time (per the location calendar). Backward calculation: order date = planned receipt date - vendor lead time (per the vendor calendar and rounded to the previous working day in first the vendor calendar and then the location calendar). If no vendor calendar exists, then: order date = planned receipt date - vendor lead time (per the location calendar).';
        }
        field(5795; "Order Date"; Date)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Order Date';
            ToolTip = 'Specifies the date when the order was created.';
        }
        field(5800; "Allow Item Charge Assignment"; Boolean)
        {
            AccessByPermission = TableData "Item Charge" = R;
            Caption = 'Allow Item Charge Assignment';
            ToolTip = 'Specifies that you can assign item charges to this line.';
            InitValue = true;
        }
        field(5803; "Return Qty. to Ship"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Return Qty. to Ship';
            ToolTip = 'Specifies the quantity of items that remains to be shipped.';
            DecimalPlaces = 0 : 5;
        }
        field(5804; "Return Qty. to Ship (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Return Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5805; "Return Qty. Shipped Not Invd."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Return Qty. Shipped Not Invd.';
            DecimalPlaces = 0 : 5;
        }
        field(5806; "Ret. Qty. Shpd Not Invd.(Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Ret. Qty. Shpd Not Invd.(Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5807; "Return Shpd. Not Invd."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Return Shpd. Not Invd.';
        }
        field(5808; "Return Shpd. Not Invd. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Return Shpd. Not Invd. (LCY)';
        }
        field(5809; "Return Qty. Shipped"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Return Qty. Shipped';
            ToolTip = 'Specifies how many units of the item on the line have been posted as shipped.';
            DecimalPlaces = 0 : 5;
        }
        field(5810; "Return Qty. Shipped (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Return Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
        }
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Base';
        }
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Amount';
        }
        field(6203; "Non-Deductible VAT Diff."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Difference';
        }
        field(6600; "Return Shipment No."; Code[20])
        {
            Caption = 'Return Shipment No.';
        }
        field(6601; "Return Shipment Line No."; Integer)
        {
            Caption = 'Return Shipment Line No.';
            Editable = false;
        }
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            ToolTip = 'Specifies the code explaining why the item was returned.';
            TableRelation = "Return Reason";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(12100; "No. of Fixed Asset Cards"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Fixed Asset Cards';
            ToolTip = 'Specifies the number of fixed assets that is being purchased.';
            MinValue = 0;
        }
        field(99000755; "Overhead Rate"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;
        }
        field(99000756; "MPS Order"; Boolean)
        {
            Caption = 'MPS Order';
        }
        field(99000757; "Planning Flexibility"; Enum "Reservation Planning Flexibility")
        {
            Caption = 'Planning Flexibility';
            ToolTip = 'Specifies whether the supply represented by this line is considered by the planning system when calculating action messages.';
        }
        field(99000758; "Safety Lead Time"; DateFormula)
        {
            Caption = 'Safety Lead Time';
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
        key(Key3; "Buy-from Vendor No.")
        {
        }
        key(Key4; "Pay-to Vendor No.")
        {
        }
        key(Key5; "Document No.", "Document Type", "Doc. No. Occurrence", "Version No.")
        {
            IncludedFields = Amount, "Amount Including VAT";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Document No.", "Line No.", "Version No.", "Buy-from Vendor No.")
        {
        }
    }

    trigger OnDelete()
    var
        PurchCommentLineArchive: Record "Purch. Comment Line Archive";
        DeferralHeaderArchive: Record "Deferral Header Archive";
    begin
        PurchCommentLineArchive.SetRange("Document Type", Rec."Document Type");
        PurchCommentLineArchive.SetRange("No.", Rec."Document No.");
        PurchCommentLineArchive.SetRange("Document Line No.", Rec."Line No.");
        PurchCommentLineArchive.SetRange("Doc. No. Occurrence", Rec."Doc. No. Occurrence");
        PurchCommentLineArchive.SetRange("Version No.", Rec."Version No.");
        if not PurchCommentLineArchive.IsEmpty() then
            PurchCommentLineArchive.DeleteAll();

        if Rec."Deferral Code" <> '' then
            DeferralHeaderArchive.DeleteHeader(
                "Deferral Document Type"::Purchase.AsInteger(),
                Rec."Document Type".AsInteger(), Rec."Document No.", Rec."Doc. No. Occurrence", Rec."Version No.", Rec."Line No.");
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        DeferralUtilities: Codeunit "Deferral Utilities";

    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        if not PurchaseHeaderArchive.Get("Document Type", "Document No.", "Doc. No. Occurrence", "Version No.") then begin
            PurchaseHeaderArchive."No." := '';
            PurchaseHeaderArchive.Init();
        end;
        if PurchaseHeaderArchive."Prices Including VAT" then
            exit(CopyStr('2,1,' + GetFieldCaption(FieldNumber), 1, 80));

        exit(CopyStr('2,0,' + GetFieldCaption(FieldNumber), 1, 80));
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Purchase Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    procedure IsExtendedText(): Boolean
    begin
        exit((Type = Type::" ") and ("Attached to Line No." <> 0) and (Quantity = 0));
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "Document No."));
    end;

    procedure ShowLineComments()
    var
        PurchCommentLineArch: Record "Purch. Comment Line Archive";
        PurchArchCommentSheet: Page "Purch. Archive Comment Sheet";
    begin
        PurchCommentLineArch.SetRange("Document Type", "Document Type");
        PurchCommentLineArch.SetRange("No.", "Document No.");
        PurchCommentLineArch.SetRange("Document Line No.", "Line No.");
        PurchCommentLineArch.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        PurchCommentLineArch.SetRange("Version No.", "Version No.");
        Clear(PurchArchCommentSheet);
        PurchArchCommentSheet.SetTableView(PurchCommentLineArch);
        PurchArchCommentSheet.RunModal();
    end;

    procedure ShowDeferrals()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDeferrals(Rec, IsHandled);
        if IsHandled then
            exit;

        DeferralUtilities.OpenLineScheduleArchive(
            "Deferral Code", "Deferral Document Type"::Purchase.AsInteger(),
            "Document Type".AsInteger(), "Document No.", "Doc. No. Occurrence", "Version No.", "Line No.");
    end;

    procedure CopyTempLines(PurchaseHeaderArchive: Record "Purchase Header Archive"; var TempPurchaseLine: Record "Purchase Line" temporary)
    var
        PurchaseLineArchive: Record "Purchase Line Archive";
    begin
        DeleteAll();

        PurchaseLineArchive.SetRange("Document Type", PurchaseHeaderArchive."Document Type");
        PurchaseLineArchive.SetRange("Document No.", PurchaseHeaderArchive."No.");
        PurchaseLineArchive.SetRange("Version No.", PurchaseHeaderArchive."Version No.");
        PurchaseLineArchive.SetRange("Doc. No. Occurrence", PurchaseHeaderArchive."Doc. No. Occurrence");
        if PurchaseLineArchive.FindSet() then
            repeat
                Init();
                Rec := PurchaseLineArchive;
                Insert();
                TempPurchaseLine.TransferFields(PurchaseLineArchive);
                TempPurchaseLine.Insert();
            until PurchaseLineArchive.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeferrals(PurchaseLineArchive: Record "Purchase Line Archive"; var IsHandled: Boolean)
    begin
    end;
}
