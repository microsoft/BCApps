codeunit 134033 "ERM Vendor Date Compression"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Date Compression] [Purchase]
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

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressionByWeek()
    var
        DateComprRegister: Record "Date Compr. Register";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        FirstPostingDate: Date;
        LastPostingDate: Date;
        NoOfEntries: Integer;
    begin
        // Check No. of Vendor Ledger Entries, Amount after posting Payment and Invoices, and Running Date Compression by Week.

        // Create Vendor and Create multiple Invoice and Payment entries on General Journal Line and Post them. Date Compress by Week and
        // verify the Amount and No. of Entries in Vendor Ledger Entries. Take 1 Week Interval between posting dates to test date
        // compression on lower and upper bounds randomly.
        Initialize();
        VendorNo := CreateVendor();
        FirstPostingDate := LibraryFiscalYear.GetFirstPostingDate(true);
        LastPostingDate := VendorDateCompression(VendorNo, DateComprRegister."Period Length"::Week, FirstPostingDate, '<1W>');
        NoOfEntries := ComputeNoOfWeek(FirstPostingDate, LastPostingDate);

        // Verify: Verify No. of Entries after Date Compression by Week.
        Assert.AreEqual(NoOfEntries, GetVendorLedgerEntries(VendorNo), StrSubstNo(CountError, NoOfEntries, VendorLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressionByMonth()
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        // Check No. of Vendor Ledger Entries, Amount after posting Payment and Invoices, and Running Date Compression by Month.

        // Date Compress by Month and verify No. of Entries and Amount in Vendor Ledger Entries. Pass 2 to fetch Entries for Month.
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
        // Check No. of Vendor Ledger Entries, Amount after posting Payment and Invoices, and Running Date Compression by Year.

        // Date Compress by Year and verify No. of Entries and Amount in Vendor Ledger Entries. Pass 3 to fetch Entries for Year.
        // Take 3 Months interval between entries to test Date Compression on Upper and Lower boundaries randomly.
        Initialize();
        DateCompressionMonthYear(DateComprRegister."Period Length"::Year, '<3M>', 3)
    end;

    local procedure DateCompressionMonthYear(PeriodLength: Option; PeriodDifference: Text[10]; PeriodOption: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        FirstPostingDate: Date;
        LastPostingDate: Date;
        NoOfEntries: Integer;
    begin
        // Create Vendor. Create multiple Invoice and Payment entries on General Journal Line and Post them. Date Compress as per the
        // Period Length selected. Verify the Amount and No. of Entries in Vendor Ledger Entries.
        VendorNo := CreateVendor();
        FirstPostingDate := LibraryFiscalYear.GetFirstPostingDate(true);
        LastPostingDate := VendorDateCompression(VendorNo, PeriodLength, FirstPostingDate, PeriodDifference);

        // Compute No. of Entries after Date Compression by Month. Pass 2 For Month, 3 for Year as option for computing entries.
        NoOfEntries := 1 + (Date2DMY(LastPostingDate, PeriodOption) - Date2DMY(FirstPostingDate, PeriodOption));

        // Verify: Verify No. of Entries after Date Compression for Month/Year selected.
        Assert.AreEqual(NoOfEntries, GetVendorLedgerEntries(VendorNo), StrSubstNo(CountError, NoOfEntries, VendorLedgerEntry.TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Vendor Date Compression");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Vendor Date Compression");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Vendor Date Compression");
    end;

    local procedure VendorDateCompression(VendorNo: Code[20]; PeriodLength: Option; FirstPostingDate: Date; Period: Text[10]): Date
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoOfLines: Integer;
        JnlLineAmount: Decimal;
    begin
        // Setup: Close the Open Fiscal Year. Make Payment and Invoice entries for a Vendor from General Journal Line with same random
        // amount and Post them.
        NoOfLines := LibraryRandom.RandInt(5);
        CreateDocumentLine(GenJournalLine, VendorNo, NoOfLines, FirstPostingDate, Period);
        JnlLineAmount := NoOfLines * GenJournalLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Run the Date Compress Vendor Ledger Batch Report.
        DateCompressForVendor(GenJournalLine, FirstPostingDate, PeriodLength);

        // Verify: Verify the Amount in Vendor Ledger Entry.
        VerifyVendorLedgerEntry(GenJournalLine."Account No.", JnlLineAmount);
        exit(GenJournalLine."Posting Date");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // Create Vendor with Application Method: Apply to Oldest.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Application Method", Vendor."Application Method"::"Apply to Oldest");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; NoOfLines: Integer; PostingDate: Date; Period: Text[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
        Counter: Integer;
    begin
        // Create multiple Journal Lines for Payment and Invoice with similar Random Amount. Take different Posting Dates.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        Amount := LibraryRandom.RandDec(5, 2);
        for Counter := 1 to NoOfLines do begin
            LibraryFiscalYear.CheckPostingDate(PostingDate);  // Check that no Posting Dates are outside Accounting Periods.
            CreateGeneralJournalLine(
              GenJournalLine, GenJournalBatch, VendorNo, GenJournalLine."Document Type"::Invoice, IncStr(GenJournalLine."Document No."),
              -Amount, PostingDate);
            CreateGeneralJournalLine(
              GenJournalLine, GenJournalBatch, VendorNo, GenJournalLine."Document Type"::Payment, IncStr(GenJournalLine."Document No."),
              Amount, PostingDate);
            PostingDate := CalcDate('<' + Period + '>', PostingDate);
        end;
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal; PostingDate: Date)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, GenJournalLine."Account Type"::Vendor,
          VendorNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        if DocumentNo <> '' then begin
            GenJournalLine.Validate("Document No.", DocumentNo);
            GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        end;
        GenJournalLine.Modify(true);
    end;

    local procedure DateCompressForVendor(GenJournalLine: Record "Gen. Journal Line"; StartingDate: Date; PeriodLength: Option)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressVendorLedger: Report "Date Compress Vendor Ledger";
    begin
        // Run the Date Compress Vendor Ledger Report with a closed Accounting Period.
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        DateComprRetainFields."Retain Document No." := false;
        DateComprRetainFields."Retain Buy-from Vendor No." := false;
        DateComprRetainFields."Retain Purchaser Code" := false;
        DateComprRetainFields."Retain Journal Template Name" := false;
        DateCompressVendorLedger.SetTableView(VendorLedgerEntry);
        DateCompressVendorLedger.InitializeRequest(StartingDate, GenJournalLine."Posting Date", PeriodLength, '', DateComprRetainFields, '', false);
        DateCompressVendorLedger.UseRequestPage(false);
        DateCompressVendorLedger.Run();
    end;

    local procedure GetVendorLedgerEntries(VendorNo: Code[20]): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        exit(VendorLedgerEntry.Count);
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

    local procedure FindFirstDayOfPeriod(PeriodStart: Date) StartingDate: Date
    var
        Date: Record Date;
    begin
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetRange("Period Start", PeriodStart);
        Date.FindFirst();
        StartingDate := CalcDate('<-' + Format(Date."Period No." - 1) + 'D>', Date."Period Start");
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20]; JnlLinePaymentAmt: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntryAmt: Decimal;
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.CalcFields(Amount);
            VendorLedgerEntryAmt += VendorLedgerEntry.Amount;
        until VendorLedgerEntry.Next() = 0;
        Assert.AreEqual(
          JnlLinePaymentAmt, VendorLedgerEntryAmt, StrSubstNo(AmountError, VendorLedgerEntry.FieldCaption(Amount),
            JnlLinePaymentAmt, VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;
}

