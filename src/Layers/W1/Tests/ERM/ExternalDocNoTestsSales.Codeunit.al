codeunit 132940 "External Doc. No. Tests-Sales"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [External Doc. No. in Sales] [Notify duplicate]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        SalesAlreadyExistsTxt: Label 'Sales %1 %2 already exists for this customer.', Comment = '%1 = Document Type; %2 = External Document No.';

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure ExternalDocNoNotificationForInvoice()
    var
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
        ExternalDocumentNo: Code[35];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO] Notification appears in the sales invoice page in case of External Document No. already used for another invoice
        Initialize();

        // [GIVEN] Enable "Show sales document with same external document number already exists" notification
        EnableShowExternalDocAlreadyExistNotification();

        // [GIVEN] Create and post sales invoice with External Document No. = XXX
        CreatePostSalesDocWithExternalDocNo(
          ExternalDocumentNo, CustomerNo, SalesHeader."Document Type"::Invoice, SalesHeader);

        // [GIVEN] Create new invoice and open it in the Sales Invoice page
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // [WHEN] External Document No. field is being filled in by XXX value
        SalesInvoice."External Document No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Sales Invoice XXX already exists for this customer" appears
        VerifyNotificationData(ExternalDocumentNo, SalesHeader."Document Type"::Invoice);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure ExternalDocNoNotificationForOrder()
    var
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesOrder: TestPage "Sales Order";
        ExternalDocumentNo: Code[35];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO] Notification appears in the sales order page in case of External Document No. already used for another order
        Initialize();

        // [GIVEN] Enable "Show sales document with same external document number already exists" notification
        EnableShowExternalDocAlreadyExistNotification();

        // [GIVEN] Create and post sales order with External Document No. = XXX
        CreatePostSalesDocWithExternalDocNo(
          ExternalDocumentNo, CustomerNo, SalesHeader."Document Type"::Order, SalesHeader);

        // [GIVEN] Create new sales order and open it in the Sales Order page
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] External Document No. field is being filled in by XXX value
        SalesOrder."External Document No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Sales Order XXX already exists for this customer" appears
        VerifyNotificationData(ExternalDocumentNo, SalesHeader."Document Type"::Order);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('RecallNotificationHandler,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure ExternalDocNoNotificationForCrMemo()
    var
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesCrMemo: TestPage "Sales Credit Memo";
        ExternalDocumentNo: Code[35];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [External Document No.] [UI]
        // [SCENARIO 223191] Notification appears in the sales cr. memo page in case of External Document No. already used for another cr. memo
        Initialize();

        // [GIVEN] Enable "Show sales document with same external document number already exists" notification
        EnableShowExternalDocAlreadyExistNotification();

        // [GIVEN] Create and post sales cr. memo with External Document No. = XXX
        CreatePostSalesDocWithExternalDocNo(
          ExternalDocumentNo, CustomerNo, SalesHeader."Document Type"::"Credit Memo", SalesHeader);

        // [GIVEN] Create new sales cr. memo and open it
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesCrMemo.OpenEdit();
        SalesCrMemo.GotoRecord(SalesHeader);

        // [WHEN] External Document No. field is being filled in by XXX value
        SalesCrMemo."External Document No.".SetValue(ExternalDocumentNo);

        // [THEN] Notification "Sales Order XXX already exists for this customer" appears
        VerifyNotificationData(ExternalDocumentNo, SalesHeader."Document Type"::"Credit Memo");

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"External Doc. No. Tests-Sales");
    end;

    local procedure EnableShowExternalDocAlreadyExistNotification()
    var
        SalesHeader: Record "Sales Header";
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.Get(UserId, SalesHeader.GetShowExternalDocAlreadyExistNotificationId()) then
            MyNotifications.Delete();
        SalesHeader.SetShowExternalDocAlreadyExistNotificationDefaultState(true);
    end;

    local procedure CreatePostSalesDocWithExternalDocNo(var ExternalDocumentNo: Code[35]; var CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; var SalesHeader: Record "Sales Header")
    begin
        ExternalDocumentNo := LibraryUtility.GenerateGUID();
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateSalesDocument(SalesHeader, DocumentType, CustomerNo);
        SalesHeader."External Document No." := ExternalDocumentNo;
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(10));
    end;

    local procedure VerifyNotificationData(ExternalDocumentNo: Code[35]; DocumentType: Enum "Sales Document Type")
    begin
        Assert.AreEqual(
          StrSubstNo(SalesAlreadyExistsTxt, DocumentType, ExternalDocumentNo),
          LibraryVariableStorage.DequeueText(),
          'Unexpected notification message');
    end;
    
    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        if Notification.Id = SalesHeader.GetShowExternalDocAlreadyExistNotificationId() then
            LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}
