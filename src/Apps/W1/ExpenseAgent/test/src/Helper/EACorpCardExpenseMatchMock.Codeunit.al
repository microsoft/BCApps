// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148366 EACorpCardExpenseMatchMock implements "EA Corp Card Expense Match"
{
    Access = Internal;

    var
        MatchedExpenseNo: Code[20];
        MatchCallCount: Integer;
        LinkCallCount: Integer;

    procedure MatchExistingExpense(CorpCardTrans: Record "EA Corp Card Trans"; var MatchedDocumentId: RecordId): Boolean
    var
        Expense: Record Expense;
    begin
        CorpCardTrans.TestField("Entry No.");
        MatchCallCount += 1;
        Clear(MatchedDocumentId);
        if MatchedExpenseNo = '' then
            exit(false);
        Expense."No." := MatchedExpenseNo;
        MatchedDocumentId := Expense.RecordId;
        exit(true);
    end;

    procedure LinkExpense(var CorpCardTrans: Record "EA Corp Card Trans"; MatchedDocumentId: RecordId)
    var
        Expense: Record Expense;
        Assert: Codeunit Assert;
    begin
        Expense."No." := MatchedExpenseNo;
        Assert.AreEqual(Expense.RecordId, MatchedDocumentId, 'Linking must use the document returned by matching.');
        LinkExpense(CorpCardTrans, MatchedExpenseNo);
    end;

    procedure LinkExpense(var CorpCardTrans: Record "EA Corp Card Trans"; ExpenseNo: Code[20])
    begin
        LinkCallCount += 1;
        CorpCardTrans."Expense No." := ExpenseNo;
        CorpCardTrans.Status := CorpCardTrans.Status::Matched;
    end;

    internal procedure SetMatchedExpenseNo(ExpenseNo: Code[20])
    begin
        MatchedExpenseNo := ExpenseNo;
    end;

    internal procedure GetMatchCallCount(): Integer
    begin
        exit(MatchCallCount);
    end;

    internal procedure GetLinkCallCount(): Integer
    begin
        exit(LinkCallCount);
    end;
}
