// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Matches corporate card transactions to existing Expense records.
/// Uses employee, date, and amount tolerance to find potential matches.
/// </summary>
codeunit 7211 "EA Corp Card Match Mgt"
{
    Access = Internal;

    internal procedure MatchTransaction(var CorpCardTrans: Record "EA Corp Card Trans"; var ExpenseNo: Code[20]): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CorpCard: Record "EA Corp Card";
        Expense: Record Expense;
        DateWindow: Integer;
        AmountTolerance: Decimal;
        ExpenseUserNo: Code[20];
    begin
        if not ExpenseAgentSetup.Get() then
            exit(false);

        DateWindow := ExpenseAgentSetup."Corp Card Date Match Window";
        AmountTolerance := ExpenseAgentSetup."Corp Card Amount Tolerance";

        if not CorpCard.Get(CorpCardTrans."Card Id") then
            exit(false);

        ExpenseUserNo := CorpCard."Expense User No.";
        if ExpenseUserNo = '' then
            exit(false);

        Expense.SetRange("Expense User No.", ExpenseUserNo);
        Expense.SetRange("Status", Expense."Status"::Open);
        Expense.SetRange("Currency Code", CorpCardTrans."Currency Code");
        Expense.SetFilter("Expense Date", '%1..%2', CorpCardTrans."Trans Date" - DateWindow, CorpCardTrans."Trans Date" + DateWindow);
        Expense.SetFilter("Amount", '%1..%2', CorpCardTrans.Amount - AmountTolerance, CorpCardTrans.Amount + AmountTolerance);

        if Expense.FindFirst() then begin
            ExpenseNo := Expense."No.";
            CorpCardTrans."Match Type" := CorpCardTrans."Match Type"::Full;
            CorpCardTrans."Match Score" := 100;
            exit(true);
        end;

        exit(false);
    end;
}
