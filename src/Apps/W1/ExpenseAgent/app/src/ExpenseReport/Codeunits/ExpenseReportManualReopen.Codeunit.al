// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6986 "Expense Report Manual Reopen"
{
    TableNo = "Expense Report Header";
    Access = Internal;

    trigger OnRun()
    var
        ReleaseExpenseReportDocument: Codeunit "Release Exp. Report Document";
    begin
        ReleaseExpenseReportDocument.PerformManualReopen(Rec);
    end;
}