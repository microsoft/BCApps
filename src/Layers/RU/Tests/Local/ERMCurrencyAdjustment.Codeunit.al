codeunit 144103 "ERM Currency Adjustment"
{
    // // [FEATURE] [Adjust Exchange Rates] [Dimensions]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IncorrectDimensionValueErr: Label '%1 has incorrect Dimension Value';
        GLEntryCountErr: Label 'Wrong G/L Entry number of records';
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';
        CurrentSaveValuesId: Integer;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesHandler,DimensionSelectChangeHandler,ExchRateAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure CurAdjIncDimensionForPositiveNegative()
    var
        DimensionValueY: Record "Dimension Value";
        DimensionValueZ: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        ExchRateAdjPostingDate: Date;
    begin
        // [SCENARIO 123183] Exchange Rate Adj assigns Dimension/Dimension Value from "Dimension for Negative" to G/L Entries
        Initialize();
        // [GIVEN] Dimension X with Dimension Values Y and Z
        CreateDimensionWithValues(DimensionValueY, DimensionValueZ);
        // [GIVEN] Currency A with exchange Rate R1 and Rate R2 (R1 < R2)
        CurrencyCode :=
          CreateCurrencyWithExchangeRates(
            WorkDate() + 1, 0D, true);
        // [GIVEN] Posted Gen. Journal Line with Currency and Rate R1
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreatePostGenJournalLine(
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo,
          CurrencyCode, WorkDate());
        // [WHEN] Adjust Exchange Rate, "Dimension For Positive" = X with value Y and "Dimension for Negative" = X with value Z.
        ExchRateAdjPostingDate := WorkDate() + 1;
        RunExchangeRateAdjWithSelectedDimensions(
          CurrencyCode, ExchRateAdjPostingDate, DimensionValueY, DimensionValueZ);
        // [THEN] Exchange Rate G/L Entries have Dimension X, Dim Value Z.
        VerifyGLEntriesDimension(ExchRateAdjPostingDate, VendorNo, DimensionValueZ);
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesHandler,DimensionSelectChangeHandler,ExchRateAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure CurAdjDecDimensionForPositiveNegative()
    var
        DimensionValueY: Record "Dimension Value";
        DimensionValueZ: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        ExchRateAdjPostingDate: Date;
    begin
        // [SCENARIO 123183] Exchange Rate Adj assigns Dimension/Dimension Value from "Dimension for Positive" to G/L Entries
        Initialize();
        // [GIVEN] Dimension X with Dimension Values Y and Z
        CreateDimensionWithValues(DimensionValueY, DimensionValueZ);
        // [GIVEN] Currency A with exchange Rate R1 and Rate R2 (R1 > R2)
        CurrencyCode :=
          CreateCurrencyWithExchangeRates(
            WorkDate() + 1, 0D, false);
        // [GIVEN] Posted Gen. Journal Line with Currency and Rate R1
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreatePostGenJournalLine(
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo,
          CurrencyCode, WorkDate());
        // [WHEN] Adjust Exchange Rate, "Dimension For Positive" = X with value Y and "Dimension for Negative" = X with value Z.
        ExchRateAdjPostingDate := WorkDate() + 1;
        RunExchangeRateAdjWithSelectedDimensions(
          CurrencyCode, ExchRateAdjPostingDate, DimensionValueY, DimensionValueZ);
        // [THEN] Exchange Rate G/L Entries have Dimension X, Dim Value Y
        VerifyGLEntriesDimension(ExchRateAdjPostingDate, VendorNo, DimensionValueY);
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesHandler,DimensionSelectChangeHandler,ExchRateAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure CurAdjIndDecDimensionForPositiveNegative()
    var
        DimensionValueY: Record "Dimension Value";
        DimensionValueZ: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        VendorANo: Code[20];
        VendorBNo: Code[20];
        ExchRateAdjPostingDate: Date;
    begin
        // [SCENARIO 123183] Exchange Rate Adj assigns Dimension/Dimension Value from "Dimension for Positive/Negative" to G/L Entries
        Initialize();
        // [GIVEN] Dimension X with Dimension Values Y and Z
        CreateDimensionWithValues(DimensionValueY, DimensionValueZ);
        // [GIVEN] Currency with exchange rates (R1 > R3 < R2)
        CurrencyCode :=
          CreateCurrencyWithExchangeRates(
            WorkDate() + 1, WorkDate() + 2, true);
        // [GIVEN] Posted Gen. Journal Line for Vendor A at Rate R1
        VendorANo := LibraryPurchase.CreateVendorNo();
        CreatePostGenJournalLine(
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorANo,
          CurrencyCode, WorkDate());
        // [GIVEN] Posted Gen. Journal Line for Vendor B at Rate R2
        VendorBNo := LibraryPurchase.CreateVendorNo();
        CreatePostGenJournalLine(
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorBNo,
          CurrencyCode, WorkDate() + 1);
        // [WHEN] Adjust Exchange Rate, "Dimension For Positive" = X with value Y and "Dimension for Negative" = X with value Z.
        ExchRateAdjPostingDate := WorkDate() + 2;
        RunExchangeRateAdjWithSelectedDimensions(
          CurrencyCode, ExchRateAdjPostingDate, DimensionValueY, DimensionValueZ);
        // [THEN] Exchange Rate G/L Entries for Vendor A have Dimension X = Y, Vendor B - Dimension X = Z.
        // VerifyGLEntriesDimension(ExchRateAdjPostingDate, VendorANo, DimensionValueZ);
        // VerifyGLEntriesDimension(ExchRateAdjPostingDate, VendorBNo, DimensionValueY);
    end;

    [Test]
    [HandlerFunctions('AdjExchRatesBankAccHandler,ExchRateAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccountExchRateAdjmt()
    var
        BankAccNo: Code[20];
        CurrencyCode: Code[10];
        DocNo: Code[20];
    begin
        // [SCENARIO 374814] Post FCY payment through the journal with balancing bank account and run Exchange Rate Adjustment
        Initialize();
        // [GIVEN] FCY
        CurrencyCode := CreateCurrencyWithExchangeRates(WorkDate() + 1, 0D, true);
        // [GIVEN] Bank Account with FCY
        BankAccNo := CreateBankAccountFCY(CurrencyCode);
        // [GIVEN] Posted FCY payment through Gen. Jnl. Line with balance Bank Account
        PostFCYPaymentWithBankBalAccount(CurrencyCode, BankAccNo);
        // [WHEN] Adjust Exchange Rates for Bank Account only
        RunBankAccountExchRateAdjmt(CurrencyCode, BankAccNo, WorkDate(), WorkDate() + 1, DocNo);
        // [THEN] Two adjustment G/L Entries for Bank Account created
        VerifyAdjustmentGLEntry(DocNo);
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesHandler,ExchRateAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure BankAdjustExchRate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
        CurrencyCode: Code[10];
        ExchRateAdjPostingDate: Date;
    begin
        // [SCENARIO 132200] GL entry is created on for Bank Account after running Adjust Exchange rate batch job. "Enable Russian Accounting" = TRUE
        Initialize();

        // [GIVEN] Currency A with exchange Rate R1 and Rate R2 (R1 < R2)
        CurrencyCode :=
          CreateCurrencyWithExchangeRates(WorkDate() + 1, 0D, true);
        // [GIVEN] Posted Gen. Journal Line with Bank Account, Currency and Rate R1.
        BankAccountNo := CreateBankAccount(CurrencyCode);
        CreatePostGenJournalLine(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"Bank Account",
          BankAccountNo, CurrencyCode, WorkDate());

        // [WHEN] Run Adjust Exchange Rate.
        ExchRateAdjPostingDate := WorkDate() + 1;
        RunExchangeRateAdjWithoutDimensions(CurrencyCode, ExchRateAdjPostingDate);

        // [THEN] Exchange Rate G/L Entries are created.
        VerifyGLEntry(ExchRateAdjPostingDate, BankAccountNo);
    end;

    local procedure Initialize()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryVariableStorage.Clear();
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;

    local procedure CreateBankAccountFCY(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateDimensionWithValues(var DimensionValue1: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value")
    var
        Dimension: Record Dimension;
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue1, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension.Code);
    end;

    local procedure CreateCurrencyWithExchangeRates(Date1: Date; Date2: Date; IncreaseExchangeRate: Boolean): Code[10]
    var
        Currency: Record Currency;
        ExchRateAmount: array[3] of Decimal;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        Currency.Validate("Unrealized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Unrealized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);

        ExchRateAmount[1] := LibraryRandom.RandIntInRange(10, 100);
        if IncreaseExchangeRate then
            ExchRateAmount[2] := LibraryRandom.RandIntInRange(ExchRateAmount[1], 200)
        else
            ExchRateAmount[2] := LibraryRandom.RandIntInRange(1, ExchRateAmount[1]);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), ExchRateAmount[1], ExchRateAmount[1]);
        LibraryERM.CreateExchangeRate(Currency.Code, Date1, ExchRateAmount[2], ExchRateAmount[2]);

        if Date2 <> 0D then begin
            ExchRateAmount[3] :=
              LibraryRandom.RandDecInDecimalRange(ExchRateAmount[1], ExchRateAmount[2] - 0.01, 2);
            LibraryERM.CreateExchangeRate(
              Currency.Code, Date2,
              ExchRateAmount[3], ExchRateAmount[3]);
        end;
        exit(Currency.Code);
    end;

    local procedure CreatePostGenJournalLine(DocType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          DocType, AccountType, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          LibraryRandom.RandIntInRange(100, 1000));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostFCYPaymentWithBankBalAccount(CurrencyCode: Code[10]; BankAccNo: Code[20])
    var
        Customer: Record Customer;
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Customer, Customer."No.", GenJnlLine."Bal. Account Type"::"Bank Account",
          BankAccNo, -LibraryRandom.RandIntInRange(100, 1000));
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
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

    local procedure EnqueueValuesForAdjustExchangeRate(CurrencyCode: Code[10]; EndingDate: Date; DimensionValue1: Record "Dimension Value"; DimensionValue2: Record "Dimension Value")
    begin
        LibraryVariableStorage.Enqueue(CurrencyCode);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(DimensionValue1."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue1.Code);
        LibraryVariableStorage.Enqueue(DimensionValue2."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue2.Code);
    end;

    local procedure RunExchangeRateAdjWithSelectedDimensions(CurrencyCode: Code[10]; EndingDate: Date; DimensionValue1: Record "Dimension Value"; DimensionValue2: Record "Dimension Value")
    begin
        EnqueueValuesForAdjustExchangeRate(CurrencyCode, EndingDate, DimensionValue1, DimensionValue2);
        Commit();
        REPORT.Run(REPORT::"Exch. Rate Adjustment");
    end;

    local procedure RunBankAccountExchRateAdjmt(CurrencyCode: Code[10]; BankAccountNo: Code[20]; StartingDate: Date; EndingDate: Date; var DocNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(CurrencyCode);
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        DocNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(DocNo);
        Commit();
        REPORT.Run(REPORT::"Exch. Rate Adjustment");
    end;

    local procedure RunExchangeRateAdjWithoutDimensions(CurrencyCode: Code[10]; EndingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(CurrencyCode);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Exch. Rate Adjustment");
    end;

    local procedure VerifyGLEntriesDimension(PostingDate: Date; SourceNo: Code[20]; DimensionValue: Record "Dimension Value")
    var
        GLEntry: Record "G/L Entry";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("Source No.", SourceNo);
        GLEntry.FindSet();
        repeat
            LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, GLEntry."Dimension Set ID");
            Assert.AreEqual(
              DimensionValue."Dimension Value ID", DimensionSetEntry."Dimension Value ID",
              StrSubstNo(IncorrectDimensionValueErr, GLEntry.TableCaption));
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyAdjustmentGLEntry(DocNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocNo);
        Assert.AreEqual(2, GLEntry.Count, GLEntryCountErr);
    end;

    local procedure VerifyGLEntry(PostingDate: Date; SourceNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("Source No.", SourceNo);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    var
        LibraryUtility: Codeunit "Library - Utility";
        CurrencyCode: Variant;
        EndingPostingDate: Variant;
        IgnoreDimensions: Boolean;
    begin
        CurrentSaveValuesId := REPORT::"Exch. Rate Adjustment";
        LibraryVariableStorage.Dequeue(CurrencyCode);
        LibraryVariableStorage.Dequeue(EndingPostingDate);
        IgnoreDimensions := LibraryVariableStorage.DequeueBoolean();
        ExchRateAdjustment.StartingDate.SetValue(WorkDate());
        ExchRateAdjustment.EndingDate.SetValue(EndingPostingDate);
        ExchRateAdjustment.PostingDateReq.SetValue(EndingPostingDate);
        ExchRateAdjustment.DocumentNo.SetValue(LibraryUtility.GenerateRandomText(5));
        ExchRateAdjustment.CurrencyFilter.SetFilter(Code, CurrencyCode);
        if not IgnoreDimensions then begin
            ExchRateAdjustment.DimForPositive.AssistEdit();
            ExchRateAdjustment.DimForNegative.AssistEdit();
        end;
        ExchRateAdjustment.PreviewPost.SetValue(false);
        ExchRateAdjustment.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjExchRatesBankAccHandler(var ExchRateAdjustment: TestRequestPage "Exch. Rate Adjustment")
    var
        EndingDate: Variant;
    begin
        CurrentSaveValuesId := REPORT::"Exch. Rate Adjustment";
        ExchRateAdjustment.CurrencyFilter.SetFilter(Code, LibraryVariableStorage.DequeueText());
        ExchRateAdjustment.BankAccountFilter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ExchRateAdjustment.StartingDate.SetValue(LibraryVariableStorage.DequeueDate());
        LibraryVariableStorage.Dequeue(EndingDate);
        ExchRateAdjustment.EndingDate.SetValue(EndingDate);
        ExchRateAdjustment.PostingDateReq.SetValue(EndingDate);
        ExchRateAdjustment.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        ExchRateAdjustment.AdjBankAcc.SetValue(true);
        ExchRateAdjustment.PreviewPost.SetValue(false);
        ExchRateAdjustment.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectChangeHandler(var DimensionSelectChange: TestPage "Dimension Selection-Change")
    var
        DimensionCode: Variant;
        DimensionValueCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionCode);
        LibraryVariableStorage.Dequeue(DimensionValueCode);
        DimensionSelectChange.FILTER.SetFilter(Code, DimensionCode);
        DimensionSelectChange.First();
        DimensionSelectChange."New Dimension Value Code".SetValue(DimensionValueCode);
        DimensionSelectChange.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExchRateAdjustedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;
}

