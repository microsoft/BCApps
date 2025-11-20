// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.MachineCenter;

using Microsoft.Foundation.Period;
using Microsoft.Manufacturing.Capacity;

page 99000762 "Machine Center Statistics"
{
    Caption = 'Machine Center Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Machine Center";

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
                            ToolTip = 'Specifies the total capacity of this machine center that is planned for the period in question.';
                        }
                        field("WorkCtrEffCapacity[1]"; WorkCtrEffCapacity[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Effective Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the total capacity multiplied by the efficiency.';
                        }
                        field("WorkCtrExpEfficiency[1]"; WorkCtrExpEfficiency[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Efficiency %';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the efficiency % of this machine center that is planned for the period in question.';
                        }
                        field("WorkCtrExpCost[1]"; WorkCtrExpCost[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Total Cost';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the total costs of this machine center that are planned for the period in question.';
                        }
                        field("MachineCtrActualThisPeriod"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'ACTUAL';
                        }
                        field("WorkCtrActNeed[1]"; WorkCtrActNeed[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Need';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the actual need of this machine center for the period in question.';
                        }
                        field("WorkCtrActEfficiency[1]"; WorkCtrActEfficiency[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Efficiency %';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the efficiency % of this machine center that is planned for the period in question.';
                        }
                        field("WorkCtrActCost[1]"; WorkCtrActCost[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Total Cost';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the total costs of this machine center that are planned for the period in question.';
                        }
                    }
                    group("This Year")
                    {
                        Caption = 'This Year';
                        field("MachineCtrExpectedThisYear"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrCapacity[2]"; WorkCtrCapacity[2])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this machine center.';
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
                        field("MachineCtrActualThisYear"; '')
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
                        field("MachineCtrExpectedLastYear"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrCapacity[3]"; WorkCtrCapacity[3])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this machine center.';
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
                        field("MachineCtrActualLastYear"; '')
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
                        field("MachineCtrExpectedTotal"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrCapacity[4]"; WorkCtrCapacity[4])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this machine center.';
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
                        field("MachineCtrActualTotal"; '')
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
                    Caption = 'Capacity (Effective)';
                    ToolTip = 'Specifies the effective available capacity of the machine center.';
                }
                field("Prod. Order Need (Qty.)"; Rec."Prod. Order Need (Qty.)")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Need (Qty.)';
                    ToolTip = 'Specifies the calculated capacity requirements for production orders at this machine center.';
                }
            }
            group(Manufacturing)
            {
                Caption = 'Manufacturing';
                fixed(Control1903836601)
                {
                    ShowCaption = false;
                    group(Control1903866801)
                    {
                        Caption = 'This Period';
                        field("Quantity Produced"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'QUANTITY PRODUCED';
                        }
                        field("WorkCtrOutputQty[1]"; WorkCtrOutputQty[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Output';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the produced quantity output for the period in question.';
                        }
                        field("WorkCtrScrapQty[1]"; WorkCtrScrapQty[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Scrap';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the produced scrap quantity for the period in question.';
                        }
                        field("WorkCtrScrapPct[1]"; WorkCtrScrapPct[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Scrap %';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the scrap % for the period in question.';
                        }
                        field("MachineCtrCapThisPeriod"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'CAPACITY';
                        }
                        field("WorkCtrRunTime[1]"; WorkCtrRunTime[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Run Time';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the run time for the period in question.';
                        }
                        field("WorkCtrStopTime[1]"; WorkCtrStopTime[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Stop Time';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the stop time for the period in question.';
                        }
                        field("WorkCtrStopPct[1]"; WorkCtrStopPct[1])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Stop %';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the stop time in percentage of the total time for the period in question.';
                        }
                    }
                    group(Control1901992801)
                    {
                        Caption = 'This Year';
                        field("MachineCtrQtyThisYear"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrOutputQty[2]"; WorkCtrOutputQty[2])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this machine center.';
                        }
                        field("WorkCtrScrapQty[2]"; WorkCtrScrapQty[2])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrScrapPct[2]"; WorkCtrScrapPct[2])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("MachineCtrCapThisYear"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrRunTime[2]"; WorkCtrRunTime[2])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this machine center.';
                        }
                        field("WorkCtrStopTime[2]"; WorkCtrStopTime[2])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrStopPct[2]"; WorkCtrStopPct[2])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                    }
                    group(Control1900296801)
                    {
                        Caption = 'Last Year';
                        field("MachineCtrQtyLastYear"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrOutputQty[3]"; WorkCtrOutputQty[3])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this machine center.';
                        }
                        field("WorkCtrScrapQty[3]"; WorkCtrScrapQty[3])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrScrapPct[3]"; WorkCtrScrapPct[3])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("MachineCtrCapLastYear"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrRunTime[3]"; WorkCtrRunTime[3])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this machine center.';
                        }
                        field("WorkCtrStopTime[3]"; WorkCtrStopTime[3])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrStopPct[3]"; WorkCtrStopPct[3])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                    }
                    group(Control1901743201)
                    {
                        Caption = 'Total';
                        field("MachineCtrQtyTotal"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrOutputQty[4]"; WorkCtrOutputQty[4])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this machine center.';
                        }
                        field("WorkCtrScrapQty[4]"; WorkCtrScrapQty[4])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrScrapPct[4]"; WorkCtrScrapPct[4])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("MachineCtrCapTotal"; '')
                        {
                            ApplicationArea = Manufacturing;
                            Caption = '';
                        }
                        field("WorkCtrRunTime[4]"; WorkCtrRunTime[4])
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the amount of work that can be done in a specified time period at this machine center.';
                        }
                        field("WorkCtrStopTime[4]"; WorkCtrStopTime[4])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                        field("WorkCtrStopPct[4]"; WorkCtrStopPct[4])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = false;
                        }
                    }
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

        MachineCenter2.Get(Rec."No.");
        MachineCenter2.CopyFilters(Rec);

        for i := 1 to 4 do begin
            WorkCtrActNeed[i] := 0;
            WorkCtrActCost[i] := 0;
            WorkCtrOutputQty[i] := 0;
            WorkCtrScrapQty[i] := 0;
            WorkCtrStopTime[i] := 0;
            WorkCtrRunTime[i] := 0;

            MachineCenter2.SetFilter("Date Filter", WorkCtrDateFilter[i]);
            MachineCenter2.CalcFields(
              "Capacity (Total)",
              "Capacity (Effective)",
              "Prod. Order Need (Qty.)");

            CapLedgEntry.SetRange(Type, CapLedgEntry.Type::"Machine Center");
            CapLedgEntry.SetRange("No.", Rec."No.");
            CapLedgEntry.SetFilter("Work Shift Code", Rec."Work Shift Filter");
            CapLedgEntry.SetFilter("Item No.", Rec."Item Filter");
            CapLedgEntry.SetFilter("Posting Date", WorkCtrDateFilter[i]);
            CapLedgEntry.CalcSums("Setup Time", "Run Time", "Stop Time", "Output Quantity", "Scrap Quantity");
            WorkCtrActNeed[i] := CapLedgEntry."Setup Time" + CapLedgEntry."Run Time" + CapLedgEntry."Stop Time";
            WorkCtrStopTime[i] := CapLedgEntry."Stop Time";
            WorkCtrRunTime[i] := CapLedgEntry."Setup Time" + CapLedgEntry."Run Time";
            WorkCtrOutputQty[i] := CapLedgEntry."Output Quantity";
            WorkCtrScrapQty[i] := CapLedgEntry."Scrap Quantity";
            CapLedgEntry.SetAutoCalcFields("Direct Cost", "Overhead Cost");
            if CapLedgEntry.Find('-') then
                repeat
                    WorkCtrActCost[i] := WorkCtrActCost[i] + CapLedgEntry."Direct Cost" + CapLedgEntry."Overhead Cost";
                until CapLedgEntry.Next() = 0;

            WorkCtrCapacity[i] := MachineCenter2."Capacity (Total)";
            WorkCtrEffCapacity[i] := MachineCenter2."Capacity (Effective)";

            WorkCtrScrapPct[i] := CalcPercentage(WorkCtrScrapQty[i], WorkCtrOutputQty[i]);
            WorkCtrExpEfficiency[i] := CalcPercentage(WorkCtrEffCapacity[i], WorkCtrCapacity[i]);
            WorkCtrActEfficiency[i] := CalcPercentage(WorkCtrActNeed[i], WorkCtrCapacity[i]);
            WorkCtrStopPct[i] := CalcPercentage(WorkCtrStopTime[i], WorkCtrRunTime[i]);
        end;
    end;

    var
        MachineCenter2: Record "Machine Center";
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
        WorkCtrScrapQty: array[4] of Decimal;
        WorkCtrOutputQty: array[4] of Decimal;
        WorkCtrScrapPct: array[4] of Decimal;
        WorkCtrStopTime: array[4] of Decimal;
        WorkCtrRunTime: array[4] of Decimal;
        WorkCtrStopPct: array[4] of Decimal;

    local procedure CalcPercentage(PartAmount: Decimal; Base: Decimal): Decimal
    begin
        if Base <> 0 then
            exit(100 * PartAmount / Base);

        exit(0);
    end;
}

