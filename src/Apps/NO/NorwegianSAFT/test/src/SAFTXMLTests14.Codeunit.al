// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport.Test;

using Microsoft.Finance.AuditFileExport;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.IO;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 148111 "SAF-T XML Tests 1.4"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SAFTTestHelper: Codeunit "SAF-T Test Helper";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        GenerateSAFTFileImmediatelyQst: Label 'Since you did not schedule the SAF-T file generation, it will be generated immediately which can take a while. Do you want to continue?';
        TaxInformationXPathLbl: Label '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:TaxInformation', Locked = true;
        Mapping13NotDoneErr: Label 'One or more G/L accounts do not have a mapping setup. Open the SAF-T Mapping Setup page for the selected mapping range and map each G/L account either to the category code and mapping number.';

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ZeroNetChangeAccountExportsWithUnusedAccountWithoutCategory()
    begin
        // [SCENARIO] Offsetting entries are exported while an unused account without a category does not block SAF-T 1.4.
        VerifyZeroNetChangeAccountExport(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ZeroNetChangeAccountExportsWithUnusedAccountWithoutMappingNo()
    begin
        // [SCENARIO] An unused account with a category but no mapping number does not block SAF-T 1.4.
        VerifyZeroNetChangeAccountExport(false);
    end;

    [Test]
    [HandlerFunctions('MappingErrorPageHandler')]
    procedure ZeroNetChangeAccountWithoutCategoryBlocksExport()
    begin
        // [SCENARIO] An account with offsetting entries still requires a category for SAF-T 1.4.
        VerifyZeroNetChangeAccountMappingError(true);
    end;

    [Test]
    [HandlerFunctions('MappingErrorPageHandler')]
    procedure ZeroNetChangeAccountWithoutMappingNoBlocksExport()
    begin
        // [SCENARIO] An account with offsetting entries still requires a mapping number for SAF-T 1.4.
        VerifyZeroNetChangeAccountMappingError(false);
    end;

    [Test]
    procedure MappingEntryExistenceRespectsDateFilters()
    begin
        // [SCENARIO] Mapping preparation and refresh use the same account-type, incoming-balance and closing-date filters.
        Initialize();
        VerifyMappingEntryExistence(true, false, 20241231D, false);
        VerifyMappingEntryExistence(true, true, 20241231D, false);
        VerifyMappingEntryExistence(false, false, 20241231D, false);
        VerifyMappingEntryExistence(false, true, 20241231D, true);
        VerifyMappingEntryExistence(true, false, 20250101D, true);
        VerifyMappingEntryExistence(false, true, 20250101D, true);
        VerifyMappingEntryExistence(true, true, 20251231D, true);
        VerifyMappingEntryExistence(false, false, 20251231D, true);
        VerifyMappingEntryExistence(true, false, ClosingDate(20251231D), false);
        VerifyMappingEntryExistence(true, true, ClosingDate(20251231D), false);
        VerifyMappingEntryExistence(false, false, ClosingDate(20251231D), false);
        VerifyMappingEntryExistence(false, true, ClosingDate(20251231D), true);
        VerifyMappingEntryExistence(true, true, 20260101D, false);
        VerifyMappingEntryExistence(false, true, 20260101D, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure CustomerCurrencyAmountsUseLCYPerFCYExchangeRate()
    begin
        // [SCENARIO 659500] Customer currency amounts use LCY per FCY for both the receivables and balancing lines.

        // [GIVEN] SAF-T is initialized and immediate file generation will be confirmed.
        Initialize();
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);

        // [WHEN] The helper creates and exports a customer foreign-currency transaction.
        // [THEN] The helper verifies 1,000 FCY and an exchange rate of 8 LCY per FCY on both transaction lines.
        SAFTTestHelper.VerifyCustomerVendorCurrencyAmounts(Enum::"SAF-T Version"::"1.40", true);

        // [THEN] All expected confirmation prompts have been handled.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure VendorCurrencyAmountsUseLCYPerFCYExchangeRate()
    begin
        // [SCENARIO 659500] Vendor currency amounts use LCY per FCY for both the payables and balancing lines.

        // [GIVEN] SAF-T is initialized and immediate file generation will be confirmed.
        Initialize();
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);

        // [WHEN] The helper creates and exports a vendor foreign-currency transaction.
        // [THEN] The helper verifies 1,000 FCY and an exchange rate of 8 LCY per FCY on both transaction lines.
        SAFTTestHelper.VerifyCustomerVendorCurrencyAmounts(Enum::"SAF-T Version"::"1.40", false);

        // [THEN] All expected confirmation prompts have been handled.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DebitCurrencyAmountsUseLongMonetaryPrecision()
    begin
        // [SCENARIO] Debit CurrencyAmount and ExchangeRate retain 18 decimal places, including calculated currency amounts.
        // [GIVEN] Debit entries with stored and calculated foreign-currency amounts and an exchange rate with 18 decimal places.
        // [WHEN] The entries are exported to SAF-T 1.4.
        // [THEN] Both DebitAmount nodes retain the expected currency amounts and exchange rate without rounding.
        VerifyLongMonetaryCurrencyAmounts(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure CreditCurrencyAmountsUseLongMonetaryPrecision()
    begin
        // [SCENARIO] Credit currency amounts retain 18 decimal places and are exported as positive magnitudes.
        // [GIVEN] Credit entries with stored and calculated foreign-currency amounts and an exchange rate with 18 decimal places.
        // [WHEN] The entries are exported to SAF-T 1.4.
        // [THEN] Both CreditAmount nodes contain positive amounts and retain currency amount and exchange rate precision.
        VerifyLongMonetaryCurrencyAmounts(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ForeignCurrencyInvoiceExportsCreditNOKTaxAmount()
    begin
        // [SCENARIO] A foreign-currency sales invoice exports CreditTaxAmount and the corresponding NOK amount and base.
        // [GIVEN] A posted foreign-currency sales invoice with VAT and an exchange rate of 0.5.
        // [WHEN] The posted entries are exported to SAF-T 1.4.
        // [THEN] CreditTaxAmount contains the foreign-currency tax details, with CreditNOKTaxAmount and NOK tax base.
        VerifyPostedSalesTaxAmounts("Sales Document Type"::Invoice, true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ForeignCurrencyCreditMemoExportsDebitNOKTaxAmount()
    begin
        // [SCENARIO] A foreign-currency sales credit memo exports DebitTaxAmount and the corresponding NOK amount and base.
        // [GIVEN] A posted foreign-currency sales credit memo with VAT and an exchange rate of 0.5.
        // [WHEN] The posted entries are exported to SAF-T 1.4.
        // [THEN] DebitTaxAmount contains the foreign-currency tax details, with DebitNOKTaxAmount and NOK tax base.
        VerifyPostedSalesTaxAmounts("Sales Document Type"::"Credit Memo", true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LocalCurrencyInvoiceDoesNotExportNOKTaxAmount()
    begin
        // [SCENARIO] A local-currency invoice has CreditTaxAmount without redundant NOK or foreign-currency children.
        // [GIVEN] A posted local-currency sales invoice with VAT.
        // [WHEN] The posted entries are exported to SAF-T 1.4.
        // [THEN] CreditTaxAmount and the tax base match the VAT entry, without NOK or foreign-currency children.
        VerifyPostedSalesTaxAmounts("Sales Document Type"::Invoice, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LocalCurrencyCreditMemoDoesNotExportNOKTaxAmount()
    begin
        // [SCENARIO] A local-currency credit memo has DebitTaxAmount without redundant NOK or foreign-currency children.
        // [GIVEN] A posted local-currency sales credit memo with VAT.
        // [WHEN] The posted entries are exported to SAF-T 1.4.
        // [THEN] DebitTaxAmount and the tax base match the VAT entry, without NOK or foreign-currency children.
        VerifyPostedSalesTaxAmounts("Sales Document Type"::"Credit Memo", false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LCYSourceCurrencyDoesNotExportNOKTaxAmount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [SCENARIO] A tax amount already denominated in LCY does not require a separate NOK tax amount.
        // [GIVEN] A purchase VAT entry with LCY as its source currency and a source tax amount with 18 decimal places.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("LCY Code");

        // [WHEN] The linked G/L entry is exported to SAF-T 1.4.
        // [THEN] DebitTaxAmount retains the source currency amount without a separate DebitNOKTaxAmount node.
        VerifySourceCurrencyTaxAmount(GeneralLedgerSetup."LCY Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure TaxCurrencyAmountUsesLongMonetaryPrecision()
    var
        Currency: Record Currency;
    begin
        // [SCENARIO] Tax CurrencyAmount retains 18 decimal places instead of monetary or currency rounding.
        Initialize();

        // [GIVEN] A purchase VAT entry with a foreign source currency and a source tax amount with 18 decimal places.
        LibraryERM.CreateCurrency(Currency);

        // [WHEN] The linked G/L entry is exported to SAF-T 1.4.
        // [THEN] DebitTaxAmount retains all source currency decimals and DebitNOKTaxAmount matches the VAT entry.
        VerifySourceCurrencyTaxAmount(Currency.Code);
    end;

    local procedure CreateZeroNetChangeAccount(var SAFTExportHeader: Record "SAF-T Export Header"; var GLAccount: Record "G/L Account"; var UnusedGLAccount: Record "G/L Account")
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTMappingCategory: Record "SAF-T Mapping Category";
        SAFTMapping: Record "SAF-T Mapping";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        SAFTMappingHelper: Codeunit "SAF-T Mapping Helper";
        TransactionNo: Integer;
        DocumentNo: Code[20];
        StartingDate: Date;
    begin
        Initialize();
        SAFTTestHelper.SetupMasterData(1, false);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(UnusedGLAccount);
        StartingDate := SAFTTestHelper.GetWorkDateInYearWithNoGLEntries();
        SAFTTestHelper.InsertSAFTMappingRange(
            SAFTMappingRange, "SAF-T Mapping Type"::"Four Digit Standard Account", StartingDate, CalcDate('<CY>', StartingDate));

        // Mapping-validation tests do not need to import shared Tenant Media resources.
        SAFTMappingCategory."Mapping Type" := SAFTMappingRange."Mapping Type";
        SAFTMappingCategory."No." := LibraryUtility.GenerateGUID();
        SAFTMappingCategory.Insert(true);
        SAFTMapping."Mapping Type" := SAFTMappingCategory."Mapping Type";
        SAFTMapping."Category No." := SAFTMappingCategory."No.";
        SAFTMapping."No." := '1000';
        SAFTMapping.Insert(true);
        SAFTMappingHelper.Run(SAFTMappingRange);
        SAFTGLAccountMapping.SetRange("Mapping Range Code", SAFTMappingRange.Code);
        SAFTGLAccountMapping.FindSet();
        repeat
            SAFTGLAccountMapping.Validate("Category No.", SAFTMapping."Category No.");
            SAFTGLAccountMapping.Validate("No.", SAFTMapping."No.");
            SAFTGLAccountMapping.Modify(true);
        until SAFTGLAccountMapping.Next() = 0;
        SAFTMappingHelper.MapRestSourceCodesToAssortedJournals();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, "SAF-T Version"::"1.40");
        SAFTExportHeader.Validate("Split By Month", false);
        SAFTExportHeader.Modify(true);
        TransactionNo := GetNextTransactionNo();
        DocumentNo := LibraryUtility.GenerateGUID();
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocumentNo, GLAccount."No.", TransactionNo, 0, '', '', 0, '', '', 100, 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocumentNo, GLAccount."No.", TransactionNo, 0, '', '', 0, '', '', 0, -100);
        GLAccount.SetRange("Date Filter", SAFTExportHeader."Starting Date", SAFTExportHeader."Ending Date");
        GLAccount.CalcFields("Net Change");
        GLAccount.TestField("Net Change", 0);
    end;

    local procedure ClearAccountMapping(MappingRangeCode: Code[20]; GLAccountNo: Code[20]; ClearCategory: Boolean)
    var
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
    begin
        SAFTGLAccountMapping.Get(MappingRangeCode, GLAccountNo);
        if ClearCategory then
            SAFTGLAccountMapping.Validate("Category No.", '')
        else
            SAFTGLAccountMapping.Validate("No.", '');
        SAFTGLAccountMapping.Modify(true);
    end;

    local procedure VerifyZeroNetChangeAccountExport(ClearCategory: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        GLAccount: Record "G/L Account";
        UnusedGLAccount: Record "G/L Account";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempNodes: Record "XML Buffer" temporary;
        TempAccountChildren: Record "XML Buffer" temporary;
        AccountXPath: Text;
        AccountCount: Integer;
        ClosingCreditBalanceCount: Integer;
    begin
        // [GIVEN] A mapped account has zero net change and another account has no entries or complete mapping.
        GeneralLedgerSetup.Get();
        CreateZeroNetChangeAccount(SAFTExportHeader, GLAccount, UnusedGLAccount);
        ClearAccountMapping(SAFTExportHeader."Mapping Range Code", UnusedGLAccount."No.", ClearCategory);

        // [WHEN] The entries are exported to SAF-T 1.4.
        ExportEntries(TempXMLBuffer, SAFTExportHeader, GeneralLedgerSetup."LCY Code");

        // [THEN] Both journal lines and their mapped account are exported despite the zero balance.
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempNodes,
                '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:AccountID'),
            'Journal account references were not exported.');
        Assert.RecordCount(TempNodes, 2);
        repeat
            Assert.AreEqual(GLAccount."No.", TempNodes.Value, 'Unexpected journal account.');
        until TempNodes.Next() = 0;
        SAFTGLAccountMapping.Get(SAFTExportHeader."Mapping Range Code", GLAccount."No.");
        SAFTGLAccountMapping.TestField("G/L Entries Exists", true);
        SAFTGLAccountMapping.Get(SAFTExportHeader."Mapping Range Code", UnusedGLAccount."No.");
        SAFTGLAccountMapping.TestField("G/L Entries Exists", false);
        SAFTExportLine.SetRange("Master Data", true);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        AccountXPath := '/n1:AuditFile/n1:MasterFiles/n1:GeneralLedgerAccounts/n1:Account';
        Assert.IsTrue(TempXMLBuffer.FindNodesByXPath(TempNodes, AccountXPath + '/n1:AccountID'), 'Mapped accounts were not exported.');
        repeat
            Assert.AreNotEqual(UnusedGLAccount."No.", TempNodes.Value, 'The unmapped unused account must not be exported.');
            if TempNodes.Value = GLAccount."No." then begin
                AccountCount += 1;
                Assert.IsTrue(TempXMLBuffer.Get(TempNodes."Parent Entry No."), 'The mapped account node is missing.');
                Assert.IsTrue(TempXMLBuffer.FindChildElements(TempAccountChildren), 'The mapped account has no child elements.');
                repeat
                    Assert.AreNotEqual('ClosingDebitBalance', TempAccountChildren.Name, 'Unexpected closing debit balance for the test account.');
                    if TempAccountChildren.Name = 'ClosingCreditBalance' then begin
                        ClosingCreditBalanceCount += 1;
                        SAFTTestHelper.AssertCurrentElementValue(TempAccountChildren, 'n1:ClosingCreditBalance', '0');
                    end;
                until TempAccountChildren.Next() = 0;
            end;
        until TempNodes.Next() = 0;
        Assert.AreEqual(1, AccountCount, 'The mapped test account must be exported exactly once.');
        Assert.AreEqual(1, ClosingCreditBalanceCount, 'The mapped test account must have one closing credit balance.');
    end;

    local procedure VerifyZeroNetChangeAccountMappingError(ClearCategory: Boolean)
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        GLAccount: Record "G/L Account";
        UnusedGLAccount: Record "G/L Account";
    begin
        // [GIVEN] An account with offsetting entries has an incomplete mapping.
        CreateZeroNetChangeAccount(SAFTExportHeader, GLAccount, UnusedGLAccount);
        ClearAccountMapping(SAFTExportHeader."Mapping Range Code", GLAccount."No.", ClearCategory);
        LibraryVariableStorage.Enqueue(Mapping13NotDoneErr);

        // [WHEN] SAF-T 1.4 export is requested.
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] The missing mapping is reported instead of ignoring the account's entries.
        SAFTExportHeader.Get(SAFTExportHeader.ID);
        Assert.AreNotEqual(SAFTExportHeader.Status::Completed, SAFTExportHeader.Status, 'Export must not complete without mapping.');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifyMappingEntryExistence(IncomeStatement: Boolean; IncludeIncomingBalance: Boolean; PostingDate: Date; ExpectedExists: Boolean)
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        SAFTMappingHelper: Codeunit "SAF-T Mapping Helper";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        if IncomeStatement then
            GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement")
        else
            GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        SAFTTestHelper.MockGLEntryNoVAT(PostingDate, GLAccount."No.", GetNextTransactionNo(), 0, 0, '', '', 0, 0);
        SAFTTestHelper.InsertSAFTMappingRange(SAFTMappingRange, "SAF-T Mapping Type"::"Four Digit Standard Account", 20250101D, 20251231D);
        SAFTMappingRange.Validate("Include Incoming Balance", IncludeIncomingBalance);
        SAFTMappingRange.Modify(true);

        SAFTMappingHelper.Run(SAFTMappingRange);
        SAFTGLAccountMapping.Get(SAFTMappingRange.Code, GLAccount."No.");
        SAFTGLAccountMapping.TestField("G/L Entries Exists", ExpectedExists);
        SAFTGLAccountMapping."G/L Entries Exists" := not ExpectedExists;
        SAFTGLAccountMapping.Modify(true);
        SAFTMappingHelper.UpdateGLEntriesExistStateForGLAccMapping(SAFTMappingRange.Code);
        SAFTGLAccountMapping.Find();
        SAFTGLAccountMapping.TestField("G/L Entries Exists", ExpectedExists);

        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.DeleteAll(true);
        SAFTMappingHelper.UpdateGLEntriesExistStateForGLAccMapping(SAFTMappingRange.Code);
        SAFTGLAccountMapping.Find();
        SAFTGLAccountMapping.TestField("G/L Entries Exists", false);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SAF-T XML Tests 1.4");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SAF-T XML Tests 1.4");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SAF-T XML Tests 1.4");
    end;

    local procedure CreateExportSetup(var SAFTExportHeader: Record "SAF-T Export Header")
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SafTVersion: Enum "SAF-T Version";
    begin
        Initialize();
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, "SAF-T Mapping Type"::"Four Digit Standard Account", 1, false);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, SafTVersion::"1.40");
        SAFTExportHeader.Validate("Split By Month", false);
        SAFTExportHeader.Modify(true);
    end;

    local procedure ExportEntries(var TempXMLBuffer: Record "XML Buffer" temporary; var SAFTExportHeader: Record "SAF-T Export Header"; OriginalLCYCode: Code[10])
    var
        SAFTExportLine: Record "SAF-T Export Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportHeader.Find();
        SAFTExportHeader.TestField(Status, SAFTExportHeader.Status::Completed);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        Assert.RecordCount(SAFTExportLine, 1);
        SAFTExportLine.TestField(Status, SAFTExportLine.Status::Completed);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("LCY Code", OriginalLCYCode);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifyLongMonetaryCurrencyAmounts(IsDebit: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SAFTExportHeader: Record "SAF-T Export Header";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        Customer: Record Customer;
        Currency: Record Currency;
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempAmountXMLBuffer: Record "XML Buffer" temporary;
        DebitAmount: Decimal;
        CreditAmount: Decimal;
        EntryNo: Integer;
        TransactionNo: Integer;
        Sign: Integer;
        AmountNode: Text;
        DocumentNo: Code[20];
    begin
        // [GIVEN] Two entries exercise stored and calculated currency amounts with an 18-decimal exchange rate.
        GeneralLedgerSetup.Get();
        CreateExportSetup(SAFTExportHeader);
        LibraryERM.CreateCurrency(Currency);
        Customer.FindFirst();
        GLAccount.FindFirst();
        TransactionNo := GetNextTransactionNo();
        DocumentNo := LibraryUtility.GenerateGUID();
        Sign := IsDebit ? 1 : -1;
        AmountNode := IsDebit ? 'DebitAmount' : 'CreditAmount';
        if IsDebit then
            DebitAmount := 0.1
        else
            CreditAmount := -0.1;
        EntryNo := SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocumentNo, GLAccount."No.", TransactionNo, 0, '', '',
            GLEntry."Source Type"::Customer.AsInteger(), Customer."No.", '',
            DebitAmount, CreditAmount);
        SAFTTestHelper.MockCustLedgEntry(
            EntryNo, SAFTExportHeader."Ending Date", Customer."No.", TransactionNo, Currency.Code,
            Sign * 0.123456789012345678, Sign * 0.123456789012345678, Sign * 0.1,
            1.23456789012345678, "Gen. Journal Document Type"::Invoice);
        // A different entry number exercises conversion rather than the stored ledger amount.
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocumentNo, GLAccount."No.", TransactionNo, 0, '', '',
            GLEntry."Source Type"::Customer.AsInteger(), Customer."No.", '',
            2 * DebitAmount, 2 * CreditAmount);

        // [WHEN] The entries are exported to SAF-T 1.4.
        ExportEntries(TempXMLBuffer, SAFTExportHeader, GeneralLedgerSetup."LCY Code");

        // [THEN] Both amount nodes contain the expected amounts, currency code, and unrounded exchange rate.
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer,
                '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:' + AmountNode),
            'Currency amount nodes were not exported.');
        Assert.RecordCount(TempXMLBuffer, 2);
        VerifyAmountChildren(TempAmountXMLBuffer, TempXMLBuffer, Currency.Code, '0.1', '0.123456789012345678', '0.810000007290000072');
        TempXMLBuffer.Next();
        VerifyAmountChildren(TempAmountXMLBuffer, TempXMLBuffer, Currency.Code, '0.2',
            '0.246913578024691356', '0.810000007290000072');
    end;

    local procedure VerifyAmountChildren(var TempChildren: Record "XML Buffer" temporary; var TempParent: Record "XML Buffer" temporary; CurrencyCode: Code[10]; Amount: Text; CurrencyAmount: Text; ExchangeRate: Text)
    begin
        TempParent.FindChildElements(TempChildren);
        Assert.RecordCount(TempChildren, 4);
        SAFTTestHelper.AssertCurrentElementValue(TempChildren, 'n1:Amount', Amount);
        TempChildren.Next();
        SAFTTestHelper.AssertCurrentElementValue(TempChildren, 'n1:CurrencyCode', CurrencyCode);
        TempChildren.Next();
        SAFTTestHelper.AssertCurrentElementValue(TempChildren, 'n1:CurrencyAmount', CurrencyAmount);
        TempChildren.Next();
        SAFTTestHelper.AssertCurrentElementValue(TempChildren, 'n1:ExchangeRate', ExchangeRate);
    end;

    local procedure VerifyPostedSalesTaxAmounts(DocumentType: Enum "Sales Document Type"; UseForeignCurrency: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SAFTExportHeader: Record "SAF-T Export Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        VATEntry: Record "VAT Entry";
        TempXMLBuffer: Record "XML Buffer" temporary;
        DocumentNo: Code[20];
    begin
        // [GIVEN] A sales document is posted with 25 percent VAT and the requested currency.
        GeneralLedgerSetup.Get();
        CreateExportSetup(SAFTExportHeader);
        Customer.FindFirst();
        GLAccount.FindFirst();
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", 25);
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        SalesHeader.Validate("Posting Date", SAFTExportHeader."Ending Date");
        SalesHeader.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Validate("Prices Including VAT", false);
        if UseForeignCurrency then begin
            LibraryERM.CreateCurrency(Currency);
            LibraryERM.CreateExchangeRate(Currency.Code, SalesHeader."Posting Date", 0.5, 0.5);
            SalesHeader.Validate("Currency Code", Currency.Code);
        end;
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.FindFirst();

        Assert.AreEqual(UseForeignCurrency ? 50 : 25, Abs(VATEntry.Amount), 'Unexpected posted tax amount.');
        Assert.AreEqual(UseForeignCurrency ? 200 : 100, Abs(VATEntry.Base), 'Unexpected posted tax base.');

        // [WHEN] The posted entries are exported to SAF-T 1.4.
        ExportEntries(TempXMLBuffer, SAFTExportHeader, GeneralLedgerSetup."LCY Code");

        // [THEN] The tax amount direction, base, and currency children match the posted VAT entry.
        VerifyTaxStructure(
            TempXMLBuffer, VATEntry, DocumentType = DocumentType::"Credit Memo", UseForeignCurrency,
            UseForeignCurrency ? Currency.Code : '', UseForeignCurrency ? 25 : 0);
    end;

    local procedure VerifySourceCurrencyTaxAmount(SourceCurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SAFTExportHeader: Record "SAF-T Export Header";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TransactionNo: Integer;
    begin
        // [GIVEN] A purchase VAT entry has a source currency tax amount with 18 decimal places and a linked G/L entry.
        GeneralLedgerSetup.Get();
        CreateExportSetup(SAFTExportHeader);
        GLAccount.FindFirst();
        TransactionNo := GetNextTransactionNo();
        SAFTTestHelper.MockVATEntry(VATEntry, SAFTExportHeader."Ending Date", VATEntry.Type::Purchase.AsInteger(), TransactionNo);
        VATEntry."Source Currency Code" := SourceCurrencyCode;
        VATEntry."Source Currency VAT Amount" := 0.000123456789012345;
        VATEntry.Modify();
        SAFTTestHelper.MockGLEntryVATEntryLink(
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", VATEntry."Document No.", GLAccount."No.", TransactionNo, 0,
                GLEntry."Gen. Posting Type"::Purchase.AsInteger(), VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group",
                GLEntry."Source Type"::" ".AsInteger(), '', '', VATEntry.Amount, 0),
            VATEntry."Entry No.");

        // [WHEN] The linked G/L entry is exported to SAF-T 1.4.
        ExportEntries(TempXMLBuffer, SAFTExportHeader, GeneralLedgerSetup."LCY Code");

        // [THEN] The source tax amount retains its precision and a separate NOK amount is present only for a foreign source currency.
        VerifyTaxStructure(
            TempXMLBuffer, VATEntry, true, SourceCurrencyCode <> GeneralLedgerSetup."LCY Code",
            SourceCurrencyCode, 0.000123456789012345);
        AssertSingleValue(TempXMLBuffer, TaxInformationXPathLbl + '/n1:DebitTaxAmount/n1:CurrencyAmount', '0.000123456789012345');
    end;

    local procedure VerifyTaxStructure(var TempXMLBuffer: Record "XML Buffer" temporary; VATEntry: Record "VAT Entry"; IsDebit: Boolean; ExpectNOKAmount: Boolean; SourceCurrencyCode: Code[10]; SourceCurrencyVATAmount: Decimal)
    var
        AmountNode: Text;
        NOKAmountNode: Text;
        OppositeAmountNode: Text;
    begin
        AmountNode := IsDebit ? 'DebitTaxAmount' : 'CreditTaxAmount';
        NOKAmountNode := IsDebit ? 'DebitNOKTaxAmount' : 'CreditNOKTaxAmount';
        OppositeAmountNode := IsDebit ? 'CreditTaxAmount' : 'DebitTaxAmount';
        AssertSingleValue(TempXMLBuffer, TaxInformationXPathLbl + '/n1:TaxBase', Format(Abs(VATEntry.Base), 0, 9));
        AssertSingleValue(TempXMLBuffer, TaxInformationXPathLbl + '/n1:' + AmountNode + '/n1:Amount', Format(Abs(VATEntry.Amount), 0, 9));
        AssertNoNodes(TempXMLBuffer, TaxInformationXPathLbl + '/n1:' + OppositeAmountNode);
        AssertNoNodes(TempXMLBuffer, TaxInformationXPathLbl + '/n1:TaxAmount');
        if SourceCurrencyCode <> '' then begin
            AssertSingleValue(TempXMLBuffer, TaxInformationXPathLbl + '/n1:' + AmountNode + '/n1:CurrencyCode', SourceCurrencyCode);
            AssertSingleValue(TempXMLBuffer, TaxInformationXPathLbl + '/n1:' + AmountNode + '/n1:CurrencyAmount',
                Format(Abs(SourceCurrencyVATAmount), 0, 9));
        end else begin
            AssertNoNodes(TempXMLBuffer, TaxInformationXPathLbl + '/n1:' + AmountNode + '/n1:CurrencyCode');
            AssertNoNodes(TempXMLBuffer, TaxInformationXPathLbl + '/n1:' + AmountNode + '/n1:CurrencyAmount');
        end;
        if ExpectNOKAmount then begin
            AssertSingleValue(TempXMLBuffer, TaxInformationXPathLbl + '/n1:' + NOKAmountNode + '/n1:NOKAmount', Format(Abs(VATEntry.Amount), 0, 9));
            AssertSingleValue(TempXMLBuffer, TaxInformationXPathLbl + '/n1:' + NOKAmountNode + '/n1:NOKTaxBase', Format(Abs(VATEntry.Base), 0, 9));
            AssertNoNodes(TempXMLBuffer, TaxInformationXPathLbl + '/n1:' + (IsDebit ? 'CreditNOKTaxAmount' : 'DebitNOKTaxAmount'));
        end else begin
            AssertNoNodes(TempXMLBuffer, TaxInformationXPathLbl + '/n1:DebitNOKTaxAmount');
            AssertNoNodes(TempXMLBuffer, TaxInformationXPathLbl + '/n1:CreditNOKTaxAmount');
        end;
    end;

    local procedure AssertSingleValue(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text; ExpectedValue: Text)
    var
        TempNodes: Record "XML Buffer" temporary;
    begin
        Assert.IsTrue(TempXMLBuffer.FindNodesByXPath(TempNodes, XPath), 'Missing XML node: ' + XPath);
        Assert.RecordCount(TempNodes, 1);
        Assert.AreEqual(ExpectedValue, TempNodes.Value, 'Unexpected XML value: ' + XPath);
    end;

    local procedure AssertNoNodes(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text)
    var
        TempNodes: Record "XML Buffer" temporary;
    begin
        Assert.IsFalse(TempXMLBuffer.FindNodesByXPath(TempNodes, XPath), 'Unexpected XML node: ' + XPath);
    end;

    local procedure GetNextTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        if GLEntry.FindLast() then
            exit(GLEntry."Transaction No." + 1);
        exit(1);
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, 'Unexpected confirmation.');
        Reply := true;
    end;

    [PageHandler]
    procedure MappingErrorPageHandler(var ErrorMessages: TestPage "Error Messages")
    begin
        ErrorMessages.Description.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(ErrorMessages.Next(), 'Unexpected additional mapping error.');
    end;
}
