codeunit 134035 "ERM Vend Date Compress Manual"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Date Compression] [Purchase]
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
        // Check that Entry Posted outside the Date Compression Period is not present in Vendor Ledger Entries after
        // Running Date Compression by Week. Take One Week Difference between Entries.
        Initialize();
        VendorDateCompression(DateComprRegister."Period Length"::Week, '<1W>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressionByMonth()
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        // Check that entry Posted outside the Date Compression Period is not present in Compressed Vendor Ledger Entries after
        // Running Date Compression by Month. Take One Month Difference between Entries.
        Initialize();
        VendorDateCompression(DateComprRegister."Period Length"::Month, '<1M>');
    end;

    local procedure VendorDateCompression(DateCompessionPeriod: Option; PeriodDifference: Text[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        PostingDate: Date;
        Counter: Integer;
    begin
        // Setup: Close any open Fiscal Year. Create Vendor, Post multiple Invoice and Payment Entries on different dates for Vendor
        // and apply Payment over Invoice.
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(true);
        LibraryPurchase.CreateVendor(Vendor);
        for Counter := 1 to 1 + LibraryRandom.RandInt(2) do begin   // Using 1 + Random for creating multiple entries.
            CreateAndPostGenJournalLines(GenJournalLine, Vendor."No.", PostingDate, PeriodDifference);
            ApplyAndPostVendorEntry(GenJournalLine);
            PostingDate := GenJournalLine."Posting Date";
        end;

        // Exercise: Run the Date Compress Vendor Ledger Batch Report as per the option selected.
        DateCompressForVendor(GenJournalLine, LibraryFiscalYear.GetFirstPostingDate(true), DateCompessionPeriod);

        // Verify: Verify that Last Posted Entry must not be compressed.
        VerifyVendorLedgerEntry(PostingDate);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Vend Date Compress Manual");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Vend Date Compress Manual");
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Vend Date Compress Manual");
    end;

    local procedure CreateAndPostGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; PostingDate: Date; PeriodDifference: Text[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create Journal Lines with Random Decimal Amount and Post them. Take Invoice Value always greater than Payment.
        LibraryERM.SelectLastGenJnBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, VendorNo,
          PostingDate, -(1 + LibraryRandom.RandDec(50, 2)));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, VendorNo,
          CalcDate('<' + PeriodDifference + '>', GenJournalLine."Posting Date"),
          -(GenJournalLine.Amount - LibraryRandom.RandDec(1, 2)));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyAndPostVendorEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, GenJournalLine.Amount);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No.");
        VendorLedgerEntry2.CalcFields("Remaining Amount");
        VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
        VendorLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; PostingDate: Date; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure DateCompressForVendor(GenJournalLine: Record "Gen. Journal Line"; StartingDate: Date; PeriodLength: Option)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressVendorLedger: Report "Date Compress Vendor Ledger";
    begin
        // Run the Date Compress Vendor Ledger Report. Take End Date a Day before Last Posted Entry's Posting Date.
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        DateComprRetainFields."Retain Document No." := false;
        DateComprRetainFields."Retain Buy-from Vendor No." := false;
        DateComprRetainFields."Retain Purchaser Code" := false;
        DateComprRetainFields."Retain Journal Template Name" := false;
        DateCompressVendorLedger.SetTableView(VendorLedgerEntry);
        DateCompressVendorLedger.InitializeRequest(
          StartingDate, CalcDate('<-1D>', GenJournalLine."Posting Date"), PeriodLength, '', DateComprRetainFields, '', false);
        DateCompressVendorLedger.UseRequestPage(false);
        DateCompressVendorLedger.Run();
    end;

    local procedure VerifyVendorLedgerEntry(LastPostingDate: Date)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLRegister: Record "G/L Register";
    begin
        GLRegister.FindLast();
        VendorLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        VendorLedgerEntry.FindSet();
        repeat
            Assert.AreNotEqual(LastPostingDate, VendorLedgerEntry."Posting Date", EntryError);
        until VendorLedgerEntry.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm Handler for Date Compression confirmation message.
        Reply := true;
    end;
}

