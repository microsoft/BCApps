codeunit 144017 "VATEXP Report Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        Assert: Codeunit Assert;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportHandler(var SalesInvoiceReport: TestRequestPage "Standard Sales - Invoice")
    begin
        SalesInvoiceReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportNoBusNoProd()
    var
        EnableVatBusPostGroup: Boolean;
        EnableVatProdPostGroup: Boolean;
    begin
        // This report (1306) can only show VAT information on saleslines (PROD).
        Initialize();
        EnableVatBusPostGroup := false;
        EnableVatProdPostGroup := false;
        TestSalesInvoiceReport(EnableVatBusPostGroup, EnableVatProdPostGroup);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportBusNoProd()
    var
        EnableVatBusPostGroup: Boolean;
        EnableVatProdPostGroup: Boolean;
    begin
        // This report (1306) can only show VAT information on saleslines (PROD).
        Initialize();
        EnableVatBusPostGroup := true;
        EnableVatProdPostGroup := false;
        TestSalesInvoiceReport(EnableVatBusPostGroup, EnableVatProdPostGroup);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportNoBusProd()
    var
        EnableVatBusPostGroup: Boolean;
        EnableVatProdPostGroup: Boolean;
    begin
        // This report (1306) can only show VAT information on saleslines (PROD).
        Initialize();
        EnableVatBusPostGroup := false;
        EnableVatProdPostGroup := true;
        TestSalesInvoiceReport(EnableVatBusPostGroup, EnableVatProdPostGroup);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportBusProd()
    var
        EnableVatBusPostGroup: Boolean;
        EnableVatProdPostGroup: Boolean;
    begin
        // This report (1306) can only show VAT information on saleslines (PROD).
        Initialize();
        EnableVatBusPostGroup := true;
        EnableVatProdPostGroup := true;
        TestSalesInvoiceReport(EnableVatBusPostGroup, EnableVatProdPostGroup);
    end;

    local procedure Initialize()
    begin
        LibraryReportDataset.Reset();
    end;

    local procedure SetupPostingGroups(EnableVatBusPostGroup: Boolean; EnableVatProdPostGroup: Boolean)
    begin
        VATBusinessPostingGroup.ModifyAll("Print on Invoice", EnableVatBusPostGroup);
        VATProductPostingGroup.ModifyAll("Print on Invoice", EnableVatProdPostGroup);
        Commit();
    end;

    local procedure VerifyVatBusPostGroup()
    var
        VATBusinessPostingGroupPrintOnInvoice: Variant;
        VATPrintedOnInvoiceFieldExists: Boolean;
    begin
        LibraryReportDataset.Reset();
        VATBusinessPostingGroup.FindFirst();
        VATPrintedOnInvoiceFieldExists := false;

        while LibraryReportDataset.GetNextRow() do
            if LibraryReportDataset.CurrentRowHasElement('PrintOnInvoice_VatBusPostGroup') then begin
                LibraryReportDataset.GetElementValueInCurrentRow('PrintOnInvoice_VatBusPostGroup', VATBusinessPostingGroupPrintOnInvoice);
                Assert.AreEqual(VATBusinessPostingGroup."Print on Invoice", VATBusinessPostingGroupPrintOnInvoice, 'No VatBusPostGroup');
                VATPrintedOnInvoiceFieldExists := true;
            end;

        Assert.IsTrue(VATPrintedOnInvoiceFieldExists, 'PrintOnInvoice_VatBusPostGroup was not present in the Dataset.');
    end;

    local procedure VerifyVatProdPostGroup()
    var
        VATProductPostingGroupPrintOnInvoice: Variant;
        VATPrintedOnInvoiceFieldExists: Boolean;
    begin
        LibraryReportDataset.Reset();
        VATProductPostingGroup.FindFirst();
        VATPrintedOnInvoiceFieldExists := false;

        while LibraryReportDataset.GetNextRow() do
            if LibraryReportDataset.CurrentRowHasElement('PrintOnInvoice_VatProdPostGroup') then begin
                LibraryReportDataset.GetElementValueInCurrentRow('PrintOnInvoice_VatProdPostGroup', VATProductPostingGroupPrintOnInvoice);
                Assert.AreEqual(VATProductPostingGroup."Print on Invoice", VATProductPostingGroupPrintOnInvoice, 'No VatProdPostGroup');
                VATPrintedOnInvoiceFieldExists := true;
            end;

        Assert.IsTrue(VATPrintedOnInvoiceFieldExists, 'PrintOnInvoice_VatProdPostGroup was not present in the Dataset.');
    end;

    local procedure VerifyReportDatasetHasData()
    begin
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.RowCount() > 0, 'Empty Dataset');
    end;

    local procedure TestSalesInvoiceReport(EnableVatBusPostGroup: Boolean; EnableVatProdPostGroup: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        StandardSalesInvoice: Report "Standard Sales - Invoice";
    begin
        SetupPostingGroups(EnableVatBusPostGroup, EnableVatProdPostGroup);

        // Execute
        CreateAndPostSalesInvoice(SalesInvoiceHeader);
        SalesInvoiceHeader.SetRange("No.", SalesInvoiceHeader."No.");
        StandardSalesInvoice.SetTableView(SalesInvoiceHeader);
        StandardSalesInvoice.UseRequestPage(true);
        StandardSalesInvoice.Run();

        // Validate
        VerifyReportDatasetHasData();
        // No VatBusPostgroup information is available for this report.
        asserterror VerifyVatBusPostGroup();
        asserterror VerifyVatProdPostGroup();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := 10;
        Item.Modify();
    end;

    local procedure CreateSalesInvoice(var Customer: Record Customer; var Item: Record Item; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, 10);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesInvHeader: Record "Sales Invoice Header"): Code[20]
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvHeaderNo: Code[20];
    begin
        CreateCustomer(Customer);
        CreateItem(Item);
        CreateSalesInvoice(Customer, Item, SalesHeader);
        SalesInvHeaderNo := LibrarySmallBusiness.PostSalesInvoice(SalesHeader);
        SalesInvHeader.Get(SalesInvHeaderNo);
        SalesInvHeader.CalcFields(Closed);
        exit(SalesInvHeaderNo)
    end;
}
