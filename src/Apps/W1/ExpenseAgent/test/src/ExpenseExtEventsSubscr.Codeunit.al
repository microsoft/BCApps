// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Journal;

codeunit 148368 "Expense Ext. Events Subscr."
{
    EventSubscriberInstance = Manual;

    var
        MarkerText: Text[20];
        GenJnlLineDescriptionMarker: Text[20];
        CapturedExpenseNo: Code[20];
        CapturedPostedExpenseReportNo: Code[20];
        CapturedPreviewMode: Boolean;
        CapturedBaseRate: Decimal;
        PerDiemAmountOverride: Decimal;
        CopyExpenseFieldsCount: Integer;
        BeforePostGenJnlLineCount: Integer;
        CopyFromGenJnlLineCount: Integer;
        CopyFromPostedLineCount: Integer;
        BeforePostExpenseReportCount: Integer;
        AfterPostExpenseReportCount: Integer;
        PerDiemCalculationCount: Integer;

    procedure SetMarkerText(NewMarkerText: Text[20])
    begin
        MarkerText := NewMarkerText;
    end;

    procedure SetGenJnlLineDescriptionMarker(NewMarkerText: Text[20])
    begin
        GenJnlLineDescriptionMarker := NewMarkerText;
    end;

    procedure SetPerDiemAmountOverride(NewPerDiemAmount: Decimal)
    begin
        PerDiemAmountOverride := NewPerDiemAmount;
    end;

    procedure GetCapturedExpenseNo(): Code[20]
    begin
        exit(CapturedExpenseNo);
    end;

    procedure GetCapturedPostedExpenseReportNo(): Code[20]
    begin
        exit(CapturedPostedExpenseReportNo);
    end;

    procedure GetCapturedPreviewMode(): Boolean
    begin
        exit(CapturedPreviewMode);
    end;

    procedure GetCapturedBaseRate(): Decimal
    begin
        exit(CapturedBaseRate);
    end;

    procedure GetCopyExpenseFieldsCount(): Integer
    begin
        exit(CopyExpenseFieldsCount);
    end;

    procedure GetBeforePostGenJnlLineCount(): Integer
    begin
        exit(BeforePostGenJnlLineCount);
    end;

    procedure GetCopyFromGenJnlLineCount(): Integer
    begin
        exit(CopyFromGenJnlLineCount);
    end;

    procedure GetCopyFromPostedLineCount(): Integer
    begin
        exit(CopyFromPostedLineCount);
    end;

    procedure GetBeforePostExpenseReportCount(): Integer
    begin
        exit(BeforePostExpenseReportCount);
    end;

    procedure GetAfterPostExpenseReportCount(): Integer
    begin
        exit(AfterPostExpenseReportCount);
    end;

    procedure GetPerDiemCalculationCount(): Integer
    begin
        exit(PerDiemCalculationCount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Report", 'OnAfterCopyExpenseFieldsToReportLine', '', false, false)]
    local procedure HandleOnAfterCopyExpenseFieldsToReportLine(Expense: Record Expense; var ExpenseReportLine: Record "Expense Report Line")
    begin
        CopyExpenseFieldsCount += 1;
        CapturedExpenseNo := Expense."No.";
        if MarkerText <> '' then
            ExpenseReportLine.Description := MarkerText;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Expense Report-Post", 'OnBeforePostExpenseGenJournalLine', '', false, false)]
    local procedure HandleOnBeforePostExpenseGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line")
    begin
        BeforePostGenJnlLineCount += 1;
        if MarkerText <> '' then
            GenJournalLine."External Document No." := MarkerText;
        if GenJnlLineDescriptionMarker <> '' then
            GenJournalLine.Description := GenJnlLineDescriptionMarker;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Ledger Entry", 'OnAfterCopyFromGenJnlLine', '', false, false)]
    local procedure HandleOnAfterCopyFromGenJnlLine(var ExpenseLedgerEntry: Record "Expense Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
        CopyFromGenJnlLineCount += 1;
        if MarkerText <> '' then
            ExpenseLedgerEntry.Description := MarkerText;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Ledger Entry", 'OnAfterCopyFromPostedExpenseReportLine', '', false, false)]
    local procedure HandleOnAfterCopyFromPostedExpenseReportLine(var ExpenseLedgerEntry: Record "Expense Ledger Entry"; PostedExpenseReportLine: Record "Posted Expense Report Line")
    begin
        CopyFromPostedLineCount += 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Expense Report-Post", 'OnBeforePostExpenseReport', '', false, false)]
    local procedure HandleOnBeforePostExpenseReport(var ExpenseReportHeader: Record "Expense Report Header")
    begin
        BeforePostExpenseReportCount += 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Expense Report-Post", 'OnAfterPostExpenseReport', '', false, false)]
    local procedure HandleOnAfterPostExpenseReport(ExpenseReportHeader: Record "Expense Report Header"; PostedExpenseReportHeader: Record "Posted Expense Report Header"; PreviewMode: Boolean)
    begin
        AfterPostExpenseReportCount += 1;
        CapturedPostedExpenseReportNo := PostedExpenseReportHeader."No.";
        CapturedPreviewMode := PreviewMode;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Expense Per Diem Calculation", 'OnAfterCalculatePerDiemForSingleDay', '', false, false)]
    local procedure HandleOnAfterCalculatePerDiemForSingleDay(CurrentDate: Date; BaseRate: Decimal; TripStartDateTime: DateTime; TripEndDateTime: DateTime; ExpenseAgentSetup: Record "Expense Agent Setup"; var PerDiemAmount: Decimal)
    begin
        PerDiemCalculationCount += 1;
        CapturedBaseRate := BaseRate;
        PerDiemAmount := PerDiemAmountOverride;
    end;
}
