// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Telemetry;

codeunit 5806 "Item Ledger Entry-Edit"
{
    Permissions = tabledata "Item Ledger Entry" = rm,
                  tabledata "Item Application Entry" = rm,
                  tabledata "Item" = rm;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NegativeEntryErr: Label 'You can only mark positive entries to adjust.';
        CostIsAdjustedResetTok: Label 'Cost adjusted reset', Locked = true;
        ItemCostIsAdjustedResetTok: Label 'Item cost was set up to be adjusted.', Locked = true;

    procedure SetAppliedEntriesToAdjust(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        Item: Record Item;
        AppliedItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if ItemLedgerEntry.FindSet() then
            repeat
                if Item.Get(ItemLedgerEntry."Item No.") then begin
                    Item."Cost is Adjusted" := false;
                    Item.Modify();

                    FeatureTelemetry.LogUsage('0000MEK', CostIsAdjustedResetTok, ItemCostIsAdjustedResetTok);
                end else
                    Item.Init();

                if Item."Costing Method" = Item."Costing Method"::Average then begin
                    if ItemLedgerEntry."Applies-to Entry" <> 0 then
                        if ItemLedgerEntry.Positive then
                            ItemLedgerEntry.SetAppliedEntryToAdjust(true)
                        else
                            if AppliedItemLedgerEntry.Get(ItemLedgerEntry."Applies-to Entry") then
                                AppliedItemLedgerEntry.SetAppliedEntryToAdjust(true);
                end else begin
                    if not ItemLedgerEntry.Positive then
                        Error(NegativeEntryErr);
                    ItemLedgerEntry.SetAppliedEntryToAdjust(true);
                    ItemApplicationEntry.SetOutboundsNotUpdated(ItemLedgerEntry);
                end;
            until ItemLedgerEntry.Next() = 0;
    end;
}
