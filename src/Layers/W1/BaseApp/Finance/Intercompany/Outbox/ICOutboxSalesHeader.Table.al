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
/// Stores sales document headers for intercompany outbox transactions pending transmission to partner companies.
/// Manages sales-specific fields, customer information, and shipping details for intercompany sales processes.
/// </summary>
/// <remarks>
/// Staging table for outbound intercompany sales documents. Integrates with IC Outbox Transaction and IC Outbox Sales Line.
/// Key relationships: IC Partner, Customer, Currency, IC Outbox Sales Line.
/// Extensible via table extensions for custom sales document fields and partner-specific requirements.
/// </remarks>
table 426 "IC Outbox Sales Header"
{
    Caption = 'IC Outbox Sales Header';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Sales document type for the intercompany outbox transaction.
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
            TableRelation = Customer;
        }
        /// <summary>
        /// Document number for the intercompany sales header.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        /// <summary>
        /// Bill-to customer number for invoicing in the intercompany sales transaction.
        /// </summary>
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        /// <summary>
        /// Ship-to customer name for delivery address identification.
        /// </summary>
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            Editable = false;
        }
        /// <summary>
        /// Primary ship-to address line for customer delivery.
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
        /// Ship-to city for customer delivery location.
        /// </summary>
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            Editable = false;
        }
        /// <summary>
        /// Posting date for the sales document transaction.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Payment due date for the sales document.
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
        /// Currency code for the sales document amounts.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Indicates whether prices on the sales document include VAT.
        /// </summary>
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        /// <summary>
        /// Order number reference for the sales document.
        /// </summary>
        field(44; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        /// <summary>
        /// Ship-to postal code for customer delivery location.
        /// </summary>
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            Editable = false;
        }
        /// <summary>
        /// Ship-to county for customer delivery location.
        /// </summary>
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        /// <summary>
        /// Ship-to country/region code for customer delivery location.
        /// </summary>
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Document date for the sales transaction.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        /// <summary>
        /// External document number reference from the customer or partner.
        /// </summary>
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        /// <summary>
        /// Code of the intercompany partner receiving this sales document.
        /// </summary>
        field(125; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Intercompany transaction number linking this header to the parent transaction.
        /// </summary>
        field(201; "IC Transaction No."; Integer)
        {
            Caption = 'IC Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Source of the intercompany transaction indicating creation or rejection origin.
        /// </summary>
        field(202; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Ship-to phone number for customer delivery contact.
        /// </summary>
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        /// <summary>
        /// Delivery date requested by the customer for this sales order.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            Editable = false;
        }
        /// <summary>
        /// Delivery date promised to the customer for this sales order.
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
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        DimMgt: Codeunit DimensionManagement;
    begin
        ICOutboxSalesLine.SetRange("IC Partner Code", "IC Partner Code");
        ICOutboxSalesLine.SetRange("IC Transaction No.", "IC Transaction No.");
        ICOutboxSalesLine.SetRange("Transaction Source", "Transaction Source");
        if ICOutboxSalesLine.FindFirst() then
            ICOutboxSalesLine.DeleteAll(true);
        DimMgt.DeleteICDocDim(
          DATABASE::"IC Outbox Sales Header", "IC Transaction No.", "IC Partner Code", "Transaction Source", 0);
    end;
}
