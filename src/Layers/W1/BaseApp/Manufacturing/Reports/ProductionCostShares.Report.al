// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Item;

report 99000793 "Production Cost Shares"
{
    ApplicationArea = Manufacturing;
    Caption = 'Production Cost Shares';
    AdditionalSearchTerms = 'bom cost share distribution,cost breakdown,rolled-up cost,detailed calculation,quantity explosion of bom';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = ProductionCostSharesExcel;

    dataset
    {
        dataitem(BOMBuffer; "BOM Buffer")
        {
            DataItemTableView = sorting("Entry No.");
            UseTemporary = true;

            column(EntryNo; "Entry No.")
            {
                IncludeCaption = true;
            }
            column(Type; Type)
            {
                IncludeCaption = true;
            }
            column(No; "No.")
            {
                IncludeCaption = true;
            }
            column(Description; Description)
            {
                IncludeCaption = true;
            }
            column(Level; PadStr('', Indentation, ' ') + Format(Indentation))
            {
            }
            column(HasWarning; BOMBufferHasWarning)
            {
            }
            column(VariantCode; "Variant Code")
            {
                IncludeCaption = true;
            }
            column(QtyPerParent; "Qty. per Parent")
            {
                IncludeCaption = true;
            }
            column(QtyPerTopItem; "Qty. per Top Item")
            {
                IncludeCaption = true;
            }
            column(QtyPerBOMLine; "Qty. per BOM Line")
            {
                IncludeCaption = true;
            }
            column(UnitOfMeasureCode; "Unit of Measure Code")
            {
                IncludeCaption = true;
            }
            column(BOMUnitOfMeasureCode; "BOM Unit of Measure Code")
            {
                IncludeCaption = true;
            }
            column(ReplenishmentSystem; "Replenishment System")
            {
                IncludeCaption = true;
            }
            column(UnitCost; "Unit Cost")
            {
                IncludeCaption = true;
            }
            column(ScrapPercentage; "Scrap %")
            {
                IncludeCaption = true;
            }
            column(ScrapQtyPerParent; "Scrap Qty. per Parent")
            {
                IncludeCaption = true;
            }
            column(ScrapQtyPerTopItem; "Scrap Qty. per Top Item")
            {
                IncludeCaption = true;
            }
            column(IndirectCostPercentage; "Indirect Cost %")
            {
                IncludeCaption = true;
            }
            column(OverheadRate; "Overhead Rate")
            {
                IncludeCaption = true;
            }
            column(LotSize; "Lot Size")
            {
                IncludeCaption = true;
            }
            column(ProductionBOMNo; "Production BOM No.")
            {
                IncludeCaption = true;
            }
            column(RoutingNo; "Routing No.")
            {
                IncludeCaption = true;
            }
            column(ResourceUsageType; "Resource Usage Type")
            {
                IncludeCaption = true;
            }
            column(RolledUpMaterialCost; "Rolled-up Material Cost")
            {
                IncludeCaption = true;
            }
            column(RolledUpMatNonInvtCost; "Rolled-up Mat. Non-Invt. Cost")
            {
                IncludeCaption = true;
            }
            column(RolledUpCapacityCost; "Rolled-up Capacity Cost")
            {
                IncludeCaption = true;
            }
            column(RolledUpSubcontractedCost; "Rolled-up Subcontracted Cost")
            {
                IncludeCaption = true;
            }
            column(RolledUpMfgOvhdCost; "Rolled-up Mfg. Ovhd Cost")
            {
                IncludeCaption = true;
            }
            column(RolledUpCapacityOvhdCost; "Rolled-up Capacity Ovhd. Cost")
            {
                IncludeCaption = true;
            }
            column(RolledUpScrapCost; "Rolled-up Scrap Cost")
            {
                IncludeCaption = true;
            }
            column(SingleLevelMaterialCost; "Single-Level Material Cost")
            {
                IncludeCaption = true;
            }
            column(SingleLvlMatNonInvtCost; "Single-Lvl Mat. Non-Invt. Cost")
            {
                IncludeCaption = true;
            }
            column(SingleLevelCapacityCost; "Single-Level Capacity Cost")
            {
                IncludeCaption = true;
            }
            column(SingleLevelSubcontrdCost; "Single-Level Subcontrd. Cost")
            {
                IncludeCaption = true;
            }
            column(SingleLevelCapOvhdCost; "Single-Level Cap. Ovhd Cost")
            {
                IncludeCaption = true;
            }
            column(SingleLevelMfgOvhdCost; "Single-Level Mfg. Ovhd Cost")
            {
                IncludeCaption = true;
            }
            column(SingleLevelScrapCost; "Single-Level Scrap Cost")
            {
                IncludeCaption = true;
            }
            column(TotalCost; "Total Cost")
            {
                IncludeCaption = true;
            }
            column(IsLeaf; "Is Leaf")
            {
                IncludeCaption = true;
            }
            column(LastUnitCostCalcDate; "Last Unit Cost Calc. Date")
            {
                IncludeCaption = true;
            }

            trigger OnAfterGetRecord()
            var
                DummyBOMWarningLog: Record "BOM Warning Log";
            begin
                BOMBufferHasWarning := not BOMBuffer.IsLineOk(false, DummyBOMWarningLog);
            end;
        }
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.";
        }
    }
    requestpage
    {
        AboutTitle = 'About Production Cost Shares';
        AboutText = 'This report contains data on how the costs of underlying items in the BOM roll up to the parent item. The information is organized according to the BOM structure to reflect at which levels the individual costs apply. Varying item levels are shown across several worksheets to obtain an overview or detailed view.';
        SaveValues = true;
    }
    rendering
    {
        layout(ProductionCostSharesExcel)
        {
            Caption = 'Production Cost Shares Excel';
            LayoutFile = './Manufacturing/Reports/ProductionCostShares.xlsx';
            Type = Excel;
        }
    }
    labels
    {
        ProductionCostShares = 'Production Cost Shares';
        // Print worksheet headings
        SingleLevelCostShares = 'Single-Level Cost Shares';
        SingleLevelCostSharesTopLevel = 'Single-Level Cost Shares - Top Level';
        SingleLevelCostSharesExploded = 'Single-Level Cost Shares - Exploded';
        RolledUpCostShares = 'Rolled-up Cost Shares';
        RolledUpCostSharesTopLevel = 'Rolled-up Cost Shares - Top Level';
        RolledUpCostSharesExploded = 'Rolled-up Cost Shares - Exploded';
        // Print worksheet names
        SingleLevelPrint = 'Single-Level (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        SingleLevelTopLevelPrint = 'Single-Level Top Level (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        SingleLevelExplodedPrint = 'Single-Level Exploded (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        RolledUpPrint = 'Rolled-up (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        RolledUpTopLevelPrint = 'Rolled-up Top Level (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        RolledUpExplodedPrint = 'Rolled-up Exploded (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        // Analysis worksheet name
        ProdCostSharesAnalysis = 'Prod. Cost Shares (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        LevelLabel = 'Level';
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
        BOMBufferHasWarning: Boolean;
        NoBOMItemsLbl: Label 'None of the items in the filter have a BOM.';

    trigger OnPreReport()
    begin
        BuildDataSet();
    end;

    local procedure BuildDataSet()
    var
        CalcBOMTree: Codeunit "Calculate BOM Tree";
        HasBOM: Boolean;
    begin
        if Item."Date Filter" = 0D then
            Item.SetRange("Date Filter", 0D, WorkDate());

        CalcBOMTree.SetItemFilter(Item);

        Item.FindSet();
        repeat
            HasBOM := Item.HasBOM() or (Item."Routing No." <> '')
        until HasBOM or (Item.Next() = 0);

        if not HasBOM then
            Error(NoBOMItemsLbl);

        CalcBOMTree.GenerateTreeForManyItems(Item, BOMBuffer, "BOM Tree Type"::Cost);
    end;
}