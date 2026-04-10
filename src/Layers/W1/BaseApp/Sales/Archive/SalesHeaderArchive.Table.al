// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Archive;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
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
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using System.Globalization;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

/// <summary>
/// Stores archived versions of sales document headers for historical reference and audit trails.
/// </summary>
table 5107 "Sales Header Archive"
{
    Caption = 'Sales Header Archive';
    DataCaptionFields = "No.", "Sell-to Customer Name", "Version No.";
    DrillDownPageID = "Sales List Archive";
    LookupPageID = "Sales List Archive";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the type of the archived sales document, such as quote, order, invoice, or credit memo.
        /// </summary>
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        /// <summary>
        /// Specifies the customer who will receive the products and be billed by default for this archived sales document.
        /// </summary>
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;
            ToolTip = 'Specifies the number of the customer who will receive the products and be billed by default.';
        }
        /// <summary>
        /// Specifies the unique identifier for the archived sales document.
        /// </summary>
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        /// <summary>
        /// Specifies the customer to whom the invoice or credit memo was sent for this archived sales document.
        /// </summary>
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;
            ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
        }
        /// <summary>
        /// Specifies the name of the customer to whom the invoice or credit memo was sent.
        /// </summary>
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
        }
        /// <summary>
        /// Specifies additional name information for the billing customer when the full name cannot fit in the primary field.
        /// </summary>
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer that you send or sent the invoice or credit memo to.';
        }
        /// <summary>
        /// Specifies the street address of the customer to whom the invoice was sent.
        /// </summary>
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            ToolTip = 'Specifies the address of the customer to whom you sent the invoice.';
        }
        /// <summary>
        /// Specifies additional address information for the billing customer when the full address cannot fit in the primary field.
        /// </summary>
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            ToolTip = 'Specifies an additional line of the address.';
        }
        /// <summary>
        /// Specifies the city of the customer's billing address.
        /// </summary>
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
            ToolTip = 'Specifies the city of the address.';
        }
        /// <summary>
        /// Specifies the name of the contact person at the customer's billing address.
        /// </summary>
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
            ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
        }
        /// <summary>
        /// Specifies the customer's own reference number for this transaction, typically used for purchase order numbers.
        /// </summary>
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            ToolTip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
        }
        /// <summary>
        /// Specifies the code for an alternate shipping address when products should be delivered to a different location than the customer's main address.
        /// </summary>
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));
            ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
        }
        /// <summary>
        /// Specifies the name of the recipient at the shipping address.
        /// </summary>
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies additional name information for the shipping recipient when the full name cannot fit in the primary field.
        /// </summary>
        field(14; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer at the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies the street address where the items are shipped to.
        /// </summary>
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            ToolTip = 'Specifies the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies additional address information for the shipping destination when the full address cannot fit in the primary field.
        /// </summary>
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
        }
        /// <summary>
        /// Specifies the city of the shipping destination address.
        /// </summary>
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
            ToolTip = 'Specifies the city of the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies the name of the contact person at the shipping destination address.
        /// </summary>
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
            ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies the date when the sales order was created, which also determines applicable prices and discounts.
        /// </summary>
        field(19; "Order Date"; Date)
        {
            Caption = 'Order Date';
            ToolTip = 'Specifies the date the order was created. The order date is also used to determine the prices and discounts on the document.';
        }
        /// <summary>
        /// Specifies the date when the sales document was posted to the general ledger.
        /// </summary>
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date when the document was posted.';
        }
        /// <summary>
        /// Specifies the date when items on the document are scheduled to ship or were shipped.
        /// </summary>
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        /// <summary>
        /// Specifies the description that appears on posted ledger entries for this document.
        /// </summary>
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        /// <summary>
        /// Specifies the payment terms that determine due dates, discount dates, and discount amounts for the sales document.
        /// </summary>
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
            ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount on the sales document.';
        }
        /// <summary>
        /// Specifies the date by which the customer must pay the sales invoice.
        /// </summary>
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies when the related sales invoice must be paid.';
        }
        /// <summary>
        /// Specifies the percentage discount granted if the customer pays by the payment discount date.
        /// </summary>
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
            ToolTip = 'Specifies the payment discount percentage that is granted if the customer pays on or before the date entered in the Pmt. Discount Date field. The discount percentage is specified in the Payment Terms Code field.';
        }
        /// <summary>
        /// Specifies the last date on which the customer can pay to receive a payment discount.
        /// </summary>
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
        }
        /// <summary>
        /// Specifies the delivery conditions for the shipment, such as free on board (FOB) or cost, insurance, and freight (CIF).
        /// </summary>
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
            ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
        }
        /// <summary>
        /// Specifies the default warehouse location from which items on the sales document are shipped.
        /// </summary>
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
            ToolTip = 'Specifies the location from where items are to be shipped. This field acts as the default location for new lines. Location code for individual lines can differ from it.';
        }
        /// <summary>
        /// Specifies the first global dimension code for analyzing the document, typically representing a department or cost center.
        /// </summary>
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
        }
        /// <summary>
        /// Specifies the second global dimension code for analyzing the document, typically representing a project or region.
        /// </summary>
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
        }
        /// <summary>
        /// Specifies the posting group that determines the G/L accounts to use for posting receivables and other financial entries.
        /// </summary>
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
        }
        /// <summary>
        /// Specifies the currency in which the sales document amounts are expressed.
        /// </summary>
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
            ToolTip = 'Specifies the currency that is used on the entry.';
        }
        /// <summary>
        /// Specifies the exchange rate used to convert document amounts from the document currency to the local currency.
        /// </summary>
        field(33; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the customer price group used to determine special sales prices for the customer.
        /// </summary>
        field(34; "Price Group Code"; Code[10])
        {
            Caption = 'Price Group Code';
            TableRelation = "Customer Price Group";
        }
        /// <summary>
        /// Indicates whether the unit prices and line amounts on the document include VAT.
        /// </summary>
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
            ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
        }
        /// <summary>
        /// Specifies the code used to look up the invoice discount terms for the customer.
        /// </summary>
        field(37; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
        }
        /// <summary>
        /// Specifies the customer discount group used to determine item-specific discounts for the customer.
        /// </summary>
        field(40; "Cust./Item Disc. Gr."; Code[20])
        {
            Caption = 'Cust./Item Disc. Gr.';
            TableRelation = "Customer Discount Group";
        }
        /// <summary>
        /// Specifies the language code used when printing documents for this customer.
        /// </summary>
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        /// <summary>
        /// Specifies the regional format settings used for dates, numbers, and currency formatting on printed documents.
        /// </summary>
        field(42; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        /// <summary>
        /// Specifies the salesperson responsible for this sales document for commission and performance tracking.
        /// </summary>
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
            ToolTip = 'Specifies which salesperson is associated with the sales document.';
        }
        /// <summary>
        /// Specifies the classification of the sales order for categorization and analysis purposes.
        /// </summary>
        field(45; "Order Class"; Code[10])
        {
            Caption = 'Order Class';
        }
        /// <summary>
        /// Indicates whether comments exist for this archived sales document header.
        /// </summary>
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Sales Comment Line Archive" where("Document Type" = field("Document Type"),
                                                                    "No." = field("No."),
                                                                    "Document Line No." = const(0),
                                                                    "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                    "Version No." = field("Version No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Stores the number of times this sales document was printed before archiving.
        /// </summary>
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        /// <summary>
        /// Specifies a code indicating that the document processing was placed on hold.
        /// </summary>
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        /// <summary>
        /// Specifies the type of posted document to which this sales document is applied for payment or settlement purposes.
        /// </summary>
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
            ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
        }
        /// <summary>
        /// Specifies the number of the posted document to which this sales document is applied for payment or settlement purposes.
        /// </summary>
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
        }
        /// <summary>
        /// Specifies the balancing account number used for posting the sales document.
        /// </summary>
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        /// <summary>
        /// Indicates whether shipment was selected to be posted when the document was archived.
        /// </summary>
        field(57; Ship; Boolean)
        {
            Caption = 'Ship';
        }
        /// <summary>
        /// Indicates whether invoice posting was selected when the document was archived.
        /// </summary>
        field(58; Invoice; Boolean)
        {
            Caption = 'Invoice';
        }
        /// <summary>
        /// Contains the total amount of all lines on the archived sales document, excluding VAT.
        /// </summary>
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Sales Line Archive".Amount where("Document Type" = field("Document Type"),
                                                                 "Document No." = field("No."),
                                                                 "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                 "Version No." = field("Version No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the total amount of all lines on the archived sales document, including VAT.
        /// </summary>
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Sales Line Archive"."Amount Including VAT" where("Document Type" = field("Document Type"),
                                                                                 "Document No." = field("No."),
                                                                                 "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                                 "Version No." = field("Version No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the number assigned to the shipment document created from this sales order.
        /// </summary>
        field(62; "Shipping No."; Code[20])
        {
            Caption = 'Shipping No.';
        }
        /// <summary>
        /// Specifies the number assigned to the posted invoice or credit memo created from this document.
        /// </summary>
        field(63; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
        }
        /// <summary>
        /// Specifies the number of the most recently posted shipment document for this sales order.
        /// </summary>
        field(64; "Last Shipping No."; Code[20])
        {
            Caption = 'Last Shipping No.';
            TableRelation = "Sales Shipment Header";
        }
        /// <summary>
        /// Specifies the number of the most recently posted invoice or credit memo for this sales document.
        /// </summary>
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            TableRelation = "Sales Invoice Header";
        }
        /// <summary>
        /// Specifies the number of the prepayment invoice for this sales order.
        /// </summary>
        field(66; "Prepayment No."; Code[20])
        {
            Caption = 'Prepayment No.';
        }
        /// <summary>
        /// Specifies the number of the most recently posted prepayment invoice for this sales order.
        /// </summary>
        field(67; "Last Prepayment No."; Code[20])
        {
            Caption = 'Last Prepayment No.';
            TableRelation = "Sales Invoice Header";
        }
        /// <summary>
        /// Specifies the number of the prepayment credit memo for this sales order.
        /// </summary>
        field(68; "Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No.';
        }
        /// <summary>
        /// Specifies the number of the most recently posted prepayment credit memo for this sales order.
        /// </summary>
        field(69; "Last Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Last Prepmt. Cr. Memo No.';
            TableRelation = "Sales Invoice Header";
        }
        /// <summary>
        /// Specifies the customer's VAT registration number for tax reporting purposes.
        /// </summary>
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        /// <summary>
        /// Indicates whether multiple orders for the customer can be combined into a single shipment.
        /// </summary>
        field(71; "Combine Shipments"; Boolean)
        {
            Caption = 'Combine Shipments';
        }
        /// <summary>
        /// Specifies the reason code explaining why the document was created or modified.
        /// </summary>
        field(73; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        /// <summary>
        /// Specifies the general business posting group used to determine the G/L accounts for posting sales transactions.
        /// </summary>
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// Indicates whether the transaction involves a triangular trade arrangement within the European Union.
        /// </summary>
        field(75; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
        }
        /// <summary>
        /// Specifies the type of transaction for Intrastat reporting, such as purchase, sale, or transfer.
        /// </summary>
        field(76; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
            ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
        }
        /// <summary>
        /// Specifies the method of transport used for the shipment, for Intrastat reporting purposes.
        /// </summary>
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
            ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
        }
        /// <summary>
        /// Specifies the country or region where VAT is reported, typically the customer's country.
        /// </summary>
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Specifies the name of the customer who receives the products and is billed by default.
        /// </summary>
        field(79; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            ToolTip = 'Specifies the name of the customer who will receive the products and be billed by default.';
        }
        /// <summary>
        /// Specifies additional name information for the sell-to customer when the full name cannot fit in the primary field.
        /// </summary>
        field(80; "Sell-to Customer Name 2"; Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer who will receive the products and be billed by default.';
        }
        /// <summary>
        /// Specifies the street address of the customer who receives the products.
        /// </summary>
        field(81; "Sell-to Address"; Text[100])
        {
            Caption = 'Sell-to Address';
            ToolTip = 'Specifies the main address of the customer.';
        }
        /// <summary>
        /// Specifies additional address information for the sell-to customer when the full address cannot fit in the primary field.
        /// </summary>
        field(82; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';
            ToolTip = 'Specifies an additional part of the address.';
        }
        /// <summary>
        /// Specifies the city of the sell-to customer's main address.
        /// </summary>
        field(83; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
            ToolTip = 'Specifies the city of the customer''s main address.';
        }
        /// <summary>
        /// Specifies the name of the contact person at the sell-to customer's main address.
        /// </summary>
        field(84; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';
            ToolTip = 'Specifies the name of the contact person at the customer''s main address.';
        }
        /// <summary>
        /// Specifies the postal code of the customer's billing address.
        /// </summary>
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
            ToolTip = 'Specifies the postal code of the customer''s billing address.';
        }
        /// <summary>
        /// Specifies the county, state, or province of the billing customer's address.
        /// </summary>
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
            ToolTip = 'Specifies the county of the customer on the sales document.';
        }
        /// <summary>
        /// Specifies the country or region of the billing customer's address.
        /// </summary>
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country or region of the customer on the sales document.';
        }
        /// <summary>
        /// Specifies the postal code of the sell-to customer's main address.
        /// </summary>
        field(88; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
            ToolTip = 'Specifies the postal code of the customer''s main address.';
        }
        /// <summary>
        /// Specifies the county, state, or province of the sell-to customer's address.
        /// </summary>
        field(89; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,2,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';
            ToolTip = 'Specifies the county of your customer.';
        }
        /// <summary>
        /// Specifies the country or region of the sell-to customer's address.
        /// </summary>
        field(90; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country or region of your customer.';
        }
        /// <summary>
        /// Specifies the postal code of the shipping destination address.
        /// </summary>
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
            ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies the county, state, or province of the shipping destination address.
        /// </summary>
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
            ToolTip = 'Specifies the county of the ship-to address.';
        }
        /// <summary>
        /// Specifies the country or region of the shipping destination address.
        /// </summary>
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
        }
        /// <summary>
        /// Specifies the type of balancing account used for posting, such as G/L Account or Bank Account.
        /// </summary>
        field(94; "Bal. Account Type"; enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        /// <summary>
        /// Specifies the point of exit through which items are shipped out of the country or region for Intrastat reporting.
        /// </summary>
        field(97; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";
            ToolTip = 'Specifies the point of exit through which you ship the items out of your country/region, for reporting to Intrastat.';
        }
        /// <summary>
        /// Indicates whether the document represents a correction to a previously posted document.
        /// </summary>
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        /// <summary>
        /// Specifies the date when the sales document was created.
        /// </summary>
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date the document was created.';
        }
        /// <summary>
        /// Specifies the customer's document number, such as a purchase order number, for cross-reference purposes.
        /// </summary>
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
        }
        /// <summary>
        /// Specifies the geographic area or destination area for Intrastat reporting purposes.
        /// </summary>
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
            ToolTip = 'Specifies the country or region of origin for the purpose of Intrastat reporting.';
        }
        /// <summary>
        /// Specifies additional transaction details for Intrastat reporting, providing further classification of the trade.
        /// </summary>
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
            ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
        }
        /// <summary>
        /// Specifies the method by which the customer will pay for the products, such as bank transfer or check.
        /// </summary>
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
            ToolTip = 'Specifies how the customer must pay for products on the sales document.';
        }
        /// <summary>
        /// Specifies the shipping carrier responsible for transporting the items to the customer.
        /// </summary>
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
            ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
        }
        /// <summary>
        /// Specifies the tracking number assigned by the shipping carrier for package tracking purposes.
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
        /// Specifies the number series used to assign document numbers to this type of sales document.
        /// </summary>
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the number series used to assign numbers to posted invoices or credit memos.
        /// </summary>
        field(108; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the number series used to assign numbers to shipment documents.
        /// </summary>
        field(109; "Shipping No. Series"; Code[20])
        {
            Caption = 'Shipping No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the tax area code used to calculate and post sales tax for this document.
        /// </summary>
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
            ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
        }
        /// <summary>
        /// Indicates whether the customer is liable for paying sales tax on the transaction.
        /// </summary>
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
        }
        /// <summary>
        /// Specifies the VAT business posting group used to determine VAT rates and accounts for this customer.
        /// </summary>
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
        }
        /// <summary>
        /// Specifies the reservation method for items on the sales document, such as always, optional, or never.
        /// </summary>
        field(117; Reserve; Enum "Reserve Method")
        {
            Caption = 'Reserve';
        }
        /// <summary>
        /// Specifies the identifier used to group entries for application during payment processing.
        /// </summary>
        field(118; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
            ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
        }
        /// <summary>
        /// Specifies the percentage discount applied to the VAT base amount for calculating VAT.
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
        /// Specifies the processing status of the sales document, such as open, released, or pending approval.
        /// </summary>
        field(120; Status; Enum "Sales Document Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies whether the document is open, waiting to be approved, has been invoiced for prepayment, or has been released to the next stage of processing.';
        }
        /// <summary>
        /// Specifies how the invoice discount is calculated, either as a percentage or a fixed amount.
        /// </summary>
        field(121; "Invoice Discount Calculation"; Option)
        {
            Caption = 'Invoice Discount Calculation';
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        /// <summary>
        /// Specifies the value of the invoice discount, either as a percentage or amount depending on the calculation method.
        /// </summary>
        field(122; "Invoice Discount Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            Caption = 'Invoice Discount Value';
        }
        /// <summary>
        /// Indicates whether the document should be sent to an intercompany partner.
        /// </summary>
        field(123; "Send IC Document"; Boolean)
        {
            Caption = 'Send IC Document';
        }
        /// <summary>
        /// Specifies the intercompany processing status of the document.
        /// </summary>
        field(124; "IC Status"; Enum "Sales Document IC Status")
        {
            Caption = 'IC Status';
        }
        /// <summary>
        /// Specifies the intercompany partner code for the sell-to customer in intercompany transactions.
        /// </summary>
        field(125; "Sell-to IC Partner Code"; Code[20])
        {
            Caption = 'Sell-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Specifies the intercompany partner code for the bill-to customer in intercompany transactions.
        /// </summary>
        field(126; "Bill-to IC Partner Code"; Code[20])
        {
            Caption = 'Bill-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Specifies the document number used by the intercompany partner to reference this transaction.
        /// </summary>
        field(127; "IC Reference Document No."; Code[20])
        {
            Caption = 'IC Reference Document No.';
            Editable = false;
        }
        /// <summary>
        /// Specifies the direction of the intercompany transaction, either outgoing or incoming.
        /// </summary>
        field(129; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';
        }
        /// <summary>
        /// Specifies the percentage of the order amount that must be prepaid before processing.
        /// </summary>
        field(130; "Prepayment %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the number series used to assign numbers to prepayment invoices.
        /// </summary>
        field(131; "Prepayment No. Series"; Code[20])
        {
            Caption = 'Prepayment No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Indicates whether prepayment lines should be compressed into a single line on the prepayment invoice.
        /// </summary>
        field(132; "Compress Prepayment"; Boolean)
        {
            Caption = 'Compress Prepayment';
            InitValue = true;
        }
        /// <summary>
        /// Specifies the date when the prepayment invoice is due for payment.
        /// </summary>
        field(133; "Prepayment Due Date"; Date)
        {
            Caption = 'Prepayment Due Date';
        }
        /// <summary>
        /// Specifies the number series used to assign numbers to prepayment credit memos.
        /// </summary>
        field(134; "Prepmt. Cr. Memo No. Series"; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the description that appears on posted ledger entries for prepayment transactions.
        /// </summary>
        field(135; "Prepmt. Posting Description"; Text[100])
        {
            Caption = 'Prepmt. Posting Description';
        }
        /// <summary>
        /// Specifies the last date on which the customer can pay the prepayment to receive a discount.
        /// </summary>
        field(138; "Prepmt. Pmt. Discount Date"; Date)
        {
            Caption = 'Prepmt. Pmt. Discount Date';
        }
        /// <summary>
        /// Specifies the payment terms applied to prepayment invoices for this sales order.
        /// </summary>
        field(139; "Prepmt. Payment Terms Code"; Code[10])
        {
            Caption = 'Prepmt. Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        /// <summary>
        /// Specifies the payment discount percentage granted if the prepayment is paid by the discount date.
        /// </summary>
        field(140; "Prepmt. Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepmt. Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Contains the total number of archived versions for this sales document.
        /// </summary>
        field(145; "No. of Archived Versions"; Integer)
        {
            CalcFormula = max("Sales Header Archive"."Version No." where("Document Type" = field("Document Type"),
                                                                          "No." = field("No."),
                                                                          "Doc. No. Occurrence" = field("Doc. No. Occurrence")));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the number of the sales quote from which this order was created.
        /// </summary>
        field(151; "Sales Quote No."; Code[20])
        {
            Caption = 'Sales Quote No.';
            Editable = false;
            TableRelation = "Sales Header"."No." where("Document Type" = const(Quote),
                                                        "No." = field("Sales Quote No."));
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Specifies the expiration date of the sales quote after which it is no longer valid.
        /// </summary>
        field(152; "Quote Valid Until Date"; Date)
        {
            Caption = 'Quote Valid To Date';
            ToolTip = 'Specifies how long the quote is valid.';
        }
        /// <summary>
        /// Specifies the date and time when the sales quote was sent to the customer.
        /// </summary>
        field(153; "Quote Sent to Customer"; DateTime)
        {
            Caption = 'Quote Sent to Customer';
        }
        /// <summary>
        /// Indicates whether the sales quote has been accepted by the customer.
        /// </summary>
        field(154; "Quote Accepted"; Boolean)
        {
            Caption = 'Quote Accepted';
        }
        /// <summary>
        /// Specifies the date when the sales quote was accepted by the customer.
        /// </summary>
        field(155; "Quote Accepted Date"; Date)
        {
            Caption = 'Quote Accepted Date';
            Editable = false;
        }
        /// <summary>
        /// Specifies the company bank account to which payments for this document should be made.
        /// </summary>
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
        }
        /// <summary>
        /// Specifies the entry number of the incoming document linked to this sales document.
        /// </summary>
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";
        }
        /// <summary>
        /// Specifies the telephone number of the sell-to customer.
        /// </summary>
        field(171; "Sell-to Phone No."; Text[30])
        {
            Caption = 'Sell-to Phone No.';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;
        }
        /// <summary>
        /// Specifies the email address of the sell-to customer.
        /// </summary>
        field(172; "Sell-to E-Mail"; Text[80])
        {
            Caption = 'Sell-to E-Mail';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }
        /// <summary>
        /// Specifies the date used for VAT reporting, which may differ from the posting date.
        /// </summary>
        field(179; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            ToolTip = 'Specifies the entry''s VAT date.';
        }
        /// <summary>
        /// Specifies the country or region from which goods were received for Intrastat reporting.
        /// </summary>
        field(181; "Rcvd.-from Count./Region Code"; Code[10])
        {
            Caption = 'Received-from Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Contains a detailed description of the work or services to be performed for this sales document.
        /// </summary>
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
        }
        /// <summary>
        /// Specifies the telephone number at the shipping destination address.
        /// </summary>
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
            ToolTip = 'Specifies the telephone number of the company''s shipping address.';
        }
        /// <summary>
        /// Specifies the unique identifier for the combination of dimension values assigned to this document.
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
        /// Indicates whether the original source sales document still exists in the system.
        /// </summary>
        field(3998; "Source Doc. Exists"; Boolean)
        {
            FieldClass = Flowfield;
            CalcFormula = exist("Sales Header" where("Document Type" = field("Document Type"),
                                                            "No." = field("No.")));
            Caption = 'Source Doc. Exists';
            Editable = false;
        }
        /// <summary>
        /// Contains the date and time when this document was last archived.
        /// </summary>
        field(3999; "Last Archived Date"; DateTime)
        {
            Caption = 'Last Archived Date';
            FieldClass = FlowField;
            CalcFormula = max("Sales Header Archive".SystemCreatedAt where("Document Type" = field("Document Type"),
                                                            "No." = field("No."),
                                                            "Doc. No. Occurrence" = field("Doc. No. Occurrence")));
            Editable = false;
        }
        /// <summary>
        /// Indicates whether the archived document is linked to an interaction log entry for CRM tracking.
        /// </summary>
        field(5043; "Interaction Exist"; Boolean)
        {
            Caption = 'Interaction Exist';
            ToolTip = 'Specifies that the archived document is linked to an interaction log entry.';
        }
        /// <summary>
        /// Specifies the time of day when this version of the document was archived.
        /// </summary>
        field(5044; "Time Archived"; Time)
        {
            Caption = 'Time Archived';
            ToolTip = 'Specifies what time the document was archived.';
        }
        /// <summary>
        /// Specifies the date when this version of the document was archived.
        /// </summary>
        field(5045; "Date Archived"; Date)
        {
            Caption = 'Date Archived';
            ToolTip = 'Specifies the date when the document was archived.';
        }
        /// <summary>
        /// Specifies the user who created this archived version of the document.
        /// </summary>
        field(5046; "Archived By"; Code[50])
        {
            Caption = 'Archived By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ToolTip = 'Specifies the user ID of the person who archived this document.';
        }
        /// <summary>
        /// Specifies the version number of this archived document within the document occurrence.
        /// </summary>
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
            ToolTip = 'Specifies the version number of the archived document.';
        }
        /// <summary>
        /// Specifies the occurrence count when the same document number has been reused multiple times.
        /// </summary>
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        /// <summary>
        /// Specifies the marketing campaign associated with this sales document.
        /// </summary>
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
            ToolTip = 'Specifies the campaign number the document is linked to.';
        }
        /// <summary>
        /// Specifies the contact person at the sell-to customer's organization.
        /// </summary>
        field(5052; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            TableRelation = Contact;
            ToolTip = 'Specifies the number of the contact person at the customer''s main address.';
        }
        /// <summary>
        /// Specifies the contact person at the billing customer's organization.
        /// </summary>
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact;
            ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
        }
#if not CLEANSCHEMA25
        field(5054; "Bill-to Customer Template Code"; Code[10])
        {
            Caption = 'Bill-to Customer Template Code (obsoleted)';
            ObsoleteReason = 'Will be removed with other functionality related to "old" templates. Replaced by "Bill-to Customer Templ. Code".';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        /// <summary>
        /// Specifies the sales opportunity linked to this document for CRM tracking.
        /// </summary>
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity."No." where("Contact No." = field("Sell-to Contact No."),
                                                     Closed = const(false));
        }
        /// <summary>
        /// Specifies the template code used when creating a new customer from a quote or contact.
        /// </summary>
        field(5056; "Sell-to Customer Templ. Code"; Code[20])
        {
            Caption = 'Sell-to Customer Template Code';
            TableRelation = "Customer Templ.";
            ToolTip = 'Specifies information about sales quotes, purchase quotes, or orders in earlier versions of the document';
        }
        /// <summary>
        /// Specifies the template code used when creating a new billing customer from a quote or contact.
        /// </summary>
        field(5057; "Bill-to Customer Templ. Code"; Code[20])
        {
            Caption = 'Bill-to Customer Template Code';
            TableRelation = "Customer Templ.";
            ToolTip = 'Specifies information about sales quotes, purchase quotes, or orders in earlier versions of the document.';
        }
        /// <summary>
        /// Specifies the responsibility center associated with this sales document for organizational reporting.
        /// </summary>
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
            ToolTip = 'Specifies the code of the responsibility center (for example, a distribution center) assigned to the customer or associated with the order.';
        }
        /// <summary>
        /// Specifies whether partial shipments are allowed or all items must be shipped together.
        /// </summary>
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipping Advice';
            ToolTip = 'Specifies the shipping advice, which informs whether partial deliveries are acceptable.';
        }
        /// <summary>
        /// Indicates whether all items on the sales order have been shipped.
        /// </summary>
        field(5752; "Completely Shipped"; Boolean)
        {
            CalcFormula = min("Sales Line Archive"."Completely Shipped" where("Document Type" = field("Document Type"),
                                                                               "Document No." = field("No."),
                                                                               "Version No." = field("Version No."),
                                                                               "Shipment Date" = field("Date Filter"),
                                                                               "Location Code" = field("Location Filter")));
            Caption = 'Completely Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies an internal reference number for warehouse posting integration.
        /// </summary>
        field(5753; "Posting from Whse. Ref."; Integer)
        {
            Caption = 'Posting from Whse. Ref.';
        }
        /// <summary>
        /// Specifies a filter for displaying document lines by warehouse location.
        /// </summary>
        field(5754; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        /// <summary>
        /// Specifies the date the customer has requested for delivery of the order.
        /// </summary>
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            ToolTip = 'Specifies the date that your customer has asked for the order to be delivered.';
        }
        /// <summary>
        /// Specifies the date that was promised to the customer for delivery, based on order promising calculations.
        /// </summary>
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
            ToolTip = 'Specifies the date that you have promised to deliver the order, as a result of the Order Promising function.';
        }
        /// <summary>
        /// Specifies the transit time from shipment to delivery at the customer's location.
        /// </summary>
        field(5792; "Shipping Time"; DateFormula)
        {
            Caption = 'Shipping Time';
            ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
        }
        /// <summary>
        /// Specifies the time required to prepare and process items in the warehouse before shipping.
        /// </summary>
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Outbound Whse. Handling Time';
            ToolTip = 'Specifies a date formula for the time it takes to get items ready to ship from this location. The time element is used in the calculation of the delivery date as follows: Shipment Date + Outbound Warehouse Handling Time = Planned Shipment Date + Shipping Time = Planned Delivery Date.';
        }
        /// <summary>
        /// Specifies the service level offered by the shipping agent, such as overnight or ground delivery.
        /// </summary>
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
            ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
        }
        /// <summary>
        /// Indicates whether there are outstanding order lines with shipment dates that have passed.
        /// </summary>
        field(5795; "Late Order Shipping"; Boolean)
        {
            CalcFormula = exist("Sales Line Archive" where("Document Type" = field("Document Type"),
                                                            "Sell-to Customer No." = field("Sell-to Customer No."),
                                                            "Document No." = field("No."),
                                                            "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                            "Version No." = field("Version No."),
                                                            "Shipment Date" = field("Date Filter")));
            Caption = 'Late Order Shipping';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Indicates a delay in the shipment of one or more lines, or that the shipment date is either the same as or earlier than the work date.';
        }
        /// <summary>
        /// Specifies a date filter used for filtering FlowFields on the document.
        /// </summary>
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Indicates whether receiving was selected when posting a return order.
        /// </summary>
        field(5800; Receive; Boolean)
        {
            Caption = 'Receive';
        }
        /// <summary>
        /// Specifies the number assigned to the return receipt document.
        /// </summary>
        field(5801; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
        }
        /// <summary>
        /// Specifies the number series used to assign numbers to return receipt documents.
        /// </summary>
        field(5802; "Return Receipt No. Series"; Code[20])
        {
            Caption = 'Return Receipt No. Series';
            TableRelation = "No. Series";
        }
        /// <summary>
        /// Specifies the number of the most recently posted return receipt for this return order.
        /// </summary>
        field(5803; "Last Return Receipt No."; Code[20])
        {
            Caption = 'Last Return Receipt No.';
            TableRelation = "Return Receipt Header";
        }
        /// <summary>
        /// Specifies the method used to calculate prices for the sales document.
        /// </summary>
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        /// <summary>
        /// Indicates whether line discounts are allowed for this sales document.
        /// </summary>
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
        }
        /// <summary>
        /// Indicates whether the Get Shipment Lines function was used to populate the document.
        /// </summary>
        field(7200; "Get Shipment Used"; Boolean)
        {
            Caption = 'Get Shipment Used';
            Editable = false;
        }
        /// <summary>
        /// Specifies the user who was assigned responsibility for processing this sales document.
        /// </summary>
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
            ToolTip = 'Specifies the ID of the user who is responsible for the document.';
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.", "Doc. No. Occurrence", "Version No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Sell-to Customer No.")
        {
        }
        key(Key3; "Document Type", "Bill-to Customer No.")
        {
        }
        key(Key4; "Incoming Document Entry No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Version No.", "Sell-to Customer Name")
        {
        }
    }

    trigger OnDelete()
    var
        SalesLineArchive: Record "Sales Line Archive";
        DeferralHeaderArchive: Record "Deferral Header Archive";
        CatalogItemMgt: Codeunit "Catalog Item Management";
    begin
        SalesLineArchive.SetRange("Document Type", "Document Type");
        SalesLineArchive.SetRange("Document No.", "No.");
        SalesLineArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        SalesLineArchive.SetRange("Version No.", "Version No.");
        SalesLineArchive.SetRange(Nonstock, true);
        if SalesLineArchive.FindSet(true) then
            repeat
                CatalogItemMgt.DelNonStockSalesArch(SalesLineArchive);
            until SalesLineArchive.Next() = 0;
        SalesLineArchive.SetRange(Nonstock);
        SalesLineArchive.DeleteAll();

        SalesCommentLineArch.SetRange("Document Type", "Document Type");
        SalesCommentLineArch.SetRange("No.", "No.");
        SalesCommentLineArch.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        SalesCommentLineArch.SetRange("Version No.", "Version No.");
        SalesCommentLineArch.DeleteAll();

        DeferralHeaderArchive.SetRange("Deferral Doc. Type", "Deferral Document Type"::Sales);
        DeferralHeaderArchive.SetRange("Document Type", "Document Type");
        DeferralHeaderArchive.SetRange("Document No.", "No.");
        DeferralHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        DeferralHeaderArchive.SetRange("Version No.", "Version No.");
        DeferralHeaderArchive.DeleteAll(true);
    end;

    var
        SalesCommentLineArch: Record "Sales Comment Line Archive";
        DimMgt: Codeunit DimensionManagement;
        UserSetupMgt: Codeunit "User Setup Management";

    /// <summary>
    /// Opens the Dimension Set Entries page to display the dimensions associated with this archived sales header.
    /// </summary>
    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."));
    end;

    /// <summary>
    /// Applies a security filter to restrict records based on the current user's assigned responsibility center.
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
    /// Retrieves the work description text from the BLOB field as a readable text string.
    /// </summary>
    /// <returns>The work description text content.</returns>
    procedure GetWorkDescription() WorkDescription: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Work Description");
        "Work Description".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Work Description")));
    end;

    /// <summary>
    /// Raises an event before applying the security filter based on the user's responsibility center.
    /// </summary>
    /// <param name="SalesHeaderArchive">Specifies the sales header archive record to filter.</param>
    /// <param name="IsHandled">Set to true to skip the default filter logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesHeaderArchive: Record "Sales Header Archive"; var IsHandled: Boolean)
    begin
    end;
}
