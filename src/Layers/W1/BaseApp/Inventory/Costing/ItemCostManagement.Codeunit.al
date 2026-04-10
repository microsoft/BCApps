// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;

codeunit 5804 ItemCostManagement
{
    Permissions = TableData Item = rm,
                  TableData "Stockkeeping Unit" = rm,
                  TableData "Value Entry" = r;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        InvtSetup: Record "Inventory Setup";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        InvoicedQty: Decimal;
        RndgSetupRead: Boolean;
        CalledFromAdjustment: Boolean;
        InvtSetupRead: Boolean;
        GLSetupRead: Boolean;
        ItemUnitCostUpdated: Boolean;

    procedure IsItemUnitCostUpdated(): Boolean;
    begin
        exit(ItemUnitCostUpdated);
    end;

    procedure UpdateUnitCost(var Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; LastDirectCost: Decimal; NewStdCost: Decimal; UpdateSKU: Boolean; FilterSKU: Boolean; RecalcStdCost: Boolean; CalledByFieldNo: Integer)
    var
        CheckItem: Record Item;
        UnitCostUpdated: Boolean;
        RunOnModifyTrigger: Boolean;
        IsHandled: Boolean;
        xUnitCost: Decimal;
    begin
        ItemUnitCostUpdated := false;
        OnBeforeUpdateUnitCost(
          Item, LocationCode, VariantCode, LastDirectCost, NewStdCost, UpdateSKU, FilterSKU, RecalcStdCost, CalledByFieldNo, UnitCostUpdated, CalledFromAdjustment);
        if UnitCostUpdated then
            exit;

        if NewStdCost <> 0 then
            Item."Standard Cost" := NewStdCost;

        xUnitCost := Item."Unit Cost";
        if Item."Costing Method" = Item."Costing Method"::Standard then
            Item."Unit Cost" := Item."Standard Cost"
        else
            if CalledFromAdjustment then
                CalcUnitCostFromAverageCost(Item)
            else
                UpdateUnitCostFromLastDirectCost(Item, LastDirectCost);
        ItemUnitCostUpdated := xUnitCost <> Item."Unit Cost";

        if RecalcStdCost then
            RecalcStdCostItem(Item);

        CheckUpdateLastDirectCost(Item, LastDirectCost);

        IsHandled := false;
        OnUpdateUnitCostOnBeforeValidatePriceProfitCalculation(Item, IsHandled);
        if not IsHandled then
            Item.Validate(Item."Price/Profit Calculation");

        RunOnModifyTrigger := CalledByFieldNo <> 0;
        OnUpdateUnitCostOnAfterCalcRunOnModifyTrigger(Item, RunOnModifyTrigger, CalledByFieldNo);
        if CheckItem.Get(Item."No.") then
            if RunOnModifyTrigger then
                Item.Modify(true)
            else
                Item.Modify();

        OnUpdateUnitCostOnBeforeUpdateSKU(Item, UpdateSKU);
        if UpdateSKU then
            FindUpdateUnitCostSKU(Item, LocationCode, VariantCode, FilterSKU, LastDirectCost);

        OnAfterUpdateUnitCost(Item, CalledByFieldNo);
    end;

    local procedure CalcUnitCostFromAverageCost(var Item: Record Item)
    var
        AverageCost: Decimal;
        AverageCostACY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcUnitCostFromAverageCost(Item, CostCalcMgt, GLSetup, IsHandled);
        if IsHandled then
            exit;

        CostCalcMgt.GetRndgSetup(GLSetup, Currency, RndgSetupRead);
        if CalculateAverageCost(Item, AverageCost, AverageCostACY) then begin
            if AverageCost <> 0 then
                Item."Unit Cost" := Round(AverageCost, GLSetup."Unit-Amount Rounding Precision");
        end else begin
            CalcLastAdjEntryAvgCost(Item, AverageCost, AverageCostACY);
            if AverageCost <> 0 then
                Item."Unit Cost" := Round(AverageCost, GLSetup."Unit-Amount Rounding Precision");
        end;
    end;

    local procedure UpdateUnitCostFromLastDirectCost(var Item: Record Item; LastDirectCost: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCostFromLastDirectCost(Item, LastDirectCost, InvoicedQty, IsHandled);
        if IsHandled then
            exit;

        if (Item."Unit Cost" = 0) or ((InvoicedQty > 0) and (LastDirectCost <> 0)) then begin
            Item.CalcFields("Net Invoiced Qty.");
            IsHandled := false;
            OnUpdateUnitCostOnBeforeNetInvoiceQtyCheck(Item, IsHandled);
            if (Item."Net Invoiced Qty." > 0) and (Item."Net Invoiced Qty." <= InvoicedQty) and not IsHandled then
                Item."Unit Cost" := LastDirectCost;
        end;
    end;

    local procedure CheckUpdateLastDirectCost(var Item: Record Item; LastDirectCost: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUpdateLastDirectCost(Item, LastDirectCost, IsHandled);
        if IsHandled then
            exit;

        if LastDirectCost <> 0 then
            Item."Last Direct Cost" := LastDirectCost;
    end;

    procedure UpdateStdCostShares(FromItem: Record Item)
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateStdCostShares(FromItem, IsHandled);
        if IsHandled then
            exit;

        Item.Get(FromItem."No.");
        Item.Validate("Standard Cost", FromItem."Standard Cost");
        Item."Single-Level Material Cost" := FromItem."Single-Level Material Cost";
        Item."Single-Level Capacity Cost" := FromItem."Single-Level Capacity Cost";
        Item."Single-Level Subcontrd. Cost" := FromItem."Single-Level Subcontrd. Cost";
        Item."Single-Level Cap. Ovhd Cost" := FromItem."Single-Level Cap. Ovhd Cost";
        Item."Single-Level Mfg. Ovhd Cost" := FromItem."Single-Level Mfg. Ovhd Cost";
        Item."Rolled-up Material Cost" := FromItem."Rolled-up Material Cost";
        Item."Rolled-up Capacity Cost" := FromItem."Rolled-up Capacity Cost";
        Item."Rolled-up Subcontracted Cost" := FromItem."Rolled-up Subcontracted Cost";
        Item."Rolled-up Mfg. Ovhd Cost" := FromItem."Rolled-up Mfg. Ovhd Cost";
        Item."Rolled-up Cap. Overhead Cost" := FromItem."Rolled-up Cap. Overhead Cost";
        Item."Last Unit Cost Calc. Date" := FromItem."Last Unit Cost Calc. Date";
        Item."Single-Lvl Mat. Non-Invt. Cost" := FromItem."Single-Lvl Mat. Non-Invt. Cost";
        Item."Rolled-up Mat. Non-Invt. Cost" := FromItem."Rolled-up Mat. Non-Invt. Cost";
        OnUpdateStdCostSharesOnAfterCopyCosts(Item, FromItem);
        Item.Modify();
    end;

    procedure UpdateStdCostSharesForSKU(FromSKU: Record "Stockkeeping Unit")
    var
        SKU: Record "Stockkeeping Unit";
    begin
        SKU.Get(FromSKU."Location Code", FromSKU."Item No.", FromSKU."Variant Code");
        SKU.Validate("Standard Cost", FromSKU."Standard Cost");
        SKU."Single-Level Material Cost" := FromSKU."Single-Level Material Cost";
        SKU."Single-Level Capacity Cost" := FromSKU."Single-Level Capacity Cost";
        SKU."Single-Level Subcontrd. Cost" := FromSKU."Single-Level Subcontrd. Cost";
        SKU."Single-Level Cap. Ovhd Cost" := FromSKU."Single-Level Cap. Ovhd Cost";
        SKU."Single-Level Mfg. Ovhd Cost" := FromSKU."Single-Level Mfg. Ovhd Cost";
        SKU."Rolled-up Material Cost" := FromSKU."Rolled-up Material Cost";
        SKU."Rolled-up Capacity Cost" := FromSKU."Rolled-up Capacity Cost";
        SKU."Rolled-up Subcontracted Cost" := FromSKU."Rolled-up Subcontracted Cost";
        SKU."Rolled-up Mfg. Ovhd Cost" := FromSKU."Rolled-up Mfg. Ovhd Cost";
        SKU."Rolled-up Cap. Overhead Cost" := FromSKU."Rolled-up Cap. Overhead Cost";
        SKU."Single-Lvl Mat. Non-Invt. Cost" := FromSKU."Single-Lvl Mat. Non-Invt. Cost";
        SKU."Rolled-up Mat. Non-Invt. Cost" := FromSKU."Rolled-up Mat. Non-Invt. Cost";
        SKU.Modify();
    end;

    procedure UpdateUnitCostSKU(Item: Record Item; var SKU: Record "Stockkeeping Unit"; LastDirectCost: Decimal; NewStdCost: Decimal; MatchSKU: Boolean; CalledByFieldNo: Integer)
    var
        ValueEntry: Record "Value Entry";
        AverageCost: Decimal;
        AverageCostACY: Decimal;
        UnitCostUpdated: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCostSKU(Item, SKU, LastDirectCost, NewStdCost, MatchSKU, CalledByFieldNo, UnitCostUpdated, CalledFromAdjustment);
        if not UnitCostUpdated then begin
            if NewStdCost <> 0 then
                SKU."Standard Cost" := NewStdCost;
            if Item."Costing Method" <> Item."Costing Method"::Standard then begin
                GetInvtSetup();
                if InvtSetup."Average Cost Calc. Type" <> InvtSetup."Average Cost Calc. Type"::Item then begin
                    IsHandled := false;
                    OnUpdateUnitCostSKUOnBeforeCalcNonItemAvgCostCalcType(Item, SKU, CalledFromAdjustment, IsHandled);
                    if not IsHandled then
                        if CalledFromAdjustment then begin
                            ValueEntry."Item No." := Item."No.";
                            ValueEntry."Valuation Date" := DMY2Date(31, 12, 9999);
                            ValueEntry."Location Code" := SKU."Location Code";
                            ValueEntry."Variant Code" := SKU."Variant Code";
                            ValueEntry.SumCostsTillValuationDate(ValueEntry);
                            if ValueEntry."Item Ledger Entry Quantity" <> 0 then begin
                                AverageCost :=
                                  (ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)") /
                                  ValueEntry."Item Ledger Entry Quantity";
                                Clear(IsHandled);
                                OnUpdateUnitCostSKUOnBeforeCheckNegCost(AverageCost, IsHandled);
                                if not IsHandled then
                                    if AverageCost < 0 then
                                        AverageCost := 0;
                            end else begin
                                Item.SetRange("Location Filter", SKU."Location Code");
                                Item.SetRange("Variant Filter", SKU."Variant Code");
                                CalcLastAdjEntryAvgCost(Item, AverageCost, AverageCostACY);
                            end;
                            if AverageCost <> 0 then
                                SKU."Unit Cost" := Round(AverageCost, GLSetup."Unit-Amount Rounding Precision");
                        end else
                            if (SKU."Unit Cost" = 0) or ((InvoicedQty > 0) and MatchSKU and (LastDirectCost <> 0)) then begin
                                Item.SetRange("Location Filter", SKU."Location Code");
                                Item.SetRange("Variant Filter", SKU."Variant Code");
                                Item.CalcFields("Net Invoiced Qty.");
                                Item.SetRange("Location Filter");
                                Item.SetRange("Variant Filter");
                                if (Item."Net Invoiced Qty." > 0) and (Item."Net Invoiced Qty." <= InvoicedQty) then
                                    SKU."Unit Cost" := LastDirectCost;
                                OnUpdateUnitCostSKUOnAfterSetSKUUnitCosts(SKU, Item, InvoicedQty, LastDirectCost);
                            end;
                end else
                    SKU."Unit Cost" := Item."Unit Cost";
            end else begin
                RecalcStdCostSKU(SKU);
                SKU."Unit Cost" := SKU."Standard Cost";
            end;

            OnUpdateUnitCostSKUOnBeforeMatchSKU(SKU, Item);
            if MatchSKU and (LastDirectCost <> 0) then
                SKU."Last Direct Cost" := LastDirectCost;

            if CalledByFieldNo <> 0 then
                SKU.Modify(true)
            else
                SKU.Modify();
        end;
        OnAfterUpdateUnitCostSKU(Item, SKU);
    end;

    local procedure RecalcStdCostItem(var Item: Record Item)
    begin
        Item."Single-Level Material Cost" := Item."Standard Cost";
        Item."Single-Level Mfg. Ovhd Cost" := 0;
        Item."Single-Level Capacity Cost" := 0;
        Item."Single-Level Subcontrd. Cost" := 0;
        Item."Single-Level Cap. Ovhd Cost" := 0;
        Item."Rolled-up Material Cost" := Item."Standard Cost";
        Item."Rolled-up Mfg. Ovhd Cost" := 0;
        Item."Rolled-up Capacity Cost" := 0;
        Item."Rolled-up Subcontracted Cost" := 0;
        Item."Rolled-up Cap. Overhead Cost" := 0;

        OnAfterRecalcStdCostItem(Item);
    end;

    local procedure RecalcStdCostSKU(var SKU: Record "Stockkeeping Unit")
    begin
        SKU."Single-Level Material Cost" := SKU."Standard Cost";
        SKU."Single-Level Mfg. Ovhd Cost" := 0;
        SKU."Single-Level Capacity Cost" := 0;
        SKU."Single-Level Subcontrd. Cost" := 0;
        SKU."Single-Level Cap. Ovhd Cost" := 0;

        SKU."Rolled-up Material Cost" := SKU."Standard Cost";
        SKU."Rolled-up Mfg. Ovhd Cost" := 0;
        SKU."Rolled-up Capacity Cost" := 0;
        SKU."Rolled-up Subcontracted Cost" := 0;
        SKU."Rolled-up Cap. Overhead Cost" := 0;
    end;

    local procedure CalcLastAdjEntryAvgCost(var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ComputeThisEntry: Boolean;
        IsSubOptimal: Boolean;
        AvgCostCalculated: Boolean;
    begin
        OnBeforeCalcLastAdjEntryAvgCost(Item, AverageCost, AverageCostACY, AvgCostCalculated);
        if AvgCostCalculated then
            exit;

        AverageCost := 0;
        AverageCostACY := 0;

        if CalculateQuantity(Item) <> 0 then
            exit;
        if HasOpenEntries(Item) then
            exit;

        AvgCostCalculated := false;
        OnCalcLastAdjEntryAvgCostOnBeforeSetFilters(ValueEntry, Item, AverageCost, AverageCostACY, AvgCostCalculated);
        if AvgCostCalculated then
            exit;

        SetFilters(ValueEntry, Item);
        if ValueEntry.Find('+') then
            repeat
                ComputeThisEntry := (ValueEntry."Item Ledger Entry Quantity" < 0) and not ValueEntry.Adjustment and not ValueEntry."Drop Shipment";
                if ComputeThisEntry then begin
                    ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                    IsSubOptimal :=
                      ItemLedgEntry.Correction or
                      ((Item."Costing Method" = Item."Costing Method"::Average) and not ValueEntry."Valued By Average Cost");

                    if not IsSubOptimal or (IsSubOptimal and (AverageCost = 0)) then begin
                        ItemLedgEntry.CalcFields(
                          "Cost Amount (Expected)", "Cost Amount (Actual)",
                          "Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)");
                        AverageCost :=
                          (ItemLedgEntry."Cost Amount (Expected)" +
                           ItemLedgEntry."Cost Amount (Actual)") /
                          ItemLedgEntry.Quantity;
                        AverageCostACY :=
                          (ItemLedgEntry."Cost Amount (Expected) (ACY)" +
                           ItemLedgEntry."Cost Amount (Actual) (ACY)") /
                          ItemLedgEntry.Quantity;

                        OnCalcLastAdjEntryAvgCostOnAfterCalcAverageCost(ItemLedgEntry, ValueEntry, Item, AverageCost, AverageCostACY);
                        if (AverageCost <> 0) and not IsSubOptimal then
                            exit;
                    end;
                end;
            until ValueEntry.Next(-1) = 0;
    end;

    procedure CalculateAverageCost(var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal): Boolean
    var
        AverageQty: Decimal;
        CostAmt: Decimal;
        CostAmtACY: Decimal;
        NeedCalcPreciseAmt: Boolean;
        NeedCalcPreciseAmtACY: Boolean;
        AvgCostCalculated: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCalculateAverageCost(Item, AverageCost, AverageCostACY, AvgCostCalculated);
        if AvgCostCalculated then
            exit;

        AverageCost := 0;
        AverageCostACY := 0;

        if CalledFromAdjustment then
            ExcludeOpenOutbndCosts(Item, AverageCost, AverageCostACY, AverageQty);
        AverageQty := AverageQty + CalculateQuantity(Item);

        OnCalculateAverageCostOnAfterCalcAverageQty(Item, AverageCost, AverageCostACY, AverageQty);

        if AverageQty <> 0 then begin
            CostAmt := AverageCost + CalculateCostAmt(Item, true) + CalculateCostAmt(Item, false);
            if (CostAmt > 0) and (CostAmt = GLSetup."Amount Rounding Precision") then
                NeedCalcPreciseAmt := true;

            GetGLSetup();
            if GLSetup."Additional Reporting Currency" <> '' then begin
                Currency.Get(GLSetup."Additional Reporting Currency");
                CostAmtACY := AverageCostACY + CalculateCostAmtACY(Item, true) + CalculateCostAmtACY(Item, false);
                if (CostAmtACY > 0) and (CostAmtACY = Currency."Amount Rounding Precision") then
                    NeedCalcPreciseAmtACY := true;
            end;

            if NeedCalcPreciseAmt or NeedCalcPreciseAmtACY then
                CalculatePreciseCostAmounts(Item, NeedCalcPreciseAmt, NeedCalcPreciseAmtACY, CostAmt, CostAmtACY);

            AverageCost := CostAmt / AverageQty;
            AverageCostACY := CostAmtACY / AverageQty;

            Clear(IsHandled);
            OnCalculateAverageCostOnAfterCalculateAverage(Item, AverageCost, AverageCostACY, IsHandled);
            if not IsHandled then begin
                if AverageCost < 0 then
                    AverageCost := 0;
                if AverageCostACY < 0 then
                    AverageCostACY := 0;
            end;
        end else begin
            AverageCost := 0;
            AverageCostACY := 0;
        end;
        if AverageQty <= 0 then
            exit(false);

        exit(true);
    end;

    procedure SetFilters(var ValueEntry: Record "Value Entry"; var Item: Record Item)
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code", "Entry No.");
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetFilter("Valuation Date", Item.GetFilter("Date Filter"));
        ValueEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        ValueEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        OnAfterSetFilters(ValueEntry, Item);
    end;

    local procedure CalculateQuantity(var Item: Record Item) CalcQty: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        SetFilters(ValueEntry, Item);
        ValueEntry.CalcSums("Item Ledger Entry Quantity");
        CalcQty := ValueEntry."Item Ledger Entry Quantity";
        OnAfterCalculateQuantity(ValueEntry, Item, CalcQty);
        exit(CalcQty);
    end;

    local procedure CalculateCostAmt(var Item: Record Item; Actual: Boolean) CostAmount: Decimal
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateCostAmount(Item, Actual, CostAmount, IsHandled);
        if IsHandled then
            exit(CostAmount);

        SetFilters(ValueEntry, Item);
        if Actual then begin
            ValueEntry.CalcSums("Cost Amount (Actual)");
            exit(ValueEntry."Cost Amount (Actual)");
        end;
        ValueEntry.CalcSums("Cost Amount (Expected)");
        exit(ValueEntry."Cost Amount (Expected)");
    end;

    local procedure CalculateCostAmtACY(var Item: Record Item; Actual: Boolean): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        SetFilters(ValueEntry, Item);
        if Actual then begin
            ValueEntry.CalcSums("Cost Amount (Actual) (ACY)");
            exit(ValueEntry."Cost Amount (Actual) (ACY)");
        end;
        ValueEntry.CalcSums("Cost Amount (Expected) (ACY)");
        exit(ValueEntry."Cost Amount (Expected) (ACY)");
    end;

    local procedure CalculatePreciseCostAmounts(var Item: Record Item; NeedCalcPreciseAmt: Boolean; NeedCalcPreciseAmtACY: Boolean; var PreciseAmt: Decimal; var PreciseAmtACY: Decimal)
    var
        OpenInbndItemLedgEntry: Record "Item Ledger Entry";
        OpenOutbndItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemApplicationEntry: Record "Item Application Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatePreciseCostAmounts(Item, NeedCalcPreciseAmt, NeedCalcPreciseAmtACY, PreciseAmt, PreciseAmtACY, IsHandled);
        if IsHandled then
            exit;

        // Collect precise (not rounded) remaining cost on:
        // 1. open inbound item ledger entries;
        // 2. closed inbound item ledger entries the open outbound item entries are applied to.
        PreciseAmt := 0;
        PreciseAmtACY := 0;

        OpenInbndItemLedgEntry.SetRange("Item No.", Item."No.");
        OpenInbndItemLedgEntry.SetRange(Open, true);
        OpenInbndItemLedgEntry.SetRange(Positive, true);
        OpenInbndItemLedgEntry.SetRange("Location Code", Item.GetFilter("Location Filter"));
        OpenInbndItemLedgEntry.SetRange("Variant Code", Item.GetFilter("Variant Filter"));
        OnCalculatePreciseCostAmountsOnAfterFilterOpenInboundItemLedgerEntry(OpenInbndItemLedgEntry, Item);
        if OpenInbndItemLedgEntry.FindSet() then
            repeat
                TempItemLedgerEntry := OpenInbndItemLedgEntry;
                TempItemLedgerEntry.Insert();
            until OpenInbndItemLedgEntry.Next() = 0;

        IsHandled := false;
        OnCalculatePreciseCostAmountsOnBeforeProcessOpenOutboundItemLedgerEntry(Item, OpenInbndItemLedgEntry, OpenOutbndItemLedgEntry, TempItemLedgerEntry, IsHandled);
        if not IsHandled then begin
            OpenOutbndItemLedgEntry.CopyFilters(OpenInbndItemLedgEntry);
            OpenOutbndItemLedgEntry.SetRange(Positive, false);
            if OpenOutbndItemLedgEntry.FindSet() then
                repeat
                    if ItemApplicationEntry.GetInboundEntriesTheOutbndEntryAppliedTo(OpenOutbndItemLedgEntry."Entry No.") then
                        repeat
                            if TempItemLedgerEntry.Get(ItemApplicationEntry."Inbound Item Entry No.") then begin
                                TempItemLedgerEntry."Remaining Quantity" -= ItemApplicationEntry.Quantity;
                                TempItemLedgerEntry.Modify();
                            end else begin
                                OpenInbndItemLedgEntry.Get(ItemApplicationEntry."Inbound Item Entry No.");
                                TempItemLedgerEntry := OpenInbndItemLedgEntry;
                                TempItemLedgerEntry."Remaining Quantity" := -ItemApplicationEntry.Quantity;
                                TempItemLedgerEntry.Insert();
                            end;
                        until ItemApplicationEntry.Next() = 0;
                until OpenOutbndItemLedgEntry.Next() = 0;
        end;

        IsHandled := false;
        OnCalculatePreciseCostAmountsOnOnBeforeProcessTempItemLedgerEntry(TempItemLedgerEntry, PreciseAmt, IsHandled);
        if not IsHandled then begin
            TempItemLedgerEntry.Reset();
            if TempItemLedgerEntry.FindSet() then
                repeat
                    if NeedCalcPreciseAmt then begin
                        TempItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
                        PreciseAmt += (TempItemLedgerEntry."Cost Amount (Actual)" + TempItemLedgerEntry."Cost Amount (Expected)") / TempItemLedgerEntry.Quantity * TempItemLedgerEntry."Remaining Quantity";
                    end;
                    if NeedCalcPreciseAmtACY then begin
                        TempItemLedgerEntry.CalcFields("Cost Amount (Actual) (ACY)", "Cost Amount (Expected) (ACY)");
                        PreciseAmtACY += (TempItemLedgerEntry."Cost Amount (Actual) (ACY)" + TempItemLedgerEntry."Cost Amount (Expected) (ACY)") / TempItemLedgerEntry.Quantity * TempItemLedgerEntry."Remaining Quantity";
                    end;
                until TempItemLedgerEntry.Next() = 0;
        end;
    end;

    local procedure ExcludeOpenOutbndCosts(var Item: Record Item; var CostAmt: Decimal; var CostAmtACY: Decimal; var Quantity: Decimal)
    var
        OpenItemLedgEntry: Record "Item Ledger Entry";
    begin
        OpenItemLedgEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        OpenItemLedgEntry.SetLoadFields("Entry No.", "Cost Amount (Actual)", "Cost Amount (Expected)", "Cost Amount (Actual) (ACY)", "Cost Amount (Expected) (ACY)", "Item Ledger Entry Quantity");
        OpenItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive);
        OpenItemLedgEntry.SetRange("Item No.", Item."No.");
        OpenItemLedgEntry.SetRange(Open, true);
        OpenItemLedgEntry.SetRange(Positive, false);
        OpenItemLedgEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        OpenItemLedgEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        OpenItemLedgEntry.SetAutoCalcFields("Cost Amount (Actual)", "Cost Amount (Expected)", "Cost Amount (Actual) (ACY)", "Cost Amount (Expected) (ACY)", "Item Ledger Entry Quantity");
        OnExcludeOpenOutbndCostsOnAfterOpenItemLedgEntrySetFilters(OpenItemLedgEntry, Item);
        if OpenItemLedgEntry.FindSet() then
            repeat
                CostAmt := CostAmt - OpenItemLedgEntry."Cost Amount (Actual)" - OpenItemLedgEntry."Cost Amount (Expected)";
                CostAmtACY := CostAmtACY - OpenItemLedgEntry."Cost Amount (Actual) (ACY)" - OpenItemLedgEntry."Cost Amount (Expected) (ACY)";
                Quantity := Quantity - OpenItemLedgEntry."Item Ledger Entry Quantity";
            until OpenItemLedgEntry.Next() = 0;

        OnAfterExcludeOpenOutbndCosts(Item, CostAmt, CostAmtACY, Quantity);
    end;

    local procedure HasOpenEntries(var Item: Record Item): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ItemLedgEntry.SetCurrentKey(ItemLedgEntry."Item No.", ItemLedgEntry.Open);
        ItemLedgEntry.SetRange(ItemLedgEntry."Item No.", Item."No.");
        ItemLedgEntry.SetRange(ItemLedgEntry.Open, true);
        ItemLedgEntry.SetFilter(ItemLedgEntry."Location Code", Item.GetFilter("Location Filter"));
        ItemLedgEntry.SetFilter(ItemLedgEntry."Variant Code", Item.GetFilter("Variant Filter"));
        exit(not ItemLedgEntry.IsEmpty());
    end;

    procedure SetProperties(NewCalledFromAdjustment: Boolean; NewInvoicedQty: Decimal)
    begin
        CalledFromAdjustment := NewCalledFromAdjustment;
        InvoicedQty := NewInvoicedQty;
    end;

    local procedure GetInvtSetup()
    begin
        if not InvtSetupRead then
            InvtSetup.Get();
        InvtSetupRead := true;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
        OnAfterGetGLSetup(GLSetup);
    end;

    procedure FindUpdateUnitCostSKU(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; FilterSKU: Boolean; LastDirectCost: Decimal)
    var
        SKU: Record "Stockkeeping Unit";
    begin
        GetInvtSetup();
        SKU.SetRange("Item No.", Item."No.");
        if InvtSetup."Average Cost Calc. Type" <> InvtSetup."Average Cost Calc. Type"::Item then
            if FilterSKU then begin
                SKU.SetFilter("Location Code", '%1|%2', '', LocationCode);
                SKU.SetFilter("Variant Code", '%1|%2', '', VariantCode);
            end else begin
                SKU.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                SKU.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
            end;
        OnFindUpdateUnitCostSKUOnBeforeLoopUpdateUnitCostSKU(SKU, FilterSKU);
        if SKU.FindSet(true) then
            repeat
                UpdateUnitCostSKU(
                  Item, SKU, LastDirectCost, 0,
                  (SKU."Location Code" = LocationCode) and (SKU."Variant Code" = VariantCode), 0);
            until SKU.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateQuantity(var ValueEntry: Record "Value Entry"; var Item: Record Item; var CalcQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExcludeOpenOutbndCosts(var Item: Record Item; var CostAmt: Decimal; var CostAmtACY: Decimal; var Quantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalcStdCostItem(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var ValueEntry: Record "Value Entry"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitCostSKU(Item: Record Item; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLastAdjEntryAvgCost(var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal; var AvgCostCalculated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateCostAmount(var Item: Record Item; Actual: Boolean; var CostAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateAverageCost(var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal; var AvgCostCalculated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcUnitCostFromAverageCost(var Item: Record Item; var CostCalcMgt: Codeunit "Cost Calculation Management"; GLSetup: Record "General Ledger Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUpdateLastDirectCost(var Item: Record Item; LastDirectCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCost(var Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; LastDirectCost: Decimal; NewStdCost: Decimal; UpdateSKU: Boolean; FilterSKU: Boolean; RecalcStdCost: Boolean; CalledByFieldNo: Integer; var UnitCostUpdated: Boolean; var CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCostSKU(Item: Record Item; var SKU: Record "Stockkeeping Unit"; LastDirectCost: Decimal; NewStdCost: Decimal; MatchSKU: Boolean; CalledByFieldNo: Integer; var UnitCostUpdated: Boolean; var CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateStdCostShares(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCostFromLastDirectCost(var Item: Record Item; LastDirectCost: Decimal; InvoicedQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLastAdjEntryAvgCostOnAfterCalcAverageCost(ItemLedgEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry"; var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateAverageCostOnAfterCalcAverageQty(var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal; var AverageQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExcludeOpenOutbndCostsOnAfterOpenItemLedgEntrySetFilters(var OpenItemLedgEntry: Record "Item Ledger Entry"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnAfterCalcRunOnModifyTrigger(var Item: Record Item; var RunOnModifyTrigger: Boolean; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeNetInvoiceQtyCheck(Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeUpdateSKU(var Item: Record Item; var UpdateSKU: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeValidatePriceProfitCalculation(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostSKUOnBeforeMatchSKU(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStdCostSharesOnAfterCopyCosts(var Item: Record Item; FromItem: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitCost(var Item: Record Item; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostSKUOnBeforeCalcNonItemAvgCostCalcType(Item: Record Item; var SKU: Record "Stockkeeping Unit"; CalledFromAdjustment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindUpdateUnitCostSKUOnBeforeLoopUpdateUnitCostSKU(var SKU: Record "Stockkeeping Unit"; FilterSKU: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostSKUOnAfterSetSKUUnitCosts(var SKU: Record "Stockkeeping Unit"; var Item: Record Item; var InvoicedQty: Decimal; var LastDirectCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateAverageCostOnAfterCalculateAverage(var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculatePreciseCostAmountsOnAfterFilterOpenInboundItemLedgerEntry(OpenInbndItemLedgerEntry: Record "Item Ledger Entry"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostSKUOnBeforeCheckNegCost(var AverageCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLastAdjEntryAvgCostOnBeforeSetFilters(var ValueEntry: Record "Value Entry"; var Item: Record Item; var AverageCost: Decimal; var AverageCostACY: Decimal; var AvgCostCalculated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculatePreciseCostAmountsOnBeforeProcessOpenOutboundItemLedgerEntry(var Item: Record Item; var OpenInboundItemLedgEntry: Record "Item Ledger Entry"; var OpenOutboundItemLedgEntry: Record "Item Ledger Entry"; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculatePreciseCostAmountsOnOnBeforeProcessTempItemLedgerEntry(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var PreciseAmt: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePreciseCostAmounts(var Item: Record Item; NeedCalcPreciseAmt: Boolean; NeedCalcPreciseAmtACY: Boolean; var PreciseAmt: Decimal; var PreciseAmtACY: Decimal; var IsHandled: Boolean)
    begin
    end;
}

