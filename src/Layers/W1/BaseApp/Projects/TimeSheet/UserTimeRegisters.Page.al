// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using System.Security.User;

page 71 "User Time Registers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'User Time Registers';
    PageType = List;
    SourceTable = "User Time Register";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Minutes; Rec.Minutes)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

