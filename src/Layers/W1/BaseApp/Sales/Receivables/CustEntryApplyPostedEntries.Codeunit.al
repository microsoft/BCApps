// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

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

/// <summary>
/// Processes the application and unapplication of posted customer ledger entries, enabling payment matching and reversal operations.
/// </summary>
codeunit 226 "CustEntry-Apply Posted Entries"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    TableNo = "Cust. Ledger Entry";

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
                    PostUnApplyCustomer(DetailedCustLedgEntryPreviewContext, ApplyUnapplyParametersContext);
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
        DetailedCustLedgEntryPreviewContext: Record "Detailed Cust. Ledg. Entry";
        ApplyUnapplyParametersContext: Record "Apply Unapply Parameters";
        RunOptionPreview: Option Apply,Unapply;
        RunOptionPreviewContext: Option Apply,Unapply;
        PreviewMode: Boolean;

        PostingApplicationMsg: Label 'Posting application...';
        MustNotBeBeforeErr: Label 'The posting date entered must not be before the posting date on the Cust. Ledger Entry.';
        NoEntriesAppliedErr: Label 'Cannot post because you did not specify which entry to apply. You must specify an entry in the %1 field for one or more open entries.', Comment = '%1 - Caption of "Applies to ID" field of Gen. Journal Line';
        UnapplyPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries that were posted after this entry.';
#pragma warning disable AA0470
        NoApplicationEntryErr: Label 'Cust. Ledger Entry No. %1 does not have an application entry.';
#pragma warning restore AA0470
        UnapplyingMsg: Label 'Unapplying and posting...';
#pragma warning disable AA0470
        UnapplyAllPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries in Cust. Ledger Entry No. %1 that were posted after this entry.';
#pragma warning restore AA0470
        NotAllowedPostingDatesErr: Label 'Posting date is not within the range of allowed posting dates.';
#pragma warning disable AA0470
        LatestEntryMustBeApplicationErr: Label 'The latest Transaction No. must be an application in Cust. Ledger Entry No. %1.';
        CannotUnapplyExchRateErr: Label 'You cannot unapply the entry with the posting date %1, because the exchange rate for the additional reporting currency has been changed.';
        CannotUnapplyInReversalErr: Label 'You cannot unapply Cust. Ledger Entry No. %1 because the entry is part of a reversal.';
#pragma warning restore AA0470
        CannotApplyClosedEntriesErr: Label 'One or more of the entries that you selected is closed. You cannot apply closed entries.';

    /// <summary>
    /// Applies the customer ledger entry based on the specified application parameters.
    /// </summary>
    /// <param name="CustLedgEntry">Specifies the customer ledger entry to apply.</param>
    /// <param name="ApplyUnapplyParameters">Specifies the parameters for the application, including document number and posting date.</param>
    /// <returns>True if the application was successful; otherwise, false.</returns>
    procedure Apply(CustLedgEntry: Record "Cust. Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters"): Boolean
    var
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        IsHandled: Boolean;
    begin
        OnBeforeApply(CustLedgEntry, ApplyUnapplyParameters."Document No.", ApplyUnapplyParameters."Posting Date");

        IsHandled := false;
        OnApplyOnBeforePmtTolCust(CustLedgEntry, PaymentToleranceMgt, PreviewMode, IsHandled);
        if not IsHandled then
            if not PreviewMode then
                if not PaymentToleranceMgt.PmtTolCust(CustLedgEntry) then
                    exit(false);

        CustLedgEntry.Get(CustLedgEntry."Entry No.");

        if ApplyUnapplyParameters."Posting Date" = 0D then
            ApplyUnapplyParameters."Posting Date" := GetApplicationDate(CustLedgEntry)
        else
            if ApplyUnapplyParameters."Posting Date" < GetApplicationDate(CustLedgEntry) then
                Error(MustNotBeBeforeErr);

        if ApplyUnapplyParameters."Document No." = '' then
            ApplyUnapplyParameters."Document No." := CustLedgEntry."Document No.";

        OnApplyOnBeforeCustPostApplyCustLedgEntry(CustLedgEntry, ApplyUnapplyParameters);
        CustPostApplyCustLedgEntry(CustLedgEntry, ApplyUnapplyParameters);
        exit(true);
    end;

    /// <summary>
    /// Gets the latest posting date among all customer ledger entries with the same Applies-to ID.
    /// </summary>
    /// <param name="CustLedgEntry">Specifies the customer ledger entry used to find related entries by Applies-to ID.</param>
    /// <returns>The latest posting date of the entries to be applied.</returns>
    procedure GetApplicationDate(CustLedgEntry: Record "Cust. Ledger Entry") ApplicationDate: Date
    var
        ApplyToCustLedgEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetApplicationDate(CustLedgEntry, ApplicationDate, IsHandled);
        if IsHandled then
            exit(ApplicationDate);

        ApplicationDate := 0D;
        ApplyToCustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID");
        ApplyToCustLedgEntry.SetRange("Customer No.", CustLedgEntry."Customer No.");
        ApplyToCustLedgEntry.SetRange("Applies-to ID", CustLedgEntry."Applies-to ID");
        OnGetApplicationDateOnAfterSetFilters(ApplyToCustLedgEntry, CustLedgEntry);
        ApplyToCustLedgEntry.FindSet();
        repeat
            if ApplyToCustLedgEntry."Posting Date" > ApplicationDate then
                ApplicationDate := ApplyToCustLedgEntry."Posting Date";
        until ApplyToCustLedgEntry.Next() = 0;
    end;

    local procedure CustPostApplyCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    var
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        EntryNoBeforeApplication: Integer;
        EntryNoAfterApplication: Integer;
        HideProgressWindow: Boolean;
        SuppressCommit: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCustPostApplyCustLedgEntry(HideProgressWindow, CustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if not HideProgressWindow then
            Window.Open(PostingApplicationMsg);

        SourceCodeSetup.Get();

        GenJnlLine.Init();
        GenJnlLine."Document No." := ApplyUnapplyParameters."Document No.";
        GenJnlLine."Posting Date" := ApplyUnapplyParameters."Posting Date";
        GenJnlLine."VAT Reporting Date" := GenJnlLine."Posting Date";
        GenJnlLine."Document Date" := GenJnlLine."Posting Date";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := CustLedgEntry."Customer No.";
        CustLedgEntry.CalcFields("Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
        GenJnlLine.Correction :=
            (CustLedgEntry."Debit Amount" < 0) or (CustLedgEntry."Credit Amount" < 0) or
            (CustLedgEntry."Debit Amount (LCY)" < 0) or (CustLedgEntry."Credit Amount (LCY)" < 0);
        GenJnlLine.CopyCustLedgEntry(CustLedgEntry);
        GenJnlLine."Source Code" := SourceCodeSetup."Sales Entry Application";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Journal Template Name" := ApplyUnapplyParameters."Journal Template Name";
        GenJnlLine."Journal Batch Name" := ApplyUnapplyParameters."Journal Batch Name";

        EntryNoBeforeApplication := FindLastApplDtldCustLedgEntry();

        OnBeforePostApplyCustLedgEntry(GenJnlLine, CustLedgEntry, GenJnlPostLine, ApplyUnapplyParameters);
        GenJnlPostLine.CustPostApplyCustLedgEntry(GenJnlLine, CustLedgEntry);
        OnAfterPostApplyCustLedgEntry(GenJnlLine, CustLedgEntry, GenJnlPostLine);

        EntryNoAfterApplication := FindLastApplDtldCustLedgEntry();
        if EntryNoAfterApplication = EntryNoBeforeApplication then
            Error(NoEntriesAppliedErr, GenJnlLine.FieldCaption("Applies-to ID"));

        if PreviewMode then
            GenJnlPostPreview.ThrowError();

        SuppressCommit := false;
        OnCustPostApplyCustLedgEntryOnBeforeCommit(CustLedgEntry, SuppressCommit);
        if not SuppressCommit then
            Commit();
        if not HideProgressWindow then
            Window.Close();
        RunUpdateAnalysisView();
    end;

    local procedure RunUpdateAnalysisView()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunUpdateAnalysisView(IsHandled);
        if IsHandled then
            exit;

        UpdateAnalysisView.UpdateAll(0, true);
    end;

    local procedure FindLastApplDtldCustLedgEntry(): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.LockTable();
        exit(DtldCustLedgEntry.GetLastEntryNo());
    end;

    /// <summary>
    /// Finds the last application entry number for the specified customer ledger entry.
    /// </summary>
    /// <param name="CustLedgEntryNo">Specifies the customer ledger entry number to search for applications.</param>
    /// <returns>The entry number of the last application entry, or 0 if no application exists.</returns>
    procedure FindLastApplEntry(CustLedgEntryNo: Integer): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplicationEntryNo: Integer;
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetRange(Unapplied, false);
        OnFindLastApplEntryOnAfterSetFilters(DtldCustLedgEntry);
        ApplicationEntryNo := 0;
        if DtldCustLedgEntry.Find('-') then
            repeat
                if DtldCustLedgEntry."Entry No." > ApplicationEntryNo then
                    ApplicationEntryNo := DtldCustLedgEntry."Entry No.";
            until DtldCustLedgEntry.Next() = 0;
        exit(ApplicationEntryNo);
    end;

    local procedure FindLastTransactionNo(CustLedgEntryNo: Integer): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastTransactionNo: Integer;
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DtldCustLedgEntry.SetRange(Unapplied, false);
        DtldCustLedgEntry.SetFilter(
            "Entry Type", '<>%1&<>%2',
            DtldCustLedgEntry."Entry Type"::"Unrealized Loss", DtldCustLedgEntry."Entry Type"::"Unrealized Gain");
        LastTransactionNo := 0;
        if DtldCustLedgEntry.FindSet() then
            repeat
                if LastTransactionNo < DtldCustLedgEntry."Transaction No." then
                    LastTransactionNo := DtldCustLedgEntry."Transaction No.";
            until DtldCustLedgEntry.Next() = 0;
        exit(LastTransactionNo);
    end;

    /// <summary>
    /// Unapplies the specified detailed customer ledger entry if it is the last application entry.
    /// </summary>
    /// <param name="DtldCustLedgEntry">Specifies the detailed customer ledger entry to unapply.</param>
    procedure UnApplyDtldCustLedgEntry(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        ApplicationEntryNo: Integer;
    begin
        DtldCustLedgEntry.TestField("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.TestField(Unapplied, false);
        ApplicationEntryNo := FindLastApplEntry(DtldCustLedgEntry."Cust. Ledger Entry No.");

        if DtldCustLedgEntry."Entry No." <> ApplicationEntryNo then
            Error(UnapplyPostedAfterThisEntryErr);
        CheckReversal(DtldCustLedgEntry."Cust. Ledger Entry No.");
        UnApplyCustomer(DtldCustLedgEntry);
    end;

    /// <summary>
    /// Validates that the customer ledger entry can be unapplied and retrieves the last application entry.
    /// </summary>
    /// <param name="CustLedgEntryNo">Specifies the customer ledger entry number to check.</param>
    /// <param name="DetailedCustLedgEntry">Returns the detailed customer ledger entry containing the last application.</param>
    procedure CheckCustLedgEntryToUnapply(CustLedgEntryNo: Integer; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        ApplicationEntryNo: Integer;
    begin
        CheckReversal(CustLedgEntryNo);
        ApplicationEntryNo := FindLastApplEntry(CustLedgEntryNo);
        if ApplicationEntryNo = 0 then
            Error(NoApplicationEntryErr, CustLedgEntryNo);
        DetailedCustLedgEntry.Get(ApplicationEntryNo);
    end;


    /// <summary>
    /// Unapplies the customer ledger entry by its entry number.
    /// </summary>
    /// <param name="CustLedgEntryNo">Specifies the entry number of the customer ledger entry to unapply.</param>
    procedure UnApplyCustLedgEntry(CustLedgEntryNo: Integer)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        CheckCustLedgEntryToUnapply(CustLedgEntryNo, DtldCustLedgEntry);
        UnApplyCustomer(DtldCustLedgEntry);
    end;

    local procedure UnApplyCustomer(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        UnapplyCustEntries: Page "Unapply Customer Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUnApplyCustomer(DtldCustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        DtldCustLedgEntry.TestField("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.TestField(Unapplied, false);
        UnapplyCustEntries.SetDtldCustLedgEntry(DtldCustLedgEntry."Entry No.");
        UnapplyCustEntries.LookupMode(true);
        UnapplyCustEntries.RunModal();

        OnAfterUnApplyCustomer(DtldCustLedgEntry);
    end;

    /// <summary>
    /// Posts the unapplication of a customer ledger entry with automatic commit.
    /// </summary>
    /// <param name="DtldCustLedgEntry2">Specifies the detailed customer ledger entry to unapply.</param>
    /// <param name="ApplyUnapplyParameters">Specifies the parameters for the unapplication, including document number and posting date.</param>
    procedure PostUnApplyCustomer(DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        PostUnApplyCustomerCommit(DtldCustLedgEntry2, ApplyUnapplyParameters, true);
    end;

    /// <summary>
    /// Posts the unapplication of a customer ledger entry with optional commit control.
    /// </summary>
    /// <param name="DtldCustLedgEntry2">Specifies the detailed customer ledger entry to unapply.</param>
    /// <param name="ApplyUnapplyParameters">Specifies the parameters for the unapplication, including document number and posting date.</param>
    /// <param name="CommitChanges">Specifies whether to commit changes after posting the unapplication.</param>
    procedure PostUnApplyCustomerCommit(DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters"; CommitChanges: Boolean)
    var
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        DateComprReg: Record "Date Compr. Register";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        AddCurrChecked: Boolean;
        MaxPostingDate: Date;
        HideProgressWindow: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostUnApplyCustomerCommit(
            HideProgressWindow, PreviewMode, DtldCustLedgEntry2, ApplyUnapplyParameters."Document No.", ApplyUnapplyParameters."Posting Date",
            CommitChanges, IsHandled);
        if IsHandled then
            exit;

        MaxPostingDate := 0D;
        GLEntry.LockTable();
        DtldCustLedgEntry.LockTable();
        CustLedgEntry.LockTable();
        CustLedgEntry.Get(DtldCustLedgEntry2."Cust. Ledger Entry No.");
        OnPostUnApplyCustomerCommitOnAfterGetCustLedgEntry(CustLedgEntry);
        if GenJnlBatch.Get(CustLedgEntry."Journal Templ. Name", CustLedgEntry."Journal Batch Name") then;
        CheckPostingDate(ApplyUnapplyParameters, MaxPostingDate);
        if ApplyUnapplyParameters."Posting Date" < DtldCustLedgEntry2."Posting Date" then
            Error(MustNotBeBeforeErr);

        OnPostUnApplyCustomerCommitOnBeforeFilterDtldCustLedgEntry(DtldCustLedgEntry2, ApplyUnapplyParameters);
        if DtldCustLedgEntry2."Transaction No." = 0 then begin
            DtldCustLedgEntry.SetCurrentKey("Application No.", "Customer No.", "Entry Type");
            DtldCustLedgEntry.SetRange("Application No.", DtldCustLedgEntry2."Application No.");
        end else begin
            DtldCustLedgEntry.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
            DtldCustLedgEntry.SetRange("Transaction No.", DtldCustLedgEntry2."Transaction No.");
        end;
        DtldCustLedgEntry.SetRange("Customer No.", DtldCustLedgEntry2."Customer No.");
        DtldCustLedgEntry.SetFilter("Entry Type", '<>%1', DtldCustLedgEntry."Entry Type"::"Initial Entry");
        DtldCustLedgEntry.SetRange(Unapplied, false);
        OnPostUnApplyCustomerCommitOnAfterSetFilters(DtldCustLedgEntry, DtldCustLedgEntry2);
        if DtldCustLedgEntry.Find('-') then
            repeat
                if not AddCurrChecked then begin
                    CheckAdditionalCurrency(ApplyUnapplyParameters."Posting Date", DtldCustLedgEntry."Posting Date");
                    AddCurrChecked := true;
                end;
                CheckReversal(DtldCustLedgEntry."Cust. Ledger Entry No.");
                if DtldCustLedgEntry."Transaction No." <> 0 then
                    CheckUnappliedEntries(DtldCustLedgEntry);
            until DtldCustLedgEntry.Next() = 0;

        DateComprReg.CheckMaxDateCompressed(MaxPostingDate, 0);

        GLSetup.GetRecordOnce();
        SourceCodeSetup.Get();
        CustLedgEntry.Get(DtldCustLedgEntry2."Cust. Ledger Entry No.");
        GenJnlLine."Document No." := ApplyUnapplyParameters."Document No.";
        GenJnlLine."Posting Date" := ApplyUnapplyParameters."Posting Date";
        GenJnlLine."VAT Reporting Date" := GenJnlLine."Posting Date";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine."Account No." := DtldCustLedgEntry2."Customer No.";
        GenJnlLine.Correction := true;
        GenJnlLine.CopyCustLedgEntry(CustLedgEntry);
        GenJnlLine."Source Code" := SourceCodeSetup."Unapplied Sales Entry Appln.";
        GenJnlLine."Source Currency Code" := DtldCustLedgEntry2."Currency Code";
        GenJnlLine."System-Created Entry" := true;
        if GLSetup."Journal Templ. Name Mandatory" then begin
            GenJnlLine."Journal Template Name" := GLSetup."Apply Jnl. Template Name";
            GenJnlLine."Journal Batch Name" := GLSetup."Apply Jnl. Batch Name";
        end;
        if not HideProgressWindow then
            Window.Open(UnapplyingMsg);

        OnBeforePostUnapplyCustLedgEntry(GenJnlLine, CustLedgEntry, DtldCustLedgEntry2, GenJnlPostLine, ApplyUnapplyParameters);
        CollectAffectedLedgerEntries(TempCustLedgerEntry, DtldCustLedgEntry2);
        GenJnlPostLine.UnapplyCustLedgEntry(GenJnlLine, DtldCustLedgEntry2);
        RunCustExchRateAdjustment(GenJnlLine, TempCustLedgerEntry);
        OnAfterPostUnapplyCustLedgEntry(
            GenJnlLine, CustLedgEntry, DtldCustLedgEntry2, GenJnlPostLine, CommitChanges, TempCustLedgerEntry);

        if PreviewMode then
            GenJnlPostPreview.ThrowError();

        OnPostUnApplyCustomerCommitOnAfterPreviewMode(CustLedgEntry);

        if CommitChanges then
            Commit();
        if not HideProgressWindow then
            Window.Close();
    end;

    local procedure RunCustExchRateAdjustment(var GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    var
        ExchRateAdjmtRunHandler: Codeunit "Exch. Rate Adjmt. Run Handler";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCustExchRateAdjustment(GenJnlLine, TempCustLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        ExchRateAdjmtRunHandler.RunCustExchRateAdjustment(GenJnlLine, TempCustLedgerEntry);
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

    /// <summary>
    /// Checks whether the customer ledger entry is part of a reversal and raises an error if it is.
    /// </summary>
    /// <param name="CustLedgEntryNo">Specifies the customer ledger entry number to check for reversal status.</param>
    procedure CheckReversal(CustLedgEntryNo: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get(CustLedgEntryNo);
        if CustLedgEntry.Reversed then
            Error(CannotUnapplyInReversalErr, CustLedgEntryNo);
        OnAfterCheckReversal(CustLedgEntry);
    end;

    /// <summary>
    /// Opens the Apply Customer Entries page to allow the user to select entries for application.
    /// </summary>
    /// <param name="ApplyingCustLedgEntry">Specifies the customer ledger entry that is being applied to other entries.</param>
    procedure ApplyCustEntryFormEntry(var ApplyingCustLedgEntry: Record "Cust. Ledger Entry")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustEntryApplID: Code[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyCustEntryFormEntry(ApplyingCustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if not ApplyingCustLedgEntry.Open then
            Error(CannotApplyClosedEntriesErr);

        OnApplyCustEntryFormEntryOnAfterCheckEntryOpen(ApplyingCustLedgEntry);

        CustEntryApplID := UserId;
        if CustEntryApplID = '' then
            CustEntryApplID := '***';
        if ApplyingCustLedgEntry."Remaining Amount" = 0 then
            ApplyingCustLedgEntry.CalcFields("Remaining Amount");

        ApplyingCustLedgEntry."Applying Entry" := true;
        if ApplyingCustLedgEntry."Applies-to ID" = '' then
            ApplyingCustLedgEntry."Applies-to ID" := CustEntryApplID;
        ApplyingCustLedgEntry."Amount to Apply" := ApplyingCustLedgEntry."Remaining Amount";
        OnApplyCustEntryFormEntryOnBeforeRunCustEntryEdit(ApplyingCustLedgEntry);
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", ApplyingCustLedgEntry);
        Commit();

        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
        CustLedgEntry.SetRange("Customer No.", ApplyingCustLedgEntry."Customer No.");
        CustLedgEntry.SetRange(Open, true);
        RunApplyCustEntries(CustLedgEntry, ApplyingCustLedgEntry, CustEntryApplID);
    end;

    local procedure RunApplyCustEntries(var CustLedgEntry: Record "Cust. Ledger Entry"; var ApplyingCustLedgEntry: Record "Cust. Ledger Entry"; CustEntryApplID: Code[50])
    var
        ApplyCustEntries: Page "Apply Customer Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnApplyApplyCustEntryFormEntryOnAfterCustLedgEntrySetFilters(CustLedgEntry, ApplyingCustLedgEntry, IsHandled, CustEntryApplID);
        if IsHandled then
            exit;

        if CustLedgEntry.FindFirst() then begin
            ApplyCustEntries.SetCustLedgEntry(ApplyingCustLedgEntry);
            ApplyCustEntries.SetRecord(CustLedgEntry);
            ApplyCustEntries.SetTableView(CustLedgEntry);
            if ApplyingCustLedgEntry."Applies-to ID" <> CustEntryApplID then
                ApplyCustEntries.SetAppliesToID(ApplyingCustLedgEntry."Applies-to ID");
            ApplyCustEntries.RunModal();
            Clear(ApplyCustEntries);
            ApplyingCustLedgEntry."Applying Entry" := false;
            ApplyingCustLedgEntry."Applies-to ID" := '';
            ApplyingCustLedgEntry."Amount to Apply" := 0;
        end;
    end;

    local procedure CollectAffectedLedgerEntries(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        TempCustLedgerEntry.DeleteAll();

        if DetailedCustLedgEntry2."Transaction No." = 0 then begin
            DetailedCustLedgEntry.SetCurrentKey("Application No.", "Customer No.", "Entry Type");
            DetailedCustLedgEntry.SetRange("Application No.", DetailedCustLedgEntry2."Application No.");
        end else begin
            DetailedCustLedgEntry.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
            DetailedCustLedgEntry.SetRange("Transaction No.", DetailedCustLedgEntry2."Transaction No.");
        end;
        DetailedCustLedgEntry.SetRange("Customer No.", DetailedCustLedgEntry2."Customer No.");
        DetailedCustLedgEntry.SetFilter("Entry Type", '<>%1', DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        OnCollectAffectedLedgerEntriesOnAfterSetFilters(DetailedCustLedgEntry, DetailedCustLedgEntry2);
        if DetailedCustLedgEntry.FindSet() then
            repeat
                TempCustLedgerEntry."Entry No." := DetailedCustLedgEntry."Cust. Ledger Entry No.";
                if TempCustLedgerEntry.Insert() then;
            until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure FindLastApplTransactionEntry(CustLedgEntryNo: Integer): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastTransactionNo: Integer;
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        LastTransactionNo := 0;
        if DtldCustLedgEntry.Find('-') then
            repeat
                if (DtldCustLedgEntry."Transaction No." > LastTransactionNo) and not DtldCustLedgEntry.Unapplied then
                    LastTransactionNo := DtldCustLedgEntry."Transaction No.";
            until DtldCustLedgEntry.Next() = 0;
        exit(LastTransactionNo);
    end;

    /// <summary>
    /// Previews the application of a customer ledger entry without posting.
    /// </summary>
    /// <param name="CustLedgEntry">Specifies the customer ledger entry to preview the application for.</param>
    /// <param name="ApplyUnapplyParameters">Specifies the parameters for the application preview, including document number and posting date.</param>
    procedure PreviewApply(CustLedgEntry: Record "Cust. Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        if not PaymentToleranceMgt.PmtTolCust(CustLedgEntry) then
            exit;

        BindSubscription(CustEntryApplyPostedEntries);
        CustEntryApplyPostedEntries.SetApplyContext(ApplyUnapplyParameters);
        GenJnlPostPreview.Preview(CustEntryApplyPostedEntries, CustLedgEntry);
    end;

    /// <summary>
    /// Previews the unapplication of a detailed customer ledger entry without posting.
    /// </summary>
    /// <param name="DetailedCustLedgEntry">Specifies the detailed customer ledger entry to preview the unapplication for.</param>
    /// <param name="ApplyUnapplyParameters">Specifies the parameters for the unapplication preview, including document number and posting date.</param>
    procedure PreviewUnapply(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        BindSubscription(CustEntryApplyPostedEntries);
        CustEntryApplyPostedEntries.SetUnapplyContext(DetailedCustLedgEntry, ApplyUnapplyParameters);
        GenJnlPostPreview.Preview(CustEntryApplyPostedEntries, CustLedgEntry);
    end;

    /// <summary>
    /// Sets the context for an application preview operation.
    /// </summary>
    /// <param name="ApplyUnapplyParameters">Specifies the parameters to use for the application preview.</param>
    procedure SetApplyContext(ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        ApplyUnapplyParametersContext := ApplyUnapplyParameters;
        RunOptionPreviewContext := RunOptionPreview::Apply;
    end;

    /// <summary>
    /// Sets the context for an unapplication preview operation.
    /// </summary>
    /// <param name="DetailedCustLedgEntry">Specifies the detailed customer ledger entry for the unapplication preview.</param>
    /// <param name="ApplyUnapplyParameters">Specifies the parameters to use for the unapplication preview.</param>
    procedure SetUnapplyContext(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        ApplyUnapplyParametersContext := ApplyUnapplyParameters;
        DetailedCustLedgEntryPreviewContext := DetailedCustLedgEntry;
        RunOptionPreviewContext := RunOptionPreview::Unapply;
    end;

    /// <summary>
    /// Retrieves all customer ledger entries that have been applied to the specified entry.
    /// </summary>
    /// <param name="TempAppliedCustLedgerEntry">Returns a temporary table containing the applied customer ledger entries.</param>
    /// <param name="CustLedgerEntryNo">Specifies the customer ledger entry number to find applied entries for.</param>
    procedure GetAppliedCustLedgerEntries(var TempAppliedCustLedgerEntry: Record "Cust. Ledger Entry" temporary; CustLedgerEntryNo: Integer)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplnDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntryNo);
        DtldCustLedgEntry.SetFilter("Applied Cust. Ledger Entry No.", '<>%1', 0);
        DtldCustLedgEntry.SetRange(Unapplied, false);
        if DtldCustLedgEntry.FindSet() then
            repeat
                if DtldCustLedgEntry."Cust. Ledger Entry No." =
                   DtldCustLedgEntry."Applied Cust. Ledger Entry No."
                then begin
                    ApplnDtldCustLedgEntry.SetCurrentKey("Applied Cust. Ledger Entry No.", "Entry Type");
                    ApplnDtldCustLedgEntry.SetRange(
                        "Applied Cust. Ledger Entry No.", DtldCustLedgEntry."Applied Cust. Ledger Entry No.");
                    ApplnDtldCustLedgEntry.SetRange("Entry Type", ApplnDtldCustLedgEntry."Entry Type"::Application);
                    ApplnDtldCustLedgEntry.SetRange(Unapplied, false);
                    if ApplnDtldCustLedgEntry.FindSet() then
                        repeat
                            if ApplnDtldCustLedgEntry."Cust. Ledger Entry No." <>
                               ApplnDtldCustLedgEntry."Applied Cust. Ledger Entry No."
                            then
                                if CustLedgerEntry.Get(ApplnDtldCustLedgEntry."Cust. Ledger Entry No.") then begin
                                    TempAppliedCustLedgerEntry := CustLedgerEntry;
                                    if TempAppliedCustLedgerEntry.Insert(false) then;
                                end;
                        until ApplnDtldCustLedgEntry.Next() = 0;
                end else
                    if CustLedgerEntry.Get(DtldCustLedgEntry."Applied Cust. Ledger Entry No.") then begin
                        TempAppliedCustLedgerEntry := CustLedgerEntry;
                        if TempAppliedCustLedgerEntry.Insert(false) then;
                    end;
            until DtldCustLedgEntry.Next() = 0;
    end;

    local procedure CheckUnappliedEntries(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        LastTransactionNo: Integer;
        IsHandled: Boolean;
    begin
        if DtldCustLedgEntry."Entry Type" = DtldCustLedgEntry."Entry Type"::Application then begin
            LastTransactionNo := FindLastApplTransactionEntry(DtldCustLedgEntry."Cust. Ledger Entry No.");
            IsHandled := false;
            OnCheckUnappliedEntriesOnBeforeUnapplyAllEntriesError(DtldCustLedgEntry, LastTransactionNo, IsHandled);
            if not IsHandled then
                if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldCustLedgEntry."Transaction No.") then
                    Error(UnapplyAllPostedAfterThisEntryErr, DtldCustLedgEntry."Cust. Ledger Entry No.");
        end;
        LastTransactionNo := FindLastTransactionNo(DtldCustLedgEntry."Cust. Ledger Entry No.");
        if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldCustLedgEntry."Transaction No.") then
            Error(LatestEntryMustBeApplicationErr, DtldCustLedgEntry."Cust. Ledger Entry No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        CustEntryApplyPostedEntries := Subscriber;
        PreviewMode := true;
        Result := CustEntryApplyPostedEntries.Run(RecVar);
    end;

    /// <summary>
    /// Raised after checking if a customer ledger entry is part of a reversal.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry that was checked.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckReversal(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised after posting the application of a customer ledger entry.
    /// </summary>
    /// <param name="GenJournalLine">The general journal line used for posting.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry that was applied.</param>
    /// <param name="GenJnlPostLine">The posting codeunit instance.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostApplyCustLedgEntry(GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Raised after posting the unapplication of a customer ledger entry.
    /// </summary>
    /// <param name="GenJournalLine">The general journal line used for posting.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry that was unapplied.</param>
    /// <param name="DetailedCustLedgEntry">The detailed customer ledger entry that was unapplied.</param>
    /// <param name="GenJnlPostLine">The posting codeunit instance.</param>
    /// <param name="CommitChanges">Indicates whether changes should be committed.</param>
    /// <param name="TempCustLedgerEntry">Temporary table containing affected ledger entries.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUnapplyCustLedgEntry(GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var CommitChanges: Boolean; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    begin
    end;

    /// <summary>
    /// Raised after unapplying a customer ledger entry through the UI.
    /// </summary>
    /// <param name="DtldCustLedgEntry">The detailed customer ledger entry that was unapplied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUnApplyCustomer(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry");
    begin
    end;

    /// <summary>
    /// Raised after checking that the entry is open in the apply customer entry form.
    /// </summary>
    /// <param name="ApplyingCustLedgEntry">The applying customer ledger entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyCustEntryFormEntryOnAfterCheckEntryOpen(ApplyingCustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    /// <summary>
    /// Raised before running customer entry edit in the apply customer entry form.
    /// </summary>
    /// <param name="ApplyingCustLedgEntry">The applying customer ledger entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyCustEntryFormEntryOnBeforeRunCustEntryEdit(var ApplyingCustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    /// <summary>
    /// Raised after filters have been set on customer ledger entries in the apply form.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry with filters applied.</param>
    /// <param name="ApplyingCustLedgerEntry">The applying customer ledger entry.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    /// <param name="CustEntryApplID">The application ID.</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyApplyCustEntryFormEntryOnAfterCustLedgEntrySetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ApplyingCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var IsHandled: Boolean; var CustEntryApplID: Code[50]);
    begin
    end;

    /// <summary>
    /// Raised before applying a customer ledger entry.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry to apply.</param>
    /// <param name="DocumentNo">The document number for the application.</param>
    /// <param name="ApplicationDate">The application date.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeApply(var CustLedgerEntry: Record "Cust. Ledger Entry"; var DocumentNo: Code[20]; var ApplicationDate: Date)
    begin
    end;

    /// <summary>
    /// Raised before opening the apply customer entry form.
    /// </summary>
    /// <param name="ApplyingCustLedgEntry">The applying customer ledger entry.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyCustEntryFormEntry(var ApplyingCustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before getting the application date.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry.</param>
    /// <param name="ApplicationDate">The application date to return.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetApplicationDate(CustLedgEntry: Record "Cust. Ledger Entry"; var ApplicationDate: Date; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before posting the application of a customer ledger entry.
    /// </summary>
    /// <param name="GenJournalLine">The general journal line for posting.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry to apply.</param>
    /// <param name="GenJnlPostLine">The posting codeunit instance.</param>
    /// <param name="ApplyUnapplyParameters">The application parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostApplyCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
    end;

    /// <summary>
    /// Raised before posting the unapplication of a customer ledger entry.
    /// </summary>
    /// <param name="GenJournalLine">The general journal line for posting.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry to unapply.</param>
    /// <param name="DetailedCustLedgEntry">The detailed customer ledger entry to unapply.</param>
    /// <param name="GenJnlPostLine">The posting codeunit instance.</param>
    /// <param name="ApplyUnapplyParameters">The unapplication parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUnapplyCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
    end;

    /// <summary>
    /// Raised after filters have been set when collecting affected ledger entries.
    /// </summary>
    /// <param name="DetailedCustLedgEntry">The detailed customer ledger entry with filters.</param>
    /// <param name="DetailedCustLedgEntry2">The original detailed customer ledger entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCollectAffectedLedgerEntriesOnAfterSetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    /// <summary>
    /// Raised after filters have been set when finding the last application entry.
    /// </summary>
    /// <param name="DetailedCustLedgEntry">The detailed customer ledger entry with filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnFindLastApplEntryOnAfterSetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    /// <summary>
    /// Raised before posting the customer application.
    /// </summary>
    /// <param name="HideProgressWindow">Set to true to hide the progress window.</param>
    /// <param name="CustLedgEntry">The customer ledger entry to apply.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustPostApplyCustLedgEntry(var HideProgressWindow: Boolean; CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after filters have been set when getting the application date.
    /// </summary>
    /// <param name="ApplyToCustLedgEntry">The apply-to customer ledger entry with filters.</param>
    /// <param name="CustLedgEntry">The original customer ledger entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetApplicationDateOnAfterSetFilters(var ApplyToCustLedgEntry: Record "Cust. Ledger Entry"; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    /// <summary>
    /// Raised before running the update analysis view.
    /// </summary>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunUpdateAnalysisView(var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before running the customer exchange rate adjustment.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line.</param>
    /// <param name="TempCustLedgerEntry">Temporary table of affected customer ledger entries.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCustExchRateAdjustment(var GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before posting the unapplication with commit control.
    /// </summary>
    /// <param name="HideProgressWindow">Set to true to hide the progress window.</param>
    /// <param name="PreviewMode">Indicates whether in preview mode.</param>
    /// <param name="DetailedCustLedgEntry2">The detailed customer ledger entry to unapply.</param>
    /// <param name="DocNo">The document number.</param>
    /// <param name="PostingDate">The posting date.</param>
    /// <param name="CommitChanges">Indicates whether to commit changes.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUnApplyCustomerCommit(var HideProgressWindow: Boolean; PreviewMode: Boolean; DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; DocNo: Code[20]; PostingDate: Date; CommitChanges: Boolean; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Raised before raising the unapply all entries error.
    /// </summary>
    /// <param name="DtldCustLedgEntry">The detailed customer ledger entry being checked.</param>
    /// <param name="LastTransactionNo">The last transaction number found.</param>
    /// <param name="IsHandled">Set to true to skip the error.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckUnappliedEntriesOnBeforeUnapplyAllEntriesError(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; LastTransactionNo: Integer; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Raised before committing the customer application posting.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry that was applied.</param>
    /// <param name="SuppressCommit">Set to true to suppress the commit.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCustPostApplyCustLedgEntryOnBeforeCommit(var CustLedgerEntry: Record "Cust. Ledger Entry"; var SuppressCommit: Boolean);
    begin
    end;

    /// <summary>
    /// Raised before unapplying a customer entry through the UI.
    /// </summary>
    /// <param name="DtldCustLedgEntry">The detailed customer ledger entry to unapply.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnApplyCustomer(DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Raised after filters have been set during unapplication posting.
    /// </summary>
    /// <param name="DetailedCustLedgEntry">The detailed customer ledger entry with filters.</param>
    /// <param name="DetailedCustLedgEntry2">The original detailed customer ledger entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyCustomerCommitOnAfterSetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    /// <summary>
    /// Raised after getting the customer ledger entry during unapplication.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry retrieved.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyCustomerCommitOnAfterGetCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry");
    begin
    end;

    /// <summary>
    /// Raised before processing payment tolerance during application.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry.</param>
    /// <param name="PaymentToleranceMgt">The payment tolerance management codeunit.</param>
    /// <param name="PreviewMode">Indicates whether in preview mode.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyOnBeforePmtTolCust(CustLedgEntry: Record "Cust. Ledger Entry"; var PaymentToleranceMgt: Codeunit "Payment Tolerance Management"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before posting the customer ledger entry application.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry to apply.</param>
    /// <param name="ApplyUnapplyParameters">The application parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyOnBeforeCustPostApplyCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; var ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
    end;

    /// <summary>
    /// Raised before filtering detailed customer ledger entries during unapplication.
    /// </summary>
    /// <param name="DetailedCustLedgEntry2">The detailed customer ledger entry to unapply.</param>
    /// <param name="ApplyUnapplyParameters">The unapplication parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyCustomerCommitOnBeforeFilterDtldCustLedgEntry(DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
    end;

    /// <summary>
    /// Raised after preview mode processing during unapplication.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyCustomerCommitOnAfterPreviewMode(CustLedgerEntry: Record "Cust. Ledger Entry");
    begin
    end;
}

