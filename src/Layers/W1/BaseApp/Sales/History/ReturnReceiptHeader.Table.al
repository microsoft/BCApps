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
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Automation;
using System.Globalization;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Stores header information for posted sales return receipts documenting received returned goods from customers.
/// </summary>
table 6660 "Return Receipt Header"
{
    Caption = 'Return Receipt Header';
    DataCaptionFields = "No.", "Sell-to Customer Name";
    LookupPageID = "Posted Return Receipts";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the customer number who returned the items.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;
            ToolTip = 'Specifies the number of the customer who returned the products.';
        }
        /// <summary>
        /// Specifies the unique identifier for the posted return receipt.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        /// <summary>
        /// Specifies the customer number who receives the credit memo for billing.
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
            ToolTip = 'Specifies an additional part of the name of the customer that you send or sent the invoice or credit memo to.';
        }
        /// <summary>
        /// Specifies the street address of the customer who receives the credit memo.
        /// </summary>
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            ToolTip = 'Specifies the address of the customer to whom you sent the invoice.';
        }
        /// <summary>
        /// Specifies additional address information for the bill-to customer.
        /// </summary>
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            ToolTip = 'Specifies an additional line of the address.';
        }
        /// <summary>
        /// Specifies the city of the customer who receives the credit memo.
        /// </summary>
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            ToolTip = 'Specifies the city of the address.';
            TableRelation = if ("Bill-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Bill-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Bill-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the name of the contact person at the bill-to customer.
        /// </summary>
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
            ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
        }
        /// <summary>
        /// Specifies the customer's own reference number for this transaction.
        /// </summary>
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        /// <summary>
        /// Specifies the code for the ship-to address on the return receipt.
        /// </summary>
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));
        }
        /// <summary>
        /// Specifies the name of the ship-to location.
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
            ToolTip = 'Specifies an additional part of the name of the customer at the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies the street address of the ship-to location.
        /// </summary>
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            ToolTip = 'Specifies the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies additional address information for the ship-to location.
        /// </summary>
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
        }
        /// <summary>
        /// Specifies the city of the ship-to location.
        /// </summary>
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            ToolTip = 'Specifies the city of the address that the items are shipped to.';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the name of the contact person at the ship-to location.
        /// </summary>
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
            ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies the date when the return order was created.
        /// </summary>
        field(19; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        /// <summary>
        /// Specifies the date when the return receipt was posted.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the entry''s posting date.';
        }
        /// <summary>
        /// Specifies the date when items were shipped or received.
        /// </summary>
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        /// <summary>
        /// Specifies the text that describes this posted return receipt.
        /// </summary>
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        /// <summary>
        /// Specifies the code for the payment terms used on the return.
        /// </summary>
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        /// <summary>
        /// Specifies the date when payment is due.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// Specifies the payment discount percentage applicable to the return.
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
        /// Specifies the last date for taking the payment discount.
        /// </summary>
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        /// <summary>
        /// Specifies the code for the shipment method used for the return.
        /// </summary>
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
            TableRelation = "Shipment Method";
        }
        /// <summary>
        /// Specifies the location where returned items were received.
        /// </summary>
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
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
        /// Specifies the customer posting group used to post receivables.
        /// </summary>
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
        }
        /// <summary>
        /// Specifies the currency code used for the return receipt amounts.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency that is used on the entry.';
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
        /// Specifies the customer price group used for pricing on the return.
        /// </summary>
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        /// <summary>
        /// Indicates whether the prices include VAT.
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
        /// Specifies the language code for the return receipt document.
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
        /// Specifies the salesperson responsible for the return.
        /// </summary>
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            ToolTip = 'Specifies which salesperson is associated with the posted return receipt.';
            TableRelation = "Salesperson/Purchaser";
        }
        /// <summary>
        /// Indicates whether comments exist for this posted return receipt.
        /// </summary>
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Sales Comment Line" where("Document Type" = const("Posted Return Receipt"),
                                                            "No." = field("No."),
                                                            "Document Line No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies how many times the return receipt has been printed.
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
        /// Specifies the type of document this return applies to.
        /// </summary>
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        /// <summary>
        /// Specifies the document number this return applies to.
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
        /// Specifies the balancing account number for posting.
        /// </summary>
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
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
        /// Specifies the reason code for the return receipt posting.
        /// </summary>
        field(73; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Specifies the general business posting group used for the return.
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
        /// Specifies the name of the customer who returned the items.
        /// </summary>
        field(79; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            ToolTip = 'Specifies the name of the customer.';
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
            ToolTip = 'Specifies the main address of the customer.';
        }
        /// <summary>
        /// Specifies additional address information for the sell-to customer.
        /// </summary>
        field(82; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';
            ToolTip = 'Specifies an additional part of the address.';
        }
        /// <summary>
        /// Specifies the city of the sell-to customer.
        /// </summary>
        field(83; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            ToolTip = 'Specifies the city of the customer''s main address.';
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Sell-to Country/Region Code"));
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
            TableRelation = if ("Bill-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Bill-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Bill-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the county or state of the bill-to customer address.
        /// </summary>
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
        }
        /// <summary>
        /// Specifies the country/region code of the bill-to customer address.
        /// </summary>
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            ToolTip = 'Specifies the country/region code of the customer''s billing address.';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Specifies the postal code of the sell-to customer address.
        /// </summary>
        field(88; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            ToolTip = 'Specifies the postal code of the customer''s main address.';
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Sell-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the county or state of the sell-to customer address.
        /// </summary>
        field(89; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,2,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';
        }
        /// <summary>
        /// Specifies the country/region code of the sell-to customer address.
        /// </summary>
        field(90; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            ToolTip = 'Specifies the country/region code of the customer''s main address.';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Specifies the postal code of the ship-to address.
        /// </summary>
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the county or state of the ship-to address.
        /// </summary>
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        /// <summary>
        /// Specifies the country/region code of the ship-to address.
        /// </summary>
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
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
        }
        /// <summary>
        /// Specifies the date when the return receipt document was created.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date when the related document was created.';
        }
        /// <summary>
        /// Specifies the external document number provided by the customer.
        /// </summary>
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
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
        /// Specifies the payment method code for the return.
        /// </summary>
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        /// <summary>
        /// Specifies the shipping agent responsible for the return shipment.
        /// </summary>
        field(105; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Shipping Agent Code';
            ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
            TableRelation = "Shipping Agent";
        }
        /// <summary>
        /// Specifies the tracking number for the return shipment package.
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
        /// Specifies the number series used for the posted return receipt.
        /// </summary>
        field(109; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the user who posted the return receipt.
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
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the return receipt is subject to sales tax.
        /// </summary>
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
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
        /// Specifies the country/region code from which the goods were received.
        /// </summary>
        field(181; "Rcvd.-from Count./Region Code"; Code[10])
        {
            Caption = 'Received-from Country/Region Code';
            TableRelation = "Country/Region";
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
        /// Specifies the unique identifier for the dimension set applied to this return receipt.
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
        /// Specifies the marketing campaign associated with the return.
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
            ToolTip = 'Specifies the number of the contact person at the customer''s main address.';
            TableRelation = Contact;
        }
        /// <summary>
        /// Specifies the contact number of the bill-to customer.
        /// </summary>
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
            TableRelation = Contact;
        }
        /// <summary>
        /// Specifies the sales opportunity associated with this return.
        /// </summary>
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;
        }
        /// <summary>
        /// Specifies the responsibility center that processed the return.
        /// </summary>
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
            TableRelation = "Responsibility Center";
        }
        /// <summary>
        /// Specifies the date when delivery was requested by the customer.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            Editable = false;
        }
        /// <summary>
        /// Specifies the date when delivery was promised to the customer.
        /// </summary>
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
            Editable = false;
        }
        /// <summary>
        /// Specifies the formula used to calculate shipping time.
        /// </summary>
        field(5792; "Shipping Time"; DateFormula)
        {
            Caption = 'Shipping Time';
            Editable = false;
        }
        /// <summary>
        /// Specifies the formula used to calculate warehouse handling time.
        /// </summary>
        field(5793; "Warehouse Handling Time"; DateFormula)
        {
            Caption = 'Warehouse Handling Time';
            Editable = false;
        }
        /// <summary>
        /// Indicates whether the order was shipped later than planned.
        /// </summary>
        field(5797; "Late Order Shipping"; Boolean)
        {
            Caption = 'Late Order Shipping';
            Editable = false;
        }
        /// <summary>
        /// Specifies the return order number that this receipt was created from.
        /// </summary>
        field(6601; "Return Order No."; Code[20])
        {
            Caption = 'Return Order No.';
            ToolTip = 'Specifies the number of the return order that will post a return receipt.';
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
        /// Specifies the method used to calculate prices on the return.
        /// </summary>
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        /// <summary>
        /// Indicates whether line discounts are allowed on the return.
        /// </summary>
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Return Order No.")
        {
        }
        key(Key3; "Sell-to Customer No.", "External Document No.")
        {
        }
        key(Key4; "Bill-to Customer No.")
        {
        }
        key(Key5; "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PostSalesDelete: Codeunit "PostSales-Delete";
    begin
        PostSalesDelete.IsDocumentDeletionAllowed("Posting Date");
        CheckNoPrinted();
        LockTable();
        PostSalesDelete.DeleteSalesRcptLines(Rec);

        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Posted Return Receipt");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.DeleteAll();

        ApprovalsMgmt.DeletePostedApprovalEntries(RecordId);
    end;

    var
        ReturnRcptHeader: Record "Return Receipt Header";
        SalesCommentLine: Record "Sales Comment Line";
        DimMgt: Codeunit DimensionManagement;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        UserSetupMgt: Codeunit "User Setup Management";
#pragma warning disable AA0074
        Text001: Label 'Posted Document Dimensions';
#pragma warning restore AA0074

    /// <summary>
    /// Gets the customer's VAT registration number from this return receipt.
    /// </summary>
    /// <returns>The VAT registration number.</returns>
    procedure GetCustomerVATRegistrationNumber(): Text
    begin
        exit("VAT Registration No.");
    end;

    /// <summary>
    /// Gets the label for the customer's VAT registration number field.
    /// </summary>
    /// <returns>The field caption if VAT registration number is set, otherwise empty string.</returns>
    procedure GetCustomerVATRegistrationNumberLbl(): Text
    begin
        if "VAT Registration No." = '' then
            exit('');
        exit(FieldCaption("VAT Registration No."));
    end;

    /// <summary>
    /// Gets the customer's Global Location Number (GLN).
    /// </summary>
    /// <returns>The customer's GLN, or empty string if customer not found.</returns>
    procedure GetCustomerGlobalLocationNumber(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Sell-to Customer No.") then
            exit(Customer.GLN);
        exit('');
    end;

    /// <summary>
    /// Gets the label for the customer's Global Location Number field.
    /// </summary>
    /// <returns>The GLN field caption, or empty string if customer not found.</returns>
    procedure GetCustomerGlobalLocationNumberLbl(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Sell-to Customer No.") then
            exit(Customer.FieldCaption(GLN));
        exit('');
    end;

    /// <summary>
    /// Gets the legal statement text from the Sales and Receivables Setup.
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
    /// Prints the return receipt records using the configured report selection.
    /// </summary>
    /// <param name="ShowDialog">Specifies whether to show the print dialog.</param>
    procedure PrintRecords(ShowDialog: Boolean)
    var
        ReportSelection: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        ReturnRcptHeader.Copy(Rec);
        ReportSelection.PrintWithDialogForCust(
            ReportSelection.Usage::"S.Ret.Rcpt.", ReturnRcptHeader, ShowDialog, FieldNo("Bill-to Customer No."));
    end;

    /// <summary>
    /// Validates that the return receipt has been printed at least once.
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
    /// Sends the return receipt records via email using the configured document sending profile.
    /// </summary>
    /// <param name="ShowDialog">Specifies whether to show the email dialog.</param>
    procedure EmailRecords(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEmailRecords(Rec, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        DocumentSendingProfile.TrySendToEMail(
          DummyReportSelections.Usage::"S.Ret.Rcpt.".AsInteger(), Rec, FieldNo("No."),
          ReportDistributionMgt.GetFullDocumentTypeText(Rec), FieldNo("Bill-to Customer No."), ShowDialog);
    end;

    /// <summary>
    /// Opens the Navigate page to show related entries for this return receipt.
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
    /// Opens a page showing the dimension set for this return receipt.
    /// </summary>
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 - %3', TableCaption(), "No.", Text001));
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
    /// Opens the shipping agent's tracking website for the package.
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
    /// Sends the selected return receipt records using the customer's document sending profile.
    /// </summary>
    procedure SendRecords()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        DocumentTypeTxt: Text[50];
    begin
        DocumentTypeTxt := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        DocumentSendingProfile.SendCustomerRecords(
          DummyReportSelections.Usage::"S.Ret.Rcpt.".AsInteger(), Rec, DocumentTypeTxt, "Bill-to Customer No.", "No.",
          FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    /// <summary>
    /// Prints the return receipt and attaches it to the document.
    /// </summary>
    /// <param name="ReturnReceiptHeader">The return receipt header records to print.</param>
    procedure PrintToDocumentAttachment(var ReturnReceiptHeader: Record "Return Receipt Header")
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := ReturnReceiptHeader.Count() = 1;
        if ReturnReceiptHeader.FindSet() then
            repeat
                DoPrintToDocumentAttachment(ReturnReceiptHeader, ShowNotificationAction);
            until ReturnReceiptHeader.Next() = 0;
    end;

    local procedure DoPrintToDocumentAttachment(ReturnReceiptHeader: Record "Return Receipt Header"; ShowNotificationAction: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReturnReceiptHeader.SetRecFilter();
        ReportSelections.SaveAsDocumentAttachment(
            ReportSelections.Usage::"S.Ret.Rcpt.".AsInteger(), ReturnReceiptHeader, ReturnReceiptHeader."No.", ReturnReceiptHeader."Bill-to Customer No.", ShowNotificationAction);
    end;

    /// <summary>
    /// Raised before printing return receipt records.
    /// </summary>
    /// <param name="ReturnRcptHeader">The return receipt header to print.</param>
    /// <param name="ShowDialog">Indicates whether to show the print dialog.</param>
    /// <param name="IsHandled">Set to true to skip default print processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var ReturnRcptHeader: Record "Return Receipt Header"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before emailing return receipt records.
    /// </summary>
    /// <param name="ReturnRcptHeader">The return receipt header to email.</param>
    /// <param name="ShowDialog">Indicates whether to show the email dialog.</param>
    /// <param name="IsHandled">Set to true to skip default email processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmailRecords(var ReturnRcptHeader: Record "Return Receipt Header"; var ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before setting security filter on responsibility center for the return receipt.
    /// </summary>
    /// <param name="ReturnReceiptHeader">The return receipt header to filter.</param>
    /// <param name="IsHandled">Set to true to skip default security filter application.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var ReturnReceiptHeader: Record "Return Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after setting filters when looking up the applies-to document number.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry with applied filters.</param>
    /// <param name="ReturnReceiptHeader">The return receipt header being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;

    /// <summary>
    /// Raised before checking the number of times the return receipt has been printed.
    /// </summary>
    /// <param name="ReturnRcptHeader">The return receipt header being checked.</param>
    /// <param name="IsHandled">Set to true to skip default print status check.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoPrinted(var ReturnRcptHeader: Record "Return Receipt Header"; var IsHandled: Boolean)
    begin
    end;
}