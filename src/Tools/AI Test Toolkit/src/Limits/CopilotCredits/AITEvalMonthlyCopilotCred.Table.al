// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
using System.Environment;
using System.AI;
using System.Telemetry;

table 149040 "AIT Eval Monthly Copilot Cred."
{
    Caption = 'AI Eval Monthly Copilot Credit Limits';
    DataClassification = SystemMetadata;
    Access = Internal;
    ReplicateData = false;
    DataPerCompany = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            ToolTip = 'Specifies the company this limit applies to. An empty value means the limit applies to the entire environment (across all companies).';
            TableRelation = Company.Name;
        }
        field(2; "Monthly Credit Limit"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Monthly Credit Limit';
            ToolTip = 'Specifies the maximum number of Copilot credits that can be consumed during the current month.';
            MinValue = 0;
            DecimalPlaces = 2 : 5;
        }
        field(3; "Enforcement Enabled"; Boolean)
        {
            Caption = 'Enforcement Enabled';
            ToolTip = 'Specifies whether the credit limit enforcement is enabled for this scope.';
            InitValue = true;
        }
        field(4; "Monthly AI Credit Limit"; Decimal)
        {
            Caption = 'Monthly AI Credit Limit';
            ToolTip = 'Specifies the separate V2 AI credit limit. Legacy Copilot credit limits are not converted.';
            AutoFormatType = 0;
            MinValue = 0;
        }
        field(5; "AI Enforcement Enabled"; Boolean)
        {
            Caption = 'AI Credit Enforcement Enabled';
            ToolTip = 'Specifies whether the separate AI credit limit is enforced against completed V2 consumption.';
            InitValue = false;
        }
    }

    keys
    {
        key(PK; "Company Name")
        {
            Clustered = true;
        }
    }

    var
        CompanyCreditLimitUpdatedLbl: Label 'Company monthly AI eval credit limit %1 for Company %2 by the UserSecurityId %3, Enabled %4, Credit Limit %5', Locked = true;
        EnvironmentCreditLimitUpdatedLbl: Label 'Environment monthly AI eval credit limit %1 by the UserSecurityId %2, Enabled %3, Credit Limit %4', Locked = true;
        NotUIClientSessionErr: Label 'Modifying AI Eval Monthly Copilot Credit Limits is only allowed from UI sessions.', Locked = true;
        InsertedLbl: Label 'inserted', Locked = true;
        ModifiedLbl: Label 'modified', Locked = true;
        DeletedLbl: Label 'deleted', Locked = true;

    procedure LogInsertedAuditMessage()
    begin
        LogAuditMessage(InsertedLbl);
    end;

    procedure LogModifiedAuditMessage()
    begin
        LogAuditMessage(ModifiedLbl);
    end;

    procedure LogDeletedAuditMessage()
    begin
        LogAuditMessage(DeletedLbl);
    end;

    procedure VerifyWriteOperationAllowed()
    var
        CallerModule, CurrentModule : ModuleInfo;
    begin
        if Session.GetExecutionContext() in [ExecutionContext::Upgrade, ExecutionContext::Install] then begin
            NavApp.GetCallerModuleInfo(CallerModule);
            NavApp.GetCurrentModuleInfo(CurrentModule);
            if CallerModule.Id = CurrentModule.Id then
                // Allow upgrade/install code from the current app to insert the default records.
                exit;
        end;

        if not (Session.CurrentClientType in [ClientType::Web, ClientType::Phone, ClientType::Tablet]) then
            Error(NotUIClientSessionErr);
    end;

    /// <summary>
    /// Gets or creates the environment-level record.
    /// </summary>
    procedure GetOrCreateEnvironmentLimits()
    begin
        if not Get(GetAllCompaniesTok()) then
            InsertEnvironmentDefaultRecord();
    end;

    /// <summary>
    /// Gets or creates the record for a specific company.
    /// </summary>
    procedure GetOrCreateCompanyLimits()
    var
        CompanyName: Text[30];
    begin
#pragma warning disable AA0139
        CompanyName := CompanyName();
#pragma warning restore AA0139

        if not Get(CompanyName) then
            InsertCompanyDefaultRecord(CompanyName);
    end;

    procedure GetPeriodStartDate(): Date
    begin
        exit(CalcDate('<-CM>', Today()));
    end;

    procedure GetPeriodEndDate(): Date
    begin
        exit(CalcDate('<CM>', Today()));
    end;

    procedure GetCreditLimit(): Decimal
    var
        Quota: Codeunit "Copilot Quota";
    begin
        if Quota.IsNewMonetizationEnabled() then
            exit("Monthly AI Credit Limit");
        exit("Monthly Credit Limit");
    end;

    procedure IsEnforcementEnabled(): Boolean
    var
        Quota: Codeunit "Copilot Quota";
    begin
        if Quota.IsNewMonetizationEnabled() then
            exit("AI Enforcement Enabled");
        exit("Enforcement Enabled");
    end;

    procedure SetCreditLimitSetup(CreditLimit: Decimal; Enabled: Boolean)
    var
        Quota: Codeunit "Copilot Quota";
    begin
        if Quota.IsNewMonetizationEnabled() then begin
            "Monthly AI Credit Limit" := CreditLimit;
            "AI Enforcement Enabled" := Enabled;
        end else begin
            "Monthly Credit Limit" := CreditLimit;
            "Enforcement Enabled" := Enabled;
        end;
    end;

    local procedure InsertEnvironmentDefaultRecord()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then begin
            Rec."Company Name" := GetAllCompaniesTok();
            Rec."Monthly Credit Limit" := 2500;
            Rec."Enforcement Enabled" := true;
        end else begin
            Rec."Company Name" := GetAllCompaniesTok();
            Rec."Monthly Credit Limit" := 0;
            Rec."Enforcement Enabled" := false;
        end;

        Rec.Insert();
    end;

    local procedure InsertCompanyDefaultRecord(CompanyName: Text[30])
    begin
        Rec."Company Name" := CompanyName;
        Rec."Monthly Credit Limit" := 0;
        Rec."Enforcement Enabled" := false;
        Rec.Insert();
    end;

    local procedure GetAllCompaniesTok(): Text[30]
    begin
        exit('');
    end;

    local procedure LogAuditMessage(Operation: Text)
    var
        Quota: Codeunit "Copilot Quota";
    begin
        if Quota.IsNewMonetizationEnabled() then
            Operation += ' (AI credits)';
        if (Rec."Company Name" = GetAllCompaniesTok()) then begin
            LogAuditMessageCore(StrSubstNo(EnvironmentCreditLimitUpdatedLbl, Operation, UserSecurityId(), IsEnforcementEnabled(), GetCreditLimit()), 0 /* AdministeredEnvironment */);
            exit;
        end;

        LogAuditMessageCore(StrSubstNo(CompanyCreditLimitUpdatedLbl, Operation, Rec."Company Name", UserSecurityId(), IsEnforcementEnabled(), GetCreditLimit()), 3 /* AdministeredCompany */);
    end;

    local procedure LogAuditMessageCore(SecurityAuditDescription: Text; AuditMessageOperation: Integer)
    var
        AuditLog: Codeunit "Audit Log";
    begin
        AuditLog.LogAuditMessage(SecurityAuditDescription, SecurityOperationResult::Success, AuditCategory::PolicyManagement, AuditMessageOperation, 0 /* Succeeded */);
    end;
}