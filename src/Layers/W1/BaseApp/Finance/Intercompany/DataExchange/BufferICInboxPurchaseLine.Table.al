// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Partner;

/// <summary>
/// Temporary buffer table for staging intercompany purchase line data during API-based data exchange.
/// Handles line-level purchase transaction details including items, quantities, pricing, and dimensions.
/// </summary>
table 606 "Buffer IC Inbox Purchase Line"
{
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        /// <summary>
        /// Type of purchase document for the line item (Order, Invoice, Credit Memo, etc.).
        /// </summary>
        field(1; "Document Type"; Enum "IC Inbox Purchase Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Purchase document number that this line item belongs to.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Unique line number within the purchase document for ordering and reference.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Primary description of the item, service, or G/L account being purchased.
        /// </summary>
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Additional description text providing supplementary details about the line item.
        /// </summary>
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Quantity of items or units being purchased on this line.
        /// </summary>
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Direct unit cost for the item excluding any discounts or indirect costs.
        /// </summary>
        field(22; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            Editable = false;
        }
        /// <summary>
        /// Line discount percentage applied to the unit cost for this purchase line.
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
        /// Line discount amount calculated from the discount percentage and unit cost.
        /// </summary>
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
        }
        /// <summary>
        /// Net amount for the line after applying discounts but excluding VAT.
        /// </summary>
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        /// <summary>
        /// Total amount for the line including VAT and all applicable taxes.
        /// </summary>
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;
        }
        /// <summary>
        /// Project number for job-related purchase line items and cost allocation.
        /// </summary>
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            Editable = false;
        }
        /// <summary>
        /// Indirect cost percentage applied to the line for overhead allocation.
        /// </summary>
        field(54; "Indirect Cost %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Indirect Cost %';
            Editable = false;
        }
        /// <summary>
        /// Receipt document number if this line references a previously received shipment.
        /// </summary>
        field(63; "Receipt No."; Code[20])
        {
            Caption = 'Receipt No.';
            Editable = false;
        }
        /// <summary>
        /// Receipt line number corresponding to the referenced receipt document.
        /// </summary>
        field(64; "Receipt Line No."; Integer)
        {
            Caption = 'Receipt Line No.';
            Editable = false;
        }
        /// <summary>
        /// Invoice discount amount allocated to this line from document-level discounts.
        /// </summary>
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether this line is for drop shipment directly from vendor to customer.
        /// </summary>
        field(73; "Drop Shipment"; Boolean)
        {
            Caption = 'Drop Shipment';
            Editable = false;
        }
        /// <summary>
        /// Currency code for amounts on this purchase line.
        /// </summary>
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
        }
        /// <summary>
        /// VAT base amount used for tax calculations on this line.
        /// </summary>
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        /// <summary>
        /// Total unit cost including direct cost and indirect cost percentage.
        /// </summary>
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        /// <summary>
        /// Line amount before discounts calculated from quantity and unit cost.
        /// </summary>
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';
            Editable = false;
        }
        /// <summary>
        /// Type of reference used by intercompany partner (Item, G/L Account, etc.).
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            Editable = false;
        }
        /// <summary>
        /// Partner's reference number or code for cross-company item identification.
        /// </summary>
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
        }
        /// <summary>
        /// Intercompany partner code identifying the originating company for this transaction.
        /// </summary>
        field(125; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
        }
        /// <summary>
        /// Unique transaction number assigned by the intercompany system for tracking purposes.
        /// </summary>
        field(126; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Source of the intercompany transaction (Created by Current Company, Returned by IC Partner, etc.).
        /// </summary>
        field(127; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Type of item reference used for intercompany item identification and mapping.
        /// </summary>
        field(128; "Item Ref."; Option)
        {
            Caption = 'Item Ref.';
            Editable = false;
            OptionCaption = 'Local Item No.,Cross Reference,Vendor Item No.';
            OptionMembers = "Local Item No.","Cross Reference","Vendor Item No.";
        }
        /// <summary>
        /// Intercompany item reference number for cross-partner item identification.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            Caption = 'IC Item Reference No.';
        }
        /// <summary>
        /// Unit of measure code for quantity calculations and inventory management.
        /// </summary>
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
        }
        /// <summary>
        /// Date when goods or services are requested to be received for this line.
        /// </summary>
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Date when the vendor has promised to deliver goods or complete services for this line.
        /// </summary>
        field(5791; "Promised Receipt Date"; Date)
        {
            Caption = 'Promised Receipt Date';
        }
        /// <summary>
        /// Return shipment document number if this line references a return transaction.
        /// </summary>
        field(6600; "Return Shipment No."; Code[20])
        {
            Caption = 'Return Shipment No.';
            Editable = false;
        }
        /// <summary>
        /// Return shipment line number corresponding to the referenced return document.
        /// </summary>
        field(6601; "Return Shipment Line No."; Integer)
        {
            Caption = 'Return Shipment Line No.';
            Editable = false;
        }
        /// <summary>
        /// Unique operation identifier for tracking API-based data exchange processes and error resolution.
        /// </summary>
        field(8100; "Operation ID"; Guid)
        {
            Editable = false;
            Caption = 'Operation ID';
        }
    }

    keys
    {
        key(Key1; "IC Transaction No.", "IC Partner Code", "Transaction Source", "Line No.")
        {
            Clustered = true;
        }
    }
}
