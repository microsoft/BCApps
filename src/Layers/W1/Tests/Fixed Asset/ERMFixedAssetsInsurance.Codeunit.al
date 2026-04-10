codeunit 134452 "ERM Fixed Assets Insurance"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [Insurance]
        isInitialized := false;
    end;

    var
        Insurance2: Record Insurance;
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        RecordExistError: Label '%1 %2 must not exist.';
        CommentLineExistError: Label '%1 for %2 = %3, %4 = %5 must not exist.';
        InsuranceAmountError: Label '%1 must be equal.';
        StartingDate: Date;
        EndingDate: Date;
        EndingDateError: Label 'You must specify an ending date.';
        Amount: Decimal;
        FANo: Code[20];
        RoundingFactorOption: Label 'None';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Fixed Assets Insurance");
        Clear(Amount);
        Clear(FANo);
        // Use global variables for Request Page Handler.
        StartingDate := 0D;
        EndingDate := 0D;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets Insurance");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Fixed Assets Insurance");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsuranceJournalDifferentBatch()
    var
        Insurance: Record Insurance;
        FixedAsset: Record "Fixed Asset";
        InsuranceJournalTemplate: Record "Insurance Journal Template";
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        Amount: array[2] of Decimal;
    begin
        // Test that Insurance Journal Posted successfully with different batch jobs.

        // 1. Setup: Create Insurance and fixed asset.
        Initialize();
        LibraryFixedAsset.CreateInsurance(Insurance);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        // 2. Exercise: Create Insurance Journal Batch and Post Insurance Journal.
        InsuranceJournalTemplate.FindFirst();
        LibraryFixedAsset.CreateInsuranceJournalBatch(InsuranceJournalBatch, InsuranceJournalTemplate.Name);
        Amount[1] := CreatePostInsuranceJournalLine(InsuranceJournalBatch, FixedAsset."No.", Insurance."No.");

        InsuranceJournalBatch.Get(InsuranceJournalBatch."Journal Template Name", InsuranceJournalBatch.Name);
        Amount[2] := CreatePostInsuranceJournalLine(InsuranceJournalBatch, FixedAsset."No.", Insurance."No.");

        // 3. Verification: To verify Insurance number, Document type and Amount are posted properly.
        VerifyCoverageLedgerEntry(FixedAsset."No.", Amount, Insurance."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationOfInsurance()
    var
        Insurance: Record Insurance;
    begin
        // Test Creation of Insurance.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Create Insurance.
        LibraryFixedAsset.CreateInsurance(Insurance);

        // 3. Verify: Verify Insurance successfully created.
        Insurance.Get(Insurance."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdationOfInsurance()
    var
        Insurance: Record Insurance;
        AnnualPremium: Decimal;
    begin
        // Test Annual Premium Amount successfully updated on Insurance.

        // 1. Setup: Create Insurance.
        Initialize();
        LibraryFixedAsset.CreateInsurance(Insurance);

        // 2. Exercise: Update Annual Premium on Insurance.
        AnnualPremium := LibraryRandom.RandDec(1000, 2);  // Use Random because value is not important.
        Insurance.Validate("Annual Premium", AnnualPremium);
        Insurance.Modify(true);

        // 3. Verify: Verify Annual Premium Amount successfully updated on Insurance.
        Insurance.Get(Insurance."No.");
        Insurance.TestField("Annual Premium", AnnualPremium);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentCreationForInsurance()
    var
        Insurance: Record Insurance;
        Comment: Text[80];
    begin
        // Test Comment creation for Insurance.

        // 1. Setup: Create Insurance.
        Initialize();
        LibraryFixedAsset.CreateInsurance(Insurance);

        // 2. Exercise: Create Comment for Insurance.
        Comment := CreateCommentForInsurance(Insurance."No.");

        // 3. Verify: Verify created comment.
        VerifyCommentForInsurance(Insurance."No.", Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentDeletionForInsurance()
    var
        Insurance: Record Insurance;
        CommentLine: Record "Comment Line";
    begin
        // Test Comment Deletion for Insurance.

        // 1. Setup: Create Insurance and Comment for It.
        Initialize();
        LibraryFixedAsset.CreateInsurance(Insurance);
        LibraryFixedAsset.CreateCommentLine(CommentLine, CommentLine."Table Name"::Insurance, Insurance."No.");

        // 2. Exercise: Delete Comment.
        CommentLine.Delete(true);

        // 3. Verify: Verify Comment successfully deleted.
        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Insurance);
        CommentLine.SetRange("No.", Insurance."No.");
        Assert.IsFalse(
          CommentLine.FindFirst(),
          StrSubstNo(
            CommentLineExistError, CommentLine.TableCaption(), CommentLine.FieldCaption("No."), CommentLine."No.",
            CommentLine.FieldCaption("Line No."), CommentLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionForInsurance()
    var
        Insurance: Record Insurance;
        DimensionValue: Record "Dimension Value";
    begin
        // Test Default Dimension Creation for Insurance.

        // 1. Setup: Create Insurance.
        Initialize();
        LibraryFixedAsset.CreateInsurance(Insurance);

        // 2. Exercise: Create Default Dimension for Insurance.
        CreateDefaultDimension(DimensionValue, Insurance."No.");

        // 3. Verify: Verify Default Dimension for Insurance.
        VerifyDefaultDimension(DimensionValue, Insurance."No.");
    end;

    [Test]
    [HandlerFunctions('InsuranceStatisticsPageHadler')]
    [Scope('OnPrem')]
    procedure InsuranceStatistics()
    var
        Insurance: Record Insurance;
        InsuranceStatistics: Page "Insurance Statistics";
    begin
        // Test Annual Premium and Policy Coverage on Insurance Statistics page.

        // 1. Setup: Create Insurance with Annual Premium and Policy Coverage.
        Initialize();
        LibraryFixedAsset.CreateInsurance(Insurance);
        ModifyAmountsOnInsurance(Insurance);

        // 2. Exercise: Run Insurance Statistics.
        Clear(InsuranceStatistics);
        InsuranceStatistics.SetRecord(Insurance);
        InsuranceStatistics.Run();

        // 3. Verify: Verify Annual Premium and Policy Coverage on Insurance Statistics page.
        Insurance2.TestField("Annual Premium", Insurance."Annual Premium");
        Insurance2.TestField("Policy Coverage", Insurance."Policy Coverage");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletionOfInsurance()
    var
        Insurance: Record Insurance;
    begin
        // Test deletion of Insurance.

        // 1. Setup: Create Insurance.
        Initialize();
        LibraryFixedAsset.CreateInsurance(Insurance);

        // 2. Exercise: Delete Insurance.
        Insurance.Delete(true);

        // 3. Verify: Verify Insurance successfully deleted.
        Assert.IsFalse(Insurance.Get(Insurance."No."), StrSubstNo(RecordExistError, Insurance.TableCaption(), Insurance."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndexInsurance()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        Insurance: Record Insurance;
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        Amount: Decimal;
        IndexFigure: Integer;
    begin
        // Test the Generates correct entry in Insurance Journal after executing the Index Insurance.

        // 1. Setup: Create Fixed Asset,Create Insurance ,FA Posting Group, FA Depreciation Book,Create and Post Purchase Invoice and
        // Create Insurance Journal Batch and Post Insurance Journal.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateJournalSetupDepreciation(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);
        IndexationAndIntegrationInBook(FADepreciationBook."Depreciation Book Code");
        CreateAndPostPurchaseInvoice(FixedAsset."No.", FADepreciationBook."Depreciation Book Code");
        LibraryFixedAsset.CreateInsurance(Insurance);
        CreateInsuranceJournalBatch(InsuranceJournalBatch);
        Amount := CreatePostInsuranceJournalLine(InsuranceJournalBatch, FixedAsset."No.", Insurance."No.");

        // 2. Exercise: Run Index Insurance.
        IndexFigure := RunIndexInsurance(FixedAsset."No.");

        // 3. Verify: Verify the Insurance Journal entries Created for Insurance with correct Amount.
        VerifyInsuranceEntry(FixedAsset."No.", Insurance."No.", Amount, IndexFigure);
    end;

    [Test]
    [HandlerFunctions('CompressInsuranceLedgerHandler')]
    [Scope('OnPrem')]
    procedure DateCompressInsuranceLedgerDatesError()
    begin
        // Test error occurs on Running Date Compress Insurance Ledger Report without Starting and Ending Dates.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Run Date Compress Insurance Ledger Report without Starting and Ending Dates.
        asserterror RunDateCompressInsuranceLedger();

        // 3. Verify: Verify error occurs on Running Date Compress Insurance Ledger Report without Starting and Ending Dates.
        Assert.ExpectedError(EndingDateError);
    end;

    [Test]
    [HandlerFunctions('CompressInsuranceLedgerHandler,DimensionSelectionHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DateCompressInsuranceLedgerBatch()
    var
        InsuranceRegister: Record "Insurance Register";
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
        DateCompression: Codeunit "Date Compression";
        JournalBatchName: Code[10];
    begin
        // Test and verify Date Compress Insurance Ledger Report functionality.

        // 1. Setup: Create and post Insurance Journal.
        Initialize();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        JournalBatchName := CreateAndPostInsuranceJournal();
        FindInsuranceRegister(InsuranceRegister, JournalBatchName);
        Commit();

        // 2. Exercise: Run Date Compress Insurance Ledger Report with Starting and Ending Dates.
        StartingDate := LibraryFiscalYear.GetFirstPostingDate(true);
        EndingDate := DateCompression.CalcMaxEndDate();
        RunDateCompressInsuranceLedger();

        // 3. Verify: Ins. Coverage Ledger Entries must be deleted after running the Date Compress Insurance Ledger Report.
        Assert.AreEqual(
          0, GetNumberCoverageLedgerEntries(InsuranceRegister."From Entry No.", InsuranceRegister."To Entry No."),
          StrSubstNo(
            CommentLineExistError, InsCoverageLedgerEntry.TableCaption(), InsuranceRegister.FieldCaption("From Entry No."),
            InsuranceRegister."From Entry No.",
            InsuranceRegister.FieldCaption("To Entry No."), InsuranceRegister."To Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalValueInsuredWithFixedAsset()
    var
        Insurance: Record Insurance;
        FixedAsset: Record "Fixed Asset";
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        FixedAssetCard: TestPage "Fixed Asset Card";
        TotalValueInsured: TestPage "Total Value Insured";
        TotalInsuredAmount: Decimal;
    begin
        // Check Total Value on Total Value Insured Page through Fixed Asset after Posting Insurance Journal.

        // Setup: Create Insurance,Fixed Asset and Post Insurance Journal Line.
        Initialize();
        LibraryFixedAsset.CreateInsurance(Insurance);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateInsuranceJournalBatch(InsuranceJournalBatch);
        TotalInsuredAmount := CreatePostInsuranceJournalLine(InsuranceJournalBatch, FixedAsset."No.", Insurance."No.");

        // Exercise: Open Total Value Insured Page through Fixed Asset.
        FixedAssetCard.OpenEdit();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        TotalValueInsured.Trap();
        FixedAssetCard."Total Value Ins&ured".Invoke();

        // Verify: Check Total Value on Total Value Insured Page after Posting Insurance Journal.
        Assert.AreEqual(
          TotalInsuredAmount, TotalValueInsured.TotalValue."Total Value Insured".AsDecimal(),
          StrSubstNo(InsuranceAmountError, TotalValueInsured.TotalValue."Total Value Insured".Caption));
    end;

    [Test]
    [HandlerFunctions('FAPostingTypesOvervMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure FAPostingTypesOverviewMatrixRoundingNone()
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FAPostingTypesOverview: TestPage "FA Posting Types Overview";
    begin
        // Check FA Posting Types Overview Matrix Page for Posted Values through Fixed Asset page with Rounding Option None.

        // Setup: Create Setup for Fixed Asset.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        // Exercise: Create and Post FA Journal Line and Assign Fixed Asset No. in Global Variable.
        Amount := LibraryRandom.RandDec(100, 2);
        CreateAndPostFAJournalLine(FixedAsset."No.", DepreciationBook.Code, Amount);
        FANo := FixedAsset."No.";

        // Verify: Verify FA Posting Types Overview Matrix Page for Posted FA Value in FAPostingTypesOvervMatrixPageHandler.
        FixedAssetCard.OpenView();
        FixedAssetCard.FILTER.SetFilter("No.", FixedAsset."No.");
        FAPostingTypesOverview.Trap();
        FixedAssetCard."FA Posting Types Overview".Invoke();
        FAPostingTypesOverview.RoundingFactor.SetValue(RoundingFactorOption);
        FAPostingTypesOverview.ShowMatrix.Invoke();
    end;

    [Test]
    [HandlerFunctions('FAPostingTypesOvervMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure FAPostingTypesOverviewRounding1()
    begin
        // Check FA Posting Types Overview Matrix Page for Posted Values through Fixed Asset page with Rounding Option 1;
        Initialize();
        FAPostingTypesOverviewWithRoundingFactor(1);
    end;

    [Test]
    [HandlerFunctions('FAPostingTypesOvervMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure FAPostingTypesOverviewRounding1000()
    begin
        // Check FA Posting Types Overview Matrix Page for Posted Values through Fixed Asset page with Rounding Option 1000;
        Initialize();
        FAPostingTypesOverviewWithRoundingFactor(1000);
    end;

    [Test]
    [HandlerFunctions('FAPostingTypesOvervMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure FAPostingTypesOverviewRounding1000000()
    begin
        // Check FA Posting Types Overview Matrix Page for Posted Values through Fixed Asset page with Rounding Option 1000000;
        Initialize();
        FAPostingTypesOverviewWithRoundingFactor(1000000);
    end;

    local procedure FAPostingTypesOverviewWithRoundingFactor(RoundingFactor: Integer)
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FixedAssetCard: TestPage "Fixed Asset Card";
        FAPostingTypesOverview: TestPage "FA Posting Types Overview";
    begin
        // Setup: Create Setup for Fixed Asset.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", FixedAsset."FA Posting Group", DepreciationBook.Code);

        // Exercise: Create and Post FA Journal Line with Random Values. Assign Fixed Asset No. and Rounding Amount in Global Variable.
        Amount := Round((LibraryRandom.RandDec(100, 2) * 10000) / RoundingFactor, 1);
        CreateAndPostFAJournalLine(FixedAsset."No.", DepreciationBook.Code, Amount);
        FANo := FixedAsset."No.";

        // Verify: Verify FA Posting Types Overview Matrix Page with Rounding Factor through FAPostingTypesOvervMatrixPageHandler.
        FixedAssetCard.OpenView();
        FixedAssetCard.FILTER.SetFilter("No.", FANo);
        FAPostingTypesOverview.Trap();
        FixedAssetCard."FA Posting Types Overview".Invoke();
        FAPostingTypesOverview.RoundingFactor.SetValue(RoundingFactor);
        FAPostingTypesOverview.ShowMatrix.Invoke();
    end;

    local procedure CreateAndPostFAJournalLine(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; GenLineAmount: Decimal)
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalLine: Record "FA Journal Line";
        NoSeries: Codeunit "No. Series";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Take Random Values for Different fields.
        SelectFAJournalBatch(FAJournalBatch);
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document No.", NoSeries.PeekNextNo(FAJournalBatch."No. Series"));
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA No.", FixedAssetNo);
        FAJournalLine.Validate(Amount, GenLineAmount);
        FAJournalLine.Validate("FA Posting Type", FAJournalLine."FA Posting Type"::"Acquisition Cost");
        FAJournalLine.Modify(true);
        LibraryERM.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateAndPostInsuranceJournal() JournalBatchName: Code[10]
    var
        Insurance: Record Insurance;
        FixedAsset: Record "Fixed Asset";
        InsuranceJournalBatch: Record "Insurance Journal Batch";
        InsuranceJournalLine: Record "Insurance Journal Line";
    begin
        LibraryFixedAsset.CreateInsurance(Insurance);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);

        CreateInsuranceJournalBatch(InsuranceJournalBatch);
        JournalBatchName := InsuranceJournalBatch.Name;

        CreateInsuranceJournalLine(
          InsuranceJournalLine, InsuranceJournalBatch, FixedAsset."No.", Insurance."No.", LibraryFiscalYear.GetFirstPostingDate(true));
        CreateInsuranceJournalLine(
          InsuranceJournalLine, InsuranceJournalBatch, FixedAsset."No.", Insurance."No.", LibraryFiscalYear.GetFirstPostingDate(true));
        LibraryFixedAsset.PostInsuranceJournal(InsuranceJournalLine);
        LibraryUtility.GenerateGUID();  // Hack to fix problem with Generate GUID.
    end;

    local procedure CreateAndPostPurchaseInvoice(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, FixedAssetNo, DepreciationBookCode);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure CreateCommentForInsurance(InsuranceNo: Code[20]): Text[80]
    var
        CommentLine: Record "Comment Line";
    begin
        LibraryFixedAsset.CreateCommentLine(CommentLine, CommentLine."Table Name"::Insurance, InsuranceNo);
        CommentLine.Validate(
          Comment,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CommentLine.FieldNo(Comment), DATABASE::"Comment Line"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Comment Line", CommentLine.FieldNo(Comment))));
        CommentLine.Modify(true);
        exit(CommentLine.Comment);
    end;

    local procedure CreateDefaultDimension(var DimensionValue: Record "Dimension Value"; InsuranceNo: Code[20])
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Insurance, InsuranceNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FANo: Code[20]; FAPostingGroupCode: Code[20]; DepreciationBookCode: Code[10])
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroupCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Depreciation Ending Date greater than Depreciation Starting Date, Using the Random Number for the Year.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateInsuranceJournalBatch(var InsuranceJournalBatch: Record "Insurance Journal Batch")
    var
        InsuranceJournalTemplate: Record "Insurance Journal Template";
    begin
        InsuranceJournalTemplate.FindFirst();
        LibraryFixedAsset.CreateInsuranceJournalBatch(InsuranceJournalBatch, InsuranceJournalTemplate.Name);
    end;

    local procedure CreateInsuranceJournalLine(var InsuranceJournalLine: Record "Insurance Journal Line"; InsuranceJournalBatch: Record "Insurance Journal Batch"; FANo: Code[20]; InsuranceNo: Code[20]; PostingDate: Date)
    begin
        LibraryFixedAsset.CreateInsuranceJournalLine(
          InsuranceJournalLine, InsuranceJournalBatch."Journal Template Name", InsuranceJournalBatch.Name);
        InsuranceJournalLine.Validate("Posting Date", PostingDate);
        InsuranceJournalLine.Validate("Document Type", InsuranceJournalLine."Document Type"::Invoice);
        InsuranceJournalLine.Validate("Document No.", FANo); // Inputting FA No. as Document No is not important.
        InsuranceJournalLine.Validate("Insurance No.", InsuranceNo);
        InsuranceJournalLine.Validate("FA No.", FANo);
        InsuranceJournalLine.Validate(Amount, LibraryRandom.RandDec(100, 2));  // Use Random because value is not important.
        InsuranceJournalLine.Modify(true);
    end;

    local procedure CreateJournalSetupDepreciation(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure CreatePostInsuranceJournalLine(InsuranceJournalBatch: Record "Insurance Journal Batch"; FixedAssetNo: Code[20]; InsuranceNo: Code[20]) Amount: Decimal
    var
        InsuranceJournalLine: Record "Insurance Journal Line";
    begin
        CreateInsuranceJournalLine(InsuranceJournalLine, InsuranceJournalBatch, FixedAssetNo, InsuranceNo, WorkDate());
        Amount := InsuranceJournalLine.Amount;
        LibraryFixedAsset.PostInsuranceJournal(InsuranceJournalLine);
        LibraryUtility.GenerateGUID();  // Hack to fix problem with Generate GUID.
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetRange("Currency Code", '');
        FindVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // Using Random Code Generator for Vendor Invoice No.
        PurchaseHeader.Validate(
          "Vendor Invoice No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Invoice No."))));
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; FANo: Code[20]; DepreciationBookCode: Code[10])
    var
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // Using the Random Number Generator for Quantity and Amount.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FANo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Depreciation Book Code", DepreciationBookCode);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure FindInsuranceRegister(var InsuranceRegister: Record "Insurance Register"; JournalBatchName: Code[10])
    begin
        InsuranceRegister.SetRange("Journal Batch Name", JournalBatchName);
        InsuranceRegister.FindFirst();
    end;

    local procedure GetNumberCoverageLedgerEntries(FromEntryNo: Integer; ToEntryNo: Integer): Integer
    var
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
    begin
        InsCoverageLedgerEntry.SetRange("Entry No.", FromEntryNo, ToEntryNo);
        exit(InsCoverageLedgerEntry.Count);
    end;

    local procedure IndexationAndIntegrationInBook(DepreciationBookCode: Code[10])
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Write-Down", true);
        DepreciationBook.Validate("G/L Integration - Appreciation", true);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("Allow Indexation", true);
        DepreciationBook.Validate("G/L Integration - Custom 1", true);
        DepreciationBook.Validate("G/L Integration - Custom 2", true);
        DepreciationBook.Validate("G/L Integration - Maintenance", true);
        DepreciationBook.Validate("Use Same FA+G/L Posting Dates", true);
        DepreciationBook.Modify(true);
    end;

    local procedure ModifyAmountsOnInsurance(var Insurance: Record Insurance)
    begin
        // Use Random for Annual Premium and Policy Coverage because values are not important.
        Insurance.Validate("Annual Premium", LibraryRandom.RandDec(10000, 2));
        Insurance.Validate("Policy Coverage", LibraryRandom.RandDec(10000, 2));
        Insurance.Modify(true);
    end;

    local procedure RunIndexInsurance(No: Code[20]) IndexFigure: Integer
    var
        FixedAsset: Record "Fixed Asset";
        IndexInsurance: Report "Index Insurance";
    begin
        Clear(IndexInsurance);
        FixedAsset.SetRange("No.", No);
        IndexInsurance.SetTableView(FixedAsset);

        // Using the Random Number Generator for New Index Figure.
        IndexFigure := LibraryRandom.RandInt(10);
        IndexInsurance.InitializeRequest(No, No, WorkDate(), IndexFigure);
        IndexInsurance.UseRequestPage(false);
        IndexInsurance.Run();
    end;

    local procedure RunDateCompressInsuranceLedger()
    var
        DateCompressInsuranceLedger: Report "Date Compress Insurance Ledger";
    begin
        Clear(DateCompressInsuranceLedger);
        DateCompressInsuranceLedger.Run();
    end;

    local procedure SelectFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalLine: Record "FA Journal Line";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        // Delete All FA General Line with Selected Batch.
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        FAJournalTemplate.SetRange(Recurring, false);
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.FindFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", NoSeries.Code);
        FAJournalBatch.Modify(true);
        FAJournalLine.SetRange("Journal Template Name", FAJournalBatch."Journal Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatch.Name);
        FAJournalLine.DeleteAll(true);
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
    begin
        FAJournalSetup2.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook());
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure VerifyCommentForInsurance(InsuranceNo: Code[20]; Comment: Text[80])
    var
        CommentLine: Record "Comment Line";
    begin
        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Insurance);
        CommentLine.SetRange("No.", InsuranceNo);
        CommentLine.FindFirst();
        CommentLine.TestField(Comment, Comment);
    end;

    local procedure VerifyCoverageLedgerEntry(FANo: Code[20]; Amount: array[2] of Decimal; InsuranceNo: Code[20])
    var
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
        "Count": Integer;
    begin
        InsCoverageLedgerEntry.SetRange("FA No.", FANo);
        InsCoverageLedgerEntry.FindSet();
        Count := 1;
        repeat
            InsCoverageLedgerEntry.TestField("Insurance No.", InsuranceNo);
            InsCoverageLedgerEntry.TestField("Document Type", InsCoverageLedgerEntry."Document Type"::Invoice);
            InsCoverageLedgerEntry.TestField(Amount, Amount[Count]);
            Count += 1;
        until InsCoverageLedgerEntry.Next() = 0;
    end;

    local procedure VerifyDefaultDimension(DimensionValue: Record "Dimension Value"; InsuranceNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Insurance, InsuranceNo);
        DefaultDimension.TestField("Dimension Code", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure VerifyInsuranceEntry(FANo: Code[20]; InsuranceNo: Code[20]; Amount: Decimal; IndexFigure: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        InsuranceJournalLine: Record "Insurance Journal Line";
        InsuranceJournalLineAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        InsuranceJournalLine.SetRange("FA No.", FANo);
        InsuranceJournalLine.SetRange("Insurance No.", InsuranceNo);
        InsuranceJournalLine.FindFirst();
        InsuranceJournalLineAmount := Amount - (Amount * IndexFigure / 100);
        Assert.AreNearlyEqual(
          -InsuranceJournalLineAmount, InsuranceJournalLine.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(InsuranceAmountError, InsuranceJournalLine.FieldCaption(Amount)));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure InsuranceStatisticsPageHadler(var InsuranceStatistics: Page "Insurance Statistics")
    begin
        Insurance2.Init();

        // Assign Global Variable.
        InsuranceStatistics.GetRecord(Insurance2);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CompressInsuranceLedgerHandler(var DateCompressInsuranceLedger: TestRequestPage "Date Compress Insurance Ledger")
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        DateCompressInsuranceLedger.StartingDate.SetValue(StartingDate);
        DateCompressInsuranceLedger.EndingDate.SetValue(EndingDate);
        DateCompressInsuranceLedger.PeriodLength.SetValue(DateComprRegister."Period Length"::Year);
        DateCompressInsuranceLedger.OnlyIndexEntries.SetValue(false);
        DateCompressInsuranceLedger.DocumentNo.SetValue(false);
        DateCompressInsuranceLedger.RetainDimensions.AssistEdit();
        DateCompressInsuranceLedger.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectionHandler(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        // Set Dimension Selection Multiple for all the rows.
        DimensionSelectionMultiple.First();
        repeat
            DimensionSelectionMultiple.Selected.SetValue(true);
        until not DimensionSelectionMultiple.Next();
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FAPostingTypesOvervMatrixPageHandler(var FAPostingTypesOvervMatrix: TestPage "FA Posting Types Overv. Matrix")
    begin
        FAPostingTypesOvervMatrix.FILTER.SetFilter("FA No.", FANo);
        if Amount = 0 then
            FAPostingTypesOvervMatrix.Field1.AssertEquals('')
        else
            FAPostingTypesOvervMatrix.Field1.AssertEquals(Amount);
    end;

    local procedure FindVendor(var Vendor: Record Vendor)
    begin
        // Filter Vendor so that errors are not generated due to mandatory fields.
        Vendor.SetFilter("Vendor Posting Group", '<>''''');
        Vendor.SetFilter("Gen. Bus. Posting Group", '<>''''');
        Vendor.SetRange(Blocked, Vendor.Blocked::" ");
        Vendor.FindFirst();
    end;
}

