// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
using System.Environment;

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
    }

    keys
    {
        key(PK; "Company Name")
        {
            Clustered = true;
        }
    }

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
    procedure GetOrCreateCompanyLimits(CompanyName: Text[30])
    begin
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

    local procedure InsertEnvironmentDefaultRecord()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then begin
            Rec."Company Name" := GetAllCompaniesTok();
            Rec."Monthly Credit Limit" := 200;
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
}