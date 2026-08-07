// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7107 "Exp. Policies To Eval Builder"
{
    Access = Internal;

    procedure Build(var TempPolicyToEvalBuffer: Record "Exp. Policy To Eval Buffer" temporary; SubjectSystemIdFilter: Text)
    var
        ExpenseReportLine: Record "Expense Report Line";
        SubjectSystemId: Guid;
    begin
        TempPolicyToEvalBuffer.Reset();
        TempPolicyToEvalBuffer.DeleteAll();

        if not TryEvaluateGuid(SubjectSystemIdFilter, SubjectSystemId) then
            exit;

        if not ExpenseReportLine.GetBySystemId(SubjectSystemId) then
            exit;

        BuildForLine(TempPolicyToEvalBuffer, ExpenseReportLine);
    end;

    local procedure BuildForLine(var TempPolicyToEvalBuffer: Record "Exp. Policy To Eval Buffer" temporary; ExpenseReportLine: Record "Expense Report Line")
    var
        ExpensePolicy: Record "Expense Policy";
        SubjectSystemId: Guid;
        SubjectVersion: Integer;
    begin
        SubjectSystemId := ExpenseReportLine.SystemId;
        SubjectVersion := ExpenseReportLine."Policy Eval Version";

        SetApplicablePolicyFilter(ExpensePolicy, ExpenseReportLine);
        if ExpensePolicy.FindSet() then
            repeat
                if not FlagExists(SubjectSystemId, ExpensePolicy.SystemId, SubjectVersion, ExpensePolicy."Version") then
                    InsertRow(TempPolicyToEvalBuffer, SubjectSystemId, SubjectVersion, ExpensePolicy);
            until ExpensePolicy.Next() = 0;
    end;

    procedure HasOutstandingPolicies(ExpenseReportLine: Record "Expense Report Line"): Boolean
    var
        ExpensePolicy: Record "Expense Policy";
        SubjectSystemId: Guid;
        SubjectVersion: Integer;
    begin
        // An applicable policy is outstanding when no flag exists for the line's current subject
        // version and the policy's current version - i.e. it has not been evaluated yet. Marking a
        // line evaluated while a policy is still outstanding would expose a status that ignores it.
        SubjectSystemId := ExpenseReportLine.SystemId;
        SubjectVersion := ExpenseReportLine."Policy Eval Version";

        SetApplicablePolicyFilter(ExpensePolicy, ExpenseReportLine);
        if ExpensePolicy.FindSet() then
            repeat
                if not FlagExists(SubjectSystemId, ExpensePolicy.SystemId, SubjectVersion, ExpensePolicy."Version") then
                    exit(true);
            until ExpensePolicy.Next() = 0;
        exit(false);
    end;

    local procedure SetApplicablePolicyFilter(var ExpensePolicy: Record "Expense Policy"; ExpenseReportLine: Record "Expense Report Line")
    begin
        // Applicable policies are the enabled report-line policies whose category matches the line
        // or is blank (a blank category applies to every category). The category-or-blank rule is
        // pushed into the query filter so unrelated categories are never loaded.
        ExpensePolicy.SetRange("Subject Type", ExpensePolicy."Subject Type"::"Expense Report Line");
        ExpensePolicy.SetRange(Enabled, true);
        ExpensePolicy.SetFilter("Expense Category Code", '%1|%2', ExpenseReportLine."Expense Category", '');
    end;

    local procedure FlagExists(SubjectSystemId: Guid; PolicySystemId: Guid; SubjectVersion: Integer; PolicyVersion: Integer): Boolean
    var
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // A policy no longer needs evaluating when a flag already exists for the line's current
        // subject version and the policy's current version. This keeps the endpoint idempotent and
        // avoids returning policies that were just re-evaluated.
        exit(ExpensePolicyFlag.Get(ExpensePolicyFlag."Subject Type"::"Expense Report Line", SubjectSystemId, PolicySystemId, SubjectVersion, PolicyVersion));
    end;

    local procedure InsertRow(var TempPolicyToEvalBuffer: Record "Exp. Policy To Eval Buffer" temporary; SubjectSystemId: Guid; SubjectVersion: Integer; var ExpensePolicy: Record "Expense Policy")
    begin
        TempPolicyToEvalBuffer.Init();
        TempPolicyToEvalBuffer."Subject System Id" := SubjectSystemId;
        TempPolicyToEvalBuffer."Policy System Id" := ExpensePolicy.SystemId;
        TempPolicyToEvalBuffer."Subject Version" := SubjectVersion;
        TempPolicyToEvalBuffer."Policy Line No." := ExpensePolicy."Line No.";
        TempPolicyToEvalBuffer."Policy Version" := ExpensePolicy."Version";
        TempPolicyToEvalBuffer."Expense Category Code" := ExpensePolicy."Expense Category Code";
        TempPolicyToEvalBuffer."Description" := ExpensePolicy."Description";
        TempPolicyToEvalBuffer."Policy Text" := ExpensePolicy."Policy Text";
        if TempPolicyToEvalBuffer.Insert() then;
    end;

    local procedure TryEvaluateGuid(SystemIdFilter: Text; var SystemId: Guid): Boolean
    begin
        Clear(SystemId);
        if SystemIdFilter = '' then
            exit(false);
        if not Evaluate(SystemId, SystemIdFilter) then
            exit(false);
        exit(not IsNullGuid(SystemId));
    end;
}
