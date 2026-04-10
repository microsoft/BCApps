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
/// Archives purchase document header information for processed intercompany inbox transactions.
/// Stores vendor details, shipping addresses, payment terms, and transaction metadata for historical tracking and audit purposes.
/// </summary>
table 440 "Handled IC Inbox Purch. Header"
{
    Caption = 'Handled IC Inbox Purch. Header';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of purchase document for this handled header (Order, Invoice, Credit Memo, Return Order).
        /// </summary>
        field(1; "Document Type"; Enum "IC Purchase Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Vendor number for the buy-from vendor in this handled purchase document.
        /// </summary>
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        /// <summary>
        /// Document number of the handled purchase document.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        /// <summary>
        /// Vendor number for payment in this handled purchase document.
        /// </summary>
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        /// <summary>
        /// Partner's reference for this archived purchase document for cross-referencing.
        /// </summary>
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        /// <summary>
        /// Ship-to recipient name for archived delivery address identification.
        /// </summary>
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            Editable = false;
        }
        /// <summary>
        /// Primary ship-to address line for archived delivery location.
        /// </summary>
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            Editable = false;
        }
        /// <summary>
        /// Additional ship-to address line for extended archived delivery location details.
        /// </summary>
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            Editable = false;
        }
        /// <summary>
        /// Ship-to city for archived delivery address location.
        /// </summary>
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            Editable = false;
        }
        /// <summary>
        /// Posting date when the archived purchase document was processed.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Expected receipt date for archived delivery scheduling reference.
        /// </summary>
        field(21; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Payment due date for archived payment terms tracking.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        /// <summary>
        /// Payment discount percentage for archived early payment terms.
        /// </summary>
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            Editable = false;
        }
        /// <summary>
        /// Payment discount date deadline for archived early payment incentive.
        /// </summary>
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            Editable = false;
        }
        /// <summary>
        /// Currency code for archived transaction monetary denomination.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Indicates whether archived prices include VAT for proper tax calculation reference.
        /// </summary>
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        /// <summary>
        /// Vendor's order number for archived cross-reference and tracking.
        /// </summary>
        field(66; "Vendor Order No."; Code[35])
        {
            Caption = 'Vendor Order No.';
        }
        /// <summary>
        /// Vendor's invoice number for archived billing reference and payment matching.
        /// </summary>
        field(68; "Vendor Invoice No."; Code[35])
        {
            Caption = 'Vendor Invoice No.';
            Editable = false;
        }
        /// <summary>
        /// Vendor's credit memo number for archived return and adjustment tracking.
        /// </summary>
        field(69; "Vendor Cr. Memo No."; Code[35])
        {
            Caption = 'Vendor Cr. Memo No.';
            Editable = false;
        }
        /// <summary>
        /// Sell-to customer number for archived intercompany transaction reference.
        /// </summary>
        field(72; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            Editable = false;
        }
        /// <summary>
        /// Ship-to postal code for archived delivery address location.
        /// </summary>
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            Editable = false;
        }
        /// <summary>
        /// Ship-to county/state for archived delivery address region.
        /// </summary>
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        /// <summary>
        /// Ship-to country/region code for archived delivery address identification.
        /// </summary>
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Document date for this handled purchase document.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        /// <summary>
        /// Intercompany partner code that sent this handled purchase document.
        /// </summary>
        field(125; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Unique transaction number identifying the handled intercompany transaction.
        /// </summary>
        field(201; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Source of this handled transaction indicating whether it was returned by partner or created by partner.
        /// </summary>
        field(202; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Ship-to phone number for archived delivery contact information.
        /// </summary>
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        /// <summary>
        /// Requested receipt date for archived delivery requirement tracking.
        /// </summary>
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Promised receipt date for archived delivery commitment tracking.
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
        HndlICInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        DimMgt: Codeunit DimensionManagement;
    begin
        HndlICInboxPurchLine.SetRange("IC Partner Code", "IC Partner Code");
        HndlICInboxPurchLine.SetRange("IC Transaction No.", "IC Transaction No.");
        HndlICInboxPurchLine.SetRange("Transaction Source", "Transaction Source");
        if HndlICInboxPurchLine.FindFirst() then
            HndlICInboxPurchLine.DeleteAll(true);
        DimMgt.DeleteICDocDim(
          DATABASE::"Handled IC Inbox Purch. Header", "IC Transaction No.", "IC Partner Code", "Transaction Source", 0);
    end;
}
