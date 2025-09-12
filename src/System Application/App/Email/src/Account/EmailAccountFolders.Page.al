// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

page 4444 "Email Account Folders"
{
    PageType = List;
    ApplicationArea = All;
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