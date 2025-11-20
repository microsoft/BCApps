// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;

table 5896 "Inventory Adjmt. Entry (Order)"
{
    Caption = 'Inventory Adjmt. Entry (Order)';
    Permissions = TableData "Inventory Adjmt. Entry (Order)" = i;
    LookupPageId = "Inventory Adjmt. Entry Orders";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
        }
        field(2; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(3; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(21; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
        }
        field(22; "Overhead Rate"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Overhead Rate';
        }
        field(29; "Cost is Adjusted"; Boolean)
        {
            Caption = 'Cost is Adjusted';
            InitValue = true;
        }
        field(30; "Allow Online Adjustment"; Boolean)
        {
            Caption = 'Allow Online Adjustment';
            InitValue = true;
        }
        field(41; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
        }
        field(42; "Direct Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Cost';
        }
        field(43; "Indirect Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Indirect Cost';
        }
        field(44; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Material Cost';
        }
        field(45; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Capacity Cost';
        }
        field(46; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Subcontrd. Cost';
        }
        field(47; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Cap. Ovhd Cost';
        }
        field(48; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Mfg. Ovhd Cost';
        }
        field(52; "Direct Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Direct Cost (ACY)';
        }
        field(53; "Indirect Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Indirect Cost (ACY)';
        }
        field(54; "Single-Lvl Material Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Single-Lvl Material Cost (ACY)';
        }
        field(55; "Single-Lvl Capacity Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Single-Lvl Capacity Cost (ACY)';
        }
        field(56; "Single-Lvl Subcontrd Cost(ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Single-Lvl Subcontrd Cost(ACY)';
        }
        field(57; "Single-Lvl Cap. Ovhd Cost(ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Single-Lvl Cap. Ovhd Cost(ACY)';
        }
        field(58; "Single-Lvl Mfg. Ovhd Cost(ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Single-Lvl Mfg. Ovhd Cost(ACY)';
        }
        field(61; "Completely Invoiced"; Boolean)
        {
            Caption = 'Completely Invoiced';
        }
        field(62; "Is Finished"; Boolean)
        {
            Caption = 'Is Finished';
        }
        field(70; "Direct Cost Non-Inventory"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Cost Non-Inventory';
        }
        field(71; "Direct Cost Non-Inv. (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Direct Cost Non-Inventory (ACY)';
        }
        field(72; "Single-Lvl Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Level Material Non-Inventory Cost';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the total Non-inventory material cost of all components on the parent item''s BOM.';
        }
        field(73; "Single-Lvl Mat.NonInvCost(ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Single-Level Material Non-Inventory Cost (ACY)';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Order Type", "Order No.", "Order Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Cost is Adjusted", "Allow Online Adjustment")
        {
            IncludedFields = "Is Finished";
        }
    }

    fieldgroups
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        GLSetupRead: Boolean;
        AmtRndgPrec: Decimal;
        AmtRndgPrecACY: Decimal;
        UnitAmtRndgPrec: Decimal;
        UnitAmtRndgPrecACY: Decimal;

    protected var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    procedure RoundCosts(ShareOfTotalCost: Decimal)
    begin
        GetRoundingPrecision(AmtRndgPrec, AmtRndgPrecACY);
        RoundAmounts(AmtRndgPrec, AmtRndgPrecACY, ShareOfTotalCost);
    end;

    local procedure RoundUnitCosts()
    begin
        GetUnitAmtRoundingPrecision(UnitAmtRndgPrec, UnitAmtRndgPrecACY);
        RoundAmounts(UnitAmtRndgPrec, UnitAmtRndgPrecACY, 1);
    end;

    local procedure RoundAmounts(RndPrecLCY: Decimal; RndPrecACY: Decimal; ShareOfTotalCost: Decimal)
    var
        RndResLCY: Decimal;
        RndResACY: Decimal;
    begin
        "Direct Cost" := RoundCost("Direct Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        "Indirect Cost" := RoundCost("Indirect Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        "Single-Level Material Cost" := RoundCost("Single-Level Material Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        "Single-Level Capacity Cost" := RoundCost("Single-Level Capacity Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        "Single-Level Subcontrd. Cost" := RoundCost("Single-Level Subcontrd. Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        "Single-Level Cap. Ovhd Cost" := RoundCost("Single-Level Cap. Ovhd Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
        "Single-Level Mfg. Ovhd Cost" := RoundCost("Single-Level Mfg. Ovhd Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);

        "Direct Cost (ACY)" := RoundCost("Direct Cost (ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        "Indirect Cost (ACY)" := RoundCost("Indirect Cost (ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        "Single-Lvl Material Cost (ACY)" := RoundCost("Single-Lvl Material Cost (ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        "Single-Lvl Capacity Cost (ACY)" := RoundCost("Single-Lvl Capacity Cost (ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        "Single-Lvl Subcontrd Cost(ACY)" := RoundCost("Single-Lvl Subcontrd Cost(ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        "Single-Lvl Cap. Ovhd Cost(ACY)" := RoundCost("Single-Lvl Cap. Ovhd Cost(ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        "Single-Lvl Mfg. Ovhd Cost(ACY)" := RoundCost("Single-Lvl Mfg. Ovhd Cost(ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);

        OnAfterRoundAmounts(Rec, RndPrecLCY, RndPrecACY, ShareOfTotalCost, RndResLCY, RndResACY);
    end;

    procedure CalcOvhdCost(OutputQty: Decimal)
    begin
        GetRoundingPrecision(AmtRndgPrec, AmtRndgPrecACY);

        "Single-Level Mfg. Ovhd Cost" :=
          (("Single-Level Material Cost" + "Single-Level Capacity Cost" +
            "Single-Level Subcontrd. Cost" + "Single-Level Cap. Ovhd Cost" +
            "Direct Cost Non-Inventory") *
           "Indirect Cost %" / 100) +
          ("Overhead Rate" * OutputQty);
        "Single-Level Mfg. Ovhd Cost" := Round("Single-Level Mfg. Ovhd Cost", AmtRndgPrec);

        "Single-Lvl Mfg. Ovhd Cost(ACY)" :=
          (("Single-Lvl Material Cost (ACY)" + "Single-Lvl Capacity Cost (ACY)" +
            "Single-Lvl Subcontrd Cost(ACY)" + "Single-Lvl Cap. Ovhd Cost(ACY)" +
            "Direct Cost Non-Inv. (ACY)") *
           "Indirect Cost %" / 100) +
          ("Overhead Rate" * OutputQty * CalcCurrencyFactor());
        "Single-Lvl Mfg. Ovhd Cost(ACY)" := Round("Single-Lvl Mfg. Ovhd Cost(ACY)", AmtRndgPrecACY);

        OnAfterCalcOvhdCost(xRec, Rec, GLSetup, OutputQty, AmtRndgPrec, AmtRndgPrecACY, CalcCurrencyFactor());
    end;

    procedure GetCostsFromItem(OutputQty: Decimal)
    begin
        GetUnroundedCostsFromItem();
        RoundCosts(OutputQty);
        CalcCostFromCostShares();
    end;

    procedure GetUnitCostsFromItem()
    begin
        GetUnroundedCostsFromItem();
        RoundUnitCosts();
        CalcCostFromCostShares();
    end;

    procedure GetUnitCostsFromProdOrderLine()
    begin
        GetSingleLevelCosts();
        RoundUnitCosts();
        CalcCostFromCostShares();
    end;

    local procedure GetUnroundedCostsFromItem()
    var
        Item: Record Item;
    begin
        Item.Get("Item No.");
        OnGetUnroundedCostsFromItemOnAfterGetItem(Item, Rec);

        "Indirect Cost %" := Item."Indirect Cost %";
        "Overhead Rate" := Item."Overhead Rate";

        GetSingleLevelCosts();
    end;

    local procedure GetSingleLevelCosts()
    var
        Item: Record Item;
        CurrExchRate: Decimal;
    begin
        Item.Get("Item No.");

        if not UpdatedFromSKU(Item) then begin
            "Single-Level Material Cost" := Item."Single-Level Material Cost";
            "Single-Level Capacity Cost" := Item."Single-Level Capacity Cost";
            "Single-Level Subcontrd. Cost" := Item."Single-Level Subcontrd. Cost";
            "Single-Level Cap. Ovhd Cost" := Item."Single-Level Cap. Ovhd Cost";
            "Single-Level Mfg. Ovhd Cost" := Item."Single-Level Mfg. Ovhd Cost";
            OnGetSingleLevelCostsOnAfterCopyCostsLCY(Rec, Item);
        end;

        CurrExchRate := CalcCurrencyFactor();
        "Direct Cost (ACY)" := "Direct Cost" * CurrExchRate;
        "Indirect Cost (ACY)" := "Indirect Cost" * CurrExchRate;
        "Single-Lvl Material Cost (ACY)" := "Single-Level Material Cost" * CurrExchRate;
        "Single-Lvl Capacity Cost (ACY)" := "Single-Level Capacity Cost" * CurrExchRate;
        "Single-Lvl Subcontrd Cost(ACY)" := "Single-Level Subcontrd. Cost" * CurrExchRate;
        "Single-Lvl Cap. Ovhd Cost(ACY)" := "Single-Level Cap. Ovhd Cost" * CurrExchRate;
        "Single-Lvl Mfg. Ovhd Cost(ACY)" := "Single-Level Mfg. Ovhd Cost" * CurrExchRate;
        OnGetSingleLevelCostsOnAfterCopyCostsACY(Rec, Item, CurrExchRate);

        OnAfterGetSingleLevelCosts(Rec, Item);
    end;

    local procedure UpdatedFromSKU(Item: Record Item): Boolean
    var
        SKU: Record "Stockkeeping Unit";
    begin
        if "Order Type" <> "Order Type"::Production then
            exit;

        if not Item.ShouldTryCostFromSKU() then
            exit;

        if not FindProdOrderLine(Item, SKU) then
            exit;

        "Single-Level Material Cost" := SKU."Single-Level Material Cost";
        "Single-Level Capacity Cost" := SKU."Single-Level Capacity Cost";
        "Single-Level Subcontrd. Cost" := SKU."Single-Level Subcontrd. Cost";
        "Single-Level Cap. Ovhd Cost" := SKU."Single-Level Cap. Ovhd Cost";
        "Single-Level Mfg. Ovhd Cost" := SKU."Single-Level Mfg. Ovhd Cost";
        OnUpdatedFromSKUOnAfterCopyCostFromSKU(Rec, SKU);

        exit(true);
    end;

    local procedure FindProdOrderLine(var Item: Record Item; var StockkeepingUnit: Record "Stockkeeping Unit") Found: Boolean
    begin
        OnFindProdOrderLine(Rec, Item, StockkeepingUnit, Found);
    end;

    local procedure CalcCostFromCostShares()
    begin
        CalcDirectCostFromCostShares();
        CalcIndirectCostFromCostShares();
        CalcUnitCost();
    end;

    local procedure CalcCurrencyFactor(): Decimal
    var
        OutputItemLedgEntry: Record "Item Ledger Entry";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        GetRoundingPrecision(AmtRndgPrec, AmtRndgPrecACY);
        if GLSetup."Additional Reporting Currency" <> '' then begin
            OutputItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
            OutputItemLedgEntry.SetRange("Order Type", "Order Type");
            OutputItemLedgEntry.SetRange("Order No.", "Order No.");
            if "Order Type" = "Order Type"::Production then begin
                OutputItemLedgEntry.SetRange("Order Line No.", "Order Line No.");
                OutputItemLedgEntry.SetRange("Entry Type", OutputItemLedgEntry."Entry Type"::Output);
            end else
                OutputItemLedgEntry.SetRange("Entry Type", OutputItemLedgEntry."Entry Type"::"Assembly Output");

            OnCalcCurrencyFactorOnAfterSetFilters(OutputItemLedgEntry, Rec);
            OutputItemLedgEntry.SetLoadFields("Posting Date");
            if OutputItemLedgEntry.FindLast() then
                exit(CurrExchRate.ExchangeRate(OutputItemLedgEntry."Posting Date", GLSetup."Additional Reporting Currency"));
        end;
    end;

    procedure CalcDirectCostFromCostShares()
    begin
        "Direct Cost" :=
          "Single-Level Material Cost" +
          "Single-Level Capacity Cost" +
          "Single-Level Subcontrd. Cost" +
          "Single-Level Cap. Ovhd Cost";
        "Direct Cost (ACY)" :=
          "Single-Lvl Material Cost (ACY)" +
          "Single-Lvl Capacity Cost (ACY)" +
          "Single-Lvl Subcontrd Cost(ACY)" +
          "Single-Lvl Cap. Ovhd Cost(ACY)";

        OnAfterCalcDirectCostFromCostShares(Rec);
    end;

    procedure CalcIndirectCostFromCostShares()
    begin
        "Indirect Cost" := "Single-Level Mfg. Ovhd Cost";
        "Indirect Cost (ACY)" := "Single-Lvl Mfg. Ovhd Cost(ACY)";
    end;

    procedure CalcUnitCost()
    begin
        "Unit Cost" := "Direct Cost" + "Indirect Cost";

        OnAfterCalcUnitCost(Rec);
    end;

    procedure CalcDiff(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OnlyCostShares: Boolean)
    begin
        if not OnlyCostShares then begin
            "Direct Cost" := InvtAdjmtEntryOrder."Direct Cost" - "Direct Cost";
            "Indirect Cost" := InvtAdjmtEntryOrder."Indirect Cost" - "Indirect Cost";
        end;
        "Single-Level Material Cost" := InvtAdjmtEntryOrder."Single-Level Material Cost" - "Single-Level Material Cost";
        "Single-Level Capacity Cost" := InvtAdjmtEntryOrder."Single-Level Capacity Cost" - "Single-Level Capacity Cost";
        "Single-Level Subcontrd. Cost" := InvtAdjmtEntryOrder."Single-Level Subcontrd. Cost" - "Single-Level Subcontrd. Cost";
        "Single-Level Cap. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Cap. Ovhd Cost" - "Single-Level Cap. Ovhd Cost";
        "Single-Level Mfg. Ovhd Cost" := InvtAdjmtEntryOrder."Single-Level Mfg. Ovhd Cost" - "Single-Level Mfg. Ovhd Cost";

        if not OnlyCostShares then begin
            "Direct Cost (ACY)" := InvtAdjmtEntryOrder."Direct Cost (ACY)" - "Direct Cost (ACY)";
            "Indirect Cost (ACY)" := InvtAdjmtEntryOrder."Indirect Cost (ACY)" - "Indirect Cost (ACY)";
        end;
        "Single-Lvl Material Cost (ACY)" := InvtAdjmtEntryOrder."Single-Lvl Material Cost (ACY)" - "Single-Lvl Material Cost (ACY)";
        "Single-Lvl Capacity Cost (ACY)" := InvtAdjmtEntryOrder."Single-Lvl Capacity Cost (ACY)" - "Single-Lvl Capacity Cost (ACY)";
        "Single-Lvl Subcontrd Cost(ACY)" := InvtAdjmtEntryOrder."Single-Lvl Subcontrd Cost(ACY)" - "Single-Lvl Subcontrd Cost(ACY)";
        "Single-Lvl Cap. Ovhd Cost(ACY)" := InvtAdjmtEntryOrder."Single-Lvl Cap. Ovhd Cost(ACY)" - "Single-Lvl Cap. Ovhd Cost(ACY)";
        "Single-Lvl Mfg. Ovhd Cost(ACY)" := InvtAdjmtEntryOrder."Single-Lvl Mfg. Ovhd Cost(ACY)" - "Single-Lvl Mfg. Ovhd Cost(ACY)";

        OnAfterCalcDiff(Rec, InvtAdjmtEntryOrder, OnlyCostShares);
    end;

    procedure AddDirectCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        "Direct Cost" += CostAmtLCY;
        "Direct Cost (ACY)" += CostAmtACY;
    end;

    procedure AddIndirectCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        "Indirect Cost" += CostAmtLCY;
        "Indirect Cost (ACY)" += CostAmtACY;
    end;

    procedure AddDirectCostNonInv(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        OnAddDirectCostNonInv(Rec, CostAmtLCY, COstAmtACY);
    end;

    procedure AddSingleLvlMaterialCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        OnBeforeAddSingleLvlMaterialCost(Rec, CostAmtLCY, CostAmtACY);

        "Single-Level Material Cost" += CostAmtLCY;
        "Single-Lvl Material Cost (ACY)" += CostAmtACY;

        OnAfterAddSingleLvlMaterialCost(Rec, CostAmtLCY, CostAmtACY);
    end;

    procedure AddSingleLvlNonInvMaterialCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        OnAddSingleLvlNonInvMaterialCost(Rec, CostAmtLCY, COstAmtACY);
    end;

    procedure AddSingleLvlCapacityCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        OnBeforeAddSingleLvlCapacityCost(Rec, CostAmtLCY, CostAmtACY);

        "Single-Level Capacity Cost" += CostAmtLCY;
        "Single-Lvl Capacity Cost (ACY)" += CostAmtACY;

        OnAfterAddSingleLvlCapacityCost(Rec, CostAmtLCY, CostAmtACY);
    end;

    procedure AddSingleLvlSubcontrdCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        OnBeforeAddSingleLvlSubcontrdCost(Rec, CostAmtLCY, CostAmtACY);

        "Single-Level Subcontrd. Cost" += CostAmtLCY;
        "Single-Lvl Subcontrd Cost(ACY)" += CostAmtACY;

        OnAfterAddSingleLvlSubcontrdCost(Rec, CostAmtLCY, CostAmtACY);
    end;

    procedure AddSingleLvlCapOvhdCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        OnBeforeAddSingleLvlCapOvhdCost(Rec, CostAmtLCY, CostAmtACY);

        "Single-Level Cap. Ovhd Cost" += CostAmtLCY;
        "Single-Lvl Cap. Ovhd Cost(ACY)" += CostAmtACY;

        OnAfterAddSingleLvlCapOvhdCost(Rec, CostAmtLCY, CostAmtACY);
    end;

    procedure AddSingleLvlMfgOvhdCost(CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        OnBeforeAddSingleLvlMfgOvhdCost(Rec, CostAmtLCY, CostAmtACY);

        "Single-Level Mfg. Ovhd Cost" += CostAmtLCY;
        "Single-Lvl Mfg. Ovhd Cost(ACY)" += CostAmtACY;

        OnAfterAddSingleLvlMfgOvhdCost(Rec, CostAmtLCY, CostAmtACY);
    end;

    local procedure GetRoundingPrecision(var AmtRndingPrecLCY: Decimal; var AmtRndingPrecACY: Decimal)
    var
        Currency: Record Currency;
    begin
        if not GLSetupRead then
            GLSetup.Get();
        AmtRndingPrecLCY := GLSetup."Amount Rounding Precision";
        AmtRndingPrecACY := Currency."Amount Rounding Precision";
        if GLSetup."Additional Reporting Currency" <> '' then begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.CheckAmountRoundingPrecision();
            AmtRndingPrecACY := Currency."Amount Rounding Precision"
        end;
        GLSetupRead := true;
    end;

    local procedure GetUnitAmtRoundingPrecision(var UnitAmtRndingPrecLCY: Decimal; var UnitAmtRndingPrecACY: Decimal)
    var
        Currency: Record Currency;
    begin
        if not GLSetupRead then
            GLSetup.Get();
        UnitAmtRndingPrecLCY := GLSetup."Unit-Amount Rounding Precision";
        UnitAmtRndingPrecACY := Currency."Unit-Amount Rounding Precision";
        if GLSetup."Additional Reporting Currency" <> '' then begin
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.CheckAmountRoundingPrecision();
            UnitAmtRndingPrecACY := Currency."Unit-Amount Rounding Precision"
        end;
        GLSetupRead := true;
    end;

    procedure RoundCost(Cost: Decimal; ShareOfTotal: Decimal; var RndRes: Decimal; AmtRndgPrec2: Decimal): Decimal
    var
        UnRoundedCost: Decimal;
    begin
        if Cost <> 0 then begin
            UnRoundedCost := Cost * ShareOfTotal + RndRes;
            Cost := Round(UnRoundedCost, AmtRndgPrec2);
            RndRes := UnRoundedCost - Cost;
            exit(Cost);
        end;
    end;

    procedure RunCostAdjustment(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        CostAdjustmentParameter: Record "Cost Adjustment Parameter";
        CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.";
        CostAdjustmentItemRunner: Codeunit "Cost Adjustment Item Runner";
    begin
        InventoryAdjmtEntryOrder.FindFirst();
        InventorySetup.SetLoadFields("Automatic Cost Posting");
        InventorySetup.Get();

        Item.Get(InventoryAdjmtEntryOrder."Item No.");
        Item.SetRecFilter();

        CostAdjustmentParameter."Post to G/L" := InventorySetup."Automatic Cost Posting";
        CostAdjustmentParamsMgt.SetParameters(CostAdjustmentParameter);
        CostAdjustmentParamsMgt.SetInventoryAdjmtEntryOrder(InventoryAdjmtEntryOrder);
        CostAdjustmentItemRunner.SetParameters(CostAdjustmentParamsMgt);
        CostAdjustmentItemRunner.Run(Item);

        Item.Find();
        Item.UpdateCostIsAdjusted();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcOvhdCost(xInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; GeneralLedgerSetup: Record "General Ledger Setup"; OutputQty: Decimal; AmtRndgPrec: Decimal; AmtRndgPrecACY: Decimal; CurrencyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcDiff(var InvtAdjmtEntryOrderRec: Record "Inventory Adjmt. Entry (Order)"; var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OnlyCostShares: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcDirectCostFromCostShares(var InvtAdjmtEntryOrderRec: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSingleLevelCosts(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundAmounts(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; RndPrecLCY: Decimal; RndPrecACY: Decimal; ShareOfTotalCost: Decimal; RndResLCY: Decimal; RndResACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSingleLvlMaterialCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CostAmtLCY: Decimal; var CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSingleLvlMaterialCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CostAmtLCY: Decimal; var CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSingleLvlCapacityCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CostAmtLCY: Decimal; var CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSingleLvlCapacityCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CostAmtLCY: Decimal; var CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSingleLvlSubcontrdCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CostAmtLCY: Decimal; var CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSingleLvlSubcontrdCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CostAmtLCY: Decimal; var CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSingleLvlCapOvhdCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CostAmtLCY: Decimal; var CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSingleLvlCapOvhdCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CostAmtLCY: Decimal; var CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddSingleLvlMfgOvhdCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CostAmtLCY: Decimal; var CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSingleLvlMfgOvhdCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var CostAmtLCY: Decimal; var CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCurrencyFactorOnAfterSetFilters(var OutputItemLedgEntry: Record "Item Ledger Entry"; InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnroundedCostsFromItemOnAfterGetItem(var Item: Record Item; var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSingleLevelCostsOnAfterCopyCostsLCY(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSingleLevelCostsOnAfterCopyCostsACY(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; Item: Record Item; CurrExchRate: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatedFromSKUOnAfterCopyCostFromSKU(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcUnitCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddDirectCostNonInv(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSingleLvlNonInvMaterialCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindProdOrderLine(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var Item: Record Item; var StockkeepingUnit: Record "Stockkeeping Unit"; var Found: Boolean)
    begin
    end;
}
