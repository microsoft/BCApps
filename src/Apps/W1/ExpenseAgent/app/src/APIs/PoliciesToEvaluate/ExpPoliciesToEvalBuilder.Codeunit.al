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
        ExistingFlagKeys: Dictionary of [Text, Boolean];
        SubjectSystemId: Guid;
        SubjectVersion: Integer;
    begin
        SubjectSystemId := ExpenseReportLine.SystemId;
        SubjectVersion := ExpenseReportLine."Policy Eval Version";

        LoadExistingFlagKeys(SubjectSystemId, SubjectVersion, ExistingFlagKeys);

        SetApplicablePolicyFilter(ExpensePolicy, ExpenseReportLine);
        if ExpensePolicy.FindSet() then
            repeat
                if not FlagExists(ExistingFlagKeys, ExpensePolicy.SystemId, ExpensePolicy."Version") then
                    InsertRow(TempPolicyToEvalBuffer, SubjectSystemId, SubjectVersion, ExpensePolicy);
            until ExpensePolicy.Next() = 0;
    end;

    procedure HasOutstandingPolicies(ExpenseReportLine: Record "Expense Report Line"): Boolean
    var
        HasApplicablePolicies: Boolean;
        HasOutstandingPoliciesResult: Boolean;
        HasPoliciesChangedSinceEvaluation: Boolean;
    begin
        GetEvaluationState(ExpenseReportLine, HasApplicablePolicies, HasOutstandingPoliciesResult, HasPoliciesChangedSinceEvaluation);
        exit(HasOutstandingPoliciesResult);
    end;

    procedure GetEvaluationState(ExpenseReportLine: Record "Expense Report Line"; var HasApplicablePolicies: Boolean; var HasOutstandingPoliciesResult: Boolean; var HasPoliciesChangedSinceEvaluation: Boolean)
    var
        ExpensePolicy: Record "Expense Policy";
        ExistingFlagKeys: Dictionary of [Text, Boolean];
        SubjectSystemId: Guid;
        SubjectVersion: Integer;
    begin
        HasApplicablePolicies := false;
        HasOutstandingPoliciesResult := false;
        HasPoliciesChangedSinceEvaluation := false;

        SubjectSystemId := ExpenseReportLine.SystemId;
        SubjectVersion := ExpenseReportLine."Policy Eval Version";

        SetApplicablePolicyFilter(ExpensePolicy, ExpenseReportLine);
        if not ExpensePolicy.FindSet() then
            exit;

        HasApplicablePolicies := true;
        LoadExistingFlagKeys(SubjectSystemId, SubjectVersion, ExistingFlagKeys);
        repeat
            if (ExpenseReportLine."Policies Evaluated At" <> 0DT) and (ExpensePolicy.SystemModifiedAt > ExpenseReportLine."Policies Evaluated At") then
                HasPoliciesChangedSinceEvaluation := true;
            if not FlagExists(ExistingFlagKeys, ExpensePolicy.SystemId, ExpensePolicy."Version") then begin
                HasOutstandingPoliciesResult := true;
                exit;
            end;
        until ExpensePolicy.Next() = 0;
    end;

    local procedure SetApplicablePolicyFilter(var ExpensePolicy: Record "Expense Policy"; ExpenseReportLine: Record "Expense Report Line")
    begin
        // Applicable policies are the enabled report-line policies whose category matches the line
        // or is blank (a blank category applies to every category). The category-or-blank rule is
        // pushed into the query filter so unrelated categories are never loaded.
        ExpensePolicy.SetCurrentKey("Subject Type", Enabled, "Expense Category Code");
        ExpensePolicy.SetRange("Subject Type", ExpensePolicy."Subject Type"::"Expense Report Line");
        ExpensePolicy.SetRange(Enabled, true);
        ExpensePolicy.SetFilter("Expense Category Code", '%1|%2', ExpenseReportLine."Expense Category", '');
    end;

    local procedure LoadExistingFlagKeys(SubjectSystemId: Guid; SubjectVersion: Integer; var ExistingFlagKeys: Dictionary of [Text, Boolean])
    var
        ExpensePolicyFlag: Record "Expense Policy Flag";
    begin
        // Load every flag recorded for this subject version once, keyed by policy and policy version,
        // so the applicable-policy loop can test each policy against an in-memory set instead of
        // issuing a separate database Get per policy (the previous N+1 pattern against a persistent
        // table on every policies-to-evaluate or mark-evaluated request).
        Clear(ExistingFlagKeys);
        ExpensePolicyFlag.SetRange("Subject Type", ExpensePolicyFlag."Subject Type"::"Expense Report Line");
        ExpensePolicyFlag.SetRange("Subject System Id", SubjectSystemId);
        ExpensePolicyFlag.SetRange("Subject Version", SubjectVersion);
        ExpensePolicyFlag.SetLoadFields("Policy System Id", "Policy Version");
        if ExpensePolicyFlag.FindSet() then
            repeat
                ExistingFlagKeys.Set(FlagKey(ExpensePolicyFlag."Policy System Id", ExpensePolicyFlag."Policy Version"), true);
            until ExpensePolicyFlag.Next() = 0;
    end;

    local procedure FlagExists(ExistingFlagKeys: Dictionary of [Text, Boolean]; PolicySystemId: Guid; PolicyVersion: Integer): Boolean
    begin
        // A policy no longer needs evaluating when a flag already exists for the line's current
        // subject version and the policy's current version. This keeps the endpoint idempotent and
        // avoids returning policies that were just re-evaluated.
        exit(ExistingFlagKeys.ContainsKey(FlagKey(PolicySystemId, PolicyVersion)));
    end;

    local procedure FlagKey(PolicySystemId: Guid; PolicyVersion: Integer): Text
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
