// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.ExcelReports.Test;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.ExcelReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 139544 "Trial Balance Excel Reports"
{
    Subtype = Test;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        DocumentTypeShouldBeInvoiceErr: Label 'Document Type should be Invoice';
        DocumentNoShouldMatchErr: Label 'Document No should match the ledger entry';

    [Test]
    [HandlerFunctions('EXRTrialBalanceExcelHandler')]
    procedure TrialBalanceExportsAsManyItemsAsGLAccounts()
    var
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [SCENARIO] An empty report should export all GL Accounts regardless
        // [GIVEN] An empty trial balance
        Initialize();
        // [GIVEN] 5 G/L Accounts
        CreateSampleGLAccounts(5);
        Commit();
        // [WHEN] Running the report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Trial Balance Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Trial Balance Excel", Variant, RequestPageXml);
        // [THEN] 5 rows of type GLAccount should be exported
        Assert.AreEqual(5, LibraryReportDataset.RowCount(), 'Only the GLAccounts should be exported');
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="GLAccounts"]');
        Assert.AreEqual(5, LibraryReportDataset.RowCount(), 'The exported items should be GLAccounts');
    end;

    [Test]
    [HandlerFunctions('EXRTrialBalanceHideNoActivityHandler')]
    procedure TrialBalanceHidesZeroActivityAccounts()
    var
        GLAccount: Record "G/L Account";
        Variant: Variant;
        RequestPageXml: Text;
        ActiveAccountNo: Code[20];
    begin
        // [SCENARIO] With Hide Accounts with No Activity enabled, only accounts with activity are exported
        // [GIVEN] 5 G/L Accounts, only 1 with activity
        Initialize();
        CreateSampleGLAccounts(5, GLAccount);
        ActiveAccountNo := GLAccount."No.";
        CreateGLEntryWithAmount(ActiveAccountNo, '', '', '', WorkDate(), 100);
        Commit();
        // [WHEN] Running the report with Hide Accounts with No Activity enabled
        RequestPageXml := Report.RunRequestPage(Report::"EXR Trial Balance Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Trial Balance Excel", Variant, RequestPageXml);
        // [THEN] Only the active account should be exported
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="GLAccounts"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'Only the account with activity should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('AccountNumber', Variant);
        Assert.AreEqual(ActiveAccountNo, Format(Variant), 'The exported account should be the one with activity');
    end;

    [Test]
    [HandlerFunctions('EXRTrialBalanceBudgetExcelHandler')]
    procedure TrialBalanceBudgetExportsAsManyItemsAsGLAccounts()
    var
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [SCENARIO] An empty report should export all GL Accounts regardless
        // [GIVEN] An empty trial balance
        Initialize();
        // [GIVEN] 7 G/L Accounts
        CreateSampleGLAccounts(7);
        Commit();
        // [WHEN] Running the report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Trial BalanceBudgetExcel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Trial BalanceBudgetExcel", Variant, RequestPageXml);
        // [THEN] 7 rows of type GLAccount should be exported
        Assert.AreEqual(7, LibraryReportDataset.RowCount(), 'Only the GLAccounts should be exported');
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="GLAccounts"]');
        Assert.AreEqual(7, LibraryReportDataset.RowCount(), 'The exported items should be GLAccounts');
    end;


    [Test]
    [HandlerFunctions('EXRConsolidatedTrialBalanceHandler')]
    procedure ConsolidatedTrialBalanceExportsAsManyItemsAsGLAccountsAndBusinessUnits()
    var
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [SCENARIO] An empty Consolidation report should export all GL Accounts regardless and all Business Units
        // [GIVEN] An empty trial balance
        Initialize();
        // [GIVEN] 9 G/L Accounts
        CreateSampleGLAccounts(9);
        // [GIVEN] 3 Business units
        CreateSampleBusinessUnits(3);
        Commit();
        // [WHEN] Running the report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Consolidated Trial Balance", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Consolidated Trial Balance", Variant, RequestPageXml);
        // [THEN] The 9 GLAccount rows and 3 Business Unit rows should be exported
        Assert.AreEqual(9 + 3, LibraryReportDataset.RowCount(), 'Only GL Accounts and Business Units should be exported');
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="GLAccounts"]');
        Assert.AreEqual(9, LibraryReportDataset.RowCount(), 'Created GL Accounts should be exported');
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="BusinessUnits"]');
        Assert.AreEqual(3, LibraryReportDataset.RowCount(), 'Created BusinessUnits should be exported');
    end;

    [Test]
    [HandlerFunctions('EXRTrialBalanceExcelHandler')]
    procedure TrialBalanceDoesntExportDimensionValuesIfUnused()
    var
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [SCENARIO] An empty report should only export GL Accounts, even if there are dimensions
        // [GIVEN] An empty trial balance
        Initialize();
        // [GIVEN] 3 GL Accounts
        CreateSampleGLAccounts(3);
        // [GIVEN] 2 Global Dimensions, with Dimension Values
        CreateSampleGlobalDimensionAndDimensionValues();
        Commit();
        // [WHEN] Running the report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Trial Balance Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Trial Balance Excel", Variant, RequestPageXml);
        // [THEN] Only the GL Accounts should be exported
        Assert.AreEqual(3, LibraryReportDataset.RowCount(), 'Only the GLAccounts should be exported');
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="GLAccounts"]');
        Assert.AreEqual(3, LibraryReportDataset.RowCount(), 'The exported items should be GLAccounts');
    end;

    [Test]
    [HandlerFunctions('EXRTrialBalanceBudgetExcelHandler')]
    procedure TrialBalanceBudgetDoesntExportDimensionValuesIfUnused()
    var
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [SCENARIO] An empty report should only export GL Accounts, even if there are dimensions
        // [GIVEN] An empty trial balance
        Initialize();
        // [GIVEN] 6 GL Accounts
        CreateSampleGLAccounts(6);
        // [GIVEN] 2 Global Dimensions, with Dimension Values
        CreateSampleGlobalDimensionAndDimensionValues();
        Commit();
        // [WHEN] Running the report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Trial BalanceBudgetExcel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Trial BalanceBudgetExcel", Variant, RequestPageXml);
        // [THEN] Only the GL Accounts should be exported
        Assert.AreEqual(6, LibraryReportDataset.RowCount(), 'Only the GLAccounts should be exported');
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="GLAccounts"]');
        Assert.AreEqual(6, LibraryReportDataset.RowCount(), 'The exported items should be GLAccounts');
    end;

    [Test]
    [HandlerFunctions('EXRConsolidatedTrialBalanceHandler')]
    procedure ConsolidatedTrialBalanceDoesntExportDimensionValuesIfUnused()
    var
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [SCENARIO] An empty report should only export GL Accounts, even if there are dimensions
        // [GIVEN] An empty trial balance
        Initialize();
        // [GIVEN] 2 Business Units
        CreateSampleBusinessUnits(2);
        // [GIVEN] 6 GL Accounts
        CreateSampleGLAccounts(6);
        // [GIVEN] 2 Global Dimensions, with Dimension Values
        CreateSampleGlobalDimensionAndDimensionValues();
        Commit();
        // [WHEN] Running the report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Consolidated Trial Balance", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Consolidated Trial Balance", Variant, RequestPageXml);
        // [THEN] Only the GL Accounts should be exported
        Assert.AreEqual(6 + 2, LibraryReportDataset.RowCount(), 'Only GL Accounts and Business Units should be exported');
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="GLAccounts"]');
        Assert.AreEqual(6, LibraryReportDataset.RowCount(), 'Created GL Accounts should be exported');
    end;

    [Test]
    [HandlerFunctions('EXRTrialBalanceExcelHandler')]
    procedure TrialBalanceExportsOnlyTheUsedDimensionValues()
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        Variant: Variant;
        ReportValue, RequestPageXml : Text;
    begin
        // [SCENARIO] The report should only export the Dimension Values for which it has a total
        // [GIVEN] A trial balance for an entry with Global Dimension 2 value defined
        Initialize();
        CreateSampleGLAccounts(10, GLAccount);
        CreateSampleGlobalDimensionAndDimensionValues(Dimension, DimensionValue);
        CreateGLEntry(GLAccount."No.", DimensionValue.Code);
        Commit();
        // [WHEN] Running the report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Trial Balance Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Trial Balance Excel", Variant, RequestPageXml);
        // [THEN] All the GLAccounts should be exported
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="GLAccounts"]');
        Assert.AreEqual(10, LibraryReportDataset.RowCount(), 'Created GL Accounts should be exported');
        // [THEN] The only Dimension1 exported is the one of the entry (blank)
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="Dimension1"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be 1 "Global dimension 1" exported, the blank dimension');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('Dim1Code', Variant);
        ReportValue := Variant;
        Assert.AreEqual('', ReportValue, 'The exported dimension should be the blank dimension');
        // [THEN] The only Dimension2 exported is the one defined on the entry
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="Dimension2"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be 1 "Global dimension 2" exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('Dim2Code', Variant);
        ReportValue := Variant;
        Assert.AreEqual(DimensionValue.Code, ReportValue, 'The exported dimension should be the dimension in the GLEntry');
    end;

    [Test]
    [HandlerFunctions('EXRTrialBalanceBudgetExcelHandler')]
    procedure TrialBalanceBudgetExportsOnlyTheUsedDimensionValues()
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        Variant: Variant;
        ReportValue, RequestPageXml : Text;
    begin
        // [SCENARIO] The report should only export the Dimension Values for which it has a total
        // [GIVEN] A trial balance for an entry with Global Dimension 2 value defined
        Initialize();
        CreateSampleGLAccounts(10, GLAccount);
        CreateSampleGlobalDimensionAndDimensionValues(Dimension, DimensionValue);
        CreateGLEntry(GLAccount."No.", DimensionValue.Code);
        Commit();
        // [WHEN] Running the report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Trial BalanceBudgetExcel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Trial BalanceBudgetExcel", Variant, RequestPageXml);
        // [THEN] All the GLAccounts should be exported
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="GLAccounts"]');
        Assert.AreEqual(10, LibraryReportDataset.RowCount(), 'Created GL Accounts should be exported');
        // [THEN] The only Dimension1 exported is the one of the entry (blank)
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="Dimension1"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be 1 "Global dimension 1" exported, the blank dimension');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('Dim1Code', Variant);
        ReportValue := Variant;
        Assert.AreEqual('', ReportValue, 'The exported dimension should be the blank dimension');
        // [THEN] The only Dimension2 exported is the one defined on the entry
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="Dimension2"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be 1 "Global dimension 2" exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('Dim2Code', Variant);
        ReportValue := Variant;
        Assert.AreEqual(DimensionValue.Code, ReportValue, 'The exported dimension should be the dimension in the GLEntry');
    end;

    [Test]
    [HandlerFunctions('EXRConsolidatedTrialBalanceHandler')]
    procedure ConsolidatedTrialBalanceExportsOnlyTheUsedDimensionValues()
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        Variant: Variant;
        ReportValue, RequestPageXml : Text;
    begin
        // [SCENARIO] The report should only export the Dimension Values for which it has a total
        // [GIVEN] A trial balance for an entry with Global Dimension 2 value defined
        Initialize();
        CreateSampleGLAccounts(10, GLAccount);
        CreateSampleBusinessUnits(1);
        CreateSampleGlobalDimensionAndDimensionValues(Dimension, DimensionValue);
        CreateGLEntry(GLAccount."No.", DimensionValue.Code);
        Commit();
        // [WHEN] Running the report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Consolidated Trial Balance", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Consolidated Trial Balance", Variant, RequestPageXml);
        // [THEN] All the GLAccounts should be exported
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="GLAccounts"]');
        Assert.AreEqual(10, LibraryReportDataset.RowCount(), 'Created GL Accounts should be exported');
        // [THEN] The only Dimension1 exported is the one of the entry (blank)
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="Dimension1"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be 1 "Global dimension 1" exported, the blank dimension');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('Dim1Code', Variant);
        ReportValue := Variant;
        Assert.AreEqual('', ReportValue, 'The exported dimension should be the blank dimension');
        // [THEN] The only Dimension2 exported is the one defined on the entry
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="Dimension2"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'There should be 1 "Global dimension 2" exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('Dim2Code', Variant);
        ReportValue := Variant;
        Assert.AreEqual(DimensionValue.Code, ReportValue, 'The exported dimension should be the dimension in the GLEntry');
    end;

    [Test]
    [HandlerFunctions('EXRConsolidatedTrialBalanceHandler')]
    procedure ConsolidatedTrialBalanceShouldErrorWithNoBusinessUnits()
    var
        GLAccount: Record "G/L Account";
        Variant: Variant;
        RequestPageXml: Text;
    begin
        // [SCENARIO 544098] Running Consolidation Trial Balance should fail when there are no business units configured.
        // [GIVEN] A company without business units
        Initialize();
        CreateSampleGLAccounts(10, GLAccount);
        Commit();
        // [WHEN] Running the Consolidation Trial Balance report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Consolidated Trial Balance", RequestPageXml);
        // [THEN] It should fail and not produce a corrupt Excel file.
        asserterror LibraryReportDataset.RunReportAndLoad(Report::"EXR Consolidated Trial Balance", Variant, RequestPageXml);
    end;

    [Test]
    procedure QueryPathProducesCorrectAmounts()
    var
        GLAccount: Record "G/L Account";
        TempDimensionValue: Record "Dimension Value" temporary;
        TempTrialBalanceData: Record "EXR Trial Balance Buffer";
        TrialBalance: Codeunit "Trial Balance";
        PostingAccount: Code[20];
        BeforePeriodAmount: Decimal;
        InPeriodAmount: Decimal;
    begin
        // [SCENARIO] The query path computes correct Starting Balance, Net Change, and Balance for a posting account.
        // [GIVEN] A posting account with entries before and within the date range
        Initialize();
        CreateGLAccount(GLAccount);
        PostingAccount := GLAccount."No.";
        BeforePeriodAmount := 1000;
        InPeriodAmount := 250;
        CreateGLEntryWithAmount(PostingAccount, '', '', '', DMY2Date(15, 1, Date2DMY(WorkDate(), 3) - 1), BeforePeriodAmount);
        CreateGLEntryWithAmount(PostingAccount, '', '', '', DMY2Date(15, 6, Date2DMY(WorkDate(), 3)), InPeriodAmount);

        // [WHEN] Running the query-based trial balance for the current year
        GLAccount.SetRange("No.", PostingAccount);
        GLAccount.SetRange("Date Filter", DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), DMY2Date(31, 12, Date2DMY(WorkDate(), 3)));
        TrialBalance.ConfigureTrialBalance(false, false);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimensionValue, TempDimensionValue, TempTrialBalanceData);

        // [THEN] The buffer has correct amounts
        TempTrialBalanceData.SetRange("G/L Account No.", PostingAccount);
        Assert.IsTrue(TempTrialBalanceData.FindFirst(), 'Buffer record should exist for the posting account');
        Assert.AreEqual(BeforePeriodAmount, TempTrialBalanceData."Starting Balance", 'Starting Balance should equal the entry before the period');
        Assert.AreEqual(InPeriodAmount, TempTrialBalanceData."Net Change", 'Net Change should equal the entry within the period');
        Assert.AreEqual(BeforePeriodAmount + InPeriodAmount, TempTrialBalanceData.Balance, 'Balance should equal Starting Balance + Net Change');
    end;

    [Test]
    procedure GrossDebitAndCreditTurnoverReportedForEachAccount()
    var
        GLAccount: Record "G/L Account";
        TempDimensionValue: Record "Dimension Value" temporary;
        TempTrialBalanceData: Record "EXR Trial Balance Buffer";
        TrialBalance: Codeunit "Trial Balance";
        PostingAccount: Code[20];
        DebitAmount: Decimal;
        CreditAmount: Decimal;
    begin
        // [SCENARIO] The query path produces gross debit and credit turnover, not netted amounts.
        // [GIVEN] A posting account with both debit and credit entries in the same period
        Initialize();
        CreateGLAccount(GLAccount);
        PostingAccount := GLAccount."No.";
        DebitAmount := 5000;
        CreditAmount := -8000;
        CreateGLEntryWithAmount(PostingAccount, '', '', '', DMY2Date(1, 3, Date2DMY(WorkDate(), 3)), DebitAmount);
        CreateGLEntryWithAmount(PostingAccount, '', '', '', DMY2Date(15, 3, Date2DMY(WorkDate(), 3)), CreditAmount);

        // [WHEN] Running the query-based trial balance for the current year
        GLAccount.SetRange("No.", PostingAccount);
        GLAccount.SetRange("Date Filter", DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), DMY2Date(31, 12, Date2DMY(WorkDate(), 3)));
        TrialBalance.ConfigureTrialBalance(false, false);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimensionValue, TempDimensionValue, TempTrialBalanceData);

        // [THEN] The buffer has gross debit and credit amounts, not netted
        TempTrialBalanceData.SetRange("G/L Account No.", PostingAccount);
        Assert.IsTrue(TempTrialBalanceData.FindFirst(), 'Buffer record should exist for the posting account');
        Assert.AreEqual(DebitAmount + CreditAmount, TempTrialBalanceData."Net Change", 'Net Change should be the algebraic sum');
        Assert.AreEqual(DebitAmount, TempTrialBalanceData."Net Change (Debit)", 'Net Change (Debit) should be the gross debit amount');
        Assert.AreEqual(-CreditAmount, TempTrialBalanceData."Net Change (Credit)", 'Net Change (Credit) should be the gross credit amount');
    end;

    [Test]
    procedure QueryPathComputesEndTotalAndTotalAccounts()
    var
        PostingAccount1, PostingAccount2, EndTotalAccount, TotalAccount, GLAccount : Record "G/L Account";
        Dimension: Record Dimension;
        DimensionValue1, DimensionValue2 : Record "Dimension Value";
        TempDimension1Values, TempDimension2Values : Record "Dimension Value" temporary;
        TempTrialBalanceData: Record "EXR Trial Balance Buffer";
        TrialBalance: Codeunit "Trial Balance";
        Amount1Dim1, Amount2Dim1, Amount1Dim2 : Decimal;
    begin
        // [SCENARIO] End-Total and Total accounts aggregate per-dimension combination from their posting children.
        // [GIVEN] Two posting accounts, an End-Total, and a Total account in the same range, with entries across two dimension values
        Initialize();

        // Create the CoA: Posting1, Posting2, End-Total (totaling Posting1..Posting2), Total (same totaling)
        CreateGLAccount(PostingAccount1);
        CreateGLAccount(PostingAccount2);
        CreateGLAccount(EndTotalAccount, Enum::"G/L Account Type"::"End-Total", PostingAccount1."No." + '..' + PostingAccount2."No.");
        CreateGLAccount(TotalAccount, Enum::"G/L Account Type"::Total, PostingAccount1."No." + '..' + PostingAccount2."No.");

        // Create dimension values for Dim2
        LibraryERM.CreateDimension(Dimension);
        LibraryERM.CreateDimensionValue(DimensionValue1, Dimension.Code);
        DimensionValue1."Global Dimension No." := 2;
        DimensionValue1.Modify();
        LibraryERM.CreateDimensionValue(DimensionValue2, Dimension.Code);
        DimensionValue2."Global Dimension No." := 2;
        DimensionValue2.Modify();

        // Post entries: Account1 with Dim2=Value1, Account2 with Dim2=Value1, Account1 with Dim2=Value2
        Amount1Dim1 := 500;
        Amount2Dim1 := 300;
        Amount1Dim2 := 200;
        CreateGLEntryWithAmount(PostingAccount1."No.", '', DimensionValue1.Code, '', WorkDate(), Amount1Dim1);
        CreateGLEntryWithAmount(PostingAccount2."No.", '', DimensionValue1.Code, '', WorkDate(), Amount2Dim1);
        CreateGLEntryWithAmount(PostingAccount1."No.", '', DimensionValue2.Code, '', WorkDate(), Amount1Dim2);

        // [WHEN] Running the trial balance for the current year
        GLAccount.SetRange("Date Filter", DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), DMY2Date(31, 12, Date2DMY(WorkDate(), 3)));
        TrialBalance.ConfigureTrialBalance(false, false);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimension1Values, TempDimension2Values, TempTrialBalanceData);

        // [THEN] End-Total has per-dimension rows with correct sums
        TempTrialBalanceData.Reset();
        TempTrialBalanceData.SetRange("G/L Account No.", EndTotalAccount."No.");
        Assert.AreEqual(2, TempTrialBalanceData.Count(), 'End-Total should have 2 rows (one per Dim2 value)');

        TempTrialBalanceData.SetRange("Dimension 2 Code", DimensionValue1.Code);
        TempTrialBalanceData.FindFirst();
        Assert.AreEqual(Amount1Dim1 + Amount2Dim1, TempTrialBalanceData.Balance, 'End-Total Dim2=Value1 should sum both posting accounts');

        TempTrialBalanceData.SetRange("Dimension 2 Code", DimensionValue2.Code);
        TempTrialBalanceData.FindFirst();
        Assert.AreEqual(Amount1Dim2, TempTrialBalanceData.Balance, 'End-Total Dim2=Value2 should have only Account1 amount');

        // [THEN] Total account has identical per-dimension rows
        TempTrialBalanceData.Reset();
        TempTrialBalanceData.SetRange("G/L Account No.", TotalAccount."No.");
        Assert.AreEqual(2, TempTrialBalanceData.Count(), 'Total should have 2 rows (one per Dim2 value)');

        TempTrialBalanceData.SetRange("Dimension 2 Code", DimensionValue1.Code);
        TempTrialBalanceData.FindFirst();
        Assert.AreEqual(Amount1Dim1 + Amount2Dim1, TempTrialBalanceData.Balance, 'Total Dim2=Value1 should sum both posting accounts');
    end;

    [Test]
    procedure QueryPathPopulatesBudgetFields()
    var
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        TempDimension1Values, TempDimension2Values : Record "Dimension Value" temporary;
        TempTrialBalanceData: Record "EXR Trial Balance Buffer";
        TrialBalance: Codeunit "Trial Balance";
        PostingAccount: Code[20];
        EntryAmount, BudgetInPeriod, BudgetBeforePeriod : Decimal;
        PeriodStart, PeriodEnd : Date;
    begin
        // [SCENARIO] The query path populates Budget (Net) and Budget (Bal. at Date) fields.
        // [GIVEN] A posting account with GL entries and budget entries
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        PostingAccount := GLAccount."No.";
        PeriodStart := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
        PeriodEnd := DMY2Date(31, 12, Date2DMY(WorkDate(), 3));

        EntryAmount := 1000;
        CreateGLEntryWithAmount(PostingAccount, '', '', '', DMY2Date(15, 6, Date2DMY(WorkDate(), 3)), EntryAmount);

        LibraryERM.CreateGLBudgetName(GLBudgetName);
        BudgetBeforePeriod := 400;
        BudgetInPeriod := 600;
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, PeriodStart - 30, PostingAccount, GLBudgetName.Name);
        GLBudgetEntry.Validate(Amount, BudgetBeforePeriod);
        GLBudgetEntry.Modify();
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, DMY2Date(15, 6, Date2DMY(WorkDate(), 3)), PostingAccount, GLBudgetName.Name);
        GLBudgetEntry.Validate(Amount, BudgetInPeriod);
        GLBudgetEntry.Modify();

        // [WHEN] Running with budget data included
        GLAccount.SetRange("No.", PostingAccount);
        GLAccount.SetRange("Date Filter", PeriodStart, PeriodEnd);
        TrialBalance.ConfigureTrialBalance(false, true);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimension1Values, TempDimension2Values, TempTrialBalanceData);

        // [THEN] Budget fields are populated
        TempTrialBalanceData.SetRange("G/L Account No.", PostingAccount);
        Assert.IsTrue(TempTrialBalanceData.FindFirst(), 'Buffer record should exist');
        Assert.AreEqual(BudgetInPeriod, TempTrialBalanceData."Budget (Net)", 'Budget (Net) should be the budget entry within the period');
        Assert.AreEqual(BudgetBeforePeriod + BudgetInPeriod, TempTrialBalanceData."Budget (Bal. at Date)", 'Budget (Bal. at Date) should be cumulative up to period end');
    end;

    [Test]
    procedure ConsolidatedQueryPathBreaksDownByBusinessUnit()
    var
        GLAccount: Record "G/L Account";
        BusinessUnit1, BusinessUnit2 : Record "Business Unit";
        TempDimension1Values, TempDimension2Values : Record "Dimension Value" temporary;
        TempTrialBalanceData: Record "EXR Trial Balance Buffer";
        TrialBalance: Codeunit "Trial Balance";
        PostingAccount: Code[20];
        AmountBU1, AmountBU2 : Decimal;
    begin
        // [SCENARIO] The consolidated trial balance query path produces separate rows per Business Unit.
        // [GIVEN] A posting account with entries for two different Business Units
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        PostingAccount := GLAccount."No.";
        LibraryERM.CreateBusinessUnit(BusinessUnit1);
        LibraryERM.CreateBusinessUnit(BusinessUnit2);

        AmountBU1 := 750;
        AmountBU2 := 320;
        CreateGLEntryWithAmount(PostingAccount, '', '', BusinessUnit1.Code, WorkDate(), AmountBU1);
        CreateGLEntryWithAmount(PostingAccount, '', '', BusinessUnit2.Code, WorkDate(), AmountBU2);

        // [WHEN] Running with BU breakdown
        GLAccount.SetRange("No.", PostingAccount);
        GLAccount.SetRange("Date Filter", DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), DMY2Date(31, 12, Date2DMY(WorkDate(), 3)));
        TrialBalance.ConfigureTrialBalance(true, false);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimension1Values, TempDimension2Values, TempTrialBalanceData);

        // [THEN] Two buffer records exist, one per BU, with correct amounts
        TempTrialBalanceData.SetRange("G/L Account No.", PostingAccount);
        Assert.AreEqual(2, TempTrialBalanceData.Count(), 'Should have one row per Business Unit');

        TempTrialBalanceData.SetRange("Business Unit Code", BusinessUnit1.Code);
        TempTrialBalanceData.FindFirst();
        Assert.AreEqual(AmountBU1, TempTrialBalanceData.Balance, 'BU1 balance should match its entries');

        TempTrialBalanceData.SetRange("Business Unit Code", BusinessUnit2.Code);
        TempTrialBalanceData.FindFirst();
        Assert.AreEqual(AmountBU2, TempTrialBalanceData.Balance, 'BU2 balance should match its entries');
    end;

    [Test]
    procedure QueryPathRespectsAccountNoFilter()
    var
        GLAccount1, GLAccount2, GLAccount3, GLAccount : Record "G/L Account";
        TempDimension1Values, TempDimension2Values : Record "Dimension Value" temporary;
        TempTrialBalanceData: Record "EXR Trial Balance Buffer";
        TrialBalance: Codeunit "Trial Balance";
    begin
        // [SCENARIO] The query path only returns data for accounts matching the No. filter.
        // [GIVEN] Three accounts with entries, but the filter selects only one
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount1);
        LibraryERM.CreateGLAccount(GLAccount2);
        LibraryERM.CreateGLAccount(GLAccount3);
        CreateGLEntryWithAmount(GLAccount1."No.", '', '', '', WorkDate(), 100);
        CreateGLEntryWithAmount(GLAccount2."No.", '', '', '', WorkDate(), 200);
        CreateGLEntryWithAmount(GLAccount3."No.", '', '', '', WorkDate(), 300);

        // [WHEN] Running with a filter on the second account only
        GLAccount.SetRange("No.", GLAccount2."No.");
        GLAccount.SetRange("Date Filter", DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), DMY2Date(31, 12, Date2DMY(WorkDate(), 3)));
        TrialBalance.ConfigureTrialBalance(false, false);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimension1Values, TempDimension2Values, TempTrialBalanceData);

        // [THEN] Only the filtered account appears in the buffer
        Assert.AreEqual(1, TempTrialBalanceData.Count(), 'Only one account should be in the buffer');
        TempTrialBalanceData.FindFirst();
        Assert.AreEqual(GLAccount2."No.", TempTrialBalanceData."G/L Account No.", 'The filtered account should be the one returned');
        Assert.AreEqual(200, TempTrialBalanceData.Balance, 'Amount should match the filtered account entry');
    end;

    [Test]
    procedure QueryPathSkipsAllZeroRecords()
    var
        GLAccount: Record "G/L Account";
        TempDimension1Values, TempDimension2Values : Record "Dimension Value" temporary;
        TempTrialBalanceData: Record "EXR Trial Balance Buffer";
        TrialBalance: Codeunit "Trial Balance";
        ZeroAccount, NonZeroAccount : Code[20];
    begin
        // [SCENARIO] Accounts with entries that sum to zero are not included in the buffer.
        // [GIVEN] One account with cancelling entries (net zero) and another with a non-zero balance
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        ZeroAccount := GLAccount."No.";
        LibraryERM.CreateGLAccount(GLAccount);
        NonZeroAccount := GLAccount."No.";

        CreateGLEntryWithAmount(ZeroAccount, '', '', '', WorkDate(), 500);
        CreateGLEntryWithAmount(ZeroAccount, '', '', '', WorkDate(), -500);
        CreateGLEntryWithAmount(NonZeroAccount, '', '', '', WorkDate(), 100);

        // [WHEN] Running the trial balance
        GLAccount.SetFilter("No.", '%1|%2', ZeroAccount, NonZeroAccount);
        GLAccount.SetRange("Date Filter", DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), DMY2Date(31, 12, Date2DMY(WorkDate(), 3)));
        TrialBalance.ConfigureTrialBalance(false, false);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimension1Values, TempDimension2Values, TempTrialBalanceData);

        // [THEN] Only the non-zero account appears
        Assert.AreEqual(1, TempTrialBalanceData.Count(), 'Only the non-zero account should be in the buffer');
        TempTrialBalanceData.FindFirst();
        Assert.AreEqual(NonZeroAccount, TempTrialBalanceData."G/L Account No.", 'The non-zero account should be the one returned');
    end;

    [Test]
    procedure QueryPathStartingBalanceIncludesClosingDateEntries()
    var
        GLAccount: Record "G/L Account";
        TempDimensionValue: Record "Dimension Value" temporary;
        TempTrialBalanceData: Record "EXR Trial Balance Buffer";
        TrialBalance: Codeunit "Trial Balance";
        PostingAccount: Code[20];
        ActivityAmount: Decimal;
        PriorYear: Integer;
    begin
        // [SCENARIO] Starting Balance includes closing date entries from the prior fiscal year, emulating what "Close Income Statement" produces.
        // [GIVEN] A posting account with activity during the prior year
        Initialize();
        CreateGLAccount(GLAccount);
        PostingAccount := GLAccount."No.";
        PriorYear := Date2DMY(WorkDate(), 3) - 1;
        ActivityAmount := 5000;
        CreateGLEntryWithAmount(PostingAccount, '', '', '', DMY2Date(15, 6, PriorYear), ActivityAmount);
        // [GIVEN] A closing entry on ClosingDate(31/12) that zeroes out the account (emulates Close Income Statement)
        CreateGLEntryWithAmount(PostingAccount, '', '', '', ClosingDate(DMY2Date(31, 12, PriorYear)), -ActivityAmount);
        // [GIVEN] An entry on the first day of the current year so the old FindFirst logic derives cutoff ..31/12 (normal date), which misses C31/12
        CreateGLEntryWithAmount(PostingAccount, '', '', '', DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), 100);

        // [WHEN] Running the trial balance for the current year
        GLAccount.SetRange("No.", PostingAccount);
        GLAccount.SetRange("Date Filter", DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), DMY2Date(31, 12, Date2DMY(WorkDate(), 3)));
        TrialBalance.ConfigureTrialBalance(false, false);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimensionValue, TempDimensionValue, TempTrialBalanceData);

        // [THEN] Starting Balance is zero because the closing entry zeroed out the account
        TempTrialBalanceData.SetRange("G/L Account No.", PostingAccount);
        TempTrialBalanceData.FindFirst();
        Assert.AreEqual(0, TempTrialBalanceData."Starting Balance", 'Starting Balance should be zero after closing entries')
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccPayableExcelHandler')]
    procedure AgedAccountsPayableExportsDocumentTypeAndNo()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        ReportDocumentType: Text;
        ReportDocumentNo: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 622247] Aged Accounts Payable Excel report exports Document Type and Document No fields correctly for Invoice entries
        InitializeAgingData();

        // [GIVEN] Vendor "V" with an open vendor ledger entry of type Invoice
        // Create vendor directly to avoid VAT posting setup requirements in some localizations
        CreateMinimalVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", "Gen. Journal Document Type"::Invoice);
        Commit();

        // [WHEN] Running the Aged Accounts Payable Excel report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Acc Payable Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Acc Payable Excel", Variant, RequestPageXml);

        // [THEN] The exported data contains the Document Type "Invoice" and the correct Document No
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'One aging entry should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('DocumentType', Variant);
        ReportDocumentType := Variant;
        Assert.AreEqual(Format("Gen. Journal Document Type"::Invoice), ReportDocumentType, DocumentTypeShouldBeInvoiceErr);
        LibraryReportDataset.FindCurrentRowValue('DocumentNo', Variant);
        ReportDocumentNo := Variant;
        Assert.AreEqual(VendorLedgerEntry."Document No.", ReportDocumentNo, DocumentNoShouldMatchErr);
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccountsRecExcelHandler')]
    procedure AgedAccountsRecExportsDocumentTypeAndNo()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        ReportDocumentType: Text;
        ReportDocumentNo: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 622247] Aged Accounts Receivable Excel report exports Document Type and Document No fields correctly for Invoice entries
        InitializeAgingData();

        // [GIVEN] Customer "C" with an open customer ledger entry of type Invoice
        // Create customer directly to avoid VAT posting setup requirements in some localizations
        CreateMinimalCustomer(Customer);
        CreateCustLedgerEntry(CustLedgerEntry, Customer."No.", "Gen. Journal Document Type"::Invoice);
        Commit();

        // [WHEN] Running the Aged Accounts Receivable Excel report
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Accounts Rec Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Accounts Rec Excel", Variant, RequestPageXml);

        // [THEN] The exported data contains the Document Type "Invoice" and the correct Document No
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'One aging entry should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('DocumentType', Variant);
        ReportDocumentType := Variant;
        Assert.AreEqual(Format("Gen. Journal Document Type"::Invoice), ReportDocumentType, DocumentTypeShouldBeInvoiceErr);
        LibraryReportDataset.FindCurrentRowValue('DocumentNo', Variant);
        ReportDocumentNo := Variant;
        Assert.AreEqual(CustLedgerEntry."Document No.", ReportDocumentNo, DocumentNoShouldMatchErr);
    end;

    [Test]
    [HandlerFunctions('EXRAgedAccPayablePostingDateHandler')]
    procedure AgedAccountsPayableReportAgesByPostingDate()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Variant: Variant;
        RequestPageXml: Text;
        ReportingDateText: Text;
        ReportingDate: Date;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Aged Accounts Payable report uses Posting Date as Reporting Date when aging by Posting Date
        InitializeAgingData();

        // [GIVEN] Vendor "V" with an open ledger entry where Posting Date, Document Date, and Due Date are distinct
        CreateMinimalVendor(Vendor);
        CreateVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", "Gen. Journal Document Type"::Invoice);
        VendorLedgerEntry."Document Date" := WorkDate() - 10;
        VendorLedgerEntry.Modify();
        Commit();

        // [WHEN] Running the Aged Accounts Payable Excel report with Aging By = Posting Date
        RequestPageXml := Report.RunRequestPage(Report::"EXR Aged Acc Payable Excel", RequestPageXml);
        LibraryReportDataset.RunReportAndLoad(Report::"EXR Aged Acc Payable Excel", Variant, RequestPageXml);

        // [THEN] The Reporting Date matches the Posting Date of the vendor ledger entry
        LibraryReportDataset.SetXmlNodeList('DataItem[@name="AgingData"]');
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'One aging entry should be exported');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('ReportingDate', Variant);
        ReportingDateText := Variant;
        Evaluate(ReportingDate, ReportingDateText);
        Assert.AreEqual(VendorLedgerEntry."Posting Date", ReportingDate, 'Reporting Date should match the Posting Date when aging by Posting Date');
    end;

    local procedure CreateSampleBusinessUnits(HowMany: Integer)
    var
        BusinessUnit: Record "Business Unit";
    begin
        CreateSampleBusinessUnits(HowMany, BusinessUnit);
    end;

    local procedure CreateSampleBusinessUnits(HowMany: Integer; var BusinessUnit: Record "Business Unit")
    var
        i: Integer;
    begin
        for i := 1 to HowMany do
            LibraryERM.CreateBusinessUnit(BusinessUnit);
    end;

    local procedure CreateSampleGLAccounts(HowMany: Integer)
    var
        GLAccount: Record "G/L Account";
    begin
        CreateSampleGLAccounts(HowMany, GLAccount);
    end;

    local procedure CreateSampleGLAccounts(HowMany: Integer; var GLAccount: Record "G/L Account")
    var
        i: Integer;
    begin
        for i := 1 to HowMany do
            CreateGLAccount(GLAccount);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    begin
        CreateGLAccount(GLAccount, Enum::"G/L Account Type"::Posting, '');
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; AccountType: Enum "G/L Account Type"; Totaling: Text)
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Account Type" := AccountType;
        GLAccount.Totaling := CopyStr(Totaling, 1, 250);
        GLAccount.Modify();
    end;

    local procedure Initialize()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLBudgetName: Record "G/L Budget Name";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        BusinessUnit: Record "Business Unit";
    begin
        DimensionValue.DeleteAll();
        Dimension.DeleteAll();
        GLAccount.DeleteAll();
        BusinessUnit.DeleteAll();
        GLEntry.DeleteAll();
        GLBudgetEntry.DeleteAll();
        GLBudgetName.DeleteAll();
        if BindSubscription(this) then;
    end;

    local procedure CreateSampleGlobalDimensionAndDimensionValues()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        CreateSampleGlobalDimensionAndDimensionValues(Dimension, DimensionValue);
    end;

    local procedure CreateSampleGlobalDimensionAndDimensionValues(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value")
    begin
        LibraryERM.CreateDimension(Dimension);
        LibraryERM.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValue."Global Dimension No." := 1;
        DimensionValue.Modify();
        LibraryERM.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValue."Global Dimension No." := 1;
        DimensionValue.Modify();
        LibraryERM.CreateDimension(Dimension);
        LibraryERM.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValue."Global Dimension No." := 2;
        DimensionValue.Modify();
        LibraryERM.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValue."Global Dimension No." := 2;
        DimensionValue.Modify();
        LibraryERM.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValue."Global Dimension No." := 2;
        DimensionValue.Modify();
    end;

    local procedure CreateGLEntry(GLAccountNo: Code[20]; DimensionValue2Code: Code[20])
    begin
        CreateGLEntryWithAmount(GLAccountNo, '', DimensionValue2Code, '', WorkDate(), 1337);
    end;

    local procedure CreateGLEntryWithAmount(GLAccountNo: Code[20]; Dim1Code: Code[20]; Dim2Code: Code[20]; BusinessUnitCode: Code[20]; PostingDate: Date; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        EntryNo: Integer;
    begin
        if GLEntry.FindLast() then;
        EntryNo := GLEntry."Entry No." + 1;
        Clear(GLEntry);
        GLEntry."Entry No." := EntryNo;
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Global Dimension 1 Code" := Dim1Code;
        GLEntry."Global Dimension 2 Code" := Dim2Code;
        GLEntry."Business Unit Code" := BusinessUnitCode;
        GLEntry.Amount := Amount;
        GLEntry."Additional-Currency Amount" := Amount;
        if Amount > 0 then begin
            GLEntry."Debit Amount" := Amount;
            GLEntry."Add.-Currency Debit Amount" := Amount;
        end else begin
            GLEntry."Credit Amount" := -Amount;
            GLEntry."Add.-Currency Credit Amount" := -Amount;
        end;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Insert();
    end;

    local procedure InitializeAgingData()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedVendorLedgEntry.DeleteAll();
        DetailedCustLedgEntry.DeleteAll();
        VendorLedgerEntry.DeleteAll();
        CustLedgerEntry.DeleteAll();
        Vendor.DeleteAll();
        Customer.DeleteAll();
    end;

    local procedure CreateMinimalVendor(var Vendor: Record Vendor)
    begin
        Vendor.Init();
        Vendor."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Vendor."No."));
        Vendor.Name := Vendor."No.";
        Vendor.Insert();
    end;

    local procedure CreateMinimalCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Customer."No."));
        Customer.Name := Customer."No.";
        Customer.Insert();
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        EntryNo: Integer;
        Amount: Decimal;
    begin
        if VendorLedgerEntry.FindLast() then;
        EntryNo := VendorLedgerEntry."Entry No." + 1;

        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := EntryNo;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Vendor Name" := VendorNo;
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Document No." := 'DOC' + Format(EntryNo);
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Document Date" := WorkDate();
        VendorLedgerEntry."Due Date" := WorkDate() + 30;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();

        // Create detailed vendor ledger entry for remaining amount
        Amount := -LibraryRandom.RandDec(1000, 2);
        if DetailedVendorLedgEntry.FindLast() then;
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry."Entry No." + 1;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry."Posting Date" := WorkDate();
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Initial Entry";
        DetailedVendorLedgEntry.Amount := Amount;
        DetailedVendorLedgEntry."Amount (LCY)" := Amount;
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure CreateCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EntryNo: Integer;
        Amount: Decimal;
    begin
        if CustLedgerEntry.FindLast() then;
        EntryNo := CustLedgerEntry."Entry No." + 1;

        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := EntryNo;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Customer Name" := CustomerNo;
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := 'DOC' + Format(EntryNo);
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Document Date" := WorkDate();
        CustLedgerEntry."Due Date" := WorkDate() + 30;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();

        // Create detailed customer ledger entry for remaining amount
        Amount := LibraryRandom.RandDec(1000, 2);
        if DetailedCustLedgEntry.FindLast() then;
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := DetailedCustLedgEntry."Entry No." + 1;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Initial Entry";
        DetailedCustLedgEntry.Amount := Amount;
        DetailedCustLedgEntry."Amount (LCY)" := Amount;
        DetailedCustLedgEntry.Insert();
    end;

    [RequestPageHandler]
    procedure EXRTrialBalanceExcelHandler(var EXRTrialBalanceExcel: TestRequestPage "EXR Trial Balance Excel")
    begin
        EXRTrialBalanceExcel.GLAccounts.SetFilter("Date Filter", Format(DMY2Date(1, 1, Date2DMY(WorkDate(), 3))) + '..' + Format(DMY2Date(31, 12, Date2DMY(WorkDate(), 3))));
        EXRTrialBalanceExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRTrialBalanceHideNoActivityHandler(var EXRTrialBalanceExcel: TestRequestPage "EXR Trial Balance Excel")
    begin
        EXRTrialBalanceExcel.GLAccounts.SetFilter("Date Filter", Format(DMY2Date(1, 1, Date2DMY(WorkDate(), 3))) + '..' + Format(DMY2Date(31, 12, Date2DMY(WorkDate(), 3))));
        EXRTrialBalanceExcel.HideAccountsWithNoActivityField.SetValue(true);
        EXRTrialBalanceExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRTrialBalanceBudgetExcelHandler(var EXRTrialBalanceBudgetExcel: TestRequestPage "EXR Trial BalanceBudgetExcel")
    begin
        EXRTrialBalanceBudgetExcel.GLAccounts.SetFilter("Date Filter", Format(DMY2Date(1, 1, Date2DMY(WorkDate(), 3))) + '..' + Format(DMY2Date(31, 12, Date2DMY(WorkDate(), 3))));
        EXRTrialBalanceBudgetExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRConsolidatedTrialBalanceHandler(var EXRConsolidatedTrialBalance: TestRequestPage "EXR Consolidated Trial Balance")
    begin
        EXRConsolidatedTrialBalance.EndingDateField.Value := Format(DMY2Date(31, 12, WorkDate().Year));
        EXRConsolidatedTrialBalance.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccPayableExcelHandler(var EXRAgedAccPayableExcel: TestRequestPage "EXR Aged Acc Payable Excel")
    begin
        EXRAgedAccPayableExcel.AgedAsOfOption.SetValue(WorkDate());
        EXRAgedAccPayableExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccountsRecExcelHandler(var EXRAgedAccountsRecExcel: TestRequestPage "EXR Aged Accounts Rec Excel")
    begin
        EXRAgedAccountsRecExcel.AgedAsOfOption.SetValue(WorkDate());
        EXRAgedAccountsRecExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRAgedAccPayablePostingDateHandler(var EXRAgedAccPayableExcel: TestRequestPage "EXR Aged Acc Payable Excel")
    begin
        EXRAgedAccPayableExcel.AgedAsOfOption.SetValue(WorkDate());
        EXRAgedAccPayableExcel.AgingbyOption.SetValue('Posting Date');
        EXRAgedAccPayableExcel.OK().Invoke();
    end;

#if not CLEAN27
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Trial Balance", OnIsPerformantTrialBalanceFeatureActive, '', false, false)]
    local procedure OnIsPerformantTrialBalanceFeatureActive(var Active: Boolean)
    begin
        Active := true;
    end;
#pragma warning restore AL0432
#endif

}
