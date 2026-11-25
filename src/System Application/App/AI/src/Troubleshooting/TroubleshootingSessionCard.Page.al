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

    trigger OnAfterGetCurrRecord()
    var
        DetailsContent: BigText;
        DetailsStream: InStream;
        ReportJson: Text;
    begin
        Clear(DetailsText);
        Clear(OwnerName);
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
