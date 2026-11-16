// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;

codeunit 148362 EACorpCardResolutionTests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryExpense: Codeunit "Library - Expense";
        CsvProviderCodeTok: Label 'CORPCARDCSV', Locked = true;
        XmlProviderCodeTok: Label 'CORPCARDXML', Locked = true;

    [Test]
    procedure LastFourResolvesConfiguredCard()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardValidateMgt: Codeunit "EA Corp Card Validate Mgt";
        ValidationReason: Text[250];
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        Assert.AreEqual('****0001', CorpCard."Masked Card No.", 'The fixture must configure the masked card suffix.');
        CorpCardTrans."Provider Code" := CsvProviderCodeTok;
        CorpCardTrans."Provider Trans Id" := 'RESOLVE-1';
        CorpCardTrans."Trans Date" := WorkDate();
        CorpCardTrans."Card Last 4" := '0001';

        Assert.IsTrue(CorpCardValidateMgt.ValidateTrans(CorpCardTrans, ValidationReason), ValidationReason);

        Assert.AreEqual(CorpCard."Card Id", CorpCardTrans."Card Id", 'Validation must resolve the configured card.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CsvLastFourResolvesUnrelatedInternalId()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        CorpCard.Rename('INTERNAL-CARD-ALPHA');
        SetCsvPayload('0001', false);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        CorpCardTestLib.FindTransInStatementByProviderTransId(CorpCardStatement."Statement Entry No.", CsvProviderCodeTok, 'RESOLVE-1', CorpCardTrans);
        Assert.AreEqual(CorpCard."Card Id", CorpCardTrans."Card Id", 'The internal card identifier must be resolved, not read from the file.');
        Assert.AreEqual('0001', CorpCardTrans."Card Last 4", 'Leading zeroes in the suffix must be preserved.');
        Assert.AreEqual(CorpCardTrans.Status::DraftCreated, CorpCardTrans.Status, 'A uniquely identified card must support draft creation.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure XmlLastFourResolvesInternalId()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        Initialize();
        SetXmlPayload('9001', false);

        RunImport(XmlProviderCodeTok, CorpCardStatement);

        CorpCardTestLib.FindTransInStatementByProviderTransId(CorpCardStatement."Statement Entry No.", XmlProviderCodeTok, 'RESOLVE-1', CorpCardTrans);
        Assert.AreEqual('XML-CARD-SAMPLE', CorpCardTrans."Card Id", 'Mapped XML must resolve the internal identifier from the suffix.');
        Assert.AreEqual('9001', CorpCardTrans."Card Last 4", 'Mapped XML must retain only the last four digits.');
        Assert.AreEqual(19.63, CorpCardTrans.Amount, 'Mapped XML must import the transaction amount from the parsed fields.');
        Assert.AreEqual('USD', CorpCardTrans."Currency Code", 'Mapped XML must import the transaction currency from the parsed fields.');
        Assert.AreEqual('Contoso Air', CorpCardTrans."Merchant Raw", 'Mapped XML must import the merchant from the parsed fields.');
        Assert.AreEqual('4511', CorpCardTrans.MCC, 'Mapped XML must import the MCC from the parsed fields.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure XmlFallbackKeepsFieldValuesScopedToEachLine()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Payload: Text;
        TransactionXml: Text;
    begin
        Initialize();
        CorpCardProvider.Get(XmlProviderCodeTok);
        DataExchFieldMapping.SetRange("Data Exch. Def Code", CorpCardProvider."Data Exch Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", CorpCardProvider."Data Exch Map Code");
        DataExchFieldMapping.SetRange("Table ID", Database::"EA Corp Card Trans");
        DataExchFieldMapping.SetFilter("Column No.", '%1|%2|%3', 2, 4, 8);
        DataExchFieldMapping.FindSet();
        repeat
            DataExchFieldMapping.Rename(
                DataExchFieldMapping."Data Exch. Def Code",
                DataExchFieldMapping."Data Exch. Line Def Code",
                DataExchFieldMapping."Table ID",
                DataExchFieldMapping."Column No.",
                CorpCardTrans.FieldNo("Merchant Norm"));
        until DataExchFieldMapping.Next() = 0;

        Payload := '<?xml version="1.0" encoding="utf-8"?><CorporateCardTransactions>' + BuildXmlRow('CACHE-1', '9001');
        TransactionXml := BuildXmlRow('CACHE-2', '9001');
        TransactionXml := TransactionXml.Replace('<MCC>4511</MCC>', '<MCC>7011</MCC>');
        TransactionXml := TransactionXml.Replace(
            '<PostingDate>' + Format(WorkDate(), 0, 9) + '</PostingDate>',
            '<PostingDate>' + Format(WorkDate() + 1, 0, 9) + '</PostingDate>');
        Payload += TransactionXml;
        TransactionXml := BuildXmlRow('CACHE-3', '9001');
        Payload += TransactionXml.Replace('<MCC>4511</MCC>', '') + '</CorporateCardTransactions>';
        CorpCardTestLib.SetProviderSourcePayload(XmlProviderCodeTok, Payload, 'Fallback-cache.xml');

        RunImport(XmlProviderCodeTok, CorpCardStatement);

        Assert.AreEqual(3, CorpCardStatement.Imported, 'Every row must import using fallback values from its own data exchange line.');
        CorpCardTestLib.FindTransInStatementByProviderTransId(CorpCardStatement."Statement Entry No.", XmlProviderCodeTok, 'CACHE-1', CorpCardTrans);
        Assert.AreEqual('9001', CorpCardTrans."Card Last 4", 'Named-column fallback must resolve the card suffix.');
        Assert.AreEqual('4511', CorpCardTrans.MCC, 'The first line must retain its MCC.');
        Assert.AreEqual(WorkDate(), CorpCardTrans."Posting Date", 'The first line must retain its posting date.');
        CorpCardTestLib.FindTransInStatementByProviderTransId(CorpCardStatement."Statement Entry No.", XmlProviderCodeTok, 'CACHE-2', CorpCardTrans);
        Assert.AreEqual('7011', CorpCardTrans.MCC, 'A later line must not reuse the first line''s MCC.');
        Assert.AreEqual(WorkDate() + 1, CorpCardTrans."Posting Date", 'A later line must not reuse the first line''s posting date.');
        CorpCardTestLib.FindTransInStatementByProviderTransId(CorpCardStatement."Statement Entry No.", XmlProviderCodeTok, 'CACHE-3', CorpCardTrans);
        Assert.AreEqual('', CorpCardTrans.MCC, 'A missing column must not retain a cached value from an earlier line.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure UnknownSuffixDoesNotAbortOtherCsvRows()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        Initialize();
        SetCsvPayload('9999', true);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'No corporate card could be identified');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure BlockedCardDoesNotAbortOtherCsvRows()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0001');
        CorpCard.Blocked := true;
        CorpCard.Modify(true);
        SetCsvPayload('0001', true);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'The corporate card is blocked.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AmbiguousSuffixNeverSelectsFirstCard()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        Initialize();
        CorpCard.Get('CORPCARD-0003');
        CorpCard."Masked Card No." := '****0001';
        CorpCard.Modify(true);
        SetCsvPayload('0001', true);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'More than one corporate card matches');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SuffixResolutionIsProviderScoped()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        Initialize();
        CorpCard.Get('XML-CARD-SAMPLE');
        CorpCard."Masked Card No." := '****0001';
        CorpCard.Modify(true);
        SetCsvPayload('0001', false);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        CorpCardTestLib.FindTransInStatementByProviderTransId(CorpCardStatement."Statement Entry No.", CsvProviderCodeTok, 'RESOLVE-1', CorpCardTrans);
        Assert.AreEqual('CORPCARD-0001', CorpCardTrans."Card Id", 'Another provider with the same suffix must not affect card identification.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FullNumberIsRejectedWithoutDisclosureInCsv()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        Initialize();
        SetCsvPayload('4111111111111111', true);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'Card Last 4 must contain exactly four digits.');
        AssertNoFullNumberRetained(CorpCardStatement);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FullNumberIsRejectedBeforeMappedFieldConversion()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        Initialize();
        SetXmlPayload('4111111111111111', true);

        RunImport(XmlProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'Card Last 4 must contain exactly four digits.');
        AssertNoFullNumberRetained(CorpCardStatement);
    end;

    [Test]
    procedure InternalCardIdentifierCannotBeMapped()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardTrans: Record "EA Corp Card Trans";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        CorpCardMapMgt: Codeunit "EA Corp Card Map Mgt";
    begin
        Initialize();
        CorpCardProvider.Get(CsvProviderCodeTok);
        DataExchFieldMapping."Data Exch. Def Code" := CorpCardProvider."Data Exch Def Code";
        DataExchFieldMapping."Data Exch. Line Def Code" := CorpCardProvider."Data Exch Map Code";
        DataExchFieldMapping."Table ID" := Database::"EA Corp Card Trans";
        DataExchFieldMapping."Field ID" := CorpCardTrans.FieldNo("Card Id");
        DataExchFieldMapping."Column No." := 2;
        DataExchFieldMapping.Insert(true);

        asserterror CorpCardMapMgt.ValidateMandatoryFieldMappings(CorpCardProvider);

        Assert.ExpectedError('is an internal field and cannot be imported');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure UniqueExpenseMatchLinksInsteadOfCreatingDraft()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
    begin
        Initialize();
        CreateMatchingExpense(Expense);
        SetCsvPayload('', false);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        CorpCardTestLib.FindTransInStatementByProviderTransId(CorpCardStatement."Statement Entry No.", CsvProviderCodeTok, 'RESOLVE-1', CorpCardTrans);
        Assert.AreEqual('CORPCARD-0001', CorpCardTrans."Card Id", 'The card must be inferred from the unique matching expense user and provider.');
        Assert.AreEqual(Expense."No.", CorpCardTrans."Expense No.", 'AutoDraft must link the unique existing expense instead of creating a duplicate.');
        Assert.AreEqual(CorpCardTrans.Status::Matched, CorpCardTrans.Status, 'The fallback must finish as a matched transaction.');
        Expense.Get(Expense."No.");
        Assert.AreEqual(CorpCardTrans."Entry No.", Expense."Credit Card Feed No.", 'The reverse expense link must be established after import.');
        Assert.AreEqual(1, Expense.Count(), 'No additional draft may be created for a fallback match.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AmbiguousExpenseMatchIsRejected()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        Expense: Record Expense;
    begin
        Initialize();
        CreateMatchingExpense(Expense);
        Clear(Expense);
        CreateMatchingExpense(Expense);
        SetCsvPayload('', true);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'More than one expense or corporate card matches');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ExpenseMatchWithMultipleCardsIsRejected()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
        Expense: Record Expense;
    begin
        Initialize();
        CreateMatchingExpense(Expense);
        CorpCard.Get('CORPCARD-0001');
        CorpCard."Card Id" := 'ANOTHER-INTERNAL-CARD';
        CorpCard."Masked Card No." := '****7777';
        CorpCard.Insert(true);
        SetCsvPayload('', true);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'More than one expense or corporate card matches');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SuppliedUnknownSuffixNeverFallsBackToExpense()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        Expense: Record Expense;
    begin
        Initialize();
        CreateMatchingExpense(Expense);
        SetCsvPayload('9999', true);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'No corporate card could be identified');
        Expense.Get(Expense."No.");
        Assert.AreEqual(0, Expense."Credit Card Feed No.", 'A supplied unknown suffix must not be ignored to match another card.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MissingSuffixWithoutExpenseNeverSelectsFirstCard()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        Initialize();
        SetCsvPayload('', true);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'No corporate card could be identified');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FallbackRequiresExactDateAndCurrency()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        Expense: Record Expense;
    begin
        Initialize();
        CreateMatchingExpense(Expense);
        Expense.Validate("Expense Date", WorkDate() - 1);
        Expense.Modify(true);
        Clear(Expense);
        CreateMatchingExpense(Expense);
        Expense.Validate("Currency Code", '');
        Expense.Modify(true);
        SetCsvPayload('', true);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'No corporate card could be identified');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FallbackRejectsNonCreditCardExpenses()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        Expense: Record Expense;
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        Initialize();
        CreateMatchingExpense(Expense);
        ExpensePaymentMethod.SetFilter("Reimbursement Type", '<>%1', ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        Assert.IsTrue(ExpensePaymentMethod.FindFirst(), 'The fixture must provide a non-credit-card payment method.');
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify(true);
        SetCsvPayload('', true);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'No corporate card could be identified');
        Expense.Get(Expense."No.");
        Assert.AreEqual(0, Expense."Credit Card Feed No.", 'A non-credit-card expense must not be linked by the fallback.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FallbackRejectsUnassignedExpenseAndCard()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
        Expense: Record Expense;
    begin
        Initialize();
        CreateMatchingExpense(Expense);
        Expense."Expense User No." := '';
        Expense.Modify(true);
        CorpCard.Get('CORPCARD-0001');
        CorpCard."Expense User No." := '';
        CorpCard.Modify(true);
        SetCsvPayload('', true);

        RunImport(CsvProviderCodeTok, CorpCardStatement);

        AssertMixedImport(CorpCardStatement, 'No corporate card could be identified');
        Expense.Get(Expense."No.");
        Assert.AreEqual(0, Expense."Credit Card Feed No.", 'An unassigned expense must not identify an unassigned card.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure StaleExpenseCandidateDoesNotCreateDraft()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        CorpCardDataExchProv: Codeunit "EA Corp Card Data Exch Prov";
        CorpCardExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        CorpCardPostImportOrch: Codeunit "EA Corp Card Post Import Orch";
    begin
        Initialize();
        CreateMatchingExpense(Expense);
        SetCsvPayload('', false);
        CorpCardProvider.Get(CsvProviderCodeTok);
        CorpCardTestLib.CreateStatement(CorpCardStatement, CsvProviderCodeTok, 'STALE-MATCH', 19.63, CorpCardStatement.Status::Importing);
        BindSubscription(CorpCardTestLib);
        CorpCardDataExchProv.Download(CorpCardStatement);
        UnbindSubscription(CorpCardTestLib);
        CorpCardDataExchProv.ParseToStaging(CorpCardStatement."Statement Entry No.");
        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        CorpCardStatement.Status := CorpCardStatement.Status::Imported;
        CorpCardStatement.Modify(true);
        Expense.Validate(Amount, 20);
        Expense.Modify(true);
        Commit();

        CorpCardPostImportOrch.ProcessStatementPostImport(CorpCardStatement."Statement Entry No.", CorpCardExpenseWriter);

        CorpCardTestLib.FindTransInStatementByProviderTransId(CorpCardStatement."Statement Entry No.", CsvProviderCodeTok, 'RESOLVE-1', CorpCardTrans);
        Assert.AreEqual(CorpCardTrans.Status::Exception, CorpCardTrans.Status, 'A changed fallback match must become a transaction-level exception.');
        Assert.AreEqual('', CorpCardTrans."Expense No.", 'A stale candidate must not be linked.');
        Assert.AreEqual(1, Expense.Count(), 'A stale fallback must not silently create a new draft.');
        Expense.Get(Expense."No.");
        Assert.AreEqual(0, Expense."Credit Card Feed No.", 'The original expense must remain unlinked.');
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Clear(CorpCardTestLib);
        CorpCardTestLib.InitializeCorpCardData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := 'EUR';
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreateMatchingExpense(var Expense: Record Expense)
    var
        CorpCard: Record "EA Corp Card";
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        CorpCard.Get('CORPCARD-0001');
        LibraryExpense.CreateExpense(Expense, CorpCard."Expense User No.", 'AIRLINE', '', '', false, 'USD', 19.63);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Credit Card");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify(true);
    end;

    local procedure SetCsvPayload(CardLast4: Text; IncludeValidRow: Boolean)
    var
        CsvPayload: TextBuilder;
    begin
        CsvPayload.AppendLine('ProviderTransId,CardLast4,TransDate,PostingDate,Amount,CurrencyCode,MerchantRaw,MCC,Country,Notes');
        CsvPayload.AppendLine(BuildCsvRow('RESOLVE-1', CardLast4));
        if IncludeValidRow then
            CsvPayload.AppendLine(BuildCsvRow('RESOLVE-2', '0002'));
        CorpCardTestLib.SetProviderSourcePayload(CsvProviderCodeTok, CsvPayload.ToText(), 'Card-resolution.csv');
    end;

    local procedure BuildCsvRow(ProviderTransId: Text; CardLast4: Text): Text
    begin
        exit(ProviderTransId + ',' + CardLast4 + ',' + Format(WorkDate(), 0, 9) + ',' + Format(WorkDate(), 0, 9) + ',19.63,USD,Contoso Air,4511,US,Card resolution');
    end;

    local procedure SetXmlPayload(CardLast4: Text; IncludeValidRow: Boolean)
    var
        Payload: Text;
    begin
        Payload := '<?xml version="1.0" encoding="utf-8"?><CorporateCardTransactions>' + BuildXmlRow('RESOLVE-1', CardLast4);
        if IncludeValidRow then
            Payload += BuildXmlRow('RESOLVE-2', '9001');
        Payload += '</CorporateCardTransactions>';
        CorpCardTestLib.SetProviderSourcePayload(XmlProviderCodeTok, Payload, 'Card-resolution.xml');
    end;

    local procedure BuildXmlRow(ProviderTransId: Text; CardLast4: Text): Text
    begin
        exit(
            '<Transaction><ProviderTransId>' + ProviderTransId + '</ProviderTransId><CardLast4>' + CardLast4 +
            '</CardLast4><TransDate>' + Format(WorkDate(), 0, 9) + '</TransDate><PostingDate>' + Format(WorkDate(), 0, 9) +
            '</PostingDate><Amount>19.63</Amount><CurrencyCode>USD</CurrencyCode><MerchantRaw>Contoso Air</MerchantRaw><MCC>4511</MCC><Country>US</Country></Transaction>');
    end;

    local procedure RunImport(ProviderCode: Code[20]; var CorpCardStatement: Record "EA Corp Card Statement")
    var
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
    begin
        CorpCardProvider.Get(ProviderCode);
        BindSubscription(CorpCardTestLib);
        CorpCardImportOrch.RunProvider(CorpCardProvider, false);
        UnbindSubscription(CorpCardTestLib);
        CorpCardProvider.Get(ProviderCode);
        CorpCardStatement.Get(CorpCardProvider."Last Statement Entry No.");
        if CorpCardStatement.Status = CorpCardStatement.Status::Failed then begin
            CorpCardException.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
            if CorpCardException.FindFirst() then
                Assert.Fail(CorpCardException.Message);
            Assert.Fail('The import failed without a row diagnostic.');
        end;
    end;

    local procedure AssertMixedImport(CorpCardStatement: Record "EA Corp Card Statement"; ExpectedReason: Text)
    var
        CorpCardException: Record "EA Corp Card Exception";
    begin
        Assert.AreEqual(CorpCardStatement.Status::Imported, CorpCardStatement.Status, 'An invalid card must not abort other valid rows.');
        Assert.AreEqual(1, CorpCardStatement.Imported, 'Only the valid row must be imported.');
        Assert.AreEqual(1, CorpCardStatement.Rejected, 'The invalid row must be rejected.');
        Assert.AreEqual(1, CorpCardStatement.Exceptions, 'The invalid row must retain its diagnostic.');
        CorpCardException.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        Assert.IsTrue(CorpCardException.FindFirst(), 'The invalid row must have an exception.');
        Assert.IsTrue(StrPos(CorpCardException.Message, ExpectedReason) > 0, 'Unexpected card-resolution diagnostic: ' + CorpCardException.Message);
    end;

    local procedure AssertNoFullNumberRetained(CorpCardStatement: Record "EA Corp Card Statement")
    var
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        CorpCardException.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardException.FindSet();
        repeat
            Assert.AreEqual(0, StrPos(CorpCardException.Message, '4111111111111111'), 'Validation diagnostics must not disclose a supplied full card number.');
        until CorpCardException.Next() = 0;
        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardTrans.FindSet();
        repeat
            Assert.AreEqual(0, StrPos(CorpCardTrans."Card Id", '4111111111111111'), 'Imported internal card identifiers must not contain the supplied full number.');
            Assert.AreEqual(4, StrLen(CorpCardTrans."Card Last 4"), 'Only the accepted four-digit suffix may be staged.');
        until CorpCardTrans.Next() = 0;
        CorpCardTestLib.AssertNoSourceFile(CorpCardStatement);
    end;
}
