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
                    ToolTip = 'Specifies the number of the related project.';
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project task.';
                }
                field("Job WIP Total Entry No."; Rec."Job WIP Total Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the entry number from the associated project WIP total.';
                }
                field("Warning Message"; Rec."Warning Message")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a warning message that is related to a project WIP calculation.';
                }
            }
        }
    }

    actions
    {
    }
}

