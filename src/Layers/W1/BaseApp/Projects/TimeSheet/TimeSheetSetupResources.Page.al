// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Projects.Resources.Resource;

page 978 "Time Sheet Setup Resources"
{
    PageType = ListPart;
    SourceTable = Resource;
    Caption = 'Resources';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Use Time Sheet"; Rec."Use Time Sheet")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether a resource uses time sheets to record the time they use on tasks.';
                }
                field("Time Sheet Owner User ID"; Rec."Time Sheet Owner User ID")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the owner of the time sheet.';
                }
                field("Time Sheet Approver User ID"; Rec."Time Sheet Approver User ID")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ID of the approver of the time sheet.';
                }
            }

        }
    }
}
