// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;

report 712 "Inventory - Sales Statistics"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventorySalesStatistics.rdlc';
    ApplicationArea = Suite;
    Caption = 'Inventory Sales Statistics';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("Inventory Posting Group");
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group", "Statistics Group", "Base Unit of Measure", "Date Filter";
            column(PeriodTextCaption; StrSubstNo(PeriodInfoTxt, PeriodText))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintAlsoWithoutSale; PrintAlsoWithoutSaleReq)
            {
            }
            column(ItemFilterCaption; StrSubstNo(TableFiltersTxt, TableCaption(), ItemFilter))
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(InventoryPostingGrp_Item; "Inventory Posting Group")
            {
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(AssemblyBOM_Item; Format("Assembly BOM"))
            {
            }
            column(BaseUnitofMeasure_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(UnitCost; UnitCost)
            {
            }
            column(UnitPrice; UnitPrice)
            {
            }
            column(SalesQty; SalesQty)
            {
            }
            column(SalesAmount; SalesAmount)
            {
            }
            column(ItemProfit; ItemProfit)
            {
                AutoFormatType = 1;
            }
            column(ItemProfitPct; ItemProfitPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(InvSalesStatisticsCapt; InvSalesStatisticsCaptLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(IncludeNotSoldItemsCaption; IncludeNotSoldItemsCaptionLbl)
            {
            }
            column(ItemAssemblyBOMCaption; ItemAssemblyBOMCaptionLbl)
            {
            }
            column(UnitCostCaption; UnitCostCaptionLbl)
            {
            }
            column(UnitPriceCaption; UnitPriceCaptionLbl)
            {
            }
            column(SalesQtyCaption; SalesQtyCaptionLbl)
            {
            }
            column(SalesAmountCaption; SalesAmountCaptionLbl)
            {
            }
            column(ItemProfitCaption; ItemProfitCaptionLbl)
            {
            }
            column(ItemProfitPctCaption; ItemProfitPctCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Assembly BOM");

                SetFilters();
                Calculate();

                if (SalesAmount = 0) and not PrintAlsoWithoutSaleReq then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                Clear(SalesQty);
                Clear(SalesAmount);
                Clear(COGSAmount);
                Clear(ItemProfit);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintAlsoWithoutSale; PrintAlsoWithoutSaleReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Include Items Not Sold';
                        MultiLine = true;
                        ToolTip = 'Specifies if items that have not yet been sold are also included in the report.';
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

    trigger OnPreReport()
    begin
        GeneralLedgerSetup.Get();

        ItemFilter := Item.GetFilters();
        PeriodText := Item.GetFilter("Date Filter");

        if Item.GetFilter("Date Filter") <> '' then
            ItemStatisticsBuffer.SetFilter("Date Filter", PeriodText);
        if Item.GetFilter("Location Filter") <> '' then
            ItemStatisticsBuffer.SetFilter("Location Filter", Item.GetFilter("Location Filter"));
        if Item.GetFilter("Variant Filter") <> '' then
            ItemStatisticsBuffer.SetFilter("Variant Filter", Item.GetFilter("Variant Filter"));
        if Item.GetFilter("Global Dimension 1 Filter") <> '' then
            ItemStatisticsBuffer.SetFilter("Global Dimension 1 Filter", Item.GetFilter("Global Dimension 1 Filter"));
        if Item.GetFilter("Global Dimension 2 Filter") <> '' then
            ItemStatisticsBuffer.SetFilter("Global Dimension 2 Filter", Item.GetFilter("Global Dimension 2 Filter"));

        OnPreReportOnAfterItemStatisticsBufferSetFilters(ItemStatisticsBuffer, Item);
    end;

    var
        ItemStatisticsBuffer: Record "Item Statistics Buffer";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ItemFilter: Text;
        PeriodText: Text;
        SalesQty: Decimal;
        SalesAmount: Decimal;
        COGSAmount: Decimal;
        ItemProfit: Decimal;
        ItemProfitPct: Decimal;
        UnitPrice: Decimal;
        UnitCost: Decimal;
        PrintAlsoWithoutSaleReq: Boolean;

        PeriodInfoTxt: Label 'Period: %1', Comment = '%1 - period name';
        TableFiltersTxt: Label '%1: %2', Locked = true;
        InvSalesStatisticsCaptLbl: Label 'Inventory - Sales Statistics';
        PageCaptionLbl: Label 'Page';
        IncludeNotSoldItemsCaptionLbl: Label 'This report also includes items that are not sold.';
        ItemAssemblyBOMCaptionLbl: Label 'BOM';
        UnitCostCaptionLbl: Label 'Unit Cost';
        UnitPriceCaptionLbl: Label 'Unit Price';
        SalesQtyCaptionLbl: Label 'Sales (Qty.)';
        SalesAmountCaptionLbl: Label 'Sales (LCY)';
        ItemProfitCaptionLbl: Label 'Profit';
        ItemProfitPctCaptionLbl: Label 'Profit %';
        TotalCaptionLbl: Label 'Total';

    local procedure Calculate()
    begin
        SalesQty := -CalcInvoicedQty();
        SalesAmount := CalcSalesAmount();
        COGSAmount := CalcCostAmount() + CalcCostAmountNonInvnt();
        ItemProfit := SalesAmount + COGSAmount;

        OnCalculateOnAfterCalcAmounts(Item, SalesQty, SalesAmount, COGSAmount, ItemProfit);

        if SalesAmount <> 0 then
            ItemProfitPct := Round(100 * ItemProfit / SalesAmount, 0.1)
        else
            ItemProfitPct := 0;

        UnitPrice := CalcPerUnit(SalesAmount, SalesQty);
        UnitCost := -CalcPerUnit(COGSAmount, SalesQty);
    end;

    local procedure SetFilters()
    begin
        ItemStatisticsBuffer.SetRange("Item Filter", Item."No.");
        ItemStatisticsBuffer.SetRange("Item Ledger Entry Type Filter", ItemStatisticsBuffer."Item Ledger Entry Type Filter"::Sale);
        ItemStatisticsBuffer.SetFilter("Entry Type Filter", '<>%1', ItemStatisticsBuffer."Entry Type Filter"::Revaluation);
    end;

    local procedure CalcSalesAmount(): Decimal
    begin
        ItemStatisticsBuffer.CalcFields("Sales Amount (Actual)");
        exit(ItemStatisticsBuffer."Sales Amount (Actual)");
    end;

    local procedure CalcCostAmount(): Decimal
    begin
        ItemStatisticsBuffer.CalcFields("Cost Amount (Actual)");
        exit(ItemStatisticsBuffer."Cost Amount (Actual)");
    end;

    local procedure CalcCostAmountNonInvnt(): Decimal
    begin
        ItemStatisticsBuffer.SetRange("Item Ledger Entry Type Filter");
        ItemStatisticsBuffer.CalcFields("Cost Amount (Non-Invtbl.)");
        exit(ItemStatisticsBuffer."Cost Amount (Non-Invtbl.)");
    end;

    local procedure CalcInvoicedQty(): Decimal
    begin
        ItemStatisticsBuffer.SetRange("Entry Type Filter");
        ItemStatisticsBuffer.CalcFields("Invoiced Quantity");
        exit(ItemStatisticsBuffer."Invoiced Quantity");
    end;

    local procedure CalcPerUnit(Amount: Decimal; Qty: Decimal): Decimal
    begin
        if Qty <> 0 then
            exit(Round(Amount / Abs(Qty), GeneralLedgerSetup."Unit-Amount Rounding Precision"));
        exit(0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnAfterItemStatisticsBufferSetFilters(var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnAfterCalcAmounts(var Item: Record Item; var SalesQty: Decimal; var SalesAmount: Decimal; var COGSAmount: Decimal; var ItemProfit: Decimal)
    begin
    end;
}

