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
/// Stores sales document line details for intercompany outbox transactions pending transmission to partner companies.
/// Manages line-level data including items, pricing, quantities, and dimensions for intercompany sales processes.
/// </summary>
/// <remarks>
/// Line detail table for outbound intercompany sales documents. Integrates with IC Outbox Sales Header and IC Outbox Transaction.
/// Key relationships: IC Outbox Sales Header, Item, IC G/L Account, Job, Currency.
/// Extensible via table extensions for custom sales line fields and partner-specific line requirements.
/// </remarks>
table 427 "IC Outbox Sales Line"
{
    Caption = 'IC Outbox Sales Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Sales document type for the intercompany outbox sales line.
        /// </summary>
        field(1; "Document Type"; Enum "IC Outbox Sales Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Document number linking this line to the parent sales header.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Line number providing unique identification within the sales document.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Primary description of the item or service on the sales line.
        /// </summary>
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Additional description text for the sales line item or service.
        /// </summary>
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Quantity of items or units of service on the sales line.
        /// </summary>
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Unit price for the item or service in the specified currency.
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
        /// Line discount amount calculated from the discount percentage.
        /// </summary>
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
        }
        /// <summary>
        /// Net amount for the sales line excluding VAT.
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
        /// Project number for job-related sales lines.
        /// </summary>
        field(45; "Job No."; Code[20])
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project No.';
            Editable = false;
        }
        /// <summary>
        /// Shipment document number for shipped sales lines.
        /// </summary>
        field(63; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';
            Editable = false;
        }
        /// <summary>
        /// Line number in the corresponding shipment document.
        /// </summary>
        field(64; "Shipment Line No."; Integer)
        {
            Caption = 'Shipment Line No.';
            Editable = false;
        }
        /// <summary>
        /// Invoice discount amount applied at document level and allocated to this line.
        /// </summary>
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;
        }
        /// <summary>
        /// Indicates if this line is part of a drop shipment arrangement.
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
        /// VAT base amount used for VAT calculation on the sales line.
        /// </summary>
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        /// <summary>
        /// Total line amount before taxes and discounts.
        /// </summary>
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';
            Editable = false;
        }
        /// <summary>
        /// Manual VAT adjustment amount for the sales line.
        /// </summary>
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        /// <summary>
        /// Type of reference used by the intercompany partner for this line.
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            Editable = false;
        }
        /// <summary>
        /// Reference code that the intercompany partner uses to identify this item or account.
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
        /// Code of the intercompany partner receiving this sales transaction.
        /// </summary>
        field(125; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Intercompany transaction number linking this line to the transaction header.
        /// </summary>
        field(126; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Source of the intercompany transaction indicating creation or rejection origin.
        /// </summary>
        field(127; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Item reference number used by the intercompany partner for item identification.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
        }
        /// <summary>
        /// Unit of measure code for the quantity on the sales line.
        /// </summary>
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
        }
        /// <summary>
        /// Delivery date requested by the customer for this sales line.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            Editable = false;
        }
        /// <summary>
        /// Delivery date promised to the customer for this sales line.
        /// </summary>
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
        }
        /// <summary>
        /// Return receipt document number for returned sales lines.
        /// </summary>
        field(6600; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
            Editable = false;
        }
        /// <summary>
        /// Line number in the corresponding return receipt document.
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
        ICDocDim: Record "IC Document Dimension";
        DimMgt: Codeunit DimensionManagement;
    begin
        ICDocDim.LockTable();
        DimMgt.DeleteICDocDim(DATABASE::"IC Outbox Sales Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;

    /// <summary>
    /// Opens the dimensions page to view or edit dimension values for the sales line.
    /// Displays intercompany document dimensions associated with this outbox sales line.
    /// </summary>
    procedure ShowDimensions()
    var
        ICDocDim: Record "IC Document Dimension";
    begin
        TestField("IC Transaction No.");
        TestField("Line No.");
        ICDocDim.ShowDimensions(
          DATABASE::"IC Outbox Sales Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;
}
