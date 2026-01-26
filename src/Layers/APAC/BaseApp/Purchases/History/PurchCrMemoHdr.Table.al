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
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.WithholdingTax;
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
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Automation;
using System.Globalization;
using System.Security.AccessControl;
using System.Security.User;

table 124 "Purch. Cr. Memo Hdr."
{
    Caption = 'Purch. Cr. Memo Hdr.';
    DataCaptionFields = "No.", "Buy-from Vendor Name";
    DrillDownPageID = "Posted Purchase Credit Memos";
    LookupPageID = "Posted Purchase Credit Memos";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;
            ToolTip = 'Specifies the number of the vendor that you shipped the items on the credit memo to.';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;
            ToolTip = 'Specifies the number of the vendor that you received the credit memo from.';
        }
        field(5; "Pay-to Name"; Text[100])
        {
            Caption = 'Pay-to Name';
        }
        field(6; "Pay-to Name 2"; Text[50])
        {
            Caption = 'Pay-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the vendor who you received the credit memo from.';
        }
        field(7; "Pay-to Address"; Text[100])
        {
            Caption = 'Pay-to Address';
        }
        field(8; "Pay-to Address 2"; Text[50])
        {
            Caption = 'Pay-to Address 2';
        }
        field(9; "Pay-to City"; Text[30])
        {
            Caption = 'Pay-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(10; "Pay-to Contact"; Text[100])
        {
            Caption = 'Pay-to Contact';
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
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(21; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
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
        field(31; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            Editable = false;
            TableRelation = "Vendor Posting Group";
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
            TableRelation = "Salesperson/Purchaser";
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Purch. Comment Line" where("Document Type" = const("Posted Credit Memo"),
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
                VendLedgEntry: Record "Vendor Ledger Entry";
            begin
                VendLedgEntry.SetCurrentKey("Document No.");
                VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
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
            CalcFormula = sum("Purch. Cr. Memo Line".Amount where("Document No." = field("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Purch. Cr. Memo Line"."Amount Including VAT" where("Document No." = field("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(69; "Vendor Cr. Memo No."; Code[35])
        {
            Caption = 'Vendor Cr. Memo No.';
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
        }
        field(80; "Buy-from Vendor Name 2"; Text[50])
        {
            Caption = 'Buy-from Vendor Name 2';
            ToolTip = 'Specifies an additional part of the name of the vendor that you’re buying from.';
        }
        field(81; "Buy-from Address"; Text[100])
        {
            Caption = 'Buy-from Address';
        }
        field(82; "Buy-from Address 2"; Text[50])
        {
            Caption = 'Buy-from Address 2';
        }
        field(83; "Buy-from City"; Text[30])
        {
            Caption = 'Buy-from City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(84; "Buy-from Contact"; Text[100])
        {
            Caption = 'Buy-from Contact';
        }
        field(85; "Pay-to Post Code"; Code[20])
        {
            Caption = 'Pay-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(86; "Pay-to County"; Text[30])
        {
            CaptionClass = '5,6,' + "Pay-to Country/Region Code";
            Caption = 'Pay-to County';
        }
        field(87; "Pay-to Country/Region Code"; Code[10])
        {
            Caption = 'Pay-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(88; "Buy-from Post Code"; Code[20])
        {
            Caption = 'Buy-from Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(89; "Buy-from County"; Text[30])
        {
            CaptionClass = '5,5,' + "Buy-from Country/Region Code";
            Caption = 'Buy-from County';
        }
        field(90; "Buy-from Country/Region Code"; Code[10])
        {
            Caption = 'Buy-from Country/Region Code';
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
        field(95; "Order Address Code"; Code[10])
        {
            Caption = 'Order Address Code';
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
        field(138; "Prepmt. Cr. Memo No. Series"; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";
        }
        field(140; "Prepayment Credit Memo"; Boolean)
        {
            Caption = 'Prepayment Credit Memo';
        }
        field(141; "Prepayment Order No."; Code[20])
        {
            Caption = 'Prepayment Order No.';
        }
        field(179; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = false;
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
        field(1302; Paid; Boolean)
        {
            CalcFormula = - exist("Vendor Ledger Entry" where("Entry No." = field("Vendor Ledger Entry No."),
                                                              Open = filter(true)));
            Caption = 'Paid';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1303; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = - sum("Detailed Vendor Ledg. Entry".Amount where("Vendor Ledger Entry No." = field("Vendor Ledger Entry No.")));
            Caption = 'Remaining Amount';
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
            CalcFormula = sum("Purch. Cr. Memo Line"."Inv. Discount Amount" where("Document No." = field("No.")));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1310; Cancelled; Boolean)
        {
            CalcFormula = exist("Cancelled Document" where("Source ID" = const(124),
                                                            "Cancelled Doc. No." = field("No.")));
            Caption = 'Cancelled';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1311; Corrective; Boolean)
        {
            CalcFormula = exist("Cancelled Document" where("Source ID" = const(122),
                                                            "Cancelled By Doc. No." = field("No.")));
            Caption = 'Corrective';
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
            TableRelation = Contact;
        }
        field(5053; "Pay-to Contact No."; Code[20])
        {
            Caption = 'Pay-to Contact No.';
            TableRelation = Contact;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(6601; "Return Order No."; Code[20])
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Return Order No.';
        }
        field(6602; "Return Order No. Series"; Code[20])
        {
            Caption = 'Return Order No. Series';
            TableRelation = "No. Series";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(8001; "Draft Cr. Memo SystemId"; Guid)
        {
            Caption = 'Draft Cr. Memo System Id';
            DataClassification = SystemMetadata;
        }
        field(11612; Adjustment; Boolean)
        {
            Caption = 'Adjustment';
            Editable = false;
        }
        field(11613; "BAS Adjustment"; Boolean)
        {
            Caption = 'BAS Adjustment';
            Editable = false;
        }
        field(11614; "Adjustment Applies-to"; Code[20])
        {
            Caption = 'Adjustment Applies-to';
        }
        field(11620; ABN; Text[14])
        {
            Caption = 'ABN';
            Editable = false;
            Numeric = true;
        }
        field(11622; "ABN Division Part No."; Text[3])
        {
            Caption = 'ABN Division Part No.';
        }
        field(28040; "WHT Business Posting Group"; Code[20])
        {
            Caption = 'WHT Business Posting Group';
            TableRelation = "WHT Business Posting Group";
        }
        field(28041; "Rem. WHT Prepaid Amount (LCY)"; Decimal)
        {
            CalcFormula = sum("WHT Entry"."Remaining Unrealized Amount" where("Document Type" = const("Credit Memo"),
                                                                               "Document No." = field("No.")));
            Caption = 'Rem. WHT Prepaid Amount (LCY)';
            FieldClass = FlowField;
        }
        field(28042; "Paid WHT Prepaid Amount (LCY)"; Decimal)
        {
            CalcFormula = sum("WHT Entry".Amount where("Document Type" = const(Refund),
                                                        "Document No." = field("No.")));
            Caption = 'Paid WHT Prepaid Amount (LCY)';
            FieldClass = FlowField;
        }
        field(28043; "Total WHT Prepaid Amount (LCY)"; Decimal)
        {
            CalcFormula = sum("WHT Entry"."Unrealized Amount" where("Document Type" = const("Credit Memo"),
                                                                     "Document No." = field("No.")));
            Caption = 'Total WHT Prepaid Amount (LCY)';
            FieldClass = FlowField;
        }
        field(28045; "Actual Vendor No."; Code[20])
        {
            Caption = 'Actual Vendor No.';
            TableRelation = Vendor;
        }
        field(28070; "Printed Tax Document"; Boolean)
        {
            Caption = 'Printed Tax Document';
            Editable = false;
        }
        field(28071; "Posted Tax Document"; Boolean)
        {
            Caption = 'Posted Tax Document';
            Editable = false;
        }
        field(28073; "Tax Date Filter"; Date)
        {
            Caption = 'Tax Date Filter';
            FieldClass = FlowFilter;
        }
        field(28074; "Tax Document Marked"; Boolean)
        {
            Caption = 'Tax Document Marked';
            Editable = false;
        }
        field(28075; "Invoice Print Type"; Option)
        {
            Caption = 'Invoice Print Type';
            Editable = false;
            OptionCaption = 'Invoice,Tax Invoice (Items),Tax Invoice (Services)';
            OptionMembers = Invoice,"Tax Invoice (Items)","Tax Invoice (Services)";
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
        key(Key3; "Vendor Cr. Memo No.", "Posting Date")
        {
        }
        key(Key4; "Return Order No.")
        {
        }
        key(Key5; "Buy-from Vendor No.")
        {
        }
        key(Key6; "Prepayment Order No.")
        {
        }
        key(Key7; "Pay-to Vendor No.")
        {
        }
        key(Key8; "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Buy-from Vendor No.", "Pay-to Vendor No.", "Posting Date", "Posting Description")
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
        PostPurchDelete.DeletePurchCrMemoLines(Rec);

        PurchCommentLine.SetRange("Document Type", PurchCommentLine."Document Type"::"Posted Credit Memo");
        PurchCommentLine.SetRange("No.", "No.");
        PurchCommentLine.DeleteAll();

        ApprovalsMgmt.DeletePostedApprovalEntries(RecordId);
        PostedDeferralHeader.DeleteForDoc(
            "Deferral Document Type"::Purchase.AsInteger(), '', '',
            PurchCommentLine."Document Type"::"Posted Credit Memo".AsInteger(), "No.");
    end;

    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCommentLine: Record "Purch. Comment Line";
        DimMgt: Codeunit DimensionManagement;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        UserSetupMgt: Codeunit "User Setup Management";

    procedure PrintRecords(ShowRequestPage: Boolean)
    var
        ReportSelection: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, ShowRequestPage, IsHandled);
        if not IsHandled then begin
            PurchCrMemoHeader.Copy(Rec);
            ReportSelection.PrintWithDialogForVend(
              ReportSelection.Usage::"P.Cr.Memo", PurchCrMemoHeader, ShowRequestPage, PurchCrMemoHeader.FieldNo("Buy-from Vendor No."));
        end;
    end;

    procedure PrintToDocumentAttachment(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        if PurchCrMemoHdr.FindSet() then
            repeat
                DoPrintToDocumentAttachment(PurchCrMemoHdr);
            until PurchCrMemoHdr.Next() = 0;
    end;

    local procedure DoPrintToDocumentAttachment(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDoPrintToDocumentAttachment(PurchCrMemoHdr, IsHandled);
        if IsHandled then
            exit;

        PurchCrMemoHdr.SetRecFilter();
        ReportSelections.SaveAsDocumentAttachment(
            ReportSelections.Usage::"P.Cr.Memo".AsInteger(), PurchCrMemoHdr, PurchCrMemoHdr."No.", PurchCrMemoHdr."Buy-from Vendor No.", true);
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

    procedure ShowCorrectiveInvoice()
    var
        CancelledDocument: Record "Cancelled Document";
        PurchInvHeader: Record "Purch. Inv. Header";
        IsHandled: Boolean;
    begin
        CalcFields(Cancelled);
        if not Cancelled then
            exit;

        if CancelledDocument.FindPurchCancelledCrMemo("No.") then begin
            PurchInvHeader.Get(CancelledDocument."Cancelled By Doc. No.");
            IsHandled := false;
            OnShowCorrectiveInvoiceOnBeforeOpenPage(PurchInvHeader, IsHandled);
            if not IsHandled then
                PAGE.Run(PAGE::"Posted Purchase Invoice", PurchInvHeader);
        end;
    end;

    procedure ShowCancelledInvoice()
    var
        CancelledDocument: Record "Cancelled Document";
        PurchInvHeader: Record "Purch. Inv. Header";
        IsHandled: Boolean;
    begin
        CalcFields(Corrective);
        if not Corrective then
            exit;

        if CancelledDocument.FindPurchCorrectiveCrMemo("No.") then begin
            PurchInvHeader.Get(CancelledDocument."Cancelled Doc. No.");
            IsHandled := false;
            OnShowCancelledInvoiceOnBeforeOpenPage(PurchInvHeader, IsHandled);
            if not IsHandled then
                PAGE.Run(PAGE::"Posted Purchase Invoice", PurchInvHeader);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; ShowRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var VendLedgEntry: Record "Vendor Ledger Entry"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoPrintToDocumentAttachment(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCorrectiveInvoiceOnBeforeOpenPage(var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCancelledInvoiceOnBeforeOpenPage(var PurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;
}
