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

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; No: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroup: Code[20])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, No, DepreciationBookCode);
        UpdateDateFADepreciationBook(FADepreciationBook, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Modify(true);
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

