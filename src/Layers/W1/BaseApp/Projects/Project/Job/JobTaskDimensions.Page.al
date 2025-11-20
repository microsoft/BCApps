// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

page 1005 "Job Task Dimensions"
{
    Caption = 'Project Task Dimensions';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Job Task Dimension";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension that the dimension value filter will be linked to. To select a dimension codes, which are set up in the Dimensions window, click the drop-down arrow in the field.';
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension value that the dimension value filter will be linked to. To select a value code, which are set up in the Dimensions window, choose the drop-down arrow in the field.';
                }
            }
        }
    }

    actions
    {
    }
}

