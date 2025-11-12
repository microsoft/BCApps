codeunit 134351 "Doc. Backgr. Error Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Error Handling]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        InvalidDimensionsErr: Label 'The dimensions used in %1 %2 are invalid', Comment = '%1 = Document Type, %2 = Document No, %3 = Error text';
        CheckUnhandledErrorTxt: Label 'Check unhandled error', Locked = true;

    [Test]
    [HandlerFunctions('BackgroundValidationShowSetupNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderNotification_Action_EnableThisForMe()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 411158] User opens sales order page first time, get notification and choose "Enable this for me" action
        Initialize();

        // [GIVEN] There are not notifications "Show the Document Check FactBox" and "Enable Data Check"
        ClearBackgroundCheckNotifications();

        // [GIVEN] Sales order "SO" with empty "Journal Templ. Name"
        CreateEmptyTemplateSalesOrder(SalesHeader);

        // [WHEN] Open Sales Order page for "SO"
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] Notification appears (BackgroundValidationShowSetupNotificationHandler)
        // [WHEN] User choose "Enable this for me" action

        // [THEN] "Sales Doc. Check Factbox" shows error "Journal Template Name must have a value..."
        SalesOrder.SalesDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(SalesOrder.SalesDocCheckFactbox.Error1.Value(), GenJournalLine.FieldCaption("Journal Template Name"), '', '', '');

        // [THEN] Notification "Enable Data Check" is disabled
        VerifyNotificationOff();
    end;

    [Test]
    [HandlerFunctions('BackgroundValidationDontShowAgainNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderNotification_Action_DontShowAgain()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 411158] User opens sales order page first time, get notification, choose "Don't show again" action
        Initialize();

        // [GIVEN] There are not notifications "Show the Document Check FactBox" and "Enable Data Check"
        ClearBackgroundCheckNotifications();

        // [GIVEN] Sales order "SO"
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [WHEN] Open Sales Order page for "SO"
        SalesOrder.OpenEdit();

        // [THEN] Notification appears (BackgroundValidationDontShowAgainNotificationHandler)
        // [WHEN] User choose "Don't show again" action

        // [THEN] Notification "Enable Data Check" is disabled
        VerifyNotificationOff();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderOneError()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 411158] "Sales Doc. Check Factbox" shows error for sales order
        Initialize();

        // [GIVEN] Sales order "SO" with empty "Journal Templ. Name"
        CreateEmptyTemplateSalesOrder(SalesHeader);

        // [WHEN] Open Sales Order page for "SO"
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] "Sales Doc. Check Factbox" shows error "Journal Template Name must have a value..."
        SalesOrder.SalesDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(SalesOrder.SalesDocCheckFactbox.Error1.Value(), GenJournalLine.FieldCaption("Journal Template Name"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderBackgrErrorCheckDisable()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 411158] "Sales Doc. Check Factbox" does not run check errors for sales order if General Ledger Setup "Enable Data Check" = false
        // FactBox visibily cannot be tested
        Initialize();

        // [GIVEN] "General Ledger Setup"."Enable Data Check" = No
        EnableBackgroundValidation(false);

        // [GIVEN] Sales order "SO" with empty "Journal Templ. Name"
        CreateEmptyTemplateSalesOrder(SalesHeader);

        // [WHEN] Open Sales Order page for "SO"
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] "Sales Doc. Check Factbox" does not show errors
        SalesOrder.SalesDocCheckFactbox.NumberOfErrors.AssertEquals(0);
        SalesOrder.SalesDocCheckFactbox.Error1.AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderHeaderAndLineErrors()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: record "Gen. Journal Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 411158] "Sales Doc. Check Factbox" shows errors for sales order header and line
        Initialize();

        // [GIVEN] Sales order "SO" with empty "Journal Templ. Name"
        CreateEmptyTemplateSalesOrder(SalesHeader);

        // [GIVEN] Mock sales order line with error
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine."Return Qty. to Receive" := 100;
        SalesLine.Modify();

        // [WHEN] Open Sales Order page for "SO"
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] "Sales Doc. Check Factbox" shows 2 errors "Journal Template Name must have a value..." and "Return Qty. to Receive must be equal to 0"
        SalesOrder.SalesDocCheckFactbox.NumberOfErrors.AssertEquals(2);
        Assert.ExpectedTestFieldMessage(SalesOrder.SalesDocCheckFactbox.Error1.Value(), GenJournalLine.FieldCaption("Journal Template Name"), '', '', '');
        Assert.ExpectedTestFieldMessage(SalesOrder.SalesDocCheckFactbox.Error2.Value(), SalesLine.FieldCaption("Return Qty. to Receive"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDimensionError()
    var
        SalesHeader: Record "Sales Header";
        DimensionValue: Record "Dimension Value";
        SalesOrder: TestPage "Sales Order";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 411158] "Sales Doc. Check Factbox" shows dimension error for sales order with same parameters as for preview error
        Initialize();

        // [GIVEN] Dimension value "DV"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        // [GIVEN] Sales order "SO" with dimension value "DV"
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.Validate("Dimension Set ID", GetDimSetId(DimensionValue));
        SalesHeader.Modify();

        // [GIVEN] Make dimension value "DV" blocked
        DimensionValue.Validate(Blocked, true);
        DimensionValue.Modify();

        // [GIVEN] Open Sales Order page for "SO"
        Commit();
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [WHEN] Drilldown "Number of Errors" on factbox
        ErrorMessages.Trap();
        SalesOrder.SalesDocCheckFactbox.NumberOfErrors.Drilldown();

        // [THEN] "Error Messages" page shows proper error details
        ErrorMessages.Source.AssertEquals(DimensionValue.RecordId);
        ErrorMessages."Field Name".AssertEquals(DimensionValue.FieldCaption(Blocked));
        ErrorMessages."Additional Information".AssertEquals(StrSubstNo(InvalidDimensionsErr, SalesHeader."Document Type", SalesHeader."No."));
        ErrorMessages."Support Url".AssertEquals('https://go.microsoft.com/fwlink/?linkid=2079638');
        Assert.IsTrue(ErrorMessages.CallStack.Value <> '', 'CallStack field must have value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderModifiedLineWithError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        CheckSalesDocBackgr: Codeunit "Check Sales Doc. Backgr.";
        Args: Dictionary of [Text, Text];
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 411158] Fix order line with error makes factbox clear only this error
        Initialize();

        // [GIVEN] Sales order "SO" with empty "Journal Templ. Name" and with line 1
        CreateEmptyTemplateSalesOrder(SalesHeader);
        // [GIVEN] Add line 2 with error
        CreateSalesOrderLineWithError(SalesLine, SalesHeader);

        // [GIVEN] Mock full document check and get 2 errors
        PrepareFullSalesDocCheckArgs(SalesHeader, Args);
        Commit();
        CheckSalesDocBackgr.RunCheck(Args, TempErrorMessage);
        Assert.AreEqual(2, TempErrorMessage.Count, 'Invalid number of full check errors');

        // [GIVEN] Mock fix line 2 error
        MockModifySalesOrderLine(SalesLine);

        // [WHEN] Run CleanTempErrorMessages
        BackgroundErrorHandlingMgt.CollectSalesDocCheckParameters(SalesHeader, ErrorHandlingParameters);
        BackgroundErrorHandlingMgt.CleanSalesTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);
        // [THEN] Error message about Line2 deleted
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", SalesLine.RecordId);
        Assert.IsTrue(TempErrorMessage.IsEmpty(), 'Error message for line 2 has to be deleted.');
        // [THEN] Error message about header is not deleted
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", SalesHeader.RecordId);
        Assert.IsFalse(TempErrorMessage.IsEmpty(), 'Error message for header has not to be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderUnhandledError()
    var
        SalesHeader: Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        DocBackgrErrorHandling: Codeunit "Doc. Backgr. Error Handling";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 411158] "Check Sales Doc. Backgr." catches the unhandled error for sales order
        Initialize();
        BindSubscription(DocBackgrErrorHandling);

        // [GIVEN] Sales order "SO"
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader."Posting Description" := CheckUnhandledErrorTxt;
        SalesHeader.Modify();

        // [WHEN] Mock check sales order
        MockCheckSalesDocument(SalesHeader, TempErrorMessage);

        // [THEN] Error message buffer contains error "Check unhandled error"
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField("Message", CheckUnhandledErrorTxt);
        UnBindSubscription(DocBackgrErrorHandling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceOneError()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 411158] "Sales Doc. Check Factbox" shows error for sales invoice
        Initialize();

        // [GIVEN] Sales invoice "SI" with empty "Journal Templ. Name"
        CreateEmptyTemplateSalesDocument(SalesHeader, "Sales Document Type"::Invoice);

        // [WHEN] Open Sales Invoice page for "SI"
        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] "Sales Doc. Check Factbox" shows error "Journal Template Name must have a value..."
        SalesInvoice.SalesDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(SalesInvoice.SalesDocCheckFactbox.Error1.Value(), GenJournalLine.FieldCaption("Journal Template Name"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoOneError()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 411158] "Sales Doc. Check Factbox" shows error for sales credit memo
        Initialize();

        // [GIVEN] Sales credit memo "SC" with empty "Journal Templ. Name"
        CreateEmptyTemplateSalesDocument(SalesHeader, "Sales Document Type"::"Credit Memo");

        // [WHEN] Open Sales Credit Memo page for "SC"
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] "Sales Doc. Check Factbox" shows error "Journal Template Name must have a value..."
        SalesCreditMemo.SalesDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(SalesCreditMemo.SalesDocCheckFactbox.Error1.Value(), GenJournalLine.FieldCaption("Journal Template Name"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderOneError()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 411158] "Sales Doc. Check Factbox" shows error for sales return order
        Initialize();

        // [GIVEN] Sales return order "SRO" with empty "Journal Templ. Name"
        CreateEmptyTemplateSalesDocument(SalesHeader, "Sales Document Type"::"Return Order");

        // [WHEN] Open Sales Return Order page for "SRO"
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] "Sales Doc. Check Factbox" shows error "Journal Template Name must have a value..."
        SalesReturnOrder.SalesDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(SalesReturnOrder.SalesDocCheckFactbox.Error1.Value(), GenJournalLine.FieldCaption("Journal Template Name"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderOneError()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 411159] "Purchase Doc. Check Factbox" shows error for purchase order
        Initialize();

        // [GIVEN] Purchase order "PO" with empty "Journal Templ. Name"
        CreateEmptyTemplatePurchaseDocument(PurchaseHeader, "Purchase Document Type"::Order);

        // [WHEN] Open Purchase Order page for "PO"
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] "Purchase Doc. Check Factbox" shows error "Journal Template Name must have a value..."
        PurchaseOrder.PurchaseDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(PurchaseOrder.PurchaseDocCheckFactbox.Error1.Value(), GenJournalLine.FieldCaption("Journal Template Name"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceOneError()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 411159] "Purchase Doc. Check Factbox" shows error for purchase invoice
        Initialize();

        // [GIVEN] Purchase invoice "PI" with empty "Journal Templ. Name"
        CreateEmptyTemplatePurchaseDocument(PurchaseHeader, "Purchase Document Type"::Invoice);

        // [WHEN] Open Purchase Invoice page for "PI"
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] "Purchase Doc. Check Factbox" shows error "Journal Template Name must have a value..."
        PurchaseInvoice.PurchaseDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(PurchaseInvoice.PurchaseDocCheckFactbox.Error1.Value(), GenJournalLine.FieldCaption("Journal Template Name"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderOneError()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 411159] "Purchase Doc. Check Factbox" shows error for purchase return order
        Initialize();

        // [GIVEN] Purchase return order "PRO" with empty "Journal Templ. Name"
        CreateEmptyTemplatePurchaseDocument(PurchaseHeader, "Purchase Document Type"::"Return Order");

        // [WHEN] Open Purchase Return Order page for "PRO"
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] "Purchase Doc. Check Factbox" shows error "Journal Template Name must have a value..."
        PurchaseReturnOrder.PurchaseDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(PurchaseReturnOrder.PurchaseDocCheckFactbox.Error1.Value(), GenJournalLine.FieldCaption("Journal Template Name"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoOneError()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 411159] "Purchase Doc. Check Factbox" shows error for purchase credit memo
        Initialize();

        // [GIVEN] Purchase credit memo "PC" with empty "Journal Templ. Name"
        CreateEmptyTemplatePurchaseDocument(PurchaseHeader, "Purchase Document Type"::"Credit Memo");

        // [WHEN] Open Purchase Credit Memo page for "PC"
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] "Purchase Doc. Check Factbox" shows error "Journal Template Name must have a value..."
        PurchaseCreditMemo.PurchaseDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(PurchaseCreditMemo.PurchaseDocCheckFactbox.Error1.Value(), GenJournalLine.FieldCaption("Journal Template Name"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderOneError()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 411160] "Service Doc. Check Factbox" shows error for service order
        Initialize();

        // [GIVEN] Service order "SO" with empty "Document Date"
        CreateEmptyDocumentDateServiceDocument(ServiceHeader, "Service Document Type"::Order);

        // [WHEN] Open Service Order page for "SO"
        ServiceOrder.OpenEdit();
        ServiceOrder.Filter.SetFilter("No.", ServiceHeader."No.");

        // [THEN] "Service Doc. Check Factbox" shows error "Document Date must have a value..."
        ServiceOrder.ServiceDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(ServiceOrder.ServiceDocCheckFactbox.Error1.Value(), ServiceHeader.FieldCaption("Document Date"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceOneError()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 411160] "Service Doc. Check Factbox" shows error for service invoice
        Initialize();

        // [GIVEN] Service invoice "SI" with empty "Document Date"
        CreateEmptyDocumentDateServiceDocument(ServiceHeader, "Service Document Type"::Invoice);

        // [WHEN] Open Service Invoice page for "SI"
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");

        // [THEN] "Service Doc. Check Factbox" shows error "Document Date must have a value..."
        ServiceInvoice.ServiceDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(ServiceInvoice.ServiceDocCheckFactbox.Error1.Value(), ServiceHeader.FieldCaption("Document Date"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoOneError()
    var
        ServiceHeader: Record "Service Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 411160] "Service Doc. Check Factbox" shows error for service creditmemo
        Initialize();

        // [GIVEN] Service creditmemo "SC" with empty "Document Date"
        CreateEmptyDocumentDateServiceDocument(ServiceHeader, "Service Document Type"::"Credit Memo");

        // [WHEN] Open Service CreditMemo page for "SC"
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.Filter.SetFilter("No.", ServiceHeader."No.");

        // [THEN] "Service Doc. Check Factbox" shows error "Document Date must have a value..."
        ServiceCreditMemo.ServiceDocCheckFactbox.NumberOfErrors.AssertEquals(1);
        Assert.ExpectedTestFieldMessage(ServiceCreditMemo.ServiceDocCheckFactbox.Error1.Value(), ServiceHeader.FieldCaption("Document Date"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceHeaderAndLineErrors()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 411160] "Service Doc. Check Factbox" shows error for header and for line
        Initialize();

        // [GIVEN] Service invoice "SI" with empty "Document Date" and with empty Unit of Measure Code line
        UpdateServiceMgtSetupMandatoryUOM();
        CreateEmptyDocumentDateServiceDocument(ServiceHeader, "Service Document Type"::Invoice);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.FindFirst();
        ServiceLine."Unit of Measure Code" := '';
        ServiceLine.Modify();
        Commit();

        // [WHEN] Open Service Invoice page for "SI"
        ServiceInvoice.OpenEdit();
        ServiceInvoice.Filter.SetFilter("No.", ServiceHeader."No.");

        // [THEN] "Service Doc. Check Factbox" shows error "Document Date must have a value..." and "Unit of Measure Code must have a value..."
        ServiceInvoice.ServiceDocCheckFactbox.NumberOfErrors.AssertEquals(2);
        Assert.ExpectedTestFieldMessage(ServiceInvoice.ServiceDocCheckFactbox.Error1.Value(), ServiceHeader.FieldCaption("Document Date"), '', '', '');
        Assert.ExpectedTestFieldMessage(ServiceInvoice.ServiceDocCheckFactbox.Error2.Value(), ServiceLine.FieldCaption("Unit of Measure Code"), '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MyNotificationsNotCreatedWhenEnableDataCheckFalse()
    var
        MyNotifications: Record "My Notifications";
        MyNotificationsPage: TestPage "My Notifications";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 425845] My Notifications "Enable Data Check" and "Show the Document Check Factbox" are not created when General Ledger Setup "Enable Data Check"=false
        Initialize();

        // [GIVEN] "General Ledger Setup"."Enable Data Check" = No
        EnableBackgroundValidation(false);

        // [GIVEN] No My Notificaions records
        MyNotifications.DeleteAll();

        // [WHEN] Open My Notifications page
        Commit();
        MyNotificationsPage.OpenEdit();

        // [THEN] Notifications "Enable Data Check" and "Show the Document Check Factbox" are not created
        Assert.IsFalse(MyNotifications.Get(UserId, DocumentErrorsMgt.GetEnableBackgroundValidationNotificationID()), 'Notification Enable Data Check must not be created');
        Assert.IsFalse(MyNotifications.Get(UserId, DocumentErrorsMgt.GetShowDocumentCheckFactboxNotificationID()), 'Notification Show the Document Check Factbox must not be created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MyNotificationsCreatedWhenEnableDataCheckTrue()
    var
        GLSetup: Record "General Ledger Setup";
        MyNotificationsPage: TestPage "My Notifications";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 427566] My Notifications "Enable Data Check" and "Show the Document Check Factbox" are created when General Ledger Setup "Enable Data Check"=true
        // Notification ShowDocumentCheckFactbox is off by default
        Initialize();

        // [GIVEN] "General Ledger Setup"."Enable Data Check" = Yes
        GLSetup.Get();
        GLSetup.TestField("Enable Data Check", true);

        // [GIVEN] No My Notificaions records
        ClearBackgroundCheckNotifications();

        // [WHEN] Open My Notifications page
        Commit();
        MyNotificationsPage.OpenEdit();

        // [THEN] Notifications "Enable Data Check" and "Show the Document Check Factbox" are created
        VerifyNotificationsCreated();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Doc. Backgr. Error Handling");
        LibrarySetupStorage.Restore();
        EnableBackgroundValidation(true);

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Doc. Backgr. Error Handling");
        IsInitialized := true;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryService.SetupServiceMgtNoSeries();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Service Mgt. Setup");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Doc. Backgr. Error Handling");
    end;

    local procedure CreateEmptyTemplateSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        CreateEmptyTemplateSalesDocument(SalesHeader, "Sales Document Type"::Order);
    end;

    local procedure CreateEmptyTemplateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    begin
        SetJournalTemplNameMandatory();
        case DocumentType of
            "Sales Document Type"::Invoice:
                LibrarySales.CreateSalesInvoice(SalesHeader);
            "Sales Document Type"::Order:
                LibrarySales.CreateSalesOrder(SalesHeader);
            "Sales Document Type"::"Credit Memo":
                LibrarySales.CreateSalesCreditMemo(SalesHeader);
            "Sales Document Type"::"Return Order":
                LibrarySales.CreateSalesReturnOrder(SalesHeader);
        end;
        SalesHeader."Journal Templ. Name" := '';
        SalesHeader.Modify();
        Commit();
    end;

    local procedure CreateSalesOrderLineWithError(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
            Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Item, Item."No.", LibraryRandom.RandInt(100));
        SalesLine."Return Qty. to Receive" := 1;
        SalesLine.Modify();
    end;

    local procedure GetDimSetId(DimensionValue: Record "Dimension Value"): Integer
    begin
        exit(LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
    end;

    local procedure MockModifySalesOrderLine(var SalesLine: Record "Sales Line")
    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        DocumentErrorsMgt.SetModifiedSalesLine(SalesLine);
        DocumentErrorsMgt.SetFullDocumentCheck(false);
        SalesLine."Return Qty. to Receive" := 0;
        SalesLine.Modify();
    end;

    local procedure MockCheckSalesDocument(SalesHeader: Record "Sales Header"; var TempErrorMessage: Record "Error Message" temporary)
    var
        CheckSalesDocBackgr: Codeunit "Check Sales Doc. Backgr.";
        Args: Dictionary of [Text, Text];
    begin
        PrepareFullSalesDocCheckArgs(SalesHeader, Args);
        Commit();
        CheckSalesDocBackgr.RunCheck(Args, TempErrorMessage);
    end;

    local procedure EnableBackgroundValidation(Enabled: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Enable Data Check" := Enabled;
        GLSetup.Modify();

        UpdateShowDocumentCheckFactboxNotification(Enabled);
    end;

    local procedure SetJournalTemplNameMandatory()
    begin
        LibraryERMCountryData.UpdateJournalTemplMandatory(true);

        UpdateNoSeriesInSalesSetup();
        UpdateNoSeriesInPurchaseSetup();
    end;

    local procedure UpdateNoSeriesInSalesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate(
            "S. Invoice Template Name",
            CreateGenJournalTemplateWithPostingSeriesNo("Gen. Journal Template Type"::Sales, CreateNoSeriesCode()));
        SalesSetup.Validate(
            "S. Cr. Memo Template Name",
            CreateGenJournalTemplateWithPostingSeriesNo("Gen. Journal Template Type"::Sales, CreateNoSeriesCode()));
        SalesSetup.Modify(true);
    end;

    local procedure UpdateNoSeriesInPurchaseSetup()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup.Validate(
            "P. Invoice Template Name",
            CreateGenJournalTemplateWithPostingSeriesNo("Gen. Journal Template Type"::Purchases, CreateNoSeriesCode()));
        PurchSetup.Validate(
            "P. Cr. Memo Template Name",
            CreateGenJournalTemplateWithPostingSeriesNo("Gen. Journal Template Type"::Purchases, CreateNoSeriesCode()));
        PurchSetup.Modify(true);
    end;

    local procedure CreateEmptyTemplatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        SetJournalTemplNameMandatory();
        case DocumentType of
            "Purchase Document Type"::Invoice:
                LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
            "Purchase Document Type"::Order:
                LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
            "Purchase Document Type"::"Credit Memo":
                LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
            "Purchase Document Type"::"Return Order":
                LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);
        end;
        PurchaseHeader."Journal Templ. Name" := '';
        PurchaseHeader.Modify();
        Commit();
    end;

    local procedure CreateEmptyDocumentDateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    begin
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, DocumentType, LibrarySales.CreateCustomerNo());
        ServiceHeader."Document Date" := 0D;
        ServiceHeader.Modify();
        Commit();
    end;

    local procedure CreateNoSeriesCode(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        Prefix: Code[10];
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);

        Prefix := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Prefix));

        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StrSubstNo('%1-0000', Prefix), StrSubstNo('%1-9999', Prefix));

        exit(NoSeriesLine."Series Code");
    end;

    local procedure CreateGenJournalTemplateWithPostingSeriesNo(TemplateType: Enum "Gen. Journal Template Type"; PostingNoSeries: Code[20]): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, TemplateType);
        GenJournalTemplate.Validate("Posting No. Series", PostingNoSeries);
        GenJournalTemplate.Modify(true);

        exit(GenJournalTemplate.Name);
    end;

    local procedure ClearBackgroundCheckNotifications()
    var
        MyNotifications: Record "My Notifications";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        if MyNotifications.Get(UserId(), DocumentErrorsMgt.GetShowDocumentCheckFactboxNotificationID()) then
            MyNotifications.Delete();
        if MyNotifications.Get(UserId(), DocumentErrorsMgt.GetEnableBackgroundValidationNotificationID()) then
            MyNotifications.Delete();
    end;

    local procedure UpdateShowDocumentCheckFactboxNotification(Enabled: Boolean)
    var
        MyNotifications: Record "My Notifications";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        if not MyNotifications.Get(UserId(), DocumentErrorsMgt.GetShowDocumentCheckFactboxNotificationID()) then
            if Enabled then
                DocumentErrorsMgt.EnableShowDocumentCheckFactboxNotification()
            else
                DocumentErrorsMgt.DisableShowDocumentCheckFactboxNotification()
        else begin
            MyNotifications.Enabled := Enabled;
            MyNotifications.Modify();
        end;
    end;

    local procedure UpdateServiceMgtSetupMandatoryUOM()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Unit of Measure Mandatory", true);
        ServiceMgtSetup.Modify();
    end;

    local procedure PrepareFullSalesDocCheckArgs(SalesHeader: Record "Sales Header"; var Args: Dictionary of [Text, Text])
    var
        ErrorHandlingParameters: Record "Error Handling Parameters";
    begin
        ErrorHandlingParameters."Document No." := SalesHeader."No.";
        ErrorHandlingParameters."Sales Document Type" := SalesHeader."Document Type";
        ErrorHandlingParameters."Full Document Check" := true;
        ErrorHandlingParameters.ToArgs(Args);
    end;

    local procedure VerifyNotificationOff()
    var
        MyNotifications: Record "My Notifications";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        MyNotifications.Get(UserId, DocumentErrorsMgt.GetEnableBackgroundValidationNotificationID());
        MyNotifications.TestField(Enabled, false);
    end;

    local procedure VerifyNotificationsCreated()
    var
        MyNotifications: Record "My Notifications";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        Assert.IsTrue(MyNotifications.Get(UserId, DocumentErrorsMgt.GetEnableBackgroundValidationNotificationID()), 'Notification Enable Data Check must be created');
        Assert.IsTrue(MyNotifications.Get(UserId, DocumentErrorsMgt.GetShowDocumentCheckFactboxNotificationID()), 'Notification Show the Document Check Factbox must be created');
        MyNotifications.TestField(Enabled, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnCheckAndUpdateOnAfterSetPostingFlags', '', false, false)]
    local procedure OnCheckAndUpdateOnAfterSetPostingFlags(var SalesHeader: Record "Sales Header"; var TempSalesLineGlobal: Record "Sales Line" temporary; var ModifyHeader: Boolean)
    begin
        if SalesHeader."Posting Description" = CheckUnhandledErrorTxt then
            Error(CheckUnhandledErrorTxt);
    end;

    [SendNotificationHandler]
    procedure BackgroundValidationShowSetupNotificationHandler(var BackgroundValidationNotification: Notification): Boolean
    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        DocumentErrorsMgt.EnableShowDocumentCheckFactbox(BackgroundValidationNotification);
    end;

    [SendNotificationHandler]
    procedure BackgroundValidationDontShowAgainNotificationHandler(var BackgroundValidationNotification: Notification): Boolean
    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        DocumentErrorsMgt.DisableBackgroundValidationNotification();
    end;
}