// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.Workspace;

page 2040 "Troubleshooting Sessions"
{
    ApplicationArea = All;
    Caption = 'Troubleshooting Sessions';
    PageType = List;
    SourceTable = "Troubleshooting Session Entry";
    SourceTableView = sorting(SystemCreatedAt, "Troubleshooting Id") order(descending);
    CardPageId = "Troubleshooting Session Card";
    UsageCategory = History;
    AdditionalSearchTerms = 'troubleshooting reports,Copilot,diagnostics';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    RefreshOnActivate = true;
    AboutTitle = 'About troubleshooting sessions';
    AboutText = 'Review saved troubleshooting reports that you are authorized to read. A concluded iteration means an answer was returned, not that the business problem was resolved. Follow-up answers update the same report.';

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
            action(Refresh)
            {
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Update the page to show the latest saved troubleshooting reports.';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Refresh_Promoted; Refresh)
                {
                }
            }
        }
    }
}
