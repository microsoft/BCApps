// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
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
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Structure;
using System.Reflection;
using System.Security.User;

table 123 "Purch. Inv. Line"
{
    Caption = 'Purch. Inv. Line';
    DrillDownPageID = "Posted Purchase Invoice Lines";
    LookupPageID = "Posted Purchase Invoice Lines";
    Permissions = TableData "Item Ledger Entry" = r,
                  TableData "Value Entry" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            ToolTip = 'Specifies the name of the vendor who delivered the items.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number.';
            TableRelation = "Purch. Inv. Header";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
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
            TableRelation = if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge"
            else
            if (Type = const(Resource)) Resource;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the code for the location where the invoice line is registered.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = if (Type = const(Item)) "Inventory Posting Group"
            else
            if (Type = const("Fixed Asset")) "FA Posting Group";
        }
        field(10; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            ToolTip = 'Specifies the date when the items were expected.';
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies either the name of, or a description of, the item or general ledger account.';
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
            ToolTip = 'Specifies the quantity posted from the line.';
            DecimalPlaces = 0 : 5;
        }
        field(22; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
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
            ToolTip = 'Specifies the VAT %.';
            DecimalPlaces = 0 : 5;
            Editable = false;
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
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
            ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the line''s net amount.';
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
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
            ToolTip = 'Specifies the number of the related project.';
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
        field(63; "Receipt No."; Code[20])
        {
            Caption = 'Receipt No.';
            Editable = false;
        }
        field(64; "Receipt Line No."; Integer)
        {
            Caption = 'Receipt Line No.';
            Editable = false;
        }
        field(65; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            ToolTip = 'Specifies the order number this line is associated with.';
        }
        field(66; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(68; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
        }
        field(70; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
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
            TableRelation = "Purch. Inv. Line"."Line No." where("Document No." = field("Document No."));
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
            ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
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
            ToolTip = 'Specifies that the purchase is subject to use tax. Use tax is a sales tax that is paid on items that are purchased by a company and are used by that company instead of being sold to a customer.';
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
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Line Amount"));
            Caption = 'Line Amount';
            ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
        }
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Difference';
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
        }
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
        }
        field(123; "Prepayment Line"; Boolean)
        {
            Caption = 'Prepayment Line';
            Editable = false;
        }
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
            TableRelation = "IC Partner";
        }
        field(131; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(138; "IC Cross-Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
        }
        field(145; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
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
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(1002; "Job Line Type"; Enum "Job Line Type")
        {
            Caption = 'Project Line Type';
        }
        field(1003; "Job Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = "Job Currency Code";
            BlankZero = true;
            Caption = 'Project Unit Price';
        }
        field(1004; "Job Total Price"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Job Currency Code";
            BlankZero = true;
            Caption = 'Project Total Price';
        }
        field(1005; "Job Line Amount"; Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Project Line Amount';
        }
        field(1006; "Job Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Project Line Discount Amount';
        }
        field(1007; "Job Line Discount %"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Project Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(1008; "Job Unit Price (LCY)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Project Unit Price (LCY)';
            AutoFormatType = 2;
            AutoFormatExpression = '';
        }
        field(1009; "Job Total Price (LCY)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Project Total Price (LCY)';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(1010; "Job Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Project Line Amount (LCY)';
        }
        field(1011; "Job Line Disc. Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Project Line Disc. Amount (LCY)';
        }
        field(1012; "Job Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
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
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            ToolTip = 'Specifies the deferral template that governs how expenses paid with this purchase document are deferred to the different accounting periods when the expenses were incurred.';
            TableRelation = "Deferral Template"."Deferral Code";
        }
        field(2678; "Allocation Account No."; Code[20])
        {
            Caption = 'Allocation Account No.';
            DataClassification = CustomerContent;
        }
        field(2679; "Alloc. Purch. Line SystemId"; Guid)
        {
            Caption = 'Allocation Purchase Line SystemId';
            DataClassification = SystemMetadata;
        }
        field(2701; "Matched Order Lines"; Integer)
        {
            BlankZero = true;
            CalcFormula = count("Posted Matched Order Line" where("Document Line SystemId" = field(SystemId), "Matched Rcpt./Shpt. Line SysId" = const('00000000-0000-0000-0000-000000000000')));
            Caption = 'Matched Order Lines';
            Editable = false;
            FieldClass = FlowField;
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
            ToolTip = 'Specifies the bin where the items are picked or put away.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"),
                                            "Item Filter" = field("No."),
                                            "Variant Filter" = field("Variant Code"));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
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
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        field(5601; "FA Posting Type"; Enum "Purchase FA Posting Type")
        {
            Caption = 'FA Posting Type';
            ToolTip = 'Specifies the posting type, if Account Type field contains Fixed Asset.';
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
            TableRelation = "Depreciation Book";
        }
        field(5603; "Salvage Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Job Currency Code";
            Caption = 'Salvage Value';
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            Caption = 'Depr. until FA Posting Date';
            ToolTip = 'Specifies if depreciation was calculated until the FA posting date of the line.';
        }
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            Caption = 'Depr. Acquisition Cost';
            ToolTip = 'Specifies if, when this line was posted, the additional acquisition cost posted on the line was depreciated in proportion to the amount by which the fixed asset had already been depreciated.';
        }
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;
        }
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            ToolTip = 'Specifies the insurance number on the purchase invoice line.';
            TableRelation = Insurance;
        }
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            ToolTip = 'Specifies the number of a fixed asset with the Budgeted Asset check box selected. When you post the journal or document line, an additional entry is created for the budgeted fixed asset where the amount has the opposite sign.';
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
            TableRelation = if (Type = const(Item)) "Item Category";
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
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
            ToolTip = 'Specifies the referenced item number.';
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure (Item Ref.)';
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
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;
        }
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Job Currency Code";
            Caption = 'Non-Deductible VAT Base';
            ToolTip = 'Specifies the amount of VAT that is not deducted due to the type of goods or services purchased.';
        }
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Job Currency Code";
            Caption = 'Non-Deductible VAT Amount';
            ToolTip = 'Specifies the amount of the transaction for which VAT is not applied, due to the type of goods or services purchased.';
        }
        field(6203; "Non-Deductible VAT Diff."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Job Currency Code";
            Caption = 'Non-Deductible VAT Difference';
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
        field(8512; "Buy-from Vendor Name"; Text[100])
        {
            CalcFormula = lookup(Vendor.Name where("No." = field("Buy-from Vendor No.")));
            Caption = 'Buy-from Vendor Name';
            ToolTip = 'Specifies the name of the vendor who delivered the items.';
            Editable = false;
            FieldClass = FlowField;
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
        key(Key3; Type, "No.", "Variant Code")
        {
            IncludedFields = "Quantity (Base)";
        }
        key(Key4; "Buy-from Vendor No.")
        {
        }
        key(Key5; "Order No.", "Order Line No.", "Posting Date")
        {
        }
        key(Key6; "Document No.", "Location Code")
        {
            IncludedFields = Amount, "Amount Including VAT", "Inv. Discount Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PurchDocLineComments: Record "Purch. Comment Line";
        PostedDeferralHeader: Record "Posted Deferral Header";
        MatchedOrderLineMgmt: Codeunit "Matched Order Line Mgmt.";
    begin
        PurchDocLineComments.SetRange("Document Type", PurchDocLineComments."Document Type"::"Posted Invoice");
        PurchDocLineComments.SetRange("No.", "Document No.");
        PurchDocLineComments.SetRange("Document Line No.", "Line No.");
        if not PurchDocLineComments.IsEmpty() then
            PurchDocLineComments.DeleteAll();

        PostedDeferralHeader.DeleteHeader(
            "Deferral Document Type"::Purchase.AsInteger(), '', '',
            PurchDocLineComments."Document Type"::"Posted Invoice".AsInteger(), "Document No.", "Line No.");

        MatchedOrderLineMgmt.DeleteMatchedLinesFromPostedPurchaseInvoice(Rec);
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        UOMMgt: Codeunit "Unit of Measure Management";
        DeferralUtilities: Codeunit "Deferral Utilities";

    procedure GetCurrencyCode(): Code[10]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if "Document No." = PurchInvHeader."No." then
            exit(PurchInvHeader."Currency Code");
        if PurchInvHeader.Get("Document No.") then
            exit(PurchInvHeader."Currency Code");
        exit('');
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgt.ShowItemTrackingForInvoiceLine(RowID1());
    end;

    procedure CalcVATAmountLines(PurchInvHeader: Record "Purch. Inv. Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        TempVATAmountLine.DeleteAll();
        SetRange("Document No.", PurchInvHeader."No.");
        if Find('-') then
            repeat
                TempVATAmountLine.Init();
                TempVATAmountLine.CopyFromPurchInvLine(Rec);
                TempVATAmountLine.InsertLine();
            until Next() = 0;
    end;

    local procedure GetFieldCaption(FieldNumber: Integer): Text[100]
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Purch. Inv. Line", FieldNumber);
        exit(Field."Field Caption");
    end;

    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if not PurchInvHeader.Get("Document No.") then
            PurchInvHeader.Init();
        if PurchInvHeader."Prices Including VAT" then
            exit('2,1,' + GetFieldCaption(FieldNumber));

        exit('2,0,' + GetFieldCaption(FieldNumber));
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Purch. Inv. Line",
            0, "Document No.", '', 0, "Line No."));
    end;

    procedure GetPurchRcptLines(var TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
    begin
        TempPurchRcptLine.Reset();
        TempPurchRcptLine.DeleteAll();

        if Type <> Type::Item then
            exit;

        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_No, "Document No.");
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Type, Enum::"Item Ledger Document Type"::"Purchase Invoice");
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Line_No, "Line No.");
        ValueItemLedgerEntries.SetFilter(Value_Entry_Invoiced_Qty, '<>0');
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Type, Enum::"Item Ledger Document Type"::"Purchase Receipt");
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do
            if PurchRcptLine.Get(ValueItemLedgerEntries.Item_Ledg_Document_No, ValueItemLedgerEntries.Item_Ledg_Document_Line_No) then begin
                TempPurchRcptLine.Init();
                TempPurchRcptLine := PurchRcptLine;
                if TempPurchRcptLine.Insert() then;
            end;
    end;

    procedure CalcReceivedPurchNotReturned(var RemainingQty: Decimal; var RevUnitCostLCY: Decimal; ExactCostReverse: Boolean)
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        TotalCostLCY: Decimal;
        TotalQtyBase: Decimal;
    begin
        RemainingQty := 0;
        if (Type <> Type::Item) or (Quantity <= 0) then begin
            RevUnitCostLCY := "Unit Cost (LCY)";
            exit;
        end;

        RevUnitCostLCY := 0;
        GetItemLedgEntries(TempItemLedgEntry, false);

        if TempItemLedgEntry.FindSet() then
            repeat
                RemainingQty := RemainingQty + TempItemLedgEntry."Remaining Quantity";
                if ExactCostReverse then begin
                    TempItemLedgEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
                    TotalCostLCY :=
                      TotalCostLCY + TempItemLedgEntry."Cost Amount (Expected)" + TempItemLedgEntry."Cost Amount (Actual)";
                    TotalQtyBase := TotalQtyBase + TempItemLedgEntry.Quantity;
                end;
            until TempItemLedgEntry.Next() = 0;

        if ExactCostReverse and (RemainingQty <> 0) and (TotalQtyBase <> 0) then
            RevUnitCostLCY :=
              Abs(TotalCostLCY / TotalQtyBase) * "Qty. per Unit of Measure"
        else
            RevUnitCostLCY := "Unit Cost (LCY)";
        RemainingQty := CalcQty(RemainingQty);

        if RemainingQty > Quantity then
            RemainingQty := Quantity;

        OnAfterCalcReceivedPurchNotReturned(Rec, RemainingQty, RevUnitCostLCY, ExactCostReverse);
    end;

    local procedure CalcQty(QtyBase: Decimal) Result: Decimal
    begin
        if "Qty. per Unit of Measure" = 0 then
            Result := QtyBase
        else
            Result := Round(QtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        OnAfterCalcQty(Rec, QtyBase, Result);
    end;

    procedure GetItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SetQuantity: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ShouldExit: Boolean;
    begin
        if SetQuantity then begin
            TempItemLedgEntry.Reset();
            TempItemLedgEntry.DeleteAll();

            if Type <> Type::Item then
                exit;

            ShouldExit := false;
            OnGetItemLedgEntryOnShouldExit(Rec, ShouldExit);
            if ShouldExit then
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
                    if Abs(TempItemLedgEntry."Remaining Quantity") > Abs(TempItemLedgEntry.Quantity) then
                        TempItemLedgEntry."Remaining Quantity" := Abs(TempItemLedgEntry.Quantity);
                end;
                OnGetItemLedgEntriesOnBeforeTempItemLedgEntryInsert(TempItemLedgEntry, ValueEntry, SetQuantity);
                if TempItemLedgEntry.Insert() then;
            until ValueEntry.Next() = 0;
    end;

    procedure FilterPstdDocLineValueEntries(var ValueEntry: Record "Value Entry")
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", "Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document Line No.", "Line No.");
    end;

    procedure ShowItemReceiptLines()
    var
        TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary;
    begin
        if Type = Type::Item then begin
            GetPurchRcptLines(TempPurchRcptLine);
            PAGE.RunModal(0, TempPurchRcptLine);
        end;
    end;

    procedure ShowLineComments()
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        PurchCommentLine.ShowComments(PurchCommentLine."Document Type"::"Posted Invoice".AsInteger(), "Document No.", "Line No.");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure InitFromPurchLine(PurchInvHeader: Record "Purch. Inv. Header"; PurchLine: Record "Purchase Line")
    begin
        Init();
        TransferFields(PurchLine);
        if ("No." = '') and HasTypeToFillMandatoryFields() then
            Type := Type::" ";
        "Posting Date" := PurchInvHeader."Posting Date";
        "Document No." := PurchInvHeader."No.";
        Quantity := PurchLine."Qty. to Invoice";
        "Quantity (Base)" := PurchLine."Qty. to Invoice (Base)";

        OnAfterInitFromPurchLine(PurchInvHeader, PurchLine, Rec);
    end;

    procedure ShowDeferrals()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDeferrals(Rec, IsHandled);
        if IsHandled then
            exit;

        DeferralUtilities.OpenLineScheduleView(
            "Deferral Code", "Deferral Document Type"::Purchase.AsInteger(), '', '',
            GetDocumentType(), "Document No.", "Line No.");
    end;

    procedure GetDocumentType(): Integer
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        exit(PurchCommentLine."Document Type"::"Posted Invoice".AsInteger())
    end;

    procedure HasTypeToFillMandatoryFields(): Boolean
    begin
        exit(Type <> Type::" ");
    end;

    procedure FormatType(): Text
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if Type = Type::" " then
            exit(PurchaseLine.FormatType());

        exit(Format(Type));
    end;

    procedure IsCancellationSupported() Result: Boolean
    begin
        Result := Type in [Type::" ", Type::Item, Type::"G/L Account", Type::"Charge (Item)", Type::Resource];
        OnAfterIsCancellationSupported(Rec, Result);
    end;

    procedure SetSecurityFilterOnRespCenter()
    var
        UserSetupMgt: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupMgt.GetPurchasesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetPurchasesFilter());
            FilterGroup(0);
        end;
    end;

    internal procedure GetVATPct() VATPct: Decimal
    begin
        VATPct := "VAT %";
        OnAfterGetVATPct(Rec, VATPct);
    end;

    procedure IsProdOrder() Result: Boolean
    begin
        OnIsProdOrder(Rec, Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQty(var PurchInvLine: Record "Purch. Inv. Line"; QtyBase: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromPurchLine(PurchInvHeader: Record "Purch. Inv. Header"; PurchLine: Record "Purchase Line"; var PurchInvLine: Record "Purch. Inv. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeferrals(var PurchInvLine: Record "Purch. Inv. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemLedgEntriesOnBeforeTempItemLedgEntryInsert(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; ValueEntry: Record "Value Entry"; SetQuantity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var PurchInvLine: Record "Purch. Inv. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemLedgEntryOnShouldExit(var PurchInvLine: Record "Purch. Inv. Line"; var ShouldExit: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPct(var PurchInvLine: Record "Purch. Inv. Line"; var VATPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReceivedPurchNotReturned(var PurchInvLine: Record "Purch. Inv. Line"; var RemainingQty: Decimal; var RevUnitCostLCY: Decimal; ExactCostReverse: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsProdOrder(var PurchInvLine: Record "Purch. Inv. Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsCancellationSupported(PurchInvLine: Record "Purch. Inv. Line"; var Result: Boolean)
    begin
    end;
}
