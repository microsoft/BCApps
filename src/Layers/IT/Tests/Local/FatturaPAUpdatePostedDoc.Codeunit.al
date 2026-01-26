codeunit 144212 "FatturaPA Update Posted Doc."
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    Permissions = tabledata "Sales Cr.Memo Header" = i,
                  tabledata "Sales Invoice Header" = i;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [UI]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedSalesInvoiceUpdatePageHandler')]
    procedure UpdatedFatturaDocumentTypeInPostedSalesInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 373947] Stan can update the value of the "Fattura Document Type" in the Posted Sales Invoice page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert();
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.Filter.SetFilter("No.", SalesInvoiceHeader."No.");
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        LibraryVariableStorage.Enqueue(FatturaDocType);
        PostedSalesInvoice."Update Document".Invoke();
        PostedSalesInvoice.Close();
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.TestField("Fattura Document Type", FatturaDocType);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedSalesCrMemoUpdatePageHandler')]
    procedure UpdatedFatturaDocumentTypeInPostedSalesCrMemo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCrMemo: TestPage "Posted Sales Credit Memo";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 373947] Stan can update the value of the "Fattura Document Type" in the Posted Sales Credit Memo page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Insert();
        PostedSalesCrMemo.OpenEdit();
        PostedSalesCrMemo.Filter.SetFilter("No.", SalesCrMemoHeader."No.");
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        LibraryVariableStorage.Enqueue(FatturaDocType);
        PostedSalesCrMemo."Update Document".Invoke();
        PostedSalesCrMemo.Close();
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader.TestField("Fattura Document Type", FatturaDocType);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServiceInvUpdatePageHandler')]
    procedure UpdatedFatturaDocumentTypeInPostedServiceInvoice()
    var
        ServInvoiceHeader: Record "Service Invoice Header";
        PostedServInvoice: TestPage "Posted Service Invoice";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Service]
        // [SCENARIO 373947] Stan can update the value of the "Fattura Document Type" in the Posted Service Invoice page

        Initialize();
        LibraryApplicationArea.EnableServiceManagementSetup();
        ServInvoiceHeader.Init();
        ServInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        ServInvoiceHeader.Insert();
        PostedServInvoice.OpenEdit();
        PostedServInvoice.Filter.SetFilter("No.", ServInvoiceHeader."No.");
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        LibraryVariableStorage.Enqueue(FatturaDocType);
        PostedServInvoice."Update Document".Invoke();
        PostedServInvoice.Close();
        ServInvoiceHeader.Find();
        ServInvoiceHeader.TestField("Fattura Document Type", FatturaDocType);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedServCrMemoUpdatePageHandler')]
    procedure UpdatedFatturaDocumentTypeInPostedServiceCrMemo()
    var
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        PostedServCrMemo: TestPage "Posted Service Credit Memo";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Service]
        // [SCENARIO 373947] Stan can update the value of the "Fattura Document Type" in the Posted Service Credit Memo page

        Initialize();
        LibraryApplicationArea.EnableServiceManagementSetup();
        ServCrMemoHeader.Init();
        ServCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        ServCrMemoHeader.Insert();
        PostedServCrMemo.OpenEdit();
        PostedServCrMemo.Filter.SetFilter("No.", ServCrMemoHeader."No.");
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        LibraryVariableStorage.Enqueue(FatturaDocType);
        PostedServCrMemo."Update Document".Invoke();
        PostedServCrMemo.Close();
        ServCrMemoHeader.Find();
        ServCrMemoHeader.TestField("Fattura Document Type", FatturaDocType);
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"FatturaPA Update Posted Doc.");
        if IsInitialized then
            exit;

        IsInitialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"FatturaPA Update Posted Doc.");

        LibraryITLocalization.SetupFatturaPA();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"FatturaPA Update Posted Doc.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceUpdatePageHandler(var PostedSalesInvoiceUpdate: TestPage "Posted Sales Invoice - Update")
    begin
        PostedSalesInvoiceUpdate."Fattura Document Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvoiceUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoUpdatePageHandler(var PstdSalesCrMemoUpdate: TestPage "Pstd. Sales Cr. Memo - Update")
    begin
        PstdSalesCrMemoUpdate."Fattura Document Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdSalesCrMemoUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvUpdatePageHandler(var PostedServiceInvUpdate: TestPage "Posted Service Inv. - Update")
    begin
        PostedServiceInvUpdate."Fattura Document Type".SetValue(LibraryVariableStorage.DequeueText());
        PostedServiceInvUpdate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedServCrMemoUpdatePageHandler(var PstdServMemoUpdate: TestPage "Posted Serv. Cr. Memo - Update")
    begin
        PstdServMemoUpdate."Fattura Document Type".SetValue(LibraryVariableStorage.DequeueText());
        PstdServMemoUpdate.OK().Invoke();
    end;
}

