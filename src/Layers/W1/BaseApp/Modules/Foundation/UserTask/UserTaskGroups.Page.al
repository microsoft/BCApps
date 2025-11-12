// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Task;

page 1177 "User Task Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'User Task Groups';
    CardPageID = "User Task Group";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "User Task Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique ID for the group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the group.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(UserTaskGroupMembers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Task Group Members';
                Image = Users;
                RunObject = Page "User Task Group Members";
                RunPageLink = "User Task Group Code" = field(Code);
                Scope = Repeater;
                ToolTip = 'View or edit the members of the user task group.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UserTaskGroupMembers_Promoted; UserTaskGroupMembers)
                {
                }
            }
        }
    }
}

