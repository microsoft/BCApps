codeunit 144060 "SEPA CAMT Bank Statement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SEPA CAMT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryCAMTFileMgt: Codeunit "Library - CAMT File Mgt.";
        BankAccountMissMatchErr: Label 'Bank account %1 does not have the bank account number %2, as specified in the bank statement file.\\Do you want to continue?', Comment = '%1=Value';
        IncorrectNamespaceErr: Label 'The imported file contains unsupported namespace "%1". The supported namespace is ''%2''.', Comment = '%1=File XML Namespace,%2=Supported XML Namespace';
        IncorrectValueForTypeErr: Label 'Incorrect description value for type %1.';
        MissingStatementDateInDataErr: Label 'The statement date was not found in the data to be imported.';
        MissingBalTypeInDataErr: Label 'The balance type was not found in the data to be imported.';
        MissingClosingBalanceInDataErr: Label 'The balance type was not found in the data to be imported.';
        MissingCrdtDbtIndInDataErr: Label 'The credit/debit indicator was not found in the data to be imported.';
        MissingCrdtDbtIndInNtryDataErr: Label 'The value in line 1, column 11 is missing.';
        MissingBankAccountInDataErr: Label 'The bank account number was not found in the data to be imported.';
        WrongCurrencyErr: Label 'The bank statement that you are importing contains transactions in currencies other than the Currency Code %1 of bank account %2.';
        WrongFileFormatErr: Label 'A call to System.Xml.XmlDocument.Load failed';
        WrongValueFormatErr: Label 'Expected format: Decimal, according to the Data Format and Data Formatting Culture of the Data Exch. Column Def.';
        WrongNrOfCBGStatementLinesErr: Label 'Wrong number of CBG statement lines created for ';
        CBGStatementProcessedMsg: Label '1 CBGStatement number has been processed containing 1 CBGStatement line';
        UnexpectedMessageErr: Label 'Unexpected message received.';

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure SunshineCBGStatementImportNetCreditBalanceWithIBAN()
    var
        CBGStatement: Record "CBG Statement";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
    begin
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);

        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        VerifyCBGStatement(
          CBGStatement, GenJournalTemplate, TempCBGStatement, TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount, 1);
        VerifyCBGStatementLine(CBGStatement, TempCreditCBGStatementLine, -1, 1);
        VerifyCBGStatementLine(CBGStatement, TempDebitCBGStatementLine, 1, 1);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure SunshineCBGStatementImportNetDebitBalanceWithLocalAccountNo()
    var
        CBGStatement: Record "CBG Statement";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
    begin
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", true);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, TempCreditCBGStatementLine.Amount + LibraryRandom.RandDec(10000, 2));

        InitCommonFileParameters(SEPACAMTFileParameters, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.BankAccountNoFieldValue := BankAccount."Bank Account No.";
        SEPACAMTFileParameters.CcyFieldValue := BankAccount."Currency Code";
        SEPACAMTFileParameters.ClsBalFieldValue := Format(Abs(TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount), 0, 9);

        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        VerifyCBGStatement(
          CBGStatement, GenJournalTemplate, TempCBGStatement, TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount, 1);
        VerifyCBGStatementLine(CBGStatement, TempCreditCBGStatementLine, -1, 1);
        VerifyCBGStatementLine(CBGStatement, TempDebitCBGStatementLine, 1, 1);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure PropertyInheritanceWhenMissingAmtFromTxDtlsNode()
    var
        CBGStatement: Record "CBG Statement";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
    begin
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.SkipTxDtlsAmt := true;
        SEPACAMTFileParameters.UstrdFieldValue1 := InitUnstructuredTextFieldValue();
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        VerifyCBGStatement(
          CBGStatement, GenJournalTemplate, TempCBGStatement, TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount, 1);
        // Verify only 2 CBG Statement Lines should have been created (i.e. the 3rd line, the parent, should have been deleted)
        VerifyCBGStatementLineInheritance(CBGStatement, 2);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure CBGStatementImportWithAdditionalEntryInfo()
    var
        CBGStatement: Record "CBG Statement";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        AddtlNtryInfFieldVal: Text[250];
    begin
        AddtlNtryInfFieldVal := InitAdditionalEntryInfFieldValue(25);

        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.AddtlNtryInfFieldValue := AddtlNtryInfFieldVal;
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        VerifyCBGStatement(
          CBGStatement, GenJournalTemplate, TempCBGStatement, TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount, 1);
        VerifyCBGStatementLine(CBGStatement, TempCreditCBGStatementLine, -1, 1);
        VerifyCBGStatementLineAndDescription(CBGStatement, TempDebitCBGStatementLine, 1, 1,
          CopyStr(AddtlNtryInfFieldVal, 1, MaxStrLen(TempDebitCBGStatementLine.Description)));
        VerifyCBGStatementLineAndAdditionalInfo(CBGStatement, TempDebitCBGStatementLine, 1, AddtlNtryInfFieldVal);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure CBGStatementImportWithUstrdTextAndAdditionalEntryInfo()
    var
        CBGStatement: Record "CBG Statement";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        AddtlNtryInfFieldVal: Text[250];
        UstrdFieldVal: Text[140];
    begin
        AddtlNtryInfFieldVal := InitAdditionalEntryInfFieldValue(10);
        UstrdFieldVal := InitUnstructuredTextFieldValue();

        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.AddtlNtryInfFieldValue := AddtlNtryInfFieldVal;
        SEPACAMTFileParameters.UstrdFieldValue1 := UstrdFieldVal;
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        VerifyCBGStatement(
          CBGStatement, GenJournalTemplate, TempCBGStatement, TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount, 1);
        VerifyCBGStatementLine(CBGStatement, TempCreditCBGStatementLine, -1, 1);
        VerifyCBGStatementLineAndDescription(CBGStatement, TempDebitCBGStatementLine, 1, 1,
          CopyStr(AddtlNtryInfFieldVal, 1, MaxStrLen(TempDebitCBGStatementLine.Description)));
        VerifyCBGStatementLineAndAdditionalInfo(CBGStatement, TempDebitCBGStatementLine, 1, AddtlNtryInfFieldVal + UstrdFieldVal);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure CBGStatementImportWithMultipleUstrdTexts()
    var
        CBGStatement: Record "CBG Statement";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        UstrdFieldVal1: Text[140];
        UstrdFieldVal2: Text[140];
        UstrdFieldVal3: Text[140];
    begin
        UstrdFieldVal1 := InitUnstructuredTextFieldValue();
        UstrdFieldVal2 := InitUnstructuredTextFieldValue();
        UstrdFieldVal3 := InitUnstructuredTextFieldValue();

        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.UstrdFieldValue1 := UstrdFieldVal1;
        SEPACAMTFileParameters.UstrdFieldValue2 := UstrdFieldVal2;
        SEPACAMTFileParameters.UstrdFieldValue3 := UstrdFieldVal3;

        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        VerifyCBGStatement(
          CBGStatement, GenJournalTemplate, TempCBGStatement, TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount, 1);
        VerifyCBGStatementLine(CBGStatement, TempCreditCBGStatementLine, -1, 1);
        VerifyCBGStatementLine(CBGStatement, TempDebitCBGStatementLine, 1, 1);
        VerifyCBGStatementLineAndAdditionalInfo(
          CBGStatement, TempDebitCBGStatementLine, 1, UstrdFieldVal1 + UstrdFieldVal2 + UstrdFieldVal3);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure DateTimeValue()
    var
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        ImportProtocol: Record "Import Protocol";
    begin
        // Pre-setup.
        CreateCommonSetup(ImportProtocol, SEPACAMTFileParameters);

        // Setup.
        SEPACAMTFileParameters.StmtDateFieldValue := '2013-04-12T10:55:08.66+02:00';
        WriteCAMTFile(SEPACAMTFileParameters);

        // Verify - the verification is that there is no err when reading DateTime format
        RunImportSEPACAMTReport(ImportProtocol.Code);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MissingBalanceTag()
    var
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        ImportProtocol: Record "Import Protocol";
    begin
        // Pre-setup.
        CreateCommonSetup(ImportProtocol, SEPACAMTFileParameters);

        // Setup.
        SEPACAMTFileParameters.HasClosingBalanceTag := false;
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReportExpectMessage(ImportProtocol.Code, MissingBalTypeInDataErr);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure MissingBankAccountInformation()
    var
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        ImportProtocol: Record "Import Protocol";
    begin
        // Pre-setup.
        CreateCommonSetup(ImportProtocol, SEPACAMTFileParameters);
        SEPACAMTFileParameters.BankAccountNoFieldValue := '';
        SEPACAMTFileParameters.IBANFieldValue := '';

        // Setup.
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        asserterror RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        Assert.ExpectedError(MissingBankAccountInDataErr);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MissingCdtDbtIndTagInBal()
    var
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        ImportProtocol: Record "Import Protocol";
    begin
        // Pre-setup.
        CreateCommonSetup(ImportProtocol, SEPACAMTFileParameters);

        // Setup.
        SEPACAMTFileParameters.HasCdtDbtIndTagInBal := false;
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReportExpectMessage(ImportProtocol.Code, MissingCrdtDbtIndInDataErr);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure MissingCdtDbtIndTagInNtry()
    var
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        ImportProtocol: Record "Import Protocol";
    begin
        // Pre-setup.
        CreateCommonSetup(ImportProtocol, SEPACAMTFileParameters);

        // Setup.
        SEPACAMTFileParameters.HasCdtDbtIndTagInNtry := false;
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        asserterror RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        Assert.ExpectedError(MissingCrdtDbtIndInNtryDataErr);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MissingClosingBalance()
    var
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        ImportProtocol: Record "Import Protocol";
    begin
        // Pre-setup.
        CreateCommonSetup(ImportProtocol, SEPACAMTFileParameters);

        // Setup.
        SEPACAMTFileParameters.CdFieldValue := 'BAD ';
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReportExpectMessage(ImportProtocol.Code, MissingClosingBalanceInDataErr);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MissingStatementDateTag()
    var
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        ImportProtocol: Record "Import Protocol";
    begin
        // Pre-setup.
        CreateCommonSetup(ImportProtocol, SEPACAMTFileParameters);

        // Setup.
        SEPACAMTFileParameters.HasStatementDateTag := false;
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReportExpectMessage(ImportProtocol.Code, MissingStatementDateInDataErr);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MissingStatementDateValue()
    var
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        ImportProtocol: Record "Import Protocol";
    begin
        // Pre-setup.
        CreateCommonSetup(ImportProtocol, SEPACAMTFileParameters);

        // Setup.
        SEPACAMTFileParameters.StmtDateFieldValue := '';
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReportExpectMessage(ImportProtocol.Code, MissingStatementDateInDataErr);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure NoPartialImport()
    var
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        UstrdFieldVal: Text[80];
    begin
        // Importing a file containing 2 bank statements. If the first one is correct, but the second statement yields an error, the whole import is not done.
        // Expected: neither statement 1 nor statement 2 has been imported.
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);
        UstrdFieldVal := LibraryUtility.GenerateGUID();

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.DbitFieldValue := 'wrongly formatted amount';
        SEPACAMTFileParameters.AddtlNtryInfFieldValue := InitAdditionalEntryInfFieldValue(1);
        SEPACAMTFileParameters.UstrdFieldValue1 := UstrdFieldVal;

        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        asserterror RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify that nothing was imported
        Assert.ExpectedError(WrongValueFormatErr);
        Assert.ExpectedError(SEPACAMTFileParameters.DbitFieldValue);
        VerifyNoTableDataWasCreated(
          TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine, GenJournalTemplate, UstrdFieldVal);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure WrongCurrency()
    var
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        CurrencyCode: Text[30];
    begin
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CurrencyCode := Format(LibraryRandom.RandIntInRange(100, 999));
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);

        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempCreditCBGStatementLine);
        SEPACAMTFileParameters.CcyFieldValue := CurrencyCode;
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        asserterror RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        Assert.ExpectedError(StrSubstNo(WrongCurrencyErr, BankAccount."Currency Code", BankAccount."No."));
        VerifyNoTableDataWasCreated(TempCBGStatement, TempCreditCBGStatementLine, TempCreditCBGStatementLine, GenJournalTemplate, '');
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WrongLocalBankAccount()
    var
        DummyBankAccountNo: Text[30];
    begin
        DummyBankAccountNo := Format(LibraryRandom.RandIntInRange(111111, 222222));
        WrongBankAccount(DummyBankAccountNo, '');
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WrongIBAN()
    var
        DummyIBAN: Text[50];
    begin
        DummyIBAN := Format(LibraryRandom.RandIntInRange(111111, 222222));
        WrongBankAccount('', DummyIBAN);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure WrongImportFileFormat()
    var
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup - create a file... not XML
        WriteNonXmlFile();

        // Exercise
        asserterror RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        Assert.ExpectedError(WrongFileFormatErr);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure WrongNamespace()
    var
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        SupportedNamespace: Text[100];
        UnsupportedNamespace: Text[100];
    begin
        // Pre-setup
        CreateCommonSetup(ImportProtocol, SEPACAMTFileParameters);

        SupportedNamespace := 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.02';
        UnsupportedNamespace := 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.03';
        SEPACAMTFileParameters.Namespace := UnsupportedNamespace;
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        asserterror RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        Assert.ExpectedError(StrSubstNo(IncorrectNamespaceErr, UnsupportedNamespace, SupportedNamespace));
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure CBGStatementImportNLMappingNetCreditBalance()
    var
        CBGStatement: Record "CBG Statement";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
    begin
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        InitCommonFileParameters(SEPACAMTFileParameters, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.IBANFieldValue := BankAccount.IBAN;
        SEPACAMTFileParameters.ClsBalFieldValue := Format(Abs(TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount), 0, 9);
        SEPACAMTFileParameters.CcyFieldValue := BankAccount."Currency Code";

        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        VerifyCBGStatement(
          CBGStatement, GenJournalTemplate, TempCBGStatement, TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount, 1);
        VerifyCBGStatementLine(CBGStatement, TempCreditCBGStatementLine, -1, 1);
        VerifyCBGStatementLine(CBGStatement, TempDebitCBGStatementLine, 1, 1);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure CBGStatementImportNLMappingNetDebitBalance()
    var
        CBGStatement: Record "CBG Statement";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
    begin
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, TempCreditCBGStatementLine.Amount + LibraryRandom.RandDec(10000, 2));

        InitCommonFileParameters(SEPACAMTFileParameters, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.IBANFieldValue := BankAccount.IBAN;
        SEPACAMTFileParameters.ClsBalFieldValue := Format(Abs(TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount), 0, 9);
        SEPACAMTFileParameters.CcyFieldValue := BankAccount."Currency Code";

        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        VerifyCBGStatement(
          CBGStatement, GenJournalTemplate, TempCBGStatement, TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount, 1);
        VerifyCBGStatementLine(CBGStatement, TempCreditCBGStatementLine, -1, 1);
        VerifyCBGStatementLine(CBGStatement, TempDebitCBGStatementLine, 1, 1);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure ImportCBGStatementAddInfo()
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
    begin
        // CBG Statement Line Add. Info. should be created on Import Bank Statement
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        CBGStatementLineAddInfo.Init();
        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.RelatedPartyName := LibraryUtility.GenerateGUID();
        SEPACAMTFileParameters.RelatedPartyAddress := LibraryUtility.GenerateGUID();
        SEPACAMTFileParameters.RelatedPartyCity := LibraryUtility.GenerateGUID();
        SEPACAMTFileParameters.RelatedPartyBankAccount := BankAccount."Bank Account No.";
        SEPACAMTFileParameters.AddtlNtryInfFieldValue :=
          PadStr(LibraryUtility.GenerateGUID(), MaxStrLen(CBGStatementLineAddInfo.Description), '0');
        SEPACAMTFileParameters.AddtlNtryInfFieldValue += LibraryUtility.GenerateGUID();

        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        VerifyCBGStatementAddInfo(SEPACAMTFileParameters, BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure RelatedPartyLocalBankAccount()
    var
        CBGStatement: Record "CBG Statement";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
    begin
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.RelatedPartyBankAccount := BankAccount."Bank Account No.";

        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        VerifyCBGStatement(
          CBGStatement, GenJournalTemplate, TempCBGStatement, TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount, 1);
        VerifyCBGStatementLine(CBGStatement, TempCreditCBGStatementLine, -1, 1);
        VerifyCBGStatementLine(CBGStatement, TempDebitCBGStatementLine, 1, 1);
        VerifyRelatedPartyBankAccount(CBGStatement, TempCreditCBGStatementLine, BankAccount, -1, false, true);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure RelatedPartyIBAN()
    var
        CBGStatement: Record "CBG Statement";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
    begin
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.RelatedPartyIBAN := BankAccount.IBAN;
        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // Verify.
        VerifyCBGStatement(
          CBGStatement, GenJournalTemplate, TempCBGStatement, TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount, 1);
        VerifyCBGStatementLine(CBGStatement, TempCreditCBGStatementLine, -1, 1);
        VerifyCBGStatementLine(CBGStatement, TempDebitCBGStatementLine, 1, 1);
        VerifyRelatedPartyBankAccount(CBGStatement, TempDebitCBGStatementLine, BankAccount, 1, true, false);
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure ImportCBGStatementIdentification()
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
    begin
        // [SCENARIO 308982] CBG Statement Line Add. Info. with Information Type "Payment Identification" is created on Import Bank Statement.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // [GIVEN] XML file with SEPA CAMT Bank Statement, that is imported to CBG Statement.
        // [GIVEN] "Stmt/Ntry/NtryDtls/TxDtls/Refs/EndToEndId" has value "A".
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.EndToEndIdFieldValue := LibraryUtility.GenerateGUID();
        WriteCAMTFile(SEPACAMTFileParameters);

        // [WHEN] Import XML file.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // [THEN] "CBG Statement Line Add. Info" with Information Type = "Payment Identification" and Description = "A" is created.
        VerifyCBGStatementAddInfoEntry(BankAccount."No.", CBGStatementLineAddInfo."Information Type"::"Payment Identification",
          SEPACAMTFileParameters.EndToEndIdFieldValue, '');
    end;

    [Test]
    [HandlerFunctions('ImportProtocolListPageHandler')]
    [Scope('OnPrem')]
    procedure ImportCBGStatementIdentificationWithoutEndToEndIdColumnDef()
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
        TempDataExchColumnDef: Record "Data Exch. Column Def" temporary;
    begin
        // [SCENARIO 308982] CBG Statement Line Add. Info. with Info. Type "Payment Identification" is not created on Import Bank Statement in case Data Exch Column Def does not exist.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // [GIVEN] Data Exch. Column Def. for "SEPA CAMT" with Path = ".../Stmt/Ntry/NtryDtls/TxDtls/Refs/EndToEndId" is removed.
        RemoveDataExchColumnDef(TempDataExchColumnDef, 'SEPA CAMT', GetEndToEndIdPath());

        // [GIVEN] XML file with SEPA CAMT Bank Statement, that is imported to CBG Statement.
        // [GIVEN] "Stmt/Ntry/NtryDtls/TxDtls/Refs/EndToEndId" has value "A".
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));

        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.EndToEndIdFieldValue := LibraryUtility.GenerateGUID();
        WriteCAMTFile(SEPACAMTFileParameters);

        // [WHEN] Import XML file.
        RunImportSEPACAMTReport(ImportProtocol.Code);

        // [THEN] "CBG Statement Line Add. Info" with Information Type = "Payment Identification" and Description = "A" is not created.
        VerifyCBGStatementAddInfoEntryNotExists(BankAccount."No.", CBGStatementLineAddInfo."Information Type"::"Payment Identification",
          SEPACAMTFileParameters.EndToEndIdFieldValue);

        Assert.TableIsEmpty(DATABASE::"Payment Export Data");

        // Tear down
        RestoreDataExchColumnDef(TempDataExchColumnDef);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UTCBGStatementReconcileForMaxLengthValuesInAddInfo()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
    begin
        // [SCENARIO 122516] CBG Statement Reconciliation for Name/Address/City with max length in "CBG Statement Line Add. Info."
        // [GIVEN] CBG Statement with Name/Address/City of max length in "CBG Statement Line Add. Info."
        MockCBGStatementWithLine(CBGStatement, CBGStatementLine);

        MockCBGStatementLineAddInfo(CBGStatementLine, CBGStatementLineAddInfo."Information Type"::"Name Acct. Holder");
        MockCBGStatementLineAddInfo(CBGStatementLine, CBGStatementLineAddInfo."Information Type"::"Address Acct. Holder");
        MockCBGStatementLineAddInfo(CBGStatementLine, CBGStatementLineAddInfo."Information Type"::"City Acct. Holder");

        // [WHEN] Run CBG Statement Reconciliation
        LibraryVariableStorage.Enqueue(CBGStatementProcessedMsg);
        CBGStatementReconciliation.MatchCBGStatement(CBGStatement);

        // [THEN] Get message that CBG Statement has been processed
        // verification is done by MessageHandler
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyTaxAmountFromTagInstdAmt()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TempBlob: Codeunit "Temp Blob";
        InstdAmt: Integer;
    begin
        // [SCENARIO 218742] Value of amount can be loaded from tag "InstdAmt" if used Data Exchange Definition - "SEPA CAMT"

        // [GIVEN] XML file with Bank Statement
        // [GIVEN] "BkToCstmrStmt/Stmt/Ntry/Amt" = 5
        // [GIVEN] "BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/AmtDtls/InstdAmt/Amt" = 10
        InstdAmt := CreateXmlFileWithBankStatement(TempBlob);

        // [GIVEN] Bank Account with "Bank Statement Import Format" = "SEPA CAMT"
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Statement Import Format", 'SEPA CAMT');
        BankAccount.Modify(true);

        // [GIVEN] Bank Acc. Reconcilation
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryCAMTFileMgt.SetupSourceMock('SEPA CAMT', TempBlob);

        // [WHEN] Import xml file
        BankAccReconciliation.ImportBankStatement();

        // [THEN] Create one Bank Acc. Reconciliation Line
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccount."No.");
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type"::"Payment Application");
        Assert.RecordCount(BankAccReconciliationLine, 1);

        // [THEN] "Bank Acc. Reconciliation Line"."Statement Amount" = 10
        BankAccReconciliationLine.FindFirst();
        BankAccReconciliationLine.TestField("Statement Amount", InstdAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportNameFieldLengthImportProtocol()
    var
        ImportProtocol: Record "Import Protocol";
        AllObjWithCaption: Record AllObjWithCaption;
        LibraryTablesUT: Codeunit "Library - Tables UT";
    begin
        // [FEATURE] [UT] [Import Protocol]
        // [SCENARIO 269016] Import Name in Import Protocol has same length as Object Caption in AllObjWithCaption
        LibraryTablesUT.CompareFieldTypeAndLength(
          AllObjWithCaption, AllObjWithCaption.FieldNo("Object Caption"),
          ImportProtocol, ImportProtocol.FieldNo("Import Name"));
    end;

    local procedure ConvertEncoding(SourceTempBlob: Codeunit "Temp Blob"; var DestinationTempBlob: Codeunit "Temp Blob"; Encoding: DotNet Encoding)
    var
        Writer: DotNet StreamWriter;
        InStream: InStream;
        OutStream: OutStream;
        EncodedText: Text;
    begin
        SourceTempBlob.CreateInStream(InStream);
        DestinationTempBlob.CreateOutStream(OutStream);

        Writer := Writer.StreamWriter(OutStream, Encoding);

        while 0 <> InStream.ReadText(EncodedText) do
            Writer.WriteLine(EncodedText);

        Writer.Close();
    end;

    local procedure CreateImportProtocol(var ImportProtocol: Record "Import Protocol"; BankAccountNo: Code[20]; AutoReconciliation: Boolean)
    begin
        ImportProtocol.Init();
        ImportProtocol.Validate(Code, LibraryUtility.GenerateRandomCode(ImportProtocol.FieldNo(Code), DATABASE::"Import Protocol"));
        ImportProtocol.Validate("Import Type", ImportProtocol."Import Type"::Codeunit);
        ImportProtocol.Validate("Import ID", CODEUNIT::"Import SEPA CAMT");
        ImportProtocol.Validate("Automatic Reconciliation", AutoReconciliation);
        ImportProtocol.Validate("Bank Account No.", BankAccountNo);
        ImportProtocol.Insert(true);
    end;

    local procedure CreateBankAccWithBankStatementSetup(var BankAccount: Record "Bank Account"; var GenJournalTemplate: Record "Gen. Journal Template"; DataExchDefCode: Code[20])
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        SetupFileDefinition(BankExportImportSetup, DataExchDefCode);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Statement No.",
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Last Statement No."), DATABASE::"Bank Account"));
        BankAccount."Bank Statement Import Format" := BankExportImportSetup.Code;
        BankAccount.IBAN :=
          Format(LibraryRandom.RandIntInRange(555555, 999999));
        BankAccount."Bank Account No." :=
          Format(LibraryRandom.RandIntInRange(555555, 999999));
        BankAccount.Validate("Currency Code", 'RON');

        BankAccount.Modify(true);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Bal. Account Type", GenJournalTemplate."Bal. Account Type"::"Bank Account");
        GenJournalTemplate.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Bank);
        GenJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalTemplate.Modify();
    end;

    local procedure CreateBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup"; DataExchDefCode: Code[20])
    begin
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup."Processing Codeunit ID" := 0;
        BankExportImportSetup."Data Exch. Def. Code" := DataExchDefCode;
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Import;
        BankExportImportSetup.Insert();
    end;

    local procedure CreateExpectedCBGStatement(var TempCreditCBGStatementLine: Record "CBG Statement Line" temporary; var TempCBGStatement: Record "CBG Statement" temporary; BankAccount: Record "Bank Account")
    begin
        CreateExpectedCBGStatementLine(TempCreditCBGStatementLine, LibraryRandom.RandDec(1000000, 2));
        TempCBGStatement."Account Type" := TempCBGStatement."Account Type"::"Bank Account";
        if BankAccount."Bank Account No." <> '' then
            TempCBGStatement."Account No." := CopyStr(BankAccount."Bank Account No.", 1, MaxStrLen(TempCBGStatement."Account No."));
        if BankAccount.IBAN <> '' then
            TempCBGStatement."Account No." := CopyStr(BankAccount.IBAN, 1, MaxStrLen(TempCBGStatement."Account No."));
        TempCBGStatement.Currency := BankAccount."Currency Code";
        TempCBGStatement.Date := TempCreditCBGStatementLine.Date + LibraryRandom.RandInt(10);
        TempCBGStatement.Insert();
    end;

    local procedure CreateExpectedCBGStatementLine(var TempCreditCBGStatementLine: Record "CBG Statement Line" temporary; Amount: Decimal)
    begin
        TempCreditCBGStatementLine.Date := WorkDate() + LibraryRandom.RandInt(10);
        TempCreditCBGStatementLine."Document No." :=
          LibraryUtility.GenerateRandomCode(TempCreditCBGStatementLine.FieldNo("Document No."), DATABASE::"CBG Statement Line");
        TempCreditCBGStatementLine.Amount := Amount;
        TempCreditCBGStatementLine.Insert();
    end;

    [HandlerFunctions('ImportProtocolListPageHandler')]
    local procedure CreateCommonSetup(var ImportProtocol: Record "Import Protocol"; var SEPACAMTFileParameters: Record "SEPA CAMT File Parameters"): Code[20]
    var
        BankAccount: Record "Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempDebitCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
    begin
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);
        CreateExpectedCBGStatementLine(
          TempDebitCBGStatementLine, LibraryRandom.RandDecInDecimalRange(1, TempCreditCBGStatementLine.Amount, 2));
        InitSunshineFileParameters(
          SEPACAMTFileParameters, BankAccount, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);

        exit(BankAccount."No.");
    end;

    local procedure CreateNtryDataExchLineDef(DataExchDef: Record "Data Exch. Def")
    var
        CamtDataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        CBGStatementLine: Record "CBG Statement Line";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        CamtDataExchLineDef.InsertRec(DataExchDef.Code, 'SEPA CAMT', '', 0);
        CamtDataExchLineDef."Data Line Tag" := '/Document/BkToCstmrStmt/Stmt/Ntry';
        CamtDataExchLineDef.Namespace := 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.02';
        CamtDataExchLineDef.Modify();
        CreateDataExchColumnDef(CamtDataExchLineDef, 1,
          DataExchColumnDef."Data Type"::Date, '', '', '', '/Document/BkToCstmrStmt/Stmt/CreDtTm');
        CreateDataExchColumnDef(CamtDataExchLineDef, 2,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Acct/Id/IBAN');
        CreateDataExchColumnDef(CamtDataExchLineDef, 14,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Acct/Id/Othr/Id');
        CreateDataExchColumnDef(CamtDataExchLineDef, 3,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Bal/Tp/CdOrPrtry/Cd');
        CreateDataExchColumnDef(CamtDataExchLineDef, 4,
          DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '', '/Document/BkToCstmrStmt/Stmt/Bal/Amt');
        CreateDataExchColumnDef(CamtDataExchLineDef, 5,
          DataExchColumnDef."Data Type"::Decimal, '', '', 'DBIT', '/Document/BkToCstmrStmt/Stmt/Bal/CdtDbtInd');
        CreateDataExchColumnDef(CamtDataExchLineDef, 6,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Bal/Amt[@Ccy]');
        CreateDataExchColumnDef(CamtDataExchLineDef, 7,
          DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '', '/Document/BkToCstmrStmt/Stmt/Ntry/Amt');
        CreateDataExchColumnDef(CamtDataExchLineDef, 8,
          DataExchColumnDef."Data Type"::Decimal, '', '', 'DBIT', '/Document/BkToCstmrStmt/Stmt/Ntry/CdtDbtInd');
        CreateDataExchColumnDef(CamtDataExchLineDef, 9,
          DataExchColumnDef."Data Type"::Date, '', '', '', '/Document/BkToCstmrStmt/Stmt/Ntry/BookgDt/DtTm');
        CreateDataExchColumnDef(CamtDataExchLineDef, 10,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Ntry/AcctSvcrRef');
        CreateDataExchColumnDef(CamtDataExchLineDef, 11,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Ntry/AddtlNtryInf');
        CreateDataExchColumnDef(CamtDataExchLineDef, 12,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RmtInf/Ustrd');
        CreateDataExchColumnDef(CamtDataExchLineDef, 17,
          DataExchColumnDef."Data Type"::Text, '', '', '',
          '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Dbtr/PstlAdr/AdrLine');
        CreateDataExchColumnDef(CamtDataExchLineDef, 18,
          DataExchColumnDef."Data Type"::Text, '', '', '',
          '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Dbtr/PstlAdr/TwnNm');
        CreateDataExchColumnDef(CamtDataExchLineDef, 19,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Dbtr/Nm');

        SetupFieldMapping(
          DataExchDef.Code, CamtDataExchLineDef.Code, CODEUNIT::"Process CBG Statement Lines",
          CBGStatementLine.FieldNo("Data Exch. Entry No."),
          CBGStatementLine.FieldNo("Data Exch. Line No."), CODEUNIT::"Imp. SEPA CAMT Pre-Mapping",
          CODEUNIT::"Imp. SEPA CAMT Post-Mapping");

        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, CamtDataExchLineDef.Code, DATABASE::"CBG Statement Line", 7, CBGStatementLine.FieldNo(Amount), false, -1);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, CamtDataExchLineDef.Code, DATABASE::"CBG Statement Line", 8, CBGStatementLine.FieldNo(Amount), false, 1);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, CamtDataExchLineDef.Code, DATABASE::"CBG Statement Line", 9, CBGStatementLine.FieldNo(Date), false, 1);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, CamtDataExchLineDef.Code, DATABASE::"CBG Statement Line", 10, CBGStatementLine.FieldNo("Document No."),
          false, 1);
    end;

    local procedure CreateTxDtlsDataExchLineDef(DataExchDef: Record "Data Exch. Def")
    var
        CamtTxDataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        CBGStatementLine: Record "CBG Statement Line";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        CamtTxDataExchLineDef.InsertRec(DataExchDef.Code, 'SEPA CAMT TX', '', 0);
        CamtTxDataExchLineDef."Data Line Tag" := '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls';
        CamtTxDataExchLineDef.Namespace := 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.02';
        CamtTxDataExchLineDef.Modify(true);
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 6,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Bal/Amt[@Ccy]');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 5,
          DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '', '/Document/BkToCstmrStmt/Stmt/Ntry/Amt');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 7,
          DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '', '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/AmtDtls/TxAmt/Amt');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 8,
          DataExchColumnDef."Data Type"::Decimal, '', '', 'DBIT', '/Document/BkToCstmrStmt/Stmt/Ntry/CdtDbtInd');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 9,
          DataExchColumnDef."Data Type"::Date, '', '', '', '/Document/BkToCstmrStmt/Stmt/Ntry/BookgDt/DtTm');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 10,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Ntry/AcctSvcrRef');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 11,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Ntry/AddtlNtryInf');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 12,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RmtInf/Ustrd');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 13,
          DataExchColumnDef."Data Type"::Text, '', '', '',
          '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/DbtrAcct/Id/IBAN');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 14,
          DataExchColumnDef."Data Type"::Text, '', '', '',
          '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/CdtrAcct/Id/IBAN');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 15,
          DataExchColumnDef."Data Type"::Text, '', '', '',
          '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/DbtrAcct/Id/Othr/Id');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 16,
          DataExchColumnDef."Data Type"::Text, '', '', '',
          '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/CdtrAcct/Id/Othr/Id');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 17,
          DataExchColumnDef."Data Type"::Text, '', '', '',
          '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Dbtr/PstlAdr/AdrLine');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 18,
          DataExchColumnDef."Data Type"::Text, '', '', '',
          '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Dbtr/PstlAdr/TwnNm');
        CreateDataExchColumnDef(CamtTxDataExchLineDef, 19,
          DataExchColumnDef."Data Type"::Text, '', '', '', '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Dbtr/Nm');

        SetupFieldMapping(
          DataExchDef.Code, CamtTxDataExchLineDef.Code, CODEUNIT::"Process CBG Statement Lines",
          CBGStatementLine.FieldNo("Data Exch. Entry No."),
          CBGStatementLine.FieldNo("Data Exch. Line No."), 0, CODEUNIT::"Imp. SEPA CAMT Post-Mapping");

        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, CamtTxDataExchLineDef.Code, DATABASE::"CBG Statement Line", 5, CBGStatementLine.FieldNo(Amount), true, -1);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, CamtTxDataExchLineDef.Code, DATABASE::"CBG Statement Line", 7, CBGStatementLine.FieldNo(Amount), true, -1);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, CamtTxDataExchLineDef.Code, DATABASE::"CBG Statement Line", 8, CBGStatementLine.FieldNo(Amount), true, 1);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, CamtTxDataExchLineDef.Code, DATABASE::"CBG Statement Line", 9, CBGStatementLine.FieldNo(Date), true, 1);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, CamtTxDataExchLineDef.Code, DATABASE::"CBG Statement Line", 10, CBGStatementLine.FieldNo("Document No."),
          true, 1);
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def")
    begin
        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), '', DataExchDef.Type::"Bank Statement Import", 0, 0, '', '');
        DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"ERM PE Source Test Mock";
        DataExchDef."Reading/Writing Codeunit" := CODEUNIT::"Import Bank Statement";
        DataExchDef."File Encoding" := DataExchDef."File Encoding"::"UTF-8";
        DataExchDef.Modify();

        CreateNtryDataExchLineDef(DataExchDef);
        CreateTxDtlsDataExchLineDef(DataExchDef);
    end;

    local procedure CreateDataExchColumnDef(DataExchLineDef: Record "Data Exch. Line Def"; ColumnNo: Integer; DataType: Option; DataTypeFormatting: Text[100]; DataFormattingCulture: Text[10]; NegativeSignIdentifier: Text[30]; Path: Text[250])
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.InsertRec(DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, ColumnNo, Format(ColumnNo),
          true, DataType, DataTypeFormatting, DataFormattingCulture, '');
        DataExchColumnDef.Path := Path;
        DataExchColumnDef."Negative-Sign Identifier" := NegativeSignIdentifier;
        DataExchColumnDef.Modify();
    end;

    local procedure CreateXmlFileWithBankStatement(var TempBlob: Codeunit "Temp Blob") InstdAmt: Integer
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        LibraryCAMTFileMgt.WriteCAMTHeader(OutStream);
        LibraryCAMTFileMgt.WriteCAMTStmtHeader(OutStream, '', LibraryUtility.GenerateGUID());
        InstdAmt := LibraryRandom.RandIntInRange(10, 100);
        LibraryCAMTFileMgt.WriteCAMTStmtLineWithInstdAmt(OutStream, WorkDate(), 'StmtText', InstdAmt / 2, '', '', InstdAmt, '');
        LibraryCAMTFileMgt.WriteCAMTStmtFooter(OutStream);
        LibraryCAMTFileMgt.WriteCAMTFooter(OutStream);
    end;

    local procedure GetEndToEndIdPath(): Text[250]
    begin
        exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/Refs/EndToEndId');
    end;

    local procedure InitAdditionalEntryInfFieldValue(Multiplier: Integer): Text[250]
    var
        AddtlNtryInfFieldVal: Text[250];
        Iterator: Integer;
    begin
        for Iterator := 1 to Multiplier do
            AddtlNtryInfFieldVal += LibraryUtility.GenerateGUID();
        exit(AddtlNtryInfFieldVal);
    end;

    local procedure InitCommonFileParameters(var SEPACAMTFileParameters: Record "SEPA CAMT File Parameters"; TempCBGStatement: Record "CBG Statement" temporary; TempCreditCBGStatementLine: Record "CBG Statement Line" temporary; TempDebitCBGStatementLine: Record "CBG Statement Line" temporary)
    begin
        SEPACAMTFileParameters.Encoding := 'UTF-8';
        SEPACAMTFileParameters.Namespace := 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.02';
        SEPACAMTFileParameters.StmtDateFieldValue := Format(TempCBGStatement.Date, 0, 9);
        SEPACAMTFileParameters.CrdtFieldValue := Format(TempCreditCBGStatementLine.Amount, 0, 9);
        SEPACAMTFileParameters.DbitFieldValue := Format(TempDebitCBGStatementLine.Amount, 0, 9);
        SEPACAMTFileParameters.CrdtDateFieldValue := Format(TempCreditCBGStatementLine.Date, 0, 9);
        SEPACAMTFileParameters.DbitDateFieldValue := Format(TempDebitCBGStatementLine.Date, 0, 9);
        SEPACAMTFileParameters.CrdtTextFieldValue := TempCreditCBGStatementLine."Document No.";
        SEPACAMTFileParameters.DbitTextFieldValue := TempDebitCBGStatementLine."Document No.";
        SEPACAMTFileParameters.NumberOfStatements := 1;
        SEPACAMTFileParameters.HasStatementDateTag := true;
        SEPACAMTFileParameters.HasClosingBalanceTag := true;
        SEPACAMTFileParameters.CdFieldValue := 'CLBD';
        SEPACAMTFileParameters.HasCdtDbtIndTagInBal := true;
        SEPACAMTFileParameters.HasCdtDbtIndTagInNtry := true;
        if TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount > 0 then
            SEPACAMTFileParameters.BalCrdtDbtFieldValue := 'CRDT'
        else
            SEPACAMTFileParameters.BalCrdtDbtFieldValue := 'DBIT';
    end;

    local procedure InitSunshineFileParameters(var SEPACAMTFileParameters: Record "SEPA CAMT File Parameters"; BankAccount: Record "Bank Account"; TempCBGStatement: Record "CBG Statement" temporary; TempCreditCBGStatementLine: Record "CBG Statement Line" temporary; TempDebitCBGStatementLine: Record "CBG Statement Line" temporary)
    begin
        InitCommonFileParameters(SEPACAMTFileParameters, TempCBGStatement, TempCreditCBGStatementLine, TempDebitCBGStatementLine);
        SEPACAMTFileParameters.IBANFieldValue := BankAccount.IBAN;
        SEPACAMTFileParameters.CcyFieldValue := BankAccount."Currency Code";
        SEPACAMTFileParameters.ClsBalFieldValue := Format(Abs(TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount), 0, 9);
    end;

    local procedure InitUnstructuredTextFieldValue(): Text[140]
    var
        UstrdFieldVal: Text[140];
        Iterator: Integer;
    begin
        for Iterator := 1 to 10 do
            UstrdFieldVal += LibraryUtility.GenerateGUID();
        exit(UstrdFieldVal);
    end;

    local procedure MockCBGStatementWithLine(var CBGStatement: Record "CBG Statement"; var CBGStatementLine: Record "CBG Statement Line")
    begin
        CBGStatement.Init();
        CBGStatement."No." := 1;
        CBGStatement.Insert();

        CBGStatementLine.Init();
        CBGStatementLine."No." := CBGStatement."No.";
        CBGStatementLine."Line No." := 1;
        CBGStatementLine.Insert();
    end;

    local procedure MockCBGStatementLineAddInfo(CBGStatementLine: Record "CBG Statement Line"; InformationType: Enum "CBG Statement Information Type")
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        RecRef: RecordRef;
    begin
        CBGStatementLineAddInfo.Init();
        CBGStatementLineAddInfo."CBG Statement No." := CBGStatementLine."No.";
        CBGStatementLineAddInfo."CBG Statement Line No." := CBGStatementLine."Line No.";
        RecRef.GetTable(CBGStatementLineAddInfo);
        CBGStatementLineAddInfo."Line No." := LibraryUtility.GetNewLineNo(RecRef, CBGStatementLineAddInfo.FieldNo("Line No."));
        CBGStatementLineAddInfo.Description := PadStr(LibraryUtility.GenerateGUID(), MaxStrLen(CBGStatementLineAddInfo.Description), '0');
        CBGStatementLineAddInfo."Information Type" := InformationType;
        CBGStatementLineAddInfo.Insert();
    end;

    local procedure RemoveDataExchColumnDef(var TempDataExchColumnDef: Record "Data Exch. Column Def" temporary; DataExchDefCode: Code[20]; Path: Text[250])
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchColumnDef.SetFilter(Path, Path);
        DataExchColumnDef.FindSet();
        repeat
            TempDataExchColumnDef := DataExchColumnDef;
            TempDataExchColumnDef.Insert();
        until DataExchColumnDef.Next() = 0;

        DataExchColumnDef.DeleteAll();
    end;

    local procedure RestoreDataExchColumnDef(var TempDataExchColumnDef: Record "Data Exch. Column Def" temporary)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        TempDataExchColumnDef.FindSet();
        repeat
            DataExchColumnDef := TempDataExchColumnDef;
            DataExchColumnDef.Insert();
        until TempDataExchColumnDef.Next() = 0;
    end;

    local procedure RunImportSEPACAMTReport(ImportProtocolCode: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ImportProtocolCode);
        CODEUNIT.Run(CODEUNIT::"Import Protocol Management");
    end;

    local procedure RunImportSEPACAMTReportExpectMessage(ImportProtocolCode: Code[20]; ExpectedMessage: Text)
    begin
        LibraryVariableStorage.Enqueue(ImportProtocolCode);
        LibraryVariableStorage.Enqueue(ExpectedMessage);
        CODEUNIT.Run(CODEUNIT::"Import Protocol Management");
    end;

    local procedure SetCBGStatementLineFilters(CBGStatement: Record "CBG Statement"; var ActualCBGStatementLine: Record "CBG Statement Line"; ExpectedCBGStatementLine: Record "CBG Statement Line"; Multiplier: Integer)
    begin
        ActualCBGStatementLine.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        ActualCBGStatementLine.SetRange("Statement Type", ActualCBGStatementLine."Statement Type"::"Bank Account");
        if CBGStatement."No." <> 0 then
            ActualCBGStatementLine.SetRange("No.", CBGStatement."No.");
        ActualCBGStatementLine.SetRange(Amount, Multiplier * ExpectedCBGStatementLine.Amount);
        ActualCBGStatementLine.SetRange(Date, ExpectedCBGStatementLine.Date);
    end;

    local procedure SetupFieldMapping(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; CodeunitId: Integer; EntryNoFieldId: Integer; LineNoFieldId: Integer; PreMappingCodeunitID: Integer; PostMappingCodeunitID: Integer)
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.InsertRec(
          DataExchDefCode, DataExchLineDefCode, DATABASE::"CBG Statement Line", '', CodeunitId, EntryNoFieldId, LineNoFieldId);
        DataExchMapping."Pre-Mapping Codeunit" := PreMappingCodeunitID;
        DataExchMapping."Post-Mapping Codeunit" := PostMappingCodeunitID;
        DataExchMapping.Modify(true);
    end;

    local procedure SetupFileDefinition(var BankExportImportSetup: Record "Bank Export/Import Setup"; DataExchDefCode: Code[20])
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        if not DataExchDef.Get(DataExchDefCode) then
            CreateDataExchDef(DataExchDef)
        else begin
            DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"ERM PE Source Test Mock";
            DataExchDef.Modify();
        end;
        CreateBankExportImportSetup(BankExportImportSetup, DataExchDef.Code);
    end;

    local procedure SetupSourceBlob(TempBlob: Codeunit "Temp Blob")
    var
        TempBlobList: Codeunit "Temp Blob List";
        ErmPeSourceTestMock: Codeunit "ERM PE Source Test Mock";
    begin
        TempBlobList.Add(TempBlob);
        ErmPeSourceTestMock.SetTempBlobList(TempBlobList);
    end;

    local procedure VerifyCBGStatement(var CBGStatement: Record "CBG Statement"; GenJnlTemplate: Record "Gen. Journal Template"; ExpectedCBGStatement: Record "CBG Statement"; ExpClosingBalance: Decimal; ExpectedNumberOfOccurrences: Integer)
    begin
        CBGStatement.SetRange("Journal Template Name", GenJnlTemplate.Name);
        CBGStatement.SetRange(Type, CBGStatement.Type::"Bank/Giro");
        CBGStatement.SetRange("Account Type", CBGStatement."Account Type"::"Bank Account");
        CBGStatement.SetRange("Account No.", GenJnlTemplate."Bal. Account No.");
        CBGStatement.SetRange("No. Series", GenJnlTemplate."No. Series");
        CBGStatement.SetRange(Date, ExpectedCBGStatement.Date);
        CBGStatement.SetRange("Closing Balance", ExpClosingBalance);
        CBGStatement.SetRange(Currency, ExpectedCBGStatement.Currency);
        Assert.AreEqual(ExpectedNumberOfOccurrences, CBGStatement.Count, WrongNrOfCBGStatementLinesErr + CBGStatement.GetFilters);
        if ExpectedNumberOfOccurrences > 0 then
            CBGStatement.FindFirst();
    end;

    local procedure VerifyCBGStatementLine(CBGStatement: Record "CBG Statement"; ExpectedCBGStatementLine: Record "CBG Statement Line"; Multiplier: Integer; ExpectedNumberOfOccurrences: Integer)
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        SetCBGStatementLineFilters(CBGStatement, CBGStatementLine, ExpectedCBGStatementLine, Multiplier);
        Assert.AreEqual(
          ExpectedNumberOfOccurrences, CBGStatementLine.Count, WrongNrOfCBGStatementLinesErr + CBGStatementLine.GetFilters);
    end;

    local procedure VerifyCBGStatementLineInheritance(CBGStatement: Record "CBG Statement"; ExpectedNumberOfOccurrences: Integer)
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        CBGStatementLine.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLine.SetRange("Statement Type", CBGStatementLine."Statement Type"::"Bank Account");
        if CBGStatement."No." <> 0 then
            CBGStatementLine.SetRange("No.", CBGStatement."No.");

        Assert.AreEqual(
          ExpectedNumberOfOccurrences, CBGStatementLine.Count, WrongNrOfCBGStatementLinesErr + CBGStatementLine.GetFilters);
    end;

    local procedure VerifyCBGStatementLineAndDescription(CBGStatement: Record "CBG Statement"; ExpectedCBGStatementLine: Record "CBG Statement Line"; Multiplier: Integer; ExpectedNumberOfOccurrences: Integer; ExpectedDescription: Text[100])
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        SetCBGStatementLineFilters(CBGStatement, CBGStatementLine, ExpectedCBGStatementLine, Multiplier);
        CBGStatementLine.SetRange(Description, ExpectedDescription);
        Assert.AreEqual(
          ExpectedNumberOfOccurrences, CBGStatementLine.Count, WrongNrOfCBGStatementLinesErr + CBGStatementLine.GetFilters);
    end;

    local procedure VerifyCBGStatementLineAndAdditionalInfo(CBGStatement: Record "CBG Statement"; ExpectedCBGStatementLine: Record "CBG Statement Line"; Multiplier: Integer; ExpectedDescription: Text[1024])
    var
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        AdditionalInfoDescription: Text[1024];
    begin
        SetCBGStatementLineFilters(CBGStatement, CBGStatementLine, ExpectedCBGStatementLine, Multiplier);

        Assert.AreEqual(1, CBGStatementLine.Count, WrongNrOfCBGStatementLinesErr + CBGStatementLine.GetFilters);
        CBGStatementLine.FindFirst();

        CBGStatementLineAddInfo.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLineAddInfo.SetRange("CBG Statement No.", CBGStatement."No.");
        CBGStatementLineAddInfo.SetRange("CBG Statement Line No.", CBGStatementLine."Line No.");
        Assert.IsTrue(CBGStatementLineAddInfo.Find('-'), 'Unable to find additional info for the CBG Statement Line.');
        repeat
            AdditionalInfoDescription += CBGStatementLineAddInfo.Description;
        until CBGStatementLineAddInfo.Next() = 0;
        Assert.AreEqual(ExpectedDescription, AdditionalInfoDescription, 'Unexpected description stored in CBGStatementLineAddInfo table.');
    end;

    local procedure VerifyNoTableDataWasCreated(TempCBGStatement: Record "CBG Statement" temporary; TempCreditCBGStatementLine: Record "CBG Statement Line" temporary; TempDebitCBGStatementLine: Record "CBG Statement Line" temporary; GenJournalTemplate: Record "Gen. Journal Template"; UstrdFieldVal: Text[80])
    var
        CBGStatement: Record "CBG Statement";
    begin
        // Verify that no table data has been created
        VerifyCBGStatement(
          CBGStatement, GenJournalTemplate, TempCBGStatement, TempCreditCBGStatementLine.Amount - TempDebitCBGStatementLine.Amount, 0);
        VerifyCBGStatementLine(CBGStatement, TempCreditCBGStatementLine, -1, 0);
        VerifyCBGStatementLine(CBGStatement, TempDebitCBGStatementLine, 1, 0);
        if UstrdFieldVal <> '' then
            VerifyZeroCBGStatementLineAdditionalInfo(CBGStatement, UstrdFieldVal);
    end;

    local procedure VerifyRelatedPartyBankAccount(CBGStatement: Record "CBG Statement"; ExpectedCBGStatementLine: Record "CBG Statement Line"; BankAccount: Record "Bank Account"; Multiplier: Integer; ExpectIBAN: Boolean; ExpectLocalBankAccount: Boolean)
    var
        ActualCBGStatementLine: Record "CBG Statement Line";
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        SetCBGStatementLineFilters(CBGStatement, ActualCBGStatementLine, ExpectedCBGStatementLine, Multiplier);
        if not ActualCBGStatementLine.FindFirst() then
            Assert.Fail('Cannot find CBG Statement Line with filters ' + ActualCBGStatementLine.GetFilters);

        CBGStatementLineAddInfo.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLineAddInfo.SetRange("CBG Statement No.", CBGStatement."No.");
        CBGStatementLineAddInfo.SetRange("CBG Statement Line No.", ActualCBGStatementLine."Line No.");
        CBGStatementLineAddInfo.SetRange("Information Type", CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account");
        if not CBGStatementLineAddInfo.FindFirst() then
            Assert.Fail(StrSubstNo('Unable to find additional info for the CBG Statement Line %1', ActualCBGStatementLine."No."));
        if ExpectIBAN then
            Assert.AreEqual(BankAccount.IBAN, CBGStatementLineAddInfo.Description, 'Incorrect IBAN');
        if ExpectLocalBankAccount then
            Assert.AreEqual(BankAccount."Bank Account No.", CBGStatementLineAddInfo.Description, 'Incorrect local bank account');
    end;

    local procedure VerifyZeroCBGStatementLineAdditionalInfo(CBGStatement: Record "CBG Statement"; ExpectedDescription: Text[80])
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        CBGStatementLineAddInfo.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLineAddInfo.SetRange(Description, ExpectedDescription);
        Assert.IsFalse(CBGStatementLineAddInfo.FindFirst(), 'Unexpected line found in GBM Statement Line Additional Info table for ' + CBGStatementLineAddInfo.GetFilters);
    end;

    local procedure WriteLine(var OutStream: OutStream; Text: Text)
    begin
        OutStream.WriteText(Text);
        OutStream.WriteText();
    end;

    local procedure WriteCAMTFile(SEPACAMTFileParameters: Record "SEPA CAMT File Parameters")
    var
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        Encoding: DotNet Encoding;
        OutStream: OutStream;
        Iterator: Integer;
    begin
        TempBlobOEM.CreateOutStream(OutStream);

        WriteLine(OutStream, '<?xml version="1.0" encoding="' + SEPACAMTFileParameters.Encoding + '"?>');
        WriteLine(
          OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + SEPACAMTFileParameters.Namespace + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>AAAASESS-FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        for Iterator := 1 to SEPACAMTFileParameters.NumberOfStatements do
            WriteStatementToCAMTFile(SEPACAMTFileParameters, OutStream);
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');

        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);
        SetupSourceBlob(TempBlobUTF8);
    end;

    local procedure WriteStatementHeaderToCAMTFile(SEPACAMTFileParameters: Record "SEPA CAMT File Parameters"; var TestXmlFileOutStream: OutStream)
    begin
        WriteLine(TestXmlFileOutStream, '      <Id>AAAASESS-FP-STAT001</Id>');
        if SEPACAMTFileParameters.HasStatementDateTag then
            WriteLine(TestXmlFileOutStream, '      <CreDtTm>' + SEPACAMTFileParameters.StmtDateFieldValue + '</CreDtTm>');
        if (SEPACAMTFileParameters.IBANFieldValue <> '') or (SEPACAMTFileParameters.BankAccountNoFieldValue <> '') then begin
            WriteLine(TestXmlFileOutStream, '      <Acct>');
            WriteLine(TestXmlFileOutStream, '        <Id>');
            if SEPACAMTFileParameters.IBANFieldValue <> '' then
                WriteLine(TestXmlFileOutStream, '          <IBAN>' + SEPACAMTFileParameters.IBANFieldValue + '</IBAN>');
            WriteLine(TestXmlFileOutStream, '          <Ccy>' + SEPACAMTFileParameters.CcyFieldValue + '</Ccy>');
            if SEPACAMTFileParameters.BankAccountNoFieldValue <> '' then begin
                WriteLine(TestXmlFileOutStream, '          <Othr>');
                WriteLine(TestXmlFileOutStream, '            <Id>' + SEPACAMTFileParameters.BankAccountNoFieldValue + '</Id>');
                WriteLine(TestXmlFileOutStream, '            <Ccy>' + SEPACAMTFileParameters.CcyFieldValue + '</Ccy>');
                WriteLine(TestXmlFileOutStream, '          </Othr>');
            end;
            WriteLine(TestXmlFileOutStream, '        </Id>');
            WriteLine(TestXmlFileOutStream, '      </Acct>');
        end;
        WriteLine(TestXmlFileOutStream, '      <Bal>');
        if SEPACAMTFileParameters.HasClosingBalanceTag then begin
            WriteLine(TestXmlFileOutStream, '        <Tp>');
            WriteLine(TestXmlFileOutStream, '          <CdOrPrtry>');
            WriteLine(TestXmlFileOutStream, '            <Cd>' + SEPACAMTFileParameters.CdFieldValue + '</Cd>');
            WriteLine(TestXmlFileOutStream, '          </CdOrPrtry>');
            WriteLine(TestXmlFileOutStream, '        </Tp>');
        end;
        WriteLine(TestXmlFileOutStream, '        <Amt Ccy="' + SEPACAMTFileParameters.CcyFieldValue + '">' + SEPACAMTFileParameters.ClsBalFieldValue + '</Amt>');
        if SEPACAMTFileParameters.HasCdtDbtIndTagInBal then
            WriteLine(TestXmlFileOutStream, '        <CdtDbtInd>' + SEPACAMTFileParameters.BalCrdtDbtFieldValue + '</CdtDbtInd>');
        WriteLine(TestXmlFileOutStream, '      </Bal>');
    end;

    local procedure WriteNonXmlFile()
    var
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        Encoding: DotNet Encoding;
        OutStream: OutStream;
    begin
        TempBlobOEM.CreateOutStream(OutStream);

        WriteLine(OutStream, 'This file should not be importable by the SEPA CAMT report');

        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);
        SetupSourceBlob(TempBlobUTF8);
    end;

    local procedure WriteStatementToCAMTFile(SEPACAMTFileParameters: Record "SEPA CAMT File Parameters"; var TestXmlFileOutStream: OutStream)
    begin
        WriteLine(TestXmlFileOutStream, '    <Stmt>');
        WriteStatementHeaderToCAMTFile(SEPACAMTFileParameters, TestXmlFileOutStream);
        WriteLine(TestXmlFileOutStream, '      <Ntry>');
        WriteLine(TestXmlFileOutStream, '        <Amt Ccy="' + SEPACAMTFileParameters.CcyFieldValue + '">' + SEPACAMTFileParameters.CrdtFieldValue + '</Amt>');
        if SEPACAMTFileParameters.HasCdtDbtIndTagInNtry then
            WriteLine(TestXmlFileOutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(TestXmlFileOutStream, '        <Sts>BOOK</Sts>');
        WriteLine(TestXmlFileOutStream, '        <BookgDt>');
        WriteLine(TestXmlFileOutStream, '          <DtTm>' + SEPACAMTFileParameters.CrdtDateFieldValue + '</DtTm>');
        WriteLine(TestXmlFileOutStream, '        </BookgDt>');
        WriteLine(TestXmlFileOutStream, '        <AcctSvcrRef>' + SEPACAMTFileParameters.CrdtTextFieldValue + '</AcctSvcrRef>');
        if SEPACAMTFileParameters.RelatedPartyBankAccount <> '' then begin
            WriteLine(TestXmlFileOutStream, '            <NtryDtls>');
            WriteLine(TestXmlFileOutStream, '              <TxDtls>');
            WriteLine(TestXmlFileOutStream, '                <RltdPties>');
            WriteLine(TestXmlFileOutStream, '                  <CdtrAcct>');
            WriteLine(TestXmlFileOutStream, '                    <Id>');
            WriteLine(TestXmlFileOutStream, '                      <Othr>');
            WriteLine(TestXmlFileOutStream, '                        <Id>' + SEPACAMTFileParameters.RelatedPartyBankAccount + '</Id>');
            WriteLine(TestXmlFileOutStream, '                      </Othr>');
            WriteLine(TestXmlFileOutStream, '                    </Id>');
            WriteLine(TestXmlFileOutStream, '                  </CdtrAcct>');
            WriteLine(TestXmlFileOutStream, '                </RltdPties>');
            WriteLine(TestXmlFileOutStream, '              </TxDtls>');
            WriteLine(TestXmlFileOutStream, '            </NtryDtls>');
        end;
        WriteLine(TestXmlFileOutStream, '      </Ntry>');
        WriteLine(TestXmlFileOutStream, '      <Ntry>');
        WriteLine(TestXmlFileOutStream, '        <Amt Ccy="' + SEPACAMTFileParameters.CcyFieldValue + '">' + SEPACAMTFileParameters.DbitFieldValue + '</Amt>');
        WriteLine(TestXmlFileOutStream, '        <CdtDbtInd>DBIT</CdtDbtInd>');
        WriteLine(TestXmlFileOutStream, '        <Sts>BOOK</Sts>');
        WriteLine(TestXmlFileOutStream, '        <BookgDt>');
        WriteLine(TestXmlFileOutStream, '          <DtTm>' + SEPACAMTFileParameters.DbitDateFieldValue + '</DtTm>');
        WriteLine(TestXmlFileOutStream, '        </BookgDt>');
        WriteLine(TestXmlFileOutStream, '        <AcctSvcrRef>' + SEPACAMTFileParameters.DbitTextFieldValue + '</AcctSvcrRef>');
        if SEPACAMTFileParameters.AddtlNtryInfFieldValue <> '' then
            WriteLine(TestXmlFileOutStream, '        <AddtlNtryInf>' + SEPACAMTFileParameters.AddtlNtryInfFieldValue + '</AddtlNtryInf>');
        if (SEPACAMTFileParameters.UstrdFieldValue1 <> '') or SEPACAMTFileParameters.SkipTxDtlsAmt or (SEPACAMTFileParameters.RelatedPartyIBAN <> '') or (SEPACAMTFileParameters.RelatedPartyName <> '') or
          (SEPACAMTFileParameters.EndToEndIdFieldValue <> '')
        then begin
            WriteLine(TestXmlFileOutStream, '        <NtryDtls>');
            WriteLine(TestXmlFileOutStream, '          <TxDtls>');
            if not SEPACAMTFileParameters.SkipTxDtlsAmt then begin
                WriteLine(TestXmlFileOutStream, '            <AmtDtls>');
                WriteLine(TestXmlFileOutStream, '              <TxAmt>');
                WriteLine(TestXmlFileOutStream, '                <Amt Ccy="' + SEPACAMTFileParameters.CcyFieldValue + '">' + SEPACAMTFileParameters.DbitFieldValue + '</Amt>');
                WriteLine(TestXmlFileOutStream, '              </TxAmt>');
                WriteLine(TestXmlFileOutStream, '            </AmtDtls>');
            end;
            if SEPACAMTFileParameters.EndToEndIdFieldValue <> '' then begin
                WriteLine(TestXmlFileOutStream, '            <Refs>');
                WriteLine(TestXmlFileOutStream, '              <EndToEndId>' + SEPACAMTFileParameters.EndToEndIdFieldValue + '</EndToEndId>');
                WriteLine(TestXmlFileOutStream, '            </Refs>');
            end;
            if (SEPACAMTFileParameters.RelatedPartyIBAN <> '') or (SEPACAMTFileParameters.RelatedPartyName <> '') then begin
                WriteLine(TestXmlFileOutStream, '            <RltdPties>');
                if SEPACAMTFileParameters.RelatedPartyName <> '' then begin
                    WriteLine(TestXmlFileOutStream, '              <Dbtr>');
                    WriteLine(TestXmlFileOutStream, '                <Nm>' + SEPACAMTFileParameters.RelatedPartyName + '</Nm>');
                    if (SEPACAMTFileParameters.RelatedPartyAddress <> '') or (SEPACAMTFileParameters.RelatedPartyCity <> '') then begin
                        WriteLine(TestXmlFileOutStream, '              <PstlAdr>');
                        if SEPACAMTFileParameters.RelatedPartyAddress <> '' then
                            WriteLine(TestXmlFileOutStream, '                <AdrLine>' + SEPACAMTFileParameters.RelatedPartyAddress + '</AdrLine>');
                        if SEPACAMTFileParameters.RelatedPartyCity <> '' then
                            WriteLine(TestXmlFileOutStream, '                <TwnNm>' + SEPACAMTFileParameters.RelatedPartyCity + '</TwnNm>');
                        WriteLine(TestXmlFileOutStream, '              </PstlAdr>');
                    end;
                    WriteLine(TestXmlFileOutStream, '              </Dbtr>');
                end;
                if SEPACAMTFileParameters.RelatedPartyIBAN <> '' then begin
                    WriteLine(TestXmlFileOutStream, '              <DbtrAcct>');
                    WriteLine(TestXmlFileOutStream, '                <Id>');
                    WriteLine(TestXmlFileOutStream, '                  <IBAN>' + SEPACAMTFileParameters.RelatedPartyIBAN + '</IBAN>');
                    WriteLine(TestXmlFileOutStream, '                </Id>');
                    WriteLine(TestXmlFileOutStream, '              </DbtrAcct>');
                end;
                WriteLine(TestXmlFileOutStream, '            </RltdPties>');
            end;
            WriteLine(TestXmlFileOutStream, '            <RmtInf>');
            WriteLine(TestXmlFileOutStream, '            <Ustrd>' + SEPACAMTFileParameters.UstrdFieldValue1 + '</Ustrd>');
            if SEPACAMTFileParameters.UstrdFieldValue2 <> '' then
                WriteLine(TestXmlFileOutStream, '            <Ustrd>' + SEPACAMTFileParameters.UstrdFieldValue2 + '</Ustrd>');
            if SEPACAMTFileParameters.UstrdFieldValue3 <> '' then
                WriteLine(TestXmlFileOutStream, '            <Ustrd>' + SEPACAMTFileParameters.UstrdFieldValue3 + '</Ustrd>');
            WriteLine(TestXmlFileOutStream, '            </RmtInf>');
            WriteLine(TestXmlFileOutStream, '          </TxDtls>');
            WriteLine(TestXmlFileOutStream, '        </NtryDtls>');
        end;
        WriteLine(TestXmlFileOutStream, '      </Ntry>');
        WriteLine(TestXmlFileOutStream, '    </Stmt>');
    end;

    local procedure WrongBankAccount(DummyBankAccountNo: Text[30]; DummyIBAN: Text[50])
    var
        TempCreditCBGStatementLine: Record "CBG Statement Line" temporary;
        TempCBGStatement: Record "CBG Statement" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        ImportProtocol: Record "Import Protocol";
        SEPACAMTFileParameters: Record "SEPA CAMT File Parameters";
    begin
        // Pre-setup.
        CreateBankAccWithBankStatementSetup(BankAccount, GenJournalTemplate, 'SEPA CAMT');
        CreateImportProtocol(ImportProtocol, BankAccount."No.", false);

        // Setup.
        CreateExpectedCBGStatement(TempCreditCBGStatementLine, TempCBGStatement, BankAccount);

        InitCommonFileParameters(SEPACAMTFileParameters, TempCBGStatement, TempCreditCBGStatementLine, TempCreditCBGStatementLine);
        SEPACAMTFileParameters.IBANFieldValue := DummyIBAN;
        SEPACAMTFileParameters.BankAccountNoFieldValue := DummyBankAccountNo;
        SEPACAMTFileParameters.ClsBalFieldValue := Format(Abs(TempCreditCBGStatementLine.Amount), 0, 9);
        SEPACAMTFileParameters.CcyFieldValue := '';

        WriteCAMTFile(SEPACAMTFileParameters);

        // Exercise and verify.
        if DummyIBAN <> '' then
            RunImportSEPACAMTReportExpectMessage(ImportProtocol.Code, StrSubstNo(BankAccountMissMatchErr, BankAccount."No.", DummyIBAN))
        else
            RunImportSEPACAMTReportExpectMessage(
              ImportProtocol.Code, StrSubstNo(BankAccountMissMatchErr, BankAccount."No.", DummyBankAccountNo));
        VerifyNoTableDataWasCreated(TempCBGStatement, TempCreditCBGStatementLine, TempCreditCBGStatementLine, GenJournalTemplate, '');
    end;

    local procedure VerifyCBGStatementAddInfo(SEPACAMTFileParameters: Record "SEPA CAMT File Parameters"; AccountNo: Code[20])
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        // Verify description
        VerifyCBGStatementAddInfoEntry(AccountNo, CBGStatementLineAddInfo."Information Type"::"Description and Sundries",
          CopyStr(SEPACAMTFileParameters.AddtlNtryInfFieldValue, 1, MaxStrLen(CBGStatementLineAddInfo.Description)),
          CopyStr(SEPACAMTFileParameters.AddtlNtryInfFieldValue, MaxStrLen(CBGStatementLineAddInfo.Description) + 1));
        // Verify Name
        VerifyCBGStatementAddInfoEntry(AccountNo, CBGStatementLineAddInfo."Information Type"::"Name Acct. Holder",
          SEPACAMTFileParameters.RelatedPartyName, '');
        // Verify Address
        VerifyCBGStatementAddInfoEntry(AccountNo, CBGStatementLineAddInfo."Information Type"::"Address Acct. Holder",
          SEPACAMTFileParameters.RelatedPartyAddress, '');
        // Verify City
        VerifyCBGStatementAddInfoEntry(AccountNo, CBGStatementLineAddInfo."Information Type"::"City Acct. Holder",
          SEPACAMTFileParameters.RelatedPartyCity, '');
    end;

    local procedure VerifyCBGStatementAddInfoEntry(AccountNo: Code[20]; InformationType: Enum "CBG Statement Information Type"; FirstExpectedEntry: Text; SecondExpectedEntry: Text)
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        CBGStatement.SetRange("Account No.", AccountNo);
        CBGStatement.FindFirst();
        CBGStatementLineAddInfo.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLineAddInfo.SetRange("CBG Statement No.", CBGStatement."No.");
        CBGStatementLineAddInfo.SetRange("Information Type", InformationType);
        CBGStatementLineAddInfo.FindSet();

        Assert.AreEqual(FirstExpectedEntry, CBGStatementLineAddInfo.Description, StrSubstNo(IncorrectValueForTypeErr, Format(CBGStatementLineAddInfo."Information Type")));
        if SecondExpectedEntry <> '' then begin
            CBGStatementLineAddInfo.Next();
            Assert.AreEqual(SecondExpectedEntry, CBGStatementLineAddInfo.Description, StrSubstNo(IncorrectValueForTypeErr, Format(CBGStatementLineAddInfo."Information Type")));
        end;
    end;

    local procedure VerifyCBGStatementAddInfoEntryNotExists(AccountNo: Code[20]; InformationType: Enum "CBG Statement Information Type"; FirstExpectedEntry: Text)
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        CBGStatement.SetRange("Account No.", AccountNo);
        CBGStatement.FindFirst();
        CBGStatementLineAddInfo.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLineAddInfo.SetRange("CBG Statement No.", CBGStatement."No.");
        CBGStatementLineAddInfo.SetRange("Information Type", InformationType);
        CBGStatementLineAddInfo.SetFilter(Description, FirstExpectedEntry);
        Assert.RecordIsEmpty(CBGStatementLineAddInfo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ImportProtocolListPageHandler(var ImportProtocolList: TestPage "Import Protocol List")
    var
        ImportProtocol: Variant;
    begin
        LibraryVariableStorage.Dequeue(ImportProtocol);
        ImportProtocolList.FILTER.SetFilter(Code, ImportProtocol);
        ImportProtocolList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedQuestion: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedQuestion);
        Assert.AreEqual(ExpectedQuestion, Question, 'Wrong message received!');
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, UnexpectedMessageErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

