codeunit 134980 "ERM Insurance Reports"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [Insurance]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        isInitialized: Boolean;
        OverUnderInsuredCaption: Label 'Over-/Underinsured';
        ValidationError: Label '%1 must be %2 ';
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2', Comment = '%1=Field Caption;%2=Field Value';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Insurance Reports");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Insurance Reports");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Insurance Reports");
    end;

    [Test]
    [HandlerFunctions('InsuranceUninsuredFAsReqPageHandler')]
    [Scope('OnPrem')]
    procedure InsuranceUninsuredFixedAsset()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        GenJournalBatch: Record "Gen. Journal Batch";
        InsuranceUninsuredFAs: Report "Insurance - Uninsured FAs";
    begin
        // Test and verify Insurance Uninsured Fixed Asset Report.

        // 1.Setup: Create Two Fixed Asset, Two Fixed Asset Depreciation Book, General Journal Batch,
        // Two Fixed Asset Journal Lines and Post.
        Initialize();
        CreateTwoFixedAssets(FixedAsset, FixedAsset2, FADepreciationBook, FADepreciationBook2);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateFAGLJournalLines(GenJournalLine, FADepreciationBook, GenJournalBatch);
        CreateFAGLJournalLines(GenJournalLine, FADepreciationBook2, GenJournalBatch);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Run the Report.
        LibraryLowerPermissions.SetO365FAView();
        LibraryLowerPermissions.AddJournalsEdit();
        FixedAsset.SetFilter("No.", '%1|%2', FixedAsset."No.", FixedAsset2."No.");
        Clear(InsuranceUninsuredFAs);
        InsuranceUninsuredFAs.SetTableView(FixedAsset);
        Commit();
        InsuranceUninsuredFAs.Run();

        // 3.Verify: Verify values on Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyFixedAssetLineValues(FADepreciationBook);
        VerifyFixedAssetLineValues(FADepreciationBook2);
        VerifyTotalAmount(FADepreciationBook, FADepreciationBook2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('InsuranceAnalysisReqPageHandler')]
    [Scope('OnPrem')]
    procedure InsuranceAnalysisPrintDetails()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Insurance: Record Insurance;
        Insurance2: Record Insurance;
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        InsuranceAnalysis: Report "Insurance - Analysis";
    begin
        // Test and verify Insurance Analysis Report with Print Details.

        // 1.Setup: Create Two Fixed Asset, Two Fixed Asset Depreciation Book, Two Insurance,
        // General Journal Batch, Two Fixed Asset Journal Lines with Insurance and Post.
        Initialize();
        CreateTwoFixedAssets(FixedAsset, FixedAsset2, FADepreciationBook, FADepreciationBook2);
        CreateInsurance(Insurance);
        CreateInsurance(Insurance2);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateJournalLineWithInsurance(GenJournalLine, GenJournalBatch, FADepreciationBook, Insurance."No.");
        CreateJournalLineWithInsurance(GenJournalLine, GenJournalBatch, FADepreciationBook2, Insurance2."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Run the Report.
        LibraryLowerPermissions.SetO365FAView();
        LibraryLowerPermissions.AddJournalsEdit();
        Insurance.SetFilter("No.", '%1|%2', Insurance."No.", Insurance2."No.");
        Clear(InsuranceAnalysis);
        InsuranceAnalysis.InitializeRequest(true);
        InsuranceAnalysis.SetTableView(Insurance);
        Commit();
        InsuranceAnalysis.Run();

        // 3.Verify: Verify values on Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInsuranceAnalysisLine(Insurance);
        VerifyInsuranceAnalysisLine(Insurance2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('InsuranceAnalysisReqPageHandler')]
    [Scope('OnPrem')]
    procedure InsuranceAnalysis()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Insurance: Record Insurance;
        Insurance2: Record Insurance;
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        InsuranceAnalysis: Report "Insurance - Analysis";
    begin
        // Test and verify Insurance Analysis Report without Print Details.

        // 1.Setup: Create Two Fixed Asset, Two Fixed Asset Depreciation Book, Two Insurance,
        // General Journal Batch, Two Fixed Asset Journal Lines with Insurance and Post.
        Initialize();
        CreateTwoFixedAssets(FixedAsset, FixedAsset2, FADepreciationBook, FADepreciationBook2);
        CreateInsurance(Insurance);
        CreateInsurance(Insurance2);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateJournalLineWithInsurance(GenJournalLine, GenJournalBatch, FADepreciationBook, Insurance."No.");
        CreateJournalLineWithInsurance(GenJournalLine, GenJournalBatch, FADepreciationBook2, Insurance2."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Run the Report.
        LibraryLowerPermissions.SetJournalsEdit();
        LibraryLowerPermissions.AddO365FAView();
        Insurance.SetFilter("No.", '%1|%2', Insurance."No.", Insurance2."No.");
        Clear(InsuranceAnalysis);
        InsuranceAnalysis.InitializeRequest(false);
        InsuranceAnalysis.SetTableView(Insurance);
        Commit();
        InsuranceAnalysis.Run();

        // 3.Verify: Verify values on Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInsuranceAnalysisTotal(Insurance, Insurance2);
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('InsuranceListReqPageHandler')]
    [Scope('OnPrem')]
    procedure InsuranceList()
    var
        Insurance: Record Insurance;
        InsuranceList: Report "Insurance - List";
    begin
        // Test and verify Insurance List Report.

        // 1.Setup: Create Insurance.
        Initialize();
        CreateInsurance(Insurance);

        // 2.Exercise: Run the Report.
        LibraryLowerPermissions.SetO365FAView();
        LibraryLowerPermissions.AddJournalsEdit();
        Insurance.SetRange("No.", Insurance."No.");
        Clear(InsuranceList);
        InsuranceList.SetTableView(Insurance);
        Commit();
        InsuranceList.Run();

        // 3.Verify: Verify values on Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInsuranceList(Insurance);
    end;

    [Test]
    [HandlerFunctions('InsuranceRegisterReqPageHandler')]
    [Scope('OnPrem')]
    procedure InsuranceRegister()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBook2: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Insurance: Record Insurance;
        InsuranceRegister2: Record "Insurance Register";
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        InsuranceRegister: Report "Insurance Register";
    begin
        // Test and verify Insurance Register Report.

        // 1.Setup: Create Two Fixed Asset, Two Fixed Asset Depreciation Book, Insurance, General Journal Batch,
        // Two Fixed Asset Journal Lines with Insurance and Post.
        Initialize();
        CreateTwoFixedAssets(FixedAsset, FixedAsset2, FADepreciationBook, FADepreciationBook2);
        CreateInsurance(Insurance);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateJournalLineWithInsurance(GenJournalLine, GenJournalBatch, FADepreciationBook, Insurance."No.");
        CreateJournalLineWithInsurance(GenJournalLine, GenJournalBatch, FADepreciationBook2, Insurance."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Run the Report.
        LibraryLowerPermissions.SetO365FAView();
        LibraryLowerPermissions.AddJournalsEdit();
        InsuranceRegister2.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Clear(InsuranceRegister);
        InsuranceRegister.SetTableView(InsuranceRegister2);
        Commit();
        InsuranceRegister.Run();

        // 3.Verify: Verify values on Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInsuranceRegisterLine(FixedAsset."No.");
        VerifyInsuranceRegisterLine(FixedAsset2."No.");
        LibraryFixedAsset.VerifyLastFARegisterGLRegisterOneToOneRelation(); // TFS 376879
    end;

    [Test]
    [HandlerFunctions('InsuranceCoverageDetailsReqPageHandler')]
    [Scope('OnPrem')]
    procedure InsuranceCoverageDetails()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Insurance: Record Insurance;
        FixedAsset: Record "Fixed Asset";
        InsuranceCoverageDetails: Report "Insurance - Coverage Details";
    begin
        // Test and verify Insurance Coverage Details Report.

        // 1.Setup: Create Fixed Asset, Fixed Asset Depreciation Book, Insurance, General Journal Batch,
        // Fixed Asset Journal Lines and Post.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateInsurance(Insurance);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateJournalLineWithInsurance(GenJournalLine, GenJournalBatch, FADepreciationBook, Insurance."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Run the Report.
        LibraryLowerPermissions.SetO365FAView();
        LibraryLowerPermissions.AddJournalsEdit();
        Insurance.SetRange("No.", Insurance."No.");
        Clear(InsuranceCoverageDetails);
        InsuranceCoverageDetails.SetTableView(Insurance);
        Commit();
        InsuranceCoverageDetails.Run();

        // 3.Verify: Verify values on Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInsuranceCoverageDetails(Insurance);
    end;

    [Test]
    [HandlerFunctions('InsuranceTotValueInsuredReqPageHandler')]
    [Scope('OnPrem')]
    procedure InsuranceTotalValueInsured()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Insurance: Record Insurance;
        FixedAsset: Record "Fixed Asset";
        InsuranceTotValueInsured: Report "Insurance - Tot. Value Insured";
    begin
        // Test and verify Insurance Total Value Insured Report.

        // 1.Setup: Create Fixed Asset, Fixed Asset Depreciation Book, Insurance, General Journal Batch,
        // Fixed Asset Journal Lines and Post.
        Initialize();
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateInsurance(Insurance);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateJournalLineWithInsurance(GenJournalLine, GenJournalBatch, FADepreciationBook, Insurance."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2.Exercise: Run the Report.
        LibraryLowerPermissions.SetJournalsEdit();
        LibraryLowerPermissions.AddO365FAView();
        FixedAsset.SetRange("No.", FixedAsset."No.");
        Clear(InsuranceTotValueInsured);
        InsuranceTotValueInsured.SetTableView(FixedAsset);
        Commit();
        InsuranceTotValueInsured.Run();

        // 3.Verify: Verify values on Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInsuranceValueInsured(FixedAsset."No.");
    end;

    [Normal]
    local procedure CreateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book"; FixedAsset: Record "Fixed Asset")
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", LibraryFixedAsset.GetDefaultDeprBook());
        UpdateDateFADepreciationBook(FADepreciationBook);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Modify(true);
    end;

    [Normal]
    local procedure CreateFAGLJournalLines(var GenJournalLine: Record "Gen. Journal Line"; FADepreciationBook: Record "FA Depreciation Book"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Using Random Number Generator for Amount.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(1000, 2));

        // Using Random Number Generator for Amount.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, FADepreciationBook, GenJournalLine."FA Posting Type"::Depreciation,
          -GenJournalLine.Amount / 2);
    end;

    [Normal]
    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Assets);
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    [Normal]
    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; FADepreciationBook: Record "FA Depreciation Book"; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", FADepreciationBook."FA No.", Amount);
        DepreciationBookGeneralJournal(GenJournalLine, FADepreciationBook."Depreciation Book Code");
        PostingSetupFAGLJournalLine(GenJournalLine, FAPostingType);
    end;

    local procedure CreateInsurance(var Insurance: Record Insurance)
    begin
        LibraryFixedAsset.CreateInsurance(Insurance);
        UpdateValuesOnInsurance(Insurance);
    end;

    [Normal]
    local procedure CreateJournalLineWithInsurance(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; FADepreciationBook: Record "FA Depreciation Book"; InsuranceNo: Code[20])
    begin
        // Using Random Number Generator for Amount.
        CreateGeneralJournalLine(
          GenJournalLine,
          GenJournalBatch,
          FADepreciationBook,
          GenJournalLine."FA Posting Type"::"Acquisition Cost",
          LibraryRandom.RandDec(1000, 2));

        GenJournalLine.Validate("Insurance No.", InsuranceNo);
        GenJournalLine.Modify(true);
    end;

    [Normal]
    local procedure DepreciationBookGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; DepreciationBookCode: Code[10])
    begin
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Modify(true);
    end;

    [Normal]
    local procedure PostingSetupFAGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FAPostingType: Enum "Gen. Journal Line FA Posting Type")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetFilter("Gen. Posting Type", '<>%1', GLAccount."Gen. Posting Type"::" ");
        LibraryERM.FindGLAccount(GLAccount);
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    [Normal]
    local procedure UpdateDateFADepreciationBook(var FADepreciationBook: Record "FA Depreciation Book")
    begin
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Random Number Generator for Ending date.
        FADepreciationBook.Validate("Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
    end;

    local procedure UpdateValuesOnInsurance(var Insurance: Record Insurance)
    begin
        Insurance.Validate("Effective Date", WorkDate());

        // Using Random Number Generator for Annual Premium and Policy Coverage.
        Insurance.Validate("Annual Premium", LibraryRandom.RandDec(10000, 2));
        Insurance.Validate("Policy Coverage", LibraryRandom.RandDec(10000, 2));
        Insurance.Modify(true);
    end;

    local procedure VerifyFixedAssetLineValues(FADepreciationBook: Record "FA Depreciation Book")
    begin
        FADepreciationBook.CalcFields("Acquisition Cost", Depreciation, "Book Value");
        LibraryReportDataset.SetRange('No_FixedAsset', FADepreciationBook."FA No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_FixedAsset', FADepreciationBook."FA No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Amounts1', FADepreciationBook."Acquisition Cost");
        LibraryReportDataset.AssertCurrentRowValueEquals('Amounts2', FADepreciationBook.Depreciation);
        LibraryReportDataset.AssertCurrentRowValueEquals('Amounts3', FADepreciationBook."Book Value");
    end;

    local procedure VerifyInsuranceAnalysisLine(Insurance: Record Insurance)
    begin
        Insurance.CalcFields("Total Value Insured");
        LibraryReportDataset.SetRange('Insurance__No__', Insurance."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Insurance__No__', Insurance."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Insurance__Annual_Premium_', Insurance."Annual Premium");
        LibraryReportDataset.AssertCurrentRowValueEquals('Insurance__Policy_Coverage_', Insurance."Policy Coverage");
        LibraryReportDataset.AssertCurrentRowValueEquals('Insurance__Total_Value_Insured_', Insurance."Total Value Insured");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'OverUnderInsured', Insurance."Policy Coverage" - Insurance."Total Value Insured");
    end;

    local procedure VerifyInsuranceAnalysisTotal(Insurance: Record Insurance; Insurance2: Record Insurance)
    var
        AnnualPremium: Decimal;
        PolicyCoverage: Decimal;
        TotalValueInsured: Decimal;
        OverUnderInsured: Decimal;
    begin
        Insurance.CalcFields("Total Value Insured");
        Insurance2.CalcFields("Total Value Insured");
        AnnualPremium := LibraryReportDataset.Sum('Insurance__Annual_Premium_');
        PolicyCoverage := LibraryReportDataset.Sum('Insurance__Policy_Coverage_');
        TotalValueInsured := LibraryReportDataset.Sum('Insurance__Total_Value_Insured_');
        OverUnderInsured := LibraryReportDataset.Sum('OverUnderInsured');
        Assert.AreEqual(
          Insurance."Annual Premium" + Insurance2."Annual Premium",
          AnnualPremium,
          StrSubstNo(ValidationError, Insurance.FieldCaption("Annual Premium"), AnnualPremium));
        Assert.AreEqual(
          Insurance."Policy Coverage" + Insurance2."Policy Coverage",
          PolicyCoverage,
          StrSubstNo(ValidationError, Insurance.FieldCaption("Policy Coverage"), PolicyCoverage));
        Assert.AreEqual(
          Insurance."Total Value Insured" + Insurance2."Total Value Insured",
          TotalValueInsured,
          StrSubstNo(ValidationError, Insurance.FieldCaption("Total Value Insured"), TotalValueInsured));
        Assert.AreEqual(
          Insurance."Policy Coverage" -
          Insurance."Total Value Insured" + Insurance2."Policy Coverage" - Insurance2."Total Value Insured",
          OverUnderInsured,
          StrSubstNo(ValidationError, OverUnderInsuredCaption, OverUnderInsured));
    end;

    local procedure VerifyInsuranceCoverageDetails(Insurance: Record Insurance)
    var
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
    begin
        InsCoverageLedgerEntry.SetRange("Insurance No.", Insurance."No.");
        InsCoverageLedgerEntry.FindFirst();
        LibraryReportDataset.SetRange('Ins__Coverage_Ledger_Entry__Posting_Date_', Format(InsCoverageLedgerEntry."Posting Date"));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Ins__Coverage_Ledger_Entry__Posting_Date_', Format(InsCoverageLedgerEntry."Posting Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('Insurance__No__', Insurance."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Ins__Coverage_Ledger_Entry_Amount', InsCoverageLedgerEntry.Amount);
    end;

    local procedure VerifyInsuranceList(Insurance: Record Insurance)
    begin
        LibraryReportDataset.SetRange('Insurance__No__', Insurance."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Insurance__No__', Insurance."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Insurance__Annual_Premium_', Insurance."Annual Premium");
        LibraryReportDataset.AssertCurrentRowValueEquals('Insurance__Policy_Coverage_', Insurance."Policy Coverage");
    end;

    local procedure VerifyInsuranceRegisterLine(FANo: Code[20])
    var
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
    begin
        InsCoverageLedgerEntry.SetRange("FA No.", FANo);
        InsCoverageLedgerEntry.FindFirst();
        LibraryReportDataset.SetRange('Ins__Coverage_Ledger_Entry__FA_No__', FANo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Ins__Coverage_Ledger_Entry__FA_No__', FANo);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Ins__Coverage_Ledger_Entry__Insurance_No__', InsCoverageLedgerEntry."Insurance No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Ins__Coverage_Ledger_Entry_Amount', InsCoverageLedgerEntry.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('Ins__Coverage_Ledger_Entry__Entry_No__', InsCoverageLedgerEntry."Entry No.");
    end;

    local procedure VerifyInsuranceValueInsured(FANo: Code[20])
    var
        InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
    begin
        InsCoverageLedgerEntry.SetRange("FA No.", FANo);
        InsCoverageLedgerEntry.FindFirst();
        LibraryReportDataset.SetRange('FANo', FANo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'FANo', FANo);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'Ins__Coverage_Ledger_Entry__Insurance_No__', InsCoverageLedgerEntry."Insurance No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Insurance__Total_Value_Insured_', InsCoverageLedgerEntry.Amount);
    end;

    local procedure VerifyTotalAmount(FADepreciationBook: Record "FA Depreciation Book"; FADepreciationBook2: Record "FA Depreciation Book")
    begin
        FADepreciationBook.CalcFields("Acquisition Cost", Depreciation, "Book Value");
        FADepreciationBook2.CalcFields("Acquisition Cost", Depreciation, "Book Value");
        LibraryReportDataset.SetRange('No_FixedAsset', FADepreciationBook2."FA No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_FixedAsset', FADepreciationBook2."FA No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalAmounts1',
          FADepreciationBook."Acquisition Cost" + FADepreciationBook2."Acquisition Cost");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'TotalAmounts2', FADepreciationBook.Depreciation + FADepreciationBook2.Depreciation);
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'TotalAmounts3', FADepreciationBook."Book Value" + FADepreciationBook2."Book Value");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InsuranceUninsuredFAsReqPageHandler(var InsuranceUninsuredFAs: TestRequestPage "Insurance - Uninsured FAs")
    begin
        InsuranceUninsuredFAs.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InsuranceAnalysisReqPageHandler(var InsuranceAnalysis: TestRequestPage "Insurance - Analysis")
    begin
        InsuranceAnalysis.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InsuranceListReqPageHandler(var InsuranceList: TestRequestPage "Insurance - List")
    begin
        InsuranceList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InsuranceRegisterReqPageHandler(var InsuranceRegister: TestRequestPage "Insurance Register")
    begin
        InsuranceRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InsuranceCoverageDetailsReqPageHandler(var InsuranceCoverageDetails: TestRequestPage "Insurance - Coverage Details")
    begin
        InsuranceCoverageDetails.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InsuranceTotValueInsuredReqPageHandler(var InsuranceTotValueInsured: TestRequestPage "Insurance - Tot. Value Insured")
    begin
        InsuranceTotValueInsured.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure CreateTwoFixedAssets(var FixedAsset: Record "Fixed Asset"; var FixedAsset2: Record "Fixed Asset"; var FADepreciationBook: Record "FA Depreciation Book"; var FADepreciationBook2: Record "FA Depreciation Book")
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset2);
        CreateFADepreciationBook(FADepreciationBook, FixedAsset);
        CreateFADepreciationBook(FADepreciationBook2, FixedAsset2);
    end;
}

