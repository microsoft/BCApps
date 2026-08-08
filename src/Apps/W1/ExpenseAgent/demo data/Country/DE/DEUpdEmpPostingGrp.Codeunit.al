// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;

codeunit 8315 "DE Upd. Emp. Posting Grp"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateEmployeePostingGroup();
    end;

    local procedure UpdateEmployeePostingGroup()
    var
        HRGLAccount: Codeunit "Create HR GL Account";
        DEGLAccountNames: Codeunit "DE GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        DEExpGLAccount: Codeunit "DE Exp. GL Account";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(HRGLAccount.EmployeesPayableName()), ExpenseGLAccount.FindGLAccountByName(DEGLAccountNames.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(DEGLAccountNames.BusinessaccountOperatingDomesticName()), DEExpGLAccount.CompanyCreditCardsClearingAccount());
        ContosoExpenseAgent.SetOverwriteData(false);
    end;
}
