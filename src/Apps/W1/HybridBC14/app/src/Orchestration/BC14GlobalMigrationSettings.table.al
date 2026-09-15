// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46856 "BC14 Global Migration Settings"
{
    DataClassification = CustomerContent;
    Description = 'Business Central 14 Global Migration Settings';
    DataPerCompany = false;

    fields
    {
        field(1; PrimaryKey; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Data Upgrade Started"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Data Upgrade Started';
        }
        field(4; "One Step Upgrade"; Boolean)
        {
            InitValue = true;
            DataClassification = CustomerContent;
            Caption = 'Run upgrade after replication';
        }
        field(5; "One Step Upgrade Delay"; Duration)
        {
            DataClassification = CustomerContent;
            Caption = 'Delay to run the upgrade after replication';
        }
        field(6; "Replication Completed"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Replication Completed';
        }
        field(7; "Max Company Setup Wait Time"; Duration)
        {
            DataClassification = CustomerContent;
            Caption = 'Max company setup wait time';
        }
    }

    keys
    {
        key(Key1; PrimaryKey)
        {
            Clustered = true;
        }
    }

    internal procedure GetOrInsertGlobalSettings(var BC14GlobalSettings: Record "BC14 Global Migration Settings")
    begin
        if not BC14GlobalSettings.Get() then begin
            BC14GlobalSettings."One Step Upgrade" := true;
            BC14GlobalSettings."One Step Upgrade Delay" := GetUpgradeDelay();
            BC14GlobalSettings."Max Company Setup Wait Time" := GetDefaultMaxCompanySetupWaitTime();
            if not BC14GlobalSettings.Insert() then
                BC14GlobalSettings.Get();
        end;
    end;

    internal procedure GetMaxCompanySetupWaitTime(): Duration
    begin
        GetOrInsertGlobalSettings(Rec);
        if Rec."Max Company Setup Wait Time" = 0 then
            exit(GetDefaultMaxCompanySetupWaitTime());
        exit(Rec."Max Company Setup Wait Time");
    end;

    local procedure GetDefaultMaxCompanySetupWaitTime(): Duration
    begin
        exit(8 * 60 * 60 * 1000); // 8 hours
    end;

    internal procedure GetUpgradeDelay(): Duration
    begin
        exit(30 * 1000); // 30 seconds
    end;
}
