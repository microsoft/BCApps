// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Item;
using System.Utilities;

report 5871 "Item - Able to Make (Timeline)"
{
    DefaultRenderingLayout = ExcelLayout;
    AdditionalSearchTerms = 'assembly availability';
    ApplicationArea = Planning;
    Caption = 'Item - Able to Make (Timeline)';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Location Filter", "Variant Filter";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Item__No__; "No.")
            {
                IncludeCaption = true;
            }
            column(Item_Description; Description)
            {
                IncludeCaption = true;
            }
            dataitem(BOMBufferLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(TotalQty; TotalQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GrossReqQty; GrossReqQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(SchRcptQty; SchRcptQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(InvtQty; InvtQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(AbleToMakeQty; AbleToMakeQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(AsOfPeriod; Format(AsOfPeriod))
                {
                }
                column(ShowDetails; ShowDetails)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number <> 1 then begin
                        CurrDate := CalcDate(DateFormula, CurrDate);
                        GenerateAvailTrend(CurrDate);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, NoOfIntervals);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrDate := StartDate;
                if not GenerateAvailTrend(CurrDate) then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                Evaluate(DateFormula, GetDateFormulaInterval());
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Item - Able to Make (Timeline)';
        AboutText = 'Provides an overview on the dynamic BOM availability. Visualise key inventory figures and forecast production capabilities to meet demand efficiently. Stay ahead with real-time insights into your assembly and production schedules.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date on the X-axis.';
                    }
                    field(DateInterval; DateInterval)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Date Interval';
                        ToolTip = 'Specifies the length of each period on the x-axis. You can select from Day, Week, Month, Quarter, or Year.';
                    }
                    field(NoOfIntervals; NoOfIntervals)
                    {
                        ApplicationArea = Planning;
                        Caption = 'No. of Intervals';
                        MaxValue = 31;
                        MinValue = 1;
                        ToolTip = 'Specifies how many date intervals are shown on the x-axis.';

                        trigger OnValidate()
                        begin
                            if NoOfIntervals > 31 then
                                Error(Text000)
                        end;
                    }
                    field(ShowDetails; ShowDetails)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Show Details';
                        ToolTip = 'Specifies a table under the graph with the quantities that the lines in the graph are based on.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            if NoOfIntervals = 0 then
                NoOfIntervals := 7;
        end;
    }

    rendering
    {
        layout(ExcelLayout)
        {
            Caption = 'Item - Able to Make (Timeline) Excel';
            Type = Excel;
            LayoutFile = './Inventory/Reports/ItemAbletoMakeTimeline.xlsx';
        }
        layout(RDLCLayout)
        {
            Caption = 'Item - Able to Make (Timeline) RDLC';
            Type = RDLC;
            LayoutFile = './Inventory/Reports/ItemAbletoMakeTimeline.rdlc';
        }
    }

    labels
    {
        ItemAbleToMakeProjectionCaption = 'Item - Able to Make (Timeline)';
        AsOfPeriodCaption = 'As of Period';
        CurrReport_PAGENOCaption = 'Page';
        TotalQtyCaption = 'Total';
        GrossReqQtyCaption = 'Gross Requirement';
        SchRcptQtyCaption = 'Scheduled Receipts';
        InvtQtyCaption = 'Inventory';
        AbleToMakeQtyCaption = 'Able to Make';
        StartDateCaption = 'Starting Date:';
        ItemAbleToMakePrintLabel = 'Item Able to Make - (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ItemAbleToMakeAnalysisLabel = 'Item Able to Make - (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrieved = 'Data retrieved:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
    }

    trigger OnInitReport()
    begin
        StartDate := WorkDate();
    end;

    var
        TempBOMBuffer: Record "BOM Buffer" temporary;
        CalcBOMTree: Codeunit "Calculate BOM Tree";
        SourceRecordVar: Variant;
        DateFormula: DateFormula;
        DateInterval: Option Day,Week,Month,Quarter,Year;
        NoOfIntervals: Integer;
        StartDate: Date;
        AbleToMakeQty: Decimal;
        InvtQty: Decimal;
        SchRcptQty: Decimal;
        GrossReqQty: Decimal;
        TotalQty: Decimal;
        AsOfPeriod: Date;
        CurrDate: Date;
        ShowDetails: Boolean;
        ShowBy: Enum "BOM Structure Show By";

#pragma warning disable AA0074
        Text000: Label 'The number of intervals cannot be greater than 31.';
#pragma warning restore AA0074

    local procedure GenerateAvailTrend(CurrDate: Date): Boolean
    var
        IsHandled: Boolean;
    begin
        CalcBOMTree.SetShowTotalAvailability(true);
        case ShowBy of
            ShowBy::Item:
                begin
                    IsHandled := false;
                    OnGenerateAvailTrendOnBeforeGenerateTreeForItem(Item, TempBOMBuffer, CurrDate, IsHandled);
                    if not IsHandled then
                        CalcBOMTree.GenerateTreeForOneItem(Item, TempBOMBuffer, CurrDate, "BOM Tree Type"::Availability);
                end;
            else
                CalcBOMTree.GenerateTreeForSource(SourceRecordVar, TempBOMBuffer, "BOM Tree Type"::Availability, ShowBy, CurrDate);
        end;

        if not TempBOMBuffer.FindFirst() then
            exit(false);
        AbleToMakeQty := TempBOMBuffer."Able to Make Top Item";
        TotalQty := TempBOMBuffer."Able to Make Top Item" + TempBOMBuffer."Available Quantity";
        CalcQuantities(Item, InvtQty, SchRcptQty, GrossReqQty, CurrDate);
        AsOfPeriod := CurrDate;
        exit(true);
    end;

    local procedure GetDateFormulaInterval(): Text[10]
    begin
        case DateInterval of
            DateInterval::Day:
                exit('<+1D>');
            DateInterval::Week:
                exit('<CW+1D>');
            DateInterval::Month:
                exit('<CM+1D>');
            DateInterval::Quarter:
                exit('<CQ+1D>');
            DateInterval::Year:
                exit('<CY+1D>');
        end;
    end;

    procedure Initialize(NewStartingDate: Date; NewDateInterval: Option; NewNoOfIntervals: Integer; NewShowDetails: Boolean)
    begin
        StartDate := NewStartingDate;
        DateInterval := NewDateInterval;
        NoOfIntervals := NewNoOfIntervals;
        ShowDetails := NewShowDetails;
    end;

    procedure InitSource(NewSourceRecordVar: Variant; NewShowBy: Enum "BOM Structure Show By")
    begin
        SourceRecordVar := NewSourceRecordVar;
        ShowBy := NewShowBy;
    end;

#if not CLEAN27
    [Obsolete('Replaced by procedure InitSource()', '27.0')]
    procedure InitAsmOrder(NewAsmHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
        SourceRecordVar := NewAsmHeader;
        ShowBy := ShowBy::Assembly;
    end;
#endif

#if not CLEAN27
    [Obsolete('Replaced by procedure InitSource()', '27.0')]
    procedure InitProdOrder(NewProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        SourceRecordVar := NewProdOrderLine;
        ShowBy := ShowBy::Production;
    end;
#endif

    local procedure CalcQuantities(var Item: Record Item; var InvtQty: Decimal; var SchRcptQty: Decimal; var GrossReqQty: Decimal; Date: Date)
    var
        Item2: Record Item;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        PlannedOrderReceipt: Decimal;
        PlannedOrderReleases: Decimal;
    begin
        Item2.Copy(Item);

        Item2.CalcFields(Inventory);
        InvtQty := Item2.Inventory;

        Item2.SetRange("Date Filter", 0D, Date);
        ItemAvailFormsMgt.CalculateNeed(Item2, GrossReqQty, PlannedOrderReceipt, SchRcptQty, PlannedOrderReleases);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateAvailTrendOnBeforeGenerateTreeForItem(var Item: Record "Item"; var BOMBuffer: Record "BOM Buffer" temporary; CurrDate: Date; var IsHandled: Boolean)
    begin
    end;
}