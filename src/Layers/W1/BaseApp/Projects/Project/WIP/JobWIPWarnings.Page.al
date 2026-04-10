// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

page 1026 "Job WIP Warnings"
{
    Caption = 'Project WIP Warnings';
    PageType = List;
    SourceTable = "Job WIP Warning";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Job WIP Total Entry No."; Rec."Job WIP Total Entry No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Warning Message"; Rec."Warning Message")
                {
                    ApplicationArea = Jobs;
                }
            }
        }
    }

    actions
    {
    }
}

