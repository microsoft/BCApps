// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

page 6314 "PBI Sales Pipeline"
{
    Caption = 'PBI Sales Pipeline';
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
                field(ID; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                }
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = All;
                    Caption = 'Stage';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Value';
                }
                field("Measure Name"; Rec."Measure Name")
                {
                    ApplicationArea = All;
                    Caption = 'Measure Name';
                }
                field("Measure No."; Rec."Measure No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Cycle Code';
                    ToolTip = 'Specifies a code for the sales process.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        PBISalesPipelineChartCalc: Codeunit "PBI Sales Pipeline Chart Calc.";
    begin
        PBISalesPipelineChartCalc.GetValues(Rec);
    end;
}

