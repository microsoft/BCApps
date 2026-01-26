codeunit 144001 CurrencyExchangeRateFile
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
        Codeunit32000001Text1090000Err: Label 'File does not contain Exchange rates in LCY Currency';
        Codeunit32000001Text1090001Msg: Label 'New Exchange Rates updated ';
        Codeunit32000001Text1090002Msg: Label 'No updated currencies';
        IsInitialized: Boolean;
        ImportFileName: Text;

    [Test]
    [Scope('OnPrem')]
    procedure ReadEmptyCurrencyFile()
    var
        CurrencyExchangeRateFile: Codeunit CurrencyExchangeRateFile;
    begin
        Initialize();

        CurrencyExchangeRateFile.SetImportFileName(
          SetupCurrencyExchangeRateFile(''));
        BindSubscription(CurrencyExchangeRateFile);
        CODEUNIT.Run(CODEUNIT::"Currency Exchange Rate");

        // Verification: no handler functions are needed.
    end;

    [Test]
    [HandlerFunctions('Text1090002MessageHandler')]
    [Scope('OnPrem')]
    procedure ReadCurrencyFileWithWrongFormat()
    var
        CurrencyExchangeRateFile: Codeunit CurrencyExchangeRateFile;
        String: DotNet String;
        BadData: Text;
    begin
        String := CreateCurrencyLine(USDCodeTok, false, EuroCodeTok);
        BadData := String.Replace('001', '002');
        Initialize();

        CurrencyExchangeRateFile.SetImportFileName(
          SetupCurrencyExchangeRateFile(BadData));
        BindSubscription(CurrencyExchangeRateFile);
        CODEUNIT.Run(CODEUNIT::"Currency Exchange Rate");

        // Verification is done in the Text1090002MessageHandler
    end;

    [Test]
    [HandlerFunctions('Text1090001MessageHandler')]
    [Scope('OnPrem')]
    procedure ReadNonEMUCurrencyFile()
    var
        CurrencyExchangeRateFile: Codeunit CurrencyExchangeRateFile;
    begin
        Initialize();

        CurrencyExchangeRateFile.SetImportFileName(
          SetupCurrencyExchangeRateFile(CreateCurrencyLine(USDCodeTok, false, EuroCodeTok)));
        BindSubscription(CurrencyExchangeRateFile);
        CODEUNIT.Run(CODEUNIT::"Currency Exchange Rate");

        Verify(USDCodeTok);
    end;

    [Test]
    [HandlerFunctions('Text1090001MessageHandler')]
    [Scope('OnPrem')]
    procedure ReadEMUCurrencyFile()
    var
        CurrencyExchangeRateFile: Codeunit CurrencyExchangeRateFile;
    begin
        Initialize();

        CurrencyExchangeRateFile.SetImportFileName(
          SetupCurrencyExchangeRateFile(CreateCurrencyLine(EuroCodeTok, true, EuroCodeTok)));
        BindSubscription(CurrencyExchangeRateFile);
        CODEUNIT.Run(CODEUNIT::"Currency Exchange Rate");

        Verify(EuroCodeTok);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadWrongLCYFile()
    var
        CurrencyExchangeRateFile: Codeunit CurrencyExchangeRateFile;
    begin
        Initialize();

        CurrencyExchangeRateFile.SetImportFileName(
          SetupCurrencyExchangeRateFile(CreateCurrencyLine(EuroCodeTok, true, USDCodeTok)));
        BindSubscription(CurrencyExchangeRateFile);
        asserterror CODEUNIT.Run(CODEUNIT::"Currency Exchange Rate");

        Assert.ExpectedError(Codeunit32000001Text1090000Err);
    end;

    [Test]
    [HandlerFunctions('Text1090002MessageHandler')]
    [Scope('OnPrem')]
    procedure ReadNonExistingCurrencyFile()
    var
        CurrencyExchangeRateFile: Codeunit CurrencyExchangeRateFile;
    begin
        Initialize();

        CurrencyExchangeRateFile.SetImportFileName(
          SetupCurrencyExchangeRateFile(CreateCurrencyLine('AAA', false, EuroCodeTok)));
        BindSubscription(CurrencyExchangeRateFile);
        CODEUNIT.Run(CODEUNIT::"Currency Exchange Rate");

        // Verification is done in the Text1090002MessageHandler
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::CurrencyExchangeRateFile);
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::CurrencyExchangeRateFile);

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
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::CurrencyExchangeRateFile);
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
    procedure Text1090002MessageHandler(Message: Text)
    begin
        Assert.AreEqual(Format(Codeunit32000001Text1090002Msg), Message, 'Wrong status message.');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure Text1090001MessageHandler(Message: Text)
    begin
        Assert.AreEqual(Format(Codeunit32000001Text1090001Msg), Message, 'Wrong status message.');
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Currency Exchange Rate", 'OnBeforeFileImport', '', false, false)]
    local procedure OnBeforeFileImport(var FileName: Text)
    begin
        FileName := ImportFileName;
    end;
}

