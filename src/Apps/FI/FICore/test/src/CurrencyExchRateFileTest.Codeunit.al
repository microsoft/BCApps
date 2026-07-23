// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 148151 "Currency Exch. Rate File Test"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        FileMgt: Codeunit "File Management";
        CurrencyExchangeRateFile: File;
        CurrencyFileExtTxt: Label 'dat';
        EuroCodeTok: Label 'EUR';
        USDCodeTok: Label 'USD';
        WrongLCYCurrencyErr: Label 'File does not contain Exchange rates in LCY Currency';
        NewRatesUpdatedMsg: Label 'New Exchange Rates updated ';
        NoUpdatedCurrenciesMsg: Label 'No updated currencies';
        IsInitialized: Boolean;
        ImportFileName: Text;

    [Test]
    [Scope('OnPrem')]
    procedure ReadEmptyCurrencyFile()
    var
        CurrencyExchRateFileTest: Codeunit "Currency Exch. Rate File Test";
    begin
        Initialize();

        CurrencyExchRateFileTest.SetImportFileName(
          SetupCurrencyExchangeRateFile(''));
        BindSubscription(CurrencyExchRateFileTest);
        CODEUNIT.Run(CODEUNIT::"Currency Exch. Rate Import");

        // Verification: no handler functions are needed.
    end;

    [Test]
    [HandlerFunctions('NoUpdatedCurrenciesMessageHandler')]
    [Scope('OnPrem')]
    procedure ReadCurrencyFileWithWrongFormat()
    var
        CurrencyExchRateFileTest: Codeunit "Currency Exch. Rate File Test";
        String: DotNet String;
        BadData: Text;
    begin
        String := CreateCurrencyLine(USDCodeTok, false, EuroCodeTok);
        BadData := String.Replace('001', '002');
        Initialize();

        CurrencyExchRateFileTest.SetImportFileName(
          SetupCurrencyExchangeRateFile(BadData));
        BindSubscription(CurrencyExchRateFileTest);
        CODEUNIT.Run(CODEUNIT::"Currency Exch. Rate Import");

        // Verification is done in the NoUpdatedCurrenciesMessageHandler
    end;

    [Test]
    [HandlerFunctions('NewRatesUpdatedMessageHandler')]
    [Scope('OnPrem')]
    procedure ReadNonEMUCurrencyFile()
    var
        CurrencyExchRateFileTest: Codeunit "Currency Exch. Rate File Test";
    begin
        Initialize();

        CurrencyExchRateFileTest.SetImportFileName(
          SetupCurrencyExchangeRateFile(CreateCurrencyLine(USDCodeTok, false, EuroCodeTok)));
        BindSubscription(CurrencyExchRateFileTest);
        CODEUNIT.Run(CODEUNIT::"Currency Exch. Rate Import");

        Verify(USDCodeTok);
    end;

    [Test]
    [HandlerFunctions('NewRatesUpdatedMessageHandler')]
    [Scope('OnPrem')]
    procedure ReadEMUCurrencyFile()
    var
        CurrencyExchRateFileTest: Codeunit "Currency Exch. Rate File Test";
    begin
        Initialize();

        CurrencyExchRateFileTest.SetImportFileName(
          SetupCurrencyExchangeRateFile(CreateCurrencyLine(EuroCodeTok, true, EuroCodeTok)));
        BindSubscription(CurrencyExchRateFileTest);
        CODEUNIT.Run(CODEUNIT::"Currency Exch. Rate Import");

        Verify(EuroCodeTok);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadWrongLCYFile()
    var
        CurrencyExchRateFileTest: Codeunit "Currency Exch. Rate File Test";
    begin
        Initialize();

        CurrencyExchRateFileTest.SetImportFileName(
          SetupCurrencyExchangeRateFile(CreateCurrencyLine(EuroCodeTok, true, USDCodeTok)));
        BindSubscription(CurrencyExchRateFileTest);
        asserterror CODEUNIT.Run(CODEUNIT::"Currency Exch. Rate Import");

        Assert.ExpectedError(WrongLCYCurrencyErr);
    end;

    [Test]
    [HandlerFunctions('NoUpdatedCurrenciesMessageHandler')]
    [Scope('OnPrem')]
    procedure ReadNonExistingCurrencyFile()
    var
        CurrencyExchRateFileTest: Codeunit "Currency Exch. Rate File Test";
    begin
        Initialize();

        CurrencyExchRateFileTest.SetImportFileName(
          SetupCurrencyExchangeRateFile(CreateCurrencyLine('AAA', false, EuroCodeTok)));
        BindSubscription(CurrencyExchRateFileTest);
        CODEUNIT.Run(CODEUNIT::"Currency Exch. Rate Import");

        // Verification is done in the NoUpdatedCurrenciesMessageHandler
    end;

#if not CLEAN29
    [Test]
    [HandlerFunctions('NewRatesUpdatedMessageHandler')]
    [Scope('OnPrem')]
    procedure ReadCurrencyFileUsingLegacyCodeunit()
    var
        CurrencyExchRateFileTest: Codeunit "Currency Exch. Rate File Test";
    begin
        Initialize();

        CurrencyExchRateFileTest.SetImportFileName(
          SetupCurrencyExchangeRateFile(CreateCurrencyLine(USDCodeTok, false, EuroCodeTok)));
        BindSubscription(CurrencyExchRateFileTest);
#pragma warning disable AL0432
        CODEUNIT.Run(CODEUNIT::"Currency Exchange Rate");
#pragma warning restore AL0432

        Verify(USDCodeTok);
    end;
#endif

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Currency Exch. Rate File Test");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Currency Exch. Rate File Test");

        if not Currency.Get(EuroCodeTok) then begin
            Currency.Init();
            Currency.Code := EuroCodeTok;
            Currency."EMU Currency" := true;
            Currency.Insert();
        end;

        if not Currency.Get(USDCodeTok) then begin
            Currency.Init();
            Currency.Code := USDCodeTok;
            Currency.Insert();
        end;

        CurrencyExchangeRate.SetFilter("Currency Code", '%1|%2', EuroCodeTok, USDCodeTok);
        CurrencyExchangeRate.SetRange("Starting Date", Today);
        CurrencyExchangeRate.DeleteAll();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Currency Exch. Rate File Test");
    end;

    local procedure CreateCurrencyLine(CurrencyCode: Code[3]; IsEmu: Boolean; LCYCode: Code[3]): Text
    var
        EmuValue: Text[1];
    begin
        if IsEmu then
            EmuValue := '1'
        else
            EmuValue := '0';

        // Data.Length = 151, Example from http://openpages.nordea.com/fi/lists/currency/elelctronicExchangeFI.dat
        // VK01001199901010730000001EUREUR00000100000000000010000000000001000000000000100000000000010000000+K000000000K
        // VK01001201312110803290001USDEUR00000137580000000013943000000001357300000000141779900000013338000+K000000000K
        // VK01001201312110803230001JPYEUR00014136599700001437660060000138966003000014546600300001369559930-K000000000K
        // ...

        exit(
          'VK01001' +
          Format(Today, 0, '<Year4><Month,2><Day,2>') +
          '0730000001' +
          CurrencyCode +
          LCYCode +
          '00000100000000000010000000000001000000000000100000000000010000000+K' +
          EmuValue +
          '00000000K                                          ');
    end;

    [Scope('OnPrem')]
    procedure SetImportFileName(NewFileName: Text)
    begin
        ImportFileName := NewFileName;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NoUpdatedCurrenciesMessageHandler(Message: Text)
    begin
        Assert.AreEqual(Format(NoUpdatedCurrenciesMsg), Message, 'Wrong status message.');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NewRatesUpdatedMessageHandler(Message: Text)
    begin
        Assert.AreEqual(Format(NewRatesUpdatedMsg), Message, 'Wrong status message.');
    end;

    local procedure Verify(CurrencyCode: Code[3])
    begin
        CurrencyExchangeRate.SetFilter("Currency Code", CurrencyCode);
        CurrencyExchangeRate.SetRange("Starting Date", Today);
        Assert.AreEqual(1, CurrencyExchangeRate.Count, 'The expected currency exchange rate record was not found.');
    end;

    [Normal]
    local procedure SetupCurrencyExchangeRateFile(CurrencyExchangeRateData: Text): Text
    var
        CurrencyExchangeRateFileName: Text;
    begin
        CurrencyExchangeRateFileName := FileMgt.ServerTempFileName(CurrencyFileExtTxt);

        CurrencyExchangeRateFile.Create(CurrencyExchangeRateFileName);
        CurrencyExchangeRateFile.TextMode := true;
        CurrencyExchangeRateFile.Write(CurrencyExchangeRateData);
        CurrencyExchangeRateFile.Close();

        exit(CurrencyExchangeRateFileName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Currency Exch. Rate Import", 'OnBeforeFileImport', '', false, false)]
    local procedure OnBeforeFileImport(var FileName: Text)
    begin
        FileName := ImportFileName;
    end;

#if not CLEAN29
#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Currency Exchange Rate", 'OnBeforeFileImport', '', false, false)]
    local procedure OnBeforeLegacyFileImport(var FileName: Text)
    begin
        FileName := ImportFileName;
    end;
#pragma warning restore AL0432
#endif
}
