codeunit 137275 "SCM Inventory Journals"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Journal] [SCM]
        isInitialized := false;
    end;

    var
        ReclassificationItemJournalTemplate: Record "Item Journal Template";
        ReclassificationItemJournalBatch: Record "Item Journal Batch";
        LibraryDimension: Codeunit "Library - Dimension";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        LibraryCosting: Codeunit "Library - Costing";
        ItemLedgerEntryType: Enum "Item Ledger Entry Type";
        isInitialized: Boolean;
        GlobalNewSerialNo: Code[50];
        GlobalNewLotNo: Code[50];
        GlobalItemNo: Code[20];
        GlobalOriginalQuantity: Decimal;
        GlobalItemTrackingAction: Option SelectEntriesSerialNo,SelectEntriesLotNo,AssignSerialNo,EditItemTrackingSerialNo,EditItemTrackingLotNo,EditNewSerialNo,AssignLotNo,EditNewLotNo,CopyInfo,LotNoAvailability,EditLotNo,ModifyQuantity,EditLotNoInformation,EditTrackedQuantity,EditQuantityBase,ItemTrackingSerialAndLot;
        GlobalExpirationDate: Date;
        GlobalDescription: Text[50];
        GlobalComment: Text[80];
        SerialNoListPageCaption: Label 'Serial No. Information List';
        ValidationError: Label 'Caption must be same.';
        SerialNoError: Label 'Serial No. %1 is already on inventory.';
        AvailabilityWarning: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        SerialNoConfirmaton: Label 'Do you want to overwrite the existing information?';
        LotNoConfirmatonQst: Label 'Do you want to overwrite the existing information?';
        LotNoListPageCaption: Label 'Lot No. Information List';
        LotNoInformationError: Label 'Do you want to overwrite the existing information?';
        LocationErr: Label 'Wrong Location Code in Item Journal Line.';
        ErrorMustMatch: Label 'Error must be same.';
        CorrectionsError: Label 'The corrections cannot be saved as excess quantity has been defined.\Close the form anyway?';
        QuantityError: Label 'Quantity must be positive.';
        QuantityErr: Label 'Quantity must be same.';
        LotNumberError: Label 'You must assign a lot number for item %1.', Comment = '%1:Value1';
        QtyToHandleBaseError: Label '%1 in the item tracking assigned to the document line for item %2 is currently %3. It must be %4.\\Check the assignment for serial number %5, lot number %6, package number %7.', Comment = '%1:FieldCaption1,%2:Item No,%3:Actual Qty.,%4:Expected Qty.,%5:Serial No.,%6:Lot,%7:Package';
        NotOnInventoryError: Label 'You have insufficient quantity of Item %1 on inventory.';
        ValueNotMatchedError: Label 'Value must be same.';
        ItemJournalLineNotExistErr: Label '%1 with Variant %2, Location %3, Bin %4 is not exist.';
        ItemJournalLineExistsErr: Label '%1 with Variant %2, Location %3, Bin %4 should be empty.';
        QtyCalculatedErr: Label 'Qty. Calculated is not correct for %1 with Variant %2, Location %3, Bin %4.';
        ItemExistErr: Label 'Item No. must have a value';
        ItemJournalLineDimErr: Label 'Dimensions on Item Journal Line should be same as on Item Ledger Entry if Calculate Inventory using By Dimensions';
        TextGetLastErrorText: Label 'Actual error: ''%1''. Expected: ''%2''';
        RecurringMustNoErr: Label 'Recurring must be equal to ''No''';
        CurrentSaveValuesId: Integer;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalWithMultipleUOM()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        UnitOfMeasureCode: Code[10];
    begin
        // [SCENARIO] Unit Of Measure and Quantity on Item Ledger Entry after posting Item Journal with different Unit Of Measure Code.

        // [GIVEN] Create Item, Item unit Of Measure and two Item Journal Lines with different Unit Of Measure Code and Quantity.
        Initialize();
        CreateItem(Item, Item."Costing Method"::FIFO);
        UnitOfMeasureCode := CreateItemUnitOfMeasure(Item."No.");
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.", WorkDate(), LibraryRandom.RandInt(10));  // Use Random value for Unit Amount.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", ItemJournalLine."Entry Type",
          Item."No.", 2 * ItemJournalLine.Quantity);  // Use Random value for Quantity.
        ModifyUnitOfMeasureOnItemJournal(ItemJournalLine, UnitOfMeasureCode);

        // [WHEN] Post Item Journal Lines.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Verify Item Ledger Entry for Quantity.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Unit of Measure Code", ItemJournalLine."Unit of Measure Code");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, ItemJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,AvailabilityConfirmationHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnItemReclassJournal()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] New Expiration Date and New Serial No. on Item Tracking Lines page.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::AssignSerialNo, LibraryUtility.GetGlobalNoSeriesCode(), false, true,
          GlobalItemTrackingAction::AssignSerialNo);

        // [WHEN]
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [THEN] Verify New Expiration Date and New Serial No. on Item Tracking Lines page, Verification done in 'ItemTrackingPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,SerialNoInformationListPageHander,SerialNumberConfirmationHandler')]
    [Scope('OnPrem')]
    procedure CopyInfoOnSerialNoInformationCard()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Serial No. Information List page caption.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::EditItemTrackingSerialNo, LibraryUtility.GetGlobalNoSeriesCode(),
          false, true, GlobalItemTrackingAction::AssignSerialNo);

        // [WHEN]
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [THEN] Verification done in 'Serial No. Information List page' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,InvokeSerialNoInformationListPageHander,SerialNumberConfirmationHandler')]
    [Scope('OnPrem')]
    procedure PostItemReclassJournalWithItemTracking()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Posting of Item Reclass. Journal.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::EditItemTrackingSerialNo, LibraryUtility.GetGlobalNoSeriesCode(),
          false, true, GlobalItemTrackingAction::AssignSerialNo);
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [WHEN] Post Item Reclass. Journal.
        LibraryInventory.PostItemJournalLine(
          ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // [THEN] Verify Serial Number on Item Ledger Entry.
        VerifySerialNoOnItemLedgerEntry();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerWithAssignTo,InvokeLotNoInformationListPageHander,LotNumberConfirmationHandler')]
    [Scope('OnPrem')]
    procedure PostItemReclassJournalAssignItemTracking()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // [SCENARIO] Posting of Item Reclass. Journal to assign item tracking.

        // [GIVEN] Create and post Purchase Order without Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        PostPurchaseOrderWithoutItemTracking(0);
        Item.Get(GlobalItemNo);
        Item.Validate("Item Tracking Code", FindItemTrackingCode(false, false));
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);

        LibraryInventory.ClearItemJournal(ReclassificationItemJournalTemplate, ReclassificationItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ReclassificationItemJournalLine, ReclassificationItemJournalBatch."Journal Template Name",
          ReclassificationItemJournalBatch.Name, ReclassificationItemJournalLine."Entry Type"::Transfer, GlobalItemNo,
          GlobalOriginalQuantity);
        GlobalItemTrackingAction := GlobalItemTrackingAction::EditItemTrackingLotNo;

        ReclassificationItemJournalLine.OpenItemTrackingLines(true);

        // [WHEN] Post Item Reclass. Journal.
        LibraryInventory.PostItemJournalLine(
          ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // [THEN] Verify Lot Number on Item Ledger Entry.
        VerifyLotNoAndExpirationOnItemLedgerEntry();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,InvokeSerialNoInformationListPageHander,SerialNumberConfirmationHandler')]
    [Scope('OnPrem')]
    procedure ItemReclassJournalWithExistingItemTrackingError()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Error message after Posting Item Reclass. Journal while updating New Serial No. with existing Serial Number.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::EditNewSerialNo, LibraryUtility.GetGlobalNoSeriesCode(), false, true,
          GlobalItemTrackingAction::AssignSerialNo);
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [WHEN] Post Item Reclass. Journal.
        asserterror LibraryInventory.PostItemJournalLine(
            ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // [THEN] Verify Error message.
        Assert.ExpectedError(StrSubstNo(SerialNoError, GlobalNewSerialNo));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingUsingLotOnItemReclassJournal()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] New Lot No. on Item Tracking Lines page.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item without Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::AssignLotNo, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);

        // [WHEN]
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [THEN] Verify New Lot No. on Item Tracking Lines page, Verification done in ItemTrackingPageHandler'ItemTrackingPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,LotNoInformationListPageHander,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure CopyInfoOnLotlNoInformationCard()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Lot No. Information List page caption.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::EditItemTrackingLotNo, LibraryUtility.GetGlobalNoSeriesCode(), true,
          false, GlobalItemTrackingAction::AssignLotNo);

        // [WHEN]
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [THEN] Verification done in 'LotNoInformationListpage' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,InvokeLotNoInformationListPageHander,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure PostItemReclassJournalWithLotNo()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Posting of Item Reclass. Journal with Item Tracking Lot Number.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::EditItemTrackingLotNo, LibraryUtility.GetGlobalNoSeriesCode(), true,
          false, GlobalItemTrackingAction::AssignLotNo);
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [WHEN] Post Item Reclass. Journal.
        LibraryInventory.PostItemJournalLine(
          ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // [THEN] Verify Lot Number on Item Ledger Entry.
        VerifyLotNoOnItemLedgerEntry();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemReclassJournalWithExistingLotNoError()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Error message after Posting Item Reclass. Journal while updating New Lot No. with existing Lot Number.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::EditNewLotNo, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);
        UpdateItemTrackingCode(true, true);
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [WHEN] Post Item Reclass. Journal.
        asserterror LibraryInventory.PostItemJournalLine(
            ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // [THEN] Verify Error message.
        Assert.ExpectedErrorCannotFind(Database::"Lot No. Information");

        // Tear Down.
        UpdateItemTrackingCode(false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,LotNoInformationListPageHander,LotNoInformationConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyInfoOnLotlNoInformationCardError()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Error message on Lot No. Information Card using Copy Info.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::CopyInfo, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);

        // [WHEN]
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [THEN] Verify Error message, verification done in 'LotNoInformationConfirmHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,AvailabilityConfirmHandler')]
    [Scope('OnPrem')]
    procedure AvailabilityErrorOnLotlNoInformationCard()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Lot No. Availability warning.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::LotNoAvailability, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);

        // [WHEN]
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [THEN] Verify error message, verification done in 'AvailabilityConfirmHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure NewExpirationDateError()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
        TrackingSpec: Record "Tracking Specification";
    begin
        // [SCENARIO] Error message after Posting Item Reclass. Journal while updating Lot Number.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::EditLotNo, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [WHEN] Post Item Reclass. Journal.
        asserterror LibraryInventory.PostItemJournalLine(
            ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // [THEN] Verify Error message.
        Assert.ExpectedTestFieldError(TrackingSpec.FieldCaption("New Expiration Date"), Format(GlobalExpirationDate));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,ConfirmationHandler,NothingToPostConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemReclassJournalPostingError()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
        ItemReclassJournal: TestPage "Item Reclass. Journal";
    begin
        // [SCENARIO] Error message while posting Item Reclass. Journal using page.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::SelectEntriesLotNo, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [WHEN] Post Item Reclass. Journal using page.
        ItemReclassJournal.OpenEdit();
        ItemReclassJournal.FILTER.SetFilter("Document No.", ReclassificationItemJournalLine."Document No.");
        ItemReclassJournal.Post.Invoke();

        // [THEN] Verify that the application generates an error as 'There is nothing to post', verification done in 'NothingToPostConfirmHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,InvokeLotNoInformationListPageHander,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure InventoryOnLotNoInformation()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
        LotNoInformation: Record "Lot No. Information";
    begin
        // [SCENARIO] values on Lot No. Information after posting Recalss. Journal.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::EditItemTrackingLotNo, LibraryUtility.GetGlobalNoSeriesCode(), true,
          false, GlobalItemTrackingAction::AssignLotNo);
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);    // Assign Item Tracking on page handler.

        // [WHEN] Post Item Reclass. Journal.
        LibraryInventory.PostItemJournalLine(
          ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // [THEN] Verify values on Lot No. Information after posting Recalss. Journal.
        FindLotNoInformation(LotNoInformation, ReclassificationItemJournalLine."Item No.");
        LotNoInformation.CalcFields(Inventory, Comment);
        LotNoInformation.TestField(Comment, true);
        Assert.AreEqual(LotNoInformation.Inventory, ReclassificationItemJournalLine.Quantity, ErrorMustMatch);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,InvokeLotNoInformationListPageHander,InvokeSerialNoInformationListPageHander,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure SerialAndLotNoOnItemTrackingComment()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
        LotNoInformation: Record "Lot No. Information";
        ItemTrackingComment: Record "Item Tracking Comment";
    begin
        // [SCENARIO] values on Item Tracking Comment using Recalss. Journal.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking. [TFS 455537: Quantity = 1]
        Initialize();
        ReclassificationJournalWithPurchaseOrderWithQty(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::ItemTrackingSerialAndLot, LibraryUtility.GetGlobalNoSeriesCode(), true,
          false, GlobalItemTrackingAction::AssignLotNo, 1);

        // Exercise.
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);    // Assign Item Tracking on page handler.

        // [THEN] Verify values on Item Tracking Comment.
        FindLotNoInformation(LotNoInformation, ReclassificationItemJournalLine."Item No.");
        FindItemTrackingComment(ItemTrackingComment, ItemTrackingComment.Type::"Lot No.", LotNoInformation."Item No.");
        ItemTrackingComment.TestField("Serial/Lot No.", LotNoInformation."Lot No.");

        FindItemTrackingComment(ItemTrackingComment, ItemTrackingComment.Type::"Serial No.", LotNoInformation."Item No.");
        ItemTrackingComment.TestField("Serial/Lot No.", GlobalNewSerialNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,CorrectionsConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingLineErrorWithUpdatedQuantity()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Corrections error message on Item Tracking Lines page while taking greater Quantity (Base).

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::ModifyQuantity, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);

        // Exercise.
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);    // Assign Item Tracking on page handler.

        // [THEN] Verification done in 'CorrectionsPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,InvokeLotNoInformationListPageHander,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure LotNoInformationErrorWithBlockedTrue()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
        LotNoInformation: Record "Lot No. Information";
    begin
        // [SCENARIO] posting Recalss. Journal with Blocked TRUE on Lot No. Information Card page.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::EditLotNoInformation, LibraryUtility.GetGlobalNoSeriesCode(), true,
          false, GlobalItemTrackingAction::AssignLotNo);
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);    // Assign Item Tracking on page handler.

        // [WHEN] Post Item Reclass. Journal.
        asserterror LibraryInventory.PostItemJournalLine(
            ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // [THEN] Verify Error message.
        Assert.ExpectedTestFieldError(LotNoInformation.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,LotNoInformationListPageHander,LotNoInformationConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure LotNoInformationUsingCopyInfo()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] message on Lot No. Information Card using Copy Info and verify value of Lot No on Lot No. Information same as Item Tracking Line.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::CopyInfo, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);

        // [WHEN]
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);  // Assign Item Tracking on page handler.

        // [THEN] Verify Error message, verification done in 'LotNoInformationConfirmHandlerFalse' and 'ItemTrackingLinesPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,InvokeLotNoInformationListPageHander,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesNegativeQuantityBaseError()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] error message while taking negative Quantity (Base) in Item Tracking Line.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::EditTrackedQuantity, LibraryUtility.GetGlobalNoSeriesCode(), true,
          false, GlobalItemTrackingAction::AssignLotNo);

        // Exercise.
        asserterror ReclassificationItemJournalLine.OpenItemTrackingLines(true);    // Assign Item Tracking on page handler.

        // [THEN] Verify Error message.
        Assert.ExpectedError(QuantityError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure ReclassJournalWithItemTrackingError()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] error message while posting Reclassification Journal with Lot Number.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::ModifyQuantity, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);    // Assign Item Tracking on page handler.

        // Exercise.
        asserterror LibraryInventory.PostItemJournalLine(
            ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // [THEN] Verify Error message.
        Assert.ExpectedError(StrSubstNo(LotNumberError, ReclassificationItemJournalLine."Item No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesQuantityHandleBaseError()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
        TrackingSpecification: Record "Tracking Specification";
    begin
        // [SCENARIO] error message while taking less Quantity (Base) on Item Tracking Line than Reclass Journal Quantity.

        // [GIVEN] Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        Initialize();
        ReclassificationJournalWithPurchaseOrder(
          ReclassificationItemJournalLine, GlobalItemTrackingAction::EditQuantityBase, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);
        ReclassificationItemJournalLine.OpenItemTrackingLines(true);    // Assign Item Tracking on page handler.

        // Exercise.
        asserterror LibraryInventory.PostItemJournalLine(
            ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // [THEN] Verify Error message.
        Assert.ExpectedError(
          StrSubstNo(
            QtyToHandleBaseError, TrackingSpecification.FieldCaption("Qty. to Handle (Base)"),
            GlobalItemNo,
            ReclassificationItemJournalLine.Quantity - 1, ReclassificationItemJournalLine.Quantity,
            '', GlobalNewLotNo, ''));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure RevaluationJournalDimension()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        DimensionSetID: Integer;
    begin
        // [SCENARIO] Dimension on Revaluation Journal after posting Transfer Order and running Calculate Inventory Value Report.

        // [GIVEN] Create Item with Dimension, Create and post Transfer Order.
        Initialize();
        CreateItem(Item, Item."Costing Method"::FIFO);
        UpdateItemDimension(DefaultDimension, Item."No.");
        CreateAndPostTransferOrder(Item."No.");

        // Exercise.
        DimensionSetID := RunCalculateInventoryValueReport(DefaultDimension."No.");

        // [THEN] Verify Dimension on Revaluation Journal.
        VerifyDimensionOnRevaluationJournal(DefaultDimension, DimensionSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler,NothingToPostConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnReclassificationJournalWithLocation()
    var
        ReclassificationItemJournalLine: Record "Item Journal Line";
        ItemReclassJournal: TestPage "Item Reclass. Journal";
        Qty: Decimal;
    begin
        // [SCENARIO] error message while posting Reclassfication Journal with Location and without New Location Code.

        // [GIVEN]
        Initialize();
        Qty := LibraryRandom.RandDec(10, 2);
        CreateItemReclassJournal(ReclassificationItemJournalLine, '', '', Qty, Qty + LibraryRandom.RandDec(10, 2));  // Use value blank for Location Code.

        // [WHEN] Post Item Reclass. Journal using page.
        ItemReclassJournal.OpenEdit();
        ItemReclassJournal.FILTER.SetFilter("Document No.", ReclassificationItemJournalLine."Document No.");
        ItemReclassJournal.Post.Invoke();

        // [THEN] Verify 'Nothing To Post' message. Verification done in MessageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorNotOnInventoryOnReclassificationJournal()
    var
        Location: Record Location;
        ReclassificationItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        // [SCENARIO] error message while posting Reclassfication Journal with New Location Code.

        // [GIVEN]
        Initialize();
        Qty := LibraryRandom.RandDec(10, 2);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemReclassJournal(ReclassificationItemJournalLine, Location.Code, '', Qty, Qty + LibraryRandom.RandDec(10, 2));

        // [WHEN] Post Item Reclass. Journal with New Location Code.
        asserterror LibraryInventory.PostItemJournalLine(
            ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // [THEN] Verify Error message.
        Assert.ExpectedError(StrSubstNo(NotOnInventoryError, ReclassificationItemJournalLine."Item No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemUnitCostWithNegativeInventory()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        InventorySetup: Record "Inventory Setup";
        Quantity: Decimal;
        UnitAmount: Decimal;
    begin
        // [SCENARIO] updated Unit cost on Item when Inventory is negative.

        // [GIVEN] Create Item and Stockkeeping Unit, create Location, post Sales entry.
        Initialize();

        LibraryInventory.SetAutomaticCostAdjmtAlways();
        LibraryInventory.SetAverageCostSetup(
          InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant", InventorySetup."Average Cost Period"::Day);

        CreateItem(Item, Item."Costing Method"::Average);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');
        Quantity := LibraryRandom.RandDec(10, 2);  // Use Random value for Quantity.
        UnitAmount := LibraryRandom.RandDec(100, 2);  // Use Random value for Unit Amount.
        UpdateItemInventory(Item."No.", Location.Code, '', Quantity, ItemJournalLine."Entry Type"::Sale, LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Amount.

        // [WHEN] Post Purchase entry.
        UpdateItemInventory(Item."No.", Location.Code, '', Quantity / 2, ItemJournalLine."Entry Type"::Purchase, UnitAmount);

        // [THEN] Verify updated Unit Cost on Item.
        Item.Get(Item."No.");
        Assert.AreNearlyEqual(Item."Unit Cost", UnitAmount, LibraryERM.GetAmountRoundingPrecision(), ValueNotMatchedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemVariantDescriptionOnPhysInventoryLedgerEntry()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemVariant: Record "Item Variant";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        // [SCENARIO] Item Variant Description is updated in Phys. Inventory Ledger when Calculate Inventory on Phys. Inventory Journal.

        // [GIVEN] Create Item with Variant and update Inventory by posting Item Journal.
        Initialize();
        CreateItem(Item, Item."Costing Method"::FIFO);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        UpdateItemInventory(
          Item."No.", '', ItemVariant.Code, LibraryRandom.RandDec(10, 2), ItemJournalLine."Entry Type"::"Positive Adjmt.",
          LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity and Unit Amount.

        // Excercise: Post Physical Inventory Journal after Calculating Inventory.
        CreateAndPostPhysInventoryJournal(ItemJournalLine, ItemJournalBatch, Item."No.", true);

        // [THEN] Check Item Variant Description on Phys. Inventory Ledger.
        PhysInventoryLedgerEntry.SetRange("Item No.", ItemVariant."Item No.");
        PhysInventoryLedgerEntry.FindFirst();
        PhysInventoryLedgerEntry.TestField(Description, ItemVariant.Description);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,CalculateInventory,MultipleDimSelectionHandler')]
    [Scope('OnPrem')]
    procedure DimensionOnPhysInventoryJournal()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Location: Record Location;
        SelectedDimension: Record "Selected Dimension";
        BinCode: Code[20];
    begin
        // [SCENARIO] No Dimension is populated when Calculate Inventory on Phys. Inventory Journal with Bin Mandatory Location.

        // [GIVEN] Create Item with different Dimensions, Create and post Item Journal.
        Initialize();
        BinCode := CreateLocationAndBin(Location);
        CreateItem(Item, Item."Costing Method"::FIFO);
        UpdateItemDimension(DefaultDimension, Item."No.");
        CreateAndPostItemJournal(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", '', Location.Code, BinCode, LibraryRandom.RandDec(10, 2)); // Use Random values for Quantity.

        // [WHEN] Create Phys. Inventory Journal and Calculate Inventory with By Dimensions.
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Code");
        LibraryVariableStorage.Enqueue(Item."No.");
        RunCalculateInventoryByDimensions(ItemJournalBatch);

        // [THEN] Item journal line has no dimensions.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch, Item."No.");
        ItemJournalLine.TestField("Dimension Set ID", 0);

        // Tear Down
        SelectedDimension.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure DimensionOnPhysInventoryJournalWhenItemDefaultDimensionValueIsEmpty()
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        DimSetID: Integer;
    begin
        // [FEATURE] [Dimensions] [Calculate Inventory] [Default Dimension]
        // [SCENARIO 381581] Calculate Inventory report for Item where Default dimension value is not specified
        Initialize();

        // [GIVEN] Item where default dimension "Dim1" with value "Val1", second default dimension "Dim2" with value empty but mandatory
        CreateItem(Item, Item."Costing Method"::FIFO);
        UpdateItemDimension(DefaultDimension, Item."No.");
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Item, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Dimension Value Code", '');
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);

        // [GIVEN] Item Journal Line created with default dimension "Dim1" with value "Val1" matching Dimension Set ID = "DS"
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", WorkDate(), LibraryRandom.RandDec(10, 2));
        DimSetID := ItemJournalLine."Dimension Set ID";
        // [GIVEN] Posted Item Journal Line with updated mandatory dimension "Dim2" with value "Val2"
        ItemJournalLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Dimension Set ID",
          LibraryDimension.CreateDimSet(ItemJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Run Calculate Inventory in Phys. Inventory Journal
        ItemJournalBatch.Init();
        CreateAndPostPhysInventoryJournal(ItemJournalLine, ItemJournalBatch, Item."No.", false);

        // [THEN] Phys. Inventory Journal is created with Dimension Set ID = "DS"
        ItemJournalLine.Find();
        ItemJournalLine.TestField("Dimension Set ID", DimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,VerifyDimensionSetEntryHandler')]
    [Scope('OnPrem')]
    procedure CalcInventoryUsesDefaultDimOfItemIfByDimIsNotSetUpForBinMandatoryLocation()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Location: Record Location;
        BinCode: Code[20];
    begin
        // [FEATURE] [Dimensions] [Physical Inventory]
        // [SCENARIO 362270] Dimensions are copied to Item Journal Line from Item's Default Dimensions by "Calculate Inventory" job ran with blank "By Dimension" with Bin Mandatory Location
        Initialize();

        // [GIVEN] Item Ledger Entry with "Dimension Code" = "D" for Bin Mandatory Location
        // [GIVEN] Bin Mandatory Location
        BinCode := CreateLocationAndBin(Location);
        CreateItem(Item, Item."Costing Method"::FIFO);
        UpdateItemDimension(DefaultDimension, Item."No.");
        CreateAndPostItemJournal(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", '', Location.Code, BinCode, LibraryRandom.RandDec(10, 2)); // Use Random values for Quantity.

        // [WHEN] Calculate Inventory where "By Dimensions" is blank
        CreateAndPostPhysInventoryJournal(ItemJournalLine, ItemJournalBatch, Item."No.", false);

        // [THEN] Created Item Journal Line with dimension set to "D"
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch, Item."No.");
        LibraryVariableStorage.Enqueue(DefaultDimension);
        ItemJournalLine.ShowDimensions();
    end;

    [Test]
    [HandlerFunctions('VerifyDimensionSetEntryHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryUsesDefaultDimensionOfItemIfByDimensionIsNotSetUp()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Dimensions] [Physical Inventory]
        // [SCENARIO 361495] Dimensions are copied to Item Journal Line from Item's Default Dimensions by "Calculate Inventory" job ran with blank "By Dimension"
        Initialize();

        // [GIVEN] Item with Default Dimension "D" = "X"
        CreateItem(Item, Item."Costing Method"::FIFO);
        UpdateItemDimensionUsingGlobal(DefaultDimension, Item."No.");
        CreateAndPostItemJournal(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", '', '', '', LibraryRandom.RandDec(10, 2));

        // [WHEN] Calculate Inventory where "By Dimensions" is blank
        CreateAndPostPhysInventoryJournal(ItemJournalLine, ItemJournalBatch, Item."No.", false);

        // [THEN] Created Item Journal Line has dimension "D" = "X"
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch, Item."No.");
        LibraryVariableStorage.Enqueue(DefaultDimension);
        ItemJournalLine.ShowDimensions();
    end;

    [Test]
    [HandlerFunctions('CalculateInventory,MultipleDimSelectionHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryUsesDimensionOfItemJournalLineIfByDimensionIsSetUp()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        SelectedDimension: Record "Selected Dimension";
        DimSetID: array[2] of Integer;
        DimCode: Code[20];
    begin
        // [FEATURE] [Dimensions] [Physical Inventory]
        // [SCENARIO 361495] Dimensions are copied through Item Journal Line by "Calculate Inventory" job ran with "By Dimension" not blank
        Initialize();

        // [GIVEN] Item Ledger Entry 1 with "Dimension Code" = "D" and "Dimension Value Code" = "C1"
        // [GIVEN] Item Ledger Entry 2 with Dimension Code = "D" and "Dimension Value Code" = "C2"
        CreateItem(Item, Item."Costing Method"::FIFO);
        DimCode := GetGlobalDimCode();

        CreateAndPostItemJournalWithDimension(
          DimSetID[1], DimCode, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(10, 2));
        CreateAndPostItemJournalWithDimension(
          DimSetID[2], DimCode, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(10, 2));

        // [WHEN] Calculate Inventory where "By Dimensions" is set to "D"
        LibraryVariableStorage.Enqueue(DimCode);
        LibraryVariableStorage.Enqueue(Item."No.");
        RunCalculateInventoryByDimensions(ItemJournalBatch);

        // [THEN] Created Item Journal Line 1 with "Dimension Code" = "D" and "Dimension Value Code" = "C1"
        // [THEN] Created Item Journal Line 2 with "Dimension Code" = "D" and "Dimension Value Code" = "C2"
        VerifyDimOnItemJournalLine(ItemJournalBatch, Item."No.", DimSetID);

        // Tear Down
        SelectedDimension.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryIncludeItemWithoutTransactionHandler')]
    [Scope('OnPrem')]
    procedure CalcInventoryWithIncludeItemWithoutTransactionComplexLocationFilter()
    var
        Item: Record Item;
        Location: array[2] of Record Location;
        LocationCode: array[2] of Code[10];
    begin
        // [FEATURE] [Physical Inventory]
        // [SCENARIO 378919] Two lines should be added in Phys. Inventory Journal after setting Location Filter = "L1|L2" in Calculate Inventory page.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create two Locations: "L1" and "L2".
        LocationCode[1] := LibraryWarehouse.CreateLocation(Location[1]);
        LocationCode[2] := LibraryWarehouse.CreateLocation(Location[2]);

        // [WHEN] Invoke Calculate Inventory with Location Filter = "L1|L2".
        CalculateInventoryAndGetLocationCodeFromFirstTwoLines(Item."No.", LocationCode);

        // [THEN] Two Phys. Inventory Journal Lines are populated: with "Location Code" = "L1" and "Location Code" = "L2"
        Assert.AreEqual(Location[1].Code, LocationCode[1], LocationErr);
        Assert.AreEqual(Location[2].Code, LocationCode[2], LocationErr);
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryIncludeItemWithoutTransactionHandler')]
    [Scope('OnPrem')]
    procedure CalcInventoryWithIncludeItemWithoutTransactionEmptyLocationFilter()
    var
        Item: Record Item;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Physical Inventory]
        // [SCENARIO 378919] "Location Code" field in Phys. Inventory Journal Line should be empty after Calculate Inventory if filter is blank.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [WHEN] Invoke Calculate Inventory with blank location filter.
        LocationCode := CalculateInventoryAndGetLocationCodeFromLastLine(Item."No.", '');

        // [THEN] Phys. Inventory Journal Line is populated: with blank "Location Code".
        Assert.AreEqual('', LocationCode, LocationErr);
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryIncludeItemWithoutTransactionHandler')]
    [Scope('OnPrem')]
    procedure CalcInventoryWithIncludeItemWithoutTransactionAppropriateLocationFilter()
    var
        Item: Record Item;
        Location: Record Location;
        LocationCode: Code[10];
    begin
        // [FEATURE] [Physical Inventory]
        // [SCENARIO 378919] "Location Code" field in Phys. Inventory Journal line should be empty after Calculate Inventory if transit location is selected in Location Filter.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create transit location "L".
        LibraryWarehouse.CreateInTransitLocation(Location);

        // [WHEN] Invoke Calculate Inventory with Location Filter = "L".
        LocationCode := CalculateInventoryAndGetLocationCodeFromLastLine(Item."No.", Location.Code);

        // [THEN] Phys. Inventory Journal Line is populated: with blank "Location Code"
        Assert.AreEqual('', LocationCode, LocationErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemReclassJournalFromLocationToBinMandatoryLocation()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ReclassificationItemJournalLine: Record "Item Journal Line";
        BinCode: Code[10];
        Qty: Decimal;
    begin
        // [THEN] Verify we can use Item Reclass. Journal to transfer item from non Bin Mandatory Location to Bin Mandatory Location.

        // [GIVEN] Create Location with Bin.
        Initialize();
        Qty := LibraryRandom.RandDec(10, 2);
        BinCode := CreateLocationAndBin(Location);

        // [WHEN] Create and post Item Reclass. Journal from a non Bin Mandatory Location to a Bin Mandatory Location.
        CreateItemReclassJournal(ReclassificationItemJournalLine, Location.Code, BinCode, Qty, Qty);
        LibraryInventory.PostItemJournalLine(
          ReclassificationItemJournalLine."Journal Template Name", ReclassificationItemJournalLine."Journal Batch Name");

        // Verfiy: Verify Item was already transfered into Bin Mandatory Location.
        FindItemLedgerEntryWithLocation(
          ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Transfer, ReclassificationItemJournalLine."Item No.", Location.Code);
        Assert.AreEqual(ItemLedgerEntry.Quantity, Qty, QuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryForItemWithMultipleVariantsAndLocations()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Location: array[3] of Record Location;
        ItemVariant: array[3] of Record "Item Variant";
        BinCode: array[3] of Code[20];
        i: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO] all inventory are calculated for item when inventory exists multiple variants and locations.

        // [GIVEN] Create Item with two Variants and create two Locations with Bins.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Costing Method"::FIFO);
        for i := 1 to 2 do begin
            LibraryInventory.CreateItemVariant(ItemVariant[i], Item."No.");
            BinCode[3 - i] := CreateLocationAndBin(Location[3 - i]);
        end;

        ItemVariant[3] := ItemVariant[2];
        Location[3] := Location[1];
        BinCode[3] := BinCode[1];

        // Create and Post three Item Journals.
        // 1st: ItemVariant[1].Code, Location[2].Code, BinCode[2]
        // 2nd: ItemVariant[2].Code, Location[1].Code, BinCode[1]
        // 3rd: ItemVariant[2].Code, Location[2].Code, BinCode[2]
        for i := 1 to ArrayLen(ItemVariant) do
            CreateAndPostItemJournal(
              ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", ItemVariant[i].Code, Location[i].Code, BinCode[i], Quantity);

        // [WHEN] Create Phys. Inventory Journal and Calculate Inventory.
        CreateAndPostPhysInventoryJournal(ItemJournalLine, ItemJournalBatch, Item."No.", false); // FALSE means do not post the Phys. Inventory Journal.

        // [THEN] Verify all inventory are calculated for item on Item Journal Line.
        for i := 1 to ArrayLen(ItemVariant) do
            VerifyItemJournalLine(Item."No.", ItemVariant[i].Code, Location[i].Code, BinCode[i], Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcInvtWithInclItemWithoutTransactionForItemsWithAndWithoutVariants()
    var
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        ItemNo: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 253621] When one item does have a variant and another one does not, Calculate Inventory run with "Include items without transaction" setting, creates two lines, one per each item, without errors.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item "I1" with variant "V1", item "I2" with no variants.
        ItemNo[1] := LibraryInventory.CreateItemNo();
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo[1]);
        ItemNo[2] := LibraryInventory.CreateItemNo();

        // [GIVEN] Post positive adjustment for item "I1" and variant "V1".
        CreateAndPostItemJournal(
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo[1], ItemVariant.Code, Location.Code, '', Qty);

        // [WHEN] Create phys. inventory journal and calculate inventory with "Include items without transaction" option for both "I1" and "I2".
        CalculateInventoryWithItemFilters(StrSubstNo('%1|%2', ItemNo[1], ItemNo[2]), Location.Code, '', true, true);

        // [THEN] Two lines are created - the first is with item "I1" and variant "V1", the second is with item "I2" and no variant code.
        VerifyItemJournalLine(ItemNo[1], ItemVariant.Code, Location.Code, '', Qty);
        VerifyItemJournalLine(ItemNo[2], '', Location.Code, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcInvtWithInclItemWithoutTransactionWithVariantFilter()
    var
        ItemVariant: array[3, 3] of Record "Item Variant";
        ItemNo: array[3] of Code[20];
        ItemNoFilter: Text;
        i: Integer;
        j: Integer;
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 253621] When you set "Variant filter" and enable "Include items without transaction" on Calculate Inventory, the job creates lines for all variants of all items.
        Initialize();

        // [GIVEN] Three items "I1", "I2", "I3", each item has three variants.
        for i := 1 to ArrayLen(ItemNo) do begin
            ItemNo[i] := LibraryInventory.CreateItemNo();
            ItemNoFilter := ItemNoFilter + '|' + ItemNo[i];
            for j := 1 to ArrayLen(ItemVariant[i]) do
                LibraryInventory.CreateItemVariant(ItemVariant[i] [j], ItemNo[i]);
        end;
        ItemNoFilter := CopyStr(ItemNoFilter, 2);

        // [WHEN] Create phys. inventory journal and calculate inventory with "Include items without transaction" option for items "I1", "I2", "I3" and variant filter "<>''" (not blank).
        CalculateInventoryWithItemFilters(ItemNoFilter, '', StrSubstNo('<>%1', ''''''), true, true);

        // [THEN] Nine (3 * 3) lines are created - one per each variant (3) of each item (3).
        for i := 1 to ArrayLen(ItemNo) do
            for j := 1 to ArrayLen(ItemVariant[i]) do
                VerifyItemJournalLine(ItemNo[i], ItemVariant[i] [j].Code, '', '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcInvtWithInclItemWithoutTransactionWithLocationAndVariantFilter()
    var
        Location: array[3] of Record Location;
        ItemVariant: array[3, 3] of Record "Item Variant";
        ItemNo: array[3] of Code[20];
        ItemNoFilter: Text;
        LocationFilter: Text;
        i: Integer;
        j: Integer;
        k: Integer;
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 253621] When you set "Location Filter" and "Variant filter" and enable "Include items without transaction" on Calculate Inventory, the job creates lines for all combinations of locations, variants and items.
        Initialize();

        // [GIVEN] Three locations "L1", "L2", "L3".
        for k := 1 to ArrayLen(Location) do begin
            LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[k]);
            LocationFilter := LocationFilter + '|' + Location[k].Code;
        end;
        LocationFilter := CopyStr(LocationFilter, 2);

        // [GIVEN] Three items "I1", "I2", "I3", each item has three variants.
        for i := 1 to ArrayLen(ItemNo) do begin
            ItemNo[i] := LibraryInventory.CreateItemNo();
            ItemNoFilter := ItemNoFilter + '|' + ItemNo[i];
            for j := 1 to ArrayLen(ItemVariant[i]) do
                LibraryInventory.CreateItemVariant(ItemVariant[i] [j], ItemNo[i]);
        end;
        ItemNoFilter := CopyStr(ItemNoFilter, 2);

        // [WHEN] Create phys. inventory journal and calculate inventory with "Include items without transaction" option for items "I1", "I2", "I3", location filter "L1|L2|L3" and variant filter "<>''" (not blank).
        CalculateInventoryWithItemFilters(ItemNoFilter, LocationFilter, StrSubstNo('<>%1', ''''''), true, true);

        // [THEN] Twenty seven (3 * 3 * 3) lines are created - one per each combination of location (3), item (3) and variant (3).
        for k := 1 to ArrayLen(Location) do
            for i := 1 to ArrayLen(ItemNo) do
                for j := 1 to ArrayLen(ItemVariant[i]) do
                    VerifyItemJournalLine(ItemNo[i], ItemVariant[i] [j].Code, Location[k].Code, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckQuantityOnItemJournalLineWithBlankItem()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 364321] An error is thrown while validating Quantity with blank "Item No."

        // [GIVEN] Item Journal Line with "Item No." blank
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Positive Adjmt.");

        // [WHEN] Set Quantity to "X"
        asserterror ItemJournalLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));

        // [THEN] Error is thrown: "Item No. must have a value"
        Assert.ExpectedError(ItemExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLocationOnItemJournalLineWithBlankItem()
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 364321] An error is thrown while validating Location Code with blank "Item No."

        // [GIVEN] Location with Code = "X"
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Item Journal Line with "Item No." blank
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Transfer);

        // [WHEN] Set Location Code to "X"
        asserterror ItemJournalLine.Validate("Location Code", Location.Code);

        // [THEN] Error is thrown: "Item No. must have a value"
        Assert.ExpectedError(ItemExistErr);
    end;

    [Test]
    [HandlerFunctions('CalculateInventoryIncludeItemWithoutTransactionHandler')]
    [Scope('OnPrem')]
    procedure ShouldNotGenerateInventoryLinesForInTransitLocations()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        PhysInvJournal: TestPage "Phys. Inventory Journal";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO] We should not create item journal lines for in-transit locations in the physical inventory journal
        // as we cannot post them.
        Initialize();

        // [GIVEN] A from-, to- and in-transit location with an item located at the from location.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Location Code", FromLocation.Code);
        PurchaseLine.Modify(true);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] A shipped transfer order.
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        Commit();

        // [WHEN] Calculating inventory for items not on inventory.
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue('');
        PhysInvJournal.OpenEdit();
        PhysInvJournal.CalculateInventory.Invoke();

        // [THEN] No item journal line is created for the in-transit location.
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindSet();
        repeat
            Assert.AreNotEqual(
                ItemJournalLine."Location Code",
                InTransitLocation.Code,
                'Expected in-transit location to not appear in Item Journal Line.'
            );
        until ItemJournalLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryWithZeroQtyFalse_PositiveAmount()
    var
        ItemVariant: array[2] of Record "Item Variant";
        Location: Record Location;
        StockKeepingUnit: Record "Stockkeeping Unit";
        ItemNo: Code[20];
        Qty: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 439359] Run calculate inventory with "Items not on inventory" = false for Item with existings quantity on inventory.
        Initialize();


        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item "I" exists with 2 Variants: "V1" and "V2"
        ItemNo := CreateItemWith2Variants(ItemVariant);

        // [GIVEN] Stockkeeping Unit for Item Variant "V1" exists
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockKeepingUnit, Location.Code, ItemNo, ItemVariant[1].Code);

        // [GIVEN] Positive adjustments for I-V1, I-V2 and I are posted.
        for i := 1 to 3 do
            Qty[i] := LibraryRandom.RandInt(10);
        CreateAndPostItemJournal(ItemLedgerEntryType::"Positive Adjmt.", ItemNo, ItemVariant[1].Code, Location.Code, '', Qty[1]);
        CreateAndPostItemJournal(ItemLedgerEntryType::"Positive Adjmt.", ItemNo, ItemVariant[2].Code, Location.Code, '', Qty[2]);
        CreateAndPostItemJournal(ItemLedgerEntryType::"Positive Adjmt.", ItemNo, '', Location.Code, '', Qty[3]);

        // [WHEN] Run "Calculate Inventory" for Item "I" with "Items not on inventory" = false
        CalculateInventoryWithItemFilters(ItemNo, '', '', false, false);

        // [THEN] Line for Item "I" variant "V1" was created with positive quantity
        VerifyItemJournalLine(ItemNo, ItemVariant[1].Code, Location.Code, '', Qty[1]);

        // [THEN] Line for Item "I" variant "V2" was created with positive quantity
        VerifyItemJournalLine(ItemNo, ItemVariant[2].Code, Location.Code, '', Qty[2]);

        // [THEN] Line for Item "I" with no variant was created with positive quantity
        VerifyItemJournalLine(ItemNo, '', Location.Code, '', Qty[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryWithZeroQtyFalse_ZeroAmount()
    var
        ItemVariant: array[2] of Record "Item Variant";
        Location: Record Location;
        StockKeepingUnit: Record "Stockkeeping Unit";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 439359] Run calculate inventory with "Items not on inventory" = false for Item with existings transactions, but 0 quantity on inventory.
        Initialize();

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item "I" exists with 2 Variants: "V1" and "V2"
        ItemNo := CreateItemWith2Variants(ItemVariant);

        // [GIVEN] Stockkeeping Unit for Item Variant "V1" exists
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockKeepingUnit, Location.Code, ItemNo, ItemVariant[1].Code);

        // [GIVEN] Each combination (I-V1, I-V2 and I-"") has two transactions of +X and -X, so total inventory is 0
        PostTwoSymmetricAdjustments(ItemNo, ItemVariant[1].Code, Location.Code);
        PostTwoSymmetricAdjustments(ItemNo, ItemVariant[2].Code, Location.Code);
        PostTwoSymmetricAdjustments(ItemNo, '', Location.Code);

        // [WHEN] Run "Calculate Inventory" for Item "I" with "Items not on inventory" = false
        CalculateInventoryWithItemFilters(ItemNo, '', '', false, false);

        // [THEN] Line for Item "I" variant "V1" was NOT created
        VerifyNoItemJournalLineExists(ItemNo, ItemVariant[1].Code, Location.Code);

        // [THEN] Line for Item "I" variant "V2" was NOT created
        VerifyNoItemJournalLineExists(ItemNo, ItemVariant[2].Code, Location.Code);

        // [THEN] Line for Item "I" with no variant was NOT created
        VerifyNoItemJournalLineExists(ItemNo, '', Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryWithZeroQtyFalse_NoTransactions()
    var
        ItemVariant: array[2] of Record "Item Variant";
        Location: Record Location;
        StockKeepingUnit: Record "Stockkeeping Unit";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 439359] Run calculate inventory with "Items not on inventory" = false for Item with no existings transactions.
        Initialize();

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item "I" exists with 2 Variants: "V1" and "V2"
        ItemNo := CreateItemWith2Variants(ItemVariant);

        // [GIVEN] Stockkeeping Unit for Item Variant "V1" exists
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockKeepingUnit, Location.Code, ItemNo, ItemVariant[1].Code);

        // [WHEN] Run "Calculate Inventory" for Item "I" with "Items not on inventory" = false
        CalculateInventoryWithItemFilters(ItemNo, '', '', false, false);

        // [THEN] Line for Item "I" variant "V1" was NOT created
        VerifyNoItemJournalLineExists(ItemNo, ItemVariant[1].Code, Location.Code);

        // [THEN] Line for Item "I" variant "V2" was NOT created
        VerifyNoItemJournalLineExists(ItemNo, ItemVariant[2].Code, Location.Code);

        // [THEN] Line for Item "I" with no variant was NOT created
        VerifyNoItemJournalLineExists(ItemNo, '', Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryWithZeroQtyTrue_PositiveAmount()
    var
        ItemVariant: array[2] of Record "Item Variant";
        Location: Record Location;
        StockKeepingUnit: Record "Stockkeeping Unit";
        ItemNo: Code[20];
        Qty: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 439359] Run calculate inventory with "Items not on inventory" = true, "Items without Transactions" = false for Item with existings quantity on inventory.
        Initialize();

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item "I" exists with 2 Variants: "V1" and "V2"
        ItemNo := CreateItemWith2Variants(ItemVariant);

        // [GIVEN] Stockkeeping Unit for Item Variant "V1" exists
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockKeepingUnit, Location.Code, ItemNo, ItemVariant[1].Code);

        // [GIVEN] Positive adjustments for I-V1, I-V2 and I are posted.
        for i := 1 to 3 do
            Qty[i] := LibraryRandom.RandInt(10);
        CreateAndPostItemJournal(ItemLedgerEntryType::"Positive Adjmt.", ItemNo, ItemVariant[1].Code, Location.Code, '', Qty[1]);
        CreateAndPostItemJournal(ItemLedgerEntryType::"Positive Adjmt.", ItemNo, ItemVariant[2].Code, Location.Code, '', Qty[2]);
        CreateAndPostItemJournal(ItemLedgerEntryType::"Positive Adjmt.", ItemNo, '', Location.Code, '', Qty[3]);

        // [WHEN] Run "Calculate Inventory" for Item "I" with "Items not on inventory" = true, "Items with no transactions" = false
        CalculateInventoryWithItemFilters(ItemNo, '', '', true, false);

        // [THEN] Line for Item "I" variant "V1" was created with positive quantity
        VerifyItemJournalLine(ItemNo, ItemVariant[1].Code, Location.Code, '', Qty[1]);

        // [THEN] Line for Item "I" variant "V2" was created with positive quantity
        VerifyItemJournalLine(ItemNo, ItemVariant[2].Code, Location.Code, '', Qty[2]);

        // [THEN] Line for Item "I" with no variant was created with positive quantity
        VerifyItemJournalLine(ItemNo, '', Location.Code, '', Qty[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryWithZeroQtyTrue_ZeroAmount()
    var
        ItemVariant: array[2] of Record "Item Variant";
        Location: Record Location;
        StockKeepingUnit: Record "Stockkeeping Unit";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 439359] Run calculate inventory with "Items not on inventory" = true, "Items without Transactions" = false for Item with existings transactions, but 0 quantity on inventory.
        Initialize();

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item "I" exists with 2 Variants: "V1" and "V2"
        ItemNo := CreateItemWith2Variants(ItemVariant);

        // [GIVEN] Stockkeeping Unit for Item Variant "V1" exists
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockKeepingUnit, Location.Code, ItemNo, ItemVariant[1].Code);

        // [GIVEN] Each combination (I-V1, I-V2 and I-"") has two transactions of +X and -X, so total inventory is 0
        PostTwoSymmetricAdjustments(ItemNo, ItemVariant[1].Code, Location.Code);
        PostTwoSymmetricAdjustments(ItemNo, ItemVariant[2].Code, Location.Code);
        PostTwoSymmetricAdjustments(ItemNo, '', Location.Code);

        // [WHEN] Run "Calculate Inventory" for Item "I" with "Items not on inventory" = true, "Items with no transactions" = false
        CalculateInventoryWithItemFilters(ItemNo, '', '', true, false);

        // [THEN] Line for Item "I" variant "V1" was created with quantity = 0
        VerifyItemJournalLine(ItemNo, ItemVariant[1].Code, Location.Code, '', 0);

        // [THEN] Line for Item "I" variant "V2" was created with quantity = 0
        VerifyItemJournalLine(ItemNo, ItemVariant[2].Code, Location.Code, '', 0);

        // [THEN] Line for Item "I" no variant was created with quantity = 0
        VerifyItemJournalLine(ItemNo, '', Location.Code, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryWithZeroQtyTrue_NoTransactions()
    var
        ItemVariant: array[2] of Record "Item Variant";
        Location: Record Location;
        StockKeepingUnit: Record "Stockkeeping Unit";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 439359] Run calculate inventory with "Items not on inventory" = true, "Items without Transactions" = false for Item with no transactions.
        Initialize();

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item "I" exists with 2 Variants: "V1" and "V2"
        ItemNo := CreateItemWith2Variants(ItemVariant);

        // [GIVEN] Stockkeeping Unit for Item Variant "V1" exists
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockKeepingUnit, Location.Code, ItemNo, ItemVariant[1].Code);

        // [WHEN] Run "Calculate Inventory" for Item "I" with "Items not on inventory" = true, "Items with no transactions" = false
        CalculateInventoryWithItemFilters(ItemNo, '', '', true, false);

        // [THEN] Line for Item "I" variant "V1" was created with quantity = 0 because of existing SKU
        VerifyItemJournalLine(ItemNo, ItemVariant[1].Code, Location.Code, '', 0);

        // [THEN] Line for Item "I" variant "V2" was NOT created
        VerifyNoItemJournalLineExists(ItemNo, ItemVariant[2].Code, Location.Code);

        // [THEN] Line for Item "I" with no variant was NOT created
        VerifyNoItemJournalLineExists(ItemNo, '', Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryWithNoTransactionsTrue_PositiveAmount()
    var
        ItemVariant: array[2] of Record "Item Variant";
        Location: Record Location;
        StockKeepingUnit: Record "Stockkeeping Unit";
        ItemNo: Code[20];
        Qty: array[3] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 439359] Run calculate inventory with "Items without Transactions" = true for Item with existings quantity on inventory.
        Initialize();

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item "I" exists with 2 Variants: "V1" and "V2"
        ItemNo := CreateItemWith2Variants(ItemVariant);

        // [GIVEN] Stockkeeping Unit for Item Variant "V1" exists
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockKeepingUnit, Location.Code, ItemNo, ItemVariant[1].Code);

        // [GIVEN] Positive adjustments for I-V1, I-V2 and I are posted.
        for i := 1 to 3 do
            Qty[i] := LibraryRandom.RandInt(10);
        CreateAndPostItemJournal(ItemLedgerEntryType::"Positive Adjmt.", ItemNo, ItemVariant[1].Code, Location.Code, '', Qty[1]);
        CreateAndPostItemJournal(ItemLedgerEntryType::"Positive Adjmt.", ItemNo, ItemVariant[2].Code, Location.Code, '', Qty[2]);
        CreateAndPostItemJournal(ItemLedgerEntryType::"Positive Adjmt.", ItemNo, '', Location.Code, '', Qty[3]);

        // [WHEN] Run "Calculate Inventory" for Item "I" with "Items not on inventory" = true, "Items with no transactions" = true
        CalculateInventoryWithItemFilters(ItemNo, '', '', true, true);

        // [THEN] Line for Item "I" variant "V1" was created with positive quantity
        VerifyItemJournalLine(ItemNo, ItemVariant[1].Code, Location.Code, '', Qty[1]);

        // [THEN] Line for Item "I" variant "V2" was created with positive quantity
        VerifyItemJournalLine(ItemNo, ItemVariant[2].Code, Location.Code, '', Qty[2]);

        // [THEN] Line for Item "I" with no variant was created with positive quantity
        VerifyItemJournalLine(ItemNo, '', Location.Code, '', Qty[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryWithNoTransactionsTrue_ZeroAmount()
    var
        ItemVariant: array[2] of Record "Item Variant";
        Location: Record Location;
        StockKeepingUnit: Record "Stockkeeping Unit";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 439359] Run calculate inventory with "Items without Transactions" = true for Item with existings transactions, but 0 quantity on inventory.
        Initialize();

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item "I" exists with 2 Variants: "V1" and "V2"
        ItemNo := CreateItemWith2Variants(ItemVariant);

        // [GIVEN] Stockkeeping Unit for Item Variant "V1" exists
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockKeepingUnit, Location.Code, ItemNo, ItemVariant[1].Code);

        // [GIVEN] Each combination (I-V1, I-V2 and I-"") has two transactions of +X and -X, so total inventory is 0
        PostTwoSymmetricAdjustments(ItemNo, ItemVariant[1].Code, Location.Code);
        PostTwoSymmetricAdjustments(ItemNo, ItemVariant[2].Code, Location.Code);
        PostTwoSymmetricAdjustments(ItemNo, '', Location.Code);

        // [WHEN] Run "Calculate Inventory" for Item "I" with "Items not on inventory" = true, "Items with no transactions" = true
        CalculateInventoryWithItemFilters(ItemNo, '', '', true, true);

        // [THEN] Line for Item "I" variant "V1" was created with quantity = 0
        VerifyItemJournalLine(ItemNo, ItemVariant[1].Code, Location.Code, '', 0);

        // [THEN] Line for Item "I" variant "V2" was created with quantity = 0
        VerifyItemJournalLine(ItemNo, ItemVariant[2].Code, Location.Code, '', 0);

        // [THEN] Line for Item "I" no variant was created with quantity = 0
        VerifyItemJournalLine(ItemNo, '', Location.Code, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateInventoryWithNoTransactionsTrue_NoTransactions()
    var
        ItemVariant: array[2] of Record "Item Variant";
        Location: Record Location;
        StockKeepingUnit: Record "Stockkeeping Unit";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Physical Inventory] [Item Variant]
        // [SCENARIO 439359] Run calculate inventory with "Items without Transactions" = true for Item with no transactions.
        Initialize();

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Item "I" exists with 2 Variants: "V1" and "V2"
        ItemNo := CreateItemWith2Variants(ItemVariant);

        // [GIVEN] Stockkeeping Unit for Item Variant "V1" exists
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockKeepingUnit, Location.Code, ItemNo, ItemVariant[1].Code);

        // [WHEN] Run "Calculate Inventory" for Item "I" with "Items not on inventory" = true, "Items with no transactions" = true
        CalculateInventoryWithItemFilters(ItemNo, '', '', true, true);

        // [THEN] Line for Item "I" variant "V1" was created with quantity = 0 because of existing SKU
        VerifyItemJournalLine(ItemNo, ItemVariant[1].Code, Location.Code, '', 0);

        // [THEN] Line for Item "I" variant "V2" was NOT created
        VerifyNoItemJournalLineExists(ItemNo, ItemVariant[2].Code, Location.Code);

        // [THEN] Line for Item "I" with no variant was created with quantity = 0
        VerifyItemJournalLine(ItemNo, '', '', '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTrackingOnLinesRestrictedToTemplateTypeItemOutputConsumption()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJournalTemplateTypeErrorLbl: Label 'can only be Item, Output, or Consumption';
    begin
        // [SCENARIO 557139] Item Tracking on Lines can only be enabled for Item Journal Batches with Template Type Item, Output, or Consumption
        Initialize();

        // [GIVEN] Create Item Journal Batch with Template Type Capacity
        CreateItemJournalBatchFromTemplateType(ItemJournalBatch, ItemJournalBatch."Template Type"::Capacity);
        ItemJournalBatch.CalcFields("Template Type");
        // [WHEN] Enabling Item Tracking on Lines for the Item Journal Batch
        asserterror ItemJournalBatch.Validate("Item Tracking on Lines", true);
        // [THEN] Field error due to the Item Journal Template Type
        Assert.ExpectedTestFieldError(ItemJnlTemplate.FieldCaption(Type), ItemJournalTemplateTypeErrorLbl);

        // [GIVEN] Create Item Journal Batch with Template Type Physical Inventory
        CreateItemJournalBatchFromTemplateType(ItemJournalBatch, ItemJournalBatch."Template Type"::"Phys. Inventory");
        ItemJournalBatch.CalcFields("Template Type");
        // [WHEN] Enabling Item Tracking on Lines for the Item Journal Batch
        asserterror ItemJournalBatch.Validate("Item Tracking on Lines", true);
        // [THEN] Field error due to the Item Journal Template Type
        Assert.ExpectedTestFieldError(ItemJnlTemplate.FieldCaption(Type), ItemJournalTemplateTypeErrorLbl);

        // [GIVEN] Create Item Journal Batch with Template Type Production Order
        CreateItemJournalBatchFromTemplateType(ItemJournalBatch, ItemJournalBatch."Template Type"::"Prod. Order");
        ItemJournalBatch.CalcFields("Template Type");
        // [WHEN] Enabling Item Tracking on Lines for the Item Journal Batch
        asserterror ItemJournalBatch.Validate("Item Tracking on Lines", true);
        // [THEN] Field error due to the Item Journal Template Type
        Assert.ExpectedTestFieldError(ItemJnlTemplate.FieldCaption(Type), ItemJournalTemplateTypeErrorLbl);

        // [GIVEN] Create Item Journal Batch with Template Type Revaluation
        CreateItemJournalBatchFromTemplateType(ItemJournalBatch, ItemJournalBatch."Template Type"::Revaluation);
        ItemJournalBatch.CalcFields("Template Type");
        // [WHEN] Enabling Item Tracking on Lines for the Item Journal Batch
        asserterror ItemJournalBatch.Validate("Item Tracking on Lines", true);
        // [THEN] Field error due to the Item Journal Template Type
        Assert.ExpectedTestFieldError(ItemJnlTemplate.FieldCaption(Type), ItemJournalTemplateTypeErrorLbl);

        // [GIVEN] Create Item Journal Batch with Template Type Transfer
        CreateItemJournalBatchFromTemplateType(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        ItemJournalBatch.CalcFields("Template Type");
        // [WHEN] Enabling Item Tracking on Lines for the Item Journal Batch
        asserterror ItemJournalBatch.Validate("Item Tracking on Lines", true);
        // [THEN] Field error due to the Item Journal Template Type
        Assert.ExpectedTestFieldError(ItemJnlTemplate.FieldCaption(Type), ItemJournalTemplateTypeErrorLbl);

        // [GIVEN] Create Item Journal Batch with Template Type Consumption
        CreateItemJournalBatchFromTemplateType(ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption);
        ItemJournalBatch.CalcFields("Template Type");
        // [WHEN] Enabling Item Tracking on Lines for the Item Journal Batch
        ItemJournalBatch.Validate("Item Tracking on Lines", true);
        // [THEN] No error

        // [GIVEN] Create Item Journal Batch with Template Type Item
        CreateItemJournalBatchFromTemplateType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        ItemJournalBatch.CalcFields("Template Type");
        // [WHEN] Enabling Item Tracking on Lines for the Item Journal Batch
        ItemJournalBatch.Validate("Item Tracking on Lines", true);
        // [THEN] No error

        // [GIVEN] Create Item Journal Batch with Template Type Output
        CreateItemJournalBatchFromTemplateType(ItemJournalBatch, ItemJournalBatch."Template Type"::Output);
        ItemJournalBatch.CalcFields("Template Type");
        // [WHEN] Enabling Item Tracking on Lines for the Item Journal Batch
        ItemJournalBatch.Validate("Item Tracking on Lines", true);
        // [THEN] No error
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyEntryTypeOnPhysInventoryJournalWhenQtyPhysInventoryUpdated()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Physical Inventory]
        // [SCENARIO 481230] Physical inventory Journal, entry type not updated after quantity change
        Initialize();

        // [GIVEN] Create Item and Post Item Positive Adjustment
        CreateItem(Item, Item."Costing Method"::FIFO);
        CreateAndPostItemJournal(
            ItemJournalLine."Entry Type"::"Positive Adjmt.",
            Item."No.",
            '',
            '',
            '',
            LibraryRandom.RandDecInRange(100, 1000, 2));

        // [WHEN] Calculate Inventory
        CreateAndPostPhysInventoryJournal(ItemJournalLine, ItemJournalBatch, Item."No.", false);

        // [THEN] Find Created Item Journal Line
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch, Item."No.");

        // [VERIFY] Verify: Entry Type when "Qty. (Phys. Inventory)" updated on Phys. Inventory journal
        OpenAndVerifyEntryTypeOnPhysInventoryJournalPageWhenUpdateQuantity(ItemJournalLine)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTrackingOnLinesShouldNotAllowedForTemplateTypeItemWhenRecurringIsTrue()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [SCENARIO 492483] The option Item Tracking on lines in the Reclassification Journal should not be available
        Initialize();

        // [GIVEN] Create Item Journal Template with Type Item and Recurring true
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        ItemJournalTemplate.Validate(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate(Recurring, true);
        ItemJournalTemplate.Modify(true);

        // [GIVEN] Create Item Journal Batch with Template Type Item
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        // [WHEN] Expected Test field error while setting true to "Item Tracking on Lines" field
        asserterror ItemJournalBatch.Validate("Item Tracking on Lines", true);

        // [VERIFY] Verify: Error: Recurring must be equal to 'No' in Item Journal Template.
        Assert.IsTrue(
            StrPos(GetLastErrorText, RecurringMustNoErr) > 0,
            StrSubstNo(TextGetLastErrorText, GetLastErrorText, RecurringMustNoErr));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevaluationJournalLinePostedWIthoutErrorWhenItemDefaultDimensionWithCodeMandatory()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        GlobalDimensionValueCode: Code[20];
    begin
        // [SCENARIO 497656] Item Revaluation Journal posted without error after posting Transfer Order and running Calculate Inventory Value Report when Item's Default Dimensions set as Code mandatory
        Initialize();

        // [GIVEN] Create Item, Create and post Transfer Order.
        LibraryInventory.CreateItem(Item);
        CreateAndPostTransferOrder(Item."No.");

        // [GIVEN] Create Default Dimension for Item with Code Mandatory
        GlobalDimensionValueCode := AddGlobalDimension(Database::Item, 1);

        // [THEN] Create Revaluation Journal for Item, and Update Unit Cost Revalued for Item at transferred Location.
        CreateRevaluationJournalForItem(Item."No.", ItemJournalLine);
        UpdateItemJournallineUnitCostRevalued(Item."No.", GlobalDimensionValueCode);

        // [THEN] Verify: Post Revaluation Journal Line For Item without any error
        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReclassJournalUnitOfMeasureUpdatedWhenItemChanged()
    var
        Item: array[2] of Record Item;
        UnitOfMeasure: array[2] of Record "Unit of Measure";
        ItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemReclassJournal: TestPage "Item Reclass. Journal";
        i: Integer;
    begin
        // [SCENARIO 581983] Unit of Measure Code should be updated automatically when Item No. is changed in Item Reclassification Journal
        Initialize();

        // [GIVEN] Create two items with different base unit of measure codes
        for i := 1 to 2 do begin
            LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[i]);
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure[i], Item[i]."No.", UnitOfMeasure[i].Code, 1);
            Item[i].Validate("Base Unit of Measure", UnitOfMeasure[i].Code);
            Item[i].Modify(true);
        end;

        // [GIVEN] Setup Item Reclassification Journal template and batch
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Transfer, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);

        // [WHEN] Open Item Reclassification Journal page
        ItemReclassJournal.OpenEdit();
        ItemReclassJournal.CurrentJnlBatchName.SetValue(ItemJournalBatch.Name);

        // [WHEN] Enter first item no. and verify unit of measure is set
        ItemReclassJournal."Item No.".SetValue(Item[1]."No.");
        ItemReclassJournal."Unit of Measure Code".AssertEquals(UnitOfMeasure[1].Code);

        // [WHEN] Change item no. to second item
        ItemReclassJournal."Item No.".SetValue(Item[2]."No.");

        // [THEN] Verify unit of measure code is updated to second item's base unit of measure
        ItemReclassJournal."Unit of Measure Code".AssertEquals(UnitOfMeasure[2].Code);

        // [THEN] Verify no error occurs when changing item number
        // This test verifies the fix for the bug where changing Item No. with different Unit of Measure Codes caused validation errors
        ItemReclassJournal.Close();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Journals");
        ClearGlobalVariable();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Journals");

        LibraryERMCountryData.CreateVATData();
        ReclassificationJournalSetup();
        SetGlobalDescriptionAndComments();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Journals");
    end;

    local procedure CalculateInventoryAndGetLocationCodeFromLastLine(ItemNo: Code[20]; LocationCode: Code[10]): Code[10]
    var
        PhysInvJournal: TestPage "Phys. Inventory Journal";
    begin
        LibraryVariableStorage.Enqueue(ItemNo); // Enqueue for CalculateInventoryIncludeItemWithoutTransaction handler
        LibraryVariableStorage.Enqueue(LocationCode); // Enqueue for CalculateInventoryIncludeItemWithoutTransaction handler
        Commit();
        PhysInvJournal.OpenEdit();
        PhysInvJournal.CalculateInventory.Invoke();
        PhysInvJournal.Last();
        exit(PhysInvJournal."Location Code".Value)
    end;

    local procedure CalculateInventoryAndGetLocationCodeFromFirstTwoLines(ItemNo: Code[20]; LocationCode: array[2] of Code[10])
    var
        PhysInvJournal: TestPage "Phys. Inventory Journal";
    begin
        LibraryVariableStorage.Enqueue(ItemNo); // Enqueue for CalculateInventoryIncludeItemWithoutTransaction handler
        LibraryVariableStorage.Enqueue(StrSubstNo('%1|%2', LocationCode[1], LocationCode[2])); // Enqueue for CalculateInventoryIncludeItemWithoutTransaction handler
        Commit();
        PhysInvJournal.OpenEdit();
        PhysInvJournal.CalculateInventory.Invoke();
        PhysInvJournal.FILTER.SetFilter("Location Code", LocationCode[1]);
        PhysInvJournal.First();
        LocationCode[1] := PhysInvJournal."Location Code".Value();
        PhysInvJournal.FILTER.SetFilter("Location Code", LocationCode[2]);
        PhysInvJournal.First();
        LocationCode[2] := PhysInvJournal."Location Code".Value();
    end;

    local procedure CalculateInventoryWithItemFilters(ItemNoFilter: Text; LocationFilter: Text; VariantFilter: Text; ItemsNotOnInvt: Boolean; ItemsWithNoTransactions: Boolean)
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        Item.SetFilter("No.", ItemNoFilter);
        Item.SetFilter("Location Filter", LocationFilter);
        Item.SetFilter("Variant Filter", VariantFilter);
        CreateItemJournalBatch(ItemJournalBatch);
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, WorkDate(), ItemsNotOnInvt, ItemsWithNoTransactions);
    end;

    local procedure ClearGlobalVariable()
    begin
        // Clear Global variables.
        GlobalNewSerialNo := '';
        GlobalItemNo := '';
        GlobalNewLotNo := '';
        GlobalOriginalQuantity := 0;
        GlobalExpirationDate := 0D;
        GlobalDescription := '';
        GlobalComment := '';
    end;

    local procedure CreateAndPostPhysInventoryJournal(var ItemJournalLine: Record "Item Journal Line"; var ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; IsPost: Boolean)
    begin
        ItemJournalLine.Init();
        CreateItemJournalBatch(ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CalculateInventoryForSingleItem(ItemJournalLine, ItemNo, WorkDate(), true, false);
        if IsPost then
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournal(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, EntryType, ItemNo, WorkDate(), LibraryRandom.RandDec(10, 2)); // Use Random value for Unit Amount.
        PostItemJournalLine(ItemJournalLine, VariantCode, LocationCode, BinCode, Qty);
    end;

    local procedure CreateAndPostItemJournalWithDimension(var DimSetID: Integer; DimensionCode: Code[20]; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, EntryType, ItemNo, WorkDate(), LibraryRandom.RandDec(10, 2));
        CreateDimSetForItemJournalLine(ItemJournalLine, DimSetID, DimensionCode);
        PostItemJournalLine(ItemJournalLine, '', '', '', Qty);
    end;

    local procedure CreateAndPostTransferOrder(ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(100, 2);  // Use Random value for Quantity.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        UpdateItemInventory(
          ItemNo, LocationFrom.Code, '', Quantity, ItemJournalLine."Entry Type"::"Positive Adjmt.", LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Amount.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
    end;

    local procedure CreateDimSetForItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; var DimSetID: Integer; DimensionCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);
        ItemJournalLine.Validate("Dimension Set ID", DimSetID);
        ItemJournalLine.Modify();
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Cost.
        Item.Modify(true);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::"Phys. Inventory");
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateItemJournalBatchFromTemplateType(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; PostingDate: Date; UnitAmount: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        // Use Random value for Quantity.
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo,
          LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(ItemNo: Code[20]): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, 1);
        exit(ItemUnitOfMeasure.Code);
    end;

    local procedure CreateItemReclassJournal(var ReclassificationItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10]; BinCode: Code[10]; Qty: Decimal; Qty2: Decimal)
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        ReclassificationItemJournalTemplate: Record "Item Journal Template";
        ReclassificationItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItem(Item, Item."Costing Method"::FIFO);
        CreatePurchaseOrder(PurchaseHeader, Item."No.", Location.Code, Qty);  // Use Random value for Quantity.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        SelectAndClearItemJournalBatch(ReclassificationItemJournalBatch, ReclassificationItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ReclassificationItemJournalLine, ReclassificationItemJournalBatch."Journal Template Name",
          ReclassificationItemJournalBatch.Name, ReclassificationItemJournalLine."Entry Type"::Transfer, Item."No.", Qty2);
        ReclassificationItemJournalLine.Validate("Location Code", Location.Code);
        ReclassificationItemJournalLine.Validate("New Location Code", LocationCode);
        ReclassificationItemJournalLine.Validate("New Bin Code", BinCode);
        ReclassificationItemJournalLine.Modify(true);
    end;

    local procedure CreateItemWith2Variants(var ItemVariant: array[2] of Record "Item Variant") ItemNo: Code[20]
    begin
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryInventory.CreateItemVariant(ItemVariant[1], ItemNo);
        LibraryInventory.CreateItemVariant(ItemVariant[2], ItemNo);
    end;

    local procedure CreateLocationAndBin(var Location: Record Location): Code[10]
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        exit(Bin.Code);
    end;

    local procedure CreateTrackedItem(LotNos: Code[20]; SerialNos: Code[20]; LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean): Code[20]
    var
        Item: Record Item;
        ExpirationCalculation: DateFormula;
    begin
        Evaluate(ExpirationCalculation, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", FindItemTrackingCode(LotSpecificTracking, SerialNoSpecificTracking));
        Item.Validate("Serial Nos.", SerialNos);
        Item.Validate("Lot Nos.", LotNos);
        EnsureTrackingCodeUsesExpirationDate(Item."Item Tracking Code");
        Item.Validate("Expiration Calculation", ExpirationCalculation);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, 0D);
    end;

    local procedure GetGlobalDimCode(): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Global Dimension 1 Code");
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindItemTrackingCode(LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.SetRange("Man. Expir. Date Entry Reqd.", false);
        ItemTrackingCode.SetRange("Lot Specific Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("Lot Sales Inbound Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("Lot Sales Outbound Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("SN Specific Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.SetRange("SN Sales Inbound Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.SetRange("SN Sales Outbound Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.FindFirst();
        exit(ItemTrackingCode.Code);
    end;

    local procedure EnsureTrackingCodeUsesExpirationDate(ItemTrackingCode: Code[10])
    var
        ItemTrackingCodeRec: Record "Item Tracking Code";
    begin
        ItemTrackingCodeRec.Get(ItemTrackingCode);
        if not ItemTrackingCodeRec."Use Expiration Dates" then begin
            ItemTrackingCodeRec.Validate("Use Expiration Dates", true);
            ItemTrackingCodeRec.Modify();
        end;
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemLedgerEntry.SetRange("Item No.", GlobalItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindItemLedgerEntryWithLocation(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindItemTrackingComment(var ItemTrackingComment: Record "Item Tracking Comment"; CommentType: Enum "Item Tracking Comment Type"; ItemNo: Code[20])
    begin
        ItemTrackingComment.SetRange(Type, CommentType);
        ItemTrackingComment.SetRange("Item No.", ItemNo);
        ItemTrackingComment.FindFirst();
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20])
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindLotNoInformation(var LotNoInformation: Record "Lot No. Information"; ItemNo: Code[20])
    begin
        LotNoInformation.SetRange("Item No.", ItemNo);
        LotNoInformation.FindFirst();
    end;

    local procedure ModifyUnitOfMeasureOnItemJournal(var ItemJournalLine: Record "Item Journal Line"; UnitOfMeasureCode: Code[10])
    begin
        ItemJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure PostItemJournalLine(ItemJournalLine: Record "Item Journal Line"; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    begin
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate(Quantity, Qty);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostPurchaseOrderWithItemTracking(LotNos: Code[20]; SerialNos: Code[20]; LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean; ItemTrackingAction2: Option; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        GlobalItemNo := CreateTrackedItem(LotNos, SerialNos, LotSpecificTracking, SerialNoSpecificTracking);  // Assign Item No. to global variable and blank value is taken for Serial No.
        if Quantity = 0 then
            // Random Integer value greater than 1 required for test. Assign it to Global Variable.
            GlobalOriginalQuantity := 1 + LibraryRandom.RandInt(10)
        else
            GlobalOriginalQuantity := Quantity;
        CreatePurchaseOrder(PurchaseHeader, GlobalItemNo, '', GlobalOriginalQuantity);
        FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.");
        GlobalItemTrackingAction := ItemTrackingAction2;
        PurchaseLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure PostPurchaseOrderWithoutItemTracking(Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        GlobalItemNo := LibraryInventory.CreateItem(Item);
        if Quantity = 0 then
            // Random Integer value greater than 1 required for test. Assign it to Global Variable.
            GlobalOriginalQuantity := 1 + LibraryRandom.RandInt(10)
        else
            GlobalOriginalQuantity := Quantity;
        CreatePurchaseOrder(PurchaseHeader, GlobalItemNo, '', GlobalOriginalQuantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure PostTwoSymmetricAdjustments(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        Qty: Integer;
    begin
        Qty := LibraryRandom.RandInt(10);
        CreateAndPostItemJournal(ItemLedgerEntryType::"Positive Adjmt.", ItemNo, VariantCode, LocationCode, '', Qty);
        CreateAndPostItemJournal(ItemLedgerEntryType::"Negative Adjmt.", ItemNo, VariantCode, LocationCode, '', Qty);
    end;

    local procedure ReclassificationJournalSetup()
    begin
        Clear(ReclassificationItemJournalTemplate);
        ReclassificationItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(
          ReclassificationItemJournalTemplate, ReclassificationItemJournalTemplate.Type::Transfer);

        Clear(ReclassificationItemJournalBatch);
        ReclassificationItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          ReclassificationItemJournalBatch, ReclassificationItemJournalTemplate.Type, ReclassificationItemJournalTemplate.Name);
    end;

    local procedure ReclassificationJournalWithPurchaseOrder(var ReclassificationItemJournalLine: Record "Item Journal Line"; TrackingAction: Option; LotNos: Code[20]; LotSpecific: Boolean; SerialSpecific: Boolean; GlobalAction: Option)
    begin
        ReclassificationJournalWithPurchaseOrderWithQty(ReclassificationItemJournalLine, TrackingAction, LotNos, LotSpecific, SerialSpecific, GlobalAction, 0);
    end;

    local procedure ReclassificationJournalWithPurchaseOrderWithQty(var ReclassificationItemJournalLine: Record "Item Journal Line"; TrackingAction: Option; LotNos: Code[20]; LotSpecific: Boolean; SerialSpecific: Boolean; GlobalAction: Option; Quantity: Decimal)
    var
        Item: Record Item;
    begin
        // Create and post Purchase Order with Item Tracking and Item with Expiration Calculation and create Reclassification Journal with Item Tracking.
        PostPurchaseOrderWithItemTracking(LotNos, LibraryUtility.GetGlobalNoSeriesCode(), LotSpecific, SerialSpecific, GlobalAction, Quantity);
        Item.Get(GlobalItemNo);
        GlobalExpirationDate := CalcDate(Item."Expiration Calculation", WorkDate());  // Assigned in global variable.

        LibraryInventory.ClearItemJournal(ReclassificationItemJournalTemplate, ReclassificationItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ReclassificationItemJournalLine, ReclassificationItemJournalBatch."Journal Template Name",
          ReclassificationItemJournalBatch.Name, ReclassificationItemJournalLine."Entry Type"::Transfer, GlobalItemNo,
          GlobalOriginalQuantity);
        GlobalItemTrackingAction := TrackingAction;
    end;

    local procedure RunCalculateInventoryValueReport(ItemNo: Code[20]): Integer
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        LibraryCosting: Codeunit "Library - Costing";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type", ItemNo, 0);
        Item.SetRange("No.", ItemNo);
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, WorkDate(), ItemJournalLine."Journal Batch Name" + Format(ItemJournalLine."Line No."), "Inventory Value Calc. Per"::Item,
          false, false, false, "Inventory Value Calc. Base"::" ", false);
        exit(ItemJournalLine."Dimension Set ID");
    end;

    local procedure RunCalculateInventoryByDimensions(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
        CalculateInventory: Report "Calculate Inventory";
    begin
        CreateItemJournalBatch(ItemJournalBatch);
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        CalculateInventory.SetItemJnlLine(ItemJournalLine);
        Commit();
        CalculateInventory.RunModal();
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetGlobalDescriptionAndComments()
    var
        SerialNoInformation: Record "Serial No. Information";
        ItemTrackingComment: Record "Item Tracking Comment";
    begin
        GlobalDescription :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(SerialNoInformation.FieldNo(Description), DATABASE::"Serial No. Information"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Serial No. Information", SerialNoInformation.FieldNo(Description)));
        GlobalComment :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(ItemTrackingComment.FieldNo(Comment), DATABASE::"Item Tracking Comment"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Item Tracking Comment", ItemTrackingComment.FieldNo(Comment)));
    end;

    local procedure UpdateAndVerifySerialNoInformationAndComments(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        SerialNoInformationList: TestPage "Serial No. Information List";
        ItemTrackingComments: TestPage "Item Tracking Comments";
        SerialNoInformationCard: TestPage "Serial No. Information Card";
    begin
        // Update Description on Serial No information Card and add Comments for Serial No.
        SerialNoInformationCard.Trap();
        ItemTrackingLines.NewSerialNoInformation.Invoke();
        SerialNoInformationCard.Description.SetValue(GlobalDescription);
        ItemTrackingComments.Trap();
        SerialNoInformationCard.Comment.Invoke();
        ItemTrackingComments.Date.SetValue(WorkDate());
        ItemTrackingComments.Comment.SetValue(GlobalComment);
        ItemTrackingComments.OK().Invoke();
        Commit();
        SerialNoInformationList.Trap();
        SerialNoInformationCard.CopyInfo.Invoke();
    end;

    local procedure UpdateAndVerifyLotNoInformationAndComments(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        LotNoInformationList: TestPage "Lot No. Information List";
        ItemTrackingComments: TestPage "Item Tracking Comments";
        LotNoInformationCard: TestPage "Lot No. Information Card";
    begin
        // Update Description on Serial No information Card and add Comments for Serial No.
        LotNoInformationCard.Trap();
        ItemTrackingLines.NewLotNoInformation.Invoke();
        LotNoInformationCard.Description.SetValue(GlobalDescription);
        ItemTrackingComments.Trap();
        LotNoInformationCard.Comment.Invoke();
        ItemTrackingComments.Date.SetValue(WorkDate());
        ItemTrackingComments.Comment.SetValue(GlobalComment);
        ItemTrackingComments.OK().Invoke();
        Commit();
        LotNoInformationList.Trap();
        LotNoInformationCard.CopyInfo.Invoke();
    end;

    local procedure UpdateItemDimension(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure UpdateItemDimensionUsingGlobal(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDefaultDimensionItem(
          DefaultDimension, ItemNo, GeneralLedgerSetup."Global Dimension 1 Code", DimensionValue.Code);
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; Quantity: Decimal; EntryType: Enum "Item Ledger Document Type"; UnitAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, EntryType, ItemNo, WorkDate(), LibraryRandom.RandInt(10));  // Use Random value for Unit Amount.
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateItemTrackingCode(LotInfoInbound: Boolean; LotInfoOutbound: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        Item.Get(GlobalItemNo);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("Lot Info. Inbound Must Exist", LotInfoInbound);
        ItemTrackingCode.Validate("Lot Info. Outbound Must Exist", LotInfoOutbound);
        ItemTrackingCode.Modify(true);
    end;

    local procedure VerifyDimensionOnRevaluationJournal(DefaultDimension: Record "Default Dimension"; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.FindFirst();
        DimensionSetEntry.TestField("Dimension Code", DefaultDimension."Dimension Code");
        DimensionSetEntry.TestField("Dimension Value Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifySerialNoOnItemLedgerEntry()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", GlobalItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Serial No.");
    end;

    local procedure VerifyLotNoOnItemLedgerEntry()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", GlobalItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Lot No.");
    end;

    local procedure VerifyLotNoAndExpirationOnItemLedgerEntry()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", GlobalItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetFilter("Lot No.", '<>%1', '');
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Lot No.");
        ItemLedgerEntry.TestField("Expiration Date", WorkDate());
    end;

    local procedure FilterItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[20]; BinCode: Code[20])
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Variant Code", VariantCode);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.SetRange("Bin Code", BinCode);
    end;

    local procedure VerifyDimOnItemJournalLine(ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; DimSetID: array[2] of Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        iDim: Integer;
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindSet();
        repeat
            iDim += 1;
            Assert.AreEqual(DimSetID[iDim], ItemJournalLine."Dimension Set ID", ItemJournalLineDimErr);
        until ItemJournalLine.Next() = 0;
    end;

    local procedure VerifyItemJournalLine(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[20]; BinCode: Code[20]; QtyCalculated: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FilterItemJournalLine(ItemJournalLine, ItemNo, VariantCode, LocationCode, BinCode);
        Assert.IsTrue(
          ItemJournalLine.FindFirst(), StrSubstNo(ItemJournalLineNotExistErr, ItemJournalLine.TableCaption(), VariantCode, LocationCode, BinCode));
        Assert.AreEqual(
          QtyCalculated, ItemJournalLine."Qty. (Calculated)",
          StrSubstNo(QtyCalculatedErr, ItemJournalLine.TableCaption(), VariantCode, LocationCode, BinCode))
    end;

    local procedure VerifyNoItemJournalLineExists(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FilterItemJournalLine(ItemJournalLine, ItemNo, VariantCode, LocationCode, '');
        Assert.IsFalse(ItemJournalLine.FindFirst(), StrSubstNo(ItemJournalLineExistsErr, ItemJournalLine.TableCaption(), VariantCode, LocationCode, ''));
    end;

    local procedure OpenAndVerifyEntryTypeOnPhysInventoryJournalPageWhenUpdateQuantity(ItemJournalLine: Record "Item Journal Line")
    var
        PhysInventoryJournal: TestPage "Phys. Inventory Journal";
    begin
        Commit();  // Commit required.
        PhysInventoryJournal.OpenEdit();
        PhysInventoryJournal.CurrentJnlBatchName.SetValue(ItemJournalLine."Journal Batch Name");
        PhysInventoryJournal."Qty. (Phys. Inventory)".SetValue(ItemJournalLine."Qty. (Phys. Inventory)" - LibraryRandom.RandDec(10, 2));
        PhysInventoryJournal."Entry Type".AssertEquals(ItemJournalLine."Entry Type"::"Negative Adjmt.");
        PhysInventoryJournal.Close();
    end;

    local procedure AddGlobalDimension(TableID: Integer; DimNo: Integer) GlobalDimensionValueCode: Code[20];
    var
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        DimensionCode: Code[20];
    begin
        DimensionCode := LibraryERM.GetGlobalDimensionCode(DimNo);
        DefaultDimension.Init();
        DefaultDimension."Table ID" := TableID;
        DefaultDimension."Dimension Code" := DimensionCode;
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        GlobalDimensionValueCode := DimensionValue.Code;
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Insert();
    end;

    local procedure CreateRevaluationJournalForItem(
        ItemNo: Code[20];
        var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.Validate("Value Entry Type", ItemJournalLine."Value Entry Type"::Revaluation);
        LibraryCosting.CalculateInventoryValue(
            ItemJournalLine, Item, WorkDate(), LibraryUtility.GetGlobalNoSeriesCode(),
            "Inventory Value Calc. Per"::Item, true, false, false, "Inventory Value Calc. Base"::" ", false);
    end;

    local procedure UpdateItemJournallineUnitCostRevalued(ItemNo: Code[20]; GlobalDimensionValueCode: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindLast();

        SelectItemJournalLineForLocation(ItemJournalLine, ItemNo, ItemLedgerEntry."Location Code");
        ItemJournalLine.Validate("Unit Cost (Revalued)", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Shortcut Dimension 1 Code", GlobalDimensionValueCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure SelectItemJournalLineForLocation(
        var ItemJournalLine: Record "Item Journal Line";
        ItemNo: Code[20];
        LocationCode: Code[10])
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNoInformation: Record "Lot No. Information";
        SerialNoInformation: Record "Serial No. Information";
        TrackingSpecification: Record "Tracking Specification";
    begin
        Commit();
        case GlobalItemTrackingAction of
            GlobalItemTrackingAction::SelectEntriesSerialNo:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines."New Serial No.".AssertEquals(ItemTrackingLines."Serial No.");
                    ItemTrackingLines."New Expiration Date".AssertEquals(GlobalExpirationDate);
                end;
            GlobalItemTrackingAction::SelectEntriesLotNo:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines."New Lot No.".AssertEquals(ItemTrackingLines."Lot No.");
                    ItemTrackingLines."New Expiration Date".AssertEquals(GlobalExpirationDate);
                end;
            GlobalItemTrackingAction::EditItemTrackingSerialNo:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.Last();
                    ItemTrackingLines."New Serial No.".SetValue(
                      LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("New Serial No."), DATABASE::"Tracking Specification"));
                    ItemTrackingLines."New Expiration Date".SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate()));
                    LibraryItemTracking.CreateSerialNoInformation(
                      SerialNoInformation, GlobalItemNo, '', ItemTrackingLines."New Serial No.".Value);
                    UpdateAndVerifySerialNoInformationAndComments(ItemTrackingLines);
                end;
            GlobalItemTrackingAction::EditItemTrackingLotNo:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.Last();
                    ItemTrackingLines."New Lot No.".SetValue(
                      LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("New Lot No."), DATABASE::"Tracking Specification"));
                    ItemTrackingLines."New Expiration Date".SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate()));
                    LibraryItemTracking.CreateLotNoInformation(LotNoInformation, GlobalItemNo, '', ItemTrackingLines."New Lot No.".Value);
                    UpdateAndVerifyLotNoInformationAndComments(ItemTrackingLines);
                end;
            GlobalItemTrackingAction::ItemTrackingSerialAndLot:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.Last();
                    ItemTrackingLines."New Lot No.".SetValue(
                      LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("New Lot No."), DATABASE::"Tracking Specification"));
                    ItemTrackingLines."New Expiration Date".SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate()));
                    LibraryItemTracking.CreateLotNoInformation(LotNoInformation, GlobalItemNo, '', ItemTrackingLines."New Lot No.".Value);
                    UpdateAndVerifyLotNoInformationAndComments(ItemTrackingLines);

                    ItemTrackingLines."New Serial No.".SetValue(
                      LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("New Serial No."), DATABASE::"Tracking Specification"));
                    ItemTrackingLines."New Expiration Date".SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate()));
                    LibraryItemTracking.CreateSerialNoInformation(
                      SerialNoInformation, GlobalItemNo, '', ItemTrackingLines."New Serial No.".Value);
                    UpdateAndVerifySerialNoInformationAndComments(ItemTrackingLines);
                    GlobalNewSerialNo := SerialNoInformation."Serial No.";
                end;
            GlobalItemTrackingAction::EditNewSerialNo:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.Last();
                    LibraryItemTracking.CreateSerialNoInformation(
                      SerialNoInformation, GlobalItemNo, '', ItemTrackingLines."New Serial No.".Value);
                    UpdateAndVerifySerialNoInformationAndComments(ItemTrackingLines);
                    FindItemLedgerEntry(ItemLedgerEntry);
                    GlobalNewSerialNo := ItemLedgerEntry."Serial No.";
                    ItemTrackingLines."New Serial No.".SetValue(GlobalNewSerialNo);
                end;
            GlobalItemTrackingAction::EditNewLotNo:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    FindItemLedgerEntry(ItemLedgerEntry);
                    GlobalNewLotNo := ItemLedgerEntry."Lot No.";
                    ItemTrackingLines."New Lot No.".SetValue(GlobalNewLotNo);
                end;
            GlobalItemTrackingAction::CopyInfo:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.Last();
                    LibraryItemTracking.CreateLotNoInformation(LotNoInformation, GlobalItemNo, '', ItemTrackingLines."New Lot No.".Value);
                    UpdateAndVerifyLotNoInformationAndComments(ItemTrackingLines);
                    FindItemLedgerEntry(ItemLedgerEntry);
                    GlobalNewLotNo := ItemLedgerEntry."Lot No.";
                end;
            GlobalItemTrackingAction::LotNoAvailability:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines."Lot No.".SetValue(
                      LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("Lot No."), DATABASE::"Tracking Specification"));
                end;
            GlobalItemTrackingAction::EditLotNo:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.Last();
                    ItemTrackingLines."Lot No.".SetValue(
                      LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("Lot No."), DATABASE::"Tracking Specification"));
                    FindItemLedgerEntry(ItemLedgerEntry);
                    GlobalNewLotNo := ItemLedgerEntry."Lot No.";
                    GlobalExpirationDate := ItemLedgerEntry."Expiration Date";
                    ItemTrackingLines."New Lot No.".SetValue(GlobalNewLotNo);
                end;
            GlobalItemTrackingAction::ModifyQuantity:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.Last();
                    FindItemLedgerEntry(ItemLedgerEntry);
                    GlobalNewLotNo := ItemLedgerEntry."Lot No.";
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemLedgerEntry.Quantity + 1);  // Greater Quantity is needed.
                end;
            GlobalItemTrackingAction::EditLotNoInformation:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.Last();
                    LibraryItemTracking.CreateLotNoInformation(LotNoInformation, GlobalItemNo, '', ItemTrackingLines."New Lot No.".Value);
                    LotNoInformation.Validate(Blocked, true);
                    LotNoInformation.Modify(true);
                    UpdateAndVerifyLotNoInformationAndComments(ItemTrackingLines);
                    FindItemLedgerEntry(ItemLedgerEntry);
                    GlobalNewLotNo := ItemLedgerEntry."Lot No.";
                end;
            GlobalItemTrackingAction::EditTrackedQuantity:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.Last();
                    ItemTrackingLines."New Lot No.".SetValue(
                      LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("New Lot No."), DATABASE::"Tracking Specification"));
                    ItemTrackingLines."New Expiration Date".SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate()));
                    LibraryItemTracking.CreateLotNoInformation(LotNoInformation, GlobalItemNo, '', ItemTrackingLines."New Lot No.".Value);
                    UpdateAndVerifyLotNoInformationAndComments(ItemTrackingLines);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemLedgerEntry.Quantity - 1);  // Less Quantity is needed.
                end;
            GlobalItemTrackingAction::EditQuantityBase:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    FindItemLedgerEntry(ItemLedgerEntry);
                    GlobalNewLotNo := ItemLedgerEntry."Lot No.";
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemLedgerEntry.Quantity - 1);  // Less Quantity is needed.
                end;
            GlobalItemTrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            GlobalItemTrackingAction::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandlerWithAssignTo(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNoInformation: Record "Lot No. Information";
        TrackingSpecification: Record "Tracking Specification";
    begin
        Commit();
        case GlobalItemTrackingAction of
            GlobalItemTrackingAction::EditItemTrackingLotNo:
                begin
                    ItemTrackingLines.Last();
                    ItemTrackingLines."New Lot No.".SetValue(
                      LibraryUtility.GenerateRandomCode(TrackingSpecification.FieldNo("New Lot No."), DATABASE::"Tracking Specification"));
                    ItemTrackingLines."New Expiration Date".SetValue(LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate()));
                    FindItemLedgerEntry(ItemLedgerEntry);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemLedgerEntry.Quantity);
                    ItemTrackingLines."Appl.-to Item Entry".SetValue(ItemLedgerEntry."Entry No.");
                    LibraryItemTracking.CreateLotNoInformation(LotNoInformation, GlobalItemNo, '', ItemTrackingLines."New Lot No.".Value);
                    UpdateAndVerifyLotNoInformationAndComments(ItemTrackingLines);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InvokeSerialNoInformationListPageHander(var SerialNoInformationList: TestPage "Serial No. Information List")
    begin
        SerialNoInformationList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SerialNoInformationListPageHander(var SerialNoInformationList: TestPage "Serial No. Information List")
    begin
        Assert.AreEqual(StrSubstNo(SerialNoListPageCaption), SerialNoInformationList.Caption, ValidationError);
        SerialNoInformationList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AvailabilityConfirmationHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, AvailabilityWarning) > 0, ConfirmMessage);
        Reply := true
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SerialNumberConfirmationHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, StrSubstNo(SerialNoConfirmaton)) > 0, ConfirmMessage);
        Reply := true
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure LotNumberConfirmationHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, StrSubstNo(LotNoConfirmatonQst)) > 0, ConfirmMessage);
        Reply := true
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LotNoInformationListPageHander(var LotNoInformationList: TestPage "Lot No. Information List")
    begin
        Assert.AreEqual(StrSubstNo(LotNoListPageCaption), LotNoInformationList.Caption, ValidationError);
        LotNoInformationList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InvokeLotNoInformationListPageHander(var LotNoInformationList: TestPage "Lot No. Information List")
    begin
        LotNoInformationList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure LotNoInformationConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, StrSubstNo(LotNoInformationError)) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure LotNoInformationConfirmHandlerFalse(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, StrSubstNo(LotNoInformationError)) > 0, ConfirmMessage);
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure AvailabilityConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, StrSubstNo(AvailabilityWarning)) > 0, ConfirmMessage);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingToPostConfirmHandler(ConfirmMessage: Text[1024])
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, StrSubstNo(JournalErrorsMgt.GetNothingToPostErrorMsg())) > 0, ConfirmMessage);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CorrectionsConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(ConfirmMessage, StrSubstNo(CorrectionsError)) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyDimensionSetEntryHandler(var DimensionSetEntry: TestPage "Edit Dimension Set Entries")
    var
        DefaultDimension: Record "Default Dimension";
        DimVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimVar);
        DefaultDimension := DimVar;
        DimensionSetEntry."Dimension Code".AssertEquals(DefaultDimension."Dimension Code");
        DimensionSetEntry.DimensionValueCode.AssertEquals(DefaultDimension."Dimension Value Code");
        DimensionSetEntry.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateInventory(var CalculateInventory: TestRequestPage "Calculate Inventory")
    var
        VarItemNo: Variant;
        ItemNo: Code[20];
    begin
        CurrentSaveValuesId := REPORT::"Calculate Inventory";
        CalculateInventory.ByDimensions.AssistEdit();
        LibraryVariableStorage.Dequeue(VarItemNo);
        ItemNo := VarItemNo;
        CalculateInventory.Item.SetFilter("No.", ItemNo);
        CalculateInventory.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateInventoryIncludeItemWithoutTransactionHandler(var CalculateInventory: TestRequestPage "Calculate Inventory")
    begin
        CurrentSaveValuesId := REPORT::"Calculate Inventory";
        CalculateInventory.Item.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CalculateInventory.Item.SetFilter("Location Filter", LibraryVariableStorage.DequeueText());
        CalculateInventory.ItemsNotOnInventory.SetValue(true);
        CalculateInventory.IncludeItemWithNoTransaction.SetValue(true);
        CalculateInventory.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MultipleDimSelectionHandler(var MultipleDimSelection: TestPage "Dimension Selection-Multiple")
    var
        DimVar: Variant;
        DimCode: Code[20];
    begin
        LibraryVariableStorage.Dequeue(DimVar);
        DimCode := DimVar;
        MultipleDimSelection.GotoKey(DimCode);

        MultipleDimSelection.Selected.SetValue(true);
        MultipleDimSelection.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

