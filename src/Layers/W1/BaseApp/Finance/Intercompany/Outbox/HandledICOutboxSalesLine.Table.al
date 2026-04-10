// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

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
/// Stores processed sales document lines for intercompany outbox transactions.
/// Maintains historical archive of transmitted sales line details sent to IC partners.
/// </summary>
/// <remarks>
/// Historical archive table for completed intercompany outbox sales line transactions.
/// Supports detailed sales line tracking, pricing analysis, and transaction history reporting.
/// Integration points: IC Partner, Item Catalog, Job Projects, dimension management, return processing.
/// </remarks>
table 431 "Handled IC Outbox Sales Line"
{
    Caption = 'Handled IC Outbox Sales Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Sales document type for intercompany transaction processing.
        /// </summary>
        field(1; "Document Type"; Enum "IC Outbox Sales Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Unique document number for the sales transaction.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Line number for ordering and identification within the document.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Primary description of the sold item or service.
        /// </summary>
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        /// <summary>
        /// Additional description details for the sold item or service.
        /// </summary>
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            Editable = false;
        }
        /// <summary>
        /// Quantity of the sold item or service.
        /// </summary>
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Unit price for the sold item or service.
        /// </summary>
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            Editable = false;
        }
        /// <summary>
        /// Line discount percentage applied to the sales line.
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
        /// Line discount amount applied to the sales line.
        /// </summary>
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
            Editable = false;
        }
        /// <summary>
        /// Total amount for the sales line excluding VAT.
        /// </summary>
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        /// <summary>
        /// Total amount for the sales line including VAT.
        /// </summary>
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;
        }
        /// <summary>
        /// Job number for project-related sales line allocation.
        /// </summary>
        field(45; "Job No."; Code[20])
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project No.';
            Editable = false;
        }
        /// <summary>
        /// Sales shipment document number for delivery tracking.
        /// </summary>
        field(63; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';
            Editable = false;
        }
        /// <summary>
        /// Sales shipment line number for delivery line tracking.
        /// </summary>
        field(64; "Shipment Line No."; Integer)
        {
            Caption = 'Shipment Line No.';
            Editable = false;
        }
        /// <summary>
        /// Invoice discount amount applied at document level.
        /// </summary>
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether this line is for drop shipment from vendor to customer.
        /// </summary>
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            Editable = false;
        }
        /// <summary>
        /// Currency code for the sales line amounts.
        /// </summary>
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// VAT base amount for tax calculation.
        /// </summary>
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        /// <summary>
        /// Line amount before discounts and VAT.
        /// </summary>
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';
            Editable = false;
        }
        /// <summary>
        /// VAT difference amount for manual VAT adjustments.
        /// </summary>
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        /// <summary>
        /// Intercompany partner reference type for item mapping.
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            Editable = false;
        }
        /// <summary>
        /// Intercompany partner reference number for item or account mapping.
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
        /// Intercompany partner code identifying the receiving company.
        /// </summary>
        field(125; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Unique identifier for the intercompany transaction.
        /// </summary>
        field(126; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Origin of the intercompany transaction indicating creation or rejection source.
        /// </summary>
        field(127; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Intercompany item reference number for cross-company item mapping.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
        }
        /// <summary>
        /// Unit of measure code for the sold item quantity.
        /// </summary>
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
        }
        /// <summary>
        /// Requested delivery date for shipment planning.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            Editable = false;
        }
        /// <summary>
        /// Company's promised delivery date for shipment confirmation.
        /// </summary>
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
            Editable = false;
        }
        /// <summary>
        /// Return receipt document number for return processing tracking.
        /// </summary>
        field(6600; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
            Editable = false;
        }
        /// <summary>
        /// Return receipt line number for return line tracking.
        /// </summary>
        field(6601; "Return Receipt Line No."; Integer)
        {
            Caption = 'Return Receipt Line No.';
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
          DATABASE::"Handled IC Outbox Sales Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;

    /// <summary>
    /// Displays dimensions associated with the handled intercompany outbox sales line.
    /// </summary>
    procedure ShowDimensions()
    var
        ICDocDim: Record "IC Document Dimension";
    begin
        TestField("IC Transaction No.");
        TestField("Line No.");
        ICDocDim.ShowDimensions(
          DATABASE::"Handled IC Outbox Sales Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;
}
