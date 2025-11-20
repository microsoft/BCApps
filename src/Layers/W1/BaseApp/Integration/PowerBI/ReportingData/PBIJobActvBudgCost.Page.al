// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Projects.Project.Analysis;

page 6312 "PBI Job Act. v. Budg. Cost"
{
    Caption = 'PBI Project Act. v. Budg. Cost';
    Editable = false;
    PageType = List;
    SourceTable = "Power BI Chart Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Measure No."; Rec."Measure No.")
                {
                    ApplicationArea = All;
                    Caption = 'Project No.';
                    ToolTip = 'Specifies the project.';
                }
                field("Measure Name"; Rec."Measure Name")
                {
                    ApplicationArea = All;
                    Caption = 'Measure Name';
                    ToolTip = 'Specifies the name.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        PBIJobChartCalc: Codeunit "PBI Job Chart Calc.";
    begin
        PBIJobChartCalc.GetValues(Rec, "Job Chart Type"::"Actual to Budget Cost".AsInteger());
    end;
}

