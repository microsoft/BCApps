// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Creates draft Expense records from corporate card transactions.
/// Implements IEACorpCardExpWriter interface to populate expense fields from transaction data.
/// </summary>
codeunit 7212 EACorpCardExpWriter implements IEACorpCardExpWriter
{
    Access = Internal;

    var
        ExpenseUserNotFoundErr: Label 'Expense User not found for card %1.';
        NoExpenseCategoryErr: Label 'No expense category found from MCC %1 mapping.';

    procedure CreateDraftFromTrans(var CorpCardTrans: Record EACorpCardTrans; var ExpenseNo: Code[20])
    var
        Expense: Record Expense;
        CorpCard: Record EACorpCard;
        ExpenseUserNo: Code[20];
        ExpenseCategory: Code[20];
    begin
        if not CorpCard.Get(CorpCardTrans."Card Id") then
            Error(ExpenseUserNotFoundErr, CorpCardTrans."Card Id");

        ExpenseUserNo := CorpCard."Expense User No.";
        if ExpenseUserNo = '' then
            Error(ExpenseUserNotFoundErr, CorpCardTrans."Card Id");

        ExpenseCategory := GetExpenseCategoryFromMCC(CorpCardTrans.MCC);

        Expense.Init();
        Expense."Expense User No." := ExpenseUserNo;
        Expense.Description := CopyStr(CorpCardTrans."Merchant Norm", 1, MaxStrLen(Expense.Description));
        Expense."Merchant Name" := CopyStr(CorpCardTrans."Merchant Norm", 1, MaxStrLen(Expense."Merchant Name"));
        Expense."Expense Date" := CorpCardTrans."Trans Date";
        Expense.Amount := CorpCardTrans.Amount;
        Expense."Currency Code" := CorpCardTrans."Currency Code";
        if ExpenseCategory <> '' then
            Expense."Expense Category" := ExpenseCategory;
        Expense."Status" := Expense."Status"::Open;

        Expense.Insert(true);
        ExpenseNo := Expense."No.";

        CorpCardTrans."Expense No." := ExpenseNo;
        CorpCardTrans.Status := CorpCardTrans.Status::DraftCreated;
    end;

    procedure LinkPosted(var CorpCardTrans: Record EACorpCardTrans; PostedDocNo: Code[20])
    begin
        CorpCardTrans."Expense No." := PostedDocNo;
        CorpCardTrans.Status := CorpCardTrans.Status::Posted;
        CorpCardTrans.Modify();
    end;

    local procedure GetExpenseCategoryFromMCC(MCC: Code[4]): Code[20]
    var
        MCCMgt: Codeunit EACorpCardMCCMgt;
    begin
        exit(MCCMgt.GetExpenseCategoryForMCC(MCC));
    end;
}
