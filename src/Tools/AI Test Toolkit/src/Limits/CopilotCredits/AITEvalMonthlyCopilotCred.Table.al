// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

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
        field(1; Code; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Monthly Credit Limit"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Monthly Credit Limit';
            ToolTip = 'Specifies the maximum number of Copilot credits that can be consumed by agent test suites during the current month.';
            MinValue = 0;
            DecimalPlaces = 2 : 5;
        }
        field(3; "Enforcement Enabled"; Boolean)
        {
            Caption = 'Enforcement Enabled';
            ToolTip = 'Specifies whether the credit limit enforcement is enabled. When disabled, suites can consume unlimited credits.';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    procedure GetOrCreate()
    begin
        if not Get() then
            InsertDefaultRecord();
    end;

    procedure GetPeriodStartDate(): Date
    begin
        exit(CalcDate('<-CM>', Today()));
    end;

    procedure GetPeriodEndDate(): Date
    begin
        exit(CalcDate('<CM>', Today()));
    end;

    internal procedure InsertDefaultRecord()
    begin
        Rec.Code := '';
        Rec."Monthly Credit Limit" := 200;
        Rec."Enforcement Enabled" := true;
        Rec.Insert();
    end;
}