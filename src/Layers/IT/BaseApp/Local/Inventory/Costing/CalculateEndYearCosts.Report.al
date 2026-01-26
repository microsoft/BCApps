// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Foundation.Period;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

report 12115 "Calculate End Year Costs"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Calculate Year Costs';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("Low-Level Code") order(descending);

            trigger OnAfterGetRecord()
            var
                NewBand: Boolean;
                ClosedBy: Integer;
                TotalBandQty: Decimal;
            begin
                NewQuantity := 0;
                NotInvAmtForEstWIP := 0;
                NotInvAmtForWIP := 0;
                ExpectedCostExist := false;
                StartDateLIFO := 0D;
                ItemCostingSetup.Get();
                InitItemCostHistory();
                SetFilter("Date Filter", '%1..%2', StartingDate, ReferenceDate);
                CalcFields("Net Change");
                if "Inventory Valuation" = "Inventory Valuation"::"Discrete LIFO" then begin
                    if "Net Change" <> 0 then
                        DoDistribution(NewBand, "Net Change", TotalBandQty)
                    else
                        NewBand := true;
                    if ItemLedgEntryExist() then
                        // Exist at least one entry in selected period
                        if NewBand then
                            NewLIFOBand(ClosedBy)
                        else
                            DoAbsorbtion(TotalBandQty);
                    UpdateDiscLIFOCost();
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ReferenceDate; ReferenceDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reference Date';
                        ToolTip = 'Specifies the reference date.';
                    }
                    field(Definitive; DefinitiveCosts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Definitive';
                        ToolTip = 'Specifies the definitive.';
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

    trigger OnPostReport()
    begin
        Window.Close();
    end;

    trigger OnPreReport()
    var
        AccountingPeriod: Record "Accounting Period";
        LIFOBand: Record "Lifo Band";
        LIFOBand2: Record "Lifo Band";
        LIFOBand3: Record "Lifo Band";
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
        LastFiscalYearEndDate: Date;
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
    begin
        ItemCostingSetup.Get();
        LowLevelCodeCalculator.Calculate(false);

        if ReferenceDate = 0D then
            Error(Text005);

        AccountingPeriod.Reset();
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetFilter("Starting Date", '<=%1', ReferenceDate);
        AccountingPeriod.Find('+');
        FiscalYearStartDate := AccountingPeriod."Starting Date";
        LastFiscalYearEndDate := AccountingPeriod."Starting Date" - 1;
        StartingDate := FiscalYearStartDate;

        AccountingPeriod.Reset();
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod."Starting Date" := FiscalYearStartDate;
        AccountingPeriod.Find();
        if AccountingPeriod.Next() <> 0 then
            FiscalYearEndDate := AccountingPeriod."Starting Date" - 1
        else
            FiscalYearEndDate := CalcDate('<12M-1D>', FiscalYearStartDate);
        if not ((ReferenceDate >= FiscalYearStartDate) and (ReferenceDate <= FiscalYearEndDate)) then
            Error(Text009, ReferenceDate);

        SetItemCostHistFilter(ReferenceDate, '>=%1', true);
        if ItemCostHistory.FindLast() then
            Error(Text008, Date2DMY(ItemCostHistory."Competence Year", 3), Date2DMY(ReferenceDate, 3));

        SetItemCostHistFilter(LastFiscalYearEndDate, '<=%1', false);
        if ItemCostHistory.FindFirst() then
            Error(Text007, Date2DMY(LastFiscalYearEndDate, 3));

        SetItemCostHistFilter(LastFiscalYearEndDate, '<=%1', false);
        if ItemCostHistory.FindLast() then
            if ItemCostHistory."Competence Year" <> LastFiscalYearEndDate then
                Error(Text007, Date2DMY(LastFiscalYearEndDate, 3));

        if DefinitiveCosts and
           (ReferenceDate <> FiscalYearEndDate)
        then
            Error(Text006, FiscalYearEndDate);

        ItemCostHistory.Reset();
        ItemCostHistory.SetRange("Competence Year", FiscalYearStartDate, FiscalYearEndDate);
        ItemCostHistory.SetRange(Definitive, false);
        ItemCostHistory.DeleteAll();

        LIFOBand.Reset();
        LIFOBand.SetRange(Definitive, false);
        if LIFOBand.FindSet() then
            repeat
                if not LIFOBand.Positive then
                    if LIFOBand2.Get(LIFOBand."Closed by Entry No.") then begin
                        LIFOBand2."Absorbed Quantity" := LIFOBand2."Absorbed Quantity" + LIFOBand."Increment Quantity";
                        LIFOBand2."Residual Quantity" := LIFOBand2."Increment Quantity" - LIFOBand2."Absorbed Quantity";
                        LIFOBand2."Increment Value" := LIFOBand2."Increment Value" - LIFOBand."Increment Value";
                        LIFOBand3.Reset();
                        LIFOBand3.SetRange(Definitive, true);
                        LIFOBand3.SetRange("Closed by Entry No.", LIFOBand2."Entry No.");
                        if LIFOBand3.FindLast() then
                            LIFOBand2."Closed by Entry No." := LIFOBand3."Entry No."
                        else
                            LIFOBand2."Closed by Entry No." := 0;
                        LIFOBand2.Modify();
                    end;
            until LIFOBand.Next() = 0;

        LIFOBand.Reset();
        LIFOBand.SetRange(Definitive, false);
        LIFOBand.DeleteAll();

        LIFOBand.Reset();
        NextEntryNo := LIFOBand.GetLastEntryNo() + 1;
        Window.Open(ProgressBarTxt);
    end;

    var
        ItemCostingSetup: Record "Item Costing Setup";
        ItemCostHistory: Record "Item Cost History";
        ItemLedgEntry: Record "Item Ledger Entry";
        Window: Dialog;
        DefinitiveCosts: Boolean;
        ExpectedCostExist: Boolean;
        NextEntryNo: Integer;
        NewQuantity: Decimal;
        NotInvAmtForEstWIP: Decimal;
        NotInvAmtForWIP: Decimal;
        ReferenceDate: Date;
        StartingDate: Date;
        StartDateLIFO: Date;
        ProgressBarTxt: Label 'Calculating Costs....\Item No.       #2##########\LIFO Category  #3##########\Level            #4######';
        Text005: Label 'The reference date cannot be blank. Please insert a date.';
        Text006: Label 'Data cannot be defined as Definitive. Reference date must be %1.';
        Text007: Label 'Previous Year %1 data must be defined as definitive first.';
        Text008: Label 'Data for Year %1 has already been defined as Final. You cannot calculate/recalculate data for Year %2.';
        Text009: Label 'No Accounting Period for reference date %1.';

    [Scope('OnPrem')]
    procedure InitItemCostHistory()
    begin
        Window.Update(2, StrSubstNo('%1', Item."No."));
        Window.Update(3, StrSubstNo('%1', Item."Lifo Category"));
        Window.Update(4, StrSubstNo('%1', Item."Low-Level Code"));

        ItemCostHistory.Init();
        ItemCostHistory."Item No." := Item."No.";
        ItemCostHistory.Description := Item.Description;
        ItemCostHistory."Competence Year" := ReferenceDate;
        ItemCostHistory.Description := Item.Description;
        ItemCostHistory."Base Unit of Measure" := Item."Base Unit of Measure";
        ItemCostHistory."Inventory Valuation" := Item."Inventory Valuation";
        ItemCostHistory."Start Year Inventory" := CalcStartYearInv();
        ItemCostHistory."End Year Inventory" := CalcEndYearInv();
        if Item."Replenishment System" = Item."Replenishment System"::Purchase then begin
            InitPurchFields();
            if ItemCostHistory."Purchase Quantity" <> 0 then
                ItemCostHistory."Year Average Cost" := ItemCostHistory."Purchase Amount" / ItemCostHistory."Purchase Quantity";
            ItemCostHistory."FIFO Cost" := CalcPurchFIFOCost();
            ItemCostHistory."LIFO Cost" := CalcPurchLIFOCost();
        end else
            if Item."Replenishment System" = Item."Replenishment System"::"Prod. Order" then begin
                ItemCostHistory."Components Valuation" := ItemCostingSetup."Components Valuation";
                ItemCostHistory."Estimated WIP Consumption" := ItemCostingSetup."Estimated WIP Consumption";
                InitProdFields();
                if ItemCostHistory."Production Quantity" <> 0 then
                    ItemCostHistory."Year Average Cost" := ItemCostHistory."Production Amount" / ItemCostHistory."Production Quantity";
                ItemCostHistory."LIFO Cost" := CalcProdLIFOCost();
            end;
        ItemCostHistory."Weighted Average Cost" := CalcWeighAvgCost();
        ItemCostHistory.Definitive := DefinitiveCosts;
        ItemCostHistory."Expected Cost Exist" := ExpectedCostExist;
        ItemCostHistory.Insert();
    end;

    [Scope('OnPrem')]
    procedure CalcStartYearInv(): Decimal
    begin
        SetItemLedgerEntryFilters(ItemLedgEntry, 0D, StartingDate - 1, '<>%1', ItemLedgEntry."Entry Type"::Transfer);
        ItemLedgEntry.CalcSums(Quantity);
        exit(ItemLedgEntry.Quantity);
    end;

    [Scope('OnPrem')]
    procedure CalcEndYearInv(): Decimal
    var
        EndYearInv: Decimal;
    begin
        SetItemLedgerEntryFilters(ItemLedgEntry, 0D, ReferenceDate, '<>%1', ItemLedgEntry."Entry Type"::Transfer);
        if ItemLedgEntry.FindSet() then
            repeat
                EndYearInv += ItemLedgEntry.Quantity;
                if EndYearInv <= 0 then
                    StartDateLIFO := ItemLedgEntry."Posting Date";
            until ItemLedgEntry.Next() = 0;
        exit(EndYearInv);
    end;

    [Scope('OnPrem')]
    procedure InitPurchFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitPurchFields(ItemCostHistory, IsHandled);
        if IsHandled then
            exit;

        GetBefStartItemQtyAndCost(ItemCostHistory."Purchase Quantity", ItemCostHistory."Purchase Amount");
        SetItemLedgerEntryFilters(ItemLedgEntry, StartingDate, ReferenceDate, '%1', ItemLedgEntry."Entry Type"::Purchase);
        IsHandled := false;
        OnInitPurchFieldsOnAfterSetItemLedgerEntryFilters(ItemCostHistory, ItemLedgEntry, IsHandled);
        if IsHandled then
            exit;
        if ItemLedgEntry.FindSet() then
            repeat
                ItemLedgEntry.CalcFields("Purchase Amount (Expected)", "Purchase Amount (Actual)");
                ItemCostHistory."Purchase Amount" += ItemLedgEntry."Purchase Amount (Actual)" + ItemLedgEntry."Purchase Amount (Expected)";
                ItemCostHistory."Purchase Quantity" += ItemLedgEntry.Quantity;
            until ItemLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CalcPurchFIFOCost(): Decimal
    var
        BefStartItemCost: Record "Before Start Item Cost";
        ItemCostHistPrevYear: Record "Item Cost History";
        FIFOCost: Decimal;
        EndYearInv: Decimal;
        PurchAmt: Decimal;
    begin
        EndYearInv := ItemCostHistory."End Year Inventory";
        SetItemLedgerEntryFilters(ItemLedgEntry, StartingDate, ReferenceDate, '%1', ItemLedgEntry."Entry Type"::Purchase);
        if ItemLedgEntry.FindLast() then
            repeat
                PurchAmt := GetPurchAmt(ItemLedgEntry);
                CalcCosts(false, EndYearInv, FIFOCost, ItemLedgEntry.Quantity, PurchAmt);
                UpdateExpCostExist(ItemLedgEntry."Posting Date", StartingDate);
            until (EndYearInv <= 0) or (ItemLedgEntry.Next(-1) = 0);
        if EndYearInv > 0 then begin
            SetBefStItemFilters(BefStartItemCost, 0D, ReferenceDate);
            if BefStartItemCost.FindSet() then
                repeat
                    CalcCosts(
                      false, EndYearInv, FIFOCost, BefStartItemCost."Purchase Quantity",
                      BefStartItemCost."Purchase Amount");
                    UpdateExpCostExist(BefStartItemCost."Starting Date", StartingDate);
                until (BefStartItemCost.Next() = 0) or (EndYearInv <= 0);
        end;
        if EndYearInv > 0 then
            if ItemCostHistPrevYear.Get(Item."No.", CalcDate('<-1Y>', ReferenceDate)) then
                CalcCosts(
                  false, EndYearInv, FIFOCost, ItemCostHistPrevYear."End Year Inventory",
                  ItemCostHistPrevYear."End Year Inventory" * ItemCostHistPrevYear."FIFO Cost");
        if EndYearInv > 0 then
            FIFOCost += (PurchAmt / ItemLedgEntry.Quantity) * EndYearInv;
        if ItemCostHistory."End Year Inventory" <> 0 then
            FIFOCost := FIFOCost / ItemCostHistory."End Year Inventory";
        exit(FIFOCost);
    end;

    [Scope('OnPrem')]
    procedure CalcPurchLIFOCost(): Decimal
    var
        BefStartItemCost: Record "Before Start Item Cost";
        ItemCostHistPrevYear: Record "Item Cost History";
        StartDate: Date;
        EndYearInv: Decimal;
        LIFOCost: Decimal;
        PurchAmt: Decimal;
    begin
        EndYearInv := ItemCostHistory."End Year Inventory";
        if EndYearInv > 0 then
            if ItemCostHistPrevYear.Get(Item."No.", CalcDate('<-1Y>', ReferenceDate)) then
                CalcCosts(
                  false, EndYearInv, LIFOCost, ItemCostHistPrevYear."End Year Inventory",
                  ItemCostHistPrevYear."End Year Inventory" * ItemCostHistPrevYear."LIFO Cost");

        if StartDateLIFO <> 0D then begin
            StartDate := StartDateLIFO;
            SetBefStItemFilters(BefStartItemCost, StartDate, ReferenceDate);
        end else begin
            StartDate := StartingDate;
            SetBefStItemFilters(BefStartItemCost, 0D, ReferenceDate);
        end;

        if EndYearInv > 0 then
            if BefStartItemCost.FindSet() then
                repeat
                    CalcCosts(
                      false, EndYearInv, LIFOCost, BefStartItemCost."Purchase Quantity",
                      BefStartItemCost."Purchase Amount");
                    UpdateExpCostExist(BefStartItemCost."Starting Date", StartingDate);
                until (BefStartItemCost.Next() = 0) or (EndYearInv <= 0);

        if EndYearInv > 0 then begin
            SetItemLedgerEntryFilters(ItemLedgEntry, StartDate, ReferenceDate, '%1', ItemLedgEntry."Entry Type"::Purchase);
            if ItemLedgEntry.FindSet() then
                repeat
                    PurchAmt := GetPurchAmt(ItemLedgEntry);
                    CalcCosts(true, EndYearInv, LIFOCost, ItemLedgEntry.Quantity, PurchAmt);
                until (EndYearInv <= 0) or (ItemLedgEntry.Next() = 0);
        end;
        if ItemCostHistory."End Year Inventory" <> 0 then
            LIFOCost := LIFOCost / ItemCostHistory."End Year Inventory";
        exit(LIFOCost);
    end;

    [Scope('OnPrem')]
    procedure InitProdFields()
    var
        BefStartItemCost: Record "Before Start Item Cost";
        ItemCostHistPrevYear: Record "Item Cost History";
        EndYearInv: Decimal;
        FIFOCost: Decimal;
        ProdAmt: Decimal;
    begin
        EndYearInv := ItemCostHistory."End Year Inventory";
        GetBefStartItemQtyAndCost(ItemCostHistory."Production Quantity", ItemCostHistory."Production Amount");
        SetItemLedgerEntryFilters(ItemLedgEntry, StartingDate, ReferenceDate, '%1', ItemLedgEntry."Entry Type"::Output);
        if ItemLedgEntry.FindLast() then
            repeat
                ItemCostHistory."Production Quantity" += ItemLedgEntry.Quantity;
                ProdAmt := GetProdAmt(ItemLedgEntry, true);
                if EndYearInv > 0 then
                    if ItemLedgEntry.Quantity <> 0 then
                        CalcCosts(false, EndYearInv, FIFOCost, ItemLedgEntry.Quantity, ProdAmt);
            until ItemLedgEntry.Next(-1) = 0;
        if EndYearInv > 0 then begin
            SetBefStItemFilters(BefStartItemCost, 0D, ReferenceDate);
            if BefStartItemCost.FindSet() then
                repeat
                    CalcCosts(
                      false, EndYearInv, FIFOCost, BefStartItemCost."Production Quantity",
                      BefStartItemCost."Production Amount");
                until (BefStartItemCost.Next() = 0) or (EndYearInv <= 0);
        end;
        if EndYearInv > 0 then
            if ItemCostHistPrevYear.Get(Item."No.", CalcDate('<-1Y>', ReferenceDate)) then
                CalcCosts(
                  false, EndYearInv, FIFOCost, ItemCostHistPrevYear."End Year Inventory",
                  ItemCostHistPrevYear."End Year Inventory" * ItemCostHistPrevYear."FIFO Cost");
        if EndYearInv > 0 then
            FIFOCost += (ProdAmt / ItemLedgEntry.Quantity) * EndYearInv;
        if ItemCostHistory."End Year Inventory" <> 0 then
            ItemCostHistory."FIFO Cost" := FIFOCost / ItemCostHistory."End Year Inventory";
        ItemCostHistory."Production Amount" +=
          ItemCostHistory."Direct Components Amount" + ItemCostHistory."Direct Routing Amount" +
          ItemCostHistory."Overhead Routing Amount" + ItemCostHistory."Subcontracted Amount";
    end;

    [Scope('OnPrem')]
    procedure CalcProdLIFOCost(): Decimal
    var
        BefStartItemCost: Record "Before Start Item Cost";
        ItemCostHistPrevYear: Record "Item Cost History";
        EndYearInv: Decimal;
        LIFOCost: Decimal;
        ProdAmt: Decimal;
        StartDate: Date;
    begin
        EndYearInv := ItemCostHistory."End Year Inventory";
        if EndYearInv > 0 then
            if ItemCostHistPrevYear.Get(Item."No.", CalcDate('<-1Y>', ReferenceDate)) then
                CalcCosts(
                  false, EndYearInv, LIFOCost, ItemCostHistPrevYear."End Year Inventory",
                  ItemCostHistPrevYear."End Year Inventory" * ItemCostHistPrevYear."LIFO Cost");

        if StartDateLIFO <> 0D then begin
            StartDate := StartDateLIFO;
            SetBefStItemFilters(BefStartItemCost, StartDate, ReferenceDate);
        end else begin
            StartDate := StartingDate;
            SetBefStItemFilters(BefStartItemCost, 0D, ReferenceDate);
        end;

        if EndYearInv > 0 then
            if BefStartItemCost.FindSet() then
                repeat
                    CalcCosts(
                      false, EndYearInv, LIFOCost, BefStartItemCost."Production Quantity",
                      BefStartItemCost."Production Amount");
                    UpdateExpCostExist(BefStartItemCost."Starting Date", StartingDate);
                until (BefStartItemCost.Next() = 0) or (EndYearInv <= 0);

        if EndYearInv > 0 then begin
            SetItemLedgerEntryFilters(ItemLedgEntry, StartDate, ReferenceDate, '%1', ItemLedgEntry."Entry Type"::Output);
            if ItemLedgEntry.FindSet() then
                repeat
                    ProdAmt := GetProdAmt(ItemLedgEntry, true);
                    CalcCosts(true, EndYearInv, LIFOCost, ItemLedgEntry.Quantity, ProdAmt);
                until (EndYearInv <= 0) or (ItemLedgEntry.Next() = 0);
        end;
        if ItemCostHistory."End Year Inventory" <> 0 then
            LIFOCost := LIFOCost / ItemCostHistory."End Year Inventory";
        exit(LIFOCost);
    end;

    [Scope('OnPrem')]
    procedure UpdateEstimatedCosts(ProdOrderLine: Record "Prod. Order Line"; UpdateItemCostHistory: Boolean): Decimal
    var
        WorkCenter: Record "Work Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrdRoutingLine: Record "Prod. Order Routing Line";
        ItemCostHistory2: Record "Item Cost History";
        Subcontracted: Boolean;
        ItemCompCost: Decimal;
        DirectRtgAmt: Decimal;
        OverheadRtgAmt: Decimal;
        SubconAmt: Decimal;
        TotCompAmt: Decimal;
        TotRoutingAmt: Decimal;
        ProdAmt: Decimal;
    begin
        ProdOrderComp.Reset();
        ProdOrderComp.SetCurrentKey("Prod. Order No.", "Prod. Order Line No.");
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        if ProdOrderComp.FindSet() then
            repeat
                if ItemCostHistory2.Get(ProdOrderComp."Item No.", ReferenceDate) then
                    ItemCompCost +=
                      Abs(ProdOrderComp."Expected Quantity") *
                      ItemCostHistory2.GetCompCost(ItemCostingSetup."Components Valuation");
            until ProdOrderComp.Next() = 0;
        TotCompAmt := ItemCompCost * ProdOrderLine."Finished Quantity" / ProdOrderLine.Quantity;
        if not ItemLedgEntry."Completely Invoiced" then
            NotInvAmtForEstWIP += TotCompAmt;
        ProdOrdRoutingLine.Reset();
        ProdOrdRoutingLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.");
        ProdOrdRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrdRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrdRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Line No.");
        if ProdOrdRoutingLine.FindSet() then
            repeat
                if ProdOrdRoutingLine.Type = ProdOrdRoutingLine.Type::"Work Center" then begin
                    WorkCenter.Get(ProdOrdRoutingLine."No.");
                    Subcontracted := WorkCenter."Subcontractor No." <> '';
                end;
                if not Subcontracted then begin
                    DirectRtgAmt += ProdOrdRoutingLine."Expected Operation Cost Amt.";
                    OverheadRtgAmt += ProdOrdRoutingLine."Expected Capacity Ovhd. Cost";
                end else
                    SubconAmt += ProdOrdRoutingLine."Expected Operation Cost Amt." + ProdOrdRoutingLine."Expected Capacity Ovhd. Cost";
            until ProdOrdRoutingLine.Next() = 0;
        if UpdateItemCostHistory then begin
            ItemCostHistory."Direct Components Amount" += ItemCompCost * ProdOrderLine."Finished Quantity" / ProdOrderLine.Quantity;
            ItemCostHistory."Direct Routing Amount" += (DirectRtgAmt * ProdOrderLine."Finished Quantity") / ProdOrderLine.Quantity;
            ItemCostHistory."Overhead Routing Amount" += OverheadRtgAmt * ProdOrderLine."Finished Quantity" / ProdOrderLine.Quantity;
            ItemCostHistory."Subcontracted Amount" += (SubconAmt * ProdOrderLine."Finished Quantity") / ProdOrderLine.Quantity;
        end;
        TotRoutingAmt :=
          ((DirectRtgAmt + OverheadRtgAmt + SubconAmt) *
           ProdOrderLine."Finished Quantity") / ProdOrderLine.Quantity;
        ProdAmt := TotCompAmt + TotRoutingAmt;
        if not ItemLedgEntry."Completely Invoiced" then
            NotInvAmtForEstWIP += TotRoutingAmt;
        exit(ProdAmt);
    end;

    [Scope('OnPrem')]
    procedure CalcWeighAvgCost(): Decimal
    var
        ItemCostHistory2: Record "Item Cost History";
        WeighAvgCost: Decimal;
        InvWeighCost: Decimal;
        EndYearInv: Decimal;
    begin
        if ItemCostHistory2.Get(Item."No.", CalcDate('<-1Y>', ReferenceDate)) then begin
            InvWeighCost := ItemCostHistory2."Weighted Average Cost" * ItemCostHistory2."End Year Inventory";
            EndYearInv := ItemCostHistory2."End Year Inventory";
            if Item."Replenishment System" = Item."Replenishment System"::Purchase then begin
                if (ItemCostHistory."Purchase Quantity" + EndYearInv) <> 0 then
                    WeighAvgCost :=
                      (InvWeighCost + ItemCostHistory."Purchase Amount") / (ItemCostHistory."Purchase Quantity" + EndYearInv);
            end else
                if (ItemCostHistory."Production Quantity" + ItemCostHistory2."End Year Inventory") <> 0 then
                    WeighAvgCost :=
                      (InvWeighCost + ItemCostHistory."Production Amount") / (ItemCostHistory."Production Quantity" + EndYearInv);
        end else
            WeighAvgCost := ItemCostHistory."Year Average Cost";
        exit(WeighAvgCost);
    end;

    [Scope('OnPrem')]
    procedure GetAdjCosts(var TotInvoicedQty: Decimal; var TotInvoicedAmt: Decimal; var NotInvoicedQty: Decimal; var NotInvoicedAmt: Decimal)
    var
        ValueEntry: Record "Value Entry";
        TotalUnitPerCost: Decimal;
        BefStItemCostQty: Decimal;
        BefStItemCostAmt: Decimal;
        InvoicedQty: Decimal;
        InvoicedAmount: Decimal;
    begin
        GetBefStartItemQtyAndCost(BefStItemCostQty, BefStItemCostAmt);
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", "Posting Date", "Location Code");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetRange("Posting Date", StartingDate, ReferenceDate);
        if ItemLedgEntry.FindSet() then begin
            repeat
                if ItemLedgEntry."Entry Type" in [ItemLedgEntry."Entry Type"::Purchase, ItemLedgEntry."Entry Type"::Output] then begin
                    ValueEntry.Reset();
                    ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                    ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
                    ValueEntry.SetFilter("Item Ledger Entry Type", '<>%1', ValueEntry."Item Ledger Entry Type"::Transfer);
                    if ValueEntry.FindSet() then
                        repeat
                            InvoicedAmount := InvoicedAmount + ValueEntry."Cost Amount (Actual)";
                        until ValueEntry.Next() = 0;
                    InvoicedQty := InvoicedQty + ItemLedgEntry."Invoiced Quantity";
                    if not ItemLedgEntry."Completely Invoiced" then begin
                        TotalUnitPerCost := 0;
                        ValueEntry.SetRange("Entry Type");
                        if ValueEntry.FindSet() then
                            repeat
                                TotalUnitPerCost := TotalUnitPerCost + ValueEntry."Cost per Unit";
                            until ValueEntry.Next() = 0;
                        NotInvoicedAmt := NotInvoicedAmt + TotalUnitPerCost * (ItemLedgEntry.Quantity - ItemLedgEntry."Invoiced Quantity");
                        NotInvoicedQty := NotInvoicedQty + (ItemLedgEntry.Quantity - ItemLedgEntry."Invoiced Quantity");
                    end;
                end;
            until ItemLedgEntry.Next() = 0;
            TotInvoicedQty := InvoicedQty + BefStItemCostQty;
            TotInvoicedAmt := InvoicedAmount + BefStItemCostAmt;
        end;
    end;

    [Scope('OnPrem')]
    procedure NewLIFOBand(ClosedBy: Integer)
    var
        LIFOBand: Record "Lifo Band";
        LinkedLIFOBand: Record "Lifo Band";
        TotInvoicedQty: Decimal;
        TotInvoicedAmt: Decimal;
        NotInvoicedQty: Decimal;
        NotInvoicedAmt: Decimal;
    begin
        GetAdjCosts(TotInvoicedQty, TotInvoicedAmt, NotInvoicedQty, NotInvoicedAmt);
        ItemCostingSetup.Get();
        ItemCostHistory.Get(Item."No.", ReferenceDate);
        LIFOBand.Init();
        LIFOBand."Entry No." := NextEntryNo;
        LIFOBand."Item No." := Item."No.";
        LIFOBand."Lifo Category" := Item."Lifo Category";
        LIFOBand."Competence Year" := ReferenceDate;
        LIFOBand.Validate("Increment Quantity", NewQuantity);
        LIFOBand."Absorbed Quantity" := 0;
        LIFOBand.Validate(CMP, ItemCostHistory."Weighted Average Cost");
        LIFOBand.Positive := LIFOBand."Increment Quantity" > 0;
        if LIFOBand.Positive then
            LIFOBand.Validate("Year Average Cost", ItemCostHistory."Year Average Cost")
        else
            if LinkedLIFOBand.Get(ClosedBy) then
                LIFOBand.Validate("Year Average Cost", LinkedLIFOBand."Year Average Cost");
        LIFOBand.Definitive := DefinitiveCosts;
        LIFOBand."Qty not Invoiced" := NotInvoicedQty;
        if Item."Replenishment System" = Item."Replenishment System"::Purchase then
            LIFOBand."Amount not Invoiced" := NotInvoicedAmt
        else
            if not ItemCostingSetup."Estimated WIP Consumption" then
                LIFOBand."Amount not Invoiced" := NotInvAmtForWIP
            else
                LIFOBand."Amount not Invoiced" := NotInvAmtForEstWIP;
        LIFOBand."Closed by Entry No." := ClosedBy;
        LIFOBand."Invoiced Quantity" := TotInvoicedQty;
        if Item."Replenishment System" = Item."Replenishment System"::Purchase then
            LIFOBand."Invoiced Amount" := TotInvoicedAmt
        else
            if not ItemCostingSetup."Estimated WIP Consumption" then
                LIFOBand."Invoiced Amount" := ItemCostHistory."Production Amount" - NotInvAmtForWIP
            else
                LIFOBand."Invoiced Amount" := ItemCostHistory."Production Amount" - NotInvAmtForEstWIP;
        LIFOBand."User ID" := UserId;
        LIFOBand.Insert();
        NextEntryNo := NextEntryNo + 1;
    end;

    [Scope('OnPrem')]
    procedure UpdateDiscLIFOCost()
    var
        LIFOBand: Record "Lifo Band";
        ItemCostHistory2: Record "Item Cost History";
        LIFOAmount: Decimal;
    begin
        LIFOBand.Reset();
        LIFOBand.SetRange("Item No.", Item."No.");
        if LIFOBand.FindSet() then
            repeat
                if LIFOBand."Residual Quantity" > 0 then
                    LIFOAmount += LIFOBand."Year Average Cost" * LIFOBand."Residual Quantity";
                UpdateExpCostExist(LIFOBand."Competence Year", StartingDate);
            until LIFOBand.Next() = 0;

        if ItemCostHistory2.Get(Item."No.", ReferenceDate) then
            if ItemCostHistory2."End Year Inventory" <> 0 then begin
                ItemCostHistory2."Discrete LIFO Cost" := LIFOAmount / ItemCostHistory2."End Year Inventory";
                ItemCostHistory2."Expected Cost Exist" := ExpectedCostExist;
                ItemCostHistory2.Modify();
            end;
    end;

    [Scope('OnPrem')]
    procedure DoAbsorbtion(TotalBandQty: Decimal)
    var
        LIFOBand: Record "Lifo Band";
        QtyToAbsorbe: Decimal;
    begin
        QtyToAbsorbe := TotalBandQty - (TotalBandQty + Item."Net Change");
        LIFOBand.Reset();
        LIFOBand.SetRange("Item No.", Item."No.");
        LIFOBand.SetRange(Positive, true);
        LIFOBand.SetFilter("Residual Quantity", '<>0');
        if LIFOBand.Find('+') then
            repeat
                if QtyToAbsorbe > LIFOBand."Residual Quantity" then begin
                    NewQuantity := -LIFOBand."Residual Quantity";
                    QtyToAbsorbe := QtyToAbsorbe - LIFOBand."Residual Quantity";
                    LIFOBand.Validate("Absorbed Quantity", (LIFOBand."Absorbed Quantity" + LIFOBand."Residual Quantity"));
                end else begin
                    LIFOBand.Validate("Absorbed Quantity", LIFOBand."Absorbed Quantity" + QtyToAbsorbe);
                    NewQuantity := -QtyToAbsorbe;
                    QtyToAbsorbe := 0;
                end;
                LIFOBand."Closed by Entry No." := NextEntryNo;
                NewLIFOBand(LIFOBand."Entry No.");
                LIFOBand.Modify();
            until (QtyToAbsorbe = 0) or (LIFOBand.Next(-1) = 0);
    end;

    [Scope('OnPrem')]
    procedure DoDistribution(var NewBand: Boolean; Quantity: Decimal; TotalBandQty: Decimal): Boolean
    var
        LIFOBand: Record "Lifo Band";
    begin
        LIFOBand.SetRange("Item No.", Item."No.");
        LIFOBand.SetRange(Positive, true);
        LIFOBand.SetFilter("Residual Quantity", '<>0');
        if LIFOBand.FindSet() then
            repeat
                TotalBandQty := TotalBandQty + LIFOBand."Residual Quantity";
            until LIFOBand.Next() = 0;
        NewBand := (TotalBandQty + Quantity) > TotalBandQty;
        NewQuantity := Quantity;
    end;

    [Scope('OnPrem')]
    procedure GetRoutingCost(var DirectRtgAmt: Decimal; var OverheadRtgAmt: Decimal; var SubconAmt: Decimal)
    var
        PurchLine: Record "Purchase Line";
        CapacityLedgEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgEntry.Reset();
        CapacityLedgEntry.SetCurrentKey("Item No.", "Order Type", "Order No.");
        CapacityLedgEntry.SetRange("Item No.", Item."No.");
        CapacityLedgEntry.SetRange("Order Type", CapacityLedgEntry."Order Type"::Production);
        CapacityLedgEntry.SetRange("Order No.", ItemLedgEntry."Order No.");
        if not ItemCostingSetup."Estimated WIP Consumption" then
            CapacityLedgEntry.SetRange("Posting Date", StartingDate, ReferenceDate);
        if CapacityLedgEntry.FindSet() then
            repeat
                CapacityLedgEntry.CalcFields("Direct Cost", "Overhead Cost");
                if CapacityLedgEntry."Direct Cost" <> 0 then begin
                    if not CapacityLedgEntry.Subcontracting then
                        DirectRtgAmt += CapacityLedgEntry."Direct Cost"
                    else
                        SubconAmt += (CapacityLedgEntry."Direct Cost" + CapacityLedgEntry."Overhead Cost");
                end else begin
                    PurchLine.Reset();
                    PurchLine.SetRange("Prod. Order No.", CapacityLedgEntry."Order No.");
                    PurchLine.SetRange("No.", CapacityLedgEntry."Item No.");
                    if PurchLine.FindFirst() then
                        if not CapacityLedgEntry.Subcontracting then
                            DirectRtgAmt += CapacityLedgEntry.Quantity * PurchLine."Direct Unit Cost"
                        else
                            SubconAmt += (CapacityLedgEntry.Quantity * PurchLine."Direct Unit Cost") + CapacityLedgEntry."Overhead Cost";
                end;
                OverheadRtgAmt += CapacityLedgEntry."Overhead Cost";
                UpdateExpCostExist(CapacityLedgEntry."Posting Date", StartingDate);
            until CapacityLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CalcCosts(CalcLIFO: Boolean; var EndYearInv: Decimal; var Cost: Decimal; Qty: Decimal; Amt: Decimal)
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        UnitCost: Decimal;
    begin
        if Qty <> 0 then
            UnitCost := Amt / Qty;
        if CalcLIFO then begin
            ItemLedgEntry2.Copy(ItemLedgEntry);
            if (Qty < EndYearInv) and (ItemLedgEntry2.Next() <> 0) then
                Cost += UnitCost * Qty
            else
                Cost += UnitCost * EndYearInv;
        end else
            if Qty <= EndYearInv then
                Cost += UnitCost * Qty
            else
                Cost += UnitCost * EndYearInv;
        EndYearInv -= Qty;
    end;

    [Scope('OnPrem')]
    procedure UpdateExpCostExist(PostingDate: Date; StartingDate: Date)
    begin
        ExpectedCostExist := ItemCostingSetup."Estimated WIP Consumption" and (PostingDate < StartingDate);
    end;

    [Scope('OnPrem')]
    procedure GetBefStartItemQtyAndCost(var BefStItemQty: Decimal; var BefStItemCost: Decimal)
    var
        BefStartItemCost: Record "Before Start Item Cost";
    begin
        SetBefStItemFilters(BefStartItemCost, StartingDate, ReferenceDate);
        BefStartItemCost.CalcSums("Purchase Quantity", "Production Quantity", "Purchase Amount", "Production Amount");
        BefStItemQty += (BefStartItemCost."Purchase Quantity" + BefStartItemCost."Production Quantity");
        BefStItemCost += (BefStartItemCost."Purchase Amount" + BefStartItemCost."Production Amount");
    end;

    [Scope('OnPrem')]
    procedure SetBefStItemFilters(var BefStartItemCost: Record "Before Start Item Cost"; StartDate: Date; EndDate: Date)
    begin
        BefStartItemCost.Reset();
        BefStartItemCost.SetRange("Item No.", Item."No.");
        BefStartItemCost.SetRange("Starting Date", StartDate, EndDate);
    end;

    [Scope('OnPrem')]
    procedure SetItemLedgerEntryFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; StartDate: Date; EndDate: Date; FilterTxt: Text[5]; EntryType: Enum "Item Ledger Entry Type")
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", "Posting Date");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetRange("Posting Date", StartDate, EndDate);
        ItemLedgEntry.SetFilter("Entry Type", FilterTxt, EntryType);
    end;

    [Scope('OnPrem')]
    procedure ItemLedgEntryExist(): Boolean
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", "Posting Date", "Location Code");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetRange("Posting Date", StartingDate, ReferenceDate);
        exit(ItemLedgEntry.FindFirst());
    end;

    [Scope('OnPrem')]
    procedure SetStartDateAndRefDate(CompetenceYear: Date)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        ReferenceDate := CompetenceYear;
        AccountingPeriod.Reset();
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetFilter("Starting Date", '<=%1', ReferenceDate);
        AccountingPeriod.FindLast();
        StartingDate := AccountingPeriod."Starting Date";
    end;

    [Scope('OnPrem')]
    procedure GetComponentCost(): Decimal
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        ItemCostHistory2: Record "Item Cost History";
        ItemCompCost: Decimal;
    begin
        ItemLedgEntry2.Reset();
        ItemLedgEntry2.SetCurrentKey("Entry Type", "Order Type", "Order No.", "Posting Date", "Source No.");
        ItemLedgEntry2.SetRange("Entry Type", ItemLedgEntry2."Entry Type"::Consumption);
        ItemLedgEntry2.SetRange("Order Type", ItemLedgEntry2."Order Type"::Production);
        ItemLedgEntry2.SetRange("Order No.", ItemLedgEntry."Order No.");

        ItemLedgEntry2.SetRange("Source No.", Item."No.");
        if not ItemCostingSetup."Estimated WIP Consumption" then
            ItemLedgEntry2.SetRange("Posting Date", StartingDate, ReferenceDate);
        if ItemLedgEntry2.FindSet() then
            repeat
                if ItemCostHistory2.Get(ItemLedgEntry2."Item No.", ReferenceDate) then
                    ItemCompCost +=
                      Abs(ItemLedgEntry2.Quantity) *
                      ItemCostHistory2.GetCompCost(ItemCostingSetup."Components Valuation");
                UpdateExpCostExist(ItemLedgEntry2."Posting Date", StartingDate);
            until ItemLedgEntry2.Next() = 0;
        exit(ItemCompCost);
    end;

    [Scope('OnPrem')]
    procedure UpdateCosts(UpdateItemCostHistory: Boolean): Decimal
    var
        ProdOrdOutput: Decimal;
        ItemCompCost: Decimal;
        DirectRtgAmt: Decimal;
        OverheadRtgAmt: Decimal;
        SubconAmt: Decimal;
        QtyNotInvoiced: Decimal;
        ProdAmt: Decimal;
        IsHandled: Boolean;
    begin
        ProdOrdOutput := GetProdOrderOutput();

        IsHandled := false;
        OnUpdateCostsOnAfterGetProdOrdOutput(ProdOrdOutput, IsHandled, ProdAmt);
        if IsHandled then
            exit(ProdAmt);

        ItemCompCost := GetComponentCost();
        GetRoutingCost(DirectRtgAmt, SubconAmt, OverheadRtgAmt);
        ProdAmt := (ItemCompCost + DirectRtgAmt + OverheadRtgAmt + SubconAmt) * ItemLedgEntry.Quantity / ProdOrdOutput;
        if UpdateItemCostHistory then begin
            ItemCostHistory."Direct Components Amount" += ItemCompCost * ItemLedgEntry.Quantity / ProdOrdOutput;
            ItemCostHistory."Subcontracted Amount" += SubconAmt * ItemLedgEntry.Quantity / ProdOrdOutput;
            ItemCostHistory."Direct Routing Amount" += DirectRtgAmt * ItemLedgEntry.Quantity / ProdOrdOutput;
            ItemCostHistory."Overhead Routing Amount" += OverheadRtgAmt * ItemLedgEntry.Quantity / ProdOrdOutput;
        end;
        if not ItemLedgEntry."Completely Invoiced" then begin
            QtyNotInvoiced := ItemLedgEntry.Quantity - ItemLedgEntry."Invoiced Quantity";
            NotInvAmtForWIP += ((ItemCompCost + DirectRtgAmt + OverheadRtgAmt + SubconAmt) * QtyNotInvoiced) / ProdOrdOutput;
        end;
        exit(ProdAmt);
    end;

    [Scope('OnPrem')]
    procedure GetProdOrderOutput(): Decimal
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        ProdOrdOutput: Decimal;
    begin
        ItemLedgEntry2.Reset();
        ItemLedgEntry2.SetCurrentKey("Item No.", "Entry Type");
        ItemLedgEntry2.SetRange("Item No.", ItemLedgEntry."Item No.");
        ItemLedgEntry2.SetRange("Entry Type", ItemLedgEntry2."Entry Type"::Output);
        if ItemCostingSetup."Estimated WIP Consumption" then begin
            ItemLedgEntry2.SetRange("Order Type", ItemLedgEntry2."Order Type"::Production);
            ItemLedgEntry2.SetRange("Order No.", ItemLedgEntry."Order No.");
        end else
            ItemLedgEntry2.SetRange("Posting Date", StartingDate, ReferenceDate);
        if ItemLedgEntry2.FindSet() then
            repeat
                if not ItemCostingSetup."Estimated WIP Consumption" then begin
                    if (ItemLedgEntry2."Item No." = ItemLedgEntry."Item No.") and
                       (ItemLedgEntry2."Order No." = ItemLedgEntry."Order No.")
                    then
                        ProdOrdOutput += ItemLedgEntry2.Quantity
                end else
                    ProdOrdOutput += ItemLedgEntry2.Quantity
            until ItemLedgEntry2.Next() = 0;
        exit(ProdOrdOutput)
    end;

    [Scope('OnPrem')]
    procedure GetPurchAmt(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    begin
        ItemLedgEntry.CalcFields("Purchase Amount (Expected)", "Purchase Amount (Actual)");
        exit(ItemLedgEntry."Purchase Amount (Expected)" + ItemLedgEntry."Purchase Amount (Actual)");
    end;

    [Scope('OnPrem')]
    procedure GetProdAmt(ItemLedgEntry2: Record "Item Ledger Entry"; UpdateItemCostHistory: Boolean): Decimal
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdAmt: Decimal;
    begin
        if not UpdateItemCostHistory then begin
            ItemCostingSetup.Get();
            ItemLedgEntry.Copy(ItemLedgEntry2);
            Item.Get(ItemLedgEntry2."Item No.");
        end;
        if ItemCostingSetup."Estimated WIP Consumption" then begin
            ProdOrderLine.Reset();
            ProdOrderLine.SetCurrentKey("Prod. Order No.", "Line No.");
            ProdOrderLine.SetRange("Prod. Order No.", ItemLedgEntry2."Order No.");
            ProdOrderLine.SetRange("Line No.", ItemLedgEntry2."Order Line No.");
            if ProdOrderLine.FindFirst() then
                if (ProdOrderLine.Status = ProdOrderLine.Status::Finished) or
                   (ProdOrderLine."Finished Quantity" >= ProdOrderLine.Quantity)
                then
                    ProdAmt := UpdateCosts(UpdateItemCostHistory)
                else
                    ProdAmt := UpdateEstimatedCosts(ProdOrderLine, UpdateItemCostHistory);
        end else
            ProdAmt := UpdateCosts(UpdateItemCostHistory);
        exit(ProdAmt);
    end;

    [Scope('OnPrem')]
    procedure SetItemCostHistFilter(CompYearDate: Date; FilterTxt: Text[4]; Def: Boolean)
    begin
        ItemCostHistory.Reset();
        ItemCostHistory.SetFilter("Competence Year", FilterTxt, CompYearDate);
        ItemCostHistory.SetRange(Definitive, Def);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPurchFields(var ItemCostHistory: Record "Item Cost History"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitPurchFieldsOnAfterSetItemLedgerEntryFilters(var ItemCostHistory: Record "Item Cost History"; var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCostsOnAfterGetProdOrdOutput(ProdOrdOutput: Decimal; var IsHandled: Boolean; var ProdAmt: Decimal)
    begin
    end;
}

