// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Orchestrates post-import processing: merchant normalization, matching, and draft creation.
/// Runs after corporate card transactions are imported into staging.
/// </summary>
codeunit 7423 "EA Corp Card Post Import Orch"
{
    Access = Internal;

    internal procedure ProcessStatementPostImport(StatementEntryNo: Integer; ExpenseWriter: Interface "EA Corp Card Expense Writer")
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        MerchantNorm: Codeunit "EA Corp Card Merchant Norm";
        EnhancedMatchMgt: Codeunit "EA Corp Card Enh. Match Mgt";
        AuditSubscribers: Codeunit "EA Corp Card Audit Subscribers";
        MatchedExpenseNo: Code[20];
        DraftExpenseNo: Code[20];
        MatchedCount: Integer;
        UnmatchedCount: Integer;
    begin
        if not CorpCardStatement.Get(StatementEntryNo) then
            exit;

        if not ExpenseAgentSetup.Get() then
            ExpenseAgentSetup.Init();

        CorpCardTrans.SetRange("Statement Entry No.", StatementEntryNo);
        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::Imported);

        if not CorpCardTrans.FindSet() then
            exit;

        repeat
            MerchantNorm.NormalizeTransaction(CorpCardTrans);
            CorpCardTrans.Modify();

            if ExpenseAgentSetup."Corp Card Create Mode" = ExpenseAgentSetup."Corp Card Create Mode"::AutoDraft then begin
                ExpenseWriter.CreateDraftFromTrans(CorpCardTrans, DraftExpenseNo);
                AuditSubscribers.LogDraftCreated(CorpCardTrans."Entry No.", DraftExpenseNo);
            end else
                if EnhancedMatchMgt.EnhancedMatchTransaction(CorpCardTrans, MatchedExpenseNo) then begin
                    CorpCardTrans.Status := CorpCardTrans.Status::Matched;
                    CorpCardTrans."Expense No." := MatchedExpenseNo;
                    MatchedCount += 1;
                end else
                    if ExpenseAgentSetup."Corp Card Auto Create Draft" then begin
                        ExpenseWriter.CreateDraftFromTrans(CorpCardTrans, DraftExpenseNo);
                        AuditSubscribers.LogDraftCreated(CorpCardTrans."Entry No.", DraftExpenseNo);
                    end else
                        UnmatchedCount += 1;

            CorpCardTrans.Modify();
        until CorpCardTrans.Next() = 0;

        AuditSubscribers.LogMatchingCompleted(MatchedCount, UnmatchedCount);
    end;
}
