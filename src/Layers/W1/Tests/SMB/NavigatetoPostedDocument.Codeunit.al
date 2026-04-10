codeunit 138047 "Navigate to Posted Document"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [My Settings] [Confirm After Posting Documents] [UI]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        EnabledValue: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostSalesInvoiceWithNavigate()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [GIVEN] a sales invoice, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the sales invoice
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        PostedSalesInvoice.Trap();
        SalesInvoice.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted sales invoice
        PostedSalesInvoice."Sell-to Customer Name".AssertEquals(SalesHeader."Sell-to Customer Name");
        PostedSalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure S475203_TestPostSalesInvoiceWithNavigate_EqualNoSeries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        xSalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [UI] [Customer] [Sales Invoice] [Posted Sales Invoice] [Notification on Posting Document]
        // [SCENARIO 475203] Notification on Posting Document is shown when posting Sales Invoice with equal No. Series and Posting No. Series.

        // [GIVEN] Set "Posted Invoice Nos." to be the same as "Invoice Nos.".
        SalesReceivablesSetup.Get();
        xSalesReceivablesSetup := SalesReceivablesSetup;
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", SalesReceivablesSetup."Invoice Nos.");
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] a sales invoice, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        DisableConfirmAfterPosting(); // This is needed in order to make enabled.
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the sales invoice
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        PostedSalesInvoice.Trap();
        SalesInvoice.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted sales invoice
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvoiceHeader.FindLast();
        PostedSalesInvoice."No.".AssertEquals(SalesInvoiceHeader."No.");
        PostedSalesInvoice.Close();

        // [Teardown] Reverse "Posted Invoice Nos." to the original value.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", xSalesReceivablesSetup."Posted Invoice Nos.");
        SalesReceivablesSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure S475203_TestPostSalesInvoiceWithNavigate_RepeatPreAssignedNo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        NoSeriesCodeunit: Codeunit "No. Series";
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        LastNoUsedToRepeat: Code[20];
        InvoiceNoToRepeat: Code[20];
        FirstPostedSalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [UI] [Customer] [Sales Invoice] [Posted Sales Invoice] [Notification on Posting Document] [Number Series]
        // [SCENARIO 475203] Notification on Posting Document is shows 2nd Posted Sales Invoice when Pre-Assigned No. is repeated.

        // [GIVEN] Find last No. Series Line for "Invoice Nos.".
        SalesReceivablesSetup.Get();
        NoSeries.Get(SalesReceivablesSetup."Invoice Nos.");
        NoSeriesCodeunit.GetNoSeriesLine(NoSeriesLine, NoSeries.Code, 0D, true);
        NoSeriesLine.FindLast();
        LastNoUsedToRepeat := NoSeriesCodeunit.GetLastNoUsed(NoSeries.Code);

        // [GIVEN] Create 1st Sales Invoice and post it.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        InvoiceNoToRepeat := SalesHeader."No.";
        FirstPostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Set "Last No. Used" to be the same as before 1st Sales Invoice.
        NoSeriesLine.GetBySystemId(NoSeriesLine.SystemId);
        NoSeriesLine.Validate("Last No. Used", LastNoUsedToRepeat);
        NoSeriesLine.Modify(true);

        // [WHEN] Create 2nd Sales Invoice.
        Clear(SalesHeader);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [THEN] Check that "No." is the same as for 1st Sales Invoice.
        SalesHeader.TestField("No.", InvoiceNoToRepeat);

        // [GIVEN] "Confirm After Posting Documents" enabled in "My Settings" window
        DisableConfirmAfterPosting(); // This is needed in order to make enabled.
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the sales invoice
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        PostedSalesInvoice.Trap();
        SalesInvoice.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted sales invoice
        SalesInvoiceHeader.SetFilter("No.", '<>%1', FirstPostedSalesInvoiceNo);
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvoiceHeader.FindLast();
        PostedSalesInvoice."No.".AssertEquals(SalesInvoiceHeader."No.");
        PostedSalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostSalesInvoiceWithoutNavigate()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [GIVEN] a sales invoice, and "Confirm After Posting Documents" disabled in "My Settings" window
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        DisableConfirmAfterPosting();

        // [WHEN] the user posts the sales invoice
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.Post.Invoke();

        // [THEN] the user will not get a confirmation dialog to open the posted sales invoice
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostSalesCreditMemoWithNavigate()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [GIVEN] a sales credit memo, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the sales credit memo
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        PostedSalesCreditMemo.Trap();
        SalesCreditMemo.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted sales credit memo
        PostedSalesCreditMemo."Sell-to Customer Name".AssertEquals(SalesHeader."Sell-to Customer Name");
        PostedSalesCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostSalesCreditMemoNoWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [GIVEN] a sales credit memo, and "Confirm After Posting Documents" disabled in "My Settings" window
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        DisableConfirmAfterPosting();

        // [WHEN] the user posts the sales credit memo
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.Post.Invoke();

        // [THEN] the user will not get a confirmation dialog to open the posted sales credit memo
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,StrMenuHandlerOK,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostSalesOrderWithNavigate()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [GIVEN] a sales order, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the sales order
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        PostedSalesInvoice.Trap();
        SalesOrder.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted sales invoice
        PostedSalesInvoice."Sell-to Customer Name".AssertEquals(SalesHeader."Sell-to Customer Name");
        PostedSalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostSalesOrderWithoutNavigate()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [GIVEN] a sales order, and "Confirm After Posting Documents" disabled in "My Settings" window
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        DisableConfirmAfterPosting();

        // [WHEN] the user posts the sales invoice
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.Post.Invoke();

        // [THEN] the user will not get a confirmation dialog to open the posted sales invoice
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,StrMenuHandlerOK,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostSalesReturnOrderWithNavigate()
    var
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [GIVEN] a sales return order, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order");
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the sales return order
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        PostedSalesCreditMemo.Trap();
        SalesReturnOrder.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted sales credit memo
        PostedSalesCreditMemo."Sell-to Customer Name".AssertEquals(SalesHeader."Sell-to Customer Name");
        PostedSalesCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostSalesReturnOrderWithoutNavigate()
    var
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [GIVEN] a sales return order, and "Confirm After Posting Documents" disabled in "My Settings" window
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order");
        DisableConfirmAfterPosting();

        // [WHEN] the user posts the sales return order
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.Post.Invoke();

        // [THEN] the user will not get a confirmation dialog to open the posted sales credit memo
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostPurchaseInvoiceWithNavigate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [GIVEN] a purchase invoice, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the purchase invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PostedPurchaseInvoice.Trap();
        PurchaseInvoice.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted purchase invoice
        PostedPurchaseInvoice."Buy-from Vendor Name".AssertEquals(PurchaseHeader."Buy-from Vendor Name");
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostPurchaseInvoiceWithoutNavigate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [GIVEN] a purchase invoice, and "Confirm After Posting Documents" disabled in "My Settings" window
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        DisableConfirmAfterPosting();

        // [WHEN] the user posts the purchase invoice
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.Post.Invoke();

        // [THEN] the user will not get a confirmation dialog to open the posted purchase invoice
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostPurchaseCreditMemoWithNavigate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [GIVEN] a purchase credit memo, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the purchase credit memo
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PostedPurchaseCreditMemo.Trap();
        PurchaseCreditMemo.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted purchase credit memo
        PostedPurchaseCreditMemo."Buy-from Vendor Name".AssertEquals(PurchaseHeader."Buy-from Vendor Name");
        PostedPurchaseCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostPurchaseCreditMemoWithoutNavigate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [GIVEN] a purchase credit memo, and "Confirm After Posting Documents" disabled in "My Settings" window
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        DisableConfirmAfterPosting();

        // [WHEN] the user posts the purchase credit memo
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.Post.Invoke();

        // [THEN] the user will not get a confirmation dialog to open the posted purchase credit memo
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,StrMenuHandlerOK,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostPurchaseOrderWithNavigate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [GIVEN] a purchase order, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        ClearTable(DATABASE::"Warehouse Receipt Line");
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the purchase order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PostedPurchaseInvoice.Trap();
        PurchaseOrder.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted purchase invoice
        PostedPurchaseInvoice."Buy-from Vendor Name".AssertEquals(PurchaseHeader."Buy-from Vendor Name");
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostPurchaseOrderWithoutNavigate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [GIVEN] a purchase order, and "Confirm After Posting Documents" disabled in "My Settings" window
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        ClearTable(DATABASE::"Warehouse Receipt Line");
        DisableConfirmAfterPosting();

        // [WHEN] the user posts the purchase order
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.Post.Invoke();

        // [THEN] the user will not get a confirmation dialog to open the posted purchase invoice
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,StrMenuHandlerOK,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostPurchaseReturnOrderWithNavigate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        // [GIVEN] a purchase return order, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the purchase order
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PostedPurchaseCreditMemo.Trap();
        PurchaseReturnOrder.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted purchase credit memo
        PostedPurchaseCreditMemo."Buy-from Vendor Name".AssertEquals(PurchaseHeader."Buy-from Vendor Name");
        PostedPurchaseCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostPurchaseReturnOrderWithoutNavigate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [GIVEN] a purchase return order, and "Confirm After Posting Documents" disabled in "My Settings" window
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");
        DisableConfirmAfterPosting();

        // [WHEN] the user posts the purchase order
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.Post.Invoke();

        // [THEN] the user will not get a confirmation dialog to open the posted purchase credit memo
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostServiceInvoiceWithNavigate()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [GIVEN] a service invoice, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the service invoice
        ServiceInvoice.OpenEdit();
        ServiceInvoice.GotoRecord(ServiceHeader);
        PostedServiceInvoice.Trap();
        ServiceInvoice.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted service invoice
        PostedServiceInvoice."Customer No.".AssertEquals(ServiceHeader."Customer No.");
        PostedServiceInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostServiceInvoiceWithoutNavigate()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [GIVEN] a service invoice, and "Confirm After Posting Documents" disabled in "My Settings" window
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        DisableConfirmAfterPosting();

        // [WHEN] the user posts the service invoice
        ServiceInvoice.OpenEdit();
        ServiceInvoice.GotoRecord(ServiceHeader);
        ServiceInvoice.Post.Invoke();

        // [THEN] the user will not get a confirmation dialog to open the posted service invoice
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostServiceCreditMemoWithNavigate()
    var
        ServiceHeader: Record "Service Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
    begin
        // [GIVEN] a service credit memo, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the service credit memo
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        PostedServiceCreditMemo.Trap();
        ServiceCreditMemo.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted service credit memo
        PostedServiceCreditMemo."Customer No.".AssertEquals(ServiceHeader."Customer No.");
        PostedServiceCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostServiceCreditMemoWithoutNavigate()
    var
        ServiceHeader: Record "Service Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [GIVEN] a service credit memo, and "Confirm After Posting Documents" disabled in "My Settings" window
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        DisableConfirmAfterPosting();

        // [WHEN] the user posts the service credit memo
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        ServiceCreditMemo.Post.Invoke();

        // [THEN] the user will not get a confirmation dialog to open the posted service credit memo
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,StrMenuHandlerOK,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostServiceOrderWithNavigate()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [GIVEN] a service order, and "Confirm After Posting Documents" enabled in "My Settings" window
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);
        EnableConfirmAfterPosting();

        // [WHEN] the user posts the service order
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        PostedServiceInvoice.Trap();
        ServiceOrder.Post.Invoke();

        // [THEN] the user will get a confirmation dialog to open the posted service invoice
        PostedServiceInvoice."Customer No.".AssertEquals(ServiceHeader."Customer No.");
        PostedServiceInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK,MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestPostServiceOrderWithoutNavigate()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        // [GIVEN] a service order, and "Confirm After Posting Documents" disabled in "My Settings" window
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);
        DisableConfirmAfterPosting();

        // [WHEN] the user posts the service order
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.Post.Invoke();

        // [THEN] the user will not get a confirmation dialog to open the posted service invoice
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Navigate to Posted Document");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Navigate to Posted Document");

        ClearTable(DATABASE::"Job Planning Line");
        ClearTable(DATABASE::"Service Document Log");
        ClearTable(DATABASE::"Service Item Component");
        ClearTable(DATABASE::"Troubleshooting Setup");
        ClearTable(DATABASE::Resource);

        LibraryERMCountryData.CreateVATData();
        CreateUserPersonalization();

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Navigate to Posted Document");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
        TroubleshootingSetup: Record "Troubleshooting Setup";
        Resource: Record Resource;
        ServiceItemComponent: Record "Service Item Component";
        ServiceDocumentLog: Record "Service Document Log";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::"Job Planning Line":
                JobPlanningLine.DeleteAll();
            DATABASE::"Troubleshooting Setup":
                TroubleshootingSetup.DeleteAll();
            DATABASE::Resource:
                Resource.DeleteAll();
            DATABASE::"Service Document Log":
                ServiceDocumentLog.DeleteAll();
            DATABASE::"Service Item Component":
                ServiceItemComponent.DeleteAll();
            DATABASE::"Warehouse Receipt Line":
                WarehouseReceiptLine.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    local procedure CreateUserPersonalization()
    var
        UserPersonalization: Record "User Personalization";
    begin
        if not UserPersonalization.Get(UserSecurityId()) then begin
            UserPersonalization.Validate("User SID", UserSecurityId());
            UserPersonalization.Insert();
        end;
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
    begin
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate(Quantity, 1);
        ServiceLine."Service Item Line No." := LibraryRandom.RandInt(1000);
        ServiceLine.Modify();
    end;

    local procedure EnableConfirmAfterPosting()
    begin
        ChangeWarningOnCloseUnpostedDoc(true);
    end;

    local procedure DisableConfirmAfterPosting()
    begin
        ChangeWarningOnCloseUnpostedDoc(false);
    end;

    local procedure ChangeWarningOnCloseUnpostedDoc(Value: Boolean)
    var
        UserSettings: TestPage "User Settings";
    begin
        UserSettings.OpenEdit();
        EnabledValue := Value;
        UserSettings.MyNotificationsLbl.DrillDown();
        UserSettings.Close();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandlerOK(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 3;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MyNotificationsModalPageHandler(var MyNotifications: TestPage "My Notifications")
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        MyNotifications.FILTER.SetFilter("Notification Id", InstructionMgt.GetOpeningPostedDocumentNotificationId());
        MyNotifications.Enabled.SetValue(EnabledValue);
    end;
}

