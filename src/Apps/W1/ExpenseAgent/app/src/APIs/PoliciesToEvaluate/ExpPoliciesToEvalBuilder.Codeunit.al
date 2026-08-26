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
        ExistingEvaluationKeys: Dictionary of [Text, Boolean];
        SubjectSystemId: Guid;
        SubjectVersion: Integer;
    begin
        SubjectSystemId := ExpenseReportLine.SystemId;
        SubjectVersion := ExpenseReportLine."Policy Eval Version";

        LoadExistingEvaluationKeys(SubjectSystemId, SubjectVersion, ExistingEvaluationKeys);

        ExpensePolicy.SetApplicableToLineFilter(ExpenseReportLine);
        if ExpensePolicy.FindSet() then
            repeat
                if not EvaluationExists(ExistingEvaluationKeys, ExpensePolicy.SystemId, ExpensePolicy."Version") then
                    InsertRow(TempPolicyToEvalBuffer, SubjectSystemId, SubjectVersion, ExpensePolicy);
            until ExpensePolicy.Next() = 0;
    end;

    procedure HasOutstandingPolicies(ExpenseReportLine: Record "Expense Report Line"): Boolean
    var
        HasApplicablePolicies: Boolean;
        HasOutstandingPoliciesResult: Boolean;
    begin
        GetEvaluationState(ExpenseReportLine, HasApplicablePolicies, HasOutstandingPoliciesResult);
        exit(HasOutstandingPoliciesResult);
    end;

    procedure GetEvaluationState(ExpenseReportLine: Record "Expense Report Line"; var HasApplicablePolicies: Boolean; var HasOutstandingPoliciesResult: Boolean)
    var
        ExpensePolicy: Record "Expense Policy";
        ExistingEvaluationKeys: Dictionary of [Text, Boolean];
        SubjectSystemId: Guid;
        SubjectVersion: Integer;
    begin
        HasApplicablePolicies := false;
        HasOutstandingPoliciesResult := false;

        SubjectSystemId := ExpenseReportLine.SystemId;
        SubjectVersion := ExpenseReportLine."Policy Eval Version";

        ExpensePolicy.SetApplicableToLineFilter(ExpenseReportLine);
        if not ExpensePolicy.FindSet() then
            exit;

        HasApplicablePolicies := true;
        LoadExistingEvaluationKeys(SubjectSystemId, SubjectVersion, ExistingEvaluationKeys);
        repeat
            if not EvaluationExists(ExistingEvaluationKeys, ExpensePolicy.SystemId, ExpensePolicy."Version") then begin
                HasOutstandingPoliciesResult := true;
                exit;
            end;
        until ExpensePolicy.Next() = 0;
    end;

    local procedure LoadExistingEvaluationKeys(SubjectSystemId: Guid; SubjectVersion: Integer; var ExistingEvaluationKeys: Dictionary of [Text, Boolean])
    var
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // Load every evaluation recorded for this subject version once, keyed by policy and policy version,
        // so the applicable-policy loop can test each policy against an in-memory set instead of
        // issuing a separate database Get per policy (the previous N+1 pattern against a persistent
        // table on every policies-to-evaluate or mark-evaluated request).
        Clear(ExistingEvaluationKeys);
        ExpensePolicyEvaluation.SetRange("Subject Type", ExpensePolicyEvaluation."Subject Type"::"Expense Report Line");
        ExpensePolicyEvaluation.SetRange("Subject System Id", SubjectSystemId);
        ExpensePolicyEvaluation.SetRange("Subject Version", SubjectVersion);
        ExpensePolicyEvaluation.SetLoadFields("Policy System Id", "Policy Version");
        if ExpensePolicyEvaluation.FindSet() then
            repeat
                ExistingEvaluationKeys.Set(EvaluationKey(ExpensePolicyEvaluation."Policy System Id", ExpensePolicyEvaluation."Policy Version"), true);
            until ExpensePolicyEvaluation.Next() = 0;
    end;

    local procedure EvaluationExists(ExistingEvaluationKeys: Dictionary of [Text, Boolean]; PolicySystemId: Guid; PolicyVersion: Integer): Boolean
    begin
        // A policy no longer needs evaluating when an evaluation already exists for the line's current
        // subject version and the policy's current version. This keeps the endpoint idempotent and
        // avoids returning policies that were just re-evaluated.
        exit(ExistingEvaluationKeys.ContainsKey(EvaluationKey(PolicySystemId, PolicyVersion)));
    end;

    local procedure EvaluationKey(PolicySystemId: Guid; PolicyVersion: Integer): Text
    begin
        exit(Format(PolicySystemId) + '|' + Format(PolicyVersion));
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
