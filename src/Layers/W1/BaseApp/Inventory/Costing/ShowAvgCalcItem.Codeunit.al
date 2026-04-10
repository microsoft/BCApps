// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

codeunit 5803 "Show Avg. Calc. - Item"
{
    TableNo = Item;

    trigger OnRun()
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code", "Entry No.");
        ValueEntry.SetRange("Item No.", Rec."No.");
        ValueEntry.SetFilter("Valuation Date", Rec.GetFilter("Date Filter"));
        ValueEntry.SetFilter("Location Code", Rec.GetFilter("Location Filter"));
        ValueEntry.SetFilter("Variant Code", Rec.GetFilter("Variant Filter"));
        OnRunOnAfterValueEntrySetFilters(ValueEntry, Rec);
        PAGE.RunModal(PAGE::"Value Entries", ValueEntry, ValueEntry."Cost Amount (Actual)");
    end;

    procedure DrillDownAvgCostAdjmtPoint(var Item: Record Item)
    var
        AvgCostCalcOverview: Page "Average Cost Calc. Overview";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrillDownAvgCostAdjmtPoint(Item, IsHandled);
        if IsHandled then
            exit;

        AvgCostCalcOverview.SetItem(Item);
        AvgCostCalcOverview.RunModal();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDownAvgCostAdjmtPoint(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterValueEntrySetFilters(var ValueEntry: Record "Value Entry"; var Item: Record Item)
    begin
    end;
}

