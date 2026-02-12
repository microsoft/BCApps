// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
codeunit 99001535 "Subc. Purch. Post Ext"
{
    var
        SubcManagementSetup: Record "Subc. Management Setup";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforeItemJnlPostLine, '', false, false)]
    local procedure "Purch.-Post_OnBeforeItemJnlPostLine"(var ItemJournalLine: Record "Item Journal Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
        FillItemJnlLineForSubcontractingItemCharge(ItemJournalLine, TempItemChargeAssignmentPurch);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnPostItemChargePerRcptOnAfterCalcDistributeCharge, '', false, false)]
    local procedure "Purch.-Post_OnPostItemChargePerRcptOnAfterCalcDistributeCharge"(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var DistributeCharge: Boolean)
    begin
        SetQuantityBaseOnSubcontractingServiceLine(PurchLine, PurchRcptLine);
    end;

    local procedure FillItemJnlLineForSubcontractingItemCharge(var ItemJournalLine: Record "Item Journal Line"; TempItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        if not SubcManagementSetup.ItemChargeToRcptSubReferenceEnabled() then
            exit;

        if ItemJournalLine."Item Charge No." <> '' then
            if PurchRcptLine.Get(TempItemChargeAssignmentPurch."Applies-to Doc. No.", TempItemChargeAssignmentPurch."Applies-to Doc. Line No.") then
                if PurchRcptLineHasProdOrder(PurchRcptLine) then
                    CopySubcontractingProdOrderFieldsToItemJnlLine(ItemJournalLine, PurchRcptLine);
    end;

    local procedure SetQuantityBaseOnSubcontractingServiceLine(PurchaseLine: Record "Purchase Line"; var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        if not SubcManagementSetup.ItemChargeToRcptSubReferenceEnabled() then
            exit;

        if PurchRcptLine."Quantity (Base)" = 0 then
            if PurchRcptLineHasProdOrder(PurchRcptLine) then
                PurchRcptLine."Quantity (Base)" := UnitofMeasureManagement.CalcBaseQty(
                        PurchRcptLine."No.", PurchRcptLine."Variant Code", PurchRcptLine."Unit of Measure Code", PurchRcptLine.Quantity, PurchRcptLine."Qty. per Unit of Measure", PurchaseLine."Qty. Rounding Precision (Base)");
    end;

    local procedure PurchRcptLineHasProdOrder(PurchRcptLine: Record "Purch. Rcpt. Line") HasProdOrder: Boolean
    begin
        HasProdOrder := (PurchRcptLine."Prod. Order No." <> '') and
                            (PurchRcptLine."Routing No." <> '') and
                            (PurchRcptLine."Operation No." <> '');
        exit(HasProdOrder);
    end;

    local procedure CopySubcontractingProdOrderFieldsToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        Item: Record Item;
    begin
        ItemJournalLine.Subcontracting := true;
        ItemJournalLine."Entry Type" := "Item Ledger Entry Type"::Output;
        ItemJournalLine.Type := "Capacity Type Journal"::"Work Center";
        ItemJournalLine."No." := PurchRcptLine."Subc. Work Center No.";
        ItemJournalLine."Routing No." := PurchRcptLine."Routing No.";
        ItemJournalLine."Routing Reference No." := PurchRcptLine."Routing Reference No.";
        ItemJournalLine."Operation No." := PurchRcptLine."Operation No.";
        ItemJournalLine."Work Center No." := PurchRcptLine."Work Center No.";
        ItemJournalLine."Unit Cost Calculation" := ItemJournalLine."Unit Cost Calculation"::Units;
        ItemJournalLine."Order Type" := "Inventory Order Type"::Production;
        ItemJournalLine."Order No." := PurchRcptLine."Prod. Order No.";
        ItemJournalLine."Order Line No." := PurchRcptLine."Prod. Order Line No.";
        Item.SetLoadFields("Inventory Posting Group");
        Item.Get(ItemJournalLine."Item No.");
        ItemJournalLine."Inventory Posting Group" := Item."Inventory Posting Group";
        ItemJournalLine."Item Charge Sub. Assign." := true;
    end;
}