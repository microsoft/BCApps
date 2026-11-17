#if not CLEAN30
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 11194 "Create Expense Categories AT"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'The country-specific Expense Agent demo data is being consolidated into a single app in W1 and will be removed in a future release.';
    ObsoleteTag = '30.0';

    trigger OnRun()
    var
        CreateExpenseGroup: Codeunit "Create Expense Group";
        CreateExpensePaymentMethod: Codeunit "Create Expense Payment Method";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateExpensePostingGrpAT: Codeunit "Create Expense Posting Grp AT";
    begin
        ContosoExpenseAgent.InsertExpenseCategory(PerDiemI(), PerDiemByAssignedPolicyLbl, PerDiemIByAssignedPolicyPostingLbl, CreateExpensePostingGrpAT.ExpensePerDiemI(), Enum::"Expense Attachment Enforcement"::" ", CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::"Per Diem");
        ContosoExpenseAgent.InsertExpenseCategory(PerDiemA(), PerDiemByAssignedPolicyLbl, PerDiemAByAssignedPolicyPostingLbl, CreateExpensePostingGrpAT.ExpensePerDiemA(), Enum::"Expense Attachment Enforcement"::" ", CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::"Per Diem");
    end;

    var
        PerDiemITok: Label 'PER-DIEM-I', MaxLength = 20, Locked = true;
        PerDiemATok: Label 'PER-DIEM-A', MaxLength = 20, Locked = true;
        PerDiemByAssignedPolicyLbl: Label 'Expenses for per-diem or daily allowance paid for business trips, typically based on travel itinerary or other proof of travel (e.g., booking or agenda), rather than individual expense receipts.', MaxLength = 250;
        PerDiemIByAssignedPolicyPostingLbl: Label 'Per-diem (international) by assigned policy', MaxLength = 100;
        PerDiemAByAssignedPolicyPostingLbl: Label 'Per-diem (local) by assigned policy', MaxLength = 100;

    procedure PerDiemI(): Code[20]
    begin
        exit(PerDiemITok);
    end;

    procedure PerDiemA(): Code[20]
    begin
        exit(PerDiemATok);
    end;
}
#endif