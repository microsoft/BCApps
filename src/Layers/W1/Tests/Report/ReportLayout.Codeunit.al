codeunit 132600 "Report Layout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report Layout]
        isInitialized := false;
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('RHTrailBalancePreviousYear')]
    [Scope('OnPrem')]
    procedure TestTrailBalancePreviousYear()
    begin
        Initialize();
        REPORT.Run(REPORT::"Trial Balance/Previous Year");
    end;

    [Test]
    [HandlerFunctions('RHVendorOrderSummary')]
    [Scope('OnPrem')]
    procedure TestVendorOrderSummary()
    begin
        Initialize();
        REPORT.Run(REPORT::"Vendor - Order Summary");
    end;

    [Test]
    [HandlerFunctions('RHItemBudget')]
    [Scope('OnPrem')]
    procedure TestItemBudget()
    begin
        Initialize();
        REPORT.Run(REPORT::"Item Budget");
    end;

    [Test]
    [HandlerFunctions('RHCustomerTrialBalance')]
    [Scope('OnPrem')]
    procedure TestCustomerTrialBalance()
    begin
        Initialize();
        REPORT.Run(REPORT::"Customer - Trial Balance");
    end;

    [Test]
    [HandlerFunctions('RHCheck')]
    [Scope('OnPrem')]
    procedure TestCheck()
    begin
        Initialize();
        REPORT.Run(REPORT::Check);
    end;

    [Test]
    [HandlerFunctions('RHVendorBalancetoDate')]
    [Scope('OnPrem')]
    procedure TestVendorBalancetoDate()
    begin
        Initialize();
        REPORT.Run(REPORT::"Vendor - Balance to Date");
    end;

    [Test]
    [HandlerFunctions('RHBudget')]
    [Scope('OnPrem')]
    procedure TestBudget()
    begin
        Initialize();
        REPORT.Run(REPORT::Budget);
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetBookValue01')]
    [Scope('OnPrem')]
    procedure TestFixedAssetBookValue01()
    begin
        Initialize();
        REPORT.Run(REPORT::"Fixed Asset - Book Value 01");
    end;

    [Test]
    [HandlerFunctions('RHCompareProductionCostShares')]
    [Scope('OnPrem')]
    procedure TestCompareProductionCostShares()
    begin
        Initialize();
        REPORT.Run(REPORT::"Compare Production Cost Shares");
    end;

    [Test]
    [HandlerFunctions('RHSalesStatistics')]
    [Scope('OnPrem')]
    procedure TestSalesStatistics()
    begin
        Initialize();
        REPORT.Run(REPORT::"Sales Statistics");
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsPayable')]
    [Scope('OnPrem')]
    procedure TestAgedAccountsPayable()
    begin
        Initialize();
        REPORT.Run(REPORT::"Aged Accounts Payable");
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetAcquisitionList')]
    [Scope('OnPrem')]
    procedure TestFixedAssetAcquisitionList()
    begin
        Initialize();
        REPORT.Run(REPORT::"Fixed Asset - Acquisition List");
    end;

    [Test]
    [HandlerFunctions('RHStatement')]
    [Scope('OnPrem')]
    procedure TestStatement()
    begin
        Initialize();
        REPORT.Run(REPORT::Statement);
    end;

    [Test]
    [HandlerFunctions('RHCustomerBalancetoDate')]
    [Scope('OnPrem')]
    procedure TestCustomerBalancetoDate()
    begin
        Initialize();
        REPORT.Run(REPORT::"Customer - Balance to Date");
    end;

    [Test]
    [HandlerFunctions('RHFAPostingGroupNetChange')]
    [Scope('OnPrem')]
    procedure TestFAPostingGroupNetChange()
    begin
        Initialize();
        REPORT.Run(REPORT::"FA Posting Group - Net Change");
    end;

    [Test]
    [HandlerFunctions('RHItemAgeCompositionQty')]
    [Scope('OnPrem')]
    procedure TestItemAgeCompositionQty()
    begin
        Initialize();
        REPORT.Run(REPORT::"Item Age Composition - Qty.");
    end;

    [Test]
    [HandlerFunctions('RHItemAgeCompositionValue')]
    [Scope('OnPrem')]
    procedure TestItemAgeCompositionValue()
    begin
        Initialize();
        REPORT.Run(REPORT::"Item Age Composition - Value");
    end;

    [Test]
    [HandlerFunctions('RHContractInvoicing,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestContractInvoicing()
    begin
        Initialize();
        REPORT.Run(REPORT::"Contract Invoicing");
    end;

    [Test]
    [HandlerFunctions('RHCostAcctgStmtperPeriod')]
    [Scope('OnPrem')]
    procedure TestCostAcctgStmtperPeriod()
    begin
        Initialize();
        REPORT.Run(REPORT::"Cost Acctg. Stmt. per Period");
    end;

    [Test]
    [HandlerFunctions('RHInventoryAvailabilityPlan')]
    [Scope('OnPrem')]
    procedure TestInventoryAvailabilityPlan()
    begin
        Initialize();
        REPORT.Run(REPORT::"Inventory - Availability Plan");
    end;

    [Test]
    [HandlerFunctions('RHPriceList')]
    [Scope('OnPrem')]
    procedure TestPriceList()
    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
    begin
        Initialize();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 15.0)");
        LibraryVariableStorage.Enqueue(LibrarySales.CreateCustomerNo());
        Commit();
        REPORT.Run(REPORT::"Price List");
    end;

    [Test]
    [HandlerFunctions('RHGLConsolidationEliminations')]
    [Scope('OnPrem')]
    procedure TestGLConsolidationEliminations()
    begin
        Initialize();
        REPORT.Run(REPORT::"G/L Consolidation Eliminations");
    end;

    [Test]
    [HandlerFunctions('RHCustomerSummaryAging')]
    [Scope('OnPrem')]
    procedure TestCustomerSummaryAging()
    begin
        Initialize();
        REPORT.Run(REPORT::"Customer - Summary Aging");
    end;

    [Test]
    [HandlerFunctions('RHAccountSchedule')]
    [Scope('OnPrem')]
    procedure TestAccountSchedule()
    begin
        Initialize();
        REPORT.Run(REPORT::"Account Schedule");
    end;

    [Test]
    [HandlerFunctions('RHConsolidatedTrialBalance')]
    [Scope('OnPrem')]
    procedure TestConsolidatedTrialBalance()
    begin
        Initialize();
        REPORT.Run(REPORT::"Consolidated Trial Balance");
    end;

    [Test]
    [HandlerFunctions('RHVendorTrialBalance')]
    [Scope('OnPrem')]
    procedure TestVendorTrialBalance()
    begin
        Initialize();
        REPORT.Run(REPORT::"Vendor - Trial Balance");
    end;

    [Test]
    [HandlerFunctions('RHCashFlowDimensionsDetail')]
    [Scope('OnPrem')]
    procedure TestCashFlowDimensionsDetail()
    begin
        Initialize();
        REPORT.Run(REPORT::"Cash Flow Dimensions - Detail");
    end;

    [Test]
    [HandlerFunctions('RHCustomerOrderSummary')]
    [Scope('OnPrem')]
    procedure TestCustomerOrderSummary()
    begin
        Initialize();
        REPORT.Run(REPORT::"Customer - Order Summary");
    end;

    [Test]
    [HandlerFunctions('RHClosingTrialBalance')]
    [Scope('OnPrem')]
    procedure TestClosingTrialBalance()
    begin
        Initialize();
        REPORT.Run(REPORT::"Closing Trial Balance");
    end;

    [Test]
    [HandlerFunctions('RHAgedAccountsReceivable')]
    [Scope('OnPrem')]
    procedure TestAgedAccountsReceivable()
    begin
        Initialize();
        REPORT.Run(REPORT::"Aged Accounts Receivable");
    end;

    [Test]
    [HandlerFunctions('RHCustomerSummaryAgingSimp')]
    [Scope('OnPrem')]
    procedure TestCustomerSummaryAgingSimp()
    begin
        Initialize();
        REPORT.Run(REPORT::"Customer - Summary Aging Simp.");
    end;

    [Test]
    [HandlerFunctions('RHFiscalYearBalance')]
    [Scope('OnPrem')]
    procedure TestFiscalYearBalance()
    begin
        Initialize();
        REPORT.Run(REPORT::"Fiscal Year Balance");
    end;

    [Test]
    [HandlerFunctions('RHTrialBalancebyPeriod')]
    [Scope('OnPrem')]
    procedure TestTrialBalancebyPeriod()
    begin
        Initialize();
        REPORT.Run(REPORT::"Trial Balance by Period");
    end;

    [Test]
    [HandlerFunctions('RHBalanceCompPrevYear')]
    [Scope('OnPrem')]
    procedure TestBalanceCompPrevYear()
    begin
        Initialize();
        REPORT.Run(REPORT::"Balance Comp. - Prev. Year");
    end;

    [Test]
    [HandlerFunctions('RHDimensionsDetail')]
    [Scope('OnPrem')]
    procedure TestDimensionsDetail()
    begin
        Initialize();
        REPORT.Run(REPORT::"Dimensions - Detail");
    end;

    [Test]
    [HandlerFunctions('RHTrialBalance')]
    [Scope('OnPrem')]
    procedure TestTrialBalance()
    begin
        Initialize();
        REPORT.Run(REPORT::"Trial Balance");
    end;

    [Test]
    [HandlerFunctions('RHCalcPostVATSettlement')]
    [Scope('OnPrem')]
    procedure TestCalcPostVATSettlement()
    begin
        Initialize();
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");
    end;

    [Test]
    [HandlerFunctions('RHPurchaseReservationAvail')]
    [Scope('OnPrem')]
    procedure TestPurchaseReservationAvail()
    begin
        Initialize();
        REPORT.Run(REPORT::"Purchase Reservation Avail.");
    end;

    [Test]
    [HandlerFunctions('RHInventoryValuationWIP')]
    [Scope('OnPrem')]
    procedure TestInventoryValuationWIP()
    begin
        Initialize();
        REPORT.Run(REPORT::"Inventory Valuation - WIP");
    end;

    [Test]
    [HandlerFunctions('RHVATVIESDeclarationTaxAuth')]
    [Scope('OnPrem')]
    procedure TestVATVIESDeclarationTaxAuth()
    begin
        Initialize();
        REPORT.Run(REPORT::"VAT- VIES Declaration Tax Auth");
    end;

    [Test]
    [HandlerFunctions('RHInventoryReorders')]
    [Scope('OnPrem')]
    procedure TestInventoryReorders()
    begin
        Initialize();
        REPORT.Run(REPORT::"Inventory - Reorders");
    end;

    [Test]
    [HandlerFunctions('RHItemDimensionsTotal')]
    [Scope('OnPrem')]
    procedure TestItemDimensionsTotal()
    begin
        Initialize();
        REPORT.Run(REPORT::"Item Dimensions - Total");
    end;

    [Test]
    [HandlerFunctions('RHAnalysisReport')]
    [Scope('OnPrem')]
    procedure TestAnalysisReport()
    begin
        Initialize();
        REPORT.Run(REPORT::"Analysis Report");
    end;

    [Test]
    [HandlerFunctions('RHMaintenanceAnalysis')]
    [Scope('OnPrem')]
    procedure TestMaintenanceAnalysis()
    begin
        Initialize();
        REPORT.Run(REPORT::"Maintenance - Analysis");
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetBookValue02')]
    [Scope('OnPrem')]
    procedure TestFixedAssetBookValue02()
    begin
        Initialize();
        REPORT.Run(REPORT::"Fixed Asset - Book Value 02");
    end;

    [Test]
    [HandlerFunctions('RHDimensionsTotal')]
    [Scope('OnPrem')]
    procedure TestDimensionsTotal()
    begin
        Initialize();
        REPORT.Run(REPORT::"Dimensions - Total");
    end;

    [Test]
    [HandlerFunctions('RHTrialBalBudget')]
    [Scope('OnPrem')]
    procedure TestTrialBalBudget()
    begin
        Initialize();
        REPORT.Run(REPORT::"Trial Balance/Budget");
    end;

    [Test]
    [HandlerFunctions('RHFixedAssetProjValue')]
    [Scope('OnPrem')]
    procedure TestFixedAssetProjValue()
    begin
        Initialize();
        REPORT.Run(REPORT::"Fixed Asset - Projected Value");
    end;

    [Test]
    [HandlerFunctions('RHSalesReservationAvail')]
    [Scope('OnPrem')]
    procedure TestSalesReservationAvail()
    begin
        Initialize();
        REPORT.Run(REPORT::"Sales Reservation Avail.");
    end;

    [Test]
    [HandlerFunctions('RHCostAcctgAnalysis')]
    [Scope('OnPrem')]
    procedure TestCostAcctgAnalysis()
    begin
        Initialize();
        REPORT.Run(REPORT::"Cost Acctg. Analysis");
    end;

    [Test]
    [HandlerFunctions('RHMovementList')]
    [Scope('OnPrem')]
    procedure TestMovementList()
    begin
        Initialize();
        REPORT.Run(REPORT::"Movement List");
    end;

    [Test]
    [HandlerFunctions('RHCostAcctgBalanceBudget')]
    [Scope('OnPrem')]
    procedure TestCostAcctgBalanceBudget()
    begin
        Initialize();
        REPORT.Run(REPORT::"Cost Acctg. Balance/Budget");
    end;

    [Test]
    [HandlerFunctions('RHPostInventoryCosttoGL')]
    [Scope('OnPrem')]
    procedure TestPostInventoryCosttoGL()
    begin
        Initialize();
        REPORT.Run(REPORT::"Post Inventory Cost to G/L");
    end;

    [Test]
    [HandlerFunctions('RHContrServOrdersTest')]
    [Scope('OnPrem')]
    procedure TestContrServOrdersTest()
    begin
        Initialize();
        REPORT.Run(REPORT::"Contr. Serv. Orders - Test");
    end;

    [Test]
    [HandlerFunctions('RHPostInvtCosttoGLtest')]
    [Scope('OnPrem')]
    procedure TestPostInvtCosttoGLtest()
    begin
        Initialize();
        REPORT.Run(REPORT::"Post Invt. Cost to G/L - Test");
    end;

    [Test]
    [HandlerFunctions('RHContractPriceUpdateTest')]
    [Scope('OnPrem')]
    procedure TestContractPriceUpdateTest()
    begin
        Initialize();
        REPORT.Run(REPORT::"Contract Price Update - Test");
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        // Setup logo to be printed by default
        SalesSetup.Get();
        SalesSetup.Validate("Logo Position on Documents", SalesSetup."Logo Position on Documents"::Center);
        SalesSetup.Modify(true);

        isInitialized := true;
        Commit();
    end;

    local procedure FormatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange(Blocked, false);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::" ");
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.SetFilter("Gen. Bus. Posting Group", '%1', '');
        GLAccount.SetFilter("Gen. Prod. Posting Group", '%1', '');
        GLAccount.SetFilter("VAT Prod. Posting Group", '%1', '');
        GLAccount.FindSet();
    end;

    local procedure FindItem(var Item: Record Item)
    begin
        // Filter Item so that errors are not generated due to mandatory fields or Item Tracking.
        Item.SetFilter("Inventory Posting Group", '<>''''');
        Item.SetFilter("Gen. Prod. Posting Group", '<>''''');
        Item.SetRange("Item Tracking Code", '');
        Item.SetRange(Blocked, false);
        Item.SetFilter("Unit Price", '<>0');
        Item.SetFilter(Reserve, '<>%1', Item.Reserve::Always);
        Item.FindFirst();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(msg: Text[1024]; var reply: Boolean)
    begin
        reply := true
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHTrailBalancePreviousYear(var TrailBalance: TestRequestPage "Trial Balance/Previous Year")
    begin
        TrailBalance."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        TrailBalance.SaveAsPdf(FormatFileName(TrailBalance.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorOrderSummary(var VendorOrderSummary: TestRequestPage "Vendor - Order Summary")
    begin
        VendorOrderSummary.StartingDate.SetValue(WorkDate());
        VendorOrderSummary.AmountsinLCY.SetValue(true);
        VendorOrderSummary.SaveAsPdf(FormatFileName(VendorOrderSummary.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHItemBudget(var ItemBudget: TestRequestPage "Item Budget")
    begin
        ItemBudget.StartingDate.SetValue(WorkDate());
        ItemBudget.PeriodLength.SetValue('1M');
        ItemBudget.SaveAsPdf(FormatFileName(ItemBudget.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerTrialBalance(var CustomerTrialBalance: TestRequestPage "Customer - Trial Balance")
    begin
        CustomerTrialBalance.Customer.SetFilter("Date Filter", Format(WorkDate()));
        CustomerTrialBalance.SaveAsPdf(FormatFileName(CustomerTrialBalance.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCheck(var Check: TestRequestPage Check)
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.SetFilter("Last Check No.", '<>%1', '');
        BankAcc.FindFirst();
        Check.BankAccount.SetValue(BankAcc."No.");
        Check.LastCheckNo.SetValue(BankAcc."Last Check No.");
        Check.TestPrinting.SetValue(true);
        Check.SaveAsPdf(FormatFileName(Check.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorBalancetoDate(var VendorBalancetoDate: TestRequestPage "Vendor - Balance to Date")
    begin
        VendorBalancetoDate.Vendor.SetFilter("Date Filter", StrSubstNo('%1..%2', Format(WorkDate()), Format(CalcDate('<+10Y>', WorkDate()))));
        VendorBalancetoDate.SaveAsPdf(FormatFileName(VendorBalancetoDate.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHBudget(var Budget: TestRequestPage Budget)
    begin
        Budget.StartingDate.SetValue(WorkDate());
        Budget.SaveAsPdf(FormatFileName(Budget.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetBookValue01(var FixedAssetBookValue01: TestRequestPage "Fixed Asset - Book Value 01")
    begin
        FixedAssetBookValue01.StartingDate.SetValue(WorkDate());
        FixedAssetBookValue01.EndingDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        FixedAssetBookValue01.SaveAsPdf(FormatFileName(FixedAssetBookValue01.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCompareProductionCostShares(var CompareProductionCostShares: TestRequestPage "Compare Production Cost Shares")
    var
        Item: Record Item;
    begin
        FindItem(Item);
        CompareProductionCostShares.ItemNo1.SetValue(Item."No.");
        Item.Next(1);
        CompareProductionCostShares.ItemNo2.SetValue(Item."No.");
        CompareProductionCostShares.SaveAsExcel(FormatFileName(CompareProductionCostShares.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHSalesStatistics(var SalesStatistics: TestRequestPage "Sales Statistics")
    begin
        SalesStatistics.StartingDate.SetValue(WorkDate());
        SalesStatistics.PeriodLength.SetValue('1M');
        SalesStatistics.SaveAsPdf(FormatFileName(SalesStatistics.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAgedAccountsPayable(var AgedAccountsPayable: TestRequestPage "Aged Accounts Payable")
    begin
        AgedAccountsPayable.AgedAsOf.SetValue(WorkDate());
        AgedAccountsPayable.PeriodLength.SetValue('1M');
        AgedAccountsPayable.SaveAsPdf(FormatFileName(AgedAccountsPayable.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetAcquisitionList(var FixedAssetAcquisitionList: TestRequestPage "Fixed Asset - Acquisition List")
    begin
        FixedAssetAcquisitionList.StartingDate.SetValue(CalcDate('<-10Y>', WorkDate()));
        FixedAssetAcquisitionList.EndingDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        FixedAssetAcquisitionList.SaveAsPdf(FormatFileName(FixedAssetAcquisitionList.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHStatement(var Statement: TestRequestPage Statement)
    begin
        Statement."Start Date".SetValue(WorkDate());
        Statement."End Date".SetValue(WorkDate());
        Statement.SaveAsPdf(FormatFileName(Statement.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerBalancetoDate(var CustomerBalancetoDate: TestRequestPage "Customer - Balance to Date")
    begin
        CustomerBalancetoDate."Ending Date".SetValue(CalcDate('<+10Y>', WorkDate()));
        CustomerBalancetoDate.SaveAsPdf(FormatFileName(CustomerBalancetoDate.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFAPostingGroupNetChange(var FAPostingGroupNetChange: TestRequestPage "FA Posting Group - Net Change")
    begin
        FAPostingGroupNetChange.StartingDate.SetValue(CalcDate('<-10Y>', WorkDate()));
        FAPostingGroupNetChange.EndingDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        FAPostingGroupNetChange.SaveAsPdf(FormatFileName(FAPostingGroupNetChange.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHItemAgeCompositionQty(var ItemAgeCompositionQty: TestRequestPage "Item Age Composition - Qty.")
    begin
        ItemAgeCompositionQty.EndingDate.SetValue(WorkDate());
        ItemAgeCompositionQty.PeriodLength.SetValue('1M');
        ItemAgeCompositionQty.SaveAsPdf(FormatFileName(ItemAgeCompositionQty.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHItemAgeCompositionValue(var ItemAgeCompositionValue: TestRequestPage "Item Age Composition - Value")
    begin
        ItemAgeCompositionValue.EndingDate.SetValue(WorkDate());
        ItemAgeCompositionValue.PeriodLength.SetValue('1M');
        ItemAgeCompositionValue.SaveAsPdf(FormatFileName(ItemAgeCompositionValue.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHContractInvoicing(var ContractInvoicing: TestRequestPage "Contract Invoicing")
    begin
        ContractInvoicing.PostingDate1.SetValue(WorkDate());
        ContractInvoicing.InvoiceDate1.SetValue(CalcDate('<+10Y>', WorkDate()));
        ContractInvoicing.SaveAsPdf(FormatFileName(ContractInvoicing.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCostAcctgStmtperPeriod(var CostAcctgStmtperPeriod: TestRequestPage "Cost Acctg. Stmt. per Period")
    begin
        CostAcctgStmtperPeriod.StartDate.SetValue(WorkDate());
        CostAcctgStmtperPeriod.OnlyAccWithEntries.SetValue(true);
        CostAcctgStmtperPeriod.ShowAddCurrency.SetValue(true);
        CostAcctgStmtperPeriod.SaveAsPdf(FormatFileName(CostAcctgStmtperPeriod.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHInventoryAvailabilityPlan(var InventoryAvailabilityPlan: TestRequestPage "Inventory - Availability Plan")
    begin
        InventoryAvailabilityPlan.StartingDate.SetValue(WorkDate());
        InventoryAvailabilityPlan.PeriodLength.SetValue('1M');
        InventoryAvailabilityPlan.UseStockkeepUnit.SetValue(true);
        InventoryAvailabilityPlan.SaveAsPdf(FormatFileName(InventoryAvailabilityPlan.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHPriceList(var PriceList: TestRequestPage "Price List")
    begin
        PriceList.SalesCodeCtrl.SetValue(LibraryVariableStorage.DequeueText());
        PriceList.Date.SetValue(WorkDate());
        PriceList.SaveAsPdf(FormatFileName(PriceList.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHGLConsolidationEliminations(var GLConsolidationEliminations: TestRequestPage "G/L Consolidation Eliminations")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryERM: Codeunit "Library - ERM";
    begin
        GLConsolidationEliminations.StartingDate.SetValue(CalcDate('<-1Y>', WorkDate()));
        GLConsolidationEliminations.EndingDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        GLConsolidationEliminations.JournalTemplateName.SetValue(GenJournalTemplate.Name);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GLConsolidationEliminations.JournalBatch.SetValue(GenJournalBatch.Name);
        GLConsolidationEliminations.SaveAsPdf(FormatFileName(GLConsolidationEliminations.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerSummaryAging(var CustomerSummaryAging: TestRequestPage "Customer - Summary Aging")
    begin
        CustomerSummaryAging.StartingDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        CustomerSummaryAging.SaveAsPdf(FormatFileName(CustomerSummaryAging.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAccountSchedule(var AccountSchedule: TestRequestPage "Account Schedule")
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ColumnLayoutName: Record "Column Layout Name";
    begin
        AccScheduleName.FindFirst();
        AccountSchedule.AccSchedNam.SetValue(AccScheduleName.Name);
        ColumnLayoutName.FindFirst();
        AccountSchedule.ColumnLayoutNames.SetValue(ColumnLayoutName.Name);
        AccountSchedule.StartDate.SetValue(WorkDate());
        AccountSchedule.EndDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        AccountSchedule.SaveAsPdf(FormatFileName(AccountSchedule.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHConsolidatedTrialBalance(var ConsolidatedTrialBalance: TestRequestPage "Consolidated Trial Balance")
    begin
        ConsolidatedTrialBalance.StartingDt.SetValue(WorkDate());
        ConsolidatedTrialBalance.EndingDt.SetValue(CalcDate('<+10Y>', WorkDate()));
        ConsolidatedTrialBalance.SaveAsPdf(FormatFileName(ConsolidatedTrialBalance.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorTrialBalance(var VendorTrialBalance: TestRequestPage "Vendor - Trial Balance")
    begin
        VendorTrialBalance.Vendor.SetFilter("Date Filter", StrSubstNo('%1..%2', Format(WorkDate()), Format(CalcDate('<+10Y>', WorkDate()))));
        VendorTrialBalance.SaveAsPdf(FormatFileName(VendorTrialBalance.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCashFlowDimensionsDetail(var CashFlowDimensionsDetail: TestRequestPage "Cash Flow Dimensions - Detail")
    var
        AnalysisView: Record "Analysis View";
        CashFlowForecast: Record "Cash Flow Forecast";
        LibraryCashFlow: Codeunit "Library - Cash Flow";
    begin
        AnalysisView.FindFirst();
        CashFlowDimensionsDetail.AnalysisViewCodes.SetValue(AnalysisView.Code);
        LibraryCashFlow.FindCashFlowCard(CashFlowForecast);
        CashFlowDimensionsDetail.ForecastFilter.SetValue(CashFlowForecast."No.");
        CashFlowDimensionsDetail.DateFilters.SetValue(StrSubstNo('%1..%2', Format(WorkDate()), CalcDate('<+1Y>', WorkDate())));
        CashFlowDimensionsDetail.PrintEmptyLine.SetValue(true);
        CashFlowDimensionsDetail.SaveAsPdf(FormatFileName(CashFlowDimensionsDetail.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerOrderSummary(var CustomerOrdeRSummary: TestRequestPage "Customer - Order Summary")
    begin
        CustomerOrdeRSummary.ShwAmtinLCY.SetValue(true);
        CustomerOrdeRSummary.StartingDate.SetValue(WorkDate());
        CustomerOrdeRSummary.SaveAsPdf(FormatFileName(CustomerOrdeRSummary.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHClosingTrialBalance(var ClosingTrialBalance: TestRequestPage "Closing Trial Balance")
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        ClosingTrialBalance.StartingDate.SetValue(LibraryFiscalYear.GetAccountingPeriodDate(WorkDate()));
        ClosingTrialBalance.AmtsInAddCurr.SetValue(false);
        ClosingTrialBalance.SaveAsPdf(FormatFileName(ClosingTrialBalance.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAgedAccountsReceivable(var AgedAccountsReceivable: TestRequestPage "Aged Accounts Receivable")
    var
        AgingBy: Option "Due Date","Posting Date","Document Date";
    begin
        AgedAccountsReceivable.AgedAsOf.SetValue(CalcDate('<+2Y>', WorkDate()));
        AgedAccountsReceivable.Agingby.SetValue(AgingBy::"Posting Date");
        AgedAccountsReceivable.PeriodLength.SetValue('2M');
        AgedAccountsReceivable.AmountsinLCY.SetValue(true);
        AgedAccountsReceivable.perCustomer.SetValue(true);
        AgedAccountsReceivable.SaveAsPdf(FormatFileName(AgedAccountsReceivable.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCustomerSummaryAgingSimp(var CustomerSummaryAgingSimp: TestRequestPage "Customer - Summary Aging Simp.")
    begin
        CustomerSummaryAgingSimp.StartingDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        CustomerSummaryAgingSimp.SaveAsPdf(FormatFileName(CustomerSummaryAgingSimp.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFiscalYearBalance(var FiscalYearBalance: TestRequestPage "Fiscal Year Balance")
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        FiscalYearBalance.StartingDate.SetValue(LibraryFiscalYear.GetAccountingPeriodDate(WorkDate()));
        FiscalYearBalance.SaveAsPdf(FormatFileName(FiscalYearBalance.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHTrialBalancebyPeriod(var TrialBalancebyPeriod: TestRequestPage "Trial Balance by Period")
    var
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        TrialBalancebyPeriod.StartingDate.SetValue(LibraryFiscalYear.GetAccountingPeriodDate(WorkDate()));
        TrialBalancebyPeriod.SaveAsPdf(FormatFileName(TrialBalancebyPeriod.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHBalanceCompPrevYear(var BalanceCompPrevYear: TestRequestPage "Balance Comp. - Prev. Year")
    begin
        BalanceCompPrevYear.StartingDate.SetValue(WorkDate());
        BalanceCompPrevYear.SaveAsPdf(FormatFileName(BalanceCompPrevYear.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDimensionsDetail(var DimensionsDetail: TestRequestPage "Dimensions - Detail")
    var
        AnalysisView: Record "Analysis View";
    begin
        AnalysisView.FindFirst();
        DimensionsDetail.AnalysisViewCode.SetValue(AnalysisView.Code);
        DimensionsDetail.DtFilter.SetValue(WorkDate());
        DimensionsDetail.SaveAsPdf(FormatFileName(DimensionsDetail.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHTrialBalance(var TrialBalance: TestRequestPage "Trial Balance")
    begin
        TrialBalance."G/L Account".SetFilter("Date Filter", StrSubstNo('%1..%2', Format(WorkDate()), Format(CalcDate('<+3Y>', WorkDate()))));
        TrialBalance.SaveAsPdf(FormatFileName(TrialBalance.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCalcPostVATSettlement(var CalcandPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    var
        GLAccount: Record "G/L Account";
    begin
        FindGLAccount(GLAccount);
        CalcandPostVATSettlement.StartingDate.SetValue(CalcDate('<-2Y>', WorkDate()));
        CalcandPostVATSettlement.PostingDt.SetValue(WorkDate());
        CalcandPostVATSettlement.VATDt.SetValue(WorkDate());
        CalcandPostVATSettlement.SettlementAcc.SetValue(GLAccount."No.");
        CalcandPostVATSettlement.DocumentNo.SetValue(GLAccount."No.");
        CalcandPostVATSettlement.ShowVATEntries.SetValue(true);
        CalcandPostVATSettlement.SaveAsPdf(FormatFileName(CalcandPostVATSettlement.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHPurchaseReservationAvail(var PurchaseReservationAvai: TestRequestPage "Purchase Reservation Avail.")
    begin
        PurchaseReservationAvai.ShowPurchLine.SetValue(true);
        PurchaseReservationAvai.ShowReservationEntries.SetValue(true);
        PurchaseReservationAvai.ModifyQtuantityToShip.SetValue(true);
        PurchaseReservationAvai.SaveAsPdf(FormatFileName(PurchaseReservationAvai.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHInventoryValuationWIP(var InventoryValuationWIP: TestRequestPage "Inventory Valuation - WIP")
    begin
        InventoryValuationWIP.StartingDate.SetValue(WorkDate());
        InventoryValuationWIP.EndingDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        InventoryValuationWIP.SaveAsPdf(FormatFileName(InventoryValuationWIP.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVATVIESDeclarationTaxAuth(var VATVIESDeclarationTaxAuth: TestRequestPage "VAT- VIES Declaration Tax Auth")
    begin
        VATVIESDeclarationTaxAuth.StartingDate.SetValue(WorkDate());
        VATVIESDeclarationTaxAuth.EndingDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        VATVIESDeclarationTaxAuth.SaveAsPdf(FormatFileName(VATVIESDeclarationTaxAuth.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHInventoryReorders(var InventoryReorders: TestRequestPage "Inventory - Reorders")
    begin
        InventoryReorders.UseStockkeepUnit.SetValue(true);
        InventoryReorders.SaveAsPdf(FormatFileName(InventoryReorders.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHItemDimensionsTotal(var ItemDimensionsTotal: TestRequestPage "Item Dimensions - Total")
    var
        ItemAnalysisView: Record "Item Analysis View";
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        ItemAnalysisView.SetRange("Analysis Area", ItemAnalysisView."Analysis Area"::Sales);
        ItemAnalysisView.FindFirst();
        AnalysisColumnTemplate.FindFirst();
        ItemDimensionsTotal.AnalysisViewCode.SetValue(ItemAnalysisView.Code);
        ItemDimensionsTotal.ColumnTemplate.SetValue(AnalysisColumnTemplate.Name);
        ItemDimensionsTotal.DateFilter.SetValue(StrSubstNo('%1..%2', Format(WorkDate()), CalcDate('<+10Y>', WorkDate())));
        ItemDimensionsTotal.SaveAsPdf(FormatFileName(ItemDimensionsTotal.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHAnalysisReport(var AnalysisReport: TestRequestPage "Analysis Report")
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisArea: Option Sales,Purchase,Inventory;
    begin
        AnalysisLineTemplate.FindFirst();
        AnalysisColumnTemplate.FindFirst();
        AnalysisReport.AnalysisArea.SetValue(AnalysisArea::Sales);
        AnalysisReport.AnalysisLineName.SetValue(AnalysisLineTemplate.Name);
        AnalysisReport.AnalysisColumnName.SetValue(AnalysisColumnTemplate.Name);
        AnalysisReport.DateFilter.SetValue(StrSubstNo('%1..%2', CalcDate('<-2Y>', WorkDate()), WorkDate()));
        AnalysisReport.SaveAsPdf(FormatFileName(AnalysisReport.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHMaintenanceAnalysis(var MaintenanceAnalysis: TestRequestPage "Maintenance - Analysis")
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.FindFirst();
        MaintenanceAnalysis.DeprBookCode.SetValue(DepreciationBook.Code);
        MaintenanceAnalysis.StartingDate.SetValue(WorkDate());
        MaintenanceAnalysis.EndingDate.SetValue(CalcDate('<+1Y>', WorkDate()));
        MaintenanceAnalysis.PrintPerFixedAsset.SetValue(true);
        MaintenanceAnalysis.SaveAsPdf(FormatFileName(MaintenanceAnalysis.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetBookValue02(var FixedAssetBookValue02: TestRequestPage "Fixed Asset - Book Value 02")
    var
        DepreciationBook: Record "Depreciation Book";
        GrpTotal: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        DepreciationBook.FindFirst();
        FixedAssetBookValue02.DeprBookCode.SetValue(DepreciationBook.Code);
        FixedAssetBookValue02.StartingDate.SetValue(WorkDate());
        FixedAssetBookValue02.EndingDate.SetValue(CalcDate('<+1Y>', WorkDate()));
        FixedAssetBookValue02.GroupTotals.SetValue(GrpTotal::"FA Subclass");
        FixedAssetBookValue02.PrintDetails.SetValue(true);
        FixedAssetBookValue02.SaveAsPdf(FormatFileName(FixedAssetBookValue02.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHDimensionsTotal(var DimensionsTotal: TestRequestPage "Dimensions - Total")
    var
        AnalysisViewCode: Record "Analysis View";
        ColumnLayoutName: Record "Column Layout Name";
        GLBudgetName: Record "G/L Budget Name";
    begin
        AnalysisViewCode.FindFirst();
        ColumnLayoutName.FindFirst();
        GLBudgetName.FindFirst();
        DimensionsTotal.AnalysisViewCode.SetValue(AnalysisViewCode.Code);
        DimensionsTotal.ColumnLayoutName.SetValue(ColumnLayoutName.Name);
        DimensionsTotal.DtFilter.SetValue(WorkDate());
        DimensionsTotal.GLBudgetName.SetValue(GLBudgetName.Name);
        DimensionsTotal.SaveAsPdf(FormatFileName(DimensionsTotal.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHTrialBalBudget(var TrialBalBudget: TestRequestPage "Trial Balance/Budget")
    begin
        TrialBalBudget."G/L Account".SetFilter("Date Filter", Format(WorkDate()));
        TrialBalBudget.SaveAsPdf(FormatFileName(TrialBalBudget.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetProjValue(var FixedAssetProjValue: TestRequestPage "Fixed Asset - Projected Value")
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        GLBudgetName.FindFirst();
        FixedAssetProjValue.FirstDeprDate.SetValue(WorkDate());
        FixedAssetProjValue.LastDeprDate.SetValue(WorkDate());
        FixedAssetProjValue.CopyToGLBudgetName.SetValue(GLBudgetName.Name);
        FixedAssetProjValue.InsertBalAccount.SetValue(true);
        FixedAssetProjValue.PrintPerFixedAsset.SetValue(true);
        FixedAssetProjValue.SaveAsPdf(FormatFileName(FixedAssetProjValue.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHSalesReservationAvail(var SalesReservationAvail: TestRequestPage "Sales Reservation Avail.")
    begin
        SalesReservationAvail.ShowSalesLines.SetValue(true);
        SalesReservationAvail.ShowReservationEntries.SetValue(true);
        SalesReservationAvail.SaveAsPdf(FormatFileName(SalesReservationAvail.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCostAcctgAnalysis(var CostAcctgAnalysis: TestRequestPage "Cost Acctg. Analysis")
    var
        CostCenter: Record "Cost Center";
        CostCenterCode: array[7] of Code[20];
        i: Integer;
    begin
        CostCenter.FindSet();
        repeat
            i += 1;
            CostCenterCode[i] := CostCenter.Code;
            CostCenter.Next(+1);
        until i >= 7;

        CostAcctgAnalysis.CostCenter1.SetValue(CostCenterCode[1]);
        CostAcctgAnalysis.CostCenter2.SetValue(CostCenterCode[2]);
        CostAcctgAnalysis.CostCenter3.SetValue(CostCenterCode[3]);
        CostAcctgAnalysis.CostCenter4.SetValue(CostCenterCode[4]);
        CostAcctgAnalysis.CostCenter5.SetValue(CostCenterCode[5]);
        CostAcctgAnalysis.CostCenter6.SetValue(CostCenterCode[6]);
        CostAcctgAnalysis.CostCenter7.SetValue(CostCenterCode[7]);
        CostAcctgAnalysis.SaveAsPdf(FormatFileName(CostAcctgAnalysis.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHMovementList(var MovementList: TestRequestPage "Movement List")
    begin
        MovementList.SetBreakbulkFilter.SetValue(true);
        MovementList.SumUpLines.SetValue(true);
        MovementList.ShowSlNoLotNo.SetValue(true);
        MovementList.SaveAsPdf(FormatFileName(MovementList.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHCostAcctgBalanceBudget(var CostAcctgBalanceBudget: TestRequestPage "Cost Acctg. Balance/Budget")
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostBudgetName: Record "Cost Budget Name";
    begin
        CostCenter.FindFirst();
        CostObject.FindFirst();
        CostBudgetName.FindFirst();
        CostAcctgBalanceBudget.StartDate.SetValue(Format(WorkDate()));
        CostAcctgBalanceBudget.EndDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        CostAcctgBalanceBudget.YearStartDate.SetValue(Format(WorkDate()));
        CostAcctgBalanceBudget.YearEndDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        CostAcctgBalanceBudget."Cost Type".SetFilter("Cost Center Filter", CostCenter.Code);
        CostAcctgBalanceBudget."Cost Type".SetFilter("Cost Object Filter", CostObject.Code);
        CostAcctgBalanceBudget."Cost Type".SetFilter("Budget Filter", CostBudgetName.Name);
        CostAcctgBalanceBudget.SaveAsPdf(FormatFileName(CostAcctgBalanceBudget.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHPostInventoryCosttoGL(var PostInventoryCosttoGL: TestRequestPage "Post Inventory Cost to G/L")
    var
        PostMethod: Option "per Posting Group","per Entry";
    begin
        PostInventoryCosttoGL.PostMethod.SetValue(PostMethod::"per Entry");
        PostInventoryCosttoGL.SaveAsPdf(FormatFileName(PostInventoryCosttoGL.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHContrServOrdersTest(var ContrServOrdersTest: TestRequestPage "Contr. Serv. Orders - Test")
    begin
        ContrServOrdersTest.EndingDate.SetValue(Format(WorkDate()));
        ContrServOrdersTest.SaveAsPdf(FormatFileName(ContrServOrdersTest.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHPostInvtCosttoGLtest(var PostInvtCosttoGLtest: TestRequestPage "Post Invt. Cost to G/L - Test")
    var
        GLAccount: Record "G/L Account";
    begin
        FindGLAccount(GLAccount);
        PostInvtCosttoGLtest.DocumentNo.SetValue(GLAccount."No.");
        PostInvtCosttoGLtest.SaveAsPdf(FormatFileName(PostInvtCosttoGLtest.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHContractPriceUpdateTest(var ContractPriceUpdateTest: TestRequestPage "Contract Price Update - Test")
    begin
        ContractPriceUpdateTest."Price Update %".SetValue(10);
        ContractPriceUpdateTest.SaveAsPdf(FormatFileName(ContractPriceUpdateTest.Caption));
    end;
}

