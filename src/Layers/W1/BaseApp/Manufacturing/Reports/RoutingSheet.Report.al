// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using System.Utilities;

report 99000787 "Routing Sheet"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/RoutingSheet.rdlc';
    AdditionalSearchTerms = 'operations sheet,process structure sheet';
    ApplicationArea = Manufacturing;
    Caption = 'Routing Sheet';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(No_Item; "No.")
            {
            }
            column(PrintComment; PrintComment)
            {
            }
            column(PrintTool; PrintTool)
            {
            }
            column(PrintPersonnel; PrintPersonnel)
            {
            }
            column(PrintQualityMeasures; PrintQualityMeasures)
            {
            }
            dataitem(Counter1; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(Counter2; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    PrintOnlyIfDetail = true;
                    column(CompanyName; COMPANYPROPERTY.DisplayName())
                    {
                    }
                    column(TodayFormatted; Format(Today))
                    {
                    }
                    column(CopyNo1; CopyNo - 1)
                    {
                    }
                    column(CopyText; CopyText)
                    {
                    }
                    column(No01_Item; Item."No.")
                    {
                    }
                    column(Desc_Item; Item.Description)
                    {
                    }
                    column(ProductionQuantity; ProductionQuantity)
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(RtngNo_Item; Item."Routing No.")
                    {
                    }
                    column(ActiveVersionCode; ActiveVersionCode)
                    {
                    }
                    column(ActiveVersionText; ActiveVersionText)
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                    {
                    }
                    column(RoutingSheetCaption; RoutingSheetCaptionLbl)
                    {
                    }
                    column(ProductionQuantityCaption; ProductionQuantityCaptionLbl)
                    {
                    }
                    column(ItemRtngNoCaption; ItemRtngNoCaptionLbl)
                    {
                    }
                    dataitem("Routing Header"; "Routing Header")
                    {
                        DataItemTableView = sorting("No.");
                        PrintOnlyIfDetail = true;
                        dataitem("Routing Line"; "Routing Line")
                        {
                            DataItemLink = "Routing No." = field("No.");
                            DataItemTableView = sorting("Routing No.", "Version Code", "Operation No.");
                            column(OperationNo_RtngLine; "Operation No.")
                            {
                                IncludeCaption = true;
                            }
                            column(Type_RtngLine; Type)
                            {
                                IncludeCaption = true;
                            }
                            column(No_RtngLine; "No.")
                            {
                                IncludeCaption = true;
                            }
                            column(SendAheadQty_RtngLine; "Send-Ahead Quantity")
                            {
                                IncludeCaption = true;
                            }
                            column(SetupTime_RtngLine; "Setup Time")
                            {
                                IncludeCaption = true;
                            }
                            column(RunTime_RtngLine; "Run Time")
                            {
                                IncludeCaption = true;
                            }
                            column(MoveTime_RtngLine; "Move Time")
                            {
                                IncludeCaption = true;
                            }
                            column(TotalTime; TotalTime)
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(RunTimeUOMCode_RtngLine; "Run Time Unit of Meas. Code")
                            {
                            }
                            column(ScrapFactor_RtngLine; "Scrap Factor %")
                            {
                                IncludeCaption = true;
                            }
                            column(WaitTime_RtngLine; "Wait Time")
                            {
                                IncludeCaption = true;
                            }
                            column(TotalTimeCaption; TotalTimeCaptionLbl)
                            {
                            }
                            column(RtngLnRunTimeUOMCodeCptn; RtngLnRunTimeUOMCodeCptnLbl)
                            {
                            }
                            dataitem("Routing Comment Line"; "Routing Comment Line")
                            {
                                DataItemLink = "Routing No." = field("Routing No."), "Version Code" = field("Version Code"), "Operation No." = field("Operation No.");
                                DataItemTableView = sorting("Routing No.", "Version Code", "Operation No.", "Line No.");
                                column(LineComment_RtngComment; Comment)
                                {
                                }

                                trigger OnPreDataItem()
                                begin
                                    SetRange("Routing No.", Item."Routing No.");

                                    if not PrintComment then
                                        CurrReport.Break();
                                end;
                            }
                            dataitem("Routing Tool"; "Routing Tool")
                            {
                                DataItemLink = "Routing No." = field("Routing No."), "Version Code" = field("Version Code"), "Operation No." = field("Operation No.");
                                DataItemTableView = sorting("Routing No.", "Version Code", "Operation No.", "Line No.");
                                column(Desc_RtngTool; Description)
                                {
                                }
                                column(No_RtngTool; "No.")
                                {
                                }

                                trigger OnPreDataItem()
                                begin
                                    if not PrintTool then
                                        CurrReport.Break();
                                end;
                            }
                            dataitem("Routing Personnel"; "Routing Personnel")
                            {
                                DataItemLink = "Routing No." = field("Routing No."), "Version Code" = field("Version Code"), "Operation No." = field("Operation No.");
                                DataItemTableView = sorting("Routing No.", "Version Code", "Operation No.", "Line No.");
                                column(Desc_RtngPersonnel; Description)
                                {
                                }
                                column(No_RtngPersonnel; "No.")
                                {
                                }

                                trigger OnPreDataItem()
                                begin
                                    if not PrintPersonnel then
                                        CurrReport.Break();
                                end;
                            }
                            dataitem("Routing Quality Measure"; "Routing Quality Measure")
                            {
                                DataItemLink = "Routing No." = field("Routing No."), "Version Code" = field("Version Code"), "Operation No." = field("Operation No.");
                                DataItemTableView = sorting("Routing No.", "Version Code", "Operation No.", "Line No.");
                                column(Desc_RtngQualityMeasure; Description)
                                {
                                }
                                column(QMCode_RtngQltyMeasure; "Qlty Measure Code")
                                {
                                }

                                trigger OnPreDataItem()
                                begin
                                    if not PrintQualityMeasures then
                                        CurrReport.Break();
                                end;
                            }

                            trigger OnAfterGetRecord()
                            var
                                RunTimeFactor: Decimal;
                            begin
                                RunTimeFactor := CalendarMgt.TimeFactor("Run Time Unit of Meas. Code");
                                TotalTime :=
                                  Round(
                                    "Setup Time" * CalendarMgt.TimeFactor("Setup Time Unit of Meas. Code") / RunTimeFactor +
                                    "Wait Time" * CalendarMgt.TimeFactor("Wait Time Unit of Meas. Code") / RunTimeFactor +
                                    "Move Time" * CalendarMgt.TimeFactor("Move Time Unit of Meas. Code") / RunTimeFactor +
                                    ProductionQuantity * "Run Time", UOMMgt.TimeRndPrecision());
                            end;

                            trigger OnPreDataItem()
                            begin
                                if ActiveVersionCode <> '' then
                                    SetFilter("Version Code", ActiveVersionCode)
                                else
                                    SetFilter("Version Code", '%1', '');
                            end;
                        }

                        trigger OnPreDataItem()
                        begin
                            SetRange("No.", Item."Routing No.");
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if CopyNo = LoopNo then
                        CurrReport.Break();

                    CopyNo := CopyNo + 1;

                    if CopyNo = 1 then
                        Clear(CopyText)
                    else begin
                        CopyText := Text000;
                        OutputNo += 1;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if NumberOfCopies = 0 then
                        LoopNo := 1
                    else
                        LoopNo := 1 + NumberOfCopies;
                    CopyNo := 0;
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Routing No." = '' then
                    CurrReport.Skip();

                ActiveVersionCode :=
                  VersionMgt.GetRtngVersion("Routing No.", WorkDate(), true);

                if ActiveVersionCode <> '' then
                    ActiveVersionText := Text001
                else
                    ActiveVersionText := '';
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Routing Sheet';
        AboutText = 'Get an overview of the operations to do to build an item, including information about the work center, machine center, personnel, and tools involved.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ProductionQuantity; ProductionQuantity)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Production Quantity';
                        DecimalPlaces = 0 : 5;
                        MinValue = 0;
                        ToolTip = 'Specifies the quantity of items to manufacture for which you want the program to calculate the total time of the routing.';
                    }
                    field(PrintComment; PrintComment)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Comment';
                        ToolTip = 'Specifies whether to include comments that provide additional information about the operation. For example, comments might mention special conditions for completing the operation.';
                    }
                    field(PrintTool; PrintTool)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Tools';
                        ToolTip = 'Specifies whether to include the tools that are required to complete the operation.';
                    }
                    field(PrintPersonnel; PrintPersonnel)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Personnel';
                        ToolTip = 'Specifies whether to include the people to involve in the operation. For example, this is useful if the operation requires special knowledge or training.';
                    }
                    field(PrintQualityMeasures; PrintQualityMeasures)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Quality Measures';
                        ToolTip = 'Specifies whether to include quality measures for the operation. For example, this is useful for quality control purposes.';
                    }
                    field(NumberOfCopies; NumberOfCopies)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'No. of Copies';
                        MinValue = 0;
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ProductionQuantity := 1;
    end;

    var
        VersionMgt: Codeunit VersionManagement;
        CalendarMgt: Codeunit "Shop Calendar Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        NumberOfCopies: Integer;
        CopyNo: Integer;
        CopyText: Text[30];
        ActiveVersionText: Text[30];
        LoopNo: Integer;
        ProductionQuantity: Decimal;
        PrintComment: Boolean;
        PrintTool: Boolean;
        PrintPersonnel: Boolean;
        PrintQualityMeasures: Boolean;
        TotalTime: Decimal;
        ActiveVersionCode: Code[20];

#pragma warning disable AA0074
        Text000: Label 'Copy number:';
        Text001: Label 'Active Version';
#pragma warning restore AA0074
        OutputNo: Integer;
        CurrReportPageNoCaptionLbl: Label 'Page';
        RoutingSheetCaptionLbl: Label 'Routing Sheet';
        ProductionQuantityCaptionLbl: Label 'Production Quantity';
        ItemRtngNoCaptionLbl: Label 'Routing No.';
        TotalTimeCaptionLbl: Label 'Total Time';
        RtngLnRunTimeUOMCodeCptnLbl: Label 'Time Unit';
}

