codeunit 144029 "Manual VAT Correction"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        UserIdErr: Label 'Incorrect User ID.';
        AmountIncorrectErr: Label 'Amount is not correct.';
        RowNoLinkErr: Label 'Row Nubmer is incorrect.';
        ManVATCorNoOfLineErr: Label 'There should be %1 records in Manual VAT correction table.';

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateIsMandatoryOnInsert()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.010] Mandatory 'Posting Date' (TC157002)

        // [GIVEN] Page Manual VAT Correction
        // [GIVEN] New record with Posting Date = <empty>; Amount = X;
        TempManualVATCorrection.Init();
        TempManualVATCorrection.Amount := 1;

        // [WHEN] Record is being inserted
        asserterror TempManualVATCorrection.Insert(true);

        // [THEN] Error message: 'Posting Date must have a value'
        Assert.ExpectedError('Posting Date must have a value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateIsMandatoryOnModify()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.010] Mandatory 'Posting Date' (TC157002)

        // [GIVEN] A record in Table Manual VAT Correction
        CreateManCorrLine(TempManualVATCorrection, LibraryRandom.RandDec(100, 2), WorkDate(), '');

        // [WHEN] Entering empty 'Posting Date'
        asserterror TempManualVATCorrection.Validate("Posting Date", 0D);

        // [THEN] Error message: 'Posting Date must have a value'
        Assert.ExpectedError('Posting Date must have a value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateIsUnique()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.011] Duplicate 'Posting Date' is not allowed (TC157003)

        // [GIVEN] Page Manual VAT Correction

        // [GIVEN] Inserted record A with Posting Date = X
        CreateManCorrLine(TempManualVATCorrection, LibraryRandom.RandDec(100, 2), WorkDate(), '');
        TempManualVATCorrection.Insert(true);

        // [GIVEN] New record B with Posting Date = X
        CreateManCorrLine(TempManualVATCorrection, LibraryRandom.RandDec(100, 2), WorkDate(), '');

        // [WHEN] Record B is being inserted
        asserterror TempManualVATCorrection.Insert(true);

        // [THEN] Error message: 'The record already exists'
        Assert.ExpectedError('already exists');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateDifferentLines()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
        VATStatementLine: Record "VAT Statement Line";
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.012] Duplicate 'Posting Date' is allowed on 2 different VAT Statement lines.

        CreateManCorrLine(TempManualVATCorrection, LibraryRandom.RandDec(100, 2), WorkDate(), '');
        TempManualVATCorrection.Insert(true);

        // [GIVEN] New record B with Posting Date = X related to VAT Statement Z.
        CreateManCorrLine(TempManualVATCorrection, LibraryRandom.RandDec(100, 2), WorkDate(), '');
        VATStatementLine.FindLast();
        TempManualVATCorrection.Validate("Statement Line No.", VATStatementLine."Line No.");

        // [WHEN] Record B is being inserted
        TempManualVATCorrection.Insert(true);

        // [THEN] There are 2 lines in the Manual VAT Correction Table
        Assert.AreEqual(TempManualVATCorrection.Count, 2, Format(ManVATCorNoOfLineErr, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountIsZeroOnInsert()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.013] Amount Zero is not allowed.

        // [GIVEN] New record with amount = 0
        TempManualVATCorrection.Init();
        TempManualVATCorrection."Posting Date" := WorkDate();

        // [WHEN] Record is being inserted
        asserterror TempManualVATCorrection.Insert(true);

        // [THEN] Error message: 'Amount must have a value.'
        Assert.ExpectedError('Amount must have a value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountIsZeroOnModify()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.013] Amount Zero is not allowed.

        // [GIVEN] Inserted record A with amount = 0
        CreateManCorrLine(TempManualVATCorrection, 1, WorkDate(), '');

        // [WHEN] Entering zero Amount
        asserterror TempManualVATCorrection.Validate(Amount, 0);

        // [THEN] Error message: 'Amount must have a value.'
        Assert.ExpectedError('Amount must have a value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserIdOnInsert()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.020] 'User ID' on insert

        // [GIVEN] Created new record
        CreateManCorrLine(TempManualVATCorrection, LibraryRandom.RandDec(100, 2), WorkDate(), '');

        // [WHEN] Record is inserted
        TempManualVATCorrection.Insert(true);

        // [THEN] 'User ID' = USERID
        Assert.AreEqual(TempManualVATCorrection."User ID", UpperCase(UserId), UserIdErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserIdOnModify()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.021] 'User ID' on modify

        // [GIVEN] Inserted record with 'User ID' = X (not equal to USERID)
        CreateManCorrLine(TempManualVATCorrection, LibraryRandom.RandDec(100, 2), WorkDate(), 'TestId');
        TempManualVATCorrection.Insert();

        // [WHEN] Record is modified
        TempManualVATCorrection.Validate(Amount, LibraryRandom.RandDec(100, 2));
        TempManualVATCorrection.Modify(true);

        // [THEN] 'User ID' = USERID
        Assert.AreEqual(TempManualVATCorrection."User ID", UpperCase(UserId), UserIdErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddCurrencyAmountCalculation()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
        SetAmount: Decimal;
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.030] 'Additional-Currency Amount' calculation (TC157004)

        // [GIVEN] Additional Reporting Currency is set on General Ledger Setup
        CreateAddnlReportingCurrency();
        // [GIVEN] Page Manual VAT Correction

        // [GIVEN] Inserted record with Amount=Y
        CreateManCorrLine(TempManualVATCorrection, 1, WorkDate(), '');
        TempManualVATCorrection.Insert();

        // [WHEN] Amount is changed to X
        SetAmount := LibraryRandom.RandDec(100, 2);
        TempManualVATCorrection.Validate(Amount, SetAmount);
        TempManualVATCorrection.Modify(true);

        // [THEN] 'Additional-Currency Amount' = X * ExchangeRate
        Assert.AreEqual(
          Round(TempManualVATCorrection."Additional-Currency Amount"),
          Round(GetExchangedAmount(WorkDate(), SetAmount)), AmountIncorrectErr);

        ClearAddnlReportingCurrency();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddCurrencyAmountIsNotEditable()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
        ManualVATCorrectionList: TestPage "Manual VAT Correction List";
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.035] 'Additional-Currency Amount' is not editable

        // [GIVEN] Inserted Manual VAT Correction record
        CreateManCorrLine(TempManualVATCorrection, LibraryRandom.RandDec(100, 2), WorkDate(), '');
        TempManualVATCorrection.Insert();

        // [WHEN] Open page Manual VAT Correction
        ManualVATCorrectionList.OpenEdit();
        ManualVATCorrectionList.First();

        // [THEN] 'Additional-Currency Amount' is not editable
        Assert.IsTrue(ManualVATCorrectionList.Amount.Editable(), 'Amount must be editable.');
        Assert.IsFalse(
          ManualVATCorrectionList."Additional-Currency Amount".Editable(),
          'Additional-Currency Amount must not be editable.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddCurrencyAmountWhenNoACY()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.031] 'Additional-Currency Amount' when ACY is not set

        // [GIVEN] Additional Reporting Currency is <empty> on General Ledger Setup
        ClearAddnlReportingCurrency();

        // [GIVEN] Page Manual VAT Correction

        // [GIVEN] Inserted record with Amount=Y
        CreateManCorrLine(TempManualVATCorrection, 1, WorkDate(), '');
        TempManualVATCorrection.Insert();

        // [WHEN] Amount is changed to X
        TempManualVATCorrection.Validate(Amount, LibraryRandom.RandDec(100, 2));
        TempManualVATCorrection.Modify(true);

        // [THEN] 'Additional-Currency Amount' = 0
        Assert.AreEqual(TempManualVATCorrection."Additional-Currency Amount", 0, AmountIncorrectErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RowNoIsLinkedToVATStmtLineRow()
    var
        TempManualVATCorrection: Record "Manual VAT Correction" temporary;
        VATStatementLine: Record "VAT Statement Line";
    begin
        // [FEATURE] MANVATCORR
        // [SCENARIO TAB.040] 'Row No.' shows related VAT Statement Line.'Row No.'

        // [GIVEN] Inserted record, related to VAT Stmt. Line 'Row No.' = X
        CreateManCorrLine(TempManualVATCorrection, LibraryRandom.RandDec(100, 2), WorkDate(), '');

        // [WHEN] VAT Stmt. Line 'Row No.' is changed to Y
        ChangeRowNoOnVATStmtLine(TempManualVATCorrection, VATStatementLine);

        // [THEN] 'Row No.' = Y
        TempManualVATCorrection.CalcFields("Row No.");
        Assert.AreEqual(TempManualVATCorrection."Row No.", VATStatementLine."Row No.", RowNoLinkErr);
    end;

    local procedure ChangeRowNoOnVATStmtLine(var ManualVATCorrection: Record "Manual VAT Correction"; var VATStatementLine: Record "VAT Statement Line")
    var
        RowNo: Code[10];
    begin
        RowNo := LinkToVATStatementLine(ManualVATCorrection);
        ManualVATCorrection.CalcFields("Row No.");
        ChangeVATStatRowNo(VATStatementLine, RowNo);
    end;

    local procedure ChangeVATStatRowNo(var VATStatementLine: Record "VAT Statement Line"; RowNo: Code[10]): Code[10]
    begin
        VATStatementLine.SetRange("Row No.", RowNo);
        VATStatementLine.FindFirst();
        VATStatementLine.Validate("Row No.", LibraryUtility.GenerateGUID());
        VATStatementLine.Modify(true);
        exit(VATStatementLine."Row No.");
    end;

    local procedure CreateManCorrLine(var ManualVATCorrection: Record "Manual VAT Correction"; AmountVal: Decimal; PostingDate: Date; UserId: Code[50])
    begin
        ManualVATCorrection.Init();
        ManualVATCorrection.Validate("Posting Date", PostingDate);
        ManualVATCorrection.Validate(Amount, AmountVal);
        if UserId <> '' then
            ManualVATCorrection."User ID" := UserId;
    end;

    local procedure CreateAddnlReportingCurrency(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CreateCurrencyAndExchangeRate();
        GeneralLedgerSetup.Modify(true);
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);

        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure ClearAddnlReportingCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := '';
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure GetExchangedAmount(PostingDate: Date; Amount: Decimal): Decimal
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
        AddCurrencyFactor: Decimal;
    begin
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then begin
            AddCurrencyFactor := CurrencyExchRate.ExchangeRate(PostingDate, GLSetup."Additional Reporting Currency");
            Currency.Get(GLSetup."Additional Reporting Currency");
            exit(AddCurrencyFactor * Amount);
        end;
    end;

    local procedure LinkToVATStatementLine(var ManualVATCorrection: Record "Manual VAT Correction"): Code[10]
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.FindLast();
        ManualVATCorrection.Validate("Statement Template Name", VATStatementLine."Statement Template Name");
        ManualVATCorrection.Validate("Statement Name", VATStatementLine."Statement Name");
        ManualVATCorrection.Validate("Statement Line No.", VATStatementLine."Line No.");
        exit(VATStatementLine."Row No.");
    end;
}

