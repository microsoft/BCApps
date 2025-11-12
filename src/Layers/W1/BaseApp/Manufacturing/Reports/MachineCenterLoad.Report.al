// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using System.Utilities;

report 99000784 "Machine Center Load"
{
    DefaultRenderingLayout = MachineCenterLoadRDLC;
    AdditionalSearchTerms = 'production resource load,production personnel load';
    ApplicationArea = Manufacturing;
    Caption = 'Machine Center Load (obsolete)';
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
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(WorkCenterTableCaptFilter; TableCaption + ':' + WorkCenterFilter)
            {
            }
            column(WorkCenterFilter; WorkCenterFilter)
            {
            }
            column(No_WorkCenter; "No.")
            {
            }
            column(Name_WorkCenter; Name)
            {
            }
            column(MachineCenterLoadCaption; MachineCenterLoadCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(CapacityAvailableCaption; CapacityAvailableCaptionLbl)
            {
            }
            column(CapacityEfficiencyCaption; CapacityEfficiencyCaptionLbl)
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
                    column(No_MachineCenter; "No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Name_MachineCenter; Name)
                    {
                        IncludeCaption = true;
                    }
                    column(Capacity_MachineCenter; Capacity)
                    {
                        IncludeCaption = true;
                    }
                    column(CpctyEffete_MachineCenter; "Capacity (Effective)")
                    {
                        IncludeCaption = true;
                    }
                    column(PONdQty_MachineCenter; "Prod. Order Need (Qty.)")
                    {
                        IncludeCaption = true;
                    }
                    column(CapacityAvailable; CapacityAvailable)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(CapacityEfficiency; CapacityEfficiency)
                    {
                        DecimalPlaces = 1 : 1;
                    }

                    trigger OnAfterGetRecord()
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
        AboutTitle = 'About Machine Center Load (obsolete)';
        AboutText = 'Analyze the load on a machine center. ** This report is obsolete and will be removed in a later release.** Please consult the report documentation for alternative ways to get to this data.';

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
                        ToolTip = 'Specifies the starting date for the machine center load evaluation.';
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'No. of Periods';
                        ToolTip = 'Specifies the number of time intervals for which the evaluation is to be created.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the time interval you have selected to view the report, such as day, week, month, quarter.';
                    }
                    field(MinCapEfficToPrint; MinCapEfficToPrint)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Load bigger than (pct.)';
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies a filter to print only machine centers whose loads exceed this percentage, for example, if you want to print all machine centers with a load of over 95% in order to troubleshoot a particular problem.';
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
        layout(MachineCenterLoadRDLC)
        {
            Caption = 'Machine Center Load (obsolete)';
            Type = RDLC;
            LayoutFile = './Manufacturing/Reports/MachineCenterLoad.rdlc';
        }
    }

    labels
    {
    }

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
        MinCapEfficToPrint: Decimal;
        MachineCenterLoadCaptionLbl: Label 'Machine Center Load';
        CurrReportPageNoCaptionLbl: Label 'Page';
        CapacityAvailableCaptionLbl: Label 'Available';
        CapacityEfficiencyCaptionLbl: Label 'Expected Efficiency';
        PeriodStartingDateCaptionLbl: Label 'Period Starting Date';
        PeriodEndingDateCaptionLbl: Label 'Period Ending Date';

    procedure InitializeRequest(NewStartingDate: Date; NewNoOfPeriods: Integer; NewPeriodLength: DateFormula; NewMinCapEfficToPrint: Decimal)
    begin
        StartingDate := NewStartingDate;
        NoOfPeriods := NewNoOfPeriods;
        PeriodLength := NewPeriodLength;
        MinCapEfficToPrint := NewMinCapEfficToPrint;
    end;
}

