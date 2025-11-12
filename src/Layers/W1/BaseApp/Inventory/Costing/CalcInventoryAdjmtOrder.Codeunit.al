// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

codeunit 5896 "Calc. Inventory Adjmt. - Order"
{
    Permissions = TableData Microsoft.Manufacturing.Capacity."Capacity Ledger Entry" = r,
                  TableData "Inventory Adjmt. Entry (Order)" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        CostCalcMgt: Codeunit "Cost Calculation Management";

    procedure Calculate(SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var InvtAdjmtBuf: Record "Inventory Adjustment Buffer")
    var
        ActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        OutputQty: Decimal;
    begin
        if not Item.Get(SourceInvtAdjmtEntryOrder."Item No.") then
            Item.Init();

        OnCalculateOnAfterGetItem(Item, SourceInvtAdjmtEntryOrder);

        OutputQty := CalcOutputQty(SourceInvtAdjmtEntryOrder, false);
        CalcActualUsageCosts(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder);
        CalcActualVariances(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder);
        CalcOutputEntryCostAdjmts(SourceInvtAdjmtEntryOrder, OutputQty, ActInvtAdjmtEntryOrder, InvtAdjmtBuf);
    end;

    procedure CalcActualUsageCosts(SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OutputQty: Decimal; var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
        InvtAdjmtEntryOrder := SourceInvtAdjmtEntryOrder;
        InvtAdjmtEntryOrder.RoundCosts(0);

        CalcActualMaterialCosts(InvtAdjmtEntryOrder);
        CalcActualCapacityCosts(InvtAdjmtEntryOrder);
        InvtAdjmtEntryOrder.RoundCosts(1);

        InvtAdjmtEntryOrder.CalcOvhdCost(OutputQty);
        InvtAdjmtEntryOrder.RoundCosts(1);

        InvtAdjmtEntryOrder.CalcDirectCostFromCostShares();
        InvtAdjmtEntryOrder.CalcIndirectCostFromCostShares();
        InvtAdjmtEntryOrder.CalcUnitCost();
    end;

    local procedure CalcActualVariances(SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OutputQty: Decimal; var VarianceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    var
        StdCostInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        StdCostInvtAdjmtEntryOrder := SourceInvtAdjmtEntryOrder;

        if Item."Costing Method" = Item."Costing Method"::Standard then begin
            CalcStandardCost(StdCostInvtAdjmtEntryOrder, OutputQty);
            VarianceInvtAdjmtEntryOrder.CalcDiff(StdCostInvtAdjmtEntryOrder, true);
        end else
            VarianceInvtAdjmtEntryOrder.CalcDiff(VarianceInvtAdjmtEntryOrder, true);
    end;

    local procedure CalcOutputEntryCostAdjmts(SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OutputQty: Decimal; ActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var InvtAdjmtBuf: Record "Inventory Adjustment Buffer")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        OldActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        NewActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        NewNegActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        RemActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        RemNegActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        ActNegInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        RemOutputQty: Decimal;
        RemNegOutputQty: Decimal;
        GrossOutputQty: Decimal;
        ReversedQty: Decimal;
        IsPositiveOutputs: Boolean;
    begin
        OutputItemLedgEntryExist(SourceInvtAdjmtEntryOrder, TempItemLedgEntry);
        GrossOutputQty := CalcOutputQty(SourceInvtAdjmtEntryOrder, true);
        if GrossOutputQty <> OutputQty then begin
            ActNegInvtAdjmtEntryOrder := ActInvtAdjmtEntryOrder;
            if OutputQty = 0 then
                ActNegInvtAdjmtEntryOrder.RoundCosts(-1)
            else
                ActNegInvtAdjmtEntryOrder.RoundCosts(-(GrossOutputQty - OutputQty) / OutputQty);
        end;

        for IsPositiveOutputs := true downto false do
            if TempItemLedgEntry.Find('-') then begin
                if IsPositiveOutputs then begin
                    RemOutputQty := OutputQty;
                    RemActInvtAdjmtEntryOrder := ActInvtAdjmtEntryOrder;
                    RemNegOutputQty := -(GrossOutputQty - OutputQty);
                    RemNegActInvtAdjmtEntryOrder := ActNegInvtAdjmtEntryOrder;
                end else begin
                    RemOutputQty := -(GrossOutputQty - OutputQty);
                    RemActInvtAdjmtEntryOrder := ActNegInvtAdjmtEntryOrder;
                    RemNegOutputQty := 0;
                end;

                repeat
                    if TempItemLedgEntry.Positive = IsPositiveOutputs then begin
                        ReversedQty := CalcExactCostReversingQty(TempItemLedgEntry);

                        OldActInvtAdjmtEntryOrder.Init();
                        CalcActualOutputCosts(OldActInvtAdjmtEntryOrder, TempItemLedgEntry."Entry No.");

                        NewActInvtAdjmtEntryOrder := RemActInvtAdjmtEntryOrder;

                        OnCalcOutputEntryCostAdjmtsOnBeforeCalculateCostForGrossOutput(NewActInvtAdjmtEntryOrder, RemOutputQty, OutputQty);

                        if RemOutputQty * (TempItemLedgEntry.Quantity + ReversedQty) <> 0 then begin
                            // Calculate cost for gross output
                            NewActInvtAdjmtEntryOrder.RoundCosts((TempItemLedgEntry.Quantity + ReversedQty) / RemOutputQty);

                            RemOutputQty -= (TempItemLedgEntry.Quantity + ReversedQty);
                            RemActInvtAdjmtEntryOrder.CalcDiff(NewActInvtAdjmtEntryOrder, false);
                            RemActInvtAdjmtEntryOrder.RoundCosts(-1);
                        end else
                            NewActInvtAdjmtEntryOrder.RoundCosts(0);

                        if RemNegOutputQty * ReversedQty <> 0 then begin
                            // Calculate cost for negative output
                            NewNegActInvtAdjmtEntryOrder := RemNegActInvtAdjmtEntryOrder;
                            NewNegActInvtAdjmtEntryOrder.RoundCosts(ReversedQty / RemNegOutputQty);

                            RemNegOutputQty -= ReversedQty;
                            RemNegActInvtAdjmtEntryOrder.CalcDiff(NewNegActInvtAdjmtEntryOrder, false);
                            RemNegActInvtAdjmtEntryOrder.RoundCosts(-1);
                            // Gross + Negative Outputs
                            NewActInvtAdjmtEntryOrder.CalcDiff(NewNegActInvtAdjmtEntryOrder, false);
                            NewActInvtAdjmtEntryOrder.RoundCosts(-1);
                        end;
                        // Compute difference to post
                        NewActInvtAdjmtEntryOrder.CalcDiff(OldActInvtAdjmtEntryOrder, false);
                        NewActInvtAdjmtEntryOrder.RoundCosts(-1);

                        UpdateOutputAdjmtBuf(TempItemLedgEntry, NewActInvtAdjmtEntryOrder, InvtAdjmtBuf);
                        TempItemLedgEntry.Delete();
                    end;
                until TempItemLedgEntry.Next() = 0;
            end;
    end;

    local procedure UpdateOutputAdjmtBuf(ItemLedgerEntry: Record "Item Ledger Entry"; InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var InventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer")
    begin
        OnBeforeUpdateOutputAdjmtBuf(InventoryAdjmtEntryOrder, ItemLedgerEntry, InventoryAdjustmentBuffer);

        if HasNewCost(InventoryAdjmtEntryOrder."Direct Cost", InventoryAdjmtEntryOrder."Direct Cost (ACY)") or not InventoryAdjmtEntryOrder."Completely Invoiced" then
            InventoryAdjustmentBuffer.AddCost(
              ItemLedgerEntry."Entry No.", InventoryAdjustmentBuffer."Entry Type"::"Direct Cost", "Cost Variance Type"::" ", InventoryAdjmtEntryOrder."Direct Cost", InventoryAdjmtEntryOrder."Direct Cost (ACY)");
        if HasNewCost(InventoryAdjmtEntryOrder."Indirect Cost", InventoryAdjmtEntryOrder."Indirect Cost (ACY)") then
            InventoryAdjustmentBuffer.AddCost(
              ItemLedgerEntry."Entry No.", InventoryAdjustmentBuffer."Entry Type"::"Indirect Cost", "Cost Variance Type"::" ", InventoryAdjmtEntryOrder."Indirect Cost", InventoryAdjmtEntryOrder."Indirect Cost (ACY)");

        if ItemLedgerEntry."Order Type" = ItemLedgerEntry."Order Type"::Production then
            if CostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                if HasNewCost(InventoryAdjmtEntryOrder."Direct Cost Non-Inventory", InventoryAdjmtEntryOrder."Direct Cost Non-Inv. (ACY)") then
                    InventoryAdjustmentBuffer.AddCost(
                      ItemLedgerEntry."Entry No.", InventoryAdjustmentBuffer."Entry Type"::"Direct Cost - Non Inventory", "Cost Variance Type"::" ", InventoryAdjmtEntryOrder."Direct Cost Non-Inventory", InventoryAdjmtEntryOrder."Direct Cost Non-Inv. (ACY)");

        if Item."Costing Method" <> Item."Costing Method"::Standard then
            exit;

        if HasNewCost(InventoryAdjmtEntryOrder."Single-Level Material Cost", InventoryAdjmtEntryOrder."Single-Lvl Material Cost (ACY)") then
            InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
              InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::Material,
              InventoryAdjmtEntryOrder."Single-Level Material Cost", InventoryAdjmtEntryOrder."Single-Lvl Material Cost (ACY)");

        if ItemLedgerEntry."Order Type" = ItemLedgerEntry."Order Type"::Production then
            if CostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                if HasNewCost(InventoryAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost", InventoryAdjmtEntryOrder."Single-Lvl Mat.NonInvCost(ACY)") then
                    InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
                      InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::"Material - Non Inventory",
                      InventoryAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost", InventoryAdjmtEntryOrder."Single-Lvl Mat.NonInvCost(ACY)");

        if HasNewCost(InventoryAdjmtEntryOrder."Single-Level Capacity Cost", InventoryAdjmtEntryOrder."Single-Lvl Capacity Cost (ACY)") then
            InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
              InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::Capacity,
              InventoryAdjmtEntryOrder."Single-Level Capacity Cost", InventoryAdjmtEntryOrder."Single-Lvl Capacity Cost (ACY)");

        if HasNewCost(InventoryAdjmtEntryOrder."Single-Level Cap. Ovhd Cost", InventoryAdjmtEntryOrder."Single-Lvl Cap. Ovhd Cost(ACY)") then
            InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
              InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::"Capacity Overhead",
              InventoryAdjmtEntryOrder."Single-Level Cap. Ovhd Cost", InventoryAdjmtEntryOrder."Single-Lvl Cap. Ovhd Cost(ACY)");

        if HasNewCost(InventoryAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost", InventoryAdjmtEntryOrder."Single-Lvl Mfg. Ovhd Cost(ACY)") then
            InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
              InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::"Manufacturing Overhead",
              InventoryAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost", InventoryAdjmtEntryOrder."Single-Lvl Mfg. Ovhd Cost(ACY)");

        if HasNewCost(InventoryAdjmtEntryOrder."Single-Level Subcontrd. Cost", InventoryAdjmtEntryOrder."Single-Lvl Subcontrd Cost(ACY)") then
            InventoryAdjustmentBuffer.AddCost(ItemLedgerEntry."Entry No.",
              InventoryAdjustmentBuffer."Entry Type"::Variance, InventoryAdjustmentBuffer."Variance Type"::Subcontracted,
              InventoryAdjmtEntryOrder."Single-Level Subcontrd. Cost", InventoryAdjmtEntryOrder."Single-Lvl Subcontrd Cost(ACY)");

        OnAfterUpdateOutputAdjmtBuf(InventoryAdjmtEntryOrder, ItemLedgerEntry, InventoryAdjustmentBuffer);
    end;

    local procedure CalcStandardCost(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OutputQty: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcStandardCost(InvtAdjmtEntryOrder, OutputQty, IsHandled);
        if IsHandled then
            exit;

        if not InvtAdjmtEntryOrder.Find() or not InvtAdjmtEntryOrder."Completely Invoiced" then
            InvtAdjmtEntryOrder.GetCostsFromItem(OutputQty)
        else begin
            InvtAdjmtEntryOrder.RoundCosts(OutputQty);
            InvtAdjmtEntryOrder.CalcDirectCostFromCostShares();
            InvtAdjmtEntryOrder.CalcIndirectCostFromCostShares();
            InvtAdjmtEntryOrder.CalcUnitCost();
        end;
    end;

    local procedure CalcActualOutputCosts(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemLedgerEntryNo: Integer)
    var
        OutputValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddCosts(InvtAdjmtEntryOrder, ItemLedgerEntryNo, IsHandled);
        if IsHandled then
            exit;

        OutputValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        OutputValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        OutputValueEntry.SetLoadFields("Entry Type", "Variance Type", "Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
        if OutputValueEntry.FindSet() then
            repeat
                case OutputValueEntry."Entry Type" of
                    OutputValueEntry."Entry Type"::"Direct Cost":
                        InvtAdjmtEntryOrder.AddDirectCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
                    OutputValueEntry."Entry Type"::"Indirect Cost":
                        InvtAdjmtEntryOrder.AddIndirectCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
                    OutputValueEntry."Entry Type"::"Direct Cost - Non Inventory":
                        if CostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                            InvtAdjmtEntryOrder.AddDirectCostNonInv(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
                    OutputValueEntry."Entry Type"::Variance:
                        case OutputValueEntry."Variance Type" of
                            OutputValueEntry."Variance Type"::Material:
                                InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
                            OutputValueEntry."Variance Type"::"Material - Non Inventory":
                                if CostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                                    InvtAdjmtEntryOrder.AddSingleLvlNonInvMaterialCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
                            OutputValueEntry."Variance Type"::Capacity:
                                InvtAdjmtEntryOrder.AddSingleLvlCapacityCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
                            OutputValueEntry."Variance Type"::"Capacity Overhead":
                                InvtAdjmtEntryOrder.AddSingleLvlCapOvhdCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
                            OutputValueEntry."Variance Type"::"Manufacturing Overhead":
                                InvtAdjmtEntryOrder.AddSingleLvlMfgOvhdCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
                            OutputValueEntry."Variance Type"::Subcontracted:
                                InvtAdjmtEntryOrder.AddSingleLvlSubcontrdCost(OutputValueEntry."Cost Amount (Actual)", OutputValueEntry."Cost Amount (Actual) (ACY)");
                        end;
                end;
            until OutputValueEntry.Next() = 0;
    end;

    local procedure CalcActualMaterialCosts(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CalcActualMaterialCostQuery: Query "Calculate Actual Material Cost";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcActualMaterialCosts(InvtAdjmtEntryOrder, IsHandled);
        if IsHandled then
            exit;

        CalcActualMaterialCostQuery.SetRange(Order_Type, InvtAdjmtEntryOrder."Order Type");
        CalcActualMaterialCostQuery.SetRange(Order_No_, InvtAdjmtEntryOrder."Order No.");
        CalcActualMaterialCostQuery.SetFilter(Entry_Type, '%1|%2',
                ItemLedgEntry."Entry Type"::Consumption,
                ItemLedgEntry."Entry Type"::"Assembly Consumption");

        CalcActualMaterialCostQuery.SetFilter(Value_Entry_Type, '<>%1', "Cost Entry Type"::Rounding);
        if not CostCalcMgt.CanIncNonInvCostIntoProductionItem() then
            CalcActualMaterialCostQuery.SetRange(Inventoriable, true);

        if InvtAdjmtEntryOrder."Order Type" = InvtAdjmtEntryOrder."Order Type"::Production then
            CalcActualMaterialCostQuery.SetRange(Order_Line_No_, InvtAdjmtEntryOrder."Order Line No.");
        OnCalcActualMaterialCostsOnAfterSetFilters(ItemLedgEntry, InvtAdjmtEntryOrder, CalcActualMaterialCostQuery, IsHandled);

        CalcActualMaterialCostQuery.Open();

        if not IsHandled then
            while CalcActualMaterialCostQuery.Read() do begin
                InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(
                    -CalcActualMaterialCostQuery.Cost_Amount__Actual_,
                    -CalcActualMaterialCostQuery.Cost_Amount__Actual___ACY_
                );
                if not CostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                    InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(
                        -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl__,
                        -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl___ACY_
                    )
                else begin
                    InvtAdjmtEntryOrder.AddDirectCostNonInv(
                        -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl__,
                        -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl___ACY_
                    );

                    InvtAdjmtEntryOrder.AddSingleLvlNonInvMaterialCost(
                        -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl__,
                        -CalcActualMaterialCostQuery.Cost_Amount__Non_Invtbl___ACY_
                    );
                end;

                if CalcActualMaterialCostQuery.Positive then
                    AdjustForRevNegCon(InvtAdjmtEntryOrder, CalcActualMaterialCostQuery.Entry_No_);
            end;
    end;

    procedure AdjustForRevNegCon(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemLedgEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
        InvtAdjmtEntryOrder.AddSingleLvlMaterialCost(ValueEntry."Cost Amount (Actual)", ValueEntry."Cost Amount (Actual) (ACY)");
    end;

    local procedure CalcActualCapacityCosts(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcActualCapacityCosts(InvtAdjmtEntryOrder, IsHandled);
        if IsHandled then
            exit;

        OnCalcActualCapacityCostsInternal(InvtAdjmtEntryOrder);
    end;

    procedure CalcOutputQty(InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OnlyInbounds: Boolean) OutputQty: Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgEntry.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type");
        ItemLedgEntry.SetRange("Order No.", InvtAdjmtEntryOrder."Order No.");
        ItemLedgEntry.SetFilter("Entry Type", '%1|%2',
          ItemLedgEntry."Entry Type"::Output,
          ItemLedgEntry."Entry Type"::"Assembly Output");
        if InvtAdjmtEntryOrder."Order Type" = InvtAdjmtEntryOrder."Order Type"::Production then
            ItemLedgEntry.SetRange("Order Line No.", InvtAdjmtEntryOrder."Order Line No.");
        if OnlyInbounds then
            ItemLedgEntry.SetRange(Positive, true);
        OnCalcOutputQtyOnAfterSetFilters(ItemLedgEntry, InvtAdjmtEntryOrder);
        ItemLedgEntry.CalcSums(Quantity);
        OutputQty := ItemLedgEntry.Quantity;
    end;

    local procedure CopyILEToILE(var FromItemLedgEntry: Record "Item Ledger Entry"; var ToItemLedgEntry: Record "Item Ledger Entry")
    begin
        ToItemLedgEntry.Reset();
        ToItemLedgEntry.DeleteAll();
        if FromItemLedgEntry.FindSet() then
            repeat
                ToItemLedgEntry := FromItemLedgEntry;
                ToItemLedgEntry.Insert();
            until FromItemLedgEntry.Next() = 0;
    end;

    local procedure OutputItemLedgEntryExist(SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ToItemLedgEntry: Record "Item Ledger Entry")
    var
        FromItemLedgEntry: Record "Item Ledger Entry";
    begin
        FromItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        FromItemLedgEntry.SetRange("Order Type", SourceInvtAdjmtEntryOrder."Order Type");
        FromItemLedgEntry.SetRange("Order No.", SourceInvtAdjmtEntryOrder."Order No.");
        FromItemLedgEntry.SetFilter("Entry Type", '%1|%2', FromItemLedgEntry."Entry Type"::Output, FromItemLedgEntry."Entry Type"::"Assembly Output");
        if SourceInvtAdjmtEntryOrder."Order Type" = SourceInvtAdjmtEntryOrder."Order Type"::Production then
            FromItemLedgEntry.SetRange("Order Line No.", SourceInvtAdjmtEntryOrder."Order Line No.");
        OnOutputItemLedgEntryExistOnAfterSetFilters(FromItemLedgEntry, SourceInvtAdjmtEntryOrder);
        CopyILEToILE(FromItemLedgEntry, ToItemLedgEntry);
    end;

    local procedure CalcExactCostReversingQty(ItemLedgEntry: Record "Item Ledger Entry") Qty: Decimal
    var
        OutbndItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
        TempItemLedgEntryInChain: Record "Item Ledger Entry" temporary;
    begin
        OutbndItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        OutbndItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type");
        OutbndItemLedgEntry.SetRange("Order No.", ItemLedgEntry."Order No.");
        OutbndItemLedgEntry.SetRange("Order Line No.", ItemLedgEntry."Order Line No.");
        OutbndItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type");
        OutbndItemLedgEntry.SetRange(Positive, false);
        OutbndItemLedgEntry.SetFilter("Applies-to Entry", '<>0');
        if OutbndItemLedgEntry.IsEmpty() then
            exit(0);

        ItemApplnEntry.GetVisitedEntries(ItemLedgEntry, TempItemLedgEntryInChain, true);
        TempItemLedgEntryInChain.SetRange("Order Type", ItemLedgEntry."Order Type");
        TempItemLedgEntryInChain.SetRange("Order No.", ItemLedgEntry."Order No.");
        TempItemLedgEntryInChain.SetRange("Order Line No.", ItemLedgEntry."Order Line No.");
        TempItemLedgEntryInChain.SetRange("Entry Type", ItemLedgEntry."Entry Type");
        TempItemLedgEntryInChain.SetRange(Positive, false);
        TempItemLedgEntryInChain.SetFilter("Applies-to Entry", '<>0');
        TempItemLedgEntryInChain.CalcSums(Quantity);
        Qty := TempItemLedgEntryInChain.Quantity;

        OnAfterCalcExactCostReversingQty(ItemLedgEntry, Qty);
    end;

    local procedure HasNewCost(NewCost: Decimal; NewCostACY: Decimal): Boolean
    begin
        exit((NewCost <> 0) or (NewCostACY <> 0));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOutputAdjmtBuf(InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemLedgerEntry: Record "Item Ledger Entry"; var InventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOutputAdjmtBuf(InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemLedgerEntry: Record "Item Ledger Entry"; var InventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcActualCapacityCosts(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddCosts(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemLedgerEntryNo: Integer; var isHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcActualMaterialCosts(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnCalcActualCapacityCostsOnAfterSetFilters(var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var IsHandled: Boolean; ShareOfTotalCapCost: Decimal)
    begin
        OnCalcActualCapacityCostsOnAfterSetFilters(CapLedgEntry, InventoryAdjmtEntryOrder, IsHandled, ShareOfTotalCapCost);
    end;

    [Obsolete('Moved to codeunit MfgInventoryAdjmtOrder', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCalcActualCapacityCostsOnAfterSetFilters(var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var IsHandled: Boolean; ShareOfTotalCapCost: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnCalcActualMaterialCostsOnAfterSetFilters(var ItemLedgEntry: Record "Item Ledger Entry"; var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CalculateActualMaterialCost: Query "Calculate Actual Material Cost"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcOutputQtyOnAfterSetFilters(var ItemLedgEntry: Record "Item Ledger Entry"; var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnAfterGetItem(var Item: Record Item; var SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOutputItemLedgEntryExistOnAfterSetFilters(var FromItemLedgEntry: Record "Item Ledger Entry"; var SourceInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcOutputEntryCostAdjmtsOnBeforeCalculateCostForGrossOutput(var NewActInvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; RemOutputQty: Decimal; OutputQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcStandardCost(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OutputQty: Decimal; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeCalcShareOfCapCost(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ShareOfCapCost: Decimal; var IsHandled: Boolean)
    begin
        OnBeforeCalcShareOfCapCost(InvtAdjmtEntryOrder, ShareOfCapCost, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgInventoryAdjmtEntryOrder', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcShareOfCapCost(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ShareOfCapCost: Decimal; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcExactCostReversingQty(ItemLedgEntry: Record "Item Ledger Entry"; var Qty: Decimal)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnCalcActualCapacityCostsInternal(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;
}

