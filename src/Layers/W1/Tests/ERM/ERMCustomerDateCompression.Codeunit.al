codeunit 134032 "ERM Customer Date Compression"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Date Compression] [Sales]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be %2 in \\%3, %4=%5.';
        CountError: Label 'No. of Entries must be %1 in %2.';
        UnapplyDateCompressError: Label 'The entry cannot be unapplied, because the %1 has been compressed.';
        ErrorMessageDoNotMatch: Label 'Error Message must be same.';

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressionByWeek()
    var
        DateComprRegister: Record "Date Compr. Register";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        FirstPostingDate: Date;
        LastPostingDate: Date;
        NoOfEntries: Integer;
    begin
        // Check No. of Customer Ledger Entries, Amount after posting Payment and Invoices, and Running Date Compression by Week.

        // Create Customer. Create multiple Invoice and Payment entries on General Journal Line and Post them. Date Compress by Week and
        // verify the Amount and No. of Entries in Customer Ledger Entries. Take 1 Week interval between posting dates to test date
        // compression on lower and upper bounds randomly.
        Initialize();
        CustomerNo := CreateCustomer();
        FirstPostingDate := LibraryFiscalYear.GetFirstPostingDate(true);
        LastPostingDate := CustomerDateCompression(CustomerNo, DateComprRegister."Period Length"::Week, FirstPostingDate, '<1W>');
        NoOfEntries := ComputeNoOfWeek(FirstPostingDate, LastPostingDate);

        // Verify: Verify No. of Entries after Date Compression by Week.
        Assert.AreEqual(
          NoOfEntries, GetCustomerLedgerEntries(CustomerNo), StrSubstNo(CountError, NoOfEntries, CustLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressionByMonth()
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        // Check No. of Customer Ledger Entries, Amount after posting Payment and Invoices, and Running Date Compression by Month.

        // Date Compress by Month and verify No. of Entries and Amount in Customer Ledger Entries. Pass 2 to fetch Entries for Month.
        // Take 10 Days interval between entries to test Date Compression on Upper and Lower boundaries randomly.
        Initialize();
        DateCompressionMonthYear(DateComprRegister."Period Length"::Month, '<10D>', 2)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressionByYear()
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        // Check No. of Customer Ledger Entries, Amount after posting Payment and Invoices, and Running Date Compression by Year.

        // Date Compress by Year and verify No. of Entries and Amount in Customer Ledger Entries. Pass 3 to fetch Entries for Year.
        // Take 3 Months interval between entries to test Date Compression on Upper and Lower boundaries randomly.
        Initialize();
        DateCompressionMonthYear(DateComprRegister."Period Length"::Year, '<3M>', 3)
    end;

    local procedure DateCompressionMonthYear(PeriodLength: Option; PeriodDifference: Text[10]; PeriodOption: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        FirstPostingDate: Date;
        LastPostingDate: Date;
        NoOfEntries: Integer;
    begin
        // Create Customer. Create multiple Invoice and Payment entries on General Journal Line and Post them. Date Compress as per the
        // Period Length selected. Verify the Amount and No. of Entries in Customer Ledger Entries.
        CustomerNo := CreateCustomer();
        FirstPostingDate := LibraryFiscalYear.GetFirstPostingDate(true);
        LastPostingDate := CustomerDateCompression(CustomerNo, PeriodLength, FirstPostingDate, PeriodDifference);

        // Compute No. of Entries after Date Compression by Month. Pass 2 For Month, 3 for Year as option for computing entries.
        NoOfEntries := 1 + (Date2DMY(LastPostingDate, PeriodOption) - Date2DMY(FirstPostingDate, PeriodOption));

        // Verify: Verify No. of Entries after Date Compression for Month/Year selected.
        Assert.AreEqual(
          NoOfEntries, GetCustomerLedgerEntries(CustomerNo), StrSubstNo(CountError, NoOfEntries, CustLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyDateCompressCustEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DateComprRegister: Record "Date Compr. Register";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        // Verify error when Unapplying Customer Ledger Entry that are Date Compressed.

        // Setup: Create and post General Journal Lines, Compress the Customer Ledger Entry.
        Initialize();
        CreateDocumentLine(GenJournalLine, CreateCustomer(), 1, LibraryFiscalYear.GetFirstPostingDate(true), '');
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DateCompressForCustomer(GenJournalLine, GenJournalLine."Posting Date", DateComprRegister."Period Length"::Week);
        FindDetailedCustLedgerEntry(DetailedCustLedgEntry, GenJournalLine."Account No.", GenJournalLine."Document Type");
        ApplyUnapplyParameters."Document No." := GenJournalLine."Document No.";
        ApplyUnapplyParameters."Posting Date" := GenJournalLine."Posting Date";

        // Exercise: Unapply Customer Ledger Entry.
        asserterror CustEntryApplyPostedEntries.PostUnApplyCustomer(
            DetailedCustLedgEntry, ApplyUnapplyParameters);

        // Verify: Verify error when Unapplying Customer Ledger Entry.
        Assert.AreEqual(
          StrSubstNo(UnapplyDateCompressError, CustLedgerEntry.TableCaption()), GetLastErrorText, ErrorMessageDoNotMatch);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Customer Date Compression");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Customer Date Compression");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Customer Date Compression");
    end;

    local procedure CustomerDateCompression(CustomerNo: Code[20]; PeriodLength: Option; FirstPostingDate: Date; Period: Text[10]): Date
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoOfLines: Integer;
        JnlLineAmount: Decimal;
    begin
        // Setup: Close the Open Fiscal Year. Make Payment and Invoice entries for a Customer from General Journal Line with same random
        // amount and Post them.
        NoOfLines := LibraryRandom.RandInt(5);
        CreateDocumentLine(GenJournalLine, CustomerNo, NoOfLines, FirstPostingDate, Period);
        JnlLineAmount := NoOfLines * GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Run the Date Compress Customer Ledger Batch Report.
        DateCompressForCustomer(GenJournalLine, FirstPostingDate, PeriodLength);

        // Verify: Verify the Amount in Customer Ledger Entry.
        VerifyCustomerLedgerEntry(GenJournalLine."Account No.", JnlLineAmount);
        exit(GenJournalLine."Posting Date");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Create Customer with Application Method: Apply to Oldest.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; NoOfLines: Integer; PostingDate: Date; Period: Text[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
        Counter: Integer;
    begin
        // Create multiple Journal Lines for Payment and Invoice with similar Random Amount. Take different Posting Dates.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        Amount := LibraryRandom.RandDec(50, 2);
        for Counter := 1 to NoOfLines do begin
            LibraryFiscalYear.CheckPostingDate(PostingDate);  // Check that no Posting Dates are outside Accounting Periods.
            CreateGeneralJournalLine(
              GenJournalLine, GenJournalBatch, CustomerNo, GenJournalLine."Document Type"::Invoice, IncStr(GenJournalLine."Document No."),
              Amount, PostingDate);
            CreateGeneralJournalLine(
              GenJournalLine, GenJournalBatch, CustomerNo, GenJournalLine."Document Type"::Payment, IncStr(GenJournalLine."Document No."),
              -Amount, PostingDate);
            PostingDate := CalcDate('<' + Period + '>', PostingDate);
        end;
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal; PostingDate: Date)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        if DocumentNo <> '' then
            GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure ComputeNoOfWeek(FirstPostingDate: Date; LastPostingDate: Date): Integer
    var
        Date: Record Date;
    begin
        Date.SetRange("Period Type", Date."Period Type"::Week);
        Date.SetRange("Period Start", FindFirstDayOfPeriod(FirstPostingDate), FindFirstDayOfPeriod(LastPostingDate));
        if (Date2DMY(LastPostingDate, 1) = 1) and (FirstPostingDate <> LastPostingDate) then
            exit(Date.Count + 1);
        exit(Date.Count);
    end;

    local procedure DateCompressForCustomer(GenJournalLine: Record "Gen. Journal Line"; StartingDate: Date; PeriodLength: Option)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressCustomerLedger: Report "Date Compress Customer Ledger";
    begin
        // Run the Date Compress Customer Ledger Report with a closed Accounting Period.
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        DateCompressCustomerLedger.SetTableView(CustLedgerEntry);
        DateComprRetainFields."Retain Document No." := false;
        DateComprRetainFields."Retain Sell-to Customer No." := false;
        DateComprRetainFields."Retain Salesperson Code" := false;
        DateComprRetainFields."Retain Journal Template Name" := false;
        DateCompressCustomerLedger.InitializeRequest(StartingDate, GenJournalLine."Posting Date", PeriodLength, '', DateComprRetainFields, '', false);
        DateCompressCustomerLedger.UseRequestPage(false);
        DateCompressCustomerLedger.Run();
    end;

    local procedure FindFirstDayOfPeriod(PeriodStart: Date) StartingDate: Date
    var
        Date: Record Date;
    begin
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetRange("Period Start", PeriodStart);
        Date.FindFirst();
        StartingDate := CalcDate('<-' + Format(Date."Period No." - 1) + 'D>', Date."Period Start");
    end;

    local procedure FindDetailedCustLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.FindFirst();
    end;

    local procedure GetCustomerLedgerEntries(CustomerNo: Code[20]): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        exit(CustLedgerEntry.Count);
    end;

    local procedure VerifyCustomerLedgerEntry(CustomerNo: Code[20]; JnlLinePaymentAmt: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgEntryAmt: Decimal;
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.CalcFields(Amount);
            CustLedgEntryAmt += CustLedgerEntry.Amount;
        until CustLedgerEntry.Next() = 0;
        Assert.AreEqual(
          JnlLinePaymentAmt, CustLedgEntryAmt, StrSubstNo(AmountError, CustLedgerEntry.FieldCaption(Amount), JnlLinePaymentAmt,
            CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
    end;
}

