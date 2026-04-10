// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

page 9144 "Approvals Activities"
{
    Caption = 'Approvals';
    PageType = CardPart;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Approvals Activities Cue";

    layout
    {
        area(content)
        {
            cuegroup(Approvals)
            {
                Caption = 'Pending Approvals';

                field("Requests Sent for Approval"; Rec."Requests Sent for Approval")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Approval Entries";
                    ToolTip = 'Specifies requests for certain documents, cards, or journal lines that your approver must approve before you can proceed.';
                }
                field("Requests to Approve"; Rec."Requests to Approve")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Requests to Approve";
                    ToolTip = 'Specifies requests for certain documents, cards, or journal lines that you must approve for other users before they can proceed.';
                }
            }
        }

    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        Rec.SetRange("User ID Filter", UserId);
    end;
}
