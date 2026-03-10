// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

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
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Automation;
using System.Globalization;
using System.Security.AccessControl;
using System.Security.User;

table 122 "Purch. Inv. Header"
{
    Caption = 'Purch. Inv. Header';
    DataCaptionFields = "No.", "Buy-from Vendor Name";
    DrillDownPageID = "Posted Purchase Invoices";
    LookupPageID = "Posted Purchase Invoices";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            NotBlank = true;
            ToolTip = 'Specifies the identifier of the vendor that you bought the items from.';
            TableRelation = Vendor;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the posted invoice number.';
        }
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;
            ToolTip = 'Specifies the number of the vendor that you received the invoice from.';
        }
        field(5; "Pay-to Name"; Text[100])
        {
            Caption = 'Pay-to Name';
            ToolTip = 'Specifies the name of the vendor who you received the invoice from.';
        }
        field(6; "Pay-to Name 2"; Text[50])
        {
            Caption = 'Pay-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the vendor who you receive the invoice from.';
        }
        field(7; "Pay-to Address"; Text[100])
        {
            Caption = 'Pay-to Address';
            ToolTip = 'Specifies the address of the vendor that you received the invoice from.';
        }
        field(8; "Pay-to Address 2"; Text[50])
        {
            Caption = 'Pay-to Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        field(9; "Pay-to City"; Text[30])
        {
            Caption = 'Pay-to City';
            ToolTip = 'Specifies the city of the vendor on the purchase document.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(10; "Pay-to Contact"; Text[100])
        {
            Caption = 'Pay-to Contact';
            ToolTip = 'Specifies the name of the person you should contact at the vendor who you received the invoice from.';
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies the address on purchase orders shipped with a drop shipment directly from the vendor to a customer.';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));
        }
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
        }
        field(14; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the company at the address to which the items in the purchase order were shipped.';
        }
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            ToolTip = 'Specifies the address that the items in the purchase order were shipped to.';
        }
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            ToolTip = 'Specifies the city of the vendor on the purchase document.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
            ToolTip = 'Specifies the name of a contact person at the address that the items in the purchase order were shipped to.';
        }
        field(19; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date the purchase header was posted.';
        }
        field(21; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            ToolTip = 'Specifies the date on which the invoiced items were expected.';
        }
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            ToolTip = 'Specifies the code to use to find the payment terms that apply to the purchase header.';
            TableRelation = "Payment Terms";
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies when the invoice is due. The program calculates the date using the Payment Terms Code and Document Date fields on the purchase header.';
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
            ToolTip = 'Specifies the code for the location where the items are registered.';
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
            ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
            Editable = false;
            TableRelation = "Vendor Posting Group";
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code used to calculate the amounts on the invoice.';
            Editable = false;
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
        field(44; "Order No."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Order No.';
            ToolTip = 'Specifies the number of the purchase order that this invoice was posted from.';
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Purch. Comment Line" where("Document Type" = const("Posted Invoice"),
                                                             "No." = field("No."),
                                                             "Document Line No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            ToolTip = 'Specifies how many times the document has been printed.';
            Editable = false;
        }
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                VendLedgEntry: Record "Vendor Ledger Entry";
            begin
                VendLedgEntry.SetCurrentKey("Document No.");
                VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                VendLedgEntry.SetRange("Bill No.", "Applies-to Bill No.");
                OnLookupAppliesToDocNoOnAfterSetFilters(VendLedgEntry, Rec);
                PAGE.Run(0, VendLedgEntry);
            end;
        }
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Purch. Inv. Line".Amount where("Document No." = field("No.")));
            Caption = 'Amount';
            ToolTip = 'Specifies the total, in the currency of the invoice, of the amounts on all the invoice lines.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Purch. Inv. Line"."Amount Including VAT" where("Document No." = field("No.")));
            Caption = 'Amount Including VAT';
            ToolTip = 'Specifies the total of the amounts, including VAT, on all the lines on the document.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(66; "Vendor Order No."; Code[35])
        {
            Caption = 'Vendor Order No.';
            ToolTip = 'Specifies the vendor''s order number.';
        }
        field(68; "Vendor Invoice No."; Code[35])
        {
            Caption = 'Vendor Invoice No.';
            ToolTip = 'Specifies the vendor''s own invoice number.';
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(72; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
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
            TableRelation = "Transaction Type";
        }
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
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
            ToolTip = 'Specifies the name of the vendor who shipped the items.';
        }
        field(80; "Buy-from Vendor Name 2"; Text[50])
        {
            Caption = 'Buy-from Vendor Name 2';
            ToolTip = 'Specifies an additional part of the name of the vendor that you’re buying from.';
        }
        field(81; "Buy-from Address"; Text[100])
        {
            Caption = 'Buy-from Address';
            ToolTip = 'Specifies the address of the vendor who shipped the items.';
        }
        field(82; "Buy-from Address 2"; Text[50])
        {
            Caption = 'Buy-from Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        field(83; "Buy-from City"; Text[30])
        {
            Caption = 'Buy-from City';
            ToolTip = 'Specifies the city of the vendor on the purchase document.';
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
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
        field(87; "Pay-to Country/Region Code"; Code[10])
        {
            Caption = 'Pay-to Country/Region Code';
            ToolTip = 'Specifies the country or region of the ship-to address.';
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
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
        field(90; "Buy-from Country/Region Code"; Code[10])
        {
            Caption = 'Buy-from Country/Region Code';
            ToolTip = 'Specifies the country or region of the ship-to address.';
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
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            ToolTip = 'Specifies the country or region of the ship-to address.';
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
            TableRelation = "Entry/Exit Point";
        }
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date on which the purchase document was created.';
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
            TableRelation = "Payment Method";
        }
        field(107; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            TableRelation = "No. Series";
        }
        field(108; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(110; "Order No. Series"; Code[20])
        {
            Caption = 'Order No. Series';
            TableRelation = "No. Series";
        }
        field(111; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
            ToolTip = 'Specifies the number of the purchase document that the posted invoice was created for.';
        }
        field(112; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(113; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
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
            ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(119; "VAT Base Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(135; "Prepayment No. Series"; Code[20])
        {
            Caption = 'Prepayment No. Series';
            TableRelation = "No. Series";
        }
        field(140; "Prepayment Invoice"; Boolean)
        {
            Caption = 'Prepayment Invoice';
        }
        field(141; "Prepayment Order No."; Code[20])
        {
            Caption = 'Prepayment Order No.';
        }
        field(151; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
            ToolTip = 'Specifies the number of the purchase quote document if a quote was used to start the purchase process.';
            Editable = false;
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
            ToolTip = 'Specifies the number of the vendor.';
        }
        field(171; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
            ToolTip = 'Specifies the payment of the purchase invoice.';
        }
        field(179; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            ToolTip = 'Specifies the VAT date on the invoice.';
            Editable = false;
        }
        field(180; "Self-Billing Invoice"; Boolean)
        {
            Caption = 'Self-Billing Invoice';
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
        field(1000; "Remit-to Code"; Code[20])
        {
            Caption = 'Remit-to Code';
            ToolTip = 'Specifies the code for the vendor''s remit address for this invoice.';
            Editable = false;
            TableRelation = "Remit Address".Code where("Vendor No." = field("Buy-from Vendor No."));
        }
        field(1302; Closed; Boolean)
        {
            CalcFormula = - exist("Vendor Ledger Entry" where("Entry No." = field("Vendor Ledger Entry No."),
                                                              Open = filter(true)));
            Caption = 'Closed';
            ToolTip = 'Specifies if the posted purchase invoice is paid. The check box will also be selected if a credit memo for the remaining amount has been applied.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1303; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Vendor Ledger Entry No." = field("Vendor Ledger Entry No.")));
            Caption = 'Remaining Amount';
            ToolTip = 'Specifies the remaining amount of the invoice.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1304; "Vendor Ledger Entry No."; Integer)
        {
            Caption = 'Vendor Ledger Entry No.';
            Editable = false;
            TableRelation = "Vendor Ledger Entry"."Entry No.";
        }
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            CalcFormula = sum("Purch. Inv. Line"."Inv. Discount Amount" where("Document No." = field("No.")));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1310; Cancelled; Boolean)
        {
            CalcFormula = exist("Cancelled Document" where("Source ID" = const(122),
                                                            "Cancelled Doc. No." = field("No.")));
            Caption = 'Cancelled';
            ToolTip = 'Specifies if the posted purchase invoice has been either corrected or canceled.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1311; Corrective; Boolean)
        {
            CalcFormula = exist("Cancelled Document" where("Source ID" = const(124),
                                                            "Cancelled By Doc. No." = field("No.")));
            Caption = 'Corrective';
            ToolTip = 'Specifies if the posted purchase invoice is a corrective document.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(5052; "Buy-from Contact No."; Code[20])
        {
            Caption = 'Buy-from Contact No.';
            ToolTip = 'Specifies the number of the contact you bought the items from.';
            TableRelation = Contact;
        }
        field(5053; "Pay-to Contact No."; Code[20])
        {
            Caption = 'Pay-to Contact No.';
            ToolTip = 'Specifies the number of the contact you received the invoice from.';
            TableRelation = Contact;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            ToolTip = 'Specifies the code for the responsibility center that serves the vendor on this purchase document.';
            TableRelation = "Responsibility Center";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(8001; "Draft Invoice SystemId"; Guid)
        {
            Caption = 'Draft Invoice SystemId';
            DataClassification = SystemMetadata;
        }
        field(10700; "Autoinvoice No."; Code[20])
        {
            Caption = 'Autoinvoice No.';
            Editable = false;
        }
        field(10706; "SII Status"; Enum "SII Document Status")
        {
            CalcFormula = lookup("SII Doc. Upload State".Status where("Document Source" = const("Vendor Ledger"),
                                                                       "Document Type" = const(Invoice),
                                                                       "Document No." = field("No.")));
            Caption = 'SII Status';
            FieldClass = FlowField;

            trigger OnLookup()
            var
                SIIDocUploadState: Record "SII Doc. Upload State";
                SIIHistory: Record "SII History";
            begin
                SIIDocUploadState.SetRange("Document Source", SIIDocUploadState."Document Source"::"Vendor Ledger");
                SIIDocUploadState.SetRange("Document Type", SIIDocUploadState."Document Type"::Invoice);
                SIIDocUploadState.SetRange("Document No.", "No.");
                if SIIDocUploadState.FindFirst() then begin
                    SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
                    PAGE.Run(PAGE::"SII History", SIIHistory);
                end;
            end;
        }
        field(10707; "Invoice Type"; Enum "SII Purch. Invoice Type")
        {
            Caption = 'Invoice Type';
        }
        field(10708; "Cr. Memo Type"; Enum "SII Purch. Credit Memo Type")
        {
            Caption = 'Cr. Memo Type';
        }
        field(10709; "Special Scheme Code"; Enum "SII Purch. Special Scheme Code")
        {
            Caption = 'Special Scheme Code';
        }
        field(10710; "Operation Description"; Text[250])
        {
            Caption = 'Operation Description';
        }
        field(10712; "Operation Description 2"; Text[250])
        {
            Caption = 'Operation Description 2';
        }
        field(10720; "Succeeded Company Name"; Text[250])
        {
            Caption = 'Succeeded Company Name';
        }
        field(10721; "Succeeded VAT Registration No."; Text[20])
        {
            Caption = 'Succeeded VAT Registration No.';
        }
        field(10722; "ID Type"; Enum "SII ID Type")
        {
            Caption = 'ID Type';
        }
        field(10723; "Sent to SII"; Boolean)
        {
            CalcFormula = exist("SII Doc. Upload State" where("Document Source" = const("Vendor Ledger"),
                                                               "Document Type" = const(Invoice),
                                                               "Document No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(10724; "Do Not Send To SII"; Boolean)
        {
            Caption = 'Do Not Send To SII';
        }
        field(7000000; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
        }
        field(7000001; "Vendor Bank Acc. Code"; Code[20])
        {
            Caption = 'Vendor Bank Acc. Code';
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Pay-to Vendor No."));
        }
#if not CLEANSCHEMA25
        field(7000003; "Pay-at Code"; Code[10])
        {
            Caption = 'Pay-at Code';
            TableRelation = "Vendor Pmt. Address".Code where("Vendor No." = field("Pay-to Vendor No."));
            ObsoleteReason = 'Address is taken from the fields Pay-to Address, Pay-to City, etc.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
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
        key(Key4; "Vendor Invoice No.", "Posting Date")
        {
        }
        key(Key5; "Buy-from Vendor No.")
        {
        }
        key(Key6; "Prepayment Order No.", "Prepayment Invoice")
        {
        }
        key(Key7; "Pay-to Vendor No.")
        {
        }
        key(Key8; "Posting Date")
        {
        }
        key(Key9; "Due Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Buy-from Vendor No.", "Pay-to Vendor No.", "Posting Date", "Posting Description")
        {
        }
        fieldgroup(Brick; "No.", "Buy-from Vendor Name", Amount, "Due Date", "Amount Including VAT")
        {
        }
    }

    trigger OnDelete()
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostPurchDelete: Codeunit "PostPurch-Delete";
    begin
        PostPurchDelete.IsDocumentDeletionAllowed("Posting Date");
        LockTable();
        PostPurchDelete.DeletePurchInvLines(Rec);

        PurchCommentLine.SetRange("Document Type", PurchCommentLine."Document Type"::"Posted Invoice");
        PurchCommentLine.SetRange("No.", "No.");
        PurchCommentLine.DeleteAll();

        ApprovalsMgmt.DeletePostedApprovalEntries(RecordId);
        PostedDeferralHeader.DeleteForDoc(
            "Deferral Document Type"::Purchase.AsInteger(), '', '',
            PurchCommentLine."Document Type"::"Posted Invoice".AsInteger(), "No.");
    end;

    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCommentLine: Record "Purch. Comment Line";
        DimMgt: Codeunit DimensionManagement;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        UserSetupMgt: Codeunit "User Setup Management";
        CorrInvDoesNotExistErr: Label 'The Corrected Invoice No. does not exist. \Identification fields and values:\Corrected Invoice No. = %1.', Comment = '%1 = number of document';

    [Scope('OnPrem')]
    procedure PrintRecordsAutoInv(ShowRequestForm: Boolean)
    var
        ReportSelection: Record "Report Selections";
    begin
        PurchInvHeader.Copy(Rec);
        ReportSelection.SetRange(Usage, ReportSelection.Usage::"P.AutoInvoice");
        ReportSelection.SetFilter("Report ID", '<>0');
        ReportSelection.Find('-');
        repeat
            REPORT.RunModal(ReportSelection."Report ID", ShowRequestForm, false, PurchInvHeader);
        until ReportSelection.Next() = 0;
    end;

    procedure IsFullyOpen(): Boolean
    var
        FullyOpen: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforCheckIfPurchaseInvoiceFullyOpen(Rec, FullyOpen, IsHandled);
        if IsHandled then
            exit(FullyOpen);

        CalcFields("Amount Including VAT", "Remaining Amount");
        exit("Amount Including VAT" = "Remaining Amount");
    end;

    procedure PrintRecords(ShowRequestPage: Boolean)
    var
        ReportSelection: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, ShowRequestPage, IsHandled);
        if not IsHandled then begin
            PurchInvHeader.Copy(Rec);
            if PurchInvHeader."Self-Billing Invoice" then
                ReportSelection.PrintWithDialogForVend(
                  ReportSelection.Usage::"P.Self Billing Invoice", PurchInvHeader, ShowRequestPage, PurchInvHeader.FieldNo("Buy-from Vendor No."))
            else
                ReportSelection.PrintWithDialogForVend(
                  ReportSelection.Usage::"P.Invoice", PurchInvHeader, ShowRequestPage, PurchInvHeader.FieldNo("Buy-from Vendor No."));
        end;
    end;

    procedure PrintToDocumentAttachment(var PurchInvHeaderLocal: Record "Purch. Inv. Header")
    begin
        if PurchInvHeaderLocal.FindSet() then
            repeat
                DoPrintToDocumentAttachment(PurchInvHeaderLocal);
            until PurchInvHeaderLocal.Next() = 0;
    end;

    local procedure DoPrintToDocumentAttachment(PurchInvHeaderLocal: Record "Purch. Inv. Header")
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDoPrintToDocumentAttachment(PurchInvHeaderLocal, IsHandled);
        if IsHandled then
            exit;

        PurchInvHeaderLocal.SetRecFilter();
        if PurchInvHeaderLocal."Self-Billing Invoice" then
            ReportSelections.SaveAsDocumentAttachment(
                ReportSelections.Usage::"P.Self Billing Invoice".AsInteger(), PurchInvHeaderLocal, PurchInvHeaderLocal."No.", PurchInvHeaderLocal."Buy-from Vendor No.", true)
        else
            ReportSelections.SaveAsDocumentAttachment(
                ReportSelections.Usage::"P.Invoice".AsInteger(), PurchInvHeaderLocal, PurchInvHeaderLocal."No.", PurchInvHeaderLocal."Buy-from Vendor No.", true);
    end;

    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;

    procedure SetSecurityFilterOnRespCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupMgt.GetPurchasesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetPurchasesFilter());
            FilterGroup(0);
        end;
    end;

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

    procedure ShowCorrectiveCreditMemo()
    var
        CancelledDocument: Record "Cancelled Document";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        CalcFields(Cancelled);
        if not Cancelled then
            exit;

        if CancelledDocument.FindPurchCancelledInvoice("No.") then begin
            PurchCrMemoHdr.Get(CancelledDocument."Cancelled By Doc. No.");
            PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHdr);
        end;
    end;

    procedure ShowCancelledCreditMemo()
    var
        CancelledDocument: Record "Cancelled Document";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        CalcFields(Corrective);
        if not Corrective then
            exit;

        if CancelledDocument.FindPurchCorrectiveInvoice("No.") then begin
            PurchCrMemoHdr.Get(CancelledDocument."Cancelled Doc. No.");
            PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHdr);
        end;
    end;

    [Scope('OnPrem')]
    procedure LookupInvoice(VendNo: Code[20]) Selected: Boolean
    var
        PostedPurchaseInvoices: Page "Posted Purchase Invoices";
    begin
        SetCurrentKey("No.");
        SetRange("Pay-to Vendor No.", VendNo);

        PostedPurchaseInvoices.SetTableView(Rec);
        PostedPurchaseInvoices.SetRecord(Rec);
        PostedPurchaseInvoices.LookupMode(true);
        if PostedPurchaseInvoices.RunModal() = ACTION::LookupOK then begin
            PostedPurchaseInvoices.GetRecord(Rec);
            Selected := true;
        end;
        Clear(PostedPurchaseInvoices);
        exit(Selected);
    end;

    [Scope('OnPrem')]
    procedure CheckCorrectedDocumentExist(VendNo: Code[20]; CorrInvNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCorrectedDocumentExist(VendNo, CorrInvNo, IsHandled);
        if IsHandled then
            exit;

        SetRange("Pay-to Vendor No.", VendNo);
        SetRange("No.", CorrInvNo);
        if not FindFirst() then
            Error(CorrInvDoesNotExistErr, CorrInvNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCorrectedDocumentExist(VendNo: Code[20]; CorrInvNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var PurchInvHeader: Record "Purch. Inv. Header"; ShowRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCanceledOrCorrCrMemo(var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoPrintToDocumentAttachment(var PurchInvHeaderLocal: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var VendLedgEntry: Record "Vendor Ledger Entry"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforCheckIfPurchaseInvoiceFullyOpen(var PurchInvHeader: Record "Purch. Inv. Header"; var FullyOpen: Boolean; var IsHandled: Boolean)
    begin
    end;
}
