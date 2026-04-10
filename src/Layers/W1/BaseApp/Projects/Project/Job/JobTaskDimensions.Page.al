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
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                }
            }
        }
    }

    actions
    {
    }
}

