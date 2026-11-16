// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6981 "Expense Manual Reopen"
{
    Access = Internal;
    TableNo = Expense;

    trigger OnRun()
    var
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        ReleaseExpenseDocument.PerformManualReopen(Rec);
    end;
}