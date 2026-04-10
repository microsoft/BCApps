// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

/// <summary>
/// Stores purchase document line details for intercompany inbox transactions awaiting processing.
/// Contains item information, quantities, costs, and IC partner references for purchase transactions received from partner companies.
/// </summary>
table 437 "IC Inbox Purchase Line"
{
    Caption = 'IC Inbox Purchase Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Document type of the purchase document containing this line.
        /// </summary>
        field(1; "Document Type"; Enum "IC Inbox Purchase Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Document number of the purchase document containing this line.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Line number for ordering and identification within the purchase document.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Description of the purchase line item or service.
        /// </summary>
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Additional description line for extended item or service details.
        /// </summary>
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Quantity of items or units for this purchase line.
        /// </summary>
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Direct cost per unit before discounts and additional charges.
        /// </summary>
        field(22; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            Editable = false;
        }
        /// <summary>
        /// Line discount percentage applied to the direct unit cost.
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
        /// Line discount amount calculated from discount percentage and unit cost.
        /// </summary>
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
        }
        /// <summary>
        /// Total line amount after discounts but excluding VAT.
        /// </summary>
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        /// <summary>
        /// Total line amount including VAT for final invoice calculation.
        /// </summary>
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;
        }
        /// <summary>
        /// Project number for job-related purchase line items.
        /// </summary>
        field(45; "Job No."; Code[20])
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project No.';
            Editable = false;
        }
        /// <summary>
        /// Indirect cost percentage applied to the purchase line for overhead allocation.
        /// </summary>
        field(54; "Indirect Cost %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Indirect Cost %';
            Editable = false;
        }
        /// <summary>
        /// Receipt document number for goods received against this purchase line.
        /// </summary>
        field(63; "Receipt No."; Code[20])
        {
            Caption = 'Receipt No.';
            Editable = false;
        }
        /// <summary>
        /// Line number reference in the receipt document for tracking purposes.
        /// </summary>
        field(64; "Receipt Line No."; Integer)
        {
            Caption = 'Receipt Line No.';
            Editable = false;
        }
        /// <summary>
        /// Invoice discount amount applied at document level allocation.
        /// </summary>
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether this purchase line is part of a drop shipment arrangement.
        /// </summary>
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            Editable = false;
        }
        /// <summary>
        /// Currency code for amounts on this intercompany purchase line.
        /// </summary>
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// VAT base amount for tax calculation on this purchase line.
        /// </summary>
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        /// <summary>
        /// Total unit cost including indirect costs and overhead allocations.
        /// </summary>
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        /// <summary>
        /// Line amount before invoice discount and VAT calculations.
        /// </summary>
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';
            Editable = false;
        }
        /// <summary>
        /// VAT difference amount for reconciliation and adjustment purposes.
        /// </summary>
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        /// <summary>
        /// Type of IC partner reference for cross-company account mapping.
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            Editable = false;
        }
        /// <summary>
        /// Partner's reference code for account or item identification across companies.
        /// </summary>
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
            TableRelation = if ("IC Partner Ref. Type" = const(" ")) "Standard Text"
            else
            if ("IC Partner Ref. Type" = const("G/L Account")) "IC G/L Account"
            else
            if ("IC Partner Ref. Type" = const(Item)) Item
            else
            if ("IC Partner Ref. Type" = const("Charge (Item)")) "Item Charge";
        }
        /// <summary>
        /// Intercompany partner code that sent this inbox purchase line transaction.
        /// </summary>
        field(125; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Unique transaction number identifying the intercompany transaction.
        /// </summary>
        field(126; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Source of the intercompany transaction indicating origin company.
        /// </summary>
        field(127; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Reference method for item identification across intercompany partners.
        /// </summary>
        field(128; "Item Ref."; Option)
        {
            Caption = 'Item Ref.';
            Editable = false;
            OptionCaption = 'Local Item No.,Cross Reference,Vendor Item No.';
            OptionMembers = "Local Item No.","Cross Reference","Vendor Item No.";
        }
        /// <summary>
        /// Item reference number used for cross-company item identification.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
        }
        /// <summary>
        /// Unit of measure code for quantity specifications in intercompany purchases.
        /// </summary>
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
        }
        /// <summary>
        /// Requested delivery date for the purchase line item.
        /// </summary>
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Promised delivery date committed by the IC partner company.
        /// </summary>
        field(5791; "Promised Receipt Date"; Date)
        {
            Caption = 'Promised Receipt Date';
        }
        /// <summary>
        /// Return shipment document number for credit processing.
        /// </summary>
        field(6600; "Return Shipment No."; Code[20])
        {
            Caption = 'Return Shipment No.';
            Editable = false;
        }
        /// <summary>
        /// Line number reference in the return shipment document.
        /// </summary>
        field(6601; "Return Shipment Line No."; Integer)
        {
            Caption = 'Return Shipment Line No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.DeleteICDocDim(
          DATABASE::"IC Inbox Purchase Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;

    /// <summary>
    /// Opens the dimension management page for this intercompany purchase line.
    /// </summary>
    procedure ShowDimensions()
    var
        ICDocDim: Record "IC Document Dimension";
    begin
        TestField("IC Transaction No.");
        TestField("Line No.");
        ICDocDim.ShowDimensions(
          DATABASE::"IC Inbox Purchase Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;
}
