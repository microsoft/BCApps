// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

table 149040 "AIT Credit Limit Setup"
{
    Caption = 'AI Eval Credit Limit Setup';
    DataClassification = SystemMetadata;
    Access = Internal;
    ReplicateData = false;
    DataPerCompany = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            ToolTip = 'Specifies the primary key.';
        }
        field(10; "Monthly Credit Limit"; Decimal)
        {
            Caption = 'Monthly Credit Limit';
            ToolTip = 'Specifies the maximum number of Copilot credits that can be consumed by agent test suites during the current month.';
            MinValue = 0;
            DecimalPlaces = 2 : 5;
        }
        field(11; "Enforcement Enabled"; Boolean)
        {
            Caption = 'Enforcement Enabled';
            ToolTip = 'Specifies whether the credit limit enforcement is enabled. When disabled, suites can consume unlimited credits.';
            InitValue = true;
        }
        field(12; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
            ToolTip = 'Specifies the start date of the current tracking period.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetOrCreate(): Boolean
    var
        IsNew: Boolean;
    begin
        if not Get() then begin
            Init();
            "Primary Key" := '';
            "Period Start Date" := CalcDate('<-CM>', Today());
            Insert();
            IsNew := true;
        end;

        // Auto-reset period on month change
        if "Period Start Date" < CalcDate('<-CM>', Today()) then begin
            "Period Start Date" := CalcDate('<-CM>', Today());
            Modify();
        end;

        exit(IsNew);
    end;

    procedure GetPeriodStartDate(): Date
    begin
        GetOrCreate();
        exit("Period Start Date");
    end;

    procedure GetPeriodEndDate(): Date
    begin
        exit(CalcDate('<CM>', GetPeriodStartDate()));
    end;
}
