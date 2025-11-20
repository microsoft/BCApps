codeunit 137296 "SCM Inventory Misc. IV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        isInitialized: Boolean;
        AmountError: Label 'Amount must be equal.';
        ItemVariantError: Label 'You cannot delete item variant %1 because there is at least one %2 that includes this Variant Code.';
        UpdateAutomaticCostMessage: Label 'The field Automatic Cost Posting should not be set to Yes if field Use Legacy G/L Entry Locking in General Ledger Setup table is set to No because of possibility of deadlocks.';
        UpdateExpCostConfMessage: Label 'If you enable the Expected Cost Posting to G/L, the program must update table Post Value Entry to G/L.This can take several hours.';
        UpdateExpCostMessage: Label 'Expected Cost Posting to G/L has been changed to Yes. You should now run Post Inventory Cost to G/L.';
        UpdateAutomaticCostPeriodMessage: Label 'Some unadjusted value entries will not be covered with the new setting.';
        WrongNextCountingStartDateErr: Label 'Wrong next phys. inventory counting period start date.';
        WrongNextCountingEndDateErr: Label 'Wrong next phys. inventory counting period end date.';
        CalculateNeedVARParameterOutputValueErr: Label '%1 output value is wrong', Comment = '%1 - VAR Parameter Name';
        LocCodeIsModifiedErr: Label 'Location Code has been modified.';

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemVariantError()
    var
        ItemVariant: Record "Item Variant";
        ItemNo: Code[20];
        VariantCode: Code[10];
    begin
        // [SCENARIO] existence of deleted Item Variant.

        // [GIVEN] Create Item, create Item Variant.
        Initialize();
        ItemNo := CreateItem();
        VariantCode := LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        ItemVariant.Delete(true);

        // Exercise.
        asserterror ItemVariant.Get(ItemNo, VariantCode);

        // [THEN] Verify existence of deleted Item Variant.
        Assert.ExpectedErrorCannotFind(Database::"Item Variant");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemVariantUsedInPurchOrderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Error while Delete Item Variant which is used in Purchase Order Line.
        DeleteItemVariantUsedInPurchLineError(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemVariantUsedInPurchRetOrderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Error while Delete Item Variant which is used in Purchase Return Order Line.
        DeleteItemVariantUsedInPurchLineError(PurchaseHeader."Document Type"::"Return Order");
    end;

    local procedure DeleteItemVariantUsedInPurchLineError(DocumentType: Enum "Purchase Document Type")
    var
        ItemVariant: Record "Item Variant";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // [GIVEN] Create Item, Create Purchase Document with Variant Code.
        Initialize();
        ItemNo := CreateItem();
        CreatePurchaseDocument(
          PurchaseLine, DocumentType, ItemNo, LibraryInventory.CreateItemVariant(ItemVariant, ItemNo), CreateVendor(),
          LibraryRandom.RandInt(10), WorkDate()); // Used Random for Quantity.

        // Exercise.
        asserterror ItemVariant.Delete(true);

        // [THEN] Verify Error while Delete Item Variant.
        Assert.ExpectedError(StrSubstNo(ItemVariantError, PurchaseLine."Variant Code", PurchaseLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemVariantUsedInSalesOrderError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] Error while Delete Item Variant which is used in Sales Order Line.
        DeleteItemVariantUsedInSalesLineError(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemVariantUsedInSalesRetOrderError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] Error while Delete Item Variant which is used in Sales Return Order Line.
        DeleteItemVariantUsedInSalesLineError(SalesHeader."Document Type"::"Return Order");
    end;

    local procedure DeleteItemVariantUsedInSalesLineError(DocumentType: Enum "Sales Document Type")
    var
        ItemVariant: Record "Item Variant";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // [GIVEN] Create Item, Create Sales Document with Variant Code.
        Initialize();
        ItemNo := CreateItem();
        CreateSalesDocument(
          SalesLine, DocumentType, ItemNo, LibraryInventory.CreateItemVariant(ItemVariant, ItemNo), LibraryRandom.RandDec(10, 2));  // Used Random for Quantity.

        // Exercise.
        asserterror ItemVariant.Delete(true);

        // [THEN] Verify Error while Delete Item Variant.
        Assert.ExpectedError(StrSubstNo(ItemVariantError, SalesLine."Variant Code", SalesLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemVariantUsedInServiceOrderError()
    var
        ItemVariant: Record "Item Variant";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] Error while Delete Item Variant which is used in Service Order Line.

        // [GIVEN] Create Service Order with Variant Code.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem());
        ServiceLine.Validate("Variant Code", LibraryInventory.CreateItemVariant(ItemVariant, ServiceLine."No."));
        ServiceLine.Modify(true);

        // Exercise.
        asserterror ItemVariant.Delete(true);

        // [THEN] Verify Error while Delete Item Variant.
        Assert.ExpectedError(StrSubstNo(ItemVariantError, ServiceLine."Variant Code", ServiceLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemVariantUsedInItemJournalError()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO] Error while Delete Item Variant which is used in Item Journal Line.

        // [GIVEN] Create Item Journal with Variant Code..
        Initialize();
        ItemNo := CreateItem();
        CreateItemJournalLine(ItemJournalLine, ItemNo, LibraryInventory.CreateItemVariant(ItemVariant, ItemNo), '', '');

        // Exercise.
        asserterror ItemVariant.Delete(true);

        // [THEN] Verify Error while Delete Item Variant.
        Assert.ExpectedError(StrSubstNo(ItemVariantError, ItemJournalLine."Variant Code", ItemJournalLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemVariantUsedInItemLedEntryError()
    var
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
    begin
        // [SCENARIO] Error while Delete Item Variant which is exist in Item Ledger Entry.

        // [GIVEN] Create Item Journal with Variant Code and Post.
        Initialize();
        ItemNo := CreateItem();
        CreateItemJournalLine(ItemJournalLine, ItemNo, LibraryInventory.CreateItemVariant(ItemVariant, ItemNo), '', '');
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Exercise.
        asserterror ItemVariant.Delete(true);

        // [THEN] Verify Error while Delete Item Variant.
        Assert.ExpectedError(StrSubstNo(ItemVariantError, ItemJournalLine."Variant Code", ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemVariantUsedInProdBOMLineError()
    var
        ItemVariant: Record "Item Variant";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO] Error while Delete Item Variant which is exist in Production BOM Line.

        // [GIVEN] Create Item, create Productin BOM with Variant Code.
        Initialize();
        ItemNo := CreateItem();
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, '');
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);  // Required 1 for Quantity Per.
        ProductionBOMLine.Validate("Variant Code", LibraryInventory.CreateItemVariant(ItemVariant, ProductionBOMLine."No."));
        ProductionBOMLine.Modify(true);

        // Exercise.
        asserterror ItemVariant.Delete(true);

        // [THEN] Verify Error while Delete Item Variant.
        Assert.ExpectedError(StrSubstNo(ItemVariantError, ProductionBOMLine."Variant Code", ProductionBOMLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemVariantUsedInProdOrdComponentError()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [SCENARIO] Error while Delete Item Variant which is exist in Production Order Component Line.

        // [GIVEN] Create Item, create component Item, create Certified Production BOM.
        Initialize();
        Item.Get(CreateItem());
        Item2.Get(CreateItem());

        // Update Production Bom on Item.
        UpdateItemWithCertifiedBOMAndRouting(Item, Item2."No.");

        // Create Released Production Order and update Prod. Order Component with Variant.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(10));  // Used Random Int for Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);
        FindAndUpdateProdCompLine(ProductionOrder, LibraryInventory.CreateItemVariant(ItemVariant, Item2."No."));

        // Exercise.
        asserterror ItemVariant.Delete(true);

        // [THEN] Verify Error while Delete Item Variant.
        Assert.ExpectedError(StrSubstNo(ItemVariantError, ItemVariant.Code, ProdOrderComponent.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInvCountingPeriodOnItem()
    var
        Item: Record Item;
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
    begin
        // [SCENARIO] 'Next Counting Period' after update 'Phys. Invt. Counting Period' on Item.

        // [GIVEN] Create Item.
        Initialize();

        // [WHEN] Update 'Phys. Invt. Counting Period' on Item.
        UpdatePhysInvCountingPeriodOnItem(Item, LibraryRandom.RandInt(100));
        NextCountingStartDate := Item."Next Counting Start Date";
        NextCountingEndDate := Item."Next Counting End Date";

        // [THEN] Verify 'Next Counting Period' after update 'Phys. Invt. Counting Period' on Item.
        GetNextCountingPeriod(Item, NextCountingStartDate, NextCountingEndDate);
        Item.TestField("Next Counting Start Date", NextCountingStartDate);
        Item.TestField("Next Counting End Date", NextCountingEndDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePhysInvCountingPeriodOnPhysInventoryWithinThePeriod()
    var
        Item: Record Item;
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
        PhysInventoryDate: Date;
        CountFrequency: Integer;
    begin
        // [FEATURE] [Physical Inventory] [UT]
        // [SCENARIO 379410] Next Counting Start and End Dates are updated when Phys. Inventory Counting Period is shorter than a month and Phys. Inventory is posted within this period.
        Initialize();

        // [GIVEN] Item with a weekly Phys. Inventory Counting Period.
        CountFrequency := 52; // 52 weeks in a year
        UpdatePhysInvCountingPeriodOnItem(Item, CountFrequency);
        NextCountingStartDate := Item."Next Counting Start Date";
        NextCountingEndDate := Item."Next Counting End Date";
        PhysInventoryDate := NextCountingStartDate + LibraryRandom.RandInt(NextCountingEndDate - NextCountingStartDate); // within the next counting period

        // [WHEN] Next Counting Start and End Dates are calculated by CalcPeriod function which is called on Phys. Inventory Journal Line posting.
        PhysInvtCountManagement.CalcPeriod(
          PhysInventoryDate, Item."Next Counting Start Date", Item."Next Counting End Date", CountFrequency);

        // [THEN] New "Next Counting Start Date" = Old "Next Counting End Date" + 1 day
        // [THEN] New "Next Counting End Date" = New "Next Counting Start Date" + 1 week
        Item.TestField("Next Counting Start Date", CalcDate('<1D>', NextCountingEndDate));
        Item.TestField("Next Counting End Date", CalcDate('<1W-1D>', Item."Next Counting Start Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotUpdatePhysInvCountingPeriodOnPhysInventoryOutsideThePeriodMonthlyCounting()
    var
        Item: Record Item;
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
        CountFrequency: Integer;
    begin
        // [FEATURE] [Physical Inventory] [UT]
        // [SCENARIO 379410] Next Counting Start and End Dates are not updated when Phys. Inventory is posted one day before the starting date of the Counting Period with monthly counting.
        Initialize();

        // [GIVEN] Item with a Phys. Inventory Counting Period, monthly counting frequency.
        CountFrequency := 12;
        UpdatePhysInvCountingPeriodOnItem(Item, CountFrequency);
        NextCountingStartDate := Item."Next Counting Start Date";
        NextCountingEndDate := Item."Next Counting End Date";

        // [WHEN] Call "Phys. Invt. Count Management".CalcPeriod function with a Phys. Inventory posting date parameter a day before the period start.
        PhysInvtCountManagement.CalcPeriod(
            NextCountingStartDate - 1, Item."Next Counting Start Date", Item."Next Counting End Date", CountFrequency);

        // [THEN] Next Counting Start and End Dates are not updated.
        Item.TestField("Next Counting Start Date", NextCountingStartDate);
        Item.TestField("Next Counting End Date", NextCountingEndDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotUpdatePhysInvCountingPeriodOnPhysInventoryOutsideThePeriodBiweeklyCounting()
    var
        Item: Record Item;
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
        CountFrequency: Integer;
    begin
        // [FEATURE] [Physical Inventory] [UT]
        // [SCENARIO 379410] Next Counting Start and End Dates are not updated when Phys. Inventory is posted one day before the starting date of the Counting Period with biweekly counting.
        Initialize();

        // [GIVEN] Item with a Phys. Inventory Counting Period, biweekly counting frequency.
        CountFrequency := 24;
        UpdatePhysInvCountingPeriodOnItem(Item, CountFrequency);
        NextCountingStartDate := Item."Next Counting Start Date";
        NextCountingEndDate := Item."Next Counting End Date";

        // [WHEN] Call "Phys. Invt. Count Management".CalcPeriod function with a Phys. Inventory posting date parameter a day before the period start.
        PhysInvtCountManagement.CalcPeriod(
            NextCountingStartDate - 1, Item."Next Counting Start Date", Item."Next Counting End Date", CountFrequency);

        // [THEN] Next Counting Start and End Dates are not updated.
        Item.TestField("Next Counting Start Date", NextCountingStartDate);
        Item.TestField("Next Counting End Date", NextCountingEndDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NextPhysInvtCountingPeriodIsAfterLastInventoryDateDoneOutsidePeriod()
    var
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
        PhysInvtDate: Date;
        CountFrequency: Integer;
        CountPeriodBounds: array[5, 2] of Integer;
        i: Integer;
    begin
        // [FEATURE] [Physical Inventory] [UT]
        // [SCENARIO 212591] The next phys. inventory counting period should be shifted to the nearest period in a sequence after the phys. inventory date, if the inventory is posted later than the end date of the current period.
        Initialize();

        // [GIVEN] Weekly (52 times a year) phys. inventory counting period.
        CountFrequency := 52;

        // [GIVEN] The current counting period is 0..6 days from WORKDATE.
        NextCountingStartDate := WorkDate();
        NextCountingEndDate := WorkDate() + 6;

        // [GIVEN] The next counting periods will be as follows: 7..13, 14..20, 21..27, ...
        for i := 1 to ArrayLen(CountPeriodBounds, 1) do begin
            CountPeriodBounds[i] [1] := 7 * i;
            CountPeriodBounds[i] [2] := 7 * i + 6;
        end;

        // [GIVEN] Last phys. inventory is carried out within the period of 8..15 days.
        i := LibraryRandom.RandInt(ArrayLen(CountPeriodBounds, 1) - 1);
        PhysInvtDate := LibraryRandom.RandDateFromInRange(WorkDate(), CountPeriodBounds[i] [1], CountPeriodBounds[i] [2]);

        // [WHEN] Calculate the next counting period.
        PhysInvtCountManagement.CalcPeriod(
          PhysInvtDate, NextCountingStartDate, NextCountingEndDate, CountFrequency);

        // [THEN] The next counting period is the period that follows 8..15, which is 16..23 days.
        Assert.AreEqual(WorkDate() + CountPeriodBounds[i + 1] [1], NextCountingStartDate, WrongNextCountingStartDateErr);
        Assert.AreEqual(WorkDate() + CountPeriodBounds[i + 1] [2], NextCountingEndDate, WrongNextCountingEndDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BiweeklyPhysInvCountingPeriodWithNoLastDate()
    var
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
        StartDateOfMonth: Date;
        MiddleDateOfMonth: Date;
        EndDateOfMonth: Date;
        HalfMonthStartDate: Date;
        HalfMonthEndDate: Date;
        DaysInMonth: Integer;
        MiddleDayOfMonth: Integer;
        LastDayOfMonth: Integer;
        CountFrequency: Integer;
    begin
        // [FEATURE] [Physical Inventory] [UT]
        // [SCENARIO 201098] CalcPeriod function in Phys. Invt. Count.-Management codeunit run with (CountFrequency = 24, LastDate = empty) parameters should set half a month long counting period into which WORKDATE would fall into.
        Initialize();

        // [GIVEN] Phys. inventory counting frequency = 24 times a year (twice in a month).
        CountFrequency := 24;

        // [GIVEN] Last counting date = empty, so the calculation of the next counting period will be based on WORKDATE.
        // [GIVEN] WORKDATE = 25/01/YY.
        StartDateOfMonth := CalcDate('<-CM>', WorkDate()); // month begin date = 01/01/YY
        EndDateOfMonth := CalcDate('<CM>', WorkDate()); // month end date = 31/01/YY
        DaysInMonth := Date2DMY(EndDateOfMonth, 1); // days in month = 31
        MiddleDateOfMonth := StartDateOfMonth + DaysInMonth div 2; // first day of second half of month = 16/01/YY

        MiddleDayOfMonth := Date2DMY(MiddleDateOfMonth, 1);
        LastDayOfMonth := Date2DMY(EndDateOfMonth, 1);

        // [GIVEN] First and last day of the half a month into which WORKDATE falls into is defined.
        HalfMonthStartDate :=
          StartDateOfMonth + (Date2DMY(WorkDate(), 1) div MiddleDayOfMonth) * (MiddleDayOfMonth - 1); // 16/01/YY
        HalfMonthEndDate :=
          EndDateOfMonth - ((LastDayOfMonth - Date2DMY(WorkDate(), 1)) div MiddleDayOfMonth) * MiddleDayOfMonth; // 31/01/YY

        // [WHEN] Run CalcPeriod function in Phys. Invt. Count.-Management to get next counting start and end dates.
        PhysInvtCountManagement.CalcPeriod(0D, NextCountingStartDate, NextCountingEndDate, CountFrequency);

        // [THEN] Next counting start date = 16/01/YY.
        // [THEN] Next counting end date = 31/01/YY.
        Assert.AreEqual(HalfMonthStartDate, NextCountingStartDate, WrongNextCountingStartDateErr);
        Assert.AreEqual(HalfMonthEndDate, NextCountingEndDate, WrongNextCountingEndDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BiweeklyPhysInvCountingPeriodWithLastDateOnFirstHalfMonth()
    var
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
        LastCountingDate: Date;
        CountFrequency: Integer;
    begin
        // [FEATURE] [Physical Inventory] [UT]
        // [SCENARIO 201098] CalcPeriod function in Phys. Invt. Count.-Management codeunit run with (CountFrequency = 24, LastDate in first half of month) parameters should set half a month long counting period, following the one with LastDate.
        Initialize();

        // [GIVEN] Phys. inventory counting frequency = 24 times a year (twice in a month).
        // [GIVEN] Last counting date = 05/01/YY (in first half of month).
        CountFrequency := 24;
        LastCountingDate := 20200105D;

        // [WHEN] Run CalcPeriod function in Phys. Invt. Count.-Management to get next counting start and end dates.
        PhysInvtCountManagement.CalcPeriod(LastCountingDate, NextCountingStartDate, NextCountingEndDate, CountFrequency);

        // [THEN] Next counting start date = 16/01/YY.
        // [THEN] Next counting end date = 31/01/YY.
        Assert.AreEqual(20200116D, NextCountingStartDate, WrongNextCountingStartDateErr);
        Assert.AreEqual(20200131D, NextCountingEndDate, WrongNextCountingEndDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BiweeklyPhysInvCountingPeriodWithLastDateOnSecondHalfMonth()
    var
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
        LastCountingDate: Date;
        CountFrequency: Integer;
    begin
        // [FEATURE] [Physical Inventory] [UT]
        // [SCENARIO 201098] CalcPeriod function in Phys. Invt. Count.-Management codeunit run with (CountFrequency = 24, LastDate in second half of month) parameters should set half a month long counting period, following the one with LastDate.
        Initialize();

        // [GIVEN] Phys. inventory counting frequency = 24 times a year (twice in a month).
        // [GIVEN] Last counting date = 25/01/YY (in second half of month).
        CountFrequency := 24;
        LastCountingDate := 20200125D;

        // [WHEN] Run CalcPeriod function in Phys. Invt. Count.-Management to get next counting start and end dates.
        PhysInvtCountManagement.CalcPeriod(LastCountingDate, NextCountingStartDate, NextCountingEndDate, CountFrequency);

        // [THEN] Next counting start date = 01/02/YY.
        // [THEN] Next counting end date = 14/02/YY.
        Assert.AreEqual(20200201D, NextCountingStartDate, WrongNextCountingStartDateErr);
        Assert.AreEqual(20200214D, NextCountingEndDate, WrongNextCountingEndDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectUnitCostOnPurchLineFromPurchPrice()
    var
        PurchasePrice: Record "Purchase Price";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Direct Unit Cost on Purchase Line when Order Date is same as Starting Date of Purchase Price.

        // [GIVEN]
        Initialize();
        CreatePurchasePrice(PurchasePrice, '', CreateVendor(), WorkDate());
        CopyAllPurchPriceToPriceListLine();

        // [WHEN] Create Purchase Order.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchasePrice."Item No.", '', PurchasePrice."Vendor No.",
          PurchasePrice."Minimum Quantity", WorkDate());

        // [THEN] Verify Direct Unit Cost on Purchase Line.
        PurchaseLine.TestField("Direct Unit Cost", PurchasePrice."Direct Unit Cost");
    end;

    local procedure CopyAllPurchPriceToPriceListLine()
    var
        PurchPrice: Record "Purchase Price";
        PurchLineDiscount: Record "Purchase Line Discount";
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.DeleteAll();
        CopyFromToPriceListLine.CopyFrom(PurchPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(PurchLineDiscount, PriceListLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectUnitCostOnPurchLineFromItem()
    var
        PurchasePrice: Record "Purchase Price";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [SCENARIO] Direct Unit Cost on Purchase Line when Order Date is before Starting Date of Purchase Price.

        // [GIVEN]
        Initialize();
        CreatePurchasePrice(PurchasePrice, '', CreateVendor(), WorkDate());
        Item.Get(PurchasePrice."Item No.");

        // [WHEN] Create Purchase Order.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchasePrice."Item No.", '', PurchasePrice."Vendor No.",
          PurchasePrice."Minimum Quantity", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));

        // [THEN] Verify Direct Unit Cost on Purchase Line.
        PurchaseLine.TestField("Direct Unit Cost", Item."Last Direct Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectUnitCostOnPurchLineWithCurrency()
    var
        PurchasePrice: Record "Purchase Price";
        PurchaseLine: Record "Purchase Line";
        Currency: Record Currency;
    begin
        // [SCENARIO] Direct Unit Cost on Purchase Line when Purchase Price is defined with Currency.

        // [GIVEN]
        Initialize();
        Currency.Get(CreateCurrency());
        CreatePurchasePrice(PurchasePrice, Currency.Code, CreateAndModifyVendor(Currency.Code), WorkDate());
        CopyAllPurchPriceToPriceListLine();

        // [WHEN] Create Purchase Order.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchasePrice."Item No.", '', PurchasePrice."Vendor No.",
          PurchasePrice."Minimum Quantity", WorkDate());

        // [THEN] Verify Direct Unit Cost on Purchase Line.
        PurchaseLine.TestField("Direct Unit Cost", PurchasePrice."Direct Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePriceForVendorWithPartialQty()
    var
        PurchasePrice: Record "Purchase Price";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Direct Unit Cost on Posted Purchase Invoice Line after posting Partial Quantity on Purchase Order and updating Unit Cost on Purchase Price.

        // [GIVEN]
        Initialize();
        CreatePurchasePrice(PurchasePrice, '', CreateVendor(), WorkDate());
        CopyAllPurchPriceToPriceListLine();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchasePrice."Item No.", '', PurchasePrice."Vendor No.",
          PurchasePrice."Minimum Quantity", WorkDate());
        UpdateUnitCostOnPurchasePrice(PurchasePrice);
        CopyAllPurchPriceToPriceListLine();
        UpdatePurchLineQtyForPartialPost(PurchaseLine);

        // [WHEN] Post Purchase Order.
        DocumentNo := PostPurchaseDocument(PurchaseLine, true);

        // [THEN] Verify Direct Unit Cost on Posted Purchase Invoice after posting Partial Quantity.
        VerifyPstdPurchaseInvoice(DocumentNo, PurchasePrice."Direct Unit Cost", 0);  // 0 for Line Discount Pct.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvUsingCopyDocument()
    var
        PurchasePrice: Record "Purchase Price";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        DirectUnitCost: Decimal;
    begin
        // [SCENARIO] Direct Unit Cost on Posted Purchase Invoice after posting Purchase Invoice using Copy Document and updating Unit Cost on Purchase Price.

        // [GIVEN] Create Purchase Price, create and Receive Purchase order.
        Initialize();
        CreatePurchasePrice(PurchasePrice, '', CreateVendor(), WorkDate());
        CopyAllPurchPriceToPriceListLine();
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchasePrice."Item No.", '', PurchasePrice."Vendor No.",
          PurchasePrice."Minimum Quantity", WorkDate());
        DocumentNo := PostPurchaseDocument(PurchaseLine, false);

        // Update Unit Cost on Purchase Price, create Purchase Invoice using Copy Document.
        DirectUnitCost := UpdateUnitCostOnPurchasePrice(PurchasePrice);
        CopyAllPurchPriceToPriceListLine();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchasePrice."Vendor No.");
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Receipt", DocumentNo, false, true);

        // [WHEN] Post Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Direct Unit Cost on Posted Purchase Invoice after posting Purchase Invoice using Copy Document.
        VerifyPstdPurchaseInvoice(DocumentNo, DirectUnitCost, 0);
    end;

    [Test]
    [HandlerFunctions('SentNotificationHandler')]
    [Scope('OnPrem')]
    procedure DirectUnitPriceOnPurchLineRemainUnchangedWhenOverReceiptIsSetOnWhseReceiptLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        Item: Record Item;
        PurchasePrice: Record "Purchase Price";
        OverReceiptCode: Record "Over-Receipt Code";
        WarehouseReceipt: TestPage "Warehouse Receipt";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Over-Receipt] [UI]
        // [SCENARIO] Over-Receipt quantity changes in Warehouse Receipt Line does not cause the Direct Unit Price on Purchase Line to change.
        // Bug https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_workitems/edit/500735
        Initialize();

        // [GIVEN] Location with Warehouse Receipt.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Vendor with a special purchase price on item with Over-Receipt setup.
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryInventory.CreateItem(Item);
        OverReceiptCode.FindFirst();
        Item.Validate("Over-Receipt Code", OverReceiptCode.Code);
        Item.Modify(true);
        CreatePurchasePrice(PurchasePrice, VendorNo, Item."No.");

        // [GIVEN] Purchase Order "PO" with Quantity = 11 and a manually entered Direct Unit Cost = 50.
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, PurchasePrice."Item No.", '', PurchasePrice."Vendor No.",
          PurchasePrice."Minimum Quantity", WorkDate());
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code, Item."No.", 11);
        PurchaseLine.Validate("Direct Unit Cost", 50);
        PurchaseLine.Modify(true);

        // [GIVEN] Warehouse Receipt created from Purchaser Order "PO"
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        // [WHEN] Enter "Qty to Receive" = 12.
        WarehouseReceipt.OpenEdit();
        WarehouseReceipt.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceipt.WhseReceiptLines."Qty. to Receive".SetValue(12);

        // [THEN] 'Over-Receipt Code' and 'Over-Receipt Qty.' are populated
        Assert.IsTrue(WarehouseReceipt.WhseReceiptLines."Over-Receipt Code".Value <> '', 'Over-Receipt Code should not be empty');
        Assert.IsTrue(WarehouseReceipt.WhseReceiptLines."Over-Receipt Quantity".AsDecimal() = 1, 'Over-Receipt Quantity should be greater than 0');
        LibraryNotificationMgt.RecallNotificationsForRecordID(PurchaseHeader.RecordId);
        WarehouseReceipt.Close();

        // [THEN] Direct Unit Cost on Purchase Line is not changed.
        PurchaseLine.Find();
        PurchaseLine.TestField("Over-Receipt Quantity", 1);
        PurchaseLine.TestField(Quantity, 12);
        PurchaseLine.TestField("Direct Unit Cost", 50);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostOnPurchLineWithCarryOutActionMsg()
    var
        PurchasePrice: Record "Purchase Price";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Direct Unit Cost on Purchase Line after Calculate Regenerative Plan and carry Out Action Message.

        // [GIVEN] Create Item, create Purchase Price, create Sales order.
        Initialize();
        CreatePurchasePrice(PurchasePrice, '', CreateVendor(), CalcDate('<-1D>', WorkDate()));
        CopyAllPurchPriceToPriceListLine();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, PurchasePrice."Item No.", '', PurchasePrice."Minimum Quantity");

        // [WHEN] Calculate Regenerative Plan and carry Out Action Message.
        CalculateRegPlanAndCarryOutActionMsg(PurchasePrice."Item No.");

        // [THEN] Verify Direct Cost on Purchase Line.
        PurchaseLine.SetRange("No.", PurchasePrice."Item No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Direct Unit Cost", PurchasePrice."Direct Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscOnPurchLineFromPurchLineDisc()
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Line Discount on Purchase Line when Order Date is same as Starting Date of Purchase Price.

        // [GIVEN] Create Purchase Line Discount.
        Initialize();
        CreatePurchaseLineDiscount(PurchaseLineDiscount);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // [WHEN] Create Purchase Order.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLineDiscount."Item No.", '', PurchaseLineDiscount."Vendor No.",
          PurchaseLineDiscount."Minimum Quantity", WorkDate());

        // [THEN] Verify Line Discount on Purchase Line.
        PurchaseLine.TestField("Line Discount %", PurchaseLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscOnPurchLineFromItem()
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
    begin
        // [SCENARIO] Line Discount on Purchase Line when Order Date is before Starting Date of Purchase Price.

        // [GIVEN] Create Purchase Line Discount.
        Initialize();
        CreatePurchaseLineDiscount(PurchaseLineDiscount);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // [WHEN] Create Purchase Order.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLineDiscount."Item No.", '', PurchaseLineDiscount."Vendor No.",
          PurchaseLineDiscount."Minimum Quantity", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()))
        ;

        // [THEN] Verify Line Discount on Purchase Line.
        PurchaseLine.TestField("Line Discount %", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchLineDiscForVendorWithPartialQty()
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
        Item: Record Item;
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Line Discount Pct on Posted Purchase Invoice Line after posting Partial Quantity on Purchase Order and updating Line Discount Pct on Purchase Line Discount.

        // [GIVEN] Create Purchase Line Discount, create Purchase Order, Update Line Discount.
        Initialize();
        CreatePurchaseLineDiscount(PurchaseLineDiscount);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);
        Item.Get(PurchaseLineDiscount."Item No.");
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLineDiscount."Item No.", '', PurchaseLineDiscount."Vendor No.",
          PurchaseLineDiscount."Minimum Quantity", WorkDate());
        UpdateLineDiscOnPurchLineDisc(PurchaseLineDiscount);
        UpdatePurchLineQtyForPartialPost(PurchaseLine);

        // [WHEN] Post Purchase Order.
        DocumentNo := PostPurchaseDocument(PurchaseLine, true);

        // [THEN] Verify Line Discount Pct on Posted Purchase Invoice Line after posting Partial Quantity on Purchase Order.
        VerifyPstdPurchaseInvoice(DocumentNo, Item."Last Direct Cost", PurchaseLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscOnPstdPurchInvUsingCopyDoc()
    var
        Item: Record Item;
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PriceListLine: Record "Price List Line";
        DocumentNo: Code[20];
        LineDiscountPct: Decimal;
    begin
        // [SCENARIO] Line Discount on Posted Purchase Invoice after posting Purchase Invoice using Copy Document and updating Line Discount Pct on Purchase Price.

        // [GIVEN] Create Purchase Price, create and Receive Purchase order.
        Initialize();
        CreatePurchaseLineDiscount(PurchaseLineDiscount);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLineDiscount."Item No.", '', PurchaseLineDiscount."Vendor No.",
          PurchaseLineDiscount."Minimum Quantity", WorkDate());
        DocumentNo := PostPurchaseDocument(PurchaseLine, false);
        Item.Get(PurchaseLine."No.");

        // Update Line Discount Pct on Purchase Price, create Purchase Invoice using Copy Document.
        LineDiscountPct := UpdateLineDiscOnPurchLineDisc(PurchaseLineDiscount);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchaseLineDiscount."Vendor No.");
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Receipt", DocumentNo, false, true);

        // [WHEN] Post Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Line Discount on Posted Purchase Invoice after posting Purchase Invoice using Copy Document.
        VerifyPstdPurchaseInvoice(DocumentNo, Item."Last Direct Cost", LineDiscountPct);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostOutputJournalFromRelProdOrder()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // [SCENARIO] Value Entry after post Output Journal which is created from Production Order.

        // Setup.
        Initialize();
        InventorySetupEnqueues();  // Enqueue Message Handler.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, true, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        // Create Item.
        ItemNo := CreateAndModifyItem('', Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase); // Component Item.

        // Excercise.
        SetupForPostOutputJournal(ProductionOrder, ItemNo);

        // [THEN] Verify Value Entry after post Output Journal.
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Consumption, ProductionOrder."No.", ItemNo);
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Output, ProductionOrder."No.", ProductionOrder."Source No.");

        // Tear Down.
        LibraryVariableStorage.Enqueue(UpdateExpCostConfMessage);
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostOutputJournalWithAppliesToEntry()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // [SCENARIO] Value Entry and Application Worksheet after post Output Journal with 'Apply to Entry' which is created from Production Order.

        // Setup.
        Initialize();
        InventorySetupEnqueues();  // Enqueue Message Handler.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, true, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");

        // Create Item, Post Purchase Order, create Released Production Order.
        ItemNo := CreateAndModifyItem('', Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase); // Component Item.
        SetupForPostOutputJournal(ProductionOrder, ItemNo);

        // Create Output Journal with Applies to Entry and Post.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Output, ProductionOrder."No.");
        CreateOutputJournal(
          ItemJournalLine, ProductionOrder."Source No.", ProductionOrder."No.", GetOperationNo(ProductionOrder."No."),
          -ProductionOrder.Quantity, ItemLedgerEntry."Entry No.");

        // Excercise.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Verify Item Ledger Entry (Application Worksheet) and Value Entry after post Output Journal.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Consumption, ProductionOrder."No.");
        ItemLedgerEntry.TestField("Item No.", ItemNo);
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Consumption, ProductionOrder."No.", ItemNo);

        // Tear Down.
        LibraryVariableStorage.Enqueue(UpdateExpCostConfMessage);
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExpCostAmountInValueEntry()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ValueEntry: Record "Value Entry";
        PurchaseLine: Record "Purchase Line";
        PostedReceiptNo: Code[20];
    begin
        // [SCENARIO] Value Entry after receive Purchase Order.

        // [GIVEN] Update Inventory Setup, create Purchase Order,
        Initialize();
        InventorySetupEnqueues(); // Enqueue Message Handler.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, true, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order,
          CreateAndModifyItem('', Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase), '', CreateVendor(),
          LibraryRandom.RandInt(10), WorkDate());

        // Exercise
        PostedReceiptNo := PostPurchaseDocument(PurchaseLine, false);

        // [THEN] Verify Value Entry after post Purchase Order.
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Purchase, PostedReceiptNo, PurchaseLine."No.");

        // Tear Down.
        LibraryVariableStorage.Enqueue(UpdateExpCostConfMessage);
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostSalesOrder()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] GL Entry after post Salse Order.

        // [GIVEN] Update Inventory Setup, create and post Purchase Order, create Sales Order.
        Initialize();
        InventorySetupEnqueues(); // Enqueue Message Handler.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, true, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        CreateAndPostPurchaseOrder(
          PurchaseLine, CreateAndModifyItem('', Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase), false);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, PurchaseLine."No.", '', LibraryRandom.RandInt(10));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify GL Entry after post Salse Order.
        VerifyGLEntry(GLEntry."Document Type"::Invoice, PostedInvoiceNo, -SalesLine."Line Amount", GLEntry."Gen. Posting Type"::Sale);
        VerifyGLEntry(
          GLEntry."Document Type"::Invoice, PostedInvoiceNo, SalesLine."Amount Including VAT", GLEntry."Gen. Posting Type"::" ");

        // Tear Down.
        LibraryVariableStorage.Enqueue(UpdateExpCostConfMessage);
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostCreditMemo()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        ReasonCode: Record "Reason Code";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        PostedCreditMemoNo: Code[20];
    begin
        // [SCENARIO] GL Entry after post Credit Memo.

        // [GIVEN] Update Inventory Setup, create and receive Purchase Order.
        Initialize();
        LibraryERM.CreateReasonCode(ReasonCode);  // Added for G1 Country Fix.
        InventorySetupEnqueues(); // Enqueue Message Handler.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, true, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        CreateAndPostPurchaseOrder(
          PurchaseLine, CreateAndModifyItem('', Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase), false);   // Used Random for 'Direct Unit Cost'.

        // Reopen Purchase Order and update Direct Unit Cost on Purchase Line.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Direct Unit Cost", (PurchaseLine."Direct Unit Cost" + LibraryRandom.RandInt(10)));  // Used Random, required more than existing 'Direct Unit Cost'.
        PurchaseLine.Modify(true);

        // Create Sales Order and post.
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, PurchaseLine."No.", '', PurchaseLine.Quantity);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create Sales Credit Memo, Get Posted Invoice to Reverse and Post.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        GetPostedDocumentLines(SalesHeader2."No.");
        SalesHeader2.Validate("Reason Code", ReasonCode.Code);
        SalesHeader2.Modify(true);
        FindSalesLine(SalesLine, SalesHeader2."Document Type"::"Credit Memo", SalesHeader2."No.");
        PostedCreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // [WHEN] Post Purhcase received Purchase Order with updated 'Direct Unit Cost'.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify GL Entry after post Salse Credit Memo.
        VerifyGLEntry(
          GLEntry."Document Type"::"Credit Memo", PostedCreditMemoNo, SalesLine."Line Amount", GLEntry."Gen. Posting Type"::Sale);
        VerifyGLEntry(
          GLEntry."Document Type"::"Credit Memo", PostedCreditMemoNo, -SalesLine."Amount Including VAT", GLEntry."Gen. Posting Type"::" ");

        // Tear Down.
        LibraryVariableStorage.Enqueue(UpdateExpCostConfMessage);
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionWorksheetDescriptionFromItemReference()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplateName: Code[10];
    begin
        // [FEATURE] [Requisition Worksheet] [Item Reference]
        // [SCENARIO 202830] Description should be copied into a requisition worksheet line from the item cross reference when calculating requisition plan

        Initialize();

        // [GIVEN] Item "I". Vendor "V" is setup as the default vendor for the item.
        CreateItemWithVendor(Item);

        // [GIVEN] Item cross reference "CR" for item "I" with vendor "V". Description in the cross reference is "D".
        CreateItemReference(ItemReference, Item."No.", Item."Vendor No.");
        // [GIVEN] Create a sales order for item "I"
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.", '', LibraryRandom.RandInt(100));

        // [WHEN] Calculate requisition plan for item "I"
        ReqWkshTemplateName := LibraryPlanning.SelectRequisitionTemplateName();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplateName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplateName, RequisitionWkshName.Name);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] New requisition line is created with "Description" = "D"
        VerifyDescriptionsOnRequisitionLine(Item."No.", ItemReference.Description, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWorksheetDescriptionFromItemRefForDropShipment()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Requisition Worksheet] [Item Reference] [Drop Shipment]
        // [SCENARIO 214007] Description should be copied into a requisition worksheet line from the item reference when running Get Sales Orders function for Drop Shipment.
        Initialize();

        // [GIVEN] Item "I". Vendor "V" is setup as the default vendor for the item.
        // [GIVEN] Item reference "CR" for item "I" with vendor "V". Description in the cross reference is "Desc-CR".
        CreateItemWithVendor(Item);
        CreateItemReference(ItemReference, Item."No.", Item."Vendor No.");

        // [GIVEN] Drop shipment sales order line for item "I". Descriptions on the sales line = "Desc-S1" and "Desc-S2".
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.", '', LibraryRandom.RandInt(100));
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Validate(Description, LibraryUtility.GenerateRandomText(20));
        SalesLine.Validate("Description 2", LibraryUtility.GenerateRandomText(20));
        SalesLine.Modify(true);

        // [WHEN] Run Get Sales Orders function in requisition worksheet.
        GetSalesOrdersInRequisitionWorksheet(SalesLine);

        // [THEN] New requisition line is created with Description = "Desc-CR" and "Description 2" = blank.
        VerifyDescriptionsOnRequisitionLine(Item."No.", ItemReference.Description, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqWorksheetDescriptionFromSalesOrderLineForDropShipment()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Requisition Worksheet] [Item Cross Reference] [Drop Shipment]
        // [SCENARIO 214007] Descriptions should be copied into a requisition worksheet line from sales line when running Get Sales Order function for Drop Shipment.
        Initialize();

        // [GIVEN] Item "I". Vendor "V" is setup as the default vendor for the item.
        CreateItemWithVendor(Item);

        // [GIVEN] Drop shipment sales order line for item "I". Descriptions on the sales line = "D1" and "D2".
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.", '', LibraryRandom.RandInt(100));
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Validate(Description, LibraryUtility.GenerateRandomText(20));
        SalesLine.Validate("Description 2", LibraryUtility.GenerateRandomText(20));
        SalesLine.Modify(true);

        // [WHEN] Run Get Sales Orders function in requisition worksheet.
        GetSalesOrdersInRequisitionWorksheet(SalesLine);

        // [THEN] New requisition line is created with Description = "D1" and "Description 2" = "D2".
        VerifyDescriptionsOnRequisitionLine(Item."No.", SalesLine.Description, SalesLine."Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReferenceGetItemDescriptionItemRefExists()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemReference: Record "Item Reference";
        Description: Text[100];
        Description2: Text[50];
    begin
        // [FEATURE] [Requisition Worksheet] [Item Reference] [UT]
        // [SCENARIO 202830] Function GetItemDescription in table "Item Reference" should return description text when a item reference exists for the given combination of item and vendor
        Initialize();

        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        CreateItemReference(ItemReference, Item."No.", Vendor."No.");

        Description := Item.Description;
#if not CLEAN26
        Assert.IsTrue(
          ItemReference.FindItemDescription(
            Description, Description2, Item."No.", '', Item."Base Unit of Measure",
            ItemReference."Reference Type"::Vendor, Vendor."No."), '');
#else
        Assert.IsTrue(
          ItemReference.FindItemDescription(
            Description, Description2, Item."No.", '', Item."Base Unit of Measure", WorkDate(),
            ItemReference."Reference Type"::Vendor, Vendor."No."), '');
#endif
        Assert.AreEqual(ItemReference.Description, Description, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReferenceGetItemDescriptionItemRefDoesNotExist()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        Description: Text[100];
        Description2: Text[50];
    begin
        // [FEATURE] [Requisition Worksheet] [Item Reference] [UT]
        // [SCENARIO 202830] Function GetItemDescription in table "Item Reference" should not change description text when no item references exist for the given combination of item and vendor
        Initialize();

        LibraryInventory.CreateItem(Item);

        Description := Item.Description;
#if not CLEAN26
        Assert.IsFalse(
          ItemReference.FindItemDescription(
            Description, Description2, Item."No.", '', Item."Base Unit of Measure",
            ItemReference."Reference Type"::Vendor, ''), '');
#else
        Assert.IsFalse(
          ItemReference.FindItemDescription(
            Description, Description2, Item."No.", '', Item."Base Unit of Measure", WorkDate(),
            ItemReference."Reference Type"::Vendor, ''), '');
#endif
        Assert.AreEqual(Item.Description, Description, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAvailabilityFormsMgtCalculateNeedAlwaysCALCFIELDSShipLFBlank()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferQuantity: Decimal;
        InventoryQuantity: Decimal;
        ToShipQuantity: Decimal;
        ToReceiveQuantity: Decimal;
        GrossRequirement: Decimal;
        PlannedOrderReceipt: Decimal;
        ScheduledReceipt: Decimal;
        PlannedOrderReleases: Decimal;
    begin
        // [FEATURE] [Transfer] [Item Availability]
        // [SCENARIO 209093] PROCEDURE "Item Availability Forms Mgt".CalculateNeed always calculates FlowFields depended from "Transfer Line", partly shipped transfer, "Location Filter" is blank
        Initialize();

        // [GIVEN] PROCEDURE CalculateNeed "CN" of Codeunit 353 calculates flowfields of Item "I", Gross Requirement "GR", Planned Order Receipt "PORcp", Scheduled Receipt "SR", Planned Order Releases "PORls";
        SetupTransferQuantities(InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [GIVEN] Item "I" has inventory = 100 at Location "L1" and no inventory at Location "L2";
        // [GIVEN] Partly shipped Transfer Line from "L1" to "L2" with "Quantity" = 50 and "Quantity Shipped" = 30;
        CreateItemInPartlyShippedTransferOrder(Item, TransferHeader, TransferLine, InventoryQuantity, TransferQuantity, ToShipQuantity);

        // [WHEN] Execute "CN" when "I"."Location Filter" is blank
        ItemAvailabilityFormsMgtCalculateNeed(
          Item, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases, '');

        // [THEN] "I" has: "Inventory" = 100, "Qty. in Transit" = 30, "Trans. Ord. Shipment (Qty.)" = 50 - 30, "Trans. Ord. Receipt (Qty.)" = 50 - 30;
        VerifyItemPlanningFields(
          Item, InventoryQuantity, ToShipQuantity, TransferQuantity - ToShipQuantity, TransferQuantity - ToShipQuantity);

        // [THEN] "GR" = 0, "PORcp" = 0, "SR" = 0, "PORls" = 0.
        VerifyCalculatedNeed(
          0, 0, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAvailabilityFormsMgtCalculateNeedAlwaysCALCFIELDSShipLFFrom()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferQuantity: Decimal;
        InventoryQuantity: Decimal;
        ToShipQuantity: Decimal;
        ToReceiveQuantity: Decimal;
        GrossRequirement: Decimal;
        PlannedOrderReceipt: Decimal;
        ScheduledReceipt: Decimal;
        PlannedOrderReleases: Decimal;
    begin
        // [FEATURE] [Transfer] [Item Availability]
        // [SCENARIO 209093] PROCEDURE "Item Availability Forms Mgt".CalculateNeed always calculates FlowFields depended from "Transfer Line", partly shipped transfer, "Location Filter" = "Transfer From Code"
        Initialize();

        // [GIVEN] PROCEDURE CalculateNeed "CN" of Codeunit 353 calculates flowfields of Item "I", Gross Requirement "GR", Planned Order Receipt "PORcp", Scheduled Receipt "SR", Planned Order Releases "PORls";
        SetupTransferQuantities(InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [GIVEN] Item "I" has inventory = 100 at Location "L1" and no inventory at Location "L2"
        // [GIVEN] Partly shipped Transfer Line from "L1" to "L2" with "Quantity" = 50 and "Quantity Shipped" = 30
        CreateItemInPartlyShippedTransferOrder(Item, TransferHeader, TransferLine, InventoryQuantity, TransferQuantity, ToShipQuantity);

        // [WHEN] Execute "CN" when "I"."Location Filter" is "L1"
        ItemAvailabilityFormsMgtCalculateNeed(
          Item, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases, TransferLine."Transfer-from Code");

        // [THEN] "I" has: "Inventory" = 100 - 30, "Qty. in Transit" = 0, "Trans. Ord. Shipment (Qty.)" = 50 - 30, "Trans. Ord. Receipt (Qty.)" = 0;
        VerifyItemPlanningFields(
          Item, InventoryQuantity - ToShipQuantity, 0, TransferQuantity - ToShipQuantity, 0);

        // [THEN] "GR" = 50 - 30, "PORcp" = 0, "SR" = 0, "PORls" = 0.
        VerifyCalculatedNeed(
          TransferQuantity - ToShipQuantity, 0, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAvailabilityFormsMgtCalculateNeedAlwaysCALCFIELDSShipLFTo()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferQuantity: Decimal;
        InventoryQuantity: Decimal;
        ToShipQuantity: Decimal;
        ToReceiveQuantity: Decimal;
        GrossRequirement: Decimal;
        PlannedOrderReceipt: Decimal;
        ScheduledReceipt: Decimal;
        PlannedOrderReleases: Decimal;
    begin
        // [FEATURE] [Transfer] [Item Availability]
        // [SCENARIO 209093] PROCEDURE "Item Availability Forms Mgt".CalculateNeed always calculates FlowFields depended from "Transfer Line", partly shipped transfer, "Location Filter" = "Transfer To Code"
        Initialize();

        // [GIVEN] PROCEDURE CalculateNeed "CN" of Codeunit 353 calculates flowfields of Item "I", Gross Requirement "GR", Planned Order Receipt "PORcp", Scheduled Receipt "SR", Planned Order Releases "PORls";
        SetupTransferQuantities(InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [GIVEN] Item "I" has inventory = 100 at Location "L1" and no inventory at Location "L2"
        // [GIVEN] Partly shipped Transfer Line from "L1" to "L2" with "Quantity" = 50 and "Quantity Shipped" = 30
        CreateItemInPartlyShippedTransferOrder(Item, TransferHeader, TransferLine, InventoryQuantity, TransferQuantity, ToShipQuantity);

        // [WHEN] Execute "CN" when "I"."Location Filter" is "L2"
        ItemAvailabilityFormsMgtCalculateNeed(
          Item, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases, TransferLine."Transfer-to Code");

        // [THEN] "I" has: "Inventory" = 0, "Qty. in Transit" = 30, "Trans. Ord. Shipment (Qty.)" = 0, "Trans. Ord. Receipt (Qty.)" = 50 - 30;
        VerifyItemPlanningFields(
          Item, 0, ToShipQuantity, 0, TransferQuantity - ToShipQuantity);

        // [THEN] "GR" = 0, "PORcp" = 0, "SR" = "TQ", "PORls" = 0.
        VerifyCalculatedNeed(
          0, TransferQuantity, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAvailabilityFormsMgtCalculateNeedAlwaysCALCFIELDSReceiveLFBlank()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferQuantity: Decimal;
        InventoryQuantity: Decimal;
        ToShipQuantity: Decimal;
        ToReceiveQuantity: Decimal;
        GrossRequirement: Decimal;
        PlannedOrderReceipt: Decimal;
        ScheduledReceipt: Decimal;
        PlannedOrderReleases: Decimal;
    begin
        // [FEATURE] [Transfer] [Item Availability]
        // [SCENARIO 209093] PROCEDURE "Item Availability Forms Mgt".CalculateNeed always calculates FlowFields depended from "Transfer Line", partly received transfer, "Location Filter" is blank
        Initialize();

        // [GIVEN] PROCEDURE CalculateNeed "CN" of Codeunit 353 calculates flowfields of Item "I", Gross Requirement "GR", Planned Order Receipt "PORcp", Scheduled Receipt "SR", Planned Order Releases "PORls";
        SetupTransferQuantities(InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [GIVEN] Item "I" has inventory = 100 at Location "L1" and no inventory at Location "L2"
        // [GIVEN] Partly received Transfer Line from "L1" to "L2" with "Quantity" = 50, "Quantity Shipped" = 30 and "Quantity Received" = 10
        CreateItemInPartlyReceivedTransferOrder(
          Item, TransferHeader, TransferLine, InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [WHEN] Execute "CN" when "I"."Location Filter" is blank
        ItemAvailabilityFormsMgtCalculateNeed(
          Item, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases, '');

        // [THEN] "I" has: "Inventory" = 100, "Qty. in Transit" = 50 - 10, "Trans. Ord. Shipment (Qty.)" = 50 - 30, "Trans. Ord. Receipt (Qty.)" = 50 - 30;
        VerifyItemPlanningFields(
          Item, InventoryQuantity, ToShipQuantity - ToReceiveQuantity, TransferQuantity - ToShipQuantity, TransferQuantity - ToShipQuantity);

        // [THEN] "GR" = 0, "PORcp" = 0, "SR" = 0, "PORls" = 0.
        VerifyCalculatedNeed(
          0, 0, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAvailabilityFormsMgtCalculateNeedAlwaysCALCFIELDSReceiveLFFrom()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferQuantity: Decimal;
        InventoryQuantity: Decimal;
        ToShipQuantity: Decimal;
        ToReceiveQuantity: Decimal;
        GrossRequirement: Decimal;
        PlannedOrderReceipt: Decimal;
        ScheduledReceipt: Decimal;
        PlannedOrderReleases: Decimal;
    begin
        // [FEATURE] [Transfer] [Item Availability]
        // [SCENARIO 209093] PROCEDURE "Item Availability Forms Mgt".CalculateNeed always calculates FlowFields depended from "Transfer Line", partly received transfer, "Location Filter" = "Transfer From Code"
        Initialize();

        // [GIVEN] PROCEDURE CalculateNeed "CN" of Codeunit 353 calculates flowfields of Item "I", Gross Requirement "GR", Planned Order Receipt "PORcp", Scheduled Receipt "SR", Planned Order Releases "PORls";
        SetupTransferQuantities(InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [GIVEN] Item "I" has inventory = 100 at Location "L1" and no inventory at Location "L2"
        // [GIVEN] Partly received Transfer Line from "L1" to "L2" with "Quantity" = 50, "Quantity Shipped" = 30 and "Quantity Received" = 10
        CreateItemInPartlyReceivedTransferOrder(
          Item, TransferHeader, TransferLine, InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [WHEN] Execute "CN" when "I"."Location Filter" is "L1"
        ItemAvailabilityFormsMgtCalculateNeed(
          Item, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases, TransferLine."Transfer-from Code");

        // [THEN] "I" has: "Inventory" = 100 - 30, "Qty. in Transit" = 0, "Trans. Ord. Shipment (Qty.)" = 50 - 30, "Trans. Ord. Receipt (Qty.)" = 0;
        VerifyItemPlanningFields(
          Item, InventoryQuantity - ToShipQuantity, 0, TransferQuantity - ToShipQuantity, 0);

        // [THEN] "GR" = 50 - 30, "PORcp" = 0, "SR" = 0, "PORls" = 0.
        VerifyCalculatedNeed(
          TransferQuantity - ToShipQuantity, 0, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAvailabilityFormsMgtCalculateNeedAlwaysCALCFIELDSReceiveLFTo()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferQuantity: Decimal;
        InventoryQuantity: Decimal;
        ToShipQuantity: Decimal;
        ToReceiveQuantity: Decimal;
        GrossRequirement: Decimal;
        PlannedOrderReceipt: Decimal;
        ScheduledReceipt: Decimal;
        PlannedOrderReleases: Decimal;
    begin
        // [FEATURE] [Transfer] [Item Availability]
        // [SCENARIO 209093]  PROCEDURE "Item Availability Forms Mgt".CalculateNeed always calculates FlowFields depended from "Transfer Line", partly received transfer, "Location Filter" = "Transfer To Code"
        Initialize();

        // [GIVEN] PROCEDURE CalculateNeed "CN" of Codeunit 353 calculates flowfields of Item "I", Gross Requirement "GR", Planned Order Receipt "PORcp", Scheduled Receipt "SR", Planned Order Releases "PORls";
        SetupTransferQuantities(InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [GIVEN] Item "I" has inventory = 100 at Location "L1" and no inventory at Location "L2"
        // [GIVEN] Partly received Transfer Line from "L1" to "L2" with "Quantity" = 50, "Quantity Shipped" = 30 and "Quantity Received" = 10
        CreateItemInPartlyReceivedTransferOrder(
          Item, TransferHeader, TransferLine, InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [WHEN] Execute "CN" when "I"."Location Filter" is "L2"
        ItemAvailabilityFormsMgtCalculateNeed(
          Item, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases, TransferLine."Transfer-to Code");

        // [THEN] "I" has: "Inventory" = 10, "Qty. in Transit" = 30 - 10, "Trans. Ord. Shipment (Qty.)" = 0, "Trans. Ord. Receipt (Qty.)" = 50 - 30;
        VerifyItemPlanningFields(
          Item, ToReceiveQuantity, ToShipQuantity - ToReceiveQuantity, 0, TransferQuantity - ToShipQuantity);

        // [THEN] "GR" = 0, "PORcp" = 0, "SR" = 50 - 10, "PORls" = 0.
        VerifyCalculatedNeed(
          0, TransferQuantity - ToReceiveQuantity, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityLineListHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailabilityFormsMgtShowItemAvailLineListLFBlank()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferQuantity: Decimal;
        InventoryQuantity: Decimal;
        ToShipQuantity: Decimal;
        ToReceiveQuantity: Decimal;
    begin
        // [FEATURE] [Transfer] [Item Availability]
        // [SCENARIO 209093] The PROCEDURE "Item Availability Forms Mgt".ShowItemAvailLineList doesn't calculate Item FlowFields, case "Location Filter" is blank
        Initialize();

        // [GIVEN] PROCEDURE ShowItemAvailLineList "SIALL" of Codeunit 353 "Item Availability Forms Mgt" has VAR output parameter Item "I";
        SetupTransferQuantities(InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [GIVEN] Item "I" has inventory = 100 at Location "L1" and no inventory at Location "L2";
        // [GIVEN] Partly received Transfer Line from "L1" to "L2" with "Quantity" = 50, "Quantity Shipped" = 30 and "Quantity Received" = 10;
        CreateItemInPartlyReceivedTransferOrder(
          Item, TransferHeader, TransferLine, InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [WHEN] Execute "SIALL" when "I"."Location Filter" is blank
        ItemAvailabilityFormsMgtShowItemAvailLineList(Item, '');

        // [THEN] "I" has: "Inventory" = 0, "Qty. in Transit" = 0, "Trans. Ord. Shipment (Qty.)" = 0, "Trans. Ord. Receipt (Qty.)" = 0.
        Item.TestField(Inventory, 0);
        Item.TestField("Qty. in Transit", 0);
        Item.TestField("Trans. Ord. Shipment (Qty.)", 0);
        Item.TestField("Trans. Ord. Receipt (Qty.)", 0);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityLineListHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailabilityFormsMgtShowItemAvailLineListLFFrom()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferQuantity: Decimal;
        InventoryQuantity: Decimal;
        ToShipQuantity: Decimal;
        ToReceiveQuantity: Decimal;
    begin
        // [FEATURE] [Transfer] [Item Availability]
        // [SCENARIO 209093] The PROCEDURE "Item Availability Forms Mgt".ShowItemAvailLineList doesn't calculate Item FlowFields, case "Location Filter" is "Transfer From Code"
        Initialize();

        // [GIVEN] PROCEDURE ShowItemAvailLineList "SIALL" of Codeunit 353 "Item Availability Forms Mgt" has VAR output parameter Item "I";
        SetupTransferQuantities(InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [GIVEN] Item "I" has inventory = 100 at Location "L1" and no inventory at Location "L2";
        // [GIVEN] Partly received Transfer Line from "L1" to "L2" with "Quantity" = 50, "Quantity Shipped" = 30 and "Quantity Received" = 10;
        CreateItemInPartlyReceivedTransferOrder(
          Item, TransferHeader, TransferLine, InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [WHEN] Execute "SIALL" when "I"."Location Filter" is "L1"
        ItemAvailabilityFormsMgtShowItemAvailLineList(Item, TransferLine."Transfer-from Code");

        // [THEN] "I" has: "Inventory" = 0, "Qty. in Transit" = 0, "Trans. Ord. Shipment (Qty.)" = 0, "Trans. Ord. Receipt (Qty.)" = 0.
        Item.TestField(Inventory, 0);
        Item.TestField("Qty. in Transit", 0);
        Item.TestField("Trans. Ord. Shipment (Qty.)", 0);
        Item.TestField("Trans. Ord. Receipt (Qty.)", 0);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityLineListHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailabilityFormsMgtShowItemAvailLineListLFTo()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferQuantity: Decimal;
        InventoryQuantity: Decimal;
        ToShipQuantity: Decimal;
        ToReceiveQuantity: Decimal;
    begin
        // [FEATURE] [Transfer] [Item Availability]
        // [SCENARIO 209093] The PROCEDURE "Item Availability Forms Mgt".ShowItemAvailLineList doesn't calculate Item FlowFields, case "Location Filter" is "Transfer To Code"
        Initialize();

        // [GIVEN] PROCEDURE ShowItemAvailLineList "SIALL" of Codeunit 353 "Item Availability Forms Mgt" has VAR output parameter Item "I";
        SetupTransferQuantities(InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [GIVEN] Item "I" has inventory = 100 at Location "L1" and no inventory at Location "L2";
        // [GIVEN] Partly received Transfer Line from "L1" to "L2" with "Quantity" = 50, "Quantity Shipped" = 30 and "Quantity Received" = 10;
        CreateItemInPartlyReceivedTransferOrder(
          Item, TransferHeader, TransferLine, InventoryQuantity, TransferQuantity, ToShipQuantity, ToReceiveQuantity);

        // [WHEN] Execute "SIALL" when "I"."Location Filter" is "L2"
        ItemAvailabilityFormsMgtShowItemAvailLineList(Item, TransferLine."Transfer-to Code");

        // [THEN] "I" has: "Inventory" = 0, "Qty. in Transit" = 0, "Trans. Ord. Shipment (Qty.)" = 0, "Trans. Ord. Receipt (Qty.)" = 0.
        Item.TestField(Inventory, 0);
        Item.TestField("Qty. in Transit", 0);
        Item.TestField("Trans. Ord. Shipment (Qty.)", 0);
        Item.TestField("Trans. Ord. Receipt (Qty.)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseVariantZeroLineDiscount()
    var
        ItemVariant: Record "Item Variant";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Variant] [Discount]
        // [SCENARIO 208048] Zero discounts must be transferred to purchase document from "Purchase Line Discount"
        Initialize();

        // [GIVEN] Variant "IV" of Item "I"
        LibraryInventory.CreateItemVariant(ItemVariant, LibraryInventory.CreateItemNo());

        // [GIVEN] Vendor "V"
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Purchase Line Discount "IPLD" for "V" and "I", "IPLD"."Minimum Quantity" = 0, "IPLD"."Variant Code" is blank, "IPLD"."Line Discount %" > 0;
        // [GIVEN] Purchase Line Discount "VPLD" for "V", "I" and "IV", "VPLD"."Minimum Quantity" = 0, "VPLD"."Variant Code" = "IV", "VPLD"."Line Discount %" = 0;
        // [GIVEN] Purchase Line "L" with "No." = "I"."No." and Quantity > 0 has "Line Discount %" = "IPLD"."Line Discount %"
        CreateZeroForVariantPurchaseLineDiscount(ItemVariant, VendorNo);

        // [WHEN] Set "Variant Code" = "IV" in "L"
        CreatePurchaseOrderLineWithItemVariant(PurchaseLine, ItemVariant, VendorNo);

        // [THEN] "L"."Line Discount %" = 0
        PurchaseLine.TestField("Line Discount %", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVariantZeroLineDiscount()
    var
        ItemVariant: Record "Item Variant";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Variant] [Discount]
        // [SCENARIO 208048] Zero discounts must be transferred to sales document from "Sales Line Discount"
        Initialize();

        // [GIVEN] Variant "IV" of Item "I"
        LibraryInventory.CreateItemVariant(ItemVariant, LibraryInventory.CreateItemNo());

        // [GIVEN] Customer "C"
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Sales Line Discount "ISLD" for "C" and "I", "ISLD"."Minimum Quantity" = 0, "ISLD"."Variant Code" is blank, "ISLD"."Line Discount %" > 0;
        // [GIVEN] Sales Line Discount "VSLD" for "C", "I" and "IV", "VSLD"."Minimum Quantity" = 0, "VSLD"."Variant Code" = "IV", "VSLD"."Line Discount %" = 0;
        // [GIVEN] Sales Line "L" with "No." = "I"."No." and Quantity > 0 has "Line Discount %" = "IPLD"."Line Discount %"
        CreateZeroForVariantSalesLineDiscount(ItemVariant, CustomerNo);

        // [WHEN] Set "Variant Code" = "IV" in "L"
        CreateSalesOrderLineWithItemVariant(SalesLine, ItemVariant, CustomerNo);

        // [THEN] "L"."Line Discount %" = 0
        SalesLine.TestField("Line Discount %", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineVariantZeroLineDiscount()
    var
        ItemVariant: Record "Item Variant";
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Job Planning] [Variant] [Discount]
        // [SCENARIO 208048] Zero discounts must be transferred to "Job Planning Line" from "Sales Line Discount"
        Initialize();

        // [GIVEN] Variant "IV" of Item "I"
        LibraryInventory.CreateItemVariant(ItemVariant, LibraryInventory.CreateItemNo());

        // [GIVEN] Customer "C"
        CustomerNo := CreateJobTask(JobTask);

        // [GIVEN] Sales Line Discount "ISLD" for "C" and "I", "ISLD"."Minimum Quantity" = 0, "ISLD"."Variant Code" is blank, "ISLD"."Line Discount %" > 0;
        // [GIVEN] Sales Line Discount "VSLD" for "C", "I" and "IV", "VSLD"."Minimum Quantity" = 0, "VSLD"."Variant Code" = "IV", "VSLD"."Line Discount %" = 0;
        // [GIVEN] "Job Planning Line" "L" with "No." = "I"."No." and Quantity > 0 has "Line Discount %" = "IPLD"."Line Discount %"
        CreateZeroForVariantSalesLineDiscount(ItemVariant, CustomerNo);

        // [WHEN] Set "Variant Code" = "IV" in "L"
        CreateJobPlanningLineWithItemVariant(JobPlanningLine, JobTask, ItemVariant);

        // [THEN] "L"."Line Discount %" = 0
        JobPlanningLine.TestField("Line Discount %", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobJournalLineVariantZeroLineDiscount()
    var
        ItemVariant: Record "Item Variant";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Job Journal] [Variant] [Discount]
        // [SCENARIO 208048] Zero discounts must be transferred to "Job Journal Line" from "Sales Line Discount"
        Initialize();

        // [GIVEN] Variant "IV" of Item "I"
        LibraryInventory.CreateItemVariant(ItemVariant, LibraryInventory.CreateItemNo());

        // [GIVEN] Customer "C"
        CustomerNo := CreateJobTask(JobTask);

        // [GIVEN] Sales Line Discount "ISLD" for "C" and "I", "ISLD"."Minimum Quantity" = 0, "ISLD"."Variant Code" is blank, "ISLD"."Line Discount %" > 0;
        // [GIVEN] Sales Line Discount "VSLD" for "C", "I" and "IV", "VSLD"."Minimum Quantity" = 0, "VSLD"."Variant Code" = "IV", "VSLD"."Line Discount %" = 0;
        // [GIVEN] "Job Journal Line" "L" with "No." = "I"."No." and Quantity > 0 has "Line Discount %" = "IPLD"."Line Discount %"
        CreateZeroForVariantSalesLineDiscount(ItemVariant, CustomerNo);

        // [WHEN] Set "Variant Code" = "IV" in "L"
        CreateJobJournalLineWithItemVariant(JobJournalLine, JobTask, ItemVariant);

        // [THEN] "L"."Line Discount %" = 0
        JobJournalLine.TestField("Line Discount %", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyReplenishSystemInPlanningWorksheet()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        OrderPromisingLine: Record "Order Promising Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Requisition Worksheet] [Capable to Promise]
        // [SCENARIO 256741] Location code shouldn't be modified in Planning Worksheet page when Replenishment System field is changed.

        Initialize();

        // [GIVEN] Create a Sales Order with single line and definite Location Code
        CreateSalesOrderWithItemAndLocation(SalesHeader, Location, Item);

        // [GIVEN] Create and update Order Promising Line.
        CreateAndUpdateOrderPromisingLine(OrderPromisingLine, SalesHeader);

        // [GIVEN] Accept Order Promising which leads to creating Requisition Line.
        AcceptOrderPromising(RequisitionLine, OrderPromisingLine, SalesHeader);

        // [WHEN] Trying to set another value into Replenishment System field.
        RequisitionLine.SetCurrFieldNo(RequisitionLine.FieldNo("Replenishment System"));
        RequisitionLine.Validate("Replenishment System", RequisitionLine."Replenishment System"::"Prod. Order");
        RequisitionLine.Modify(true);

        // [THEN] Location Code hasn't been modified.
        Assert.AreEqual(Location.Code, RequisitionLine."Location Code", LocCodeIsModifiedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToCodeUpdatedOnPurchaseCreatedFromReqWorksheet()
    var
        Item: Record Item;
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment] [Ship-to Address] [Planning] [Requisition Worksheet] [Sales] [Purchase]
        // [SCENARIO 370342] "Ship-to Code" is updated in purchase order created from drop shipment sales order via requisition worksheet.
        Initialize();

        // [GIVEN] Item "I" with vendor no.
        CreateItemWithVendor(Item);

        // [GIVEN] Customer with ship-to address.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        // [GIVEN] Drop shipment sales order for item "I". Set "Ship-to Code" = "X".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);

        // [GIVEN] Open requisition worksheet and plan the sales order using "Get Sales Orders".
        GetSalesOrdersInRequisitionWorksheet(SalesLine);

        // [WHEN] Carry out action message to create a supplying purchase order.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [THEN] "Ship-to Code" on the purchase order = "X".
        PurchaseHeader.SetRange("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField("Ship-to Code", SalesHeader."Ship-to Code");
    end;

    [Test]
    procedure NextPhysInvtCountingPeriodWithBlankLastDate()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Phys. Invt. Counting Period] [UT]
        // [SCENARIO 420429] Next Phys. Invt. Counting Period is a current period when "Last Counting Period Update" is blank.
        Initialize();

        LibraryInventory.CreateItem(Item);

        Item.Validate("Phys Invt Counting Period Code", CreatePhysInvtCountingPeriod(12));

        Item.TestField("Next Counting Start Date", CalcDate('<-CM>', WorkDate()));
        Item.TestField("Next Counting End Date", CalcDate('<CM>', WorkDate()));
    end;

    [Test]
    procedure NextPhysInvtCountingPeriodWithNonBlankLastDate()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Phys. Invt. Counting Period] [UT]
        // [SCENARIO 420429] Next Phys. Invt. Counting Period is next period when "Last Counting Period Update" is not blank.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item."Last Counting Period Update" := WorkDate();

        Item.Validate("Phys Invt Counting Period Code", CreatePhysInvtCountingPeriod(12));

        Item.TestField("Next Counting Start Date", CalcDate('<CM + 1D>', WorkDate()));
        Item.TestField("Next Counting End Date", CalcDate('<CM + 1D + 1M - 1D>', WorkDate()));
    end;

    [Test]
    procedure NextPhysInvtCountingPeriodWithNoPreviousInvtAndCustomFreq()
    var
        Item: Record Item;
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
    begin
        // [FEATURE] [Phys. Invt. Counting Period] [UT]
        // [SCENARIO 420429] When counting frequency is 52 times/year and there are no next counting dates, the next Phys. Invt. Counting Period will start in a week from WORKDATE.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item."Last Counting Period Update" := WorkDate();
        Item."Phys Invt Counting Period Code" := CreatePhysInvtCountingPeriod(52);
        Item.Modify();

        PhysInvtCountManagement.CalcPeriod(
          Item."Last Counting Period Update", Item."Next Counting Start Date", Item."Next Counting End Date", 52);

        Item.TestField("Next Counting Start Date", CalcDate('<1W>', WorkDate()));
        Item.TestField("Next Counting End Date", CalcDate('<1W + 6D>', WorkDate()));
    end;

    [Test]
    procedure NextPhysInvtCountingPeriodWithCurrentLastDateAndCustomFreq()
    var
        Item: Record Item;
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
    begin
        // [FEATURE] [Phys. Invt. Counting Period] [UT]
        // [SCENARIO 420429] When counting frequency is 52 times/year and "Last Counting Period Update" = WorkDate(), the next Phys. Invt. Counting Period will start right after the current week.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item."Last Counting Period Update" := WorkDate();
        Item."Next Counting Start Date" := CalcDate('<-CW>', WorkDate());
        Item."Next Counting End Date" := CalcDate('<CW>', WorkDate());
        Item."Phys Invt Counting Period Code" := CreatePhysInvtCountingPeriod(52);
        Item.Modify();

        PhysInvtCountManagement.CalcPeriod(
          Item."Last Counting Period Update", Item."Next Counting Start Date", Item."Next Counting End Date", 52);

        Item.TestField("Next Counting Start Date", CalcDate('<CW + 1D>', WorkDate()));
        Item.TestField("Next Counting End Date", CalcDate('<CW + 7D>', WorkDate()));
    end;

    [Test]
    procedure NextPhysInvtCountingPeriodWithPastLastDateAndCustomFreq()
    var
        Item: Record Item;
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
    begin
        // [FEATURE] [Phys. Invt. Counting Period] [UT]
        // [SCENARIO 420429] When counting frequency is 52 times/year and "Last Counting Period Update is a past date, the next Phys. Invt. Counting Period will start in a week from that past date.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item."Last Counting Period Update" := CalcDate('<-2M>', WorkDate());
        Item."Next Counting Start Date" := CalcDate('<-CW>', WorkDate());
        Item."Next Counting End Date" := CalcDate('<CW>', WorkDate());
        Item."Phys Invt Counting Period Code" := CreatePhysInvtCountingPeriod(52);
        Item.Modify();

        PhysInvtCountManagement.CalcPeriod(
          Item."Last Counting Period Update", Item."Next Counting Start Date", Item."Next Counting End Date", 52);

        Item.TestField("Next Counting Start Date", CalcDate('<1W>', Item."Last Counting Period Update"));
        Item.TestField("Next Counting End Date", CalcDate('<1W + 6D>', Item."Last Counting Period Update"));
    end;

    [Test]
    procedure NextPhysInvtCountingPeriodWithFutureDateAndCustomFreq()
    var
        Item: Record Item;
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
    begin
        // [FEATURE] [Phys. Invt. Counting Period] [UT]
        // [SCENARIO 420429] When counting frequency is 52 times/year and "Last Counting Period Update is a future date and the existing counting period starts from Tuesday (for example), the next counting period will start next Tuesday from that future date.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item."Last Counting Period Update" := CalcDate('<WD4 + 4W>', WorkDate());
        Item."Next Counting Start Date" := CalcDate('<WD2>', WorkDate());
        Item."Next Counting End Date" := CalcDate('<WD2 + 6D>', WorkDate());
        Item."Phys Invt Counting Period Code" := CreatePhysInvtCountingPeriod(52);
        Item.Modify();

        PhysInvtCountManagement.CalcPeriod(
          Item."Last Counting Period Update", Item."Next Counting Start Date", Item."Next Counting End Date", 52);

        Item.TestField("Next Counting Start Date", CalcDate('<WD2>', Item."Last Counting Period Update"));
        Item.TestField("Next Counting End Date", CalcDate('<WD2 + 6D>', Item."Last Counting Period Update"));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PriceListLine: Record "Price List Line";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Misc. IV");

        LibraryVariableStorage.Clear();
        PriceListLine.DeleteAll();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Misc. IV");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Misc. IV");
    end;

    local procedure SetupTransferQuantities(var TransferQuantity: Decimal; var InventoryQuantity: Decimal; var ToShipQuantity: Decimal; var ToReceiveQuantity: Decimal)
    begin
        ToReceiveQuantity := LibraryRandom.RandIntInRange(10, 100);
        ToShipQuantity := ToReceiveQuantity + LibraryRandom.RandIntInRange(10, 100);
        TransferQuantity := ToShipQuantity + LibraryRandom.RandIntInRange(10, 100);
        InventoryQuantity := TransferQuantity + LibraryRandom.RandIntInRange(10, 100);
    end;

    local procedure CreatePurchaseOrderLineWithItemVariant(var PurchaseLine: Record "Purchase Line"; ItemVariant: Record "Item Variant"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo,
          ItemVariant."Item No.", LibraryRandom.RandIntInRange(10, 20), '', WorkDate());
        PurchaseLine.Validate("Variant Code", ItemVariant.Code);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrderLineWithItemVariant(var SalesLine: Record "Sales Line"; ItemVariant: Record "Item Variant"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo,
          ItemVariant."Item No.", LibraryRandom.RandIntInRange(10, 20), '', WorkDate());
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateJobTask(var JobTask: Record "Job Task"): Code[20]
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        exit(Job."Bill-to Customer No.");
    end;

    local procedure CreateJobPlanningLineWithItemVariant(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; ItemVariant: Record "Item Variant")
    begin
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ItemVariant."Item No.");
        JobPlanningLine.Validate("Variant Code", ItemVariant.Code);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandIntInRange(10, 20));
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobJournalLineWithItemVariant(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; ItemVariant: Record "Item Variant")
    begin
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::"Both Budget and Billable", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", ItemVariant."Item No.");
        JobJournalLine.Validate("Variant Code", ItemVariant.Code);
        JobJournalLine.Validate(Quantity, LibraryRandom.RandIntInRange(10, 20));
        JobJournalLine.Modify(true);
    end;

    local procedure CreateZeroForVariantPurchaseLineDiscount(ItemVariant: Record "Item Variant"; VendorNo: Code[20])
    var
        ItemBlankVariantPurchaseLineDiscount: Record "Purchase Line Discount";
        ItemWithVariantPurchaseLineDiscount: Record "Purchase Line Discount";
    begin
        LibraryERM.CreateLineDiscForVendor(
          ItemBlankVariantPurchaseLineDiscount, ItemVariant."Item No.", VendorNo, WorkDate(), '', '', '', 0);
        ItemBlankVariantPurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 20));
        ItemBlankVariantPurchaseLineDiscount.Modify(true);
        LibraryERM.CreateLineDiscForVendor(
          ItemWithVariantPurchaseLineDiscount, ItemVariant."Item No.", VendorNo, WorkDate(), '', ItemVariant.Code, '', 0);
    end;

    local procedure CreateZeroForVariantSalesLineDiscount(ItemVariant: Record "Item Variant"; CustomerNo: Code[20])
    var
        ItemBlankVariantSalesLineDiscount: Record "Sales Line Discount";
        ItemWithVariantSalesLineDiscount: Record "Sales Line Discount";
    begin
        LibraryERM.CreateLineDiscForCustomer(
          ItemBlankVariantSalesLineDiscount, ItemBlankVariantSalesLineDiscount.Type::Item, ItemVariant."Item No.",
          ItemBlankVariantSalesLineDiscount."Sales Type"::Customer, CustomerNo, WorkDate(), '', '', '', 0);
        ItemBlankVariantSalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 20));
        ItemBlankVariantSalesLineDiscount.Modify(true);

        LibraryERM.CreateLineDiscForCustomer(
          ItemWithVariantSalesLineDiscount, ItemWithVariantSalesLineDiscount.Type::Item, ItemVariant."Item No.",
          ItemWithVariantSalesLineDiscount."Sales Type"::Customer, CustomerNo, WorkDate(), '', ItemVariant.Code, '', 0);
    end;

    local procedure AcceptAndCarryOutActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure AcceptOrderPromising(var RequisitionLine: Record "Requisition Line"; var OrderPromisingLine: Record "Order Promising Line"; var SalesHeader: Record "Sales Header")
    var
        AvailabilityMgt: Codeunit AvailabilityManagement;
    begin
        AvailabilityMgt.UpdateSource(OrderPromisingLine);
        RequisitionLine.SetCurrentKey("Order Promising ID", "Order Promising Line ID", "Order Promising Line No.");
        RequisitionLine.SetRange("Order Promising ID", SalesHeader."No.");
        RequisitionLine.ModifyAll("Accept Action Message", true);
        RequisitionLine.FindFirst();
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Invoice: Boolean): Code[20]
    begin
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, ItemNo, '', CreateVendor(), LibraryRandom.RandInt(10), WorkDate());
        exit(PostPurchaseDocument(PurchaseLine, Invoice));
    end;

    local procedure CalculateRegPlanAndCarryOutActionMsg(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Planning);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        AcceptAndCarryOutActionMessage(ItemNo);
    end;

    local procedure CreateAndModifyItem(VendorNo: Code[20]; FlushingMethod: Enum "Flushing Method"; ReplenishmentSystem: Enum "Replenishment System"): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem());
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Vendor No.", VendorNo);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndModifyVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendor());
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; No: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, No, 1);  // Use blank value for Version Code and 1 for Quantity per.
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndUpdateOrderPromisingLine(var OrderPromisingLine: Record "Order Promising Line"; var SalesHeader: Record "Sales Header")
    var
        AvailabilityMgt: Codeunit AvailabilityManagement;
    begin
        AvailabilityMgt.SetSourceRecord(OrderPromisingLine, SalesHeader);
        AvailabilityMgt.CalcCapableToPromise(OrderPromisingLine, SalesHeader."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateLocationsChain(var FromLocation: Record Location; var ToLocation: Record Location; var TransitLocation: Record Location)
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, FromLocation.Code, ToLocation.Code, TransitLocation.Code, '', '');
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandIntInRange(10, 20));
        Item.Validate("Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithInventory(var Item: Record Item; LocationCode: Code[10]; InventoryQuantity: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        UpdateInventory(Item."No.", LocationCode, InventoryQuantity);
    end;

    local procedure CreateItemInTransferOrder(var Item: Record Item; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; InventoryQuantity: Decimal; TransferQuantity: Decimal; ToShipQuantity: Decimal)
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
    begin
        CreateLocationsChain(FromLocation, ToLocation, TransitLocation);
        CreateItemWithInventory(Item, FromLocation.Code, InventoryQuantity);
        CreateTransferOrder(
          TransferHeader, TransferLine, Item."No.", FromLocation.Code, ToLocation.Code, TransitLocation.Code, TransferQuantity);
        UpdateTransferLineQtyToShip(TransferLine, ToShipQuantity);
    end;

    local procedure CreateItemInPartlyShippedTransferOrder(var Item: Record Item; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; InventoryQuantity: Decimal; TransferQuantity: Decimal; ToShipQuantity: Decimal)
    begin
        CreateItemInTransferOrder(Item, TransferHeader, TransferLine, InventoryQuantity, TransferQuantity, ToShipQuantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
    end;

    local procedure CreateItemInPartlyReceivedTransferOrder(var Item: Record Item; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; InventoryQuantity: Decimal; TransferQuantity: Decimal; ToShipQuantity: Decimal; ToReceiveQuantity: Decimal)
    begin
        CreateItemInPartlyShippedTransferOrder(Item, TransferHeader, TransferLine, InventoryQuantity, TransferQuantity, ToShipQuantity);
        UpdateTransferLineQtyToReceive(TransferLine, ToReceiveQuantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);
    end;

    local procedure CreateItemReference(var ItemReference: Record "Item Reference"; ItemNo: Code[20]; VendorNo: Code[20])
    var
        StrLen: Integer;
    begin
        StrLen := MaxStrLen(ItemReference.Description);
        LibraryItemReference.CreateItemReference(ItemReference, ItemNo, ItemReference."Reference Type"::Vendor, VendorNo);
        ItemReference.Description := CopyStr(LibraryUtility.GenerateRandomText(StrLen), 1, StrLen);
        ItemReference.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, 10 + LibraryRandom.RandInt(10)); // Use random Quantity.
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2)); // Using Random value for Unit Cost.
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreatePositiveAdjmtItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemWithVendor(var Item: Record Item)
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Item.Get(CreateAndModifyItem(Vendor."No.", Item."Flushing Method"::Backward, Item."Replenishment System"::Purchase));
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);
    end;

    local procedure CreateOutputJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; ProductionOrderNo: Code[20]; OperationNo: Code[10]; OutputQuantity: Decimal; AppliesToEntry: Integer)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Output);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProductionOrderNo);
        ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Applies-to Entry", AppliesToEntry);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreatePhysInvtCountingPeriod(CountFrequency: Integer): Code[10]
    var
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
    begin
        LibraryInventory.CreatePhysicalInventoryCountingPeriod(PhysInvtCountingPeriod);
        PhysInvtCountingPeriod.Validate("Count Frequency per Year", CountFrequency);
        PhysInvtCountingPeriod.Modify(true);
        exit(PhysInvtCountingPeriod.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; VariantCode: Code[10]; VendorNo: Code[20]; Quantity: Decimal; OrderDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Order Date", OrderDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);

        // Update 'Invt. Accrual Acc. (Interim)' in General Posting Setup.
        LibraryERM.FindGLAccount(GLAccount);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);  // Taking Random Quantity.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineDiscount(var PurchaseLineDiscount: Record "Purchase Line Discount")
    begin
        LibraryERM.CreateLineDiscForVendor(
          PurchaseLineDiscount, CreateItem(), CreateVendor(), WorkDate(), '', '', '', LibraryRandom.RandDec(10, 2));  // Take random for Quantity.
        PurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));  // Take random for Line Discount Pct.
        PurchaseLineDiscount.Modify(true);
    end;

    local procedure CreatePurchasePrice(var PurchasePrice: Record "Purchase Price"; VendorNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryCosting.CreatePurchasePrice(
          PurchasePrice, VendorNo, ItemNo, 0D, '', '', '', 0);  // Take random for Quantity.
        PurchasePrice.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // take random for Direct Unit Cost.
        PurchasePrice.Modify(true);
    end;

    local procedure CreatePurchasePrice(var PurchasePrice: Record "Purchase Price"; CurrencyCode: Code[10]; VendorNo: Code[20]; StartingDate: Date)
    var
        Item: Record Item;
        ItemNo: Code[20];
    begin
        ItemNo := CreateAndModifyItem(VendorNo, Item."Flushing Method"::"Pick + Manual", Item."Replenishment System"::Purchase);
        LibraryCosting.CreatePurchasePrice(
          PurchasePrice, VendorNo, ItemNo, StartingDate, CurrencyCode, '', '', LibraryRandom.RandDec(10, 2));  // Take random for Quantity.
        PurchasePrice.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // take random for Direct Unit Cost.
        PurchasePrice.Modify(true);
    end;

    local procedure CreateRoutingSetup(WorkCenterNo: Code[20]; RoutingLinkCode: Code[10]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));  // Take random for Unit Price.
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithItemAndLocation(var SalesHeader: Record "Sales Header"; var Location: Record Location; var Item: Record Item)
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryWarehouse.CreateLocation(Location);

        CreateItemWithVendor(Item);

        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.", '', LibraryRandom.RandInt(100));
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; TransitLocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, TransitLocationCode);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Receipt Date", WorkDate());
        TransferLine.Modify(true);
    end;

    local procedure ItemAvailabilityFormsMgtCalculateNeed(var Item: Record Item; var GrossRequirement: Decimal; var PlannedOrderReceipt: Decimal; var ScheduledReceipt: Decimal; var PlannedOrderReleases: Decimal; LocationFilter: Text)
    var
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
    begin
        Item.Init();
        Item.SetFilter("Location Filter", LocationFilter);
        ItemAvailabilityFormsMgt.CalculateNeed(Item, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases);
    end;

    local procedure ItemAvailabilityFormsMgtShowItemAvailLineList(var Item: Record Item; LocationFilter: Text)
    var
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
    begin
        Item.Init();
        Item.SetRange("Date Filter", WorkDate());
        Item.SetFilter("Location Filter", LocationFilter);
        ItemAvailabilityFormsMgt.ShowItemAvailLineList(Item, 4);
    end;

    local procedure FindAndUpdateProdCompLine(ProductionOrder: Record "Production Order"; VariantCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Variant Code", VariantCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure FindCapacityLedgerEntry(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; OrderNo: Code[20])
    begin
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", OrderNo);
        CapacityLedgerEntry.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; OrderNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", OrderNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; DocumentNo: Code[20])
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();
    end;

    local procedure GetNextCountingPeriod(Item: Record Item; var NextCountingStartDate: Date; var NextCountingEndDate: Date)
    var
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
    begin
        PhysInvtCountingPeriod.Get(Item."Phys Invt Counting Period Code");
        PhysInvtCountManagement.CalcPeriod(
          Item."Last Counting Period Update", NextCountingStartDate, NextCountingEndDate,
          PhysInvtCountingPeriod."Count Frequency per Year");
    end;

    local procedure GetOperationNo(OrderNo: Code[20]): Code[10]
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        FindCapacityLedgerEntry(CapacityLedgerEntry, OrderNo);
        exit(CapacityLedgerEntry."Operation No.");
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure GetPostedDocumentLines(No: Code[20])
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", No);
        SalesCreditMemo.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetSalesOrdersInRequisitionWorksheet(SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, LibraryPlanning.SelectRequisitionTemplateName());
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, 0);
    end;

    local procedure InventorySetupEnqueues()
    begin
        LibraryVariableStorage.Enqueue(UpdateAutomaticCostMessage);
        LibraryVariableStorage.Enqueue(UpdateExpCostConfMessage);
        LibraryVariableStorage.Enqueue(UpdateExpCostMessage);
        LibraryVariableStorage.Enqueue(UpdateAutomaticCostPeriodMessage);
    end;

    local procedure PostPurchaseDocument(PurchaseLine: Record "Purchase Line"; Invoice: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice));
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure SetupForPostOutputJournal(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Create Finished Item.
        Item.Get(CreateAndModifyItem('', Item."Flushing Method"::Backward, Item."Replenishment System"::"Prod. Order")); // Finished Item.

        // Update BOM and Routing on Item, create and post two Purchase Order with different 'Unit Cost'.
        UpdateItemWithCertifiedBOMAndRouting(Item, ItemNo);
        CreateAndPostPurchaseOrder(PurchaseLine, ItemNo, true);

        CreatePurchaseDocument(
          PurchaseLine2, PurchaseLine2."Document Type"::Order, PurchaseLine."No.", '', CreateVendor(), LibraryRandom.RandInt(10),
          WorkDate());  // Used Rnadom for Quantity.
        PurchaseLine2.Validate("Direct Unit Cost", (PurchaseLine2."Direct Unit Cost" + LibraryRandom.RandInt(10)));  // 'Direct Unit Cost' required more than previous Purchase Order.
        PurchaseLine2.Modify(true);
        PostPurchaseDocument(PurchaseLine2, true);

        // Create Released Production Order and create Output Journal, Explode Routing and Post.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(10));   // Used Random Int for Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        CreateOutputJournal(ItemJournalLine, Item."No.", ProductionOrder."No.", '', 0, 0);  // 0s are used for 'Output Quantity' and 'Apply to Entry'.
        CODEUNIT.Run(CODEUNIT::"Output Jnl.-Expl. Route", ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateItemWithCertifiedBOMAndRouting(var Item: Record Item; ItemNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
    begin
        RoutingLink.FindFirst();
        WorkCenter.FindFirst();

        // Create Production BOM with Raouting Link Code.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item."Base Unit of Measure", ItemNo, RoutingLink.Code);

        // Update Item with Prodouction BOM No. and Routing No.
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Routing No.", CreateRoutingSetup(WorkCenter."No.", RoutingLink.Code));
        Item.Modify(true);
    end;

    local procedure UpdateLineDiscOnPurchLineDisc(PurchaseLineDiscount: Record "Purchase Line Discount"): Decimal
    begin
        PurchaseLineDiscount.Validate("Line Discount %", PurchaseLineDiscount."Line Discount %" + LibraryRandom.RandDec(10, 2));  // Take random to update Line Discount Pct.
        PurchaseLineDiscount.Modify(true);
        exit(PurchaseLineDiscount."Line Discount %");
    end;

    local procedure UpdatePhysInvCountingPeriodOnItem(var Item: Record Item; CountFrequency: Integer)
    begin
        Item.Get(CreateItem());
        Item.Validate("Phys Invt Counting Period Code", CreatePhysInvtCountingPeriod(CountFrequency));
        Item.Modify(true);
    end;

    local procedure UpdatePurchLineQtyForPartialPost(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Qty. to Receive" / 2);
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice" / 2);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateUnitCostOnPurchasePrice(PurchasePrice: Record "Purchase Price"): Decimal
    begin
        PurchasePrice.Validate("Direct Unit Cost", PurchasePrice."Direct Unit Cost" + LibraryRandom.RandDec(10, 2));  // Take random value to update Direct Unit Cost.
        PurchasePrice.Modify(true);
        exit(PurchasePrice."Direct Unit Cost");
    end;

    local procedure UpdateInventory(ItemNo: Code[20]; LocationCode: Code[10]; Quantuty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreatePositiveAdjmtItemJournalLine(ItemJournalLine, ItemNo, LocationCode, Quantuty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateTransferLineQtyToShip(var TransferLine: Record "Transfer Line"; ToShipQuantity: Decimal)
    begin
        TransferLine.Validate("Qty. to Ship", ToShipQuantity);
        TransferLine.Modify(true);
    end;

    local procedure UpdateTransferLineQtyToReceive(var TransferLine: Record "Transfer Line"; ToReceiveQuantity: Decimal)
    begin
        TransferLine.Find();
        TransferLine.Validate("Qty. to Receive", ToReceiveQuantity);
        TransferLine.Modify(true);
    end;

    local procedure VerifyDescriptionsOnRequisitionLine(ItemNo: Code[20]; Desc: Text; Desc2: Text)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Description, Desc);
        RequisitionLine.TestField("Description 2", Desc2);
    end;

    local procedure VerifyGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal; GenPostingType: Enum "General Posting Type")
    var
        GLEntry: Record "G/L Entry";
        ActualAmount: Decimal;
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.FindSet();
        repeat
            ActualAmount := GLEntry.Amount;
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(Amount, ActualAmount, LibraryERM.GetAmountRoundingPrecision(), AmountError);
    end;

    local procedure VerifyPstdPurchaseInvoice(DocumentNo: Code[20]; DirectUnitCost: Decimal; LineDiscountPct: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("Direct Unit Cost", DirectUnitCost);
        PurchInvLine.TestField("Line Discount %", LineDiscountPct);
    end;

    local procedure VerifyValueEntry(ItemLedgerEntryType: Enum "Item Ledger Entry Type"; DocumentNo: Code[20]; ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, ItemLedgerEntryType, DocumentNo);
        ValueEntry.TestField("Item No.", ItemNo);
    end;

    local procedure VerifyItemPlanningFields(var Item: Record Item; InventoryExpected: Decimal; QtyInTransitExpected: Decimal; TransOrdShipmentQtyExpected: Decimal; TransOrdReceiptQtyExpected: Decimal)
    begin
        Item.TestField(Inventory, InventoryExpected);
        Item.TestField("Qty. in Transit", QtyInTransitExpected);
        Item.TestField("Trans. Ord. Shipment (Qty.)", TransOrdShipmentQtyExpected);
        Item.TestField("Trans. Ord. Receipt (Qty.)", TransOrdReceiptQtyExpected);
    end;

    local procedure VerifyCalculatedNeed(ExpectedGrossRequirement: Decimal; ExpectedScheduledReceipt: Decimal; ActualGrossRequirement: Decimal; ActualPlannedOrderReceipt: Decimal; ActualScheduledReceipt: Decimal; ActualPlannedOrderReleases: Decimal)
    begin
        Assert.AreEqual(
          ExpectedGrossRequirement, ActualGrossRequirement, StrSubstNo(CalculateNeedVARParameterOutputValueErr, 'GrossRequirement'));
        Assert.AreEqual(0, ActualPlannedOrderReceipt, StrSubstNo(CalculateNeedVARParameterOutputValueErr, 'PlannedOrderReceipt'));
        Assert.AreEqual(
          ExpectedScheduledReceipt, ActualScheduledReceipt, StrSubstNo(CalculateNeedVARParameterOutputValueErr, 'ScheduledReceipt'));
        Assert.AreEqual(0, ActualPlannedOrderReleases, StrSubstNo(CalculateNeedVARParameterOutputValueErr, 'PlannedOrderReleases'));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityLineListHandler(var ItemAvailabilityLineList: TestPage "Item Availability Line List")
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SentNotificationHandler(var Notification: Notification): Boolean;
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;
}
