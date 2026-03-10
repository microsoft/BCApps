// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

page 50161 "BC14 Upgrade Settings"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "BC14 Upgrade Settings";
    Caption = 'BC14 Upgrade Settings';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General Settings';

                field("One Step Upgrade"; Rec."One Step Upgrade")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to run the upgrade automatically after replication completes.';
                }

                field("One Step Upgrade Delay"; Rec."One Step Upgrade Delay")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the delay before starting the upgrade after replication.';
                }

                field("Collect All Errors"; Rec."Collect All Errors")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to collect all errors during migration or stop at first error.';
                }
            }

            group(Status)
            {
                Caption = 'Status Information';

                field("Data Upgrade Started"; Rec."Data Upgrade Started")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the data upgrade was started.';
                    Editable = false;
                }

                field("Replication Completed"; Rec."Replication Completed")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the replication was completed.';
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetOrInsertBC14UpgradeSettings(Rec);
    end;
}
