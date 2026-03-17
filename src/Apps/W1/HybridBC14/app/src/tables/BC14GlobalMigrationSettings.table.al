// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

table 50156 "BC14 Global Migration Settings"
{
    DataClassification = CustomerContent;
    Description = 'BC14 Global Migration Settings';
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
        field(10; "Migration In Progress"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Migration In Progress';
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
            BC14GlobalSettings.Insert();
            BC14GlobalSettings.Get();
        end;
    end;

    internal procedure GetUpgradeDelay(): Duration
    begin
        exit(30 * 1000); // 30 seconds
    end;

    internal procedure SetMigrationInProgress(IsRunning: Boolean)
    begin
        GetOrInsertGlobalSettings(Rec);
        Rec."Migration In Progress" := IsRunning;
        Rec.Modify();
    end;
}
