// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

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
using Microsoft.Sales.FinanceCharge;
using System.Globalization;
using System.Security.AccessControl;
using System.Text;

table 297 "Issued Reminder Header"
{
    Caption = 'Issued Reminder Header';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Issued Reminder List";
    LookupPageID = "Issued Reminder List";
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
        field(24; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            TableRelation = "Reminder Terms";
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
        field(28; "Reminder Level"; Integer)
        {
            Caption = 'Reminder Level';
            TableRelation = "Reminder Level"."No." where("Reminder Terms Code" = field("Reminder Terms Code"));
        }
        field(29; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = exist("Reminder Comment Line" where(Type = const("Issued Reminder"),
                                                               "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Reminder Line"."Remaining Amount" where("Reminder No." = field("No."),
                                                                               "Line Type" = const("Reminder Line"),
                                                                               "Detailed Interest Rates Entry" = const(false)));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Interest Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Reminder Line".Amount where("Reminder No." = field("No."),
                                                                   Type = const("Customer Ledger Entry"),
                                                                   "Line Type" = const("Reminder Line"),
                                                                   "Detailed Interest Rates Entry" = const(false)));
            Caption = 'Interest Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Additional Fee"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Reminder Line".Amount where("Reminder No." = field("No."),
                                                                  Type = const("G/L Account"),
                                                                  "Line Type" = filter(<> "Not Due")));
            Caption = 'Additional Fee';
            Editable = false;
            FieldClass = FlowField;
        }
        field(34; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Issued Reminder Line"."VAT Amount" where("Reminder No." = field("No."),
                                                                        "Detailed Interest Rates Entry" = const(false),
                                                                        "Line Type" = filter(<> "Not Due")));
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
        field(44; "Add. Fee per Line"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            CalcFormula = sum("Issued Reminder Line".Amount where("Reminder No." = field("No."),
                                                                   Type = const("Line Fee")));
            Caption = 'Add. Fee per Line';
            FieldClass = FlowField;
        }
        field(47; "VAT Reporting Date"; Date)
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
        field(55; "Email Text"; Blob)
        {
            Caption = 'Email Text';
        }
        field(56; "Sent For Current Level"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(57; "Last Email Sent Date Time"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(58; "Total Email Sent Count"; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(59; "Last Level Email Sent Count"; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(60; "Email Sent Level"; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(61; "Failed Email Outbox Entry No."; BigInteger)
        {
            DataClassification = CustomerContent;
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
        field(500; "Reminder Automation Code"; Code[50])
        {
            DataClassification = CustomerContent;
            TableRelation = "Reminder Action Group"."Code";
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
        ReminderIssue.DeleteIssuedReminderLines(Rec);

        ReminderCommentLine.SetRange(Type, ReminderCommentLine.Type::"Issued Reminder");
        ReminderCommentLine.SetRange("No.", "No.");
        ReminderCommentLine.DeleteAll();
    end;

    var
        ReminderCommentLine: Record "Reminder Comment Line";
        ReminderIssue: Codeunit "Reminder-Issue";
        DimMgt: Codeunit DimensionManagement;
        SuppresSendDialogQst: Label 'Do you want to suppress send dialog?';

    procedure PrintRecords(ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderHeaderToSend: Record "Issued Reminder Header";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, ShowRequestForm, SendAsEmail, HideDialog, IsHandled);
        if IsHandled then
            exit;

        if SendAsEmail then begin
            IssuedReminderHeader.Copy(Rec);
            if (not HideDialog) and (IssuedReminderHeader.Count > 1) then
                if Confirm(SuppresSendDialogQst) then
                    HideDialog := true;
            if IssuedReminderHeader.FindSet() then
                repeat
                    IssuedReminderHeaderToSend.Copy(IssuedReminderHeader);
                    IssuedReminderHeaderToSend.SetRecFilter();
                    DocumentSendingProfile.TrySendToEMail(
                      DummyReportSelections.Usage::Reminder.AsInteger(), IssuedReminderHeaderToSend, IssuedReminderHeaderToSend.FieldNo("No."),
                      ReportDistributionMgt.GetFullDocumentTypeText(Rec), IssuedReminderHeaderToSend.FieldNo("Customer No."), not HideDialog)
                until IssuedReminderHeader.Next() = 0;
        end else
            DocumentSendingProfile.TrySendToPrinter(
              DummyReportSelections.Usage::Reminder.AsInteger(), Rec,
              IssuedReminderHeaderToSend.FieldNo("Customer No."), ShowRequestForm);

        OnAfterPrintRecords(Rec, ShowRequestForm, SendAsEmail, HideDialog);
    end;

    procedure ClearSentEmailFieldsOnLevelUpdate(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        IssuedReminderHeader."Sent For Current Level" := false;
        IssuedReminderHeader."Last Level Email Sent Count" := 0;
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
        ReminderIssue.IncrNoPrinted(Rec);
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;

    procedure GetCustomerVATRegistrationNumber(): Text
    begin
        exit("VAT Registration No.");
    end;

    procedure GetCustomerVATRegistrationNumberLbl(): Text
    begin
        exit(FieldCaption("VAT Registration No."));
    end;

    procedure CalculateLineFeeVATAmount(): Decimal
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetCurrentKey("Reminder No.", Type, "Line Type");
        IssuedReminderLine.SetRange("Reminder No.", "No.");
        IssuedReminderLine.SetRange(Type, IssuedReminderLine.Type::"Line Fee");
        IssuedReminderLine.CalcSums("VAT Amount");
        exit(IssuedReminderLine."VAT Amount");
    end;

    procedure CalculateTotalIncludingVAT(): Decimal
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        ReminderInterestAmount: Decimal;
        InterestAmountTotal: Decimal;
        VATAmountTotal: Decimal;
        RemainingAmountTotal: Decimal;
    begin
        IssuedReminderLine.SetRange("Reminder No.", Rec."No.");

        IssuedReminderLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if IssuedReminderLine.IsEmpty() then
            exit(0);

        IssuedReminderLine.FindSet();
        repeat
            ReminderInterestAmount := 0;
            case IssuedReminderLine.Type of
                IssuedReminderLine.Type::"G/L Account":
                    "Remaining Amount" := IssuedReminderLine.Amount;
                IssuedReminderLine.Type::"Line Fee":
                    "Remaining Amount" := IssuedReminderLine.Amount;
                IssuedReminderLine.Type::"Customer Ledger Entry":
                    ReminderInterestAmount := IssuedReminderLine.Amount;
            end;

            InterestAmountTotal += ReminderInterestAmount;
            RemainingAmountTotal += IssuedReminderLine."Remaining Amount";
            VATAmountTotal += IssuedReminderLine."VAT Amount";
        until IssuedReminderLine.Next() = 0;
        exit(RemainingAmountTotal + InterestAmountTotal + VATAmountTotal);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintRecords(var IssuedReminderHeader: Record "Issued Reminder Header"; ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var IssuedReminderHeader: Record "Issued Reminder Header"; ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    procedure RunCancelIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(IssuedReminderHeader);
        IssuedReminderHeader.SetFilter(
          "No.",
          SelectionFilterManagement.GetSelectionFilter(RecRef, IssuedReminderHeader.FieldNo("No.")));

        REPORT.RunModal(REPORT::"Cancel Issued Reminders", true, false, IssuedReminderHeader);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetReportParameters(var LogInteraction: Boolean; var ShowNotDueAmounts: Boolean; var ShowMIRLines: Boolean; ReportID: Integer; var Handled: Boolean)
    begin
    end;
}

