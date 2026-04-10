// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Automation;
using System.Email;
using System.Globalization;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;

/// <summary>
/// Stores header information for posted sales invoices including customer details, amounts, and payment terms.
/// </summary>
table 112 "Sales Invoice Header"
{
    Caption = 'Sales Invoice Header';
    DataCaptionFields = "No.", "Sell-to Customer Name";
    DrillDownPageID = "Posted Sales Invoices";
    LookupPageID = "Posted Sales Invoices";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the customer number who received the shipped items on this invoice.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;
            ToolTip = 'Specifies the number of the customer that you shipped the items on the invoice to.';
        }
        /// <summary>
        /// Specifies the unique document number of the posted sales invoice.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the posted sales invoice number. Each posted sales invoice gets a unique number. Typically, the number is generated based on a number series.';
        }
        /// <summary>
        /// Specifies the customer number to whom the invoice was sent for payment.
        /// </summary>
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            ToolTip = 'Specifies the number of the customer that you send or sent the invoice to.';
            NotBlank = true;
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies the name of the customer receiving the invoice for payment.
        /// </summary>
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
        }
        /// <summary>
        /// Specifies additional name information for the bill-to customer.
        /// </summary>
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer that you send or sent the invoice to.';
        }
        /// <summary>
        /// Specifies the street address of the customer receiving the invoice.
        /// </summary>
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            ToolTip = 'Specifies the address of the customer that the invoice was sent to.';
        }
        /// <summary>
        /// Specifies additional street address information for the bill-to customer.
        /// </summary>
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        /// <summary>
        /// Specifies the city of the customer receiving the invoice.
        /// </summary>
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            ToolTip = 'Specifies the city of the customer on the sales document.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the name of the contact person at the bill-to customer's address.
        /// </summary>
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
            ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
        }
        /// <summary>
        /// Specifies the customer's own reference number for this document.
        /// </summary>
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            ToolTip = 'Specifies the customer''s reference. The contents will be printed on sales documents.';
        }
        /// <summary>
        /// Specifies the code for an alternate ship-to address.
        /// </summary>
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies the address on purchase orders shipped with a drop shipment directly from the vendor to a customer.';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));
        }
        /// <summary>
        /// Specifies the name of the recipient at the ship-to address.
        /// </summary>
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies additional name information for the ship-to address.
        /// </summary>
        field(14; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
            ToolTip = 'Specifies an additional part of the the name of the customer that you delivered the items to.';
        }
        /// <summary>
        /// Specifies the street address where items were shipped.
        /// </summary>
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            ToolTip = 'Specifies the address that the items on the invoice were shipped to.';
        }
        /// <summary>
        /// Specifies additional street address information for the ship-to address.
        /// </summary>
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        /// <summary>
        /// Specifies the city of the ship-to address.
        /// </summary>
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            ToolTip = 'Specifies the city of the customer on the sales document.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the name of the contact person at the ship-to address.
        /// </summary>
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
            ToolTip = 'Specifies the name of the person you regularly contact at the address that the items were shipped to.';
        }
        /// <summary>
        /// Specifies the date when the sales order was created.
        /// </summary>
        field(19; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        /// <summary>
        /// Specifies the date when the invoice was posted to the ledger.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date on which the invoice was posted.';
        }
        /// <summary>
        /// Specifies the date when the items were shipped to the customer.
        /// </summary>
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        /// <summary>
        /// Specifies a description of the posting that appears in the general ledger.
        /// </summary>
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
        }
        /// <summary>
        /// Specifies the code for payment terms used for this invoice.
        /// </summary>
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount on the sales document.';
            TableRelation = "Payment Terms";
        }
        /// <summary>
        /// Specifies the date by which payment for this invoice is due.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the date on which the invoice is due for payment.';
        }
        /// <summary>
        /// Specifies the percentage of payment discount given if payment is made within the discount period.
        /// </summary>
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            ToolTip = 'Specifies the payment discount percent granted if payment is made on or before the date in the Pmt. Discount Date field.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the last date for taking the payment discount.
        /// </summary>
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
        }
        /// <summary>
        /// Specifies the shipment method used for delivering the items.
        /// </summary>
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            ToolTip = 'Specifies the code that represents the shipment method for the invoice.';
            TableRelation = "Shipment Method";
        }
        /// <summary>
        /// Specifies the warehouse location from which items were shipped.
        /// </summary>
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the code for the location from which the items were shipped.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        /// <summary>
        /// Specifies the first global dimension code used for analysis.
        /// </summary>
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Specifies the second global dimension code used for analysis.
        /// </summary>
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Specifies the customer posting group that determines the G/L accounts for posting.
        /// </summary>
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            ToolTip = 'Specifies the customer''s market type to link business transactions to.';
            Editable = false;
            TableRelation = "Customer Posting Group";
        }
        /// <summary>
        /// Specifies the currency code for amounts on the invoice.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code of the invoice.';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Specifies the exchange rate between the document currency and the local currency.
        /// </summary>
        field(33; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the customer price group for determining sales prices.
        /// </summary>
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        /// <summary>
        /// Indicates whether the unit prices on the invoice include VAT.
        /// </summary>
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        /// <summary>
        /// Specifies the code used to determine invoice discount terms.
        /// </summary>
        field(37; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
        }
        /// <summary>
        /// Specifies the customer discount group for determining line discounts.
        /// </summary>
        field(40; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        /// <summary>
        /// Specifies the language code used for printing documents.
        /// </summary>
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        /// <summary>
        /// Specifies the regional format for dates, numbers, and other data on printed documents.
        /// </summary>
        field(42; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        /// <summary>
        /// Specifies the salesperson responsible for this sale.
        /// </summary>
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            ToolTip = 'Specifies which salesperson is associated with the invoice.';
            TableRelation = "Salesperson/Purchaser";
        }
        /// <summary>
        /// Specifies the sales order number from which this invoice was created.
        /// </summary>
        field(44; "Order No."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Order No.';
            ToolTip = 'Specifies the number of the related order.';
        }
        /// <summary>
        /// Indicates whether comments exist for this invoice.
        /// </summary>
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Sales Comment Line" where("Document Type" = const("Posted Invoice"),
                                                            "No." = field("No."),
                                                            "Document Line No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies how many times the invoice has been printed.
        /// </summary>
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            ToolTip = 'Specifies how many times the document has been printed.';
            Editable = false;
        }
        /// <summary>
        /// Specifies a code indicating that processing of the invoice is on hold.
        /// </summary>
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        /// <summary>
        /// Specifies the type of document this invoice applies to for payment application.
        /// </summary>
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        /// <summary>
        /// Specifies the document number this invoice applies to for payment application.
        /// </summary>
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
            begin
                CustLedgEntry.SetCurrentKey("Document No.");
                CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                OnLookupAppliesToDocNoOnAfterSetFilters(CustLedgEntry, Rec);
                PAGE.Run(0, CustLedgEntry);
            end;
        }
        /// <summary>
        /// Specifies the balancing account number used for posting.
        /// </summary>
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        /// <summary>
        /// Contains the total invoice amount excluding VAT.
        /// </summary>
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Sales Invoice Line".Amount where("Document No." = field("No.")));
            Caption = 'Amount';
            ToolTip = 'Specifies the total, in the currency of the invoice, of the amounts on all the invoice lines. The amount does not include VAT.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total invoice amount including VAT.
        /// </summary>
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Sales Invoice Line"."Amount Including VAT" where("Document No." = field("No.")));
            Caption = 'Amount Including VAT';
            ToolTip = 'Specifies the total of the amounts, including VAT, on all the lines on the document.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the customer's VAT registration number.
        /// </summary>
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            ToolTip = 'Specifies the customer''s VAT registration number for customers.';
        }
        /// <summary>
        /// Specifies the customer's company registration number.
        /// </summary>
        field(72; "Registration Number"; Text[50])
        {
            Caption = 'Registration No.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the reason code for the transaction.
        /// </summary>
        field(73; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Specifies the general business posting group for determining G/L accounts.
        /// </summary>
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// Indicates whether the transaction is part of a three-party trade within the EU.
        /// </summary>
        field(75; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            ToolTip = 'Specifies whether the invoice was part of an EU 3-party trade transaction.';
        }
        /// <summary>
        /// Specifies the transaction type for Intrastat reporting.
        /// </summary>
        field(76; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        /// <summary>
        /// Specifies the transport method for Intrastat reporting.
        /// </summary>
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            ToolTip = 'Specifies the transport method of the sales header that this line was posted from.';
            TableRelation = "Transport Method";
        }
        /// <summary>
        /// Specifies the country or region code for VAT purposes.
        /// </summary>
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Specifies the name of the sell-to customer.
        /// </summary>
        field(79; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            ToolTip = 'Specifies the name of the customer that you shipped the items on the invoice to.';
        }
        /// <summary>
        /// Specifies additional name information for the sell-to customer.
        /// </summary>
        field(80; "Sell-to Customer Name 2"; Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer who will receive the products and be billed by default.';
        }
        /// <summary>
        /// Specifies the street address of the sell-to customer.
        /// </summary>
        field(81; "Sell-to Address"; Text[100])
        {
            Caption = 'Sell-to Address';
            ToolTip = 'Specifies the address of the customer that the items on the invoice were shipped to.';
        }
        /// <summary>
        /// Specifies additional street address information for the sell-to customer.
        /// </summary>
        field(82; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        /// <summary>
        /// Specifies the city of the sell-to customer.
        /// </summary>
        field(83; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            ToolTip = 'Specifies the city of the customer on the sales document.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the name of the contact person at the sell-to customer.
        /// </summary>
        field(84; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';
            ToolTip = 'Specifies the name of the contact person at the customer''s main address.';
        }
        /// <summary>
        /// Specifies the postal code of the bill-to customer.
        /// </summary>
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            ToolTip = 'Specifies the postal code of the customer''s billing address.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the county or state of the bill-to customer.
        /// </summary>
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
        /// <summary>
        /// Specifies the country or region of the bill-to customer.
        /// </summary>
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            ToolTip = 'Specifies the country or region of the address.';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Specifies the postal code of the sell-to customer.
        /// </summary>
        field(88; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            ToolTip = 'Specifies the postal code of the customer''s main address.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the county or state of the sell-to customer.
        /// </summary>
        field(89; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,2,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
        /// <summary>
        /// Specifies the country or region of the sell-to customer.
        /// </summary>
        field(90; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            ToolTip = 'Specifies the country or region of the address.';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Specifies the postal code of the ship-to address.
        /// </summary>
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the county or state of the ship-to address.
        /// </summary>
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
        /// <summary>
        /// Specifies the country or region of the ship-to address.
        /// </summary>
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            ToolTip = 'Specifies the country or region of the address.';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Specifies the type of balancing account used for posting.
        /// </summary>
        field(94; "Bal. Account Type"; enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        /// <summary>
        /// Specifies the exit point for goods leaving the country for Intrastat reporting.
        /// </summary>
        field(97; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            ToolTip = 'Specifies the point of exit through which you ship the items out of your country/region, for reporting to Intrastat.';
            TableRelation = "Entry/Exit Point";
        }
        /// <summary>
        /// Indicates whether this invoice is a correction entry.
        /// </summary>
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        /// <summary>
        /// Specifies the date when the document was created.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date on which you created the sales document.';
        }
        /// <summary>
        /// Specifies an external document number such as the customer's purchase order number.
        /// </summary>
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies the external document number that is entered on the sales header that this line was posted from.';
        }
        /// <summary>
        /// Specifies the geographic area for Intrastat reporting.
        /// </summary>
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            ToolTip = 'Specifies the area code used in the invoice.';
            TableRelation = Area;
        }
        /// <summary>
        /// Specifies additional transaction details for Intrastat reporting.
        /// </summary>
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            ToolTip = 'Specifies the transaction specification that was used in the invoice.';
            TableRelation = "Transaction Specification";
        }
        /// <summary>
        /// Specifies the method of payment for the invoice.
        /// </summary>
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            ToolTip = 'Specifies how the customer must pay for products on the sales document.';
            TableRelation = "Payment Method";
        }
        /// <summary>
        /// Specifies the shipping agent used for delivery.
        /// </summary>
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
            TableRelation = "Shipping Agent";
        }
        /// <summary>
        /// Specifies the tracking number for tracking shipped packages.
        /// </summary>
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(106; "Package Tracking No."; Text[50])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Package Tracking No.';
            ToolTip = 'Specifies the shipping agent''s package number.';
        }
        /// <summary>
        /// Specifies the number series used before the invoice was posted.
        /// </summary>
        field(107; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the number series used for the posted invoice.
        /// </summary>
        field(108; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the number series of the original sales order.
        /// </summary>
        field(110; "Order No. Series"; Code[20])
        {
            Caption = 'Order No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the document number that was assigned before posting.
        /// </summary>
        field(111; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
            ToolTip = 'Specifies the number of the sales document that the posted invoice was created for.';
        }
        /// <summary>
        /// Specifies the user who posted the invoice.
        /// </summary>
        field(112; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Specifies the source code that identifies where the entry was created.
        /// </summary>
        field(113; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Specifies the tax area code for sales tax calculation.
        /// </summary>
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the customer is liable for sales tax.
        /// </summary>
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
        }
        /// <summary>
        /// Specifies the VAT business posting group for VAT calculation.
        /// </summary>
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Specifies the percentage of the payment discount that is deducted from the VAT base.
        /// </summary>
        field(119; "VAT Base Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the method used to calculate the invoice discount.
        /// </summary>
        field(121; "Invoice Discount Calculation"; Option)
        {
            Caption = 'Invoice Discount Calculation';
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        /// <summary>
        /// Specifies the invoice discount value as a percentage or amount.
        /// </summary>
        field(122; "Invoice Discount Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Invoice Discount Value';
        }
        /// <summary>
        /// Specifies the number series for prepayment invoices.
        /// </summary>
        field(131; "Prepayment No. Series"; Code[20])
        {
            Caption = 'Prepayment No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Indicates whether this invoice is a prepayment invoice.
        /// </summary>
        field(136; "Prepayment Invoice"; Boolean)
        {
            Caption = 'Prepayment Invoice';
        }
        /// <summary>
        /// Specifies the order number associated with the prepayment.
        /// </summary>
        field(137; "Prepayment Order No."; Code[20])
        {
            Caption = 'Prepayment Order No.';
        }
        /// <summary>
        /// Specifies the quote number from which the invoice originated.
        /// </summary>
        field(151; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
            ToolTip = 'Specifies the number of the sales quote document if a quote was used to start the sales process.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the company bank account for receiving payment.
        /// </summary>
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
        }
        /// <summary>
        /// Indicates whether an alternative VAT registration number was used.
        /// </summary>
        field(166; "Alt. VAT Registration No."; Boolean)
        {
            Caption = 'Alternative VAT Registration No.';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether an alternative general business posting group was used.
        /// </summary>
        field(167; "Alt. Gen. Bus Posting Group"; Boolean)
        {
            Caption = 'Alternative Gen. Bus. Posting Group';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether an alternative VAT business posting group was used.
        /// </summary>
        field(168; "Alt. VAT Bus Posting Group"; Boolean)
        {
            Caption = 'Alternative VAT Bus. Posting Group';
            Editable = false;
        }
        /// <summary>
        /// Specifies the phone number of the sell-to customer.
        /// </summary>
        field(171; "Sell-to Phone No."; Text[30])
        {
            Caption = 'Sell-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        /// <summary>
        /// Specifies the email address of the sell-to customer.
        /// </summary>
        field(172; "Sell-to E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
        }
        /// <summary>
        /// Specifies the date used for VAT reporting purposes.
        /// </summary>
        field(179; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            ToolTip = 'Specifies the VAT date on the invoice.';
            Editable = false;
        }
        /// <summary>
        /// Specifies a reference number for customer payments.
        /// </summary>
        field(180; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
            ToolTip = 'Specifies the payment of the sales invoice.';
        }
        /// <summary>
        /// Contains the timestamp of when the last email was sent for this invoice.
        /// </summary>
        field(185; "Last Email Sent Time"; DateTime)
        {
            Caption = 'Last Email Sent Time';
            FieldClass = FlowField;
            CalcFormula = max("Email Related Record".SystemCreatedAt where("Table Id" = const(Database::"Sales Invoice Header"),
                                                                           "System Id" = field(SystemId)));
        }
        field(186; "Last Email Sent Message Id"; Guid)
        {
            Caption = 'Last Email Sent Message Id';
            FieldClass = FlowField;
            CalcFormula = lookup("Email Related Record"."Email Message Id" where(SystemCreatedAt = field("Last Email Sent Time")));
        }
        /// <summary>
        /// Contains the work or job description for the invoice.
        /// </summary>
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
        }
        /// <summary>
        /// Specifies the phone number at the ship-to address.
        /// </summary>
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ToolTip = 'Specifies the telephone number of the company''s shipping address.';
            ExtendedDatatype = PhoneNo;
        }
        /// <summary>
        /// Specifies the unique identifier for the dimension set applied to this document.
        /// </summary>
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        /// <summary>
        /// Specifies the ID of the payment service set used for online payments.
        /// </summary>
        field(600; "Payment Service Set ID"; Integer)
        {
            Caption = 'Payment Service Set ID';
        }
        /// <summary>
        /// Specifies the identifier for the document in the document exchange service.
        /// </summary>
        field(710; "Document Exchange Identifier"; Text[50])
        {
            Caption = 'Document Exchange Identifier';
        }
        /// <summary>
        /// Specifies the status of the document exchange process.
        /// </summary>
        field(711; "Document Exchange Status"; Enum "Sales Document Exchange Status")
        {
            Caption = 'Document Exchange Status';
            ToolTip = 'Specifies the status of the document if you are using a document exchange service to send it as an electronic document. The status values are reported by the document exchange service.';
        }
        /// <summary>
        /// Specifies the original identifier of the document in the exchange service.
        /// </summary>
        field(712; "Doc. Exch. Original Identifier"; Text[50])
        {
            Caption = 'Doc. Exch. Original Identifier';
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        /// <summary>
        /// Indicates whether this invoice is coupled to Dynamics 365 Sales.
        /// </summary>
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            ToolTip = 'Specifies that the posted sales order is coupled to a sales order in Dynamics 365 Sales.';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Sales Invoice Header")));
        }
        /// <summary>
        /// Specifies the direct debit mandate ID for collecting payment.
        /// </summary>
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            ToolTip = 'Specifies the direct-debit mandate that the customer has signed to allow direct debit collection of payments.';
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Bill-to Customer No."));
        }
        /// <summary>
        /// Indicates whether the invoice has been fully paid and closed.
        /// </summary>
        field(1302; Closed; Boolean)
        {
            CalcFormula = - exist("Cust. Ledger Entry" where("Entry No." = field("Cust. Ledger Entry No."),
                                                             Open = filter(true)));
            Caption = 'Closed';
            ToolTip = 'Specifies if the posted invoice is paid. The check box will also be selected if a credit memo for the remaining amount has been applied.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the remaining unpaid amount on the invoice.
        /// </summary>
        field(1303; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Cust. Ledger Entry No." = field("Cust. Ledger Entry No.")));
            Caption = 'Remaining Amount';
            ToolTip = 'Specifies the amount that remains to be paid on the sales invoices that are due next week.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the entry number in the customer ledger.
        /// </summary>
        field(1304; "Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Cust. Ledger Entry No.';
            Editable = false;
            TableRelation = "Cust. Ledger Entry"."Entry No.";
        }
        /// <summary>
        /// Contains the total invoice discount amount.
        /// </summary>
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            CalcFormula = sum("Sales Invoice Line"."Inv. Discount Amount" where("Document No." = field("No.")));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether this invoice has been cancelled by a credit memo.
        /// </summary>
        field(1310; Cancelled; Boolean)
        {
            CalcFormula = exist("Cancelled Document" where("Source ID" = const(112),
                                                            "Cancelled Doc. No." = field("No.")));
            Caption = 'Cancelled';
            ToolTip = 'Specifies if the posted sales invoice has been either corrected or canceled.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether this invoice was created to correct a cancelled credit memo.
        /// </summary>
        field(1311; Corrective; Boolean)
        {
            CalcFormula = exist("Cancelled Document" where("Source ID" = const(114),
                                                            "Cancelled By Doc. No." = field("No.")));
            Caption = 'Corrective';
            ToolTip = 'Specifies if the posted sales invoice is a corrective document.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether the associated ledger entry has been reversed.
        /// </summary>
        field(1312; Reversed; Boolean)
        {
            Caption = 'Reversed';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Cust. Ledger Entry".Reversed where("Entry No." = field("Cust. Ledger Entry No.")));
        }
        /// <summary>
        /// Specifies the dispute status code if the invoice is under dispute.
        /// </summary>
        field(1340; "Dispute Status"; Code[10])
        {
            Caption = 'Dispute Status';
            TableRelation = "Dispute Status";
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                UpdateDisputeStatusId();
            end;
        }
        /// <summary>
        /// Specifies the date when the customer promised to pay the invoice.
        /// </summary>
        field(1341; "Promised Pay Date"; Date)
        {
            Caption = 'Promised Pay Date';
            ToolTip = 'Specifies the date on which the customer have promised to pay this invoice.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the marketing campaign associated with this invoice.
        /// </summary>
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        /// <summary>
        /// Specifies the contact number for the sell-to customer.
        /// </summary>
        field(5052; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            ToolTip = 'Specifies a unique identifier for the contact person at the customer the invoice was sent to.';
            TableRelation = Contact;
        }
        /// <summary>
        /// Specifies the contact number for the bill-to customer.
        /// </summary>
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            ToolTip = 'Specifies the number of the contact the invoice was sent to.';
            TableRelation = Contact;
        }
        /// <summary>
        /// Specifies the sales opportunity associated with this invoice.
        /// </summary>
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;
        }
        /// <summary>
        /// Specifies the responsibility center for this invoice.
        /// </summary>
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            ToolTip = 'Specifies the code of the responsibility center associated with the user who created the invoice, your company, or the customer in the sales invoice.';
            TableRelation = "Responsibility Center";
        }
        /// <summary>
        /// Specifies the shipping agent service level used for delivery.
        /// </summary>
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            ToolTip = 'Specifies which shipping agent service is used to transport the items on the sales document to the customer.';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        /// <summary>
        /// Specifies the method used for calculating prices on this invoice.
        /// </summary>
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        /// <summary>
        /// Indicates whether line discounts are allowed on this invoice.
        /// </summary>
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
        }
        /// <summary>
        /// Indicates whether the Get Shipment Lines function was used.
        /// </summary>
        field(7200; "Get Shipment Used"; Boolean)
        {
            Caption = 'Get Shipment Used';
        }
        /// <summary>
        /// Stores the system ID of the draft invoice before posting.
        /// </summary>
        field(8001; "Draft Invoice SystemId"; Guid)
        {
            Caption = 'Draft Invoice SystemId';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Stores the unique identifier for the dispute status record.
        /// </summary>
        field(8010; "Dispute Status Id"; Guid)
        {
            Caption = 'Dispute Status Id';
            TableRelation = "Dispute Status".SystemId;
            trigger OnValidate()
            begin
                UpdateDisputeStatus();
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Order No.")
        {
        }
        key(Key3; "Pre-Assigned No.")
        {
        }
        key(Key4; "Sell-to Customer No.", "External Document No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; "Sell-to Customer No.", "Order Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key6; "Sell-to Customer No.")
        {
        }
        key(Key7; "Prepayment Order No.", "Prepayment Invoice")
        {
        }
        key(Key8; "Bill-to Customer No.")
        {
        }
        key(Key9; "Posting Date")
        {
        }
        key(Key10; "Document Exchange Status")
        {
        }
        key(Key11; "Due Date")
        {
        }
        key(Key12; "Salesperson Code")
        {
        }
        key(Key13; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Sell-to Customer No.", "Bill-to Customer No.", "Posting Date", "Posting Description")
        {
        }
        fieldgroup(Brick; "No.", "Sell-to Customer Name", Amount, "Due Date", "Amount Including VAT")
        {
        }
    }

    trigger OnDelete()
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostSalesDelete: Codeunit "PostSales-Delete";
    begin
        PostSalesDelete.IsDocumentDeletionAllowed("Posting Date");
        CheckNoPrinted();
        LockTable();
        PostSalesDelete.DeleteSalesInvLines(Rec);

        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Posted Invoice");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.DeleteAll();

        ApprovalsMgmt.DeletePostedApprovalEntries(RecordId);

        PostedDeferralHeader.DeleteForDoc(
            Enum::"Deferral Document Type"::Sales.AsInteger(), '', '',
            SalesCommentLine."Document Type"::"Posted Invoice".AsInteger(), "No.");
    end;

    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesSetup: Record "Sales & Receivables Setup";
        DimMgt: Codeunit DimensionManagement;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        UserSetupMgt: Codeunit "User Setup Management";
        DocTxt: Label 'Invoice';
        PaymentReference: Text;
        PaymentReferenceLbl: Text;

    /// <summary>
    /// Checks if the invoice is fully open (no payments applied).
    /// </summary>
    /// <returns>True if the remaining amount equals the amount including VAT.</returns>
    procedure IsFullyOpen(): Boolean
    var
        FullyOpen: Boolean;
        IsHandled: Boolean;
    begin
        OnPostedSalesInvoiceFullyOpen(Rec, FullyOpen, IsHandled);
        if IsHandled then
            exit(FullyOpen);

        CalcFields("Amount Including VAT", "Remaining Amount");
        exit("Amount Including VAT" = "Remaining Amount");
    end;

    /// <summary>
    /// Validates that the invoice has been printed at least once.
    /// </summary>
    procedure CheckNoPrinted()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoPrinted(Rec, IsHandled);
        if IsHandled then
            exit;

        Rec.TestField("No. Printed");
    end;

    /// <summary>
    /// Sends the invoice records using the customer's document sending profile.
    /// </summary>
    procedure SendRecords()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        DocumentTypeTxt: Text[50];
        IsHandled: Boolean;
    begin
        DocumentTypeTxt := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        IsHandled := false;
        OnBeforeSendRecords(DummyReportSelections, Rec, DocumentTypeTxt, IsHandled);
        if not IsHandled then
            DocumentSendingProfile.SendCustomerRecords(
              DummyReportSelections.Usage::"S.Invoice".AsInteger(), Rec, DocumentTypeTxt, "Bill-to Customer No.", "No.",
              FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    /// <summary>
    /// Sends the invoice using a specific document sending profile.
    /// </summary>
    /// <param name="DocumentSendingProfile">The document sending profile to use.</param>
    procedure SendProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    var
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        DocumentTypeTxt: Text[50];
        IsHandled: Boolean;
    begin
        DocumentTypeTxt := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        IsHandled := false;
        OnBeforeSendProfile(DummyReportSelections, Rec, DocumentTypeTxt, IsHandled, DocumentSendingProfile);
        if not IsHandled then
            DocumentSendingProfile.Send(
              DummyReportSelections.Usage::"S.Invoice".AsInteger(), Rec, "No.", "Bill-to Customer No.",
              DocumentTypeTxt, FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    /// <summary>
    /// Prints the selected invoice records.
    /// </summary>
    /// <param name="ShowRequestPage">Whether to show the report request page.</param>
    procedure PrintRecords(ShowRequestPage: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(DummyReportSelections, Rec, ShowRequestPage, IsHandled);
        if not IsHandled then
            DocumentSendingProfile.TrySendToPrinter(
              DummyReportSelections.Usage::"S.Invoice".AsInteger(), Rec, FieldNo("Bill-to Customer No."), ShowRequestPage);
    end;

    /// <summary>
    /// Updates the Dispute Status field from the Dispute Status Id.
    /// </summary>
    procedure UpdateDisputeStatus()
    var
        DisputeStatus: Record "Dispute Status";
    begin
        if not IsNullGuid("Dispute Status Id") then
            DisputeStatus.GetBySystemId("Dispute Status Id");
        Validate("Dispute Status", DisputeStatus.Code);
    end;

    /// <summary>
    /// Updates the Dispute Status Id from the Dispute Status code.
    /// </summary>
    procedure UpdateDisputeStatusId()
    var
        DisputeStatus: Record "Dispute Status";
    begin
        if "Dispute Status" = '' then begin
            Clear("Dispute Status Id");
            exit;
        end;
        if not DisputeStatus.Get("Dispute Status") then
            exit;
        "Dispute Status Id" := DisputeStatus.SystemId;
    end;

    /// <summary>
    /// Prints the invoices and saves them as document attachments.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The invoice records to print and attach.</param>
    procedure PrintToDocumentAttachment(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := SalesInvoiceHeader.Count() = 1;
        if SalesInvoiceHeader.FindSet() then
            repeat
                DoPrintToDocumentAttachment(SalesInvoiceHeader, ShowNotificationAction);
            until SalesInvoiceHeader.Next() = 0;
    end;

    local procedure DoPrintToDocumentAttachment(SalesInvoiceHeader: Record "Sales Invoice Header"; ShowNotificationAction: Boolean)
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDoPrintToDocumentAttachment(SalesInvoiceHeader, ShowNotificationAction, IsHandled);
        if IsHandled then
            exit;

        SalesInvoiceHeader.SetRecFilter();
        ReportSelections.SaveAsDocumentAttachment(
            ReportSelections.Usage::"S.Invoice".AsInteger(), SalesInvoiceHeader, SalesInvoiceHeader."No.", SalesInvoiceHeader."Bill-to Customer No.", ShowNotificationAction);
    end;

    /// <summary>
    /// Sends the invoice records by email.
    /// </summary>
    /// <param name="ShowDialog">Whether to show the email dialog.</param>
    procedure EmailRecords(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        DocumentTypeTxt: Text[50];
        IsHandled: Boolean;
    begin
        DocumentTypeTxt := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        IsHandled := false;
        OnBeforeEmailRecords(DummyReportSelections, Rec, DocumentTypeTxt, ShowDialog, IsHandled);
        if not IsHandled then
            DocumentSendingProfile.TrySendToEMail(
              DummyReportSelections.Usage::"S.Invoice".AsInteger(), Rec, FieldNo("No."), DocumentTypeTxt,
              FieldNo("Bill-to Customer No."), ShowDialog);
    end;

    /// <summary>
    /// Gets the full document type text for the invoice.
    /// </summary>
    /// <returns>The document type text.</returns>
    procedure GetDocTypeTxt(): Text[50]
    var
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        exit(ReportDistributionMgt.GetFullDocumentTypeText(Rec));
    end;

    /// <summary>
    /// Opens the Navigate page to show related entries for this invoice.
    /// </summary>
    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    /// <summary>
    /// Opens a page showing value entries with adjustments for this invoice.
    /// </summary>
    procedure LookupAdjmtValueEntries()
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", "No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.SetRange(Adjustment, true);
        PAGE.RunModal(0, ValueEntry);
    end;

    /// <summary>
    /// Gets the customer's VAT registration number.
    /// </summary>
    /// <returns>The VAT registration number.</returns>
    procedure GetCustomerVATRegistrationNumber(): Text
    begin
        exit("VAT Registration No.");
    end;

    /// <summary>
    /// Gets the label for the VAT registration number field.
    /// </summary>
    /// <returns>The field caption if VAT registration number exists, otherwise empty.</returns>
    procedure GetCustomerVATRegistrationNumberLbl(): Text
    begin
        if "VAT Registration No." = '' then
            exit('');
        exit(FieldCaption("VAT Registration No."));
    end;

    /// <summary>
    /// Gets the customer's global location number (GLN).
    /// </summary>
    /// <returns>The GLN if customer exists, otherwise empty.</returns>
    procedure GetCustomerGlobalLocationNumber(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Sell-to Customer No.") then
            exit(Customer.GLN);
        exit('');
    end;

    /// <summary>
    /// Gets the label for the GLN field.
    /// </summary>
    /// <returns>The field caption if customer exists, otherwise empty.</returns>
    procedure GetCustomerGlobalLocationNumberLbl(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Sell-to Customer No.") then
            exit(Customer.FieldCaption(GLN));
        exit('');
    end;

    /// <summary>
    /// Gets the sell-to customer's fax number.
    /// </summary>
    /// <returns>The fax number if customer exists.</returns>
    procedure GetSellToCustomerFaxNo(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Sell-to Customer No.") then
            exit(Customer."Fax No.");
    end;

    /// <summary>
    /// Gets the payment reference for the invoice.
    /// </summary>
    /// <returns>The payment reference text.</returns>
    procedure GetPaymentReference(): Text
    begin
        OnGetPaymentReference(PaymentReference);
        exit(PaymentReference);
    end;

    /// <summary>
    /// Gets the label for the payment reference field.
    /// </summary>
    /// <returns>The payment reference label text.</returns>
    procedure GetPaymentReferenceLbl(): Text
    begin
        OnGetPaymentReferenceLbl(PaymentReferenceLbl);
        exit(PaymentReferenceLbl);
    end;

    /// <summary>
    /// Gets the legal statement from sales setup for printing on invoices.
    /// </summary>
    /// <returns>The legal statement text.</returns>
    procedure GetLegalStatement(): Text
    begin
        SalesSetup.Get();
        exit(SalesSetup.GetLegalStatement());
    end;

    /// <summary>
    /// Gets the remaining amount from the associated customer ledger entry.
    /// </summary>
    /// <returns>The remaining amount.</returns>
    procedure GetRemainingAmount(): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", "Bill-to Customer No.");
        CustLedgerEntry.SetRange("Posting Date", "Posting Date");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", "No.");
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount");

        if not CustLedgerEntry.FindFirst() then
            exit(0);

        exit(CustLedgerEntry."Remaining Amount");
    end;

    /// <summary>
    /// Shows the dimension set entries for this invoice.
    /// </summary>
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;

    /// <summary>
    /// Sets a security filter based on the user's responsibility center.
    /// </summary>
    procedure SetSecurityFilterOnRespCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupMgt.GetSalesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetSalesFilter());
            FilterGroup(0);
        end;
    end;

    /// <summary>
    /// Gets the style class for displaying the document exchange status.
    /// </summary>
    /// <returns>A style name for UI display.</returns>
    procedure GetDocExchStatusStyle(): Text
    begin
        case "Document Exchange Status" of
            "Document Exchange Status"::"Not Sent":
                exit('Standard');
            "Document Exchange Status"::"Sent to Document Exchange Service":
                exit('Ambiguous');
            "Document Exchange Status"::"Delivered to Recipient":
                exit('Favorable');
            else
                exit('Unfavorable');
        end;
    end;

    /// <summary>
    /// Shows the activity log entries for this invoice.
    /// </summary>
    procedure ShowActivityLog()
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.ShowEntries(Rec.RecordId);
    end;

    /// <summary>
    /// Opens the shipping agent's tracking website for this shipment.
    /// </summary>
    procedure StartTrackingSite()
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        TestField("Shipping Agent Code");
        ShippingAgent.Get("Shipping Agent Code");
        HyperLink(ShippingAgent.GetTrackingInternetAddr("Package Tracking No."));
    end;

    /// <summary>
    /// Gets the text describing the selected payment services for this invoice.
    /// </summary>
    /// <returns>The payment services text.</returns>
    procedure GetSelectedPaymentsText(): Text
    var
        PaymentServiceSetup: Record "Payment Service Setup";
    begin
        exit(PaymentServiceSetup.GetSelectedPaymentsText("Payment Service Set ID"));
    end;

    /// <summary>
    /// Gets the work description text from the blob field.
    /// </summary>
    /// <returns>The work description text.</returns>
    procedure GetWorkDescription(): Text
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        OnBeforeGetWorkDescription(Rec);
        TempBlob.FromRecord(Rec, FieldNo("Work Description"));
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Work Description")));
    end;

    /// <summary>
    /// Gets the currency symbol for display purposes.
    /// </summary>
    /// <returns>The currency symbol or code.</returns>
    procedure GetCurrencySymbol(): Text[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if GeneralLedgerSetup.Get() then
            if ("Currency Code" = '') or ("Currency Code" = GeneralLedgerSetup."LCY Code") then
                exit(GeneralLedgerSetup.GetCurrencySymbol());

        if Currency.Get("Currency Code") then
            exit(Currency.GetCurrencySymbol());

        exit("Currency Code");
    end;

    /// <summary>
    /// Checks if the invoice has been sent via document exchange.
    /// </summary>
    /// <returns>True if the document has been sent.</returns>
    procedure DocExchangeStatusIsSent(): Boolean
    begin
        exit("Document Exchange Status" <> "Document Exchange Status"::"Not Sent");
    end;

    /// <summary>
    /// Shows the credit memo that canceled or corrected this invoice.
    /// </summary>
    procedure ShowCanceledOrCorrCrMemo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowCanceledOrCorrCrMemo(Rec, IsHandled);
        if IsHandled then
            exit;

        CalcFields(Cancelled, Corrective);
        case true of
            Cancelled:
                Rec.ShowCorrectiveCreditMemo();
            Corrective:
                Rec.ShowCancelledCreditMemo();
        end;
    end;

    /// <summary>
    /// Opens the credit memo that corrected this cancelled invoice.
    /// </summary>
    procedure ShowCorrectiveCreditMemo()
    var
        CancelledDocument: Record "Cancelled Document";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PageManagement: Codeunit "Page Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowCorrectiveCreditMemo(Rec, IsHandled);
        if IsHandled then
            exit;

        CalcFields(Cancelled);
        if not Cancelled then
            exit;

        if CancelledDocument.FindSalesCancelledInvoice("No.") then begin
            SalesCrMemoHeader.Get(CancelledDocument."Cancelled By Doc. No.");
            PageManagement.PageRun(SalesCrMemoHeader);
        end;
    end;

    /// <summary>
    /// Opens the credit memo that was cancelled by this corrective invoice.
    /// </summary>
    procedure ShowCancelledCreditMemo()
    var
        CancelledDocument: Record "Cancelled Document";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PageManagement: Codeunit "Page Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowCancelledCreditMemo(Rec, IsHandled);
        if IsHandled then
            exit;

        CalcFields(Corrective);
        if not Corrective then
            exit;

        if CancelledDocument.FindSalesCorrectiveInvoice("No.") then begin
            SalesCrMemoHeader.Get(CancelledDocument."Cancelled Doc. No.");
            PageManagement.PageRun(SalesCrMemoHeader);
        end;
    end;

    /// <summary>
    /// Gets the default document name for email purposes.
    /// </summary>
    /// <returns>The default email document name.</returns>
    procedure GetDefaultEmailDocumentName(): Text[150]
    begin
        exit(DocTxt);
    end;

    /// <summary>
    /// Raised before checking if the invoice has been printed.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The sales invoice header being checked.</param>
    /// <param name="IsHandled">Set to true to skip default print status check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoPrinted(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before emailing sales invoice records to customers.
    /// </summary>
    /// <param name="ReportSelections">The report selections to use.</param>
    /// <param name="SalesInvoiceHeader">The sales invoice header to email.</param>
    /// <param name="DocTxt">The document type text.</param>
    /// <param name="ShowDialog">Indicates whether to show the email dialog.</param>
    /// <param name="IsHandled">Set to true to skip default email processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmailRecords(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; DocTxt: Text; var ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing sales invoice records.
    /// </summary>
    /// <param name="ReportSelections">The report selections to use.</param>
    /// <param name="SalesInvoiceHeader">The sales invoice header to print.</param>
    /// <param name="ShowRequestPage">Indicates whether to show the report request page.</param>
    /// <param name="IsHandled">Set to true to skip default print processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; ShowRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing to document attachment for the sales invoice.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The sales invoice header to print.</param>
    /// <param name="ShowNotificationAction">Indicates whether to show notification action.</param>
    /// <param name="IsHandled">Set to true to skip default document attachment processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoPrintToDocumentAttachment(var SalesInvoiceHeader: Record "Sales Invoice Header"; var ShowNotificationAction: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before sending the sales invoice using the document sending profile.
    /// </summary>
    /// <param name="ReportSelections">The report selections to use.</param>
    /// <param name="SalesInvoiceHeader">The sales invoice header to send.</param>
    /// <param name="DocTxt">The document type text.</param>
    /// <param name="IsHandled">Set to true to skip default sending profile processing.</param>
    /// <param name="DocumentSendingProfile">The document sending profile to use.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendProfile(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; DocTxt: Text; var IsHandled: Boolean; var DocumentSendingProfile: Record "Document Sending Profile")
    begin
    end;

    /// <summary>
    /// Raised before sending sales invoice records.
    /// </summary>
    /// <param name="ReportSelections">The report selections to use.</param>
    /// <param name="SalesInvoiceHeader">The sales invoice header to send.</param>
    /// <param name="DocTxt">The document type text.</param>
    /// <param name="IsHandled">Set to true to skip default sending processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRecords(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; DocTxt: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before showing the cancelled or corrective credit memo related to this invoice.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The sales invoice header.</param>
    /// <param name="IsHandled">Set to true to skip default credit memo display.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCanceledOrCorrCrMemo(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before showing the corrective credit memo that cancelled this invoice.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The cancelled sales invoice header.</param>
    /// <param name="IsHandled">Set to true to skip default corrective credit memo display.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCorrectiveCreditMemo(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before showing the cancelled credit memo when this invoice is a corrective invoice.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The corrective sales invoice header.</param>
    /// <param name="IsHandled">Set to true to skip default cancelled credit memo display.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCancelledCreditMemo(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before setting security filter on responsibility center for the sales invoice.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The sales invoice header to filter.</param>
    /// <param name="IsHandled">Set to true to skip default security filter application.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised to retrieve the payment reference for the sales invoice.
    /// </summary>
    /// <param name="PaymentReference">Returns the payment reference text.</param>
    [IntegrationEvent(true, false)]
    local procedure OnGetPaymentReference(var PaymentReference: Text)
    begin
    end;

    /// <summary>
    /// Raised to retrieve the payment reference label for display.
    /// </summary>
    /// <param name="PaymentReferenceLbl">Returns the payment reference label text.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetPaymentReferenceLbl(var PaymentReferenceLbl: Text)
    begin
    end;

    /// <summary>
    /// Raised after setting filters when looking up the applies-to document number.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry with applied filters.</param>
    /// <param name="SalesInvoiceHeader">The sales invoice header being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    /// <summary>
    /// Raised to determine whether the posted sales invoice is fully open.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The sales invoice header being checked.</param>
    /// <param name="FullyOpen">Returns whether the invoice is fully open.</param>
    /// <param name="IsHandled">Set to true to skip default open status check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostedSalesInvoiceFullyOpen(var SalesInvoiceHeader: Record "Sales Invoice Header"; var FullyOpen: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before retrieving the work description text for the sales invoice.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The sales invoice header.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWorkDescription(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}