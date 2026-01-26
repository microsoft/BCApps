codeunit 147538 "Receivable Bill"
{
    // Test Report Receivable Bill (7000003)

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LocalCurrencyCode: Code[10];

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LocalCurrencyCode := '';
    end;

    [Test]
    [HandlerFunctions('ReceivableBillRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreateDocumentAndReport()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        ReportAmount: Variant;
        ReportBillNo: Variant;
        ReportDocumentNo: Variant;
        DocumentNo: Code[20];
        Found: Boolean;
        Amount1: Decimal;
    begin
        Initialize();

        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");

        Commit();
        REPORT.Run(REPORT::"Receivable Bill");

        LibraryReportDataset.LoadDataSetFile();

        Assert.IsTrue(LibraryReportDataset.RowCount() > 0, 'No rows in dataset.');

        Found := false;
        while LibraryReportDataset.GetNextRow() do begin
            LibraryReportDataset.FindCurrentRowValue('DocumentNo_CustLedgEntry', ReportDocumentNo);
            if DocumentNo = Format(ReportDocumentNo) then begin
                Assert.IsFalse(Found, 'Only one row expected.');
                Found := true;
                LibraryReportDataset.FindCurrentRowValue('PrintAmt', ReportAmount);
                Amount1 := CarteraDoc."Remaining Amount";
                Assert.AreEqual(Format(Amount1), Format(ReportAmount), 'Wrong Amount.');
                LibraryReportDataset.FindCurrentRowValue('BillNo_CustLedgEntry', ReportBillNo);
                Assert.AreEqual(Format(CarteraDoc."No."), Format(ReportBillNo), 'Wrong Bill No.');
            end
        end;

        Assert.IsTrue(Found, 'Document entry was not found in dataset.');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReceivableBillRequestPageHandler(var ReceivableBillPage: TestRequestPage "Receivable Bill")
    var
        DataSetFileName: Text;
        DataSetParameterFileName: Text;
    begin
        DataSetFileName := LibraryReportDataset.GetFileName();
        DataSetParameterFileName := LibraryReportDataset.GetParametersFileName();

        ReceivableBillPage.SaveAsXml(DataSetParameterFileName, DataSetFileName)
    end;
}

