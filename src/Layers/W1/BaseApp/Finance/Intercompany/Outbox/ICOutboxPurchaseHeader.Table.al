// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Purchases.Vendor;

/// <summary>
/// Stores purchase document headers for intercompany outbox transactions pending transmission to partner companies.
/// Manages purchase-specific fields, vendor information, and shipping details for intercompany purchase processes.
/// </summary>
/// <remarks>
/// Staging table for outbound intercompany purchase documents. Integrates with IC Outbox Transaction and IC Outbox Purchase Line.
/// Key relationships: IC Partner, Vendor, Currency, IC Outbox Purchase Line.
/// Extensible via table extensions for custom purchase document fields and partner-specific requirements.
/// </remarks>
table 428 "IC Outbox Purchase Header"
{
    Caption = 'IC Outbox Purchase Header';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Purchase document type for the intercompany outbox transaction.
        /// </summary>
        field(1; "Document Type"; Enum "IC Purchase Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Buy-from vendor number for the purchase document.
        /// </summary>
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        /// <summary>
        /// Document number for the purchase transaction.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        /// <summary>
        /// Pay-to vendor number for payment processing.
        /// </summary>
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        /// <summary>
        /// Vendor's reference number for the purchase document.
        /// </summary>
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        /// <summary>
        /// Ship-to name for delivery address identification.
        /// </summary>
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            Editable = false;
        }
        /// <summary>
        /// Primary ship-to address line for delivery location.
        /// </summary>
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            Editable = false;
        }
        /// <summary>
        /// Secondary ship-to address line for additional delivery details.
        /// </summary>
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            Editable = false;
        }
        /// <summary>
        /// Ship-to city for delivery location.
        /// </summary>
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            Editable = false;
        }
        /// <summary>
        /// Posting date for the purchase document transaction.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Expected receipt date for the purchase order delivery.
        /// </summary>
        field(21; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Payment due date for the purchase document.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// Payment discount percentage available for early payment.
        /// </summary>
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            Editable = false;
        }
        /// <summary>
        /// Date until which payment discount percentage is valid.
        /// </summary>
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            Editable = false;
        }
        /// <summary>
        /// Currency code for the purchase document amounts.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Indicates whether prices on the purchase document include VAT.
        /// </summary>
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        /// <summary>
        /// Vendor's invoice number for reference and matching.
        /// </summary>
        field(68; "Vendor Invoice No."; Code[35])
        {
            Caption = 'Vendor Invoice No.';
            Editable = false;
        }
        /// <summary>
        /// Vendor's credit memo number for reference and matching.
        /// </summary>
        field(69; "Vendor Cr. Memo No."; Code[35])
        {
            Caption = 'Vendor Cr. Memo No.';
            Editable = false;
        }
        /// <summary>
        /// Sell-to customer number for drop shipment scenarios.
        /// </summary>
        field(72; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            Editable = false;
        }
        /// <summary>
        /// Ship-to postal code for delivery location.
        /// </summary>
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            Editable = false;
        }
        /// <summary>
        /// Ship-to county for delivery location.
        /// </summary>
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        /// <summary>
        /// Ship-to country/region code for delivery location.
        /// </summary>
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Document creation date for reference and sequencing.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
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
        field(201; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Origin of the intercompany transaction indicating creation or rejection source.
        /// </summary>
        field(202; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Ship-to phone number for delivery location contact.
        /// </summary>
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        /// <summary>
        /// Requested receipt date for delivery planning.
        /// </summary>
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Vendor's promised receipt date for delivery confirmation.
        /// </summary>
        field(5791; "Promised Receipt Date"; Date)
        {
            Caption = 'Promised Receipt Date';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "IC Transaction No.", "IC Partner Code", "Transaction Source")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ICOutboxPurchLine: Record "IC Outbox Purchase Line";
        ICDocDim: Record "IC Document Dimension";
        DimMgt: Codeunit DimensionManagement;
    begin
        ICOutboxPurchLine.SetRange("IC Partner Code", "IC Partner Code");
        ICOutboxPurchLine.SetRange("IC Transaction No.", "IC Transaction No.");
        ICOutboxPurchLine.SetRange("Transaction Source", "Transaction Source");
        if ICOutboxPurchLine.FindFirst() then
            ICOutboxPurchLine.DeleteAll(true);
        ICDocDim.LockTable();
        DimMgt.DeleteICDocDim(
          DATABASE::"IC Outbox Purchase Header", "IC Transaction No.", "IC Partner Code", "Transaction Source", 0);
    end;
}
