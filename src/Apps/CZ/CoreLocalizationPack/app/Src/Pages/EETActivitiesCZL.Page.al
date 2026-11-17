// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Visualization;

page 11706 "EET Activities CZL"
{
    Caption = 'EET Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "EET Cue CZL";
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            cuegroup(TodayEntries)
            {
                Caption = 'Today''s EET Entries';
                field("Sent Entries"; Rec."Sent Entries")
                {
                }
                field("Successful Entries"; Rec."Successful Entries")
                {
                }
                field("Entries with Warnings"; Rec."Entries with Warnings")
                {
                }
                field("Pending Entries"; Rec."Pending Entries")
                {
                }
                field("Canceled Entries"; Rec."Canceled Entries")
                {
                }
                field("Failed Entries"; Rec."Failed Entries")
                {
                }
            }
            cuegroup(Amounts)
            {
                Caption = 'Amounts';
                CuegroupLayout = Wide;
                field("Registered Amount"; Rec."Registered Amount")
                {
                }
                field("Pending Amount"; Rec."Pending Amount")
                {
                }
                field("Canceled Amount"; Rec."Canceled Amount")
                {
                }
                field("Failed Amount"; Rec."Failed Amount")
                {
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CuesAndKpis: Codeunit "Cues And KPIs";
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetRange("Created At Filter", CreateDateTime(Today(), 000000T), CreateDateTime(Today(), 235959.999T));
    end;
}
