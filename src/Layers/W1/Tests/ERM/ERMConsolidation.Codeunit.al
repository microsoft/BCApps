codeunit 134092 "ERM Consolidation"
{
    Permissions = TableData "G/L Entry" = imd;
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Consolidation]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        ERMConsolidation: Codeunit "ERM Consolidation";
        IsInitialized: Boolean;
        CurrentSaveValuesId: Integer;
        FileName: Text;
        GLEntryErrTagTok: Label 'ErrorText_Number__Control23';
        GLEntryDimensionErr: Label 'G/L Entry %1: The %2 must be %3 for %4 %5 for %6 %7. Currently it''s %8.', Comment = '%2 = "Dimension value code" caption, %3 = expected "Dimension value code" value, %4 = "Dimension code" caption, %5 = "Dimension Code" value, %6 = Table caption (Vendor), %7 = Table value (XYZ), %8 = current "Dimension value code" value';
        ExpectedTextNotFoundErr: Label 'Expected text line %1 not found in exported file', Comment = '%1 - text';
        DimensionTextLineTok: Label '%1,"%2",%3', Comment = '%1 and %3 - numbers, %2 - text value';
        TransactionLineTok: Label '2,"%1","%2",%3,"%4",%5,%6,%7,%8,%9', Comment = '%3, %5-%9 - numbers, %1,%4 - text value, %2 - date';
        GLAccountLineTok: Label '1,"%1","%2"', Comment = '%1, %2 - text value, %3 - number';
        DimensionValueLineTok: Label '7,"%1",%2,%3', Comment = '%1 text value, %2, %3 - number';
        LegalEntityIDLineTok: Label '4,"%1"', Comment = '%1  text value';
        StartingDateErr: Label '%1 must be %2 in %3', Comment = '%1 = Starting Date, %2 = WorkDate, %3 = Consolidate Wizard';

    [Test]
    [Scope('OnPrem')]
    procedure ConsolidateLocalDebitCreditGLAccounts()
    var
        DebitGLAcc: Record "G/L Account";
        CreditGLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
        TempGLEntry: Record "G/L Entry" temporary;
        DocNo: Code[20];
        Amount: Decimal;
        ExpectedDebitAmount: Decimal;
        ExpectedCreditAmount: Decimal;
    begin
        // [SCENARIO 372046] G/L Account with Debit/Credit Balance should be consolidated to Debit/Credit Consolidation Account

        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        // [GIVEN] G/L Account "X1" with Debit Balance = 100, "Cons. Debit Acc" = "A1", "Cons. Credit Acc." = "B1"
        ExpectedDebitAmount :=
          PostDebitCreditGenJnlLines(DebitGLAcc, TempGLEntry, Amount * LibraryRandom.RandIntInRange(3, 5), -Amount);
        // [GIVEN] G/L Account "X2" with Credit Balance = -100 "Cons. Debit Acc" = "A2", "Cons. Credit Acc." = "B2"
        ExpectedCreditAmount :=
          PostDebitCreditGenJnlLines(CreditGLAcc, TempGLEntry, Amount, -Amount * LibraryRandom.RandIntInRange(3, 5));

        // [WHEN] Run Consolidation with "Data Source" = "Local Currency"
        DocNo :=
          RunConsolidation(TempGLEntry, DebitGLAcc, CreditGLAcc, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "A1" and "Amount" = 100
        VerifyGLEntryAmount(DocNo, DebitGLAcc."Consol. Debit Acc.", ExpectedDebitAmount);
        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "B2" and "Amount" = -100
        VerifyGLEntryAmount(DocNo, CreditGLAcc."Consol. Credit Acc.", ExpectedCreditAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsolidateACYDebitCreditGLAccounts()
    var
        DebitGLAcc: Record "G/L Account";
        CreditGLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
        TempGLEntry: Record "G/L Entry" temporary;
        DocNo: Code[20];
        Amount: Decimal;
        ExpectedDebitAmount: Decimal;
        ExpectedCreditAmount: Decimal;
    begin
        // [FEATURE] [ACY]
        // [SCENARIO 372046] G/L Account with Debit/Credit Add. Currency Balance should be consolidated to Debit/Credit Consolidation Account

        Initialize();
        UpdateAddnlReportingCurrency(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, LibraryRandom.RandDec(100, 2)));
        Amount := LibraryRandom.RandDec(100, 2);
        // [GIVEN] G/L Account "X1" with Debit Balance = 100, "Cons. Debit Acc" = "A1", "Cons. Credit Acc." = "B1"
        ExpectedDebitAmount :=
          PostDebitCreditGenJnlLines(DebitGLAcc, TempGLEntry, Amount * LibraryRandom.RandIntInRange(3, 5), -Amount);
        // [GIVEN] G/L Account "X2" with Credit Balance = -100 "Cons. Debit Acc" = "A2", "Cons. Credit Acc." = "B2"
        ExpectedCreditAmount :=
          PostDebitCreditGenJnlLines(CreditGLAcc, TempGLEntry, Amount, -Amount * LibraryRandom.RandIntInRange(3, 5));

        // [WHEN] Run Consolidation with "Data Source" = "Additional Currency"
        DocNo := RunConsolidation(TempGLEntry, DebitGLAcc, CreditGLAcc, BusinessUnit."Data Source"::"Add. Rep. Curr. (ACY)");
        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "A1" and "Additional Currency Amount" = 100
        VerifyGLEntryAmountACY(DocNo, DebitGLAcc."Consol. Debit Acc.", ExpectedDebitAmount);
        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "B2" and "Additional Currency Amount" = -100
        VerifyGLEntryAmountACY(DocNo, CreditGLAcc."Consol. Credit Acc.", ExpectedCreditAmount);
    end;

    [Test]
    [HandlerFunctions('ConsolidationTestDatabaseReportHandler')]
    [Scope('OnPrem')]
    procedure PrintGLAccountInConsolidationTestDatabaseReport()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 372262] "G/L Account No." should be printed in "Consolidation - Test Database" report if related G/L Entry exists

        Initialize();
        // [GIVEN] G/L Account = "X" with Consolidation Setup and posted G/L Entry
        CreateGLAccountWithConsolidationSetup(GLAccount);
        InsertGLEntry(GLAccount."No.");

        // [WHEN] Run "Consolidation - Test Database" report
        LibraryVariableStorage.Enqueue('');
        RunConsolidationTestDatabase();

        // [THEN] G/L Account = "X" is printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(LibraryReportDataset.FindRow('G_L_Account__No__', GLAccount."No."));
    end;

    [Test]
    [HandlerFunctions('GLConsolidationEliminationsRPH')]
    [Scope('OnPrem')]
    procedure GLConsolidationEliminationsBooleanColumnType()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [Reports] [UT]
        // [SCENARIO 375924] "G/L Consolidation Eliminations" report dataset uses "0"/"1" for boolean columns
        Initialize();

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);

        // [WHEN] Run "G/L Consolidation Eliminations" report
        Commit();
        RunGLConsolidationEliminationsRep(GenJournalBatch);

        // [THEN] Report dataset contains "0"/"1" for boolean columns "FirstLine" and "FirstLine2"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('FirstLine2', '1');
    end;

    [Test]
    [HandlerFunctions('ConsolidationTestDatabaseReportHandler')]
    [Scope('OnPrem')]
    procedure PrintErrorAccountDimInConsolidationTestDatabaseReport()
    var
        GLAccount: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
        DefaultDimension: Record "Default Dimension";
        DimSetEntry: Record "Dimension Set Entry";
        DimSetID: Integer;
        GLEntryNo: Integer;
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 380422] "Consolidation - Test Database" report log error if wrong G/L Entry dimension value set.
        Initialize();

        // [GIVEN] G/L Account = "X" with Consolidation Setup
        CreateGLAccountWithConsolidationSetup(GLAccount);

        // [GIVEN] Business Unit "BU" with current company
        CreateBusinessUnit(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");

        // [GIVEN] Default Dimension with Dimension Code = "D1", Dimension value = "V1"
        // [GIVEN] "D1"."Value Posting" = "Value Posting"::"Same Code"
        // [GIVEN] Dimension Set entry "DS": "DS".Dimension Code = "D1", "DS".Dimension Value = "V2"
        // [GIVEN] Selected Dimension code for checking in report is "D1"
        CreateSelectedDim(DefaultDimension, DimSetID, GLAccount."No.");

        // [GIVEN] G/L Entry "GLE": "GLE"."G/L Account" = "X", "GLE".BusinessUnit = "BU", "GLE".Dimension Set = "DS"
        GLEntryNo := InsertGLEntryWithBusinessUnit(GLAccount."No.", BusinessUnit.Code, DimSetID);

        // [WHEN] Run "Consolidation - Test Database" report filtered on Business Unit "BU"
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Code");
        Commit();
        REPORT.Run(REPORT::"Consolidation - Test Database", true, false, BusinessUnit);

        // [THEN] Error "G/L Entry "GLE": Select Dimension Value Code "V1" for the Dimension Code "D1 for G/L Account "X" has been logged.
        LibraryDimension.FindDimensionSetEntry(DimSetEntry, DimSetID);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists(
          GLEntryErrTagTok,
          StrSubstNo(
            GLEntryDimensionErr, GLEntryNo, DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension."Dimension Value Code", DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code", GLAccount.TableCaption, GLAccount."No.", DimSetEntry."Dimension Value Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsolidateLocalDebitCreditGLAccountsTemporaryGLEntries()
    var
        DebitGLAcc: Record "G/L Account";
        CreditGLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
        TempGLEntry: Record "G/L Entry" temporary;
        DocNo: Code[20];
        Amount: Decimal;
        ExpectedDebitAmount: Decimal;
        ExpectedCreditAmount: Decimal;
    begin
        // [SCENARIO 273629] Consolidation Debit/Credit account is chosen based on amounts in generated temporary G/L Entries

        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] G/L Account "X1" with "Cons. Debit Acc" = "A1", "Cons. Credit Acc." = "B1"
        // [GIVEN] Temporary G/L Entry with "G/L Account No." = "X1", "Debit Amount" = 200
        // [GIVEN] Temporary G/L Entry with "G/L Account No." = "X1", "Credit Amount" = 100
        ExpectedDebitAmount :=
          PrepareTempDebitCreditGLEntries(DebitGLAcc, TempGLEntry, Amount * LibraryRandom.RandIntInRange(3, 5), Amount);

        // [GIVEN] G/L Account "X2" with "Cons. Debit Acc" = "A2", "Cons. Credit Acc." = "B2"
        // [GIVEN] Temporary G/L Entry with "G/L Account No." = "X2", "Debit Amount" = 100
        // [GIVEN] Temporary G/L Entry with "G/L Account No." = "X2", "Credit Amount" = 200
        ExpectedCreditAmount :=
          PrepareTempDebitCreditGLEntries(CreditGLAcc, TempGLEntry, Amount, Amount * LibraryRandom.RandIntInRange(3, 5));

        // [WHEN] Run Consolidation with "Data Source" = "Local Currency"
        DocNo :=
          RunConsolidation(TempGLEntry, DebitGLAcc, CreditGLAcc, BusinessUnit."Data Source"::"Local Curr. (LCY)");

        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "A1" and "Amount" = 100
        VerifyGLEntryAmount(DocNo, DebitGLAcc."Consol. Debit Acc.", ExpectedDebitAmount);
        // [THEN] Consolidation G/L Entry created with "G/L Account No." = "B2" and "Amount" = -100
        VerifyGLEntryAmount(DocNo, CreditGLAcc."Consol. Credit Acc.", ExpectedCreditAmount);
    end;

    [Test]
    [HandlerFunctions('ImportConsolidationFromDBReportHandler,ConfirmHandlerYes,ConsolidatedTrialBalanceReportHandler')]
    [Scope('OnPrem')]
    procedure ImportConsolidationfromBusinessUnitWithDates()
    var
        AccountingPeriod: Record "Accounting Period";
        BusinessUnit: Record "Business Unit";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 298236] Consolidation do not throw error, even if Business Unit's dates are not Fiscal Year dates of Business Unit's Company
        Initialize();

        // [GIVEN] No Accounting periods/Fiscal years setup
        AccountingPeriod.DeleteAll();

        // [GIVEN] Business Unit with Company set to current company
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Company Name", CompanyName);
        BusinessUnit.Validate("Starting Date", WorkDate());
        BusinessUnit.Validate("Ending Date", WorkDate() + 1);
        BusinessUnit.Modify(true);
        Commit();

        // [WHEN] Report "Import Consolidation from DB" is run
        REPORT.Run(REPORT::"Import Consolidation from DB", true, false, BusinessUnit);

        // [THEN] No errors is thrown
    end;

    [Test]
    [HandlerFunctions('GLConsolidationEliminationsRPH')]
    [Scope('OnPrem')]
    procedure GLConsolidationEliminationReportIncludesBalAccountInGenJournal()
    var
        GLAccount: Record "G/L Account";
        BalGLAccount: Record "G/L Account";
        TotalingGLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Reports]
        // [SCENARIO 322981] G/L Consolidation Elimination report includes balanced account amount on general journal line.
        Initialize();

        // [GIVEN] G/L Accounts "A", "B".
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(BalGLAccount);

        // [GIVEN] Totaling g/l account "T" with totaling formula "A"|"B".
        LibraryERM.CreateGLAccount(TotalingGLAccount);
        TotalingGLAccount.Totaling := StrSubstNo('%1|%2', GLAccount."No.", BalGLAccount."No.");
        TotalingGLAccount.Modify(true);

        // [GIVEN] Gen. journal line with account no. = "A" and bal. account no. = "B". Amount = "X".
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", BalGLAccount."No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Run "G/L Consolidation Eliminations" report.
        Commit();
        RunGLConsolidationEliminationsRep(GenJournalBatch);

        // [THEN] The amount for g/l account "A" in the report layout = "X".
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('GLAcc2No', GLAccount."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_GenJournalLine', GenJournalLine.Amount);

        // [THEN] The amount for balanced g/l account "B" in the report layout = -"X".
        // [THEN] The description of this entry is equal to the name of "B".
        LibraryReportDataset.SetRange('GLAcc2No', BalGLAccount."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Amount_GenJournalLine', -GenJournalLine.Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('Desc_GenJournalLine', BalGLAccount.Name);

        // [THEN] The amount for totaling g/l account "T" = 0.
        LibraryReportDataset.SetRange('No2__GLAccount', TotalingGLAccount."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('EliminationAmount', 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportConsolidationRequesPageHandler')]
    procedure ExportConsolidationFO_LegalEntityID()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        FileContent: BigText;
        PostingDate: Date;
        LegalEntityID: Code[4];
    begin
        // [FEATURE] [Export F&O]
        // [SCENARIO 341917] F&O file contains F&O legal entity ID
        Initialize();
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(ERMConsolidation);

        // [GIVEN] Post G/L entry for account X, Posting Date = 27.02.2020
        PostingDate := CalcDate('<1M>', WorkDate());
        ClearGLEntriesOnPostingDate(PostingDate);

        // [WHEN] Report "Export Consolidation" is being run for period 27.02.2020..27.02.2020 and LegalEntityID = "ABCD"
        LegalEntityID := LibraryRandom.RandText(4);
        RunExportConsolidation(PostingDate, PostingDate, LegalEntityID);

        // [THEN] Exported file contains section with dimension DIM1
        LibraryTextFileValidation.ReadTextFile(ERMConsolidation.GetFileName(), FileContent);
        VerifyFileContent(FileContent, StrSubstNo(LegalEntityIDLineTok, LegalEntityID));

        UnBindSubscription(ERMConsolidation);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportConsolidationRequesPageHandler')]
    procedure ExportConsolidationFO_Dimension()
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SelectedDimension: Record "Selected Dimension";
        TempGLEntry: Record "G/L Entry" temporary;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        FileContent: BigText;
        PostingDate: Date;
    begin
        // [FEATURE] [Export F&O]
        // [SCENARIO 341917] F&O file contains dimensions from exported entries
        Initialize();
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(ERMConsolidation);

        // [GIVEN] G/L Account = "X" with Consolidation Setup, dimension DIM1
        CreateGLAccountWithConsolidationSetup(GLAccount);

        CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryDimension.CreateSelectedDimension(
                  SelectedDimension, 3, REPORT::"Export Consolidation", '', DimensionValue."Dimension Code");

        // [GIVEN] Post G/L entry for account X, Posting Date = 27.02.2020
        PostingDate := CalcDate('<1M>', WorkDate());
        ClearGLEntriesOnPostingDate(PostingDate);
        PostGenJnlLine(TempGLEntry, GLAccount."No.", GLAccount."No.", LibraryRandom.RandDec(100, 2), PostingDate, false);

        // [WHEN] Report "Export Consolidation" is being run for period 27.02.2020..27.02.2020
        RunExportConsolidation(PostingDate, PostingDate, LibraryRandom.RandText(4));

        // [THEN] Exported file contains section with dimension DIM1
        Dimension.Get(DimensionValue."Dimension Code");
        LibraryTextFileValidation.ReadTextFile(ERMConsolidation.GetFileName(), FileContent);
        VerifyFileContent(FileContent, StrSubstNo(DimensionTextLineTok, 6, Dimension.Name, 1));

        SelectedDimension.Delete();
        UnBindSubscription(ERMConsolidation);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportConsolidationRequesPageHandler')]
    procedure ExportConsolidationFO_DimensionValues()
    var
        GLAccount: array[2] of Record "G/L Account";
        BalAccount: Record "G/L Account";
        DimensionValue: array[2] of Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SelectedDimension: Record "Selected Dimension";
        TempGLEntry: Record "G/L Entry" temporary;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        FileContent: BigText;
        PostingDate: Date;
        ExpectedDimensionValueLine: Text;
    begin
        // [FEATURE] [Export F&O]
        // [SCENARIO 341917] F&O file contains dimension values from exported entries
        Initialize();
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(ERMConsolidation);

        // [GIVEN] G/L Account = "X" with Consolidation Setup, dimension DIM1, DIMVALUE1
        CreateGLAccountWithConsolidationSetup(GLAccount[1]);
        CreateDimWithDimValue(DimensionValue[1]);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount[1]."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        // [GIVEN] G/L Account = "Y" with Consolidation Setup, dimension DIM2, DIMVALUE2
        CreateGLAccountWithConsolidationSetup(GLAccount[2]);
        CreateDimWithDimValue(DimensionValue[2]);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount[2]."No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);

        // [GIVEN] Post G/L entry for account X, Posting Date = 27.02.2020
        PostingDate := CalcDate('<1M>', WorkDate());
        ClearGLEntriesOnPostingDate(PostingDate);
        CreateGLAccountWithConsolidationSetup(BalAccount);
        PostGenJnlLine(TempGLEntry, GLAccount[1]."No.", BalAccount."No.", LibraryRandom.RandDec(100, 2), PostingDate, false);
        // [GIVEN] Post G/L entry for account Y, Posting Date = 28.02.2020
        PostGenJnlLine(TempGLEntry, GLAccount[2]."No.", BalAccount."No.", LibraryRandom.RandDec(100, 2), PostingDate + 1, false);

        // [WHEN] Report "Export Consolidation" is being run with selected dimensions DIM1 and DIM2 for period 27.02.2020..28.02.2020
        LibraryDimension.CreateSelectedDimension(
                  SelectedDimension, 3, REPORT::"Export Consolidation", '', DimensionValue[1]."Dimension Code");
        LibraryDimension.CreateSelectedDimension(
                  SelectedDimension, 3, REPORT::"Export Consolidation", '', DimensionValue[2]."Dimension Code");
        RunExportConsolidation(PostingDate, PostingDate + 1, LibraryRandom.RandText(4));

        // [THEN] Exported file contains line with dimension value DIMVALUE1 for entries 1 and 2
        LibraryTextFileValidation.ReadTextFile(ERMConsolidation.GetFileName(), FileContent);

        ExpectedDimensionValueLine := StrSubstNo(DimensionValueLineTok, DimensionValue[1]."Consolidation Code", 1, 1);
        VerifyFileContent(FileContent, ExpectedDimensionValueLine);
        ExpectedDimensionValueLine := StrSubstNo(DimensionValueLineTok, DimensionValue[1]."Consolidation Code", 1, 3);
        VerifyFileContent(FileContent, ExpectedDimensionValueLine);

        // [THEN] Exported file contains line with dimension value DIMVALUE2 for entries 3 and 4
        ExpectedDimensionValueLine := StrSubstNo(DimensionValueLineTok, DimensionValue[2]."Consolidation Code", 2, 2);
        VerifyFileContent(FileContent, ExpectedDimensionValueLine);
        ExpectedDimensionValueLine := StrSubstNo(DimensionValueLineTok, DimensionValue[2]."Consolidation Code", 2, 4);
        VerifyFileContent(FileContent, ExpectedDimensionValueLine);

        SelectedDimension.Delete();
        UnBindSubscription(ERMConsolidation);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportConsolidationRequesPageHandler')]
    procedure ExportConsolidationFO_GLEntries()
    var
        DebitGLAccount: Record "G/L Account";
        CreditGLAccount: Record "G/L Account";
        TempGLEntry: Record "G/L Entry" temporary;
        GLSetup: Record "General Ledger Setup";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        FileContent: BigText;
        PostingDate: Date;
        ExpectedTransactionLine: Text;
    begin
        // [FEATURE] [Export F&O]
        // [SCENARIO 341917] F&O file contains consolidated entries
        Initialize();
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(ERMConsolidation);

        GLSetup.Get();

        // [GIVEN] G/L Account = "X" with "Consol. Debit Acc." = "DX" and "Consol. Credit Acc."= "CX"
        CreateGLAccountWithConsolidationSetup(DebitGLAccount);
        // [GIVEN] G/L Account = "Y" with Consolidation Setup "Consol. Debit Acc."= "DY" and "Consol. Credit Acc."= "CY"
        CreateGLAccountWithConsolidationSetup(CreditGLAccount);
        // [GIVEN] Post G/L entry for account X, Posting Date = 27.02.2020, Amount = 100
        PostingDate := CalcDate('<1M>', WorkDate());
        ClearGLEntriesOnPostingDate(PostingDate);
        PostGenJnlLine(TempGLEntry, DebitGLAccount."No.", CreditGLAccount."No.", LibraryRandom.RandDec(100, 2), PostingDate, false);

        // [WHEN] Report "Export Consolidation" is being run for period 27.02.2020..27.02.2020
        RunExportConsolidation(PostingDate, PostingDate, LibraryRandom.RandText(4));
        LibraryTextFileValidation.ReadTextFile(ERMConsolidation.GetFileName(), FileContent);

        // [THEN] Exported file contains section with debit entry Account No. = "DX", Amount = 100
        ExpectedTransactionLine :=
            StrSubstNo(
                TransactionLineTok,
                DebitGLAccount."Consol. Debit Acc.",
                FormatDate(TempGLEntry."Posting Date"),
                1,
                GLSetup."LCY Code",
                0,
                0,
                FormatDecimal(TempGLEntry."Debit Amount"),
                FormatDecimal(0),
                1);
        VerifyFileContent(FileContent, ExpectedTransactionLine);

        // [THEN] Exported file contains section with credit entry Account No. = "CY", Amount = -100
        ExpectedTransactionLine :=
            StrSubstNo(
                TransactionLineTok,
                CreditGLAccount."Consol. Credit Acc.",
                FormatDate(TempGLEntry."Posting Date"),
                1,
                GLSetup."LCY Code",
                1,
                0,
                FormatDecimal(-TempGLEntry."Debit Amount"),
                FormatDecimal(0),
                2);
        VerifyFileContent(FileContent, ExpectedTransactionLine);

        UnBindSubscription(ERMConsolidation);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportConsolidationRequesPageHandler')]
    procedure ExportConsolidationFO_GLEntriesWithCorrection()
    var
        DebitGLAccount: Record "G/L Account";
        CreditGLAccount: Record "G/L Account";
        TempGLEntry: Record "G/L Entry" temporary;
        GLSetup: Record "General Ledger Setup";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        FileContent: BigText;
        PostingDate: Date;
        ExpectedTransactionLine: Text;
    begin
        // [FEATURE] [Export F&O]
        // [SCENARIO 341917] F&O file contains consolidated entries with negative debit amount and positive credit amount
        Initialize();
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(ERMConsolidation);

        GLSetup.Get();

        // [GIVEN] G/L Account = "X" with "Consol. Debit Acc." = "DX" and "Consol. Credit Acc."= "CX"
        CreateGLAccountWithConsolidationSetup(DebitGLAccount);
        // [GIVEN] G/L Account = "Y" with Consolidation Setup "Consol. Debit Acc."= "DY" and "Consol. Credit Acc."= "CY"
        CreateGLAccountWithConsolidationSetup(CreditGLAccount);
        // [GIVEN] Post G/L entry for account X, Posting Date = 27.02.2020, Amount = 100, Correction = true
        PostingDate := CalcDate('<1M>', WorkDate());
        ClearGLEntriesOnPostingDate(PostingDate);
        PostGenJnlLine(TempGLEntry, DebitGLAccount."No.", CreditGLAccount."No.", LibraryRandom.RandDec(100, 2), PostingDate, true);

        // [WHEN] Report "Export Consolidation" is being run for period 27.02.2020..27.02.2020
        RunExportConsolidation(PostingDate, PostingDate, LibraryRandom.RandText(4));
        LibraryTextFileValidation.ReadTextFile(ERMConsolidation.GetFileName(), FileContent);

        // [THEN] Exported file contains section with credit entry Account No. = "CX", Amount = 100, sign = 1
        ExpectedTransactionLine :=
            StrSubstNo(
                TransactionLineTok,
                DebitGLAccount."Consol. Credit Acc.",
                FormatDate(TempGLEntry."Posting Date"),
                1,
                GLSetup."LCY Code",
                1,
                0,
                FormatDecimal(-TempGLEntry."Credit Amount"),
                FormatDecimal(0),
                1);
        VerifyFileContent(FileContent, ExpectedTransactionLine);

        // [THEN] Exported file contains section with credit entry Account No. = "DY", Amount = -100, sign = 0
        ExpectedTransactionLine :=
            StrSubstNo(
                TransactionLineTok,
                CreditGLAccount."Consol. Debit Acc.",
                FormatDate(TempGLEntry."Posting Date"),
                1,
                GLSetup."LCY Code",
                0,
                0,
                FormatDecimal(TempGLEntry."Credit Amount"),
                FormatDecimal(0),
                2);

        UnBindSubscription(ERMConsolidation);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ExportConsolidationRequesPageHandler')]
    procedure ExportConsolidationFO_GLAccounts()
    var
        DebitGLAccount: Record "G/L Account";
        CreditGLAccount: Record "G/L Account";
        GLAccount: Record "G/L Account";
        TempGLEntry: Record "G/L Entry" temporary;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        FileContent: BigText;
        PostingDate: Date;
        ExpectedGLAccountLine: Text;
    begin
        // [FEATURE] [Export F&O]
        // [SCENARIO 341917] F&O file contains G/L accounts used in exported transactions
        Initialize();
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        BindSubscription(ERMConsolidation);

        // [GIVEN] G/L Account = "X" with "Consol. Debit Acc." = "DX" and "Consol. Credit Acc."= "CX"
        CreateGLAccountWithConsolidationSetup(DebitGLAccount);
        // [GIVEN] G/L Account = "Y" with Consolidation Setup "Consol. Debit Acc."= "DY" and "Consol. Credit Acc."= "CY"
        CreateGLAccountWithConsolidationSetup(CreditGLAccount);
        // [GIVEN] Post G/L entry for account X, Posting Date = 27.02.2020, Amount = 100
        PostingDate := CalcDate('<1M>', WorkDate());
        ClearGLEntriesOnPostingDate(PostingDate);
        PostGenJnlLine(TempGLEntry, DebitGLAccount."No.", CreditGLAccount."No.", LibraryRandom.RandDec(100, 2), PostingDate, false);

        // [WHEN] Report "Export Consolidation" is being run for period 27.02.2020..27.02.2020
        RunExportConsolidation(PostingDate, PostingDate, LibraryRandom.RandText(4));
        LibraryTextFileValidation.ReadTextFile(ERMConsolidation.GetFileName(), FileContent);

        // [THEN] Exported file contains section with used account "DX"
        GLAccount.Get(DebitGLAccount."Consol. Debit Acc.");
        ExpectedGLAccountLine := StrSubstNo(GLAccountLineTok, GLAccount."No.", DebitGLAccount.Name);
        VerifyFileContent(FileContent, ExpectedGLAccountLine);

        // [THEN] Exported file contains section with used account "CY"
        GLAccount.Get(CreditGLAccount."Consol. Credit Acc.");
        ExpectedGLAccountLine := StrSubstNo(GLAccountLineTok, GLAccount."No.", CreditGLAccount.Name);
        VerifyFileContent(FileContent, ExpectedGLAccountLine);

        UnBindSubscription(ERMConsolidation);
    end;

    [Test]
    procedure ConsolidationPercentDecimals()
    var
        BusinessUnit: Record "Business Unit";
        BusinessUnitCard: TestPage "Business Unit Card";
        ConsolidationPercent: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 374636] Value with 5 decimals can be set to "Consolidation %" field of Business Unit.
        Initialize();
        ConsolidationPercent := LibraryRandom.RandDecInRange(10, 90, 4) + LibraryRandom.RandIntInRange(1, 9) / Power(10, 5);    // last digit is not zero

        // [GIVEN] Business Unit. Opened Business Unit card.
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnitCard.OpenEdit();
        BusinessUnitCard.Filter.SetFilter("Code", BusinessUnit.Code);

        // [WHEN] Set "Consolidation %" = 50.12345, i.e. a value with 5 decimals.
        BusinessUnitCard."Consolidation %".SetValue(ConsolidationPercent);
        BusinessUnitCard.Close();

        // [THEN] Value was set for Business Unit record.
        BusinessUnit.Get(BusinessUnit.Code);
        Assert.AreEqual(ConsolidationPercent, BusinessUnit."Consolidation %", '');
    end;

    [Test]
    procedure ConsolidationProcessesCanBeDeleted()
    var
        ConsolidationProcess: Record "Consolidation Process";
        BusUnitInConsProcess: Record "Bus. Unit In Cons. Process";
    begin
        BusUnitInConsProcess.DeleteAll();
        ConsolidationProcess.DeleteAll(true);
        // [SCENARIO 536561] Consolidation Processes are deleted with it's child "Business Units in Consolidation Process".
        // [GIVEN] Consolidation Processes with "child" "Business Units in Consolidation Process".
        ConsolidationProcess.Insert();
        BusUnitInConsProcess."Consolidation Process Id" := ConsolidationProcess."Id";
        BusUnitInConsProcess."Business Unit Code" := 'BU1';
        BusUnitInConsProcess.Insert();
        BusUnitInConsProcess."Consolidation Process Id" := ConsolidationProcess."Id";
        BusUnitInConsProcess."Business Unit Code" := 'BU2';
        BusUnitInConsProcess.Insert();
        ConsolidationProcess.Id += 1;
        ConsolidationProcess.Insert();
        BusUnitInConsProcess."Consolidation Process Id" := ConsolidationProcess."Id";
        BusUnitInConsProcess."Business Unit Code" := 'BU1';
        BusUnitInConsProcess.Insert();
        BusUnitInConsProcess."Consolidation Process Id" := ConsolidationProcess."Id";
        BusUnitInConsProcess."Business Unit Code" := 'BU2';
        BusUnitInConsProcess.Insert();
        // [WHEN] Deleting the Consolidation Process.
        ConsolidationProcess.DeleteAll(true);
        // [THEN] It also deletes the child "Business Units in Consolidation Process".
        Assert.AreEqual(0, BusUnitInConsProcess.Count(), 'Business Units in Consolidation Process should be deleted.');
        Assert.AreEqual(0, ConsolidationProcess.Count(), 'Consolidation Processes should be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingDateAndEndingDateCanBeChangedInConsolidateWizardWithoutErr()
    var
        BusinessUnit: Record "Business Unit";
        CompanyInformation: Record "Company Information";
        ConsolidateWizard: TestPage "Consolidate Wizard";
    begin
        // [SCENARIO 550614] Starting Date and Ending Date in Consolidate Wizard can be changed without any error.
        Initialize();

        // [GIVEN] Find Company Information.
        CompanyInformation.Get();

        // [GIVEN] Create a Business Unit and Validate Company Name.
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Company Name", CompanyInformation.Name);
        BusinessUnit.Modify(true);

        // [GIVEN] Open Consolidate Wizard and set Starting Date, Ending Date and Document No.
        ConsolidateWizard.Trap();
        Page.Run(Page::"Consolidate Wizard");
        ConsolidateWizard.ActionNext.Invoke();
        ConsolidateWizard.StartingDate.SetValue('C' + Format(WorkDate()));
        ConsolidateWizard.EndingDate.SetValue('C' + Format(WorkDate()));
        ConsolidateWizard.DocumentNo.SetValue(LibraryRandom.RandText(4));

        // [WHEN] Change Starting Date.
        ConsolidateWizard.StartingDate.SetValue(WorkDate());

        // [THEN] Starting Date in Consolidate Wizard is equal to WorkDate.
        Assert.AreEqual(
            WorkDate(),
            ConsolidateWizard.StartingDate.AsDate(),
            StrSubstNo(
                StartingDateErr,
                ConsolidateWizard.StartingDate.Caption(),
                WorkDate(),
                ConsolidateWizard.Caption()));
    end;

    [Test]
    procedure ASingleDateCanBeSpecifiedInConsolidateWizardWithoutError()
    var
        ConsolidateWizard: TestPage "Consolidate Wizard";
    begin
        // [SCENARIO 556939] A single date can be specified in Consolidate Wizard without any error.
        Initialize();
        // [GIVEN] Someone opening the Consolidate Wizard.
        ConsolidateWizard.Trap();
        // [WHEN] They set a date in the Starting Date field and nothing in the Ending Date field.
        Page.Run(Page::"Consolidate Wizard");
        ConsolidateWizard.StartingDate.SetValue(Format(WorkDate()));
        // [THEN] They face no error can can proceed.
        ConsolidateWizard.Close();
    end;

    [Test]
    [HandlerFunctions('DimensionSelectionMultiplePageHandler')]
    [Scope('OnPrem')]
    procedure ConsolidationWizardClearsDimensionsOnSecondRun()
    var
        BusinessUnit: Record "Business Unit";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ConsolidateWizard: TestPage "Consolidate Wizard";
        DimensionCode: Code[20];
        StartingDate: Date;
        EndingDate: Date;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 578672] Dimensions to Transfer field should be cleared when opening Consolidate Wizard for the second time
        Initialize();
        CreateFiscalYear();

        // [GIVEN] Create a new dimension that can be selected
        LibraryDimension.CreateDimension(Dimension);
        DimensionCode := Dimension.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);

        // [GIVEN] Create and setup Business Unit
        CreateBusinessUnit(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        BusinessUnit.Consolidate := true;
        BusinessUnit."Starting Date" := CalcDate('<-1M>', CurrentDateTime().Date);
        BusinessUnit."Ending Date" := CalcDate('<+1M>', CurrentDateTime().Date);
        BusinessUnit.Modify(true);

        // [GIVEN] Setup consolidation parameters
        StartingDate := BusinessUnit."Starting Date";
        EndingDate := BusinessUnit."Ending Date";
        DocumentNo := LibraryUtility.GenerateGUID();

        // [WHEN] Open Consolidate Wizard first time and select dimensions
        ConsolidateWizard.OpenNew();
        ConsolidateWizard.StartingDate.SetValue(StartingDate);
        ConsolidateWizard.EndingDate.SetValue(EndingDate);
        ConsolidateWizard.DocumentNo.SetValue(DocumentNo);

        // [THEN] Select dimensions using AssistEdit
        LibraryVariableStorage.Enqueue(DimensionCode); // For dimension selection handler
        ConsolidateWizard.TransferedDimensions.AssistEdit();

        // [GIVEN] Navigate through wizard steps
        ConsolidateWizard.ActionNext.Invoke();
        ConsolidateWizard.ActionNext.Invoke();
        ConsolidateWizard.Close();

        // [WHEN] Open Consolidate Wizard second time
        ConsolidateWizard.OpenNew();

        // [THEN] Verify that Dimensions to Transfer field is cleared (empty)
        ConsolidateWizard.TransferedDimensions.AssertEquals('');
        ConsolidateWizard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        IsInitialized := true;
    end;

    local procedure CreateFiscalYear()
    var
        AccountingPeriod: Record "Accounting Period";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        AccountingPeriod.DeleteAll();
        WorkDate := DMY2Date(1, 1, 2025);
        LibraryFiscalYear.CreateFiscalYear();
    end;

    local procedure ClearGLEntriesOnPostingDate(PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Posting Date");
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.DeleteAll();
    end;

    local procedure CreateGLAccountWithConsolidationSetup(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Consol. Debit Acc.", LibraryERM.CreateGLAccountNo());
        GLAccount.Validate("Consol. Credit Acc.", LibraryERM.CreateGLAccountNo());
        GLAccount.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateBusinessUnit(var BusinessUnit: Record "Business Unit"; DataSource: Option)
    begin
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        BusinessUnit.Validate("Company Name", CompanyName);
        BusinessUnit.Validate("Residual Account", LibraryERM.CreateGLAccountNo());
        BusinessUnit.Validate("Data Source", DataSource);
        BusinessUnit.Modify(true);
    end;

    local procedure CreateDimWithDimValue(var DimensionValue: Record "Dimension Value")
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimensionValue."Consolidation Code" :=
            LibraryUtility.GenerateRandomCode20(DimensionValue.FieldNo("Consolidation Code"), Database::"Dimension Value");
        DimensionValue.Modify();
    end;

    local procedure CreateSelectedDim(var DefaultDimension: Record "Default Dimension"; var DimSetID: Integer; GLAccountCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        SelectedDimension: Record "Selected Dimension";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimension(DefaultDimension,
          DATABASE::"G/L Account", GLAccountCode, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify(true);
        LibraryDimension.CreateDimensionValue(DimensionValue, DefaultDimension."Dimension Code");
        Commit();
        DimSetID := LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code);
        SelectedDimension.Init();
        LibraryDimension.CreateSelectedDimension(SelectedDimension, 3,
          REPORT::"Consolidation - Test Database", '', DefaultDimension."Dimension Code");
        DimensionSelectionBuffer.Init();
        DimensionSelectionBuffer.Code := SelectedDimension."Dimension Code";
        DimensionSelectionBuffer.Selected := true;
        DimensionSelectionBuffer.Insert();
    end;

    local procedure FormatDate(DateToFormat: Date): Text
    begin
        exit(Format(DateToFormat, 0, '<Year4>/<Month,2>/<Day,2>'));
    end;

    local procedure FormatDecimal(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, 9));
    end;

    procedure GetFileName(): Text
    begin
        exit(FileName);
    end;

    local procedure InsertGLEntry(GLAccNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := GLAccNo;
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Insert();
        exit(GLEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure InsertGLEntryWithBusinessUnit(GLAccountNo: Code[20]; BusinessUnitCode: Code[20]; DimensionSetID: Integer): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Get(InsertGLEntry(GLAccountNo));
        GLEntry."Business Unit Code" := BusinessUnitCode;
        GLEntry."Dimension Set ID" := DimensionSetID;
        GLEntry.Modify();
        exit(GLEntry."Entry No.");
    end;

    local procedure UpdateAddnlReportingCurrency(AdditionalReportingCurrency: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure PostDebitCreditGenJnlLines(var GLAccount: Record "G/L Account"; var GLEntry: Record "G/L Entry"; DebitAmount: Decimal; CreditAmount: Decimal): Decimal
    begin
        CreateGLAccountWithConsolidationSetup(GLAccount);
        PostGenJnlLine(GLEntry, GLAccount."No.", DebitAmount);
        PostGenJnlLine(GLEntry, GLAccount."No.", CreditAmount);
        exit(DebitAmount + CreditAmount);
    end;

    local procedure PostGenJnlLine(var GLEntryBuffer: Record "G/L Entry"; GLAccNo: Code[20]; Amount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, "Gen. Journal Account Type"::"G/L Account", GenJnlLine."Account Type"::"G/L Account", GLAccNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        FindGLEntry(GLEntry, GenJnlLine."Account No.", GenJnlLine."Document No.");
        GLEntryBuffer := GLEntry;
        GLEntryBuffer.Insert();
    end;

    local procedure PostGenJnlLine(var GLEntryBuffer: Record "G/L Entry"; AccountNo: Code[20]; BalAccountNo: Code[20]; Amount: Decimal; PostingDate: Date; Correction: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          "Gen. Journal Document Type"::" ",
          "Gen. Journal Account Type"::"G/L Account",
          AccountNo,
          "Gen. Journal Account Type"::"G/L Account",
          BalAccountNo,
          Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);

        GenJournalLine.Validate(Correction, Correction);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindGLEntry(GLEntry, GenJournalLine."Account No.", GenJournalLine."Document No.");
        GLEntryBuffer := GLEntry;
        GLEntryBuffer.Insert();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; GLAccNo: Code[20]; DocNo: Code[20])
    begin
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.FindFirst();
    end;

    local procedure RunConsolidation(var TempGLEntry: Record "G/L Entry" temporary; DebitGLAcc: Record "G/L Account"; CreditGLAcc: Record "G/L Account"; DateSource: Option) DocNo: Code[20]
    var
        BusinessUnit: Record "Business Unit";
        Consolidate: Codeunit Consolidate;
    begin
        DocNo := LibraryUtility.GenerateGUID();
        Consolidate.SetDocNo(DocNo);
        Consolidate.InsertGLAccount(DebitGLAcc);
        Consolidate.InsertGLAccount(CreditGLAcc);
        TempGLEntry.FindSet();
        repeat
            Consolidate.InsertGLEntry(TempGLEntry);
        until TempGLEntry.Next() = 0;
        CreateBusinessUnit(BusinessUnit, DateSource);
        Consolidate.SetGlobals('', '', BusinessUnit."Company Name", '', '', '', 0, WorkDate(), WorkDate());
        Consolidate.Run(BusinessUnit);
    end;

    local procedure RunGLConsolidationEliminationsRep(GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        REPORT.Run(REPORT::"G/L Consolidation Eliminations", true, false);
    end;

    local procedure RunConsolidationTestDatabase()
    var
        BusinessUnit: Record "Business Unit";
    begin
        CreateBusinessUnit(BusinessUnit, BusinessUnit."Data Source"::"Local Curr. (LCY)");
        Commit();
        REPORT.Run(REPORT::"Consolidation - Test Database", true, false, BusinessUnit);
    end;

    local procedure RunExportConsolidation(StartDate: Date; EndDate: Date; LegalEntityID: Code[4])
    var
        ExportConsolidation: Report "Export Consolidation";
    begin
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        LibraryVariableStorage.Enqueue(LegalEntityID);
        Commit();
        // InitializeRequest to initialize selected dimensions description
        ExportConsolidation.InitializeRequest(2, '');
        ExportConsolidation.Run();
    end;

    local procedure VerifyGLEntryAmount(DocNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, GLAccNo, DocNo);
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyGLEntryAmountACY(DocNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, GLAccNo, DocNo);
        GLEntry.TestField("Additional-Currency Amount", ExpectedAmount);
    end;

    local procedure PrepareTempDebitCreditGLEntries(var GLAccount: Record "G/L Account"; var GLEntry: Record "G/L Entry"; DebitAmount: Decimal; CreditAmount: Decimal): Decimal
    begin
        CreateGLAccountWithConsolidationSetup(GLAccount);
        MockGLEntry(GLEntry, GLAccount."No.", DebitAmount, 0);
        MockGLEntry(GLEntry, GLAccount."No.", 0, CreditAmount);
        exit(DebitAmount - CreditAmount);
    end;

    local procedure MockGLEntry(var GLEntry: Record "G/L Entry"; GLAccNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    begin
        GLEntry.Init();
        GLEntry."Entry No." += 1;
        GLEntry."G/L Account No." := GLAccNo;
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Amount := DebitAmount - CreditAmount;
        GLEntry."Debit Amount" := DebitAmount;
        GLEntry."Credit Amount" := CreditAmount;
        GLEntry.Insert();
    end;

    local procedure VerifyFileContent(FileContent: BigText; ExpectedTextLine: Text)
    var
        TextPosition: Integer;
    begin
        TextPosition := FileContent.TextPos(ExpectedTextLine);
        Assert.IsTrue(TextPosition > 0, StrSubstNo(ExpectedTextNotFoundErr, ExpectedTextLine));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidationTestDatabaseReportHandler(var ConsolidationTestDatabase: TestRequestPage "Consolidation - Test Database")
    begin
        ConsolidationTestDatabase.StartingDate.SetValue(WorkDate());
        ConsolidationTestDatabase.EndingDate.SetValue(WorkDate());
        ConsolidationTestDatabase.CopyDimensions.SetValue(LibraryVariableStorage.DequeueText());
        ConsolidationTestDatabase.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConsolidatedTrialBalanceReportHandler(var ConsolidatedTrialBalance: TestRequestPage "Consolidated Trial Balance")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImportConsolidationFromDBReportHandler(var ImportConsolidationfromDB: TestRequestPage "Import Consolidation from DB")
    begin
        ImportConsolidationfromDB.StartingDate.SetValue(WorkDate());
        ImportConsolidationfromDB.EndingDate.SetValue(WorkDate() + 1);
        ImportConsolidationfromDB.DocumentNo.SetValue(LibraryRandom.RandInt(100));
        ImportConsolidationfromDB.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLConsolidationEliminationsRPH(var GLConsolidationEliminations: TestRequestPage "G/L Consolidation Eliminations")
    begin
        GLConsolidationEliminations.JournalTemplateName.SetValue(LibraryVariableStorage.DequeueText());
        GLConsolidationEliminations.JournalBatch.SetValue(LibraryVariableStorage.DequeueText());
        GLConsolidationEliminations.StartingDate.SetValue(WorkDate());
        GLConsolidationEliminations.EndingDate.SetValue(WorkDate());
        GLConsolidationEliminations.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportConsolidationRequesPageHandler(var ExportConsolidation: TestRequestPage "Export Consolidation")
    begin
        CurrentSaveValuesId := REPORT::"Export Consolidation";
        ExportConsolidation.StartDate.SetValue(LibraryVariableStorage.DequeueDate());
        ExportConsolidation.EndDate.SetValue(LibraryVariableStorage.DequeueDate());
        ExportConsolidation.ClientFileNameControl.SetValue('DummyFileName'); // not important
        ExportConsolidation.FileFormat.SetValue(2); // Version F&O
        ExportConsolidation."F&O Legal Entity ID".SetValue(LibraryVariableStorage.DequeueText());
        ExportConsolidation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectionMultiplePageHandler(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    var
        DimensionCode: Code[20];
    begin
        DimensionCode := LibraryVariableStorage.DequeueText();
        DimensionSelectionMultiple.FILTER.SetFilter(Code, DimensionCode);
        DimensionSelectionMultiple.Selected.SetValue(true);
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure SaveFileToDisk(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    var
        FileManagement: Codeunit "File Management";
        ServerTempFileName: Text;
    begin
        FileName := FromFileName;
        ServerTempFileName := FileManagement.ServerTempFileName('txt');
        FileManagement.CopyServerFile(FromFileName, ServerTempFileName, false);
        IsHandled := true;
    end;
}

