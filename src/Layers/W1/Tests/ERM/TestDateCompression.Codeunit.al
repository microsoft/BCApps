codeunit 134169 "Test Date Compression"
{
    Subtype = test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        DateCompressionEndingDateErr: Label 'The end date %1 is not valid. You must keep at least %2 years uncompressed.', Comment = '%1 is a date in short date format, %2 is an integer';

    [Test]
    procedure TestRunDateCompressionAllReports()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateComprRegister: Record "Date Compr. Register";
        DateCompression: Codeunit "Date Compression";
    begin
        // [Scenario] Run all date compression reports in one go
        // Setup
        DateComprRegister.DeleteAll();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        FillDateComprSettingsTable(DateComprSettingsBuffer);

        // Exercise
        DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.TableIsNotEmpty(DataBase::"Date Compr. Register");
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodCompressGLEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compress G/L Entries" := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodDateCompVATEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compress VAT Entries" := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodDateCompBankAccLedgEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compr. Bank Acc. Ledg Entries" := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodDateCompCustomerLedgerEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compr. Customer Ledger Entries" := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodDateCompVendorLedgerEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compress Vendor Ledger Entries" := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodDateCompFALedgerEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compress FA Ledger Entries" := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodDateCompMaintenanceLedgerEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compr. Maintenance Ledg. Entr." := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodDateCompGLBudgetEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compress G/L Budget Entries" := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodDateCompResourceLedgerEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compr. Resource Ledger Entries" := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodDateCompInsuranceLedgEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compr. Insurance Ledg. Entries" := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodDateCompWarehouseEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compress Warehouse Entries" := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    [Test]
    procedure TestMinimumUncompressedPeriodDateCompItemBudgetEntries()
    var
        DateComprSettingsBuffer: Record "Date Compr. Settings Buffer";
        DateCompression: Codeunit "Date Compression";
        NoOfUncompressedYears: Integer;
    begin
        // Setup
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        DateCompression.InitDateComprSettingsBuffer(DateComprSettingsBuffer);
        NoOfUncompressedYears := 5;
        DateComprSettingsBuffer."Ending Date" := DateCompression.CalcMaxEndDate() + 1;
        DateComprSettingsBuffer."Compress Item Budget Entries" := true;

        // Exercise
        asserterror DateCompression.RunDateCompression(DateComprSettingsBuffer);

        // Verify
        Assert.ExpectedError(StrSubstNo(DateCompressionEndingDateErr, DateComprSettingsBuffer."Ending Date", NoOfUncompressedYears));
    end;

    local procedure FillDateComprSettingsTable(var DateComprSettingsBuffer: Record "Date Compr. Settings Buffer")
    begin
        DateComprSettingsBuffer."Compress G/L Entries" := true;
        DateComprSettingsBuffer."Compress VAT Entries" := true;
        DateComprSettingsBuffer."Compr. Bank Acc. Ledg Entries" := true;
        DateComprSettingsBuffer."Compr. Customer Ledger Entries" := true;
        DateComprSettingsBuffer."Compress Vendor Ledger Entries" := true;
        DateComprSettingsBuffer."Compress FA Ledger Entries" := true;
        DateComprSettingsBuffer."Compr. Maintenance Ledg. Entr." := true;
        DateComprSettingsBuffer."Compress G/L Budget Entries" := true;
        DateComprSettingsBuffer."Compr. Resource Ledger Entries" := true;
        DateComprSettingsBuffer."Compr. Insurance Ledg. Entries" := true;
        DateComprSettingsBuffer."Compress Warehouse Entries" := true;
        DateComprSettingsBuffer."Compress Item Budget Entries" := true;

        DateComprSettingsBuffer."Delete Empty Registers" := true;

        DateComprSettingsBuffer.Description := 'Test Date Compression';
    end;
}