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

    procedure MatchExistingExpense(CorpCardTrans: Record "EA Corp Card Trans"; var ExpenseNo: Code[20]): Boolean
    begin
        CorpCardTrans.TestField("Entry No.");
        MatchCallCount += 1;
        ExpenseNo := MatchedExpenseNo;
        exit(ExpenseNo <> '');
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
