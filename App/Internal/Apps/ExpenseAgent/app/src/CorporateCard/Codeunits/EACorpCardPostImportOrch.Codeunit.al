// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Orchestrates post-import processing: merchant normalization, matching, and draft creation.
/// Runs after corporate card transactions are imported into staging.
/// </summary>
codeunit 7213 EACorpCardPostImportOrch
{
    Access = Internal;

    internal procedure ProcessBatchPostImport(BatchNo: Integer)
    var
        CorpCardBatch: Record EACorpCardBatch;
        CorpCardTrans: Record EACorpCardTrans;
        CorpCardSetup: Record EACorpCardSetup;
        MerchantNorm: Codeunit EACorpCardMerchantNorm;
        EnhancedMatchMgt: Codeunit EACorpCardEnhancedMatchMgt;
        ExpWriter: Codeunit EACorpCardExpWriter;
        AuditSubscribers: Codeunit EACorpCardAuditSubscribers;
        MatchedExpenseNo: Code[20];
        DraftExpenseNo: Code[20];
        MatchedCount: Integer;
        UnmatchedCount: Integer;
    begin
        if not CorpCardBatch.Get(BatchNo) then
            exit;

        if not CorpCardSetup.Get() then
            CorpCardSetup.Init();

        CorpCardTrans.SetRange("Batch No.", BatchNo);
        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::Imported);

        if not CorpCardTrans.FindSet() then
            exit;

        repeat
            MerchantNorm.NormalizeTransaction(CorpCardTrans);
            CorpCardTrans.Modify();

            if EnhancedMatchMgt.EnhancedMatchTransaction(CorpCardTrans, MatchedExpenseNo) then begin
                CorpCardTrans.Status := CorpCardTrans.Status::Matched;
                CorpCardTrans."Expense No." := MatchedExpenseNo;
                MatchedCount += 1;
            end else
                if CorpCardSetup."Auto Create Draft" then begin
                    ExpWriter.CreateDraftFromTrans(CorpCardTrans, DraftExpenseNo);
                    AuditSubscribers.LogDraftCreated(CorpCardTrans."Entry No.", DraftExpenseNo);
                end else
                    UnmatchedCount += 1;

            CorpCardTrans.Modify();
        until CorpCardTrans.Next() = 0;

        AuditSubscribers.LogMatchingCompleted(MatchedCount, UnmatchedCount);
    end;
}
