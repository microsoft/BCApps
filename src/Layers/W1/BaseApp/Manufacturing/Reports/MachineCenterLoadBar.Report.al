// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using System.Utilities;

report 99000786 "Machine Center Load/Bar"
{
    DefaultRenderingLayout = MachineCenterLoadBarRDLC;
    AdditionalSearchTerms = 'production resource load/bar,production personnel  load/bar';
    ApplicationArea = Manufacturing;
    Caption = 'Machine Center Load/Bar (obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'This report has been replaced by the "Work/Machine Center Load" report and will be removed in a future release.';
    ObsoleteTag = '27.0';

    dataset
    {
        dataitem("Work Center"; "Work Center")
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Work Shift Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Work_Center__TABLECAPTION_________WorkCenterFilter; TableCaption + ':' + WorkCenterFilter)
            {
            }
            column(WorkCenterFilter; WorkCenterFilter)
            {
            }
            column(Work_Center__No__; "No.")
            {
            }
            column(Work_Center_Name; Name)
            {
            }
            column(Machine_Center_Load___BarCaption; Machine_Center_Load___BarCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Machine_Center__No__Caption; "Machine Center".FieldCaption("No."))
            {
            }
            column(Machine_Center_NameCaption; "Machine Center".FieldCaption(Name))
            {
            }
            column(Machine_Center__Capacity__Effective__Caption; Machine_Center__Capacity__Effective__CaptionLbl)
            {
            }
            column(Machine_Center__Prod__Order_Need__Qty___Caption; "Machine Center".FieldCaption("Prod. Order Need (Qty.)"))
            {
            }
            column(CapacityAvailableCaption; CapacityAvailableCaptionLbl)
            {
            }
            column(CapacityEfficiencyCaption; CapacityEfficiencyCaptionLbl)
            {
            }
            column(LoadStrTotalCaption; LoadStrTotalCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                PrintOnlyIfDetail = true;
                column(PeriodStartingDate; Format(PeriodStartingDate))
                {
                }
                column(PeriodEndingDate; Format(PeriodEndingDate))
                {
                }
                column(BarTxt; BarTxt)
                {
                }
                column(BarTxt2; BarTxt2)
                {
                }
                column(PeriodStartingDateCaption; PeriodStartingDateCaptionLbl)
                {
                }
                column(PeriodEndingDateCaption; PeriodEndingDateCaptionLbl)
                {
                }
                dataitem("Machine Center"; "Machine Center")
                {
                    DataItemLink = "Work Center No." = field("No."), "Work Shift Filter" = field("Work Shift Filter");
                    DataItemLinkReference = "Work Center";
                    DataItemTableView = sorting("Work Center No.");
                    column(Machine_Center__No__; "No.")
                    {
                    }
                    column(Machine_Center_Name; Name)
                    {
                    }
                    column(Machine_Center__Capacity__Effective__; "Capacity (Effective)")
                    {
                    }
                    column(Machine_Center__Prod__Order_Need__Qty___; "Prod. Order Need (Qty.)")
                    {
                    }
                    column(CapacityAvailable; CapacityAvailable)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(CapacityEfficiency; CapacityEfficiency)
                    {
                        DecimalPlaces = 1 : 1;
                    }
                    column(LoadStrTotal; LoadStrTotal)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        EffectivityStr: Text[30];
                    begin
                        CalcFields("Capacity (Effective)", "Prod. Order Need (Qty.)");

                        CapacityAvailable := "Capacity (Effective)" - "Prod. Order Need (Qty.)";
                        if "Capacity (Effective)" <> 0 then
                            CapacityEfficiency := Round("Prod. Order Need (Qty.)" / "Capacity (Effective)" * 100, 0.1)
                        else
                            if "Prod. Order Need (Qty.)" <> 0 then
                                CapacityEfficiency := 100
                            else
                                CapacityEfficiency := 0;

                        if CapacityEfficiency < MinCapEfficToPrint then
                            CurrReport.Skip();

                        EffectivityStr := Format(Round(CapacityEfficiency, 1));
                        if CapacityEfficiency <= 100 then begin
                            LoadStr := PadStr('', Round(CapacityEfficiency / 100 * MaxStrLen(LoadStr), 1), '#');
                            LoadStr2 := '';
                        end else begin
                            LoadStr := PadStr('', Round(MaxStrLen(LoadStr), 1), '#');
                            if Round(CapacityEfficiency, 1) <= 200 then
                                LoadStr2 := PadStr('', Round((CapacityEfficiency - 100) / 100 * MaxStrLen(LoadStr), 1), '#')
                            else begin
                                LoadStr2 := PadStr('', Round(MaxStrLen(LoadStr) - (5 + StrLen(EffectivityStr)), 1), '#');
                                LoadStr2 := LoadStr2 + '...' + EffectivityStr + ' %';
                            end;
                        end;

                        LoadStrTotal := LoadStr + LoadStr2;
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
        AboutTitle = 'About Machine Center Load/Bar (obsolete)';
        AboutText = 'Get a list of machine centers that are overloaded according to the plan. ** This report is obsolete and will be removed in a later release.** Please consult the report documentation for alternative ways to get to this data.';

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
                        ToolTip = 'Specifies the starting date for the evaluation.';
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'No. of Periods';
                        ToolTip = 'Specifies the number of time intervals the evaluation is to be created for.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Period Length';
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

        actions
        {
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
        layout(MachineCenterLoadBarRDLC)
        {
            Caption = 'Machine Center Load/Bar (obsolete)';
            Type = RDLC;
            LayoutFile = './Manufacturing/Reports/MachineCenterLoadBar.rdlc';
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        BarTxt := '0                       100                      200';
        BarTxt2 := '|                        |                        |';
        if StartingDate = 0D then
            StartingDate := WorkDate();
        if Format(PeriodLength) = '' then
            Evaluate(PeriodLength, '<1W>');
        if NoOfPeriods = 0 then
            NoOfPeriods := 4;
    end;

    trigger OnPreReport()
    begin
        WorkCenterFilter := "Work Center".GetFilters();
    end;

    var
        WorkCenterFilter: Text;
        StartingDate: Date;
        PeriodStartingDate: Date;
        PeriodEndingDate: Date;
        PeriodLength: DateFormula;
        NoOfPeriods: Integer;
        i: Integer;
        CapacityAvailable: Decimal;
        CapacityEfficiency: Decimal;
        LoadStr: Text[25];
        LoadStr2: Text[25];
        LoadStrTotal: Text[50];
        MinCapEfficToPrint: Decimal;
        BarTxt: Text[52];
        BarTxt2: Text[51];
        Machine_Center_Load___BarCaptionLbl: Label 'Machine Center Load/Bar';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Machine_Center__Capacity__Effective__CaptionLbl: Label 'Capacity (Effective)';
        CapacityAvailableCaptionLbl: Label 'Available';
        CapacityEfficiencyCaptionLbl: Label 'Expected Efficiency';
        LoadStrTotalCaptionLbl: Label 'Load';
        PeriodStartingDateCaptionLbl: Label 'Period Starting Date';
        PeriodEndingDateCaptionLbl: Label 'Period Ending Date';
}

