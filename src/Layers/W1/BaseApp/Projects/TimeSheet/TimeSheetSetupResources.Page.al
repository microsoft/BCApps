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
                }
                field("Use Time Sheet"; Rec."Use Time Sheet")
                {
                    ApplicationArea = Jobs;
                }
                field("Time Sheet Owner User ID"; Rec."Time Sheet Owner User ID")
                {
                    ApplicationArea = Jobs;
                }
                field("Time Sheet Approver User ID"; Rec."Time Sheet Approver User ID")
                {
                    ApplicationArea = Jobs;
                }
            }

        }
    }
}
