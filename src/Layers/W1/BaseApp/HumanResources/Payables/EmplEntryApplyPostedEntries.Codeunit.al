// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;

codeunit 224 "EmplEntry-Apply Posted Entries"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Employee Ledger Entry" = rimd,
                  TableData "Detailed Employee Ledger Entry" = rimd;
    TableNo = "Employee Ledger Entry";

    trigger OnRun()
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(PreviewMode);
        if PreviewMode then
            case RunOptionPreviewContext of
                RunOptionPreview::Apply:
                    Apply(Rec, ApplyUnapplyParametersContext);
                RunOptionPreview::Unapply:
                    PostUnApplyEmployee(DetailedEmployeeLedgEntryPreviewContext, ApplyUnapplyParametersContext);
            end
        else begin
            Clear(ApplyUnapplyParameters);
            GLSetup.GetRecordOnce();
            if GLSetup."Journal Templ. Name Mandatory" then begin
                GLSetup.TestField("Apply Jnl. Template Name");
                GLSetup.TestField("Apply Jnl. Batch Name");
                ApplyUnapplyParameters."Journal Template Name" := GLSetup."Apply Jnl. Template Name";
                ApplyUnapplyParameters."Journal Batch Name" := GLSetup."Apply Jnl. Batch Name";
                GenJnlBatch.Get(GLSetup."Apply Jnl. Template Name", GLSetup."Apply Jnl. Batch Name");
            end;
            ApplyUnapplyParameters."Document No." := Rec."Document No.";

            Apply(Rec, ApplyUnapplyParameters);
        end;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        DetailedEmployeeLedgEntryPreviewContext: Record "Detailed Employee Ledger Entry";
        ApplyUnapplyParametersContext: Record "Apply Unapply Parameters";
        RunOptionPreview: Option Apply,Unapply;
        RunOptionPreviewContext: Option Apply,Unapply;
        PreviewMode: Boolean;

        PostingApplicationMsg: Label 'Posting application...';
        MustNotBeBeforeErr: Label 'The posting date entered must not be before the posting date on the employee ledger entry.';
        NoEntriesAppliedErr: Label 'Cannot post because you did not specify which entry to apply. You must specify an entry in the Applies-to ID field for one or more open entries.', Comment = '%1 - Caption of "Applies to ID" field of Gen. Journal Line';
        UnapplyPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries that were posted after this entry.';
        NoApplicationEntryErr: Label 'Employee ledger entry number %1 does not have an application entry.', Comment = '%1 - arbitrary text, the identifier of the ledger entry';
        UnapplyingMsg: Label 'Unapplying and posting...';
        UnapplyAllPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries in employee ledger entry number %1 that were posted after this entry.', Comment = '%1 - arbitrary text, the identifier of the ledger entry';
        NotAllowedPostingDatesErr: Label 'Posting date is not within the range of allowed posting dates.';
        LatestEntryMustBeApplicationErr: Label 'The latest transaction number must be an application in employee ledger entry number %1.', Comment = '%1 - arbitrary text, the identifier of the ledger entry';
        CannotUnapplyExchRateErr: Label 'You cannot unapply the entry with the posting date %1, because the exchange rate for the additional reporting currency has been changed.', Comment = '%1 - a date';
        CannotApplyClosedEntriesErr: Label 'One or more of the entries that you selected is closed. You cannot apply closed entries.';
        CannotUnapplyInReversalErr: Label 'You cannot unapply Employee Ledger Entry No. %1 because the entry is part of a reversal.', Comment = '%1 - arbitrary text, the identifier of the ledger entry';

    procedure Apply(EmplLedgEntry: Record "Employee Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        OnBeforeApply(EmplLedgEntry, ApplyUnapplyParameters."Document No.", ApplyUnapplyParameters."Posting Date");

        EmplLedgEntry.Get(EmplLedgEntry."Entry No.");

        if ApplyUnapplyParameters."Posting Date" = 0D then
            ApplyUnapplyParameters."Posting Date" := GetApplicationDate(EmplLedgEntry)
        else
            if ApplyUnapplyParameters."Posting Date" < GetApplicationDate(EmplLedgEntry) then
                Error(MustNotBeBeforeErr);

        if ApplyUnapplyParameters."Document No." = '' then
            ApplyUnapplyParameters."Document No." := EmplLedgEntry."Document No.";

        EmplPostApplyEmplLedgEntry(EmplLedgEntry, ApplyUnapplyParameters);
    end;

    procedure GetApplicationDate(EmplLedgEntry: Record "Employee Ledger Entry") ApplicationDate: Date
    var
        ApplyToEmplLedgEntry: Record "Employee Ledger Entry";
    begin
        ApplicationDate := 0D;
        ApplyToEmplLedgEntry.SetCurrentKey("Employee No.", "Applies-to ID");
        ApplyToEmplLedgEntry.SetRange("Employee No.", EmplLedgEntry."Employee No.");
        ApplyToEmplLedgEntry.SetRange("Applies-to ID", EmplLedgEntry."Applies-to ID");
        ApplyToEmplLedgEntry.Find('-');
        repeat
            if ApplyToEmplLedgEntry."Posting Date" > ApplicationDate then
                ApplicationDate := ApplyToEmplLedgEntry."Posting Date";
        until ApplyToEmplLedgEntry.Next() = 0;
    end;

    local procedure EmplPostApplyEmplLedgEntry(EmplLedgEntry: Record "Employee Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    var
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        EntryNoBeforeApplication: Integer;
        EntryNoAfterApplication: Integer;
    begin
        Window.Open(PostingApplicationMsg);

        SourceCodeSetup.Get();

        GenJnlLine.Init();
        GenJnlLine."Document No." := ApplyUnapplyParameters."Document No.";
        GenJnlLine."Posting Date" := ApplyUnapplyParameters."Posting Date";
        GenJnlLine."VAT Reporting Date" := GenJnlLine."Posting Date";
        GenJnlLine."Document Date" := GenJnlLine."Posting Date";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Employee;
        GenJnlLine."Account No." := EmplLedgEntry."Employee No.";
        EmplLedgEntry.CalcFields("Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
        GenJnlLine.Correction :=
            (EmplLedgEntry."Debit Amount" < 0) or (EmplLedgEntry."Credit Amount" < 0) or
            (EmplLedgEntry."Debit Amount (LCY)" < 0) or (EmplLedgEntry."Credit Amount (LCY)" < 0);
        GenJnlLine."Document Type" := EmplLedgEntry."Document Type";
        GenJnlLine.Description := EmplLedgEntry.Description;
        GenJnlLine."Shortcut Dimension 1 Code" := EmplLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := EmplLedgEntry."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := EmplLedgEntry."Dimension Set ID";
        GenJnlLine."Posting Group" := EmplLedgEntry."Employee Posting Group";
        GenJnlLine."Source No." := EmplLedgEntry."Employee No.";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Employee;
        GenJnlLine."Source Code" := SourceCodeSetup."Employee Entry Application";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Journal Template Name" := ApplyUnapplyParameters."Journal Template Name";
        GenJnlLine."Journal Batch Name" := ApplyUnapplyParameters."Journal Batch Name";

        EntryNoBeforeApplication := FindLastApplDtldEmplLedgEntry();

        OnEmplPostApplyEmplLedgEntryOnBeforeGenJnlPostLine(GenJnlLine, EmplLedgEntry);
        GenJnlPostLine.EmplPostApplyEmplLedgEntry(GenJnlLine, EmplLedgEntry);

        EntryNoAfterApplication := FindLastApplDtldEmplLedgEntry();
        if EntryNoAfterApplication = EntryNoBeforeApplication then
            Error(NoEntriesAppliedErr);

        if PreviewMode then
            GenJnlPostPreview.ThrowError();

        Commit();
        Window.Close();
        UpdateAnalysisView.UpdateAll(0, true);
    end;

    local procedure FindLastApplDtldEmplLedgEntry(): Integer
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        DtldEmplLedgEntry.LockTable();
        exit(DtldEmplLedgEntry.GetLastEntryNo());
    end;

    procedure FindLastApplEntry(EmplLedgEntryNo: Integer): Integer
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        ApplicationEntryNo: Integer;
    begin
        DtldEmplLedgEntry.SetCurrentKey("Employee Ledger Entry No.", "Entry Type");
        DtldEmplLedgEntry.SetRange("Employee Ledger Entry No.", EmplLedgEntryNo);
        DtldEmplLedgEntry.SetRange("Entry Type", DtldEmplLedgEntry."Entry Type"::Application);
        DtldEmplLedgEntry.SetRange(Unapplied, false);
        ApplicationEntryNo := 0;
        if DtldEmplLedgEntry.Find('-') then
            repeat
                if DtldEmplLedgEntry."Entry No." > ApplicationEntryNo then
                    ApplicationEntryNo := DtldEmplLedgEntry."Entry No.";
            until DtldEmplLedgEntry.Next() = 0;
        exit(ApplicationEntryNo);
    end;

    local procedure FindLastTransactionNo(EmplLedgEntryNo: Integer): Integer
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        LastTransactionNo: Integer;
    begin
        DtldEmplLedgEntry.SetCurrentKey("Employee Ledger Entry No.", "Entry Type");
        DtldEmplLedgEntry.SetRange("Employee Ledger Entry No.", EmplLedgEntryNo);
        DtldEmplLedgEntry.SetRange(Unapplied, false);
        DtldEmplLedgEntry.SetFilter(
            "Entry Type", '<>%1&<>%2',
            DtldEmplLedgEntry."Entry Type"::"Unrealized Loss", DtldEmplLedgEntry."Entry Type"::"Unrealized Gain");
        OnFindLastTransactionNoOnAfterSetFilters(DtldEmplLedgEntry);
        LastTransactionNo := 0;
        if DtldEmplLedgEntry.FindSet() then
            repeat
                if LastTransactionNo < DtldEmplLedgEntry."Transaction No." then
                    LastTransactionNo := DtldEmplLedgEntry."Transaction No.";
            until DtldEmplLedgEntry.Next() = 0;
        exit(LastTransactionNo);
    end;

    procedure UnApplyDtldEmplLedgEntry(DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry")
    var
        ApplicationEntryNo: Integer;
    begin
        DtldEmplLedgEntry.TestField("Entry Type", DtldEmplLedgEntry."Entry Type"::Application);
        DtldEmplLedgEntry.TestField(Unapplied, false);
        ApplicationEntryNo := FindLastApplEntry(DtldEmplLedgEntry."Employee Ledger Entry No.");

        if DtldEmplLedgEntry."Entry No." <> ApplicationEntryNo then
            Error(UnapplyPostedAfterThisEntryErr);
        UnApplyEmployee(DtldEmplLedgEntry);
    end;

    procedure UnApplyEmplLedgEntry(EmplLedgEntryNo: Integer)
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        CheckEmployeeLedgerEntryToUnapply(EmplLedgEntryNo, DtldEmplLedgEntry);
        UnApplyEmployee(DtldEmplLedgEntry);
    end;

    procedure CheckEmployeeLedgerEntryToUnapply(EmployeeLedgerEntryNo: Integer; var DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    var
        ApplicationEntryNo: Integer;
    begin
        CheckReversal(EmployeeLedgerEntryNo);
        ApplicationEntryNo := FindLastApplEntry(EmployeeLedgerEntryNo);
        if ApplicationEntryNo = 0 then
            Error(NoApplicationEntryErr, EmployeeLedgerEntryNo);
        DetailedEmployeeLedgerEntry.Get(ApplicationEntryNo);
    end;

    local procedure UnApplyEmployee(DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry")
    var
        UnapplyEmplEntries: Page "Unapply Employee Entries";
    begin
        if DtldEmplLedgEntry."Applied Empl. Ledger Entry No." <> DtldEmplLedgEntry."Employee Ledger Entry No." then
            DtldEmplLedgEntry.Get(FindLastApplEntry(DtldEmplLedgEntry."Applied Empl. Ledger Entry No."));
        DtldEmplLedgEntry.TestField("Entry Type", DtldEmplLedgEntry."Entry Type"::Application);
        DtldEmplLedgEntry.TestField(Unapplied, false);
        UnapplyEmplEntries.SetDtldEmplLedgEntry(DtldEmplLedgEntry."Entry No.");
        UnapplyEmplEntries.LookupMode(true);
        UnapplyEmplEntries.RunModal();
    end;

    procedure PostUnApplyEmployee(DtldEmplLedgEntry2: Record "Detailed Employee Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    var
        GLEntry: Record "G/L Entry";
        EmplLedgEntry: Record "Employee Ledger Entry";
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        DateComprReg: Record "Date Compr. Register";
        TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        LastTransactionNo: Integer;
        AddCurrChecked: Boolean;
        MaxPostingDate: Date;
    begin
        MaxPostingDate := 0D;
        GLEntry.LockTable();
        DtldEmplLedgEntry.LockTable();
        EmplLedgEntry.LockTable();
        EmplLedgEntry.Get(DtldEmplLedgEntry2."Employee Ledger Entry No.");
        OnPostUnApplyEmployeeOnAfterGetEmplLedgEntry(DtldEmplLedgEntry2, EmplLedgEntry);
        if GenJnlBatch.Get(EmplLedgEntry."Journal Templ. Name", EmplLedgEntry."Journal Batch Name") then;
        CheckPostingDate(ApplyUnapplyParameters, MaxPostingDate);
        if ApplyUnapplyParameters."Posting Date" < DtldEmplLedgEntry2."Posting Date" then
            Error(MustNotBeBeforeErr);
        if DtldEmplLedgEntry2."Transaction No." = 0 then begin
            DtldEmplLedgEntry.SetCurrentKey("Application No.", "Employee No.", "Entry Type");
            DtldEmplLedgEntry.SetRange("Application No.", DtldEmplLedgEntry2."Application No.");
        end else begin
            DtldEmplLedgEntry.SetCurrentKey("Transaction No.", "Employee No.", "Entry Type");
            DtldEmplLedgEntry.SetRange("Transaction No.", DtldEmplLedgEntry2."Transaction No.");
        end;
        DtldEmplLedgEntry.SetRange("Employee No.", DtldEmplLedgEntry2."Employee No.");
        DtldEmplLedgEntry.SetFilter("Entry Type", '<>%1', DtldEmplLedgEntry."Entry Type"::"Initial Entry");
        DtldEmplLedgEntry.SetRange(Unapplied, false);
        if DtldEmplLedgEntry.Find('-') then
            repeat
                if not AddCurrChecked then begin
                    CheckAdditionalCurrency(ApplyUnapplyParameters."Posting Date", DtldEmplLedgEntry."Posting Date");
                    AddCurrChecked := true;
                end;
                CheckReversal(DtldEmplLedgEntry."Employee Ledger Entry No.");
                if DtldEmplLedgEntry."Transaction No." <> 0 then begin
                    if DtldEmplLedgEntry."Entry Type" = DtldEmplLedgEntry."Entry Type"::Application then begin
                        LastTransactionNo :=
                          FindLastApplTransactionEntry(DtldEmplLedgEntry."Employee Ledger Entry No.");
                        if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldEmplLedgEntry."Transaction No.") then
                            Error(UnapplyAllPostedAfterThisEntryErr, DtldEmplLedgEntry."Employee Ledger Entry No.");
                    end;
                    LastTransactionNo := FindLastTransactionNo(DtldEmplLedgEntry."Employee Ledger Entry No.");
                    if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldEmplLedgEntry."Transaction No.") then
                        Error(LatestEntryMustBeApplicationErr, DtldEmplLedgEntry."Employee Ledger Entry No.");
                end;
            until DtldEmplLedgEntry.Next() = 0;

        DateComprReg.CheckMaxDateCompressed(MaxPostingDate, 0);
        OnPostUnApplyEmployeeOnAfterCheckMaxDateCompressed(DtldEmplLedgEntry2);

        SourceCodeSetup.Get();
        EmplLedgEntry.Get(DtldEmplLedgEntry2."Employee Ledger Entry No.");
        GenJnlLine."Document No." := ApplyUnapplyParameters."Document No.";
        GenJnlLine."Posting Date" := ApplyUnapplyParameters."Posting Date";
        GenJnlLine."VAT Reporting Date" := GenJnlLine."Posting Date";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Employee;
        GenJnlLine."Account No." := DtldEmplLedgEntry2."Employee No.";
        GenJnlLine.Correction := true;
        GenJnlLine."Document Type" := EmplLedgEntry."Document Type";
        GenJnlLine.Description := EmplLedgEntry.Description;
        GenJnlLine."Dimension Set ID" := EmplLedgEntry."Dimension Set ID";
        GenJnlLine."Shortcut Dimension 1 Code" := EmplLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := EmplLedgEntry."Global Dimension 2 Code";
        GenJnlLine."Source Type" := GenJnlLine."Source Type"::Employee;
        GenJnlLine."Source No." := EmplLedgEntry."Employee No.";
        GenJnlLine."Source Code" := SourceCodeSetup."Unapplied Empl. Entry Appln.";
        GenJnlLine."Posting Group" := EmplLedgEntry."Employee Posting Group";
        GenJnlLine."Source Currency Code" := DtldEmplLedgEntry2."Currency Code";
        GenJnlLine."System-Created Entry" := true;
        Window.Open(UnapplyingMsg);

        OnPostUnApplyEmployeeOnBeforeGenJnlPostLineUnapplyEmplLedgEntry(GenJnlLine, EmplLedgEntry, DtldEmplLedgEntry2, GenJnlPostLine);
        CollectAffectedLedgerEntries(TempEmployeeLedgerEntry, DtldEmplLedgEntry2);
        GenJnlPostLine.UnapplyEmplLedgEntry(GenJnlLine, DtldEmplLedgEntry2);
        RunEmployeeExchRateAdjustment(GenJnlLine, TempEmployeeLedgerEntry);

        OnPostUnApplyEmployeeOnAfterRunEmployeeExchRateAdjustment(GenJnlLine, EmplLedgEntry, DtldEmplLedgEntry2, GenJnlPostLine, TempEmployeeLedgerEntry);

        if PreviewMode then
            GenJnlPostPreview.ThrowError();

        Commit();
        Window.Close();
    end;

    local procedure RunEmployeeExchRateAdjustment(var GenJnlLine: Record "Gen. Journal Line"; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary)
    var
        ExchRateAdjmtRunHandler: Codeunit "Exch. Rate Adjmt. Run Handler";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunEmplExchRateAdjustment(GenJnlLine, TempEmployeeLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        ExchRateAdjmtRunHandler.RunEmplExchRateAdjustment(GenJnlLine, TempEmployeeLedgerEntry);
    end;

    local procedure CheckPostingDate(ApplyUnapplyParameters: Record "Apply Unapply Parameters"; var MaxPostingDate: Date)
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        GenJnlCheckLine.SetGenJnlBatch(GenJnlBatch);
        if GenJnlCheckLine.DateNotAllowed(ApplyUnapplyParameters."Posting Date") then
            Error(NotAllowedPostingDatesErr);

        if ApplyUnapplyParameters."Posting Date" > MaxPostingDate then
            MaxPostingDate := ApplyUnapplyParameters."Posting Date";
    end;

    local procedure CheckAdditionalCurrency(OldPostingDate: Date; NewPostingDate: Date)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if OldPostingDate = NewPostingDate then
            exit;
        GLSetup.GetRecordOnce();
        if GLSetup."Additional Reporting Currency" <> '' then
            if CurrExchRate.ExchangeRate(OldPostingDate, GLSetup."Additional Reporting Currency") <>
               CurrExchRate.ExchangeRate(NewPostingDate, GLSetup."Additional Reporting Currency")
            then
                Error(CannotUnapplyExchRateErr, NewPostingDate);
    end;

    local procedure CheckReversal(EmplLedgEntryNo: Integer)
    var
        VendLedgEntry: Record "Employee Ledger Entry";
    begin
        VendLedgEntry.Get(EmplLedgEntryNo);
        if VendLedgEntry.Reversed then
            Error(CannotUnapplyInReversalErr, EmplLedgEntryNo);
    end;

    procedure ApplyEmplEntryFormEntry(var ApplyingEmplLedgEntry: Record "Employee Ledger Entry")
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
        ApplyEmplEntries: Page "Apply Employee Entries";
        EmplEntryApplID: Code[50];
    begin
        if not ApplyingEmplLedgEntry.Open then
            Error(CannotApplyClosedEntriesErr);

        EmplEntryApplID := CopyStr(UserId(), 1, 50);
        if EmplEntryApplID = '' then
            EmplEntryApplID := '***';
        if ApplyingEmplLedgEntry."Remaining Amount" = 0 then
            ApplyingEmplLedgEntry.CalcFields("Remaining Amount");

        ApplyingEmplLedgEntry."Applying Entry" := true;
        if ApplyingEmplLedgEntry."Applies-to ID" = '' then
            ApplyingEmplLedgEntry."Applies-to ID" := EmplEntryApplID;
        ApplyingEmplLedgEntry."Amount to Apply" := ApplyingEmplLedgEntry."Remaining Amount";
        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", ApplyingEmplLedgEntry);
        Commit();

        EmplLedgEntry.SetCurrentKey("Employee No.", Open, Positive);
        EmplLedgEntry.SetRange("Employee No.", ApplyingEmplLedgEntry."Employee No.");
        EmplLedgEntry.SetRange(Open, true);
        if EmplLedgEntry.FindFirst() then begin
            ApplyEmplEntries.SetEmplLedgEntry(ApplyingEmplLedgEntry);
            ApplyEmplEntries.SetRecord(EmplLedgEntry);
            ApplyEmplEntries.SetTableView(EmplLedgEntry);
            if ApplyingEmplLedgEntry."Applies-to ID" <> EmplEntryApplID then
                ApplyEmplEntries.SetAppliesToID(ApplyingEmplLedgEntry."Applies-to ID");
            ApplyEmplEntries.RunModal();
            Clear(ApplyEmplEntries);
            ApplyingEmplLedgEntry."Applying Entry" := false;
            ApplyingEmplLedgEntry."Applies-to ID" := '';
            ApplyingEmplLedgEntry."Amount to Apply" := 0;
        end;
    end;

    local procedure FindLastApplTransactionEntry(EmplLedgEntryNo: Integer): Integer
    var
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        LastTransactionNo: Integer;
    begin
        DtldEmplLedgEntry.SetCurrentKey("Employee Ledger Entry No.", "Entry Type");
        DtldEmplLedgEntry.SetRange("Employee Ledger Entry No.", EmplLedgEntryNo);
        DtldEmplLedgEntry.SetRange("Entry Type", DtldEmplLedgEntry."Entry Type"::Application);
        LastTransactionNo := 0;
        if DtldEmplLedgEntry.Find('-') then
            repeat
                if (DtldEmplLedgEntry."Transaction No." > LastTransactionNo) and not DtldEmplLedgEntry.Unapplied then
                    LastTransactionNo := DtldEmplLedgEntry."Transaction No.";
            until DtldEmplLedgEntry.Next() = 0;
        exit(LastTransactionNo);
    end;

    local procedure CollectAffectedLedgerEntries(var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary; DetailedVendorLedgEntry2: Record "Detailed Employee Ledger Entry")
    var
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        TempEmployeeLedgerEntry.DeleteAll();

        if DetailedVendorLedgEntry2."Transaction No." = 0 then begin
            DetailedEmployeeLedgEntry.SetCurrentKey("Application No.", "Employee No.", "Entry Type");
            DetailedEmployeeLedgEntry.SetRange("Application No.", DetailedVendorLedgEntry2."Application No.");
        end else begin
            DetailedEmployeeLedgEntry.SetCurrentKey("Transaction No.", "Employee No.", "Entry Type");
            DetailedEmployeeLedgEntry.SetRange("Transaction No.", DetailedVendorLedgEntry2."Transaction No.");
        end;
        DetailedEmployeeLedgEntry.SetRange("Employee No.", DetailedVendorLedgEntry2."Employee No.");
        DetailedEmployeeLedgEntry.SetFilter("Entry Type", '<>%1', DetailedEmployeeLedgEntry."Entry Type"::"Initial Entry");
        DetailedEmployeeLedgEntry.SetRange(Unapplied, false);
        OnCollectAffectedLedgerEntriesOnAfterSetFilters(DetailedEmployeeLedgEntry, DetailedVendorLedgEntry2);
        if DetailedEmployeeLedgEntry.FindSet() then
            repeat
                TempEmployeeLedgerEntry."Entry No." := DetailedEmployeeLedgEntry."Employee Ledger Entry No.";
                if TempEmployeeLedgerEntry.Insert() then;
            until DetailedEmployeeLedgEntry.Next() = 0;
    end;

    procedure PreviewApply(EmployeeLedgerEntry: Record "Employee Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
    begin
        BindSubscription(EmplEntryApplyPostedEntries);
        EmplEntryApplyPostedEntries.SetApplyContext(ApplyUnapplyParameters);
        GenJnlPostPreview.Preview(EmplEntryApplyPostedEntries, EmployeeLedgerEntry);
    end;

    procedure PreviewUnapply(DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
    begin
        BindSubscription(EmplEntryApplyPostedEntries);
        EmplEntryApplyPostedEntries.SetUnapplyContext(DetailedEmployeeLedgEntry, ApplyUnapplyParameters);
        GenJnlPostPreview.Preview(EmplEntryApplyPostedEntries, EmployeeLedgerEntry);
    end;

    procedure SetApplyContext(ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        ApplyUnapplyParametersContext := ApplyUnapplyParameters;
        RunOptionPreviewContext := RunOptionPreview::Apply;
    end;

    procedure SetUnapplyContext(var DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        ApplyUnapplyParametersContext := ApplyUnapplyParameters;
        DetailedEmployeeLedgEntryPreviewContext := DetailedEmployeeLedgEntry;
        RunOptionPreviewContext := RunOptionPreview::Unapply;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
    begin
        EmplEntryApplyPostedEntries := Subscriber;
        PreviewMode := true;
        Result := EmplEntryApplyPostedEntries.Run(RecVar);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApply(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var DocumentNo: Code[20]; var ApplicationDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEmplPostApplyEmplLedgEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyEmployeeOnAfterCheckMaxDateCompressed(var DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyEmployeeOnAfterGetEmplLedgEntry(var DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyEmployeeOnBeforeGenJnlPostLineUnapplyEmplLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; EmplLedgerEntry: Record "Employee Ledger Entry"; DetailedEmplLedgEntry: Record "Detailed Employee Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindLastTransactionNoOnAfterSetFilters(var DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectAffectedLedgerEntriesOnAfterSetFilters(var DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"; DetailedEmployeeLedgEntry2: Record "Detailed Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunEmplExchRateAdjustment(var GenJnlLine: Record "Gen. Journal Line"; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyEmployeeOnAfterRunEmployeeExchRateAdjustment(GenJournalLine: Record "Gen. Journal Line"; EmplLedgerEntry: Record "employee Ledger Entry"; DetailedEmplLedgEntry: Record "Detailed Employee Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var TempEmplLedgerEntry: Record "Employee Ledger Entry" temporary)
    begin
    end;
}
