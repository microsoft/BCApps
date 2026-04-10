codeunit 134766 "Test Service Post Preview"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Preview] [Service]
        IsInitialized := false;
    end;

    var
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ExpectedCost: Decimal;
        ExpectedQuantity: Decimal;
        NoRecordsErr: Label 'There are no preview records to show.';
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Service Post Preview");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Service Post Preview");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Service Post Preview");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceOpensPreview()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Preview action on Service Invoice should open G/L Posting Preview Page
        // Initialize service header
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice);

        // Execute the page
        ServiceInvoice.Trap();
        PAGE.Run(PAGE::"Service Invoice", ServiceHeader);

        Commit();
        GLPostingPreview.Trap();
        ServiceInvoice.Preview.Invoke();

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        ServiceHeader.Find();
        ServiceHeader.Delete();
        ClearAll();
    end;

    [Test]
    [HandlerFunctions('PickShipAndInvoiceInMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderOpensPreview()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Preview action on Service Order should open G/L Posting Preview Page
        Initialize();
        // Initialize service header
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);

        // Execute the page
        ServiceOrder.Trap();
        PAGE.Run(PAGE::"Service Order", ServiceHeader);

        Commit();
        GLPostingPreview.Trap();
        ServiceOrder.Preview.Invoke();

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        ServiceHeader.Find();
        ServiceHeader.Delete();
        ClearAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoOpensPreview()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Preview action on Service Credit Memo should open G/L Posting Preview Page
        Initialize();
        // Initialize purchase header
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", '');
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, '');

        // Execute the page
        ServiceCreditMemo.Trap();
        PAGE.Run(PAGE::"Service Credit Memo", ServiceHeader);

        Commit();
        GLPostingPreview.Trap();
        ServiceCreditMemo.Preview.Invoke();

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        ServiceHeader.Find();
        ServiceHeader.Delete();
        ClearAll();
    end;

    [Test]
    [HandlerFunctions('ServiceLinesModalHandler,PickShipAndInvoiceInMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceLinesOpensPreview()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        // [SCENARIO] Preview action on Service Lines should open G/L Posting Preview Page
        Initialize();
        // Initialize service header
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);

        // Execute the page
        ServiceOrder.Trap();
        PAGE.Run(PAGE::"Service Order", ServiceHeader);
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        // Cleanup
        ServiceHeader.Find();
        ServiceHeader.Delete();
        ClearAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceListOpensPreview()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoices: TestPage "Service Invoices";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Preview action on Service Invoices should open G/L Posting Preview Page
        Initialize();
        // Initialize service header
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice);

        // Execute the page
        ServiceInvoices.Trap();
        PAGE.Run(PAGE::"Service Invoices", ServiceHeader);

        Commit();
        GLPostingPreview.Trap();
        ServiceInvoices.Preview.Invoke();

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        ServiceHeader.Find();
        ServiceHeader.Delete();
        ClearAll();
    end;

    [Test]
    [HandlerFunctions('PickShipAndInvoiceInMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderListOpensPreview()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrders: TestPage "Service Orders";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Preview action on Service Orders should open G/L Posting Preview Page
        Initialize();
        // Initialize service header
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);

        // Execute the page
        ServiceOrders.Trap();
        PAGE.Run(PAGE::"Service Orders", ServiceHeader);

        Commit();
        GLPostingPreview.Trap();
        ServiceOrders.Preview.Invoke();

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        ServiceHeader.Find();
        ServiceHeader.Delete();
        ClearAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoListOpensPreview()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCreditMemos: TestPage "Service Credit Memos";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Preview action on Service Credit Memo List should open G/L Posting Preview Page
        Initialize();
        // Initialize purchase header
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", '');
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, '');

        // Execute the page
        ServiceCreditMemos.Trap();
        PAGE.Run(PAGE::"Service Credit Memos", ServiceHeader);

        Commit();
        GLPostingPreview.Trap();
        ServiceCreditMemos.Preview.Invoke();

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();

        // Cleanup
        ServiceHeader.Find();
        ServiceHeader.Delete();
        ClearAll();
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", ExpectedCost);
        Item.Modify(true);

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, ExpectedQuantity);
        ServiceLine.Modify(true);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PickShipAndInvoiceInMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 3;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesModalHandler(var ServiceLines: TestPage "Service Lines")
    var
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        Commit();
        GLPostingPreview.Trap();
        ServiceLines.Preview.Invoke();

        if not GLPostingPreview.First() then
            Error(NoRecordsErr);
        GLPostingPreview.OK().Invoke();
    end;

    [Normal]
    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        ExpectedCost := LibraryRandom.RandInt(100);
        ExpectedQuantity := LibraryRandom.RandInt(10);
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");
    end;
}

