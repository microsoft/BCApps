codeunit 135415 "Reserv. & Order Promising E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [User Group Plan] [Return Order] [Reserve]
    end;

    var
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTemplates: Codeunit "Library - Templates";
        isInitialized: Boolean;
        PlannedDeliveryDateErr: Label 'Incorrect Planned Delivery Date on Order Promising Line.';
        EarliestShipmentDateErr: Label 'Incorrect Earliest Shipment Date on Order Promising Line.';
        TeamMemberErr: Label 'You are logged in as a Team Member role, so you cannot complete this task.';

    [Test]
    [HandlerFunctions('StrMenuHandler,ReservationModalPageHandler,SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,OrderPromisingLinesModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateReservationAndOrderPromisingAsBusinessManager()
    var
        SalesOrder: TestPage "Sales Order";
        ItemNo: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
        PurchaseOrderNo: Code[20];
        InitialSalesOrderNo: Code[20];
    begin
        // [SCENARIO] Create a purchase return order as Business Manager
        Initialize();

        // [GIVEN] A posted purchase invoice
        VendorNo := CreateVendor();
        CustomerNo := CreateCustomer();
        ItemNo := CreateItem();
        CreateAndPostPurchaseInvoice(VendorNo, ItemNo, 7);

        // Set plan to Business Manager
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [WHEN] Create a purchase order from existing vendor
        PurchaseOrderNo := CreatePurchaseOrder(VendorNo, ItemNo, 13, WorkDate());

        // [WHEN] Create a new sales order and select reserve
        InitialSalesOrderNo := CreateAndReserveSalesOrder(SalesOrder, CustomerNo, ItemNo, 12, CalcDate('<+2W>', WorkDate()));
        // [THEN] Quantity is reserved
        Assert.AreEqual('12', SalesOrder.SalesLines."Reserved Quantity".Value, '');

        // [WHEN] Use Available to Promise to give customer the expected delivery date
        CalculateAvailableToPromise(SalesOrder);

        // [THEN] Dates have been automatically calculated and filled in
        VerifyOrderPromisingLines();

        // [WHEN] Post the purchase order (as received or received and invoiced),
        // So now the inventory is in stock and we can ship to the customer
        PostPurchaseOrder(PurchaseOrderNo);

        // [WHEN] Create a new sales order and select reserve
        CreateAndReserveSalesOrder(SalesOrder, CustomerNo, ItemNo, 15, CalcDate('<+4W>', WorkDate()));

        // [THEN] You can only reserve 8 pcs, 12 of 20 available items are already reserved.
        Assert.AreEqual('8', SalesOrder.SalesLines."Reserved Quantity".Value, '');

        // [THEN] Can post the initial sales order without errors
        VerifyPostingInitialSalesOrder(InitialSalesOrderNo);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ReservationModalPageHandler,SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,OrderPromisingLinesModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateReservationAndOrderPromisingAsAccountant()
    var
        SalesOrder: TestPage "Sales Order";
        ItemNo: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
        PurchaseOrderNo: Code[20];
        InitialSalesOrderNo: Code[20];
    begin
        // [SCENARIO] Create a purchase return order as Accountant
        Initialize();

        // [GIVEN] A posted purchase invoice
        VendorNo := CreateVendor();
        CustomerNo := CreateCustomer();
        ItemNo := CreateItem();
        CreateAndPostPurchaseInvoice(VendorNo, ItemNo, 7);

        // Set plan to Accountant
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [WHEN] Create a purchase order from existing vendor
        PurchaseOrderNo := CreatePurchaseOrder(VendorNo, ItemNo, 13, WorkDate());

        // [WHEN] Create a new sales order and select reserve
        InitialSalesOrderNo := CreateAndReserveSalesOrder(SalesOrder, CustomerNo, ItemNo, 12, CalcDate('<+2W>', WorkDate()));
        // [THEN] Quantity is reserved
        Assert.AreEqual('12', SalesOrder.SalesLines."Reserved Quantity".Value, '');

        // [WHEN] Use Available to Promise to give customer the expected delivery date
        CalculateAvailableToPromise(SalesOrder);

        // [THEN] Dates have been automatically calculated and filled in
        VerifyOrderPromisingLines();

        // [WHEN] Post the purchase order (as received or received and invoiced),
        // So now the inventory is in stock and we can ship to the customer
        PostPurchaseOrder(PurchaseOrderNo);

        // [WHEN] Create a new sales order and select reserve
        CreateAndReserveSalesOrder(SalesOrder, CustomerNo, ItemNo, 15, CalcDate('<+4W>', WorkDate()));

        // [THEN] You can only reserve 8 pcs, 12 of 20 available items are already reserved.
        Assert.AreEqual('8', SalesOrder.SalesLines."Reserved Quantity".Value, '');

        // [THEN] Can post the initial sales order without errors
        VerifyPostingInitialSalesOrder(InitialSalesOrderNo);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ReservationModalPageHandler,SelectCustomerTemplListModalPageHandler,SelectVendorTemplListModalPageHandler,SelectItemTemplListModalPageHandler,OrderPromisingLinesModalPageHandler,ConfirmHandlerYes,PostedPurchaseInvoicePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateReservationAndOrderPromisingAsTeamMember()
    var
        SalesOrder: TestPage "Sales Order";
        ErrorMessagesPage: TestPage "Error Messages";
        ItemNo: Code[20];
        VendorNo: Code[20];
        CustomerNo: Code[20];
        PurchaseOrderNo: Code[20];
        InitialSalesOrderNo: Code[20];
    begin
        // [SCENARIO] Create a purchase return order as Team Member
        Initialize();

        // [GIVEN] A posted purchase invoice
        VendorNo := CreateVendor();
        CustomerNo := CreateCustomer();
        ItemNo := CreateItem();
        CreateAndPostPurchaseInvoice(VendorNo, ItemNo, 7);

        // Set plan to Team Member
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [WHEN] Create a purchase order from existing vendor
        asserterror PurchaseOrderNo := CreatePurchaseOrder(VendorNo, ItemNo, 13, WorkDate());
        Assert.ExpectedErrorCode('TestValidation');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        PurchaseOrderNo := CreatePurchaseOrder(VendorNo, ItemNo, 13, WorkDate());

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [WHEN] Create a new sales order and select reserve
        asserterror InitialSalesOrderNo := CreateAndReserveSalesOrder(SalesOrder, CustomerNo, ItemNo, 12, CalcDate('<+2W>', WorkDate()));
        SalesOrder.Close();
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('TestValidation');
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        InitialSalesOrderNo := CreateAndReserveSalesOrder(SalesOrder, CustomerNo, ItemNo, 12, CalcDate('<+2W>', WorkDate()));

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [THEN] Quantity is reserved
        SalesOrder.SalesLines."Reserved Quantity".AssertEquals(12);

        // [WHEN] Use Available to Promise to give customer the expected delivery date
        CalculateAvailableToPromise(SalesOrder);

        // [THEN] Dates have been automatically calculated and filled in
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        VerifyOrderPromisingLines();

        // [WHEN] Post the purchase order (as received or received and invoiced),
        // So now the inventory is in stock and we can ship to the customer
        ErrorMessagesPage.Trap();
        PostPurchaseOrder(PurchaseOrderNo);
        ErrorMessagesPage.Description.AssertEquals(TeamMemberErr);
        ErrorMessagesPage.Close();

        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        PostPurchaseOrder(PurchaseOrderNo);

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [WHEN] Create a new sales order and select reserve
        asserterror CreateAndReserveSalesOrder(SalesOrder, CustomerNo, ItemNo, 15, CalcDate('<+4W>', WorkDate()));
        SalesOrder.Close();
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CreateAndReserveSalesOrder(SalesOrder, CustomerNo, ItemNo, 15, CalcDate('<+4W>', WorkDate()));

        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [GIVEN] You can only reserve 8 pcs, 12 of 20 available items are already reserved.
        SalesOrder.SalesLines."Reserved Quantity".AssertEquals(8);

        // [WHEN] Post sales order
        ErrorMessagesPage.Trap();
        asserterror VerifyPostingInitialSalesOrder(InitialSalesOrderNo);
        // [THEN] Order is not posted, error message: 'As a Team Member you cannot complete this task '
        Assert.ExpectedError('The TestPage is not open.');
        ErrorMessagesPage.Description.AssertEquals(TeamMemberErr);
        ErrorMessagesPage.Close();

        // [WHEN] Set Business Manager Plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        // [THEN] Post the initial sales order without errors
        VerifyPostingInitialSalesOrder(InitialSalesOrderNo);
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Reserv. & Order Promising E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Reserv. & Order Promising E2E");

        LibraryTemplates.EnableTemplatesFeature();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryTemplates.UpdateTemplatesVATGroups();

        InitializeAvailabilityCheckSettingsOnCompanyInformation();

        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Reserv. & Order Promising E2E");
    end;

    local procedure CreateAndPostPurchaseInvoice(VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Integer)
    var
        PurchaseInvoiceNo: Code[20];
    begin
        PurchaseInvoiceNo := CreatePurchaseInvoice(VendorNo, ItemNo, Quantity);
        PostPurchaseInvoice(PurchaseInvoiceNo);
    end;

    local procedure CreatePurchaseInvoice(VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Integer) PurchaseInvoiceNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(VendorNo);
        PurchaseInvoice."Vendor Invoice No.".SetValue(LibraryUtility.GenerateGUID());
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::Item));
        PurchaseInvoice.PurchLines."No.".SetValue(ItemNo);
        PurchaseInvoice.PurchLines.Quantity.SetValue(Quantity);
        PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandDecInRange(1, 1000, 2));
        PurchaseInvoiceNo := PurchaseInvoice."No.".Value();
        PurchaseInvoice.OK().Invoke();
    end;

    local procedure PostPurchaseInvoice(PurchaseInvoiceNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoKey(PurchaseHeader."Document Type"::Invoice, PurchaseInvoiceNo);
        PurchaseInvoice.Post.Invoke();
    end;

    [Normal]
    local procedure CreatePurchaseOrder(VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Integer; OrderDate: Date) PurchaseOrderNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenNew();
        PurchaseOrder."Buy-from Vendor Name".SetValue(VendorNo);
        PurchaseOrder."Vendor Invoice No.".SetValue(LibraryUtility.GenerateGUID());
        PurchaseOrder."Order Date".SetValue(OrderDate);
        PurchaseOrder.PurchLines.FilteredTypeField.SetValue(Format(PurchaseLine.Type::Item));
        PurchaseOrder.PurchLines."No.".SetValue(ItemNo);
        PurchaseOrder.PurchLines.Quantity.SetValue(Quantity);
        PurchaseOrder.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandDecInRange(1, 1000, 2));
        PurchaseOrderNo := PurchaseOrder."No.".Value();
        PurchaseOrder.OK().Invoke();
    end;

    local procedure PostPurchaseOrder(PurchaseOrderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoKey(PurchaseHeader."Document Type"::Order, PurchaseOrderNo);
        PurchaseOrder.Post.Invoke();
    end;

    local procedure CreateItem() ItemNo: Code[20]
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenNew();
        ItemCard.Description.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)));
        ItemNo := ItemCard."No.".Value();
        ItemCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateVendor() VendorNo: Code[20]
    var
        Vendor: Record Vendor;
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VendorCard: TestPage "Vendor Card";
    begin
        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        VendorCard.OpenNew();
        VendorCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        VendorCard."Gen. Bus. Posting Group".SetValue(GenBusinessPostingGroup.Code);
        VendorCard."Vendor Posting Group".SetValue(LibraryPurchase.FindVendorPostingGroup());
        VendorNo := VendorCard."No.".Value();
        VendorCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateCustomer() CustomerNo: Code[20]
    var
        Customer: Record Customer;
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        CustomerCard: TestPage "Customer Card";
    begin
        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)));
        CustomerCard."Gen. Bus. Posting Group".SetValue(GenBusinessPostingGroup.Code);
        CustomerCard."Customer Posting Group".SetValue(LibrarySales.FindCustomerPostingGroup());
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.OK().Invoke();
        Commit();
    end;

    [Normal]
    local procedure CreateAndReserveSalesOrder(var SalesOrder: TestPage "Sales Order"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Integer; OrderDate: Date) SalesOrderNo: Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer No.".SetValue(CustomerNo);
        SalesOrder."Order Date".SetValue(OrderDate);
        SalesOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesOrder.SalesLines."No.".SetValue(ItemNo);
        SalesOrder.SalesLines.Quantity.SetValue(Quantity);
        SalesOrder.SalesLines."Shipment Date".SetValue(OrderDate);
        SalesOrderNo := SalesOrder."No.".Value();
        SalesOrder.SalesLines.Reserve.Invoke();
    end;

    local procedure CalculateAvailableToPromise(SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.OrderPromising.Invoke();
        SalesOrder.OK().Invoke();
    end;

    local procedure VerifyOrderPromisingLines()
    begin
        Assert.AreEqual(0D, LibraryVariableStorage.DequeueDate(), PlannedDeliveryDateErr);
        Assert.AreEqual(0D, LibraryVariableStorage.DequeueDate(), EarliestShipmentDateErr);
        Assert.AreEqual(CalcDate('<+2W>', WorkDate()), LibraryVariableStorage.DequeueDate(), PlannedDeliveryDateErr);
        Assert.AreEqual(CalcDate('<+2W>', WorkDate()), LibraryVariableStorage.DequeueDate(), EarliestShipmentDateErr);
    end;

    local procedure VerifyPostingInitialSalesOrder(InitialSalesOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesHeader."Document Type"::Order, InitialSalesOrderNo);
        PostedSalesInvoice.Trap();
        SalesOrder.Post.Invoke();
        PostedSalesInvoice.Close();
    end;

    local procedure InitializeAvailabilityCheckSettingsOnCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
        DateFormulaForQuarter: DateFormula;
    begin
        Evaluate(DateFormulaForQuarter, '<3M>');
        CompanyInformation.Get();
        CompanyInformation.Validate("Check-Avail. Period Calc.", DateFormulaForQuarter);
        CompanyInformation.Validate("Check-Avail. Time Bucket", CompanyInformation."Check-Avail. Time Bucket"::Day);
        CompanyInformation.Modify(true);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Option: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 3; // Receive/Ship and Invoice
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoicePageHandler(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    begin
        PostedPurchaseInvoice.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplListModalPageHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.First();
        SelectCustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectVendorTemplListModalPageHandler(var SelectVendorTemplList: TestPage "Select Vendor Templ. List")
    begin
        SelectVendorTemplList.First();
        SelectVendorTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplListModalPageHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.First();
        SelectItemTemplList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationModalPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderPromisingLinesModalPageHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.First();
        // Collect values BEFORE invoking Available-to-Promise
        LibraryVariableStorage.Enqueue(OrderPromisingLines."Planned Delivery Date".AsDate());
        LibraryVariableStorage.Enqueue(OrderPromisingLines."Earliest Shipment Date".AsDate());

        OrderPromisingLines.AvailableToPromise.Invoke();
        // Collect values AFTER invoking Available-to-Promise
        LibraryVariableStorage.Enqueue(OrderPromisingLines."Planned Delivery Date".AsDate());
        LibraryVariableStorage.Enqueue(OrderPromisingLines."Earliest Shipment Date".AsDate());

        OrderPromisingLines.AcceptButton.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}

