codeunit 137931 "Item Tracking Code Changes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Tracking Code Change]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryCosting: Codeunit "Library - Costing";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ChangeLogImmutableErr: Label 'Item tracking code change log entries cannot be modified or deleted.';
        OpenItemLedgerEntriesExistErr: Label 'You cannot change Item Tracking Code for item %1 because one or more open item ledger entries exist.', Comment = '%1 = Item No.';
        ItemLedgerEntriesOnChangeDateErr: Label 'You cannot change the Item Tracking Code for item %1 because item ledger entries exist with Posting Date %2.', Comment = '%1 = Item No., %2 = Posting Date';
        RecordsExistErr: Label 'You cannot change Item Tracking Code for item %1 because one or more %2 records exist.', Comment = '%1 = Item No., %2 = Table Caption';

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ChangeFromBlankToLotTrackingCreatesAuditEntry()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Changing an eligible historical item from blank to lot tracking creates an audit entry.
        Initialize();

        // [GIVEN] Item "I" with closed historical entries and no current tracking.
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        ChangeItemTrackingCode(Item, ItemTrackingCode.Code);

        // [THEN] Item "I" uses lot tracking and the change is logged.
        VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
        VerifyChangeLog(Item."No.", WorkDate(), '', ItemTrackingCode.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ChangeFromLotToBlankTrackingCreatesAuditEntry()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Removing lot tracking from an eligible historical item creates an audit entry.
        Initialize();

        // [GIVEN] Item "I" with closed historical entries and lot tracking.
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify();

        // [WHEN] Tracking is removed from item "I".
        ChangeItemTrackingCode(Item, '');

        // [THEN] Item "I" has blank tracking and the change is logged.
        VerifyItemTrackingCode(Item."No.", '');
        VerifyChangeLog(Item."No.", WorkDate(), ItemTrackingCode.Code, '');
    end;

    [Test]
    procedure HistoricalTrackingCodeIsReconstructedAcrossMultipleChangeDates()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        FirstItemTrackingCode: Record "Item Tracking Code";
        SecondItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
        HistoricalItemTrackingCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] The tracking code active on the posting date is reconstructed through later audit entries.
        Initialize();

        // [GIVEN] Item "I" posted without tracking and changed first to lot and later to serial tracking.
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.CreateItemTrackingCode(FirstItemTrackingCode, false, true);
        LibraryItemTracking.CreateItemTrackingCode(SecondItemTrackingCode, true, false);
        Item."Item Tracking Code" := SecondItemTrackingCode.Code;
        Item.Modify();
        CreateMockItemLedgerEntry(ItemLedgerEntry, Item."No.", WorkDate() - 2, false);
        CreateChangeLog(Item."No.", WorkDate() - 1, '', FirstItemTrackingCode.Code);
        CreateChangeLog(Item."No.", WorkDate(), FirstItemTrackingCode.Code, SecondItemTrackingCode.Code);

        // [WHEN] The tracking code for the historical entry is requested.
        Assert.IsTrue(
            ItemTrackingCodeChangeMgt.GetTrackingCodeForLinkedApplication(
                Item."No.", ItemLedgerEntry."Entry No.", HistoricalItemTrackingCode),
            'A cross-period tracking application should be detected.');

        // [THEN] The code active when the entry was posted was blank.
        Assert.AreEqual('', HistoricalItemTrackingCode, 'The historical tracking code is incorrect.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeIsBlockedWithoutDedicatedPermission()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Item edit permission alone cannot create the mandatory tracking-code audit entry.
        Initialize();

        // [GIVEN] Eligible item "I" and a user with item edit permission but without ITEM TRACKING CHANGE.
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryLowerPermissions.SetExactPermissionSet('D365 ITEM, EDIT');
        LibraryLowerPermissions.AddO365Basic();

        // [WHEN] The user enables lot tracking for item "I".
        asserterror ChangeItemTrackingCode(Item, ItemTrackingCode.Code);

        // [THEN] The change is blocked because the dedicated permission is missing.
        Assert.ExpectedError('ITEM TRACKING CHANGE');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeSucceedsWithDedicatedPermission()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] A user with item edit and ITEM TRACKING CHANGE can change an eligible item.
        Initialize();

        // [GIVEN] Eligible item "I" and a user with item edit and ITEM TRACKING CHANGE permissions.
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryLowerPermissions.SetExactPermissionSet('D365 ITEM, EDIT');
        LibraryLowerPermissions.AddO365Basic();
        LibraryLowerPermissions.AddPermissionSet('ITEM TRACKING CHANGE');

        // [WHEN] The user enables lot tracking for item "I".
        ChangeItemTrackingCode(Item, ItemTrackingCode.Code);

        // [THEN] The change is logged.
        VerifyChangeLog(Item."No.", WorkDate(), '', ItemTrackingCode.Code);
    end;

    [Test]
    procedure ChangeLogCannotBeModified()
    var
        Item: Record Item;
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] An item tracking code change-log entry cannot be modified.
        Initialize();

        // [GIVEN] Audit entry "L" for item "I".
        LibraryInventory.CreateItem(Item);
        CreateChangeLog(Item."No.", WorkDate(), '', 'NEW');
        ItemTrackingCodeChangeLog.Get(Item."No.", WorkDate());

        // [WHEN] Audit entry "L" is modified.
        ItemTrackingCodeChangeLog."New Item Tracking Code" := LibraryUtility.GenerateRandomCode(
            ItemTrackingCodeChangeLog.FieldNo("New Item Tracking Code"), Database::"Item Tracking Code Change Log");
        asserterror ItemTrackingCodeChangeLog.Modify(true);

        // [THEN] The immutable-log error is raised.
        Assert.ExpectedError(ChangeLogImmutableErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ChangeLogCannotBeDeleted()
    var
        Item: Record Item;
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] An item tracking code change-log entry cannot be deleted.
        Initialize();

        // [GIVEN] Audit entry "L" for item "I".
        LibraryInventory.CreateItem(Item);
        CreateChangeLog(Item."No.", WorkDate(), '', 'NEW');
        ItemTrackingCodeChangeLog.Get(Item."No.", WorkDate());

        // [WHEN] Audit entry "L" is deleted.
        asserterror ItemTrackingCodeChangeLog.Delete(true);

        // [THEN] The immutable-log error is raised.
        Assert.ExpectedError(ChangeLogImmutableErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ChangeLogCannotBeRenamed()
    var
        Item: Record Item;
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] An item tracking code change-log entry cannot be renamed.
        Initialize();

        // [GIVEN] Audit entry "L" for item "I".
        LibraryInventory.CreateItem(Item);
        CreateChangeLog(Item."No.", WorkDate(), '', 'NEW');
        ItemTrackingCodeChangeLog.Get(Item."No.", WorkDate());

        // [WHEN] Audit entry "L" is renamed.
        asserterror ItemTrackingCodeChangeLog.Rename(Item."No.", WorkDate() - 1);

        // [THEN] The immutable-log error is raised.
        Assert.ExpectedError(ChangeLogImmutableErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure HistoricalTrackingCodeCannotBeDeleted()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] A tracking code referenced as a previous code cannot be deleted.
        Initialize();

        // [GIVEN] Tracking code "T" referenced by an audit entry.
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateChangeLog(Item."No.", WorkDate(), ItemTrackingCode.Code, '');

        // [WHEN] Tracking code "T" is deleted.
        asserterror ItemTrackingCode.Delete(true);

        // [THEN] Deletion is blocked because historical audit information must remain valid.
        Assert.ExpectedError('Item Tracking Code Change Log');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeIsBlockedByOpenItemLedgerEntry()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Tracking cannot change while an item ledger entry remains open.
        Initialize();

        // [GIVEN] Item "I" with an open historical item ledger entry.
        CreateItemWithOpenHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        // [THEN] The open-entry error is collected.
        Assert.ExpectedMessage(StrSubstNo(OpenItemLedgerEntriesExistErr, Item."No."), ErrorMessages.Description.Value);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeIsBlockedByItemLedgerEntryOnChangeDate()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Tracking cannot change on a date that already has item ledger entries.
        Initialize();

        // [GIVEN] Item "I" with closed entries posted on the working date.
        CreateClosedItemHistory(Item, WorkDate(), true, true);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        // [THEN] The posting-date error is collected.
        Assert.ExpectedMessage(
            StrSubstNo(ItemLedgerEntriesOnChangeDateErr, Item."No.", WorkDate()),
            ErrorMessages.Description.Value);
    end;

    [Test]
    procedure TrackingChangeIsBlockedWhenCostIsNotAdjusted()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Tracking cannot change before item costs are adjusted.
        Initialize();

        // [GIVEN] Item "I" with closed history whose costs have not been adjusted.
        CreateClosedItemHistory(Item, WorkDate() - 1, false, false);
        Item.Validate("Cost is Adjusted", false);
        Item.Modify();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        // [THEN] The cost-adjustment error is collected.
        Assert.ExpectedMessage(Item.FieldCaption("Cost is Adjusted"), ErrorMessages.Description.Value);
    end;

    [Test]
    procedure TrackingChangeIsBlockedWhenCostIsNotPostedToGL()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Tracking cannot change before adjusted inventory costs are posted to the general ledger.
        Initialize();

        // [GIVEN] Item "I" with adjusted costs that have not been posted to the general ledger.
        CreateClosedItemHistory(Item, WorkDate() - 1, true, false);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        // [THEN] The cost-posting error is collected.
        Assert.ExpectedMessage(Item.FieldCaption("Cost is Posted to G/L"), ErrorMessages.Description.Value);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeIsBlockedForItemWithExpirationCalculation()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Tracking cannot change for an item with expiration calculation.
        Initialize();

        // [GIVEN] Eligible item "I" with expiration calculation.
        CreateEligibleItemWithHistory(Item);
        Evaluate(Item."Expiration Calculation", '<1M>');
        Item.Modify();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        // [THEN] The expiration-calculation error is collected.
        Assert.ExpectedMessage(Item.FieldCaption("Expiration Calculation"), ErrorMessages.Description.Value);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeIsBlockedByReservationEntry()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Tracking cannot change while reservation entries exist.
        Initialize();

        // [GIVEN] Eligible item "I" with reservation entry "R".
        CreateEligibleItemWithHistory(Item);
        CreateReservationEntry(ReservationEntry, Item."No.");
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        // [THEN] The reservation-entry error is collected.
        Assert.ExpectedMessage(
            StrSubstNo(RecordsExistErr, Item."No.", ReservationEntry.TableCaption()),
            ErrorMessages.Description.Value);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeIsBlockedByOutstandingPurchaseDocument()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseLine: Record "Purchase Line";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Tracking cannot change while an outstanding purchase document exists.
        Initialize();

        // [GIVEN] Eligible item "I" with received quantity not invoiced on purchase line "P".
        CreateEligibleItemWithHistory(Item);
        CreateOutstandingPurchaseLine(PurchaseLine, Item."No.");
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        // [THEN] The purchase-line error is collected.
        Assert.ExpectedMessage(
            StrSubstNo(RecordsExistErr, Item."No.", PurchaseLine.TableCaption()),
            ErrorMessages.Description.Value);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeIsBlockedByItemJournalLine()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Tracking cannot change while an item journal line exists.
        Initialize();

        // [GIVEN] Eligible item "I" with item journal line "J".
        CreateEligibleItemWithHistory(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 1);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        // [THEN] The item-journal-line error is collected.
        Assert.ExpectedMessage(
            StrSubstNo(RecordsExistErr, Item."No.", ItemJournalLine.TableCaption()),
            ErrorMessages.Description.Value);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeIsBlockedByOutstandingWarehouseQuantity()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEntry: Record "Warehouse Entry";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Tracking cannot change while warehouse quantity exists.
        Initialize();

        // [GIVEN] Eligible item "I" with outstanding warehouse quantity.
        CreateEligibleItemWithHistory(Item);
        CreateWarehouseEntry(WarehouseEntry, Item."No.");
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        // [THEN] The warehouse-entry error is collected.
        Assert.ExpectedMessage(
            StrSubstNo(RecordsExistErr, Item."No.", WarehouseEntry.TableCaption()),
            ErrorMessages.Description.Value);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeIsBlockedByServiceItem()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ServiceItem: Record "Service Item";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Tracking cannot change while a service item exists.
        Initialize();

        // [GIVEN] Eligible item "I" with service item "S".
        CreateEligibleItemWithHistory(Item);
        CreateServiceItem(ServiceItem, Item."No.");
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        // [THEN] The service-item error is collected.
        Assert.ExpectedMessage(
            StrSubstNo(RecordsExistErr, Item."No.", ServiceItem.TableCaption()),
            ErrorMessages.Description.Value);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeCollectsMultipleBlockingErrors()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] All tracking-code blockers are collected and shown together.
        Initialize();

        // [GIVEN] Eligible item "I" with reservation entry "R" and item journal line "J".
        CreateEligibleItemWithHistory(Item);
        CreateReservationEntry(ReservationEntry, Item."No.");
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 1);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        // [THEN] Errors for both blocking record types are shown.
        Assert.ExpectedMessage(ReservationEntry.TableCaption(), ErrorMessages.Description.Value);
        ErrorMessages.Next();
        Assert.ExpectedMessage(ItemJournalLine.TableCaption(), ErrorMessages.Description.Value);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Item Tracking Code Changes");
        LibraryLowerPermissions.SetOutsideO365Scope();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Item Tracking Code Changes");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Item Tracking Code Changes");
    end;

    local procedure ChangeItemTrackingCode(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        Item.Get(Item."No.");
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Modify(true);
    end;

    local procedure CreateEligibleItemWithHistory(var Item: Record Item)
    begin
        CreateClosedItemHistory(Item, WorkDate() - 1, true, true);
    end;

    local procedure CreateClosedItemHistory(var Item: Record Item; PostingDate: Date; AdjustCost: Boolean; PostCostToGL: Boolean)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", 1);
        Item.Modify(true);
        PostItemJournalLine(Item."No.", PostingDate, 1);
        PostItemJournalLine(Item."No.", PostingDate, -1);
        if AdjustCost then
            LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        if PostCostToGL then
            PostItemCostToGL(Item."No.", PostingDate);
        Item.Get(Item."No.");
    end;

    local procedure CreateItemWithOpenHistory(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", 1);
        Item.Modify(true);
        PostItemJournalLine(Item."No.", WorkDate() - 1, 1);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        PostItemCostToGL(Item."No.", WorkDate() - 1);
        Item.Get(Item."No.");
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; PostingDate: Date; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostItemCostToGL(ItemNo: Code[20]; PostingDate: Date)
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        PostInventoryCostToGL: Report "Post Inventory Cost to G/L";
        PostMethod: Option "per Posting Group","per Entry";
    begin
        Commit();
        PostValueEntryToGL.SetRange("Item No.", ItemNo);
        PostValueEntryToGL.SetRange("Posting Date", PostingDate);
        PostInventoryCostToGL.InitializeRequest(PostMethod::"per Entry", '', true);
        PostInventoryCostToGL.SetTableView(PostValueEntryToGL);
        PostInventoryCostToGL.UseRequestPage(false);
        PostInventoryCostToGL.SaveAsPdf(GetTemporaryPdfPath());
    end;

    local procedure GetTemporaryPdfPath(): Text
    begin
        exit(TemporaryPath + DelChr(Format(CreateGuid()), '=', '{}') + '.pdf');
    end;

    local procedure CreateChangeLog(ItemNo: Code[20]; ChangeDate: Date; PreviousItemTrackingCode: Code[10]; NewItemTrackingCode: Code[10])
    var
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
    begin
        ItemTrackingCodeChangeLog.Init();
        ItemTrackingCodeChangeLog."Item No." := ItemNo;
        ItemTrackingCodeChangeLog."Change Date" := ChangeDate;
        ItemTrackingCodeChangeLog."Previous Item Tracking Code" := PreviousItemTrackingCode;
        ItemTrackingCodeChangeLog."New Item Tracking Code" := NewItemTrackingCode;
        ItemTrackingCodeChangeLog.Insert(true);
    end;

    local procedure CreateMockItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; PostingDate: Date; Open: Boolean)
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Posting Date" := PostingDate;
        ItemLedgerEntry.Open := Open;
        ItemLedgerEntry.Insert();
    end;

    local procedure CreateReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20])
    begin
        ReservationEntry.Init();
        ReservationEntry."Entry No." := LibraryUtility.GetNewRecNo(ReservationEntry, ReservationEntry.FieldNo("Entry No."));
        ReservationEntry.Positive := true;
        ReservationEntry."Item No." := ItemNo;
        ReservationEntry.Quantity := 1;
        ReservationEntry."Quantity (Base)" := 1;
        ReservationEntry.Insert();
    end;

    local procedure CreateOutstandingPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine."Document No." := LibraryUtility.GenerateGUID();
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := ItemNo;
        PurchaseLine."Qty. Rcd. Not Invoiced" := 1;
        PurchaseLine.Insert();
    end;

    local procedure CreateWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; ItemNo: Code[20])
    begin
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := LibraryUtility.GetNewRecNo(WarehouseEntry, WarehouseEntry.FieldNo("Entry No."));
        WarehouseEntry."Item No." := ItemNo;
        WarehouseEntry."Qty. (Base)" := 1;
        WarehouseEntry.Insert();
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item"; ItemNo: Code[20])
    begin
        ServiceItem.Init();
        ServiceItem."No." := LibraryUtility.GenerateRandomCode(ServiceItem.FieldNo("No."), Database::"Service Item");
        ServiceItem."Item No." := ItemNo;
        ServiceItem.Insert();
    end;

    local procedure TrapTrackingChangeErrors(var Item: Record Item; ItemTrackingCode: Code[10]; var ErrorMessages: TestPage "Error Messages")
    begin
        LibraryErrorMessage.TrapErrorMessages();
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        LibraryErrorMessage.GetTestPage(ErrorMessages);
    end;

    local procedure VerifyItemTrackingCode(ItemNo: Code[20]; ExpectedItemTrackingCode: Code[10])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreEqual(ExpectedItemTrackingCode, Item."Item Tracking Code", 'The item tracking code is incorrect.');
    end;

    local procedure VerifyChangeLog(ItemNo: Code[20]; ChangeDate: Date; PreviousItemTrackingCode: Code[10]; NewItemTrackingCode: Code[10])
    var
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
    begin
        ItemTrackingCodeChangeLog.Get(ItemNo, ChangeDate);
        Assert.AreEqual(
            PreviousItemTrackingCode, ItemTrackingCodeChangeLog."Previous Item Tracking Code",
            'The previous item tracking code is incorrect.');
        Assert.AreEqual(
            NewItemTrackingCode, ItemTrackingCodeChangeLog."New Item Tracking Code",
            'The new item tracking code is incorrect.');
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}
