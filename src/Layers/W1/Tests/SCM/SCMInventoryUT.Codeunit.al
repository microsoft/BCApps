codeunit 137821 "SCM - Inventory UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        CannotChangeItemTrackingCodeErr: Label 'You cannot change Item Tracking Code because there is at least one outstanding Purchase Order that include this item.';
        AvailProblemOccursOnSNTrackingErr: Label 'No availability problem should occur if SN Specific Tracking = FALSE.';
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure WrongErrorMessageWhenDeletingITCodeFromItem()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 6816] Item Tracking Code in Item could not be changed if an outstanding Purchase Order including this Item exists.
        Initialize();

        // [GIVEN] Item with Item Tracking Code. "Lot Specific Tracking" := TRUE.
        MockItemTrackingCode(ItemTrackingCode, true);
        MockItem(Item, LibraryUtility.GenerateGUID(), ItemTrackingCode.Code);

        // [GIVEN] Purchase Line with Item.
        MockPurchaseLine(PurchaseLine, Item."No.");

        // [WHEN] Delete the Item Tracking Code from Item.
        asserterror Item.Validate("Item Tracking Code", '');

        // [THEN] The error message refers to the purchase order line.
        Assert.ExpectedError(CannotChangeItemTrackingCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullSNAvailabilityWhenSNTrackingIsFalse()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        LookupMode: Enum "Item Tracking Type";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 6744] Check of Serial No. availability in Item Tracking should be passed successfully when "SN Specific Tracking" = FALSE in Item Tracking Code.
        Initialize();

        // [GIVEN] Item Tracking Code with "SN Specific Tracking" = FALSE.
        MockItemTrackingCode(ItemTrackingCode, false);

        // [GIVEN] Demand Reservation Entry and Tracking Specification.
        MockReservationEntry(ReservationEntry, LibraryUtility.GenerateGUID());
        MockTrackingSpecification(TrackingSpecification, ReservationEntry);

        // [WHEN] Call TrackingAvailable function checking whether any availability problem occurs.
        ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode('', ItemTrackingCode);
        Assert.IsTrue(
          ItemTrackingDataCollection.TrackingAvailable(TrackingSpecification, LookupMode::"Serial No."),
          AvailProblemOccursOnSNTrackingErr);

        // [THEN] TrackingAvailable function returns TRUE (no availability problem).
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoEntriesExistCheckSkippedOnEmptyItem()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item]
        // [SCENARIO 380565] Update of Costing Method for an Item with so far undefined "No.", should not check existence of Purchase Lines with "Item" Type and blank "No.".
        Initialize();

        // [GIVEN] Item with blank "No." and "Costing Method" = FIFO.
        MockItem(Item, '', '');

        // [GIVEN] Purchase Line with "Type" = Item and blank "No.".
        MockPurchaseLine(PurchaseLine, Item."No.");

        // [WHEN] Validate "Costing Method" of Item to Standard.
        Item.Validate("Costing Method", Item."Costing Method"::Standard);

        // [THEN] No error is thrown.
        // [THEN] "Costing Method" is updated.
        Item.TestField("Costing Method", Item."Costing Method"::Standard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankCustomerNos()
    var
        Customer: Record Customer;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 381935]  If delete the content of "Customer Nos." field in the "Sales & Receivables Setup" table, it should not be possible to create a record "Customer" with an empty value of the prinary key "No.".
        Initialize();
        // [GIVEN] "Sales & Receivables Setup" with a blank field "Customer Nos."
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Customer Nos.", '');
        SalesReceivablesSetup.Modify(true);
        // [WHEN] Insert "Customer" with blank "No."
        Customer.Init();
        Customer.Validate(Name, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer));
        // [THEN] Error occurs : "Customer Nos. must have a value in Sales & Receivables Setup: Primary Key=. It cannot be zero or empty."
        asserterror Customer.Insert(true);
        Assert.ExpectedTestFieldError(SalesReceivablesSetup.FieldName("Customer Nos."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankVendorNos()
    var
        Vendor: Record Vendor;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 381935]  If delete the content of "Vendor Nos." field in the "Purchases & Payables Setup" table, it should not be possible to create a record "Vendor" with an empty value of the prinary key "No.".
        Initialize();
        // [GIVEN] "Purchases & Payables Setup" with a blank field "Vendor Nos."
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Vendor Nos.", '');
        PurchasesPayablesSetup.Modify(true);
        // [WHEN] Insert "Vendor" with blank "No."
        Vendor.Init();
        Vendor.Validate(Name, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Name), DATABASE::Vendor));
        // [THEN] Error occurs : "Vendor Nos. must have a value in Purchases & Payables Setup: Primary Key=. It cannot be zero or empty."
        asserterror Vendor.Insert(true);
        Assert.ExpectedTestFieldError(PurchasesPayablesSetup.FieldName("Vendor Nos."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankItemNos()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
    begin
        // [FEATURE] [Item]
        // [SCENARIO 381935]  If delete the content of "Item Nos." field in the "Inventory Setup" table, it should not be possible to create a record "Item" with an empty value of the prinary key "No.".
        Initialize();
        // [GIVEN] "Inventory Setup" with a blank field "Item Nos."
        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", '');
        InventorySetup.Modify(true);
        // [WHEN] Insert "Item" with blank "No."
        Item.Init();
        Item.Validate(Description, LibraryUtility.GenerateRandomCode(Item.FieldNo(Description), DATABASE::Item));
        // [THEN] Error occurs : "Item Nos. must have a value in Inventory Setup: Primary Key=. It cannot be zero or empty."
        asserterror Item.Insert(true);

        Assert.ExpectedTestFieldError(InventorySetup.FieldName("Item Nos."), '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM - Inventory UT");
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM - Inventory UT");

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM - Inventory UT");
    end;

    local procedure MockItem(var Item: Record Item; No: Code[20]; ItemTrackingCode: Code[10])
    begin
        Item.Init();
        Item."No." := No;
        Item."Item Tracking Code" := ItemTrackingCode;
        Item."Costing Method" := Item."Costing Method"::FIFO;
        Item.Insert();
    end;

    local procedure MockItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; IsSpecificTracking: Boolean)
    begin
        ItemTrackingCode.Init();
        ItemTrackingCode.Code := LibraryUtility.GenerateGUID();
        ItemTrackingCode."Lot Specific Tracking" := IsSpecificTracking;
        ItemTrackingCode."SN Specific Tracking" := IsSpecificTracking;
        ItemTrackingCode.Insert();
    end;

    local procedure MockPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine."Document No." := LibraryUtility.GenerateGUID();
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := ItemNo;
        PurchaseLine.Insert();
    end;

    local procedure MockReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20])
    begin
        ReservationEntry.Init();
        ReservationEntry."Entry No." := LibraryUtility.GetNewRecNo(ReservationEntry, ReservationEntry.FieldNo("Entry No."));
        ReservationEntry.Positive := false;
        ReservationEntry."Item No." := ItemNo;
        ReservationEntry.Quantity := -LibraryRandom.RandInt(10);
        ReservationEntry."Quantity (Base)" := ReservationEntry.Quantity;
        ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Serial No.";
        ReservationEntry."Serial No." := LibraryUtility.GenerateGUID();
        ReservationEntry.Insert();
    end;

    local procedure MockTrackingSpecification(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
        TrackingSpecification.Init();
        TrackingSpecification."Item No." := ReservationEntry."Item No.";
        TrackingSpecification."Quantity (Base)" := ReservationEntry."Quantity (Base)";
        TrackingSpecification."Serial No." := ReservationEntry."Serial No.";
        TrackingSpecification.Insert();
    end;
}

