// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

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

codeunit 227 "VendEntry-Apply Posted Entries"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    TableNo = "Vendor Ledger Entry";

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
                    PostUnApplyVendor(DetailedVendorLedgEntryPreviewContext, ApplyUnapplyParametersContext);
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
        DetailedVendorLedgEntryPreviewContext: Record "Detailed Vendor Ledg. Entry";
        ApplyUnapplyParametersContext: Record "Apply Unapply Parameters";
        RunOptionPreview: Option Apply,Unapply;
        RunOptionPreviewContext: Option Apply,Unapply;
        PreviewMode: Boolean;

        PostingApplicationMsg: Label 'Posting application...';
        MustNotBeBeforeErr: Label 'The posting date entered must not be before the posting date on the vendor ledger entry.';
        NoEntriesAppliedErr: Label 'Cannot post because you did not specify which entry to apply. You must specify an entry in the %1 field for one or more open entries.', Comment = '%1 - Caption of "Applies to ID" field of Gen. Journal Line';
        UnapplyPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries that were posted after this entry.';
#pragma warning disable AA0470
        NoApplicationEntryErr: Label 'Vendor Ledger Entry No. %1 does not have an application entry.';
#pragma warning restore AA0470
        UnapplyingMsg: Label 'Unapplying and posting...';
#pragma warning disable AA0470
        UnapplyAllPostedAfterThisEntryErr: Label 'Before you can unapply this entry, you must first unapply all application entries in Vendor Ledger Entry No. %1 that were posted after this entry.';
#pragma warning restore AA0470
        NotAllowedPostingDatesErr: Label 'Posting date is not within the range of allowed posting dates.';
#pragma warning disable AA0470
        LatestEntryMustBeApplicationErr: Label 'The latest Transaction No. must be an application in Vendor Ledger Entry No. %1.';
        CannotUnapplyExchRateErr: Label 'You cannot unapply the entry with the posting date %1, because the exchange rate for the additional reporting currency has been changed.';
        CannotUnapplyInReversalErr: Label 'You cannot unapply Vendor Ledger Entry No. %1 because the entry is part of a reversal.';
#pragma warning restore AA0470
        CannotApplyClosedEntriesErr: Label 'One or more of the entries that you selected is closed. You cannot apply closed entries.';

    procedure Apply(VendLedgEntry: Record "Vendor Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters"): Boolean
    var
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        IsHandled: Boolean;
    begin
        OnBeforeApply(VendLedgEntry, ApplyUnapplyParameters."Document No.", ApplyUnapplyParameters."Posting Date");

        IsHandled := false;
        OnApplyOnBeforePmtTolVend(VendLedgEntry, PaymentToleranceMgt, PreviewMode, IsHandled);
        if not IsHandled then
            if not PreviewMode then
                if not PaymentToleranceMgt.PmtTolVend(VendLedgEntry) then
                    exit(false);

        VendLedgEntry.Get(VendLedgEntry."Entry No.");

        if ApplyUnapplyParameters."Posting Date" = 0D then
            ApplyUnapplyParameters."Posting Date" := GetApplicationDate(VendLedgEntry)
        else
            if ApplyUnapplyParameters."Posting Date" < GetApplicationDate(VendLedgEntry) then begin
                IsHandled := false;
                OnApplyOnBeforePostingDateMustNotBeBeforeError(ApplyUnapplyParameters, VendLedgEntry, PreviewMode, IsHandled);
                if not IsHandled then
                    Error(MustNotBeBeforeErr);
            end;

        if ApplyUnapplyParameters."Document No." = '' then
            ApplyUnapplyParameters."Document No." := VendLedgEntry."Document No.";

        OnApplyOnBeforeVendPostApplyVendLedgEntry(VendLedgEntry, ApplyUnapplyParameters);
        VendPostApplyVendLedgEntry(VendLedgEntry, ApplyUnapplyParameters);
        exit(true);
    end;

    procedure GetApplicationDate(VendLedgEntry: Record "Vendor Ledger Entry") ApplicationDate: Date
    var
        ApplyToVendLedgEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetApplicationDate(VendLedgEntry, ApplicationDate, IsHandled);
        if IsHandled then
            exit(ApplicationDate);

        ApplicationDate := 0D;
        ApplyToVendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID");
        ApplyToVendLedgEntry.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
        ApplyToVendLedgEntry.SetRange("Applies-to ID", VendLedgEntry."Applies-to ID");
        OnGetApplicationDateOnAfterSetFilters(ApplyToVendLedgEntry, VendLedgEntry);
        ApplyToVendLedgEntry.FindSet();
        repeat
            if ApplyToVendLedgEntry."Posting Date" > ApplicationDate then
                ApplicationDate := ApplyToVendLedgEntry."Posting Date";
        until ApplyToVendLedgEntry.Next() = 0;
    end;

    local procedure VendPostApplyVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
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
        OnBeforeVendPostApplyVendLedgEntry(HideProgressWindow, VendLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if not HideProgressWindow then
            Window.Open(PostingApplicationMsg);

        SourceCodeSetup.Get();

        GenJnlLine.Init();
        GenJnlLine."Document No." := ApplyUnapplyParameters."Document No.";
        GenJnlLine."Posting Date" := ApplyUnapplyParameters."Posting Date";
        GenJnlLine."Document Date" := GenJnlLine."Posting Date";
        GenJnlLine."VAT Reporting Date" := GenJnlLine."Posting Date";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Account No." := VendLedgEntry."Vendor No.";
        VendLedgEntry.CalcFields("Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
        GenJnlLine.Correction :=
            (VendLedgEntry."Debit Amount" < 0) or (VendLedgEntry."Credit Amount" < 0) or
            (VendLedgEntry."Debit Amount (LCY)" < 0) or (VendLedgEntry."Credit Amount (LCY)" < 0);
        GenJnlLine.CopyVendLedgEntry(VendLedgEntry);
        GenJnlLine."Source Code" := SourceCodeSetup."Purchase Entry Application";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."External Document No." := VendLedgEntry."External Document No.";
        GenJnlLine."Journal Template Name" := ApplyUnapplyParameters."Journal Template Name";
        GenJnlLine."Journal Batch Name" := ApplyUnapplyParameters."Journal Batch Name";

        EntryNoBeforeApplication := FindLastApplDtldVendLedgEntry();

        OnBeforePostApplyVendLedgEntry(GenJnlLine, VendLedgEntry, GenJnlPostLine, ApplyUnapplyParameters);
        GenJnlPostLine.VendPostApplyVendLedgEntry(GenJnlLine, VendLedgEntry);
        OnAfterPostApplyVendLedgEntry(GenJnlLine, VendLedgEntry, GenJnlPostLine);

        EntryNoAfterApplication := FindLastApplDtldVendLedgEntry();
        if EntryNoAfterApplication = EntryNoBeforeApplication then
            Error(NoEntriesAppliedErr, GenJnlLine.FieldCaption("Applies-to ID"));

        if PreviewMode then
            GenJnlPostPreview.ThrowError();

        SuppressCommit := false;
        OnVendPostApplyVendLedgEntryOnBeforeCommit(VendLedgEntry, SuppressCommit);
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

    local procedure FindLastApplDtldVendLedgEntry(): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.LockTable();
        exit(DtldVendLedgEntry.GetLastEntryNo());
    end;

    procedure FindLastApplEntry(VendLedgEntryNo: Integer): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ApplicationEntryNo: Integer;
    begin
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.SetRange(Unapplied, false);
        OnFindLastApplEntryOnAfterSetFilters(DtldVendLedgEntry);
        ApplicationEntryNo := 0;
        if DtldVendLedgEntry.Find('-') then
            repeat
                if DtldVendLedgEntry."Entry No." > ApplicationEntryNo then
                    ApplicationEntryNo := DtldVendLedgEntry."Entry No.";
            until DtldVendLedgEntry.Next() = 0;
        exit(ApplicationEntryNo);
    end;

    local procedure FindLastTransactionNo(VendLedgEntryNo: Integer): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        LastTransactionNo: Integer;
    begin
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DtldVendLedgEntry.SetRange(Unapplied, false);
        DtldVendLedgEntry.SetFilter(
            "Entry Type", '<>%1&<>%2',
            DtldVendLedgEntry."Entry Type"::"Unrealized Loss", DtldVendLedgEntry."Entry Type"::"Unrealized Gain");
        LastTransactionNo := 0;
        if DtldVendLedgEntry.FindSet() then
            repeat
                if LastTransactionNo < DtldVendLedgEntry."Transaction No." then
                    LastTransactionNo := DtldVendLedgEntry."Transaction No.";
            until DtldVendLedgEntry.Next() = 0;
        exit(LastTransactionNo);
    end;

    procedure UnApplyDtldVendLedgEntry(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        ApplicationEntryNo: Integer;
    begin
        DtldVendLedgEntry.TestField("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        DtldVendLedgEntry.TestField(Unapplied, false);
        ApplicationEntryNo := FindLastApplEntry(DtldVendLedgEntry."Vendor Ledger Entry No.");

        if DtldVendLedgEntry."Entry No." <> ApplicationEntryNo then
            Error(UnapplyPostedAfterThisEntryErr);
        CheckReversal(DtldVendLedgEntry."Vendor Ledger Entry No.");
        UnApplyVendor(DtldVendLedgEntry);
    end;

    procedure UnApplyVendLedgEntry(VendLedgEntryNo: Integer)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        CheckVendorLedgerEntryToUnapply(VendLedgEntryNo, DtldVendLedgEntry);
        UnApplyVendor(DtldVendLedgEntry);
    end;

    procedure CheckVendorLedgerEntryToUnapply(VendorLedgerEntryNo: Integer; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        ApplicationEntryNo: Integer;
    begin
        CheckReversal(VendorLedgerEntryNo);
        ApplicationEntryNo := FindLastApplEntry(VendorLedgerEntryNo);
        if ApplicationEntryNo = 0 then
            Error(NoApplicationEntryErr, VendorLedgerEntryNo);
        DetailedVendorLedgEntry.Get(ApplicationEntryNo);
    end;

    local procedure UnApplyVendor(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        UnapplyVendEntries: Page "Unapply Vendor Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUnApplyVendor(DtldVendLedgEntry, IsHandled);
        if not IsHandled then begin
            DtldVendLedgEntry.TestField("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
            DtldVendLedgEntry.TestField(Unapplied, false);
            UnapplyVendEntries.SetDtldVendLedgEntry(DtldVendLedgEntry."Entry No.");
            UnapplyVendEntries.LookupMode(true);
            UnapplyVendEntries.RunModal();
        end;

        OnAfterUnApplyVendor(DtldVendLedgEntry);
    end;

    procedure PostUnApplyVendor(DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        PostUnApplyVendorCommit(DtldVendLedgEntry2, ApplyUnapplyParameters, true);
    end;

    procedure PostUnApplyVendorCommit(DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters"; CommitChanges: Boolean)
    var
        GLEntry: Record "G/L Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlLine: Record "Gen. Journal Line";
        DateComprReg: Record "Date Compr. Register";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        AddCurrChecked: Boolean;
        MaxPostingDate: Date;
        HideProgressWindow: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostUnApplyVendorCommit(
            HideProgressWindow, PreviewMode, DtldVendLedgEntry2, ApplyUnapplyParameters."Document No.", ApplyUnapplyParameters."Posting Date",
            CommitChanges, IsHandled);
        if IsHandled then
            exit;

        MaxPostingDate := 0D;
        GLEntry.LockTable();
        DtldVendLedgEntry.LockTable();
        VendLedgEntry.LockTable();
        VendLedgEntry.Get(DtldVendLedgEntry2."Vendor Ledger Entry No.");
        OnPostUnApplyVendorOnAfterGetVendLedgEntry(VendLedgEntry);
        if GenJnlBatch.Get(VendLedgEntry."Journal Templ. Name", VendLedgEntry."Journal Batch Name") then;
        CheckPostingDate(ApplyUnapplyParameters, MaxPostingDate);
        if ApplyUnapplyParameters."Posting Date" < DtldVendLedgEntry2."Posting Date" then begin
            IsHandled := false;
            OnPostUnApplyVendorCommitOnBeforePostingDateMustNotBeBeforeError(ApplyUnapplyParameters, DtldVendLedgEntry2, PreviewMode, IsHandled);
            if not IsHandled then
                Error(MustNotBeBeforeErr);
        end;

        OnPostUnApplyVendorCommitOnBeforeFilterDtldVendLedgEntry(DtldVendLedgEntry2, ApplyUnapplyParameters);
        if DtldVendLedgEntry2."Transaction No." = 0 then begin
            DtldVendLedgEntry.SetCurrentKey("Application No.", "Vendor No.", "Entry Type");
            DtldVendLedgEntry.SetRange("Application No.", DtldVendLedgEntry2."Application No.");
        end else begin
            DtldVendLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
            DtldVendLedgEntry.SetRange("Transaction No.", DtldVendLedgEntry2."Transaction No.");
        end;
        DtldVendLedgEntry.SetRange("Vendor No.", DtldVendLedgEntry2."Vendor No.");
        DtldVendLedgEntry.SetFilter("Entry Type", '<>%1', DtldVendLedgEntry."Entry Type"::"Initial Entry");
        DtldVendLedgEntry.SetRange(Unapplied, false);
        OnPostUnApplyVendorOnAfterDtldVendLedgEntrySetFilters(DtldVendLedgEntry, DtldVendLedgEntry2);
        if DtldVendLedgEntry.Find('-') then
            repeat
                if not AddCurrChecked then begin
                    CheckAdditionalCurrency(ApplyUnapplyParameters."Posting Date", DtldVendLedgEntry."Posting Date");
                    AddCurrChecked := true;
                end;
                CheckReversal(DtldVendLedgEntry."Vendor Ledger Entry No.");
                if DtldVendLedgEntry."Transaction No." <> 0 then
                    CheckUnappliedEntries(DtldVendLedgEntry);
            until DtldVendLedgEntry.Next() = 0;

        DateComprReg.CheckMaxDateCompressed(MaxPostingDate, 0);

        GLSetup.GetRecordOnce();
        SourceCodeSetup.Get();
        VendLedgEntry.Get(DtldVendLedgEntry2."Vendor Ledger Entry No.");
        GenJnlLine."Document No." := ApplyUnapplyParameters."Document No.";
        GenJnlLine."Posting Date" := ApplyUnapplyParameters."Posting Date";
        GenJnlLine."VAT Reporting Date" := GenJnlLine."Posting Date";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Account No." := DtldVendLedgEntry2."Vendor No.";
        GenJnlLine.Correction := true;
        GenJnlLine.CopyVendLedgEntry(VendLedgEntry);
        GenJnlLine."Source Code" := SourceCodeSetup."Unapplied Purch. Entry Appln.";
        GenJnlLine."Source Currency Code" := DtldVendLedgEntry2."Currency Code";
        GenJnlLine."System-Created Entry" := true;
        if GLSetup."Journal Templ. Name Mandatory" then begin
            GenJnlLine."Journal Template Name" := GLSetup."Apply Jnl. Template Name";
            GenJnlLine."Journal Batch Name" := GLSetup."Apply Jnl. Batch Name";
        end;
        if not HideProgressWindow then
            Window.Open(UnapplyingMsg);

        OnBeforePostUnapplyVendLedgEntry(GenJnlLine, VendLedgEntry, DtldVendLedgEntry2, GenJnlPostLine, ApplyUnapplyParameters);
        CollectAffectedLedgerEntries(TempVendorLedgerEntry, DtldVendLedgEntry2);
        GenJnlPostLine.UnapplyVendLedgEntry(GenJnlLine, DtldVendLedgEntry2);
        RunVendExchRateAdjustment(GenJnlLine, TempVendorLedgerEntry);
        OnAfterPostUnapplyVendLedgEntry(
            GenJnlLine, VendLedgEntry, DtldVendLedgEntry2, GenJnlPostLine, TempVendorLedgerEntry);

        if PreviewMode then
            GenJnlPostPreview.ThrowError();

        if CommitChanges then
            Commit();
        if not HideProgressWindow then
            Window.Close();
    end;

    local procedure RunVendExchRateAdjustment(var GenJnlLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    var
        ExchRateAdjmtRunHandler: Codeunit "Exch. Rate Adjmt. Run Handler";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunVendExchRateAdjustment(GenJnlLine, TempVendorLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        ExchRateAdjmtRunHandler.RunVendExchRateAdjustment(GenJnlLine, TempVendorLedgerEntry);
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

    procedure CheckReversal(VendLedgEntryNo: Integer)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Get(VendLedgEntryNo);
        if VendLedgEntry.Reversed then
            Error(CannotUnapplyInReversalErr, VendLedgEntryNo);
        OnAfterCheckReversal(VendLedgEntry);
    end;

    procedure ApplyVendEntryFormEntry(var ApplyingVendLedgEntry: Record "Vendor Ledger Entry")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendEntryApplID: Code[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyVendEntryFormEntry(ApplyingVendLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if not ApplyingVendLedgEntry.Open then
            Error(CannotApplyClosedEntriesErr);

        OnApplyVendEntryFormEntryOnAfterCheckEntryOpen(ApplyingVendLedgEntry);

        VendEntryApplID := UserId;
        if VendEntryApplID = '' then
            VendEntryApplID := '***';
        if ApplyingVendLedgEntry."Remaining Amount" = 0 then
            ApplyingVendLedgEntry.CalcFields("Remaining Amount");

        ApplyingVendLedgEntry."Applying Entry" := true;
        if ApplyingVendLedgEntry."Applies-to ID" = '' then
            ApplyingVendLedgEntry."Applies-to ID" := VendEntryApplID;
        ApplyingVendLedgEntry."Amount to Apply" := ApplyingVendLedgEntry."Remaining Amount";
        OnApplyVendEntryFormEntryOnBeforeRunVendEntryEdit(ApplyingVendLedgEntry);
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", ApplyingVendLedgEntry);
        Commit();

        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
        VendLedgEntry.SetRange("Vendor No.", ApplyingVendLedgEntry."Vendor No.");
        VendLedgEntry.SetRange(Open, true);
        RunApplyVendEntries(VendLedgEntry, ApplyingVendLedgEntry, VendEntryApplID);
    end;

    local procedure RunApplyVendEntries(var VendLedgEntry: Record "Vendor Ledger Entry"; var ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; VendEntryApplID: Code[50])
    var
        ApplyVendEntries: Page "Apply Vendor Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnApplyVendEntryFormEntryOnAfterVendLedgEntrySetFilters(VendLedgEntry, ApplyingVendLedgEntry, IsHandled, VendEntryApplID);
        if IsHandled then
            exit;

        if VendLedgEntry.FindFirst() then begin
            ApplyVendEntries.SetVendLedgEntry(ApplyingVendLedgEntry);
            ApplyVendEntries.SetRecord(VendLedgEntry);
            ApplyVendEntries.SetTableView(VendLedgEntry);
            if ApplyingVendLedgEntry."Applies-to ID" <> VendEntryApplID then
                ApplyVendEntries.SetAppliesToID(ApplyingVendLedgEntry."Applies-to ID");
            ApplyVendEntries.RunModal();
            Clear(ApplyVendEntries);
            ApplyingVendLedgEntry."Applying Entry" := false;
            ApplyingVendLedgEntry."Applies-to ID" := '';
            ApplyingVendLedgEntry."Amount to Apply" := 0;
        end;
    end;

    local procedure CollectAffectedLedgerEntries(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        TempVendorLedgerEntry.DeleteAll();

        if DetailedVendorLedgEntry2."Transaction No." = 0 then begin
            DetailedVendorLedgEntry.SetCurrentKey("Application No.", "Vendor No.", "Entry Type");
            DetailedVendorLedgEntry.SetRange("Application No.", DetailedVendorLedgEntry2."Application No.");
        end else begin
            DetailedVendorLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
            DetailedVendorLedgEntry.SetRange("Transaction No.", DetailedVendorLedgEntry2."Transaction No.");
        end;
        DetailedVendorLedgEntry.SetRange("Vendor No.", DetailedVendorLedgEntry2."Vendor No.");
        DetailedVendorLedgEntry.SetFilter("Entry Type", '<>%1', DetailedVendorLedgEntry."Entry Type"::"Initial Entry");
        DetailedVendorLedgEntry.SetRange(Unapplied, false);
        OnCollectAffectedLedgerEntriesOnAfterSetFilters(DetailedVendorLedgEntry, DetailedVendorLedgEntry2);
        if DetailedVendorLedgEntry.FindSet() then
            repeat
                TempVendorLedgerEntry."Entry No." := DetailedVendorLedgEntry."Vendor Ledger Entry No.";
                if TempVendorLedgerEntry.Insert() then;
            until DetailedVendorLedgEntry.Next() = 0;
    end;

    local procedure FindLastApplTransactionEntry(VendLedgEntryNo: Integer): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        LastTransactionNo: Integer;
    begin
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        LastTransactionNo := 0;
        if DtldVendLedgEntry.Find('-') then
            repeat
                if (DtldVendLedgEntry."Transaction No." > LastTransactionNo) and not DtldVendLedgEntry.Unapplied then
                    LastTransactionNo := DtldVendLedgEntry."Transaction No.";
            until DtldVendLedgEntry.Next() = 0;
        exit(LastTransactionNo);
    end;

    procedure PreviewApply(VendorLedgerEntry: Record "Vendor Ledger Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        if not PaymentToleranceMgt.PmtTolVend(VendorLedgerEntry) then
            exit;

        BindSubscription(VendEntryApplyPostedEntries);
        VendEntryApplyPostedEntries.SetApplyContext(ApplyUnapplyParameters);
        GenJnlPostPreview.Preview(VendEntryApplyPostedEntries, VendorLedgerEntry);
    end;

    procedure PreviewUnapply(DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        BindSubscription(VendEntryApplyPostedEntries);
        VendEntryApplyPostedEntries.SetUnapplyContext(DetailedVendorLedgEntry, ApplyUnapplyParameters);
        GenJnlPostPreview.Preview(VendEntryApplyPostedEntries, VendorLedgerEntry);
    end;

    procedure SetApplyContext(ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        ApplyUnapplyParametersContext := ApplyUnapplyParameters;
        RunOptionPreviewContext := RunOptionPreview::Apply;
    end;

    procedure SetUnapplyContext(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        ApplyUnapplyParametersContext := ApplyUnapplyParameters;
        DetailedVendorLedgEntryPreviewContext := DetailedVendorLedgEntry;
        RunOptionPreviewContext := RunOptionPreview::Unapply;
    end;

    procedure GetAppliedVendLedgerEntries(var TempAppliedVendLedgerEntry: Record "Vendor Ledger Entry" temporary; VendLedgerEntryNo: Integer)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ApplnDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgerEntryNo);
        DtldVendLedgEntry.SetFilter("Applied Vend. Ledger Entry No.", '<>%1', 0);
        DtldVendLedgEntry.SetRange(Unapplied, false);
        if DtldVendLedgEntry.FindSet() then
            repeat
                if DtldVendLedgEntry."Vendor Ledger Entry No." =
                   DtldVendLedgEntry."Applied Vend. Ledger Entry No."
                then begin
                    ApplnDtldVendLedgEntry.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    ApplnDtldVendLedgEntry.SetRange(
                        "Applied Vend. Ledger Entry No.", DtldVendLedgEntry."Applied Vend. Ledger Entry No.");
                    ApplnDtldVendLedgEntry.SetRange("Entry Type", ApplnDtldVendLedgEntry."Entry Type"::Application);
                    ApplnDtldVendLedgEntry.SetRange(Unapplied, false);
                    if ApplnDtldVendLedgEntry.FindSet() then
                        repeat
                            if ApplnDtldVendLedgEntry."Vendor Ledger Entry No." <>
                               ApplnDtldVendLedgEntry."Applied Vend. Ledger Entry No."
                            then
                                if VendLedgerEntry.Get(ApplnDtldVendLedgEntry."Vendor Ledger Entry No.") then begin
                                    TempAppliedVendLedgerEntry := VendLedgerEntry;
                                    if TempAppliedVendLedgerEntry.Insert(false) then;
                                end;
                        until ApplnDtldVendLedgEntry.Next() = 0;
                end else
                    if VendLedgerEntry.Get(DtldVendLedgEntry."Applied Vend. Ledger Entry No.") then begin
                        TempAppliedVendLedgerEntry := VendLedgerEntry;
                        if TempAppliedVendLedgerEntry.Insert(false) then;
                    end;
            until DtldVendLedgEntry.Next() = 0;
    end;

    local procedure CheckUnappliedEntries(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        LastTransactionNo: Integer;
        IsHandled: Boolean;
    begin
        if DtldVendLedgEntry."Entry Type" = DtldVendLedgEntry."Entry Type"::Application then begin
            LastTransactionNo := FindLastApplTransactionEntry(DtldVendLedgEntry."Vendor Ledger Entry No.");
            IsHandled := false;
            OnCheckUnappliedEntriesOnBeforeUnapplyAllEntriesError(DtldVendLedgEntry, LastTransactionNo, IsHandled);
            if not IsHandled then
                if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldVendLedgEntry."Transaction No.") then
                    Error(UnapplyAllPostedAfterThisEntryErr, DtldVendLedgEntry."Vendor Ledger Entry No.");
        end;
        LastTransactionNo := FindLastTransactionNo(DtldVendLedgEntry."Vendor Ledger Entry No.");
        if (LastTransactionNo <> 0) and (LastTransactionNo <> DtldVendLedgEntry."Transaction No.") then
            Error(LatestEntryMustBeApplicationErr, DtldVendLedgEntry."Vendor Ledger Entry No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        VendEntryApplyPostedEntries := Subscriber;
        PreviewMode := true;
        Result := VendEntryApplyPostedEntries.Run(RecVar);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckReversal(VendLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostApplyVendLedgEntry(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostUnapplyVendLedgEntry(GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUnApplyVendor(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendEntryFormEntryOnAfterCheckEntryOpen(ApplyingVendLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendEntryFormEntryOnBeforeRunVendEntryEdit(var ApplyingVendLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyVendEntryFormEntryOnAfterVendLedgEntrySetFilters(var VendorLedgEntry: Record "Vendor Ledger Entry"; var ApplyToVendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean; var VendEntryApplID: Code[50]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApply(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var DocumentNo: Code[20]; var ApplicationDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyVendEntryFormEntry(var ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetApplicationDate(VendorLedgEntry: Record "Vendor Ledger Entry"; var ApplicationDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostApplyVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUnapplyVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectAffectedLedgerEntriesOnAfterSetFilters(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindLastApplEntryOnAfterSetFilters(var DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendPostApplyVendLedgEntry(var HideProgressWindow: Boolean; VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetApplicationDateOnAfterSetFilters(var ApplyToVendLedgEntry: Record "Vendor Ledger Entry"; VendorLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunUpdateAnalysisView(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunVendExchRateAdjustment(var GenJnlLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostUnApplyVendorCommit(var HideProgressWindow: Boolean; PreviewMode: Boolean; DetailedVendLedgEntry2: Record "Detailed Vendor Ledg. Entry"; DocNo: Code[20]; PostingDate: Date; CommitChanges: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckUnappliedEntriesOnBeforeUnapplyAllEntriesError(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; LastTransactionNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendPostApplyVendLedgEntryOnBeforeCommit(var VendLedgerEntry: Record "Vendor Ledger Entry"; var SuppressCommit: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnApplyVendor(DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyVendorOnAfterDtldVendLedgEntrySetFilters(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyVendorOnAfterGetVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyOnBeforePmtTolVend(VendLedgEntry: Record "Vendor Ledger Entry"; var PaymentToleranceMgt: Codeunit "Payment Tolerance Management"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyVendorCommitOnBeforeFilterDtldVendLedgEntry(DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyOnBeforeVendPostApplyVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; var ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyOnBeforePostingDateMustNotBeBeforeError(var ApplyUnapplyParameters: Record "Apply Unapply Parameters"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostUnApplyVendorCommitOnBeforePostingDateMustNotBeBeforeError(var ApplyUnapplyParameters: Record "Apply Unapply Parameters"; var DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry"; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;
}

