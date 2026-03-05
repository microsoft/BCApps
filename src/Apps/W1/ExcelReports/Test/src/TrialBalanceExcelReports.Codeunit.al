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
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 139544 "Trial Balance Excel Reports"
{
    Subtype = Test;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;

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
    procedure TrialBalanceBufferNetChangeSplitsIntoDebitAndCreditWhenCalledSeveralTimes()
    var
        EXRTrialBalanceBuffer: Record "EXR Trial Balance Buffer";
        ValuesToSplitInCreditAndDebit: array[3] of Decimal;
    begin
        // [SCENARIO 547558] Trial Balance Buffer data split into Debit and Credit correctly, even if called multiple times.
        // [GIVEN] Trial Balance Buffer filled with positive Balance/Net Change
        ValuesToSplitInCreditAndDebit[1] := 837;
        // [GIVEN] Trial Balance Buffer filled with negative Balance/Net Change
        ValuesToSplitInCreditAndDebit[2] := -110;
        // [GIVEN] Trial Balance Buffer filled with positive Balance/Net Change
        ValuesToSplitInCreditAndDebit[3] := 998;
        // [WHEN] Trial Balance Buffer entries are inserted
        EXRTrialBalanceBuffer."G/L Account No." := 'A';
        EXRTrialBalanceBuffer.Validate("Starting Balance", ValuesToSplitInCreditAndDebit[1]);
        EXRTrialBalanceBuffer.Validate("Net Change", ValuesToSplitInCreditAndDebit[1]);
        EXRTrialBalanceBuffer.Validate(Balance, ValuesToSplitInCreditAndDebit[1]);
        EXRTrialBalanceBuffer.Validate("Starting Balance (ACY)", ValuesToSplitInCreditAndDebit[1]);
        EXRTrialBalanceBuffer.Validate("Net Change (ACY)", ValuesToSplitInCreditAndDebit[1]);
        EXRTrialBalanceBuffer.Validate("Balance (ACY)", ValuesToSplitInCreditAndDebit[1]);
        EXRTrialBalanceBuffer.Insert();
        EXRTrialBalanceBuffer."G/L Account No." := 'B';
        EXRTrialBalanceBuffer.Validate("Starting Balance", ValuesToSplitInCreditAndDebit[2]);
        EXRTrialBalanceBuffer.Validate("Net Change", ValuesToSplitInCreditAndDebit[2]);
        EXRTrialBalanceBuffer.Validate(Balance, ValuesToSplitInCreditAndDebit[2]);
        EXRTrialBalanceBuffer.Validate("Starting Balance (ACY)", ValuesToSplitInCreditAndDebit[2]);
        EXRTrialBalanceBuffer.Validate("Net Change (ACY)", ValuesToSplitInCreditAndDebit[2]);
        EXRTrialBalanceBuffer.Validate("Balance (ACY)", ValuesToSplitInCreditAndDebit[2]);
        EXRTrialBalanceBuffer.Insert();
        EXRTrialBalanceBuffer."G/L Account No." := 'C';
        EXRTrialBalanceBuffer.Validate("Starting Balance", ValuesToSplitInCreditAndDebit[3]);
        EXRTrialBalanceBuffer.Validate("Net Change", ValuesToSplitInCreditAndDebit[3]);
        EXRTrialBalanceBuffer.Validate(Balance, ValuesToSplitInCreditAndDebit[3]);
        EXRTrialBalanceBuffer.Validate("Starting Balance (ACY)", ValuesToSplitInCreditAndDebit[3]);
        EXRTrialBalanceBuffer.Validate("Net Change (ACY)", ValuesToSplitInCreditAndDebit[3]);
        EXRTrialBalanceBuffer.Validate("Balance (ACY)", ValuesToSplitInCreditAndDebit[3]);
        EXRTrialBalanceBuffer.Insert();
        // [THEN] All Entries have the right split in Credit and Debit
        EXRTrialBalanceBuffer.FindSet();
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[1], Abs(EXRTrialBalanceBuffer."Starting Balance (Debit)" + EXRTrialBalanceBuffer."Starting Balance (Credit)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[1], Abs(EXRTrialBalanceBuffer."Net Change (Debit)" + EXRTrialBalanceBuffer."Net Change (Credit)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[1], Abs(EXRTrialBalanceBuffer."Balance (Debit)" + EXRTrialBalanceBuffer."Balance (Credit)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[1], Abs(EXRTrialBalanceBuffer."Starting Balance (Debit) (ACY)" + EXRTrialBalanceBuffer."Starting Balance (Credit)(ACY)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[1], Abs(EXRTrialBalanceBuffer."Net Change (Debit) (ACY)" + EXRTrialBalanceBuffer."Net Change (Credit) (ACY)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[1], Abs(EXRTrialBalanceBuffer."Balance (Debit) (ACY)" + EXRTrialBalanceBuffer."Balance (Credit) (ACY)"), 'Split in line in credit and debit should be the same as the inserted value.');
        EXRTrialBalanceBuffer.Next();
        Assert.AreEqual(-ValuesToSplitInCreditAndDebit[2], Abs(EXRTrialBalanceBuffer."Starting Balance (Debit)" + EXRTrialBalanceBuffer."Starting Balance (Credit)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(-ValuesToSplitInCreditAndDebit[2], Abs(EXRTrialBalanceBuffer."Net Change (Debit)" + EXRTrialBalanceBuffer."Net Change (Credit)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(-ValuesToSplitInCreditAndDebit[2], Abs(EXRTrialBalanceBuffer."Balance (Debit)" + EXRTrialBalanceBuffer."Balance (Credit)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(-ValuesToSplitInCreditAndDebit[2], Abs(EXRTrialBalanceBuffer."Starting Balance (Debit) (ACY)" + EXRTrialBalanceBuffer."Starting Balance (Credit)(ACY)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(-ValuesToSplitInCreditAndDebit[2], Abs(EXRTrialBalanceBuffer."Net Change (Debit) (ACY)" + EXRTrialBalanceBuffer."Net Change (Credit) (ACY)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(-ValuesToSplitInCreditAndDebit[2], Abs(EXRTrialBalanceBuffer."Balance (Debit) (ACY)" + EXRTrialBalanceBuffer."Balance (Credit) (ACY)"), 'Split in line in credit and debit should be the same as the inserted value.');
        EXRTrialBalanceBuffer.Next();
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[3], Abs(EXRTrialBalanceBuffer."Starting Balance (Debit)" + EXRTrialBalanceBuffer."Starting Balance (Credit)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[3], Abs(EXRTrialBalanceBuffer."Net Change (Debit)" + EXRTrialBalanceBuffer."Net Change (Credit)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[3], Abs(EXRTrialBalanceBuffer."Balance (Debit)" + EXRTrialBalanceBuffer."Balance (Credit)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[3], Abs(EXRTrialBalanceBuffer."Starting Balance (Debit) (ACY)" + EXRTrialBalanceBuffer."Starting Balance (Credit)(ACY)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[3], Abs(EXRTrialBalanceBuffer."Net Change (Debit) (ACY)" + EXRTrialBalanceBuffer."Net Change (Credit) (ACY)"), 'Split in line in credit and debit should be the same as the inserted value.');
        Assert.AreEqual(ValuesToSplitInCreditAndDebit[3], Abs(EXRTrialBalanceBuffer."Balance (Debit) (ACY)" + EXRTrialBalanceBuffer."Balance (Credit) (ACY)"), 'Split in line in credit and debit should be the same as the inserted value.');
    end;

    [Test]
    procedure QueryPathProducesCorrectAmounts()
    var
        GLAccount: Record "G/L Account";
        TempDimensionValue: Record "Dimension Value" temporary;
        TrialBalanceData: Record "EXR Trial Balance Buffer";
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
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimensionValue, TempDimensionValue, TrialBalanceData);

        // [THEN] The buffer has correct amounts
        TrialBalanceData.SetRange("G/L Account No.", PostingAccount);
        Assert.IsTrue(TrialBalanceData.FindFirst(), 'Buffer record should exist for the posting account');
        Assert.AreEqual(BeforePeriodAmount, TrialBalanceData."Starting Balance", 'Starting Balance should equal the entry before the period');
        Assert.AreEqual(InPeriodAmount, TrialBalanceData."Net Change", 'Net Change should equal the entry within the period');
        Assert.AreEqual(BeforePeriodAmount + InPeriodAmount, TrialBalanceData.Balance, 'Balance should equal Starting Balance + Net Change');
    end;

    [Test]
    procedure QueryPathComputesEndTotalAndTotalAccounts()
    var
        PostingAccount1, PostingAccount2, EndTotalAccount, TotalAccount, GLAccount : Record "G/L Account";
        Dimension: Record Dimension;
        DimensionValue1, DimensionValue2 : Record "Dimension Value";
        TempDimension1Values, TempDimension2Values : Record "Dimension Value" temporary;
        TrialBalanceData: Record "EXR Trial Balance Buffer";
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
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimension1Values, TempDimension2Values, TrialBalanceData);

        // [THEN] End-Total has per-dimension rows with correct sums
        TrialBalanceData.Reset();
        TrialBalanceData.SetRange("G/L Account No.", EndTotalAccount."No.");
        Assert.AreEqual(2, TrialBalanceData.Count(), 'End-Total should have 2 rows (one per Dim2 value)');

        TrialBalanceData.SetRange("Dimension 2 Code", DimensionValue1.Code);
        TrialBalanceData.FindFirst();
        Assert.AreEqual(Amount1Dim1 + Amount2Dim1, TrialBalanceData.Balance, 'End-Total Dim2=Value1 should sum both posting accounts');

        TrialBalanceData.SetRange("Dimension 2 Code", DimensionValue2.Code);
        TrialBalanceData.FindFirst();
        Assert.AreEqual(Amount1Dim2, TrialBalanceData.Balance, 'End-Total Dim2=Value2 should have only Account1 amount');

        // [THEN] Total account has identical per-dimension rows
        TrialBalanceData.Reset();
        TrialBalanceData.SetRange("G/L Account No.", TotalAccount."No.");
        Assert.AreEqual(2, TrialBalanceData.Count(), 'Total should have 2 rows (one per Dim2 value)');

        TrialBalanceData.SetRange("Dimension 2 Code", DimensionValue1.Code);
        TrialBalanceData.FindFirst();
        Assert.AreEqual(Amount1Dim1 + Amount2Dim1, TrialBalanceData.Balance, 'Total Dim2=Value1 should sum both posting accounts');
    end;

    [Test]
    procedure QueryPathPopulatesBudgetFields()
    var
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        TempDimension1Values, TempDimension2Values : Record "Dimension Value" temporary;
        TrialBalanceData: Record "EXR Trial Balance Buffer";
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
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimension1Values, TempDimension2Values, TrialBalanceData);

        // [THEN] Budget fields are populated
        TrialBalanceData.SetRange("G/L Account No.", PostingAccount);
        Assert.IsTrue(TrialBalanceData.FindFirst(), 'Buffer record should exist');
        Assert.AreEqual(BudgetInPeriod, TrialBalanceData."Budget (Net)", 'Budget (Net) should be the budget entry within the period');
        Assert.AreEqual(BudgetBeforePeriod + BudgetInPeriod, TrialBalanceData."Budget (Bal. at Date)", 'Budget (Bal. at Date) should be cumulative up to period end');
    end;

    [Test]
    procedure ConsolidatedQueryPathBreaksDownByBusinessUnit()
    var
        GLAccount: Record "G/L Account";
        BusinessUnit1, BusinessUnit2 : Record "Business Unit";
        TempDimension1Values, TempDimension2Values : Record "Dimension Value" temporary;
        TrialBalanceData: Record "EXR Trial Balance Buffer";
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
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimension1Values, TempDimension2Values, TrialBalanceData);

        // [THEN] Two buffer records exist, one per BU, with correct amounts
        TrialBalanceData.SetRange("G/L Account No.", PostingAccount);
        Assert.AreEqual(2, TrialBalanceData.Count(), 'Should have one row per Business Unit');

        TrialBalanceData.SetRange("Business Unit Code", BusinessUnit1.Code);
        TrialBalanceData.FindFirst();
        Assert.AreEqual(AmountBU1, TrialBalanceData.Balance, 'BU1 balance should match its entries');

        TrialBalanceData.SetRange("Business Unit Code", BusinessUnit2.Code);
        TrialBalanceData.FindFirst();
        Assert.AreEqual(AmountBU2, TrialBalanceData.Balance, 'BU2 balance should match its entries');
    end;

    [Test]
    procedure QueryPathRespectsAccountNoFilter()
    var
        GLAccount1, GLAccount2, GLAccount3, GLAccount : Record "G/L Account";
        TempDimension1Values, TempDimension2Values : Record "Dimension Value" temporary;
        TrialBalanceData: Record "EXR Trial Balance Buffer";
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
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimension1Values, TempDimension2Values, TrialBalanceData);

        // [THEN] Only the filtered account appears in the buffer
        Assert.AreEqual(1, TrialBalanceData.Count(), 'Only one account should be in the buffer');
        TrialBalanceData.FindFirst();
        Assert.AreEqual(GLAccount2."No.", TrialBalanceData."G/L Account No.", 'The filtered account should be the one returned');
        Assert.AreEqual(200, TrialBalanceData.Balance, 'Amount should match the filtered account entry');
    end;

    [Test]
    procedure QueryPathSkipsAllZeroRecords()
    var
        GLAccount: Record "G/L Account";
        TempDimension1Values, TempDimension2Values : Record "Dimension Value" temporary;
        TrialBalanceData: Record "EXR Trial Balance Buffer";
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
        TrialBalance.InsertTrialBalanceReportData(GLAccount, TempDimension1Values, TempDimension2Values, TrialBalanceData);

        // [THEN] Only the non-zero account appears
        Assert.AreEqual(1, TrialBalanceData.Count(), 'Only the non-zero account should be in the buffer');
        TrialBalanceData.FindFirst();
        Assert.AreEqual(NonZeroAccount, TrialBalanceData."G/L Account No.", 'The non-zero account should be the one returned');
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
        if Amount > 0 then
            GLEntry."Debit Amount" := Amount
        else
            GLEntry."Credit Amount" := -Amount;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Insert();
    end;

    [RequestPageHandler]
    procedure EXRTrialBalanceExcelHandler(var EXRTrialBalanceExcel: TestRequestPage "EXR Trial Balance Excel")
    begin
        EXRTrialBalanceExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRTrialBalanceBudgetExcelHandler(var EXRTrialBalanceBudgetExcel: TestRequestPage "EXR Trial BalanceBudgetExcel")
    begin
        EXRTrialBalanceBudgetExcel.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure EXRConsolidatedTrialBalanceHandler(var EXRConsolidatedTrialBalance: TestRequestPage "EXR Consolidated Trial Balance")
    begin
        EXRConsolidatedTrialBalance.EndingDateField.Value := Format(DMY2Date(31, 12, WorkDate().Year));
        EXRConsolidatedTrialBalance.OK().Invoke();
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
