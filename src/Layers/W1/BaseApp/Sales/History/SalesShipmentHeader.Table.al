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
using Microsoft.Utilities;
using System.Automation;
using System.Globalization;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Stores header information for posted sales shipments including shipping details and customer information.
/// </summary>
table 110 "Sales Shipment Header"
{
    Caption = 'Sales Shipment Header';
    DataCaptionFields = "No.", "Sell-to Customer Name";
    DrillDownPageID = "Posted Sales Shipments";
    LookupPageID = "Posted Sales Shipments";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the customer number who received the shipped items.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            begin
                UpdateSellToCustomerId();
            end;
        }
        /// <summary>
        /// Specifies the unique document number of the posted sales shipment.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the record.';
        }
        /// <summary>
        /// Specifies the customer number to whom the invoice will be sent.
        /// </summary>
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            begin
                UpdateBillToCustomerId();
            end;
        }
        /// <summary>
        /// Specifies the name of the customer receiving the invoice.
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
            ToolTip = 'Specifies an additional part of the name of the customer that you send or sent the invoice or credit memo to.';
        }
        /// <summary>
        /// Specifies the street address of the customer receiving the invoice.
        /// </summary>
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            ToolTip = 'Specifies the address that you sent the invoice to.';
        }
        /// <summary>
        /// Specifies additional street address information for the bill-to customer.
        /// </summary>
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            ToolTip = 'Specifies the extended address that you sent the invoice to.';
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
        /// Specifies the name of the contact person at the bill-to customer.
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
        }
        /// <summary>
        /// Specifies the code for an alternate ship-to address.
        /// </summary>
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies the code for the customer''s additional shipment address.';
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
            ToolTip = 'Specifies the address that you delivered the items to.';
        }
        /// <summary>
        /// Specifies additional street address information for the ship-to address.
        /// </summary>
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            ToolTip = 'Specifies the extended address that you delivered the items to.';
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
        /// Specifies the date when the shipment was posted to the ledger.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date for the entry.';
        }
        /// <summary>
        /// Specifies the date when the items were shipped.
        /// </summary>
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        /// <summary>
        /// Specifies a description of the posting.
        /// </summary>
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        /// <summary>
        /// Specifies the code for payment terms.
        /// </summary>
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        /// <summary>
        /// Specifies the date by which payment is due.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// Specifies the percentage of payment discount given if payment is made on time.
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
        /// Specifies the shipment method used for delivering the items.
        /// </summary>
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
            TableRelation = "Shipment Method";
        }
        /// <summary>
        /// Specifies the warehouse location from which items were shipped.
        /// </summary>
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location from which the items were shipped.';
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
        /// Specifies the customer posting group that determines G/L accounts for posting.
        /// </summary>
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
        }
        /// <summary>
        /// Specifies the currency code for amounts on the shipment.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code of the shipment.';
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
        /// Indicates whether the unit prices include VAT.
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
            ToolTip = 'Specifies a code for the salesperson who normally handles this customer''s account.';
            TableRelation = "Salesperson/Purchaser";
        }
        /// <summary>
        /// Specifies the sales order number from which this shipment was created.
        /// </summary>
        field(44; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            ToolTip = 'Specifies the number of the sales order that this invoice was posted from.';
        }
        /// <summary>
        /// Indicates whether comments exist for this shipment.
        /// </summary>
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Sales Comment Line" where("Document Type" = const(Shipment),
                                                            "No." = field("No."),
                                                            "Document Line No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies how many times the shipment has been printed.
        /// </summary>
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            ToolTip = 'Specifies how many times the document has been printed.';
            Editable = false;
        }
        /// <summary>
        /// Specifies a code indicating that processing is on hold.
        /// </summary>
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        /// <summary>
        /// Specifies the type of document this applies to for payment application.
        /// </summary>
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        /// <summary>
        /// Specifies the document number this applies to for payment application.
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
        /// Specifies the customer's VAT registration number.
        /// </summary>
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
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
        /// Indicates whether this is a three-party trade within the EU.
        /// </summary>
        field(75; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
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
            ToolTip = 'Specifies the name of customer at the sell-to address.';
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
            ToolTip = 'Specifies the customer''s sell-to address.';
        }
        /// <summary>
        /// Specifies additional street address information for the sell-to customer.
        /// </summary>
        field(82; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';
            ToolTip = 'Specifies the customer''s extended sell-to address.';
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
            ToolTip = 'Specifies the post code of the customer''s sell-to address.';
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
            ToolTip = 'Specifies the customer''s country/region.';
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
            TableRelation = "Entry/Exit Point";
        }
        /// <summary>
        /// Indicates whether this shipment is a correction entry.
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
            ToolTip = 'Specifies the date when the related document was created.';
        }
        /// <summary>
        /// Specifies an external document number such as the customer's purchase order number.
        /// </summary>
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies the number that the customer uses in their own system to refer to this sales document.';
        }
        /// <summary>
        /// Specifies the geographic area for Intrastat reporting.
        /// </summary>
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        /// <summary>
        /// Specifies additional transaction details for Intrastat reporting.
        /// </summary>
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        /// <summary>
        /// Specifies the method of payment.
        /// </summary>
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
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

            trigger OnValidate()
            begin
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
            end;
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
        /// Specifies the number series used for the posted shipment.
        /// </summary>
        field(109; "No. Series"; Code[20])
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
        /// Specifies the user who posted the shipment.
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
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether the customer is liable for sales tax.
        /// </summary>
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
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
        /// Specifies the percentage of payment discount deducted from the VAT base.
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
        /// Specifies the quote number from which the order originated.
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
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
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
        /// Contains the work or job description for the shipment.
        /// </summary>
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
            DataClassification = CustomerContent;
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
        /// Specifies the marketing campaign associated with this shipment.
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
            ToolTip = 'Specifies the contact number.';
            TableRelation = Contact;
        }
        /// <summary>
        /// Specifies the contact number for the bill-to customer.
        /// </summary>
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            ToolTip = 'Specifies the number of the contact person at the customer''s bill-to address.';
            TableRelation = Contact;
        }
        /// <summary>
        /// Specifies the sales opportunity associated with this shipment.
        /// </summary>
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;
        }
        /// <summary>
        /// Specifies the responsibility center for this shipment.
        /// </summary>
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            ToolTip = 'Specifies the code for the responsibility center that serves the customer on this sales document.';
            TableRelation = "Responsibility Center";
        }
        /// <summary>
        /// Specifies the date the customer requested delivery.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            ToolTip = 'Specifies the date that the customer has asked for the order to be delivered.';
        }
        /// <summary>
        /// Specifies the date that was promised for delivery.
        /// </summary>
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
            ToolTip = 'Specifies the date that you have promised to deliver the order, as a result of the Order Promising function.';
        }
        /// <summary>
        /// Specifies the time required for shipping from the shipping agent.
        /// </summary>
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';
            ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
        }
        /// <summary>
        /// Specifies the time required for outbound warehouse handling.
        /// </summary>
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Outbound Whse. Handling Time';
            ToolTip = 'Specifies a date formula for the time it takes to get items ready to ship from this location. The time element is used in the calculation of the delivery date as follows: Shipment Date + Outbound Warehouse Handling Time = Planned Shipment Date + Shipping Time = Planned Delivery Date.';
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
        /// Specifies the method used for calculating prices.
        /// </summary>
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        /// <summary>
        /// Indicates whether line discounts are allowed.
        /// </summary>
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
        }
        /// <summary>
        /// Stores the unique identifier for the sell-to customer.
        /// </summary>
        field(9001; "Customer Id"; Guid)
        {
            Caption = 'Customer Id';
            DataClassification = SystemMetadata;
            TableRelation = Customer.SystemId;

            trigger OnValidate()
            begin
                UpdateSellToCustomerNo();
            end;
        }
        /// <summary>
        /// Stores the unique identifier for the bill-to customer.
        /// </summary>
        field(9002; "Bill-to Customer Id"; Guid)
        {
            Caption = 'Bill-to Customer Id';
            DataClassification = SystemMetadata;
            TableRelation = Customer.SystemId;

            trigger OnValidate()
            begin
                UpdateBillToCustomerNo();
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
        key(Key3; "Bill-to Customer No.")
        {
        }
        key(Key4; "Sell-to Customer No.")
        {
        }
        key(Key5; "Posting Date")
        {
        }
        key(Key6; "Location Code")
        {
        }
        key(Key7; "Salesperson Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Sell-to Customer No.", "Sell-to Customer Name", "Posting Date", "Posting Description")
        {
        }
    }

    trigger OnInsert()
    begin
        UpdateSellToCustomerId();
        UpdateBillToCustomerId();
    end;

    trigger OnDelete()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        PostSalesDelete: Codeunit "PostSales-Delete";
    begin
        PostSalesDelete.IsDocumentDeletionAllowed("Posting Date");
        CheckNoPrinted();
        LockTable();
        PostSalesDelete.DeleteSalesShptLines(Rec);

        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::Shipment);
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.DeleteAll();

        ApprovalsMgmt.DeletePostedApprovalEntries(RecordId);

        if CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", "No.") then
            CertificateOfSupply.Delete(true);
    end;

    var
        SalesShptHeader: Record "Sales Shipment Header";
        SalesCommentLine: Record "Sales Comment Line";
        ShippingAgent: Record "Shipping Agent";
        DimMgt: Codeunit DimensionManagement;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        UserSetupMgt: Codeunit "User Setup Management";

    /// <summary>
    /// Sends the shipment document using the specified document sending profile.
    /// </summary>
    /// <param name="DocumentSendingProfile">Specifies the sending profile to use.</param>
    procedure SendProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    var
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendProfile(DocumentSendingProfile, Rec, IsHandled);
        if IsHandled then
            exit;

        DocumentSendingProfile.Send(
          DummyReportSelections.Usage::"S.Shipment".AsInteger(), Rec, "No.", "Sell-to Customer No.",
          ReportDistributionMgt.GetFullDocumentTypeText(Rec), FieldNo("Sell-to Customer No."), FieldNo("No."));
    end;

    /// <summary>
    /// Sends the selected shipment records using the customer's document sending profile.
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
          DummyReportSelections.Usage::"S.Shipment".AsInteger(), Rec, DocumentTypeTxt, "Bill-to Customer No.", "No.",
          FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    /// <summary>
    /// Prints the sales shipment records using the configured report selection.
    /// </summary>
    /// <param name="ShowRequestForm">Specifies whether to show the report request page.</param>
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        ReportSelection: Record "Report Selections";
        IsHandled: Boolean;
    begin
        SalesShptHeader.Copy(Rec);
        OnBeforePrintRecords(SalesShptHeader, ShowRequestForm, IsHandled);
        if IsHandled then
            exit;

        ReportSelection.PrintWithDialogForCust(
          ReportSelection.Usage::"S.Shipment", SalesShptHeader, ShowRequestForm, SalesShptHeader.FieldNo("Bill-to Customer No."));
    end;

    /// <summary>
    /// Validates that the shipment has been printed at least once.
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
    /// Sends the sales shipment records via email using the configured document sending profile.
    /// </summary>
    /// <param name="ShowDialog">Specifies whether to show the email dialog.</param>
    procedure EmailRecords(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        IsHandled: Boolean;
    begin
        OnBeforeEmailRecords(Rec, ShowDialog, IsHandled);
        if IsHandled then
            exit;

        DocumentSendingProfile.TrySendToEMail(
          DummyReportSelections.Usage::"S.Shipment".AsInteger(), Rec, FieldNo("No."),
          ReportDistributionMgt.GetFullDocumentTypeText(Rec), FieldNo("Bill-to Customer No."), ShowDialog);
    end;

    /// <summary>
    /// Opens the Navigate page to show related entries for this sales shipment.
    /// </summary>
    procedure Navigate()
    var
        NavigatePage: Page Navigate;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNavigate(Rec, IsHandled);
        if IsHandled then
            exit;

        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    /// <summary>
    /// Opens the shipping agent's tracking website for the package.
    /// </summary>
    procedure StartTrackingSite()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStartTrackingSite(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Shipping Agent Code");
        ShippingAgent.Get("Shipping Agent Code");
        HyperLink(ShippingAgent.GetTrackingInternetAddr("Package Tracking No."));
    end;

    /// <summary>
    /// Opens a page showing the dimension set for this sales shipment.
    /// </summary>
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;

    /// <summary>
    /// Checks if all lines in the shipment have been fully invoiced.
    /// </summary>
    /// <returns>Returns true if there are no uninvoiced quantities remaining.</returns>
    procedure IsCompletlyInvoiced(): Boolean
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", "No.");
        SalesShipmentLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
        if SalesShipmentLine.IsEmpty() then
            exit(true);
        exit(false);
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
    /// Gets the legal statement from sales setup for printing on shipments.
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
    /// Gets the work description text from the blob field.
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
    /// Prints the shipments and saves them as document attachments.
    /// </summary>
    /// <param name="SalesShipmentHeader">The shipment records to print and attach.</param>
    procedure PrintToDocumentAttachment(var SalesShipmentHeader: Record "Sales Shipment Header")
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := SalesShipmentHeader.Count() = 1;
        if SalesShipmentHeader.FindSet() then
            repeat
                DoPrintToDocumentAttachment(SalesShipmentHeader, ShowNotificationAction);
            until SalesShipmentHeader.Next() = 0;
    end;

    local procedure DoPrintToDocumentAttachment(SalesShipmentHeader: Record "Sales Shipment Header"; ShowNotificationAction: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        SalesShipmentHeader.SetRecFilter();
        ReportSelections.SaveAsDocumentAttachment(
            ReportSelections.Usage::"S.Shipment".AsInteger(), SalesShipmentHeader, SalesShipmentHeader."No.", SalesShipmentHeader."Bill-to Customer No.", ShowNotificationAction);
    end;

    local procedure UpdateSellToCustomerId()
    var
        Customer: Record Customer;
    begin
        if "Sell-to Customer No." = '' then begin
            Clear("Customer Id");
            exit;
        end;

        if not Customer.Get("Sell-to Customer No.") then
            exit;

        "Customer Id" := Customer.SystemId;
    end;

    local procedure UpdateBillToCustomerId()
    var
        Customer: Record Customer;
    begin
        if "Bill-to Customer No." = '' then begin
            Clear("Bill-to Customer Id");
            exit;
        end;

        if not Customer.Get("Bill-to Customer No.") then
            exit;

        "Bill-to Customer Id" := Customer.SystemId;
    end;

    local procedure UpdateSellToCustomerNo()
    var
        Customer: Record Customer;
    begin
        if not IsNullGuid("Customer Id") then
            Customer.GetBySystemId("Customer Id");

        "Sell-to Customer No." := Customer."No.";
    end;

    local procedure UpdateBillToCustomerNo()
    var
        Customer: Record Customer;
    begin
        if not IsNullGuid("Bill-to Customer Id") then
            Customer.GetBySystemId("Bill-to Customer Id");

        "Bill-to Customer No." := Customer."No.";
    end;

    /// <summary>
    /// Raised before emailing sales shipment records.
    /// </summary>
    /// <param name="SalesShipmentHeader">The sales shipment header records to email.</param>
    /// <param name="SendDialog">Specifies whether to show the send dialog.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmailRecords(var SalesShipmentHeader: Record "Sales Shipment Header"; var SendDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before printing sales shipment records.
    /// </summary>
    /// <param name="SalesShipmentHeader">The sales shipment header records to print.</param>
    /// <param name="ShowDialog">Specifies whether to show the print dialog.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var SalesShipmentHeader: Record "Sales Shipment Header"; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before starting the package tracking site for the shipment.
    /// </summary>
    /// <param name="SalesShipmentHeader">The sales shipment header record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartTrackingSite(var SalesShipmentHeader: Record "Sales Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before sending the sales shipment using a document sending profile.
    /// </summary>
    /// <param name="DocumentSendingProfile">The document sending profile to use.</param>
    /// <param name="SalesShipmentHeader">The sales shipment header record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendProfile(var DocumentSendingProfile: Record "Document Sending Profile"; var SalesShipmentHeader: Record "Sales Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before setting the security filter on responsibility center for the sales shipment header.
    /// </summary>
    /// <param name="SalesShipmentHeader">The sales shipment header record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesShipmentHeader: Record "Sales Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after setting filters during the Applies-to Doc. No. lookup.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry record with filters applied.</param>
    /// <param name="SalesShipmentHeader">The sales shipment header record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    /// <summary>
    /// Raised before navigating to related entries for the sales shipment.
    /// </summary>
    /// <param name="SalesShipmentHeader">The sales shipment header record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeNavigate(SalesShipmentHeader: Record "Sales Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking the number of times the sales shipment has been printed.
    /// </summary>
    /// <param name="SalesShipmentHeader">The sales shipment header record.</param>
    /// <param name="IsHandled">Set to true to skip the default logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoPrinted(var SalesShipmentHeader: Record "Sales Shipment Header"; var IsHandled: Boolean)
    begin
    end;
}
