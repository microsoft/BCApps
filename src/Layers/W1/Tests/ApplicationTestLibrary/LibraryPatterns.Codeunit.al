/// <summary>
/// Provides utility functions implementing common test patterns for inventory, purchase, and sales scenarios.
/// </summary>
codeunit 132212 "Library - Patterns"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        TXTIncorrectEntry: Label 'Incorrect %1 in Entry No. %2.';
        TXTUnexpectedLine: Label 'Unexpected line after getting posted line to reverse.';
        TXTLineCountMismatch: Label 'Line count mismatch in revaluation for Item %1.';

    procedure POSTItemJournalLineWithApplication(TemplateType: Enum "Item Journal Template Type"; EntryType: Enum "Item Ledger Entry Type"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitAmount: Decimal; AppltoEntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, TemplateType);
        LibraryInventory.CreateItemJournalLineWithApplication(
          ItemJournalLine, ItemJournalBatch, Item, LocationCode, VariantCode, PostingDate, EntryType, Qty, UnitAmount, AppltoEntryNo);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTNegativeAdjustmentWithItemTracking(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; SerialNo: Code[50]; LotNo: Code[50])
    var
        ReservEntry: Record "Reservation Entry";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, LocationCode, VariantCode, PostingDate,
          ItemJournalLine."Entry Type"::"Negative Adjmt.", Qty, 0);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, SerialNo, LotNo, Qty);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTNegativeAdjustmentAmount(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; Amount: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, LocationCode, VariantCode, PostingDate,
          ItemJournalLine."Entry Type"::"Negative Adjmt.", Qty, 0);
        ItemJournalLine.Validate(Amount, Amount);
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure POSTPositiveAdjustmentAmount(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; Amount: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, LocationCode, VariantCode, PostingDate,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Qty, 0);
        ItemJournalLine.Validate(Amount, Amount);
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure SETInventorySetup(AutomaticCostAdjustment: Option; AvgCostCalcType: Option; AvgCostPeriod: Option)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := false;
        InventorySetup."Expected Cost Posting to G/L" := false;
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Validate("Average Cost Calc. Type", AvgCostCalcType);
        InventorySetup.Validate("Average Cost Period", AvgCostPeriod);
        InventorySetup.Modify();
    end;

    procedure SETNoSeries()
    var
        InventorySetup: Record "Inventory Setup";
#if not CLEAN27
#pragma warning disable AL0801
        ManufacturingSetup: Record "Manufacturing Setup";
#pragma warning restore AL0801
#endif
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        MarketingSetup: Record "Marketing Setup";
        NoSeries: Code[20];
    begin
        NoSeries := LibraryUtility.GetGlobalNoSeriesCode();

        InventorySetup.Get();
        if InventorySetup."Item Nos." <> NoSeries then begin
            InventorySetup.Validate("Item Nos.", NoSeries);
            InventorySetup.Modify();
        end;
        if InventorySetup."Transfer Order Nos." <> NoSeries then begin
            InventorySetup.Validate("Transfer Order Nos.", NoSeries);
            InventorySetup.Modify();
        end;

#if not CLEAN27
#pragma warning disable AL0801
        ManufacturingSetup.Get();
        if ManufacturingSetup."Simulated Order Nos." <> NoSeries then begin
            ManufacturingSetup."Simulated Order Nos." := NoSeries;
            ManufacturingSetup.Modify();
        end;
        if ManufacturingSetup."Planned Order Nos." <> NoSeries then begin
            ManufacturingSetup."Planned Order Nos." := NoSeries;
            ManufacturingSetup.Modify();
        end;
        if ManufacturingSetup."Firm Planned Order Nos." <> NoSeries then begin
            ManufacturingSetup."Firm Planned Order Nos." := NoSeries;
            ManufacturingSetup.Modify();
        end;
        if ManufacturingSetup."Released Order Nos." <> NoSeries then begin
            ManufacturingSetup."Released Order Nos." := NoSeries;
            ManufacturingSetup.Modify();
        end;
#pragma warning restore AL0801
#endif

        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Quote Nos." <> NoSeries then begin
            SalesReceivablesSetup."Quote Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;
        if SalesReceivablesSetup."Order Nos." <> NoSeries then begin
            SalesReceivablesSetup."Order Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;
        if SalesReceivablesSetup."Invoice Nos." <> NoSeries then begin
            SalesReceivablesSetup."Invoice Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;
        if SalesReceivablesSetup."Credit Memo Nos." <> NoSeries then begin
            SalesReceivablesSetup."Credit Memo Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;
        if SalesReceivablesSetup."Return Order Nos." <> NoSeries then begin
            SalesReceivablesSetup."Return Order Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;
        if SalesReceivablesSetup."Customer Nos." <> NoSeries then begin
            SalesReceivablesSetup."Customer Nos." := NoSeries;
            SalesReceivablesSetup.Modify();
        end;

        MarketingSetup.Get();
        if MarketingSetup."Contact Nos." <> NoSeries then begin
            MarketingSetup."Contact Nos." := NoSeries;
            MarketingSetup.Modify();
        end;
    end;

    local procedure GRPH1Outbound1Purchase(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; InvoicePurchase: Boolean)
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        Day1: Date;
        OutboundQty: Decimal;
    begin
        Clear(TempItemLedgerEntry);
        Day1 := WorkDate();

        OutboundQty := LibraryRandom.RandInt(10);
        LibraryInventory.PostNegativeAdjustment(
            Item, LocationCode, VariantCode, '', OutboundQty, Day1, LibraryRandom.RandDec(100, 2));
        InsertTempILEFromLast(TempItemLedgerEntry);

        LibraryPurchase.PostPurchaseOrder(
          PurchaseHeader1, Item, LocationCode, VariantCode,
          LibraryRandom.RandIntInRange(OutboundQty, OutboundQty + LibraryRandom.RandInt(10)), Day1 + 1,
          LibraryRandom.RandDec(100, 2), true, InvoicePurchase);
        InsertTempILEFromLast(TempItemLedgerEntry);

        LibraryPurchase.CreatePurchaseOrder(
          PurchaseHeader2, PurchaseLine, Item, LocationCode, VariantCode, LibraryRandom.RandInt(10), Day1 + 2,
          LibraryRandom.RandDec(100, 2));
    end;

    procedure GRPH1Outbound1PurchRcvd(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        GRPH1Outbound1Purchase(TempItemLedgerEntry, PurchaseLine, Item, LocationCode, VariantCode, false);
    end;

    procedure GRPH1Outbound1PurchInvd(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        GRPH1Outbound1Purchase(TempItemLedgerEntry, PurchaseLine, Item, LocationCode, VariantCode, true);
    end;

    procedure GRPHPurchPartialRcvd1PurchReturn(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var PurchaseLine: Record "Purchase Line"; var PurchaseLine1: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; InvoicePurchase: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader1: Record "Purchase Header";
        Day1: Date;
        InboundQty: Decimal;
    begin
        Clear(TempItemLedgerEntry);
        Day1 := WorkDate();

        // Receive partially the Purchase Line, with or without invoicing.
        InboundQty := LibraryRandom.RandIntInRange(10, 20);
        LibraryPurchase.CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, LocationCode, VariantCode, InboundQty, Day1 + 2, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Qty. to Receive", LibraryRandom.RandInt(PurchaseLine."Outstanding Quantity" - 5));
        PurchaseLine.Modify();
        if InvoicePurchase then
            SetVendorDocNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, InvoicePurchase);
        InsertTempILEFromLast(TempItemLedgerEntry);

        // Repeat the receipt.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", LibraryRandom.RandInt(PurchaseLine."Outstanding Quantity" - 1));
        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        if InvoicePurchase then
            SetVendorDocNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, InvoicePurchase);
        InsertTempILEFromLast(TempItemLedgerEntry);

        // Create Purchase Return Header and Line with 0 quantity. Actual qty to be added in calling test.
        LibraryPurchase.CreatePurchaseReturnOrder(
          PurchaseHeader1, PurchaseLine1, Item, LocationCode, VariantCode, 0, Day1 + 2, LibraryRandom.RandDec(100, 5));
    end;

    procedure GRPHPurchItemTracked(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var PurchaseLine: Record "Purchase Line"; var ReservEntry: Record "Reservation Entry"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        Day1: Date;
        InboundQty: Decimal;
    begin
        Clear(TempItemLedgerEntry);
        Day1 := WorkDate();

        InboundQty := LibraryRandom.RandInt(10);
        LibraryPurchase.CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, LocationCode, VariantCode, InboundQty, Day1, LibraryRandom.RandDec(100, 2));
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservEntry, PurchaseLine, '',
          CopyStr(LibraryUtility.GenerateRandomCode(ReservEntry.FieldNo("Lot No."), DATABASE::"Reservation Entry"), 1, 10), InboundQty);
        if Invoice then
            SetVendorDocNo(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
        InsertTempILEFromLast(TempItemLedgerEntry);
    end;

    procedure GRPHSalesItemTracked(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var SalesLine: Record "Sales Line"; var ReservEntry: Record "Reservation Entry"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        ReservEntry2: Record "Reservation Entry";
        Day1: Date;
        OutboundQty: Decimal;
    begin
        Clear(TempItemLedgerEntry);
        Day1 := WorkDate();

        OutboundQty := LibraryRandom.RandInt(ReservEntry.Quantity);
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, LocationCode, VariantCode, OutboundQty, Day1, LibraryRandom.RandDec(100, 2));
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry2, SalesLine, '', ReservEntry."Lot No.", OutboundQty);

        LibrarySales.PostSalesDocument(SalesHeader, true, Invoice);
        ReservEntry := ReservEntry2;
        InsertTempILEFromLast(TempItemLedgerEntry);
    end;

    procedure GRPH3Purch1SalesItemTracked(var SalesLine: Record "Sales Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; InvoicePurchase: Boolean; InvoiceSales: Boolean)
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        PurchaseLine: Record "Purchase Line";
    begin
        // Purchase 3 times.
        GRPHPurchItemTracked(TempItemLedgerEntry, PurchaseLine, ReservEntry2, Item, LocationCode, VariantCode, InvoicePurchase);
        GRPHPurchItemTracked(TempItemLedgerEntry, PurchaseLine, ReservEntry, Item, LocationCode, VariantCode, InvoicePurchase);
        GRPHPurchItemTracked(TempItemLedgerEntry, PurchaseLine, ReservEntry2, Item, LocationCode, VariantCode, InvoicePurchase);

        // Make the sales for the item tracking in 2nd purchase line
        GRPHSalesItemTracked(TempItemLedgerEntry, SalesLine, ReservEntry, Item, LocationCode, VariantCode, InvoiceSales);
    end;

    procedure GRPHSplitApplication(Item: Record Item; SalesLine: Record "Sales Line"; SalesLineSplit: Record "Sales Line")
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        QtyPurch1: Decimal;
        QtyPurch2: Decimal;
        QtySales1: Decimal;
        QtySales2: Decimal;
    begin
        QtyPurch1 := RandDec(10, 20, 2);
        QtyPurch2 := RandDec(10, 20, 2);
        QtySales1 := RandDec(0, QtyPurch1, 2);
        QtySales2 := RandDec(QtyPurch1 - QtySales1, QtyPurch1 - QtySales1 + QtyPurch2, 2);

        MAKEInbound(Item, QtyPurch1, WorkDate(), TempItemJournalLine);
        MAKEInbound(Item, QtyPurch2, WorkDate(), TempItemJournalLine);

        SHIPSales(SalesLine, Item, QtySales1, WorkDate());
        SHIPSales(SalesLineSplit, Item, QtySales2, WorkDate() + 1);
    end;

    procedure GRPHSeveralSplitApplicationWithCosts(Item: Record Item; var SalesLine: Record "Sales Line"; var TempItemJournalLine: Record "Item Journal Line" temporary; var Cost1: Decimal; var Cost2: Decimal; var Cost3: Decimal)
    var
        UnitCost1: Decimal;
        UnitCost2: Decimal;
        UnitCost3: Decimal;
        Qty1: Decimal;
        Qty2: Decimal;
        Qty3: Decimal;
        QtyOut1: Decimal;
        QtyOut2: Decimal;
        RemainingQty2: Decimal;
    begin
        Qty1 := RandDec(10, 20, 2);
        Qty2 := RandDec(10, 20, 2);
        Qty3 := RandDec(10, 20, 2);

        MAKEInbound(Item, Qty1, WorkDate(), TempItemJournalLine);
        UnitCost1 := TempItemJournalLine."Unit Amount";
        MAKEInbound(Item, Qty2, WorkDate() + 1, TempItemJournalLine);
        UnitCost2 := TempItemJournalLine."Unit Amount";
        MAKEInbound(Item, Qty3, WorkDate() + 2, TempItemJournalLine);
        UnitCost3 := TempItemJournalLine."Unit Amount";

        QtyOut1 := Qty1 + RandDec(0, Qty2 / 2, 2);
        RemainingQty2 := Qty2 + Qty1 - QtyOut1;
        QtyOut2 := RandDec(0, RemainingQty2, 2);

        MAKEOutbound(Item, QtyOut1, WorkDate() + 3, TempItemJournalLine);
        Cost1 := (Qty1 * UnitCost1 + (QtyOut1 - Qty1) * UnitCost2) / QtyOut1;
        MAKEOutbound(Item, QtyOut2, WorkDate() + 4, TempItemJournalLine);
        Cost2 := UnitCost2;

        RemainingQty2 -= QtyOut2;
        SHIPSales(SalesLine, Item, RemainingQty2 + RandDec(0, Qty3, 2), WorkDate() + 5);
        Cost3 := (RemainingQty2 * UnitCost2 + (SalesLine.Quantity - RemainingQty2) * UnitCost3) / SalesLine.Quantity;

        TempItemJournalLine.FindSet();
    end;

    procedure GRPHSplitJoinApplication(Item: Record Item; var SalesLine: Record "Sales Line"; var SalesLineReturn: Record "Sales Line"; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        Qty: Decimal;
    begin
        Qty := RandDec(10, 20, 2);

        MAKEInbound(Item, Qty, WorkDate(), TempItemJournalLine);

        SHIPSales(SalesLine, Item, Qty / 2, WorkDate());
        LibrarySales.PostSalesLine(SalesLine, true, true);

        RECEIVESalesReturn(SalesLineReturn, SalesLine, WorkDate());
        SHIPSales(SalesLine, Item, Qty, WorkDate());
    end;

    procedure GRPHSeveralSplitApplication(Item: Record Item; var SalesLine: Record "Sales Line"; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        Unused: Decimal;
    begin
        GRPHSeveralSplitApplicationWithCosts(Item, SalesLine, TempItemJournalLine, Unused, Unused, Unused);
    end;

    procedure GRPHSalesOnly(Item: Record Item; var SalesLine: Record "Sales Line")
    begin
        SHIPSales(SalesLine, Item, RandDec(10, 20, 2), WorkDate());
    end;

    procedure GRPHApplyInboundToUnappliedOutbound(var Item: Record Item; var SalesLine: Record "Sales Line")
    var
        TempItemJournalLine: Record "Item Journal Line" temporary;
        QtyOut: Decimal;
        QtyIn1: Decimal;
        QtyIn2: Decimal;
    begin
        QtyOut := RandDec(10, 20, 2);
        QtyIn1 := RandDec(0, QtyOut / 2, 2);
        QtyIn2 := QtyOut - QtyIn1 + RandDec(0, 10, 2);

        SHIPSales(SalesLine, Item, QtyOut, WorkDate());

        MAKEInbound(Item, QtyIn1, WorkDate() - 1, TempItemJournalLine);
        MAKEInbound(Item, QtyIn2, WorkDate() - 2, TempItemJournalLine);
    end;

    procedure GRPHSimpleApplication(Item: Record Item; var SalesLine: Record "Sales Line"; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        QtyIn: Decimal;
    begin
        QtyIn := RandDec(10, 20, 2);
        MAKEInbound(Item, QtyIn, WorkDate(), TempItemJournalLine);
        SHIPSales(SalesLine, Item, RandDec(0, QtyIn, 2), WorkDate() + 1);
    end;

    procedure GRPHSalesReturnOnly(var Item: Record Item; var ReturnReceiptLine: Record "Return Receipt Line")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", RandDec(10, 20, 2));
        Commit();

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ReturnReceiptLine.SetFilter("No.", Item."No.");
        ReturnReceiptLine.FindLast();
    end;

    procedure GRPHSalesFromReturnReceipts(var Item: Record Item; var SalesLine: Record "Sales Line")
    var
        ReturnReceiptLine1: Record "Return Receipt Line";
        ReturnReceiptLine2: Record "Return Receipt Line";
    begin
        GRPHSalesReturnOnly(Item, ReturnReceiptLine1);
        GRPHSalesReturnOnly(Item, ReturnReceiptLine2);
        SHIPSales(SalesLine, Item, ReturnReceiptLine1.Quantity + RandDec(0, ReturnReceiptLine2.Quantity, 2), WorkDate());
    end;

    procedure InsertTempILEFromLast(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.FindLast();
        TempItemLedgerEntry := ItemLedgerEntry;
        TempItemLedgerEntry.Insert();
    end;

    procedure CHECKValueEntry(var RefValueEntry: Record "Value Entry"; ValueEntry: Record "Value Entry")
    begin
        ValueEntry.TestField("Cost Amount (Expected)", RefValueEntry."Cost Amount (Expected)");
        ValueEntry.TestField("Cost Amount (Actual)", RefValueEntry."Cost Amount (Actual)");
        ValueEntry.TestField("Valued Quantity", RefValueEntry."Valued Quantity");
        ValueEntry.TestField("Cost per Unit", RefValueEntry."Cost per Unit");
        ValueEntry.TestField("Valuation Date", RefValueEntry."Valuation Date");
        ValueEntry.TestField("Entry Type", RefValueEntry."Entry Type");
        ValueEntry.TestField("Variance Type", RefValueEntry."Variance Type");
    end;

    procedure CHECKItemLedgerEntry(var RefItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        RefItemLedgerEntry.FindSet();
        ItemLedgerEntry.SetRange("Item No.", RefItemLedgerEntry."Item No.");
        ItemLedgerEntry.SetRange("Location Code", RefItemLedgerEntry."Location Code");
        ItemLedgerEntry.SetRange("Variant Code", RefItemLedgerEntry."Variant Code");
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField("Cost Amount (Expected)", RefItemLedgerEntry."Cost Amount (Expected)");
            ItemLedgerEntry.TestField("Cost Amount (Actual)", RefItemLedgerEntry."Cost Amount (Actual)");
            ItemLedgerEntry.TestField("Remaining Quantity", RefItemLedgerEntry."Remaining Quantity");
            ItemLedgerEntry.TestField("Invoiced Quantity", RefItemLedgerEntry."Invoiced Quantity");
            ItemLedgerEntry.TestField("Applies-to Entry", RefItemLedgerEntry."Applies-to Entry");
            RefItemLedgerEntry.Next();
        until ItemLedgerEntry.Next() = 0;
    end;

    procedure RandDec("Min": Decimal; "Max": Decimal; Precision: Integer): Decimal
    var
        Min2: Integer;
        Max2: Integer;
        Pow: Integer;
    begin
        Pow := Power(10, Precision);
        Min2 := Round(Min * Pow, 1);
        Max2 := Round(Max * Pow, 1);
        exit(Round(LibraryRandom.RandDecInRange(Min2, Max2, 1) / Pow, 1 / Pow));
    end;

    procedure RandCost(Item: Record Item): Decimal
    var
        Precision: Decimal;
    begin
        Precision := LibraryERM.GetAmountRoundingPrecision();
        if Item."Unit Cost" <> 0 then
            exit(Round(Item."Unit Cost" * RandDec(0, 2, 5), Precision));
        exit(Round(RandDec(0, 100, 5), Precision));
    end;

    local procedure SHIPSales(var SalesLine: Record "Sales Line"; Item: Record Item; Qty: Decimal; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Shipment Date", PostingDate);
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure RECEIVESalesReturn(var SalesLineReturn: Record "Sales Line"; FromSalesLine: Record "Sales Line"; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        SalesShipmentLine.SetRange("Order No.", FromSalesLine."Document No.");
        SalesShipmentLine.FindFirst();
        CopyDocMgt.SetProperties(false, true, false, false, true, true, true);
        CopyDocMgt.CopySalesShptLinesToDoc(
          SalesHeader, SalesShipmentLine, LinesNotCopied, MissingExCostRevLink);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesLineReturn.SetRange("Document Type", SalesHeader."Document Type");
        SalesLineReturn.SetRange("Document No.", SalesHeader."No.");
        SalesLineReturn.SetRange(Type, SalesLineReturn.Type::Item);
        Assert.AreEqual(1, SalesLineReturn.Count, TXTUnexpectedLine);
        SalesLineReturn.FindFirst();
    end;

    procedure CHECKCalcInvPost(Item: Record Item; ItemJnlBatch: Record "Item Journal Batch"; PostingDate: Date; CalculatePer: Enum "Inventory Value Calc. Per"; ByLocation: Boolean; ByVariant: Boolean; LocationFilter: Code[20]; VariantFilter: Code[20])
    var
        TempRefItemJnlLine: Record "Item Journal Line" temporary;
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Verify journal lines created by Calculate Inventory Value report
        CreateRefJnlforCalcInvPost(Item, TempRefItemJnlLine, PostingDate, CalculatePer, ByLocation, ByVariant, LocationFilter, VariantFilter);

        ItemJnlLine.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        ItemJnlLine.SetRange("Item No.", Item."No.");

        Assert.AreEqual(TempRefItemJnlLine.Count, ItemJnlLine.Count, StrSubstNo(TXTLineCountMismatch, Item."No."));

        if CalculatePer = CalculatePer::Item then begin
            if ItemJnlLine.FindSet() then
                repeat
                    TempRefItemJnlLine.SetRange("Location Code", ItemJnlLine."Location Code");
                    TempRefItemJnlLine.SetRange("Variant Code", ItemJnlLine."Variant Code");
                    TempRefItemJnlLine.FindFirst();
                    Assert.AreEqual(
                      TempRefItemJnlLine.Quantity, ItemJnlLine.Quantity,
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName(Quantity), ItemJnlLine."Line No."));
                    Assert.AreEqual(TempRefItemJnlLine."Inventory Value (Calculated)", ItemJnlLine."Inventory Value (Calculated)",
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName("Inventory Value (Calculated)"), ItemJnlLine."Line No."));
                until ItemJnlLine.Next() = 0;
        end else
            if ItemJnlLine.FindSet() then
                repeat
                    TempRefItemJnlLine.SetRange("Applies-to Entry", ItemJnlLine."Applies-to Entry");
                    TempRefItemJnlLine.FindFirst();
                    Assert.AreEqual(
                      TempRefItemJnlLine."Location Code", ItemJnlLine."Location Code",
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName("Location Code"), ItemJnlLine."Applies-to Entry"));
                    Assert.AreEqual(
                      TempRefItemJnlLine."Variant Code", ItemJnlLine."Variant Code",
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName("Variant Code"), ItemJnlLine."Applies-to Entry"));
                    Assert.AreEqual(
                      TempRefItemJnlLine.Quantity, ItemJnlLine.Quantity,
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName(Quantity), ItemJnlLine."Applies-to Entry"));
                    Assert.AreEqual(
                      TempRefItemJnlLine."Inventory Value (Calculated)", ItemJnlLine."Inventory Value (Calculated)",
                      StrSubstNo(TXTIncorrectEntry, TempRefItemJnlLine.FieldName("Inventory Value (Calculated)"), ItemJnlLine."Applies-to Entry"));
                until ItemJnlLine.Next() = 0;
    end;

    local procedure CreateRefJnlforCalcInvPost(Item: Record Item; var TempRefItemJnlLine: Record "Item Journal Line" temporary; PostingDate: Date; CalculatePer: Enum "Inventory Value Calc. Per"; ByLocation: Boolean; ByVariant: Boolean; LocationFilter: Code[20]; VariantFilter: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempLocation: Record Location temporary;
        TempItemVariant: Record "Item Variant" temporary;
    begin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetFilter("Location Code", LocationFilter);
        ItemLedgerEntry.SetFilter("Variant Code", VariantFilter);
        ItemLedgerEntry.SetFilter("Posting Date", '<=%1', PostingDate);
        if Item."Costing Method" <> Item."Costing Method"::Standard then begin
            ItemLedgerEntry.SetRange("Completely Invoiced", true);
            ItemLedgerEntry.SetRange("Last Invoice Date", 0D, PostingDate);
        end;
        if CalculatePer = CalculatePer::Item then begin
            if LocationFilter <> '' then
                ByLocation := true;
            if VariantFilter <> '' then
                ByVariant := true;

            TempLocation.Code := '';
            TempLocation.Insert();
            TempItemVariant.Code := '';
            TempItemVariant.Insert();

            if ItemLedgerEntry.FindSet() then
                repeat
                    TempItemLedgerEntry := ItemLedgerEntry;
                    TempItemLedgerEntry.Insert();
                    TempLocation.Code := ItemLedgerEntry."Location Code";
                    if not TempLocation.Insert() then;
                    TempItemVariant.Code := ItemLedgerEntry."Variant Code";
                    if not TempItemVariant.Insert() then;
                until ItemLedgerEntry.Next() = 0;

            if ByLocation then begin
                TempLocation.FindSet();
                repeat
                    TempItemLedgerEntry.SetRange("Location Code", TempLocation.Code);
                    if ByVariant then begin
                        TempItemVariant.FindSet();
                        repeat
                            TempItemLedgerEntry.SetRange("Variant Code", TempItemVariant.Code);
                            CreateRefJournalLinePerItem(TempItemLedgerEntry, TempRefItemJnlLine, PostingDate, ByLocation, ByVariant);
                        until TempItemVariant.Next() = 0;
                    end else
                        CreateRefJournalLinePerItem(TempItemLedgerEntry, TempRefItemJnlLine, PostingDate, ByLocation, ByVariant);
                until TempLocation.Next() = 0;
            end else
                if ByVariant then begin
                    TempItemVariant.FindSet();
                    repeat
                        TempItemLedgerEntry.SetRange("Variant Code", TempItemVariant.Code);
                        CreateRefJournalLinePerItem(TempItemLedgerEntry, TempRefItemJnlLine, PostingDate, ByLocation, ByVariant);
                    until TempItemVariant.Next() = 0;
                end else
                    CreateRefJournalLinePerItem(TempItemLedgerEntry, TempRefItemJnlLine, PostingDate, ByLocation, ByVariant);
        end else begin
            if ItemLedgerEntry.FindSet() then
                repeat
                    TempItemLedgerEntry := ItemLedgerEntry;
                    TempItemLedgerEntry.Insert();
                until ItemLedgerEntry.Next() = 0;
            CreateRefJournalLinePerILE(TempItemLedgerEntry, TempRefItemJnlLine, PostingDate);
        end;
    end;

    local procedure CreateRefJournalLinePerItem(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempRefItemJnlLine: Record "Item Journal Line" temporary; PostingDate: Date; ByLocation: Boolean; ByVariant: Boolean)
    var
        OutboundItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        RefQuantity: Decimal;
        RefCostAmount: Decimal;
    begin
        if TempItemLedgerEntry.FindSet() then
            repeat
                RefQuantity += TempItemLedgerEntry.Quantity;
                RefCostAmount += CalculateCostAtDate(TempItemLedgerEntry."Entry No.", PostingDate);
                ItemApplicationEntry.SetRange("Inbound Item Entry No.", TempItemLedgerEntry."Entry No.");
                ItemApplicationEntry.SetFilter("Posting Date", '<=%1', PostingDate);
                if ItemApplicationEntry.FindSet() then
                    repeat
                        if (ItemApplicationEntry."Outbound Item Entry No." <> 0) and (ItemApplicationEntry.Quantity < 0) then begin
                            OutboundItemLedgerEntry.Get(ItemApplicationEntry."Outbound Item Entry No.");
                            RefQuantity += ItemApplicationEntry.Quantity;
                            RefCostAmount += CalculateCostAtDate(OutboundItemLedgerEntry."Entry No.", PostingDate) /
                              OutboundItemLedgerEntry.Quantity * ItemApplicationEntry.Quantity;
                        end;
                    until ItemApplicationEntry.Next() = 0;
            until TempItemLedgerEntry.Next() = 0;

        if RefQuantity = 0 then
            exit;

        TempRefItemJnlLine."Line No." += 10000;
        TempRefItemJnlLine."Item No." := TempItemLedgerEntry."Item No.";
        if ByLocation then
            TempRefItemJnlLine."Location Code" := TempItemLedgerEntry."Location Code";
        if ByVariant then
            TempRefItemJnlLine."Variant Code" := TempItemLedgerEntry."Variant Code";
        TempRefItemJnlLine.Quantity := RefQuantity;
        TempRefItemJnlLine."Inventory Value (Calculated)" := Round(RefCostAmount, LibraryERM.GetAmountRoundingPrecision());
        TempRefItemJnlLine.Insert();
    end;

    local procedure CreateRefJournalLinePerILE(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempRefItemJnlLine: Record "Item Journal Line" temporary; PostingDate: Date)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if TempItemLedgerEntry.FindSet() then
            repeat
                TempItemLedgerEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Non-Invtbl.)");
                ItemApplicationEntry.SetRange("Inbound Item Entry No.", TempItemLedgerEntry."Entry No.");
                ItemApplicationEntry.SetFilter("Posting Date", '<=%1', PostingDate);
                ItemApplicationEntry.CalcSums(Quantity);

                if ItemApplicationEntry.Quantity > 0 then begin
                    TempRefItemJnlLine."Line No." += 10000;
                    TempRefItemJnlLine."Item No." := TempItemLedgerEntry."Item No.";
                    TempRefItemJnlLine."Location Code" := TempItemLedgerEntry."Location Code";
                    TempRefItemJnlLine."Variant Code" := TempItemLedgerEntry."Variant Code";

                    TempRefItemJnlLine.Quantity := ItemApplicationEntry.Quantity;
                    TempRefItemJnlLine."Inventory Value (Calculated)" :=
                      Round(
                        CalculateCostAtDate(TempItemLedgerEntry."Entry No.", PostingDate) /
                        TempItemLedgerEntry.Quantity * ItemApplicationEntry.Quantity, LibraryERM.GetAmountRoundingPrecision());
                    TempRefItemJnlLine."Applies-to Entry" := TempItemLedgerEntry."Entry No.";
                    TempRefItemJnlLine.Insert();
                end;
            until TempItemLedgerEntry.Next() = 0;
    end;

    local procedure CalculateCostAtDate(ItemLedgerEntryNo: Integer; PostingDate: Date): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        ValueEntry.SetRange("Valuation Date", 0D, PostingDate);
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        exit(ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)");
    end;

    procedure ExecutePostRevalueInboundILE(Item: Record Item; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; Factor: Decimal)
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        EntryNo: Integer;
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryCosting.CheckAdjustment(Item);

        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Revaluation);
        LibraryInventory.MakeItemJournalLine(ItemJnlLine, ItemJnlBatch, Item, WorkDate(), ItemJnlLine."Entry Type"::Purchase, 0);
        TempItemLedgerEntry.FindFirst();
        EntryNo := TempItemLedgerEntry."Entry No.";
        ItemJnlLine.Validate("Applies-to Entry", EntryNo);
        ItemJnlLine.Validate("Inventory Value (Revalued)", ItemJnlLine."Inventory Value (Revalued)" * Factor);
        ItemJnlLine.Insert();

        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
    end;

    procedure CalculateInventoryValueRun(var ItemJnlBatch: Record "Item Journal Batch"; var Item: Record Item; PostingDate: Date; CalculatePer: Enum "Inventory Value Calc. Per"; ByLocation: Boolean; ByVariant: Boolean; UpdStdCost: Boolean; CalcBase: Enum "Inventory Value Calc. Base"; ShowDialog: Boolean; LocationFilter: Code[20]; VariantFilter: Code[20])
    var
        RevalueItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        CalculateInventoryValue: Report "Calculate Inventory Value";
        DocumentNo: Code[20];
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJnlBatch, ItemJnlBatch."Template Type"::Revaluation);
        DocumentNo := LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Document No."), DATABASE::"Item Journal Line");
        ItemJournalLine.Validate("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJnlBatch.Name);
        Item.SetFilter("Location Filter", LocationFilter);
        Item.SetFilter("Variant Filter", VariantFilter);
        CalculateInventoryValue.UseRequestPage(false);
        CalculateInventoryValue.SetItemJnlLine(ItemJournalLine);
        RevalueItem.Copy(Item);
        if Item."No." <> '' then
            RevalueItem.SetRange("No.", Item."No.");
        CalculateInventoryValue.SetTableView(RevalueItem);
        CalculateInventoryValue.SetParameters(
          PostingDate, DocumentNo, true, CalculatePer, ByLocation, ByVariant, UpdStdCost, CalcBase, ShowDialog);
        CalculateInventoryValue.RunModal();
    end;

    procedure ModifyPostRevaluation(var ItemJnlBatch: Record "Item Journal Batch"; Factor: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        if ItemJnlLine.FindSet() then
            repeat
                ItemJnlLine.Validate("Inventory Value (Revalued)",
                  Round(ItemJnlLine."Inventory Value (Revalued)" * Factor, LibraryERM.GetAmountRoundingPrecision()));
                ItemJnlLine.Modify();
            until ItemJnlLine.Next() = 0;
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
    end;

    procedure ModifyAppliesToPostRevaluation(var ItemJnlBatch: Record "Item Journal Batch"; Factor: Decimal; AppliesToEntry: Integer)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        if ItemJnlLine.FindSet() then
            repeat
                ItemJnlLine.Validate("Inventory Value (Revalued)",
                  Round(ItemJnlLine."Inventory Value (Revalued)" * Factor, LibraryERM.GetAmountRoundingPrecision()));
                ItemJnlLine.Validate("Applies-to Entry", AppliesToEntry);
                ItemJnlLine.Modify();
            until ItemJnlLine.Next() = 0;
        LibraryInventory.PostItemJournalBatch(ItemJnlBatch);
    end;

    local procedure MAKEXBound(Item: Record Item; Qty: Decimal; Date: Date; EntryType: Enum "Item Ledger Entry Type"; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.MakeItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, Date, EntryType, Qty);
        ItemJournalLine.Insert(true);
        ItemJournalLine.Validate("Posting Date", Date);
        ItemJournalLine.Validate("Unit Amount", RandCost(Item));
        ItemJournalLine.Modify(true);

        TempItemJournalLine := ItemJournalLine;
        TempItemJournalLine.Insert();

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure MAKEInbound(Item: Record Item; Qty: Decimal; Date: Date; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        MAKEXBound(Item, Qty, Date, ItemJournalLine."Entry Type"::Purchase, TempItemJournalLine);
    end;

    local procedure MAKEOutbound(Item: Record Item; Qty: Decimal; Date: Date; var TempItemJournalLine: Record "Item Journal Line" temporary)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        MAKEXBound(Item, Qty, Date, ItemJournalLine."Entry Type"::Sale, TempItemJournalLine);
    end;

    procedure Minimum(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 < Value2 then
            exit(Value1);

        exit(Value2);
    end;

    local procedure SetVendorDocNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchaseHeader."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify();
    end;
}

