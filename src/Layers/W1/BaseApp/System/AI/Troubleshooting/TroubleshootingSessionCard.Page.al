// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.Workspace;

page 2041 "Troubleshooting Session Card"
{
    ApplicationArea = All;
    Caption = 'Troubleshooting Session';
    PageType = Card;
    SourceTable = "Troubleshooting Session Entry";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    RefreshOnActivate = true;
    AboutTitle = 'About this troubleshooting session';
    AboutText = 'Review the saved report for this conversation. The details are shown as plain JSON without additional truncation. Access to the report is checked by the platform for its owner and every represented company.';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
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
                    Importance = Additional;
                }
            }
            group(ReportDetails)
            {
                Caption = 'Report Details';
                field(Details; DetailsText)
                {
                    Caption = 'Details (JSON)';
                    ToolTip = 'Specifies the full saved report as plain JSON, including conversation history, the latest response, and coverage limitations. No additional truncation is applied by this page.';
                    MultiLine = true;
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
                ToolTip = 'Update the page to show the latest saved troubleshooting report.';

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

    trigger OnAfterGetCurrRecord()
    var
        DetailsContent: BigText;
        DetailsStream: InStream;
    begin
        Clear(DetailsText);
        if IsNullGuid(Rec."Troubleshooting Id") then
            exit;

        Rec.CalcFields(Details);
        if not Rec.Details.HasValue() then
            exit;

        Rec.Details.CreateInStream(DetailsStream, TextEncoding::UTF8);
        DetailsContent.Read(DetailsStream);
        DetailsContent.GetSubText(DetailsText, 1);
    end;

    var
        DetailsText: Text;
}
