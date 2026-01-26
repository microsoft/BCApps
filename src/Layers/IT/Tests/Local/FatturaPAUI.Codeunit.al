codeunit 144211 "FatturaPA UI"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [UI]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaPAFieldsExistsInSalesOrderPage()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 361252] FatturaPA fields are visible in the Sales Order page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        SalesOrder.OpenEdit();
        Assert.IsTrue(SalesOrder."Fattura Project Code".Visible(), 'Fattura Project Code is not visible');
        Assert.IsTrue(SalesOrder."Fattura Tender Code".Visible(), 'Fattura Tender Code is not visible');
        SalesOrder.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaPAFieldsExistsInServiceOrderPage()
    var
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 361252] FatturaPA fields are visible in the Service Order page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        ServiceOrder.OpenEdit();
        Assert.IsTrue(ServiceOrder."Fattura Project Code".Visible(), 'Fattura Project Code is not visible');
        Assert.IsTrue(ServiceOrder."Fattura Tender Code".Visible(), 'Fattura Tender Code is not visible');
        ServiceOrder.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaDocTypeExistsInPostedSalesInvoicePage()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 373967] "Fattura Document Type" field is visible in the Posted Sales Invoice page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        PostedSalesInvoice.OpenEdit();
        Assert.IsTrue(PostedSalesInvoice."Fattura Document Type".Visible(), 'Fattura Document Type is not visible');
        PostedSalesInvoice.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaDocTypeExistsInPostedSalesCrMemoPage()
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 373967] "Fattura Document Type" field is visible in the Posted Sales Credit Memo page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        PostedSalesCreditMemo.OpenEdit();
        Assert.IsTrue(PostedSalesCreditMemo."Fattura Document Type".Visible(), 'Fattura Document Type is not visible');
        PostedSalesCreditMemo.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaDocTypeExistsInVATPostingSetupPage()
    var
        VATPostingSetup: TestPage "VAT Posting Setup";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 373967] "Fattura Document Type" field is visible in the VAT Posting Setup page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        VATPostingSetup.OpenEdit();
        Assert.IsTrue(VATPostingSetup."Fattura Document Type".Visible(), 'Fattura Document Type is not visible');
        VATPostingSetup.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaDocTypeExistsInVATPostingSetupCardPage()
    var
        VATPostingSetupCard: TestPage "VAT Posting Setup Card";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 373967] "Fattura Document Type" field is visible in the VAT Posting Setup Card page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        VATPostingSetupCard.OpenEdit();
        Assert.IsTrue(VATPostingSetupCard."Fattura Document Type".Visible(), 'Fattura Document Type is not visible');
        VATPostingSetupCard.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaDocTypeExistsInPostedServiceInvoicePage()
    var
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 373967] "Fattura Document Type" field is visible in the Posted Service Invoice page

        Initialize();
        LibraryApplicationArea.EnableServiceManagementSetup();
        PostedServiceInvoice.OpenEdit();
        Assert.IsTrue(PostedServiceInvoice."Fattura Document Type".Visible(), 'Fattura Document Type is not visible');
        PostedServiceInvoice.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaDocTypeExistsInPostedServiceCrMemoPage()
    var
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 373967] "Fattura Document Type" field is visible in the Posted Service Credit Memo page

        Initialize();
        LibraryApplicationArea.EnableServiceManagementSetup();
        PostedServiceCreditMemo.OpenEdit();
        Assert.IsTrue(PostedServiceCreditMemo."Fattura Document Type".Visible(), 'Fattura Document Type is not visible');
        PostedServiceCreditMemo.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"FatturaPA UI");
        if IsInitialized then
            exit;

        IsInitialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"FatturaPA UI");

        LibraryITLocalization.SetupFatturaPA();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"FatturaPA UI");
    end;
}

