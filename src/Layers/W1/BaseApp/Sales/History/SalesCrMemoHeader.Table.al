// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
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
using System.Globalization;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Stores header information for posted sales credit memos including customer details and credited amounts.
/// </summary>
table 114 "Sales Cr.Memo Header"
{
    Caption = 'Sales Cr.Memo Header';
    DataCaptionFields = "No.", "Sell-to Customer Name";
    DrillDownPageID = "Posted Sales Credit Memos";
    LookupPageID = "Posted Sales Credit Memos";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the customer number who received the credited items.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;
            ToolTip = 'Specifies the number of the customer that you shipped the items on the credit memo to.';
        }
        /// <summary>
        /// Specifies the unique identifier for the posted sales credit memo.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the posted credit memo number. You cannot change the number because the document has already been posted.';
        }
        /// <summary>
        /// Specifies the customer number who receives the credit memo for billing purposes.
        /// </summary>
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;
            ToolTip = 'Specifies the number of the customer that you send or sent the credit memo to.';
        }
        /// <summary>
        /// Specifies the name of the customer who receives the credit memo.
        /// </summary>
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
        }
        /// <summary>
        /// Specifies an additional part of the bill-to customer name.
        /// </summary>
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer that you send or sent the credit memo to.';
        }
        /// <summary>
        /// Specifies the street address of the customer who receives the credit memo.
        /// </summary>
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            ToolTip = 'Specifies the address of the customer that the credit memo was sent to.';
        }
        /// <summary>
        /// Specifies additional address information for the bill-to customer.
        /// </summary>
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        /// <summary>
        /// Specifies the city of the customer who receives the credit memo.
        /// </summary>
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            ToolTip = 'Specifies the city of the customer on the sales document.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the name of the contact person at the bill-to customer.
        /// </summary>
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
            ToolTip = 'Specifies the name of the person you regularly contact when you communicate with the customer to whom the credit memo was sent.';
        }
        /// <summary>
        /// Specifies the customer's own reference number for this transaction.
        /// </summary>
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            ToolTip = 'Specifies the customer''s reference. The contents will be printed on sales documents.';
        }
        /// <summary>
        /// Specifies the code for the ship-to address used on the credit memo.
        /// </summary>
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));
        }
        /// <summary>
        /// Specifies the name of the location where items were shipped.
        /// </summary>
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies an additional part of the ship-to name.
        /// </summary>
        field(14; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer that the items were shipped to.';
        }
        /// <summary>
        /// Specifies the street address of the ship-to location.
        /// </summary>
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            ToolTip = 'Specifies the address that the items were shipped to.';
        }
        /// <summary>
        /// Specifies additional address information for the ship-to location.
        /// </summary>
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        /// <summary>
        /// Specifies the city of the ship-to location.
        /// </summary>
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            ToolTip = 'Specifies the city of the customer on the sales document.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the name of the contact person at the ship-to location.
        /// </summary>
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
            ToolTip = 'Specifies the name of the person you regularly contact at the customer to whom the items were shipped.';
        }
        /// <summary>
        /// Specifies the date when the credit memo was posted to the ledger.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date when the credit memo was posted.';
        }
        /// <summary>
        /// Specifies the date when items were shipped related to this credit memo.
        /// </summary>
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        /// <summary>
        /// Specifies the text that describes this posted credit memo.
        /// </summary>
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
        }
        /// <summary>
        /// Specifies the code for the payment terms used on the credit memo.
        /// </summary>
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        /// <summary>
        /// Specifies the date when the credit memo payment is due.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the date on which the shipment is due for payment.';
        }
        /// <summary>
        /// Specifies the payment discount percentage applied to the credit memo.
        /// </summary>
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the last date for the customer to take the payment discount.
        /// </summary>
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        /// <summary>
        /// Specifies the code for the shipment method used on the credit memo.
        /// </summary>
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            ToolTip = 'Specifies the shipment method for the shipment.';
            TableRelation = "Shipment Method";
        }
        /// <summary>
        /// Specifies the location from which items were shipped or returned.
        /// </summary>
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location where the credit memo was registered.';
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
        /// Specifies the customer posting group used to post receivables to the general ledger.
        /// </summary>
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            ToolTip = 'Specifies the customer''s market type to link business transactions to.';
            Editable = false;
            TableRelation = "Customer Posting Group";
        }
        /// <summary>
        /// Specifies the currency code used for the credit memo amounts.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code of the credit memo.';
            Editable = false;
            TableRelation = Currency;
        }
        /// <summary>
        /// Specifies the exchange rate used to convert amounts to local currency.
        /// </summary>
        field(33; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the customer price group used for pricing on the credit memo.
        /// </summary>
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        /// <summary>
        /// Indicates whether the prices on the credit memo include VAT.
        /// </summary>
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        /// <summary>
        /// Specifies the code used to calculate invoice discounts for this customer.
        /// </summary>
        field(37; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
        }
        /// <summary>
        /// Specifies the customer discount group used for line discounts.
        /// </summary>
        field(40; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        /// <summary>
        /// Specifies the language code for the credit memo document.
        /// </summary>
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        /// <summary>
        /// Specifies the regional format for dates and numbers on the document.
        /// </summary>
        field(42; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        /// <summary>
        /// Specifies the salesperson responsible for the credit memo.
        /// </summary>
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            ToolTip = 'Specifies which salesperson is associated with the credit memo.';
            TableRelation = "Salesperson/Purchaser";
        }
        /// <summary>
        /// Indicates whether comments exist for this posted credit memo.
        /// </summary>
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Sales Comment Line" where("Document Type" = const("Posted Credit Memo"),
                                                            "No." = field("No."),
                                                            "Document Line No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies how many times the credit memo has been printed.
        /// </summary>
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            ToolTip = 'Specifies how many times the document has been printed.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the on hold status to block further processing.
        /// </summary>
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        /// <summary>
        /// Specifies the type of document this credit memo is applied to.
        /// </summary>
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
            ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
        }
        /// <summary>
        /// Specifies the document number this credit memo is applied to.
        /// </summary>
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';

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
        /// Specifies the balancing account number for the credit memo posting.
        /// </summary>
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        /// <summary>
        /// Specifies the total amount of the credit memo excluding VAT.
        /// </summary>
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Sales Cr.Memo Line".Amount where("Document No." = field("No.")));
            Caption = 'Amount';
            ToolTip = 'Specifies the total of the amounts on all the credit memo lines, in the currency of the credit memo. The amount does not include VAT.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the total amount of the credit memo including VAT.
        /// </summary>
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Sales Cr.Memo Line"."Amount Including VAT" where("Document No." = field("No.")));
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
        /// Specifies the reason code for the credit memo posting.
        /// </summary>
        field(73; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Specifies the general business posting group used for the credit memo.
        /// </summary>
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// Indicates whether the transaction involves three-party trade within the EU.
        /// </summary>
        field(75; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            ToolTip = 'Specifies whether the invoice was part of an EU 3-party trade transaction.';
        }
        /// <summary>
        /// Specifies the transaction type code for Intrastat reporting.
        /// </summary>
        field(76; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        /// <summary>
        /// Specifies the transport method code for Intrastat reporting.
        /// </summary>
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        /// <summary>
        /// Specifies the country/region code for VAT purposes.
        /// </summary>
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Specifies the name of the customer who received the credited items.
        /// </summary>
        field(79; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            ToolTip = 'Specifies the name of the customer that you shipped the items on the credit memo to.';
        }
        /// <summary>
        /// Specifies an additional part of the sell-to customer name.
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
            ToolTip = 'Specifies the address of the customer that the items on the credit memo were sent to.';
        }
        /// <summary>
        /// Specifies additional address information for the sell-to customer.
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
        /// Specifies the postal code of the bill-to customer address.
        /// </summary>
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            ToolTip = 'Specifies the postal code of the customer''s billing address.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the county or state of the bill-to customer address.
        /// </summary>
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
        /// <summary>
        /// Specifies the country/region code of the bill-to customer address.
        /// </summary>
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            ToolTip = 'Specifies the country or region of the address.';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Specifies the postal code of the sell-to customer address.
        /// </summary>
        field(88; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            ToolTip = 'Specifies the postal code of the customer''s main address.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the county or state of the sell-to customer address.
        /// </summary>
        field(89; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,2,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
        /// <summary>
        /// Specifies the country/region code of the sell-to customer address.
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
        /// Specifies the country/region code of the ship-to address.
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
        /// Specifies the exit point for goods leaving the country for Intrastat.
        /// </summary>
        field(97; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        /// <summary>
        /// Indicates whether this is a correcting entry that reverses a previous posting.
        /// </summary>
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
            ToolTip = 'Specifies the entry was posted as a corrective entry.';
        }
        /// <summary>
        /// Specifies the date when the credit memo document was created.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date on which you created the sales document.';
        }
        /// <summary>
        /// Specifies the external document number provided by the customer.
        /// </summary>
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies the external document number that is entered on the sales header that this line was posted from.';
        }
        /// <summary>
        /// Specifies the area code for Intrastat reporting.
        /// </summary>
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        /// <summary>
        /// Specifies the transaction specification code for Intrastat reporting.
        /// </summary>
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        /// <summary>
        /// Specifies the payment method code for the credit memo.
        /// </summary>
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            ToolTip = 'Specifies the customer''s method of payment. The program has copied the code from the Payment Method Code field on the sales header.';
            TableRelation = "Payment Method";
        }
        /// <summary>
        /// Specifies the shipping agent responsible for delivering goods.
        /// </summary>
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
            TableRelation = "Shipping Agent";
        }
        /// <summary>
        /// Specifies the tracking number for the shipped package.
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
        /// Specifies the number series used before the credit memo was posted.
        /// </summary>
        field(107; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the number series used for the posted credit memo.
        /// </summary>
        field(108; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the document number assigned before posting.
        /// </summary>
        field(111; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
            ToolTip = 'Specifies the number of the credit memo that the posted credit memo was created from.';
        }
        /// <summary>
        /// Specifies the user who posted the credit memo.
        /// </summary>
        field(112; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Specifies the source code that identifies the posting origin.
        /// </summary>
        field(113; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        /// <summary>
        /// Specifies the tax area code for sales tax calculations.
        /// </summary>
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the credit memo is subject to sales tax.
        /// </summary>
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
        }
        /// <summary>
        /// Specifies the VAT business posting group used for tax calculations.
        /// </summary>
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Specifies the percentage used to reduce the VAT base amount for discounts.
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
        /// Specifies the number series for prepayment credit memos.
        /// </summary>
        field(134; "Prepmt. Cr. Memo No. Series"; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Indicates whether this is a prepayment credit memo.
        /// </summary>
        field(136; "Prepayment Credit Memo"; Boolean)
        {
            Caption = 'Prepayment Credit Memo';
        }
        /// <summary>
        /// Specifies the prepayment order number related to this credit memo.
        /// </summary>
        field(137; "Prepayment Order No."; Code[20])
        {
            Caption = 'Prepayment Order No.';
        }
        /// <summary>
        /// Specifies the company bank account used for the credit memo payment.
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
        /// Specifies the country/region code from which the goods were received.
        /// </summary>
        field(181; "Rcvd.-from Count./Region Code"; Code[10])
        {
            Caption = 'Received-from Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Stores the work description or detailed notes for the credit memo.
        /// </summary>
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the phone number of the ship-to location.
        /// </summary>
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ToolTip = 'Specifies the telephone number of the company''s shipping address.';
            ExtendedDatatype = PhoneNo;
        }
        /// <summary>
        /// Specifies the unique identifier for the dimension set applied to this credit memo.
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
        /// Specifies the identifier used when exchanging the document electronically.
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
        /// Specifies the original identifier from the document exchange service.
        /// </summary>
        field(712; "Doc. Exch. Original Identifier"; Text[50])
        {
            Caption = 'Doc. Exch. Original Identifier';
        }
        /// <summary>
        /// Indicates whether the credit memo has been fully paid or applied.
        /// </summary>
        field(1302; Paid; Boolean)
        {
            CalcFormula = - exist("Cust. Ledger Entry" where("Entry No." = field("Cust. Ledger Entry No."),
                                                             Open = filter(true)));
            Caption = 'Paid';
            ToolTip = 'Specifies if the posted sales invoice that relates to this sales credit memo is paid.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the remaining amount to be applied from the credit memo.
        /// </summary>
        field(1303; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Cust. Ledger Entry No." = field("Cust. Ledger Entry No.")));
            Caption = 'Remaining Amount';
            ToolTip = 'Specifies the amount that remains to be paid for the posted sales invoice.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the entry number of the related customer ledger entry.
        /// </summary>
        field(1304; "Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Cust. Ledger Entry No.';
            Editable = false;
            TableRelation = "Cust. Ledger Entry"."Entry No.";
        }
        /// <summary>
        /// Specifies the total invoice discount amount applied to the credit memo.
        /// </summary>
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            CalcFormula = sum("Sales Cr.Memo Line"."Inv. Discount Amount" where("Document No." = field("No.")));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether this credit memo has been cancelled by another document.
        /// </summary>
        field(1310; Cancelled; Boolean)
        {
            CalcFormula = exist("Cancelled Document" where("Source ID" = const(114),
                                                            "Cancelled Doc. No." = field("No.")));
            Caption = 'Cancelled';
            ToolTip = 'Specifies if the posted sales invoice that relates to this sales credit memo has been either corrected or canceled.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether this credit memo is a correction of a posted invoice.
        /// </summary>
        field(1311; Corrective; Boolean)
        {
            CalcFormula = exist("Cancelled Document" where("Source ID" = const(112),
                                                            "Cancelled By Doc. No." = field("No.")));
            Caption = 'Corrective';
            ToolTip = 'Specifies if the posted sales invoice has been either corrected or canceled by this sales credit memo.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the marketing campaign associated with the credit memo.
        /// </summary>
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        /// <summary>
        /// Specifies the contact number of the sell-to customer.
        /// </summary>
        field(5052; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            ToolTip = 'Specifies the number of the contact at the customer who handles the credit memo.';
            TableRelation = Contact;
        }
        /// <summary>
        /// Specifies the contact number of the bill-to customer.
        /// </summary>
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            ToolTip = 'Specifies the number of the contact at the customer who handles the credit memo.';
            TableRelation = Contact;
        }
        /// <summary>
        /// Specifies the sales opportunity associated with this credit memo.
        /// </summary>
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;
        }
        /// <summary>
        /// Specifies the responsibility center that processed the credit memo.
        /// </summary>
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            ToolTip = 'Specifies the code for the responsibility center that serves the customer on this sales document.';
            TableRelation = "Responsibility Center";
        }
        /// <summary>
        /// Specifies the shipping agent service code for delivery options.
        /// </summary>
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            ToolTip = 'Specifies which shipping agent service is used to transport the items on the sales document to the customer.';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        /// <summary>
        /// Specifies the return order number that this credit memo was created from.
        /// </summary>
        field(6601; "Return Order No."; Code[20])
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Return Order No.';
        }
        /// <summary>
        /// Specifies the number series used for the return order.
        /// </summary>
        field(6602; "Return Order No. Series"; Code[20])
        {
            Caption = 'Return Order No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the method used to calculate prices on the credit memo.
        /// </summary>
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        /// <summary>
        /// Indicates whether line discounts are allowed on the credit memo.
        /// </summary>
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
        }
        /// <summary>
        /// Indicates whether the Get Return Receipt function was used to create lines.
        /// </summary>
        field(7200; "Get Return Receipt Used"; Boolean)
        {
            Caption = 'Get Return Receipt Used';
        }
        /// <summary>
        /// Specifies the system ID of the draft credit memo before posting.
        /// </summary>
        field(8001; "Draft Cr. Memo SystemId"; Guid)
        {
            Caption = 'Draft Cr. Memo System Id';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Pre-Assigned No.")
        {
        }
        key(Key3; "Return Order No.")
        {
        }
        key(Key4; "Sell-to Customer No.")
        {
        }
        key(Key5; "Prepayment Order No.")
        {
        }
        key(Key6; "Bill-to Customer No.")
        {
        }
        key(Key7; "Posting Date")
        {
        }
        key(Key8; "Document Exchange Status")
        {
        }
        key(Key9; "Salesperson Code")
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
        PostSalesDelete.DeleteSalesCrMemoLines(Rec);

        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Posted Credit Memo");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.DeleteAll();

        ApprovalsMgmt.DeletePostedApprovalEntries(RecordId);
        PostedDeferralHeader.DeleteForDoc(
            "Deferral Document Type"::Sales.AsInteger(), '', '',
            SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger(), "No.");
    end;

    var
        SalesCommentLine: Record "Sales Comment Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        DimMgt: Codeunit DimensionManagement;
        UserSetupMgt: Codeunit "User Setup Management";

    /// <summary>
    /// Sends the credit memo records using the customer's document sending profile.
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
        if IsHandled then
            exit;

        DocumentSendingProfile.SendCustomerRecords(
          DummyReportSelections.Usage::"S.Cr.Memo".AsInteger(), Rec, DocumentTypeTxt, "Bill-to Customer No.", "No.",
          FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    /// <summary>
    /// Sends the credit memo using a specific document sending profile.
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
        if IsHandled then
            exit;

        DocumentSendingProfile.Send(
          DummyReportSelections.Usage::"S.Cr.Memo".AsInteger(), Rec, "No.", "Bill-to Customer No.",
          DocumentTypeTxt, FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    /// <summary>
    /// Opens the shipping agent's tracking website for this return shipment.
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
    /// Prints the selected credit memo records.
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
        if IsHandled then
            exit;

        DocumentSendingProfile.TrySendToPrinter(
          DummyReportSelections.Usage::"S.Cr.Memo".AsInteger(), Rec, FieldNo("Bill-to Customer No."), ShowRequestPage);
    end;

    /// <summary>
    /// Validates that the credit memo has been printed at least once.
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
    /// Sends the credit memo records by email.
    /// </summary>
    /// <param name="ShowRequestPage">Whether to show the email dialog.</param>
    procedure EmailRecords(ShowRequestPage: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        DocumentTypeTxt: Text[50];
        IsHandled: Boolean;
    begin
        DocumentTypeTxt := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        IsHandled := false;
        OnBeforeEmailRecords(DummyReportSelections, Rec, DocumentTypeTxt, ShowRequestPage, IsHandled);
        if IsHandled then
            exit;

        DocumentSendingProfile.TrySendToEMail(
          DummyReportSelections.Usage::"S.Cr.Memo".AsInteger(), Rec, FieldNo("No."), DocumentTypeTxt,
          FieldNo("Bill-to Customer No."), ShowRequestPage);
    end;

    /// <summary>
    /// Prints the credit memos and saves them as document attachments.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The credit memo records to print and attach.</param>
    procedure PrintToDocumentAttachment(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := SalesCrMemoHeader.Count() = 1;
        if SalesCrMemoHeader.FindSet() then
            repeat
                DoPrintToDocumentAttachment(SalesCrMemoHeader, ShowNotificationAction);
            until SalesCrMemoHeader.Next() = 0;
    end;

    local procedure DoPrintToDocumentAttachment(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ShowNotificationAction: Boolean)
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDoPrintToDocumentAttachment(SalesCrMemoHeader, ShowNotificationAction, IsHandled);
        if IsHandled then
            exit;

        SalesCrMemoHeader.SetRecFilter();
        ReportSelections.SaveAsDocumentAttachment(
            ReportSelections.Usage::"S.Cr.Memo".AsInteger(), SalesCrMemoHeader, SalesCrMemoHeader."No.", SalesCrMemoHeader."Bill-to Customer No.", ShowNotificationAction);
    end;

    /// <summary>
    /// Opens the Navigate page to show related entries for this credit memo.
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
    /// Opens a page showing value entries with adjustments for this credit memo.
    /// </summary>
    procedure LookupAdjmtValueEntries()
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", "No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Credit Memo");
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
    /// <returns>The field caption.</returns>
    procedure GetCustomerVATRegistrationNumberLbl(): Text
    begin
        exit(FieldCaption("VAT Registration No."));
    end;


    /// <summary>
    /// Gets the legal statement from sales setup for printing on credit memos.
    /// </summary>
    /// <returns>The legal statement text.</returns>
    procedure GetLegalStatement(): Text
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        exit(SalesSetup.GetLegalStatement());
    end;

    /// <summary>
    /// Shows the dimension set entries for this credit memo.
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
    /// Shows the activity log entries for this credit memo.
    /// </summary>
    procedure ShowActivityLog()
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.ShowEntries(Rec.RecordId);
    end;

    /// <summary>
    /// Checks if the credit memo has been sent via document exchange.
    /// </summary>
    /// <returns>True if the document has been sent.</returns>
    procedure DocExchangeStatusIsSent(): Boolean
    begin
        exit("Document Exchange Status" <> "Document Exchange Status"::"Not Sent");
    end;

    /// <summary>
    /// Shows the invoice that was canceled or corrected by this credit memo.
    /// </summary>
    procedure ShowCanceledOrCorrInvoice()
    begin
        CalcFields(Cancelled, Corrective);
        case true of
            Cancelled:
                Rec.ShowCorrectiveInvoice();
            Corrective:
                Rec.ShowCancelledInvoice();
        end;
    end;

    /// <summary>
    /// Opens the invoice that corrected this cancelled credit memo.
    /// </summary>
    procedure ShowCorrectiveInvoice()
    var
        CancelledDocument: Record "Cancelled Document";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        CalcFields(Cancelled);
        if not Cancelled then
            exit;

        if CancelledDocument.FindSalesCancelledCrMemo("No.") then begin
            SalesInvHeader.Get(CancelledDocument."Cancelled By Doc. No.");
            RunSalesInvoiceHeaderPage(SalesInvHeader, PAGE::"Posted Sales Invoice");
        end;
    end;

    /// <summary>
    /// Opens the invoice that was cancelled by this corrective credit memo.
    /// </summary>
    procedure ShowCancelledInvoice()
    var
        CancelledDocument: Record "Cancelled Document";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        CalcFields(Corrective);
        if not Corrective then
            exit;

        if CancelledDocument.FindSalesCorrectiveCrMemo("No.") then begin
            SalesInvHeader.Get(CancelledDocument."Cancelled Doc. No.");
            RunSalesInvoiceHeaderPage(SalesInvHeader, PAGE::"Posted Sales Invoice");
        end;
    end;

    local procedure RunSalesInvoiceHeaderPage(var SalesInvoiceHeader: Record "Sales Invoice Header"; PageID: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunSalesInvoiceHeaderPage(SalesInvoiceHeader, PageID, IsHandled);
        if IsHandled then
            exit;

        PAGE.Run(PageID, SalesInvoiceHeader);
    end;

    /// <summary>
    /// Retrieves the work description text from the BLOB field.
    /// </summary>
    /// <returns>The work description text.</returns>
    procedure GetWorkDescription(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Work Description");
        "Work Description".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Work Description")));
    end;

    /// <summary>
    /// Raised before emailing sales credit memo records to customers.
    /// </summary>
    /// <param name="ReportSelections">The report selections to use.</param>
    /// <param name="SalesCrMemoHeader">The sales credit memo header to email.</param>
    /// <param name="DocTxt">The document type text.</param>
    /// <param name="ShowDialog">Indicates whether to show the email dialog.</param>
    /// <param name="IsHandled">Set to true to skip default email processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmailRecords(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocTxt: Text; var ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing sales credit memo records.
    /// </summary>
    /// <param name="ReportSelections">The report selections to use.</param>
    /// <param name="SalesCrMemoHeader">The sales credit memo header to print.</param>
    /// <param name="ShowRequestPage">Indicates whether to show the report request page.</param>
    /// <param name="IsHandled">Set to true to skip default print processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ShowRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before sending the sales credit memo using the document sending profile.
    /// </summary>
    /// <param name="ReportSelections">The report selections to use.</param>
    /// <param name="SalesCrMemoHeader">The sales credit memo header to send.</param>
    /// <param name="DocTxt">The document type text.</param>
    /// <param name="IsHandled">Set to true to skip default sending profile processing.</param>
    /// <param name="DocumentSendingProfile">The document sending profile to use.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendProfile(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocTxt: Text; var IsHandled: Boolean; var DocumentSendingProfile: Record "Document Sending Profile")
    begin
    end;

    /// <summary>
    /// Raised before sending sales credit memo records.
    /// </summary>
    /// <param name="ReportSelections">The report selections to use.</param>
    /// <param name="SalesCrMemoHeader">The sales credit memo header to send.</param>
    /// <param name="DocTxt">The document type text.</param>
    /// <param name="IsHandled">Set to true to skip default sending processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRecords(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocTxt: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before setting security filter on responsibility center for the sales credit memo.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The sales credit memo header to filter.</param>
    /// <param name="IsHandled">Set to true to skip default security filter application.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after setting filters when looking up the applies-to document number.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry with applied filters.</param>
    /// <param name="SalesCrMemoHeader">The sales credit memo header being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    /// <summary>
    /// Raised before running the sales invoice header page when showing the cancelled invoice.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The sales invoice header to display.</param>
    /// <param name="PageID">The page ID to run.</param>
    /// <param name="IsHandled">Set to true to skip default page execution.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunSalesInvoiceHeaderPage(var SalesInvoiceHeader: Record "Sales Invoice Header"; var PageID: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing to document attachment for the sales credit memo.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The sales credit memo header to print.</param>
    /// <param name="ShowNotificationAction">Indicates whether to show notification action.</param>
    /// <param name="IsHandled">Set to true to skip default document attachment processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoPrintToDocumentAttachment(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ShowNotificationAction: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking if the credit memo has been printed.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The sales credit memo header being checked.</param>
    /// <param name="IsHandled">Set to true to skip default print status check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoPrinted(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;
}