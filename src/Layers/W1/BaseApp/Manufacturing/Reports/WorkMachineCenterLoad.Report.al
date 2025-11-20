// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using System.Utilities;

report 99000792 "Work/Machine Center Load"
{
    ApplicationArea = Manufacturing;
    Caption = 'Work/Machine Center Load';
    DefaultRenderingLayout = WorkMachineCenterLoadWord;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Work Center Group"; "Work Center Group")
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Code";

            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(WorkCenterGroupTableCaptFilter; TableCaption + ': ' + WorkCenterGroupFilter)
            {
            }
            column(WorkCenterGroupFilter; WorkCenterGroupFilter)
            {
            }
            column(WorkCenterTableCaptFilter; "Work Center".TableCaption + ': ' + WorkCenterFilter)
            {
            }
            column(WorkCenterFilter; WorkCenterFilter)
            {
            }
            column(WorkCenterGroupCode; Code)
            {
                IncludeCaption = true;
            }
            column(WorkCenterGroupName; Name)
            {
                IncludeCaption = true;
            }
            dataitem(PeriodDates; "Integer")
            {
                DataItemTableView = sorting(Number);
                PrintOnlyIfDetail = true;

                column(PeriodStartingDate; Format(PeriodStartingDate))
                {
                }
                column(PeriodEndingDate; Format(PeriodEndingDate))
                {
                }
                dataitem("Work Center"; "Work Center")
                {
                    DataItemLink = "Work Center Group Code" = field(Code);
                    DataItemLinkReference = "Work Center Group";
                    DataItemTableView = sorting("Work Center Group Code");
                    RequestFilterFields = "Work Shift Filter";

                    column(WorkCenterNo; "No.")
                    {
                        IncludeCaption = true;
                    }
                    column(WorkCenterName; Name)
                    {
                        IncludeCaption = true;
                    }
                    column(WorkCenterCapacity; Capacity)
                    {
                        IncludeCaption = true;
                    }
                    column(WorkCenterUOMCode; "Unit of Measure Code")
                    {
                        IncludeCaption = true;
                    }
                    column(WorkCenterCapacityEffective; "Capacity (Effective)")
                    {
                        IncludeCaption = true;
                    }
                    column(WorkCenterProdOrderNeedQty; "Prod. Order Need (Qty.)")
                    {
                        IncludeCaption = true;
                    }
                    column(WorkCenterCapacityAvailable; WorkCenterCapacityAvailable)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(WorkCenterCapacityEfficiency; WorkCenterCapacityEfficiency)
                    {
                        DecimalPlaces = 1 : 1;
                    }
                    column(WorkCenterLoadStrTotal; WorkCenterLoadStrTotal)
                    {
                    }
                    dataitem("Machine Center"; "Machine Center")
                    {
                        DataItemLink = "Work Center No." = field("No."), "Work Shift Filter" = field("Work Shift Filter");
                        DataItemLinkReference = "Work Center";
                        DataItemTableView = sorting("Work Center No.");

                        column(MachineCenterNo; "No.")
                        {
                            IncludeCaption = true;
                        }
                        column(MachineCenterName; Name)
                        {
                            IncludeCaption = true;
                        }
                        column(MachineCenterCapacity; "Capacity")
                        {
                            IncludeCaption = true;
                        }
                        column(MachineCenterCapacityEffective; "Capacity (Effective)")
                        {
                            IncludeCaption = true;
                        }
                        column(MachineCenterProdOrderNeedQty; "Prod. Order Need (Qty.)")
                        {
                            IncludeCaption = true;
                        }
                        column(MachineCenterCapacityAvailable; MachineCenterCapacityAvailable)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(MachineCenterCapacityEfficiency; MachineCenterCapacityEfficiency)
                        {
                            DecimalPlaces = 1 : 1;
                        }
                        column(MachineCenterLoadStrTotal; MachineCenterLoadStrTotal)
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            EffectivityStr: Text[30];
                            LoadStr: Text[25];
                            LoadStr2: Text[25];
                        begin
                            CalcFields("Capacity (Effective)", "Prod. Order Need (Qty.)");

                            MachineCenterCapacityAvailable := "Capacity (Effective)" - "Prod. Order Need (Qty.)";
                            if "Capacity (Effective)" <> 0 then
                                MachineCenterCapacityEfficiency := Round("Prod. Order Need (Qty.)" / "Capacity (Effective)" * 100, 0.1)
                            else
                                if "Prod. Order Need (Qty.)" <> 0 then
                                    MachineCenterCapacityEfficiency := 100
                                else
                                    MachineCenterCapacityEfficiency := 0;

                            if MachineCenterCapacityEfficiency < MinCapEfficToPrint then
                                CurrReport.Skip();

                            EffectivityStr := Format(Round(MachineCenterCapacityEfficiency, 1));
                            if MachineCenterCapacityEfficiency <= 100 then begin
                                LoadStr := PadStr('', Round(MachineCenterCapacityEfficiency / 100 * MaxStrLen(LoadStr), 1), '#');
                                LoadStr2 := '';
                            end else begin
                                LoadStr := PadStr('', Round(MaxStrLen(LoadStr), 1), '#');
                                if Round(MachineCenterCapacityEfficiency, 1) <= 200 then
                                    LoadStr2 := PadStr('', Round((MachineCenterCapacityEfficiency - 100) / 100 * MaxStrLen(LoadStr), 1), '#')
                                else begin
                                    LoadStr2 := PadStr('', Round(MaxStrLen(LoadStr) - (5 + StrLen(EffectivityStr)), 1), '#');
                                    LoadStr2 := LoadStr2 + '...' + EffectivityStr + ' %';
                                end;
                            end;

                            MachineCenterLoadStrTotal := LoadStr + LoadStr2;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Date Filter", PeriodStartingDate, PeriodEndingDate);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        EffStr: Text[30];
                        LoadStr: Text[25];
                        LoadStr2: Text[25];
                    begin
                        CalcFields("Capacity (Effective)", "Prod. Order Need (Qty.)");

                        WorkCenterCapacityAvailable := "Capacity (Effective)" - "Prod. Order Need (Qty.)";
                        if "Capacity (Effective)" <> 0 then
                            WorkCenterCapacityEfficiency := Round("Prod. Order Need (Qty.)" / "Capacity (Effective)" * 100, 0.1)
                        else
                            if "Prod. Order Need (Qty.)" <> 0 then
                                WorkCenterCapacityEfficiency := 100
                            else
                                WorkCenterCapacityEfficiency := 0;

                        if WorkCenterCapacityEfficiency < MinCapEfficToPrint then
                            CurrReport.Skip();

                        EffStr := Format(Round(WorkCenterCapacityEfficiency, 1));
                        if WorkCenterCapacityEfficiency <= 100 then begin
                            LoadStr := PadStr('', Round(WorkCenterCapacityEfficiency / 100 * MaxStrLen(LoadStr), 1), '#');
                            LoadStr2 := '';
                        end else begin
                            LoadStr := PadStr('', Round(MaxStrLen(LoadStr), 1), '#');
                            if Round(WorkCenterCapacityEfficiency, 1) <= 200 then
                                LoadStr2 := PadStr('', Round((WorkCenterCapacityEfficiency - 100) / 100 * MaxStrLen(LoadStr), 1), '#')
                            else begin
                                LoadStr2 := PadStr('', Round(MaxStrLen(LoadStr) - (5 + StrLen(EffStr)), 1), '#');
                                LoadStr2 := LoadStr2 + '...' + EffStr + ' %';
                            end;
                        end;

                        WorkCenterLoadStrTotal := LoadStr + LoadStr2;
                    end;

                    trigger OnPostDataItem()
                    begin
                        PeriodStartingDate := PeriodEndingDate + 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Date Filter", PeriodStartingDate, PeriodEndingDate);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    i := i + 1;

                    if i > NoOfPeriods then
                        CurrReport.Break();

                    PeriodEndingDate := CalcDate(PeriodLength, PeriodStartingDate) - 1;
                end;

                trigger OnPreDataItem()
                begin
                    i := 0;

                    PeriodStartingDate := StartingDate;
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Work/Machine Center Load';
        AboutText = 'Get an overview of availability at the work center and machine center, such as the capacity, the allocated quantity, availability after order, and the load in percent.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Starting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the starting date for the evaluation.';
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'No. of Periods';
                        NotBlank = true;
                        ToolTip = 'Specifies the number of time intervals for which the evaluation is to be created.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Period Length';
                        NotBlank = true;
                        ToolTip = 'Specifies the length of the time interval, for example 1W = one week.';
                    }
                    field(MinCapEfficToPrint; MinCapEfficToPrint)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Load bigger than (pct.)';
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies a filter to print only work centers whose loads exceed this percentage, for example, if you want to print all work centers with a load of over 95% in order to troubleshoot a particular problem.';
                    }
                }
            }
        }

        trigger OnInit()
        begin
            if StartingDate = 0D then
                StartingDate := WorkDate();
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1W>');
            if NoOfPeriods = 0 then
                NoOfPeriods := 4;
        end;
    }


    rendering
    {
        layout(WorkMachineCenterLoadWord)
        {
            Type = Word;
            LayoutFile = './Manufacturing/Reports/WorkMachineCenterLoad.docx';
            Caption = 'Work/Machine Center Load (Word)';
        }
        layout(WorkMachineCenterLoadExcel)
        {
            Type = Excel;
            LayoutFile = './Manufacturing/Reports/WorkMachineCenterLoad.xlsx';
            Caption = 'Work/Machine Center Load (Excel)';
        }
    }

    labels
    {
        WorkMachineCenterLoad = 'Work/Machine Center Load';
        WorkCenterLoad = 'Work Center Load';
        WorkCenterLoadPrint = 'Work Center Load (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        WorkCenterLoadAnalysis = 'Work Center Load (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        MachineCenterLoad = 'Machine Center Load';
        MachineCenterLoadPrint = 'Machine Center Load (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        MachineCenterLoadAnalysis = 'Machine Center Load (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        WorkCenterGroupCodeLabel = 'Work Center Group Code';
        WorkCenterGroupNameLabel = 'Work Center Group Name';
        WorkCenterNoLabel = 'Work Center No.';
        WorkCenterNameLabel = 'Work Center Name';
        Available = 'Available';
        Load = 'Load';
        ExpectedEfficiency = 'Expected Efficiency';
        PeriodStartingDateCaption = 'Period Starting Date';
        PeriodEndingDateCaption = 'Period Ending Date';
        BarTxt = '0                       100                      200';
        BarTxt2 = '|                        |                        |';
        Page = 'Page';
        DataRetrieved = 'Data retrieved:';
        // About the report labels
        AboutTheReportLabel = 'About the report';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
    }

    trigger OnPreReport()
    begin
        if (StartingDate = 0D) or
            (NoOfPeriods = 0) or
            (Format(PeriodLength) = '')
        then
            Error(EmptyPeriodErr);

        WorkCenterGroupFilter := "Work Center Group".GetFilters();
        WorkCenterFilter := "Work Center".GetFilters();
    end;

    var
        PeriodLength: DateFormula;
        WorkCenterGroupFilter: Text;
        WorkCenterFilter: Text;
        StartingDate: Date;
        PeriodStartingDate: Date;
        PeriodEndingDate: Date;
        NoOfPeriods: Integer;
        i: Integer;
        WorkCenterCapacityAvailable: Decimal;
        WorkCenterCapacityEfficiency: Decimal;
        WorkCenterLoadStrTotal: Text[50];
        MachineCenterCapacityAvailable: Decimal;
        MachineCenterCapacityEfficiency: Decimal;
        MachineCenterLoadStrTotal: Text[50];
        MinCapEfficToPrint: Decimal;
        EmptyPeriodErr: Label 'You must specify the starting date, number of periods, and period length.';

    procedure InitializeRequest(NewStartingDate: Date; NewNoOfPeriods: Integer; NewPeriodLength: DateFormula; NewMinCapEfficToPrint: Decimal)
    begin
        StartingDate := NewStartingDate;
        NoOfPeriods := NewNoOfPeriods;
        PeriodLength := NewPeriodLength;
        MinCapEfficToPrint := NewMinCapEfficToPrint;
    end;
}