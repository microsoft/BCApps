// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6985 "Expense Report Manual Release"
{
    Access = Internal;
    TableNo = "Expense Report Header";

    trigger OnRun()
    var
        ReleaseExpenseReportDocument: Codeunit "Release Exp. Report Document";
    begin
        ReleaseExpenseReportDocument.PerformManualRelease(Rec);
    end;
}