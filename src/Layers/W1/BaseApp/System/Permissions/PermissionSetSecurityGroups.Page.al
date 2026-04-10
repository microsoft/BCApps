// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

page 9884 "Permission Set Security Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Security Groups Assignments';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Perm. Set Assignment Buffer";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Code; Rec.Code)
                {
                    ToolTip = 'Specifies the security group code.';
                }
                field(GroupName; Rec.Name)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the security group.';
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
                ToolTip = 'View or edit the security group.';

                trigger OnAction()
                var
                    SecurityGroupBuffer: Record "Security Group Buffer";
                begin
                    SecurityGroupBuffer.SetRange(Code, Rec.Code);
                    Page.Run(Page::"Security Groups", SecurityGroupBuffer);
                end;
            }
        }
    }

    procedure SetSource(var PermSetAssignmentBuffer: Record "Perm. Set Assignment Buffer")
    begin
        Rec.Copy(PermSetAssignmentBuffer, true);
        Rec.SetRange(Type, Rec.Type::SecurityGroup);
        CurrPage.Update(false);
    end;
}