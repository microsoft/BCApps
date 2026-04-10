// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Inventory.Item;

codeunit 7154 ItemStatisticsCache
{
    var
        TempItemStatisticsCache: Record "Item Statistics Cache" temporary;
        Params: Dictionary of [Text, Text];

    trigger OnRun()
    var
        Item: Record Item;
        ItemStatisticsCache: Record "Item Statistics Cache";
        Results: Dictionary of [Text, Text];
        CurrentDate: Date;
        ItemDateFilters: array[4] of Text[30];
        PriorPeriodItemDateFilters: array[4] of Text[30];
    begin
        Params := Page.GetBackgroundParameters();
        GetCurrentDate(CurrentDate);
        GetItemDateFilters(ItemDateFilters);
        GetPriorPeriodItemDateFilters(PriorPeriodItemDateFilters);

        Item.Get(CopyStr(Params.Get('ItemNo'), 1, 20));
        ItemStatisticsCache.Get(Item."No.");
        TempItemStatisticsCache.Init();
        TempItemStatisticsCache.Copy(ItemStatisticsCache);
        TempItemStatisticsCache.Insert(false);

        TempItemStatisticsCache.UpdateIfNeeded(Item, CurrentDate, ItemDateFilters, PriorPeriodItemDateFilters);

        SetResults(Results);
        Page.SetBackgroundTaskResult(Results);
    end;

    local procedure GetCurrentDate(var CurrentDate: Date)
    begin
        Evaluate(CurrentDate, Params.Get('CurrentDate'));
    end;

    local procedure GetItemDateFilters(var ItemDateFilters: array[4] of Text[30])
    begin
        ItemDateFilters[1] := CopyStr(Params.Get('ItemDateFilter1'), 1, 30);
        ItemDateFilters[2] := CopyStr(Params.Get('ItemDateFilter2'), 1, 30);
        ItemDateFilters[3] := CopyStr(Params.Get('ItemDateFilter3'), 1, 30);
        ItemDateFilters[4] := CopyStr(Params.Get('ItemDateFilter4'), 1, 30);
    end;

    local procedure GetPriorPeriodItemDateFilters(var PriorPeriodItemDateFilters: array[4] of Text[30])
    begin
        PriorPeriodItemDateFilters[1] := CopyStr(Params.Get('PriorPeriodItemDateFilter1'), 1, 30);
        PriorPeriodItemDateFilters[2] := CopyStr(Params.Get('PriorPeriodItemDateFilter2'), 1, 30);
        PriorPeriodItemDateFilters[3] := CopyStr(Params.Get('PriorPeriodItemDateFilter3'), 1, 30);
    end;

    local procedure SetResults(var Results: Dictionary of [Text, Text])
    begin
        Results.Add('LastUpdated', Format(TempItemStatisticsCache."LastUpdated"));

        Results.Add('CurrentInventoryValue', Format(TempItemStatisticsCache.CurrentInventoryValue));
        Results.Add('ExpiredStockValue', Format(TempItemStatisticsCache.ExpiredStockValue));

        Results.Add('SalesGrowthRateThisPeriod', Format(TempItemStatisticsCache.SalesGrowthRateThisPeriod));
        Results.Add('SalesGrowthRateThisFY', Format(TempItemStatisticsCache.SalesGrowthRateThisFY));
        Results.Add('SalesGrowthRateLastFY', Format(TempItemStatisticsCache.SalesGrowthRateLastFY));

        Results.Add('ReturnRateThisPeriod', Format(TempItemStatisticsCache.ReturnRateThisPeriod));
        Results.Add('ReturnRateThisFY', Format(TempItemStatisticsCache.ReturnRateThisFY));
        Results.Add('ReturnRateLastFY', Format(TempItemStatisticsCache.ReturnRateLastFY));
        Results.Add('ReturnRateLifetime', Format(TempItemStatisticsCache.ReturnRateLifetime));

        Results.Add('NetSalesLCYThisPeriod', Format(TempItemStatisticsCache.NetSalesLCYThisPeriod));
        Results.Add('NetSalesLCYThisFY', Format(TempItemStatisticsCache.NetSalesLCYThisFY));
        Results.Add('NetSalesLCYLastFY', Format(TempItemStatisticsCache.NetSalesLCYLastFY));
        Results.Add('NetSalesLCYLifetime', Format(TempItemStatisticsCache.NetSalesLCYLifetime));

        Results.Add('GrossMarginThisPeriod', Format(TempItemStatisticsCache.GrossMarginThisPeriod));
        Results.Add('GrossMarginThisFY', Format(TempItemStatisticsCache.GrossMarginThisFY));
        Results.Add('GrossMarginLastFY', Format(TempItemStatisticsCache.GrossMarginLastFY));
        Results.Add('GrossMarginLifetime', Format(TempItemStatisticsCache.GrossMarginLifetime));
    end;
}