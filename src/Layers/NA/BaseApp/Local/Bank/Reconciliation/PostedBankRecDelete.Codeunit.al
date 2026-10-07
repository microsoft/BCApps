// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;

codeunit 10125 "Posted Bank Rec.-Delete"
{
    Permissions = TableData "Bank Comment Line" = rd,
                  TableData "Posted Bank Rec. Header" = rd,
                  TableData "Posted Bank Rec. Line" = rd;
    TableNo = "Posted Bank Rec. Header";

    trigger OnRun()
    begin
        PostedBankRecLines.SetRange("Bank Account No.", Rec."Bank Account No.");
        PostedBankRecLines.SetRange("Statement No.", Rec."Statement No.");
        PostedBankRecLines.DeleteAll();

        BankRecCommentLines.SetRange("Table Name", BankRecCommentLines."Table Name"::"Posted Bank Rec.");
        BankRecCommentLines.SetRange("Bank Account No.", Rec."Bank Account No.");
        BankRecCommentLines.SetRange("No.", Rec."Statement No.");
        BankRecCommentLines.DeleteAll();

        OnRunOnBeforeDelete(Rec);
        Rec.Delete();
    end;

    var
        PostedBankRecLines: Record "Posted Bank Rec. Line";
        BankRecCommentLines: Record "Bank Comment Line";

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeDelete(var PostedBankRecHeader: Record "Posted Bank Rec. Header")
    begin
    end;
}

