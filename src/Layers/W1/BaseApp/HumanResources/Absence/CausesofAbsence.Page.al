// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Absence;

page 5210 "Causes of Absence"
{
    AdditionalSearchTerms = 'vacation holiday sickness leave cause';
    ApplicationArea = BasicHR;
    Caption = 'Causes of Absence';
    PageType = List;
    SourceTable = "Cause of Absence";
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
                    ApplicationArea = BasicHR;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                }
                field("Total Absence (Base)"; Rec."Total Absence (Base)")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the total number of absences (calculated in days or hours) for all employees.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = BasicHR;
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

