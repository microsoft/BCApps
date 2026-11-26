// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.Troubleshooting;

using System.AI.Workspace;
using System.Security.AccessControl;

page 7786 "Troubleshooting Session Card"
{
    ApplicationArea = All;
    Caption = 'Troubleshooting Session';
    PageType = Card;
    SourceTable = "Troubleshooting Session Entry";
    InherentEntitlements = X;
    InherentPermissions = X;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    RefreshOnActivate = true;
    AboutTitle = 'About this troubleshooting session';
    AboutText = 'Review the saved report for this conversation. The platform limits access to reports based on their owner and the companies they cover.';

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
                field(CaseClosed; Rec."Case Closed")
                {
                    ToolTip = 'Specifies whether the owner closed the case.';
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
                field(OwnerName; OwnerName)
                {
                    Caption = 'Owner';
                    ToolTip = 'Specifies the name of the user who owns the troubleshooting conversation, if available.';
                    Importance = Additional;
                }
            }
            group(ReportDetails)
            {
                Caption = 'Report Details';
                field(Details; DetailsText)
                {
                    Caption = 'Details (JSON)';
                    ToolTip = 'Specifies the saved report as JSON, including conversation history, the latest response, and coverage limitations.';
                    ExtendedDatatype = RichContent;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CloseCase)
            {
                Caption = 'Close Case';
                Image = Close;
                ToolTip = 'Close this active case without changing its report or AI status.';
                Enabled = CanCloseCase;

                trigger OnAction()
                var
                    TroubleshootingCase: Codeunit "Troubleshooting Case";
                begin
                    if not Confirm(CloseCaseQst, false) then
                        exit;
                    if not TroubleshootingCase.CloseCase(Rec."Troubleshooting Id") then
                        Error(CaseNotClosedErr);
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        DetailsContent: BigText;
        DetailsStream: InStream;
        ReportJson: Text;
    begin
        Clear(DetailsText);
        Clear(OwnerName);
        CanCloseCase := not IsNullGuid(Rec."Troubleshooting Id") and not Rec."Case Closed" and
            (Rec."Owner User Security Id" = UserSecurityId());
        if IsNullGuid(Rec."Troubleshooting Id") then
            exit;

        OwnerName := GetOwnerName();
        Rec.CalcFields(Details);
        if not Rec.Details.HasValue() then
            exit;

        Rec.Details.CreateInStream(DetailsStream, TextEncoding::UTF8);
        DetailsContent.Read(DetailsStream);
        DetailsContent.GetSubText(ReportJson, 1);
        // Encode report content so customer text is displayed, never interpreted as markup.
        DetailsText := '<pre>' + ReportJson.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;') + '</pre>';
    end;

    var
        DetailsText: Text;
        OwnerName: Text;
        CanCloseCase: Boolean;
        CloseCaseQst: Label 'Close this case? You cannot reopen it.';
        CaseNotClosedErr: Label 'The case could not be closed. It may already be closed or you may no longer have access.';

    local procedure GetOwnerName(): Text
    var
        User: Record User;
    begin
        if not User.ReadPermission() then
            exit('');

        if not User.Get(Rec."Owner User Security Id") then
            exit('');

        if User."Full Name" <> '' then
            exit(User."Full Name");
        exit(User."User Name");
    end;
}
