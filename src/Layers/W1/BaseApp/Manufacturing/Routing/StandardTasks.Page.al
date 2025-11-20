// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

page 99000799 "Standard Tasks"
{
    ApplicationArea = Manufacturing;
    Caption = 'Standard Tasks';
    PageType = List;
    SourceTable = "Standard Task";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the standard task code.';
                }
                field(Control4; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the description of the standard task.';
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
        area(navigation)
        {
            group("&Std. Task")
            {
                Caption = '&Std. Task';
                Image = Tools;
                action(Tools)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Tools';
                    Image = Tools;
                    RunObject = Page "Standard Task Tools";
                    RunPageLink = "Standard Task Code" = field(Code);
                    ToolTip = 'View or edit information about tools that apply to operations that represent the standard task.';
                }
                action(Personnel)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Personnel';
                    Image = User;
                    RunObject = Page "Standard Task Personnel";
                    RunPageLink = "Standard Task Code" = field(Code);
                    ToolTip = 'View or edit information about personnel that applies to operations that represent the standard task.';
                }
                action(Description)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Description';
                    Image = Description;
                    RunObject = Page "Standard Task Descript. Sheet";
                    RunPageLink = "Standard Task Code" = field(Code);
                    ToolTip = 'View or edit a special description that applies to operations that represent the standard task. ';
                }
                action("Quality Measures")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Quality Measures';
                    Image = TaskQualityMeasure;
                    RunObject = Page "Standard Task Qlty Measures";
                    RunPageLink = "Standard Task Code" = field(Code);
                    ToolTip = 'View or edit information about quality measures that apply to operations that represent the standard task.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Task)
            {
                Caption = 'Task';

                actionref(Tools_Promoted; Tools)
                {
                }
                actionref(Personnel_Promoted; Personnel)
                {
                }
                actionref(Description_Promoted; Description)
                {
                }
                actionref("Quality Measures_Promoted"; "Quality Measures")
                {
                }
            }
        }
    }
}

