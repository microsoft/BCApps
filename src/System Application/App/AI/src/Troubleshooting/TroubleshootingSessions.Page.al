// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.Troubleshooting;

using System.AI.Workspace;

page 7785 "Troubleshooting Sessions"
{
    ApplicationArea = All;
    Caption = 'Troubleshooting Sessions';
    PageType = List;
    SourceTable = "Troubleshooting Session Entry";
    SourceTableView = sorting(SystemCreatedAt, "Troubleshooting Id") order(descending);
    CardPageId = "Troubleshooting Session Card";
    UsageCategory = History;
    InherentEntitlements = X;
    InherentPermissions = X;
    AdditionalSearchTerms = 'troubleshooting reports,Copilot,diagnostics';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    RefreshOnActivate = true;
    AboutTitle = 'About troubleshooting sessions';
    AboutText = 'The list opens with sessions that are in progress or awaiting user input. To see sessions with any status, choose Show All Sessions.';

    layout
    {
        area(Content)
        {
            repeater(Sessions)
            {
                field(TroubleshootingId; Rec."Troubleshooting Id")
                {
                    Caption = 'Troubleshooting ID';
                    ToolTip = 'Specifies the identifier of the continuing troubleshooting conversation.';
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies the saved troubleshooting state. Concluded means an iteration returned an answer, not that the business problem was resolved.';
                }
                field(FirstSavedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'First Saved At';
                    ToolTip = 'Specifies when the first report for this conversation was saved, not when the conversation started.';
                }
                field(LastSavedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Saved At';
                    ToolTip = 'Specifies when the saved report was last updated.';
                }
                field(Revision; Rec.Revision)
                {
                    Caption = 'Revision';
                    ToolTip = 'Specifies the source revision of the saved report. Revisions increase as follow-up answers are saved and can contain gaps.';
                }
                field(OwnerUserSecurityId; Rec."Owner User Security Id")
                {
                    Caption = 'Owner User Security ID';
                    ToolTip = 'Specifies the security identifier of the user who owns the troubleshooting conversation.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowAllSessions)
            {
                Caption = 'Show All Sessions';
                Image = AllLines;
                ToolTip = 'Show troubleshooting sessions with any status that you can access.';

                trigger OnAction()
                begin
                    Rec.SetRange(Status);
                    CurrPage.Update(false);
                end;
            }
            action(ShowActiveSessions)
            {
                Caption = 'Show Active Sessions';
                Image = FilterLines;
                ToolTip = 'Show troubleshooting sessions that are in progress or awaiting user input.';

                trigger OnAction()
                begin
                    ApplyActiveStatusFilter();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ApplyActiveStatusFilter();
    end;

    local procedure ApplyActiveStatusFilter()
    begin
        Rec.SetFilter(Status, '%1|%2', Rec.Status::InProgress, Rec.Status::AwaitingUser);
    end;
}
