codeunit 134989 "ERM Cash Flow - Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryCFHelper: Codeunit "Library - Cash Flow Helper";
        LibraryCF: Codeunit "Library - Cash Flow";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryService: Codeunit "Library - Service";
        IsInitialized: Boolean;
        DocumentNoFilterText: Text[250];
        EmptyDateFormula: DateFormula;
        SourceType: Option " ",Receivables,Payables,"Liquid Funds","Cash Flow Manual Expense","Cash Flow Manual Revenue","Sales Order","Purchase Order","Fixed Assets Budget","Fixed Assets Disposal","Service Orders","G/L Budget";
        CFForecastNo: Code[20];

    [Test]
    [HandlerFunctions('RHCashFlowDateList')]
    [Scope('OnPrem')]
    procedure AllSourcesOnePeriodDateList()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        CFManualRevenue: Record "Cash Flow Manual Revenue";
        CFManualExpense2: Record "Cash Flow Manual Expense";
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        IntervalLength: DateFormula;
        TotalAmount: Decimal;
        CustomDateFormula: DateFormula;
        DeprecStartDateFormula: DateFormula;
        DeprecEndDateFormula: DateFormula;
        ConsiderSource: array[16] of Boolean;
        SourceTypeValues: array[16] of Decimal;
    begin
        // Setup
        Initialize();
        LibraryCFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CreateDocumentsOnDate('<0D>', SalesHeader, PurchHeader, SourceTypeValues[10], CustomDateFormula);
        SourceTypeValues[1] := CreateCustLedgEntry(SalesHeader);
        SourceTypeValues[2] := CreateVendLedgEntry(PurchHeader);
        LibraryCFHelper.CreateManualRevenue(CFManualRevenue);
        AppendDocumentNoToFilter(CFManualRevenue.Code);
        LibraryCFHelper.CreateManualPayment(CFManualExpense2);
        AppendDocumentNoToFilter(CFManualExpense2.Code);
        // Investment in FA source
        SourceTypeValues[8] := LibraryRandom.RandDec(1000, 2);
        LibraryCFHelper.CreateFixedAssetForInvestment(
          FixedAsset, LibraryFixedAsset.GetDefaultDeprBook(), CustomDateFormula, SourceTypeValues[8]);
        AppendDocumentNoToFilter(FixedAsset."No.");
        // Disposal of FA source
        SourceTypeValues[9] := LibraryRandom.RandDec(1000, 2);
        Evaluate(DeprecStartDateFormula, '<-2Y>');
        Evaluate(DeprecEndDateFormula, '<-1D>');
        LibraryCFHelper.CreateFixedAssetForDisposal(
          FixedAsset2, LibraryFixedAsset.GetDefaultDeprBook(), DeprecStartDateFormula,
          DeprecEndDateFormula, CustomDateFormula, SourceTypeValues[9]);
        AppendDocumentNoToFilter(FixedAsset2."No.");
        SourceTypeValues[6] := GetSalesAmountIncVAT(SalesHeader);
        SourceTypeValues[7] := GetPurchaseAmountIncVAT(PurchHeader);
        TotalAmount :=
          CashFlowForecast.CalcSourceTypeAmount("Cash Flow Source Type"::"Liquid Funds") +
          SourceTypeValues[6] + SourceTypeValues[10] - SourceTypeValues[7] + SourceTypeValues[1] +
          SourceTypeValues[2] + CFManualRevenue.Amount - CFManualExpense2.Amount - SourceTypeValues[8] + SourceTypeValues[9];

        for SourceType := 1 to ArrayLen(ConsiderSource) do
            ConsiderSource[SourceType] := true;

        LibraryApplicationArea.EnableFoundationSetup();

        ConsiderSource[SourceType::"Liquid Funds"] := false;
        ConsiderSource[SourceType::"G/L Budget"] := false;
        FillAndPostCFJournal(ConsiderSource, CashFlowForecast."No.", DocumentNoFilterText, WorkDate());

        // Exercise
        Evaluate(IntervalLength, '<1D>');
        RunAndExportCFDateListReport(WorkDate(), 1, IntervalLength, CashFlowForecast."No."); // include just 1 day (workdate)

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        VerifyExpDateListSourceLine(SourceTypeValues, CFManualRevenue.Amount, -CFManualExpense2.Amount, TotalAmount,
          'FORMAT_DateFrom_', WorkDate());
    end;

    [Test]
    [HandlerFunctions('RHCashFlowDateList')]
    [Scope('OnPrem')]
    procedure PartialSrcMultPeriodDateList()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        IntervalLength: DateFormula;
        TotalAmountPeriod1: Decimal;
        TotalAmountPeriod2: Decimal;
        CustomDateFormula: DateFormula;
        ConsiderSource: array[16] of Boolean;
        SourceTypeValues: array[16] of Decimal;
    begin
        // Setup
        Initialize();
        LibraryCFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CreateDocumentsOnDate('<1D>', SalesHeader, PurchHeader, SourceTypeValues[10], CustomDateFormula);
        SourceTypeValues[1] := CreateCustLedgEntry(SalesHeader);
        SourceTypeValues[2] := CreateVendLedgEntry(PurchHeader);
        LibraryApplicationArea.EnableFoundationSetup();

        TotalAmountPeriod1 :=
          CashFlowForecast.CalcSourceTypeAmount("Cash Flow Source Type"::"Liquid Funds") + SourceTypeValues[1] + SourceTypeValues[2];
        TotalAmountPeriod2 :=
          TotalAmountPeriod1 + GetSalesAmountIncVAT(SalesHeader) + SourceTypeValues[10] - GetPurchaseAmountIncVAT(PurchHeader);
        ConsiderSalesPurchSources(ConsiderSource);
        FillAndPostCFJournal(ConsiderSource, CashFlowForecast."No.", DocumentNoFilterText, WorkDate());

        // Exercise
        Evaluate(IntervalLength, '<1D>');
        RunAndExportCFDateListReport(WorkDate(), 2, IntervalLength, CashFlowForecast."No."); // include just 1 day (workdate)

        // Verify

        LibraryReportDataset.LoadDataSetFile();
        VerifyTotalAmount(TotalAmountPeriod1, 'FORMAT_DateFrom_', WorkDate());
        VerifyTotalAmount(TotalAmountPeriod2, 'FORMAT_DateFrom_', CalcDate(CustomDateFormula, WorkDate()));
    end;

    [Test]
    [HandlerFunctions('RHCashFlowDateList')]
    [Scope('OnPrem')]
    procedure BeforeAndAfterDateList()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        PurchHeader2: Record "Purchase Header";
        IntervalLength: DateFormula;
        TotalAmountBefore: Decimal;
        TotalAmountPeriod: Decimal;
        TotalAmountAfter: Decimal;
        CustomDateFormula: DateFormula;
        ConsiderSource: array[16] of Boolean;
        SouceTypeValuesBefore: array[16] of Decimal;
        SouceTypeValuesAfter: array[16] of Decimal;
    begin
        // Setup
        Initialize();
        LibraryCFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        LibraryApplicationArea.EnableFoundationSetup();
        // Sales and purchase order source - before date list period
        CreateDocumentsOnDate('<-1D>', SalesHeader, PurchHeader, SouceTypeValuesBefore[10], CustomDateFormula);
        // Sales and purchase order source - after date list period
        CreateDocumentsOnDate('<2D>', SalesHeader2, PurchHeader2, SouceTypeValuesAfter[10], CustomDateFormula);
        SouceTypeValuesBefore[1] := CreateCustLedgEntry(SalesHeader);
        SouceTypeValuesBefore[2] := CreateVendLedgEntry(PurchHeader);
        SouceTypeValuesBefore[6] := GetSalesAmountIncVAT(SalesHeader);
        SouceTypeValuesBefore[7] := GetPurchaseAmountIncVAT(PurchHeader);
        SouceTypeValuesAfter[6] := GetSalesAmountIncVAT(SalesHeader2);
        SouceTypeValuesAfter[7] := GetPurchaseAmountIncVAT(PurchHeader2);
        TotalAmountBefore :=
          CashFlowForecast.CalcSourceTypeAmount("Cash Flow Source Type"::"Liquid Funds") +
          SouceTypeValuesBefore[6] + SouceTypeValuesBefore[10] - SouceTypeValuesBefore[7];
        TotalAmountPeriod := SouceTypeValuesBefore[1] + SouceTypeValuesBefore[2] + TotalAmountBefore;
        TotalAmountAfter := SouceTypeValuesAfter[6] + SouceTypeValuesAfter[10] - SouceTypeValuesAfter[7] + TotalAmountPeriod;

        // Fill and post journal
        ConsiderSalesPurchSources(ConsiderSource);
        FillAndPostCFJournal(ConsiderSource, CashFlowForecast."No.", DocumentNoFilterText, CalcDate('<-1D>', WorkDate()));

        // Exercise
        Evaluate(IntervalLength, '<1D>');
        RunAndExportCFDateListReport(WorkDate(), 1, IntervalLength, CashFlowForecast."No.");

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('NewCFSumTotal', TotalAmountBefore);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('NewCFSumTotal', TotalAmountPeriod);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('NewCFSumTotal', TotalAmountAfter);
    end;

    [Test]
    [HandlerFunctions('RHCashFlowDimensionsDetail')]
    [Scope('OnPrem')]
    procedure DimensionDetailCashFlowForecast()
    var
        AllObj: Record AllObj;
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        AnalysisView: Record "Analysis View";
        SelectedDimension: Record "Selected Dimension";
        CashFlowDimensionsDetail: Report "Cash Flow Dimensions - Detail";
        DateFilter: Text[30];
        ConsiderSource: array[16] of Boolean;
        CashFlowStartDate: Date;
        CashFlowEndDate: Date;
    begin
        // Tests the Dimension - Total report with cash flow view and column layout

        // Setup
        LibraryCF.FindCashFlowCard(CashFlowForecast);
        LibraryCF.FindCashFlowAnalysisView(AnalysisView);

        SelectedDimension.DeleteAll();
        LibraryDimension.CreateSelectedDimension(
          SelectedDimension, AllObj."Object Type"::Report, REPORT::"Cash Flow Dimensions - Detail", AnalysisView.Code,
          LibraryERM.GetGlobalDimensionCode(2));
        SelectedDimension.Validate(Level, SelectedDimension.Level::"Level 1");
        SelectedDimension.Modify(true);

        ConsiderSource[SourceType::Receivables] := true;
        FillAndPostCFJournal(ConsiderSource, CashFlowForecast."No.", '', GetCustLedgEntryPostingDate());

        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);

        CashFlowForecastEntry.SetCurrentKey("Cash Flow Forecast No.", "Cash Flow Date");
        CashFlowForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CashFlowForecastEntry.SetFilter("Dimension Set ID", '<>%1', 0);
        CashFlowForecastEntry.FindFirst();
        CashFlowStartDate := CashFlowForecastEntry."Cash Flow Date";
        CashFlowForecastEntry.FindLast();
        CashFlowEndDate := CashFlowForecastEntry."Cash Flow Date";
        CashFlowForecastEntry.SetRange("Cash Flow Date", CashFlowStartDate, CashFlowEndDate);
        DateFilter := Format(CashFlowStartDate) + '..' + Format(CashFlowEndDate);

        // Exercise
        CashFlowDimensionsDetail.InitializeRequest(AnalysisView.Code, CashFlowForecast."No.", DateFilter, false);
        Commit();
        CashFlowDimensionsDetail.Run();

        // Verify
        // Check that all CF LEs are included in the report
        CashFlowForecastEntry.FindSet();
        LibraryReportDataset.LoadDataSetFile();
        repeat
            LibraryReportDataset.SetRange('TempCFLedgEntryEntryNo', CashFlowForecastEntry."Entry No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertElementWithValueExists('TempCFLedgEntryAmt', CashFlowForecastEntry."Amount (LCY)");
        until CashFlowForecastEntry.Next() = 0;
    end;

    local procedure AppendDocumentNoToFilter(DocumentNo: Code[20])
    begin
        if StrLen(DocumentNoFilterText) = 0 then
            DocumentNoFilterText := DocumentNo
        else
            DocumentNoFilterText += StrSubstNo('|%1', DocumentNo);
    end;

    local procedure CalcServiceHeaderAmt(var ServiceHeader: Record "Service Header"): Decimal
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.CalcSums("Amount Including VAT");
        exit(ServiceLine."Amount Including VAT");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; DocumentDate: Date; PaymentTermsCode: Code[10])
    begin
        LibraryCFHelper.CreateSpecificSalesOrder(SalesHeader, '', PaymentTermsCode);
        SalesHeader.Validate("Document Date", DocumentDate);
        SalesHeader.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; DocumentDate: Date; PaymentTermsCode: Code[10])
    begin
        LibraryService.CreateSpecificServiceOrder(ServiceHeader, '', PaymentTermsCode);
        ServiceHeader.Validate("Document Date", DocumentDate);
        ServiceHeader.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; DocumentDate: Date; PaymentTermsCode: Code[10])
    begin
        LibraryCFHelper.CreateSpecificPurchaseOrder(PurchaseHeader, '', PaymentTermsCode);
        PurchaseHeader.Validate("Document Date", DocumentDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);
    end;

    local procedure FillAndPostCFJournal(ConsiderSource: array[16] of Boolean; CFNo: Code[20]; DocumentNoFilterText: Text[250]; CashFlowStartDate: Date)
    var
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
    begin
        LibraryCF.ClearJournal();
        LibraryCF.FillJournal(ConsiderSource, CFNo, false);
        CFWorksheetLine.SetFilter("Document No.", DocumentNoFilterText);
        CFWorksheetLine.SetFilter("Cash Flow Date", '>=%1', CashFlowStartDate);
        LibraryCF.PostJournalLines(CFWorksheetLine);
    end;

    local procedure GetSalesAmountIncVAT(SalesHeader: Record "Sales Header"): Decimal
    begin
        SalesHeader.CalcFields("Amount Including VAT");
        exit(SalesHeader."Amount Including VAT");
    end;

    local procedure GetPurchaseAmountIncVAT(PurchHeader: Record "Purchase Header"): Decimal
    begin
        PurchHeader.CalcFields("Amount Including VAT");
        exit(PurchHeader."Amount Including VAT");
    end;

    local procedure GetCustLedgEntryPostingDate(): Date
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.FindFirst();
        exit(CustLedgEntry."Posting Date");
    end;

    local procedure RunAndExportCFDateListReport(FromDate: Date; NumberOfIntervals: Integer; IntervalLength: DateFormula; CFNo: Code[20])
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFDateList: Report "Cash Flow Date List";
    begin
        CashFlowForecast.SetRange("No.", CFNo);
        CFDateList.SetTableView(CashFlowForecast);
        CFDateList.InitializeRequest(FromDate, NumberOfIntervals, IntervalLength);
        Commit();
        CFDateList.Run();
    end;

    local procedure VerifyExpDateListSourceLine(SourceValues: array[16] of Decimal; NeutrRevenues: Decimal; NeutrExpenses: Decimal; CFInterference: Decimal; ElementName: Text; FilterValue: Date)
    begin
        LibraryReportDataset.SetRange(ElementName, Format(FilterValue));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Receivables', SourceValues[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals('Payables', SourceValues[2]);
        LibraryReportDataset.AssertCurrentRowValueEquals('Sales_Orders_', SourceValues[6]);
        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Orders_', -SourceValues[7]);
        LibraryReportDataset.AssertCurrentRowValueEquals('InvFixedAssets', -SourceValues[8]);
        LibraryReportDataset.AssertCurrentRowValueEquals('SaleFixedAssets', SourceValues[9]);
        LibraryReportDataset.AssertCurrentRowValueEquals('Service_Orders_', SourceValues[10]);
        LibraryReportDataset.AssertCurrentRowValueEquals('ManualRevenues', NeutrRevenues);
        LibraryReportDataset.AssertCurrentRowValueEquals('ManualExpenses', NeutrExpenses);
        LibraryReportDataset.AssertCurrentRowValueEquals('NewCFSumTotal', CFInterference);
    end;

    local procedure VerifyTotalAmount(CFInterference: Decimal; ElementName: Text; FilterValue: Date)
    begin
        LibraryReportDataset.SetRange(ElementName, Format(FilterValue));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('NewCFSumTotal', CFInterference);
    end;

    [Test]
    [HandlerFunctions('RHCashFlowDateList')]
    [Scope('OnPrem')]
    procedure TestLiquidFundonCashFlowDateListReport()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        TestAmountsonCashFlowDateListReport(CFForecastEntry."Source Type"::"Liquid Funds");
    end;

    [Test]
    [HandlerFunctions('RHCashFlowDateList')]
    [Scope('OnPrem')]
    procedure TestGLBudgetonCashFlowDateListReport()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        TestAmountsonCashFlowDateListReport(CFForecastEntry."Source Type"::"G/L Budget");
    end;

    local procedure TestAmountsonCashFlowDateListReport(CFEntryType: Enum "Cash Flow Source Type")
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CFForecast: Record "Cash Flow Forecast";
        Amount: Decimal;
        IntervalLength: DateFormula;
    begin
        // Bug 279751 - To check Liquidity and G/L budget columns on Cash Flow Date List report Using CashFlowDateListReportHandler.
        // Setup : Create Cash Flow card and insert Cash Flow Forecast Entry.
        Initialize();
        LibraryCF.CreateCashFlowCard(CFForecast);
        CFForecastNo := CFForecast."No.";
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryCFHelper.InsertCFLedgerEntry(CFForecastNo, '', CFEntryType, WorkDate(), Amount);

        // Exercise : Run report Cash Flow Date List.
        Evaluate(IntervalLength, '<1D>');
        RunAndExportCFDateListReport(WorkDate(), 0, IntervalLength, CFForecastNo); // include just 1 day (workdate)
        LibraryReportDataset.LoadDataSetFile();

        // Verify : Liquidity or G/L budget column amounts on Cash flow date list report.
        if CFEntryType = CFForecastEntry."Source Type"::"Liquid Funds" then
            LibraryReportDataset.AssertElementWithValueExists('Liquidity', Amount)
        else
            LibraryReportDataset.AssertElementWithValueExists('GLBudget', Amount);
    end;

    [Test]
    [HandlerFunctions('RHCashFlowDateListToExcel')]
    [Scope('OnPrem')]
    procedure TestTaxesLabelOnCashFlowDateListReport()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry" temporary;
        CFForecast: Record "Cash Flow Forecast";
        CFDateList: Report "Cash Flow Date List";
        Amount: Decimal;
        IntervalLength: DateFormula;
    begin
        // [SCENARIO 361088] The caption of column 'Taxes' is wrong
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Cash Flow Forecast
        LibraryCFHelper.CreateCashFlowForecastDefault(CFForecast);

        // [GIVEN] Cash Flow Forecast Entry of source type Tax with Amount
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryCFHelper.InsertCFLedgerEntry(CFForecast."No.", '', CFForecastEntry."Source Type"::Tax, WorkDate(), Amount);

        // [WHEN] Run report Cash Flow Date List
        Evaluate(IntervalLength, '<1D>');
        CFDateList.SetTableView(CFForecast);
        CFDateList.InitializeRequest(WorkDate(), 2, IntervalLength);
        Commit();

        LibraryVariableStorage.Enqueue(CFForecast."No.");
        CFDateList.Run();

        // [THEN] Column with caption 'Taxes' should exists and contains correct value
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.CheckIfValueExistsInSpecifiedColumn('Taxes', StrSubstNo('%1', Amount));
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cash Flow - Reports");
        DocumentNoFilterText := '';
        Evaluate(EmptyDateFormula, '<0D>');

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cash Flow - Reports");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cash Flow - Reports");
    end;

    local procedure CreateDocumentsOnDate(DateString: Text; var SalesHeader: Record "Sales Header"; var PurchHeader: Record "Purchase Header"; var ServiceHeaderAmount: Decimal; var CustomDateFormula: DateFormula)
    var
        ServiceHeader: Record "Service Header";
    begin
        Evaluate(CustomDateFormula, DateString);
        CreateSalesOrder(SalesHeader, CalcDate(CustomDateFormula, WorkDate()), '');
        AppendDocumentNoToFilter(SalesHeader."No.");
        CreateServiceOrder(ServiceHeader, CalcDate(CustomDateFormula, WorkDate()), '');
        AppendDocumentNoToFilter(ServiceHeader."No.");
        ServiceHeaderAmount := CalcServiceHeaderAmt(ServiceHeader);
        CreatePurchaseOrder(PurchHeader, CalcDate(CustomDateFormula, WorkDate()), '');
        AppendDocumentNoToFilter(PurchHeader."No.");
    end;

    local procedure CreateCustLedgEntry(SalesHeader: Record "Sales Header"): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryCFHelper.CreateLedgerEntry(GenJournalLine, SalesHeader."Sell-to Customer No.", SalesHeader.Amount,
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice);
        AppendDocumentNoToFilter(GenJournalLine."Document No.");
        exit(GenJournalLine.Amount);
    end;

    local procedure CreateVendLedgEntry(PurchHeader: Record "Purchase Header"): Decimal
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        LibraryCFHelper.CreateLedgerEntry(GenJournalLine2, PurchHeader."Buy-from Vendor No.", -PurchHeader.Amount,
          GenJournalLine2."Account Type"::Vendor, GenJournalLine2."Document Type"::Invoice);
        AppendDocumentNoToFilter(GenJournalLine2."Document No.");
        exit(GenJournalLine2.Amount);
    end;

    local procedure ConsiderSalesPurchSources(var ConsiderSource: array[16] of Boolean)
    begin
        ConsiderSource[SourceType::Receivables] := true;
        ConsiderSource[SourceType::Payables] := true;
        ConsiderSource[SourceType::"Sales Order"] := true;
        ConsiderSource[SourceType::"Purchase Order"] := true;
        ConsiderSource[SourceType::"Service Orders"] := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCashFlowDateList(var CashFlowDateList: TestRequestPage "Cash Flow Date List")
    begin
        CashFlowDateList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCashFlowDimensionsDetail(var CashFlowDimensionsDetail: TestRequestPage "Cash Flow Dimensions - Detail")
    begin
        CashFlowDimensionsDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCashFlowDateListToExcel(var CashFlowDateList: TestRequestPage "Cash Flow Date List")
    begin
        CashFlowDateList.CashFlow.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CashFlowDateList.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}

