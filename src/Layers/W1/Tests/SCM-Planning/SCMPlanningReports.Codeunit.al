codeunit 137308 "SCM Planning Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [Reports] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        RecordShould: Option Exist,"Not Exist";
        RecordExistenceErr: Label '%1 record should %2.';

    [Test]
    [Scope('OnPrem')]
    procedure ReplanCycleDoesNotDuplicateSupply()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Planning] [Calculate Plan - Plan Wksh] [Reservation]
        // [SCENARIO] No planning worksheet infinite cycle appears if reservation on supply deleted manually.

        // [GIVEN] Demand from Production order component on an Item with SKU having Order reordering policy.
        Initialize();
        CreateItemAndSKU(Item);
        CreateProductionOrderWithComponent(Item."No.", Item.GetFilter("Location Filter"));
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        // [GIVEN] Calc supply, carry out.
        CarryOutActionMessageForRegenPlan(Item."No.");
        // [GIVEN] Partly post supply, then cancel reservation.
        PurchReceiptAndCancelReservation(Item."No.");
        // [GIVEN] Calc supply, carry out, but not post.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        CarryOutActionMessageForRegenPlan(Item."No.");

        // [WHEN] Calculating regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] No requisition worksheet suggested.
        VerifyActionLinesExists(Item."No.", RecordShould::"Not Exist");
    end;

    local procedure Initialize()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Planning Reports");
        RequisitionWkshName.DeleteAll();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        LibraryApplicationArea.EnableEssentialSetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Planning Reports");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        ItemJournalSetup();
        LibrarySetupStorage.SaveInventorySetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Planning Reports");
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; ReorderPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::FIFO, 0, ReorderPolicy, Item."Flushing Method"::"Pick + Manual", RoutingNo, ProductionBOMNo);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateItemAndSKU(var Item: Record Item)
    var
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
    begin
        CreateItem(Item, '', '', Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location.Code, Item."No.", '');
        SKU.Validate("Reordering Policy", SKU."Reordering Policy"::Order);
        SKU.Modify(true);
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", Location.Code);
    end;

    local procedure CreateProductionOrderWithComponent(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        Item: Record Item;
    begin
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ItemNo, 1); // Quantity per = 1.
        CreateItem(Item, '', ProductionBOMHeader."No.", Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        CreateAndRefreshProdOrderWithLocation(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LocationCode);
    end;

    local procedure CreateAndRefreshProdOrderWithLocation(var ProductionOrder: Record "Production Order"; ProductionOrderStatus: Enum "Production Order Status"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrderStatus, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(5, 2));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CarryOutActionMessageForRegenPlan(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(ItemNo);
        SelectRequisitionLineForItem(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure AcceptActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLineForItem(RequisitionLine, ItemNo);
        repeat
            if RequisitionLine."Ref. Order Type" = RequisitionLine."Ref. Order Type"::Purchase then
                RequisitionLine.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
            UpdateActionMessageRequisitionLine(RequisitionLine);
        until RequisitionLine.Next() = 0;
    end;

    local procedure SelectRequisitionLineForItem(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindSet();
    end;

    local procedure SelectPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.FindSet();
    end;

    local procedure UpdateActionMessageRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    local procedure PurchReceiptAndCancelReservation(ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
    begin
        SelectPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        FindReservEntry(ReservationEntry, PurchaseLine);
        ReservationEngineMgt.CancelReservation(ReservationEntry);
    end;

    local procedure FindReservEntry(var ReservationEntry: Record "Reservation Entry"; PurchaseLine: Record "Purchase Line")
    begin
        ReservationEngineMgt.InitFilterAndSortingLookupFor(ReservationEntry, true);
        PurchaseLine.SetReservationFilters(ReservationEntry);
        ReservationEntry.FindFirst();
    end;

    local procedure VerifyActionLinesExists(ItemNo: Code[20]; RecordShould: Option Exist,"Not Exist")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        Assert.AreEqual(RequisitionLine.IsEmpty, RecordShould = RecordShould::"Not Exist",
          StrSubstNo(RecordExistenceErr, RequisitionLine.TableCaption(), RecordShould));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), ConfirmMessage);
        Reply := true;
    end;
}

