// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Partner;

/// <summary>
/// Temporary buffer table for staging intercompany sales line data during API-based data exchange.
/// Facilitates sales line validation and transformation before posting to target partner systems.
/// </summary>
table 609 "Buffer IC Inbox Sales Line"
{
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        /// <summary>
        /// Type of sales document for this line (Order, Invoice, Credit Memo, etc.).
        /// </summary>
        field(1; "Document Type"; Enum "IC Inbox Sales Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Document number linking this line to the parent sales document.
        /// </summary>
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Sequential line number identifying this sales line within the document.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Primary description of the item or service being sold on this line.
        /// </summary>
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Additional description text for extended item or service details.
        /// </summary>
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Quantity of items or units of service being sold on this line.
        /// </summary>
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Unit price for each quantity unit on this sales line.
        /// </summary>
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            Editable = false;
        }
        /// <summary>
        /// Line discount percentage applied to the unit price for this sales line.
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
        /// Line discount amount calculated from discount percentage and unit price.
        /// </summary>
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
        }
        /// <summary>
        /// Total amount for this sales line excluding VAT after discounts applied.
        /// </summary>
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        /// <summary>
        /// Total amount for this sales line including VAT after discounts applied.
        /// </summary>
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;
        }
        /// <summary>
        /// Project number for tracking this sales line to a specific job or project.
        /// </summary>
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            Editable = false;
        }
        /// <summary>
        /// Invoice discount amount allocated to this sales line.
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
        /// Currency code for all monetary amounts on this sales line.
        /// </summary>
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
        }
        /// <summary>
        /// VAT base amount for calculating VAT on this sales line.
        /// </summary>
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        /// <summary>
        /// Total line amount before invoice-level discounts are applied.
        /// </summary>
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';
            Editable = false;
        }
        /// <summary>
        /// Type of reference used by the intercompany partner for this sales line item.
        /// </summary>
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            Caption = 'IC Partner Ref. Type';
            Editable = false;
        }
        /// <summary>
        /// Partner's reference number or code for identifying this item in their system.
        /// </summary>
        field(108; "IC Partner Reference"; Code[20])
        {
            Caption = 'IC Partner Reference';
        }
        /// <summary>
        /// Intercompany partner code identifying the originating company for this sales line.
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
        /// Source of the transaction indicating whether returned by partner or created by partner.
        /// </summary>
        field(127; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Item reference type used for intercompany item identification and mapping.
        /// </summary>
        field(128; "Item Ref."; Option)
        {
            Caption = 'Item Ref.';
            Editable = false;
            OptionCaption = 'Local Item No.,Cross Reference,Vendor Item No.';
            OptionMembers = "Local Item No.","Cross Reference","Vendor Item No.";
        }
        /// <summary>
        /// Intercompany item reference number for identifying items across partner companies.
        /// </summary>
        field(138; "IC Item Reference No."; Code[50])
        {
            Caption = 'IC Item Reference No.';
        }
        /// <summary>
        /// Unit of measure code for the quantity on this sales line.
        /// </summary>
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
        }
        /// <summary>
        /// Date when goods or services are requested to be delivered to the customer.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            Editable = false;
        }
        /// <summary>
        /// Date when delivery has been promised to the customer by the partner company.
        /// </summary>
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
            Editable = false;
        }
        /// <summary>
        /// Unique identifier for the intercompany data exchange operation.
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
