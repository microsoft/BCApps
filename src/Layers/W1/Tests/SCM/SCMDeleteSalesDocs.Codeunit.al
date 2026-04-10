codeunit 137208 "SCM Delete Sales Docs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Print Documents] [Sales]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        AllowPostedDocumentDeletionDate: Date;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Delete Sales Docs");
        LibraryVariableStorage.Clear();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Delete Sales Docs");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        AllowPostedDocumentDeletionDate := LibraryERM.GetDeletionBlockedAfterDate();
        CompanyInformation.Get();
        CompanyInformation."Bank Account No." := 'A';
        CompanyInformation.Modify();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Delete Sales Docs");
    end;

    [Test]
    [HandlerFunctions('SalesShipReportHandler')]
    [Scope('OnPrem')]
    procedure DeletePostedShipment()
    var
        SalesHeader: Record "Sales Header";
    begin
        DeletePostedDoc(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('SalesInvReportHandler')]
    [Scope('OnPrem')]
    procedure DeletePostedInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        DeletePostedDoc(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('RetRcptReportHandler')]
    [Scope('OnPrem')]
    procedure DeletePostedRetReceipt()
    var
        SalesHeader: Record "Sales Header";
    begin
        DeletePostedDoc(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('CrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure DeletePostedCrMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        DeletePostedDoc(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesShipmentRequestPageHandler')]
    procedure PrintTwoShipmentsWithRequestPage()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedShipmentNos: array[2] of Code[20];
        Index: Integer;
    begin
        Initialize();
        for Index := 1 to ArrayLen(PostedShipmentNos) do begin
            CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
            SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
            SalesShipmentHeader.FindFirst();
            PostedShipmentNos[Index] := SalesShipmentHeader."No.";
        end;

        Clear(SalesShipmentHeader);
        SalesShipmentHeader.SetFilter("No.", StrSubstNo('%1|%2', PostedShipmentNos[1], PostedShipmentNos[2]));
        LibraryVariableStorage.Enqueue(SalesShipmentHeader.GetFilter("No."));
        SalesShipmentHeader.FindFirst();
        Report.Run(Report::"Sales - Shipment", true, false, SalesShipmentHeader);

        LibraryReportDataset.LoadDataSetFile();
        for Index := 1 to ArrayLen(PostedShipmentNos) do
            LibraryReportDataset.AssertElementWithValueExists('No_SalesShptHeader', PostedShipmentNos[Index]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SalesShipmentXmlReportHandler')]
    procedure PrintTwoShipmentsWithoutRequestPage()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        FileManagement: Codeunit "File Management";
        PostedShipmentNos: array[2] of Code[20];
        FilePath: Text;
        Index: Integer;
    begin
        Initialize();
        for Index := 1 to ArrayLen(PostedShipmentNos) do begin
            CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
            SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
            SalesShipmentHeader.FindFirst();
            PostedShipmentNos[Index] := SalesShipmentHeader."No.";
        end;

        Clear(SalesShipmentHeader);
        SalesShipmentHeader.SetFilter("No.", StrSubstNo('%1|%2', PostedShipmentNos[1], PostedShipmentNos[2]));
        SalesShipmentHeader.FindFirst();
        LibraryVariableStorage.Enqueue(SalesShipmentHeader.GetFilter("No."));

        FilePath := FileManagement.ServerTempFileName('xml');
        LibraryVariableStorage.Enqueue(FilePath);

        Report.Run(Report::"Sales - Shipment", false, false, SalesShipmentHeader);

        LibraryXPathXMLReader.Initialize(FilePath, '');
        for Index := 1 to ArrayLen(PostedShipmentNos) do
            LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
                '//ReportDataSet/DataItems/DataItem/Columns/Column[@name="No_SalesShptHeader"]',
                PostedShipmentNos[Index],
                Index - 1);

        LibraryVariableStorage.AssertEmpty();
    end;


    local procedure DeletePostedDoc(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        FileManagement: Codeunit "File Management";
        FilePath: Text;
    begin
        Initialize();
        CreateSalesDocument(SalesHeader, DocumentType);
        LibrarySales.SetAllowDocumentDeletionBeforeDate(SalesHeader."Posting Date" + 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        FilePath := FileManagement.ServerTempFileName('pdf');
        LibraryVariableStorage.Enqueue(FilePath);
        PrintDocument(SalesHeader);

        VerifyLinesAreDeleted(SalesHeader, DocumentType);
        File.Exists(FilePath);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
        Counter: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        SalesHeader.Validate("Posting Date", AllowPostedDocumentDeletionDate - 1);
        SalesHeader.Modify();
        // Create a sales document with 2 lines.
        for Counter := 1 to 2 do begin
            LibraryInventory.CreateItem(Item);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        end;
    end;

    local procedure PrintDocument(SalesHeader: Record "Sales Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        NoPrinted: Integer;
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                begin
                    SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
                    SalesShipmentHeader.FindFirst();
                    LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");
                    NoPrinted := SalesShipmentHeader."No. Printed";
                    Report.Run(Report::"Sales - Shipment", false, false, SalesShipmentHeader);
                    SalesShipmentHeader.Get(SalesShipmentHeader."No.");
                    NoPrinted := SalesShipmentHeader."No. Printed" - NoPrinted;
                    SalesShipmentHeader.Delete(true);
                end;
            SalesHeader."Document Type"::Invoice:
                begin
                    SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
                    SalesInvoiceHeader.FindFirst();
                    LibraryVariableStorage.Enqueue(SalesInvoiceHeader."No.");
                    NoPrinted := SalesInvoiceHeader."No. Printed";
                    Report.Run(Report::"Standard Sales - Invoice", false, false, SalesInvoiceHeader);
                    SalesInvoiceHeader.Get(SalesInvoiceHeader."No.");
                    NoPrinted := SalesInvoiceHeader."No. Printed" - NoPrinted;
                    SalesInvoiceHeader.Delete(true);
                end;
            SalesHeader."Document Type"::"Return Order":
                begin
                    ReturnReceiptHeader.SetRange("Return Order No.", SalesHeader."No.");
                    ReturnReceiptHeader.FindFirst();
                    LibraryVariableStorage.Enqueue(ReturnReceiptHeader."No.");
                    NoPrinted := ReturnReceiptHeader."No. Printed";
                    Report.Run(Report::"Sales - Return Receipt", false, false, ReturnReceiptHeader);
                    ReturnReceiptHeader.Get(ReturnReceiptHeader."No.");
                    NoPrinted := ReturnReceiptHeader."No. Printed" - NoPrinted;
                    ReturnReceiptHeader.Delete(true);
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    SalesCrMemoHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
                    SalesCrMemoHeader.FindFirst();
                    LibraryVariableStorage.Enqueue(SalesCrMemoHeader."No.");
                    NoPrinted := SalesCrMemoHeader."No. Printed";
                    Report.Run(Report::"Standard Sales - Credit Memo", false, false, SalesCrMemoHeader);
                    SalesCrMemoHeader.Get(SalesCrMemoHeader."No.");
                    NoPrinted := SalesCrMemoHeader."No. Printed" - NoPrinted;
                    SalesCrMemoHeader.Delete(true);
                end;
        end;
        Assert.AreEqual(1, NoPrinted, 'No. printed was not incremented for ' + SalesHeader."No.");
    end;

    local procedure VerifyLinesAreDeleted(SalesHeader: Record "Sales Header";
                                                           DocumentType: Enum "Sales Document Type")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        // Verify there are no related document lines remaining in the database for the given doc. no.
        case DocumentType of
            SalesHeader."Document Type"::Order:
                begin
                    SalesShipmentLine.SetRange("Order No.", SalesHeader."No.");
                    Assert.IsTrue(SalesShipmentLine.IsEmpty, 'Not all shipment lines were deleted.');
                end;
            SalesHeader."Document Type"::Invoice:
                begin
                    SalesInvoiceLine.SetRange("Document No.", SalesHeader."No.");
                    Assert.IsTrue(SalesInvoiceLine.IsEmpty, 'Not all invoice lines were deleted.');
                end;
            SalesHeader."Document Type"::"Return Order":
                begin
                    ReturnReceiptLine.SetRange("Return Order No.", SalesHeader."No.");
                    Assert.IsTrue(ReturnReceiptLine.IsEmpty, 'Not all receipt lines were deleted.');
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    SalesCrMemoLine.SetRange("Document No.", SalesHeader."No.");
                    Assert.IsTrue(SalesCrMemoLine.IsEmpty, 'Not all cr. memo lines were deleted.');
                end;
        end;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure SalesShipReportHandler(var SalesShipment: Report "Sales - Shipment")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        FilePath: Text;
    begin
        FilePath := LibraryVariableStorage.DequeueText();
        SalesShipmentHeader.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SalesShipment.SetTableView(SalesShipmentHeader);
        SalesShipment.SaveAsPdf(FilePath);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure RetRcptReportHandler(var SalesReturnReceipt: Report "Sales - Return Receipt")
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        FilePath: Text;
    begin
        FilePath := LibraryVariableStorage.DequeueText();
        ReturnReceiptHeader.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SalesReturnReceipt.SetTableView(ReturnReceiptHeader);
        SalesReturnReceipt.SaveAsPdf(FilePath);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure SalesInvReportHandler(var StandardSalesInvoice: Report "Standard Sales - Invoice")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilePath: Text;
    begin
        FilePath := LibraryVariableStorage.DequeueText();
        SalesInvoiceHeader.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardSalesInvoice.SetTableView(SalesInvoiceHeader);
        StandardSalesInvoice.SaveAsPdf(FilePath);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure CrMemoReportHandler(var StandardSalesCreditMemo: Report "Standard Sales - Credit Memo")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FilePath: Text;
    begin
        FilePath := LibraryVariableStorage.DequeueText();
        SalesCrMemoHeader.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardSalesCreditMemo.SetTableView(SalesCrMemoHeader);
        StandardSalesCreditMemo.SaveAsPdf(FilePath);
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentXmlReportHandler(var SalesShipment: Report "Sales - Shipment")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SalesShipment.SetTableView(SalesShipmentHeader);
        SalesShipment.SaveAsXml(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentRequestPageHandler(var SalesShipment: TestRequestPage "Sales - Shipment")
    begin
        SalesShipment."Sales Shipment Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

