// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

page 4444 "Email Account Folders"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Email Folders";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                IndentationControls = Name;
                IndentationColumn = Rec.Indent;
                ShowAsTree = true;

                field(Name; Rec."Folder Name")
                {
                    ApplicationArea = All;
                    Caption = 'Folder Name';
                    ToolTip = 'Specifies the name of the email folder';
                }
                field(ID; Rec.Id)
                {
                    ApplicationArea = All;
                    Caption = 'Folder ID';
                    ToolTip = 'Specifies the unique identifier of the email folder';
                    Visible = false;
                }
                field("Has Children"; Rec."Has Children")
                {
                    ApplicationArea = All;
                    Caption = 'Has Children';
                    ToolTip = 'Specifies whether the email folder has subfolders';
                }
                field(TestID; Rec.TestID)
                {
                    ApplicationArea = All;
                    Caption = 'Test ID';
                    ToolTip = 'Specifies the test ID of the email folder';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                Image = RollUpCosts;
                ToolTip = 'Roll up costs for the selected email folder';

                trigger OnAction()
                begin
                    Email.GetMailFolders(TempEmailAccountRec."Account Id", TempEmailAccountRec.Connector, Rec)
                end;
            }
        }
    }

    var
        TempEmailAccountRec: Record "Email Account" temporary;
        Email: Codeunit Email;

    trigger OnOpenPage()
    begin
        Email.GetMailFolders(TempEmailAccountRec."Account Id", TempEmailAccountRec.Connector, Rec)
    end;

    procedure SetEmailAccount(EmailAccountId: Guid; Connector: Enum "Email Connector")
    begin
        TempEmailAccountRec."Account Id" := EmailAccountId;
        TempEmailAccountRec.Connector := Connector;
    end;
}