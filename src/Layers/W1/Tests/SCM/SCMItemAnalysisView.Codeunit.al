codeunit 137229 "SCM Item Analysis View"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Analysis View] [SCM]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        InvPickCreatedMessageTxt: Label 'Number of Invt. Pick activities created: 1 out of a total of 1.';

    [Test]
    [Scope('OnPrem')]
    procedure CheckUpdateOnPosting()
    var
        ItemAnalysisView: Record "Item Analysis View";
        LastEntryNo: Integer;
    begin
        // 5. Check Update on Posting for GL
        Initialize();

        // Setup
        PrepareAnalysisViewRec(ItemAnalysisView, false, true);

        // Validate
        CODEUNIT.Run(CODEUNIT::"Update Item Analysis View", ItemAnalysisView);
        ItemAnalysisView.Find();
        ItemAnalysisView.TestField("Last Entry No.");
        LastEntryNo := ItemAnalysisView."Last Entry No.";
        PostSalesOrder();
        CODEUNIT.Run(CODEUNIT::"Update Item Analysis View", ItemAnalysisView);
        ItemAnalysisView.Find();
        ItemAnalysisView.TestField("Last Entry No.");
        Assert.IsTrue(ItemAnalysisView."Last Entry No." > LastEntryNo, 'Item Analysis View was not updated.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckUpdateOnPostingRollback()
    var
        ItemAnalysisView: Record "Item Analysis View";
        TransferLine: Record "Transfer Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Transfer] [Inventory Pick] [Dimension]
        // [SCENARIO 381591] When item analysis view updates on posting and error occurs from posting inventory pick for transfer order no lines must exist in item ledger entry for this transfer order.
        Initialize();

        // [GIVEN] Item Analysis View with Update on Posting enabled.
        PrepareAnalysisViewRec(ItemAnalysisView, true, false);

        // [GIVEN] Released transfer order T with line TL for item I with inventory in Bin B.
        CreateReleasedTransferLineQtyOneFromLocation(TransferLine);

        // [GIVEN] Inventory Pick P with line PL with Bin B.
        CreateInvPickFromTransferLine(WarehouseActivityHeader, WarehouseActivityLine, TransferLine);

        // [GIVEN] Post reclassification for item I from bin B to some other bin. That means the unpossibility of posting the Inventory Pick P.
        ReclassItemWithNewBin(TransferLine."Transfer-from Code", TransferLine."Item No.", TransferLine.Quantity, WarehouseActivityLine."Bin Code");

        // [WHEN] Posting inventory pick P and error occurs
        asserterror LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Transaction rollback completely and no lines exist in item ledger entry for transfer order T.
        ItemLedgerEntry.Init();
        ItemLedgerEntry.SetRange("Order No.", TransferLine."Document No.");
        Assert.RecordIsEmpty(ItemLedgerEntry);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Item Analysis View");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Item Analysis View");

        LibraryERMCountryData.CreateVATData();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Item Analysis View");
    end;

    local procedure PrepareAnalysisViewRec(var ItemAnalysisView: Record "Item Analysis View"; UpdateOnPosting: Boolean; IncludeBudgets: Boolean)
    var
        Dim: Record Dimension;
        i: Integer;
    begin
        ItemAnalysisView.Init();
        ItemAnalysisView."Analysis Area" := ItemAnalysisView."Analysis Area"::Inventory;
        ItemAnalysisView.Validate(Code, LibraryUtility.GenerateRandomCode(ItemAnalysisView.FieldNo(Code), DATABASE::"Item Analysis View"));
        ItemAnalysisView.Insert(true);

        ItemAnalysisView.Validate("Update on Posting", UpdateOnPosting);
        ItemAnalysisView.Validate("Include Budgets", IncludeBudgets);
        if Dim.FindSet() then
            repeat
                i += 1;
                case i of
                    1:
                        ItemAnalysisView.Validate("Dimension 1 Code", Dim.Code);
                    2:
                        ItemAnalysisView.Validate("Dimension 2 Code", Dim.Code);
                    3:
                        ItemAnalysisView.Validate("Dimension 3 Code", Dim.Code);
                end;
            until (i = 3) or (Dim.Next() = 0);

        ItemAnalysisView.Modify(true);
    end;

    local procedure PostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateLocationsChain(var FromLocation: Record Location; var ToLocation: Record Location; var TransitLocation: Record Location)
    var
        TransferRoute: Record "Transfer Route";
    begin
        CreateLocationRequirePick(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryInventory.CreateTransferRoute(TransferRoute, FromLocation.Code, ToLocation.Code);
        TransferRoute.Validate("In-Transit Code", TransitLocation.Code);
        TransferRoute.Modify(true);
    end;

    local procedure PostPurchaseDocument(PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemInventory(LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationCode, ItemNo, Quantity, BinCode);
        PostPurchaseDocument(PurchaseHeader);
    end;

    local procedure ReclassItemWithNewBin(LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        NewBinCode: Code[20];
    begin
        NewBinCode := CreateBinCode(LocationCode);
        CreateItemReclassJournalLine(ItemJournalLine, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("New Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("New Bin Code", NewBinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateTransferOrderQtyOne(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; TransitLocationCode: Code[10]; ReceiptDate: Date)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, TransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, 1);
        TransferLine.Validate("Receipt Date", ReceiptDate);
        TransferLine.Modify(true);
    end;

    local procedure CreateReleasedTransferLineQtyOneFromLocation(var TransferLine: Record "Transfer Line")
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        LibraryInventory.CreateItem(Item);
        CreateLocationsChain(FromLocation, ToLocation, TransitLocation);
        CreateItemInventory(FromLocation.Code, Item."No.", 1, FromLocation."Receipt Bin Code");
        CreateTransferOrderQtyOne(
          TransferHeader, TransferLine, Item."No.", FromLocation.Code, ToLocation.Code, TransitLocation.Code, WorkDate());
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateLocationRequirePick(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Receipt Bin Code", CreateBinCode(Location.Code));
        Location.Validate("Shipment Bin Code", CreateBinCode(Location.Code));
        Location.Modify(true);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateBinCode(LocationCode: Code[10]): Code[20]
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), '', '');
        exit(Bin.Code);
    end;

    local procedure CreateItemReclassJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer, ItemNo,
          Quantity);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure CreateInvPick(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(InvPickCreatedMessageTxt);
        LibraryWarehouse.CreateInvtPutPickMovement(SourceDocument, SourceNo, false, true, false);
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, LocationCode);
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::"Invt. Pick", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
    end;

    local procedure CreateInvPickFromTransferLine(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; TransferLine: Record "Transfer Line")
    begin
        CreateInvPick(
              WarehouseActivityHeader, WarehouseActivityLine,
              WarehouseActivityHeader."Source Document"::"Outbound Transfer", TransferLine."Document No.", TransferLine."Transfer-from Code");
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; LocationCode: Code[10])
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;
}

