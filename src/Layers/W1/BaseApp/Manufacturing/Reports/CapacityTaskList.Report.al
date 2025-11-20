// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;

report 99000780 "Capacity Task List"
{
    DefaultRenderingLayout = WordLayout;
    ApplicationArea = Manufacturing;
    Caption = 'Capacity Task List';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "Prod. Order Routing Line Group";

    dataset
    {
        dataitem("Prod. Order Routing Line Group"; "Prod. Order Routing Line")
        {
            DataItemTableView = sorting(Type, "No.");
            RequestFilterFields = Type, "No.", Status, "Starting Date";
            column(Type; Type)
            {
            }
            column(No; "No.")
            {
            }
            dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
            {
                DataItemTableView = sorting(Type, "No.");
                DataItemLink = Type = field(Type), "No." = field("No.");
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(PORtngLineTableCaptFilter; TableCaption + ':' + ProdOrderRtngLineFilter)
                {
                }
                column(ProdOrderRtngLineFilter; ProdOrderRtngLineFilter)
                {
                }
                column(Type_ProdOrderRtngLine; Type)
                {
                    IncludeCaption = true;
                }
                column(No_ProdOrderRtngLine; "No.")
                {
                    IncludeCaption = true;
                }
                column(PONo_ProdOrderRtngLine; "Prod. Order No.")
                {
                    IncludeCaption = true;
                }
                column(RtngNo_ProdOrderRtngLine; "Routing No.")
                {
                    IncludeCaption = true;
                }
                column(OPNo_ProdOrderRtngLine; "Operation No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_ProdOrderRtngLine; Description)
                {
                    IncludeCaption = true;
                }
                column(InptQty_ProdOrderRtngLine; "Input Quantity")
                {
                    IncludeCaption = true;
                }
                column(StrtTm_ProdOrderRtngLine; Format("Starting Time"))
                {
                }
                column(StrtDt_ProdOrderRtngLine; Format("Starting Date"))
                {
                }
                column(EndTime_ProdOrderRtngLine; Format("Ending Time"))
                {
                }
                column(EndDate_ProdOrderRtngLine; Format("Ending Date"))
                {
                }
                column(StartingDateTime; Format("Starting Date-Time"))
                {
                }
                column(EndingDateTime; Format("Ending Date-Time"))
                {
                }
                // RDLC Only
                column(CapacityTaskListCapt; CapacityTaskListCaptLbl)
                {
                }
                // RDLC Only
                column(CurrReportPageNoCapt; CurrReportPageNoCaptLbl)
                {
                }
                // RDLC Only
                column(ProdOrderRtngLnStrtDtCapt; ProdOrderRtngLnStrtDtCaptLbl)
                {
                }
                // RDLC Only
                column(ProdOrderRtngLnEndDtCapt; ProdOrderRtngLnEndDtCaptLbl)
                {
                }
                // RDLC Only
                column(ProdOrderRtngLnStrtTimeCapt; ProdOrderRtngLnStrtTimeCaptLbl)
                {
                }
                // RDLC Only
                column(ProdOrderRtngLnEndTimeCapt; ProdOrderRtngLnEndTimeCaptLbl)
                {
                }
                column(ExpectedCapacityNeed; "Expected Capacity Need" / CalcExpectedCapacityNeed())
                {
                    DecimalPlaces = 0 : 5;
                }
                column(UnitofMeasureCode; UnitOfMeasureCode)
                {
                }
                column(CapacityName; CapacityName)
                {
                }
                dataitem("Prod. Order Line"; "Prod. Order Line")
                {
                    DataItemLink = "Prod. Order No." = field("Prod. Order No."), "Line No." = field("Routing Reference No.");
                    column(ItemNo; "Item No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Description; Description)
                    {
                        IncludeCaption = true;
                    }
                }
                trigger OnAfterGetRecord()
                var
                    MachineCenter: Record "Machine Center";
                    WorkCenter: Record "Work Center";
                begin
                    if (Status = Status::Finished) or ("Routing Status" = "Routing Status"::Finished) then
                        CurrReport.Skip();

                    Clear(UnitOfMeasureCode);
                    if "Prod. Order Routing Line"."No." = '' then
                        exit;
                    case "Prod. Order Routing Line".Type of
                        "Prod. Order Routing Line".Type::"Work Center":
                            if WorkCenter.Get("Prod. Order Routing Line"."No.") then begin
                                CapacityName := WorkCenter.Name;
                                UnitOfMeasureCode := WorkCenter."Unit of Measure Code";
                            end;
                        "Prod. Order Routing Line".Type::"Machine Center":
                            begin
                                if MachineCenter.Get("Prod. Order Routing Line"."No.") then
                                    CapacityName := MachineCenter.Name;
                                if WorkCenter.Get(MachineCenter."Work Center No.") then
                                    UnitOfMeasureCode := WorkCenter."Unit of Measure Code";
                            end;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if (Status = Status::Finished) or ("Routing Status" = "Routing Status"::Finished) then
                    CurrReport.Skip();

                if (FoundMachineCenter.Contains("Prod. Order Routing Line Group"."No.")) or (FoundWorkCenter.Contains("Prod. Order Routing Line Group"."No.")) then
                    CurrReport.Skip();

                case "Prod. Order Routing Line Group".Type of
                    "Prod. Order Routing Line Group".Type::"Machine Center":
                        FoundMachineCenter.Add("Prod. Order Routing Line Group"."No.");

                    "Prod. Order Routing Line Group".Type::"Work Center":
                        FoundWorkCenter.Add("Prod. Order Routing Line Group"."No.");
                end;
            end;

            trigger OnPreDataItem()
            begin
                ProdOrderRtngLineFilter := GetFilters();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Capacity Task List';
        AboutText = 'Analyze the capacity of work centers or machine centers.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    Visible = false;
                    // Used to set the date filter on the report header across multiple languages
                    field(RequestDateFilter; DateFilter)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Date Filter';
                        ToolTip = 'Specifies the Date Filter applied to the Capacity Task List Report';
                        Visible = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnClosePage()
        begin
            DateFilter := "Prod. Order Routing Line Group".GetFilter("Starting Date");
        end;
    }

    rendering
    {
        layout(WordLayout)
        {
            Type = Word;
            LayoutFile = './Manufacturing/Reports/CapacityTaskList.docx';
        }
        layout(ExcelLayout)
        {
            Type = Excel;
            LayoutFile = './Manufacturing/Reports/CapacityTaskList.xlsx';
        }
#if not CLEAN27
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './Manufacturing/Reports/CapacityTaskList.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel layout and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        CapacityTaskListLabel = 'Capacity Task List';
        CapacityTaskListPrint = 'Capacity Task List (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        CapacityTaskListAnalysis = 'Capacity Task List (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DateFilterLabel = 'Starting Date:';
        StartingDateTimeLabel = 'Starting Date-Time';
        StartingTimeLabel = 'Starting Time';
        StartingDateLabel = 'Starting Date';
        EndingDateTimeLabel = 'Ending Date-Time';
        EndingTimeLabel = 'Ending Time';
        EndingDateLabel = 'Ending Date';
        CapacityNameLabel = 'Capacity Name';
        ItemDescriptionLabel = 'Item Description';
        ExpectedCapacityNeedLabel = 'Expected Capacity Need';
        UnitofMeasureCodeLabel = 'Unit of Measure Code';
        DataRetrieved = 'Data retrieved:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
    }

    var
        ProdOrderRtngLineFilter: Text;
        DateFilter: Text;
        CapacityName: Text[100];
        UnitOfMeasureCode: Code[10];
        FoundWorkCenter: List of [Code[20]];
        FoundMachineCenter: List of [Code[20]];
        CapacityTaskListCaptLbl: Label 'Capacity Task List';
        CurrReportPageNoCaptLbl: Label 'Page';
        ProdOrderRtngLnStrtDtCaptLbl: Label 'Starting Date';
        ProdOrderRtngLnEndDtCaptLbl: Label 'Ending Date';
        ProdOrderRtngLnStrtTimeCaptLbl: Label 'Starting Time';
        ProdOrderRtngLnEndTimeCaptLbl: Label 'Ending Time';

    local procedure CalcExpectedCapacityNeed(): Decimal
    var
        WorkCenter: Record "Work Center";
        CalendarMgt: Codeunit "Shop Calendar Management";
    begin
        if "Prod. Order Routing Line"."Work Center No." = '' then
            exit(1);
        WorkCenter.Get("Prod. Order Routing Line"."Work Center No.");
        exit(CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"));
    end;
}