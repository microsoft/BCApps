codeunit 138042 "O365 Page Dimensions"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [SMB] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        TestDimensionCode: Code[20];
        TestDimensionValue: Code[20];
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        DimensionValue: Record "Dimension Value";
        ExperienceTierSetup: Record "Experience Tier Setup";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        InstructionMgt: Codeunit "Instruction Mgt.";
        DimensionValues: TestPage "Dimension Values";
        Dimensions: TestPage Dimensions;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Page Dimensions");
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Page Dimensions");

        ClearTable(DATABASE::Resource);

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryERMCountryData.CreateVATData();

        TestDimensionCode := LibraryUtility.GenerateGUID();
        TestDimensionValue := LibraryUtility.GenerateGUID();
        Dimensions.OpenNew();
        Dimensions.New();
        Dimensions.Code.SetValue(TestDimensionCode);
        Dimensions.OK().Invoke();
        DimensionValue.Init();
        DimensionValue."Dimension Code" := TestDimensionCode;
        DimensionValue.Code := TestDimensionValue;
        DimensionValue.Insert();
        Dimensions.OpenEdit();
        DimensionValues.Trap();
        Dimensions.FindFirstField(Code, TestDimensionCode);
        Dimensions."Dimension &Values".Invoke();
        DimensionValues.New();
        DimensionValues.Code.SetValue(TestDimensionValue);
        DimensionValues.OK().Invoke();
        Dimensions.OK().Invoke();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Page Dimensions");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        Resource: Record Resource;
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::Resource:
                Resource.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    [Test]
    [HandlerFunctions('DimensionEntryHandler,ConfirmationHandler,DimensionCheckHandler')]
    [Scope('OnPrem')]
    procedure DimensionsOnSalesInvoices()
    var
        TestCustomer: Record Customer;
        TestItem: Record Item;
        TestSalesLine: Record "Sales Line";
        TestSalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(TestCustomer);
        LibrarySmallBusiness.CreateItem(TestItem);
        LibrarySmallBusiness.CreateSalesInvoiceHeader(TestSalesHeader, TestCustomer);
        LibrarySmallBusiness.CreateSalesLine(TestSalesLine, TestSalesHeader, TestItem, LibraryRandom.RandInt(100));

        // open the test sales invoice and add the test dimension
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(TestSalesHeader);
        SalesInvoice.Dimensions.Invoke();

        // we need to get the sales header again, because dimension has been added to it
        TestSalesHeader.Get(TestSalesHeader."Document Type", TestSalesHeader."No.");

        // post the test sales invoice
        LibrarySmallBusiness.PostSalesInvoice(TestSalesHeader);

        // check that the posted sales invoice has test dimension
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", TestCustomer."No.");
        SalesInvoiceHeader.FindFirst();
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice.Dimensions.Invoke();
    end;

    [Test]
    [HandlerFunctions('DimensionEntryHandler,ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure DimensionsOnSalesQuotes()
    var
        TestCustomer: Record Customer;
        TestItem: Record Item;
        TestSalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();
        LibrarySmallBusiness.CreateCustomer(TestCustomer);
        LibrarySmallBusiness.CreateItem(TestItem);
        LibrarySmallBusiness.CreateSalesQuoteHeaderWithLines(TestSalesHeader, TestCustomer, TestItem, 1, 1);

        // open the test sales invoice and add the test dimension
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(TestSalesHeader);
        SalesQuote.Dimensions.Invoke();
    end;

    [Test]
    [HandlerFunctions('DimensionEntryHandler,ConfirmationHandler,DimensionCheckHandler')]
    [Scope('OnPrem')]
    procedure DimensionsOnPurchaseInvoices()
    var
        TestPurchaseHeader: Record "Purchase Header";
        TestPurchaseLine: Record "Purchase Line";
        TestVendor: Record Vendor;
        TestItem: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        Initialize();

        LibrarySmallBusiness.CreateVendor(TestVendor);
        LibrarySmallBusiness.CreateItem(TestItem);
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(TestPurchaseHeader, TestVendor);
        LibrarySmallBusiness.CreatePurchaseLine(TestPurchaseLine, TestPurchaseHeader, TestItem, LibraryRandom.RandInt(100));

        // open the test purchase invoice and add the test dimension
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(TestPurchaseHeader);
        PurchaseInvoice.Dimensions.Invoke();

        // we need to get the purchase header again, because dimension has been added to it
        TestPurchaseHeader.Get(TestPurchaseHeader."Document Type", TestPurchaseHeader."No.");

        // post the test purchase invoice
        LibrarySmallBusiness.PostPurchaseInvoice(TestPurchaseHeader);

        // check that the posted purchase invoice has test dimension
        PurchInvHeader.SetRange("Buy-from Vendor No.", TestVendor."No.");
        PurchInvHeader.FindFirst();
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GotoRecord(PurchInvHeader);
        PostedPurchaseInvoice.Dimensions.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionEntryHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        EditDimensionSetEntries.New();
        EditDimensionSetEntries.First();
        EditDimensionSetEntries."Dimension Code".SetValue(TestDimensionCode);
        EditDimensionSetEntries.DimensionValueCode.SetValue(TestDimensionValue);
        EditDimensionSetEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionCheckHandler(var ViewDimensionSetEntries: TestPage "Dimension Set Entries")
    begin
        ViewDimensionSetEntries.First();
        Assert.AreEqual(ViewDimensionSetEntries."Dimension Code".Value, TestDimensionCode, 'Unexpected dimension on posted document.');
        Assert.AreEqual(ViewDimensionSetEntries.DimensionValueCode.Value, TestDimensionValue, 'Unexpected dimension value on posted doc.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

