codeunit 134049 "ERM Date Compression FA"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Date Compression] [Fixed Asset]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        FARegisterErr: Label 'FA Register must be deleted for Journal Batch Name %1 .', Comment = '%1 = Journal Batch Name';
        DateLockedErr: Label 'The accounting periods for the period you wish to date compress must be Date Locked.';
        LinkedEntryDateCompressionErr: Label 'belongs to a derogatory depreciation pair';

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressOpenFiscalYear()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DateComprRegister: Record "Date Compr. Register";
        AccountingPeriod: Record "Accounting Period";
        SaveWorkDate: Date;
        FANo: Code[20];
    begin
        // Test the Date Compression with open Accounting Period.

        // 1.Setup: Create and modify Fixed Asset, create General Journal Batch, create Generel Journal Line,
        // post the FA General Journal line.
        Initialize();
        SaveWorkDate := WorkDate();
        WorkDate(CalcDate('<-7y>', Today())); // must keep at least 5y uncompressed so 7 years ensures an always compressable date
        // must have open accounting periods
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetFilter("Starting Date", '<=%1', WorkDate());
        AccountingPeriod.FindFirst(); // accouting periods were created in Initialize so we know these exist
        AccountingPeriod.SetRange("New Fiscal Year");
        AccountingPeriod.SetFilter("Starting Date", '>=%1', AccountingPeriod."Starting Date");
        AccountingPeriod.ModifyAll(Closed, false);
        AccountingPeriod.ModifyAll("Date Locked", false);

        FANo := CreateFixedAssetWithDimension();
        CreateGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, FANo, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        PostingDateInGenJournalLine(GenJournalLine, LibraryFiscalYear.GetFirstPostingDate(false));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        WorkDate(SaveWorkDate);

        // 2.Exercise: Run the Date Compress FA Ledger.
        asserterror
          RunDateCompressFALedger(
            FANo, LibraryFiscalYear.GetFirstPostingDate(false), LibraryFiscalYear.GetFirstPostingDate(false),
            DateComprRegister."Period Length"::Day);

        // 3.Verify: Verify the Error message.
        Assert.ExpectedError(DateLockedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressClosedFiscalYear()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DateComprRegister: Record "Date Compr. Register";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test the Date Compression with closed Accounting Period.

        // 1.Setup: Create and modify Fixed Asset, create General Journal Batch, create Generel Journal Line,
        // post the FA General Journal line.
        Initialize();
        FANo := CreateFixedAssetWithDimension();
        CreateGenJournalBatch(GenJournalBatch);
        Amount := CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, FANo, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        PostingDateInGenJournalLine(GenJournalLine, LibraryFiscalYear.GetFirstPostingDate(true));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Run the Date Compress FA Ledger.
        RunDateCompressFALedger(
          FANo, LibraryFiscalYear.GetFirstPostingDate(true), LibraryFiscalYear.GetFirstPostingDate(true),
          DateComprRegister."Period Length"::Day);

        // 3.Verify: Verify the FA Ledger Entry.
        VerifyAmountInFALedgerEntry(FANo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressMaintenanceLedger()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DateComprRegister: Record "Date Compr. Register";
        DateCompression: Codeunit "Date Compression";
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test Date Compression with closed Accounting Period for Maintenance Ledger Entry.

        // 1. Setup: Create and modify Fixed Asset, create General Journal Batch, Create and Post General Journal Line with FA Posting
        // Type Maintenance.
        Initialize();
        FANo := CreateFixedAssetWithDimension();
        CreateGenJournalBatch(GenJournalBatch);
        Amount := CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, FANo, GenJournalLine."FA Posting Type"::Maintenance);
        PostingDateInGenJournalLine(GenJournalLine, LibraryFiscalYear.GetFirstPostingDate(true));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run the Date Compress Maintenance Ledger.
        RunDateCompressMaintenance(
          FANo, LibraryFiscalYear.GetFirstPostingDate(true), DateCompression.CalcMaxEndDate(), false, false, DateComprRegister."Period Length"::Month);

        // 3. Verify: Verify the Maintenance Ledger Entry.
        VerifyMaintenanceLedgerEntry(FANo, Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteEmptyFARegisters()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FARegister: Record "FA Register";
        DateComprRegister: Record "Date Compr. Register";
        DateCompression: Codeunit "Date Compression";
    begin
        // Test Delete Empty FA Registers functionality after running Date Compress FA Ledger.

        // 1. Setup: Create and post General Journal Lines with Account Type as Fixed Asset. Run Date Compress FA Ledger.
        Initialize();
        CreateAndPostGenJournalLines(GenJournalLine, GenJournalLine."FA Posting Type"::"Acquisition Cost");
        RunDateCompressFALedger(
          GenJournalLine."Account No.", LibraryFiscalYear.GetFirstPostingDate(true),
          DateCompression.CalcMaxEndDate(), DateComprRegister."Period Length"::Year);
        FindFARegister(FARegister, GenJournalLine."Journal Batch Name");

        // 2. Exercise: Run Delete Empty FA Registers Report.
        RunDeleteEmptyFARegisters(FARegister);

        // 3. Verify: FA Register must be deleted after running the Delete Empty FA Registers Report.
        Assert.IsFalse(
          FindFARegister(FARegister, GenJournalLine."Journal Batch Name"),
          StrSubstNo(FARegisterErr, GenJournalLine."Journal Batch Name"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure EmptyFARegistersMaintenance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FARegister: Record "FA Register";
        DateComprRegister: Record "Date Compr. Register";
        DateCompression: Codeunit "Date Compression";
    begin
        // Test Delete Empty FA Registers functionality after running Date Compress Maintenance.

        // 1. Setup: Create and post General Journal Lines with Account Type as Fixed Asset. Run Date Compress Maintenance.
        Initialize();
        CreateAndPostGenJournalLines(GenJournalLine, GenJournalLine."FA Posting Type"::Maintenance);
        RunDateCompressMaintenance(
          GenJournalLine."Account No.", LibraryFiscalYear.GetFirstPostingDate(true), DateCompression.CalcMaxEndDate(),
          true, true, DateComprRegister."Period Length"::Year);
        FindFARegister(FARegister, GenJournalLine."Journal Batch Name");

        // 2. Exercise: Run Delete Empty FA Registers Report.
        RunDeleteEmptyFARegisters(FARegister);

        // 3. Verify: FA Register must be deleted after running the Delete Empty FA Registers Report.
        Assert.IsFalse(
          FindFARegister(FARegister, GenJournalLine."Journal Batch Name"),
          StrSubstNo(FARegisterErr, GenJournalLine."Journal Batch Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateCompressFixedAssetLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DateComprRegister: Record "Date Compr. Register";
        DateCompression: Codeunit "Date Compression";
        LastFALedgerEntryNo: Integer;
    begin
        // Test FA Ledger Entry exist or not after run Date Compress FA Ledger.

        // 1. Setup: Create and post General Journal Lines with Account Type as Fixed Asset.
        Initialize();
        LastFALedgerEntryNo := GetLastFALedgerEntryNo();
        CreateAndPostGenJournalLines(GenJournalLine, GenJournalLine."FA Posting Type"::"Acquisition Cost");

        // 2. Exercise: Run Date Compress FA Ledger.
        RunDateCompressFALedger(
          GenJournalLine."Account No.", LibraryFiscalYear.GetFirstPostingDate(true),
          DateCompression.CalcMaxEndDate(), DateComprRegister."Period Length"::Year);

        // 3. Verify: FA Ledger Entry must exist.
        VerifyFALedgerEntryExists(LastFALedgerEntryNo, GenJournalLine."Account No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DateCompressionRejectsFASource()
    var
        SourceEntry: Record "FA Ledger Entry";
        CounterpartEntry: Record "FA Ledger Entry";
        UnlinkedEntry: Record "FA Ledger Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Compressing only the FA source book cannot orphan its counterpart
        Initialize();

        // [GIVEN] A linked FA pair and an unlinked entry
        CreateFACompressionFailureFixture(SourceEntry, CounterpartEntry, UnlinkedEntry);
        Commit();

        // [WHEN] Only the source book is selected for compression
        // [THEN] Compression fails before modifying any entries or registers
        VerifyLinkedFACompressionRejected(SourceEntry, CounterpartEntry, UnlinkedEntry, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DateCompressionRejectsFACounterpart()
    var
        SourceEntry: Record "FA Ledger Entry";
        CounterpartEntry: Record "FA Ledger Entry";
        UnlinkedEntry: Record "FA Ledger Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Compressing only the FA counterpart book cannot remove a persisted link
        Initialize();

        // [GIVEN] A linked FA pair and an unlinked entry
        CreateFACompressionFailureFixture(SourceEntry, CounterpartEntry, UnlinkedEntry);
        Commit();

        // [WHEN] Only the counterpart book is selected for compression
        // [THEN] Compression fails before modifying any entries or registers
        VerifyLinkedFACompressionRejected(SourceEntry, CounterpartEntry, UnlinkedEntry, true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DateCompressionRejectsMaintenanceSource()
    var
        SourceEntry: Record "Maintenance Ledger Entry";
        CounterpartEntry: Record "Maintenance Ledger Entry";
        UnlinkedEntry: Record "Maintenance Ledger Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Compressing only the maintenance source book cannot orphan its counterpart
        Initialize();

        // [GIVEN] A linked maintenance pair and an unlinked entry
        CreateMaintenanceCompressionFailureFixture(SourceEntry, CounterpartEntry, UnlinkedEntry);
        Commit();

        // [WHEN] Only the source book is selected for compression
        // [THEN] Compression fails before modifying any entries or registers
        VerifyLinkedMaintenanceCompressionRejected(SourceEntry, CounterpartEntry, UnlinkedEntry, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DateCompressionRejectsMaintenanceCounterpart()
    var
        SourceEntry: Record "Maintenance Ledger Entry";
        CounterpartEntry: Record "Maintenance Ledger Entry";
        UnlinkedEntry: Record "Maintenance Ledger Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Compressing only the maintenance counterpart book cannot remove a persisted link
        Initialize();

        // [GIVEN] A linked maintenance pair and an unlinked entry
        CreateMaintenanceCompressionFailureFixture(SourceEntry, CounterpartEntry, UnlinkedEntry);
        Commit();

        // [WHEN] Only the counterpart book is selected for compression
        // [THEN] Compression fails before modifying any entries or registers
        VerifyLinkedMaintenanceCompressionRejected(SourceEntry, CounterpartEntry, UnlinkedEntry, true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DateCompressionIgnoresFALinksOutsideDateFilter()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An FA pair outside the date filter does not prevent compressing unlinked history
        Initialize();

        // [GIVEN] A linked pair and an unlinked FA entry on another date
        // [WHEN] Only the unlinked entry's date is compressed
        // [THEN] Compression succeeds and the pair remains unchanged
        VerifyUnlinkedFACompression(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DateCompressionIgnoresFALinksOutsideBookFilter()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An FA pair outside the book filter does not prevent compressing unlinked history
        Initialize();

        // [GIVEN] A linked pair and an unlinked FA entry in another book
        // [WHEN] Only the unlinked entry's book is compressed
        // [THEN] Compression succeeds and the pair remains unchanged
        VerifyUnlinkedFACompression(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DateCompressionIgnoresMaintenanceLinksOutsideDateFilter()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A maintenance pair outside the date filter does not prevent compressing unlinked history
        Initialize();

        // [GIVEN] A linked pair and an unlinked maintenance entry on another date
        // [WHEN] Only the unlinked entry's date is compressed
        // [THEN] Compression succeeds and the pair remains unchanged
        VerifyUnlinkedMaintenanceCompression(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DateCompressionIgnoresMaintenanceLinksOutsideBookFilter()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A maintenance pair outside the book filter does not prevent compressing unlinked history
        Initialize();

        // [GIVEN] A linked pair and an unlinked maintenance entry in another book
        // [WHEN] Only the unlinked entry's book is compressed
        // [THEN] Compression succeeds and the pair remains unchanged
        VerifyUnlinkedMaintenanceCompression(false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryFiscalYear.CreateClosedAccountingPeriods();

        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateLocalData();
        isInitialized := true;
        Commit();
    end;

    local procedure AttachDimensionOnFixedAsset(var DimensionValue: Record "Dimension Value"; FANo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        FindDimensionValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Fixed Asset", FANo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateAndPostGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        FANo: Code[20];
    begin
        FANo := CreateFixedAssetWithDimension();
        CreateGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FANo, FAPostingType);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, FANo, FAPostingType);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; No: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroup: Code[20])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, No, DepreciationBookCode);
        UpdateDateFADepreciationBook(FADepreciationBook, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFixedAssetWithDimension(): Code[20]
    var
        DepreciationBook: Record "Depreciation Book";
        DimensionValue: Record "Dimension Value";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
    begin
        DepreciationBook.Get(LibraryFixedAsset.GetDefaultDeprBook());
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");
        UpdateFixedAsset(FixedAsset);
        AttachDimensionOnFixedAsset(DimensionValue, FixedAsset."No.");
        exit(FixedAsset."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", AccountNo, LibraryRandom.RandDec(1000, 2));
        PostingSetupFAGLJournalLine(GenJournalLine, FAPostingType);
        GenJournalLine.Validate(
          "Posting Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', LibraryFiscalYear.GetFirstPostingDate(true)));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; FAPostingType: Enum "Gen. Journal Line FA Posting Type") Amount: Decimal
    var
        Counter: Integer;
    begin
        // Use Random for creating multiple General Lines and Amount.
        for Counter := 1 to LibraryRandom.RandInt(10) do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"Fixed Asset", AccountNo, LibraryRandom.RandDec(1000, 2));
            Amount += GenJournalLine.Amount;
            PostingSetupFAGLJournalLine(GenJournalLine, FAPostingType);
        end;
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        GenJournalTemplate.SetRange(Recurring, false);

        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateAdditionalCompressionBook(FANo: Code[20]): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBook.Code);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateCompressionBooks(var FixedAsset: Record "Fixed Asset"; var SourceBook: Record "Depreciation Book"; var CounterpartBook: Record "Depreciation Book")
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(SourceBook);
        LibraryFixedAsset.CreateDepreciationBook(CounterpartBook);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", SourceBook.Code);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", CounterpartBook.Code);
    end;

    local procedure CreateFACompressionFailureFixture(var SourceEntry: Record "FA Ledger Entry"; var CounterpartEntry: Record "FA Ledger Entry"; var UnlinkedEntry: Record "FA Ledger Entry")
    begin
        CreateFACompressionPair(SourceEntry, CounterpartEntry);
        UnlinkedEntry := SourceEntry;
        UnlinkedEntry."Entry No." := UnlinkedEntry.GetLastEntryNo() + 1;
        UnlinkedEntry.Insert();
    end;

    local procedure CreateFACompressionPair(var SourceEntry: Record "FA Ledger Entry"; var CounterpartEntry: Record "FA Ledger Entry")
    var
        FixedAsset: Record "Fixed Asset";
        SourceBook: Record "Depreciation Book";
        CounterpartBook: Record "Depreciation Book";
    begin
        CreateCompressionBooks(FixedAsset, SourceBook, CounterpartBook);
        SourceEntry."Entry No." := SourceEntry.GetLastEntryNo() + 1;
        SourceEntry."FA No." := FixedAsset."No.";
        SourceEntry."Depreciation Book Code" := SourceBook.Code;
        SourceEntry."FA Posting Group" := FixedAsset."FA Posting Group";
        SourceEntry."FA Posting Type" := SourceEntry."FA Posting Type"::Depreciation;
        SourceEntry."FA Posting Date" := LibraryFiscalYear.GetFirstPostingDate(true);
        SourceEntry."Posting Date" := SourceEntry."FA Posting Date";
        SourceEntry.Amount := 100;
        SourceEntry.Insert();
        CounterpartEntry := SourceEntry;
        CounterpartEntry."Entry No." += 1;
        CounterpartEntry."Depreciation Book Code" := CounterpartBook.Code;
        CounterpartEntry."Derogatory Source Entry No." := SourceEntry."Entry No.";
        CounterpartEntry.Insert();
    end;

    local procedure CreateMaintenanceCompressionFailureFixture(var SourceEntry: Record "Maintenance Ledger Entry"; var CounterpartEntry: Record "Maintenance Ledger Entry"; var UnlinkedEntry: Record "Maintenance Ledger Entry")
    begin
        CreateMaintenanceCompressionPair(SourceEntry, CounterpartEntry);
        UnlinkedEntry := SourceEntry;
        UnlinkedEntry."Entry No." := UnlinkedEntry.GetLastEntryNo() + 1;
        UnlinkedEntry.Insert();
    end;

    local procedure CreateMaintenanceCompressionPair(var SourceEntry: Record "Maintenance Ledger Entry"; var CounterpartEntry: Record "Maintenance Ledger Entry")
    var
        FixedAsset: Record "Fixed Asset";
        SourceBook: Record "Depreciation Book";
        CounterpartBook: Record "Depreciation Book";
    begin
        CreateCompressionBooks(FixedAsset, SourceBook, CounterpartBook);
        SourceEntry."Entry No." := SourceEntry.GetLastEntryNo() + 1;
        SourceEntry."FA No." := FixedAsset."No.";
        SourceEntry."Depreciation Book Code" := SourceBook.Code;
        SourceEntry."FA Posting Group" := FixedAsset."FA Posting Group";
        SourceEntry."FA Posting Date" := LibraryFiscalYear.GetFirstPostingDate(true);
        SourceEntry."Posting Date" := SourceEntry."FA Posting Date";
        SourceEntry.Amount := 100;
        SourceEntry.Insert();
        CounterpartEntry := SourceEntry;
        CounterpartEntry."Entry No." += 1;
        CounterpartEntry."Depreciation Book Code" := CounterpartBook.Code;
        CounterpartEntry."Derogatory Source Entry No." := SourceEntry."Entry No.";
        CounterpartEntry.Insert();
    end;

    local procedure FindDimensionValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure FindFARegister(var FARegister: Record "FA Register"; JournalBatchName: Code[10]): Boolean
    begin
        FARegister.SetRange("Journal Batch Name", JournalBatchName);
        exit(FARegister.FindSet());
    end;

    local procedure GetLastFALedgerEntryNo(): Integer
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.FindLast();
        exit(FALedgerEntry."Entry No.");
    end;

    local procedure PostingDateInGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindSet();
        repeat
            GenJournalLine.Validate("Posting Date", PostingDate);
            GenJournalLine.Modify(true);
        until GenJournalLine.Next() = 0;
    end;

    local procedure PostingSetupFAGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    begin
        GenJournalLine.Validate(
          "Document No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Document No."))));
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
    end;

    local procedure RunDateCompressFALedger(FANo: Code[20]; StartingDate: Date; EndingDate: Date; PeriodLengthFrom: Option)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        DateCompressFALedger: Report "Date Compress FA Ledger";
    begin
        Clear(DateCompressFALedger);
        FALedgerEntry.SetRange("FA No.", FANo);
        DateCompressFALedger.SetTableView(FALedgerEntry);
        DateCompressFALedger.SetRetainDocumentNo(false);
        DateCompressFALedger.SetRetainIndexEntry(false);
        DateCompressFALedger.InitializeRequest(StartingDate, EndingDate, PeriodLengthFrom, FANo, '');
        DateCompressFALedger.UseRequestPage(false);
        DateCompressFALedger.Run();
    end;

    local procedure RunDateCompressMaintenance(FANo: Code[20]; StartingDate: Date; EndingDate: Date; RetainDocumentNo: Boolean; RetainIndexEntry: Boolean; PeriodLengthFrom: Option)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        DateCompressMaintLedger: Report "Date Compress Maint. Ledger";
    begin
        Clear(DateCompressMaintLedger);
        MaintenanceLedgerEntry.SetRange("FA No.", FANo);
        DateCompressMaintLedger.SetTableView(MaintenanceLedgerEntry);
        DateCompressMaintLedger.SetRetainDocumentNo(RetainDocumentNo);
        DateCompressMaintLedger.SetRetainIndexEntry(RetainIndexEntry);
        DateCompressMaintLedger.InitializeRequest(StartingDate, EndingDate, PeriodLengthFrom, FANo, '');
        DateCompressMaintLedger.UseRequestPage(false);
        DateCompressMaintLedger.Run();
    end;

    local procedure RunDeleteEmptyFARegisters(var FARegister: Record "FA Register")
    var
        DeleteEmptyFARegisters: Report "Delete Empty FA Registers";
    begin
        Clear(DeleteEmptyFARegisters);
        DeleteEmptyFARegisters.SetTableView(FARegister);
        DeleteEmptyFARegisters.UseRequestPage(false);
        DeleteEmptyFARegisters.Run();
    end;

    local procedure RunFilteredFACompression(FANo: Code[20]; BookCode: Code[10]; PostingDate: Date)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        DateComprRegister: Record "Date Compr. Register";
        DateCompressFALedger: Report "Date Compress FA Ledger";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("Depreciation Book Code", BookCode);
        DateCompressFALedger.SetTableView(FALedgerEntry);
        DateCompressFALedger.InitializeRequest(PostingDate, PostingDate, DateComprRegister."Period Length"::Day, FANo, '', false);
        DateCompressFALedger.UseRequestPage(false);
        DateCompressFALedger.Run();
    end;

    local procedure RunFilteredMaintenanceCompression(FANo: Code[20]; BookCode: Code[10]; PostingDate: Date)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        DateComprRegister: Record "Date Compr. Register";
        DateCompressMaintLedger: Report "Date Compress Maint. Ledger";
    begin
        MaintenanceLedgerEntry.SetRange("FA No.", FANo);
        MaintenanceLedgerEntry.SetRange("Depreciation Book Code", BookCode);
        DateCompressMaintLedger.SetTableView(MaintenanceLedgerEntry);
        DateCompressMaintLedger.InitializeRequest(PostingDate, PostingDate, DateComprRegister."Period Length"::Day, FANo, '', false);
        DateCompressMaintLedger.UseRequestPage(false);
        DateCompressMaintLedger.Run();
    end;

    local procedure UpdateDateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; DepreciationBookCode: Code[10])
    begin
        FADepreciationBook.Validate("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Random Number Generator for Ending date.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Modify(true);
    end;

    local procedure UpdateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        Employee: Record Employee;
        FASubclass: Record "FA Subclass";
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        LibraryFixedAsset.FindFASubclass(FASubclass);
        FixedAsset.Validate("Responsible Employee", Employee."No.");
        FixedAsset.Validate("FA Subclass Code", FASubclass.Code);
        FixedAsset.Modify(true);
    end;

    local procedure VerifyAmountInFALedgerEntry(Description: Text[50]; Amount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange(Description, Description);
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyFALedgerEntryExists(EntryNo: Integer; Description: Text[50])
    var
        FALedgerEntry: Record "FA Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        FALedgerEntry.SetFilter("Entry No.", '>=%1', EntryNo);
        FALedgerEntry.SetRange("Source Code", SourceCodeSetup."Compress FA Ledger");
        FALedgerEntry.SetRange(Description, Description);
        FALedgerEntry.FindFirst();
    end;

    local procedure VerifyMaintenanceLedgerEntry(FANo: Code[20]; Amount: Decimal)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.SetRange("FA No.", FANo);
        MaintenanceLedgerEntry.FindFirst();
        MaintenanceLedgerEntry.TestField(Description, FANo);
        MaintenanceLedgerEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyFACompressionPair(SourceEntryNo: Integer; CounterpartEntryNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.Get(SourceEntryNo);
        Assert.AreEqual(100, FALedgerEntry.Amount, 'The original source amount must be preserved.');
        Assert.AreEqual(0, FALedgerEntry."Derogatory Source Entry No.", 'The source must remain a source.');
        FALedgerEntry.Get(CounterpartEntryNo);
        Assert.AreEqual(100, FALedgerEntry.Amount, 'The original counterpart amount must be preserved.');
        Assert.AreEqual(SourceEntryNo, FALedgerEntry."Derogatory Source Entry No.", 'The persisted pair must be preserved.');
    end;

    local procedure VerifyLinkedFACompressionRejected(SourceEntry: Record "FA Ledger Entry"; CounterpartEntry: Record "FA Ledger Entry"; UnlinkedEntry: Record "FA Ledger Entry"; CompressCounterpart: Boolean)
    var
        DateComprRegister: Record "Date Compr. Register";
        FARegister: Record "FA Register";
        RegisterCount: Integer;
        FARegisterCount: Integer;
        BookCode: Code[10];
    begin
        BookCode := SourceEntry."Depreciation Book Code";
        if CompressCounterpart then
            BookCode := CounterpartEntry."Depreciation Book Code";
        RegisterCount := DateComprRegister.Count();
        FARegisterCount := FARegister.Count();

        asserterror RunFilteredFACompression(SourceEntry."FA No.", BookCode, SourceEntry."FA Posting Date");

        Assert.ExpectedError(LinkedEntryDateCompressionErr);
        Assert.ExpectedErrorCode('Dialog');
        VerifyFACompressionPair(SourceEntry."Entry No.", CounterpartEntry."Entry No.");
        UnlinkedEntry.Get(UnlinkedEntry."Entry No.");
        Assert.AreEqual(100, UnlinkedEntry.Amount, 'An unlinked entry must not be compressed before the failure.');
        Assert.AreEqual(RegisterCount, DateComprRegister.Count(), 'A rejected compression must not create a register.');
        Assert.AreEqual(FARegisterCount, FARegister.Count(), 'A rejected compression must not create an FA register.');
    end;

    local procedure VerifyLinkedMaintenanceCompressionRejected(SourceEntry: Record "Maintenance Ledger Entry"; CounterpartEntry: Record "Maintenance Ledger Entry"; UnlinkedEntry: Record "Maintenance Ledger Entry"; CompressCounterpart: Boolean)
    var
        DateComprRegister: Record "Date Compr. Register";
        FARegister: Record "FA Register";
        RegisterCount: Integer;
        FARegisterCount: Integer;
        BookCode: Code[10];
    begin
        BookCode := SourceEntry."Depreciation Book Code";
        if CompressCounterpart then
            BookCode := CounterpartEntry."Depreciation Book Code";
        RegisterCount := DateComprRegister.Count();
        FARegisterCount := FARegister.Count();

        asserterror RunFilteredMaintenanceCompression(SourceEntry."FA No.", BookCode, SourceEntry."FA Posting Date");

        Assert.ExpectedError(LinkedEntryDateCompressionErr);
        Assert.ExpectedErrorCode('Dialog');
        VerifyMaintenanceCompressionPair(SourceEntry."Entry No.", CounterpartEntry."Entry No.");
        UnlinkedEntry.Get(UnlinkedEntry."Entry No.");
        Assert.AreEqual(100, UnlinkedEntry.Amount, 'An unlinked entry must not be compressed before the failure.');
        Assert.AreEqual(RegisterCount, DateComprRegister.Count(), 'A rejected compression must not create a register.');
        Assert.AreEqual(FARegisterCount, FARegister.Count(), 'A rejected compression must not create an FA register.');
    end;

    local procedure VerifyMaintenanceCompressionPair(SourceEntryNo: Integer; CounterpartEntryNo: Integer)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.Get(SourceEntryNo);
        Assert.AreEqual(100, MaintenanceLedgerEntry.Amount, 'The original source amount must be preserved.');
        Assert.AreEqual(0, MaintenanceLedgerEntry."Derogatory Source Entry No.", 'The source must remain a source.');
        MaintenanceLedgerEntry.Get(CounterpartEntryNo);
        Assert.AreEqual(100, MaintenanceLedgerEntry.Amount, 'The original counterpart amount must be preserved.');
        Assert.AreEqual(SourceEntryNo, MaintenanceLedgerEntry."Derogatory Source Entry No.", 'The persisted pair must be preserved.');
    end;

    local procedure VerifyUnlinkedFACompression(UseDifferentDate: Boolean)
    var
        SourceEntry: Record "FA Ledger Entry";
        CounterpartEntry: Record "FA Ledger Entry";
        UnlinkedEntry: Record "FA Ledger Entry";
        CompressedEntry: Record "FA Ledger Entry";
    begin
        CreateFACompressionPair(SourceEntry, CounterpartEntry);
        UnlinkedEntry := SourceEntry;
        UnlinkedEntry."Entry No." := UnlinkedEntry.GetLastEntryNo() + 1;
        if UseDifferentDate then
            UnlinkedEntry."FA Posting Date" += 1
        else
            UnlinkedEntry."Depreciation Book Code" := CreateAdditionalCompressionBook(SourceEntry."FA No.");
        UnlinkedEntry."Posting Date" := UnlinkedEntry."FA Posting Date";
        UnlinkedEntry.Insert();

        RunFilteredFACompression(UnlinkedEntry."FA No.", UnlinkedEntry."Depreciation Book Code", UnlinkedEntry."FA Posting Date");

        VerifyFACompressionPair(SourceEntry."Entry No.", CounterpartEntry."Entry No.");
        Assert.IsFalse(CompressedEntry.Get(UnlinkedEntry."Entry No."), 'The selected unlinked entry must be compressed.');
        CompressedEntry.SetRange("FA No.", UnlinkedEntry."FA No.");
        CompressedEntry.SetRange("Depreciation Book Code", UnlinkedEntry."Depreciation Book Code");
        CompressedEntry.SetRange("FA Posting Date", UnlinkedEntry."FA Posting Date");
        Assert.AreEqual(1, CompressedEntry.Count(), 'Compression must leave one summary.');
        CompressedEntry.FindFirst();
        Assert.AreEqual(100, CompressedEntry.Amount, 'Compression must preserve the selected amount.');
        Assert.AreEqual(0, CompressedEntry."Derogatory Source Entry No.", 'An unlinked summary must remain unlinked.');
    end;

    local procedure VerifyUnlinkedMaintenanceCompression(UseDifferentDate: Boolean)
    var
        SourceEntry: Record "Maintenance Ledger Entry";
        CounterpartEntry: Record "Maintenance Ledger Entry";
        UnlinkedEntry: Record "Maintenance Ledger Entry";
        CompressedEntry: Record "Maintenance Ledger Entry";
    begin
        CreateMaintenanceCompressionPair(SourceEntry, CounterpartEntry);
        UnlinkedEntry := SourceEntry;
        UnlinkedEntry."Entry No." := UnlinkedEntry.GetLastEntryNo() + 1;
        if UseDifferentDate then
            UnlinkedEntry."FA Posting Date" += 1
        else
            UnlinkedEntry."Depreciation Book Code" := CreateAdditionalCompressionBook(SourceEntry."FA No.");
        UnlinkedEntry."Posting Date" := UnlinkedEntry."FA Posting Date";
        UnlinkedEntry.Insert();

        RunFilteredMaintenanceCompression(UnlinkedEntry."FA No.", UnlinkedEntry."Depreciation Book Code", UnlinkedEntry."FA Posting Date");

        VerifyMaintenanceCompressionPair(SourceEntry."Entry No.", CounterpartEntry."Entry No.");
        Assert.IsFalse(CompressedEntry.Get(UnlinkedEntry."Entry No."), 'The selected unlinked entry must be compressed.');
        CompressedEntry.SetRange("FA No.", UnlinkedEntry."FA No.");
        CompressedEntry.SetRange("Depreciation Book Code", UnlinkedEntry."Depreciation Book Code");
        CompressedEntry.SetRange("FA Posting Date", UnlinkedEntry."FA Posting Date");
        Assert.AreEqual(1, CompressedEntry.Count(), 'Compression must leave one summary.');
        CompressedEntry.FindFirst();
        Assert.AreEqual(100, CompressedEntry.Amount, 'Compression must preserve the selected amount.');
        Assert.AreEqual(0, CompressedEntry."Derogatory Source Entry No.", 'An unlinked summary must remain unlinked.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
