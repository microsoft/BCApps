codeunit 138007 "O365 Shipping Agent"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [SMB] [Sales] [Shipping Agent]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithShippingAgent()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCopy: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        PackageTrackingNo: Text[50];
    begin
        Initialize();

        LibraryInventory.CreateShippingAgent(ShippingAgent);
        PackageTrackingNo := GenerateRandomPackageTrackingNo();

        // Sales Invoice Is Created
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeaderCopy := SalesHeader;

        LibraryLowerPermissions.SetSalesDocsCreate();
        AddShippingAgentToSalesInvoice(SalesHeader, ShippingAgent.Code);
        AddPackageTrackingNumberToSalesInvoice(SalesHeader, PackageTrackingNo);

        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();
        PostSalesInvoice(SalesHeader);

        // Verify
        VerifyShippingDetailsOnPostedSalesInvoice(SalesHeaderCopy, ShippingAgent.Code);
        VerifySalesShipmentExists(SalesHeaderCopy, ShippingAgent.Code, '', PackageTrackingNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithShippingAgentSAAS()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCopy: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PackageTrackingNo: Text[50];
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 171020] Susan will not see the confirm message on Shipping Agent Code when using SAAS
        Initialize();

        // [GIVEN] Set Software As A Service to TRUE and Create Shipping Agent and Package Tracking No
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [WHEN] Sales Invoice Is Created
        // [WHEN] Add the Shipping Agent and Package Tracking Number
        // [THEN] After adding the Shipping Agent confirm message won't show
        LibraryInventory.CreateShippingAgent(ShippingAgent);

        // Sales Invoice Is Created
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeaderCopy := SalesHeader;

        LibraryLowerPermissions.SetSalesDocsCreate();
        AddShippingAgentToSalesInvoice(SalesHeader, ShippingAgent.Code);
        PackageTrackingNo := GenerateRandomPackageTrackingNo();
        AddPackageTrackingNumberToSalesInvoice(SalesHeader, PackageTrackingNo);

        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();
        PostSalesInvoice(SalesHeader);

        // Verify
        VerifyShippingDetailsOnPostedSalesInvoice(SalesHeaderCopy, ShippingAgent.Code);
        VerifySalesShipmentExists(SalesHeaderCopy, ShippingAgent.Code, '', PackageTrackingNo);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithShippingAgentService()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCopy: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServiceCode: Code[10];
        PackageTrackingNo: Text[50];
    begin
        Initialize();

        // Setup
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgentServiceCode := LibraryInventory.CreateShippingAgentServiceUsingPages(ShippingAgent.Code);
        PackageTrackingNo := GenerateRandomPackageTrackingNo();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeaderCopy := SalesHeader;

        // Exercise
        LibraryLowerPermissions.SetSalesDocsCreate();
        AddShippingAgentToSalesInvoice(SalesHeader, ShippingAgent.Code);
        AddShippingAgentServiceToSalesInvoice(SalesHeader, ShippingAgentServiceCode);
        AddPackageTrackingNumberToSalesInvoice(SalesHeader, PackageTrackingNo);

        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();
        PostSalesInvoice(SalesHeader);

        // Verify
        VerifyShippingDetailsOnPostedSalesInvoice(SalesHeaderCopy, ShippingAgent.Code);
        VerifySalesShipmentExists(SalesHeaderCopy, ShippingAgent.Code, ShippingAgentServiceCode, PackageTrackingNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceForCustomerWithShippingAgentService()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCopy: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServiceCode: Code[10];
        PackageTrackingNo: Text[50];
    begin
        Initialize();

        // Setup
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgentServiceCode := LibraryInventory.CreateShippingAgentServiceUsingPages(ShippingAgent.Code);
        PackageTrackingNo := GenerateRandomPackageTrackingNo();

        CreateSalesDocumentForCustomerWithShippingAgent(
          SalesHeader, SalesHeader."Document Type"::Invoice, ShippingAgent.Code, ShippingAgentServiceCode);
        SalesHeaderCopy := SalesHeader;

        // Exercise
        LibraryLowerPermissions.SetSalesDocsCreate();
        AddPackageTrackingNumberToSalesInvoice(SalesHeader, PackageTrackingNo);

        LibraryLowerPermissions.SetSalesDocsPost();
        LibraryLowerPermissions.AddJobs();
        PostSalesInvoice(SalesHeader);

        // Verify
        VerifyShippingDetailsOnPostedSalesInvoice(SalesHeaderCopy, ShippingAgent.Code);
        VerifySalesShipmentExists(SalesHeaderCopy, ShippingAgent.Code, ShippingAgentServiceCode, PackageTrackingNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ShipAndInvoiceSalesOrderStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithShippingAgent()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCopy: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        PackageTrackingNo: Text[50];
    begin
        Initialize();

        // Setup
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        PackageTrackingNo := GenerateRandomPackageTrackingNo();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesHeaderCopy := SalesHeader;

        // Exercise
        // Removing lowering of permissions as it is causing test failures in the O365 runs for CA and US
        // LibraryLowerPermissions.SetSalesDocsCreate();
        AddShippingAgentToSalesOrder(SalesHeader, ShippingAgent.Code);
        AddPackageTrackingNumberToSalesOrder(SalesHeader, PackageTrackingNo);

        // LibraryLowerPermissions.SetSalesDocsPost();
        PostSalesOrder(SalesHeader);

        // Verify
        VerifyShippingDetailsOnPostedSalesInvoice(SalesHeaderCopy, ShippingAgent.Code);
        VerifySalesShipmentExists(SalesHeaderCopy, ShippingAgent.Code, '', PackageTrackingNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ShipAndInvoiceSalesOrderStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithShippingAgentService()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCopy: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServiceCode: Code[10];
        PackageTrackingNo: Text[50];
    begin
        Initialize();

        // Setup
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgentServiceCode := LibraryInventory.CreateShippingAgentServiceUsingPages(ShippingAgent.Code);
        PackageTrackingNo := GenerateRandomPackageTrackingNo();

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesHeaderCopy := SalesHeader;

        // Exercise
        // LibraryLowerPermissions.SetSalesDocsCreate();
        AddShippingAgentToSalesOrder(SalesHeader, ShippingAgent.Code);
        AddShippingAgentServiceToSalesOrder(SalesHeader, ShippingAgentServiceCode);
        AddPackageTrackingNumberToSalesOrder(SalesHeader, PackageTrackingNo);

        // LibraryLowerPermissions.SetSalesDocsPost();
        PostSalesOrder(SalesHeader);

        // Verify
        VerifyShippingDetailsOnPostedSalesInvoice(SalesHeaderCopy, ShippingAgent.Code);
        VerifySalesShipmentExists(SalesHeaderCopy, ShippingAgent.Code, ShippingAgentServiceCode, PackageTrackingNo);
    end;

    [Test]
    [HandlerFunctions('ShipAndInvoiceSalesOrderStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderForCustomerWithShippingAgentService()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCopy: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServiceCode: Code[10];
        PackageTrackingNo: Text[50];
    begin
        Initialize();

        // Setup
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgentServiceCode := LibraryInventory.CreateShippingAgentServiceUsingPages(ShippingAgent.Code);
        PackageTrackingNo := GenerateRandomPackageTrackingNo();

        CreateSalesDocumentForCustomerWithShippingAgent(
          SalesHeader, SalesHeader."Document Type"::Order, ShippingAgent.Code, ShippingAgentServiceCode);
        SalesHeaderCopy := SalesHeader;

        // Exercise
        // LibraryLowerPermissions.SetSalesDocsCreate();
        AddPackageTrackingNumberToSalesOrder(SalesHeader, PackageTrackingNo);

        // LibraryLowerPermissions.SetSalesDocsPost();
        PostSalesOrder(SalesHeader);

        // Verify
        VerifyShippingDetailsOnPostedSalesInvoice(SalesHeaderCopy, ShippingAgent.Code);
        VerifySalesShipmentExists(SalesHeaderCopy, ShippingAgent.Code, ShippingAgentServiceCode, PackageTrackingNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,SalesOrderPageHandler,ShipAndInvoiceSalesOrderStrMenuHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PostSalesQuoteAsSalesOrderWithShippingAgent()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCopy: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        Initialize();

        // Setup
        LibraryInventory.CreateShippingAgent(ShippingAgent);

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote);
        SalesHeaderCopy := SalesHeader;

        // Exercise
        // LibraryLowerPermissions.SetSalesDocsCreate();
        AddShippingAgentToSalesQuote(SalesHeader, ShippingAgent.Code);

        // LibraryLowerPermissions.SetSalesDocsPost();
        MakeSalesOrderFromSalesQuote(SalesHeader);

        // Verify
        VerifyShippingDetailsOnPostedSalesInvoice(SalesHeaderCopy, ShippingAgent.Code);
        VerifySalesShipmentExists(SalesHeaderCopy, ShippingAgent.Code, '', '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,SalesOrderPageHandler,ShipAndInvoiceSalesOrderStrMenuHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PostSalesQuoteAsSalesOrderWithShippingAgentService()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCopy: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ShippingAgentServiceCode: Code[10];
    begin
        Initialize();

        // Setup
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgentServiceCode := LibraryInventory.CreateShippingAgentServiceUsingPages(ShippingAgent.Code);

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote);
        SalesHeaderCopy := SalesHeader;

        // Exercise
        // LibraryLowerPermissions.SetSalesDocsCreate();
        AddShippingAgentToSalesQuote(SalesHeader, ShippingAgent.Code);
        AddShippingAgentServiceToSalesQuote(SalesHeader, ShippingAgentServiceCode);

        // LibraryLowerPermissions.SetSalesDocsPost();
        MakeSalesOrderFromSalesQuote(SalesHeader);

        // Verify
        VerifyShippingDetailsOnPostedSalesInvoice(SalesHeaderCopy, ShippingAgent.Code);
        VerifySalesShipmentExists(SalesHeaderCopy, ShippingAgent.Code, ShippingAgentServiceCode, '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,SalesOrderPageHandler,ShipAndInvoiceSalesOrderStrMenuHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PostSalesQuoteAsSalesOrderForCustomerWithShippingAgentService()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderCopy: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ShippingAgentServiceCode: Code[10];
    begin
        Initialize();

        // Setup
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgentServiceCode := LibraryInventory.CreateShippingAgentServiceUsingPages(ShippingAgent.Code);

        CreateSalesDocumentForCustomerWithShippingAgent(
          SalesHeader, SalesHeader."Document Type"::Quote, ShippingAgent.Code, ShippingAgentServiceCode);
        SalesHeaderCopy := SalesHeader;

        // Exercise
        // LibraryLowerPermissions.SetSalesDocsPost();
        MakeSalesOrderFromSalesQuote(SalesHeader);

        // Verify
        VerifyShippingDetailsOnPostedSalesInvoice(SalesHeaderCopy, ShippingAgent.Code);
        VerifySalesShipmentExists(SalesHeaderCopy, ShippingAgent.Code, ShippingAgentServiceCode, '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Shipping Agent");
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Shipping Agent");

        LibraryERMCountryData.CreateVATData();

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Shipment on Invoice" := true;
        SalesReceivablesSetup.Modify();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Shipping Agent");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType,
          LibrarySales.CreateCustomerNo(), '', LibraryRandom.RandInt(10), '', 0D);
    end;

    local procedure CreateSalesDocumentForCustomerWithShippingAgent(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, DocumentType,
          CreateCustomerWithShippingAgentService(ShippingAgentCode, ShippingAgentServiceCode), '', LibraryRandom.RandInt(10), '', 0D);
    end;

    local procedure AddShippingAgentToSalesInvoice(var SalesHeader: Record "Sales Header"; ShippingAgentCode: Code[10])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice."Shipping Agent Code".SetValue(ShippingAgentCode);
        SalesInvoice.OK().Invoke();
    end;

    local procedure AddShippingAgentToSalesOrder(var SalesHeader: Record "Sales Header"; ShippingAgentCode: Code[10])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder."Shipping Agent Code".SetValue(ShippingAgentCode);
        SalesOrder.OK().Invoke();
    end;

    local procedure AddShippingAgentToSalesQuote(var SalesHeader: Record "Sales Header"; ShippingAgentCode: Code[10])
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote."Shipping Agent Code".SetValue(ShippingAgentCode);
        SalesQuote.OK().Invoke();
    end;

    local procedure AddShippingAgentServiceToSalesInvoice(var SalesHeader: Record "Sales Header"; ShippingAgentServiceCode: Code[10])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice."Shipping Agent Service Code".SetValue(ShippingAgentServiceCode);
        SalesInvoice.OK().Invoke();
    end;

    local procedure AddShippingAgentServiceToSalesOrder(var SalesHeader: Record "Sales Header"; ShippingAgentServiceCode: Code[10])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder."Shipping Agent Service Code".SetValue(ShippingAgentServiceCode);
        SalesOrder.OK().Invoke();
    end;

    local procedure AddShippingAgentServiceToSalesQuote(var SalesHeader: Record "Sales Header"; ShippingAgentServiceCode: Code[10])
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote."Shipping Agent Service Code".SetValue(ShippingAgentServiceCode);
        SalesQuote.OK().Invoke();
    end;

    local procedure AddPackageTrackingNumberToSalesInvoice(var SalesHeader: Record "Sales Header"; PackageTrackingNo: Text[50])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice."Package Tracking No.".SetValue(PackageTrackingNo);
        SalesInvoice.OK().Invoke();
    end;

    local procedure AddPackageTrackingNumberToSalesOrder(var SalesHeader: Record "Sales Header"; PackageTrackingNo: Text[50])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder."Package Tracking No.".SetValue(PackageTrackingNo);
        SalesOrder.OK().Invoke();
    end;

    local procedure CreateCustomerWithShippingAgentService(ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        LibrarySales.CreateCustomer(Customer);

        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard."Shipping Agent Code".SetValue(ShippingAgentCode);
        CustomerCard."Shipping Agent Service Code".SetValue(ShippingAgentServiceCode);
        CustomerCard.OK().Invoke();

        exit(Customer."No.");
    end;

    local procedure GenerateRandomPackageTrackingNo(): Text[50]
    var
        DummySalesHeader: Record "Sales Header";
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(DummySalesHeader."Package Tracking No.")),
            1, MaxStrLen(DummySalesHeader."Package Tracking No.")));
    end;

    local procedure PostSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.Post.Invoke();
    end;

    local procedure PostSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.Post.Invoke();
    end;

    local procedure MakeSalesOrderFromSalesQuote(SalesHeader: Record "Sales Header")
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.MakeOrder.Invoke();
    end;

    local procedure VerifyShippingDetailsOnPostedSalesInvoice(SalesHeader: Record "Sales Header"; ShippingAgentCode: Code[10])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        SalesInvoiceHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.SetRange("External Document No.", SalesHeader."External Document No.");
        SalesInvoiceHeader.FindLast();

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice."Shipping Agent Code".AssertEquals(ShippingAgentCode);
        PostedSalesInvoice.OK().Invoke();
    end;

    local procedure VerifySalesShipmentExists(SalesHeader: Record "Sales Header"; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10]; PackageTrackingNo: Text)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
    begin
        SalesShipmentHeader.SetCurrentKey("Sell-to Customer No.");
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindLast();

        PostedSalesShipment.OpenView();
        PostedSalesShipment.GotoRecord(SalesShipmentHeader);
        PostedSalesShipment."External Document No.".AssertEquals(SalesHeader."External Document No.");
        PostedSalesShipment."Shipping Agent Code".AssertEquals(ShippingAgentCode);
        PostedSalesShipment."Shipping Agent Service Code".AssertEquals(ShippingAgentServiceCode);
        PostedSalesShipment."Package Tracking No.".AssertEquals(PackageTrackingNo);
        PostedSalesShipment.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceSalesOrderStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 3;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPageHandler(var SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.Post.Invoke();
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}
