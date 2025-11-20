// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

page 964 "Period Summary Archive FactBox"
{
    Caption = 'Period Summary';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            field("DateQuantity[1]"; DateQuantity[1])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[1];
                ToolTip = 'Specifies the number of hours registered for this day.';
                Editable = false;
            }
            field("DateQuantity[2]"; DateQuantity[2])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[2];
                ToolTip = 'Specifies the number of hours registered for this day.';
                Editable = false;
            }
            field("DateQuantity[3]"; DateQuantity[3])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[3];
                ToolTip = 'Specifies the number of hours registered for this day.';
                Editable = false;
            }
            field("DateQuantity[4]"; DateQuantity[4])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[4];
                ToolTip = 'Specifies the number of hours registered for this day.';
                Editable = false;
            }
            field("DateQuantity[5]"; DateQuantity[5])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[5];
                ToolTip = 'Specifies the number of hours registered for this day.';
                Editable = false;
            }
            field("DateQuantity[6]"; DateQuantity[6])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[6];
                ToolTip = 'Specifies the number of hours registered for this day.';
                Editable = false;
            }
            field("DateQuantity[7]"; DateQuantity[7])
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + DateDescription[7];
                ToolTip = 'Specifies the number of hours registered for this day.';
                Editable = false;
            }
            field(TotalQuantity; TotalQuantity)
            {
                ApplicationArea = Jobs;
                Caption = 'Total';
                Editable = false;
                Style = Strong;
                StyleExpr = true;
                ToolTip = 'Specifies the total.';
            }
            field(PresenceQty; PresenceQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Total Presence';
                ToolTip = 'Specifies the total presence (calculated in days or hours) for all resources on the line.';
            }
            field(AbsenceQty; AbsenceQty)
            {
                ApplicationArea = Jobs;
                Caption = 'Total Absence';
                ToolTip = 'Specifies the total absence (calculated in days or hours) for all resources on the line.';
            }
        }
    }

    actions
    {
    }

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        DateDescription: array[7] of Text[30];
        DateQuantity: array[7] of Decimal;
        TotalQuantity: Decimal;
        PresenceQty: Decimal;
        AbsenceQty: Decimal;

    procedure UpdateData(TimeSheetHeaderArchive: Record "Time Sheet Header Archive")
    begin
        TimeSheetMgt.CalcSummaryArcFactBoxData(TimeSheetHeaderArchive, DateDescription, DateQuantity, TotalQuantity, AbsenceQty);
        PresenceQty := TotalQuantity - AbsenceQty;
        CurrPage.Update(false);
    end;
}

