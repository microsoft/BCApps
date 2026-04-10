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
/// Stores purchase document line details for outbound intercompany transactions.
/// Contains line-level purchase information including items, costs, discounts, and delivery details for IC partner communication.
/// </summary>
/// <remarks>
/// Active transaction table used during IC purchase document processing. Integrates with purchase documents, job projects, and dimension management.
/// Key relationships: IC Partner, IC Transaction, Currency, Project, Item Catalog, Dimension Management.
/// </remarks>
table 429 "IC Outbox Purchase Line"
{
    Caption = 'IC Outbox Purchase Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Purchase document type for the intercompany transaction line.
        /// </summary>
        field(1; "Document Type"; Enum "IC Outbox Purchase Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Purchase document number containing this line for IC partner reference.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Sequential line number within the purchase document for ordering and identification.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Primary description of the purchased item or service for IC partner identification.
        /// </summary>
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Additional description line providing supplementary details about the purchased item or service.
        /// </summary>
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Quantity of items being purchased in the base unit of measure.
        /// </summary>
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Unit cost of the item excluding indirect costs and VAT, used for purchase calculations.
        /// </summary>
        field(22; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            Editable = false;
        }
        /// <summary>
        /// Line-level discount percentage applied to the unit cost for this purchase line.
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
        /// Calculated line discount amount in document currency based on line discount percentage.
        /// </summary>
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
        }
        /// <summary>
        /// Total line amount excluding VAT after applying line and invoice discounts.
        /// </summary>
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        /// <summary>
        /// Total line amount including applicable VAT for purchase accounting and payment processing.
        /// </summary>
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;
        }
        /// <summary>
        /// Project number for linking purchase line to specific project activities and cost allocation.
        /// </summary>
        field(45; "Job No."; Code[20])
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project No.';
            Editable = false;
        }
        /// <summary>
        /// Percentage of indirect costs added to direct unit cost for comprehensive cost calculation.
        /// </summary>
        field(54; "Indirect Cost %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Indirect Cost %';
            Editable = false;
        }
        /// <summary>
        /// Document-level invoice discount amount allocated to this purchase line based on line value.
        /// </summary>
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether this purchase line uses drop shipment delivery directly to customer.
        /// </summary>
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            Editable = false;
        }
        /// <summary>
        /// Currency code for all monetary amounts on this purchase line, used for multi-currency transactions.
        /// </summary>
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Base amount for VAT calculation excluding VAT but including discounts and charges.
        /// </summary>
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        /// <summary>
        /// Unit cost including indirect costs and overhead for comprehensive purchase cost analysis.
        /// </summary>
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        /// <summary>
        /// Total line amount before VAT and invoice discounts for base calculation purposes.
        /// </summary>
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';
            Editable = false;
        }
        /// <summary>
        /// Difference between calculated VAT and manually adjusted VAT amount for audit and reconciliation.
        /// </summary>
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        /// <summary>
        /// Type of IC partner reference for item mapping between companies (G/L Account, Item, Charge Item).
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            Editable = false;
        }
        /// <summary>
        /// IC partner's reference code for item identification and mapping between company item catalogs.
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
        /// Code identifying the intercompany partner receiving this purchase transaction.
        /// </summary>
        field(125; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Unique transaction number linking this line to the parent IC outbox transaction.
        /// </summary>
        field(126; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Source of the IC transaction indicating whether created by current company or rejected by partner.
        /// </summary>
        field(127; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Alternative item reference number used by IC partner for cross-referencing item catalogs.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';
        }
        /// <summary>
        /// Unit of measure code for quantity calculations and partner inventory management.
        /// </summary>
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
        }
        /// <summary>
        /// Date when items are requested to be received for delivery planning and logistics coordination.
        /// </summary>
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Date when supplier commits to deliver items for delivery confirmation and scheduling.
        /// </summary>
        field(5791; "Promised Receipt Date"; Date)
        {
            Caption = 'Promised Receipt Date';
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
          DATABASE::"IC Outbox Purchase Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;

    /// <summary>
    /// Opens the dimension management interface for viewing and editing dimensions associated with this purchase line.
    /// Enables dimension analysis and financial reporting for intercompany purchase transactions.
    /// </summary>
    procedure ShowDimensions()
    var
        ICDocDim: Record "IC Document Dimension";
    begin
        TestField("IC Transaction No.");
        TestField("Line No.");
        ICDocDim.ShowDimensions(
          DATABASE::"IC Outbox Purchase Line", "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;
}
