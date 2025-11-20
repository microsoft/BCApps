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
using System.Globalization;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;
using System.Email;

table 112 "Sales Invoice Header"
{
    Caption = 'Sales Invoice Header';
    DataCaptionFields = "No.", "Sell-to Customer Name";
    DrillDownPageID = "Posted Sales Invoices";
    LookupPageID = "Posted Sales Invoices";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;
            ToolTip = 'Specifies the number of the customer that you shipped the items on the invoice to.';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            ToolTip = 'Specifies the number of the customer that you send or sent the invoice to.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
        }
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer that you send or sent the invoice to.';
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));
        }
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
        }
        field(14; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
        }
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
        }
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
        }
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
        }
        field(19; "Order Date"; Date)
        {
            Caption = 'Order Date';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(25; "Payment Discount %"; Decimal)
        {
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
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
            TableRelation = "Salesperson/Purchaser";
        }
        field(44; "Order No."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Order No.';
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Sales Comment Line" where("Document Type" = const("Posted Invoice"),
                                                            "No." = field("No."),
                                                            "Document Line No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
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
                CustLedgEntry: Record "Cust. Ledger Entry";
            begin
                CustLedgEntry.SetCurrentKey("Document No.");
                CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                OnLookupAppliesToDocNoOnAfterSetFilters(CustLedgEntry, Rec);
                PAGE.Run(0, CustLedgEntry);
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
            CalcFormula = sum("Sales Invoice Line".Amount where("Document No." = field("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Sales Invoice Line"."Amount Including VAT" where("Document No." = field("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(72; "Registration Number"; Text[50])
        {
            Caption = 'Registration No.';
            DataClassification = CustomerContent;
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
        field(79; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
        }
        field(80; "Sell-to Customer Name 2"; Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer who will receive the products and be billed by default.';
        }
        field(81; "Sell-to Address"; Text[100])
        {
            Caption = 'Sell-to Address';
        }
        field(82; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';
        }
        field(83; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(84; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(88; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(89; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,2,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';
        }
        field(90; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(94; "Bal. Account Type"; enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(97; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
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
            TableRelation = "Payment Method";
        }
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(106; "Package Tracking No."; Text[50])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Package Tracking No.';
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
            TableRelation = "Tax Area";
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(119; "VAT Base Discount %"; Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
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
            Caption = 'Invoice Discount Value';
        }
        field(131; "Prepayment No. Series"; Code[20])
        {
            Caption = 'Prepayment No. Series';
            TableRelation = "No. Series";
        }
        field(136; "Prepayment Invoice"; Boolean)
        {
            Caption = 'Prepayment Invoice';
        }
        field(137; "Prepayment Order No."; Code[20])
        {
            Caption = 'Prepayment Order No.';
        }
        field(151; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
            Editable = false;
        }
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
        }
        field(166; "Alt. VAT Registration No."; Boolean)
        {
            Caption = 'Alternative VAT Registration No.';
            Editable = false;
        }
        field(167; "Alt. Gen. Bus Posting Group"; Boolean)
        {
            Caption = 'Alternative Gen. Bus. Posting Group';
            Editable = false;
        }
        field(168; "Alt. VAT Bus Posting Group"; Boolean)
        {
            Caption = 'Alternative VAT Bus. Posting Group';
            Editable = false;
        }
        field(171; "Sell-to Phone No."; Text[30])
        {
            Caption = 'Sell-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(172; "Sell-to E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
        }
        field(179; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = false;
        }
        field(180; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
        }
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
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
        }
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
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
        field(600; "Payment Service Set ID"; Integer)
        {
            Caption = 'Payment Service Set ID';
        }
        field(710; "Document Exchange Identifier"; Text[50])
        {
            Caption = 'Document Exchange Identifier';
        }
        field(711; "Document Exchange Status"; Enum "Sales Document Exchange Status")
        {
            Caption = 'Document Exchange Status';
        }
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
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Sales Invoice Header")));
        }
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Bill-to Customer No."));
        }
        field(1302; Closed; Boolean)
        {
            CalcFormula = - exist("Cust. Ledger Entry" where("Entry No." = field("Cust. Ledger Entry No."),
                                                             Open = filter(true)));
            Caption = 'Closed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1303; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Detailed Cust. Ledg. Entry".Amount where("Cust. Ledger Entry No." = field("Cust. Ledger Entry No.")));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1304; "Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Cust. Ledger Entry No.';
            Editable = false;
            TableRelation = "Cust. Ledger Entry"."Entry No.";
        }
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Sales Invoice Line"."Inv. Discount Amount" where("Document No." = field("No.")));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1310; Cancelled; Boolean)
        {
            CalcFormula = exist("Cancelled Document" where("Source ID" = const(112),
                                                            "Cancelled Doc. No." = field("No.")));
            Caption = 'Cancelled';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1311; Corrective; Boolean)
        {
            CalcFormula = exist("Cancelled Document" where("Source ID" = const(114),
                                                            "Cancelled By Doc. No." = field("No.")));
            Caption = 'Corrective';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1312; Reversed; Boolean)
        {
            Caption = 'Reversed';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Cust. Ledger Entry".Reversed where("Entry No." = field("Cust. Ledger Entry No.")));
        }
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
        field(1341; "Promised Pay Date"; Date)
        {
            Caption = 'Promised Pay Date';
            DataClassification = CustomerContent;
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(5052; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            TableRelation = Contact;
        }
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact;
        }
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
        }
        field(7200; "Get Shipment Used"; Boolean)
        {
            Caption = 'Get Shipment Used';
        }
        field(8001; "Draft Invoice SystemId"; Guid)
        {
            Caption = 'Draft Invoice SystemId';
            DataClassification = SystemMetadata;
        }
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

    procedure UpdateDisputeStatus()
    var
        DisputeStatus: Record "Dispute Status";
    begin
        if not IsNullGuid("Dispute Status Id") then
            DisputeStatus.GetBySystemId("Dispute Status Id");
        Validate("Dispute Status", DisputeStatus.Code);
    end;

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

    procedure GetDocTypeTxt(): Text[50]
    var
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        exit(ReportDistributionMgt.GetFullDocumentTypeText(Rec));
    end;

    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

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

    procedure GetCustomerVATRegistrationNumber(): Text
    begin
        exit("VAT Registration No.");
    end;

    procedure GetCustomerVATRegistrationNumberLbl(): Text
    begin
        if "VAT Registration No." = '' then
            exit('');
        exit(FieldCaption("VAT Registration No."));
    end;

    procedure GetCustomerGlobalLocationNumber(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Sell-to Customer No.") then
            exit(Customer.GLN);
        exit('');
    end;

    procedure GetCustomerGlobalLocationNumberLbl(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Sell-to Customer No.") then
            exit(Customer.FieldCaption(GLN));
        exit('');
    end;

    procedure GetSellToCustomerFaxNo(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Sell-to Customer No.") then
            exit(Customer."Fax No.");
    end;

    procedure GetPaymentReference(): Text
    begin
        OnGetPaymentReference(PaymentReference);
        exit(PaymentReference);
    end;

    procedure GetPaymentReferenceLbl(): Text
    begin
        OnGetPaymentReferenceLbl(PaymentReferenceLbl);
        exit(PaymentReferenceLbl);
    end;

    procedure GetLegalStatement(): Text
    begin
        SalesSetup.Get();
        exit(SalesSetup.GetLegalStatement());
    end;

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

        if UserSetupMgt.GetSalesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetSalesFilter());
            FilterGroup(0);
        end;
    end;

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

    procedure ShowActivityLog()
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.ShowEntries(Rec.RecordId);
    end;

    procedure StartTrackingSite()
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        TestField("Shipping Agent Code");
        ShippingAgent.Get("Shipping Agent Code");
        HyperLink(ShippingAgent.GetTrackingInternetAddr("Package Tracking No."));
    end;

    procedure GetSelectedPaymentsText(): Text
    var
        PaymentServiceSetup: Record "Payment Service Setup";
    begin
        exit(PaymentServiceSetup.GetSelectedPaymentsText("Payment Service Set ID"));
    end;

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

    procedure DocExchangeStatusIsSent(): Boolean
    begin
        exit("Document Exchange Status" <> "Document Exchange Status"::"Not Sent");
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

    procedure GetDefaultEmailDocumentName(): Text[150]
    begin
        exit(DocTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoPrinted(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmailRecords(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; DocTxt: Text; var ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; ShowRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoPrintToDocumentAttachment(var SalesInvoiceHeader: Record "Sales Invoice Header"; var ShowNotificationAction: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendProfile(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; DocTxt: Text; var IsHandled: Boolean; var DocumentSendingProfile: Record "Document Sending Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRecords(var ReportSelections: Record "Report Selections"; var SalesInvoiceHeader: Record "Sales Invoice Header"; DocTxt: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCanceledOrCorrCrMemo(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCorrectiveCreditMemo(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCancelledCreditMemo(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetPaymentReference(var PaymentReference: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPaymentReferenceLbl(var PaymentReferenceLbl: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostedSalesInvoiceFullyOpen(var SalesInvoiceHeader: Record "Sales Invoice Header"; var FullyOpen: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWorkDescription(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}