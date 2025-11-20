// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Posting;

using Microsoft.Bank.BankAccount;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Journal;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Intercompany;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Reflection;
using System.Utilities;

codeunit 13 "Gen. Jnl.-Post Batch"
{
    Permissions =
        TableData "Gen. Journal Batch" = rimd,
        TableData "Gen. Journal Line" = rimd;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
        StartDateTime: DateTime;
        FinishDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime();
        GenJnlLine.Copy(Rec);
        GenJnlLine.SetAutoCalcFields();
        Code(GenJnlLine);
        Rec := GenJnlLine;
        FinishDateTime := CurrentDateTime();
    end;

    var
#pragma warning disable AA0470
        PostingStateMsg: Label 'Journal Batch Name    #1##########\\Posting @2@@@@@@@@@@@@@\#3#############', Comment = 'This is a message for dialog window. Parameters do not require translation.';
#pragma warning restore AA0470
        CheckingLinesMsg: Label 'Checking lines';
        CheckingBalanceMsg: Label 'Checking balance';
        UpdatingBalLinesMsg: Label 'Updating bal. lines';
        PostingLinesMsg: Label 'Posting lines';
        PostingReversLinesMsg: Label 'Posting revers. lines';
        UpdatingLinesMsg: Label 'Updating lines';
#pragma warning disable AA0074
        Text008: Label 'must be the same on all lines for the same document';
#pragma warning disable AA0470
        Text009: Label '%1 %2 posted on %3 includes more than one customer or vendor. ';
#pragma warning restore AA0470
        Text010: Label 'In order for the program to calculate VAT, the entries must be separated by another document number or by an empty line.';
#pragma warning disable AA0470
        Text012: Label '%5 %2 is out of balance by %1. ';
        Text013: Label 'Please check that %3, %4, %5 and %6 are correct for each line.';
        Text014: Label 'The lines in %1 are out of balance by %2. ';
        Text015: Label 'Check that %3 and %4 are correct for each line.';
        Text016: Label 'Your reversing entries in %4 %2 are out of balance by %1. ';
        Text017: Label 'Please check whether %3 is correct for each line for this %4.';
        Text018: Label 'Your reversing entries for %1 are out of balance by %2. ';
        Text019: Label '%3 %1 is out of balance due to the additional reporting currency. ';
        Text020: Label 'Please check that %2 is correct for each line.';
#pragma warning restore AA0470
        Text021: Label 'cannot be specified when using recurring journals.';
        Text022: Label 'The Balance and Reversing Balance recurring methods can be used only for G/L accounts.';
        Text023: Label 'Allocations can only be used with recurring journals.';
        Text024: Label '<Month Text>', Locked = true;
#pragma warning disable AA0470
        Text026: Label '%5 %2 is out of balance by %1 %7. ';
        Text027: Label 'The lines in %1 are out of balance by %2 %5. ';
#pragma warning restore AA0470
        Text028: Label 'The Balance and Reversing Balance recurring methods can be used only with Allocations.';
#pragma warning restore AA0074
        ConfirmManualCheckTxt: Label 'A balancing account is not specified for one or more lines. If you print checks without specifying balancing accounts you will not be able to void the checks, if needed. Do you want to continue?';
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlLine3: Record "Gen. Journal Line";
        TempGenJnlLine4: Record "Gen. Journal Line" temporary;
        GenJnlLine5: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GLReg: Record "G/L Register";
        GLAcc: Record "G/L Account";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        AccountingPeriod: Record "Accounting Period";
        GLSetup: Record "General Ledger Setup";
        FAJnlSetup: Record "FA Journal Setup";
        TempGenJnlLine3: Record "Gen. Journal Line" temporary;
        SavedGenJournalLine: Record "Gen. Journal Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        ICOutboxMgt: Codeunit ICInboxOutboxMgt;
        PostingSetupMgt: Codeunit PostingSetupManagement;
        Window: Dialog;
        GLRegNo: Integer;
        StartLineNo: Integer;
        StartLineNoReverse: Integer;
        LastDate: Date;
        LastDocType: Enum "Gen. Journal Document Type";
        LastDocNo: Code[20];
        LastPostedDocNo: Code[20];
        CurrentBalance: Decimal;
        CurrentBalanceReverse: Decimal;
        Day: Integer;
        Week: Integer;
        Month: Integer;
        MonthText: Text[30];
        NoOfRecords: Integer;
        NoOfReversingRecords: Integer;
        LineCount: Integer;
        DocCorrection: Boolean;
        VATEntryCreated: Boolean;
        LastFAAddCurrExchRate: Decimal;
        LastCurrencyCode: Code[10];
        CurrencyBalance: Decimal;
#pragma warning disable AA0074
        Text029: Label '%1 %2 posted on %3 includes more than one customer, vendor or IC Partner.', Comment = '%1 = Document Type;%2 = Document No.;%3=Posting Date';
#pragma warning disable AA0470
        Text030: Label 'You cannot enter G/L Account or Bank Account in both %1 and %2.';
        Text031: Label 'Line No. %1 does not contain a G/L Account or Bank Account. When the %2 field contains an account number, either the %3 field or the %4 field must contain a G/L Account or Bank Account.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        RefPostingState: Option "Checking lines","Checking balance","Updating bal. lines","Posting Lines","Posting revers. lines","Updating lines";
        PreviewMode: Boolean;
        SkippedLineMsg: Label 'One or more lines has not been posted because the amount is zero.';
        ConfirmPostingAfterWorkingDateQst: Label 'The posting date of one or more journal lines is after the working date. Do you want to continue?';
        SuppressCommit: Boolean;
        ReversePostingDateErr: Label 'Posting Date for reverse cannot be less than %1', Comment = '%1 = Posting Date';
        FirstLine: Boolean;
        TempBatchNameTxt: Label 'BD_TEMP', Locked = true;
        TwoPlaceHoldersTok: Label '%1%2', Locked = true;
        ServiceSessionTok: Label '#%1#%2#', Locked = true;
        GlblDimNoInconsistErr: Label 'A setting for one or more global or shortcut dimensions is incorrect. To fix it, choose the link in the Source column. For more information, choose the link in the Support URL column.';
        PostingDateErr: Label 'is not within your range of allowed posting dates';

    local procedure "Code"(var GenJnlLine: Record "Gen. Journal Line")
    var
        TempMarkedGenJnlLine: Record "Gen. Journal Line" temporary;
        RaiseError: Boolean;
    begin
        OnBeforeCode(GenJnlLine, PreviewMode, SuppressCommit);

        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");

        GenJnlLine.LockTable();
        GenJnlAlloc.LockTable();

        GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");

        GLSetup.Get();
        OnBeforeRaiseExceedLengthError(GenJnlBatch, RaiseError, GenJnlLine);

        if GenJnlTemplate.Recurring then begin
            PrepareDimensionBalancedGenJnlLine(GenJnlLine);
            TempMarkedGenJnlLine.Copy(GenJnlLine);
            CheckGenJnlLine(TempMarkedGenJnlLine, GenJnlLine);
            TempMarkedGenJnlLine.SetRange("Posting Date", 0D, WorkDate());
        end;

        if GenJnlTemplate.Recurring then begin
            ProcessLines(TempMarkedGenJnlLine);
            GenJnlLine.Copy(TempMarkedGenJnlLine);
        end else
            ProcessLines(GenJnlLine);

        OnAfterCode(GenJnlLine, PreviewMode);
    end;

    local procedure ProcessLines(var GenJnlLine: Record "Gen. Journal Line")
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        TempGenJnlBatch: Record "Gen. Journal Batch" temporary;
        GenJnlLineVATInfoSource: Record "Gen. Journal Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        ICOutboxExport: Codeunit "IC Outbox Export";
        TypeHelper: Codeunit "Type Helper";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ICFeedback: Codeunit "IC Feedback";
        RecRef: RecordRef;
        ICLastDocNo: Code[20];
        CurrentICPartner: Code[20];
        LastLineNo: Integer;
        LastICTransactionNo: Integer;
        ICTransactionNo: Integer;
        ICProccessedLines: Integer;
        ICLastDocType: Enum "Gen. Journal Document Type";
        ICLastDate: Date;
        VATInfoSourceLineIsInserted: Boolean;
        SkippedLine: Boolean;
        PostingAfterWorkingDateConfirmed: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeProcessLines(GenJnlLine, PreviewMode, SuppressCommit);

        if not GenJnlLine.Find('=><') then begin
            if GenJnlLine.IsRecurring() then
                if GenJnlCheckLine.DateNotAllowed(GenJnlLine."Posting Date") then
                    GenJnlLine.FieldError("Posting Date", ErrorInfo.Create(PostingDateErr, true));

            GenJnlLine."Line No." := 0;
            if PreviewMode then
                GenJnlPostPreview.ThrowError();
            if not SuppressCommit then
                Commit();
            DeleteDimBalBatch(GenJnlLine, false);
            exit;
        end;

        if GuiAllowed() then begin
            Window.Open(PostingStateMsg);
            Window.Update(1, GenJnlLine."Journal Batch Name");
        end;

        // Check lines
        LineCount := 0;
        StartLineNo := GenJnlLine."Line No.";
        NoOfRecords := CountGenJournalLines(GenJnlLine);
        GenJnlCheckLine.SetBatchMode(true);
        repeat
            LineCount := LineCount + 1;
            UpdateDialog(RefPostingState::"Checking lines", LineCount, NoOfRecords);
            AssignVATDateIfEmpty(GenJnlLine);
            CheckLine(GenJnlLine, PostingAfterWorkingDateConfirmed);
            TempGenJnlLine := GenJnlLine5;
            TempGenJnlLine.Insert();
            if GenJnlLine.Next() = 0 then
                GenJnlLine.FindFirst();
        until GenJnlLine."Line No." = StartLineNo;
        if GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany then
            CheckICDocument(TempGenJnlLine);

        ProcessBalanceOfLines(GenJnlLine, GenJnlLineVATInfoSource, VATInfoSourceLineIsInserted, LastLineNo, CurrentICPartner);

        // Find next register no.
        GLEntry.LockTable();
        FindNextGLRegisterNo();

        // Post lines
        LineCount := 0;
        LastDocNo := '';
        LastPostedDocNo := '';
        LastICTransactionNo := 0;
        TempGenJnlLine4.DeleteAll();
        NoOfReversingRecords := 0;
        GenJnlLine.FindSet(true);
        FirstLine := true;
        ICProccessedLines := 0;
        repeat
            ErrorMessageMgt.PushContext(ErrorContextElement, GenJnlLine.RecordId, 0, PostingLinesMsg);
            ProcessICLines(CurrentICPartner, ICTransactionNo, ICLastDocNo, ICLastDate, ICLastDocType, GenJnlLine, TempGenJnlLine, ICProccessedLines);
            ProcessICTransaction(LastICTransactionNo, ICTransactionNo);
            OnProcessLinesOnAfterProcessICTransaction(GenJnlLine);
            GenJnlLine3 := GenJnlLine;
            if not PostGenJournalLine(GenJnlLine3, CurrentICPartner, ICTransactionNo) then
                SkippedLine := true;
            ErrorMessageMgt.PopContext(ErrorContextElement);
        until GenJnlLine.Next() = 0;

        if LastICTransactionNo > 0 then
            ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICTransactionNo);

        // Post reversing lines
        RecRef.GetTable(TempGenJnlLine4);
        TypeHelper.SortRecordRef(RecRef, GenJnlLine.CurrentKey, GenJnlLine.Ascending);
        RecRef.SetTable(TempGenJnlLine4);
        PostReversingLines(TempGenJnlLine4);

        OnProcessLinesOnAfterPostGenJnlLines(GenJnlLine, GLReg, GLRegNo, PreviewMode);

        // Copy register no. and current journal batch name to general journal
        IsHandled := false;
        OnProcessLinesOnBeforeSetGLRegNoToZero(GenJnlLine, GLRegNo, IsHandled, GenJnlPostLine);
        if not IsHandled then
            if not GLReg.FindLast() or (GLReg."No." <> GLRegNo) then
                GLRegNo := 0;

        GenJnlLine.Init();
        GenJnlLine."Line No." := GLRegNo;

        OnProcessLinesOnAfterAssignGLNegNo(GenJnlLine, GLReg, GLRegNo);

        if PreviewMode then begin
            OnBeforeThrowPreviewError(GenJnlLine, GLRegNo);
            GenJnlPostPreview.ThrowError();
        end;

        TempGenJnlBatch.Copy(GenJnlBatch);

        // Update/delete lines
        if GLRegNo <> 0 then
            UpdateAndDeleteLines(GenJnlLine);

        NoSeriesBatch.SaveState();

        DeleteDimBalBatch(GenJnlLine, true);

        OnBeforeCommit(GLRegNo, GenJnlLine, GenJnlPostLine);

        if not SuppressCommit then
            Commit();

        OnProcessLinesOnBeforeClearPostingCodeunits(GenJnlLine, SuppressCommit);
        Clear(GenJnlCheckLine);
        Clear(GenJnlPostLine);
        GenJnlLine.ClearMarks();
        UpdateAnalysisView.UpdateAll(0, true);
        TempGenJnlBatch.OnMoveGenJournalBatch(GLReg.RecordId);
        if not SuppressCommit then
            Commit();

        if SkippedLine and GuiAllowed then
            Message(SkippedLineMsg);

        OnAfterProcessLines(TempGenJnlLine, GenJnlLine, SuppressCommit, PreviewMode);

        if LastICTransactionNo > 0 then
            ICFeedback.ShowIntercompanyMessage(TempGenJnlLine, ICLastDocNo, ICProccessedLines);
    end;

    local procedure ProcessBalanceOfLines(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlLineVATInfoSource: Record "Gen. Journal Line"; var VATInfoSourceLineIsInserted: Boolean; var LastLineNo: Integer; CurrentICPartner: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        BalVATPostingSetup: Record "VAT Posting Setup";
        ErrorMessage: Text;
        LastDocTypeOption: Option;
        ForceCheckBalance: Boolean;
        IsProcessingKeySet: Boolean;
        IsHandled: Boolean;
        ShouldCheckDocNoBasedOnNoSeries, SkipCheckingPostingNoSeries : Boolean;
    begin
        IsProcessingKeySet := false;
        OnBeforeProcessBalanceOfLines(GenJnlLine, GenJnlBatch, GenJnlTemplate, IsProcessingKeySet);
        if not IsProcessingKeySet then
            if GenJnlTemplate."Force Doc. Balance" then
                GenJnlLine.SetCurrentKey("Document No.", "Posting Date")
            else
                if CheckIfDiffPostingDatesExist(GenJnlBatch, GenJnlLine."Posting Date") then
                    GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Bal. Account No.");
        LineCount := 0;
        LastDate := 0D;
        LastDocType := LastDocType::" ";
        LastDocNo := '';
        LastFAAddCurrExchRate := 0;
        TempGenJnlLine3.Reset();
        TempGenJnlLine3.DeleteAll();
        VATEntryCreated := false;
        CurrentBalance := 0;
        CurrentBalanceReverse := 0;
        CurrencyBalance := 0;

        GenJnlLine.FindSet(true);
        LastCurrencyCode := GenJnlLine."Currency Code";

        repeat
            IsHandled := false;
            OnProcessBalanceOfLinesOnBeforeCheckLine(GenJnlLine, IsHandled);
            if not IsHandled then begin
                LineCount := LineCount + 1;
                UpdateDialog(RefPostingState::"Checking balance", LineCount, NoOfRecords);

                if not GenJnlLine.EmptyLine() then begin
                    ShouldCheckDocNoBasedOnNoSeries := not PreviewMode and (GenJnlBatch."No. Series" <> '') and (LastDocNo <> GenJnlLine."Document No.");
                    SkipCheckingPostingNoSeries := false;
                    OnProcessBalanceOfLinesOnAfterCalcShouldCheckDocNoBasedOnNoSeries(GenJnlLine, GenJnlBatch, ShouldCheckDocNoBasedOnNoSeries, SkipCheckingPostingNoSeries, LastDocNo, CurrentBalance);
                    if ShouldCheckDocNoBasedOnNoSeries then
                        if GenJnlLine."Document No." = NoSeriesBatch.PeekNextNo(GenJnlBatch."No. Series", GenJnlLine."Posting Date") then
                            // No. used is same as peek so need to save it.
                            NoSeriesBatch.GetNextNo(GenJnlBatch."No. Series", GenJnlLine."Posting Date")
                        else
                            // manual nos should be allowed.
                            NoSeriesBatch.TestManual(GenJnlBatch."No. Series", GenJnlLine."Document No.");
                    if not SkipCheckingPostingNoSeries then
                        if GenJnlLine."Posting No. Series" <> '' then
                            GenJnlLine.TestField("Posting No. Series", GenJnlBatch."Posting No. Series");
                    CheckCorrection(GenJnlLine);
                end;
                LastDocTypeOption := LastDocType.AsInteger();
                OnBeforeIfCheckBalance(GenJnlTemplate, GenJnlLine, LastDocTypeOption, LastDocNo, LastDate, ForceCheckBalance, SuppressCommit, IsHandled, CurrentBalance);
                LastDocType := "Gen. Journal Document Type".FromInteger(LastDocTypeOption);
                if not IsHandled then
                    if ForceCheckBalance or (GenJnlLine."Posting Date" <> LastDate) or GenJnlTemplate."Force Doc. Balance" and
                       ((GenJnlLine."Document Type" <> LastDocType) or (GenJnlLine."Document No." <> LastDocNo))
                    then begin
                        CheckBalance(GenJnlLine);
                        CurrencyBalance := 0;
                        LastCurrencyCode := GenJnlLine."Currency Code";
                        TempGenJnlLine3.Reset();
                        TempGenJnlLine3.DeleteAll();
                    end;

                if IsNonZeroAmount(GenJnlLine) then begin
                    if LastFAAddCurrExchRate <> GenJnlLine."FA Add.-Currency Factor" then
                        CheckAddExchRateBalance(GenJnlLine);
                    if (CurrentBalance = 0) and (CurrentICPartner = '') then begin
                        TempGenJnlLine3.Reset();
                        TempGenJnlLine3.DeleteAll();
                        if VATEntryCreated and VATInfoSourceLineIsInserted then
                            UpdateGenJnlLineWithVATInfo(GenJnlLine, GenJnlLineVATInfoSource, StartLineNo, LastLineNo);
                        VATEntryCreated := false;
                        VATInfoSourceLineIsInserted := false;
                        StartLineNo := GenJnlLine."Line No.";
                    end;
                    if CurrentBalanceReverse = 0 then
                        StartLineNoReverse := GenJnlLine."Line No.";
                    GenJnlLine.UpdateLineBalance();
                    OnAfterUpdateLineBalance(GenJnlLine);
                    CurrentBalance := CurrentBalance + GenJnlLine."Balance (LCY)";
                    if GenJnlLine."Recurring Method".AsInteger() >= GenJnlLine."Recurring Method"::"RF Reversing Fixed".AsInteger() then
                        CurrentBalanceReverse := CurrentBalanceReverse + GenJnlLine."Balance (LCY)";

                    UpdateCurrencyBalanceForRecurringLine(GenJnlLine);
                end;

                LastDate := GenJnlLine."Posting Date";
                LastDocType := GenJnlLine."Document Type";
                if not GenJnlLine.EmptyLine() then
                    LastDocNo := GenJnlLine."Document No.";
                LastFAAddCurrExchRate := GenJnlLine."FA Add.-Currency Factor";
                if GenJnlTemplate."Force Doc. Balance" then begin
                    if not VATPostingSetup.Get(GenJnlLine."VAT Bus. Posting Group", GenJnlLine."VAT Prod. Posting Group") then
                        Clear(VATPostingSetup);
                    if not BalVATPostingSetup.Get(GenJnlLine."Bal. VAT Bus. Posting Group", GenJnlLine."Bal. VAT Prod. Posting Group") then
                        Clear(BalVATPostingSetup);
                    VATEntryCreated :=
                      VATEntryCreated or
                      ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account") and (GenJnlLine."Account No." <> '') and
                       (GenJnlLine."Gen. Posting Type" in [GenJnlLine."Gen. Posting Type"::Purchase, GenJnlLine."Gen. Posting Type"::Sale]) and
                       (VATPostingSetup."VAT %" <> 0)) or
                      ((GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account") and (GenJnlLine."Bal. Account No." <> '') and
                       (GenJnlLine."Bal. Gen. Posting Type" in [GenJnlLine."Bal. Gen. Posting Type"::Purchase, GenJnlLine."Bal. Gen. Posting Type"::Sale]) and
                       (BalVATPostingSetup."VAT %" <> 0));
                    OnProcessBalanceOfLinesOnAfterSetVATEntryCreated(GenJnlLine, VATEntryCreated);
                    if TempGenJnlLine3.IsCustVendICAdded(GenJnlLine) then begin
                        GenJnlLineVATInfoSource := GenJnlLine;
                        VATInfoSourceLineIsInserted := true;
                    end;
                    if (TempGenJnlLine3.Count > 1) and VATEntryCreated then begin
                        ErrorMessage := Text009 + Text010;
                        Error(ErrorMessage, GenJnlLine."Document Type", GenJnlLine."Document No.", GenJnlLine."Posting Date");
                    end;
                    if (TempGenJnlLine3.Count > 1) and (CurrentICPartner <> '') and
                       (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany)
                    then
                        Error(
                          Text029,
                          GenJnlLine."Document Type", GenJnlLine."Document No.", GenJnlLine."Posting Date");
                    LastLineNo := GenJnlLine."Line No.";
                end;
            end;
        until GenJnlLine.Next() = 0;
        CheckBalance(GenJnlLine);
        CopyFields(GenJnlLine);
        if VATEntryCreated and VATInfoSourceLineIsInserted then
            UpdateGenJnlLineWithVATInfo(GenJnlLine, GenJnlLineVATInfoSource, StartLineNo, LastLineNo);

        OnAfterProcessBalanceOfLines(GenJnlLine);
    end;

    local procedure ProcessICLines(var CurrentICPartner: Code[20]; var ICTransactionNo: Integer; var ICLastDocNo: Code[20]; var ICLastDate: Date; var ICLastDocType: Enum "Gen. Journal Document Type"; var GenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; var ICProccessedLines: Integer)
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessICLines(CurrentICPartner, ICTransactionNo, ICLastDocNo, ICLastDate, ICLastDocType, GenJnlLine, TempGenJnlLine, ICProccessedLines, IsHandled);
        if IsHandled then
            exit;

        if (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) and not GenJnlLine.EmptyLine() and
               ((GenJnlLine."Posting Date" <> ICLastDate) or (GenJnlLine."Document Type" <> ICLastDocType) or (GenJnlLine."Document No." <> ICLastDocNo) or
               ((GenJnlLine."IC Partner Code" <> CurrentICPartner) and (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"IC Partner")))
        then begin
            CurrentICPartner := '';
            ICLastDate := GenJnlLine."Posting Date";
            ICLastDocType := GenJnlLine."Document Type";
            ICLastDocNo := GenJnlLine."Document No.";
            TempGenJnlLine.Reset();
            TempGenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
            TempGenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
            TempGenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
            TempGenJnlLine.SetRange("Posting Date", GenJnlLine."Posting Date");
            TempGenJnlLine.SetRange("Document No.", GenJnlLine."Document No.");
            if (GenJnlLine."IC Partner Code" = '') then
                TempGenJnlLine.SetFilter("IC Partner Code", '<>%1', '')
            else
                TempGenJnlLine.SetRange("IC Partner Code", GenJnlLine."IC Partner Code");

            if TempGenJnlLine.FindFirst() and (TempGenJnlLine."IC Partner Code" <> '') then begin
                ICProccessedLines := ICProccessedLines + 1;
                CurrentICPartner := TempGenJnlLine."IC Partner Code";
                if TempGenJnlLine."IC Direction" = TempGenJnlLine."IC Direction"::Outgoing then
                    ICTransactionNo := ICOutboxMgt.CreateOutboxJnlTransaction(TempGenJnlLine, false)
                else
                    if HandledICInboxTrans.Get(
                         TempGenJnlLine."IC Partner Transaction No.", TempGenJnlLine."IC Partner Code",
                         HandledICInboxTrans."Transaction Source"::"Created by Partner", TempGenJnlLine."Document Type")
                    then begin
                        HandledICInboxTrans.LockTable();
                        HandledICInboxTrans.Status := HandledICInboxTrans.Status::Posted;
                        OnProcessICLinesOnBeforeHandledICInboxTransModify(HandledICInboxTrans, GenJnlLine);
                        HandledICInboxTrans.Modify();
                    end
            end
        end;
    end;

    local procedure ProcessICTransaction(var LastICTransactionNo: Integer; ICTransactionNo: Integer)
    var
        ICOutboxExport: Codeunit "IC Outbox Export";
    begin
        if LastICTransactionNo = 0 then
            LastICTransactionNo := ICTransactionNo
        else
            if LastICTransactionNo <> ICTransactionNo then begin
                ICOutboxExport.ProcessAutoSendOutboxTransactionNo(LastICTransactionNo);
                LastICTransactionNo := ICTransactionNo;
            end;
    end;

    local procedure CheckBalance(var GenJnlLine: Record "Gen. Journal Line")
    begin
        OnBeforeCheckBalance(
          GenJnlTemplate, GenJnlLine, CurrentBalance, CurrentBalanceReverse, CurrencyBalance,
          StartLineNo, StartLineNoReverse, LastDocType.AsInteger(), LastDocNo, LastDate, LastCurrencyCode, SuppressCommit);

        if CurrentBalance <> 0 then begin
            GenJnlLine.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", StartLineNo);
            if GenJnlTemplate."Force Doc. Balance" then
                Error(
                  Text012 +
                  Text013,
                  CurrentBalance, LastDocNo, GenJnlLine.FieldCaption("Posting Date"), GenJnlLine.FieldCaption("Document Type"),
                  GenJnlLine.FieldCaption("Document No."), GenJnlLine.FieldCaption(Amount));
            Error(
              Text014 +
              Text015,
              LastDate, CurrentBalance, GenJnlLine.FieldCaption("Posting Date"), GenJnlLine.FieldCaption(Amount));
        end;
        if CurrentBalanceReverse <> 0 then begin
            GenJnlLine.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", StartLineNoReverse);
            if GenJnlTemplate."Force Doc. Balance" then
                Error(
                  Text016 +
                  Text017,
                  CurrentBalanceReverse, LastDocNo, GenJnlLine.FieldCaption("Recurring Method"), GenJnlLine.FieldCaption("Document No."));
            Error(
              Text018 +
              Text017,
              LastDate, CurrentBalanceReverse, GenJnlLine.FieldCaption("Recurring Method"), GenJnlLine.FieldCaption("Posting Date"));
        end;
        if (LastCurrencyCode <> '') and (CurrencyBalance <> 0) then begin
            GenJnlLine.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", StartLineNo);
            if GenJnlTemplate."Force Doc. Balance" then
                Error(
                  Text026 +
                  Text013,
                  CurrencyBalance, LastDocNo, GenJnlLine.FieldCaption("Posting Date"), GenJnlLine.FieldCaption("Document Type"),
                  GenJnlLine.FieldCaption("Document No."), GenJnlLine.FieldCaption(Amount),
                  LastCurrencyCode);
            Error(
              Text027 +
              Text015,
              LastDate, CurrencyBalance, GenJnlLine.FieldCaption("Posting Date"), GenJnlLine.FieldCaption(Amount), LastCurrencyCode);
        end;
    end;

    local procedure CheckCorrection(GenJournalLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCorrection(GenJournalLine, IsHandled, GenJnlTemplate, LastDate, LastDocType, LastDocNo, DocCorrection);
        if IsHandled then
            exit;

        if (GenJournalLine."Posting Date" <> LastDate) or (GenJournalLine."Document Type" <> LastDocType) or (GenJournalLine."Document No." <> LastDocNo) then begin
            if GenJournalLine.Correction then
                GenJnlTemplate.TestField("Force Doc. Balance", true);
            DocCorrection := GenJournalLine.Correction;
        end else
            if GenJournalLine.Correction <> DocCorrection then
                GenJournalLine.FieldError(GenJournalLine.Correction, Text008);
    end;

    local procedure CheckAddExchRateBalance(GenJnlLine: Record "Gen. Journal Line")
    begin
        if CurrentBalance <> 0 then
            Error(
              Text019 +
              Text020,
              LastDocNo, GenJnlLine.FieldCaption("FA Add.-Currency Factor"), GenJnlLine.FieldCaption("Document No."));
    end;

    local procedure CheckRecurringLine(var GenJnlLine2: Record "Gen. Journal Line")
    var
        DummyDateFormula: DateFormula;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRecurringLine(GenJnlLine2, GenJnlTemplate, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine2."Account No." <> '' then
            if GenJnlTemplate.Recurring then begin
                GenJnlLine2.TestField(GenJnlLine2."Recurring Method");
                GenJnlLine2.TestField(GenJnlLine2."Recurring Frequency");
                if GenJnlLine2."Bal. Account No." <> '' then
                    GenJnlLine2.FieldError(GenJnlLine2."Bal. Account No.", Text021);
                case GenJnlLine2."Recurring Method" of
                    GenJnlLine2."Recurring Method"::"V  Variable", GenJnlLine2."Recurring Method"::"RV Reversing Variable",
                  GenJnlLine2."Recurring Method"::"F  Fixed", GenJnlLine2."Recurring Method"::"RF Reversing Fixed":
                        if not GenJnlLine2."Allow Zero-Amount Posting" then
                            GenJnlLine2.TestField(GenJnlLine2.Amount);
                    GenJnlLine2."Recurring Method"::"B  Balance", GenJnlLine2."Recurring Method"::"RB Reversing Balance":
                        GenJnlLine2.TestField(GenJnlLine2.Amount, 0);
                end;
            end else begin
                GenJnlLine2.TestField(GenJnlLine2."Recurring Method", 0);
                GenJnlLine2.TestField(GenJnlLine2."Recurring Frequency", DummyDateFormula);
            end;
    end;

    local procedure UpdateRecurringAmt(var GenJnlLine2: Record "Gen. Journal Line") Updated: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRecurringAmt(GenJnlLine2, Updated, IsHandled, GLEntry, GLAcc, GenJnlAlloc);
        if IsHandled then
            exit(Updated);

        if (GenJnlLine2."Account No." <> '') and
               (GenJnlLine2."Recurring Method" in
                [GenJnlLine2."Recurring Method"::"B  Balance", GenJnlLine2."Recurring Method"::"RB Reversing Balance"])
        then begin
            GLEntry.LockTable();
            if GenJnlLine2."Account Type" = GenJnlLine2."Account Type"::"G/L Account" then begin
                GLAcc."No." := GenJnlLine2."Account No.";
                GLAcc.SetRange("Date Filter", 0D, GenJnlLine2."Posting Date");
                if GLSetup."Additional Reporting Currency" <> '' then begin
                    GenJnlLine2."Source Currency Code" := GLSetup."Additional Reporting Currency";
                    GLAcc.CalcFields("Additional-Currency Net Change");
                    GenJnlLine2."Source Currency Amount" := -GLAcc."Additional-Currency Net Change";
                    GenJnlAlloc.UpdateAllocationsAddCurr(GenJnlLine2, GenJnlLine2."Source Currency Amount");
                end;
                GLAcc.CalcFields("Net Change");
                GenJnlLine2.Validate(GenJnlLine2.Amount, -GLAcc."Net Change");
                exit(true);
            end;
            Error(Text022);
        end;
        exit(false);
    end;

    local procedure CheckAllocations(var GenJnlLine2: Record "Gen. Journal Line")
    var
        ShowAllocationsRecurringError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAllocations(GenJnlLine2, IsHandled);
        if IsHandled then
            exit;
        if GenJnlLine2."Account No." <> '' then begin
            if GenJnlLine2."Recurring Method" in
               [GenJnlLine2."Recurring Method"::"B  Balance",
                GenJnlLine2."Recurring Method"::"RB Reversing Balance"]
            then begin
                GenJnlAlloc.Reset();
                GenJnlAlloc.SetRange("Journal Template Name", GenJnlLine2."Journal Template Name");
                GenJnlAlloc.SetRange("Journal Batch Name", GenJnlLine2."Journal Batch Name");
                GenJnlAlloc.SetRange("Journal Line No.", GenJnlLine2."Line No.");
                if GenJnlAlloc.IsEmpty() then
                    Error(
                      Text028);
            end;

            GenJnlAlloc.Reset();
            GenJnlAlloc.SetRange("Journal Template Name", GenJnlLine2."Journal Template Name");
            GenJnlAlloc.SetRange("Journal Batch Name", GenJnlLine2."Journal Batch Name");
            GenJnlAlloc.SetRange("Journal Line No.", GenJnlLine2."Line No.");
            GenJnlAlloc.SetFilter(Amount, '<>0');
            if not GenJnlAlloc.IsEmpty() then begin
                ShowAllocationsRecurringError := not GenJnlTemplate.Recurring;
                OnCheckAllocationsOnAfterCalcShowAllocationsRecurringError(GenJnlAlloc, GenJnlLine2, ShowAllocationsRecurringError);
                if ShowAllocationsRecurringError then
                    Error(Text023);
                GenJnlAlloc.SetRange("Account No.", '');
                if GenJnlAlloc.FindFirst() then
                    GenJnlAlloc.TestField("Account No.");
            end;
        end;
    end;

    local procedure MakeRecurringTexts(var GenJnlLine2: Record "Gen. Journal Line")
    begin
        if (GenJnlLine2."Account No." <> '') and (GenJnlLine2."Recurring Method" <> "Gen. Journal Recurring Method"::" ") then begin
            AccountingPeriod.MakeRecurringTexts(GenJnlLine2."Posting Date", GenJnlLine2."Document No.", GenJnlLine2.Description);
            Day := Date2DMY(GenJnlLine2."Posting Date", 1);
            Week := Date2DWY(GenJnlLine2."Posting Date", 2);
            Month := Date2DMY(GenJnlLine2."Posting Date", 2);
            MonthText := Format(GenJnlLine2."Posting Date", 0, Text024);
            OnAfterMakeRecurringTexts(GenJnlLine2, AccountingPeriod, Day, Week, Month, MonthText);
        end;
    end;

    local procedure PostAllocations(var AllocateGenJnlLine: Record "Gen. Journal Line"; Reversing: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostAllocations(AllocateGenJnlLine, Reversing, IsHandled);
        if IsHandled then
            exit;

        if AllocateGenJnlLine."Account No." <> '' then begin
            GenJnlAlloc.Reset();
            GenJnlAlloc.SetRange("Journal Template Name", AllocateGenJnlLine."Journal Template Name");
            GenJnlAlloc.SetRange("Journal Batch Name", AllocateGenJnlLine."Journal Batch Name");
            GenJnlAlloc.SetRange("Journal Line No.", AllocateGenJnlLine."Line No.");
            GenJnlAlloc.SetFilter("Account No.", '<>%1', '');
            if GenJnlAlloc.FindSet(true) then begin
                GenJnlLine2.Init();
                GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::"G/L Account";
                GenJnlLine2."Posting Date" := AllocateGenJnlLine."Posting Date";
                GenJnlLine2."VAT Reporting Date" := AllocateGenJnlLine."VAT Reporting Date";
                GenJnlLine2."Document Type" := AllocateGenJnlLine."Document Type";
                GenJnlLine2."Document No." := AllocateGenJnlLine."Document No.";
                GenJnlLine2.Description := AllocateGenJnlLine.Description;
                GenJnlLine2."Source Code" := AllocateGenJnlLine."Source Code";
                GenJnlLine2."Journal Batch Name" := AllocateGenJnlLine."Journal Batch Name";
                GenJnlLine2."Journal Template Name" := AllocateGenJnlLine."Journal Template Name";
                GenJnlLine2."Line No." := AllocateGenJnlLine."Line No.";
                GenJnlLine2."Reason Code" := AllocateGenJnlLine."Reason Code";
                GenJnlLine2.Correction := AllocateGenJnlLine.Correction;
                GenJnlLine2."Recurring Method" := AllocateGenJnlLine."Recurring Method";
                if AllocateGenJnlLine."Account Type" in [AllocateGenJnlLine."Account Type"::Customer, AllocateGenJnlLine."Account Type"::Vendor] then
                    CopyGenJnlLineBalancingData(GenJnlLine2, AllocateGenJnlLine);
                GenJnlLine2."External Document No." := AllocateGenJnlLine."External Document No.";
                OnPostAllocationsOnBeforeCopyFromGenJnlAlloc(GenJnlLine2, AllocateGenJnlLine, Reversing);
                repeat
                    GenJnlLine2.CopyFromGenJnlAllocation(GenJnlAlloc);
                    GenJnlLine2."Allow Zero-Amount Posting" := true;
                    UpdateDimBalBatchName(GenJnlLine2);
                    OnPostAllocationsOnBeforePrepareGenJnlLineAddCurr(GenJnlLine2, AllocateGenJnlLine);
                    PrepareGenJnlLineAddCurr(GenJnlLine2);
                    if not Reversing then begin
                        OnPostAllocationsOnBeforePostNotReversingLine(GenJnlLine2, GenJnlPostLine, AllocateGenJnlLine, GenJnlAlloc);
                        GenJnlPostLine.RunWithCheck(GenJnlLine2);
                        if AllocateGenJnlLine."Recurring Method" in
                           [AllocateGenJnlLine."Recurring Method"::"V  Variable", AllocateGenJnlLine."Recurring Method"::"B  Balance"]
                        then begin
                            GenJnlAlloc.Amount := 0;
                            GenJnlAlloc."Additional-Currency Amount" := 0;
                            GenJnlAlloc.Modify();
                        end;
                    end else begin
                        MultiplyAmounts(GenJnlLine2, -1);
                        GenJnlLine2."Reversing Entry" := true;
                        OnPostAllocationsOnBeforePostReversingLine(GenJnlLine2, GenJnlPostLine, AllocateGenJnlLine, GenJnlAlloc);
                        GenJnlPostLine.RunWithCheck(GenJnlLine2);
                        if AllocateGenJnlLine."Recurring Method" in
                           [AllocateGenJnlLine."Recurring Method"::"RV Reversing Variable",
                            AllocateGenJnlLine."Recurring Method"::"RB Reversing Balance"]
                        then begin
                            GenJnlAlloc.Amount := 0;
                            GenJnlAlloc."Additional-Currency Amount" := 0;
                            GenJnlAlloc.Modify();
                        end;
                    end;
                until GenJnlAlloc.Next() = 0;
            end;
        end;

        OnAfterPostAllocations(AllocateGenJnlLine, Reversing, SuppressCommit, GenJnlPostLine);
    end;

    local procedure MultiplyAmounts(var GenJnlLine2: Record "Gen. Journal Line"; Factor: Decimal)
    begin
        if GenJnlLine2."Account No." <> '' then begin
            GenJnlLine2.Amount := GenJnlLine2.Amount * Factor;
            GenJnlLine2."Debit Amount" := GenJnlLine2."Debit Amount" * Factor;
            GenJnlLine2."Credit Amount" := GenJnlLine2."Credit Amount" * Factor;
            GenJnlLine2."Amount (LCY)" := GenJnlLine2."Amount (LCY)" * Factor;
            GenJnlLine2."Balance (LCY)" := GenJnlLine2."Balance (LCY)" * Factor;
            GenJnlLine2."Sales/Purch. (LCY)" := GenJnlLine2."Sales/Purch. (LCY)" * Factor;
            GenJnlLine2."Profit (LCY)" := GenJnlLine2."Profit (LCY)" * Factor;
            GenJnlLine2."Inv. Discount (LCY)" := GenJnlLine2."Inv. Discount (LCY)" * Factor;
            GenJnlLine2.Quantity := GenJnlLine2.Quantity * Factor;
            GenJnlLine2."VAT Amount" := GenJnlLine2."VAT Amount" * Factor;
            GenJnlLine2."VAT Base Amount" := GenJnlLine2."VAT Base Amount" * Factor;
            GenJnlLine2."VAT Amount (LCY)" := GenJnlLine2."VAT Amount (LCY)" * Factor;
            GenJnlLine2."VAT Base Amount (LCY)" := GenJnlLine2."VAT Base Amount (LCY)" * Factor;
            GenJnlLine2."Source Currency Amount" := GenJnlLine2."Source Currency Amount" * Factor;
            GenJnlLine2."Non-Deductible VAT Amount" := GenJnlLine2."Non-Deductible VAT Amount" * Factor;
            GenJnlLine2."Non-Deductible VAT Base" := GenJnlLine2."Non-Deductible VAT Base" * Factor;
            GenJnlLine2."Non-Deductible VAT Amount LCY" := GenJnlLine2."Non-Deductible VAT Amount LCY" * Factor;
            GenJnlLine2."Non-Deductible VAT Base LCY" := GenJnlLine2."Non-Deductible VAT Base LCY" * Factor;
            if GenJnlLine2."Job No." <> '' then
                MultiplyJobAmounts(GenJnlLine2, Factor);
        end;

        OnAfterMultiplyAmounts(GenJnlLine2, Factor, SuppressCommit);
    end;

    local procedure MultiplyJobAmounts(var GenJnlLine2: Record "Gen. Journal Line"; Factor: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMultiplyJobAmounts(GenJnlLine2, Factor, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine2."Job Quantity" := GenJnlLine2."Job Quantity" * Factor;
        GenJnlLine2."Job Total Cost (LCY)" := GenJnlLine2."Job Total Cost (LCY)" * Factor;
        GenJnlLine2."Job Total Price (LCY)" := GenJnlLine2."Job Total Price (LCY)" * Factor;
        GenJnlLine2."Job Line Amount (LCY)" := GenJnlLine2."Job Line Amount (LCY)" * Factor;
        GenJnlLine2."Job Total Cost" := GenJnlLine2."Job Total Cost" * Factor;
        GenJnlLine2."Job Total Price" := GenJnlLine2."Job Total Price" * Factor;
        GenJnlLine2."Job Line Amount" := GenJnlLine2."Job Line Amount" * Factor;
        GenJnlLine2."Job Line Discount Amount" := GenJnlLine2."Job Line Discount Amount" * Factor;
        GenJnlLine2."Job Line Disc. Amount (LCY)" := GenJnlLine2."Job Line Disc. Amount (LCY)" * Factor;
    end;

    local procedure CheckDocumentNo(var GenJnlLine2: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocumentNo(GenJnlLine2, LastDocNo, LastPostedDocNo, NoSeriesBatch, IsHandled);
        if not IsHandled then
            if GenJnlLine2."Posting No. Series" = '' then
                GenJnlLine2."Posting No. Series" := GenJnlBatch."No. Series"
            else
                if not GenJnlLine2.EmptyLine() then
                    if ShouldSetDocNoToLastPosted(GenJnlLine2) then
                        GenJnlLine2."Document No." := LastPostedDocNo
                    else begin
                        LastDocNo := GenJnlLine2."Document No.";
                        GenJnlLine2."Document No." := NoSeriesBatch.GetNextNo(GenJnlLine2."Posting No. Series", GenJnlLine2."Posting Date");
                        LastPostedDocNo := GenJnlLine2."Document No.";
                    end;
        OnAfterCheckDocumentNo(GenJnlLine2, LastDocNo, LastPostedDocNo);
    end;

    local procedure ShouldSetDocNoToLastPosted(var GenJournalLine: Record "Gen. Journal Line") Result: Boolean
    begin
        Result := GenJournalLine."Document No." = LastDocNo;
        OnAfterShouldSetDocNoToLastPosted(GenJournalLine, LastDocNo, Result);
    end;

    local procedure PrepareGenJnlLineAddCurr(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if (GLSetup."Additional Reporting Currency" <> '') and
           (GenJnlLine."Recurring Method" in
            [GenJnlLine."Recurring Method"::"B  Balance",
             GenJnlLine."Recurring Method"::"RB Reversing Balance"])
        then begin
            GenJnlLine."Source Currency Code" := GLSetup."Additional Reporting Currency";
            if (GenJnlLine.Amount = 0) and
               (GenJnlLine."Source Currency Amount" <> 0)
            then begin
                GenJnlLine."Additional-Currency Posting" :=
                  GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only";
                GenJnlLine.Amount := GenJnlLine."Source Currency Amount";
                GenJnlLine."Source Currency Amount" := 0;
            end;
        end;
    end;

    local procedure CopyFields(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine4: Record "Gen. Journal Line";
        GenJnlLine6: Record "Gen. Journal Line";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        JnlLineTotalQty: Integer;
        RefPostingSubState: Option "Check account","Check bal. account","Update lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFields(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine6.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
        GenJnlLine4.FilterGroup(2);
        GenJnlLine4.Copy(GenJnlLine);
        GenJnlLine4.FilterGroup(0);
        GenJnlLine6.FilterGroup(2);
        GenJnlLine6.Copy(GenJnlLine);
        GenJnlLine6.FilterGroup(0);
        GenJnlLine6.SetFilter(
          "Account Type", '<>%1&<>%2', GenJnlLine6."Account Type"::Customer, GenJnlLine6."Account Type"::Vendor);
        GenJnlLine6.SetFilter(
          "Bal. Account Type", '<>%1&<>%2', GenJnlLine6."Bal. Account Type"::Customer, GenJnlLine6."Bal. Account Type"::Vendor);
        GenJnlLine4.SetFilter(
          "Account Type", '%1|%2', GenJnlLine4."Account Type"::Customer, GenJnlLine4."Account Type"::Vendor);
        GenJnlLine4.SetRange("Bal. Account No.", '');
        OnCopyFieldsOnAfterSetGenJnlFilters(GenJnlLine4, GenJnlLine6);
        CheckAndCopyBalancingData(GenJnlLine4, GenJnlLine6, TempGenJnlLine, false);

        GenJnlLine4.SetRange("Account Type");
        GenJnlLine4.SetRange("Bal. Account No.");
        GenJnlLine4.SetFilter(
          "Bal. Account Type", '%1|%2', GenJnlLine4."Bal. Account Type"::Customer, GenJnlLine4."Bal. Account Type"::Vendor);
        GenJnlLine4.SetRange("Account No.", '');
        CheckAndCopyBalancingData(GenJnlLine4, GenJnlLine6, TempGenJnlLine, true);

        JnlLineTotalQty := TempGenJnlLine.Count();
        LineCount := 0;
        if TempGenJnlLine.FindSet() then
            repeat
                LineCount := LineCount + 1;
                UpdateDialogUpdateBalLines(RefPostingSubState::"Update lines", LineCount, JnlLineTotalQty);
                GenJnlLine4.Get(TempGenJnlLine."Journal Template Name", TempGenJnlLine."Journal Batch Name", TempGenJnlLine."Line No.");
                CopyGenJnlLineBalancingData(GenJnlLine4, TempGenJnlLine);
                GenJnlLine4.Modify();
            until TempGenJnlLine.Next() = 0;
    end;

    local procedure CheckICDocument(var TempGenJnlLine1: Record "Gen. Journal Line" temporary)
    var
        TempGenJnlLine2: Record "Gen. Journal Line" temporary;
        CurrentICPartner: Code[20];
    begin
        TempGenJnlLine1.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
        TempGenJnlLine1.SetRange("Journal Template Name", TempGenJnlLine1."Journal Template Name");
        TempGenJnlLine1.SetRange("Journal Batch Name", TempGenJnlLine1."Journal Batch Name");
        TempGenJnlLine1.Find('-');
        repeat
            if (TempGenJnlLine1."Posting Date" <> LastDate) or (TempGenJnlLine1."Document Type" <> LastDocType) or (TempGenJnlLine1."Document No." <> LastDocNo) then begin
                TempGenJnlLine2 := TempGenJnlLine1;
                TempGenJnlLine1.SetRange("Posting Date", TempGenJnlLine1."Posting Date");
                TempGenJnlLine1.SetRange("Document No.", TempGenJnlLine1."Document No.");
                TempGenJnlLine1.SetFilter(TempGenJnlLine1."IC Partner Code", '<>%1', '');
                if TempGenJnlLine1.Find('-') then
                    CurrentICPartner := TempGenJnlLine1."IC Partner Code"
                else
                    CurrentICPartner := '';
                TempGenJnlLine1.SetRange("Posting Date");
                TempGenJnlLine1.SetRange("Document No.");
                TempGenJnlLine1.SetRange("IC Partner Code");
                LastDate := TempGenJnlLine1."Posting Date";
                LastDocType := TempGenJnlLine1."Document Type";
                LastDocNo := TempGenJnlLine1."Document No.";
                TempGenJnlLine1 := TempGenJnlLine2;
            end;
            if (CurrentICPartner <> '') and (TempGenJnlLine1."IC Direction" = TempGenJnlLine1."IC Direction"::Outgoing) then begin
                if (TempGenJnlLine1."Account Type" in [TempGenJnlLine1."Account Type"::"G/L Account", TempGenJnlLine1."Account Type"::"Bank Account"]) and
                   (TempGenJnlLine1."Bal. Account Type" in [TempGenJnlLine1."Bal. Account Type"::"G/L Account", TempGenJnlLine1."Account Type"::"Bank Account"]) and
                   (TempGenJnlLine1."Account No." <> '') and
                   (TempGenJnlLine1."Bal. Account No." <> '')
                then
                    Error(Text030, TempGenJnlLine1.FieldCaption("Account No."), TempGenJnlLine1.FieldCaption("Bal. Account No."));
                if ((TempGenJnlLine1."Account Type" in [TempGenJnlLine1."Account Type"::"G/L Account", TempGenJnlLine1."Account Type"::"Bank Account"]) and (TempGenJnlLine1."Account No." <> '')) xor
                   ((TempGenJnlLine1."Bal. Account Type" in [TempGenJnlLine1."Bal. Account Type"::"G/L Account", TempGenJnlLine1."Account Type"::"Bank Account"]) and
                    (TempGenJnlLine1."Bal. Account No." <> ''))
                then
                    TempGenJnlLine1.TestField(TempGenJnlLine1."IC Account No.")
                else
                    if TempGenJnlLine1."IC Account No." <> '' then
                        Error(Text031,
                          TempGenJnlLine1."Line No.", TempGenJnlLine1.FieldCaption("IC Account No."), TempGenJnlLine1.FieldCaption("Account No."),
                          TempGenJnlLine1.FieldCaption("Bal. Account No."));
            end else
                TempGenJnlLine1.TestField(TempGenJnlLine1."IC Account No.", '');
        until TempGenJnlLine1.Next() = 0;
    end;

    local procedure UpdateIncomingDocument(var GenJnlLine: Record "Gen. Journal Line")
    var
        IncomingDocument: Record "Incoming Document";
    begin
        OnBeforeUpdateIncomingDocument(GenJnlLine);
        IncomingDocument.UpdateIncomingDocumentFromPosting(
          GenJnlLine."Incoming Document Entry No.", GenJnlLine."Posting Date", GenJnlLine."Document No.");
    end;

    local procedure UnlinkIncDocFromGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        CurrGenJnlTemplate: Record "Gen. Journal Template";
    begin
        if GenJnlLine."Journal Template Name" = '' then
            exit;
        if not CurrGenJnlTemplate.Get(GenJnlLine."Journal Template Name") then
            exit;
        if not CurrGenJnlTemplate."Unlink Inc. Doc On Posting" then
            exit;
        GenJnlLine.GET(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Line No.");
        GenJnlLine."Incoming Document Entry No." := 0;
        GenJnlLine.Modify();
    end;

    local procedure CopyGenJnlLineBalancingData(var GenJnlLineTo: Record "Gen. Journal Line"; var GenJnlLineFrom: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyGenJnlLineBalancingData(IsHandled, GenJnlLineTo, GenJnlLineFrom);
        if not IsHandled then begin
            GenJnlLineTo."Bill-to/Pay-to No." := GenJnlLineFrom."Bill-to/Pay-to No.";
            GenJnlLineTo."Ship-to/Order Address Code" := GenJnlLineFrom."Ship-to/Order Address Code";
            GenJnlLineTo."VAT Registration No." := GenJnlLineFrom."VAT Registration No.";
            GenJnlLineTo."Country/Region Code" := GenJnlLineFrom."Country/Region Code";
        end;

        OnAfterCopyGenJnlLineBalancingData(GenJnlLineTo, GenJnlLineFrom);
    end;

    local procedure CheckGenPostingType(GenJnlLine6: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckGenPostingType(GenJnlLine6, AccountType, IsHandled);
        if IsHandled then
            exit;

        if (AccountType = AccountType::Customer) and
           (GenJnlLine6."Gen. Posting Type" = GenJnlLine6."Gen. Posting Type"::Purchase) or
           (AccountType = AccountType::Vendor) and
           (GenJnlLine6."Gen. Posting Type" = GenJnlLine6."Gen. Posting Type"::Sale)
        then
            GenJnlLine6.FieldError("Gen. Posting Type");
        if (AccountType = AccountType::Customer) and
           (GenJnlLine6."Bal. Gen. Posting Type" = GenJnlLine6."Bal. Gen. Posting Type"::Purchase) or
           (AccountType = AccountType::Vendor) and
           (GenJnlLine6."Bal. Gen. Posting Type" = GenJnlLine6."Bal. Gen. Posting Type"::Sale)
        then
            GenJnlLine6.FieldError("Bal. Gen. Posting Type");
    end;

    local procedure CheckAndCopyBalancingData(var GenJnlLine4: Record "Gen. Journal Line"; var GenJnlLine6: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; CheckBalAcount: Boolean)
    var
        TempGenJournalLineHistory: Record "Gen. Journal Line" temporary;
        AccountType: Enum "Gen. Journal Account Type";
        CheckAmount: Decimal;
        JnlLineTotalQty: Integer;
        RefPostingSubState: Option "Check account","Check bal. account","Update lines";
        LinesFound: Boolean;
    begin
        JnlLineTotalQty := CountGenJournalLines(GenJnlLine4);
        LineCount := 0;
        if CheckBalAcount then
            RefPostingSubState := RefPostingSubState::"Check bal. account"
        else
            RefPostingSubState := RefPostingSubState::"Check account";
        if GenJnlLine4.FindSet() then
            repeat
                LineCount := LineCount + 1;
                UpdateDialogUpdateBalLines(RefPostingSubState, LineCount, JnlLineTotalQty);
                TempGenJournalLineHistory.SetRange("Posting Date", GenJnlLine4."Posting Date");
                TempGenJournalLineHistory.SetRange("Document No.", GenJnlLine4."Document No.");
                if TempGenJournalLineHistory.IsEmpty() then begin
                    TempGenJournalLineHistory := GenJnlLine4;
                    TempGenJournalLineHistory.Insert();
                    GenJnlLine6.SetRange("Posting Date", GenJnlLine4."Posting Date");
                    GenJnlLine6.SetRange("Document No.", GenJnlLine4."Document No.");
                    LinesFound := GenJnlLine6.FindSet();
                end;
                if LinesFound then begin
                    AccountType := GetPostingTypeFilter(GenJnlLine4, CheckBalAcount);
                    CheckAmount := 0;
                    repeat
                        if (GenJnlLine6."Account No." = '') <> (GenJnlLine6."Bal. Account No." = '') then begin
                            OnCheckAndCopyBalancingDataOnBeforeCheckGenPostingType(GenJnlLine4, GenJnlLine6, AccountType);
                            CheckGenPostingType(GenJnlLine6, AccountType);
                            if GenJnlLine6."Bill-to/Pay-to No." = '' then begin
                                TempGenJnlLine := GenJnlLine6;
                                CopyGenJnlLineBalancingData(TempGenJnlLine, GenJnlLine4);
                                if TempGenJnlLine.Insert() then;
                            end;
                            CheckAmount := CheckAmount + GenJnlLine6.Amount;
                        end;
                        LinesFound := (GenJnlLine6.Next() <> 0);
                    until not LinesFound or (-GenJnlLine4.Amount = CheckAmount);
                end;
            until GenJnlLine4.Next() = 0;
    end;

    local procedure CountGenJournalLines(var GenJournalLine: Record "Gen. Journal Line") Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCountGenJournalLines(GenJournalLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := GenJournalLine.Count();
    end;

    local procedure UpdateGenJnlLineWithVATInfo(var GenJournalLine: Record "Gen. Journal Line"; GenJournalLineVATInfoSource: Record "Gen. Journal Line"; StartLineNo: Integer; LastLineNo: Integer)
    var
        GenJournalLineCopy: Record "Gen. Journal Line";
        Finish: Boolean;
        OldLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateGenJnlLineWithVATInfo(GenJournalLine, GenJournalLineVATInfoSource, StartLineNo, LastLineNo, IsHandled);
        if IsHandled then
            exit;

        OldLineNo := GenJournalLine."Line No.";
        GenJournalLine."Line No." := StartLineNo;
        Finish := false;
        if GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.") then
            repeat
                if GenJournalLine."Line No." <> GenJournalLineVATInfoSource."Line No." then begin
                    GenJournalLine."Bill-to/Pay-to No." := GenJournalLineVATInfoSource."Bill-to/Pay-to No.";
                    GenJournalLine."Country/Region Code" := GenJournalLineVATInfoSource."Country/Region Code";
                    GenJournalLine."VAT Registration No." := GenJournalLineVATInfoSource."VAT Registration No.";
                    GenJournalLine.Modify();
                    if GenJournalLine.IsTemporary then begin
                        GenJournalLineCopy.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
                        GenJournalLineCopy."Bill-to/Pay-to No." := GenJournalLine."Bill-to/Pay-to No.";
                        GenJournalLineCopy."Country/Region Code" := GenJournalLine."Country/Region Code";
                        GenJournalLineCopy."VAT Registration No." := GenJournalLine."VAT Registration No.";
                        GenJournalLineCopy.Modify();
                    end;
                end;
                Finish := GenJournalLine."Line No." = LastLineNo;
            until (GenJournalLine.Next() = 0) or Finish;

        if GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", OldLineNo) then;
    end;

    local procedure GetPostingTypeFilter(var GenJnlLine4: Record "Gen. Journal Line"; CheckBalAcount: Boolean): Enum "Gen. Journal Account Type"
    begin
        if CheckBalAcount then
            exit(GenJnlLine4."Bal. Account Type");
        exit(GenJnlLine4."Account Type");
    end;

    procedure UpdateDialog(PostingState: Integer; LineNo: Integer; TotalLinesQty: Integer)
    begin
        if GuiAllowed() then begin
            UpdatePostingState(PostingState, LineNo);
            Window.Update(2, GetProgressBarValue(PostingState, LineNo, TotalLinesQty));
        end;
    end;

    procedure UpdateDialogUpdateBalLines(PostingSubState: Integer; LineNo: Integer; TotalLinesQty: Integer)
    begin
        if GuiAllowed() then begin
            UpdatePostingState(RefPostingState::"Updating bal. lines", LineNo);
            Window.Update(2, GetProgressBarUpdateBalLinesValue(CalcProgressPercent(PostingSubState, 3, LineCount, TotalLinesQty)));
        end;
    end;

    local procedure UpdatePostingState(PostingState: Integer; LineNo: Integer)
    begin
        if GuiAllowed() then
            Window.Update(3, StrSubstNo('%1 (%2)', GetPostingStateMsg(PostingState), LineNo));
    end;

    local procedure UpdateCurrencyBalanceForRecurringLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCurrencyBalanceForRecurringLine(GenJnlLine, CurrencyBalance, LastCurrencyCode, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine."Recurring Method" <> GenJnlLine."Recurring Method"::" " then
            GenJnlLine.CalcFields(GenJnlLine."Allocated Amt. (LCY)");
        if (GenJnlLine."Recurring Method" = GenJnlLine."Recurring Method"::" ") or (GenJnlLine."Amount (LCY)" <> -GenJnlLine."Allocated Amt. (LCY)") then
            if GenJnlLine."Currency Code" <> LastCurrencyCode then
                LastCurrencyCode := ''
            else
                if (GenJnlLine."Currency Code" <> '') and ((GenJnlLine."Account No." = '') xor (GenJnlLine."Bal. Account No." = '')) then
                    if GenJnlLine."Account No." <> '' then
                        CurrencyBalance := CurrencyBalance + GenJnlLine.Amount
                    else
                        CurrencyBalance := CurrencyBalance - GenJnlLine.Amount;
    end;

    local procedure GetPostingStateMsg(PostingState: Integer) Result: Text
    begin
        case PostingState of
            RefPostingState::"Checking lines":
                exit(CheckingLinesMsg);
            RefPostingState::"Checking balance":
                exit(CheckingBalanceMsg);
            RefPostingState::"Updating bal. lines":
                exit(UpdatingBalLinesMsg);
            RefPostingState::"Posting Lines":
                exit(PostingLinesMsg);
            RefPostingState::"Posting revers. lines":
                exit(PostingReversLinesMsg);
            RefPostingState::"Updating lines":
                exit(UpdatingLinesMsg);
        end;

        OnAfterGetPostingStateMsg(PostingState, Result);
    end;

    local procedure GetProgressBarValue(PostingState: Integer; LineNo: Integer; TotalLinesQty: Integer): Integer
    begin
        exit(Round(100 * CalcProgressPercent(PostingState, GetNumberOfPostingStages(), LineNo, TotalLinesQty), 1));
    end;

    local procedure GetProgressBarUpdateBalLinesValue(PostingStatePercent: Decimal): Integer
    begin
        exit(Round((RefPostingState::"Updating bal. lines" * 100 + PostingStatePercent) / GetNumberOfPostingStages() * 100, 1));
    end;

    local procedure CalcProgressPercent(PostingState: Integer; NumberOfPostingStates: Integer; LineNo: Integer; TotalLinesQty: Integer): Decimal
    begin
        exit(100 / NumberOfPostingStates * (PostingState + LineNo / TotalLinesQty));
    end;

    local procedure GetNumberOfPostingStages(): Integer
    begin
        if GenJnlTemplate.Recurring then
            exit(6);

        exit(4);
    end;

    local procedure FindNextGLRegisterNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindNextGLRegisterNo(GLReg, GLRegNo, IsHandled);
        if IsHandled then
            exit;

        GLReg.LockTable();
        GLRegNo := GLReg.GetLastEntryNo() + 1;
    end;

    local procedure CheckGenJnlLine(var MarkedGenJnlLine: Record "Gen. Journal Line"; var GenJournalLine: Record "Gen. Journal Line")
    var
        StartBatchName: Code[10];
    begin
        if not GenJournalLine.Find() then
            GenJournalLine.FindSet();
        GenJournalLine.SetRange("Posting Date", 0D, WorkDate());
        OnCheckGenJnlLineOnAfterSetPostingDateFilter(GenJournalLine);
        if GenJournalLine.FindSet() then begin
            StartLineNo := GenJournalLine."Line No.";
            StartBatchName := GenJournalLine."Journal Batch Name";
            repeat
                if IsNotExpired(GenJournalLine) and IsPostingDateAllowed(GenJournalLine) and IsNotNullAmountLine(GenJournalLine) then begin
                    MarkedGenJnlLine := GenJournalLine;
                    if GenJournalLine."Recurring Method" in
                        [GenJournalLine."Recurring Method"::"BD Balance by Dimension", GenJournalLine."Recurring Method"::"RBD Reversing Balance by Dimension"]
                    then begin
                        if GenJournalLine."Journal Batch Name" <> GenJnlBatch.Name then
                            MarkedGenJnlLine.Insert();
                    end else
                        MarkedGenJnlLine.Insert();
                end;
                if GenJournalLine.Next() = 0 then
                    GenJournalLine.FindFirst();
            until (GenJournalLine."Line No." = StartLineNo) and (StartBatchName = GenJournalLine."Journal Batch Name");
        end;
        MarkedGenJnlLine := GenJournalLine;
    end;

    procedure ConfirmPostingUnvoidableChecks(JournalBatchName: Code[20]; JournalTemplateName: Code[20]): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
        ConfirmManagement: Codeunit "Confirm Management";
        BankPaymentType: Enum "Bank Payment Type";
    begin
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Bal. Account No.", '');
        GenJournalLine.SetRange("Bank Payment Type", BankPaymentType::"Manual Check");
        if GenJournalLine.FindFirst() then
            if GenJournalLine."Bal. Account Type" in [GenJournalLine."Account Type"::"Bank Account", GenJournalLine."Account Type"::"G/L Account"] then
                exit(ConfirmManagement.GetResponseOrDefault(ConfirmManualCheckTxt, true));
        exit(true);
    end;

    local procedure IsNotExpired(GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        exit((GenJournalLine."Expiration Date" = 0D) or (GenJournalLine."Expiration Date" >= GenJournalLine."Posting Date"));
    end;

    local procedure IsPostingDateAllowed(GenJournalLine: Record "Gen. Journal Line") IsAllowed: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsPostingDateAllowed(GenJournalLine, IsAllowed, IsHandled);
        if IsHandled then
            exit;

        IsAllowed := not GenJnlCheckLine.DateNotAllowed(GenJournalLine."Posting Date");
    end;

    local procedure IsNotNullAmountLine(GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        if GenJournalLine.Amount = 0 then begin
            if GenJournalLine."Recurring Method" in
                [GenJournalLine."Recurring Method"::"B  Balance", GenJournalLine."Recurring Method"::"RB Reversing Balance",
                GenJournalLine."Recurring Method"::"BD Balance by Dimension", GenJournalLine."Recurring Method"::"RBD Reversing Balance by Dimension"]
            then
                exit(true);
        end else
            exit(true);
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure PostReversingLines(var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        LineCount := 0;
        LastDocNo := '';
        LastPostedDocNo := '';
        if TempGenJnlLine.Find('-') then
            repeat
                GenJournalLine1 := TempGenJnlLine;
                LineCount := LineCount + 1;
                UpdateDialog(RefPostingState::"Posting revers. lines", LineCount, NoOfReversingRecords);
                CheckDocumentNo(GenJournalLine1);
                GenJournalLine2.Copy(GenJournalLine1);
                PrepareGenJnlLineAddCurr(GenJournalLine2);
                UpdateDimBalBatchName(GenJournalLine2);
                IsHandled := false;
                OnPostReversingLinesOnBeforeGenJnlPostLine(GenJournalLine2, GenJnlPostLine, IsHandled);
                if not IsHandled then
                    GenJnlPostLine.RunWithCheck(GenJournalLine2);
                PostAllocations(GenJournalLine1, true);
            until TempGenJnlLine.Next() = 0;

        OnAfterPostReversingLines(TempGenJnlLine, PreviewMode);
    end;

    local procedure UpdateAndDeleteLines(var GenJnlLine: Record "Gen. Journal Line")
    var
        TempGenJnlLine2: Record "Gen. Journal Line" temporary;
        RecordLinkManagement: Codeunit "Record Link Management";
        OldVATAmount: Decimal;
        OldVATPct: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAndDeleteLines(GenJnlLine, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        ClearDataExchEntries(GenJnlLine);
        if GenJnlTemplate.Recurring then begin
            // Recurring journal
            LineCount := 0;
            GenJnlLine2.Copy(GenJnlLine);
            GenJnlLine2.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
            GenJnlLine2.FindSet(true);
            repeat
                LineCount := LineCount + 1;
                UpdateDialog(RefPostingState::"Updating lines", LineCount, NoOfRecords);
                OldVATAmount := GenJnlLine2."VAT Amount";
                OldVATPct := GenJnlLine2."VAT %";
                OnUpdateAndDeleteLinesOnBeforeUpdatePostingDate(GenJnlLine2);
                if ShouldUpdateRecurringGenJournalLinePostingDate(GenJnlLine2) then
                    GenJnlLine2.Validate(
                      "Posting Date", CalcDate(GenJnlLine2."Recurring Frequency", GenJnlLine2."Posting Date"));
                if not
                   (GenJnlLine2."Recurring Method" in
                    [GenJnlLine2."Recurring Method"::"F  Fixed",
                     GenJnlLine2."Recurring Method"::"RF Reversing Fixed"])
                then
                    MultiplyAmounts(GenJnlLine2, 0)
                else
                    if (GenJnlLine2."VAT %" = OldVATPct) and (GenJnlLine2."VAT Amount" <> OldVATAmount) then
                        GenJnlLine2.Validate("VAT Amount", OldVATAmount);
                OnUpdateAndDeleteLinesOnBeforeModifyRecurringLine(GenJnlLine2);
                GenJnlLine2.Modify();
                OnUpdateAndDeleteLinesOnAfterModifyRecurringLine(GenJnlLine2);
            until GenJnlLine2.Next() = 0;
        end else begin
            // Not a recurring journal
            GenJnlLine2.Copy(GenJnlLine);
            GenJnlLine2.SetFilter("Account No.", '<>%1', '');
            if GenJnlLine2.FindLast() then; // Remember the last line
            GenJnlLine3.Copy(GenJnlLine);
            GenJnlLine3.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
            OnUpdateAndDeleteLinesOnBeforeDeleteNonRecurringLines(GenJnlLine3);
            RecordLinkManagement.RemoveLinks(GenJnlLine3);
            GenJnlLine3.DeleteAll();
            GenJnlLine3.Reset();
            GenJnlLine3.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
            GenJnlLine3.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");

            IsHandled := false;
            OnUpdateAndDeleteLinesOnBeforeInBatchName(GenJnlBatch, GenJnlLine3, IsHandled);
            if not IsHandled then begin
                if GenJnlTemplate."Increment Batch Name" then
                    if not GenJnlLine3.FindLast() then
                        IncrementBatchName(GenJnlLine);

                GenJnlLine3.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                if (GenJnlBatch."No. Series" = '') and not GenJnlLine3.FindLast() then begin
                    GenJnlLine3.Init();
                    GenJnlLine3."Journal Template Name" := GenJnlLine."Journal Template Name";
                    GenJnlLine3."Journal Batch Name" := GenJnlLine."Journal Batch Name";
                    GenJnlLine3."Line No." := 10000;
                    GenJnlLine3.Insert();
                    TempGenJnlLine2 := GenJnlLine2;
                    TempGenJnlLine2."Balance (LCY)" := 0;
                    GenJnlLine3.SetUpNewLine(TempGenJnlLine2, 0, true);
                    OnUpdateAndDeleteLinesOnBeforeModifyNonRecurringLine(GenJnlTemplate, GenJnlLine3, TempGenJnlLine2);
                    GenJnlLine3.Modify();
                    OnUpdateAndDeleteLinesOnAfterModifyNonRecurringLine(GenJnlTemplate, GenJnlLine3, TempGenJnlLine2);
                end;
            end;
        end;
    end;

    local procedure ShouldUpdateRecurringGenJournalLinePostingDate(var GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        if GenJournalLine."Posting Date" = 0D then
            exit(false);

        if not IsNotExpired(GenJournalLine) then
            exit(false);

        if not IsPostingDateAllowed(GenJournalLine) then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure Preview(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        PreviewMode := true;
        GenJnlLine.Copy(GenJournalLine);
        GenJnlLine.SetAutoCalcFields();
        Code(GenJnlLine);
    end;

    local procedure CheckRestrictions(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if not PreviewMode then
            GenJournalLine.OnCheckGenJournalLinePostRestrictions();
    end;

    local procedure ClearDataExchEntries(var PassedGenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearDataExchEntries(PassedGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.Copy(PassedGenJnlLine);
        if GenJnlLine.FindSet() then
            repeat
                GenJnlLine.ClearDataExchangeEntries(true);
            until GenJnlLine.Next() = 0;
    end;

    local procedure PostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CurrentICPartner: Code[20]; ICTransactionNo: Integer) Result: Boolean
    var
        IsPosted: Boolean;
        SavedPostingDate: Date;
        SavedVATReportingDate: Date;
    begin
        if GenJournalLine.NeedCheckZeroAmount() and (GenJournalLine.Amount = 0) and GenJournalLine.IsRecurring() then
            exit(false);

        GenJnlPostLine.SetPreviewMode(PreviewMode);
        LineCount := LineCount + 1;
        if CurrentICPartner <> '' then
            GenJournalLine."IC Partner Code" := CurrentICPartner;
        UpdateDialog(RefPostingState::"Posting Lines", LineCount, NoOfRecords);
        MakeRecurringTexts(GenJournalLine);
        OnPostGenJournalLineOnBeforeCheckDocumentNo(GenJournalLine, GLRegNo);
        CheckDocumentNo(GenJournalLine);
        GenJnlLine5.Copy(GenJournalLine);
        PrepareGenJnlLineAddCurr(GenJnlLine5);
        UpdateIncomingDocument(GenJnlLine5);
        UpdateDimBalBatchName(GenJnlLine5);
        OnBeforePostGenJnlLine(GenJnlLine5, SuppressCommit, IsPosted, GenJnlPostLine, GenJournalLine);
        if not IsPosted then begin
            GenJnlPostLine.RunWithoutCheck(GenJnlLine5);
            InsertPostedGenJnlLine(GenJournalLine);
            RemoveRecordLink(GenJournalLine);
            UnlinkIncDocFromGenJnlLine(GenJournalLine);
        end;
        OnAfterPostGenJnlLine(GenJnlLine5, SuppressCommit, GenJnlPostLine, IsPosted, GenJournalLine);
        if (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) and (CurrentICPartner <> '') and
           (GenJournalLine."IC Direction" = GenJournalLine."IC Direction"::Outgoing) and (ICTransactionNo > 0)
        then
            ICOutboxMgt.CreateOutboxJnlLine(ICTransactionNo, 1, GenJnlLine5);
        if (GenJournalLine."Recurring Method".AsInteger() >= GenJournalLine."Recurring Method"::"RF Reversing Fixed".AsInteger()) and (GenJournalLine."Posting Date" <> 0D) and (GenJournalLine."Recurring Method".AsInteger() <> GenJournalLine."Recurring Method"::"BD Balance by Dimension".AsInteger()) then begin
            SavedPostingDate := GenJournalLine."Posting Date";
            if GenJournalLine."VAT Reporting Date" = 0D then
                GenJournalLine."VAT Reporting Date" := GenJournalLine."Posting Date";
            SavedVATReportingDate := GenJournalLine."VAT Reporting Date";

            GenJournalLine."Posting Date" := CalcReversePostingDate(GenJournalLine);
            GenJournalLine."Document Date" := GenJournalLine."Posting Date";
            GenJournalLine."VAT Reporting Date" := GenJournalLine."Posting Date";
            GenJournalLine."Due Date" := GenJournalLine."Posting Date";
            OnPostGenJournalLineOnBeforeMultiplyAmounts(GenJnlLine5, SavedPostingDate, SavedVATReportingDate, GenJournalLine);
            MultiplyAmounts(GenJournalLine, -1);
            TempGenJnlLine4 := GenJournalLine;
            TempGenJnlLine4."Reversing Entry" := true;
            TempGenJnlLine4.Insert();
            NoOfReversingRecords := NoOfReversingRecords + 1;
            GenJournalLine."Posting Date" := SavedPostingDate;
            GenJournalLine."Document Date" := GenJournalLine."Posting Date";
            GenJournalLine."VAT Reporting Date" := SavedVATReportingDate;
            GenJournalLine."Due Date" := GenJournalLine."Posting Date";
        end;
        PostAllocations(GenJournalLine, false);
        Result := true;
        OnAfterPostGenJournalLine(GenJournalLine, Result, GenJnlPostLine);
    end;

    local procedure CheckLine(var GenJnlLine: Record "Gen. Journal Line"; var PostingAfterWorkingDateConfirmed: Boolean)
    var
        GenJournalLineToUpdate: Record "Gen. Journal Line";
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorContextElement: Codeunit "Error Context Element";
        IsModified: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLine(GenJnlLine, PostingAfterWorkingDateConfirmed, IsHandled);
        if IsHandled then
            exit;

        GenJournalLineToUpdate.Copy(GenJnlLine);
        CheckRecurringLine(GenJournalLineToUpdate);
        IsModified := UpdateRecurringAmt(GenJournalLineToUpdate);
        CheckAllocations(GenJournalLineToUpdate);
        OnCheckLineOnAfterCheckAllocations(GenJournalLineToUpdate);
        GenJnlLine5.Copy(GenJournalLineToUpdate);
        if not PostingAfterWorkingDateConfirmed then
            PostingAfterWorkingDateConfirmed :=
              PostingSetupMgt.ConfirmPostingAfterWorkingDate(
                ConfirmPostingAfterWorkingDateQst, GenJnlLine5."Posting Date");
        PrepareGenJnlLineAddCurr(GenJnlLine5);
        ErrorMessageManagement.PushContext(ErrorContextElement, GenJnlLine5.RecordId, 0, '');
        OnCheckLineOnBeforeRunCheck(GenJnlLine5);
        GenJnlCheckLine.RunCheck(GenJnlLine5);
        ErrorMessageManagement.PopContext(ErrorContextElement);
        CheckRestrictions(GenJnlLine5);
        GenJnlLine.Copy(GenJournalLineToUpdate);
        if IsModified then
            GenJnlLine.Modify();
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure IsNonZeroAmount(GenJournalLine: Record "Gen. Journal Line") Result: Boolean
    begin
        Result := GenJournalLine.Amount <> 0;
        OnAfterIsNonZeroAmount(GenJournalLine, Result);
    end;

    local procedure IncrementBatchName(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIncrementBatchName(GenJnlBatch, IsHandled);
        if IsHandled then
            exit;

        if IncStr(GenJnlLine."Journal Batch Name") <> '' then begin
            GenJnlBatch.Delete();
            if GenJnlTemplate.Type = GenJnlTemplate.Type::Assets then
                FAJnlSetup.IncGenJnlBatchName(GenJnlBatch);
            GenJnlBatch.Name := IncStr(GenJnlLine."Journal Batch Name");
            if GenJnlBatch.Insert() then;
            GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
            OnAfterIncrementBatchName(GenJnlBatch, GenJnlLine2."Journal Batch Name");
        end;
    end;

    procedure InsertPostedGenJnlLine(GenJournalLine: Record "Gen. Journal Line")
    var
        PostedGenJournalBatch: Record "Posted Gen. Journal Batch";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
    begin
        if GenJnlTemplate.Recurring then
            exit;

        if not GenJnlBatch."Copy to Posted Jnl. Lines" then
            exit;

        if GenJournalLine.EmptyLine() then
            exit;

        if not PostedGenJournalBatch.Get(GenJnlBatch."Journal Template Name", GenJnlBatch.Name) then
            PostedGenJournalBatch.InsertFromGenJournalBatch(GenJnlBatch);

        PostedGenJournalLine.InsertFromGenJournalLine(GenJournalLine, GLRegNo, FirstLine);
        FirstLine := false;
    end;

    local procedure CalcReversePostingDate(GenJournalLine: Record "Gen. Journal Line") PostingDate: Date
    begin
        OnBeforeCalcReversePostingDate(GenJournalLine);

        if Format(GenJournalLine."Reverse Date Calculation") <> '' then begin
            PostingDate := CalcDate(GenJournalLine."Reverse Date Calculation", GenJournalLine."Posting Date");
            if PostingDate <= GenJournalLine."Posting Date" then
                Error(ReversePostingDateErr, GenJournalLine."Posting Date" + 1);
        end else
            PostingDate := GenJournalLine."Posting Date" + 1;

        OnAfterCalcReversePostingDate(GenJournalLine, PostingDate);
    end;

    local procedure PrepareDimensionBalancedGenJnlLine(var SrcGenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempBatchName: Code[10];
    begin
        GenJournalLine.Copy(SrcGenJournalLine);
        GenJournalLine.SetFilter(
            "Recurring Method", '%1|%2',
            GenJournalLine."Recurring Method"::"BD Balance by Dimension",
            GenJournalLine."Recurring Method"::"RBD Reversing Balance by Dimension");
        if not GenJournalLine.FindFirst() then
            exit;

        CheckDimSetEntryConsistency(GenJournalLine);
        SavedGenJournalLine := SrcGenJournalLine;
        TempBatchName := CreateDimBalGenJnlBatch(SrcGenJournalLine);
        CreateDimBalGenJnlLines(GenJournalLine);
        SrcGenJournalLine.FilterGroup(2);
        SrcGenJournalLine.SetFilter("Journal Batch Name", '%1|%2', SrcGenJournalLine."Journal Batch Name", TempBatchName);
        SrcGenJournalLine.FilterGroup(0);
        SrcGenJournalLine.SetFilter("Journal Batch Name", '%1|%2', SrcGenJournalLine."Journal Batch Name", TempBatchName);
    end;

    local procedure CreateDimBalGenJnlBatch(SrcGenJournalLine: Record "Gen. Journal Line"): Code[10];
    var
        SrcGenJournalBatch: Record "Gen. Journal Batch";
        DstGenJournalBatch: Record "Gen. Journal Batch";
    begin
        SrcGenJournalBatch.Get(SrcGenJournalLine."Journal Template Name", SrcGenJournalLine."Journal Batch Name");
        DstGenJournalBatch := SrcGenJournalBatch;
        DstGenJournalBatch.Name := NewTempBatchName();
        DstGenJournalBatch.Description := GetSessionId();
        DstGenJournalBatch.Insert();
        exit(DstGenJournalBatch.Name);
    end;

    local procedure FindTempBatch(var GenJournalBatch: Record "Gen. Journal Batch"): Boolean;
    begin
        GenJournalBatch.SetFilter(Name, StrSubstNo(TwoPlaceHoldersTok, TempBatchNameTxt, '*'));
        exit(GenJournalBatch.FindLast());
    end;

    local procedure GetSessionId(): Text[100];
    begin
        exit(StrSubstNo(ServiceSessionTok, ServiceInstanceId(), SessionId()));
    end;

    local procedure GetTempBatchName(): Code[10];
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.SetRange(Description, GetSessionId());
        if FindTempBatch(GenJournalBatch) then
            exit(GenJournalBatch.Name);
    end;

    local procedure NewTempBatchName() Name: Code[10];
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if FindTempBatch(GenJournalBatch) then
            Name := GenJournalBatch.Name
        else
            Name := StrSubstNo(TwoPlaceHoldersTok, TempBatchNameTxt, '000');
        exit(IncStr(Name));
    end;

    local procedure CreateDimBalGenJnlLines(var SrcGenJournalLine: Record "Gen. Journal Line");
    var
        GenJournalLine: Record "Gen. Journal Line";
        DimBalGLEntry: Record "G/L Entry";
        TempInteger: Record Integer temporary;
        TempBatchName: Code[10];
        LineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDimBalGenJnlLines(SrcGenJournalLine, IsHandled);
        if IsHandled then
            exit;

        TempBatchName := GetTempBatchName();
        if SrcGenJournalLine.FindSet() then
            repeat
                DimBalGLEntry.Reset();
                DimBalGLEntry.SetRange("G/L Account No.", SrcGenJournalLine."Account No.");
                DimBalGLEntry.SetRange("Posting Date", 0D, SrcGenJournalLine."Posting Date");
                SetGLEntryDimensionFilters(DimBalGLEntry, SrcGenJournalLine);
                if DimBalGLEntry.FindSet() then
                    repeat
                        TempInteger.Number := DimBalGLEntry."Dimension Set ID";
                        if TempInteger.Insert() then;
                    until DimBalGLEntry.Next() = 0;

                if TempInteger.FindSet() then
                    repeat
                        LineNo += 1;
                        DimBalGLEntry.SetRange("Dimension Set ID", TempInteger.Number);
                        DimBalGLEntry.CalcSums(Amount);
                        if DimBalGLEntry.Amount <> 0 then begin
                            GenJournalLine := SrcGenJournalLine;
                            GenJournalLine."Journal Batch Name" := TempBatchName;
                            GenJournalLine."Line No." := LineNo;
                            GenJournalLine.Validate("Dimension Set ID", TempInteger.Number);
                            GenJournalLine.Validate(Amount, -DimBalGLEntry.Amount);
                            GenJournalLine.Insert();

                            CopyDimBalGenJnlAlloc(SrcGenJournalLine, GenJournalLine);
                        end;
                    until TempInteger.Next() = 0;
            until SrcGenJournalLine.Next() = 0;
    end;

    local procedure SetGLEntryDimensionFilters(var DimBalGLEntry: Record "G/L Entry"; SrcGenJournalLine: Record "Gen. Journal Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
    begin
        GeneralLedgerSetup.Get();

        GenJnlDimFilter.SetRange("Journal Template Name", SrcGenJournalLine."Journal Template Name");
        GenJnlDimFilter.SetRange("Journal Batch Name", SrcGenJournalLine."Journal Batch Name");
        GenJnlDimFilter.SetRange("Journal Line No.", SrcGenJournalLine."Line No.");
        GenJnlDimFilter.SetFilter("Dimension Value Filter", '<>%1', '');
        if GenJnlDimFilter.FindSet() then
            repeat
                case GenJnlDimFilter."Dimension Code" of
                    GeneralLedgerSetup."Global Dimension 1 Code":
                        DimBalGLEntry.SetFilter("Global Dimension 1 Code", GenJnlDimFilter."Dimension Value Filter");
                    GeneralLedgerSetup."Global Dimension 2 Code":
                        DimBalGLEntry.SetFilter("Global Dimension 2 Code", GenJnlDimFilter."Dimension Value Filter");
                    GeneralLedgerSetup."Shortcut Dimension 3 Code":
                        DimBalGLEntry.SetFilter("Shortcut Dimension 3 Code", GenJnlDimFilter."Dimension Value Filter");
                    GeneralLedgerSetup."Shortcut Dimension 4 Code":
                        DimBalGLEntry.SetFilter("Shortcut Dimension 4 Code", GenJnlDimFilter."Dimension Value Filter");
                    GeneralLedgerSetup."Shortcut Dimension 5 Code":
                        DimBalGLEntry.SetFilter("Shortcut Dimension 5 Code", GenJnlDimFilter."Dimension Value Filter");
                    GeneralLedgerSetup."Shortcut Dimension 6 Code":
                        DimBalGLEntry.SetFilter("Shortcut Dimension 6 Code", GenJnlDimFilter."Dimension Value Filter");
                    GeneralLedgerSetup."Shortcut Dimension 7 Code":
                        DimBalGLEntry.SetFilter("Shortcut Dimension 7 Code", GenJnlDimFilter."Dimension Value Filter");
                    GeneralLedgerSetup."Shortcut Dimension 8 Code":
                        DimBalGLEntry.SetFilter("Shortcut Dimension 8 Code", GenJnlDimFilter."Dimension Value Filter");
                end;
            until GenJnlDimFilter.Next() = 0;
    end;

    local procedure CopyDimBalGenJnlAlloc(SrcGenJournalLine: Record "Gen. Journal Line"; DstGenJournalLine: Record "Gen. Journal Line")
    var
        SrcGenJnlAllocation: Record "Gen. Jnl. Allocation";
        DstGenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        SrcGenJnlAllocation.SetRange("Journal Template Name", SrcGenJournalLine."Journal Template Name");
        SrcGenJnlAllocation.SetRange("Journal Batch Name", SrcGenJournalLine."Journal Batch Name");
        SrcGenJnlAllocation.SetRange("Journal Line No.", SrcGenJournalLine."Line No.");
        if SrcGenJnlAllocation.FindSet() then
            repeat
                DstGenJnlAllocation := SrcGenJnlAllocation;
                DstGenJnlAllocation."Journal Batch Name" := DstGenJournalLine."Journal Batch Name";
                DstGenJnlAllocation."Journal Line No." := DstGenJournalLine."Line No.";
                DstGenJnlAllocation.Insert();
            until SrcGenJnlAllocation.Next() = 0;
    end;

    local procedure DeleteDimBalBatch(var SrcGenJournalLine: Record "Gen. Journal Line"; Posted: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if GenJournalBatch.Get(GenJnlTemplate.Name, GetTempBatchName()) then begin
            GenJournalBatch.Delete(true);
            if Posted then
                SrcGenJournalLine := SavedGenJournalLine;
        end;
    end;

    local procedure UpdateDimBalBatchName(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Recurring Method" in [GenJournalLine."Recurring Method"::"BD Balance by Dimension", GenJournalLine."Recurring Method"::"RBD Reversing Balance by Dimension"] then
            GenJournalLine."Journal Batch Name" := SavedGenJournalLine."Journal Batch Name";
    end;

    local procedure CheckDimSetEntryConsistency(GenJournalLine: Record "Gen. Journal Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ErrorLogged: Boolean;
    begin
        GeneralLedgerSetup.Get();

        CheckShortcutDimConsistency(GeneralLedgerSetup."Global Dimension 1 Code", 0, ErrorLogged, GenJournalLine);
        CheckShortcutDimConsistency(GeneralLedgerSetup."Global Dimension 2 Code", 0, ErrorLogged, GenJournalLine);
        CheckShortcutDimConsistency(GeneralLedgerSetup."Shortcut Dimension 3 Code", 3, ErrorLogged, GenJournalLine);
        CheckShortcutDimConsistency(GeneralLedgerSetup."Shortcut Dimension 4 Code", 4, ErrorLogged, GenJournalLine);
        CheckShortcutDimConsistency(GeneralLedgerSetup."Shortcut Dimension 5 Code", 5, ErrorLogged, GenJournalLine);
        CheckShortcutDimConsistency(GeneralLedgerSetup."Shortcut Dimension 6 Code", 6, ErrorLogged, GenJournalLine);
        CheckShortcutDimConsistency(GeneralLedgerSetup."Shortcut Dimension 7 Code", 7, ErrorLogged, GenJournalLine);
        CheckShortcutDimConsistency(GeneralLedgerSetup."Shortcut Dimension 8 Code", 8, ErrorLogged, GenJournalLine);
    end;

    local procedure CheckShortcutDimConsistency(ShortcutDimensionCode: Code[20]; ShortcutDimensionNo: Integer; var ErrorLogged: Boolean; GenJournalLine: Record "Gen. Journal Line")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        ErrorMsgMgt: Codeunit "Error Message Management";
        ErrorContextElement: Codeunit "Error Context Element";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
    begin
        if ErrorLogged then
            exit;

        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimensionCode);
        DimensionSetEntry.SetFilter("Global Dimension No.", '<>%1', ShortcutDimensionNo);
        if DimensionSetEntry.FindFirst() then begin
            ErrorLogged := true;
            ErrorMsgMgt.PushContext(ErrorContextElement, GenJournalLine.RecordId, 0, '');
            ErrorMsgMgt.LogContextFieldError(
              GenJournalLine.FieldNo("Recurring Method"), GlblDimNoInconsistErr, DimensionSetEntry, DimensionSetEntry.FieldNo("Global Dimension No."), ForwardLinkMgt.GetHelpCodeForTroubleshootingDimensions());
            ErrorMsgMgt.Finish(GenJournalLine.RecordId);
        end;
    end;


    local procedure RemoveRecordLink(GenJournalLine: Record "Gen. Journal Line")
    var
        RecordLink: Record "Record Link";
        RecordRef: RecordRef;
        RecVariant: Variant;
    begin
        RecVariant := GenJournalLine;
        RecordRef.GetTable(RecVariant);
        RecordLink.SetRange("Record ID", RecordRef.RecordId());
        if RecordLink.FindSet() then
            RecordLink.DeleteAll();
    end;

    local procedure AssignVATDateIfEmpty(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignVATDateIfEmpty(GenJnlLine, IsHandled);
        if IsHandled then
            exit;
        if GenJnlLine."VAT Reporting Date" = 0D then begin
            GLSetup.Get();
            if (GenJnlLine."Document Date" = 0D) and (GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Document Date") then
                GenJnlLine."VAT Reporting Date" := GenJnlLine."Posting Date"
            else
                GenJnlLine."VAT Reporting Date" := GLSetup.GetVATDate(GenJnlLine."Posting Date", GenJnlLine."Document Date");
            GenJnlLine.Modify();
        end;
    end;

    local procedure CheckIfDiffPostingDatesExist(GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetLoadFields("Journal Template Name", "Journal Batch Name", "Posting Date");
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetFilter("Posting Date", '<>%1', PostingDate);
        exit(not GenJournalLine.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; LastDocNo: code[20]; LastPostedDocNo: code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var GenJournalLine: Record "Gen. Journal Line"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlLineBalancingData(var GenJnlLineTo: Record "Gen. Journal Line"; GenJnlLineFrom: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPostingStateMsg(PostingState: Integer; var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; IsPosted: Boolean; var PostingGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessLines(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalLine: Record "Gen. Journal Line"; SuppressCommit: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldSetDocNoToLastPosted(var GenJournalLine: Record "Gen. Journal Line"; LastDocNo: Code[20]; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBalance(GenJnlTemplate: Record "Gen. Journal Template"; GenJnlLine: Record "Gen. Journal Line"; CurrentBalance: Decimal; CurrentBalanceReverse: Decimal; CurrencyBalance: Decimal; StartLineNo: Integer; StartLineNoReverse: Integer; LastDocType: Option; LastDocNo: Code[20]; LastDate: Date; LastCurrencyCode: Code[10]; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCorrection(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; GenJnlTemplate: Record "Gen. Journal Template"; var LastDate: Date; var LastDocType: Enum "Gen. Journal Document Type"; var LastDocNo: Code[20]; var DocCorrection: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenPostingType(GenJnlLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearDataExchEntries(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var GenJournalLine: Record "Gen. Journal Line"; PreviewMode: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCountGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalLineCount: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCommit(GLRegNo: Integer; var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFields(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDimBalGenJnlLines(var SrcGenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIfCheckBalance(GenJnlTemplate: Record "Gen. Journal Template"; GenJnlLine: Record "Gen. Journal Line"; var LastDocType: Option; var LastDocNo: Code[20]; var LastDate: Date; var CheckIfBalance: Boolean; CommitIsSuppressed: Boolean; var IsHandled: Boolean; CurrentBalance: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsPostingDateAllowed(var GenJournalLine: Record "Gen. Journal Line"; var IsAllowed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostAllocations(var AllocateGenJnlLine: Record "Gen. Journal Line"; Reversing: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; CommitIsSuppressed: Boolean; var Posted: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var PostingGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessLines(var GenJournalLine: Record "Gen. Journal Line"; PreviewMode: Boolean; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessBalanceOfLines(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalTemplate: Record "Gen. Journal Template"; var IsKeySet: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRaiseExceedLengthError(var GenJournalBatch: Record "Gen. Journal Batch"; var RaiseError: Boolean; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeThrowPreviewError(var GenJournalLine: Record "Gen. Journal Line"; GLRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRecurringAmt(var GenJnlLine2: Record "Gen. Journal Line"; var Updated: Boolean; var IsHandled: Boolean; var GLEntry: Record "G/L Entry"; var GLAccount: Record "G/L Account"; var GenJnlAllocation: Record "Gen. Jnl. Allocation")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateAndDeleteLines(var GenJournalLine: Record "Gen. Journal Line"; CommitIsSuppressed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateIncomingDocument(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckLineOnBeforeRunCheck(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncrementBatchName(var GenJournalBatch: Record "Gen. Journal Batch"; OldBatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAllocations(GenJournalLine: Record "Gen. Journal Line"; Reversing: Boolean; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeRecurringTexts(var GenJournalLine: Record "Gen. Journal Line"; var AccountingPeriod: Record "Accounting Period"; var Day: Integer; var Week: Integer; var Month: Integer; var MonthText: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAllocationsOnBeforeCopyFromGenJnlAlloc(var GenJournalLine: Record "Gen. Journal Line"; var AllocateGenJournalLine: Record "Gen. Journal Line"; var Reversing: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMultiplyAmounts(var GenJournalLine: Record "Gen. Journal Line"; Factor: Decimal; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReversingLines(var GenJournalLine: Record "Gen. Journal Line"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterProcessBalanceOfLines(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateLineBalance(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMultiplyJobAmounts(var GenJournalLine: Record "Gen. Journal Line"; Factor: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAllocationsOnBeforePostNotReversingLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; AllocateGenJournalLine: Record "Gen. Journal Line"; var GenJnlAllocation: Record "Gen. Jnl. Allocation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAllocationsOnBeforePostReversingLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; AllocateGenJournalLine: Record "Gen. Journal Line"; var GenJnlAllocation: Record "Gen. Jnl. Allocation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAllocationsOnBeforePrepareGenJnlLineAddCurr(var GenJournalLine: Record "Gen. Journal Line"; AllocateGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReversingLinesOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessBalanceOfLinesOnAfterCalcShouldCheckDocNoBasedOnNoSeries(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; var ShouldCheckDocNoBasedOnNoSeries: Boolean; var SkipCheckingPostingNoSeries: Boolean; LastDocNo: Code[20]; CurrentBalance: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessLinesOnAfterAssignGLNegNo(var GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register"; GLRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessLinesOnAfterPostGenJnlLines(var GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register"; var GLRegNo: Integer; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessLinesOnBeforeSetGLRegNoToZero(var GenJournalLine: Record "Gen. Journal Line"; var GLRegNo: Integer; var IsHandled: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessLinesOnBeforeClearPostingCodeunits(var GenJournalLine: Record "Gen. Journal Line"; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsNonZeroAmount(GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessICLinesOnBeforeHandledICInboxTransModify(var HandledICInboxTrans: Record "Handled IC Inbox Trans."; GenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAllocationsOnAfterCalcShowAllocationsRecurringError(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var GenJournalLine: Record "Gen. Journal Line"; var ShowAllocationsRecurringError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndCopyBalancingDataOnBeforeCheckGenPostingType(GenJnlLine4: Record "Gen. Journal Line"; GenJnlLine6: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFieldsOnAfterSetGenJnlFilters(var GenJnlLine4: Record "Gen. Journal Line"; var GenJnlLine6: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRecurringLine(GenJnlLine2: Record "Gen. Journal Line"; GenJnlTemplate: Record "Gen. Journal Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncrementBatchName(var GenJnlBatch: Record "Gen. Journal Batch"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCurrencyBalanceForRecurringLine(var GenJnlLine: Record "Gen. Journal Line"; var CurrencyBalance: Decimal; var LastCurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAndDeleteLinesOnBeforeModifyRecurringLine(var GenJnlLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAndDeleteLinesOnBeforeDeleteNonRecurringLines(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGenJournalLineOnBeforeCheckDocumentNo(var GenJnlLine: Record "Gen. Journal Line"; GLRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAndDeleteLinesOnAfterModifyRecurringLine(var GenJnlLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAndDeleteLinesOnBeforeModifyNonRecurringLine(GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAndDeleteLinesOnAfterModifyNonRecurringLine(GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReversePostingDate(GenJournalLine: Record "Gen. Journal Line"; var PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAndDeleteLinesOnBeforeInBatchName(var GenJnlBatch: Record "Gen. Journal Batch"; var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAndDeleteLinesOnBeforeUpdatePostingDate(var GenJnlLine2: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLine(var GenJournalLine: Record "Gen. Journal Line"; var PostingAfterWorkingDateConfirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessICLines(var CurrentICPartner: Code[20]; var ICTransactionNo: Integer; var ICLastDocNo: Code[20]; var ICLastDate: Date; var ICLastDocType: Enum "Gen. Journal Document Type"; var GenJournalLine: Record "Gen. Journal Line"; var TempGenJournalLine: Record "Gen. Journal Line" temporary; var ICProccessedLines: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateGenJnlLineWithVATInfo(var GenJournalLine: Record "Gen. Journal Line"; GenJournalLineVATInfoSource: Record "Gen. Journal Line"; StartLineNo: Integer; LastLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessLinesOnAfterProcessICTransaction(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckLineOnAfterCheckAllocations(GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcReversePostingDate(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyGenJnlLineBalancingData(var IsHandled: Boolean; GenJnlLineTo: Record "Gen. Journal Line"; GenJnlLineFrom: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; var LastDocumentNo: code[20]; var LastPostedDocumentNo: code[20]; var NoSeriesBatch: Codeunit "No. Series - Batch"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessBalanceOfLinesOnAfterSetVATEntryCreated(GenJournalLine: Record "Gen. Journal Line"; var VATEntryCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAllocations(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckGenJnlLineOnAfterSetPostingDateFilter(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignVATDateIfEmpty(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNextGLRegisterNo(var GLRegister: Record "G/L Register"; var GLRegNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessBalanceOfLinesOnBeforeCheckLine(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGenJournalLineOnBeforeMultiplyAmounts(var GenJournalLine: Record "Gen. Journal Line"; SavedPostingDate: Date; SavedVATReportingDate: Date; var PostingGenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}
