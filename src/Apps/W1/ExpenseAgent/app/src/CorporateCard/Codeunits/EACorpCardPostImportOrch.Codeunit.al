// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Orchestrates post-import processing: merchant normalization, matching, and draft creation.
/// Processes each staged transaction in its own transaction after the import has committed.
/// </summary>
codeunit 7423 "EA Corp Card Post Import Orch"
{
    Access = Internal;
    Permissions = tabledata Expense = rm;
    TableNo = "EA Corp Card Trans";

    trigger OnRun()
    begin
        ProcessTransaction(Rec);
    end;

    var
        TransactionExpenseWriter: Interface "EA Corp Card Expense Writer";

    internal procedure ProcessStatementPostImport(StatementEntryNo: Integer; ExpenseWriter: Interface "EA Corp Card Expense Writer")
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        PostImportWorker: Codeunit "EA Corp Card Post Import Orch";
        CorpCardErrorContext: Codeunit "EA Corp Card Error Context";
        AuditSubscribers: Codeunit "EA Corp Card Audit Subscribers";
        TransactionEntryNos: List of [Integer];
        TransactionEntryNo: Integer;
        ProcessingError: Text;
        MatchedCount: Integer;
        UnmatchedCount: Integer;
    begin
        CorpCardStatement.Get(StatementEntryNo);
        CorpCardStatement.TestField(Status, CorpCardStatement.Status::Imported);

        CorpCardTrans.SetRange("Statement Entry No.", StatementEntryNo);
        CorpCardTrans.SetFilter(Status, '%1|%2', CorpCardTrans.Status::Imported, CorpCardTrans.Status::Exception);

        if not CorpCardTrans.FindSet() then
            exit;
        repeat
            if CorpCardTrans.Status = CorpCardTrans.Status::Imported then
                TransactionEntryNos.Add(CorpCardTrans."Entry No.")
            else
                if HasProcessingException(CorpCardTrans) then
                    TransactionEntryNos.Add(CorpCardTrans."Entry No.");
        until CorpCardTrans.Next() = 0;

        Commit();
        foreach TransactionEntryNo in TransactionEntryNos do begin
            CorpCardTrans.Get(TransactionEntryNo);
            Clear(PostImportWorker);
            PostImportWorker.SetExpenseWriter(ExpenseWriter);
            CorpCardErrorContext.ClearErrorInfo();
            ClearLastError();
            if PostImportWorker.Run(CorpCardTrans) then begin
                CorpCardTrans.Get(TransactionEntryNo);
                if CorpCardTrans.Status = CorpCardTrans.Status::Matched then
                    MatchedCount += 1
                else
                    if CorpCardTrans.Status = CorpCardTrans.Status::Imported then
                        UnmatchedCount += 1;
            end else begin
                ProcessingError := GetLastErrorText();
                RecordProcessingFailure(TransactionEntryNo, ProcessingError);
                UnmatchedCount += 1;
                Commit();
            end;
            CorpCardErrorContext.ClearErrorInfo();
        end;
        AuditSubscribers.LogMatchingCompleted(MatchedCount, UnmatchedCount);
    end;

    internal procedure SetExpenseWriter(ExpenseWriter: Interface "EA Corp Card Expense Writer")
    begin
        TransactionExpenseWriter := ExpenseWriter;
    end;

    local procedure ProcessTransaction(var CorpCardTrans: Record "EA Corp Card Trans")
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CorpCardValidateMgt: Codeunit "EA Corp Card Validate Mgt";
        MerchantNorm: Codeunit "EA Corp Card Merchant Norm";
        EnhancedMatchMgt: Codeunit "EA Corp Card Enh. Match Mgt";
        AuditSubscribers: Codeunit "EA Corp Card Audit Subscribers";
        MatchedExpenseNo: Code[20];
        DraftExpenseNo: Code[20];
        ValidationReason: Text[250];
    begin
        CorpCardStatement.LockTable();
        CorpCardStatement.Get(CorpCardTrans."Statement Entry No.");
        CorpCardStatement.TestField(Status, CorpCardStatement.Status::Imported);
        CorpCardTrans.LockTable();
        CorpCardTrans.Get(CorpCardTrans."Entry No.");
        if not (CorpCardTrans.Status in [CorpCardTrans.Status::Imported, CorpCardTrans.Status::Exception]) then
            exit;
        CorpCardTrans.TestField("Expense No.", '');

        if not ExpenseAgentSetup.Get() then
            ExpenseAgentSetup.Init();

        CorpCardTrans.Status := CorpCardTrans.Status::Imported;
        Clear(CorpCardTrans."Reject Reason");
        MerchantNorm.NormalizeTransaction(CorpCardTrans);
        CorpCardTrans.Modify(true);
        EnhancedMatchMgt.InitializeCardCache();
        if CorpCardTrans."Expense Match No." <> '' then begin
            Expense.LockTable();
            if not CorpCardValidateMgt.ResolveCardFromExpense(CorpCardTrans, CorpCard, MatchedExpenseNo, ValidationReason) then
                Error(ValidationReason);
            CorpCard.TestField("Card Id", CorpCardTrans."Card Id");
            CorpCardTrans.TestField("Expense Match No.", MatchedExpenseNo);
            LinkExpenseToTransaction(MatchedExpenseNo, CorpCardTrans."Entry No.");
            CorpCardTrans.Status := CorpCardTrans.Status::Matched;
            CorpCardTrans."Expense No." := MatchedExpenseNo;
            CorpCardTrans."Match Type" := CorpCardTrans."Match Type"::Full;
            CorpCardTrans."Match Score" := 100;
        end else
            if ExpenseAgentSetup."Corp Card Create Mode" = ExpenseAgentSetup."Corp Card Create Mode"::AutoDraft then begin
                TransactionExpenseWriter.CreateDraftFromTrans(CorpCardTrans, DraftExpenseNo);
                AuditSubscribers.LogDraftCreated(CorpCardTrans."Entry No.");
            end else
                if EnhancedMatchMgt.EnhancedMatchTransaction(CorpCardTrans, MatchedExpenseNo) then begin
                    LinkExpenseToTransaction(MatchedExpenseNo, CorpCardTrans."Entry No.");
                    CorpCardTrans.Status := CorpCardTrans.Status::Matched;
                    CorpCardTrans."Expense No." := MatchedExpenseNo;
                end else
                    if ExpenseAgentSetup."Corp Card Auto Create Draft" then begin
                        TransactionExpenseWriter.CreateDraftFromTrans(CorpCardTrans, DraftExpenseNo);
                        AuditSubscribers.LogDraftCreated(CorpCardTrans."Entry No.");
                    end;

        CorpCardTrans.Modify(true);
        ResolveProcessingExceptions(CorpCardTrans);
    end;

    local procedure HasProcessingException(CorpCardTrans: Record "EA Corp Card Trans"): Boolean
    var
        CorpCardException: Record "EA Corp Card Exception";
    begin
        CorpCardException.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
        CorpCardException.SetRange("Exception Type", CorpCardException."Exception Type"::PostImportProcessing);
        exit(not CorpCardException.IsEmpty());
    end;

    local procedure RecordProcessingFailure(TransactionEntryNo: Integer; ProcessingError: Text)
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardException: Record "EA Corp Card Exception";
    begin
        CorpCardTrans.Get(TransactionEntryNo);
        CorpCardStatement.LockTable();
        CorpCardStatement.Get(CorpCardTrans."Statement Entry No.");
        CorpCardStatement.TestField(Status, CorpCardStatement.Status::Imported);
        CorpCardTrans.LockTable();
        CorpCardTrans.Get(TransactionEntryNo);
        if not (CorpCardTrans.Status in [CorpCardTrans.Status::Imported, CorpCardTrans.Status::Exception]) then
            exit;
        CorpCardTrans.Status := CorpCardTrans.Status::Exception;
        CorpCardTrans."Reject Reason" := CopyStr(ProcessingError, 1, MaxStrLen(CorpCardTrans."Reject Reason"));
        CorpCardTrans.Modify(true);

        CorpCardException.SetRange("Trans Entry No.", TransactionEntryNo);
        CorpCardException.SetRange("Exception Type", CorpCardException."Exception Type"::PostImportProcessing);
        if CorpCardException.FindFirst() then begin
            CorpCardException.Message := CopyStr(ProcessingError, 1, MaxStrLen(CorpCardException.Message));
            CorpCardException.Resolved := false;
            CorpCardException.Modify(true);
        end else begin
            CorpCardException.Init();
            CorpCardException."Statement Entry No." := CorpCardTrans."Statement Entry No.";
            CorpCardException."Trans Entry No." := TransactionEntryNo;
            CorpCardException."Exception Type" := CorpCardException."Exception Type"::PostImportProcessing;
            CorpCardException.Message := CopyStr(ProcessingError, 1, MaxStrLen(CorpCardException.Message));
            CorpCardException."Created DT" := CurrentDateTime();
            CorpCardException.Insert(true);
        end;
        UpdateExceptionCount(CorpCardTrans."Statement Entry No.");
    end;

    local procedure ResolveProcessingExceptions(CorpCardTrans: Record "EA Corp Card Trans")
    var
        CorpCardException: Record "EA Corp Card Exception";
    begin
        CorpCardException.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
        CorpCardException.SetRange("Exception Type", CorpCardException."Exception Type"::PostImportProcessing);
        if not CorpCardException.FindSet(true) then
            exit;
        repeat
            if not CorpCardException.Resolved then begin
                CorpCardException.Resolved := true;
                CorpCardException.Modify(true);
            end;
        until CorpCardException.Next() = 0;
        UpdateExceptionCount(CorpCardTrans."Statement Entry No.");
    end;

    local procedure UpdateExceptionCount(StatementEntryNo: Integer)
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardException: Record "EA Corp Card Exception";
    begin
        CorpCardStatement.Get(StatementEntryNo);
        CorpCardException.SetRange("Statement Entry No.", StatementEntryNo);
        CorpCardException.SetRange(Resolved, false);
        CorpCardStatement.Exceptions := CorpCardException.Count();
        CorpCardStatement.Modify(true);
    end;

    local procedure LinkExpenseToTransaction(ExpenseNo: Code[20]; CorpCardTransEntryNo: Integer)
    var
        Expense: Record Expense;
    begin
        Expense.Get(ExpenseNo);
        Expense.Validate("Credit Card Feed No.", CorpCardTransEntryNo);
        Expense.Modify(true);
    end;
}
