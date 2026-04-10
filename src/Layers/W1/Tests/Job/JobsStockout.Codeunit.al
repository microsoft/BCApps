codeunit 136134 "Jobs Stockout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Availability] [Job]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        DescriptionTxt: Label 'NTF_TEST_NTF_TEST';
        ValidateQuantityDocumentErr: Label 'DocNo %1 not found in following objects: Project.';
        ReceiptDateDocumentErr: Label 'No Purchase Line found with sales order no %1.';
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJob: Codeunit "Library - Job";
        JobPlanningLines: TestPage "Job Planning Lines";
        IsInitialized: Boolean;
        ZeroQuantity: Integer;
        PlanningLineQuantity: Integer;
        QuantityToSet: Integer;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Jobs Stockout");
        // Clear the needed globals
        ClearGlobals();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Jobs Stockout");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Jobs Stockout");
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure JobDemandHigherThanSupply()
    var
        TempNotificationContext: Record "Notification Context" temporary;
        JobPlanningLine: Record "Job Planning Line";
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        JobNo: Code[20];
        PurchaseOrderNo: Code[20];
        PurchaseQuantity: Integer;
        NbNotifs: Integer;
    begin
        // Test availability warning for Job Demand higher than Supply.

        // SETUP: Create Supply with Purchase Order for Item X, Quantity = Y.
        // SETUP: Create Job Planning Line Demand for Item X,with zero quantity
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10);
        PlanningLineQuantity := PurchaseQuantity + 1;
        CreateItem(Item);
        PurchaseOrderNo := CreatePurchaseSupply(Item."No.", PurchaseQuantity);
        JobNo := CreateJobDemandAfter(Item."No.", PurchaseQuantity + 5, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Open the Job Planning Lines Card.
        // EXECUTE: Change Demand Quantity on Job Planning Line Through UI to Quantity = Y + 1.
        // EXECUTE: (Quantity Change set in EditJobPlanningLinesQuantity).
        EditJobPlaningLinesQuantity(JobNo, PlanningLineQuantity);

        // VERIFY: that quantity change is reflected when availability warning is ignored
        ValidateQuantity(JobNo, PlanningLineQuantity);

        // WHEN we decrease the quantity so the item is available (0 items ordered)
        NotificationLifecycleMgt.GetTmpNotificationContext(TempNotificationContext);
        NbNotifs := TempNotificationContext.Count();
        EditJobPlaningLinesQuantity(JobNo, 0);

        // THEN the item availability notification is recalled
        Assert.AreEqual(NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after decreasing Quantity.');

        // WHEN we change the planning line type
        EditJobPlaningLinesQuantity(JobNo, PlanningLineQuantity);
        Assert.AreEqual(NbNotifs, TempNotificationContext.Count, 'Unexpected number of notifications after increasing Quantity.');
        EditJobPlanningLinesType(JobNo, Format(JobPlanningLine.Type::Resource));

        // THEN the item availability notification is recalled
        Assert.AreEqual(
          NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after changing Type to Resource.');

        // WHEN we change the planning line "Line type"
        // first, setup everything back so we have a notification
        EditJobPlanningLinesType(JobNo, Format(JobPlanningLine.Type::Item));
        EditJobPlanningLinesNo(JobNo, Item."No.");
        EditJobPlaningLinesQuantity(JobNo, PlanningLineQuantity);
        Assert.AreEqual(
          NbNotifs, TempNotificationContext.Count,
          'Unexpected number of notifications after changing Type back to item with high demand.');
        // change the planning line "Line type"
        EditJobPlanningLinesLineType(JobNo, Format(JobPlanningLine."Line Type"::Billable));

        // THEN the item availability notification is recalled
        Assert.AreEqual(
          NbNotifs - 1, TempNotificationContext.Count, 'Unexpected number of notifications after changing Line type to Billable.');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobDemandLowerThanSupply()
    var
        Item: Record Item;
        JobNo: Code[20];
        PurchaseOrderNo: Code[20];
        PurchaseQuantity: Integer;
    begin
        // Test supply cover Job Planning Line demand and therefore no warning.

        // SETUP: Create Supply for Item X.
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10);
        CreateItem(Item);
        PurchaseOrderNo := CreatePurchaseSupply(Item."No.", PurchaseQuantity);
        JobNo := CreateJobDemandAfter(Item."No.", ZeroQuantity, GetReceiptDate(PurchaseOrderNo));
        PlanningLineQuantity := PurchaseQuantity - 1;

        // EXECUTE: Open the Job Planning Lines Card.
        // EXECUTE: Create Job Plannnig Line Demand for Item X at a date after Supply is arrived and quantity less than supply
        EditJobPlaningLinesQuantity(JobNo, PlanningLineQuantity);

        // VERIFY: Quantity is not changed. Availability warning is not displayed.
        ValidateQuantity(JobNo, PlanningLineQuantity);
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure JobDemandBeforeSupplyArrive()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        JobNo: Code[20];
        PurchaseQuantity: Integer;
    begin
        // Test availability warning if Job Demand is at a date before Supply arrives.

        // SETUP: Create Job Planning Line Demand for Item X,with zero quantity.
        // SETUP: Create Supply with Purchase Order for Item X, Qantity=Y, at a date after Job Demand.
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10) * 2;  // Taking Minimum Value as 2 as the Sale Quantity should not be zero.
        PlanningLineQuantity := PurchaseQuantity - 1;
        CreateItem(Item);
        JobNo := CreateJobDemand(Item."No.", PurchaseQuantity - 5);
        CreatePurchaseSupplyAfter(Item."No.", PurchaseQuantity, GetPlanningDate(JobNo));

        // EXECUTE: Open the Job Planning Lines Card.
        // EXECUTE: Change Demand Quantity on Job Planning Line Through UI to Quantity = Y - 1.
        // EXECUTE: (Quantity Change set in EditJobPlanningLinesQuantity).
        EditJobPlaningLinesQuantity(JobNo, PlanningLineQuantity);

        // VERIFY: Quantity on Job Planning Line after warning is Y - 1.
        ValidateQuantity(JobNo, PlanningLineQuantity);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure JobLocationDifferentFromSupply()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        JobNo: Code[20];
        LocationA: Code[10];
        LocationB: Code[10];
        PurchaseOrderNo: Code[20];
        PurchaseQuantity: Integer;
    begin
        // Test availability warning if Job Demand is at a different Location than a supply from purchase.

        // SETUP: Create Supply with Purchase Order for Item X, Qantity=Y, Location = Z.
        // SETUP: Create Job Planning Line Demand for Item X, Quantity=0, Location = M.
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10) * 2;  // Taking Minimum Value as 2 as the Sale Quantity should not be zero.
        PlanningLineQuantity := PurchaseQuantity - 1;
        CreateItem(Item);
        LocationA := CreateLocation();
        LocationB := CreateLocation();
        PurchaseOrderNo := CreatePurchaseSupplyAtLocation(Item."No.", PurchaseQuantity, LocationA);
        JobNo := CreateJobDemandLocationAfter(Item."No.", PurchaseQuantity - 5, LocationB, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Open the Job Planning Lines Card.
        // EXECUTE: Change Demand Quantity on Job Planning Line Through UI to Quantity = Y - 1.
        // EXECUTE: (Quantity Change set in EditJobPlanningLinesQuantity).
        EditJobPlaningLinesQuantity(JobNo, PlanningLineQuantity);

        // VERIFY: Verify Quantity on Job Planning Line after warning is Y - 1.
        ValidateQuantity(JobNo, PlanningLineQuantity);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendAvailabilityNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure JobChangeDate()
    var
        Item: Record Item;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        JobNo: Code[20];
        PurchaseOrderNo: Code[20];
        PurchaseQuantity: Integer;
    begin
        // Test availability warning if the date of Job Demand is modified to a date where demand cannot be met

        // SETUP: Create Supply with Purchase Order for Item X, Qantity=Y, Date = Workdate.
        // SETUP: Create Job Planning Line Demand for Item X, Quantity=Y, Date = WorkDate() + 1
        Initialize();
        PurchaseQuantity := LibraryRandom.RandInt(10);
        CreateItem(Item);
        JobNo := CreateJobDemand(Item."No.", PurchaseQuantity);
        PurchaseOrderNo := CreatePurchaseSupplyAfter(Item."No.", PurchaseQuantity, GetPlanningDate(JobNo));
        JobNo := CreateJobDemandAfter(Item."No.", PurchaseQuantity, GetReceiptDate(PurchaseOrderNo));

        // EXECUTE: Open the Job Planning Lines Card.
        // EXECUTE: Change Date on Job Planning Line Through UI to Date = WorkDate() - 1.
        // EXECUTE: (Date Change set in EditJobPlanningLinesDate).
        QuantityToSet := PurchaseQuantity;
        EditJobPlaningLinesPlanDate(JobNo);

        // VERIFY: Quantity on Job Planning Line after warning is Y and Date is WorkDate() - 1.
        ValidateQuantity(JobNo, QuantityToSet);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure ClearGlobals()
    begin
        // Clear all global variables
        ZeroQuantity := 0;
        Clear(JobPlanningLines);
        PlanningLineQuantity := 0;
        QuantityToSet := 0;
    end;

    local procedure CreateJobDemandAtBasis(ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]; PlanDate: Date): Code[20]
    var
        Job: Record Job;
        JobTaskLine: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        DocNo: Code[20];
    begin
        // Create Job
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Validate("Description 2", DescriptionTxt);
        Job.Modify();

        // Job Task Line:
        LibraryJob.CreateJobTask(Job, JobTaskLine);
        JobTaskLine.Modify();

        // Job Planning Line:
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTaskLine, JobPlanningLine);

        JobPlanningLine.Validate("Planning Date", PlanDate);
        JobPlanningLine.Validate("Usage Link", true);

        DocNo := DelChr(Format(Today), '=', '-/') + '_' + DelChr(Format(Time), '=', ':');
        JobPlanningLine.Validate("Document No.", DocNo);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, ItemQuantity);
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Modify();

        exit(Job."No.");
    end;

    local procedure CreateJobDemand(ItemNo: Code[20]; Quantity: Integer): Code[20]
    begin
        exit(CreateJobDemandAtBasis(ItemNo, Quantity, '', WorkDate()));
    end;

    local procedure CreateJobDemandAfter(ItemNo: Code[20]; Quantity: Integer; PlanningDate: Date): Code[20]
    begin
        exit(CreateJobDemandAtBasis(ItemNo, Quantity, '', CalcDate('<+1D>', PlanningDate)));
    end;

    local procedure CreateJobDemandLocationAfter(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]; PlanningDate: Date): Code[20]
    begin
        exit(CreateJobDemandAtBasis(ItemNo, Quantity, LocationCode, CalcDate('<+1D>', PlanningDate)));
    end;

    [Normal]
    local procedure CreateItem(var Item: Record Item)
    begin
        // Creates a new item. Wrapper for the library method.
        LibraryInventory.CreateItem(Item);
    end;

    [Normal]
    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        // Creates a new Location. Wrapper for the library method.
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    local procedure CreatePurchaseSupplyBasis(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]; ReceiptDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Creates a Purchase order for the given item.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Expected Receipt Date", ReceiptDate);
        PurchaseLine.Modify();
        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseSupply(ItemNo: Code[20]; ItemQuantity: Integer): Code[20]
    begin
        // Creates a Purchase order for the given item.
        exit(CreatePurchaseSupplyBasis(ItemNo, ItemQuantity, '', WorkDate()));
    end;

    local procedure CreatePurchaseSupplyAtLocation(ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Code[20]
    begin
        // Creates a Purchase order for the given item at the specified location.
        exit(CreatePurchaseSupplyBasis(ItemNo, ItemQuantity, LocationCode, WorkDate()));
    end;

    local procedure CreatePurchaseSupplyAfter(ItemNo: Code[20]; Quantity: Integer; ReceiptDate: Date): Code[20]
    begin
        // Creates a Purchase order for the given item After a source document date.
        exit(CreatePurchaseSupplyBasis(ItemNo, Quantity, '', CalcDate('<+1D>', ReceiptDate)));
    end;

    local procedure GetReceiptDate(PurchaseHeaderNo: Code[20]): Date
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Method returns the receipt date from a purchase order.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeaderNo);
        PurchaseLine.FindFirst();
        if PurchaseLine.Count > 0 then
            exit(PurchaseLine."Expected Receipt Date");
        Error(ReceiptDateDocumentErr, PurchaseHeaderNo);
    end;

    local procedure GetPlanningDate(JobNo: Code[20]): Date
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Method returns the planning date from Job.
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.FindFirst();
        exit(JobPlanningLine."Planning Date");
    end;

    [Normal]
    local procedure OpenJobPlanningLines(var JobPlanningLinesToReturn: TestPage "Job Planning Lines"; JobNo: Code[20])
    var
        Job: Record Job;
        JobTaskLine: Record "Job Task";
    begin
        JobPlanningLinesToReturn.OpenEdit();
        if Job.Get(JobNo) then begin
            JobTaskLine.SetRange("Job No.", Job."No.");
            JobTaskLine.FindFirst();
            JobPlanningLinesToReturn.FILTER.SetFilter("Job No.", Job."No.");
            JobPlanningLinesToReturn.FILTER.SetFilter("Job Task No.", JobTaskLine."Job Task No.");
            JobPlanningLinesToReturn.First();
        end;
    end;

    [Normal]
    local procedure EditJobPlanningLinesNo(JobNo: Code[20]; PlanningLineNo: Code[20])
    var
        DummyJobPlanningLinesToEdit: TestPage "Job Planning Lines";
    begin
        // Open Job Planning Lines Page.
        // Change the line number (item number for example).
        OpenJobPlanningLines(DummyJobPlanningLinesToEdit, JobNo);
        JobPlanningLines := DummyJobPlanningLinesToEdit;
        DummyJobPlanningLinesToEdit."No.".SetValue(PlanningLineNo);
    end;

    [Normal]
    local procedure EditJobPlanningLinesLineType(JobNo: Code[20]; PlanningLineLineType: Text)
    var
        DummyJobPlanningLinesToEdit: TestPage "Job Planning Lines";
    begin
        // Open Job Planning Lines Page.
        // Change the line "Line Type".
        OpenJobPlanningLines(DummyJobPlanningLinesToEdit, JobNo);
        JobPlanningLines := DummyJobPlanningLinesToEdit;
        DummyJobPlanningLinesToEdit."Line Type".SetValue(PlanningLineLineType);
    end;

    [Normal]
    local procedure EditJobPlanningLinesType(JobNo: Code[20]; PlanningLineType: Text)
    var
        DummyJobPlanningLinesToEdit: TestPage "Job Planning Lines";
    begin
        // Open Job Planning Lines Page.
        // Change the line Type.
        OpenJobPlanningLines(DummyJobPlanningLinesToEdit, JobNo);
        JobPlanningLines := DummyJobPlanningLinesToEdit;
        DummyJobPlanningLinesToEdit.Type.SetValue(PlanningLineType);
    end;

    [Normal]
    local procedure EditJobPlaningLinesQuantity(JobNo: Code[20]; PlanningLineQuantity: Integer)
    var
        DummyJobPlanningLinesToEdit: TestPage "Job Planning Lines";
    begin
        // Open Job Planning Lines Page.
        // Change the line quantity.
        OpenJobPlanningLines(DummyJobPlanningLinesToEdit, JobNo);
        JobPlanningLines := DummyJobPlanningLinesToEdit;
        QuantityToSet := PlanningLineQuantity;
        DummyJobPlanningLinesToEdit.Quantity.SetValue(Format(QuantityToSet));
    end;

    [Normal]
    local procedure EditJobPlaningLinesPlanDate(JobNo: Code[20])
    var
        DummyJobPlanningLinesToEdit: TestPage "Job Planning Lines";
    begin
        // Open Job Planning Lines Page.
        // Change the line Planning Date.
        OpenJobPlanningLines(DummyJobPlanningLinesToEdit, JobNo);
        JobPlanningLines := DummyJobPlanningLinesToEdit;
        DummyJobPlanningLinesToEdit."Planning Date".SetValue(Format(WorkDate()));
    end;

    local procedure ValidateQuantity(DocumentNo: Code[20]; Quantity: Integer)
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
    begin
        // Method verifies the quantity on a Job.
        if Job.Get(DocumentNo) then begin
            JobPlanningLine.SetRange("Job No.", Job."No.");
            JobPlanningLine.FindFirst();
            Assert.AreEqual(Quantity, JobPlanningLine.Quantity, 'Verify Job Planning Line Quantity matches expected');
            exit;
        end;

        Error(ValidateQuantityDocumentErr, DocumentNo);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendAvailabilityNotificationHandler(var Notification: Notification): Boolean
    var
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        Quantity: Integer;
        Inventory: Decimal;
        TotalQuantity: Decimal;
        ReservedQty: Decimal;
        SchedRcpt: Decimal;
        ReservedRcpt: Decimal;
        GrossReq: Decimal;
        ReservedReq: Decimal;
    begin
        Item.Get(JobPlanningLines."No.".Value);
        Assert.AreEqual(Notification.GetData('ItemNo'), Item."No.", 'Item No. was different than expected');
        Item.CalcFields(Inventory);
        Evaluate(Inventory, Notification.GetData('InventoryQty'));
        Assert.AreEqual(Inventory, Item.Inventory, 'Available Inventory was different than expected');
        Evaluate(Quantity, Notification.GetData('CurrentQuantity'));
        Evaluate(TotalQuantity, Notification.GetData('TotalQuantity'));
        Evaluate(ReservedQty, Notification.GetData('CurrentReservedQty'));
        Evaluate(ReservedReq, Notification.GetData('ReservedReq'));
        Evaluate(SchedRcpt, Notification.GetData('SchedRcpt'));
        Evaluate(GrossReq, Notification.GetData('GrossReq'));
        Evaluate(ReservedRcpt, Notification.GetData('ReservedRcpt'));
        Assert.AreEqual(TotalQuantity, Inventory - Quantity + (SchedRcpt - ReservedRcpt) - (GrossReq - ReservedReq),
          'Total quantity different than expected');
        Assert.AreEqual(Quantity, QuantityToSet, 'Quantity was different than expected');
        ItemCheckAvail.ShowNotificationDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NotificationDetailsHandler(var ItemAvailabilityCheck: TestPage "Item Availability Check")
    var
        Item: Record Item;
    begin
        Item.Get(JobPlanningLines."No.".Value);
        Item.CalcFields(Inventory);
        ItemAvailabilityCheck.AvailabilityCheckDetails."No.".AssertEquals(Item."No.");
        ItemAvailabilityCheck.AvailabilityCheckDetails.Description.AssertEquals(Item.Description);
        ItemAvailabilityCheck.AvailabilityCheckDetails.CurrentQuantity.AssertEquals(QuantityToSet);
        ItemAvailabilityCheck.InventoryQty.AssertEquals(Item.Inventory);
    end;
}

