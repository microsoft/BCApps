namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.History;
using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.Item;
using Microsoft.Warehouse.Ledger;
using System.Utilities;

codeunit 137933 "Item Tracking Code Changes"
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
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ChangeLogImmutableErr: Label 'Item tracking code change log entries cannot be modified or deleted.';
        OpenItemLedgerEntriesExistErr: Label 'You cannot change Item Tracking Code for item %1 because one or more open item ledger entries exist.', Comment = '%1 = Item No.';
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
        VerifyChangeLog(Item."No.", '', ItemTrackingCode.Code);
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
        VerifyChangeLog(Item."No.", ItemTrackingCode.Code, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ExpirationTrackedItemWithHistoryCannotChangeTrackingCode()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        EmptyDateFormula: DateFormula;
    begin
        // [SCENARIO 435436] Expiration-enabled tracking cannot be removed through advanced validation with an empty item formula.
        Initialize();
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(ItemTrackingCode, false, true);
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify();
        Item.TestField("Expiration Calculation", EmptyDateFormula);
        Commit();

        asserterror ChangeItemTrackingCode(Item, '');

        Assert.ExpectedTestFieldError(ItemTrackingCode.FieldCaption("Use Expiration Dates"), Format(false));
        Assert.ExpectedErrorCode('TestField');
        VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
    end;

    [Test]
    procedure ExpirationTrackedItemWithoutHistoryCannotRemoveTracking()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] The current expiration-enabled code also prevents changes before the first posting.
        Initialize();
        CreateExpirationTrackedItem(Item, ItemTrackingCode);

        asserterror ChangeItemTrackingCode(Item, '');

        Assert.ExpectedTestFieldError(ItemTrackingCode.FieldCaption("Use Expiration Dates"), Format(false));
        Assert.ExpectedErrorCode('TestField');
        VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
    end;

    [Test]
    procedure ExpirationTrackedItemCannotSelectAnotherTrackingCode()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        NewItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] Expiration-enabled tracking cannot be replaced even when the specific-tracking settings match.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(NewItemTrackingCode, false, true);
        CreateExpirationTrackedItem(Item, ItemTrackingCode);

        asserterror ChangeItemTrackingCode(Item, NewItemTrackingCode.Code);

        Assert.ExpectedTestFieldError(ItemTrackingCode.FieldCaption("Use Expiration Dates"), Format(false));
        Assert.ExpectedErrorCode('TestField');
        VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
    end;

    [Test]
    procedure ExpirationTrackedItemCannotSelectAnotherExpirationCode()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        NewItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] A different expiration-enabled code is not an exception to the current-code restriction.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(NewItemTrackingCode, false, true);
        CreateExpirationTrackedItem(Item, ItemTrackingCode);

        asserterror ChangeItemTrackingCode(Item, NewItemTrackingCode.Code);

        Assert.ExpectedTestFieldError(ItemTrackingCode.FieldCaption("Use Expiration Dates"), Format(false));
        Assert.ExpectedErrorCode('TestField');
        VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
    end;

    [Test]
    procedure ExpirationTrackedItemCanValidateUnchangedTrackingCode()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] Validating the already assigned expiration-enabled code remains a no-op.
        Initialize();
        CreateExpirationTrackedItem(Item, ItemTrackingCode);

        ChangeItemTrackingCode(Item, ItemTrackingCode.Code);

        VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
    end;

    [Test]
    procedure TrackingChangeToExpirationEnabledCodeRemainsAllowed()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        NewItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] The current-code restriction does not prohibit selecting an expiration-enabled destination.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(NewItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);

        ChangeItemTrackingCode(Item, NewItemTrackingCode.Code);

        VerifyItemTrackingCode(Item."No.", NewItemTrackingCode.Code);
    end;

    [Test]
    procedure HistoricalTrackingCodeIsReconstructedAcrossMultipleChangeDateTimes()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        FirstItemTrackingCode: Record "Item Tracking Code";
        SecondItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
        HistoricalItemTrackingCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] The tracking code active at creation is reconstructed through later audit entries.
        Initialize();

        // [GIVEN] Item "I" posted without tracking and changed first to lot and later to serial tracking.
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.CreateItemTrackingCode(FirstItemTrackingCode, false, true);
        LibraryItemTracking.CreateItemTrackingCode(SecondItemTrackingCode, true, false);
        Item."Item Tracking Code" := SecondItemTrackingCode.Code;
        Item.Modify();
        CreateMockItemLedgerEntry(ItemLedgerEntry, Item."No.", WorkDate() - 2, false);
        CreateChangeLog(Item."No.", ItemLedgerEntry.SystemCreatedAt + 1000, '', FirstItemTrackingCode.Code);
        CreateChangeLog(Item."No.", ItemLedgerEntry.SystemCreatedAt + 2000, FirstItemTrackingCode.Code, SecondItemTrackingCode.Code);

        // [WHEN] The tracking code for the historical entry is requested.
        Assert.IsTrue(
            ItemTrackingCodeChangeMgt.GetTrackingCodeForLinkedApplication(
                Item."No.", ItemLedgerEntry."Entry No.", HistoricalItemTrackingCode),
            'A cross-period tracking application should be detected.');

        // [THEN] The code active when the entry was posted was blank.
        Assert.AreEqual('', HistoricalItemTrackingCode, 'The historical tracking code is incorrect.');
    end;

    [Test]
    procedure NonSpecificSerialNumberRemainsCompatibleWithCurrentTracking()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
    begin
        // [SCENARIO 435436] A recorded serial number does not require serial-specific tracking.
        Initialize();
        CreateTrackingCompatibilitySetup(ItemLedgerEntry, false, false, false);
        ItemLedgerEntry."Serial No." := LibraryUtility.GenerateGUID();

        Assert.IsTrue(
            ItemTrackingCodeChangeMgt.IsCurrentTrackingCodeCompatibleWithEntry(ItemLedgerEntry),
            'A non-specific serial number must not block undo.');
    end;

    [Test]
    procedure NonSpecificLotNumberRemainsCompatibleWithCurrentTracking()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
    begin
        // [SCENARIO 435436] A recorded lot number does not require lot-specific tracking.
        Initialize();
        CreateTrackingCompatibilitySetup(ItemLedgerEntry, false, false, false);
        ItemLedgerEntry."Lot No." := LibraryUtility.GenerateGUID();

        Assert.IsTrue(
            ItemTrackingCodeChangeMgt.IsCurrentTrackingCodeCompatibleWithEntry(ItemLedgerEntry),
            'A non-specific lot number must not block undo.');
    end;

    [Test]
    procedure NonSpecificPackageNumberRemainsCompatibleWithCurrentTracking()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
    begin
        // [SCENARIO 435436] A recorded package number does not require package-specific tracking.
        Initialize();
        CreateTrackingCompatibilitySetup(ItemLedgerEntry, false, false, false);
        ItemLedgerEntry."Package No." := LibraryUtility.GenerateGUID();

        Assert.IsTrue(
            ItemTrackingCodeChangeMgt.IsCurrentTrackingCodeCompatibleWithEntry(ItemLedgerEntry),
            'A non-specific package number must not block undo.');
    end;

    [Test]
    procedure SpecificTrackingStillRequiresEachTrackingNumber()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
        SerialNo: Code[50];
        LotNo: Code[50];
    begin
        // [SCENARIO 435436] Specific tracking still rejects missing numbers and accepts all required numbers.
        Initialize();
        CreateTrackingCompatibilitySetup(ItemLedgerEntry, true, true, true);
        SerialNo := LibraryUtility.GenerateGUID();
        LotNo := LibraryUtility.GenerateGUID();
        ItemLedgerEntry."Serial No." := SerialNo;
        ItemLedgerEntry."Lot No." := LotNo;
        ItemLedgerEntry."Package No." := LibraryUtility.GenerateGUID();
        Assert.IsTrue(
            ItemTrackingCodeChangeMgt.IsCurrentTrackingCodeCompatibleWithEntry(ItemLedgerEntry),
            'An entry with all required tracking numbers should be compatible.');

        Clear(ItemLedgerEntry."Serial No.");
        Assert.IsFalse(
            ItemTrackingCodeChangeMgt.IsCurrentTrackingCodeCompatibleWithEntry(ItemLedgerEntry),
            'Missing specific serial tracking must still block undo.');
        ItemLedgerEntry."Serial No." := SerialNo;

        Clear(ItemLedgerEntry."Lot No.");
        Assert.IsFalse(
            ItemTrackingCodeChangeMgt.IsCurrentTrackingCodeCompatibleWithEntry(ItemLedgerEntry),
            'Missing specific lot tracking must still block undo.');
        ItemLedgerEntry."Lot No." := LotNo;

        Clear(ItemLedgerEntry."Package No.");
        Assert.IsFalse(
            ItemTrackingCodeChangeMgt.IsCurrentTrackingCodeCompatibleWithEntry(ItemLedgerEntry),
            'Missing specific package tracking must still block undo.');
    end;

    [Test]
    procedure CompatibleTrackingDoesNotHideCrossPeriodApplication()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PreviousItemTrackingCode: Record "Item Tracking Code";
        CurrentItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
        HistoricalItemTrackingCode: Code[10];
    begin
        // [SCENARIO 435436] Compatible tracking numbers do not bypass the separate cross-period check.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(PreviousItemTrackingCode, false, false);
        LibraryItemTracking.CreateItemTrackingCode(CurrentItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', CurrentItemTrackingCode.Code);
        CreateMockItemLedgerEntry(ItemLedgerEntry, Item."No.", WorkDate() - 1, false);
        ItemLedgerEntry."Lot No." := LibraryUtility.GenerateGUID();
        ItemLedgerEntry.Modify();
        CreateChangeLog(Item."No.", ItemLedgerEntry.SystemCreatedAt + 1000, PreviousItemTrackingCode.Code, CurrentItemTrackingCode.Code);

        Assert.IsTrue(
            ItemTrackingCodeChangeMgt.IsCurrentTrackingCodeCompatibleWithEntry(ItemLedgerEntry),
            'The entry should satisfy the current specific-tracking requirements.');
        Assert.IsTrue(
            ItemTrackingCodeChangeMgt.GetTrackingCodeForLinkedApplication(
                Item."No.", ItemLedgerEntry."Entry No.", HistoricalItemTrackingCode),
            'The historical tracking-code change must still be detected.');
        Assert.AreEqual(
            PreviousItemTrackingCode.Code, HistoricalItemTrackingCode,
            'The cross-period check should retain the historical tracking code.');
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
        LibraryLowerPermissions.AddeRead();

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
        LibraryLowerPermissions.AddeRead();
        LibraryLowerPermissions.AddPermissionSet('ITEM TRACKING CHANGE');

        // [WHEN] The user enables lot tracking for item "I".
        ChangeItemTrackingCode(Item, ItemTrackingCode.Code);

        // [THEN] The change is logged.
        VerifyChangeLog(Item."No.", '', ItemTrackingCode.Code);
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
        CreateChangeLog(Item."No.", CreateDateTime(WorkDate(), 0T), '', 'NEW');
        ItemTrackingCodeChangeLog.Get(Item."No.", CreateDateTime(WorkDate(), 0T));

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
        CreateChangeLog(Item."No.", CreateDateTime(WorkDate(), 0T), '', 'NEW');
        ItemTrackingCodeChangeLog.Get(Item."No.", CreateDateTime(WorkDate(), 0T));

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
        CreateChangeLog(Item."No.", CreateDateTime(WorkDate(), 0T), '', 'NEW');
        ItemTrackingCodeChangeLog.Get(Item."No.", CreateDateTime(WorkDate(), 0T));

        // [WHEN] Audit entry "L" is renamed.
        asserterror ItemTrackingCodeChangeLog.Rename(Item."No.", CreateDateTime(WorkDate() - 1, 0T));

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
        CreateChangeLog(Item."No.", CurrentDateTime(), ItemTrackingCode.Code, '');

        // [WHEN] Tracking code "T" is deleted.
        asserterror ItemTrackingCode.Delete(true);

        // [THEN] Deletion is blocked because historical audit information must remain valid.
        Assert.ExpectedError('Item Tracking Code Change Log');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure HistoricalSerialSpecificTrackingCannotBeDisabled()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] Historical serial-specific tracking remains protected after the last item switches away.
        Initialize();
        CreateHistoricalTrackingCode(ItemTrackingCode, true, false, false);

        asserterror ItemTrackingCode.Validate("SN Specific Tracking", false);

        Assert.ExpectedError('Item Tracking Code Change Log');
        Assert.ExpectedErrorCode('Dialog');
        ItemTrackingCode.Get(ItemTrackingCode.Code);
        ItemTrackingCode.TestField("SN Specific Tracking", true);
    end;

    [Test]
    procedure HistoricalLotSpecificTrackingCannotBeDisabled()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] Historical lot-specific tracking remains protected after the last item switches away.
        Initialize();
        CreateHistoricalTrackingCode(ItemTrackingCode, false, true, false);

        asserterror ItemTrackingCode.Validate("Lot Specific Tracking", false);

        Assert.ExpectedError('Item Tracking Code Change Log');
        Assert.ExpectedErrorCode('Dialog');
        ItemTrackingCode.Get(ItemTrackingCode.Code);
        ItemTrackingCode.TestField("Lot Specific Tracking", true);
    end;

    [Test]
    procedure HistoricalPackageSpecificTrackingCannotBeDisabled()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] Historical package-specific tracking remains protected after the last item switches away.
        Initialize();
        CreateHistoricalTrackingCode(ItemTrackingCode, false, false, true);

        asserterror ItemTrackingCode.Validate("Package Specific Tracking", false);

        Assert.ExpectedError('Item Tracking Code Change Log');
        Assert.ExpectedErrorCode('Dialog');
        ItemTrackingCode.Get(ItemTrackingCode.Code);
        ItemTrackingCode.TestField("Package Specific Tracking", true);
    end;

    [Test]
    procedure HistoricalSpecificTrackingCannotBeEnabled()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] A historical non-specific tracking definition cannot acquire lot-specific tracking.
        Initialize();
        CreateHistoricalTrackingCode(ItemTrackingCode, false, false, false);

        asserterror ItemTrackingCode.Validate("Lot Specific Tracking", true);

        Assert.ExpectedError('Item Tracking Code Change Log');
        Assert.ExpectedErrorCode('Dialog');
        ItemTrackingCode.Get(ItemTrackingCode.Code);
        ItemTrackingCode.TestField("Lot Specific Tracking", false);
    end;

    [Test]
    procedure HistoricalWarehouseTrackingCannotBeDisabled()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] Historical warehouse tracking is protected by the existing field validation paths.
        Initialize();
        CreateHistoricalTrackingCode(ItemTrackingCode, false, true, false);

        asserterror ItemTrackingCode.Validate("Lot Warehouse Tracking", false);

        Assert.ExpectedError('Item Tracking Code Change Log');
        Assert.ExpectedErrorCode('Dialog');
        ItemTrackingCode.Get(ItemTrackingCode.Code);
        ItemTrackingCode.TestField("Lot Warehouse Tracking", true);
    end;

    [Test]
    procedure HistoricalTrackingCodeDescriptionCanBeChanged()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] Historical use does not prevent editing a tracking code description.
        Initialize();
        CreateHistoricalTrackingCode(ItemTrackingCode, false, true, false);

        ItemTrackingCode.Validate(Description, 'Updated description');
        ItemTrackingCode.Modify(true);

        ItemTrackingCode.Get(ItemTrackingCode.Code);
        ItemTrackingCode.TestField(Description, 'Updated description');
    end;

    [Test]
    procedure HistoricalTrackingCodeOtherSettingsKeepExistingBehavior()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] Historical use does not introduce a blanket lock on settings without the existing restrictions.
        Initialize();
        CreateHistoricalTrackingCode(ItemTrackingCode, false, true, false);

        ItemTrackingCode.Validate("Lot Info. Inbound Must Exist", true);
        ItemTrackingCode.Modify(true);

        ItemTrackingCode.Get(ItemTrackingCode.Code);
        ItemTrackingCode.TestField("Lot Info. Inbound Must Exist", true);
    end;

    [Test]
    procedure UnusedTrackingCodeSpecificTrackingCanBeChanged()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] An unused tracking definition can still be configured.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);

        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Modify(true);
        ItemTrackingCode.Get(ItemTrackingCode.Code);
        ItemTrackingCode.TestField("Lot Specific Tracking", true);

        ItemTrackingCode.Validate("Lot Specific Tracking", false);
        ItemTrackingCode.Modify(true);

        ItemTrackingCode.Get(ItemTrackingCode.Code);
        ItemTrackingCode.TestField("Lot Specific Tracking", false);
    end;

    [Test]
    procedure AssignedTrackingCodeWithoutEntriesCanStillBeConfigured()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] Assignment alone does not introduce a new restriction before the first posting.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);

        ItemTrackingCode.Validate("Lot Specific Tracking", false);
        ItemTrackingCode.Modify(true);

        ItemTrackingCode.Get(ItemTrackingCode.Code);
        ItemTrackingCode.TestField("Lot Specific Tracking", false);
    end;

    [Test]
    procedure AssignedTrackingCodeWithEntriesRemainsProtected()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] Existing protection for currently assigned items with ledger entries remains unchanged.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        CreateMockItemLedgerEntry(ItemLedgerEntry, Item."No.", WorkDate() - 1, false);
        Commit();

        asserterror ItemTrackingCode.Validate("Lot Specific Tracking", false);

        Assert.ExpectedError('Entries exist for item');
        Assert.ExpectedErrorCode('Dialog');
        ItemTrackingCode.Get(ItemTrackingCode.Code);
        ItemTrackingCode.TestField("Lot Specific Tracking", true);
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
    procedure TrackingChangeIsAllowedWithClosedItemLedgerEntriesOnSameDate()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Closed, fully costed entries on the same date do not prevent a tracking change.
        Initialize();

        // [GIVEN] Item "I" with closed entries posted on the working date.
        CreateClosedItemHistory(Item, WorkDate(), true, true);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [WHEN] Lot tracking is enabled for item "I".
        ChangeItemTrackingCode(Item, ItemTrackingCode.Code);

        // [THEN] The current tracking code and actual change date and time are logged.
        VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
        VerifyChangeLog(Item."No.", '', ItemTrackingCode.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BackdatedPostingUsesCurrentLotTracking()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
        LotNo: Code[50];
    begin
        // [SCENARIO 435436] A backdated new receipt uses current lot tracking, not historical accounting dates.
        Initialize();
        CreateItemWithTrackingChange(Item);
        LotNo := LibraryUtility.GenerateGUID();

        PostLotTrackedItemJournalLine(Item."No.", WorkDate() - 2, LotNo);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        Assert.RecordCount(ItemLedgerEntry, 1);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Posting Date", WorkDate() - 2);
        ItemLedgerEntry.TestField(Quantity, 1);
        Assert.IsFalse(
            ItemTrackingCodeChangeMgt.IsLinkedApplicationAcrossTrackingPeriods(Item."No.", ItemLedgerEntry."Entry No."),
            'A new backdated receipt must not be classified as belonging to the earlier tracking setup.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PostingOnTrackingChangeDateIsAllowed()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[50];
    begin
        // [SCENARIO 435436] New lot-tracked posting remains allowed on the same accounting date as the closed history.
        Initialize();
        CreateItemWithTrackingChange(Item);
        LotNo := LibraryUtility.GenerateGUID();

        PostLotTrackedItemJournalLine(Item."No.", WorkDate(), LotNo);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Posting Date", WorkDate());
        Assert.RecordCount(ItemLedgerEntry, 1);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField(Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PostingAfterTrackingChangeDateIsAllowed()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[50];
    begin
        // [SCENARIO 435436] New lot-tracked posting remains allowed with a later accounting date.
        Initialize();
        CreateItemWithTrackingChange(Item);
        LotNo := LibraryUtility.GenerateGUID();

        PostLotTrackedItemJournalLine(Item."No.", WorkDate() + 1, LotNo);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Posting Date", WorkDate() + 1);
        Assert.RecordCount(ItemLedgerEntry, 1);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField(Quantity, 1);
    end;

    [Test]
    procedure PostingAfterTrackingIsDisabledCanBeBackdated()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO 435436] A backdated posting uses the currently untracked setup after tracking is disabled.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateChangeLog(Item."No.", CurrentDateTime() - 2000, '', ItemTrackingCode.Code);
        CreateChangeLog(Item."No.", CurrentDateTime() - 1000, ItemTrackingCode.Code, '');

        PostItemJournalLine(Item."No.", WorkDate() - 1, 1);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        Assert.RecordCount(ItemLedgerEntry, 1);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Posting Date", WorkDate() - 1);
        ItemLedgerEntry.TestField("Lot No.", '');
    end;

    [Test]
    procedure PostingWithoutTrackingChangesCanStillBeBackdated()
    var
        Item: Record Item;
        OtherItemTrackingCode: Record "Item Tracking Code";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO 435436] Another item's tracking changes do not restrict ordinary backdated posting.
        Initialize();
        CreateHistoricalTrackingCode(OtherItemTrackingCode, false, true, false);
        LibraryInventory.CreateItem(Item);

        PostItemJournalLine(Item."No.", WorkDate() - 1, 1);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        Assert.RecordCount(ItemLedgerEntry, 1);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Posting Date", WorkDate() - 1);
        ItemLedgerEntry.TestField(Quantity, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeIsAllowedWithClosedFutureDatedHistory()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 435436] Closed, fully costed history can have accounting dates later than the tracking change.
        Initialize();
        CreateClosedItemHistory(Item, WorkDate() + 1, true, true);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        ChangeItemTrackingCode(Item, ItemTrackingCode.Code);

        VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
        VerifyChangeLog(Item."No.", '', ItemTrackingCode.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeUsesActualDateTimeNotWorkDate()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
        OriginalWorkDate: Date;
        BeforeChange: DateTime;
        AfterChange: DateTime;
    begin
        // [SCENARIO 435436] Changing WorkDate does not backdate the tracking-code audit event.
        Initialize();
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        OriginalWorkDate := WorkDate();
        WorkDate(Today() - 7);
        BeforeChange := CurrentDateTime();

        ChangeItemTrackingCode(Item, ItemTrackingCode.Code);

        AfterChange := CurrentDateTime();
        WorkDate(OriginalWorkDate);
        ItemTrackingCodeChangeLog.SetRange("Item No.", Item."No.");
        ItemTrackingCodeChangeLog.FindFirst();
        Assert.IsTrue(
            (ItemTrackingCodeChangeLog."Change DateTime" >= BeforeChange) and
            (ItemTrackingCodeChangeLog."Change DateTime" <= AfterChange),
            'The audit event must use the actual date and time, not WorkDate.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TrackingChangeCanRepeatOnSameDate()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
    begin
        // [SCENARIO 435436] An eligible item can change tracking again on the same date at a different time.
        Initialize();
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify();
        CreateChangeLog(Item."No.", CreateDateTime(Today(), 0T), '', ItemTrackingCode.Code);

        ChangeItemTrackingCode(Item, '');

        ItemTrackingCodeChangeLog.SetRange("Item No.", Item."No.");
        Assert.RecordCount(ItemTrackingCodeChangeLog, 2);
        ItemTrackingCodeChangeLog.FindLast();
        Assert.AreEqual(Today(), DT2Date(ItemTrackingCodeChangeLog."Change DateTime"), 'Both changes must be on the same date.');
        VerifyItemTrackingCode(Item."No.", '');
        VerifyChangeLog(Item."No.", ItemTrackingCode.Code, '');
    end;

    [Test]
    procedure SameDayTrackingPeriodsAreReconstructedByCreationTime()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotTrackingCode: Record "Item Tracking Code";
        SerialTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
    begin
        // [SCENARIO 435436] Same-day entries before, between and after changes resolve their actual tracking setup.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(LotTrackingCode, false, true);
        LibraryItemTracking.CreateItemTrackingCode(SerialTrackingCode, true, false);
        LibraryInventory.CreateTrackedItem(Item, '', '', SerialTrackingCode.Code);
        CreateChangeLog(Item."No.", CreateDateTime(Today(), 103000T), '', LotTrackingCode.Code);
        CreateChangeLog(Item."No.", CreateDateTime(Today(), 113000T), LotTrackingCode.Code, SerialTrackingCode.Code);
        ItemLedgerEntry."Item No." := Item."No.";
        ItemLedgerEntry."Posting Date" := WorkDate() + 10;

        ItemLedgerEntry.SystemCreatedAt := CreateDateTime(Today(), 101500T);
        Assert.AreEqual(
            '', ItemTrackingCodeChangeMgt.GetTrackingCodeAtPosting(ItemLedgerEntry),
            'An entry created at 10:15 must retain the untracked setup.');

        ItemLedgerEntry.SystemCreatedAt := CreateDateTime(Today(), 110000T);
        Assert.AreEqual(
            LotTrackingCode.Code, ItemTrackingCodeChangeMgt.GetTrackingCodeAtPosting(ItemLedgerEntry),
            'An entry created at 11:00 must retain the lot-tracked setup.');

        ItemLedgerEntry."Posting Date" := WorkDate() - 10;
        ItemLedgerEntry.SystemCreatedAt := CreateDateTime(Today(), 120000T);
        Assert.AreEqual(
            SerialTrackingCode.Code, ItemTrackingCodeChangeMgt.GetTrackingCodeAtPosting(ItemLedgerEntry),
            'An entry created at 12:00 must use the current serial-tracked setup, even when backdated.');
    end;

    [Test]
    procedure FutureDatedOriginalEntryRetainsHistoricalTracking()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
        HistoricalItemTrackingCode: Code[10];
    begin
        // [SCENARIO 435436] A future Posting Date does not conceal that an original entry predates a tracking change.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        CreateMockItemLedgerEntry(ItemLedgerEntry, Item."No.", WorkDate() + 10, false);
        CreateChangeLog(Item."No.", ItemLedgerEntry.SystemCreatedAt + 1000, '', ItemTrackingCode.Code);

        Assert.IsTrue(
            ItemTrackingCodeChangeMgt.GetTrackingCodeForLinkedApplication(
                Item."No.", ItemLedgerEntry."Entry No.", HistoricalItemTrackingCode),
            'The original entry must be recognized as belonging to the previous tracking setup.');
        Assert.AreEqual('', HistoricalItemTrackingCode, 'The original entry was untracked.');
    end;

    [Test]
    procedure BackdatedEntryCreatedAfterChangeIsNotHistorical()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
    begin
        // [SCENARIO 435436] Historical application checks use creation time rather than a backdated Posting Date.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        CreateChangeLog(Item."No.", CurrentDateTime() - 1000, '', ItemTrackingCode.Code);
        CreateMockItemLedgerEntry(ItemLedgerEntry, Item."No.", WorkDate() - 10, false);

        Assert.IsFalse(
            ItemTrackingCodeChangeMgt.IsLinkedApplicationAcrossTrackingPeriods(Item."No.", ItemLedgerEntry."Entry No."),
            'The entry was created after the tracking change and must not be treated as historical.');
    end;

    [Test]
    procedure EmptyCreationDateTimeUsesCurrentDateTime()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
    begin
        // [SCENARIO 435436] An empty creation timestamp resolves at the current actual time without changing the audit field.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        CreateChangeLog(Item."No.", CurrentDateTime() - 1000, '', ItemTrackingCode.Code);
        ItemLedgerEntry."Item No." := Item."No.";
        ItemLedgerEntry."Posting Date" := WorkDate() - 10;

        Assert.AreEqual(
            ItemTrackingCode.Code, ItemTrackingCodeChangeMgt.GetTrackingCodeAtPosting(ItemLedgerEntry),
            'An empty creation timestamp must use the current time, not the backdated Posting Date.');
        ItemLedgerEntry.TestField(SystemCreatedAt, 0DT);
    end;

    [Test]
    procedure ChangeLogDefaultsToCurrentDateTime()
    var
        Item: Record Item;
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
        OriginalWorkDate: Date;
        BeforeChange: DateTime;
        AfterChange: DateTime;
    begin
        // [SCENARIO 435436] Inserting an audit event without a timestamp defaults to actual time rather than WorkDate.
        Initialize();
        LibraryInventory.CreateItem(Item);
        OriginalWorkDate := WorkDate();
        WorkDate(Today() - 7);
        // Round the bounds outward to allow for persisted DateTime precision.
        BeforeChange := RoundDateTime(CurrentDateTime(), 1000, '<');

        CreateChangeLog(Item."No.", 0DT, '', 'NEW');

        AfterChange := RoundDateTime(CurrentDateTime(), 1000, '>');
        WorkDate(OriginalWorkDate);
        ItemTrackingCodeChangeLog.SetRange("Item No.", Item."No.");
        ItemTrackingCodeChangeLog.FindFirst();
        Assert.IsTrue(
            (ItemTrackingCodeChangeLog."Change DateTime" >= BeforeChange) and
            (ItemTrackingCodeChangeLog."Change DateTime" <= AfterChange),
            'The default audit timestamp must be the current date and time.');
    end;

    [Test]
    procedure MatchingCreationAndChangeDateTimesRaiseExplicitError()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
    begin
        // [SCENARIO 435436] Identical timestamps must not silently guess which tracking setup governed an entry.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        CreateMockItemLedgerEntry(ItemLedgerEntry, Item."No.", WorkDate(), false);
        CreateChangeLog(Item."No.", ItemLedgerEntry.SystemCreatedAt, '', ItemTrackingCode.Code);

        asserterror ItemTrackingCodeChangeMgt.IsLinkedApplicationAcrossTrackingPeriods(Item."No.", ItemLedgerEntry."Entry No.");

        Assert.ExpectedError('matches an item tracking code change');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure TrackingHistoryForAnotherItemDoesNotAffectLookup()
    var
        Item: Record Item;
        OtherItem: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingCodeChangeMgt: Codeunit "Item Tracking Code Change Mgt.";
    begin
        // [SCENARIO 435436] Another item's later change cannot make an untracked entry cross-period.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(OtherItem);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateMockItemLedgerEntry(ItemLedgerEntry, Item."No.", WorkDate(), false);
        CreateChangeLog(OtherItem."No.", ItemLedgerEntry.SystemCreatedAt + 1000, '', ItemTrackingCode.Code);

        Assert.IsFalse(
            ItemTrackingCodeChangeMgt.IsLinkedApplicationAcrossTrackingPeriods(Item."No.", ItemLedgerEntry."Entry No."),
            'Tracking history must be isolated by item.');
    end;

    [Test]
    procedure TemporaryHistoricalEntryCanRetainOriginalPostingDate()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
    begin
        // [SCENARIO 435436] Temporary copies of historical entries are not new inventory postings.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateChangeLog(Item."No.", CurrentDateTime(), ItemTrackingCode.Code, '');
        TempItemLedgerEntry."Entry No." := 1;
        TempItemLedgerEntry."Item No." := Item."No.";
        TempItemLedgerEntry."Posting Date" := WorkDate() - 1;

        TempItemLedgerEntry.Insert(true);

        Assert.RecordCount(TempItemLedgerEntry, 1);
        TempItemLedgerEntry.TestField("Posting Date", WorkDate() - 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure HistoricalCostAdjustmentRemainsAllowedAfterTrackingChange()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [SCENARIO 435436] Adjusting existing historical entries preserves their original accounting dates.
        Initialize();
        CreateItemWithTrackingChange(Item);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.ModifyAll("Applied Entry to Adjust", true, true);
        Item.Validate("Cost is Adjusted", false);
        Item.Modify(true);

        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        Assert.RecordCount(ItemLedgerEntry, 2);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Posting Date", WorkDate() - 1);
        Item.Get(Item."No.");
        Item.TestField("Cost is Adjusted", true);
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
        InventorySetup: Record "Inventory Setup";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 435436] Tracking cannot change before adjusted inventory costs are posted to the general ledger.
        Initialize();

        // [GIVEN] Item "I" with adjusted costs that have not been posted to the general ledger.
        InventorySetup.Get();
        LibraryInventory.SetAutomaticCostPosting(false);
        CreateClosedItemHistory(Item, WorkDate() - 1, true, false);
        LibraryInventory.SetAutomaticCostPosting(InventorySetup."Automatic Cost Posting");
        Item.TestField("Cost is Adjusted", true);
        Item.CalcFields("Cost is Posted to G/L");
        Item.TestField("Cost is Posted to G/L", false);
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
    procedure PartiallyShippedInvoicedSalesOrderBlocksTrackingChange()
    begin
        // [SCENARIO 435436] A fully invoiced shipment does not permit changing tracking while the order remains outstanding.
        Initialize();
        VerifySalesDocumentTrackingChange("Sales Document Type"::Order, 1, 1, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PartiallyReceivedInvoicedSalesReturnBlocksTrackingChange()
    begin
        // [SCENARIO 435436] A partially received and fully invoiced sales return still prevents changing tracking.
        Initialize();
        VerifySalesDocumentTrackingChange("Sales Document Type"::"Return Order", 1, 1, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PartiallyReceivedInvoicedPurchaseOrderBlocksTrackingChange()
    begin
        // [SCENARIO 435436] A fully invoiced receipt does not permit changing tracking while the order remains outstanding.
        Initialize();
        VerifyPurchaseDocumentTrackingChange("Purchase Document Type"::Order, 1, 1, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PartiallyShippedInvoicedPurchaseReturnBlocksTrackingChange()
    begin
        // [SCENARIO 435436] A partially shipped and fully invoiced purchase return still prevents changing tracking.
        Initialize();
        VerifyPurchaseDocumentTrackingChange("Purchase Document Type"::"Return Order", 1, 1, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure UntouchedSalesOrderAllowsTrackingChange()
    begin
        // [SCENARIO 435436] An outstanding sales order with no shipment does not prevent changing tracking.
        Initialize();
        VerifySalesDocumentTrackingChange("Sales Document Type"::Order, 0, 1, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure UntouchedSalesReturnAllowsTrackingChange()
    begin
        // [SCENARIO 435436] An outstanding sales return with no receipt does not prevent changing tracking.
        Initialize();
        VerifySalesDocumentTrackingChange("Sales Document Type"::"Return Order", 0, 1, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure UntouchedPurchaseOrderAllowsTrackingChange()
    begin
        // [SCENARIO 435436] An outstanding purchase order with no receipt does not prevent changing tracking.
        Initialize();
        VerifyPurchaseDocumentTrackingChange("Purchase Document Type"::Order, 0, 1, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure UntouchedPurchaseReturnAllowsTrackingChange()
    begin
        // [SCENARIO 435436] An outstanding purchase return with no shipment does not prevent changing tracking.
        Initialize();
        VerifyPurchaseDocumentTrackingChange("Purchase Document Type"::"Return Order", 0, 1, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CompletedInvoicedSalesOrderAllowsTrackingChange()
    begin
        // [SCENARIO 435436] A completely shipped and invoiced sales order does not prevent changing tracking.
        Initialize();
        VerifySalesDocumentTrackingChange("Sales Document Type"::Order, 1, 0, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CompletedInvoicedSalesReturnAllowsTrackingChange()
    begin
        // [SCENARIO 435436] A completely received and invoiced sales return does not prevent changing tracking.
        Initialize();
        VerifySalesDocumentTrackingChange("Sales Document Type"::"Return Order", 1, 0, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CompletedInvoicedPurchaseOrderAllowsTrackingChange()
    begin
        // [SCENARIO 435436] A completely received and invoiced purchase order does not prevent changing tracking.
        Initialize();
        VerifyPurchaseDocumentTrackingChange("Purchase Document Type"::Order, 1, 0, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CompletedInvoicedPurchaseReturnAllowsTrackingChange()
    begin
        // [SCENARIO 435436] A completely shipped and invoiced purchase return does not prevent changing tracking.
        Initialize();
        VerifyPurchaseDocumentTrackingChange("Purchase Document Type"::"Return Order", 1, 0, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure NegativePartiallyProcessedSalesOrderBlocksTrackingChange()
    begin
        // [SCENARIO 435436] Negative processed and outstanding quantities do not bypass the partial-order restriction.
        Initialize();
        VerifySalesDocumentTrackingChange("Sales Document Type"::Order, -1, -1, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure NegativePartiallyProcessedPurchaseOrderBlocksTrackingChange()
    begin
        // [SCENARIO 435436] Negative processed and outstanding quantities do not bypass the partial-order restriction.
        Initialize();
        VerifyPurchaseDocumentTrackingChange("Purchase Document Type"::Order, -1, -1, true);
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
    procedure UnmatchedPhysicalInventoryRecordingBlocksTrackingChange()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 435436] An unfinished recording without a matching order line prevents changing tracking.
        Initialize();
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateUnmatchedPhysicalInventoryRecording(PhysInvtRecordLine, Item."No.");
        PhysInvtRecordLine.TestField("Use Item Tracking", false);
        PhysInvtRecordLine.TestField(Recorded, false);
        Commit();

        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        Assert.ExpectedMessage(
            StrSubstNo(RecordsExistErr, Item."No.", PhysInvtRecordLine.TableCaption()),
            ErrorMessages.Description.Value);
        VerifyItemTrackingCode(Item."No.", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ZeroQuantityPhysicalInventoryRecordingBlocksTrackingChange()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 435436] A recorded zero count is still unposted inventory work and prevents changing tracking.
        Initialize();
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateUnmatchedPhysicalInventoryRecording(PhysInvtRecordLine, Item."No.");
        PhysInvtRecordLine.Validate(Quantity, 0);
        PhysInvtRecordLine.Modify(true);
        PhysInvtRecordLine.TestField(Recorded, true);
        Commit();

        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        Assert.ExpectedMessage(
            StrSubstNo(RecordsExistErr, Item."No.", PhysInvtRecordLine.TableCaption()),
            ErrorMessages.Description.Value);
        VerifyItemTrackingCode(Item."No.", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AnotherItemsPhysicalInventoryRecordingAllowsTrackingChange()
    var
        Item: Record Item;
        OtherItem: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [SCENARIO 435436] An unmatched recording for another item does not prevent changing this item's tracking.
        Initialize();
        CreateEligibleItemWithHistory(Item);
        LibraryInventory.CreateItem(OtherItem);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateUnmatchedPhysicalInventoryRecording(PhysInvtRecordLine, OtherItem."No.");

        ChangeItemTrackingCode(Item, ItemTrackingCode.Code);

        VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
        VerifyChangeLog(Item."No.", '', ItemTrackingCode.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PostedPhysicalInventoryRecordingAllowsTrackingChange()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
    begin
        // [SCENARIO 435436] Posted recording history alone does not prevent changing tracking.
        Initialize();
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        PstdPhysInvtRecordLine."Order No." := LibraryUtility.GenerateGUID();
        PstdPhysInvtRecordLine."Recording No." := 1;
        PstdPhysInvtRecordLine."Line No." := 10000;
        PstdPhysInvtRecordLine."Item No." := Item."No.";
        PstdPhysInvtRecordLine.Insert();

        ChangeItemTrackingCode(Item, ItemTrackingCode.Code);

        VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
        VerifyChangeLog(Item."No.", '', ItemTrackingCode.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure DeletingPhysicalInventoryRecordingAllowsTrackingChange()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [SCENARIO 435436] Removing an unmatched recording leaves no counting-line blocker for the item.
        Initialize();
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateUnmatchedPhysicalInventoryRecording(PhysInvtRecordLine, Item."No.");
        PhysInvtRecordHeader.Get(PhysInvtRecordLine."Order No.", PhysInvtRecordLine."Recording No.");
        PhysInvtRecordHeader.Delete(true);
        PhysInvtRecordLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(PhysInvtRecordLine, 0);

        ChangeItemTrackingCode(Item, ItemTrackingCode.Code);

        VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
        VerifyChangeLog(Item."No.", '', ItemTrackingCode.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PhysicalInventoryOrderLineStillBlocksTrackingChange()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO 435436] The original order-line blocker remains effective without any recording line.
        Initialize();
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateUnmatchedPhysicalInventoryRecording(PhysInvtRecordLine, Item."No.");
        PhysInvtRecordLine.Delete(true);
        LibraryInventory.CreatePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtRecordLine."Order No.", Item."No.");
        Commit();

        TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);

        Assert.ExpectedMessage(
            StrSubstNo(RecordsExistErr, Item."No.", PhysInvtOrderLine.TableCaption()),
            ErrorMessages.Description.Value);
        VerifyItemTrackingCode(Item."No.", '');
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
        ErrorMessages.First();
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

    local procedure CreateItemWithTrackingChange(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ChangeItemTrackingCode(Item, ItemTrackingCode.Code);
    end;

    local procedure PostLotTrackedItemJournalLine(ItemNo: Code[20]; PostingDate: Date; LotNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', 1);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, 1);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateTrackingCompatibilitySetup(var ItemLedgerEntry: Record "Item Ledger Entry"; SNSpecific: Boolean; LotSpecific: Boolean; PackageSpecific: Boolean)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LotSpecific, PackageSpecific);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Item No." := Item."No.";
    end;

    local procedure CreateExpirationTrackedItem(var Item: Record Item; var ItemTrackingCode: Record "Item Tracking Code")
    var
        EmptyDateFormula: DateFormula;
    begin
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        Item.TestField("Expiration Calculation", EmptyDateFormula);
        Commit();
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
            LibraryPostInventoryToGL.PostInvtCostToGL(Item."No.", PostingDate);
        Item.Get(Item."No.");
    end;

    local procedure CreateItemWithOpenHistory(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", 1);
        Item.Modify(true);
        PostItemJournalLine(Item."No.", WorkDate() - 1, 1);
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        LibraryPostInventoryToGL.PostInvtCostToGL(Item."No.", WorkDate() - 1);
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

    local procedure CreateChangeLog(ItemNo: Code[20]; ChangeDateTime: DateTime; PreviousItemTrackingCode: Code[10]; NewItemTrackingCode: Code[10])
    var
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
    begin
        ItemTrackingCodeChangeLog.Init();
        ItemTrackingCodeChangeLog."Item No." := ItemNo;
        ItemTrackingCodeChangeLog."Change DateTime" := ChangeDateTime;
        ItemTrackingCodeChangeLog."Previous Item Tracking Code" := PreviousItemTrackingCode;
        ItemTrackingCodeChangeLog."New Item Tracking Code" := NewItemTrackingCode;
        ItemTrackingCodeChangeLog.Insert(true);
    end;

    local procedure CreateHistoricalTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; SNSpecific: Boolean; LotSpecific: Boolean; PackageSpecific: Boolean)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LotSpecific, PackageSpecific);
        CreateChangeLog(Item."No.", CurrentDateTime(), ItemTrackingCode.Code, '');
        Commit();
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

    local procedure VerifySalesDocumentTrackingChange(DocumentType: Enum "Sales Document Type"; ProcessedQuantity: Decimal; OutstandingQuantity: Decimal; ShouldBlock: Boolean)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SalesLine: Record "Sales Line";
        ErrorMessages: TestPage "Error Messages";
    begin
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        SalesLine."Document Type" := DocumentType;
        SalesLine."Document No." := LibraryUtility.GenerateGUID();
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Quantity := ProcessedQuantity + OutstandingQuantity;
        SalesLine."Quantity (Base)" := SalesLine.Quantity;
        SalesLine."Quantity Invoiced" := ProcessedQuantity;
        SalesLine."Qty. Invoiced (Base)" := ProcessedQuantity;
        SalesLine."Outstanding Quantity" := OutstandingQuantity;
        SalesLine."Outstanding Qty. (Base)" := OutstandingQuantity;
        if DocumentType = DocumentType::Order then begin
            SalesLine."Quantity Shipped" := ProcessedQuantity;
            SalesLine."Qty. Shipped (Base)" := ProcessedQuantity;
        end else begin
            SalesLine."Return Qty. Received" := ProcessedQuantity;
            SalesLine."Return Qty. Received (Base)" := ProcessedQuantity;
        end;
        SalesLine.Insert();
        SalesLine.TestField("Qty. Shipped Not Invoiced", 0);
        SalesLine.TestField("Return Qty. Rcd. Not Invd.", 0);

        if ShouldBlock then begin
            Commit();
            TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);
            Assert.ExpectedMessage(
                StrSubstNo(RecordsExistErr, Item."No.", SalesLine.TableCaption()),
                ErrorMessages.Description.Value);
            VerifyItemTrackingCode(Item."No.", '');
        end else begin
            ChangeItemTrackingCode(Item, ItemTrackingCode.Code);
            VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
            VerifyChangeLog(Item."No.", '', ItemTrackingCode.Code);
        end;
    end;

    local procedure VerifyPurchaseDocumentTrackingChange(DocumentType: Enum "Purchase Document Type"; ProcessedQuantity: Decimal; OutstandingQuantity: Decimal; ShouldBlock: Boolean)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseLine: Record "Purchase Line";
        ErrorMessages: TestPage "Error Messages";
    begin
        CreateEligibleItemWithHistory(Item);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        PurchaseLine."Document Type" := DocumentType;
        PurchaseLine."Document No." := LibraryUtility.GenerateGUID();
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := Item."No.";
        PurchaseLine.Quantity := ProcessedQuantity + OutstandingQuantity;
        PurchaseLine."Quantity (Base)" := PurchaseLine.Quantity;
        PurchaseLine."Quantity Invoiced" := ProcessedQuantity;
        PurchaseLine."Qty. Invoiced (Base)" := ProcessedQuantity;
        PurchaseLine."Outstanding Quantity" := OutstandingQuantity;
        PurchaseLine."Outstanding Qty. (Base)" := OutstandingQuantity;
        if DocumentType = DocumentType::Order then begin
            PurchaseLine."Quantity Received" := ProcessedQuantity;
            PurchaseLine."Qty. Received (Base)" := ProcessedQuantity;
        end else begin
            PurchaseLine."Return Qty. Shipped" := ProcessedQuantity;
            PurchaseLine."Return Qty. Shipped (Base)" := ProcessedQuantity;
        end;
        PurchaseLine.Insert();
        PurchaseLine.TestField("Qty. Rcd. Not Invoiced", 0);
        PurchaseLine.TestField("Return Qty. Shipped Not Invd.", 0);

        if ShouldBlock then begin
            Commit();
            TrapTrackingChangeErrors(Item, ItemTrackingCode.Code, ErrorMessages);
            Assert.ExpectedMessage(
                StrSubstNo(RecordsExistErr, Item."No.", PurchaseLine.TableCaption()),
                ErrorMessages.Description.Value);
            VerifyItemTrackingCode(Item."No.", '');
        end else begin
            ChangeItemTrackingCode(Item, ItemTrackingCode.Code);
            VerifyItemTrackingCode(Item."No.", ItemTrackingCode.Code);
            VerifyChangeLog(Item."No.", '', ItemTrackingCode.Code);
        end;
    end;

    local procedure CreateUnmatchedPhysicalInventoryRecording(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; ItemNo: Code[20])
    var
        InventorySetup: Record "Inventory Setup";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Phys. Invt. Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Validate("Posted Phys. Invt. Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);
        LibraryInventory.CreatePhysInvtOrderHeader(PhysInvtOrderHeader);
        LibraryInventory.CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderHeader."No.");
        PhysInvtRecordHeader.Validate("Allow Recording Without Order", true);
        PhysInvtRecordHeader.Modify(true);

        PhysInvtRecordLine.Init();
        PhysInvtRecordLine.Validate("Order No.", PhysInvtOrderHeader."No.");
        PhysInvtRecordLine.Validate("Recording No.", PhysInvtRecordHeader."Recording No.");
        PhysInvtRecordLine.Validate("Line No.", 10000);
        PhysInvtRecordLine.Validate("Item No.", ItemNo);
        PhysInvtRecordLine.Validate(Recorded, false);
        PhysInvtRecordLine.Insert(true);
        PhysInvtRecordLine.TestField("Order Line No.", 0);
        PhysInvtOrderLine.SetRange("Item No.", ItemNo);
        Assert.RecordCount(PhysInvtOrderLine, 0);
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
        asserterror Item.Validate("Item Tracking Code", ItemTrackingCode);
        LibraryErrorMessage.GetTestPage(ErrorMessages);
    end;

    local procedure VerifyItemTrackingCode(ItemNo: Code[20]; ExpectedItemTrackingCode: Code[10])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreEqual(ExpectedItemTrackingCode, Item."Item Tracking Code", 'The item tracking code is incorrect.');
    end;

    local procedure VerifyChangeLog(ItemNo: Code[20]; PreviousItemTrackingCode: Code[10]; NewItemTrackingCode: Code[10])
    var
        ItemTrackingCodeChangeLog: Record "Item Tracking Code Change Log";
    begin
        ItemTrackingCodeChangeLog.SetRange("Item No.", ItemNo);
        ItemTrackingCodeChangeLog.FindLast();
        Assert.AreEqual(
            Today(), DT2Date(ItemTrackingCodeChangeLog."Change DateTime"),
            'The tracking change must be logged on the actual date.');
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
