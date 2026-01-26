codeunit 134802 "Positive Pay Test Unit 2"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Positive Pay]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        ExpLauncherPosPay: Codeunit "Exp. Launcher Pos. Pay";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        isInitialized: Boolean;
        PositivePayFileNotFoundErr: Label 'The original positive pay export file was not found.';
        TransformationErr: Label 'Transformation rule not applied';
        ExtraLineErr: Label 'Extra empty line found in files.';
        AmountStringErr: Label 'Amount substring contains incorrect symbols.';
        PeriodTxt: Label '.', Comment = '.';
        CommaTxt: Label ',', Comment = ',';
        NoDecimalMarkErr: Label 'Random number does not have decimal mark.';
        StringValuesNotEqualErr: Label 'String vales must be equal.';

    [Test]
    [Scope('OnPrem')]
    procedure TestPositivePayDefaultFormats()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchCode: Code[20];
    begin
        // [SCENARIO 122825] Test that user can select New Positive Pay Default Formats
        // [GIVEN] User has loaded the default data, which includes Citibank and Bank of America formats

        DataExchCode := 'BANKOFAMERICA-PP';
        DataExchDef.Get(DataExchCode);
        DataExchDef.TestField(Type, DataExchDef.Type::"Positive Pay Export");

        DataExchCode := 'CITIBANK-PP';
        DataExchDef.Get(DataExchCode);
        DataExchDef.TestField(Type, DataExchDef.Type::"Positive Pay Export");
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestGenerationOfExportFile()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PositivePayEntry: Record "Positive Pay Entry";
        LibraryUtility: Codeunit "Library - Utility";
        BankAccountNumber: Code[20];
        FieldNo: Integer;
    begin
        // [SCENARIO 122869] Test that user can generate a Positive Pay Upload file
        // [GIVEN] User has created a Data Exchange Definition of type "Positive Pay Export"
        // They should already have 2 new positive pay Data Exchange codes to choose from.
        // [GIVEN] User has set up a Bank Export/Import Code to use this new Data Exchange Definition
        BankExportImportSetup.Init();
        FieldNo := BankExportImportSetup.FieldNo(Code);
        BankExportImportSetup.Code := LibraryUtility.GenerateRandomCode(FieldNo, DATABASE::"Bank Export/Import Setup");
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::"Export-Positive Pay";
        BankExportImportSetup.Validate(Direction);
        // BankExportImportSetup."Data Exch. Def. Code" := 'CITIBANK-PP';
        BankExportImportSetup."Data Exch. Def. Code" := 'BANKOFAMERICA-PP';

        BankExportImportSetup.Insert();

        // [GIVEN] User has set up Bank Account to use the Bank Export/Import Code
        BankAccountNumber := CreateBankAccount(BankExportImportSetup.Code);

        // [GIVEN] User has set up checks drawn from this Bank Account
        CreateCheckLedgerEntries(CheckLedgerEntry, BankAccountNumber);

        // Exercise
        // Pull up the checks for the new bank account and export checks
        BankAccount.Get(BankAccountNumber);

        if BankAccount.GetPosPayExportCodeunitID() > 0 then
            ExpLauncherPosPay.PositivePayProcess(CheckLedgerEntry, false);

        // Check for the existence of the file, we'll do this by checking to make sure the blob
        // created and stored in the Positive Pay Entry table is not empty/null
        PositivePayEntry.SetRange("Bank Account No.", BankAccountNumber);
        if PositivePayEntry.FindFirst() then begin
            PositivePayEntry.CalcFields("Exported File");
            if not PositivePayEntry."Exported File".HasValue() then
                Error(PositivePayFileNotFoundErr);
        end;
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure TestGenerationOfExportFileWithoutFooter()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PositivePayEntry: Record "Positive Pay Entry";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempDataExchLineDef: Record "Data Exch. Line Def" temporary;
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 379318] Export Positive Pay that has no Footer
        // [GIVEN] Bank Export/Import Setup used Data Exchange Definition of type "Positive Pay Export"
        LibraryPaymentExport.CreateBankExportImportSetup(
          BankExportImportSetup, FindPositivePayExportDataExchDef(DataExchLineDef."Line Type"::Footer));
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::"Export-Positive Pay");
        BankExportImportSetup.Modify(true);

        // [GIVEN] Data Exchange Definition Footer line deleted
        RemoveDataExchByType(BankExportImportSetup."Data Exch. Def. Code", DataExchLineDef."Line Type"::Footer, TempDataExchLineDef);

        // [GIVEN] Bank Account to use the Bank Export/Import Code
        BankAccountNo := CreateBankAccount(BankExportImportSetup.Code);

        // [GIVEN] Check Ledger Entries of Bank Account to export
        CreateCheckLedgerEntries(CheckLedgerEntry, BankAccountNo);

        // [WHEN] Export Positive Pay
        ExpLauncherPosPay.PositivePayProcess(CheckLedgerEntry, false);

        // [THEN] BLOB created and stored in the Positive Pay Entry table is not empty/null
        GetPositivePayExportedFile(PositivePayEntry, BankAccountNo);
        Assert.IsTrue(PositivePayEntry."Exported File".HasValue, PositivePayFileNotFoundErr);

        // Tear-down
        DataExchLineDef := TempDataExchLineDef;
        DataExchLineDef.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTextTransformationOnPositivePayExport()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PositivePayEntry: Record "Positive Pay Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DataExchLineDef: Record "Data Exch. Line Def";
        BankAccountNo: Code[20];
        RecordTypeCodeOnFile: Text[1];
        ReplaceByValue: Text[1];
        ReplacePosition: Integer;
    begin
        // [SCENARIO 379424] Text Tranformation by rules when export Positive Pay
        Initialize();

        // [GIVEN] Bank Export/Import Setup used Data Exchange Definition of type "Positive Pay Export"
        LibraryPaymentExport.CreateBankExportImportSetup(
          BankExportImportSetup, FindPositivePayExportDataExchDef(DataExchLineDef."Line Type"::Detail));
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::"Export-Positive Pay");
        BankExportImportSetup.Modify(true);

        // [GIVEN] Bank Account to use the Bank Export/Import Code
        BankAccountNo := CreateBankAccount(BankExportImportSetup.Code);

        // [GIVEN] Check Ledger Entry of Bank Account to export with Record Type Code = 'O'
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bank Payment Type"::"Manual Check", '', BankAccountNo, LibraryRandom.RandDec(1000, 2), '');

        // [GIVEN] Data Exchange Detail Column added with Transformation Rule to replace Record Type Code to ReplaceByValue
        ReplaceByValue := CopyStr(LibraryUtility.GenerateRandomText(1), 1, 1);
        AddDetailColumnWithReplaceRule(BankExportImportSetup."Data Exch. Def. Code", ReplaceByValue, ReplacePosition);

        // [WHEN] Export Positive Pay
        FilterCheckLedgerEntry(CheckLedgerEntry, BankAccountNo);
        ExpLauncherPosPay.PositivePayProcess(CheckLedgerEntry, false);

        // [THEN] Record Type Code on detail line of Positive Pay file replaced to ReplaceByValue
        GetPositivePayExportedFile(PositivePayEntry, BankAccountNo);
        RecordTypeCodeOnFile := GetRecordTypeCodeOnFileDetailLine(PositivePayEntry, ReplaceByValue, ReplacePosition);
        Assert.AreEqual(ReplaceByValue, RecordTypeCodeOnFile, TransformationErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositivePayExportWithoutHeader()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PositivePayEntry: Record "Positive Pay Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempDataExchLineDef: Record "Data Exch. Line Def" temporary;
        Stream: InStream;
        TextLine: Text;
        BankAccountNo: Code[20];
        LineCount: Integer;
    begin
        // [SCENARIO 380648] Exported Positive Pay file should not contain empty line in the beginning, if there is no header in Data Exchange Setup
        Initialize();

        // [GIVEN] Bank Export/Import Setup used Data Exchange Definition of type "Positive Pay Export" having no header
        LibraryPaymentExport.CreateBankExportImportSetup(
          BankExportImportSetup, FindPositivePayExportDataExchDef(DataExchLineDef."Line Type"::Detail));
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::"Export-Positive Pay");
        BankExportImportSetup.Modify(true);

        RemoveDataExchByType(BankExportImportSetup."Data Exch. Def. Code", DataExchLineDef."Line Type"::Header, TempDataExchLineDef);

        // [GIVEN] Bank Account to use the Bank Export/Import Code
        BankAccountNo := CreateBankAccount(BankExportImportSetup.Code);

        // [GIVEN] Check Ledger Entry of Bank Account to export
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bank Payment Type"::"Manual Check", '', BankAccountNo, LibraryRandom.RandDec(1000, 2), '');

        // [WHEN] Export Positive Pay
        FilterCheckLedgerEntry(CheckLedgerEntry, BankAccountNo);
        ExpLauncherPosPay.PositivePayProcess(CheckLedgerEntry, false);

        // [THEN] Exported file does not contain empty line in the beginning
        GetPositivePayExportedFile(PositivePayEntry, BankAccountNo);
        PositivePayEntry."Exported File".CreateInStream(Stream);
        while not Stream.EOS do begin
            Stream.ReadText(TextLine);
            LineCount += 1;
        end;
        Assert.AreEqual(2, LineCount, ExtraLineErr);

        // Tear-down
        DataExchLineDef := TempDataExchLineDef;
        DataExchLineDef.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveDecimalFromStringWithDecimalUT()
    var
        StringConversionManagement: Codeunit StringConversionManagement;
        DecimalRandom: Decimal;
        FractureRandom: Decimal;
        PadLengthLess: Integer;
        PadLengthExact: Integer;
        PadLengthExceeds: Integer;
        IntegerRandom: Integer;
        MarkPosNo: Integer;
        WaveNo: Integer;
        DecimalString: Text[250];
        ResultStringArray: array[3] of Text;
        IntegerString: Text;
        FractureString: Text;
        PadChar: Text[1];
        MarkChar: Text[1];
        Justification: Option Right,Left;
    begin
        // [SCENARIO 381212] A decimal mark is removed from a string containing any decimal value
        // [FEATURE] [UT]
        Initialize();
        PadChar := CopyStr(LibraryUtility.GenerateRandomText(1), 1, 1);

        for WaveNo := 1 to LibraryRandom.RandIntInRange(5, 35) do begin
            IntegerRandom := LibraryRandom.RandInt(2147483647);
            while FractureRandom = 0 do
                FractureRandom := LibraryRandom.RandDecInDecimalRange(0, 0.99999999, 8);
            DecimalRandom := IntegerRandom + FractureRandom;
            DecimalString := Format(DecimalRandom, 0, 1);

            // Only two type of decimal mark allowed by ISO standard - Comma or Period
            MarkPosNo := StrPos(DecimalString, PeriodTxt);
            if MarkPosNo = 0 then
                MarkPosNo := StrPos(DecimalString, CommaTxt);
            Assert.AreNotEqual(0, MarkPosNo, NoDecimalMarkErr);
            MarkChar := CopyStr(DecimalString, MarkPosNo, 1);

            PadLengthLess := StrLen(DecimalString) - StrLen(PadChar) - StrLen(MarkChar);
            PadLengthExact := StrLen(DecimalString) - StrLen(MarkChar);
            PadLengthExceeds := StrLen(DecimalString) + StrLen(PadChar) - StrLen(MarkChar);

            IntegerString := CopyStr(DecimalString, 1, MarkPosNo - 1);
            FractureString := CopyStr(DecimalString, MarkPosNo + 1, StrLen(DecimalString) - MarkPosNo);

            ResultStringArray[1] :=
              StringConversionManagement.RemoveDecimalFromString(DecimalString, PadLengthLess, PadChar, Justification::Right);
            ResultStringArray[2] :=
              StringConversionManagement.RemoveDecimalFromString(DecimalString, PadLengthExact, PadChar, Justification::Right);
            ResultStringArray[3] :=
              StringConversionManagement.RemoveDecimalFromString(DecimalString, PadLengthExceeds, PadChar, Justification::Right);

            Assert.AreEqual(DecimalString, ResultStringArray[1], StringValuesNotEqualErr);
            Assert.AreEqual(IntegerString + FractureString, ResultStringArray[2], StringValuesNotEqualErr);
            Assert.AreEqual(PadChar + IntegerString + FractureString, ResultStringArray[3], StringValuesNotEqualErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveDecimalFromStringWithIntegerUT()
    var
        StringConversionManagement: Codeunit StringConversionManagement;
        IntegerString: Text[250];
        ResultStringArray: array[3] of Text;
        PadChar: Text[1];
        WaveNo: Integer;
        PadLengthLess: Integer;
        PadLengthExact: Integer;
        PadLengthExceeds: Integer;
        Justification: Option Right,Left;
    begin
        // [SCENARIO 381212] If a string contains integer value, its treated like a value without decimal mark
        // [FEATURE] [UT]
        Initialize();
        PadChar := CopyStr(LibraryUtility.GenerateRandomText(1), 1, 1);

        for WaveNo := 1 to LibraryRandom.RandIntInRange(5, 35) do begin
            IntegerString := Format(LibraryRandom.RandInt(2147483647));

            PadLengthLess := StrLen(IntegerString) - StrLen(PadChar);
            PadLengthExact := StrLen(IntegerString);
            PadLengthExceeds := StrLen(IntegerString) + StrLen(PadChar);

            ResultStringArray[1] :=
              StringConversionManagement.RemoveDecimalFromString(IntegerString, PadLengthLess, PadChar, Justification::Right);
            ResultStringArray[2] :=
              StringConversionManagement.RemoveDecimalFromString(IntegerString, PadLengthExact, PadChar, Justification::Right);
            ResultStringArray[3] :=
              StringConversionManagement.RemoveDecimalFromString(IntegerString, PadLengthExceeds, PadChar, Justification::Right);

            Assert.AreEqual(IntegerString, ResultStringArray[1], StringValuesNotEqualErr);
            Assert.AreEqual(IntegerString, ResultStringArray[2], StringValuesNotEqualErr);
            Assert.AreEqual(PadChar + IntegerString, ResultStringArray[3], StringValuesNotEqualErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveDecimalFromStringWithTextUT()
    var
        StringConversionManagement: Codeunit StringConversionManagement;
        OriginalString: Text[250];
        PadChar: Text[1];
        PadLength: Integer;
        Justification: Option Right,Left;
    begin
        // [SCENARIO 381212] If a string contains no decimal or integer, then the original string is returned
        // [FEATURE] [UT]

        Initialize();
        PadChar := CopyStr(LibraryUtility.GenerateRandomText(1), 1, 1);
        OriginalString := LibraryUtility.GenerateGUID();
        PadLength := StrLen(OriginalString) + StrLen(PadChar);
        Assert.AreEqual(
          StringConversionManagement.RemoveDecimalFromString(OriginalString, PadLength, PadChar, Justification::Right),
          OriginalString, StringValuesNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositivePayExportDecimalWithCurrentRegionalSettings()
    var
        InputAmount: Decimal;
        ExpectedAmount: Text[250];
    begin
        // [SCENARIO 382044] Export Positive Pay with Decimal Amount, receiving output value with decimal and thousands separators are taken from Regional setting, left adjusted
        InputAmount := 1234567.8;
        ExpectedAmount := Format(InputAmount, 0, '<Standard Format,0>');
        ExpectedAmount := PadStr(ExpectedAmount, 12, ' ');

        // [GIVEN] no Transformation Rule, padding is OFF, decimals and thousands from regional settings
        // [WHEN] Export Positive Pay with Decimal Amount = 1234567.8
        // [THEN] receiving output value "1.234.567,8 "
        PositivePayExport(InputAmount, ExpectedAmount, '', false, '', '<Standard Format,0>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositivePayExportDecimalWithNoThousandthsDotNoLeading()
    begin
        // [SCENARIO 382044] Export Positive Pay with Decimal Amount receiving output value with a dot as decimal separator, no thousands separator, left adjusted

        // [GIVEN] no Transformation Rule, padding is OFF
        // [WHEN] Export Positive Pay with Decimal Amount = 12345678.9
        // [THEN] receiving output value "12345678.90 "
        PositivePayExport(12345678.9, '12345678.90 ', '', false, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositivePayExportDecimalWithNoThousandthsDotLeading()
    begin
        // [SCENARIO 382044] Export Positive Pay with Decimal Amount, receiving output value with a dot as decimal separator, no thousands separator, "0" as leading character

        // [GIVEN] no Transformation Rule, padding is ON with "0" as filler
        // [WHEN] Export Positive Pay with Decimal Amount = 12345678.9
        // [THEN] receiving output value "012345678.90"
        PositivePayExport(12345678.9, '012345678.90', '', true, '0', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositivePayExportDecimalWithNoThousandthsNoDotLeading()
    begin
        // [SCENARIO 381212] Export Positive Pay with Decimal Amount, receiving output value with no decimal and thousands separators, "0" as leading character

        // [GIVEN] Transformation Rule = "ALPHANUMERIC_ONLY", padding is ON with "0" as filler
        // [WHEN] Export Positive Pay with Decimal Amount = 123456789.1
        // [THEN] receiving output value "012345678910"
        PositivePayExport(123456789.1, '012345678910', 'ALPHANUMERIC_ONLY', true, '0', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReplaceBlankValueWithText()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PositivePayEntry: Record "Positive Pay Entry";
        GenJournalLine: Record "Gen. Journal Line";
        TempDataExchLineDef: array[2] of Record "Data Exch. Line Def" temporary;
        DataExchLineDef: Record "Data Exch. Line Def";
        BankAccountNo: Code[20];
        ReplaceByValue: Text[250];
    begin
        // [FEATURE] [Data Exchange] [Transformation Rule]
        // [SCENARIO 293066] When Export Positive Pay, blank value can be replaced with symbol using regex-replace transformation rule.
        Initialize();

        // [GIVEN] Bank Export/Import Setup used Data Exchange Definition of type "Positive Pay Export"
        LibraryPaymentExport.CreateBankExportImportSetup(
          BankExportImportSetup, FindPositivePayExportDataExchDef(DataExchLineDef."Line Type"::Detail));
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::"Export-Positive Pay");
        BankExportImportSetup.Modify(true);

        RemoveDataExchByType(BankExportImportSetup."Data Exch. Def. Code", DataExchLineDef."Line Type"::Footer, TempDataExchLineDef[1]);
        RemoveDataExchByType(BankExportImportSetup."Data Exch. Def. Code", DataExchLineDef."Line Type"::Header, TempDataExchLineDef[2]);

        // [GIVEN] Bank Account to use the Bank Export/Import Code
        BankAccountNo := CreateBankAccount(BankExportImportSetup.Code);

        // [GIVEN] Check Ledger Entry of Bank Account to export with blank Void Check Indicator
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bank Payment Type"::"Manual Check", '', BankAccountNo, LibraryRandom.RandDec(1000, 2), '');

        // [GIVEN] Data Exchange Definition contains only Detail Line Definition.
        // [GIVEN] Data Line Definition mapping contains the only column with Transformation Rule.
        // [GIVEN] Transformation Rule using regex-replace type must replace blank value into "XYZ".
        ReplaceByValue := CopyStr(LibraryUtility.GenerateRandomText(LibraryRandom.RandInt(10)), 1, MaxStrLen(ReplaceByValue));
        AddDetailColumnWithRegexReplaceRule(
          BankExportImportSetup."Data Exch. Def. Code", '^(?![\s\S])', ReplaceByValue, StrLen(ReplaceByValue));

        // [WHEN] Export Positive Pay
        FilterCheckLedgerEntry(CheckLedgerEntry, BankAccountNo);
        ExpLauncherPosPay.PositivePayProcess(CheckLedgerEntry, false);

        // [THEN] Blank Void Check Indicator on the detail line is replaced to "XYZ"
        GetPositivePayExportedFile(PositivePayEntry, BankAccountNo);
        Assert.AreEqual(ReplaceByValue, GetReplaceValueFromFileDetailLine(PositivePayEntry), TransformationErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Positive Pay Test Unit 2");
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Positive Pay Test Unit 2");
        LibraryERMCountryData.DisableActivateChequeNoOnGeneralLedgerSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        CreateAccountingPeriodsWithNewFiscalYear();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Positive Pay Test Unit 2");
    end;

    [HandlerFunctions('VoidCheckPageHandler,ConfirmHandler')]
    local procedure CreateCheckLedgerEntries(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountNumber: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        CheckCount: Integer;
        VoidType: Option "Unapply and void check","Void check only";
    begin
        // Test that system correctly apply and unapply the Check ledger entries for Vendor.
        // Setup: Post Payment Journal for Vendor and modify Bank Account Reconciliation Line with type "Check Ledger Entry".
        FilterCheckLedgerEntry(CheckLedgerEntry, BankAccountNumber);

        Initialize();
        // Try to hit as many account types as possible, for code coverage
        for CheckCount := 1 to 2 do
            CreateAndPostGenJournalLine(
              GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
              GenJournalLine."Bank Payment Type"::"Manual Check", '', BankAccountNumber, LibraryRandom.RandDec(1000, 2), '');
        for CheckCount := 1 to 2 do
            CreateAndPostGenJournalLine(
              GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
              GenJournalLine."Bank Payment Type"::"Manual Check", '', BankAccountNumber, LibraryRandom.RandDec(1000, 2), '');
        for CheckCount := 1 to 2 do
            CreateAndPostGenJournalLine(
              GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
              GenJournalLine."Bank Payment Type"::"Manual Check", '', BankAccountNumber, LibraryRandom.RandDec(1000, 2), '');
        for CheckCount := 1 to 2 do
            CreateAndPostGenJournalLine(
              GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"Bank Account", BankAccountNumber,
              GenJournalLine."Bank Payment Type"::"Manual Check", '', BankAccountNumber, LibraryRandom.RandDec(1000, 2), '');
        // Create a couple of checks to void
        for CheckCount := 1 to 2 do begin
            CreateAndPostGenJournalLine(
              GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
              GenJournalLine."Bank Payment Type"::"Manual Check", '', BankAccountNumber, LibraryRandom.RandDec(1000, 2), '');
            LibraryVariableStorage.Enqueue(VoidType::"Void check only");
            VoidCheck(GenJournalLine."Document No.");
        end;
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type"; CurrencyCode: Code[10]; BalAccountNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        // Take Random Amount for General Journal Line.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(true));
        // Get Posting Date for Closed Financial Year.
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateBankAccount(BankExportCode: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Statement No.", Format(LibraryRandom.RandInt(10)));  // Take Random Value.
        BankAccount.Validate("Positive Pay Export Code", BankExportCode);
        BankAccount.Validate("Bank Account No.", Format(LibraryRandom.RandInt(1000000000)));
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type"; CurrencyCode: Code[10]; BalAccountNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20])
    begin
        CreateGenJournalLine(
          GenJournalLine, DocumentType, AccountType, AccountNo, BankPaymentType, CurrencyCode, BalAccountNo, Amount, AppliesToDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAccountingPeriodsWithNewFiscalYear()
    var
        AccountingPeriod: Record "Accounting Period";
        i: Integer;
    begin
        // Create Fiscal Year.
        LibraryFiscalYear.CloseAccountingPeriod();
        LibraryFiscalYear.CreateFiscalYear();
        FindAccountingPeriod(AccountingPeriod);
        while not (AccountingPeriod."Starting Date" >= WorkDate()) do
            AccountingPeriod.Next(); // Cannot Calculate FA Depreciation if Depreciation Date earlier than Workdate

        // For first 4 months, mark "New Fiscal Year Period" as true.
        for i := 1 to 4 do begin
            UpdateAccountingPeriodForNewFiscalYear(AccountingPeriod, true);
            AccountingPeriod.Next();
        end;
    end;

    local procedure FindAccountingPeriod(var AccountingPeriod: Record "Accounting Period")
    begin
        AccountingPeriod.SetRange("New Fiscal Year", false);
        AccountingPeriod.SetRange(Closed, false);
        AccountingPeriod.SetRange("Date Locked", false);
        AccountingPeriod.FindFirst();
    end;

    local procedure FindPositivePayExportDataExchDef(LineType: Option): Code[20]
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchDef.SetRange(Type, DataExchDef.Type::"Positive Pay Export");
        DataExchDef.FindSet();
        repeat
            DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
            DataExchLineDef.SetRange("Line Type", LineType);
            if not DataExchLineDef.IsEmpty() then
                exit(DataExchDef.Code);
        until DataExchDef.Next() = 0;
        exit('');
    end;

    local procedure FilterCheckLedgerEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountNo: Code[20])
    begin
        CheckLedgerEntry.SetCurrentKey("Bank Account No.", "Check Date");
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.SetRange("Check Date", 0D, WorkDate());
    end;

    local procedure AddDetailColumnWithReplaceRule(DataExchDefCode: Code[20]; ReplaceValue: Text[1]; var ReplacePosition: Integer)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TransformationRule: Record "Transformation Rule";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Detail);
        DataExchLineDef.FindFirst();
        DataExchLineDef.Validate("Column Count", DataExchLineDef."Column Count" + 1);
        DataExchLineDef.Modify(true);

        DataExchColumnDef.InsertRec(
          DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, DataExchLineDef."Column Count", 'Record Type Code',
          true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.Validate(Length, 1);
        DataExchColumnDef.Modify(true);

        DataExchMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchMapping.FindFirst();
        DataExchFieldMapping.InsertRec(
          DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, DataExchMapping."Table ID",
          DataExchColumnDef."Column No.", 4, false, 0);

        TransformationRule.Init();
        TransformationRule.Validate(Code, LibraryUtility.GenerateGUID());
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Replace);
        TransformationRule.Validate("Find Value", 'O');
        TransformationRule.Validate("Replace Value", ReplaceValue);
        TransformationRule.Insert();

        DataExchFieldMapping.Validate("Transformation Rule", TransformationRule.Code);
        DataExchFieldMapping.Modify(true);

        ReplacePosition := 0;
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.FindSet();
        repeat
            ReplacePosition += DataExchColumnDef.Length;
        until DataExchColumnDef.Next() = 0;
    end;

    local procedure AddDetailColumnWithRegexReplaceRule(DataExchDefCode: Code[20]; RegexValue: Text[250]; ReplaceValue: Text[250]; Length: Integer)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TransformationRule: Record "Transformation Rule";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Detail);
        DataExchLineDef.FindFirst();
        DataExchLineDef.Validate("Column Count", 1);
        DataExchLineDef.Modify(true);

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.DeleteAll();

        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchFieldMapping.DeleteAll();

        DataExchColumnDef.InsertRec(
          DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, DataExchLineDef."Column Count", 'Void Check Indicator',
          true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.Validate(Length, Length);
        DataExchColumnDef.Modify(true);

        DataExchMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchMapping.FindFirst();
        DataExchFieldMapping.InsertRec(
          DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, DataExchMapping."Table ID", 1, 5, true, 0);

        TransformationRule.Init();
        TransformationRule.Validate(Code, LibraryUtility.GenerateGUID());
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::"Regular Expression - Replace");
        TransformationRule.Validate("Find Value", RegexValue);
        TransformationRule.Validate("Replace Value", CopyStr(ReplaceValue, 1, StrLen(ReplaceValue)));
        TransformationRule.Insert();

        DataExchFieldMapping.Validate("Transformation Rule", TransformationRule.Code);
        DataExchFieldMapping.Modify(true);
    end;

    local procedure GetPositivePayExportedFile(var PositivePayEntry: Record "Positive Pay Entry"; BankAccountNo: Code[20])
    begin
        PositivePayEntry.SetRange("Bank Account No.", BankAccountNo);
        PositivePayEntry.FindFirst();
        PositivePayEntry.CalcFields("Exported File");
    end;

    local procedure GetRecordTypeCodeOnFileDetailLine(var PositivePayEntry: Record "Positive Pay Entry"; ReplacedCode: Text[1]; ReplacePosition: Integer): Text[1]
    var
        Stream: InStream;
        TextLine: Text;
        RecordTypeCodeOnFile: Text[1];
    begin
        PositivePayEntry."Exported File".CreateInStream(Stream);
        while (not Stream.EOS) and (RecordTypeCodeOnFile <> 'O') and (RecordTypeCodeOnFile <> ReplacedCode) do begin
            Stream.ReadText(TextLine);
            RecordTypeCodeOnFile := CopyStr(TextLine, ReplacePosition, 1);
        end;
        exit(RecordTypeCodeOnFile);
    end;

    local procedure GetReplaceValueFromFileDetailLine(var PositivePayEntry: Record "Positive Pay Entry") TextLine: Text
    var
        Stream: InStream;
    begin
        PositivePayEntry."Exported File".CreateInStream(Stream);
        while not Stream.EOS do
            Stream.ReadText(TextLine);
        exit(TextLine);
    end;

    [Scope('OnPrem')]
    procedure PositivePayExport(InputAmount: Decimal; ExpectedAmount: Text[250]; TransformationRule: Code[20]; TextPaddingRequired: Boolean; PadCharacter: Text[1]; DataFormat: Text[100])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PositivePayEntry: Record "Positive Pay Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempDataExchLineDef: array[2] of Record "Data Exch. Line Def" temporary;
        DataExchColumnDef: Record "Data Exch. Column Def";
        SaveDataExchColumnDef: Record "Data Exch. Column Def";
        SaveDataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Stream: InStream;
        AmountStartPosNo: Integer;
        TextLine: Text;
        AmountStringText: Text;
        BankAccountNo: Code[20];
        DataExchDefCode: Code[20];
    begin
        Initialize();

        DataExchDefCode := FindPositivePayExportDataExchDef(DataExchLineDef."Line Type"::Detail);

        RemoveDataExchByType(DataExchDefCode, DataExchLineDef."Line Type"::Header, TempDataExchLineDef[1]);
        RemoveDataExchByType(DataExchDefCode, DataExchLineDef."Line Type"::Footer, TempDataExchLineDef[2]);

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchColumnDef.FindSet();
        repeat
            AmountStartPosNo += DataExchColumnDef.Length;
        until (DataExchColumnDef.Next() = 0) or (DataExchColumnDef."Data Type" = DataExchColumnDef."Data Type"::Decimal);
        AmountStartPosNo += 1;

        // Bank Export/Import Setup used Data Exchange Definition of type "Positive Pay Export"
        LibraryPaymentExport.CreateBankExportImportSetup(BankExportImportSetup, DataExchDefCode);
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::"Export-Positive Pay");
        BankExportImportSetup.Modify(true);

        SaveDataExchColumnDef := DataExchColumnDef;
        DataExchColumnDef."Text Padding Required" := TextPaddingRequired;
        DataExchColumnDef."Pad Character" := PadCharacter;
        DataExchColumnDef."Data Format" := DataFormat;
        DataExchColumnDef.Modify();
        DataExchFieldMapping.Get(DataExchColumnDef."Data Exch. Def Code", DataExchColumnDef."Data Exch. Line Def Code", DATABASE::"Positive Pay Detail", DataExchColumnDef."Column No.", 7);
        SaveDataExchFieldMapping := DataExchFieldMapping;
        DataExchFieldMapping."Transformation Rule" := TransformationRule;
        DataExchFieldMapping.Modify();

        // Bank Account to use the Bank Export/Import Code
        BankAccountNo := CreateBankAccount(BankExportImportSetup.Code);

        // Check Ledger Entry of Bank Account to export with amount with tens of millions
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bank Payment Type"::"Manual Check", '', BankAccountNo, InputAmount, '');

        // Export Positive Pay
        FilterCheckLedgerEntry(CheckLedgerEntry, BankAccountNo);
        ExpLauncherPosPay.PositivePayProcess(CheckLedgerEntry, false);

        // Exported file contain a line with amount of tens of millions
        GetPositivePayExportedFile(PositivePayEntry, BankAccountNo);
        PositivePayEntry."Exported File".CreateInStream(Stream);
        Stream.ReadText(TextLine);

        AmountStringText := CopyStr(TextLine, AmountStartPosNo, DataExchColumnDef.Length);
        Assert.AreEqual(ExpectedAmount, AmountStringText, AmountStringErr);

        // Tear-down
        DataExchLineDef := TempDataExchLineDef[2];
        DataExchLineDef.Insert();
        DataExchLineDef := TempDataExchLineDef[1];
        DataExchLineDef.Insert();

        DataExchFieldMapping.TransferFields(SaveDataExchFieldMapping, false);
        DataExchFieldMapping.Modify();

        DataExchColumnDef.TransferFields(SaveDataExchColumnDef, false);
        DataExchColumnDef.Modify();
    end;

    local procedure RemoveDataExchByType(DataExchDefCode: Code[20]; LineType: Option; var TempDataExchLineDef: Record "Data Exch. Line Def" temporary)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.SetRange("Line Type", LineType);
        DataExchLineDef.FindFirst();
        TempDataExchLineDef := DataExchLineDef;
        DataExchLineDef.Delete();
    end;

    local procedure VoidCheck(DocumentNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckManagement: Codeunit CheckManagement;
        ConfirmFinancialVoid: Page "Confirm Financial Void";
    begin
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();
        CheckManagement.FinancialVoidCheck(CheckLedgerEntry);
        ConfirmFinancialVoid.SetCheckLedgerEntry(CheckLedgerEntry);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VoidCheckPageHandler(var ConfirmFinancialVoid: Page "Confirm Financial Void"; var Response: Action)
    var
        VoidTypeVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(VoidTypeVariant);
        ConfirmFinancialVoid.InitializeRequest(WorkDate(), VoidTypeVariant);
        Response := ACTION::Yes
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
        exit;
    end;

    local procedure UpdateAccountingPeriodForNewFiscalYear(var AccountingPeriod: Record "Accounting Period"; NewFiscalYear: Boolean)
    begin
        AccountingPeriod.Validate("New Fiscal Year", NewFiscalYear);
        AccountingPeriod.Modify(true);
    end;
}

