codeunit 132549 "Import XML Gen Jnl Line"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Import Bank Statement]
    end;

    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        AssertMsg: Label '%1 Field:"%2" different from expected.';
        IBANTxt: Text[50];
        CurrTxt: Text[10];
        MultiStatementErr: Label 'The file that you are trying to import contains more than one bank statement.';
        IsInitialized: Boolean;
        IBANMismatchQst: Label 'does not have the bank account number', Comment = '%1=Value';
        MissingIBANInDataErr: Label 'The bank account number was not found in the data to be imported.';
        DiffCurrQst: Label 'The bank statement that you are importing contains transactions in ';
        NamespaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.02';

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure MissingIBANConfirmNo()
    var
        GenJnlLineTemplate: Record "Gen. Journal Line";
        BankAcc: Record "Bank Account";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        Initialize();

        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);

        // Exercise
        CreateGenJnlLineTemplateWithFilter(GenJnlLineTemplate, 'SEPA CAMT');
        BankAcc.Get(GenJnlLineTemplate."Bal. Account No.");
        BankAcc.IBAN := '';
        BankAcc.Modify();
        asserterror GenJnlLineTemplate.ImportBankStatement();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure MissingIBANConfirmYes()
    var
        GenJnlLineTemplate: Record "Gen. Journal Line";
        BankAcc: Record "Bank Account";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        Initialize();

        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);

        // Exercise
        CreateGenJnlLineTemplateWithFilter(GenJnlLineTemplate, 'SEPA CAMT');
        BankAcc.Get(GenJnlLineTemplate."Bal. Account No.");
        BankAcc.IBAN := '';
        BankAcc.Modify();
        GenJnlLineTemplate.ImportBankStatement();

        // Verify
        // No Errors
    end;

    [Test]
    [HandlerFunctions('IBANMismatchConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyBankAccIBAN()
    var
        GenJnlLineTemplate: Record "Gen. Journal Line";
        BankAcc: Record "Bank Account";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        Initialize();

        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);

        // Exercise
        CreateGenJnlLineTemplateWithFilter(GenJnlLineTemplate, 'SEPA CAMT');
        BankAcc.Get(GenJnlLineTemplate."Bal. Account No.");
        BankAcc.IBAN := LibraryUtility.GenerateGUID();
        BankAcc.Modify();
        GenJnlLineTemplate.ImportBankStatement();

        // Verify: In confirm handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyBankAccCurrency()
    var
        GenJnlLineTemplate: Record "Gen. Journal Line";
        BankAcc: Record "Bank Account";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        Initialize();

        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);

        CreateGenJnlLineTemplateWithFilter(GenJnlLineTemplate, 'SEPA CAMT');
        BankAcc.Get(GenJnlLineTemplate."Bal. Account No.");
        BankAcc.IBAN := IBANTxt;
        BankAcc."Currency Code" :=
          LibraryERM.CreateCurrencyWithExchangeRate(DMY2Date(1, 1, 2000), 1, 1);
        BankAcc.Modify();

        // Exercise
        asserterror GenJnlLineTemplate.ImportBankStatement();

        // Verify
        Assert.ExpectedError(DiffCurrQst);
    end;

    [Test]
    [HandlerFunctions('DiffCurrConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLAccDifferentStatementCurrency()
    var
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempExpdGenJnlLine: Record "Gen. Journal Line" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
        FileCurrencyCode: Code[10];
    begin
        Initialize();

        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        FileCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(DMY2Date(1, 1, 2000), 1, 1);
        WriteCAMTFileWithCurrency(OutStream, 'UTF-8', FileCurrencyCode);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);
        CreateGenJnlTemplateForGLAccountImport(GenJnlLineTemplate, 'SEPA CAMT');

        // Exercise
        GenJnlLineTemplate.ImportBankStatement();

        // Verify
        PrepareImportedDataValidation(TempExpdGenJnlLine, GenJnlLineTemplate, FileCurrencyCode);
        AssertDataInTable(TempExpdGenJnlLine, GenJnlLineTemplate, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure GLAccDifferentStatementCurrencyRefuse()
    var
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
        FileCurrencyCode: Code[10];
    begin
        Initialize();

        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        FileCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(DMY2Date(1, 1, 2000), 1, 1);
        WriteCAMTFileWithCurrency(OutStream, 'UTF-8', FileCurrencyCode);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);
        CreateGenJnlTemplateForGLAccountImport(GenJnlLineTemplate, 'SEPA CAMT');

        // Exercise
        asserterror GenJnlLineTemplate.ImportBankStatement();

        // Verify
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccSameStatementCurrency()
    var
        TempExpdGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        Initialize();

        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithCurrency(OutStream, 'UTF-8', CurrTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);
        CreateGenJnlTemplateForGLAccountImport(GenJnlLineTemplate, 'SEPA CAMT');

        // Exercise
        GenJnlLineTemplate.ImportBankStatement();

        // Verify
        PrepareImportedDataValidation(TempExpdGenJnlLine, GenJnlLineTemplate, '');
        AssertDataInTable(TempExpdGenJnlLine, GenJnlLineTemplate, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyIBANMissingFromData()
    var
        GenJnlLineTemplate: Record "Gen. Journal Line";
        BankAcc: Record "Bank Account";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        Initialize();

        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileNoIBAN(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);

        // Exercise
        CreateGenJnlLineTemplateWithFilter(GenJnlLineTemplate, 'SEPA CAMT');
        BankAcc.Get(GenJnlLineTemplate."Bal. Account No.");
        BankAcc.IBAN := LibraryUtility.GenerateGUID();
        BankAcc.Modify();
        asserterror GenJnlLineTemplate.ImportBankStatement();

        // Verify
        Assert.ExpectedError(MissingIBANInDataErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyMultiStatement()
    var
        GenJnlLineTemplate: Record "Gen. Journal Line";
        BankAcc: Record "Bank Account";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        Initialize();

        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteMultiStatementCAMTFile(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);

        // Exercise
        CreateGenJnlLineTemplateWithFilter(GenJnlLineTemplate, 'SEPA CAMT');
        BankAcc.Get(GenJnlLineTemplate."Bal. Account No.");
        BankAcc.IBAN := IBANTxt;
        BankAcc.Modify();

        asserterror GenJnlLineTemplate.ImportBankStatement();
        Assert.ExpectedError(MultiStatementErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyImportedLines()
    var
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempExpdGenJnlLine: Record "Gen. Journal Line" temporary;
        BankAcc: Record "Bank Account";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        Initialize();

        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);

        // Exercise
        CreateGenJnlLineTemplateWithFilter(GenJnlLineTemplate, 'SEPA CAMT');
        BankAcc.Get(GenJnlLineTemplate."Bal. Account No.");
        BankAcc.IBAN := IBANTxt;
        BankAcc.Modify();

        GenJnlLineTemplate.ImportBankStatement();

        // Verify
        PrepareImportedDataValidation(TempExpdGenJnlLine, GenJnlLineTemplate, '');
        AssertDataInTable(TempExpdGenJnlLine, GenJnlLineTemplate, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyMultipleElementConcatenation()
    var
        DataExch: Record "Data Exch.";
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempExpdGenJnlLine: Record "Gen. Journal Line" temporary;
        BankAcc: Record "Bank Account";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
        EntryNo: Integer;
        LineNo: Integer;
        DocNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileMultiUstrd(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);

        // Exercise
        CreateGenJnlLineTemplateWithFilter(GenJnlLineTemplate, 'SEPA CAMT');
        BankAcc.Get(GenJnlLineTemplate."Bal. Account No.");
        BankAcc.IBAN := IBANTxt;
        BankAcc.Modify();

        GenJnlLineTemplate.ImportBankStatement();
        DataExch.SetRange("Data Exch. Def Code", 'SEPA CAMT');
        DataExch.FindLast();
        EntryNo := DataExch."Entry No.";
        GenJnlLineTemplate.Find();

        // Verify
        LineNo := GenJnlLineTemplate."Line No.";
        DocNo := GenJnlLineTemplate."Document No.";
        CreateLine(TempExpdGenJnlLine, GenJnlLineTemplate, EntryNo, 1, LineNo * 1,
          IncCode(0, DocNo), DMY2Date(5, 5, Date2DMY(WorkDate(), 3)), '0a 1a 2a 3a 4a 5a 6a 7a 8a 9a 10a 11a', '', '', -105678.5, '');

        AssertDataInTable(TempExpdGenJnlLine, GenJnlLineTemplate, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteRelatedInfo()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        SetupGenJnlLineForImport(GenJnlLine);
        GenJnlLine.ImportBankStatement();

        // Exercise.
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlLine.DeleteAll(true);

        // Verify.
        VerifyDataExchFieldIsDeleted(GetLastDataExch());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteRelatedInfoMultipleImports()
    var
        GenJnlLine: Record "Gen. Journal Line";
        EntryNo: Integer;
    begin
        Initialize();

        // Setup
        SetupGenJnlLineForImport(GenJnlLine);
        GenJnlLine.ImportBankStatement();
        EntryNo := GetLastDataExch();
        GenJnlLine.ImportBankStatement();

        // Exercise.
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlLine.DeleteAll(true);

        // Verify.
        VerifyDataExchFieldIsDeleted(EntryNo);
        VerifyDataExchFieldIsDeleted(GetLastDataExch());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteRelatedInfoMultipleImportsByLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        EntryNo: Integer;
    begin
        Initialize();

        // Setup.
        SetupGenJnlLineForImport(GenJnlLine);
        GenJnlLine.ImportBankStatement();
        EntryNo := GetLastDataExch();
        GenJnlLine.ImportBankStatement();

        // Exercise.
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlLine.SetRange("Data Exch. Entry No.", EntryNo);
        GenJnlLine.DeleteAll(true);

        // Verify.
        VerifyDataExchFieldIsDeleted(EntryNo);
        VerifyDataExchFieldIsKept(GetLastDataExch());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteRelatedInfoWhenPosting()
    var
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup.
        SetupGenJnlLineForImport(GenJnlLine);
        GenJnlLine.ImportBankStatement();

        // Exercise.
        LibraryERM.FindGLAccount(GLAccount);
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlLine.ModifyAll("Account No.", GLAccount."No.");
        GenJnlLine.ModifyAll(Description, LibraryUtility.GenerateGUID());
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Verify.
        VerifyDataExchFieldIsDeleted(GetLastDataExch());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteRelatedInfoWhenPostingMultipleImports()
    var
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        EntryNo: Integer;
    begin
        Initialize();

        // Setup.
        SetupGenJnlLineForImport(GenJnlLine);
        GenJnlLine.ImportBankStatement();
        EntryNo := GetLastDataExch();
        GenJnlLine.ImportBankStatement();

        // Exercise.
        LibraryERM.FindGLAccount(GLAccount);
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlLine.ModifyAll("Account No.", GLAccount."No.");
        GenJnlLine.ModifyAll(Description, LibraryUtility.GenerateGUID());
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Verify.
        VerifyDataExchFieldIsDeleted(EntryNo);
        VerifyDataExchFieldIsDeleted(GetLastDataExch());
    end;

    [Test]
    [HandlerFunctions('DiffCurrConfirmHandler')]
    [Scope('OnPrem')]
    procedure CurrencyFactorShouldSameGLAccDifferentStatementCurrency()
    var
        GenJnlLineTemplate: Record "Gen. Journal Line";
        TempExpdGenJnlLine: Record "Gen. Journal Line" temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
        FileCurrencyCode: Code[10];
        CurrencyFactor: Decimal;
    begin
        // [SCENARIO 524613] Wrong amounts in LCY when importing a bank statement into the general journal lines.
        Initialize();

        // [GIVEN] Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        FileCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        CurrencyFactor := CurrExchRate.ExchangeRate(WorkDate(), FileCurrencyCode);
        WriteCAMTFileWithCurrency(OutStream, 'UTF-8', FileCurrencyCode);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // [GIVEN] Setup and Create General Journal Template For G/L Account Import
        SetupSourceMock('SEPA CAMT', TempBlobUTF8);
        CreateGenJnlTemplateForGLAccountImport(GenJnlLineTemplate, 'SEPA CAMT');

        // [WHEN] Exercise Import Bank Statement
        GenJnlLineTemplate.ImportBankStatement();

        // [THEN] Validate Imported Data and Verify Currency Factor
        PrepareImportedDataValidation(TempExpdGenJnlLine, GenJnlLineTemplate, FileCurrencyCode);
        AssertDataInTable(TempExpdGenJnlLine, GenJnlLineTemplate, '');
        Assert.AreEqual(CurrencyFactor, TempExpdGenJnlLine."Currency Factor", '');
    end;

    [Normal]
    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        CurrTxt := 'EUR';
        IBANTxt := '15415024154';
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERM.SetLCYCode(CurrTxt);
        Commit();

        IsInitialized := true;
    end;

    local procedure IncCode(IncrementCount: Integer; TextToIncrement: Code[20]): Code[20]
    var
        i: Integer;
    begin
        for i := 1 to IncrementCount do
            TextToIncrement := IncStr(TextToIncrement);

        exit(TextToIncrement);
    end;

    local procedure WriteCAMTFile(OutStream: OutStream; Encoding: Text)
    begin
        CAMTFileWriter(OutStream, Encoding, true, CurrTxt);
    end;

    local procedure WriteCAMTFileNoIBAN(OutStream: OutStream; Encoding: Text)
    begin
        CAMTFileWriter(OutStream, Encoding, false, CurrTxt);
    end;

    local procedure WriteCAMTFileWithCurrency(OutStream: OutStream; Encoding: Text; CAMTCurrTxt: Text)
    begin
        CAMTFileWriter(OutStream, Encoding, true, CAMTCurrTxt);
    end;

    local procedure CAMTFileWriter(OutStream: OutStream; Encoding: Text; IncludeIBAN: Boolean; FileCurrTxt: Text)
    var
        YearText: Text;
    begin
        YearText := Format(Date2DMY(WorkDate(), 3));
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>FP-STAT001</Id>');
        WriteLine(OutStream, StrSubstNo('      <CreDtTm>%1-05-05T17:00:00+01:00</CreDtTm>', YearText));
        WriteLine(OutStream, '      <Acct>');
        WriteLine(OutStream, '        <Id>');
        if IncludeIBAN then
            WriteLine(OutStream, '          <IBAN>' + IBANTxt + '</IBAN>');
        WriteLine(OutStream, '        </Id>');
        WriteLine(OutStream, '      </Acct>');
        WriteLine(OutStream, '      <Bal>');
        WriteLine(OutStream, '        <Tp>');
        WriteLine(OutStream, '          <CdOrPrtry>');
        WriteLine(OutStream, '            <Cd>OPBD</Cd>');
        WriteLine(OutStream, '          </CdOrPrtry>');
        WriteLine(OutStream, '        </Tp>');
        WriteLine(OutStream, '      <Amt Ccy="' + FileCurrTxt + '">500000</Amt>');
        WriteLine(OutStream, '      <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '      <Dt>');
        WriteLine(OutStream, StrSubstNo('        <Dt>%1-05-05</Dt>', YearText));
        WriteLine(OutStream, '      </Dt>');
        WriteLine(OutStream, '      </Bal>');
        WriteLine(OutStream, '      <Bal>');
        WriteLine(OutStream, '        <Tp>');
        WriteLine(OutStream, '          <CdOrPrtry>');
        WriteLine(OutStream, '            <Cd>CLBD</Cd>');
        WriteLine(OutStream, '          </CdOrPrtry>');
        WriteLine(OutStream, '        </Tp>');
        WriteLine(OutStream, '      <Amt Ccy="' + FileCurrTxt + '">435678.50</Amt>');
        WriteLine(OutStream, '      <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '      <Dt>');
        WriteLine(OutStream, StrSubstNo('        <Dt>%1-05-05</Dt>', YearText));
        WriteLine(OutStream, '      </Dt>');
        WriteLine(OutStream, '      </Bal>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="' + FileCurrTxt + '">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '        <BookgDt>');
        WriteLine(OutStream, StrSubstNo('          <Dt>%1-05-05</Dt>', YearText));
        WriteLine(OutStream, '        </BookgDt>');
        WriteLine(OutStream, '        <ValDt>');
        WriteLine(OutStream, StrSubstNo('          <Dt>%1-05-05</Dt>', YearText));
        WriteLine(OutStream, '        </ValDt>');
        WriteLine(OutStream, '        <AcctSvcrRef>FP-CN_98765/01</AcctSvcrRef>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="' + FileCurrTxt + '">105.42</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK2</Sts>');
        WriteLine(OutStream, '        <BookgDt>');
        WriteLine(OutStream, StrSubstNo('          <DtTm>%1-08-08T13:15:00+01:00</DtTm>', YearText));
        WriteLine(OutStream, '        </BookgDt>');
        WriteLine(OutStream, '        <ValDt>');
        WriteLine(OutStream, StrSubstNo('          <Dt>%1-08-08</Dt>', YearText));
        WriteLine(OutStream, '        </ValDt>');
        WriteLine(OutStream, '        <AcctSvcrRef>FP-CN_3321d3/0/2</AcctSvcrRef>');
        WriteLine(OutStream, '        <NtryDtls>');
        WriteLine(OutStream, '          <TxDtls>');
        WriteLine(OutStream, '            <RltdPties>');
        WriteLine(OutStream, '              <Dbtr>');
        WriteLine(OutStream, '                <Nm>MUELLER</Nm>');
        WriteLine(OutStream, '              </Dbtr>');
        WriteLine(OutStream, '            </RltdPties>');
        WriteLine(OutStream, '          </TxDtls>');
        WriteLine(OutStream, '        </NtryDtls>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileMultiUstrd(OutStream: OutStream; Encoding: Text)
    var
        YearText: Text;
    begin
        YearText := Format(Date2DMY(WorkDate(), 3));
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>FP-STAT001</Id>');
        WriteLine(OutStream, StrSubstNo('      <CreDtTm>%1-05-05T17:00:00+01:00</CreDtTm>', YearText));
        WriteLine(OutStream, '      <Acct>');
        WriteLine(OutStream, '        <Id>');
        WriteLine(OutStream, '          <IBAN>' + IBANTxt + '</IBAN>');
        WriteLine(OutStream, '        </Id>');
        WriteLine(OutStream, '      </Acct>');
        WriteLine(OutStream, '      <Bal>');
        WriteLine(OutStream, '        <Tp>');
        WriteLine(OutStream, '          <CdOrPrtry>');
        WriteLine(OutStream, '            <Cd>OPBD</Cd>');
        WriteLine(OutStream, '          </CdOrPrtry>');
        WriteLine(OutStream, '        </Tp>');
        WriteLine(OutStream, '      <Amt Ccy="' + CurrTxt + '">500000</Amt>');
        WriteLine(OutStream, '      <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '      <Dt>');
        WriteLine(OutStream, StrSubstNo('        <Dt>%1-05-05</Dt>', YearText));
        WriteLine(OutStream, '      </Dt>');
        WriteLine(OutStream, '      </Bal>');
        WriteLine(OutStream, '      <Bal>');
        WriteLine(OutStream, '        <Tp>');
        WriteLine(OutStream, '          <CdOrPrtry>');
        WriteLine(OutStream, '            <Cd>CLBD</Cd>');
        WriteLine(OutStream, '          </CdOrPrtry>');
        WriteLine(OutStream, '        </Tp>');
        WriteLine(OutStream, '      <Amt Ccy="' + CurrTxt + '">435678.50</Amt>');
        WriteLine(OutStream, '      <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '      <Dt>');
        WriteLine(OutStream, StrSubstNo('        <Dt>%1-05-05</Dt>', YearText));
        WriteLine(OutStream, '      </Dt>');
        WriteLine(OutStream, '      </Bal>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="' + CurrTxt + '">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '        <BookgDt>');
        WriteLine(OutStream, StrSubstNo('          <DtTm>%1-05-05T13:15:00+01:00</DtTm>', YearText));
        WriteLine(OutStream, '        </BookgDt>');
        WriteLine(OutStream, '        <ValDt>');
        WriteLine(OutStream, StrSubstNo('          <Dt>%1-05-05</Dt>', YearText));
        WriteLine(OutStream, '        </ValDt>');
        WriteLine(OutStream, '        <AcctSvcrRef>FP-CN_98765/01</AcctSvcrRef>');
        WriteLine(OutStream, '        <NtryDtls>');
        WriteLine(OutStream, '          <TxDtls>');
        WriteLine(OutStream, '            <RmtInf>');
        WriteLine(OutStream, '              <Ustrd>0a</Ustrd>');
        WriteLine(OutStream, '              <Ustrd>1a</Ustrd>');
        WriteLine(OutStream, '              <Ustrd>2a</Ustrd>');
        WriteLine(OutStream, '              <Ustrd>3a</Ustrd>');
        WriteLine(OutStream, '              <Ustrd>4a</Ustrd>');
        WriteLine(OutStream, '              <Ustrd>5a</Ustrd>');
        WriteLine(OutStream, '              <Ustrd>6a</Ustrd>');
        WriteLine(OutStream, '              <Ustrd>7a</Ustrd>');
        WriteLine(OutStream, '              <Ustrd>8a</Ustrd>');
        WriteLine(OutStream, '              <Ustrd>9a</Ustrd>');
        WriteLine(OutStream, '              <Ustrd>10a</Ustrd>');
        WriteLine(OutStream, '              <Ustrd>11a</Ustrd>');
        WriteLine(OutStream, '            </RmtInf>');
        WriteLine(OutStream, '          </TxDtls>');
        WriteLine(OutStream, '        </NtryDtls>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteMultiStatementCAMTFile(OutStream: OutStream; Encoding: Text)
    var
        YearText: Text;
    begin
        YearText := Format(Date2DMY(WorkDate(), 3));
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>FP-STAT001</Id>');
        WriteLine(OutStream, StrSubstNo('      <CreDtTm>%1-05-05T17:00:00+01:00</CreDtTm>', YearText));
        WriteLine(OutStream, '      <Acct>');
        WriteLine(OutStream, '        <Id>');
        WriteLine(OutStream, '          <IBAN>' + IBANTxt + '</IBAN>');
        WriteLine(OutStream, '        </Id>');
        WriteLine(OutStream, '      </Acct>');
        WriteLine(OutStream, '      <Bal>');
        WriteLine(OutStream, '        <Tp>');
        WriteLine(OutStream, '          <CdOrPrtry>');
        WriteLine(OutStream, '            <Cd>OPBD</Cd>');
        WriteLine(OutStream, '          </CdOrPrtry>');
        WriteLine(OutStream, '        </Tp>');
        WriteLine(OutStream, '      <Amt Ccy="' + CurrTxt + '">500000</Amt>');
        WriteLine(OutStream, '      <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '      <Dt>');
        WriteLine(OutStream, '        <Dt>2010-10-15</Dt>');
        WriteLine(OutStream, '      </Dt>');
        WriteLine(OutStream, '      </Bal>');
        WriteLine(OutStream, '      <Bal>');
        WriteLine(OutStream, '        <Tp>');
        WriteLine(OutStream, '          <CdOrPrtry>');
        WriteLine(OutStream, '            <Cd>CLBD</Cd>');
        WriteLine(OutStream, '          </CdOrPrtry>');
        WriteLine(OutStream, '        </Tp>');
        WriteLine(OutStream, '      <Amt Ccy="' + CurrTxt + '">435678.50</Amt>');
        WriteLine(OutStream, '      <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '      <Dt>');
        WriteLine(OutStream, StrSubstNo('        <Dt>%1-05-05</Dt>', YearText));
        WriteLine(OutStream, '      </Dt>');
        WriteLine(OutStream, '      </Bal>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="' + CurrTxt + '">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '        <BookgDt>');
        WriteLine(OutStream, StrSubstNo('          <DtTm>%1-05-05T13:15:00+01:00</DtTm>', YearText));
        WriteLine(OutStream, '        </BookgDt>');
        WriteLine(OutStream, '        <ValDt>');
        WriteLine(OutStream, StrSubstNo('          <Dt>%1-05-05</Dt>', YearText));
        WriteLine(OutStream, '        </ValDt>');
        WriteLine(OutStream, '        <AcctSvcrRef>FP-CN_98765/01</AcctSvcrRef>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>FP-STAT002</Id>');
        WriteLine(OutStream, StrSubstNo('      <CreDtTm>%1-05-05T17:00:00+01:00</CreDtTm>', YearText));
        WriteLine(OutStream, '      <Acct>');
        WriteLine(OutStream, '        <Id>');
        WriteLine(OutStream, '          <IBAN>' + IBANTxt + '</IBAN>');
        WriteLine(OutStream, '        </Id>');
        WriteLine(OutStream, '      </Acct>');
        WriteLine(OutStream, '      <Bal>');
        WriteLine(OutStream, '        <Tp>');
        WriteLine(OutStream, '          <CdOrPrtry>');
        WriteLine(OutStream, '            <Cd>OPBD</Cd>');
        WriteLine(OutStream, '          </CdOrPrtry>');
        WriteLine(OutStream, '        </Tp>');
        WriteLine(OutStream, '      <Amt Ccy="' + CurrTxt + '">500000</Amt>');
        WriteLine(OutStream, '      <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '      <Dt>');
        WriteLine(OutStream, '        <Dt>2010-10-15</Dt>');
        WriteLine(OutStream, '      </Dt>');
        WriteLine(OutStream, '      </Bal>');
        WriteLine(OutStream, '      <Bal>');
        WriteLine(OutStream, '        <Tp>');
        WriteLine(OutStream, '          <CdOrPrtry>');
        WriteLine(OutStream, '            <Cd>CLBD</Cd>');
        WriteLine(OutStream, '          </CdOrPrtry>');
        WriteLine(OutStream, '        </Tp>');
        WriteLine(OutStream, '      <Amt Ccy="' + CurrTxt + '">435678.50</Amt>');
        WriteLine(OutStream, '      <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '      <Dt>');
        WriteLine(OutStream, StrSubstNo('        <Dt>%1-05-05</Dt>', YearText));
        WriteLine(OutStream, '      </Dt>');
        WriteLine(OutStream, '      </Bal>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="' + CurrTxt + '">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '        <BookgDt>');
        WriteLine(OutStream, StrSubstNo('          <DtTm>%1-05-05T13:15:00+01:00</DtTm>', YearText));
        WriteLine(OutStream, '        </BookgDt>');
        WriteLine(OutStream, '        <ValDt>');
        WriteLine(OutStream, StrSubstNo('          <Dt>%1-05-05</Dt>', YearText));
        WriteLine(OutStream, '        </ValDt>');
        WriteLine(OutStream, '        <AcctSvcrRef>FP-CN_98765/01</AcctSvcrRef>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteLine(OutStream: OutStream; Text: Text)
    begin
        OutStream.WriteText(Text);
        OutStream.WriteText();
    end;

    local procedure ConvertEncoding(TempBlobSource: Codeunit "Temp Blob"; var TempBlobDestination: Codeunit "Temp Blob"; Encoding: DotNet Encoding)
    var
        Writer: DotNet StreamWriter;
        InStream: InStream;
        OutStream: OutStream;
        EncodedText: Text;
    begin
        TempBlobSource.CreateInStream(InStream);
        TempBlobDestination.CreateOutStream(OutStream);

        Writer := Writer.StreamWriter(OutStream, Encoding);

        while 0 <> InStream.ReadText(EncodedText) do
            Writer.WriteLine(EncodedText);

        Writer.Close();
    end;

    local procedure SetupSourceMock(DataExchDefCode: Code[20]; TempBlob: Codeunit "Temp Blob")
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempBlobList: Codeunit "Temp Blob List";
        ErmPeSourceTestMock: Codeunit "ERM PE Source Test Mock";
    begin
        TempBlobList.Add(TempBlob);
        ErmPeSourceTestMock.SetTempBlobList(TempBlobList);

        DataExchDef.Get(DataExchDefCode);
        DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"ERM PE Source Test Mock";
        DataExchDef.Modify();

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.FindFirst();
        DataExchLineDef.Namespace := NamespaceTxt;
        DataExchLineDef.Modify();
    end;

    local procedure SetupGenJnlLineForImport(var GenJnlLine: Record "Gen. Journal Line")
    var
        BankAcc: Record "Bank Account";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        SetupSourceMock('SEPA CAMT', TempBlobUTF8);
        CreateGenJnlLineTemplateWithFilter(GenJnlLine, 'SEPA CAMT');
        BankAcc.Get(GenJnlLine."Bal. Account No.");
        BankAcc.IBAN := IBANTxt;
        BankAcc.Modify(true);
    end;

    local procedure CreateGenJnlLineTemplateWithFilter(var GenJnlLineTemplate: Record "Gen. Journal Line"; DataExchDefCode: Code[20])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccWithBankStatementSetup(BankAccount, DataExchDefCode);
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"Bank Account";
        GenJnlBatch."Bal. Account No." := BankAccount."No.";
        GenJnlBatch.Modify();

        LibraryERM.CreateGeneralJnlLine(GenJnlLineTemplate, GenJnlTemplate.Name,
          GenJnlBatch.Name, GenJnlLineTemplate."Document Type"::Payment, GenJnlLineTemplate."Account Type"::"G/L Account", '', 0);
        GenJnlLineTemplate.Validate("External Document No.", ''); // External Doc. No. is ignored. The user has to specify a value.
        GenJnlLineTemplate.Description := LibraryUtility.GenerateGUID();
        GenJnlLineTemplate.Modify(true);
        GenJnlLineTemplate.Delete(true); // The template needs to removed to not skew when comparing testresults.

        GenJnlLineTemplate.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLineTemplate.SetRange("Journal Batch Name", GenJnlBatch.Name);
    end;

    local procedure CreateGenJnlTemplateForGLAccountImport(var GenJnlLineTemplate: Record "Gen. Journal Line"; DataExchDefCode: Code[20])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateBankExportImportSetup(BankExportImportSetup, DataExchDefCode);
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"G/L Account";
        GenJnlBatch."Bal. Account No." := GLAccount."No.";
        GenJnlBatch."Bank Statement Import Format" := BankExportImportSetup.Code;
        GenJnlBatch.Modify();

        LibraryERM.CreateGeneralJnlLine(GenJnlLineTemplate, GenJnlTemplate.Name,
          GenJnlBatch.Name, GenJnlLineTemplate."Document Type"::Payment, GenJnlLineTemplate."Account Type"::"G/L Account", '', 0);
        GenJnlLineTemplate.Delete(true);
        GenJnlLineTemplate.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLineTemplate.SetRange("Journal Batch Name", GenJnlBatch.Name);
    end;

    local procedure CreateLineExt(var TempGenJnlLine: Record "Gen. Journal Line" temporary; GenJnlLineTemplate: Record "Gen. Journal Line"; DataExchEntryNo: Integer; DataExchLineNo: Integer; LineNo: Integer; DocumentNo: Code[20]; PostingDate: Date; Description: Text[50]; PayerInfo: Text[50]; TransactionInfo: Text[50]; Amount: Decimal; CurrencyCode: Code[10])
    begin
        TempGenJnlLine.Copy(GenJnlLineTemplate);
        TempGenJnlLine.Validate("Data Exch. Entry No.", DataExchEntryNo);
        TempGenJnlLine.Validate("Data Exch. Line No.", DataExchLineNo);
        TempGenJnlLine.Validate("Line No.", LineNo);
        TempGenJnlLine.Validate("Document No.", DocumentNo);
        TempGenJnlLine.Validate("Posting Date", PostingDate);
        TempGenJnlLine.Validate(Description, Description);
        TempGenJnlLine.Validate("Payer Information", PayerInfo);
        TempGenJnlLine.Validate("Transaction Information", TransactionInfo);
        TempGenJnlLine.Validate(Amount, Amount);
        TempGenJnlLine.Validate("Currency Code", CurrencyCode);
        TempGenJnlLine.Insert();
    end;

    local procedure CreateLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary; GenJnlLineTemplate: Record "Gen. Journal Line"; DataExchEntryNo: Integer; DataExchLineNo: Integer; LineNo: Integer; DocumentNo: Code[20]; PostingDate: Date; Description: Text[50]; PayerInfo: Text[50]; TransactionInfo: Text[50]; Amount: Decimal; CurrencyCode: Code[10])
    begin
        CreateLineExt(TempGenJnlLine, GenJnlLineTemplate, DataExchEntryNo, DataExchLineNo, LineNo,
          DocumentNo, PostingDate, Description, PayerInfo, TransactionInfo, Amount, CurrencyCode);
    end;

    local procedure CreateBankAccWithBankStatementSetup(var BankAccount: Record "Bank Account"; DataExchDefCode: Code[20])
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        CreateBankExportImportSetup(BankExportImportSetup, DataExchDefCode);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Statement No.",
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Last Statement No."), DATABASE::"Bank Account"));
        BankAccount."Bank Statement Import Format" := BankExportImportSetup.Code;
        BankAccount.Modify(true);
    end;

    local procedure CreateBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup"; DataExchDefCode: Code[20])
    begin
        BankExportImportSetup.Init();
        BankExportImportSetup.Code :=
          LibraryUtility.GenerateRandomCode(BankExportImportSetup.FieldNo(Code), DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Import;
        if DataExchDefCode <> '' then
            BankExportImportSetup."Data Exch. Def. Code" := DataExchDefCode;
        BankExportImportSetup.Insert();
    end;

    local procedure PrepareImportedDataValidation(var TempExpdGenJnlLine: Record "Gen. Journal Line" temporary; GenJnlLineTemplate: Record "Gen. Journal Line"; CurrencyCode: Code[10])
    var
        DataExch: Record "Data Exch.";
        EntryNo: Integer;
        LineNo: Integer;
        DocNo: Code[20];
    begin
        DataExch.SetRange("Data Exch. Def Code", 'SEPA CAMT');
        DataExch.FindLast();
        EntryNo := DataExch."Entry No.";
        GenJnlLineTemplate.Find();
        LineNo := GenJnlLineTemplate."Line No.";
        DocNo := GenJnlLineTemplate."Document No.";
        CreateLine(TempExpdGenJnlLine, GenJnlLineTemplate, EntryNo, 1, LineNo * 1,
          IncCode(0, DocNo), DMY2Date(5, 5, Date2DMY(WorkDate(), 3)), '', '', '', -105678.5, CurrencyCode);
        CreateLine(TempExpdGenJnlLine, GenJnlLineTemplate, EntryNo, 2, LineNo * 2,
          IncCode(1, DocNo), DMY2Date(8, 8, Date2DMY(WorkDate(), 3)), '', 'MUELLER', '', -105.42, CurrencyCode);
    end;

    local procedure AssertDataInTable(var TempExpectedGenJnlLine: Record "Gen. Journal Line" temporary; var ActualGenJnlLine: Record "Gen. Journal Line"; Msg: Text)
    var
        LineNo: Integer;
    begin
        TempExpectedGenJnlLine.FindFirst();
        ActualGenJnlLine.FindFirst();
        repeat
            LineNo += 1;
            AreEqualRecords(TempExpectedGenJnlLine, ActualGenJnlLine, Msg + 'Line:' + Format(LineNo) + ' ');
        until (TempExpectedGenJnlLine.Next() = 0) or (ActualGenJnlLine.Next() = 0);
        Assert.AreEqual(TempExpectedGenJnlLine.Count, ActualGenJnlLine.Count, 'Row count does not match');
    end;

    local procedure AreEqualRecords(ExpectedRecord: Variant; ActualRecord: Variant; Msg: Text)
    var
        ExpectedRecRef: RecordRef;
        ActualRecRef: RecordRef;
        i: Integer;
    begin
        ExpectedRecRef.GetTable(ExpectedRecord);
        ActualRecRef.GetTable(ActualRecord);

        Assert.AreEqual(ExpectedRecRef.Number, ActualRecRef.Number, 'Tables are not the same');

        for i := 1 to ExpectedRecRef.FieldCount do
            if IsSupportedType(ExpectedRecRef.FieldIndex(i).Value) then
                Assert.AreEqual(ExpectedRecRef.FieldIndex(i).Value, ActualRecRef.FieldIndex(i).Value,
                  StrSubstNo(AssertMsg, Msg, ExpectedRecRef.FieldIndex(i).Name));
    end;

    local procedure IsSupportedType(Value: Variant): Boolean
    begin
        exit(Value.IsBoolean or
          Value.IsOption or
          Value.IsInteger or
          Value.IsDecimal or
          Value.IsText or
          Value.IsCode or
          Value.IsDate or
          Value.IsTime);
    end;

    local procedure GetLastDataExch(): Integer
    var
        DataExch: Record "Data Exch.";
    begin
        DataExch.SetRange("Data Exch. Def Code", 'SEPA CAMT');
        DataExch.FindLast();
        exit(DataExch."Entry No.");
    end;

    local procedure VerifyDataExchFieldIsDeleted(ExchNo: Integer)
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", ExchNo);
        Assert.IsTrue(DataExchField.IsEmpty, 'There should be no remaining related info.');
    end;

    local procedure VerifyDataExchFieldIsKept(ExchNo: Integer)
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", ExchNo);
        Assert.IsFalse(DataExchField.IsEmpty, 'The related info should not be deleted.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DiffCurrConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, DiffCurrQst) > 0, 'Unexpected question:' + Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure IBANMismatchConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, IBANMismatchQst) > 0, 'Unexpected question:' + Question);
        Reply := true;
    end;
}

