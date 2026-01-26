codeunit 141000 "Report Layout - Local"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        ReportFilePath: Text;
        EmptyFileError: Label 'File content is empty! Either data needs to be created or the correct filters need to be set.';
        IsInitialized: Boolean;

    local procedure Init()
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
    end;

    [Test]
    [HandlerFunctions('RHCustOrdersPeriod')]
    [Scope('OnPrem')]
    procedure TestCustOrdersPeriod()
    begin
        //Execute
        REPORT.Run(REPORT::"SR Cust. Orders per Period");

        //Verify
        VerifyFileCreated(ReportFilePath);
    end;

    [Test]
    [HandlerFunctions('RHVenDueAmountPeriod')]
    [Scope('OnPrem')]
    procedure TestVenDueAmountPeriod()
    begin
        //Execute
        REPORT.Run(REPORT::"SR Ven. Due Amount per Period");

        //Verify
        VerifyFileCreated(ReportFilePath);
    end;

    [Test]
    [HandlerFunctions('RHVendorOrderPeriod')]
    [Scope('OnPrem')]
    procedure TestVendorOrderPeriod()
    begin
        //Execute
        REPORT.Run(REPORT::"SR Vendor Orders per Period");

        //Verify
        VerifyFileCreated(ReportFilePath);
    end;

    [Test]
    [HandlerFunctions('BatchesPageHandler,CashReceiptJnlPageHandler,CustESRJnlRepHandler')]
    [Scope('OnPrem')]
    procedure TestCustESRJnlReport()
    var
        CustNo: Code[20];
        LinesCount: Integer;
    begin
        Init();

        CustNo := CreateCustomer();
        LinesCount := LibraryRandom.RandInt(10);
        CreateRunBatchAndCallReport(true, CustNo, CreateCustomer(), LinesCount);

        VerifyReportDataset(LinesCount, CustNo);
    end;

    [Test]
    [HandlerFunctions('BatchesPageHandler,VendPaymentJnlPageHandler,VendDTAPaymentJnlRepHandler')]
    [Scope('OnPrem')]
    procedure TestVendDTAPaymentJnlReport()
    var
        VendNo: Code[20];
        LinesCount: Integer;
    begin
        Init();

        VendNo := CreateVendor();
        LinesCount := LibraryRandom.RandInt(10);
        CreateRunBatchAndCallReport(false, VendNo, CreateVendor(), LinesCount);

        VerifyReportDataset(LinesCount, VendNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustOrdersPeriod(var CustOrdersPeriod: TestRequestPage "SR Cust. Orders per Period")
    begin
        CustOrdersPeriod."Start Date".SetValue(WorkDate());
        CustOrdersPeriod."Period Length".SetValue(GetPeriodLength());
        ReportFilePath := FormatFileName(CustOrdersPeriod.Caption);
        if Exists(ReportFilePath) then
            Erase(ReportFilePath);
        CustOrdersPeriod.SaveAsPdf(ReportFilePath);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVenDueAmountPeriod(var VenDueAmountPeriod: TestRequestPage "SR Ven. Due Amount per Period")
    begin
        VenDueAmountPeriod."Key Date".SetValue(WorkDate());
        VenDueAmountPeriod."Period Length".SetValue(GetPeriodLength());
        ReportFilePath := FormatFileName(VenDueAmountPeriod.Caption);
        if Exists(ReportFilePath) then
            Erase(ReportFilePath);
        VenDueAmountPeriod.SaveAsPdf(ReportFilePath);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorOrderPeriod(var VendorOderPeriod: TestRequestPage "SR Vendor Orders per Period")
    begin
        VendorOderPeriod."Start Date".SetValue(WorkDate());
        VendorOderPeriod."Period Length".SetValue(GetPeriodLength());
        ReportFilePath := FormatFileName(VendorOderPeriod.Caption);
        if Exists(ReportFilePath) then
            Erase(ReportFilePath);
        VendorOderPeriod.SaveAsPdf(ReportFilePath);
    end;

    local procedure FormatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;

    local procedure IsFileEmpty(FilePath: Text) FileEmpty: Boolean
    var
        File: File;
    begin
        FileEmpty := not Exists(FilePath);
        if not FileEmpty then begin
            File.Open(FilePath);
            File.TextMode(true);
            FileEmpty := File.Len = 0;
            File.Close();
        end
    end;

    local procedure VerifyFileCreated(FilePath: Text)
    begin
        if IsFileEmpty(FilePath) then
            Error(EmptyFileError)
    end;

    local procedure GetPeriodLength(): Text
    var
        PeriodLength: DateFormula;
    begin
        Evaluate(PeriodLength, '<1M>');
        exit(Format(PeriodLength));
    end;

    local procedure CreateGenJnlBatchAndSeveralLines(GenJnlTemplateName: Code[10]; IsCust: Boolean; CVNo: Code[20]; LinesCount: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        CreateGeneralJournalBatchWithBankAcc(GenJournalBatch, GenJnlTemplateName);

        for i := 1 to LinesCount do
            CreateGenJournalLine(GenJournalBatch, IsCust, CVNo);
    end;

    local procedure CreateGenJnlTemplate(IsCust: Boolean): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        if IsCust then
            GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::"Cash Receipts")
        else
            GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify();
        exit(GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralJournalBatchWithBankAcc(var GenJournalBatch: Record "Gen. Journal Batch"; GenJnlTemplName: Code[10])
    var
        BankAccount: Record "Bank Account";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJnlTemplName);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJournalLine(GenJnlBatch: Record "Gen. Journal Batch"; IsCust: Boolean; CVNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        RecRef: RecordRef;
    begin
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        RecRef.GetTable(GenJnlLine);
        GenJnlLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, GenJnlLine.FieldNo("Line No."));
        GenJnlLine."Posting Date" := WorkDate();
        GenJnlLine.Amount := LibraryRandom.RandDec(100, 2);
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        if IsCust then
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer
        else
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Account No." := CVNo;
        GenJnlLine.Insert();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateRunBatchAndCallReport(IsCust: Boolean; CVNo1: Code[20]; CVNo2: Code[20]; LinesCount: Integer)
    var
        GenJnlTemplName: Code[10];
    begin
        GenJnlTemplName := CreateGenJnlTemplate(IsCust);
        CreateGenJnlBatchAndSeveralLines(GenJnlTemplName, IsCust, CVNo1, LinesCount);
        CreateGenJnlBatchAndSeveralLines(GenJnlTemplName, IsCust, CVNo2, LinesCount + LibraryRandom.RandInt(10));
        RunGenJnlBatches(GenJnlTemplName);
    end;

    local procedure RunGenJnlBatches(GenJnlTemplName: Code[10])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        Batches: Page "General Journal Batches";
    begin
        // Call page 251 "General Journal Batches"
        Commit();
        GenJnlBatch.SetRange("Journal Template Name", GenJnlTemplName);
        Batches.SetTableView(GenJnlBatch);
        Batches.Run();
    end;

    local procedure VerifyReportDataset(ExpectedRowCount: Integer; ExpectedAccountNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(ExpectedRowCount, LibraryReportDataset.RowCount(), '');
        LibraryReportDataset.MoveToRow(1);
        repeat
            LibraryReportDataset.AssertCurrentRowValueEquals('AccountNo_GenJournalLine', ExpectedAccountNo);
        until LibraryReportDataset.GetNextRow() = false;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BatchesPageHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        // Call page 255 "Cash Receipt Journal" in case of Cash Receipt Journal Template
        // Call page 256 "Payment Journal" in case of Payment Journal Template
        GeneralJournalBatches.EditJournal.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CashReceiptJnlPageHandler(var CashReceiptJournal: TestPage "Cash Receipt Journal")
    begin
        // Call Report 3010531 "Customer ESR Journal"
        CashReceiptJournal."Print ESR Journal".Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendPaymentJnlPageHandler(var VendPaymentJournal: TestPage "Payment Journal")
    begin
        // Call Report 3010545 "DTA Payment Journal"
        VendPaymentJournal."Print Payment Journal".Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustESRJnlRepHandler(var CustESRJnl: TestRequestPage "Customer ESR Journal")
    begin
        //Save as XML with reportdataset library
        CustESRJnl.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendDTAPaymentJnlRepHandler(var VendDTAPaymentJnl: TestRequestPage "DTA Payment Journal")
    begin
        //Save as XML with reportdataset library
        VendDTAPaymentJnl.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

