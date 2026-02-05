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

    procedure ApplySubcontractorPricingToPlanningRouting(var RequisitionLine: Record "Requisition Line"; var RoutingLine: Record "Routing Line"; var PlanningRoutingLine: Record "Planning Routing Line")
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
            RequisitionLine."No.",
            RequisitionLine."Variant Code",
            PlanningRoutingLine."Standard Task Code",
            WorkCenter."No.",
            RequisitionLine."Unit of Measure Code",
            RequisitionLine."Order Date");

        SetRoutingPriceListCost(
          SubcontractorPrice,
          WorkCenter,
          PlanningRoutingLine."Direct Unit Cost",
          PlanningRoutingLine."Indirect Cost %",
          PlanningRoutingLine."Overhead Rate",
          PlanningRoutingLine."Unit Cost per",
          PlanningRoutingLine."Unit Cost Calculation",
          RequisitionLine.Quantity,
          RequisitionLine."Qty. per Unit of Measure",
          RequisitionLine."Quantity (Base)");

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

    procedure GetSubcPriceList(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
        SubcontractorPrice: Record "Subcontractor Price";
        WorkCenter: Record "Work Center";
        VendorNo: Code[20];
    begin
        if (ProdOrderRoutingLine.Type <> "Capacity Type"::"Work Center") then
            exit;

        WorkCenter.Get(ProdOrderRoutingLine."No.");

        if (WorkCenter."Subcontractor No." = '') and (ProdOrderRoutingLine."Vendor No. Subc. Price" = '') then
            exit;

        VendorNo := WorkCenter."Subcontractor No.";
        if ProdOrderRoutingLine."Vendor No. Subc. Price" <> '' then
            VendorNo := ProdOrderRoutingLine."Vendor No. Subc. Price";

        GetLine(ProdOrderLine, ProdOrderRoutingLine);

        SetSubcontractorPriceForPriceCalculation(
            SubcontractorPrice,
            VendorNo,
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

    local procedure GetLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        ProdOrderLine.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderLine.FindFirst();
    end;

    procedure SetRoutingPriceListCost(var InSubcontractorPrice: Record "Subcontractor Price"; WorkCenter: Record "Work Center"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculationType: Enum "Unit Cost Calculation Type"; QtyUoM: Decimal; ProdQtyPerUom: Decimal; QtyBase: Decimal)
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

        if InSubcontractorPrice."Starting Date" = 0D then
            InSubcontractorPrice."Starting Date" := WorkDate();

        SubcontractorPrice.Reset();
        SubcontractorPrice.SetRange("Vendor No.", InSubcontractorPrice."Vendor No.");
        SubcontractorPrice.SetFilter("Work Center No.", '%1|%2', InSubcontractorPrice."Work Center No.", '');
        SubcontractorPrice.SetRange("Standard Task Code", InSubcontractorPrice."Standard Task Code");
        SubcontractorPrice.SetFilter("Item No.", '%1|%2', InSubcontractorPrice."Item No.", '');
        SubcontractorPrice.SetFilter("Variant Code", '%1|%2', InSubcontractorPrice."Variant Code", '');
        SubcontractorPrice.SetRange("Starting Date", 0D, InSubcontractorPrice."Starting Date");
        SubcontractorPrice.SetFilter("Ending Date", '>=%1|%2', InSubcontractorPrice."Starting Date", 0D);
        if SubcontractorPrice.FindLast() then begin
            if SubcontractorPrice."Unit of Measure Code" = InSubcontractorPrice."Unit of Measure Code" then begin
                PriceListQtyPerUOM := ProdQtyPerUom;
                PriceListQty := QtyUoM;
                PriceListUOM := SubcontractorPrice."Unit of Measure Code";
            end else
                GetUOMPrice(InSubcontractorPrice."Item No.", QtyBase, SubcontractorPrice, PriceListUOM, PriceListQtyPerUOM, PriceListQty);

            GetPriceByUOM(SubcontractorPrice, PriceListQty, PriceListCost);
            if PriceListCost <> 0 then begin
                ConvertPriceToUOM(InSubcontractorPrice."Unit of Measure Code", ProdQtyPerUom, PriceListUOM, PriceListQtyPerUOM, PriceListCost, DirectCost);
                if SubcontractorPrice."Currency Code" <> '' then
                    ConvertPriceFromCurrency(SubcontractorPrice."Currency Code", InSubcontractorPrice."Starting Date", DirectCost);
                GeneralLedgerSetup.Get();
                DirectCost := Round(DirectCost, GeneralLedgerSetup."Unit-Amount Rounding Precision");
                DirUnitCost := DirectCost;
                UnitCost := (DirUnitCost * (1 + IndirCostPct / 100) + OvhdRate);
            end;
        end;
    end;

    local procedure GetUOMPrice(ItemNo: Code[20]; QtyBase: Decimal; SubcontractorPrice: Record "Subcontractor Price"; var PriceListUOM: Code[10]; var PriceListQtyPerUOM: Decimal; var PriceListQty: Decimal)
    var
        Item: Record Item;
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        Item.SetLoadFields("Base Unit of Measure");
        Item.Get(ItemNo);
        PriceListQtyPerUOM := UnitofMeasureManagement.GetQtyPerUnitOfMeasure(Item, SubcontractorPrice."Unit of Measure Code");

        if (PriceListQtyPerUOM = 1) and (SubcontractorPrice."Unit of Measure Code" = '') then
            PriceListUOM := Item."Base Unit of Measure"
        else
            PriceListUOM := SubcontractorPrice."Unit of Measure Code";

        PriceListQty := QtyBase / PriceListQtyPerUOM;
    end;

    local procedure GetPriceByUOM(var SubcontractorPrice: Record "Subcontractor Price"; PriceListQty: Decimal; var PriceListCost: Decimal)
    begin
        SubcontractorPrice.SetRange(SubcontractorPrice."Minimum Quantity", 0, PriceListQty);
        SubcontractorPrice.SetRange(SubcontractorPrice."Unit of Measure Code", SubcontractorPrice."Unit of Measure Code");
        if SubcontractorPrice.FindLast() then begin
            PriceListCost := SubcontractorPrice."Direct Unit Cost";
            if PriceListCost <> 0 then
                if (PriceListCost * PriceListQty) < SubcontractorPrice."Minimum Amount" then
                    PriceListCost := SubcontractorPrice."Minimum Amount" / PriceListQty;
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
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GeneralLedgerSetup: Record "General Ledger Setup";
        UnitAmtRngPrecision: Decimal;
    begin
        if TargetCurrencyCode = '' then begin
            GeneralLedgerSetup.SetLoadFields("Unit-Amount Rounding Precision");
            GeneralLedgerSetup.Get();
            UnitAmtRngPrecision := GeneralLedgerSetup."Unit-Amount Rounding Precision";
        end else begin
            Currency.SetLoadFields("Unit-Amount Rounding Precision");
            Currency.Get(TargetCurrencyCode);
            Currency.TestField("Unit-Amount Rounding Precision");
            UnitAmtRngPrecision := Currency."Unit-Amount Rounding Precision";
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

    procedure GetSubcPriceForReqLine(var RequisitionLine: Record "Requisition Line"; FixedUOM: Code[10])
    var
        SubcontractorPrice: Record "Subcontractor Price";
        PriceListUOM: Code[10];
        OrderDate: Date;
        DirectCost: Decimal;
        PriceListCost: Decimal;
        PriceListQty: Decimal;
        PriceListQtyPerUOM: Decimal;
    begin
        OrderDate := RequisitionLine."Order Date";
        if OrderDate = 0D then
            OrderDate := WorkDate();

        SubcontractorPrice.SetRange("Vendor No.", RequisitionLine."Vendor No.");
        SubcontractorPrice.SetFilter("Work Center No.", '%1|%2', RequisitionLine."Work Center No.", '');
        SubcontractorPrice.SetRange("Standard Task Code", RequisitionLine."Standard Task Code");
        SubcontractorPrice.SetRange("Variant Code", RequisitionLine."Variant Code");
        SubcontractorPrice.SetFilter("Item No.", '%1|%2', RequisitionLine."No.", '');
        SubcontractorPrice.SetRange("Starting Date", 0D, OrderDate);
        SubcontractorPrice.SetFilter("Ending Date", '>=%1|%2', OrderDate, 0D);
        SubcontractorPrice.SetFilter("Currency Code", '%1|%2', RequisitionLine."Currency Code", '');

        if FixedUOM <> '' then
            SubcontractorPrice.SetRange("Unit of Measure Code", FixedUOM);

        if SubcontractorPrice.FindLast() then begin
            if SubcontractorPrice."Unit of Measure Code" = RequisitionLine."Unit of Measure Code" then begin
                PriceListQtyPerUOM := RequisitionLine.GetQuantityForUOM();
                PriceListQty := RequisitionLine.Quantity;
                PriceListUOM := RequisitionLine."Unit of Measure Code";
            end else
                GetUOMPrice(RequisitionLine."No.", RequisitionLine.GetQuantityBase(), SubcontractorPrice, PriceListUOM, PriceListQtyPerUOM, PriceListQty);

            GetPriceByUOM(SubcontractorPrice, PriceListQty, PriceListCost);
            if PriceListCost <> 0 then begin
                ConvertPriceToUOM(RequisitionLine."Unit of Measure Code", RequisitionLine.GetQuantityBase(), PriceListUOM, PriceListQtyPerUOM, PriceListCost, DirectCost);
                ConvertPriceToCurrency(RequisitionLine."Currency Code", SubcontractorPrice."Currency Code", PriceListCost, DirectCost);
            end;
            RequisitionLine."Direct Unit Cost" := DirectCost;
            RequisitionLine."Pricelist Cost" := PriceListCost;
            RequisitionLine."UoM for Pricelist" := PriceListUOM;
            RequisitionLine."Base UM Qty/PL UM Qty" := PriceListQtyPerUOM;
            if RequisitionLine."Base UM Qty/PL UM Qty" = 0 then
                RequisitionLine."Base UM Qty/PL UM Qty" := 1;
            if RequisitionLine."Unit of Measure Code" = RequisitionLine."UoM for Pricelist" then
                RequisitionLine."PL UM Qty/Base UM Qty" := RequisitionLine.Quantity
            else
                RequisitionLine."PL UM Qty/Base UM Qty" := RequisitionLine.GetQuantityBase() / RequisitionLine."Base UM Qty/PL UM Qty";
            if RequisitionLine."PL UM Qty/Base UM Qty" = 0 then
                RequisitionLine."PL UM Qty/Base UM Qty" := 1;
        end;
    end;

    procedure GetSubcPriceForPurchLine(var PurchaseLine: Record "Purchase Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcontractorPrice: Record "Subcontractor Price";
        PriceListUOM: Code[10];
        OrderDate: Date;
        DirectCost, PriceListCost, PriceListQty, PriceListQtyPerUOM : Decimal;
    begin
        OrderDate := PurchaseLine."Order Date";
        if OrderDate = 0D then
            OrderDate := WorkDate();

        SubcontractorPrice.SetRange("Vendor No.", PurchaseLine."Buy-from Vendor No.");
        SubcontractorPrice.SetFilter("Work Center No.", '%1|%2', PurchaseLine."Work Center No.", '');
        SubcontractorPrice.SetRange("Variant Code", PurchaseLine."Variant Code");
        SubcontractorPrice.SetFilter("Item No.", '%1|%2', PurchaseLine."No.", '');

        GetProdOrderRtngLine(PurchaseLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.", ProdOrderRoutingLine);

        SubcontractorPrice.SetFilter("Standard Task Code", '%1|%2', ProdOrderRoutingLine."Standard Task Code", '');
        SubcontractorPrice.SetRange("Starting Date", 0D, OrderDate);
        SubcontractorPrice.SetFilter("Ending Date", '>=%1|%2', OrderDate, 0D);
        SubcontractorPrice.SetFilter("Currency Code", '%1|%2', PurchaseLine."Currency Code", '');
        SubcontractorPrice.SetFilter("Unit of Measure Code", '%1|%2', PurchaseLine."Unit of Measure Code", '');

        if SubcontractorPrice.FindLast() then begin
            if SubcontractorPrice."Unit of Measure Code" = PurchaseLine."Unit of Measure Code" then
                PriceListUOM := SubcontractorPrice."Unit of Measure Code";
            GetUOMPrice(PurchaseLine."No.", GetQuantityBase(PurchaseLine), SubcontractorPrice, PriceListUOM, PriceListQtyPerUOM, PriceListQty);
            GetPriceByUOM(SubcontractorPrice, PriceListQty, PriceListCost);
            if PriceListCost <> 0 then begin
                ConvertPriceToUOM(PurchaseLine."Unit of Measure Code", PurchaseLine.GetQuantityPerUOM(), PriceListUOM, PriceListQtyPerUOM, PriceListCost, DirectCost);
                ConvertPriceToCurrency(PurchaseLine."Currency Code", SubcontractorPrice."Currency Code", PriceListCost, DirectCost)
            end;
        end else begin
            GetUOMPrice(PurchaseLine."No.", PurchaseLine.GetQuantityBase(), SubcontractorPrice, PriceListUOM, PriceListQtyPerUOM, PriceListQty);
            ProdOrderRoutingLine.TestField(Type, "Capacity Type"::"Work Center");
            DirectCost := ProdOrderRoutingLine."Direct Unit Cost";
        end;

        PurchaseLine."Direct Unit Cost" := DirectCost;
        PurchaseLine.Validate("Line Discount %");
    end;

    local procedure GetProdOrderRtngLine(ProdOrderNo: Code[20]; RtngRefNo: Integer; RoutingNo: Code[20]; OperationNo: Code[10]; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        ProdOrderRoutingLine.SetFilter(Status, '%1|%2', ProdOrderRoutingLine.Status::Released, ProdOrderRoutingLine.Status::Finished);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", RtngRefNo);
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);

        ProdOrderRoutingLine.FindFirst();
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

    local procedure GetQuantityBase(var PurchaseLine: Record "Purchase Line"): Decimal
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitofMeasure.Get(PurchaseLine."No.", PurchaseLine."Unit of Measure Code");
        exit(Round(PurchaseLine.Quantity * ItemUnitofMeasure."Qty. per Unit of Measure", 0.00001));
    end;
}