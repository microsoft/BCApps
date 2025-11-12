// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.WorkCenter;

using Microsoft.Foundation.Period;
using Microsoft.Manufacturing.Capacity;

page 99000756 "Work Center Statistics"
{
    Caption = 'Work Center Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Work Center";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                fixed(Control1903895201)
                {
                    ShowCaption = false;
                    group("This Period")
                    {
                        Caption = 'This Period';
                        field("WorkCtrDateName[1]"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'EXPECTED';
                        }
                        field("WorkCtrCapacity[1]"; WorkCtrCapacity[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Total Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the total capacity of this work center that is planned for the period in question.';
                        }
                        field("WorkCtrEffCapacity[1]"; WorkCtrEffCapacity[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Effective Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the effective capacity of this work center that is planned for the period in question.';
                        }
                        field("WorkCtrExpEfficiency[1]"; WorkCtrExpEfficiency[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Efficiency %';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the efficiency % of this work center that is planned for the period in question.';
                        }
                        field("WorkCtrExpCost[1]"; WorkCtrExpCost[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Total Cost';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the total costs of this work center that are planned for the period in question.';
                        }
                        field("WorkCtrActualThisPeriod"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'ACTUAL';
                        }
                        field("WorkCtrActNeed[1]"; WorkCtrActNeed[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Need';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the actual need of this work center for the period in question.';
                        }
                        field("WorkCtrActEfficiency[1]"; WorkCtrActEfficiency[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Efficiency %';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the efficiency % of this work center that is planned for the period in question';
                        }
                        field("WorkCtrActCost[1]"; WorkCtrActCost[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Total Cost';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the actual used total costs for the period in question.';
                        }
                    }
                    group("This Year")
                    {
                        Caption = 'This Year';
                        field("WorkCtrExpectedThisYear"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrCapacity[2]"; WorkCtrCapacity[2])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this work center. ';
                        }
                        field("WorkCtrEffCapacity[2]"; WorkCtrEffCapacity[2])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrExpEfficiency[2]"; WorkCtrExpEfficiency[2])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrExpCost[2]"; WorkCtrExpCost[2])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrActualThisYear"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrActNeed[2]"; WorkCtrActNeed[2])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrActEfficiency[2]"; WorkCtrActEfficiency[2])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrActCost[2]"; WorkCtrActCost[2])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                    }
                    group("Last Year")
                    {
                        Caption = 'Last Year';
                        field("WorkCtrExpectedLastYear"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrCapacity[3]"; WorkCtrCapacity[3])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this work center. ';
                        }
                        field("WorkCtrEffCapacity[3]"; WorkCtrEffCapacity[3])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrExpEfficiency[3]"; WorkCtrExpEfficiency[3])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrExpCost[3]"; WorkCtrExpCost[3])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrActualLastYear"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrActNeed[3]"; WorkCtrActNeed[3])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrActEfficiency[3]"; WorkCtrActEfficiency[3])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrActCost[3]"; WorkCtrActCost[3])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                    }
                    group(Total)
                    {
                        Caption = 'Total';
                        field("WorkCtrExpectedTotal"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrCapacity[4]"; WorkCtrCapacity[4])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this work center. ';
                        }
                        field("WorkCtrEffCapacity[4]"; WorkCtrEffCapacity[4])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrExpEfficiency[4]"; WorkCtrExpEfficiency[4])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrExpCost[4]"; WorkCtrExpCost[4])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrActualTotal"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrActNeed[4]"; WorkCtrActNeed[4])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrActEfficiency[4]"; WorkCtrActEfficiency[4])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrActCost[4]"; WorkCtrActCost[4])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                    }
                }
            }
            group("Prod. Order")
            {
                Caption = 'Prod. Order';
                field("Capacity (Effective)"; Rec."Capacity (Effective)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the effective available capacity of the work center.';
                }
                field("Prod. Order Need (Qty.)"; Rec."Prod. Order Need (Qty.)")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Need (Qty.)';
                    ToolTip = 'Specifies the calculated capacity requirements for production orders at this work center.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if CurrentDate <> WorkDate() then begin
            CurrentDate := WorkDate();
            DateFilterCalc.CreateAccountingPeriodFilter(WorkCtrDateFilter[1], WorkCtrDateName[1], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(WorkCtrDateFilter[2], WorkCtrDateName[2], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(WorkCtrDateFilter[3], WorkCtrDateName[3], CurrentDate, -1);
        end;

        WorkCenter2.Get(Rec."No.");
        WorkCenter2.CopyFilters(Rec);

        for i := 1 to 4 do begin
            WorkCtrActCost[i] := 0;
            WorkCtrActNeed[i] := 0;

            WorkCenter2.SetFilter("Date Filter", WorkCtrDateFilter[i]);
            WorkCenter2.CalcFields("Capacity (Total)", "Capacity (Effective)", "Prod. Order Need (Qty.)");

            CapLedgEntry.SetCurrentKey("Work Center No.", "Work Shift Code", "Posting Date");
            CapLedgEntry.SetRange("Work Center No.", Rec."No.");
            CapLedgEntry.SetFilter("Work Shift Code", Rec."Work Shift Filter");
            CapLedgEntry.SetFilter("Posting Date", WorkCtrDateFilter[i]);
            if CapLedgEntry.Find('-') then
                repeat
                    CapLedgEntry.CalcFields("Direct Cost", "Overhead Cost");
                    WorkCtrActNeed[i] :=
                      WorkCtrActNeed[i] +
                      CapLedgEntry."Setup Time" + CapLedgEntry."Run Time" + CapLedgEntry."Stop Time";
                    WorkCtrActCost[i] := WorkCtrActCost[i] + CapLedgEntry."Direct Cost" + CapLedgEntry."Overhead Cost";
                until CapLedgEntry.Next() = 0;
            WorkCtrCapacity[i] := WorkCenter2."Capacity (Total)";
            WorkCtrEffCapacity[i] := WorkCenter2."Capacity (Effective)";
            WorkCtrExpEfficiency[i] := CalcPercentage(WorkCtrEffCapacity[i], WorkCtrCapacity[i]);
            WorkCtrActEfficiency[i] := CalcPercentage(WorkCtrActNeed[i], WorkCtrCapacity[i]);
        end;

        Rec.SetRange("Date Filter");
    end;

    var
        WorkCenter2: Record "Work Center";
        CapLedgEntry: Record "Capacity Ledger Entry";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        WorkCtrDateFilter: array[4] of Text[30];
        WorkCtrDateName: array[4] of Text[30];
        i: Integer;
        CurrentDate: Date;
        WorkCtrCapacity: array[4] of Decimal;
        WorkCtrEffCapacity: array[4] of Decimal;
        WorkCtrExpEfficiency: array[4] of Decimal;
        WorkCtrExpCost: array[4] of Decimal;
        WorkCtrActNeed: array[4] of Decimal;
        WorkCtrActEfficiency: array[4] of Decimal;
        WorkCtrActCost: array[4] of Decimal;

    local procedure CalcPercentage(PartAmount: Decimal; Base: Decimal): Decimal
    begin
        if Base <> 0 then
            exit(100 * PartAmount / Base);

        exit(0);
    end;
}

