// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

page 46864 "BC14 Upgrade Settings"
{
    PageType = Card;
    SourceTable = "BC14 Global Migration Settings";
    Caption = 'BC14 Upgrade Settings';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;

    layout
    {
        area(Content)
        {
            group(Upgrade)
            {
                Caption = 'Upgrade';

                field(OneStepUpgrade; Rec."One Step Upgrade")
                {
                    ApplicationArea = All;
                    Caption = 'Run upgrade after replication';
                    ToolTip = 'Specifies whether to run the upgrade automatically after replication completes. Disable this if you want to manually trigger the upgrade.';
                }
                field(OneStepUpgradeDelay; Rec."One Step Upgrade Delay")
                {
                    ApplicationArea = All;
                    Caption = 'Upgrade delay after replication';
                    ToolTip = 'Specifies the delay before starting the upgrade after replication completes.';
                }
                field(MaxCompanySetupWaitTime; Rec."Max Company Setup Wait Time")
                {
                    ApplicationArea = All;
                    Caption = 'Max company setup wait time';
                    ToolTip = 'Specifies the maximum time to wait for company setup to complete before marking pending companies as failed. Increase this for large companies with lots of data. Default is 8 hours.';
                }
            }

            group(Status)
            {
                Caption = 'Status';

                field(DataUpgradeStarted; Rec."Data Upgrade Started")
                {
                    ApplicationArea = All;
                    Caption = 'Data Upgrade Started';
                    ToolTip = 'Specifies when the data upgrade was started.';
                    Editable = false;
                }
                field(ReplicationCompleted; Rec."Replication Completed")
                {
                    ApplicationArea = All;
                    Caption = 'Replication Completed';
                    ToolTip = 'Specifies when the replication was completed.';
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetOrInsertGlobalSettings(Rec);
    end;
}
