codeunit 138060 "Non-O365 Shipping Agent"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Shipping Agent]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        ModifiedShippingCodeMsg: Label 'You have modified Shipping Agent Code.\\Do you want to update the lines?';
        ModifiedShippingSvcCodeMsg: Label 'You have modified Shipping Agent Service Code.\\Do you want to update the lines?';

    [Test]
    [HandlerFunctions('ReceiveAndInvoiceSalesReturnOrderStrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderWithShippingAgent()
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

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order");
        SalesHeaderCopy := SalesHeader;

        LibraryVariableStorage.Enqueue(ModifiedShippingCodeMsg);
        LibraryVariableStorage.Enqueue(true);

        // Exercise
        AddShippingAgentToSalesReturnOrder(SalesHeader, ShippingAgent.Code);
        AddPackageTrackingNumberToSalesReturnOrder(SalesHeader, PackageTrackingNo);

        PostSalesReturnOrder(SalesHeader);

        // Verify
        VerifySalesReturnReceiptExists(SalesHeaderCopy, ShippingAgent.Code, true, PackageTrackingNo);
    end;

    [Test]
    [HandlerFunctions('ReceiveAndInvoiceSalesReturnOrderStrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderWithShippingAgentService()
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

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Return Order");
        SalesHeaderCopy := SalesHeader;

        LibraryVariableStorage.Enqueue(ModifiedShippingCodeMsg);
        LibraryVariableStorage.Enqueue(true);

        LibraryVariableStorage.Enqueue(ModifiedShippingSvcCodeMsg);
        LibraryVariableStorage.Enqueue(true);

        // Exercise
        AddShippingAgentToSalesReturnOrder(SalesHeader, ShippingAgent.Code);
        AddShippingAgentServiceToSalesReturnOrder(SalesHeader, ShippingAgentServiceCode);
        AddPackageTrackingNumberToSalesReturnOrder(SalesHeader, PackageTrackingNo);

        PostSalesReturnOrder(SalesHeader);

        // Verify
        VerifySalesReturnReceiptExists(SalesHeaderCopy, ShippingAgent.Code, true, PackageTrackingNo);
    end;

    [Test]
    [HandlerFunctions('ReceiveAndInvoiceSalesReturnOrderStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderForCustomerWithShippingAgentService()
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
          SalesHeader, SalesHeader."Document Type"::"Return Order", ShippingAgent.Code, ShippingAgentServiceCode);
        SalesHeaderCopy := SalesHeader;

        // Exercise
        AddPackageTrackingNumberToSalesReturnOrder(SalesHeader, PackageTrackingNo);

        PostSalesReturnOrder(SalesHeader);

        // Verify
        VerifySalesReturnReceiptExists(SalesHeaderCopy, ShippingAgent.Code, false, PackageTrackingNo);
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Non-O365 Shipping Agent");
        LibraryApplicationArea.DisableApplicationAreaSetup();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Non-O365 Shipping Agent");
        LibraryERMCountryData.CreateVATData();
        // Not running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Non-O365 Shipping Agent");
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

    local procedure AddShippingAgentToSalesReturnOrder(var SalesHeader: Record "Sales Header"; ShippingAgentCode: Code[10])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder."Shipping Agent Code".SetValue(ShippingAgentCode);
        SalesReturnOrder.OK().Invoke();
    end;

    local procedure AddShippingAgentServiceToSalesReturnOrder(var SalesHeader: Record "Sales Header"; ShippingAgentServiceCode: Code[10])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder."Shipping Agent Service Code".SetValue(ShippingAgentServiceCode);
        SalesReturnOrder.OK().Invoke();
    end;

    local procedure AddPackageTrackingNumberToSalesReturnOrder(var SalesHeader: Record "Sales Header"; PackageTrackingNo: Text[50])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder."Package Tracking No.".SetValue(PackageTrackingNo);
        SalesReturnOrder.OK().Invoke();
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

    local procedure PostSalesReturnOrder(var SalesHeader: Record "Sales Header")
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.Post.Invoke();
    end;

    local procedure VerifySalesReturnReceiptExists(SalesHeader: Record "Sales Header"; ShippingAgentCode: Code[10]; CheckShippingAgentCode: Boolean; PackageTrackingNo: Text)
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedReturnReceipt: TestPage "Posted Return Receipt";
    begin
        ReturnReceiptHeader.SetCurrentKey("Sell-to Customer No.");
        ReturnReceiptHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        ReturnReceiptHeader.FindLast();

        PostedReturnReceipt.OpenView();
        PostedReturnReceipt.GotoRecord(ReturnReceiptHeader);
        PostedReturnReceipt."External Document No.".AssertEquals(SalesHeader."External Document No.");
        if CheckShippingAgentCode then
            PostedReturnReceipt."Shipping Agent Code".AssertEquals(ShippingAgentCode);
        PostedReturnReceipt."Package Tracking No.".AssertEquals(PackageTrackingNo);
        PostedReturnReceipt.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ReceiveAndInvoiceSalesReturnOrderStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 3;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, '');
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}
