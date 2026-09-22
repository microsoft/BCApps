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

        ExpenseReportLine.SetLoadFields(SystemId, "Policy Eval Version", "Expense Category");
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

        ExpensePolicy.SetLoadFields(SystemId, Version, "Expense Category Code", Description, "Policy Text");
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
        TempMatchedEvaluations: Record "Expense Policy Evaluation" temporary;
    begin
        GetEvaluationState(ExpenseReportLine, HasApplicablePolicies, HasOutstandingPoliciesResult, TempMatchedEvaluations, false, IsolationLevel::Default);
    end;

    /// <summary>
    /// Replaces the temporary output with current applicable results (keys, compliance and timestamp only).
    /// Tests result presence, not line confirmation. Snapshot callers explicitly select their read isolation.
    /// </summary>
    internal procedure GetEvaluationState(ExpenseReportLine: Record "Expense Report Line"; var HasApplicablePolicies: Boolean; var HasOutstandingPoliciesResult: Boolean; var TempMatchedEvaluations: Record "Expense Policy Evaluation" temporary; ReadIsolation: IsolationLevel)
    begin
        GetEvaluationState(ExpenseReportLine, HasApplicablePolicies, HasOutstandingPoliciesResult, TempMatchedEvaluations, true, ReadIsolation);
    end;

    local procedure GetEvaluationState(ExpenseReportLine: Record "Expense Report Line"; var HasApplicablePolicies: Boolean; var HasOutstandingPoliciesResult: Boolean; var TempMatchedEvaluations: Record "Expense Policy Evaluation" temporary; CollectEvaluations: Boolean; ReadIsolation: IsolationLevel)
    var
        ExpensePolicy: Record "Expense Policy";
        TempExistingEvaluations: Record "Expense Policy Evaluation" temporary;
        ExistingEvaluationKeys: Dictionary of [Text, Boolean];
        SubjectSystemId: Guid;
        SubjectVersion: Integer;
    begin
        HasApplicablePolicies := false;
        HasOutstandingPoliciesResult := false;
        TempMatchedEvaluations.Reset();
        TempMatchedEvaluations.DeleteAll();

        SubjectSystemId := ExpenseReportLine.SystemId;
        SubjectVersion := ExpenseReportLine."Policy Eval Version";

        ExpensePolicy.ReadIsolation := ReadIsolation;
        ExpensePolicy.SetLoadFields(SystemId, Version);
        ExpensePolicy.SetApplicableToLineFilter(ExpenseReportLine);
        if not ExpensePolicy.FindSet() then
            exit;

        HasApplicablePolicies := true;
        LoadExistingEvaluationKeys(SubjectSystemId, SubjectVersion, ExistingEvaluationKeys, TempExistingEvaluations, CollectEvaluations, ReadIsolation);
        repeat
            if not EvaluationExists(ExistingEvaluationKeys, ExpensePolicy.SystemId, ExpensePolicy."Version") then begin
                HasOutstandingPoliciesResult := true;
                if not CollectEvaluations then
                    exit;
            end else
                if CollectEvaluations then begin
                    TempExistingEvaluations.Get(ExpensePolicy."Subject Type", SubjectSystemId, ExpensePolicy.SystemId, SubjectVersion, ExpensePolicy.Version);
                    TempMatchedEvaluations := TempExistingEvaluations;
                    TempMatchedEvaluations.Insert();
                end;
        until ExpensePolicy.Next() = 0;
    end;

    local procedure LoadExistingEvaluationKeys(SubjectSystemId: Guid; SubjectVersion: Integer; var ExistingEvaluationKeys: Dictionary of [Text, Boolean])
    var
        TempExistingEvaluations: Record "Expense Policy Evaluation" temporary;
    begin
        LoadExistingEvaluationKeys(SubjectSystemId, SubjectVersion, ExistingEvaluationKeys, TempExistingEvaluations, false, IsolationLevel::Default);
    end;

    local procedure LoadExistingEvaluationKeys(SubjectSystemId: Guid; SubjectVersion: Integer; var ExistingEvaluationKeys: Dictionary of [Text, Boolean]; var TempExistingEvaluations: Record "Expense Policy Evaluation" temporary; CollectEvaluations: Boolean; ReadIsolation: IsolationLevel)
    var
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        // Load every evaluation recorded for this subject version once, keyed by policy and policy version,
        // so the applicable-policy loop can test each policy against an in-memory set instead of
        // issuing a separate database Get per policy (the previous N+1 pattern against a persistent
        // table on every policies-to-evaluate or mark-evaluated request).
        Clear(ExistingEvaluationKeys);
        ExpensePolicyEvaluation.ReadIsolation := ReadIsolation;
        ExpensePolicyEvaluation.SetRange("Subject Type", ExpensePolicyEvaluation."Subject Type"::"Expense Report Line");
        ExpensePolicyEvaluation.SetRange("Subject System Id", SubjectSystemId);
        ExpensePolicyEvaluation.SetRange("Subject Version", SubjectVersion);
        ExpensePolicyEvaluation.SetLoadFields("Policy System Id", "Policy Version");
        if CollectEvaluations then
            ExpensePolicyEvaluation.AddLoadFields(Compliant, "Evaluated At");
        if ExpensePolicyEvaluation.FindSet() then
            repeat
                ExistingEvaluationKeys.Set(EvaluationKey(ExpensePolicyEvaluation."Policy System Id", ExpensePolicyEvaluation."Policy Version"), true);
                if CollectEvaluations then begin
                    TempExistingEvaluations.Init();
                    TempExistingEvaluations."Subject Type" := ExpensePolicyEvaluation."Subject Type";
                    TempExistingEvaluations."Subject System Id" := ExpensePolicyEvaluation."Subject System Id";
                    TempExistingEvaluations."Subject Version" := ExpensePolicyEvaluation."Subject Version";
                    TempExistingEvaluations."Policy System Id" := ExpensePolicyEvaluation."Policy System Id";
                    TempExistingEvaluations."Policy Version" := ExpensePolicyEvaluation."Policy Version";
                    TempExistingEvaluations.Compliant := ExpensePolicyEvaluation.Compliant;
                    TempExistingEvaluations."Evaluated At" := ExpensePolicyEvaluation."Evaluated At";
                    TempExistingEvaluations.Insert();
                end;
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
