codeunit 134034 "ERM Cust Date Compress Manual"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Date Compression] [Sales]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        IsInitialized: Boolean;
        EntryError: Label 'Entries posted after Date Compression End Date must not be compressed.';

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressionByWeek()
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        // Check that entry Posted outside the Date Compression Period is not present in Compressed Customer Ledger Entries after
        // Running Date Compression by Week. Take One Week Difference between Entries.
        Initialize();
        CustomerDateCompression(DateComprRegister."Period Length"::Week, '<1W>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressionByMonth()
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        // Check that entry Posted outside the Date Compression Period is not present in Compressed Customer Ledger Entries after
        // Running Date Compression by Month. Take One Month Difference between Entries.
        Initialize();
        CustomerDateCompression(DateComprRegister."Period Length"::Month, '<1M>');
    end;

    local procedure CustomerDateCompression(DateCompessionPeriod: Option; PeriodDifference: Text[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        PostingDate: Date;
        Counter: Integer;
    begin
        // Setup: Close any open Fiscal Year. Create Customer, Post multiple Invoice and Payment Entries on different dates for Customer
        // and apply Payment over Invoice.
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(true);
        LibrarySales.CreateCustomer(Customer);
        for Counter := 1 to 1 + LibraryRandom.RandInt(2) do begin
            CreateAndPostGenJournalLines(GenJournalLine, Customer."No.", PostingDate, PeriodDifference);
            ApplyAndPostCustomerEntry(GenJournalLine);
            PostingDate := GenJournalLine."Posting Date";
        end;

        // Exercise: Run the Date Compress Customer Ledger Batch Report as per the option selected.
        DateCompressForCustomer(GenJournalLine, LibraryFiscalYear.GetFirstPostingDate(true), DateCompessionPeriod);

        // Verify: Verify that Last Posted Entry must not be compressed.
        VerifyCustomerLedgerEntry(GenJournalLine."Posting Date");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cust Date Compress Manual");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cust Date Compress Manual");
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cust Date Compress Manual");
    end;

    local procedure CreateAndPostGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; PostingDate: Date; PeriodDifference: Text[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create Journal Lines with Random Decimal Amount and Post them. Take Invoice Value always greater than Payment.
        LibraryERM.SelectLastGenJnBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, CustomerNo, PostingDate,
          1 + LibraryRandom.RandDec(50, 2));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, CustomerNo,
          CalcDate('<' + PeriodDifference + '>', GenJournalLine."Posting Date"),
          -(GenJournalLine.Amount - LibraryRandom.RandDec(1, 2)));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyAndPostCustomerEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, GenJournalLine.Amount);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No.");
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
        CustLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; PostingDate: Date; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure DateCompressForCustomer(GenJournalLine: Record "Gen. Journal Line"; StartingDate: Date; PeriodLength: Option)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressCustomerLedger: Report "Date Compress Customer Ledger";
    begin
        // Run the Date Compress Customer Ledger Report. Take End Date a Day before Last Posted Entry's Posting Date.
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        DateCompressCustomerLedger.SetTableView(CustLedgerEntry);
        DateComprRetainFields."Retain Document No." := false;
        DateComprRetainFields."Retain Sell-to Customer No." := false;
        DateComprRetainFields."Retain Salesperson Code" := false;
        DateComprRetainFields."Retain Journal Template Name" := false;
        DateCompressCustomerLedger.InitializeRequest(
            StartingDate, CalcDate('<-1D>', GenJournalLine."Posting Date"), PeriodLength, '', DateComprRetainFields, '', false);
        DateCompressCustomerLedger.UseRequestPage(false);
        DateCompressCustomerLedger.Run();
    end;

    local procedure VerifyCustomerLedgerEntry(LastPostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        CustLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        CustLedgerEntry.FindSet();
        repeat
            Assert.AreNotEqual(LastPostingDate, CustLedgerEntry."Posting Date", EntryError);
        until CustLedgerEntry.Next() = 0;
    end;
}

