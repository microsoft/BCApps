// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Projects.Project.Analysis;

page 6311 "PBI Job Profitability"
{
    Caption = 'PBI Project Profitability';
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
                }
                field("Measure Name"; Rec."Measure Name")
                {
                    ApplicationArea = All;
                    Caption = 'Measure Name';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Value';
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
        PBIJobChartCalc.GetValues(Rec, "Job Chart Type"::Profitability.AsInteger());
    end;
}

