// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Setup;

/// <summary>
/// Temporary buffer table for staging intercompany sales header data during API-based data exchange.
/// Facilitates sales document validation and transformation before posting to target partner systems.
/// </summary>
table 608 "Buffer IC Inbox Sales Header"
{
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        /// <summary>
        /// Type of sales document being processed (Order, Invoice, Credit Memo, etc.).
        /// </summary>
        field(1; "Document Type"; Enum "IC Sales Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Customer number for the sell-to customer in the intercompany sales transaction.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            Editable = false;
        }
        /// <summary>
        /// Document number for the intercompany sales transaction being processed.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        /// <summary>
        /// Customer number for the bill-to customer in the intercompany sales transaction.
        /// </summary>
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
        }
        /// <summary>
        /// Name of the ship-to address for delivery of sold goods or services.
        /// </summary>
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            Editable = false;
        }
        /// <summary>
        /// Primary street address for goods delivery location.
        /// </summary>
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            Editable = false;
        }
        /// <summary>
        /// Secondary address line for additional delivery location details.
        /// </summary>
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            Editable = false;
        }
        /// <summary>
        /// City name for the delivery address location.
        /// </summary>
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            Editable = false;
        }
        /// <summary>
        /// Date when the sales document will be posted to the general ledger.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Payment due date for the sales document based on payment terms.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// Payment discount percentage available for early payment within discount period.
        /// </summary>
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            Editable = false;
        }
        /// <summary>
        /// Last date when payment discount percentage can be applied.
        /// </summary>
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            Editable = false;
        }
        /// <summary>
        /// Currency code for the sales transaction amounts and calculations.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether document prices include VAT in the calculation amounts.
        /// </summary>
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        /// <summary>
        /// Postal code for the ship-to delivery address.
        /// </summary>
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            Editable = false;
        }
        /// <summary>
        /// County or state information for the ship-to delivery address.
        /// </summary>
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        /// <summary>
        /// Country or region code for the ship-to delivery address.
        /// </summary>
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
        }
        /// <summary>
        /// Original document date when the sales document was created.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        /// <summary>
        /// External document number reference from customer or originating partner system.
        /// </summary>
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
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
        field(201; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Source of the intercompany transaction (Created by Current Company, Returned by IC Partner, etc.).
        /// </summary>
        field(202; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Phone number for the ship-to delivery location contact.
        /// </summary>
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
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
        key(Key1; "IC Transaction No.", "IC Partner Code", "Transaction Source")
        {
            Clustered = true;
        }
    }
}
