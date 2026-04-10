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
using Microsoft.Sales.Customer;

/// <summary>
/// Stores sales document header information for intercompany transactions received from partner companies.
/// Contains customer details, shipping information, and transaction parameters for IC sales documents.
/// </summary>
table 434 "IC Inbox Sales Header"
{
    Caption = 'IC Inbox Sales Header';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of sales document (Order, Invoice, Credit Memo, etc.) received from IC partner.
        /// </summary>
        field(1; "Document Type"; Enum "IC Sales Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Customer number for the sell-to customer in the IC sales transaction.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Document number for this intercompany sales document.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        /// <summary>
        /// Bill-to customer number for invoice processing and payment collection.
        /// </summary>
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
            TableRelation = Customer;
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
        /// Posting date for the sales document in the general ledger.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
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
        /// Currency code for sales document amounts and financial calculations.
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
        /// Document creation date for transaction tracking and audit trail.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        /// <summary>
        /// External document number from partner company for cross-referencing.
        /// </summary>
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        /// <summary>
        /// Intercompany partner code that sent this inbox sales document.
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
        /// Requested delivery date for goods delivery planning.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            Editable = false;
        }
        /// <summary>
        /// Promised delivery date committed by the IC partner company.
        /// </summary>
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
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
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        DimMgt: Codeunit DimensionManagement;
    begin
        ICInboxSalesLine.SetRange("IC Partner Code", "IC Partner Code");
        ICInboxSalesLine.SetRange("IC Transaction No.", "IC Transaction No.");
        ICInboxSalesLine.SetRange("Transaction Source", "Transaction Source");
        if ICInboxSalesLine.FindFirst() then
            ICInboxSalesLine.DeleteAll(true);
        DimMgt.DeleteICDocDim(
          DATABASE::"IC Inbox Sales Header", "IC Transaction No.", "IC Partner Code", "Transaction Source", 0);
    end;
}
