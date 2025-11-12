// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Task;

using System.Security.AccessControl;
using System.Security.User;

page 1176 "User Task Group Members"
{
    Caption = 'User Task Group Members';
    PageType = ListPart;
    SourceTable = "User Task Group Member";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                //The GridLayout property is only supported on controls of type Grid
                //GridLayout = Rows;
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Name';
                    DrillDown = false;
                    ToolTip = 'Specifies a user that is a member of the group.';

                    trigger OnAssistEdit()
                    var
                        User: Record User;
                        Users: Page Users;
                    begin
                        if User.Get(Rec."User Security ID") then
                            Users.SetRecord(User);

                        Users.LookupMode := true;
                        if Users.RunModal() = ACTION::LookupOK then begin
                            Users.GetRecord(User);
                            Rec."User Security ID" := User."User Security ID";
                            CurrPage.Update(true);
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }
}

