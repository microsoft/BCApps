// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Intercompany.Setup;
using Microsoft.Sales.Customer;

/// <summary>
/// Archives sales document header information for processed intercompany inbox transactions.
/// Stores customer details, shipping addresses, payment terms, and transaction metadata for historical tracking and audit purposes.
/// </summary>
table 438 "Handled IC Inbox Sales Header"
{
    Caption = 'Handled IC Inbox Sales Header';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

    fields
    {
        /// <summary>
        /// Type of sales document for this handled header (Order, Invoice, Credit Memo, Return Order).
        /// </summary>
        field(1; "Document Type"; Enum "IC Sales Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Customer number for the sell-to customer in this handled sales document.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Document number of the handled sales document.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        /// <summary>
        /// Customer number for billing in this handled sales document.
        /// </summary>
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Ship-to contact name for this handled sales document.
        /// </summary>
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            Editable = false;
        }
        /// <summary>
        /// Ship-to address line 1 for this handled sales document.
        /// </summary>
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            Editable = false;
        }
        /// <summary>
        /// Ship-to address line 2 for this handled sales document.
        /// </summary>
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            Editable = false;
        }
        /// <summary>
        /// Ship-to city for this handled sales document.
        /// </summary>
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            Editable = false;
        }
        /// <summary>
        /// Posting date for this handled sales document.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Due date for payment of this handled sales document.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        /// <summary>
        /// Payment discount percentage for early payment of this handled sales document.
        /// </summary>
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            Editable = false;
        }
        /// <summary>
        /// Payment discount date for early payment of this handled sales document.
        /// </summary>
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            Editable = false;
        }
        /// <summary>
        /// Currency code for amounts in this handled sales document.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Indicates whether prices include VAT in this handled sales document.
        /// </summary>
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        /// <summary>
        /// Ship-to postal code for this handled sales document.
        /// </summary>
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            Editable = false;
        }
        /// <summary>
        /// Ship-to county for this handled sales document.
        /// </summary>
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        /// <summary>
        /// Ship-to country/region code for this handled sales document.
        /// </summary>
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Document date for this handled sales document.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            Editable = false;
        }
        /// <summary>
        /// External document number reference for this handled sales document.
        /// </summary>
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        /// <summary>
        /// Intercompany partner code that sent this handled sales document.
        /// </summary>
        field(125; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
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
        /// Ship-to phone number for this handled sales document.
        /// </summary>
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        /// <summary>
        /// Requested delivery date for this handled sales document.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            Editable = false;
        }
        /// <summary>
        /// Promised delivery date for this handled sales document.
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
}
#endif
