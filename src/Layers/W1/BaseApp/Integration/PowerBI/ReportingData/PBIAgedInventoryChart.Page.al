// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

page 6309 "PBI Aged Inventory Chart"
{
    Caption = 'PBI Aged Inventory Chart';
    Editable = false;
    PageType = List;
    SourceTable = "Power BI Chart Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(ID; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Value';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = All;
                    Caption = 'Date';
                }
                field("Period Type"; Rec."Period Type")
                {
                    ApplicationArea = All;
                    Caption = 'Period Type';
                }
                field("Period Type Sorting"; Rec."Period Type Sorting")
                {
                    ApplicationArea = All;
                    Caption = 'Period Type Sorting';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        PBIAgedInventoryCalc: Codeunit "PBI Aged Inventory Calc.";
    begin
        PBIAgedInventoryCalc.GetValues(Rec);
    end;
}

