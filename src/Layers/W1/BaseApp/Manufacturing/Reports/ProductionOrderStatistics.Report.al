// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Costing;
using Microsoft.Manufacturing.Document;
using System.Utilities;

report 99000791 "Production Order Statistics"
{
    AdditionalSearchTerms = 'material cost,capacity cost,material overhead';
    ApplicationArea = Manufacturing;
    Caption = 'Production Order Statistics';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = ProdOrderStatisticsWord;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            RequestFilterFields = Status, "No.", "Date Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ProdOrderTableCaptionFilt; StrSubstNo('%1: %2', TableCaption(), ProdOrderFilter))
            {
            }
            column(ProdOrderFilter; ProdOrderFilter)
            {
            }
            column(No_ProdOrder; "No.")
            {
                IncludeCaption = true;
            }
            column(Desc_ProdOrder; Description)
            {
                IncludeCaption = true;
            }
            column(Quantity_ProdOrder; Quantity)
            {
                DecimalPlaces = 0 : 5;
                IncludeCaption = true;
            }
            column(ExpCost2; ExpCost[2])
            {
                AutoFormatType = 1;
            }
            column(ExpCost1; ExpCost[1])
            {
                AutoFormatType = 1;
            }
            column(ExpCost6; ExpCost[6])
            {
                AutoFormatType = 1;
            }
            column(ExpCost3; ExpCost[3])
            {
                AutoFormatType = 1;
            }
            column(ExpCost4; ExpCost[4])
            {
                AutoFormatType = 1;
            }
            column(ExpCost5; ExpCost[5])
            {
                AutoFormatType = 1;
            }
            column(ActCost1; ActCost[1])
            {
                AutoFormatType = 1;
            }
            column(ActCost2; ActCost[2])
            {
                AutoFormatType = 1;
            }
            column(ActCost3; ActCost[3])
            {
                AutoFormatType = 1;
            }
            column(ActCost4; ActCost[4])
            {
                AutoFormatType = 1;
            }
            column(ActCost5; ActCost[5])
            {
                AutoFormatType = 1;
            }
            column(ActCost6; ActCost[6])
            {
                AutoFormatType = 1;
            }
            column(VarPct1; VarPct[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPct2; VarPct[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPct3; VarPct[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPct4; VarPct[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPct5; VarPct[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPct6; VarPct[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Status_ProdOrder; Status)
            {
                IncludeCaption = true;
            }
            // RDLC Only
            column(ProdOrderStatisticsCapt; ProdOrderStatisticsCaptLbl)
            {
            }
            // RDLC Only
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            // RDLC Only
            column(CapacityCostCaption; CapacityCostCaptionLbl)
            {
            }
            // RDLC Only
            column(MaterialCostCaption; MaterialCostCaptionLbl)
            {
            }
            // RDLC Only
            column(TotalCostCaption; TotalCostCaptionLbl)
            {
            }
            // RDLC Only
            column(SubcontractedCostCaption; SubcontractedCostCaptionLbl)
            {
            }
            // RDLC Only
            column(CapOverheadCostCaption; CapOverheadCostCaptionLbl)
            {
            }
            // RDLC Only
            column(MatOverheadCostCaption; MatOverheadCostCaptionLbl)
            {
            }
            // RDLC Only
            column(ExpectedCaption; ExpectedCaptionLbl)
            {
            }
            // RDLC Only
            column(ActualCaption; ActualCaptionLbl)
            {
            }
            // RDLC Only
            column(DeviationCaption; DeviationCaptionLbl)
            {
            }
            // RDLC Only
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                ProdOrderLine: Record "Prod. Order Line";
            begin
                Clear(StdCost);
                Clear(ExpCost);
                Clear(ActCost);
                Clear(MfgCostCalcMgt);

                GLSetup.Get();

                ProdOrderLine.SetRange(Status, Status);
                ProdOrderLine.SetRange("Prod. Order No.", "No.");
                ProdOrderLine.SetRange("Planning Level Code", 0);
                if ProdOrderLine.FindSet() then
                    repeat
                        MfgCostCalcMgt.CalcShareOfTotalCapCost(ProdOrderLine, ShareOfTotalCapCost);
                        MfgCostCalcMgt.CalcProdOrderLineStdCost(
                          ProdOrderLine, 1, GLSetup."Amount Rounding Precision",
                          StdCost[1], StdCost[2], StdCost[3], StdCost[4], StdCost[5]);
                        MfgCostCalcMgt.CalcProdOrderLineExpCost(
                          ProdOrderLine, ShareOfTotalCapCost,
                          ExpCost[1], ExpCost[2], ExpCost[3], ExpCost[4], ExpCost[5]);
                        MfgCostCalcMgt.CalcProdOrderLineActCost(
                          ProdOrderLine,
                          ActCost[1], ActCost[2], ActCost[3], ActCost[4], ActCost[5],
                          DummyVar, DummyVar, DummyVar, DummyVar, DummyVar);
                    until ProdOrderLine.Next() = 0;

                CalcTotal(StdCost, StdCost[6]);
                CalcTotal(ExpCost, ExpCost[6]);
                CalcTotal(ActCost, ActCost[6]);
                CalcVariance();

                CalcCostTotal(ExpCost, ExpCostTotal);
                CalcCostTotal(ActCost, ActCostTotal);
                CalcVarianceTotal();
            end;

            trigger OnPreDataItem()
            begin
                Clear(ExpCost);
                Clear(ActCost);

                Clear(ExpCostTotal);
                Clear(ActCostTotal);
            end;
        }
        dataitem(Totals; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(ExpCostTotal1; ExpCostTotal[1])
            {
                AutoFormatType = 1;
            }
            column(ExpCostTotal2; ExpCostTotal[2])
            {
                AutoFormatType = 1;
            }
            column(ExpCostTotal3; ExpCostTotal[3])
            {
                AutoFormatType = 1;
            }
            column(ExpCostTotal4; ExpCostTotal[4])
            {
                AutoFormatType = 1;
            }
            column(ExpCostTotal5; ExpCostTotal[5])
            {
                AutoFormatType = 1;
            }
            column(ExpCostTotal6; ExpCostTotal[6])
            {
                AutoFormatType = 1;
            }
            column(ActCostTotal1; ActCostTotal[1])
            {
                AutoFormatType = 1;
            }
            column(ActCostTotal2; ActCostTotal[2])
            {
                AutoFormatType = 1;
            }
            column(ActCostTotal3; ActCostTotal[3])
            {
                AutoFormatType = 1;
            }
            column(ActCostTotal4; ActCostTotal[4])
            {
                AutoFormatType = 1;
            }
            column(ActCostTotal5; ActCostTotal[5])
            {
                AutoFormatType = 1;
            }
            column(ActCostTotal6; ActCostTotal[6])
            {
                AutoFormatType = 1;
            }
            column(VarPctTotal1; VarPctTotal[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPctTotal2; VarPctTotal[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPctTotal3; VarPctTotal[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPctTotal4; VarPctTotal[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPctTotal5; VarPctTotal[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(VarPctTotal6; VarPctTotal[6])
            {
                DecimalPlaces = 0 : 5;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Production Order Statistics';
        AboutText = 'Analyse your actual costs and variance from expected cost for production orders to make key decisions about your production execution and its impact on costs. Displays a breakdown of all cost categories for a production order including material, capacity, subcontracting, and overheads.';

        layout
        {
        }

        actions
        {
        }
    }
    rendering
    {
        layout(ProdOrderStatisticsExcel)
        {
            Caption = 'Production Order Statistics Excel';
            LayoutFile = '.\Manufacturing\Reports\ProdOrderStatisticsExcel.xlsx';
            Type = Excel;
            Summary = 'Built in layout for the Production Order Statistics excel report.';
        }
        layout(ProdOrderStatisticsWord)
        {
            Caption = 'Production Order Statistics Word';
            LayoutFile = '.\Manufacturing\Reports\ProdOrderStatisticsWord.docx';
            Type = Word;
        }
#if not CLEAN27
        layout(ProdOrderStatisticsRDLC)
        {
            Caption = 'Production Order Statistics RDLC';
            LayoutFile = '.\Manufacturing\Reports\ProductionOrderStatistics.rdlc';
            Type = RDLC;
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel layout and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }
    labels
    {
        DataRetrieved = 'Data retrieved:';
        ProdOrderStatistics = 'Production Order Statistics';
        ProdOrderStatsPrint = 'Prod. Order Stats (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ProdOrderStatsAnalysis = 'Prod. Order Stats (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        PostingDateFilterLabel = 'Posting Date Filter:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
        // End of About the report labels
        ExpCost1Label = 'Material Cost (Expected)';
        ExpCost2Label = 'Capacity Cost (Expected)';
        ExpCost3Label = 'Subcontracted Cost (Expected)';
        ExpCost4Label = 'Capacity Overhead Cost (Expected)';
        ExpCost5Label = 'Material Overhead Cost (Expected)';
        ExpCost6Label = 'Total Cost (Expected)';
        ActCost1Label = 'Material Cost (Actual)';
        ActCost2Label = 'Capacity Cost (Actual)';
        ActCost3Label = 'Subcontracted Cost (Actual)';
        ActCost4Label = 'Capacity Overhead Cost (Actual)';
        ActCost5Label = 'Material Overhead Cost (Actual)';
        ActCost6Label = 'Total Cost (Actual)';
        VarPct1Label = 'Material Cost (Deviation %)';
        VarPct2Label = 'Capacity Cost (Deviation %)';
        VarPct3Label = 'Subcontracted Cost (Deviation %)';
        VarPct4Label = 'Capacity Overhead Cost (Deviation %)';
        VarPct5Label = 'Material Overhead Cost (Deviation %)';
        VarPct6Label = 'Total Cost (Deviation %)';
    }

    trigger OnPreReport()
    begin
        ProdOrderFilter := "Production Order".GetFilters();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        ProdOrderFilter: Text;
        ShareOfTotalCapCost: Decimal;
        ExpCost: array[6] of Decimal;
        ActCost: array[6] of Decimal;
        StdCost: array[6] of Decimal;
        VarPct: array[6] of Decimal;
        ExpCostTotal: array[6] of Decimal;
        ActCostTotal: array[6] of Decimal;
        VarPctTotal: array[6] of Decimal;
        DummyVar: Decimal;
        // RDLC Only layout field captions. To be removed in a future release along with the RDLC layout.
        ProdOrderStatisticsCaptLbl: Label 'Production Order Statistics';
        CurrReportPageNoCaptionLbl: Label 'Page';
        CapacityCostCaptionLbl: Label 'Capacity Cost';
        MaterialCostCaptionLbl: Label 'Material Cost';
        TotalCostCaptionLbl: Label 'Total Cost';
        SubcontractedCostCaptionLbl: Label 'Subcontracted Cost';
        CapOverheadCostCaptionLbl: Label 'Capacity Overhead Cost';
        MatOverheadCostCaptionLbl: Label 'Material Overhead Cost';
        ExpectedCaptionLbl: Label 'Expected';
        ActualCaptionLbl: Label 'Actual';
        DeviationCaptionLbl: Label 'Deviation %';
        TotalCaptionLbl: Label 'Total';

    local procedure CalcTotal(Operand: array[6] of Decimal; var Total: Decimal)
    var
        i: Integer;
    begin
        Total := 0;

        for i := 1 to ArrayLen(Operand) - 1 do
            Total := Total + Operand[i];
    end;

    local procedure CalcVariance()
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VarPct) do
            VarPct[i] := CalcIndicatorPct(ExpCost[i], ActCost[i]);
    end;

    local procedure CalcIndicatorPct(Value: Decimal; "Sum": Decimal): Decimal
    begin
        if Value = 0 then
            exit(0);

        exit(Round((Sum - Value) / Value * 100, 1));
    end;

    local procedure CalcCostTotal(Operand: array[6] of Decimal; var TotalOperand: array[6] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(Operand) do
            TotalOperand[i] += Operand[i];
    end;

    local procedure CalcVarianceTotal()
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VarPctTotal) do
            VarPctTotal[i] := CalcIndicatorPct(ExpCostTotal[i], ActCostTotal[i]);
    end;
}

