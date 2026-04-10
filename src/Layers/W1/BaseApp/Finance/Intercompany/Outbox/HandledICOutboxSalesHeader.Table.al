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
using Microsoft.Sales.Customer;

/// <summary>
/// Stores processed sales document headers for intercompany outbox transactions.
/// Maintains historical archive of transmitted sales documents sent to IC partners.
/// </summary>
/// <remarks>
/// Historical archive table for completed intercompany outbox sales transactions.
/// Supports sales document tracking, audit trails, and transaction history reporting.
/// Integration points: IC Partner, Customer, Currency, sales document processing.
/// </remarks>
table 430 "Handled IC Outbox Sales Header"
{
    Caption = 'Handled IC Outbox Sales Header';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Sales document type for intercompany transaction processing.
        /// </summary>
        field(1; "Document Type"; Enum "IC Sales Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        /// <summary>
        /// Customer number for the sales transaction.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Unique document number for the sales transaction.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        /// <summary>
        /// Customer to be invoiced for the sales transaction.
        /// </summary>
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Ship-to name for delivery location.
        /// </summary>
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            Editable = false;
        }
        /// <summary>
        /// Ship-to address line 1 for delivery location.
        /// </summary>
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            Editable = false;
        }
        /// <summary>
        /// Ship-to address line 2 for delivery location.
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
        /// Posting date for the sales transaction.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        /// <summary>
        /// Payment due date for the sales transaction.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        /// <summary>
        /// Payment discount percentage for early payment.
        /// </summary>
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            Editable = false;
        }
        /// <summary>
        /// Payment discount date for early payment calculation.
        /// </summary>
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            Editable = false;
        }
        /// <summary>
        /// Currency code for the sales transaction amounts.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Indicates whether prices include VAT.
        /// </summary>
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        /// <summary>
        /// Order number reference for the sales transaction.
        /// </summary>
        field(44; "Order No."; Code[20])
        {
            Caption = 'Order No.';
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
            Editable = false;
        }
        /// <summary>
        /// External document number for customer reference.
        /// </summary>
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
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
        /// Requested delivery date for shipment planning.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            Editable = false;
        }
        /// <summary>
        /// Company's promised delivery date for shipment confirmation.
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
        HndlICOutboxSalesLine: Record "Handled IC Outbox Sales Line";
        DimMgt: Codeunit DimensionManagement;
    begin
        HndlICOutboxSalesLine.SetRange("IC Partner Code", "IC Partner Code");
        HndlICOutboxSalesLine.SetRange("IC Transaction No.", "IC Transaction No.");
        HndlICOutboxSalesLine.SetRange("Transaction Source", "Transaction Source");
        if HndlICOutboxSalesLine.FindFirst() then
            HndlICOutboxSalesLine.DeleteAll(true);
        DimMgt.DeleteICDocDim(
          DATABASE::"Handled IC Outbox Sales Header", "IC Transaction No.", "IC Partner Code", "Transaction Source", 0);
    end;
}
