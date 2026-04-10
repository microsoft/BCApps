codeunit 137060 "SCM Inventory 7.0"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Inventory] [SCM]
        Initialized := false;
    end;

    var
        LocationInTransit: Record Location;
        LocationBlue: Record Location;
        LocationRed: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        RevaluationItemJournalTemplate: Record "Item Journal Template";
        RevaluationItemJournalBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        ReservationManagement: Codeunit "Reservation Management";
        ErrorDoNotMatchErr: Label 'Expected error: ''%1''\Actual error: ''%2''', Comment = '%1 = Error Text, %2 = Error Text';
        DivideByZeroErr: Label 'Attempted to divide by zero.';
        DimErr: Label 'Expected DimSetID: %1, Actual DimSetID: %2 ', Comment = 'Expected DimSetID: %1, Actual DimSetID: %2 ';
        ConfirmQst: Label 'Do you really want to change the Average Cost Period?';
        AdjustCostMsg: Label 'Average Cost Period has been changed to Accounting Period. You should now run Adjust Cost - Item Entries.';
        AdjustCost2Msg: Label 'Average Cost Period has been changed to Day. You should now run Adjust Cost - Item Entries.';
        Initialized: Boolean;
        RoundingPrecisionErr: Label 'Rounding Precision must be greater than 0.';
        DecimalPlacesErr: Label 'The field can have a maximum of 5 decimal places.';
        ReservedQtyErr: Label 'The Reserved Quantity Outbnd is changed.';
        WrongFieldValueErr: Label 'Value of %1 in table %2 is incorrect', Comment = '%1 = Field Name, %2 = Table Name';
        ItemVendorMustExistErr: Label 'Item Vendor must exist.';
        ItemVendorMustNotExistErr: Label 'Item Vendor must not exist.';
        DescriptionErr: Label 'Incorrect Description';
        TestFieldCodeErr: Label 'TestField';
        ReorderingPolicyShouldNotBeVisibleErr: Label ' Reordering Policy should not be visible.';
        SpecialEquipmentCodeShouldNotBeVisibleErr: Label ' Special Equipment Code should not be visible.';

    [Test]
    [Scope('OnPrem')]
    procedure B7425_AmtAtLowerBound()
    begin
        // Item Unit Cost test Boundary value : 0.
        Initialize();
        ItemJournalAmount(0, false); // Divide by Zero boolean - False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B7425_AmtLessThanUpperBound()
    begin
        // Item Unit Cost test Boundary value : Decimal value less than 100.
        Initialize();
        ItemJournalAmount(LibraryRandom.RandDec(99, 2), false);  // Divide by Zero boolean - False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B7425_AmtLargerThanUpperBound()
    begin
        // Item Unit Cost test Boundary value : Decimal value greater than 100.
        Initialize();
        ItemJournalAmount(100 + LibraryRandom.RandDec(10, 2), false);  // Divide by Zero boolean - False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B7425_AmtLessThanLowerBound()
    begin
        // Item Unit Cost test Boundary value : Decimal value less than -10.
        Initialize();
        ItemJournalAmount(-LibraryRandom.RandDec(10, 2), false);  // Divide by Zero boolean - False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B7425_AmtErrorDivisionByZero()
    begin
        // Item Unit Cost test Boundary value : -100 required for test.
        Initialize();
        ItemJournalAmount(-100, true);  // Divide by Zero boolean True to generate error.
    end;

    local procedure ItemJournalAmount(UnitCost: Decimal; DivideByZero: Boolean)
    var
        Item: Record Item;
    begin
        // Setup.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Indirect Cost %", UnitCost);
        Item.Modify(true);

        // Exercise and Verify.
        if not DivideByZero then
            VerifyUnitCostItemJournal(Item)
        else begin
            asserterror VerifyUnitCostItemJournal(Item);
            Assert.IsFalse(
              StrPos(GetLastErrorText, DivideByZeroErr) = 0, StrSubstNo(ErrorDoNotMatchErr, DivideByZeroErr, GetLastErrorText));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B29325_StockKeepingUnitError()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        VendorNo: Code[20];
    begin
        // Setup.
        Initialize();

        LibraryWarehouse.CreateLocation(Location);
        VendorNo := LibraryUtility.GenerateGUID();
        CreateItem(Item, Location.Code, Item."Costing Method"::FIFO);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);
        StockkeepingUnit.Get(Location.Code, Item."No.", '');

        // Exercise: Create Stock Keeping Unit to generate error.
        asserterror StockkeepingUnit.Validate("Vendor No.", VendorNo);

        Assert.AssertPrimRecordNotFound();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure B29388_UpdateAverageCostPeriod()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        AverageCostPeriod: Enum "Average Cost Period Type";
    begin
        // Update Average Cost Period in Inventory Setup and verify message in confirm handler.
        // Setup.
        Initialize();

        LibraryInventory.CreateItem(Item);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(10, 2), 0);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Exercise and Verify: Update Average Cost Period in Inventory Setup and verify message in confirm handler.
        LibraryVariableStorage.Enqueue(ConfirmQst);  // Enqueue Value for ConfirmHandler.
        LibraryVariableStorage.Enqueue(AdjustCostMsg);  // Enqueue Value for MessageHandler.

        InventorySetup.Get();
        AverageCostPeriod := InventorySetup."Average Cost Period";
        InventorySetup.Validate("Average Cost Period", InventorySetup."Average Cost Period"::"Accounting Period");
        InventorySetup.Modify(true);

        // Teardown.
        LibraryVariableStorage.Enqueue(ConfirmQst);  // Enqueue Value for ConfirmHandler.
        LibraryVariableStorage.Enqueue(AdjustCost2Msg);  // Enqueue Value for MessageHandler.
        UpdateInventorySetup(AverageCostPeriod);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B43701_InvoiceDimInReval()
    var
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Dimension] [Revaluation]
        // [SCENARIO] Verify that Dimensions entered in invoice are same in Revaluation Journal.

        // Setup.
        Initialize();
        PurchaseDocumentWithDimSetup(Item, DimensionValue, DimensionValue2);

        // Calculate inventory on Revaluation journal- calculate per ILE.
        Item.SetRange("No.", Item."No.");
        CreateRevaluationJournal(ItemJournalLine);
        LibraryCosting.CalculateInventoryValue(ItemJournalLine, Item, WorkDate(), LibraryUtility.GenerateGUID(), "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Per"::Item, false);

        // Verify: verify that the dimensions entered above are there.
        VerifyDimensions(
          ItemJournalLine, DimensionValue."Dimension Code", DimensionValue2."Dimension Code", DimensionValue.Code, DimensionValue2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B43701_InvoiceAndItemDimReval()
    var
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DimensionValue3: Record "Dimension Value";
        DimensionValue4: Record "Dimension Value";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Dimension] [Revaluation]
        // [SCENARIO] Verify that Dimensions entered in the item card and dimension values are still same as invoice in the Revaluation Journal.

        // Setup.
        Initialize();

        PurchaseDocumentWithDimSetup(Item, DimensionValue, DimensionValue2);
        UpdateItemWithDimensions(Item, DimensionValue3, DimensionValue4, DimensionValue."Dimension Code", DimensionValue2."Dimension Code");

        // Calculate inventory on Revaluation journal- calculate per ILE.
        Item.SetRange("No.", Item."No.");
        CreateRevaluationJournal(ItemJournalLine);

        // Exercise.
        LibraryCosting.CalculateInventoryValue(ItemJournalLine, Item, WorkDate(), LibraryUtility.GenerateGUID(), "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", false);

        // Verify: verify dimension values are still the ones chosen on the Purchase Invoice line.
        VerifyDimensions(
          ItemJournalLine, DimensionValue."Dimension Code", DimensionValue2."Dimension Code", DimensionValue.Code, DimensionValue2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B43701_ItemDimInReval()
    var
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DimensionValue3: Record "Dimension Value";
        DimensionValue4: Record "Dimension Value";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Dimension] [Revaluation]
        // [SCENARIO] Verify that Dimensions entered in the item card are same in the Revaluation Journal.

        // Setup.
        Initialize();
        PurchaseDocumentWithDimSetup(Item, DimensionValue, DimensionValue2);
        UpdateItemWithDimensions(Item, DimensionValue3, DimensionValue4, DimensionValue."Dimension Code", DimensionValue2."Dimension Code");

        // Calculate inventory on Revaluation journal- calculate per ILE.
        Item.SetRange("No.", Item."No.");
        CreateRevaluationJournal(ItemJournalLine);

        // Exercise.
        LibraryCosting.CalculateInventoryValue(ItemJournalLine, Item, WorkDate(), LibraryUtility.GenerateGUID(), "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false);

        // Verify: verify dimension values are the ones chosen on the item.
        VerifyDimensions(
          ItemJournalLine, DimensionValue."Dimension Code", DimensionValue2."Dimension Code", DimensionValue3.Code, DimensionValue4.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnTransferShipment()
    begin
        // Verify Dimension on Transfer Shipment.
        // Setup.
        Initialize();
        TransferOrderWithDimension(false);  // Update Dimension as False.
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesPageHandler,ConfirmHandlerOnChangeDimension')]
    [Scope('OnPrem')]
    procedure DimensionOnTransferReceiptWithNewDimension()
    begin
        // Verify Dimension on Transfer Receipt after Updating Dimension on Transfer Order.
        // Setup.
        Initialize();
        TransferOrderWithDimension(true);  // Update Dimension as True.
    end;

    local procedure TransferOrderWithDimension(UpdateDimension: Boolean)
    var
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // Create Item with Dimension, Update Inventory and Create Transfer Order.
        CreateItemWithDimension(Item, DimensionValue);
        CreateAndPostItemJournalLine(Item."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2) + 10);  // Using Large Random Value.
        CreateTransferRoute(LocationRed.Code, LocationBlue.Code, LocationInTransit.Code);
        CreateAndReleaseTransferOrder(
          TransferHeader, TransferLine, Item."No.", LocationRed.Code, LocationBlue.Code, LocationInTransit.Code,
          LibraryRandom.RandDec(10, 2));

        // Exercise: Post Transfer Shipment. Update Dimension on Transfer Order and Post Transfer Receipt.
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);  // Post with Ship Option.
        if UpdateDimension then begin
            UpdateDimensionOnTransferOrder(DimensionValue2, TransferHeader."No.");
            TransferHeader.Get(TransferHeader."No.");
            LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);  // Post with Receive Option.
        end;

        // Verify: Verify Dimension on Transfer Shipment and Transfer Receipt.
        if UpdateDimension then
            VerifyDimensionOnTransferReceipt(TransferHeader."No.", DimensionValue, DimensionValue2, Item."No.")
        else
            VerifyDimensionOnTransferShipmentLine(TransferHeader."No.", Item."No.", DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemWithZeroRoundingPrecisionError()
    begin
        // Verify Error message when update Zero Rounding Precision on Item.
        // Setup.
        Initialize();
        ItemWithRoundingPrecision(0);  // Zero Rounding Precision.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemWithNegativeRoundingPrecisionError()
    begin
        // Verify Error message when update Negative Rounding Precision on Item.
        // Setup.
        Initialize();
        ItemWithRoundingPrecision(-LibraryRandom.RandDec(10, 2));  // Negative Rounding Precision.
    end;

    local procedure ItemWithRoundingPrecision(RoundingPrecision: Decimal)
    var
        Item: Record Item;
    begin
        // Create Item.
        CreateItem(Item, '', Item."Costing Method"::FIFO);

        // Exercise: Validate Rounding Precision on Item.
        asserterror Item.Validate("Rounding Precision", RoundingPrecision);

        // Verify: Verify Error message for Rounding Precision.
        Assert.ExpectedError(RoundingPrecisionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemWithRoundingPrecisionMoreThanFiveDecimalPlaceValueError()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // Verify Error message when update Rounding Precision with more than five decimal place value on Item.
        // Setup: Create Item and Open Item Card.
        Initialize();
        CreateItem(Item, '', Item."Costing Method"::FIFO);
        OpenItemCard(ItemCard, Item."No.");

        // Exercise: Update Rounding Precision with more than five decimal place value on Item Card. Use page because Rounding Precision Field Property Decimal Places defined as 0:5.
        asserterror ItemCard."Rounding Precision".SetValue(Format(0.000001));    // Six decimal place value required.

        // Verify: Verify error message for Rounding Precision.
        Assert.ExpectedError(DecimalPlacesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemWithRoundingPrecisionEqualAndLessThanFiveDecimalPlaceValue()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        RoundingPrecision: Decimal;
    begin
        // Verify Rounding Precision on Item when update Rounding Precision with five decimal place value on Item.
        // Setup: Create Item and Open Item Card.
        Initialize();
        RoundingPrecision := LibraryRandom.RandDec(10, LibraryRandom.RandInt(5));  // Using Random for range of one to five decimal place.
        CreateItem(Item, '', Item."Costing Method"::FIFO);
        OpenItemCard(ItemCard, Item."No.");

        // Exercise: Update Rounding Precision with range of one to Five decimal place value on Item Card.
        ItemCard."Rounding Precision".SetValue(Format(RoundingPrecision));  // Use page because Rounding Precision Field Property Decimal Places defined as 0:5.
        ItemCard.OK().Invoke();

        // Verify: Verify Updated Rounding Precision on Item.
        Item.Get(Item."No.");
        Item.TestField("Rounding Precision", RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateShipmentDateOnReservedTransferOrder()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
    begin
        // Setup: Create an Item. Create and post Item Journal Line, Create Transfer Order with reservation.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", LocationBlue.Code, LibraryRandom.RandInt(100) + 100); // Random Number Generator Add 100 is for reservation.
        CreateTransferOrderWithReservation(TransferLine, LibraryRandom.RandInt(100), Item."No.");

        // Exercise: Change the Shipment Date on Transfer Header.
        ModifyShipmentDateOnTransferHeader(TransferLine."Document No.");

        // Verify: Verify the Confirm Message doesn't pop up and the Reserved Quantity Outbnd. has no change on Transfer Line.
        TransferLine.CalcFields("Reserved Quantity Outbnd.");
        Assert.AreEqual(TransferLine.Quantity, TransferLine."Reserved Quantity Outbnd.", ReservedQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangingItemRefNoDoesNotChangeItemVendorLeadTimeDiffUnitsOfMeasure()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        UnitOfMeasure: Record "Unit of Measure";
        Vendor: Record Vendor;
        ItemVendor: Record "Item Vendor";
        LeadTimeFormula: DateFormula;
        VendorItemNo: Text[20];
    begin
        // [FEATURE] [Item Reference]
        // [SCENARIO 361680] Lead time calculation in Vendor Item is not changed after changing "Ref. No." in linked item reference when two item ref. with diff. units of measure
        Initialize();

        // [GIVEN] Item with two units of measure
        CreateItemWithTwoUnitsOfMeasure(Item, UnitOfMeasure);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Item cross reference with unit of measure = "U1" and Item Reference No. = "N1"
        CreateItemReference(ItemReference, Item."No.", Item."Base Unit of Measure", Vendor."No.", '');

        // [GIVEN] Item cross reference with unit of measure = "U2" and Item Reference No. = "N2"
        VendorItemNo := ItemReference."Reference No.";
        CreateItemReference(ItemReference, Item."No.", UnitOfMeasure.Code, Vendor."No.", '');

        // [GIVEN] Set Lead Time Calculation in Item Vendor = "1D"
        Evaluate(LeadTimeFormula, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        UpdateItemVendorLeadTime(Vendor."No.", Item."No.", LeadTimeFormula);

        // [WHEN] In Item Cross Reference change Cross Reference No. from "N2" to "N1"
        ItemReference.Rename(ItemReference."Item No.", '', ItemReference."Unit of Measure", ItemReference."Reference Type", ItemReference."Reference Type No.", VendorItemNo);

        ItemVendor.Get(Vendor."No.", Item."No.", '');
        // [THEN] Item Vendor is updated: "Vendor Item No." = "N1", "Lead Time Calculation" = "1D"
        Assert.AreEqual(
          VendorItemNo, ItemVendor."Vendor Item No.",
          StrSubstNo(WrongFieldValueErr, ItemVendor.FieldCaption("Vendor Item No."), ItemVendor.TableCaption()));
        Assert.IsTrue(
          LeadTimeFormula = ItemVendor."Lead Time Calculation",
          StrSubstNo(WrongFieldValueErr, ItemVendor.FieldCaption("Lead Time Calculation"), ItemVendor.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoItemReferencesWithDiffVendorsCreateTwoItemVendors()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        UnitOfMeasure: Record "Unit of Measure";
        Vendor: array[2] of Record Vendor;
        ItemVendor: Record "Item Vendor";
    begin
        // [FEATURE] [Item Reference]
        // [SCENARIO 361680] One linked Item Vendor created for each of two Item References
        Initialize();

        // [GIVEN] Item reference related to Vendor "V1"
        CreateItemWithTwoUnitsOfMeasure(Item, UnitOfMeasure);
        LibraryPurchase.CreateVendor(Vendor[1]);
        CreateItemReference(ItemReference, Item."No.", Item."Base Unit of Measure", Vendor[1]."No.", '');

        LibraryPurchase.CreateVendor(Vendor[2]);

        // [WHEN] The second item reference for the same item created with a link to Vendor "V2"
        CreateItemReference(ItemReference, Item."No.", Item."Base Unit of Measure", Vendor[2]."No.", '');

        // [THEN] Two Item Vendor records exist - one for each Vendor
        Assert.IsTrue(ItemVendor.Get(Vendor[1]."No.", Item."No.", ''), ItemVendorMustExistErr);
        Assert.IsTrue(ItemVendor.Get(Vendor[2]."No.", Item."No.", ''), ItemVendorMustExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangingVendorInItemReferenceDeletesRelatedItemVendor()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        UnitOfMeasure: Record "Unit of Measure";
        Vendor: array[2] of Record Vendor;
        ItemVendor: Record "Item Vendor";
    begin
        // [FEATURE] [Item Reference]
        // [SCENARIO 361680] Item Vendor deleted after the linked reference renamed so that two item references refer to the same vendor after renaming
        Initialize();

        // [GIVEN] Item with two references on different vendors "V1" and "V2"
        CreateItemWithTwoUnitsOfMeasure(Item, UnitOfMeasure);
        LibraryPurchase.CreateVendor(Vendor[1]);
        CreateItemReference(ItemReference, Item."No.", Item."Base Unit of Measure", Vendor[1]."No.", '');

        LibraryPurchase.CreateVendor(Vendor[2]);
        CreateItemReference(ItemReference, Item."No.", Item."Base Unit of Measure", Vendor[2]."No.", '');

        // [WHEN] Vendor "V2" in cross-reference is changed "V1"
        ItemReference.Rename(ItemReference."Item No.", '', ItemReference."Unit of Measure", ItemReference."Reference Type", Vendor[1]."No.", ItemReference."Reference No.");

        // [THEN] Item Vendor for Vendor "V1" exists, Item Vendor for Vendor "V2" does not exist
        Assert.IsTrue(ItemVendor.Get(Vendor[1]."No.", Item."No.", ''), ItemVendorMustExistErr);
        Assert.IsFalse(ItemVendor.Get(Vendor[2]."No.", Item."No.", ''), ItemVendorMustNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangingUnitOfMeasureInItemRefDoesNotChangeItemVendorLeadTime()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        UnitOfMeasure: Record "Unit of Measure";
        ItemReference: Record "Item Reference";
        ItemVendor: Record "Item Vendor";
        LeadTimeFormula: DateFormula;
    begin
        // [FEATURE] [Item Reference]
        // [SCENARIO 361680] Lead time calculation in Vendor Item is not changed after changing "Unit of Measure" in linked item eference when two item ref.
        Initialize();

        // [GIVEN] Item with two units of measure "U1" and "U2"
        // [GIVEN] Item reference with unit of measure = "U1" and Reference No. = "N"
        CreateItemWithTwoUnitsOfMeasure(Item, UnitOfMeasure);
        LibraryPurchase.CreateVendor(Vendor);
        CreateItemReference(ItemReference, Item."No.", Item."Base Unit of Measure", Vendor."No.", '');

        // [GIVEN] Set Lead Time Calculation in Item Vendor = '1D'
        Evaluate(LeadTimeFormula, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        UpdateItemVendorLeadTime(Vendor."No.", Item."No.", LeadTimeFormula);

        // [WHEN] Set "Unit of Measure" = "U2" in item cross-reference
        ItemReference.Rename(ItemReference."Item No.", '', UnitOfMeasure.Code, ItemReference."Reference Type", ItemReference."Reference Type No.", ItemReference."Reference No.");

        ItemVendor.Get(Vendor."No.", Item."No.", '');
        // [THEN] Vendor Item No. in Item Vendor = "N", Lead Time Calculation = "1D"
        Assert.AreEqual(
          ItemReference."Reference No.", ItemVendor."Vendor Item No.",
          StrSubstNo(WrongFieldValueErr, ItemVendor.FieldCaption("Vendor Item No."), ItemVendor.TableCaption()));
        Assert.IsTrue(
          LeadTimeFormula = ItemVendor."Lead Time Calculation",
          StrSubstNo(WrongFieldValueErr, ItemVendor.FieldCaption("Lead Time Calculation"), ItemVendor.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoCopiedFromItemReference()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Reference] [Vendor Item No.]
        // [SCENARIO 377506] "Vendor Item No." in purchase line should be copied from item reference if there is a item reference with matching vendor and unit of measure
        Initialize();

        // [GIVEN] Create item "I" with base unit of measure "U"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Create vendor "V"
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Create item reference for item "I", vendor "V" and unit of measure "U", set vendor item no. = "N"
        CreateItemReference(ItemReference, Item."No.", Item."Base Unit of Measure", Vendor."No.", '');

        // [WHEN] Create purchase order for vendor "V", item "I", unit of measure "U"
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", '', '');

        // [THEN] "Vendor Item No." in purchase line is "N"
        PurchaseLine.TestField("Vendor Item No.", ItemReference."Reference No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoCopiedFromItemReferenceMismatchingUoM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        ItemReference: Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Reference] [Item Unit of Measure] [Vendor Item No.]
        // [SCENARIO 377506] "Vendor Item No." in purch. line should be copied from item reference if there is no item reference with matching UoM and no other item vendors
        Initialize();

        // [GIVEN] Create item "I" with base unit of measure "U1"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor Item No.", LibraryUtility.GenerateGUID());
        Item.Modify(true);

        // [GIVEN] Create unit of measure "U2" for item "I"
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);

        // [GIVEN] Create vendor "V"
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Create item cross reference for item "I", vendor "V" and unit of measure "U2", set vendor item no. = "N"
        CreateItemReference(ItemReference, Item."No.", ItemUnitOfMeasure.Code, Vendor."No.", '');

        // [WHEN] Create purchase order for vendor "V", item "I" and unit of measure "U1"
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", '', '');

        // [THEN] "Vendor Item No." in purchase line is "N"
        PurchaseLine.TestField("Vendor Item No.", ItemReference."Reference No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoPriorityItemReferenceItemVendor()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemReference: Record "Item Reference";
        ItemVendor: Record "Item Vendor";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Reference] [Item Vendor] [Vendor Item No.]
        // [SCENARIO 377506] "Vendor Item No." in purch. line should be copied from item reference if there is a item reference with matching UoM and another item vendor for the same item
        Initialize();

        // [GIVEN] Create item "I" with base unit of measure "U"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Create vendor "V"
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Create item vendor for item "I", vendor "V", set vendor item no. = "N1"
        MockItemVendor(ItemVendor, Vendor."No.", Item."No.", '');
        // [GIVEN] Create item reference for item "I", vendor "V", unit of measure "U", set vendor item no. = "N2"
        CreateItemReference(ItemReference, Item."No.", Item."Base Unit of Measure", Vendor."No.", '');

        // [WHEN] Create purchase order for vendor "V", item "I", unit of measure "U"
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", '', '');

        // [THEN] "Vendor Item No." in purchase line is "N2"
        PurchaseLine.TestField("Vendor Item No.", ItemReference."Reference No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoMismatchingItemReferenceVendorItem()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        ItemReference: Record "Item Reference";
        ItemVendor: Record "Item Vendor";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Reference] [Item Vendor] [Vendor Item No.]
        // [SCENARIO 377506] "Vendor Item No." in purch. line should be copied from item item vendor catalog if there is a item reference with mismatching UoM and another item vendor for the same item
        Initialize();

        // [GIVEN] Create item "I" with base unit of measure "U1"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Create unit of measure "U2" for item "I"
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);

        // [GIVEN] Create vendor "V"
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Create item vendor for item "I", vendor "V", set vendor item no. = "N1"
        MockItemVendor(ItemVendor, Vendor."No.", Item."No.", '');
        // [GIVEN] Create item reference - vendor = "V", item = "I", unit of measure = "U2", set vendor item no. = "N2"
        CreateItemReference(ItemReference, Item."No.", ItemUnitOfMeasure.Code, Vendor."No.", '');

        // [WHEN] Create purchase order for vendor "V", item "I", unit of measure "U1"
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", '', '');

        // [THEN] "Vendor Item No." in purchase line is "N1"
        PurchaseLine.TestField("Vendor Item No.", ItemVendor."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoPriorityItemVendorSKU()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemVendor: Record "Item Vendor";
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Vendor] [Stockkeeping Unit] [Vendor Item No.]
        // [SCENARIO 377506] "Vendor Item No." in purch. line should be copied from item item vendor catalog if there is an item vendor and SKU for the same item
        Initialize();

        // [GIVEN] Create item "I"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Create vendor "V"
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Create item vendor for item "I" and vendor "V", set vendor item no. = "N1"
        MockItemVendor(ItemVendor, Vendor."No.", Item."No.", '');

        // [GIVEN] Create location "L" and stockkeeping unit for item "I", location "L". Set vendor item no. = "N2" in SKU
        LibraryWarehouse.CreateLocation(Location);
        CreateStockkeepingUnit(SKU, Item."No.", '', Location.Code);

        // [WHEN] Create purchase order: vendor = "V", item = "I", location = "L"
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", Location.Code, '');

        // [THEN] Vendor item no. in purchase line = "N1"
        PurchaseLine.TestField("Vendor Item No.", ItemVendor."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoItemVendorSKUDifferentVariants()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemVariant: array[2] of Record "Item Variant";
        ItemVendor: Record "Item Vendor";
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Vendor] [Stockkeeping Unit] [Vendor Item No.]
        // [SCENARIO 377506] "Vendor Item No." in purch. line should be copied from SKU if variant code in item vendor does not match the purch. line
        Initialize();

        // [GIVEN] Create item "I"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Create 2 item variants: "V1" and "V2"
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item."No.");
        // [GIVEN] Create vendor "V"
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Create item vendor: item = "I", vendor = "V", variant = "V1", set vendor item no. = "N1"
        MockItemVendor(ItemVendor, Vendor."No.", Item."No.", ItemVariant[1].Code);

        // [GIVEN] Create location "L"
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Create stockkeeping unit: item = "I", location = "L", variant = "V2", set vendor item no. = "N2"
        CreateStockkeepingUnit(SKU, Item."No.", ItemVariant[2].Code, Location.Code);

        // [WHEN] Create purchase order: vendor = "V", item = "I", location = "L", variant = "V2"
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", Location.Code, ItemVariant[2].Code);

        // [THEN] Vendor item no. in purchase line = "N2"
        PurchaseLine.TestField("Vendor Item No.", SKU."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoCopiedFromSKU()
    var
        Item: Record Item;
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Stockkeeping Unit] [Location] [Vendor Item No.]
        // [SCENARIO 377506] Vendor item no. in purchase line should be copied from a stockkeeping unit if there is a SKU matching the purchase line
        Initialize();

        // [GIVEN] Create item "I"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Create location "L"
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Create stockkeeping unit with item = "I", location = "L", set vendor item no. = "N"
        CreateStockkeepingUnit(SKU, Item."No.", '', Location.Code);

        // [WHEN] Create purchase order for item "I", location "L"
        CreatePurchaseOrder(PurchaseLine, '', Item."No.", Location.Code, '');

        // [THEN] Vendor item no. in purchase line = "N"
        PurchaseLine.TestField("Vendor Item No.", SKU."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoUpdatedFromItemRefWhenChangingUoM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        ItemReference: array[2] of Record "Item Reference";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Reference] [Item Unit of Measure] [Vendor Item No.]
        // [SCENARIO 377506] Vendor item no. in purchase line should be updated when changing the unit of measure and there are item references matching both UoMs
        Initialize();

        // [GIVEN] Create item "I" with base unit of measure "U1"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Create unit of measure "U2" for item "I"
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);

        // [GIVEN] Create vendor "V"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create item reference: item = "I", vendor = "V", unit of measure = "U1", set vendor item no. = "N1"
        CreateItemReference(ItemReference[1], Item."No.", Item."Base Unit of Measure", Vendor."No.", '');
        // [GIVEN] Create item reference: item = "I", vendor = "V", unit of measure = "U2", set vendor item no. = "N2"
        CreateItemReference(ItemReference[2], Item."No.", ItemUnitOfMeasure.Code, Vendor."No.", '');

        // [GIVEN] Create purchase order: vendor = "V", item = "I", unit of measure = "U1"
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", '', '');

        // [WHEN] Change unit of measure in purcahse line: new UoM = "U2"
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);

        // [THEN] Vendor item no. in purchase line = "N2"
        PurchaseLine.TestField("Vendor Item No.", ItemReference[2]."Reference No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoNotUpdatedWhenChangingUoMMismatchingItemReference()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        ItemReference: Record "Item Reference";
        ItemVendor: Record "Item Vendor";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Reference] [Item Unit of Measure] [Vendor Item No.]
        // [SCENARIO 377506] Vendor item no. in purchase line should not be updated from item vendor when changing the unit of measure and there is a mismatching item reference and item vendor for the item
        Initialize();

        // [GIVEN] Create item "I" with base unit of measure "U1"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Create unit of measure "U2" for item "I"
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        // [GIVEN] Create vendor "V"
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Create item vendor: item = "I", vendor = "V", vendor item no. = "N1"
        MockItemVendor(ItemVendor, Vendor."No.", Item."No.", '');
        // [GIVEN] Create item reference: item = "I", vendor = "V", unit of measure = "U1", vendor item no. = "N2"
        CreateItemReference(ItemReference, Item."No.", Item."Base Unit of Measure", Vendor."No.", '');
        // [GIVEN] Create purchase order: vendor = "V", item = "I", unit of measure = "U1"
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", '', '');

        // [WHEN] Change unit of measure in purchase line. New unit of measure = "U2"
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);

        // [THEN] Vendor item no. in purchase line is updated. New item vendor no. = "N1"
        PurchaseLine.TestField("Vendor Item No.", ItemVendor."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoUpdatedFromItemWhenChangingUoMMismatchingItemReference()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        ItemReference: Record "Item Reference";
        ItemVendor: Record "Item Vendor";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Reference] [Item Unit of Measure] [Vendor Item No.]
        // [SCENARIO 377506] Vendor item no. in purchase line should be copied from item card when changing the unit of measure and there is a mismatching item reference
        Initialize();

        // [GIVEN] Create item "I" with base unit of measure "U1", Set vendor item no. = "N1"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor Item No.", LibraryUtility.GenerateGUID());
        Item.Modify(true);

        // [GIVEN] Create unit of measure "U2" for item "I"
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        // [GIVEN] Create vendor "V"
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Create cross reference: item = "I", vendor = "V", unit of measure = "U1", vendor item no. = "N2"
        CreateItemReference(ItemReference, Item."No.", Item."Base Unit of Measure", Vendor."No.", '');
        // [GIVEN] Delete all item vendors
        ItemVendor.SetRange("Item No.", Item."No.");
        ItemVendor.DeleteAll();

        // [GIVEN] Create purchase order: vendor = "V", item = "I", unit of measure = "U1"
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", Item."No.", '', '');

        // [WHEN] Change unit of measure in purchase line. New unit of measure = "U2"
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);

        // [THEN] Vendor item no. in purchase line is updated. New vendor item no. = "N1"
        PurchaseLine.TestField("Vendor Item No.", Item."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoUpdatedFromSKUWhenChangingVariant()
    var
        Item: Record Item;
        Location: Record Location;
        ItemVariant: array[2] of Record "Item Variant";
        SKU: array[2] of Record "Stockkeeping Unit";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Stockkeeping Unit] [Item Variant] [Location] [Vendor Item No.]
        // [SCENARIO 377506] Vendor item no. in purchase line should be updated when changing the variant code and there are matching stockkeeping units
        Initialize();

        // [GIVEN] Create item "I"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Create location "L"
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Create 2 item variants: "V1" and "V2"
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item."No.");
        // [GIVEN] Create stockkeeping unit: item "I", location "L", variant "V1", set vendor item no. = "N1"
        CreateStockkeepingUnit(SKU[1], Item."No.", ItemVariant[1].Code, Location.Code);
        // [GIVEN] Create stockkeeping unit: item "I", location "L", variant "V2", set vendor item no. = "N2"
        CreateStockkeepingUnit(SKU[2], Item."No.", ItemVariant[2].Code, Location.Code);

        // [GIVEN] Create purchase order: item = "I", location = "L", variant = "V1"
        CreatePurchaseOrder(PurchaseLine, '', Item."No.", Location.Code, ItemVariant[1].Code);
        PurchaseLine.TestField("Vendor Item No.", SKU[1]."Vendor Item No.");

        // [WHEN] Change variant code in the purchase lin: new variant code = "V2"
        PurchaseLine.Validate("Variant Code", ItemVariant[2].Code);

        // [THEN] Vendor item no. in purchase line = "N2"
        PurchaseLine.TestField("Vendor Item No.", SKU[2]."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorItemNoCopiedFromItemCardWhenChangingVariantMismatchingSKU()
    var
        Item: Record Item;
        Location: Record Location;
        ItemVariant: array[2] of Record "Item Variant";
        PurchaseLine: Record "Purchase Line";
        SKU: Record "Stockkeeping Unit";
    begin
        // [FEATURE] [Stockkeeping Unit] [Item Variant] [Location] [Vendor Item No.]
        // [SCENARIO 377506] Vendor item no. in purchase line should be copied from item card when changing the variant code and new variant code does not match the SKU
        Initialize();

        // [GIVEN] Create item "I", set vendor item no. = "N1"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor Item No.", LibraryUtility.GenerateGUID());
        Item.Modify(true);

        // [GIVEN] Create location "L"
        LibraryWarehouse.CreateLocation(Location);
        // [GIVEN] Create 2 item variants "V1" and "V2"
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item."No.");
        // [GIVEN] Create stockkeeping unit: item = "I", location = "L", variant = "V1", set vendor item no. = "N2"
        CreateStockkeepingUnit(SKU, Item."No.", ItemVariant[1].Code, Location.Code);

        // [GIVEN] Create purchase order: item = "I", location = "L", variant = "V1"
        CreatePurchaseOrder(PurchaseLine, '', Item."No.", Location.Code, ItemVariant[1].Code);
        PurchaseLine.TestField("Vendor Item No.", SKU."Vendor Item No.");

        // [WHEN] Change variant code in purchase line: new variant code = "V2"
        PurchaseLine.Validate("Variant Code", ItemVariant[2].Code);

        // [THEN] Vendor item no. in purchase line = "N1"
        PurchaseLine.TestField("Vendor Item No.", Item."Vendor Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemDescriptionReqLine()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemVendor: Record "Item Vendor";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Description]
        // [SCENARIO 378078] Item Description in Requisition Line mustn't be modified after Vendor No. validate
        Initialize();

        // [GIVEN] Item with a Description
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Item Vendor and Cross Reference simultaneously
        CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");

        // [GIVEN] Init Requisition Line and validate No. field, Description field is filled from Item.Description
        RequisitionLine.Init();
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");

        // [WHEN] Validate "Vendor No." in Requisition Line
        RequisitionLine.Validate("Vendor No.", Vendor."No.");

        // [THEN] Description is not changed
        Assert.AreEqual(Item.Description, RequisitionLine.Description, DescriptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemDescriptionReqLineTranslation()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemVendor: Record "Item Vendor";
        RequisitionLine: Record "Requisition Line";
        ItemTranslationDescription: Text[100];
    begin
        // [FEATURE] [Description] [Item Translation]
        // [SCENARIO 378078] Item Description in Requisition Line must be validated from Item Translation when it exists

        Initialize();

        // [GIVEN] Create with a Description
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Item Translation
        ItemTranslationDescription := CreateVendorWithItemTranslationDescription(Vendor, Item."No.");

        // [GIVEN] Create Item Vendor
        CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");

        // [GIVEN] Init Requisition Line and validate No. field, Description field is filled from Item.Description
        RequisitionLine.Init();
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");

        // [WHEN] Validate "Vendor No." in Requisition Line
        RequisitionLine.Validate("Vendor No.", Vendor."No.");

        // [THEN] Description is validated from Item Description
        Assert.AreEqual(ItemTranslationDescription, RequisitionLine.Description, DescriptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFailedInsertUnitOfMeasureWithBlankCode()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [SCENARIO 462492]: Users are able to import blank records and this leads to setup issue "Unit of Measure Code must have a value in Warehouse Journal Line
        Initialize();

        // [GIVEN] Create item "I" with base unit of measure "U1"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create unit of measure with blank Code for item "I"
        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure.Validate("Item No.", Item."No.");

        // [WHEN] Insert record
        asserterror ItemUnitOfMeasure.Insert(true);

        // [THEN] The TestField Error was shown
        Assert.ExpectedErrorCode(TestFieldCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningAndWarehouseTabsNotVisibleForNonInvAndServiceItemsInSKUCard()
    var
        Item: Record Item;
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        StocKkeepingCard: TestPage "Stockkeeping Unit Card";
    begin
        // [SCENARIO 497598] Planning and Warehouse tabs are not visible in SKU card for items of Type = Non-Inventory or Service.
        Initialize();

        // [GIVEN] Create an Item and Validate Type as Non-Inventory.
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Stockkeeping Unit.
        CreateStockkeepingUnit(StockkeepingUnit, Item."No.", '', Location.Code);

        // [WHEN] Open Stockkeeping Unit Card page.
        StocKkeepingCard.OpenEdit();
        StocKkeepingCard.GoToRecord(StockkeepingUnit);

        // [VERIFY] Planning tab is not visible.
        Assert.IsFalse(
            StocKkeepingCard."Reordering Policy".Visible(),
            ReorderingPolicyShouldNotBeVisibleErr);

        // [VERIFY] Warehouse tab is not visible.
        Assert.IsFalse(
            StocKkeepingCard."Special Equipment Code".Visible(),
            SpecialEquipmentCodeShouldNotBeVisibleErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Inventory 7.0");
        LibraryVariableStorage.Clear();
        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Inventory 7.0");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        NoSeriesSetup();
        CreateLocationSetup();
        ItemJournalSetup();
        RevaluationJournalSetup();
        Commit();

        Initialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Inventory 7.0");
    end;

    local procedure ItemJournalSetup()
    begin
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure CreateLocationSetup()
    begin
        // Location - Blue.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // Location - Red.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationRed);

        // Location In - Transit.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationInTransit);
        LocationInTransit.Validate("Use As In-Transit", true);
        LocationInTransit.Modify(true);
    end;

    local procedure RevaluationJournalSetup()
    begin
        RevaluationItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(RevaluationItemJournalTemplate, RevaluationItemJournalTemplate.Type::Revaluation);

        RevaluationItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(RevaluationItemJournalBatch, RevaluationItemJournalTemplate.Type,
          RevaluationItemJournalTemplate.Name);
    end;

    local procedure UpdateInventorySetup(AverageCostPeriod: Enum "Average Cost Period Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Average Cost Period", AverageCostPeriod);
        InventorySetup.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; LocationFilter: Code[10]; ItemCostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", ItemCostingMethod);
        Item.Validate("Location Filter", LocationFilter);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateDimensionWithValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateVendorWithItemTranslationDescription(var Vendor: Record Vendor; ItemNo: Code[20]): Text[100]
    var
        Language: Record Language;
    begin
        Language.FindFirst();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Language Code", Language.Code);
        Vendor.Modify(true);
        exit(CreateItemTranslation(ItemNo, Vendor."Language Code"));
    end;

    local procedure CreateItemReference(var ItemReference: Record "Item Reference"; ItemNo: Code[20]; UoMCode: Code[10]; VendorNo: Code[20]; VariantCode: Code[10])
    begin
        ItemReference.Init();
        ItemReference.Validate("Item No.", ItemNo);
        ItemReference.Validate("Variant Code", VariantCode);
        ItemReference.Validate("Unit of Measure", UoMCode);
        ItemReference.Validate("Reference Type", ItemReference."Reference Type"::Vendor);
        ItemReference.Validate("Reference Type No.", VendorNo);
        ItemReference.Validate("Reference No.", LibraryUtility.GenerateGUID());
        ItemReference.Insert(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Validate("Posting Date", WorkDate());
        ItemJournalLine.Modify(true);
    end;

    local procedure MockItemVendor(var ItemVendor: Record "Item Vendor"; VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        ItemVendor.Init();
        ItemVendor."Vendor No." := VendorNo;
        ItemVendor."Item No." := ItemNo;
        ItemVendor."Variant Code" := VariantCode;
        Evaluate(ItemVendor."Lead Time Calculation", StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));
        ItemVendor."Vendor Item No." := LibraryUtility.GenerateGUID();
        ItemVendor.Insert();
    end;

    local procedure CreateItemVendor(var ItemVendor: Record "Item Vendor"; VendorNo: Code[20]; ItemNo: Code[20])
    begin
        ItemVendor.Init();
        ItemVendor."Vendor No." := VendorNo;
        ItemVendor."Item No." := ItemNo;
        ItemVendor.Insert(true);
    end;

    local procedure CreateItemTranslation(ItemNo: Code[20]; LanguageCode: Code[10]): Text[100]
    var
        ItemTranslation: Record "Item Translation";
    begin
        ItemTranslation.Init();
        ItemTranslation.Validate("Item No.", ItemNo);
        ItemTranslation.Validate("Language Code", LanguageCode);
        ItemTranslation.Validate(Description, ItemNo + LanguageCode);
        ItemTranslation.Insert(true);
        exit(ItemTranslation.Description);
    end;

    local procedure CreateItemWithTwoUnitsOfMeasure(var Item: Record Item; var UnitOfMeasure: Record "Unit of Measure")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateRevaluationJournal(var ItemJournalLine: Record "Item Journal Line")
    begin
        LibraryInventory.ClearItemJournal(RevaluationItemJournalTemplate, RevaluationItemJournalBatch);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, RevaluationItemJournalBatch, RevaluationItemJournalBatch."Journal Template Name",
          RevaluationItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.");
    end;

    local procedure CreateStockkeepingUnit(var SKU: Record "Stockkeeping Unit"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        SKU."Location Code" := LocationCode;
        SKU."Item No." := ItemNo;
        SKU."Variant Code" := VariantCode;
        SKU."Vendor Item No." := LibraryUtility.GenerateGUID();
        SKU.Insert();
    end;

    local procedure CreateTransferRoute(TransferFrom: Code[10]; TransferTo: Code[10]; InTransit: Code[10])
    var
        TransferRoute: Record "Transfer Route";
    begin
        if not TransferRoute.Get(TransferFrom, TransferTo) then begin  // Check Transfer Route exists.
            LibraryWarehouse.CreateTransferRoute(TransferRoute, TransferFrom, TransferTo);
            TransferRoute.Validate("In-Transit Code", InTransit);
            TransferRoute.Modify(true);
        end;
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; TransferFrom: Code[10]; TransferTo: Code[10]; InTransit: Code[10]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, TransferFrom, TransferTo, InTransit);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateTransferOrderWithReservation(var TransferLine: Record "Transfer Line"; Qty: Decimal; ItemNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
        FullReservation: Boolean;
    begin
        Clear(TransferHeader);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationBlue.Code, LocationRed.Code, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
        ReservationManagement.SetReservSource(TransferLine, "Transfer Direction"::Outbound);
        ReservationManagement.AutoReserve(FullReservation, '', TransferLine."Shipment Date", Qty, Qty);
    end;

    local procedure UpdateItemWithDimensions(var Item: Record Item; var DimensionValue: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value"; DimensionCode: Code[20]; DimensionCode2: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDimensionValue(DimensionValue2, DimensionCode2);

        // Item with dimensions.
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Item, Item."No.", DimensionCode, DimensionValue.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Item, Item."No.", DimensionCode2, DimensionValue2.Code);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity, 0);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure PurchaseDocumentWithDimSetup(var Item: Record Item; var DimensionValue: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineDimSetID: Integer;
        VendorNo: Code[20];
    begin
        VendorNo := SelectVendorWithDimension();
        CreateItem(Item, '', Item."Costing Method"::FIFO);

        // Create purchase invoice.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // Retrieve Dimension Set ID from the Purchase line.
        LineDimSetID := PurchaseLine."Dimension Set ID";

        // Create Dimension with different Dimension Value.
        CreateDimensionWithValue(DimensionValue);
        CreateDimensionWithValue(DimensionValue2);

        LineDimSetID := LibraryDimension.CreateDimSet(LineDimSetID, DimensionValue."Dimension Code", DimensionValue.Code);
        LineDimSetID := LibraryDimension.CreateDimSet(LineDimSetID, DimensionValue2."Dimension Code", DimensionValue2.Code);

        // Link to new dimension set ID in Purchase line.
        PurchaseLine.Validate("Dimension Set ID", LineDimSetID);
        PurchaseLine.Modify(true);

        // Post invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Run adjust cost item entries.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
    end;

    local procedure SelectVendorWithDimension() VendorNo: Code[20]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        if LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Vendor, VendorNo) then
            exit;
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Vendor, VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure UpdateDimensionOnTransferOrder(var DimensionValue: Record "Dimension Value"; No: Code[20])
    var
        TransferOrder: TestPage "Transfer Order";
    begin
        CreateDimensionWithValue(DimensionValue);
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");  // Enqueue Value for Page Handler - EditDimensionSetEntriesPageHandler.
        LibraryVariableStorage.Enqueue(DimensionValue.Code);  // Enqueue Value for Page Handler - EditDimensionSetEntriesPageHandler.

        // Use Page Testability to Update Dimension on Transfer Order. Dimension Set ID - OnLookup trigger code required.
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", No);
        TransferOrder.Dimensions.Invoke();
    end;

    local procedure FindTransferShipmentHeader(var TransferShipmentHeader: Record "Transfer Shipment Header"; TransferOrderNo: Code[20])
    begin
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferOrderNo);
        TransferShipmentHeader.FindFirst();
    end;

    local procedure CreateItemWithDimension(var Item: Record Item; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        CreateItem(Item, '', Item."Costing Method"::FIFO);
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Item, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure OpenItemCard(var ItemCard: TestPage "Item Card"; No: Code[20])
    begin
        ItemCard.OpenEdit();
        ItemCard.FILTER.SetFilter("No.", No);
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure UpdateItemVendorLeadTime(VendorNo: Code[20]; ItemNo: Code[20]; LeadTimeFormula: DateFormula)
    var
        ItemVendor: Record "Item Vendor";
    begin
        ItemVendor.Get(VendorNo, ItemNo, '');
        ItemVendor.Validate("Lead Time Calculation", LeadTimeFormula);
        ItemVendor.Modify(true);
    end;

    local procedure VerifyUnitCostItemJournal(Item: Record Item)
    var
        ItemJournalLine: Record "Item Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));

        // Verify.
        ItemJournalLine.TestField(
          "Unit Amount", Round(Item."Standard Cost" / (1 + Item."Indirect Cost %" / 100),
            GeneralLedgerSetup."Unit-Amount Rounding Precision"));
        ItemJournalLine.TestField("Unit Cost", Item."Standard Cost");
    end;

    local procedure VerifyDimensions(var ItemJournalLine: Record "Item Journal Line"; DimCode1: Code[20]; DimCode2: Code[20]; DimValue1: Code[20]; DimValue2: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        ItemJournalLine.SetRange("Journal Template Name", RevaluationItemJournalTemplate.Name);
        ItemJournalLine.FindLast();
        DimensionSetEntry.SetRange("Dimension Set ID", ItemJournalLine."Dimension Set ID");
        DimensionSetEntry.SetRange("Dimension Code", DimCode1);
        DimensionSetEntry.FindFirst();
        Assert.IsFalse(
          DimensionSetEntry."Dimension Value Code" <> DimValue1, StrSubstNo(DimErr, DimValue1, DimensionSetEntry."Dimension Value Code"));

        Clear(DimensionSetEntry);
        DimensionSetEntry.SetRange("Dimension Set ID", ItemJournalLine."Dimension Set ID");
        DimensionSetEntry.SetRange("Dimension Code", DimCode2);
        DimensionSetEntry.FindFirst();
        Assert.IsFalse(
          DimensionSetEntry."Dimension Value Code" <> DimValue2, StrSubstNo(DimErr, DimValue2, DimensionSetEntry."Dimension Value Code"));
    end;

    local procedure VerifyDimensionSetEntry(DimensionSetID: Integer; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.Get(DimensionSetID, DimensionCode);
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    local procedure VerifyDimensionOnTransferShipmentLine(TransferOrderNo: Code[20]; ItemNo: Code[20]; DimensionValue: Record "Dimension Value")
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        FindTransferShipmentHeader(TransferShipmentHeader, TransferOrderNo);
        TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
        TransferShipmentLine.SetRange("Item No.", ItemNo);
        TransferShipmentLine.FindFirst();
        VerifyDimensionSetEntry(TransferShipmentLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure VerifyDimensionOnTransferReceipt(TransferOrderNo: Code[20]; DimensionValue: Record "Dimension Value"; DimensionValue2: Record "Dimension Value"; ItemNo: Code[20])
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        VerifyDimensionOnTransferReceiptHeader(TransferReceiptHeader, TransferOrderNo, DimensionValue2);
        VerifyDimensionOnTransferReceiptLine(TransferReceiptHeader."No.", ItemNo, DimensionValue, DimensionValue2);
    end;

    local procedure VerifyDimensionOnTransferReceiptHeader(var TransferReceiptHeader: Record "Transfer Receipt Header"; TransferOrderNo: Code[20]; DimensionValue: Record "Dimension Value")
    begin
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferOrderNo);
        TransferReceiptHeader.FindFirst();
        VerifyDimensionSetEntry(TransferReceiptHeader."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure VerifyDimensionOnTransferReceiptLine(DocumentNo: Code[20]; ItemNo: Code[20]; DimensionValue: Record "Dimension Value"; DimensionValue2: Record "Dimension Value")
    var
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        TransferReceiptLine.SetRange("Document No.", DocumentNo);
        TransferReceiptLine.SetRange("Item No.", ItemNo);
        TransferReceiptLine.FindFirst();
        VerifyDimensionSetEntry(TransferReceiptLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
        VerifyDimensionSetEntry(TransferReceiptLine."Dimension Set ID", DimensionValue2."Dimension Code", DimensionValue2.Code);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(AreSameMessages(Question, ExpectedMessage), StrSubstNo(ErrorDoNotMatchErr, ExpectedMessage, Question));
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerOnChangeDimension(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(AreSameMessages(Message, ExpectedMessage), StrSubstNo(ErrorDoNotMatchErr, ExpectedMessage, Message));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    var
        DimensionCode: Variant;
        DimensionValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionCode);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(DimensionValue);  // Dequeue variable.

        EditDimensionSetEntries."Dimension Code".SetValue(DimensionCode);
        EditDimensionSetEntries.DimensionValueCode.SetValue(DimensionValue);
        EditDimensionSetEntries.OK().Invoke();
    end;

    local procedure ModifyShipmentDateOnTransferHeader(DocumentNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.Get(DocumentNo);
        TransferHeader.Validate("Shipment Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
        TransferHeader.Modify(true);
    end;
}

