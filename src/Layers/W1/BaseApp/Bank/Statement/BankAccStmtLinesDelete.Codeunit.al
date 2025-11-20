// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

codeunit 382 "BankAccStmtLines-Delete"
{
    Permissions = TableData "Bank Account Statement Line" = d;
    TableNo = "Bank Account Statement";

    trigger OnRun()
    begin
        BankAccStmtLine.SetRange("Bank Account No.", Rec."Bank Account No.");
        BankAccStmtLine.SetRange("Statement No.", Rec."Statement No.");
        BankAccStmtLine.DeleteAll();
    end;

    var
        BankAccStmtLine: Record "Bank Account Statement Line";
}

