// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Payment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
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
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Setup;
using System.Globalization;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

table 6010 "Service Header Archive"
{
    Caption = 'Service Header Archive';
    DataCaptionFields = "No.", Name, Description, "Version No.";
    DataClassification = CustomerContent;
    DrillDownPageId = "Service List Archive";
    LookupPageId = "Service List Archive";

    fields
    {
        field(1; "Document Type"; Enum "Service Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the number of the customer who owns the items in the service document.';
            TableRelation = Customer."No.";
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
        }
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer that you send or sent the invoice or credit memo to.';
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            ToolTip = 'Specifies the address of the customer to whom you will send the invoice.';
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            ToolTip = 'Specifies an additional line of the address.';
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            ToolTip = 'Specifies the city of the address.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
            ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            ToolTip = 'Specifies a customer reference, which will be used when printing service documents.';
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
        }
        field(14; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer that the items are shipped to.';
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
            Caption = 'Order Date';
            ToolTip = 'Specifies the date when the order was created.';
            NotBlank = true;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the entry''s posting date.';
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
            ToolTip = 'Specifies when the invoice is due.';
        }
        field(25; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            ToolTip = 'Specifies the percentage of payment discount given, if the customer pays by the date entered in the Pmt. Discount Date field.';
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
            ToolTip = 'Specifies the code of the location (for example, warehouse or distribution center) of the items specified on the service item lines.';
            TableRelation = Location;
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
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code for various amounts on the service lines.';
            TableRelation = Currency;
        }
        field(33; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
        }
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
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
        field(40; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
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
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            ToolTip = 'Specifies the code of the salesperson assigned to this service document.';
            TableRelation = "Salesperson/Purchaser";
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Service Comment Line Archive" where("Table Name" = const("Service Header"),
                                                                     "Table Subtype" = field("Document Type"),
                                                                     "No." = field("No."),
                                                                     "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                     "Version No." = field("Version No."),
                                                                      Type = const(General)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
        }
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        field(62; "Shipping No."; Code[20])
        {
            Caption = 'Shipping No.';
        }
        field(63; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
        }
        field(64; "Last Shipping No."; Code[20])
        {
            Caption = 'Last Shipping No.';
            Editable = false;
            TableRelation = "Service Shipment Header";
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            Editable = false;
            TableRelation = "Service Invoice Header";
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(71; "Combine Shipments"; Boolean)
        {
            Caption = 'Combine Shipments';
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
        field(75; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
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
        field(79; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the customer to whom the items on the document will be shipped.';
        }
        field(80; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(81; Address; Text[100])
        {
            Caption = 'Address';
            ToolTip = 'Specifies the address of the customer to whom the service will be shipped.';
        }
        field(82; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        field(83; City; Text[30])
        {
            Caption = 'City';
            ToolTip = 'Specifies the city of the address.';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(84; "Contact Name"; Text[100])
        {
            Caption = 'Contact Name';
            ToolTip = 'Specifies the name of the contact who will receive the service.';
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            ToolTip = 'Specifies the postal code of the customer''s billing address.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
            ToolTip = 'Specifies the county of the customer on the service document.';
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            ToolTip = 'Specifies the country/region code of the customer''s billing address.';
            TableRelation = "Country/Region";
        }
        field(88; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            ToolTip = 'Specifies the postal code.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(89; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
            ToolTip = 'Specifies the county of your customer.';
        }
        field(90; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            ToolTip = 'Specifies the country/region of the address.';
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
            ToolTip = 'Specifies the country or region of the ship-to address.';
            TableRelation = "Country/Region";
        }
        field(94; "Bal. Account Type"; Enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(97; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            ToolTip = 'Specifies the point of exit through which you ship the items out of your country/region, for reporting to Intrastat.';
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
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
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
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
            TableRelation = "Shipping Agent";
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(108; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(109; "Shipping No. Series"; Code[20])
        {
            Caption = 'Shipping No. Series';
            TableRelation = "No. Series";
        }
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
            TableRelation = "Tax Area";
            ValidateTableRelation = false;
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Business Posting Group";
        }
        field(117; Reserve; Enum "Reserve Method")
        {
            Caption = 'Reserve';
        }
        field(118; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(119; "VAT Base Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(120; Status; Enum "Service Document Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the service order status, which reflects the repair or maintenance status of all service items on the service order.';
        }
        field(121; "Invoice Discount Calculation"; Option)
        {
            Caption = 'Invoice Discount Calculation';
            Editable = false;
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        field(122; "Invoice Discount Value"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Invoice Discount Value';
            Editable = false;
        }
        field(129; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
        }
        field(130; "Release Status"; Enum "Service Doc. Release Status")
        {
            Caption = 'Release Status';
            ToolTip = 'Specifies if items in the Service Lines window are ready to be handled in warehouse activities.';
            Editable = false;
        }
        field(131; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            ToolTip = 'Specifies the date used to include entries on VAT reports in a VAT period. This is either the date that the document was created or posted, depending on your setting on the General Ledger Setup page.';
            Editable = false;
        }
#pragma warning disable AA0232
        field(145; "No. of Archived Versions"; Integer)
#pragma warning restore AA0232
        {
            CalcFormula = max("Service Header Archive"."Version No." where("Document Type" = field("Document Type"),
                                                                           "No." = field("No."),
                                                                           "Doc. No. Occurrence" = field("Doc. No. Occurrence")));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";
        }
        field(178; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));
        }
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
            DataClassification = CustomerContent;
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
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            ToolTip = 'Specifies the direct-debit mandate that the customer has signed to allow direct debit collection of payments.';
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Bill-to Customer No."));
            DataClassification = SystemMetadata;
        }
        field(3998; "Source Doc. Exists"; Boolean)
        {
            Caption = 'Source Doc. Exists';
            FieldClass = FlowField;
            CalcFormula = exist("Service Header" where("Document Type" = field("Document Type"),
                                                       "No." = field("No.")));
            Editable = false;
        }
        field(3999; "Last Archived Date"; DateTime)
        {
            Caption = 'Last Archived Date';
            FieldClass = FlowField;
            CalcFormula = max("Service Header Archive".SystemCreatedAt where("Document Type" = field("Document Type"),
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
        field(5052; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            ToolTip = 'Specifies the number of the contact to whom you will deliver the service.';
            TableRelation = Contact;
        }
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
            TableRelation = Contact;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
            TableRelation = "Responsibility Center";
        }
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
            ToolTip = 'Specifies information about whether the customer will accept a partial shipment of the order.';
        }
        field(5754; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location.Code;
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';
            ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
        }
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5902; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a short description of the service document, such as Order 2001.';
        }
        field(5904; "Service Order Type"; Code[10])
        {
            Caption = 'Service Order Type';
            ToolTip = 'Specifies the type of this service order.';
            TableRelation = "Service Order Type";
        }
        field(5905; "Link Service to Service Item"; Boolean)
        {
            Caption = 'Link Service to Service Item';
            ToolTip = 'Specifies that service lines for items and resources must be linked to a service item line.';
        }
        field(5907; Priority; Option)
        {
            Caption = 'Priority';
            ToolTip = 'Specifies the priority of the service order.';
            Editable = false;
            OptionCaption = 'Low,Medium,High';
            OptionMembers = Low,Medium,High;
        }
        field(5911; "Allocated Hours"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Service Order Allocat. Archive"."Allocated Hours" where("Document Type" = field("Document Type"),
                                                                                       "Document No." = field("No."),
                                                                                       "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                                       "Version No." = field("Version No."),
                                                                                       "Allocation Date" = field("Date Filter"),
                                                                                       "Resource No." = field("Resource Filter"),
                                                                                        Status = filter(Active | Finished),
                                                                                       "Resource Group No." = field("Resource Group Filter")));
            Caption = 'Allocated Hours';
            ToolTip = 'Specifies the number of hours allocated to the items in this service order.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5915; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ToolTip = 'Specifies the phone number of the customer in this service order.';
            ExtendedDatatype = PhoneNo;
        }
        field(5916; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ToolTip = 'Specifies the email address of the customer in this service order.';
            ExtendedDatatype = EMail;
        }
        field(5917; "Phone No. 2"; Text[30])
        {
            Caption = 'Phone No. 2';
            ToolTip = 'Specifies your customer''s alternate phone number.';
            ExtendedDatatype = PhoneNo;
        }
        field(5918; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(5921; "No. of Unallocated Items"; Integer)
        {
            Caption = 'No. of Unallocated Items';
            ToolTip = 'Specifies the number of service items in this order that are not allocated to resources.';
            Editable = false;
        }
        field(5923; "Order Time"; Time)
        {
            Caption = 'Order Time';
            ToolTip = 'Specifies the time when the service order was created.';
            NotBlank = true;
        }
        field(5924; "Default Response Time (Hours)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Default Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5925; "Actual Response Time (Hours)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Actual Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(5926; "Service Time (Hours)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Service Time (Hours)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5927; "Response Date"; Date)
        {
            Caption = 'Response Date';
            ToolTip = 'Specifies the estimated date when work on the order should start, that is, when the service order status changes from Pending, to In Process.';
            Editable = false;
        }
        field(5928; "Response Time"; Time)
        {
            Caption = 'Response Time';
            ToolTip = 'Specifies the estimated time when work on the order starts, that is, when the service order status changes from Pending, to In Process.';
            Editable = false;
        }
        field(5929; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the starting date of the service, that is, the date when the order status changes from Pending, to In Process for the first time.';
        }
        field(5930; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            ToolTip = 'Specifies the starting time of the service, that is, the time when the order status changes from Pending, to In Process for the first time.';
        }
        field(5931; "Finishing Date"; Date)
        {
            Caption = 'Finishing Date';
            ToolTip = 'Specifies the finishing date of the service, that is, the date when the Status field changes to Finished.';
        }
        field(5932; "Finishing Time"; Time)
        {
            Caption = 'Finishing Time';
            ToolTip = 'Specifies the finishing time of the service, that is, the time when the Status field changes to Finished.';
        }
        field(5936; "Notify Customer"; Option)
        {
            Caption = 'Notify Customer';
            ToolTip = 'Specifies how the customer wants to receive notifications about service completion.';
            OptionCaption = 'No,By Phone 1,By Phone 2,By Fax,By Email';
            OptionMembers = No,"By Phone 1","By Phone 2","By Fax","By Email";
        }
        field(5937; "Max. Labor Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Max. Labor Unit Price';
            ToolTip = 'Specifies the maximum unit price that can be set for a resource (for example, a technician) on all service lines linked to this order.';
        }
        field(5938; "Warning Status"; Option)
        {
            Caption = 'Warning Status';
            ToolTip = 'Specifies the response time warning status for the order.';
            OptionCaption = ' ,First Warning,Second Warning,Third Warning';
            OptionMembers = " ","First Warning","Second Warning","Third Warning";
        }
        field(5939; "No. of Allocations"; Integer)
        {
            CalcFormula = count("Service Order Allocat. Archive" where("Document Type" = field("Document Type"),
                                                                       "Document No." = field("No."),
                                                                       "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                       "Version No." = field("Version No."),
                                                                       "Resource No." = field("Resource Filter"),
                                                                       "Resource Group No." = field("Resource Group Filter"),
                                                                       "Allocation Date" = field("Date Filter"),
                                                                        Status = filter(Active | Finished)));
            Caption = 'No. of Allocations';
            ToolTip = 'Specifies the number of resource allocations to service items in this order.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5940; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            ToolTip = 'Specifies the number of the contract associated with the order.';
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract),
                                                                           "Customer No." = field("Customer No."),
                                                                           "Ship-to Code" = field("Ship-to Code"),
                                                                           "Bill-to Customer No." = field("Bill-to Customer No."));
            ValidateTableRelation = false;
        }
        field(5953; "Resource Filter"; Code[20])
        {
            Caption = 'Resource Filter';
            FieldClass = FlowFilter;
            TableRelation = Resource;
        }
        field(5955; "Ship-to Fax No."; Text[30])
        {
            Caption = 'Ship-to Fax No.';
        }
        field(5956; "Ship-to E-Mail"; Text[80])
        {
            Caption = 'Ship-to Email';
            ToolTip = 'Specifies the email address at the address that the items are shipped to.';
            ExtendedDatatype = EMail;
        }
        field(5957; "Resource Group Filter"; Code[20])
        {
            Caption = 'Resource Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Resource Group";
        }
        field(5958; "Ship-to Phone"; Text[30])
        {
            Caption = 'Ship-to Phone';
            ToolTip = 'Specifies the phone number of the address where the service items in the order are located.';
            ExtendedDatatype = PhoneNo;
        }
        field(5959; "Ship-to Phone 2"; Text[30])
        {
            Caption = 'Ship-to Phone 2';
            ToolTip = 'Specifies an additional phone number at address that the items are shipped to.';
            ExtendedDatatype = PhoneNo;
        }
        field(5968; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            ToolTip = 'Specifies the service zone code of the customer''s ship-to address in the service order.';
            Editable = false;
            TableRelation = "Service Zone".Code;
        }
        field(5981; "Expected Finishing Date"; Date)
        {
            Caption = 'Expected Finishing Date';
            ToolTip = 'Specifies the date when service on the order is expected to be finished.';
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            ToolTip = 'Specifies the ID of the user who is responsible for the document.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
        field(9001; "Service Quote No."; Code[20])
        {
            Caption = 'Service Quote No.';
            ToolTip = 'Specifies the number of the service quote that the service order was created from. You can track the number to service quote documents that you have printed, saved, or emailed.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.", "Doc. No. Occurrence", "Version No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Customer No.", "Date Archived")
        {
        }
        key(Key3; "Document Type", "Bill-to Customer No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Version No.", Name)
        {
        }
    }

    trigger OnDelete()
    var
        ServiceLineArchive: Record "Service Line Archive";
        ServiceItemLineArchive: Record "Service Item Line Archive";
        ServiceOrderAllocatArchive: Record "Service Order Allocat. Archive";
        ServiceCommentLineArchive: Record "Service Comment Line Archive";
        ServCatalogItemMgt: Codeunit "Serv. Catalog Item Mgt.";
    begin
        ServiceLineArchive.SetRange("Document Type", "Document Type");
        ServiceLineArchive.SetRange("Document No.", "No.");
        ServiceLineArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        ServiceLineArchive.SetRange("Version No.", "Version No.");
        ServiceLineArchive.SetRange(Nonstock, true);
        if ServiceLineArchive.FindSet(true) then
            repeat
                ServCatalogItemMgt.DelNonStockServiceArch(ServiceLineArchive);
            until ServiceLineArchive.Next() = 0;
        ServiceLineArchive.SetRange(Nonstock);
        ServiceLineArchive.DeleteAll();

        ServiceOrderAllocatArchive.SetRange("Document Type", "Document Type");
        ServiceOrderAllocatArchive.SetRange("Document No.", "No.");
        ServiceOrderAllocatArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        ServiceOrderAllocatArchive.SetRange("Version No.", "Version No.");
        ServiceOrderAllocatArchive.DeleteAll();

        ServiceCommentLineArchive.SetRange("Table Subtype", "Document Type");
        ServiceCommentLineArchive.SetRange("No.", "No.");
        ServiceCommentLineArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        ServiceCommentLineArchive.SetRange("Version No.", "Version No.");
        ServiceCommentLineArchive.DeleteAll();

        ServiceItemLineArchive.SetRange("Document Type", "Document Type");
        ServiceItemLineArchive.SetRange("Document No.", "No.");
        ServiceItemLineArchive.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        ServiceItemLineArchive.SetRange("Version No.", "Version No.");
        ServiceItemLineArchive.DeleteAll();
    end;

    procedure ShowDimensions()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."));
    end;

    internal procedure SetSecurityFilterOnRespCenter()
    var
        UserSetupManagement: Codeunit "User Setup Management";
    begin
        if UserSetupManagement.GetServiceFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupManagement.GetServiceFilter());
            FilterGroup(0);
        end;
    end;

    procedure GetWorkDescription(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Work Description");
        "Work Description".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Work Description")));
    end;
}