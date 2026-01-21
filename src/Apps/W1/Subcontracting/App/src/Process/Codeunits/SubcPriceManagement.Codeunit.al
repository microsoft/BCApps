// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

codeunit 99001508 "Subc. Price Management"
{
    var
        SubcManagementSetup: Record "Subc. Management Setup";

    procedure ApplySubcontractorPricingToProdOrderRouting(var ProdOrderLine: Record "Prod. Order Line"; var RoutingLine: Record "Routing Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        SubcontractorPrice: Record "Subcontractor Price";
        WorkCenter: Record "Work Center";
    begin
        if not SubcManagementSetup.Get() then
            exit;

        if ProdOrderRoutingLine.Type <> "Capacity Type Routing"::"Work Center" then
            exit;

        WorkCenter.Get(ProdOrderRoutingLine."Work Center No.");

        if WorkCenter."Subcontractor No." = '' then
            exit;

        SetSubcontractorPriceForPriceCalculation(
                SubcontractorPrice,
                WorkCenter."Subcontractor No.",
                ProdOrderLine."Item No.",
                ProdOrderLine."Variant Code",
                ProdOrderRoutingLine."Standard Task Code",
                WorkCenter."No.",
                ProdOrderLine."Unit of Measure Code",
                WorkDate());

        SetRoutingPriceListCost(
          SubcontractorPrice,
          WorkCenter,
          ProdOrderRoutingLine."Direct Unit Cost",
          ProdOrderRoutingLine."Indirect Cost %",
          ProdOrderRoutingLine."Overhead Rate",
          ProdOrderRoutingLine."Unit Cost per",
          ProdOrderRoutingLine."Unit Cost Calculation",
          ProdOrderLine.Quantity,
          ProdOrderLine."Qty. per Unit of Measure",
          ProdOrderLine."Quantity (Base)");
    end;

    procedure ApplySubcontractorPricingToPlanningRouting(var ReqLine: Record "Requisition Line"; var RoutingLine: Record "Routing Line"; var PlanningRoutingLine: Record "Planning Routing Line")
    var
        SubcontractorPrice: Record "Subcontractor Price";
        WorkCenter: Record "Work Center";
    begin
        if not SubcManagementSetup.Get() then
            exit;

        if RoutingLine.Type <> "Capacity Type Routing"::"Work Center" then
            exit;

        WorkCenter.Get(RoutingLine."Work Center No.");

        if WorkCenter."Subcontractor No." = '' then
            exit;

        SetSubcontractorPriceForPriceCalculation(
            SubcontractorPrice,
            WorkCenter."Subcontractor No.",
            ReqLine."No.",
            ReqLine."Variant Code",
            PlanningRoutingLine."Standard Task Code",
            WorkCenter."No.",
            ReqLine."Unit of Measure Code",
            ReqLine."Order Date");

        SetRoutingPriceListCost(
          SubcontractorPrice,
          WorkCenter,
          PlanningRoutingLine."Direct Unit Cost",
          PlanningRoutingLine."Indirect Cost %",
          PlanningRoutingLine."Overhead Rate",
          PlanningRoutingLine."Unit Cost per",
          PlanningRoutingLine."Unit Cost Calculation",
          ReqLine.Quantity,
          ReqLine."Qty. per Unit of Measure",
          ReqLine."Quantity (Base)");

        PlanningRoutingLine.Validate(PlanningRoutingLine."Direct Unit Cost");

        PlanningRoutingLine.UpdateDatetime();
    end;

    procedure CalcStandardCostOnAfterCalcRtngLineCost(RoutingLine: Record "Routing Line"; MfgItemQtyBase: Decimal; var SLSub: Decimal)
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        SingleInstanceDictionary: Codeunit "Single Instance Dictionary";
        ItemRecordID: RecordId;
        RecRef: RecordRef;
        CalculationDate: Date;
        CostTime: Decimal;
        DirectUnitCost: Decimal;
        IndirCostPct: Decimal;
        OvhdRate: Decimal;
        UnitCost: Decimal;
        UnitCostCalculationType: Enum "Unit Cost Calculation Type";
    begin
        if not SubcManagementSetup.Get() then
            exit;

        if RoutingLine.Type <> "Capacity Type Routing"::"Work Center" then
            exit;

        if RoutingLine."No." = '' then
            exit;

        WorkCenter.SetLoadFields("Subcontractor No.");
        if not WorkCenter.Get(RoutingLine."No.") then
            exit;

        if WorkCenter."Subcontractor No." = '' then
            exit;

        SingleInstanceDictionary.GetRecordID('OnBeforeCalcRoutingLineCosts', ItemRecordID);
        if ItemRecordID.TableNo() <> 0 then
            RecRef := ItemRecordID.GetRecord()
        else begin
            SingleInstanceDictionary.GetRecordID('OnCalcMfgItemOnBeforeCalcRtngCost', ItemRecordID);
            if ItemRecordID.TableNo() = 0 then
                exit;
            RecRef := ItemRecordID.GetRecord()
        end;

        RecRef.SetTable(Item);
        CalculationDate := SingleInstanceDictionary.GetDate('OnAfterSetProperties');
        if CalculationDate = 0D then
            CalculationDate := WorkDate();

        UnitCost := RoutingLine."Unit Cost per";
        CalcRtngCostPerUnit(RoutingLine."No.", DirectUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalculationType, Item, RoutingLine."Standard Task Code", CalculationDate);

        ManufacturingSetup.SetLoadFields("Cost Incl. Setup");
        ManufacturingSetup.Get();

        CostTime :=
          MfgCostCalculationMgt.CalculateCostTime(
            MfgItemQtyBase,
            RoutingLine."Setup Time", RoutingLine."Setup Time Unit of Meas. Code",
            RoutingLine."Run Time", RoutingLine."Run Time Unit of Meas. Code", RoutingLine."Lot Size",
            RoutingLine."Scrap Factor % (Accumulated)", RoutingLine."Fixed Scrap Qty. (Accum.)",
            RoutingLine."Work Center No.", UnitCostCalculationType, ManufacturingSetup."Cost Incl. Setup",
            RoutingLine."Concurrent Capacities");
        SLSub := (CostTime * DirectUnitCost);

        SingleInstanceDictionary.ClearAllDictionariesForKey('OnBeforeCalcRoutingLineCosts');
        SingleInstanceDictionary.ClearAllDictionariesForKey('OnCalcMfgItemOnBeforeCalcRtngCost');
    end;

    local procedure CalcRtngCostPerUnit(No: Code[20]; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculationType: Enum "Unit Cost Calculation Type"; Item: Record Item; StandardTaskCode: Code[10]; CalculationDate: Date)
    var
        SubContractorPrice: Record "Subcontractor Price";
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.Get(No);

        SetSubcontractorPriceForPriceCalculation(
            SubContractorPrice,
            WorkCenter."Subcontractor No.",
            Item."No.",
            '',
            StandardTaskCode,
            WorkCenter."No.",
            Item."Base Unit of Measure",
            CalculationDate);

        SetRoutingPriceListCost(
            SubContractorPrice,
            WorkCenter,
            DirUnitCost,
            IndirCostPct,
            OvhdRate,
            UnitCost,
            UnitCostCalculationType,
            1,
            1,
            1);
    end;

    procedure GetSubcPriceList(var ProdOrderRtngLine: Record "Prod. Order Routing Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
        SubcontractorPrice: Record "Subcontractor Price";
        WorkCenter: Record "Work Center";
        VendorNo: Code[20];
    begin
        if (ProdOrderRtngLine.Type <> "Capacity Type"::"Work Center") then
            exit;

        WorkCenter.Get(ProdOrderRtngLine."No.");

        if (WorkCenter."Subcontractor No." = '') and (ProdOrderRtngLine."Vendor No. Subc. Price" = '') then
            exit;

        VendorNo := WorkCenter."Subcontractor No.";
        if ProdOrderRtngLine."Vendor No. Subc. Price" <> '' then
            VendorNo := ProdOrderRtngLine."Vendor No. Subc. Price";

        GetLine(ProdOrderLine, ProdOrderRtngLine);

        SetSubcontractorPriceForPriceCalculation(
            SubcontractorPrice,
            VendorNo,
            ProdOrderLine."Item No.",
            ProdOrderLine."Variant Code",
            ProdOrderRtngLine."Standard Task Code",
            WorkCenter."No.",
            ProdOrderLine."Unit of Measure Code",
            WorkDate());

        SetRoutingPriceListCost(
            SubcontractorPrice,
            WorkCenter,
            ProdOrderRtngLine."Direct Unit Cost",
            ProdOrderRtngLine."Indirect Cost %",
            ProdOrderRtngLine."Overhead Rate",
            ProdOrderRtngLine."Unit Cost per",
            ProdOrderRtngLine."Unit Cost Calculation",
            ProdOrderLine.Quantity,
            ProdOrderLine."Qty. per Unit of Measure",
            ProdOrderLine."Quantity (Base)");
    end;

    local procedure GetLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
        ProdOrderLine.SetRange(Status, ProdOrderRtngLine.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderRtngLine."Prod. Order No.");
        ProdOrderLine.SetRange("Routing No.", ProdOrderRtngLine."Routing No.");
        ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRtngLine."Routing Reference No.");
        ProdOrderLine.FindFirst();
    end;

    procedure SetRoutingPriceListCost(var InSubcPrices: Record "Subcontractor Price"; WorkCenter: Record "Work Center"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculationType: Enum "Unit Cost Calculation Type"; QtyUoM: Decimal; ProdQtyPerUom: Decimal; QtyBase: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SubcontractorPrice: Record "Subcontractor Price";
        PriceListUOM: Code[10];
        DirectCost: Decimal;
        PriceListCost: Decimal;
        PriceListQty: Decimal;
        PriceListQtyPerUOM: Decimal;
    begin
        PriceListQtyPerUOM := 0;
        PriceListQty := 0;
        PriceListCost := 0;
        DirectCost := 0;
        PriceListUOM := '';

        UnitCostCalculationType := WorkCenter."Unit Cost Calculation";
        IndirCostPct := WorkCenter."Indirect Cost %";
        OvhdRate := WorkCenter."Overhead Rate";
        if WorkCenter."Specific Unit Cost" then
            DirUnitCost := (UnitCost - OvhdRate) / (1 + IndirCostPct / 100)
        else begin
            DirUnitCost := WorkCenter."Direct Unit Cost";
            UnitCost := WorkCenter."Unit Cost";
        end;

        if InSubcPrices."Starting Date" = 0D then
            InSubcPrices."Starting Date" := WorkDate();

        SubcontractorPrice.Reset();
        SubcontractorPrice.SetRange("Vendor No.", InSubcPrices."Vendor No.");
        SubcontractorPrice.SetFilter("Work Center No.", '%1|%2', InSubcPrices."Work Center No.", '');
        SubcontractorPrice.SetRange("Standard Task Code", InSubcPrices."Standard Task Code");
        SubcontractorPrice.SetFilter("Item No.", '%1|%2', InSubcPrices."Item No.", '');
        SubcontractorPrice.SetFilter("Variant Code", '%1|%2', InSubcPrices."Variant Code", '');
        SubcontractorPrice.SetRange("Starting Date", 0D, InSubcPrices."Starting Date");
        SubcontractorPrice.SetFilter("Ending Date", '>=%1|%2', InSubcPrices."Starting Date", 0D);
        if SubcontractorPrice.FindLast() then begin
            if SubcontractorPrice."Unit of Measure Code" = InSubcPrices."Unit of Measure Code" then begin
                PriceListQtyPerUOM := ProdQtyPerUom;
                PriceListQty := QtyUoM;
                PriceListUOM := SubcontractorPrice."Unit of Measure Code";
            end else
                GetUOMPrice(InSubcPrices."Item No.", QtyBase, SubcontractorPrice, PriceListUOM, PriceListQtyPerUOM, PriceListQty);

            GetPriceByUOM(SubcontractorPrice, PriceListQty, PriceListCost);
            if PriceListCost <> 0 then begin
                ConvertPriceToUOM(InSubcPrices."Unit of Measure Code", ProdQtyPerUom, PriceListUOM, PriceListQtyPerUOM, PriceListCost, DirectCost);
                if SubcontractorPrice."Currency Code" <> '' then
                    ConvertPriceFromCurrency(SubcontractorPrice."Currency Code", InSubcPrices."Starting Date", DirectCost);
                GeneralLedgerSetup.Get();
                DirectCost := Round(DirectCost, GeneralLedgerSetup."Unit-Amount Rounding Precision");
                DirUnitCost := DirectCost;
                UnitCost := (DirUnitCost * (1 + IndirCostPct / 100) + OvhdRate);
            end;
        end;
    end;

    local procedure GetUOMPrice(ItemNo: Code[20]; QtyBase: Decimal; SubCPrice: Record "Subcontractor Price"; var PriceListUOM: Code[10]; var PriceListQtyPerUOM: Decimal; var PriceListQty: Decimal)
    var
        Item: Record Item;
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        Item.SetLoadFields("Base Unit of Measure");
        Item.Get(ItemNo);
        PriceListQtyPerUOM := UnitofMeasureManagement.GetQtyPerUnitOfMeasure(Item, SubCPrice."Unit of Measure Code");

        if (PriceListQtyPerUOM = 1) and (SubCPrice."Unit of Measure Code" = '') then
            PriceListUOM := Item."Base Unit of Measure"
        else
            PriceListUOM := SubCPrice."Unit of Measure Code";

        PriceListQty := QtyBase / PriceListQtyPerUOM;
    end;

    local procedure GetPriceByUOM(var SubCPrice: Record "Subcontractor Price"; PriceListQty: Decimal; var PriceListCost: Decimal)
    begin
        SubCPrice.SetRange(SubCPrice."Minimum Quantity", 0, PriceListQty);
        SubCPrice.SetRange(SubCPrice."Unit of Measure Code", SubCPrice."Unit of Measure Code");
        if SubCPrice.FindLast() then begin
            PriceListCost := SubCPrice."Direct Unit Cost";
            if PriceListCost <> 0 then
                if (PriceListCost * PriceListQty) < SubCPrice."Minimum Amount" then
                    PriceListCost := SubCPrice."Minimum Amount" / PriceListQty;
        end;
    end;

    procedure ConvertPriceToUOM(ProdUOM: Code[10]; ProdQtyPerUoM: Decimal; PriceListUOM: Code[10]; PriceListQtyPerUOM: Decimal; PriceListCost: Decimal; var DirectCost: Decimal)
    begin
        if ProdUOM <> PriceListUOM then begin
            DirectCost := PriceListCost / PriceListQtyPerUOM;
            DirectCost := DirectCost * ProdQtyPerUoM;
        end else
            DirectCost := PriceListCost;
    end;

    local procedure ConvertPriceToCurrency(TargetCurrencyCode: Code[10]; PriceListCurrencyCode: Code[10]; PriceListCost: Decimal; var DirectCost: Decimal)
    var
        TargetCurrency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GeneralLedgerSetup: Record "General Ledger Setup";
        UnitAmtRngPrecision: Decimal;
    begin
        if TargetCurrencyCode = '' then begin
            GeneralLedgerSetup.SetLoadFields("Unit-Amount Rounding Precision");
            GeneralLedgerSetup.Get();
            UnitAmtRngPrecision := GeneralLedgerSetup."Unit-Amount Rounding Precision";
        end else begin
            TargetCurrency.SetLoadFields("Unit-Amount Rounding Precision");
            TargetCurrency.Get(TargetCurrencyCode);
            TargetCurrency.TestField("Unit-Amount Rounding Precision");
            UnitAmtRngPrecision := TargetCurrency."Unit-Amount Rounding Precision";
        end;

        case true of
            TargetCurrencyCode = PriceListCurrencyCode:
                DirectCost := Round(DirectCost, UnitAmtRngPrecision);
            (TargetCurrencyCode <> '') and (PriceListCurrencyCode = ''):
                DirectCost := CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                    WorkDate(), TargetCurrencyCode, PriceListCost,
                    CurrencyExchangeRate.ExchangeRate(WorkDate(), TargetCurrencyCode));
            (TargetCurrencyCode = '') and (PriceListCurrencyCode <> ''):
                DirectCost := CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    WorkDate(), PriceListCurrencyCode, PriceListCost,
                    CurrencyExchangeRate.ExchangeRate(WorkDate(), PriceListCurrencyCode));
            (TargetCurrencyCode <> '') and (PriceListCurrencyCode <> ''):
                DirectCost := CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                    WorkDate(), PriceListCurrencyCode, TargetCurrencyCode, PriceListCost);
        end;

        DirectCost := Round(DirectCost, UnitAmtRngPrecision);
    end;

    local procedure ConvertPriceFromCurrency(CurrencyCode: Code[10]; OrderDate: Date; var DirectCost: Decimal)
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Currency.Get(CurrencyCode);
        DirectCost := CurrencyExchangeRate.ExchangeAmtFCYToLCY(
            OrderDate, CurrencyCode, DirectCost,
            CurrencyExchangeRate.ExchangeRate(OrderDate, CurrencyCode));
    end;

    procedure GetSubcPriceForReqLine(var ReqLine: Record "Requisition Line"; FixedUOM: Code[10])
    var
        SubcontractorPrice: Record "Subcontractor Price";
        PriceListUOM: Code[10];
        OrderDate: Date;
        DirectCost: Decimal;
        PriceListCost: Decimal;
        PriceListQty: Decimal;
        PriceListQtyPerUOM: Decimal;
    begin
        OrderDate := ReqLine."Order Date";
        if OrderDate = 0D then
            OrderDate := WorkDate();

        SubcontractorPrice.SetRange("Vendor No.", ReqLine."Vendor No.");
        SubcontractorPrice.SetFilter("Work Center No.", '%1|%2', ReqLine."Work Center No.", '');
        SubcontractorPrice.SetRange("Standard Task Code", ReqLine."Standard Task Code");
        SubcontractorPrice.SetRange("Variant Code", ReqLine."Variant Code");
        SubcontractorPrice.SetFilter("Item No.", '%1|%2', ReqLine."No.", '');
        SubcontractorPrice.SetRange("Starting Date", 0D, OrderDate);
        SubcontractorPrice.SetFilter("Ending Date", '>=%1|%2', OrderDate, 0D);
        SubcontractorPrice.SetFilter("Currency Code", '%1|%2', ReqLine."Currency Code", '');

        if FixedUOM <> '' then
            SubcontractorPrice.SetRange("Unit of Measure Code", FixedUOM);

        if SubcontractorPrice.FindLast() then begin
            if SubcontractorPrice."Unit of Measure Code" = ReqLine."Unit of Measure Code" then begin
                PriceListQtyPerUOM := ReqLine.GetQuantityForUOM();
                PriceListQty := ReqLine.Quantity;
                PriceListUOM := ReqLine."Unit of Measure Code";
            end else
                GetUOMPrice(ReqLine."No.", ReqLine.GetQuantityBase(), SubcontractorPrice, PriceListUOM, PriceListQtyPerUOM, PriceListQty);

            GetPriceByUOM(SubcontractorPrice, PriceListQty, PriceListCost);
            if PriceListCost <> 0 then begin
                ConvertPriceToUOM(ReqLine."Unit of Measure Code", ReqLine.GetQuantityBase(), PriceListUOM, PriceListQtyPerUOM, PriceListCost, DirectCost);
                ConvertPriceToCurrency(ReqLine."Currency Code", SubcontractorPrice."Currency Code", PriceListCost, DirectCost);
            end;
            ReqLine."Direct Unit Cost" := DirectCost;
            ReqLine."Pricelist Cost" := PriceListCost;
            ReqLine."UoM for Pricelist" := PriceListUOM;
            ReqLine."Base UM Qty/PL UM Qty" := PriceListQtyPerUOM;
            if ReqLine."Base UM Qty/PL UM Qty" = 0 then
                ReqLine."Base UM Qty/PL UM Qty" := 1;
            if ReqLine."Unit of Measure Code" = ReqLine."UoM for Pricelist" then
                ReqLine."PL UM Qty/Base UM Qty" := ReqLine.Quantity
            else
                ReqLine."PL UM Qty/Base UM Qty" := ReqLine.GetQuantityBase() / ReqLine."Base UM Qty/PL UM Qty";
            if ReqLine."PL UM Qty/Base UM Qty" = 0 then
                ReqLine."PL UM Qty/Base UM Qty" := 1;
        end;
    end;

    procedure GetSubcPriceForPurchLine(var PurchLine: Record "Purchase Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcontractorPrice: Record "Subcontractor Price";
        PriceListUOM: Code[10];
        OrderDate: Date;
        DirectCost, PriceListCost, PriceListQty, PriceListQtyPerUOM : Decimal;
    begin
        OrderDate := PurchLine."Order Date";
        if OrderDate = 0D then
            OrderDate := WorkDate();

        SubcontractorPrice.SetRange("Vendor No.", PurchLine."Buy-from Vendor No.");
        SubcontractorPrice.SetFilter("Work Center No.", '%1|%2', PurchLine."Work Center No.", '');
        SubcontractorPrice.SetRange("Variant Code", PurchLine."Variant Code");
        SubcontractorPrice.SetFilter("Item No.", '%1|%2', PurchLine."No.", '');

        GetProdOrderRtngLine(PurchLine."Prod. Order No.", PurchLine."Routing Reference No.", PurchLine."Routing No.", PurchLine."Operation No.", ProdOrderRoutingLine);

        SubcontractorPrice.SetFilter("Standard Task Code", '%1|%2', ProdOrderRoutingLine."Standard Task Code", '');
        SubcontractorPrice.SetRange("Starting Date", 0D, OrderDate);
        SubcontractorPrice.SetFilter("Ending Date", '>=%1|%2', OrderDate, 0D);
        SubcontractorPrice.SetFilter("Currency Code", '%1|%2', PurchLine."Currency Code", '');
        SubcontractorPrice.SetFilter("Unit of Measure Code", '%1|%2', PurchLine."Unit of Measure Code", '');

        if SubcontractorPrice.FindLast() then begin
            if SubcontractorPrice."Unit of Measure Code" = PurchLine."Unit of Measure Code" then
                PriceListUOM := SubcontractorPrice."Unit of Measure Code";
            GetUOMPrice(PurchLine."No.", GetQuantityBase(PurchLine), SubcontractorPrice, PriceListUOM, PriceListQtyPerUOM, PriceListQty);
            GetPriceByUOM(SubcontractorPrice, PriceListQty, PriceListCost);
            if PriceListCost <> 0 then begin
                ConvertPriceToUOM(PurchLine."Unit of Measure Code", PurchLine.GetQuantityPerUOM(), PriceListUOM, PriceListQtyPerUOM, PriceListCost, DirectCost);
                ConvertPriceToCurrency(PurchLine."Currency Code", SubcontractorPrice."Currency Code", PriceListCost, DirectCost)
            end;
        end else begin
            GetUOMPrice(PurchLine."No.", PurchLine.GetQuantityBase(), SubcontractorPrice, PriceListUOM, PriceListQtyPerUOM, PriceListQty);
            ProdOrderRoutingLine.TestField(Type, "Capacity Type"::"Work Center");
            DirectCost := ProdOrderRoutingLine."Direct Unit Cost";
        end;

        PurchLine."Direct Unit Cost" := DirectCost;
        PurchLine.Validate("Line Discount %");
    end;

    local procedure GetProdOrderRtngLine(ProdOrderNo: Code[20]; RtngRefNo: Integer; RoutingNo: Code[20]; OperationNo: Code[10]; var ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
        ProdOrderRtngLine.SetFilter(Status, '%1|%2', ProdOrderRtngLine.Status::Released, ProdOrderRtngLine.Status::Finished);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRtngLine.SetRange("Routing Reference No.", RtngRefNo);
        ProdOrderRtngLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRtngLine.SetRange("Operation No.", OperationNo);

        ProdOrderRtngLine.FindFirst();
    end;

    local procedure SetSubcontractorPriceForPriceCalculation(var SubcontractorPrice: Record "Subcontractor Price"; VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; StandardTaskCode: Code[10]; WorkCenterNo: Code[20]; UoM: Code[10]; StartingDate: Date)
    begin
        SubcontractorPrice."Vendor No." := VendorNo;
        SubcontractorPrice."Item No." := ItemNo;
        SubcontractorPrice."Standard Task Code" := StandardTaskCode;
        SubcontractorPrice."Work Center No." := WorkCenterNo;
        SubcontractorPrice."Variant Code" := VariantCode;
        SubcontractorPrice."Unit of Measure Code" := UoM;
        SubcontractorPrice."Starting Date" := StartingDate;
        SubcontractorPrice."Currency Code" := '';
    end;

    local procedure GetQuantityBase(var PurchLine: Record "Purchase Line"): Decimal
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitofMeasure.Get(PurchLine."No.", PurchLine."Unit of Measure Code");
        exit(Round(PurchLine.Quantity * ItemUnitofMeasure."Qty. per Unit of Measure", 0.00001));
    end;
}