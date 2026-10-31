// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.RoleCenters;

using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Setup;

pageextension 8524 "ICO365Activities" extends "O365 Activities"
{
    layout
    {
        addafter("Ongoing Purchases")
        {
            cuegroup(Intercompany)
            {
                Caption = 'Intercompany';
                Visible = ShowIntercompanyActivities;
                field("IC Inbox Transactions"; Rec."IC Inbox Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Pending Inbox Transactions';
                    Tooltip = 'Specifies the number of pending incoming intercompany transactions.';
                    DrillDownPageID = "IC Inbox Transactions";
                    Visible = Rec."IC Inbox Transactions" <> 0;
                }
                field("IC Outbox Transactions"; Rec."IC Outbox Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Pending Outbox Transactions';
                    ToolTip = 'Specifies the number of pending outgoing intercompany transactions.';
                    DrillDownPageID = "IC Outbox Transactions";
                    Visible = Rec."IC Outbox Transactions" <> 0;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetIntercompanyGroupVisibility();
    end;

    var
        ShowIntercompanyActivities: Boolean;

    local procedure SetIntercompanyGroupVisibility()
    var
        ICSetup: Record "IC Setup";
    begin
        ICSetup.SetLoadFields("IC Partner Code");
        if ICSetup.Get() then
            ShowIntercompanyActivities :=
              (ICSetup."IC Partner Code" <> '') and ((Rec."IC Inbox Transactions" <> 0) or (Rec."IC Outbox Transactions" <> 0));
    end;
}
