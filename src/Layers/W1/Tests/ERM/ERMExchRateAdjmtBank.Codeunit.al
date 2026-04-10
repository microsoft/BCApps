codeunit 134882 "ERM Exch. Rate Adjmt. Bank"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Exchange Rate]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AmountErr: Label '%1 field must be %2 in %3 table for %4 field %5.';
        GLEntryAmountErr: Label '%1 must be %2 in %3.';
        PostingDate: Date;
        SetHandler: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure BankAdjustExchRateForHigher()
    begin
        // Check that after Modify Higher Exchange rate and run Adjust Exchange rate batch job GL entry created on for Bank Account.
        Initialize();
        AdjustExchRateForBank(LibraryRandom.RandInt(50));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAdjustExchRateForLower()
    begin
        // Check that after Modify Lower Exchange rate and run Adjust Exchange rate batch job GL entry created on for Bank Account.
        Initialize();
        AdjustExchRateForBank(-LibraryRandom.RandInt(50));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalWithBankAccount()
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
    begin
        // Verify program allows to create General journal line with a Balancing Account Type Bank with presetup Currency.

        // Setup: Create General Journal Line with Random value and update Bal. Account No.
        Initialize();
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Document Type"::" ", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccount(CreateCurrency()));
        GenJournalLine.Modify(true);
        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Amount on G/L Entry.
        FindGLEntry(GLEntry, GenJournalLine."Document No.", BankAccountPostingGroup."G/L Account No.", GLEntry."Document Type"::" ");
        Currency.Get(GenJournalLine."Currency Code");
        Assert.AreNearlyEqual(
          -GenJournalLine."Amount (LCY)", GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountErr, GLEntry.FieldCaption(Amount), GenJournalLine."Amount (LCY)", GLEntry.TableCaption(),
            GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAdjmtWithNegativeAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FirstStartingDate: Date;
        SecondStartingDate: Date;
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Check GL Entry after Run Adjust Exchange Rate Batch Job with multiple Currency Exchange Rate with Negative Amount on General Line.

        // Setup: Create Currency with three different exchange Rate and Starting Date. Custom 1 and 2 M is required for difference only 1 Month.
        Initialize();
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(FirstStartingDate, SecondStartingDate);

        // Create and Post General Line. Amount 1 is required.
        CreateAndModifyGeneralLine(GenJournalLine, -1, CurrencyCode, FirstStartingDate);
        Amount := LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', WorkDate());
        Amount := Amount - LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', FirstStartingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        RunAdjustExchRate(GenJournalLine."Currency Code", SecondStartingDate);

        // Verify: Verify GL Entry for Adjusted Negative Amount with Currency.
        VerifyGLEntryAmountAdjmtExchangeRate(GenJournalLine."Account No.", Amount, GenJournalLine."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAdjmtWithPositiveAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FirstStartingDate: Date;
        SecondStartingDate: Date;
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Check GL Entry after Run Adjust Exchange Rate Batch Job with multiple Currency Exchange Rate with Positive Amount on General Line.

        // Setup: Create Currency with different exchange Rate and Starting Date.
        Initialize();
        CurrencyCode := CreateCurrencyWithMultipleExchangeRate(FirstStartingDate, SecondStartingDate);

        // Create and Post General Line. Amount 1 is Required.
        CreateAndModifyGeneralLine(GenJournalLine, 1, CurrencyCode, FirstStartingDate);
        Amount := FindRelationalExchRateAmount(CurrencyCode, WorkDate(), SecondStartingDate);
        Amount := Amount + FindRelationalExchRateAmount(CurrencyCode, FirstStartingDate, SecondStartingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        RunAdjustExchRate(GenJournalLine."Currency Code", SecondStartingDate);

        // Verify: Verify GL Entry for Adjusted Postitive Amount with Currency.
        VerifyGLEntryAmountAdjmtExchangeRate(GenJournalLine."Account No.", Amount, CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAdjustExchRateForGainOrLoss()
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        FirstStartingDate: Date;
        CurrencyCode: Code[10];
        Amount: Decimal;
        Amount2: Decimal;
        ExchRateAmount: Decimal;
        GLEntryAmount2: Decimal;
        GLEntryAmount: Decimal;
    begin
        // Check GL Entry for Currency Gain/Loss after running Adjust Exchange Rate Batch Job with multiple Currency Exchange Rate.

        // Setup: Create Currency with different Exchange Rate and Starting Date. Taken Random value to set Exchange rate amount and next Date.
        Initialize();
        CurrencyCode := CreateCurrency();
        ExchRateAmount := LibraryRandom.RandDec(100, 2);
        FirstStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        DeleteExistingExchangeRates(CurrencyCode);
        CreateExchangeRateWithFixRelationalAmount(CurrencyCode, WorkDate(), ExchRateAmount);
        CreateExchangeRateWithFixRelationalAmount(CurrencyCode, FirstStartingDate, ExchRateAmount + LibraryRandom.RandDec(10, 2));

        // Create, modify and Post General Line with Random Amount.
        Currency.Get(CurrencyCode);
        Amount :=
          CreateModifyAndPostGeneralLine(
            GenJournalLine, CreateBankAccount(CurrencyCode), FirstStartingDate, LibraryRandom.RandDec(1000, 2));
        GLEntryAmount := CalculateGLEntryBaseAmount(Currency."Realized Gains Acc.", Amount);

        Amount2 :=
          CreateModifyAndPostGeneralLine(GenJournalLine, CreateBankAccount(CurrencyCode), FirstStartingDate, -GenJournalLine.Amount / 2);
        GLEntryAmount2 := CalculateGLEntryBaseAmount(Currency."Realized Losses Acc.", Amount2);

        // Exercise.
        RunAdjustExchRate(GenJournalLine."Currency Code", FirstStartingDate);

        // Verify: Verify GL Entry for Currency Gain/Loss.
        FindGLEntry(GLEntry, Currency.Code, Currency."Realized Gains Acc.", GLEntry."Document Type"::" ");
        Assert.AreNearlyEqual(
          -GLEntryAmount, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(GLEntryAmountErr, GLEntry.FieldCaption(Amount), -Amount, GLEntry.TableCaption()));
        FindGLEntry(GLEntry, Currency.Code, Currency."Realized Losses Acc.", GLEntry."Document Type"::" ");
        Assert.AreNearlyEqual(
          -GLEntryAmount2, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(GLEntryAmountErr, GLEntry.FieldCaption(Amount), -Amount2, GLEntry.TableCaption()));
    end;

    [Test]
    procedure BankAccountsDiffPostingGroupsGetSeparateRegisters()
    var
        BankAccount1: Record "Bank Account";
        BankAccount2: Record "Bank Account";
        BankAccountPostingGroup1: Record "Bank Account Posting Group";
        BankAccountPostingGroup2: Record "Bank Account Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] Two bank accounts with different posting groups get separate registers with non-zero amounts
        Initialize();

        // [GIVEN] Currency "C" with exchange rate
        CurrencyCode := CreateCurrency();

        // [GIVEN] Bank Account "BA1" with Bank Posting Group "BPG1" and currency "C"
        CreateBankAccountWithNewPostingGroup(BankAccount1, BankAccountPostingGroup1, CurrencyCode);

        // [GIVEN] Bank Account "BA2" with Bank Posting Group "BPG2" and currency "C"
        CreateBankAccountWithNewPostingGroup(BankAccount2, BankAccountPostingGroup2, CurrencyCode);

        // [GIVEN] Posted journal entries for "BA1" and "BA2"
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Bank Account",
            BankAccount1."No.", LibraryRandom.RandIntInRange(500, 1000));
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Bank Account",
            BankAccount2."No.", LibraryRandom.RandIntInRange(500, 1000));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exchange rate is changed
        ModifyExchangeRate(CurrencyCode, LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates
        RunAdjustExchRate(CurrencyCode, WorkDate());

        // [THEN] Two register entries exist for Bank Account with different posting groups
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::"Bank Account");
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        Assert.AreEqual(2, ExchRateAdjmtReg.Count(), 'Expected 2 bank registers for 2 posting groups.');

        // [THEN] Register for BPG1 has non-zero adjusted amount
        ExchRateAdjmtReg.SetRange("Posting Group", BankAccountPostingGroup1.Code);
        ExchRateAdjmtReg.FindFirst();
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Register for BPG1 must have non-zero amount.');

        // [THEN] Register for BPG2 has non-zero adjusted amount
        ExchRateAdjmtReg.SetRange("Posting Group", BankAccountPostingGroup2.Code);
        ExchRateAdjmtReg.FindFirst();
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjusted Amt. (LCY)", 'Register for BPG2 must have non-zero amount.');
    end;

    [Test]
    procedure BankRegisterAmtMatchesLinkedLedgerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] Bank register "Adjusted Amt. (LCY)" equals sum of linked ledger entry amounts
        Initialize();

        // [GIVEN] Bank account "BA" with posted journal entry and changed exchange rate
        CreateGenAndModifyExchRate(
            GenJournalLine, GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(CreateCurrency()),
            GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates
        RunAdjustExchRate(GenJournalLine."Currency Code", WorkDate());

        // [THEN] Register "Adjusted Amt. (LCY)" equals CalcSums of linked ledger entries "Adjustment Amount"
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::"Bank Account");
        ExchRateAdjmtReg.SetRange("Currency Code", GenJournalLine."Currency Code");
        ExchRateAdjmtReg.FindFirst();
        VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);
    end;

    [Test]
    procedure TwoBankAccountsSamePostingGroupSingleRegister()
    var
        BankAccount1: Record "Bank Account";
        BankAccount2: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626336] Two bank accounts with the same posting group produce one register with combined amount
        Initialize();

        // [GIVEN] Currency "C" with exchange rate
        CurrencyCode := CreateCurrency();

        // [GIVEN] Bank Account "BA1" with posting group "BPG" and currency "C"
        BankAccountPostingGroup.SetFilter("G/L Account No.", '<>''''');
        BankAccountPostingGroup.FindFirst();
        LibraryERM.CreateBankAccount(BankAccount1);
        BankAccount1.Validate("Currency Code", CurrencyCode);
        BankAccount1.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount1.Modify(true);

        // [GIVEN] Bank Account "BA2" with the same posting group "BPG" and currency "C"
        LibraryERM.CreateBankAccount(BankAccount2);
        BankAccount2.Validate("Currency Code", CurrencyCode);
        BankAccount2.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount2.Modify(true);

        // [GIVEN] Posted journal entries for "BA1" and "BA2"
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Bank Account",
            BankAccount1."No.", LibraryRandom.RandIntInRange(500, 1000));
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Bank Account",
            BankAccount2."No.", LibraryRandom.RandIntInRange(500, 1000));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Exchange rate is changed
        ModifyExchangeRate(CurrencyCode, LibraryRandom.RandInt(50));

        // [WHEN] Run Adjust Exchange Rates
        RunAdjustExchRate(CurrencyCode, WorkDate());

        // [THEN] One register entry exists since both bank accounts share the same posting group
        ExchRateAdjmtReg.SetRange("Account Type", ExchRateAdjmtReg."Account Type"::"Bank Account");
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        Assert.AreEqual(1, ExchRateAdjmtReg.Count(), 'Expected 1 bank register for same posting group.');

        // [THEN] Register amount matches linked ledger entries
        ExchRateAdjmtReg.FindFirst();
        VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Exch. Rate Adjmt. Bank");

        Clear(PostingDate);
        Clear(SetHandler);
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Exch. Rate Adjmt. Bank");

        LibraryApplicationArea.EnableFoundationSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Exch. Rate Adjmt. Bank");
    end;

    local procedure AdjustExchRateForBank(ExchRateAmt: Decimal)
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Setup: Modify Exchange Rate after Create and Post General Journal Line for Bank.
        CreateGenAndModifyExchRate(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(CreateCurrency()),
          GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2), ExchRateAmt);
        FindCurrencyExchRate(CurrencyExchangeRate, GenJournalLine."Currency Code");
        Amount := GenJournalLine.Amount * ExchRateAmt / CurrencyExchangeRate."Exchange Rate Amount";
        BankAccount.Get(GenJournalLine."Account No.");
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");

        // Exercise:  Run Adjust Exchange Rate batch job on Posted Entries.
        RunAdjustExchRate(GenJournalLine."Currency Code", WorkDate());

        // Verify: Verify G/L Entry for correct entry after made from running Adjust Exchange Rate Batch Job.
        VerifyGLEntry(
          GenJournalLine."Currency Code", GenJournalLine."Currency Code", Amount, BankAccountPostingGroup."G/L Account No.",
          GenJournalLine."Document Type"::" ");
    end;

    local procedure CreateAndModifyGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; CurrencyCode: Code[10]; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create General Line and Modify Posting Date in Second Line. Amount 1 is Required.
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(CurrencyCode), 1);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type", CreateBankAccount(CurrencyCode), Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateModifyAndPostGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20]; FirstStartingDate: Date; Amount: Decimal) AmountLCY: Decimal
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Document Type"::" ", Amount);
        GenJournalLine.Validate("Currency Code", BankAccount."Currency Code");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        AmountLCY := Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', WorkDate()));
        AmountLCY -= Round(LibraryERM.ConvertCurrency(GenJournalLine.Amount, GenJournalLine."Currency Code", '', FirstStartingDate));
    end;

    local procedure CreateCurrencyWithMultipleExchangeRate(var FirstStartingDate: Date; var SecondStartingDate: Date): Code[10]
    var
        Currency: Record Currency;
    begin
        // Create Currency with different starting date and Exchange Rate. Taken Random value to calculate Date.
        FirstStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        SecondStartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', FirstStartingDate);
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        CreateExchangeRate(Currency.Code, WorkDate());
        CreateExchangeRate(Currency.Code, FirstStartingDate);
        CreateExchangeRate(Currency.Code, SecondStartingDate);
        exit(Currency.Code);
    end;

    local procedure CreateExchangeRateWithFixRelationalAmount(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Take 1 to fix the Relational amounts for Exchange Rate.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateBankAccount(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccountPostingGroup.SetFilter("G/L Account No.", '<>''''');
        BankAccountPostingGroup.FindFirst();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Unrealized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Unrealized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10]; StartingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Take Random Value for Exchange Rate Fields.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" + LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate(
          "Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount" + LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Take Random Amount for Invoice on General Journal Line.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateGenAndModifyExchRate(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; ExchangeRateAmount: Decimal)
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountType, AccountNo, DocumentType, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ModifyExchangeRate(GenJournalLine."Currency Code", ExchangeRateAmount);
    end;

    local procedure DeleteExistingExchangeRates(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.DeleteAll(true);
    end;

    local procedure FindCurrencyExchRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindRelationalExchRateAmount(CurrencyCode: Code[10]; StartingDate: Date; StartingDate2: Date): Decimal
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Amount: Decimal;
    begin
        Currency.Get(CurrencyCode);
        CurrencyExchangeRate.Get(CurrencyCode, StartingDate);
        Amount := CurrencyExchangeRate."Relational Exch. Rate Amount";
        CurrencyExchangeRate.Get(CurrencyCode, StartingDate2);
        exit(CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" - Amount);
    end;

    local procedure ModifyExchangeRate(CurrencyCode: Code[10]; ExchRateAmt: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        FindCurrencyExchRate(CurrencyExchangeRate, CurrencyCode);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + ExchRateAmt);
        CurrencyExchangeRate.Validate(
          "Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" + ExchRateAmt);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure RunAdjustExchRate("Code": Code[10]; EndDate: Date)
    begin
        // Using Currency Code for Document No. parameter.
        LibraryERM.RunExchRateAdjustmentForDocNo(Code, Code, EndDate);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exist before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure VerifyGLEntryAmountAdjmtExchangeRate(BankAccountNo: Code[20]; Amount: Decimal; DocumentNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        GLEntryAmount: Decimal;
    begin
        BankAccount.Get(BankAccountNo);
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", BankAccountPostingGroup."G/L Account No.");
        GLEntry.FindSet();
        repeat
            GLEntryAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
        Currency.Get(DocumentNo);
        Assert.AreNearlyEqual(
          Amount, GLEntryAmount, Currency."Invoice Rounding Precision",
          StrSubstNo(GLEntryAmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntry(CurrencyCode: Code[10]; DocumentNo: Code[20]; Amount: Decimal; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, AccountNo, DocumentType);
        Currency.Get(CurrencyCode);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    local procedure CalculateGLEntryBaseAmount(GLAccountNo: Code[20]; Amount: Decimal): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
        VATAmount: Decimal;
    begin
        // function calculates VAT Base Amount based on VAT Posting Setup applied for input account
        GLAccount.Get(GLAccountNo);
        if VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group") then
            VATAmount :=
              Round(
                Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"), Currency."Amount Rounding Precision",
                Currency.VATRoundingDirection());
        exit(Round(Amount - VATAmount, Currency."Amount Rounding Precision"));
    end;

    local procedure CreateBankAccountWithNewPostingGroup(var BankAccount: Record "Bank Account"; var BankAccountPostingGroup: Record "Bank Account Posting Group"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccountPostingGroup.Validate("G/L Account No.", LibraryERM.CreateGLAccountNo());
        BankAccountPostingGroup.Modify(true);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
    end;

    local procedure VerifyRegisterAmtMatchesLedgerEntries(ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.")
    begin
        ExchRateAdjmtReg.CalcFields("Adjustment Amount");
        Assert.AreNotEqual(0, ExchRateAdjmtReg."Adjustment Amount", 'Register adjustment amount must be non-zero.');
        Assert.AreEqual(
            ExchRateAdjmtReg."Adjusted Amt. (LCY)", ExchRateAdjmtReg."Adjustment Amount",
            'Register Adjusted Amt. (LCY) must equal sum of linked ledger entry Adjustment Amount.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.PostingDate.SetValue(Format(PostingDate));
        PostApplication.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // To handle the message.
    end;
}
