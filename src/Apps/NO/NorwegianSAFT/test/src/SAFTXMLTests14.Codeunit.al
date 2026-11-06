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

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DebitCurrencyAmountsUseLongMonetaryPrecision()
    begin
        // [SCENARIO] Debit CurrencyAmount and ExchangeRate retain 18 decimal places, including calculated currency amounts.
        VerifyLongMonetaryCurrencyAmounts(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure CreditCurrencyAmountsUseLongMonetaryPrecision()
    begin
        // [SCENARIO] Credit currency amounts retain 18 decimal places and are exported as positive magnitudes.
        VerifyLongMonetaryCurrencyAmounts(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ForeignCurrencyInvoiceExportsCreditNOKTaxAmount()
    begin
        // [SCENARIO] A foreign-currency sales invoice exports CreditTaxAmount and the corresponding NOK amount and base.
        VerifyPostedSalesTaxAmounts("Sales Document Type"::Invoice, true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ForeignCurrencyCreditMemoExportsDebitNOKTaxAmount()
    begin
        // [SCENARIO] A foreign-currency sales credit memo exports DebitTaxAmount and the corresponding NOK amount and base.
        VerifyPostedSalesTaxAmounts("Sales Document Type"::"Credit Memo", true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LocalCurrencyInvoiceDoesNotExportNOKTaxAmount()
    begin
        // [SCENARIO] A local-currency invoice has CreditTaxAmount without redundant NOK or foreign-currency children.
        VerifyPostedSalesTaxAmounts("Sales Document Type"::Invoice, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LocalCurrencyCreditMemoDoesNotExportNOKTaxAmount()
    begin
        // [SCENARIO] A local-currency credit memo has DebitTaxAmount without redundant NOK or foreign-currency children.
        VerifyPostedSalesTaxAmounts("Sales Document Type"::"Credit Memo", false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure NOKSourceCurrencyDoesNotExportNOKTaxAmount()
    begin
        // [SCENARIO] A tax amount already denominated in NOK does not require a separate NOK tax amount.
        VerifySourceCurrencyTaxAmount('NOK');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure TaxCurrencyAmountUsesLongMonetaryPrecision()
    var
        Currency: Record Currency;
    begin
        // [SCENARIO] Tax CurrencyAmount retains 18 decimal places instead of monetary or currency rounding.
        LibraryERM.CreateCurrency(Currency);
        VerifySourceCurrencyTaxAmount(Currency.Code);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SAF-T XML Tests 1.4");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SAF-T XML Tests 1.4");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SAF-T XML Tests 1.4");
    end;

    local procedure CreateExportSetup(var SAFTExportHeader: Record "SAF-T Export Header")
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
    begin
        Initialize();
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, "SAF-T Mapping Type"::"Four Digit Standard Account", 1, false);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, "SAF-T Version"::"1.40");
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
        EntryNo: Integer;
        TransactionNo: Integer;
        Sign: Integer;
        AmountNode: Text;
        DocumentNo: Code[20];
    begin
        GeneralLedgerSetup.Get();
        CreateExportSetup(SAFTExportHeader);
        LibraryERM.CreateCurrency(Currency);
        Customer.FindFirst();
        GLAccount.FindFirst();
        TransactionNo := GetNextTransactionNo();
        DocumentNo := LibraryUtility.GenerateGUID();
        Sign := IsDebit ? 1 : -1;
        AmountNode := IsDebit ? 'DebitAmount' : 'CreditAmount';
        EntryNo := SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocumentNo, GLAccount."No.", TransactionNo, 0, '', '',
            GLEntry."Source Type"::Customer.AsInteger(), Customer."No.", '',
            IsDebit ? 100 : 0, IsDebit ? 0 : -100);
        SAFTTestHelper.MockCustLedgEntry(
            EntryNo, SAFTExportHeader."Ending Date", Customer."No.", TransactionNo, Currency.Code,
            Sign * 0.000123456789012345, Sign * 0.000123456789012345, Sign * 100,
            0.000123456789012345, "Gen. Journal Document Type"::Invoice);
        // A different entry number exercises conversion rather than the stored ledger amount.
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocumentNo, GLAccount."No.", TransactionNo, 0, '', '',
            GLEntry."Source Type"::Customer.AsInteger(), Customer."No.", '',
            IsDebit ? 1 : 0, IsDebit ? 0 : -1);

        ExportEntries(TempXMLBuffer, SAFTExportHeader, GeneralLedgerSetup."LCY Code");

        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer,
                '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:' + AmountNode),
            'Currency amount nodes were not exported.');
        Assert.RecordCount(TempXMLBuffer, 2);
        VerifyAmountChildren(TempAmountXMLBuffer, TempXMLBuffer, Currency.Code, '100', '0.000123456789012345', '0.000123456789012345');
        TempXMLBuffer.Next();
        VerifyAmountChildren(TempAmountXMLBuffer, TempXMLBuffer, Currency.Code, '1',
            Format(Round(1 / 0.000123456789012345, 0.000000000000000001), 0, 9), '0.000123456789012345');
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

        ExportEntries(TempXMLBuffer, SAFTExportHeader, GeneralLedgerSetup."LCY Code");

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

        ExportEntries(TempXMLBuffer, SAFTExportHeader, GeneralLedgerSetup."LCY Code");

        VerifyTaxStructure(TempXMLBuffer, VATEntry, true, SourceCurrencyCode <> 'NOK', SourceCurrencyCode, 0.000123456789012345);
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
}
