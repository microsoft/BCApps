// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 13678 "Create Expense Categories DK"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        CreateExpenseGroup: Codeunit "Create Expense Group";
        CreateExpensePaymentMethod: Codeunit "Create Expense Payment Method";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateExpensePostingGrpDK: Codeunit "Create Expense Posting Grp DK";
    begin
        ContosoExpenseAgent.InsertExpenseCategory(PerDiem(), PerDiemByAssignedPolicyLbl, PerDiemByAssignedPolicyPostingLbl, CreateExpensePostingGrpDK.ExpensePerDiem(), Enum::"Expense Attachment Enforcement"::" ", CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::"Per Diem");
    end;

    var
        PerDiemTok: Label 'PER-DIEM', MaxLength = 20, Locked = true;
        PerDiemByAssignedPolicyLbl: Label 'Expenses for per-diem or daily allowance paid for business trips, typically based on travel itinerary or other proof of travel (e.g., booking or agenda), rather than individual expense receipts.', MaxLength = 250;
        PerDiemByAssignedPolicyPostingLbl: Label 'Per-diem by assigned policy', MaxLength = 100;

    procedure PerDiem(): Code[20]
    begin
        exit(PerDiemTok);
    end;
}