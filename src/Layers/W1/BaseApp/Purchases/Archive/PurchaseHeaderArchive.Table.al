// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
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
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using System.Globalization;
using System.Security.AccessControl;
using System.Security.User;

table 5109 "Purchase Header Archive"
{
    Caption = 'Purchase Header Archive';
    DataCaptionFields = "No.", "Buy-from Vendor Name", "Version No.";
    DrillDownPageID = "Purchase List Archive";
    LookupPageID = "Purchase List Archive";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Purchase Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            ToolTip = 'Specifies the name of the vendor who delivered the items.';
            TableRelation = Vendor;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            ToolTip = 'Specifies the number of the vendor that you received the invoice from.';
            NotBlank = true;
            TableRelation = Vendor;
        }
        field(5; "Pay-to Name"; Text[100])
        {
            Caption = 'Pay-to Name';
            ToolTip = 'Specifies the name of the vendor who you received the invoice from.';
        }
        field(6; "Pay-to Name 2"; Text[50])
        {
            Caption = 'Pay-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the vendor who you receive the invoice or credit memo from.';
        }
        field(7; "Pay-to Address"; Text[100])
        {
            Caption = 'Pay-to Address';
            ToolTip = 'Specifies the address of the vendor that you received the invoice from.';
        }
        field(8; "Pay-to Address 2"; Text[50])
        {
            Caption = 'Pay-to Address 2';
            ToolTip = 'Specifies an additional part of the address of the vendor that the invoice was received from.';
        }
        field(9; "Pay-to City"; Text[30])
        {
            Caption = 'Pay-to City';
            ToolTip = 'Specifies the city of the vendor that you received the invoice from.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(10; "Pay-to Contact"; Text[100])
        {
            Caption = 'Pay-to Contact';
            ToolTip = 'Specifies the name of the person to contact about an invoice from this vendor.';
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
        }
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
        }
        field(14; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer at the address that the items are shipped to.';
        }
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            ToolTip = 'Specifies the address that the items are shipped to.';
        }
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
        }
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            ToolTip = 'Specifies the city of the address that the items are shipped to.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
            ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
        }
        field(19; "Order Date"; Date)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Order Date';
            ToolTip = 'Specifies the date when the order was created.';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the entry''s posting date.';
        }
        field(21; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            ToolTip = 'Specifies the date on which the invoiced items were expected.';
        }
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
            TableRelation = "Payment Terms";
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies when the related purchase invoice must be paid.';
        }
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            ToolTip = 'Specifies the payment discount percent granted if payment is made on or before the date in the Pmt. Discount Date field.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
        }
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
            TableRelation = "Shipment Method";
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location where the items are to be placed when they are received. This field acts as the default location for new lines. Location code for individual lines can differ from it.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(31; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency that is used on the entry.';
            TableRelation = Currency;
        }
        field(33; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
            ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
        }
        field(37; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(42; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(43; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            ToolTip = 'Specifies which purchaser is assigned to the vendor.';
            TableRelation = "Salesperson/Purchaser";
        }
        field(45; "Order Class"; Code[10])
        {
            Caption = 'Order Class';
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Purch. Comment Line Archive" where("Document Type" = field("Document Type"),
                                                                     "No." = field("No."),
                                                                     "Document Line No." = const(0),
                                                                     "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                     "Version No." = field("Version No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
            ToolTip = 'Specifies that the related entry represents an unpaid invoice for which either a payment suggestion, a reminder, or a finance charge memo exists.';
        }
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
            ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
        }
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
        }
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        field(57; Receive; Boolean)
        {
            Caption = 'Receive';
        }
        field(58; Invoice; Boolean)
        {
            Caption = 'Invoice';
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line Archive".Amount where("Document Type" = field("Document Type"),
                                                                    "Document No." = field("No."),
                                                                    "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                    "Version No." = field("Version No.")));
            Caption = 'Amount';
            ToolTip = 'Specifies the total amount for the archived purchase document.';
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Purchase Line Archive"."Amount Including VAT" where("Document Type" = field("Document Type"),
                                                                                    "Document No." = field("No."),
                                                                                    "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                                    "Version No." = field("Version No.")));
            Caption = 'Amount Including VAT';
            ToolTip = 'Specifies the total amount including VAT for the archived purchase document.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Receiving No."; Code[20])
        {
            Caption = 'Receiving No.';
        }
        field(63; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
        }
        field(64; "Last Receiving No."; Code[20])
        {
            Caption = 'Last Receiving No.';
            TableRelation = "Purch. Rcpt. Header";
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            TableRelation = "Purch. Inv. Header";
        }
        field(66; "Vendor Order No."; Code[35])
        {
            Caption = 'Vendor Order No.';
            ToolTip = 'Specifies the vendor''s order number.';
        }
        field(67; "Vendor Shipment No."; Code[35])
        {
            Caption = 'Vendor Shipment No.';
            ToolTip = 'Specifies the vendor''s shipment number. It is inserted in the corresponding field on the source document during posting.';
        }
        field(68; "Vendor Invoice No."; Code[35])
        {
            Caption = 'Vendor Invoice No.';
            ToolTip = 'Specifies the document number of the original document you received from the vendor. You can require the document number for posting, or let it be optional. By default, it''s required, so that this document references the original. Making document numbers optional removes a step from the posting process. For example, if you attach the original invoice as a PDF, you might not need to enter the document number. To specify whether document numbers are required, in the Purchases & Payables Setup window, select or clear the Ext. Doc. No. Mandatory field.';
        }
        field(69; "Vendor Cr. Memo No."; Code[35])
        {
            Caption = 'Vendor Cr. Memo No.';
            ToolTip = 'Specifies the number that the vendor uses for the credit memo you are creating in this purchase return order.';
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(72; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            ToolTip = 'Specifies the number of the customer.';
            TableRelation = Customer;
        }
        field(73; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(76; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
            TableRelation = "Transaction Type";
        }
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
            TableRelation = "Transport Method";
        }
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(79; "Buy-from Vendor Name"; Text[100])
        {
            Caption = 'Buy-from Vendor Name';
            ToolTip = 'Specifies the name of the vendor who delivered the items.';
        }
        field(80; "Buy-from Vendor Name 2"; Text[50])
        {
            Caption = 'Buy-from Vendor Name 2';
            ToolTip = 'Specifies an additional part of the name of the vendor that you’re buying from.';
        }
        field(81; "Buy-from Address"; Text[100])
        {
            Caption = 'Buy-from Address';
            ToolTip = 'Specifies the address of the vendor who delivered the items.';
        }
        field(82; "Buy-from Address 2"; Text[50])
        {
            Caption = 'Buy-from Address 2';
            ToolTip = 'Specifies an additional part of the address of the vendor who delivered the items.';
        }
        field(83; "Buy-from City"; Text[30])
        {
            Caption = 'Buy-from City';
            ToolTip = 'Specifies the city of the vendor who delivered the items.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(84; "Buy-from Contact"; Text[100])
        {
            Caption = 'Buy-from Contact';
            ToolTip = 'Specifies the name of the contact person at the vendor who delivered the items.';
        }
        field(85; "Pay-to Post Code"; Code[20])
        {
            Caption = 'Pay-to Post Code';
            ToolTip = 'Specifies the post code of the vendor that you received the invoice from.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(86; "Pay-to County"; Text[30])
        {
            CaptionClass = '5,6,' + "Pay-to Country/Region Code";
            Caption = 'Pay-to County';
            ToolTip = 'Specifies the county of the vendor on the purchase document.';
        }
        field(87; "Pay-to Country/Region Code"; Code[10])
        {
            Caption = 'Pay-to Country/Region Code';
            ToolTip = 'Specifies the country/region code of the address.';
            TableRelation = "Country/Region";
        }
        field(88; "Buy-from Post Code"; Code[20])
        {
            Caption = 'Buy-from Post Code';
            ToolTip = 'Specifies the post code of the vendor who delivered the items.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(89; "Buy-from County"; Text[30])
        {
            CaptionClass = '5,5,' + "Buy-from Country/Region Code";
            Caption = 'Buy-from County';
            ToolTip = 'Specifies the county of your vendor.';
        }
        field(90; "Buy-from Country/Region Code"; Code[10])
        {
            Caption = 'Buy-from Country/Region Code';
            ToolTip = 'Specifies the city of the vendor who delivered the items.';
            TableRelation = "Country/Region";
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
            ToolTip = 'Specifies the county of the ship-to address.';
        }
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
            TableRelation = "Country/Region";
        }
        field(94; "Bal. Account Type"; enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(95; "Order Address Code"; Code[10])
        {
            Caption = 'Order Address Code';
            ToolTip = 'Specifies the order address of the related vendor.';
            TableRelation = "Order Address".Code where("Vendor No." = field("Buy-from Vendor No."));
        }
        field(97; "Entry Point"; Code[10])
        {
            Caption = 'Entry Point';
            ToolTip = 'Specifies the code of the port of entry where the items pass into your country/region, for reporting to Intrastat.';
            TableRelation = "Entry/Exit Point";
        }
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date when the related document was created.';
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            ToolTip = 'Specifies the destination country or region for the purpose of Intrastat reporting.';
            TableRelation = Area;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
            TableRelation = "Transaction Specification";
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
            TableRelation = "Payment Method";
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(108; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(109; "Receiving No. Series"; Code[20])
        {
            Caption = 'Receiving No. Series';
            TableRelation = "No. Series";
        }
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
            TableRelation = "Tax Area";
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if this vendor charges you sales tax for purchases.';
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Business Posting Group";
        }
        field(118; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
            ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
        }
        field(119; "VAT Base Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(120; Status; Enum "Purchase Document Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies whether the record is open, waiting to be approved, invoiced for prepayment, or released to the next stage of processing.';
        }
        field(121; "Invoice Discount Calculation"; Option)
        {
            Caption = 'Invoice Discount Calculation';
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        field(122; "Invoice Discount Value"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Invoice Discount Value';
        }
        field(123; "Send IC Document"; Boolean)
        {
            Caption = 'Send IC Document';
        }
        field(124; "IC Status"; Enum "Purchase Document IC Status")
        {
            Caption = 'IC Status';
        }
        field(125; "Buy-from IC Partner Code"; Code[20])
        {
            Caption = 'Buy-from IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(126; "Pay-to IC Partner Code"; Code[20])
        {
            Caption = 'Pay-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(127; "IC Reference Document No."; Code[20])
        {
            Caption = 'IC Reference Document No.';
            Editable = false;
        }
        field(129; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';
        }
        field(130; "Prepayment No."; Code[20])
        {
            Caption = 'Prepayment No.';
        }
        field(131; "Last Prepayment No."; Code[20])
        {
            Caption = 'Last Prepayment No.';
            TableRelation = "Sales Invoice Header";
        }
        field(132; "Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No.';
        }
        field(133; "Last Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Last Prepmt. Cr. Memo No.';
            TableRelation = "Sales Invoice Header";
        }
        field(134; "Prepayment %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(135; "Prepayment No. Series"; Code[20])
        {
            Caption = 'Prepayment No. Series';
            TableRelation = "No. Series";
        }
        field(136; "Compress Prepayment"; Boolean)
        {
            Caption = 'Compress Prepayment';
            InitValue = true;
        }
        field(137; "Prepayment Due Date"; Date)
        {
            Caption = 'Prepayment Due Date';
        }
        field(138; "Prepmt. Cr. Memo No. Series"; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";
        }
        field(139; "Prepmt. Posting Description"; Text[100])
        {
            Caption = 'Prepmt. Posting Description';
        }
        field(142; "Prepmt. Pmt. Discount Date"; Date)
        {
            Caption = 'Prepmt. Pmt. Discount Date';
        }
        field(143; "Prepmt. Payment Terms Code"; Code[10])
        {
            Caption = 'Prepmt. Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(144; "Prepmt. Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepmt. Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(145; "No. of Archived Versions"; Integer)
        {
            CalcFormula = max("Purchase Header Archive"."Version No." where("Document Type" = field("Document Type"),
                                                                             "No." = field("No."),
                                                                             "Doc. No. Occurrence" = field("Doc. No. Occurrence")));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(151; "Purchase Quote No."; Code[20])
        {
            Caption = 'Purchase Quote No.';
            Editable = false;
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Quote),
                                                           "No." = field("Purchase Quote No."));
            ValidateTableRelation = false;
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";
        }
        field(179; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            ToolTip = 'Specifies the entry''s VAT date.';
        }
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ToolTip = 'Specifies the telephone number of the company''s shipping address.';
            ExtendedDatatype = PhoneNo;
        }
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
        field(3998; "Source Doc. Exists"; Boolean)
        {
            FieldClass = Flowfield;
            CalcFormula = exist("Purchase Header" where("Document Type" = field("Document Type"),
                                                            "No." = field("No.")));
            Caption = 'Source Doc. Exists';
            Editable = false;
        }
        field(3999; "Last Archived Date"; DateTime)
        {
            Caption = 'Last Archived Date';
            FieldClass = FlowField;
            CalcFormula = max("Purchase Header Archive".SystemCreatedAt where("Document Type" = field("Document Type"),
                                                            "No." = field("No."),
                                                            "Doc. No. Occurrence" = field("Doc. No. Occurrence")));
            Editable = false;
        }
        field(5043; "Interaction Exist"; Boolean)
        {
            Caption = 'Interaction Exist';
            ToolTip = 'Specifies that the archived document is linked to an interaction log entry.';
        }
        field(5044; "Time Archived"; Time)
        {
            Caption = 'Time Archived';
            ToolTip = 'Specifies what time the document was archived.';
        }
        field(5045; "Date Archived"; Date)
        {
            Caption = 'Date Archived';
            ToolTip = 'Specifies the date when the document was archived.';
        }
        field(5046; "Archived By"; Code[50])
        {
            Caption = 'Archived By';
            ToolTip = 'Specifies the user ID of the person who archived this document.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
            ToolTip = 'Specifies the version number of the archived document.';
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(5052; "Buy-from Contact No."; Code[20])
        {
            Caption = 'Buy-from Contact No.';
            ToolTip = 'Specifies the number of the contact person at the vendor who delivered the items.';
            TableRelation = Contact;
        }
        field(5053; "Pay-to Contact No."; Code[20])
        {
            Caption = 'Pay-to Contact No.';
            ToolTip = 'Specifies the number of the person to contact about an invoice from this vendor.';
            TableRelation = Contact;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
            TableRelation = "Responsibility Center";
        }
        field(5752; "Completely Received"; Boolean)
        {
            CalcFormula = min("Purchase Line Archive"."Completely Received" where("Document Type" = field("Document Type"),
                                                                                   "Document No." = field("No."),
                                                                                   "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                                   "Version No." = field("Version No."),
                                                                                   "Expected Receipt Date" = field("Date Filter"),
                                                                                   "Location Code" = field("Location Filter")));
            Caption = 'Completely Received';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5753; "Posting from Whse. Ref."; Integer)
        {
            Caption = 'Posting from Whse. Ref.';
        }
        field(5754; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
            ToolTip = 'Specifies the date you want the vendor to deliver your order.';
        }
        field(5791; "Promised Receipt Date"; Date)
        {
            Caption = 'Promised Receipt Date';
            ToolTip = 'Specifies the date that the vendor has promised to deliver the order.';
        }
        field(5792; "Lead Time Calculation"; DateFormula)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lead Time Calculation';
            ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
        }
        field(5793; "Inbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Inbound Whse. Handling Time';
            ToolTip = 'Specifies the time it takes to make items part of available inventory, after the items have been posted as received.';
        }
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5800; "Vendor Authorization No."; Code[35])
        {
            Caption = 'Vendor Authorization No.';
            ToolTip = 'Specifies information about sales quotes, purchase quotes, or orders in earlier versions of the document.';
        }
        field(5801; "Return Shipment No."; Code[20])
        {
            Caption = 'Return Shipment No.';
        }
        field(5802; "Return Shipment No. Series"; Code[20])
        {
            Caption = 'Return Shipment No. Series';
            TableRelation = "No. Series";
        }
        field(5803; Ship; Boolean)
        {
            Caption = 'Ship';
        }
        field(5804; "Last Return Shipment No."; Code[20])
        {
            Caption = 'Last Return Shipment No.';
            TableRelation = "Return Shipment Header";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            ToolTip = 'Specifies the ID of the user who is responsible for the document.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.", "Doc. No. Occurrence", "Version No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Buy-from Vendor No.")
        {
        }
        key(Key3; "Document Type", "Pay-to Vendor No.")
        {
        }
        key(Key4; "Incoming Document Entry No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Version No.", "Buy-from Vendor No.")
        {
        }
    }

    trigger OnDelete()
    var
        PurchaseLineArchive: Record "Purchase Line Archive";
        PurchCommentLineArchive: Record "Purch. Comment Line Archive";
        DeferralHeaderArchive: Record "Deferral Header Archive";
    begin
        PurchaseLineArchive.SetRange("Document Type", "Document Type");
        PurchaseLineArchive.SetRange("Document No.", "No.");
        PurchaseLineArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        PurchaseLineArchive.SetRange("Version No.", "Version No.");
        PurchaseLineArchive.DeleteAll();

        PurchCommentLineArchive.SetRange("Document Type", "Document Type");
        PurchCommentLineArchive.SetRange("No.", "No.");
        PurchCommentLineArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        PurchCommentLineArchive.SetRange("Version No.", "Version No.");
        PurchCommentLineArchive.DeleteAll();

        DeferralHeaderArchive.SetRange("Deferral Doc. Type", "Deferral Document Type"::Purchase);
        DeferralHeaderArchive.SetRange("Document Type", "Document Type");
        DeferralHeaderArchive.SetRange("Document No.", "No.");
        DeferralHeaderArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        DeferralHeaderArchive.SetRange("Version No.", "Version No.");
        DeferralHeaderArchive.DeleteAll(true);
    end;

    var
        DimensionManagement: Codeunit DimensionManagement;
        UserSetupManagement: Codeunit "User Setup Management";

    procedure ShowDimensions()
    begin
        DimensionManagement.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."));
    end;

    procedure SetSecurityFilterOnRespCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupManagement.GetPurchasesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupManagement.GetPurchasesFilter());
            FilterGroup(0);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var PurchaseHeaderArchive: Record "Purchase Header Archive"; var IsHandled: Boolean)
    begin
    end;
}

