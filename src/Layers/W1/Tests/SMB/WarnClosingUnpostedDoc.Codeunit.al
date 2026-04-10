codeunit 138046 "Warn Closing Unposted Doc"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [My Settings] [Confirm Closing Document] [UI]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        DocumentNotPostedClosePageQst: Label 'The document has been saved but is not yet posted.\\Are you sure you want to exit?';
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryERM: Codeunit "Library - ERM";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        isInitialized: Boolean;
        OrderNotUnreleasedCloseQst: Label 'The document has not been released.\Are you sure you want to exit?';

    [Test]
    [HandlerFunctions('CloseUnpostedConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedSalesInvoiceWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Unposted] [Sales] [Invoice]
        // [SCENARIO 275553] Notification is on, closing unposted Invoice brings up notification
        // [GIVEN] Sales Invoice document
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        // [GIVEN] Page opened
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [WHEN] Page closed
        SalesInvoice.Close();
        // [THEN] Page closes with UI Confirm
        Assert.AreEqual(
          DocumentNotPostedClosePageQst, LibraryVariableStorage.DequeueText(), 'CloseUnpostedConfirmHandler');
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedSalesInvoiceNoWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Unposted] [Sales] [Invoice]
        // [SCENARIO 275553] Notification is off, closing unposted Invoice doesn't bring up notification
        // [GIVEN] Sales Invoice document
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        // [GIVEN] Notification for unposted documents disabled
        DisableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        // [WHEN] Page closed
        SalesInvoice.Close();
        // [THEN] Page closes without UI Confirm
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedSalesCreditMemoWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Unposted] [Sales] [Credit Memo]
        // [SCENARIO 275553] Notification is on, closing unposted Credit Memo doesn't bring up notification
        // [GIVEN] Sales Credit Memo document
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        // [WHEN] Page closed
        SalesCreditMemo.Close();
        // [THEN] Page closes without UI Confirm
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedSalesCreditMemoNoWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Unposted] [Sales] [Credit Memo]
        // [SCENARIO 275553] Notification is off, closing unposted Credit Memo doesn't bring up notification
        // [GIVEN] Sales Credit Memo document
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        // [GIVEN] Notification for unposted documents disabled
        DisableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        // [WHEN] Page closed
        SalesCreditMemo.Close();
        // [THEN] Page closes without UI Confirm
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedSalesOrderWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Unposted] [Sales] [Order]
        // [SCENARIO 275553] Notification is on, closing unposted Order doesn't bring up notification
        // [GIVEN] Sales Order document
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Notification for unreleased documents disabled
        DisableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Page opened
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        // [WHEN] Page closed
        SalesOrder.Close();
        // [THEN] Page closes without UI Confirm
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedSalesOrderNoWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Unposted] [Sales] [Order]
        // [SCENARIO 275553] Notification is off, closing unposted Order doesn't bring up notification
        // [GIVEN] Sales Order document
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        // [GIVEN] Notification for unposted and unreleased documents disabled
        DisableWarningOnCloseUnpostedDoc();
        DisableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Page opened
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        // [WHEN] Page closed
        SalesOrder.Close();
        // [THEN] Page closes without UI Confirm
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedSalesReturnOrderWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Unposted] [Sales] [Return Order]
        // [SCENARIO 275553] Notification is on, closing unposted Return Order doesn't bring up notification
        // [GIVEN] Sales Return Order document
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order");
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        // [WHEN] Page closed
        SalesReturnOrder.Close();
        // [THEN] Page closes without UI Confirm
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedSalesReturnOrderNoWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Unposted] [Sales] [Return Order]
        // [SCENARIO 275553] Notification is off, closing unposted Return Order doesn't bring up notification
        // [GIVEN] Sales Return Order document
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order");
        // [GIVEN] Notification for unposted documents disabled
        DisableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        // [WHEN] Page closed
        SalesReturnOrder.Close();
        // [THEN] Page closes without UI Confirm
        SalesHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('CloseUnpostedConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedPurchaseInvoiceWarning()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Unposted] [Purchase] [Invoice]
        // [SCENARIO 275553] Notification is on, closing unposted Invoice brings up notification
        // [GIVEN] Purchase Invoice document
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        // [WHEN] Page closed
        PurchaseInvoice.Close();
        // [THEN] Page closes with UI Confirm
        Assert.AreEqual(
          DocumentNotPostedClosePageQst, LibraryVariableStorage.DequeueText(), 'CloseUnpostedConfirmHandler');
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedPurchaseInvoiceNoWarning()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Unposted] [Purchase] [Invoice]
        // [SCENARIO 275553] Notification is off, closing unposted Invoice doesn't bring up notification
        // [GIVEN] Purchase Invoice document
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        // [GIVEN] Notification for unposted documents disabled
        DisableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        // [WHEN] Page closed
        PurchaseInvoice.Close();
        // [THEN] Page closes without UI Confirm
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedPurchaseCreditMemoWarning()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Unposted] [Purchase] [Credit Memo]
        // [SCENARIO 275553] Notification is on, closing unposted Credit Memo doesn't bring up notification
        // [GIVEN] Purchase Credit Memo document
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        // [WHEN] Page closed
        PurchaseCreditMemo.Close();
        // [THEN] Page closes without UI Confirm
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedPurchaseCreditMemoNoWarning()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Unposted] [Purchase] [Credit Memo]
        // [SCENARIO 275553] Notification is off, closing unposted Credit Memo doesn't bring up notification
        // [GIVEN] Purchase Credit Memo document
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        // [GIVEN] Notification for unposted documents disabled
        DisableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        // [WHEN] Page closed
        PurchaseCreditMemo.Close();
        // [THEN] Page closes without UI Confirm
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedPurchaseOrderWarning()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Unposted] [Purchase] [Order]
        // [SCENARIO 275553] Notification is on, closing unposted Purchase Order doesn't bring up notification
        // [GIVEN] Purchase Order document
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        ClearTable(DATABASE::"Warehouse Receipt Line");
        // [GIVEN] Notification for unreleased documents disabled
        DisableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        // [WHEN] Page closed
        PurchaseOrder.Close();
        // [THEN] Page closes without UI Confirm
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedPurchaseOrderNoWarning()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Unposted] [Purchase] [Order]
        // [SCENARIO 275553] Notification is off, closing unposted Order doesn't bring up notification
        // [GIVEN] Purchase Order document
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        ClearTable(DATABASE::"Warehouse Receipt Line");
        // [GIVEN] Notification for unposted and unreleased documents disabled
        DisableWarningOnCloseUnreleasedOrders();
        DisableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        // [WHEN] Page closed
        PurchaseOrder.Close();
        // [THEN] Page closes without UI Confirm
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedPurchaseReturnOrderWarning()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Unposted] [Purchase] [Return Order]
        // [SCENARIO 275553] Notification is on, closing unposted Return Order doesn't bring up notification
        // [GIVEN] Purchase Return Order document
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        // [WHEN] Page closed
        PurchaseReturnOrder.Close();
        // [THEN] Page closes without UI Confirm
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedPurchaseReturnOrderNoWarning()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Unposted] [Purchase] [Return Order]
        // [SCENARIO 275553] Notification is off, closing unposted Return Order doesn't bring up notification
        // [GIVEN] Purchase Return Order document
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");
        // [GIVEN] Notification for unposted documents disabled
        DisableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        // [WHEN] Page closed
        PurchaseReturnOrder.Close();
        // [THEN] Page closes without UI Confirm
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('CloseUnpostedConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedServiceInvoiceWarning()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Unposted] [Service] [Invoice]
        // [SCENARIO 275553] Notification is on, closing unposted Invoice brings up notification
        // [GIVEN] Service Invoice document
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        ServiceInvoice.OpenEdit();
        ServiceInvoice.GotoRecord(ServiceHeader);
        // [WHEN] Page closed
        ServiceInvoice.Close();
        // [THEN] Page closes with UI Confirm
        Assert.AreEqual(
          DocumentNotPostedClosePageQst, LibraryVariableStorage.DequeueText(), 'CloseUnpostedConfirmHandler');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedServiceInvoiceNoWarning()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Unposted] [Service] [Invoice]
        // [SCENARIO 275553] Notification is off, closing unposted Invoice doesn't bring up notification
        // [GIVEN] Service Invoice document
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        // [GIVEN] Notification for unposted documents disabled
        DisableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        ServiceInvoice.OpenEdit();
        ServiceInvoice.GotoRecord(ServiceHeader);
        // [WHEN] Page closed
        ServiceInvoice.Close();
        // [THEN] Page closes without UI Confirm
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedServiceCreditMemoWarning()
    var
        ServiceHeader: Record "Service Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [FEATURE] [Unposted] [Service] [Credit Memo]
        // [SCENARIO 275553] Notification is on, closing unposted Credit Memo doesn't bring up notification
        // [GIVEN] Service Credit Memo document
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        // [WHEN] Page closed
        ServiceCreditMemo.Close();
        // [THEN] Page closes without UI Confirm
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedServiceCreditMemoNoWarning()
    var
        ServiceHeader: Record "Service Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [FEATURE] [Unposted] [Service] [Credit Memo]
        // [SCENARIO 275553] Notification is off, closing unposted Credit Memo doesn't bring up notification
        // [GIVEN] Service Credit Memo document
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        // [GIVEN] Notification for unposted documents disabled
        DisableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        // [WHEN] Page closed
        ServiceCreditMemo.Close();
        // [THEN] Page closes without UI Confirm
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedServiceOrderWarning()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Unposted] [Service] [Order]
        // [SCENARIO 275553] Notification is on, closing unposted Order doesn't bring up notification
        // [GIVEN] Service Order document
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);
        ClearTable(DATABASE::"Repair Status");
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        // [WHEN] Page closed
        ServiceOrder.Close();
        // [THEN] Page closes without UI Confirm
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedServiceOrderNoWarning()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Unposted] [Service] [Order]
        // [SCENARIO 275553] Notification is off, closing unposted Order doesn't bring up notification
        // [GIVEN] Service Order document
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);
        ClearTable(DATABASE::"Repair Status");
        // [GIVEN] Notification for unposted documents disabled
        DisableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        // [WHEN] Page closed
        ServiceOrder.Close();
        // [THEN] Page closes without UI Confirm
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedSalesCreditMemoWarningWithEmptyNotifications()
    var
        MyNotifications: Record "My Notifications";
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Unposted] [Sales] [Credit Memo]
        // [SCENARIO 275553] Notification is on, Table My Notifications is empty, closing unposted Credit Memo doesn't bring up notification
        // [GIVEN] Sales Credit Memo document
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        // [GIVEN] Table My Notifications is empty
        MyNotifications.DeleteAll();
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        // [WHEN] Page closed
        SalesCreditMemo.Close();
        // [THEN] Page closes without UI Confirm
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedSalesOrderWarningWithEmptyNotifications()
    var
        MyNotifications: Record "My Notifications";
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Unposted] [Sales] [Order]
        // [SCENARIO 275553] Notification is on, Table My Notifications is empty, closing unposted Order doesn't bring up notification
        // [GIVEN] Sales Order document
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        // [GIVEN] Table My Notifications is empty
        MyNotifications.DeleteAll();
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Notification for unreleased documents disabled
        DisableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Page opened
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        // [WHEN] Page closed
        SalesOrder.Close();
        // [THEN] Page closes without UI Confirm
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedSalesReturnOrderWarningWithEmptyNotifications()
    var
        MyNotifications: Record "My Notifications";
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Unposted] [Sales] [Return Order]
        // [SCENARIO 275553] Notification is on, Table My Notifications is empty, closing unposted Return Order doesn't bring up notification
        // [GIVEN] Sales Return Order document
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order");
        // [GIVEN] Table My Notifications is empty
        MyNotifications.DeleteAll();
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        // [WHEN] Page closed
        SalesReturnOrder.Close();
        // [THEN] Page closes without UI Confirm
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedPurchaseCreditMemoWarningWithEmptyNotifications()
    var
        MyNotifications: Record "My Notifications";
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [Unposted] [Purchase] [Credit Memo]
        // [SCENARIO 275553] Notification is on, Table My Notifications is empty, closing unposted Credit Memo doesn't bring up notification
        // [GIVEN] Purchase Credit Memo document
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        // [GIVEN] Table My Notifications is empty
        MyNotifications.DeleteAll();
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        // [WHEN] Page closed
        PurchaseCreditMemo.Close();
        // [THEN] Page closes without UI Confirm
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedPurchaseOrderWarningWithEmptyNotifications()
    var
        MyNotifications: Record "My Notifications";
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Unposted] [Purchase] [Order]
        // [SCENARIO 275553] Notification is on, Table My Notifications is empty, closing unposted Purchase Order doesn't bring up notification
        // [GIVEN] Purchase Order document
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        ClearTable(DATABASE::"Warehouse Receipt Line");
        // [GIVEN] Table My Notifications is empty
        MyNotifications.DeleteAll();
        // [GIVEN] Notification for unreleased documents disabled
        DisableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        // [WHEN] Page closed
        PurchaseOrder.Close();
        // [THEN] Page closes without UI Confirm
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedPurchaseReturnOrderWarningWithEmptyNotifications()
    var
        MyNotifications: Record "My Notifications";
        PurchaseHeader: Record "Purchase Header";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [Unposted] [Purchase] [Return Order]
        // [SCENARIO 275553] Notification is on, Table My Notifications is empty, closing unposted Return Order doesn't bring up notification
        // [GIVEN] Purchase Return Order document
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order");
        // [GIVEN] Table My Notifications is empty
        MyNotifications.DeleteAll();
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        // [WHEN] Page closed
        PurchaseReturnOrder.Close();
        // [THEN] Page closes without UI Confirm
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedServiceCreditMemoWarningWithEmptyNotifications()
    var
        MyNotifications: Record "My Notifications";
        ServiceHeader: Record "Service Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [FEATURE] [Unposted] [Service] [Credit Memo]
        // [SCENARIO 275553] Notification is on, Table My Notifications is empty, closing unposted Credit Memo doesn't bring up notification
        // [GIVEN] Service Credit Memo document
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        // [GIVEN] Table My Notifications is empty
        MyNotifications.DeleteAll();
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.GotoRecord(ServiceHeader);
        // [WHEN] Page closed
        ServiceCreditMemo.Close();
        // [THEN] Page closes without UI Confirm
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCloseUnpostedServiceOrderWarningWithEmptyNotifications()
    var
        MyNotifications: Record "My Notifications";
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Unposted] [Service] [Order]
        // [SCENARIO 275553] Notification is on, Table My Notifications is empty, closing unposted Order doesn't bring up notification
        // [GIVEN] Service Order document
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);
        ClearTable(DATABASE::"Repair Status");
        // [GIVEN] Table My Notifications is empty
        MyNotifications.DeleteAll();
        // [GIVEN] Notification for unposted documents enabled with default filter for Document Type: Invoice
        EnableWarningOnCloseUnpostedDoc();
        // [GIVEN] Page opened
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        // [WHEN] Page closed
        ServiceOrder.Close();
        // [THEN] Page closes without UI Confirm
    end;

    [Test]
    [HandlerFunctions('UnreleasedConfirmHandlerYES')]
    [Scope('OnPrem')]
    procedure UnreleasedSalesRequireShipmentWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        SalesOrder: TestPage "Sales Order";
        MyQuery: Query "Locations from items Sales";
    begin
        // [FEATURE] [Unreleased] [Order] [Sales]
        // [SCENARIO 275555] Query returns at least one line with location that has "Require Shipment" enabled, notification shows
        InitUnreleasedTests();

        // [GIVEN] Sale order page was open
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        // [GIVEN] Order was not released
        SalesHeader.Status := SalesHeader.Status::Open;
        // [GIVEN] Notification for not released orders was enabled
        EnableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Query returns a line with Require Shipment = true
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        CreateSalesLineWithLocation(SalesLine, SalesHeader,
          Location.Code, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        MyQuery.SetRange(Document_No, SalesHeader."No.");
        MyQuery.SetRange(Require_Shipment, true);
        MyQuery.Open();
        Assert.IsTrue(MyQuery.Read(), 'Query 5001 must return one line on this input');

        // [WHEN] User presses "close page"
        SalesOrder.Close();

        // [THEN] Notification for the unreleased document pops up
        Assert.AreEqual(OrderNotUnreleasedCloseQst, LibraryVariableStorage.DequeueText(), 'UnreleasedConfirmHandlerYES');
    end;

    [Test]
    [HandlerFunctions('UnreleasedConfirmHandlerYES')]
    [Scope('OnPrem')]
    procedure UnreleasedSalesRequirePickWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        SalesOrder: TestPage "Sales Order";
        MyQuery: Query "Locations from items Sales";
    begin
        // [FEATURE] [Unreleased] [Order] [Sales]
        // [SCENARIO 275555] Query returns at least one line with location that has "Require Pick" enabled, notification shows
        InitUnreleasedTests();

        // [GIVEN] Sale order page was open
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        // [GIVEN] Order was not released
        SalesHeader.Status := SalesHeader.Status::Open;
        // [GIVEN] Notification for not released orders was enabled
        EnableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Query returns a line with Require Pick = true
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        CreateSalesLineWithLocation(SalesLine, SalesHeader, Location.Code,
          SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        MyQuery.SetRange(Document_No, SalesHeader."No.");
        MyQuery.SetRange(Require_Pick, true);
        MyQuery.Open();
        Assert.IsTrue(MyQuery.Read(), 'Query 5001 must return one line on this input');

        // [WHEN] User presses "close page"
        SalesOrder.Close();

        // [THEN] Notification for the unreleased document pops up
        Assert.AreEqual(OrderNotUnreleasedCloseQst, LibraryVariableStorage.DequeueText(), 'UnreleasedConfirmHandlerYES');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnreleasedSalesNoPickOrShipmentNoWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        SalesOrder: TestPage "Sales Order";
        MyQuery: Query "Locations from items Sales";
    begin
        // [FEATURE] [Unreleased] [Order] [Sales]
        // [SCENARIO 275555] Query returns no lines that have Require Pick or Require Shipment enabled, notification doesn't show
        InitUnreleasedTests();

        // [GIVEN] Sale order page was open
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        // [GIVEN] Order was not released
        SalesHeader.Status := SalesHeader.Status::Open;
        // [GIVEN] Notification for not released orders was enabled
        EnableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Query returns no lines with Require Pick = true and no lines with Require Shipment = true
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, true, false);
        CreateSalesLineWithLocation(SalesLine, SalesHeader, Location.Code,
          SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        CreateSalesLineWithLocation(SalesLine, SalesHeader, Location.Code,
          SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        MyQuery.SetRange(Document_No, SalesHeader."No.");
        MyQuery.SetRange(Require_Pick, true);
        MyQuery.Open();
        Assert.IsFalse(MyQuery.Read(), 'Query 5001 must return no lines on this input');
        MyQuery.SetRange(Require_Pick);
        MyQuery.SetRange(Require_Shipment, true);
        MyQuery.Open();
        Assert.IsFalse(MyQuery.Read(), 'Query 5001 must return no lines on this input');

        // [WHEN] User presses "close page"
        SalesOrder.Close();

        // [THEN] Page closes with no warning
    end;

    [Test]
    [HandlerFunctions('UnreleasedConfirmHandlerYES')]
    [Scope('OnPrem')]
    procedure UnreleasedPurchaseRequireReceiveWarning()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        PurchaseOrder: TestPage "Purchase Order";
        MyQuery: Query "Locations from items Purch";
    begin
        // [FEATURE] [Unreleased] [Order] [Purchase]
        // [SCENARIO 275555] Query returns at least one line with location that has "Require Receive" enabled, notification shows
        InitUnreleasedTests();

        // [GIVEN] Purchase order page is open
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        // [GIVEN] Order is not released
        PurchaseHeader.Status := PurchaseHeader.Status::Open;
        // [GIVEN] Notification for not released orders was enabled
        EnableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Query returns a line with "Require Receive" = true
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, true, false);
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader,
          Location.Code, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        MyQuery.SetRange(Document_No, PurchaseHeader."No.");
        MyQuery.SetRange(Require_Receive, true);
        MyQuery.Open();
        Assert.IsTrue(MyQuery.Read(), 'Query 5002 must return one line on this input');

        // [WHEN] User presses "close page"
        PurchaseOrder.Close();

        // [THEN] Notification for the unreleased document pops up
        Assert.AreEqual(OrderNotUnreleasedCloseQst, LibraryVariableStorage.DequeueText(), 'UnreleasedConfirmHandlerYES');
    end;

    [Test]
    [HandlerFunctions('UnreleasedConfirmHandlerYES')]
    [Scope('OnPrem')]
    procedure UnreleasedPurchaseRequirePutawayWarning()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        PurchaseOrder: TestPage "Purchase Order";
        MyQuery: Query "Locations from items Purch";
    begin
        // [FEATURE] [Unreleased] [Order] [Purchase]
        // [SCENARIO 275555] Query returns at least one line with location that has "Require Put-away" enabled, notification shows
        InitUnreleasedTests();

        // [GIVEN] Purchase order page is open
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        // [GIVEN] Order is not released
        PurchaseHeader.Status := PurchaseHeader.Status::Open;
        // [GIVEN] Notification for not released orders was enabled
        EnableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Query returns a line with "Require Put-away" = true
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader,
          Location.Code, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        MyQuery.SetRange(Document_No, PurchaseHeader."No.");
        MyQuery.SetRange(Require_Put_away, true);
        MyQuery.Open();
        Assert.IsTrue(MyQuery.Read(), 'Query 5002 must return one line on this input');

        // [WHEN] User presses "close page"
        PurchaseOrder.Close();

        // [THEN] Notification for the unreleased document pops up
        Assert.AreEqual(OrderNotUnreleasedCloseQst, LibraryVariableStorage.DequeueText(), 'UnreleasedConfirmHandlerYES');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnreleasedPurchaseNoReceiveOrPutawayNoWarning()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        PurchaseOrder: TestPage "Purchase Order";
        MyQuery: Query "Locations from items Purch";
    begin
        // [FEATURE] [Unreleased] [Order] [Purchase]
        // [SCENARIO 275555] Query returns no lines that have "Require Put-away"or "Require Receive" enabled, notification doesn't show
        InitUnreleasedTests();

        // [GIVEN] Sale order page was open
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        // [GIVEN] Order was not released
        PurchaseHeader.Status := PurchaseHeader.Status::Open;
        // [GIVEN] Notification for not released orders was enabled
        EnableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Query returns no lines with "Require Put-away" = true and no lines with "Require Receive" = true
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader,
          Location.Code, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        MyQuery.SetRange(Document_No, PurchaseHeader."No.");
        MyQuery.SetRange(Require_Put_away, true);
        MyQuery.Open();
        Assert.IsFalse(MyQuery.Read(), 'Query 5002 must return no lines on this input');
        MyQuery.SetRange(Require_Put_away);
        MyQuery.SetRange(Require_Receive, true);
        MyQuery.Open();
        Assert.IsFalse(MyQuery.Read(), 'Query 5002 must return no lines on this input');

        // [WHEN] User presses "close page"
        PurchaseOrder.Close();

        // [THEN] Page closes with no warning
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedOrderNoWarning()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        SalesOrder: TestPage "Sales Order";
        MyQuery: Query "Locations from items Sales";
    begin
        // [FEATURE] [Unreleased] [Order]
        // [SCENARIO 275555] Order is released, notification is enabled but not shown
        InitUnreleasedTests();

        // [GIVEN] Sale order page was open
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        // [GIVEN] Order was released
        SalesHeader.Status := SalesHeader.Status::Released;
        // [GIVEN] Notification for not released orders was disabled
        DisableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Query returns a line with Require Shipment = true
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        CreateSalesLineWithLocation(SalesLine, SalesHeader,
          Location.Code, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        MyQuery.SetRange(Document_No, SalesHeader."No.");
        MyQuery.SetRange(Require_Shipment, true);
        MyQuery.Open();
        Assert.IsTrue(MyQuery.Read(), 'Query 5001 must return one line on this input');

        // [WHEN] User presses "close page"
        SalesOrder.Close();

        // [THEN] Page closes without notification
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnreleasedNotificationOffNoWarning()
    var
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Unreleased] [Order]
        // [SCENARIO 275555] Order is not released, but notification is disabled and not shown
        InitUnreleasedTests();

        // [GIVEN] Sale order page was open
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        // [GIVEN] Order was not released
        SalesHeader.Status := SalesHeader.Status::Open;
        // [GIVEN] Notification for not released orders was disabled
        DisableWarningOnCloseUnreleasedOrders();
        // [GIVEN] Company had at least one location that has "Require Shipment" enabled
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);

        // [WHEN] User presses "close page"
        SalesOrder.Close();

        // [THEN] Page closes without notification
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLinesItemsLocationsQueryInvoiceUT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        MyQuery: Query "Locations from items Sales";
    begin
        // [FEATURE] [UT] [Sales] [Location] [Query]
        // [SCENARIO 275555] Query 5001 returns empty for Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, true, true);
        CreateSalesLineWithLocation(SalesLine, SalesHeader,
          Location.Code, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        // Not an order (invoice), but with valid line
        MyQuery.SetRange(Document_No, SalesHeader."No.");
        MyQuery.Open();
        Assert.IsFalse(MyQuery.Read(), 'Query 5001 returned lines, but it must be empty on this input');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLinesItemsLocationsQueryEmptyOrderUT()
    var
        SalesHeader: Record "Sales Header";
        MyQuery: Query "Locations from items Sales";
    begin
        // [FEATURE] [UT] [Sales] [Location] [Query]
        // [SCENARIO 275555] Query 5001 returns empty for order with no lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        // Empty order
        MyQuery.SetRange(Document_No, SalesHeader."No.");
        MyQuery.Open();
        Assert.IsFalse(MyQuery.Read(), 'Query 5001 returned lines, but it must be empty on this input');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLinesItemsLocationsQueryInvalidLinesUT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        MyQuery: Query "Locations from items Sales";
    begin
        // [FEATURE] [UT] [Sales] [Location] [Query]
        // [SCENARIO 275555] Query 5001 returns empty for Order with lines that have type <> item, quantity = 0, location code = ''
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, true, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        // Three lines, each missing a vital part: 1st doesn't have a location, 2nd has quantity = 0, 3rd is not an item type
        CreateSalesLineWithLocation(SalesLine, SalesHeader, '',
          SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        CreateSalesLineWithLocation(SalesLine, SalesHeader, Location.Code, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 0);
        CreateSalesLineWithLocation(SalesLine, SalesHeader, Location.Code,
          SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(10));
        MyQuery.Open();
        Assert.IsFalse(MyQuery.Read(), 'Query 5001 returned lines, but it must be empty on this input');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLinesItemsLocationsQueryValidLineUT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        MyQuery: Query "Locations from items Sales";
    begin
        // [FEATURE] [UT] [Sales] [Location] [Query]
        // [SCENARIO 275555] Query 5001 returns Location."Require Pick" and Location."Require Receive" for Order
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, true, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        // A correct line
        CreateSalesLineWithLocation(SalesLine, SalesHeader, Location.Code,
          SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        MyQuery.Open();
        Assert.IsTrue(MyQuery.Read(), 'Query 5001 returned no lines, but it must return one line on this input');
        Assert.AreEqual(SalesHeader."No.", MyQuery.Document_No, 'Document No from query must match actual document No');
        Assert.AreEqual(Location.Code, MyQuery.Location_Code, 'Location code from query must match actual Location.Code');
        Assert.AreEqual(Location."Require Pick",
          MyQuery.Require_Pick, 'Require Pick form query must match actual Location."Require Pick"');
        Assert.AreEqual(Location."Require Shipment",
          MyQuery.Require_Shipment, 'Require Shipment form query must match actual Location."Require Shipment"');
        Assert.IsFalse(MyQuery.Read(), 'Query 5001 returned more than 1 line, but must return only 1 on this input');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLinesItemsLocationsQueryInvoiceUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        MyQuery: Query "Locations from items Purch";
    begin
        // [FEATURE] [UT] [Purchase] [Location] [Query]
        // [SCENARIO 275555] Query 5002 returns empty for Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, true, true);
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader, Location.Code,
          PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        // Not an order (invoice), but with valid line
        MyQuery.SetRange(Document_No, PurchaseHeader."No.");
        MyQuery.Open();
        Assert.IsFalse(MyQuery.Read(), 'Query 5002 returned lines, but it must be empty on this input');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLinesItemsLocationsQueryEmptyOrderUT()
    var
        PurchaseHeader: Record "Purchase Header";
        MyQuery: Query "Locations from items Purch";
    begin
        // [FEATURE] [UT] [Purchase] [Location] [Query]
        // [SCENARIO 275555] Query 5002 returns empty for order with no lines
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        // Empty order
        MyQuery.SetRange(Document_No, PurchaseHeader."No.");
        MyQuery.Open();
        Assert.IsFalse(MyQuery.Read(), 'Query 5002 returned lines, but it must be empty on this input');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLinesItemsLocationsQueryInvalidLinesUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        MyQuery: Query "Locations from items Purch";
    begin
        // [FEATURE] [UT] [Purchase] [Location] [Query]
        // [SCENARIO 275555] Query 5002 returns empty for Order with lines that have type <> item, quantity = 0, location code = ''
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, true, true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        // Three lines, each missing a vital part: 1st doesn't have a location, 2nd has quantity = 0, 3rd is not an item type
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader, '',
          PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader, Location.Code,
          PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 0);
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader, Location.Code,
          PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));
        MyQuery.Open();
        Assert.IsFalse(MyQuery.Read(), 'Query 5002 returned lines, but it must be empty on this input');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLinesItemsLocationsQueryValidLineUT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        MyQuery: Query "Locations from items Purch";
    begin
        // [FEATURE] [UT] [Purchase] [Location] [Query]
        // [SCENARIO 275555] Query 5002 returns Location."Require Pick" and Location."Require Receive" for Order
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, true, true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithLocation(PurchaseLine, PurchaseHeader, Location.Code,
          PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        MyQuery.Open();
        Assert.IsTrue(MyQuery.Read(), 'Query 5002 returned no lines, but it must return one line on this input');
        Assert.AreEqual(PurchaseHeader."No.", MyQuery.Document_No, 'Document No from query must match actual document No');
        Assert.AreEqual(Location.Code, MyQuery.Location_Code, 'Location code from query must match actual Location.Code');
        Assert.AreEqual(Location."Require Put-away",
          MyQuery.Require_Put_away, 'Require Put-away form query must match actual Location."Require Put-away"');
        Assert.AreEqual(Location."Require Receive",
          MyQuery.Require_Receive, 'Require Receive form query must match actual Location."Require Receive"');
        Assert.IsFalse(MyQuery.Read(), 'Query 5002 returned more than 1 line, but must return only 1 on this input');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerOK')]
    [Scope('OnPrem')]
    procedure TestPostSalesOrderNoConfirmAboutClosingUnposted()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup
        LibraryVariableStorage.Enqueue(true);
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesOrderHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, LibraryRandom.RandDecInRange(1, 100, 2));

        // Exercise
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        SalesOrder.Post.Invoke();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        MyNotificationsPage: Page "My Notifications";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Warn Closing Unposted Doc");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Warn Closing Unposted Doc");

        ClearTable(DATABASE::"Job Planning Line");
        ClearTable(DATABASE::"Service Document Log");
        ClearTable(DATABASE::"Service Item Component");
        ClearTable(DATABASE::"Troubleshooting Setup");
        ClearTable(DATABASE::Resource);

        LibraryERMCountryData.CreateVATData();
        CreateUserPersonalization();

        MyNotificationsPage.InitializeNotificationsWithDefaultState();

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Warn Closing Unposted Doc");
    end;

    local procedure InitUnreleasedTests()
    var
        Location: Record Location;
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
    begin
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        LibraryVariableStorage.Clear();
        Location.DeleteAll();
    end;

    local procedure ClearTable(TableID: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
        TroubleshootingSetup: Record "Troubleshooting Setup";
        Resource: Record Resource;
        ServiceItemComponent: Record "Service Item Component";
        ServiceDocumentLog: Record "Service Document Log";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        RepairStatus: Record "Repair Status";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::"Job Planning Line":
                JobPlanningLine.DeleteAll();
            DATABASE::"Troubleshooting Setup":
                TroubleshootingSetup.DeleteAll();
            DATABASE::Resource:
                Resource.DeleteAll();
            DATABASE::"Repair Status":
                RepairStatus.DeleteAll();
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

    local procedure CreateSalesLineWithLocation(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LocationCode: Code[10]; Type: Enum "Sales Document Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
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

    local procedure CreatePurchaseLineWithLocation(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; Type: Enum "Purchase Document Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
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
        LibraryLowerPermissions.SetO365Full();
    end;

    local procedure EnableWarningOnCloseUnpostedDoc()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        InstructionMgt.EnableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());
    end;

    local procedure DisableWarningOnCloseUnpostedDoc()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());
    end;

    local procedure EnableWarningOnCloseUnreleasedOrders()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        InstructionMgt.EnableMessageForCurrentUser('ClosingUnreleasedOrders');
    end;

    local procedure DisableWarningOnCloseUnreleasedOrders()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        InstructionMgt.DisableMessageForCurrentUser('ClosingUnreleasedOrders');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CloseUnpostedConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UnreleasedConfirmHandlerYES(Question: Text; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandlerOK(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 1;
    end;
}

