// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Purchases.Vendor;

/// <summary>
/// Stores purchase document header information for intercompany inbox transactions awaiting processing.
/// Contains vendor details, shipping addresses, payment terms, and IC partner references for purchase transactions received from partner companies.
/// </summary>
table 436 "IC Inbox Purchase Header"
{
    Caption = 'IC Inbox Purchase Header';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of purchase document for this inbox header (Order, Invoice, Credit Memo, Return Order).
        /// </summary>
        field(1; "Document Type"; Enum "IC Purchase Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Vendor number for the buy-from vendor in this inbox purchase document.
        /// </summary>
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        /// <summary>
        /// Document number of the inbox purchase document.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        /// <summary>
        /// Vendor number for payment in this inbox purchase document.
        /// </summary>
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        /// <summary>
        /// Partner's reference for this purchase document for cross-referencing.
        /// </summary>
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        /// <summary>
        /// Ship-to recipient name for delivery address identification.
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
        /// Additional ship-to address line for extended delivery location details.
        /// </summary>
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            Editable = false;
        }
        /// <summary>
        /// Ship-to city for delivery location identification.
        /// </summary>
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            Editable = false;
        }
        /// <summary>
        /// Posting date for the purchase document in the general ledger.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Expected receipt date for delivery planning and scheduling.
        /// </summary>
        field(21; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Payment due date for invoice settlement and cash flow planning.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// Payment discount percentage for early payment incentives.
        /// </summary>
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            Editable = false;
        }
        /// <summary>
        /// Payment discount date deadline for early payment discount eligibility.
        /// </summary>
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            Editable = false;
        }
        /// <summary>
        /// Currency code for purchase document amounts and financial calculations.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Indicates whether line prices include VAT for tax calculation.
        /// </summary>
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        /// <summary>
        /// Vendor's order number for purchase order cross-referencing.
        /// </summary>
        field(66; "Vendor Order No."; Code[35])
        {
            Caption = 'Vendor Order No.';
        }
        /// <summary>
        /// Vendor's invoice number for invoice matching and reconciliation.
        /// </summary>
        field(68; "Vendor Invoice No."; Code[35])
        {
            Caption = 'Vendor Invoice No.';
            Editable = false;
        }
        /// <summary>
        /// Vendor's credit memo number for credit processing and returns.
        /// </summary>
        field(69; "Vendor Cr. Memo No."; Code[35])
        {
            Caption = 'Vendor Cr. Memo No.';
            Editable = false;
        }
        /// <summary>
        /// Sell-to customer number for drop shipment and direct delivery scenarios.
        /// </summary>
        field(72; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            Editable = false;
        }
        /// <summary>
        /// Ship-to postal code for delivery location identification.
        /// </summary>
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            Editable = false;
        }
        /// <summary>
        /// Ship-to county for regional delivery address specification.
        /// </summary>
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        /// <summary>
        /// Ship-to country/region code for international delivery logistics.
        /// </summary>
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Document date for this inbox purchase document.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        /// <summary>
        /// Intercompany partner code that sent this inbox purchase document.
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
        field(201; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Source of this transaction indicating whether it was returned by partner or created by partner.
        /// </summary>
        field(202; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Ship-to phone number for delivery coordination and contact purposes.
        /// </summary>
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        /// <summary>
        /// Requested receipt date for goods delivery planning.
        /// </summary>
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Promised receipt date committed by the IC partner company.
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
        ICInboxPurchLine: Record "IC Inbox Purchase Line";
        DimMgt: Codeunit DimensionManagement;
    begin
        ICInboxPurchLine.SetRange("IC Partner Code", "IC Partner Code");
        ICInboxPurchLine.SetRange("IC Transaction No.", "IC Transaction No.");
        ICInboxPurchLine.SetRange("Transaction Source", "Transaction Source");
        if ICInboxPurchLine.FindFirst() then
            ICInboxPurchLine.DeleteAll(true);
        DimMgt.DeleteICDocDim(
          DATABASE::"IC Inbox Purchase Header", "IC Transaction No.", "IC Partner Code", "Transaction Source", 0);
    end;
}
