#if not CLEAN30
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;

codeunit 27108 "Create Expense CA"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'The country-specific Expense Agent demo data is being consolidated into a single app in W1 and will be removed in a future release.';
    ObsoleteTag = '30.0';
    Permissions = tabledata "Expense Per Diem" = rim;

    trigger OnRun()
    begin
        CreateOpenExpense();
    end;

    local procedure CreateOpenExpense()
    var
        Expense: Record Expense;
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateExpenseLocation: Codeunit "Create Expense Location";
    begin
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), CreateExpCategoriesCA.PerDiem(), CreateExpenseLocation.DenmarkAll(), PerDiemByAssignedPolicyLbl, '', ContosoUtility.AdjustDate(19030203D), '', 0, '', CreateExpensePaymentMethod.Cash(), true, false, '', CreateDateTime(ContosoUtility.AdjustDate(19030115D), 144000T), CreateDateTime(ContosoUtility.AdjustDate(19030121D), 000500T), 0, 0, '', '', '', '', '');
        UpdateExpensePerDiem(Expense."No.", 10000, false, false, true);
        UpdateExpensePerDiem(Expense."No.", 30000, false, true, false);
        UpdateExpensePerDiem(Expense."No.", 40000, false, false, true);
        UpdateExpensePerDiem(Expense."No.", 60000, false, true, true);
    end;

    var
        ContosoUtility: Codeunit "Contoso Utilities";
        CreateExpenseUser: Codeunit "Create Expense User";
        CreateExpCategoriesCA: Codeunit "Create Expense Categories CA";
        CreateExpensePaymentMethod: Codeunit "Create Expense Payment Method";
        PerDiemByAssignedPolicyLbl: Label 'Per-diem by assigned policy', MaxLength = 100;

    local procedure UpdateExpensePerDiem(ExpenseNo: Code[20]; LineNo: Integer; Breakfast: Boolean; Lunch: Boolean; Dinner: Boolean)
    var
        ExpensePerDiem: Record "Expense Per Diem";
    begin
        ExpensePerDiem.Get(ExpenseNo, LineNo);

        ExpensePerDiem.Validate(Breakfast, Breakfast);
        ExpensePerDiem.Validate(Lunch, Lunch);
        ExpensePerDiem.Validate(Dinner, Dinner);
        ExpensePerDiem.Modify();
    end;
}
#endif