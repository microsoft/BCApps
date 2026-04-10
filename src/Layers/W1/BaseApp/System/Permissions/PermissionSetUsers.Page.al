// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using System.Security.User;

page 9885 "Permission Set Users"
{
    ApplicationArea = Basic, Suite;
    Caption = 'User Assignments';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Perm. Set Assignment Buffer";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(UserName; Rec.Code)
                {
                    Caption = 'User Name';
                    TableRelation = User;
                    ToolTip = 'Specifies the name of the user.';
                }
                field(FullUserName; Rec.Name)
                {
                    Caption = 'Full Name';
                    ToolTip = 'Specifies the full name of the user.';
                    Visible = false;
                }
                field(CompanyName; Rec.CompanyName)
                {
                    Caption = 'Company';
                    ToolTip = 'Specifies the company that the permission set applies to.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(View)
            {
                Caption = 'View';
                Image = View;
                Scope = Repeater;
                ToolTip = 'View or edit the user.';

                trigger OnAction()
                var
                    User: Record User;
                begin
                    User.SetRange("User Security ID", Rec.SecurityId);
                    Page.Run(Page::"User Card", User);
                end;
            }
        }
    }

    procedure SetSource(var PermSetAssignmentBuffer: Record "Perm. Set Assignment Buffer")
    begin
        Rec.Copy(PermSetAssignmentBuffer, true);
        Rec.SetRange(Type, Rec.Type::User);
        CurrPage.Update(false);
    end;
}