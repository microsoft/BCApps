// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148341 "Library - Expense Agent"
{
    SingleInstance = true;

    var
        TempExpenseAgentSetup: Record "Expense Agent Setup" temporary;
        ExpenseAgentSetupExisted: Boolean;
        HasExpenseAgentSetupBackup: Boolean;

    internal procedure BackupExpenseAgentSetup()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if HasExpenseAgentSetupBackup then
            RestoreExpenseAgentSetup();

        TempExpenseAgentSetup.DeleteAll();
        ExpenseAgentSetupExisted := ExpenseAgentSetup.Get();
        if ExpenseAgentSetupExisted then begin
            TempExpenseAgentSetup.Init();
            TempExpenseAgentSetup.TransferFields(ExpenseAgentSetup, true);
            TempExpenseAgentSetup.Insert();
        end;
        HasExpenseAgentSetupBackup := true;
    end;

    internal procedure RestoreExpenseAgentSetup()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if not HasExpenseAgentSetupBackup then
            exit;

        if ExpenseAgentSetupExisted then begin
            TempExpenseAgentSetup.Get();
            ExpenseAgentSetup.Get();
            ExpenseAgentSetup.TransferFields(TempExpenseAgentSetup, false);
            ExpenseAgentSetup.Modify(false);
        end else
            if ExpenseAgentSetup.Get() then
                ExpenseAgentSetup.Delete(false);

        TempExpenseAgentSetup.DeleteAll();
        Clear(ExpenseAgentSetupExisted);
        Clear(HasExpenseAgentSetupBackup);
    end;
}
