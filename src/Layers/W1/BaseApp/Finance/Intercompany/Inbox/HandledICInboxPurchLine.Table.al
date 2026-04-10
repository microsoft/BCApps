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
/// Archive table for processed intercompany inbox purchase document lines.
/// Maintains complete transaction history for audit trail and compliance reporting.
/// </summary>
table 441 "Handled IC Inbox Purch. Line"
{
    Caption = 'Handled IC Inbox Purch. Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Document type for this archived purchase line.
        /// </summary>
        field(1; "Document Type"; Enum "IC Inbox Purchase Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Document number for this archived purchase line.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Line number for this archived purchase line.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Description of the archived purchase item or service.
        /// </summary>
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        /// <summary>
        /// Additional description for the archived purchase item or service.
        /// </summary>
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Quantity ordered for this archived purchase line.
        /// </summary>
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Direct unit cost for this archived purchase item.
        /// </summary>
        field(22; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            Editable = false;
        }
        /// <summary>
        /// Line discount percentage for archived purchase line pricing.
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
        /// Line discount amount for archived purchase line calculation.
        /// </summary>
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
            Editable = false;
        }
        /// <summary>
        /// Amount for archived purchase line excluding VAT.
        /// </summary>
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        /// <summary>
        /// Amount including VAT for archived purchase line total value.
        /// </summary>
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;
        }
        /// <summary>
        /// Project number for archived job-related purchase line tracking.
        /// </summary>
        field(45; "Job No."; Code[20])
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project No.';
            Editable = false;
        }
        /// <summary>
        /// Indirect cost percentage for archived purchase line cost calculation.
        /// </summary>
        field(54; "Indirect Cost %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Indirect Cost %';
            Editable = false;
        }
        /// <summary>
        /// Receipt number for archived purchase line shipment reference.
        /// </summary>
        field(63; "Receipt No."; Code[20])
        {
            Caption = 'Receipt No.';
            Editable = false;
        }
        /// <summary>
        /// Receipt line number for archived purchase line shipment tracking.
        /// </summary>
        field(64; "Receipt Line No."; Integer)
        {
            Caption = 'Receipt Line No.';
            Editable = false;
        }
        /// <summary>
        /// Invoice discount amount for archived purchase line calculation.
        /// </summary>
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;
        }
        /// <summary>
        /// Indicates archived drop shipment delivery method for direct vendor fulfillment.
        /// </summary>
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            Editable = false;
        }
        /// <summary>
        /// Currency code for archived purchase line monetary denomination.
        /// </summary>
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// VAT base amount for archived purchase line tax calculation reference.
        /// </summary>
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        /// <summary>
        /// Unit cost for archived purchase line cost tracking.
        /// </summary>
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        /// <summary>
        /// Line amount for archived purchase line total value calculation.
        /// </summary>
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';
            Editable = false;
        }
        /// <summary>
        /// VAT difference for archived purchase line tax calculation adjustment.
        /// </summary>
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        /// <summary>
        /// IC partner reference type for archived cross-company item identification.
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            Editable = false;
        }
        /// <summary>
        /// IC partner reference for archived intercompany item cross-reference.
        /// </summary>
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
            Editable = false;
            TableRelation = if ("IC Partner Ref. Type" = const(" ")) "Standard Text"
            else
            if ("IC Partner Ref. Type" = const("G/L Account")) "IC G/L Account"
            else
            if ("IC Partner Ref. Type" = const(Item)) Item
            else
            if ("IC Partner Ref. Type" = const("Charge (Item)")) "Item Charge";
        }
        /// <summary>
        /// Intercompany partner code that sent this archived purchase line transaction.
        /// </summary>
        field(125; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Unique transaction number identifying the archived intercompany transaction.
        /// </summary>
        field(126; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Source of this archived transaction indicating whether it was returned by partner or created by partner.
        /// </summary>
        field(127; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// IC item reference number for archived intercompany item cross-reference.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
        }
        /// <summary>
        /// Unit of measure code for archived purchase line quantity specification.
        /// </summary>
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
        }
        /// <summary>
        /// Requested receipt date for archived purchase line delivery requirement.
        /// </summary>
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Promised receipt date for archived purchase line delivery commitment.
        /// </summary>
        field(5791; "Promised Receipt Date"; Date)
        {
            Caption = 'Promised Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Return shipment number for archived purchase line return processing reference.
        /// </summary>
        field(6600; "Return Shipment No."; Code[20])
        {
            Caption = 'Return Shipment No.';
            Editable = false;
        }
        /// <summary>
        /// Return shipment line number for archived purchase line return tracking.
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
          DATABASE::"Handled IC Inbox Purch. Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;

    /// <summary>
    /// Shows dimensions for the archived intercompany purchase line.
    /// </summary>
    procedure ShowDimensions()
    var
        ICDocDim: Record "IC Document Dimension";
    begin
        TestField("IC Transaction No.");
        TestField("Line No.");
        ICDocDim.ShowDimensions(
          DATABASE::"Handled IC Inbox Purch. Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;
}
