// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Setup;

using Microsoft.Service.Resources;

page 6018 "Skill Codes"
{
    ApplicationArea = Service;
    Caption = 'Skill Codes';
    PageType = List;
    SourceTable = "Skill Code";
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
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a code for the skill.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of the skill code.';
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
            group("&Skill Code")
            {
                Caption = '&Skill Code';
                Image = Skills;
                action("&Resource Skills")
                {
                    ApplicationArea = Service;
                    Caption = '&Resource Skills';
                    Image = ResourceSkills;
                    RunObject = Page "Resource Skills";
                    RunPageLink = "Skill Code" = field(Code);
                    RunPageView = sorting("Skill Code")
                                  where(Type = const(Resource));
                    ToolTip = 'View or edit information about sills that can be assigned to resources.';
                }
            }
        }
    }
}

