codeunit 142067 "UT REPORTS GENERAL"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        CountryFilterTxt: Label '%1: %2';
        LastUsedTxt: Label 'Last used options and filters';
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('CurrencyListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCurrencyList()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Purpose of the test is to validate Currency - OnAfterGetRecord trigger of Report ID - 10308.
        // Setup: Create Currency and Currency Exchange Rate.
        Initialize();
        CreateCurrencyAndExchangeRate(CurrencyExchangeRate);

        // Exercise.
        REPORT.Run(REPORT::"Currency List");  // Opens CurrencyListRequestPageHandler.

        // Verify: Verify Currency Code after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Currency_Code', CurrencyExchangeRate."Currency Code");
        LibraryReportDataset.AssertElementWithValueExists(
          'CurrExchRate__Exchange_Rate_Amount_', CurrencyExchangeRate."Exchange Rate Amount");
    end;

    [Test]
    [HandlerFunctions('LanguageListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLanguageList()
    var
        LanguageCode: Code[10];
    begin
        // Purpose of the test is to validate Language - OnAfterGetRecord trigger of Report ID - 10310.
        // Setup: Create Language.
        Initialize();
        LanguageCode := CreateLanguage();

        // Exercise.
        REPORT.Run(REPORT::"Language List");  // Opens LanguageListRequestPageHandler.

        // Verify: Verify Windows Language Name of Language after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Language_Code', LanguageCode);
    end;

    [Test]
    [HandlerFunctions('ReasonCodeListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportReasonCodeList()
    var
        ReasonCode: Record "Reason Code";
        "Code": Code[10];
    begin
        // Purpose of the test is to validate Reason Code - OnPreReport trigger of Report ID - 10312.
        // Setup: Create Reason Code.
        Initialize();
        Code := CreateReasonCode();

        // Exercise.
        REPORT.Run(REPORT::"Reason Code List");  // Opens ReasonCodeListRequestPageHandler.

        // Verify: Verify Filters on Reason Code is updated on Report Reason Code List.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          'ReasonFilter', StrSubstNo('%1: %2', ReasonCode.FieldCaption(Code), Code));
    end;

    [Test]
    [HandlerFunctions('CountryRegionListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportCountryRegionList()
    var
        CountryRegion: Record "Country/Region";
    begin
        // Purpose of the test is to validate OnPreReport trigger of Report ID - 10307 Country/Region List.
        // Setup.
        Initialize();
        CreateCountryRegion(CountryRegion);

        // Exercise.
        REPORT.Run(REPORT::"Country/Region List");  // Opens handler - CountryRegionListRequestPageHandler.

        // Verify: Verify Country Region Code and Name on Report - Country/Region List.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CountryFilter', StrSubstNo(CountryFilterTxt, CountryRegion.FieldCaption(Code), CountryRegion.Code));
        LibraryReportDataset.AssertElementWithValueExists('Country_Region_Code', CountryRegion.Code);
        LibraryReportDataset.AssertElementWithValueExists('Country_Region_Name', CountryRegion.Name);
    end;

    [Test]
    [HandlerFunctions('GLRegisterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure GLRegisterSavedSettings()
    var
        ObjectOptions: Record "Object Options";
    begin
        // [FEATURE] [G/L Register] [UT]
        // [SCENARIO 331052] Settings of the "G/L Register" report are saved after its run.
        Initialize();
        Assert.IsFalse(
          ObjectOptions.Get(LastUsedTxt, REPORT::"G/L Register", ObjectOptions."Object Type"::Report, UserId, CompanyName), '');

        // [WHEN] Run "G/L Register" report.
        REPORT.Run(REPORT::"G/L Register");

        // [THEN] Object options with report parameters were not created for "G/L Register" report.
        Assert.IsFalse(
          ObjectOptions.Get(LastUsedTxt, REPORT::"G/L Register", ObjectOptions."Object Type"::Report, UserId, CompanyName), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardStatementAddedToReportSelectionsOnCompanyInit()
    var
        ReportSelections: Record "Report Selections";
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        // [FEATURE] [Report Selection] [UT]
        // [SCENARIO 314076] A line with Report ID 1316 "Standard Statement" is added to Report Selections for Usage "Customer Statement" when "Company-Initialize" runs.
        Initialize();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"C.Statement");
        ReportSelections.DeleteAll();

        // [WHEN] Run InitReportUsage function of "Report Selection Mgt." codeunit for Usage "C.Statement".
        ReportSelectionMgt.InitReportSelection(ReportSelections.Usage::"C.Statement");

        // [THEN] A line with Report ID 1316 was added to Report Selections for Usage "Customer Statement".
        ReportSelections.SetRange("Report ID", REPORT::"Standard Statement");
        Assert.RecordIsNotEmpty(ReportSelections);
    end;

    [Test]
    [HandlerFunctions('CustomerStatementsCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RunCustomerStatementsReportSelections()
    var
        ReportSelections: Record "Report Selections";
    begin
        // [FEATURE] [Report Selection] [UT]
        // [SCENARIO 314076] Run report 153 "Customer Statement" in case Report Selections for "C.Statement" contains the only line with Report 10072 "Customer Statements".
        Initialize();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"C.Statement");
        ReportSelections.DeleteAll();

        // [GIVEN] A line with the report 10072 "Customer Statements" in the Report Selection for Usage "Customer Statement".
        InsertReportSelections(ReportSelections.Usage::"C.Statement", '1', REPORT::"Customer Statements");

        // [WHEN] Run report 153 "Customer Statement".
        REPORT.Run(REPORT::"Customer Statement");

        // [THEN] Report 10072 "Customer Statements" is run.
    end;

    [Test]
    [HandlerFunctions('TrialBalanceDetailSummaryPrintDetailRequestPageHandler')]
    procedure RunTrialBalanceDetailSummaryReportGLEntriesWithDimensionsSortedByPostingDate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension1Value: array[2] of Record "Dimension Value";
        Dimension2Value: array[2] of Record "Dimension Value";
        GlobalDim1Code: Code[20];
        GlobalDim2Code: Code[20];
        GLAccountNo: Code[20];
        PostedDocNo: array[4] of Code[20];
    begin
        // [FEATURE] [Trial Balance] [Dimensions]
        //[SCENARIO 395883] Run "Trial Balance Detail/Summary" for G/L Account when G/L Entries' sorting order by Dimensions 1/2 is different from sorting order by Posting Date.
        Initialize();
        GeneralLedgerSetup.Get();
        GlobalDim1Code := GeneralLedgerSetup."Global Dimension 1 Code";
        GlobalDim2Code := GeneralLedgerSetup."Global Dimension 2 Code";

        // [GIVEN] Two dimension values "A1" and "A2" of Global Dimension 1. Two dimension values "B1" and "B2" of Global Dimension 2.
        LibraryDimension.CreateDimensionValueWithCode(Dimension1Value[1], LibraryUtility.GenerateGUID(), GlobalDim1Code);
        LibraryDimension.CreateDimensionValueWithCode(Dimension1Value[2], LibraryUtility.GenerateGUID(), GlobalDim1Code);
        LibraryDimension.CreateDimensionValueWithCode(Dimension2Value[1], LibraryUtility.GenerateGUID(), GlobalDim2Code);
        LibraryDimension.CreateDimensionValueWithCode(Dimension2Value[2], LibraryUtility.GenerateGUID(), GlobalDim2Code);

        // [GIVEN] Four G/L Entries "G1", "G2", "G3", "G4" with dimensions combinations "A1" "B1", "A1" "B2", "A2" "B1", "A2" "B2" and with Posting Dates 20.01, 15.01, 10.01, 05.01 accordingly.
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        PostedDocNo[1] := CreateAndPostGenJnlLineWithDimensions(GLAccountNo, Dimension1Value[1].Code, Dimension2Value[1].Code, WorkDate() + 20);
        PostedDocNo[2] := CreateAndPostGenJnlLineWithDimensions(GLAccountNo, Dimension1Value[1].Code, Dimension2Value[2].Code, WorkDate() + 15);
        PostedDocNo[3] := CreateAndPostGenJnlLineWithDimensions(GLAccountNo, Dimension1Value[2].Code, Dimension2Value[1].Code, WorkDate() + 10);
        PostedDocNo[4] := CreateAndPostGenJnlLineWithDimensions(GLAccountNo, Dimension1Value[2].Code, Dimension2Value[2].Code, WorkDate() + 5);

        // [WHEN] Run report "Trial Balance Detail/Summary".
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate() + 20);
        Report.Run(Report::"Trial Balance Detail/Summary");

        // [THEN] Lines for G/L Entries in the report results are sorted by Posting Date, i.e. in this order "G4", "G3", "G2", "G1".
        LibraryXPathXMLReader.Initialize(LibraryVariableStorage.DequeueText(), '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('/DataSet/Result/G_L_Entry__Document_No__', PostedDocNo[4], 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('/DataSet/Result/G_L_Entry__Document_No__', PostedDocNo[3], 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('/DataSet/Result/G_L_Entry__Document_No__', PostedDocNo[2], 2);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('/DataSet/Result/G_L_Entry__Document_No__', PostedDocNo[1], 3);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TrialBalanceDetailSummaryPrintDetailRequestPageHandler')]
    procedure RunTrialBalanceDetailSummaryReportGLEntriesNoDimensionsSortedByPostingDate()
    var
        GLAccountNo: Code[20];
        PostedDocNo: array[4] of Code[20];
    begin
        // [FEATURE] [Trial Balance]
        //[SCENARIO 395883] Run "Trial Balance Detail/Summary" for G/L Account when G/L Entries' dimensions are not set and G/L Entries are created with descending Posting Date.
        Initialize();

        // [GIVEN] Four G/L Entries "G1", "G2", "G3", "G4" with empty Shortcut Dimension 1/2 codes and with Posting Dates 20.01, 15.01, 10.01, 05.01 accordingly.
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        PostedDocNo[1] := CreateAndPostGenJnlLineWithDimensions(GLAccountNo, '', '', WorkDate() + 20);
        PostedDocNo[2] := CreateAndPostGenJnlLineWithDimensions(GLAccountNo, '', '', WorkDate() + 15);
        PostedDocNo[3] := CreateAndPostGenJnlLineWithDimensions(GLAccountNo, '', '', WorkDate() + 10);
        PostedDocNo[4] := CreateAndPostGenJnlLineWithDimensions(GLAccountNo, '', '', WorkDate() + 5);

        // [WHEN] Run report "Trial Balance Detail/Summary".
        LibraryVariableStorage.Enqueue(GLAccountNo);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate() + 20);
        Report.Run(Report::"Trial Balance Detail/Summary");

        // [THEN] Lines for G/L Entries in the report results are sorted by Posting Date, i.e. in this order "G4", "G3", "G2", "G1".
        LibraryXPathXMLReader.Initialize(LibraryVariableStorage.DequeueText(), '');
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('/DataSet/Result/G_L_Entry__Document_No__', PostedDocNo[4], 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('/DataSet/Result/G_L_Entry__Document_No__', PostedDocNo[3], 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('/DataSet/Result/G_L_Entry__Document_No__', PostedDocNo[2], 2);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('/DataSet/Result/G_L_Entry__Document_No__', PostedDocNo[1], 3);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCountryRegion(var CountryRegion: Record "Country/Region")
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10();
        CountryRegion.Name := LibraryUTUtility.GetNewCode();
        CountryRegion.Insert();
        LibraryVariableStorage.Enqueue(CountryRegion.Code);  // Enqueue required inside CountryRegionListRequestPageHandler.
    end;

    local procedure CreateCurrencyAndExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        CurrencyExchangeRate."Currency Code" := Currency.Code;
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate.Insert();

        // Enqueue required inside CurrencyListRequestPageHandler.
        LibraryVariableStorage.Enqueue(Currency.Code);
    end;

    local procedure CreateLanguage(): Code[10]
    var
        Language: Record Language;
    begin
        Language.Code := LibraryUTUtility.GetNewCode10();
        Language.Insert();

        // Enqueue required for LanguageListRequestPageHandler.
        LibraryVariableStorage.Enqueue(Language.Code);
        exit(Language.Code);
    end;

    local procedure CreateReasonCode(): Code[10]
    var
        ReasonCode: Record "Reason Code";
    begin
        ReasonCode.Code := LibraryUTUtility.GetNewCode10();
        ReasonCode.Insert();

        // Enqueue required for ReasonCodeListRequestPageHandler.
        LibraryVariableStorage.Enqueue(ReasonCode.Code);
        exit(ReasonCode.Code);
    end;

    local procedure CreateAndPostGenJnlLineWithDimensions(GLAccountNo: Code[20]; Dimension1ValueCode: Code[20]; Dimension2ValueCode: Code[20]; PostingDate: Date): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentType: Enum "Gen. Journal Document Type";
        AccountType: Enum "Gen. Journal Account Type";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType::Invoice, AccountType::"G/L Account",
            GLAccountNo, AccountType::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(100, 200, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Shortcut Dimension 1 Code", Dimension1ValueCode);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", Dimension2ValueCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure InsertReportSelections(ReportUsage: Enum "Report Selection Usage"; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Init();
        ReportSelections.Usage := ReportUsage;
        ReportSelections.Sequence := Sequence;
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CurrencyListRequestPageHandler(var CurrencyList: TestRequestPage "Currency List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        CurrencyList.Currency.SetFilter(Code, Code);
        CurrencyList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LanguageListRequestPageHandler(var LanguageList: TestRequestPage "Language List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        LanguageList.LanguageDataItem.SetFilter(Code, Code);
        LanguageList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReasonCodeListRequestPageHandler(var ReasonCodeList: TestRequestPage "Reason Code List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        ReasonCodeList."Reason Code".SetFilter(Code, Code);
        ReasonCodeList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CountryRegionListRequestPageHandler(var CountryRegionList: TestRequestPage "Country/Region List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        CountryRegionList."Country/Region".SetFilter(Code, Code);
        CountryRegionList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLRegisterRequestPageHandler(var GLRegister: TestRequestPage "G/L Register")
    begin
        GLRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerStatementsCancelRequestPageHandler(var CustomerStatements: TestRequestPage "Customer Statements")
    begin
        CustomerStatements.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure TrialBalanceDetailSummaryPrintDetailRequestPageHandler(var TrialBalanceDetailSummary: TestRequestPage "Trial Balance Detail/Summary")
    var
        FileName: Text;
        GLAccountNo: Text;
        FromDate: Date;
        ToDate: Date;
    begin
        GLAccountNo := LibraryVariableStorage.DequeueText();
        FromDate := LibraryVariableStorage.DequeueDate();
        ToDate := LibraryVariableStorage.DequeueDate();
        FileName := LibraryReportDataset.GetFileName();
        LibraryVariableStorage.Enqueue(FileName);
        TrialBalanceDetailSummary.PrintTransactionDetail.SetValue(true);
        TrialBalanceDetailSummary."G/L Account".SetFilter("No.", GLAccountNo);
        TrialBalanceDetailSummary."G/L Account".SetFilter("Date Filter", StrSubstNo('%1..%2', FromDate, ToDate));
        TrialBalanceDetailSummary.SaveAsXml(LibraryReportDataset.GetParametersFileName(), FileName);
    end;
}

