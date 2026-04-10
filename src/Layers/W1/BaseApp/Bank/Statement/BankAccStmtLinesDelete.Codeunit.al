// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

/// <summary>
/// Deletes all bank account statement lines for a specified bank statement.
/// Used when deleting bank account statements to ensure related line records are properly removed.
/// </summary>
/// <remarks>
/// Table processor codeunit that operates on Bank Account Statement table records.
/// Removes all associated Bank Account Statement Line records for the specified statement.
/// Called automatically during bank statement deletion operations.
/// </remarks>
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

