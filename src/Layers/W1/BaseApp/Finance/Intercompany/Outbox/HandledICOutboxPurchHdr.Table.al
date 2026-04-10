// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Purchases.Vendor;

/// <summary>
/// Stores handled intercompany outbox purchase document headers that have been processed and archived.
/// Contains purchase header information sent to intercompany partners through the outbox process.
/// </summary>
/// <remarks>
/// Archive table for processed IC outbox purchase transactions. Records are moved here after successful 
/// processing or handling by the intercompany partner. Links to handled purchase lines and dimension data.
/// </remarks>
table 432 "Handled IC Outbox Purch. Hdr"
{
    Caption = 'Handled IC Outbox Purch. Hdr';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of purchase document being processed in the intercompany transaction.
        /// </summary>
        field(1; "Document Type"; Enum "IC Purchase Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Vendor number from which the purchase is being made in the intercompany transaction.
        /// </summary>
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        /// <summary>
        /// Document number uniquely identifying the purchase document in the intercompany transaction.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        /// <summary>
        /// Vendor number to whom payment will be made for the intercompany purchase transaction.
        /// </summary>
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        /// <summary>
        /// External reference provided by the vendor for tracking the intercompany purchase.
        /// </summary>
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        /// <summary>
        /// Name of the location where goods will be shipped for the intercompany purchase.
        /// </summary>
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            Editable = false;
        }
        /// <summary>
        /// Primary address line for the shipping destination of the intercompany purchase.
        /// </summary>
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            Editable = false;
        }
        /// <summary>
        /// Secondary address line for the shipping destination of the intercompany purchase.
        /// </summary>
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            Editable = false;
        }
        /// <summary>
        /// City name for the shipping destination of the intercompany purchase.
        /// </summary>
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            Editable = false;
        }
        /// <summary>
        /// Date when the intercompany purchase transaction will be posted to the general ledger.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Expected date when goods or services will be received for the intercompany purchase.
        /// </summary>
        field(21; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Date when payment is due for the intercompany purchase transaction.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        /// <summary>
        /// Percentage discount applied for early payment of the intercompany purchase.
        /// </summary>
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            Editable = false;
        }
        /// <summary>
        /// Date until which the payment discount is valid for the intercompany purchase.
        /// </summary>
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            Editable = false;
        }
        /// <summary>
        /// Currency code used for the intercompany purchase transaction amounts.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Indicates whether prices in the intercompany purchase include VAT amounts.
        /// </summary>
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        /// <summary>
        /// Invoice number provided by the vendor for the intercompany purchase transaction.
        /// </summary>
        field(68; "Vendor Invoice No."; Code[35])
        {
            Caption = 'Vendor Invoice No.';
            Editable = false;
        }
        /// <summary>
        /// Credit memo number provided by the vendor for the intercompany purchase transaction.
        /// </summary>
        field(69; "Vendor Cr. Memo No."; Code[35])
        {
            Caption = 'Vendor Cr. Memo No.';
            Editable = false;
        }
        /// <summary>
        /// Customer number for drop shipment scenarios in the intercompany purchase.
        /// </summary>
        field(72; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            Editable = false;
        }
        /// <summary>
        /// Postal code for the shipping destination of the intercompany purchase.
        /// </summary>
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            Editable = false;
        }
        /// <summary>
        /// County or state for the shipping destination of the intercompany purchase.
        /// </summary>
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        /// <summary>
        /// Country or region code for the shipping destination of the intercompany purchase.
        /// </summary>
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Document creation date for the intercompany purchase transaction.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        /// <summary>
        /// Code identifying the intercompany partner involved in this purchase transaction.
        /// </summary>
        field(125; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Unique transaction number identifying this intercompany outbox transaction.
        /// </summary>
        field(201; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Source origin of the intercompany transaction indicating how it was created or processed.
        /// </summary>
        field(202; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Phone number for the shipping destination contact of the intercompany purchase.
        /// </summary>
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        /// <summary>
        /// Requested delivery date for goods or services in the intercompany purchase.
        /// </summary>
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
            Editable = false;
        }
        /// <summary>
        /// Confirmed delivery date promised by the vendor for the intercompany purchase.
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
        HndlICOutboxPurchLine: Record "Handled IC Outbox Purch. Line";
        DimMgt: Codeunit DimensionManagement;
    begin
        HndlICOutboxPurchLine.SetRange("IC Partner Code", "IC Partner Code");
        HndlICOutboxPurchLine.SetRange("IC Transaction No.", "IC Transaction No.");
        HndlICOutboxPurchLine.SetRange("Transaction Source", "Transaction Source");
        if HndlICOutboxPurchLine.FindFirst() then
            HndlICOutboxPurchLine.DeleteAll(true);
        DimMgt.DeleteICDocDim(
          DATABASE::"Handled IC Outbox Purch. Hdr", "IC Transaction No.", "IC Partner Code", "Transaction Source", 0);
    end;
}
