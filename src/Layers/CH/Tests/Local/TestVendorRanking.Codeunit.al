codeunit 144034 "Test Vendor Ranking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        ColumnOption: Option Balance,Movement,"Balance Due",Purchase,"Invoice Amount","Credit Memos",Payments,Backlog,"Shipped not Invoiced","Budget Amount","<blank>";

    local procedure Initialize()
    begin
        LibraryReportDataset.Reset();
    end;

    [Normal]
    local procedure VendorRankingTest(Column1Option: Option; Column2Option: Option; Column1Name: Text; Column2Name: Text)
    var
        Vendor: Record Vendor;
        Col1Text: Variant;
        Col2Text: Variant;
        Col1Amount: Variant;
        ExpectedNumberOfRecords: Integer;
        i: Integer;
    begin
        Initialize();

        ExpectedNumberOfRecords := LibraryRandom.RandInt(20);
        LibraryVariableStorage.Enqueue(ExpectedNumberOfRecords);
        LibraryVariableStorage.Enqueue(Column1Option);
        LibraryVariableStorage.Enqueue(Column2Option);

        REPORT.Run(REPORT::"SR Vendor Ranking");

        // Verify
        LibraryReportDataset.LoadDataSetFile();

        Assert.AreEqual(ExpectedNumberOfRecords, LibraryReportDataset.RowCount(), 'Incorrect number of records');

        for i := 0 to LibraryReportDataset.RowCount() - 1 do begin
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.GetElementValueInCurrentRow('Col1Txt', Col1Text);
            LibraryReportDataset.GetElementValueInCurrentRow('Col1Amt', Col1Amount);
            LibraryReportDataset.GetElementValueInCurrentRow('Col2Txt', Col2Text);

            Assert.AreEqual(Column1Name, Col1Text, 'Incorrect column1 name');
            Assert.AreEqual(Column2Name, Col2Text, 'Incorrect column2 name');

            case Column1Option of
                ColumnOption::Balance:
                    Vendor.SetFilter("Balance (LCY)", '>%1', Col1Amount);
                ColumnOption::"Balance Due":
                    Vendor.SetFilter("Balance Due (LCY)", '>%1', Col1Amount);
                ColumnOption::Purchase:
                    Vendor.SetFilter("Purchases (LCY)", '>%1', Col1Amount);
                ColumnOption::"Credit Memos":
                    Vendor.SetFilter("Cr. Memo Amounts (LCY)", '>%1', Col1Amount);
                ColumnOption::Payments:
                    Vendor.SetFilter("Payments (LCY)", '>%1', Col1Amount);
                ColumnOption::"Invoice Amount":
                    Vendor.SetFilter("Inv. Amounts (LCY)", '>%1', Col1Amount);
            end;
            Assert.AreEqual(i, Vendor.Count, 'Incorrect ranking of vendors')
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorRankingRequestPageHandler(var CustRankingRequestPage: TestRequestPage "SR Vendor Ranking")
    var
        NumberOfRecords: Variant;
        Column1Option: Variant;
        Column2Option: Variant;
    begin
        LibraryVariableStorage.Dequeue(NumberOfRecords);
        LibraryVariableStorage.Dequeue(Column1Option);
        LibraryVariableStorage.Dequeue(Column2Option);

        CustRankingRequestPage.MaxNoOfRecs.SetValue(NumberOfRecords);
        CustRankingRequestPage."Column[1]".SetValue(Column1Option);
        CustRankingRequestPage."Column[2]".SetValue(Column2Option);

        CustRankingRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('VendorRankingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorRankingBalance()
    begin
        VendorRankingTest(ColumnOption::Balance, ColumnOption::Movement, 'Balance', 'Movement');
    end;

    [Test]
    [HandlerFunctions('VendorRankingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorRankingBalanceDue()
    begin
        VendorRankingTest(ColumnOption::"Balance Due", ColumnOption::Purchase, 'Balance Due', 'Purchase');
    end;

    [Test]
    [HandlerFunctions('VendorRankingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorRankingPurchase()
    begin
        VendorRankingTest(ColumnOption::Purchase, ColumnOption::"Invoice Amount", 'Purchase', 'Invoice Amount');
    end;

    [Test]
    [HandlerFunctions('VendorRankingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorRankingPayments()
    begin
        VendorRankingTest(ColumnOption::Payments, ColumnOption::Backlog, 'Payments', 'Backlog');
    end;

    [Test]
    [HandlerFunctions('VendorRankingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorRankingInvoiceAmount()
    begin
        VendorRankingTest(ColumnOption::"Invoice Amount", ColumnOption::"Shipped not Invoiced", 'Invoice Amount', 'Shipped not Invoiced');
    end;
}

