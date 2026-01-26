// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using System.Globalization;
using System.Security.AccessControl;
using System.Text;

table 304 "Issued Fin. Charge Memo Header"
{
    Caption = 'Issued Fin. Charge Memo Header';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Issued Fin. Charge Memo List";
    LookupPageID = "Issued Fin. Charge Memo List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(8; City; Text[30])
        {
            Caption = 'City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(9; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(13; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(15; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(16; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(17; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
        }
        field(18; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(19; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(20; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(22; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(23; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(25; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            TableRelation = "Finance Charge Terms";
        }
        field(26; "Interest Posted"; Boolean)
        {
            Caption = 'Interest Posted';
        }
        field(27; "Additional Fee Posted"; Boolean)
        {
            Caption = 'Additional Fee Posted';
        }
        field(29; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = exist("Fin. Charge Comment Line" where(Type = const("Issued Finance Charge Memo"),
                                                                  "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Fin. Charge Memo Line"."Remaining Amount" where("Finance Charge Memo No." = field("No."),
                                                                                       "Detailed Interest Rates Entry" = const(false)));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Interest Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Fin. Charge Memo Line".Amount where("Finance Charge Memo No." = field("No."),
                                                                           Type = const("Customer Ledger Entry"),
                                                                           "Detailed Interest Rates Entry" = const(false)));
            Caption = 'Interest Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Additional Fee"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Fin. Charge Memo Line".Amount where("Finance Charge Memo No." = field("No."),
                                                                           Type = const("G/L Account")));
            Caption = 'Additional Fee';
            Editable = false;
            FieldClass = FlowField;
        }
        field(34; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Fin. Charge Memo Line"."VAT Amount" where("Finance Charge Memo No." = field("No."),
                                                                                 "Detailed Interest Rates Entry" = const(false)));
            Caption = 'VAT Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(35; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(36; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(37; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(38; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            TableRelation = "No. Series";
        }
        field(39; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
        }
        field(40; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(41; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(42; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(43; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(44; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = false;
        }
        field(50; Canceled; Boolean)
        {
            Caption = 'Canceled';
            DataClassification = SystemMetadata;
        }
        field(51; "Canceled By"; Code[50])
        {
            Caption = 'Canceled By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(52; "Canceled Date"; Date)
        {
            Caption = 'Canceled Date';
            DataClassification = SystemMetadata;
        }
        field(53; "Canceled By Document No."; Code[20])
        {
            Caption = 'Canceled By Document No.';
            DataClassification = CustomerContent;
        }
        field(54; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
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
        field(11310; "Enterprise No."; Text[50])
        {
            Caption = 'Enterprise No.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Customer No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Customer No.", Name, "Posting Date")
        {
        }
    }

    trigger OnDelete()
    begin
        TestField("No. Printed");
        LockTable();
        FinChrgMemoIssue.DeleteIssuedFinChrgLines(Rec);

        FinChrgCommentLine.SetRange(Type, FinChrgCommentLine.Type::"Issued Finance Charge Memo");
        FinChrgCommentLine.SetRange("No.", "No.");
        FinChrgCommentLine.DeleteAll();
    end;

    var
        FinChrgCommentLine: Record "Fin. Charge Comment Line";
        FinChrgMemoIssue: Codeunit "FinChrgMemo-Issue";
        DimMgt: Codeunit DimensionManagement;

    procedure PrintRecords(ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean)
    var
        DummyReportSelections: Record "Report Selections";
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, ShowRequestForm, SendAsEmail, HideDialog, IsHandled);
        if IsHandled then
            exit;

        if SendAsEmail then
            DocumentSendingProfile.TrySendToEMail(
              DummyReportSelections.Usage::"Fin.Charge".AsInteger(), Rec, FieldNo("No."),
              ReportDistributionMgt.GetFullDocumentTypeText(Rec), FieldNo("Customer No."), not HideDialog)
        else
            DocumentSendingProfile.TrySendToPrinter(
              DummyReportSelections.Usage::"Fin.Charge".AsInteger(), Rec, FieldNo("Customer No."), ShowRequestForm)
    end;

    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    procedure IncrNoPrinted()
    begin
        FinChrgMemoIssue.IncrNoPrinted(Rec);
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;

    procedure GetCustomerVATRegistrationNumber(): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.DetermineCountry("Country/Region Code") then
            exit("Enterprise No.");
        exit("VAT Registration No.");
    end;

    procedure GetCustomerVATRegistrationNumberLbl(): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.DetermineCountry("Country/Region Code") then
            exit(FieldCaption("Enterprise No."));
        exit(FieldCaption("VAT Registration No."));
    end;

    procedure RunCancelIssuedFinChargeMemo(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(IssuedFinChargeMemoHeader);
        IssuedFinChargeMemoHeader.SetFilter(
          "No.",
          SelectionFilterManagement.GetSelectionFilter(RecRef, IssuedFinChargeMemoHeader.FieldNo("No.")));

        REPORT.RunModal(REPORT::"Cancel Issued Fin.Charge Memos", true, false, IssuedFinChargeMemoHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;
}

