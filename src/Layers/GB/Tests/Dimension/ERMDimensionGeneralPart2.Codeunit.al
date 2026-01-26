codeunit 134480 "ERM Dimension General Part 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        DeleteDimensionError: Label 'Dimension code must not be exist.';
        DimensionSetEntryError: Label 'The %1 must exist.';
        RoundingFactorOption: Label 'None';
        CheckColIndexErr: Label 'Wrong checked column index.';
        StartPeriodErr: Label 'Start period wrong.';
        EndPeriodErr: Label 'End period wrong.';
        WrongGLEntryLinesErr: Label 'Wrong number of G/L Entry lines.';
        WrongValueAfterLookupErr: Label 'Wrong value in control after lookup.';
        WrongNumberOfAnalysisViewEntriesErr: Label 'Wrong number of Analysis View Entries.';
        PeriodTxt: Label 'Period';
        DimensionCategory: Option "Dimension 1","Dimension 2","Dimension 3","Dimension 4";
        ClosingDateOptions: Option Include,Exclude;
        ShowAmounts: Option "Actual Amounts","Budgeted Amounts",Variance,"Variance%","Index%",Amounts;
        LineDimOptionRef: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast";
        ColumnDimOptionRef: Option "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast";
        NoLineShouldBeFoundErr: Label 'No line should be found.';
        WrongCostAmountNonInvtblErr: Label 'Wrong "Item Analysis View Entry"."Cost Amount (Non-Invtbl.)"';
        SalesAmountNotMatchAnalysisReportMsg: Label 'Posted Sales Amount does not match corresponding cell value in Sales Analysis Report.';
        ExcelControlVisibilityErr: Label 'Wrong Excel control visibility';
        GLBudgetFilterControlId: Integer;
        CostBudgetFilterControlId: Integer;
        FormatStrTxt: Label '<Precision,%1><Standard Format,0>';
        FieldMustBeVisibleErr: Label 'Field must be visible.';
        FieldMustBeHiddenErr: Label 'Field must be hidden.';

    [Test]
    [Scope('OnPrem')]
    procedure DimensionWithExistingCode()
    var
        Dimension: Record Dimension;
        Dimension2: Record Dimension;
    begin
        // Test setup the dimension code with already exist code.

        // 1. Setup: Create a Dimension, find a dimension.
        Initialize();
        LibraryDimension.CreateDimension(Dimension2);
        LibraryDimension.FindDimension(Dimension);

        // 2. Exercise: Change the dimension with already exist dimension.
        asserterror Dimension2.Rename(Dimension.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionWithGLAccountCaption()
    var
        GLAccount: Record "G/L Account";
    begin
        // Test setup the dimension code as GL Account.
        DimensionWithConflictName(GLAccount.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionBusinessUnitCaption()
    var
        BusinessUnit: Record "Business Unit";
    begin
        // Test setup the dimension code as Business Unit.
        DimensionWithConflictName(BusinessUnit.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionWithItemCaption()
    var
        Item: Record Item;
    begin
        // Test setup the dimension code as Item.
        DimensionWithConflictName(Item.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionWithLocationCaption()
    var
        Location: Record Location;
    begin
        // Test setup the dimension code as Location.
        DimensionWithConflictName(Location.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionWithPeriodCaption()
    begin
        // Test setup the dimension code as Period.
        DimensionWithConflictName(PeriodTxt);
    end;

    local procedure DimensionWithConflictName("Code": Code[20])
    var
        Dimension: Record Dimension;
    begin
        // 1. Setup: Create a Dimension.
        Initialize();
        Dimension.Init();

        // 2. Exercise: Change the dimension with code Period.
        asserterror Dimension.Validate(Code, Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameDimensionWithPostedEntry()
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DimensionSetID: Integer;
    begin
        // Test Rename the Dimension.

        // 1. Setup: Create Dimension and Dimension Value, create Customer, create General Journal Line with dimension,
        // post the created General Journal Line.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibrarySales.CreateCustomer(Customer);
        CreateJournalLineWithDimension(GenJournalLine, DimensionValue, Customer."No.", GenJournalLine."Account Type"::Customer);
        DimensionSetID := GenJournalLine."Dimension Set ID";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Rename the created dimension.
        Dimension.Rename(Customer."No.");

        // 3. Verify: Verify the renamed dimension.
        Assert.IsTrue(
          DimensionSetEntry.Get(DimensionSetID, Customer."No."), StrSubstNo(DimensionSetEntryError, DimensionSetEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameGlobalDimension()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        NewDimensionCode: Code[20];
        OldDimensionCode: Code[20];
    begin
        // Test Rename the Global Dimension with new code.

        // 1. Setup: Find the Global Dimension 1 code.
        Initialize();
        GeneralLedgerSetup.Get();
        Dimension.Get(GeneralLedgerSetup."Global Dimension 1 Code");
        OldDimensionCode := Dimension.Code;

        // 2. Exercise: Rename the Global Dimension 1 Code.
        NewDimensionCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Dimension.FieldNo(Code), DATABASE::Dimension),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Dimension, Dimension.FieldNo(Code)));
        Dimension.Rename(NewDimensionCode);

        // 3. Verify: Verify the Global Dimension 1 code in General Ledger Setup with new created code.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Global Dimension 1 Code", NewDimensionCode);

        // tear down
        Dimension.Rename(OldDimensionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameShortcutDimension()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        NewDimensionCode: Code[20];
        OldDimensionCode: Code[20];
    begin
        // Test Rename the Shortcut Dimension with new code.

        // 1. Setup: Find the Shortcut Dimension 3 code.
        Initialize();
        GeneralLedgerSetup.Get();
        Dimension.Get(GeneralLedgerSetup."Shortcut Dimension 3 Code");
        OldDimensionCode := Dimension.Code;

        // 2. Exercise: Rename the Shortcut Dimension 3 Code.
        NewDimensionCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Dimension.FieldNo(Code), DATABASE::Dimension),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Dimension, Dimension.FieldNo(Code)));
        Dimension.Rename(NewDimensionCode);

        // 3. Verify: Verify the Shortcut Dimension 3 code in General Ledger Setup with new created code.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Shortcut Dimension 3 Code", NewDimensionCode);

        // tear down
        Dimension.Rename(OldDimensionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankDimensionCode()
    var
        Dimension: Record Dimension;
    begin
        // Test Rename the Dimension with Blank.

        // 1. Setup: Create a new Dimension.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);

        // 2. Exercise: Rename the Dimension with blank.
        asserterror Dimension.Rename('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionWithGLBudgetName()
    var
        Dimension: Record Dimension;
        GLBudgetName: Record "G/L Budget Name";
        BudgetName: Code[10];
        BudgetDimension1Code: Code[20];
    begin
        // Test Rename Dimension attached on G/L Budget Name.

        // 1. Setup: Create Dimension, Create New G/L Budget Name, update Dimension as Budget Dimension 1 Code on it.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        BudgetName := CreateGLBudgetNameDimension(Dimension.Code);

        // 2. Exercise: Rename Dimension.
        BudgetDimension1Code :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Dimension.FieldNo(Code), DATABASE::Dimension),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Dimension, Dimension.FieldNo(Code)));
        Dimension.Rename(BudgetDimension1Code);

        // 3. Verify: Verify that the Dimension is renamed.
        GLBudgetName.Get(BudgetName);
        GLBudgetName.TestField("Budget Dimension 1 Code", BudgetDimension1Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionWithAnalysisView()
    var
        Dimension: Record Dimension;
        AnalysisView: Record "Analysis View";
        AnalysisViewCode: Code[10];
        Dimension1Code: Code[20];
    begin
        // Test error occurs on deleting Dimension attached on Analysis View.

        // 1. Setup: Create Dimension, Create New Analysis View, update Dimension as Dimension 1 Code on it.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        AnalysisViewCode := CreateAnalysisViewDimension(Dimension.Code);

        // 2. Exercise: Rename Dimension.
        Dimension1Code :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Dimension.FieldNo(Code), DATABASE::Dimension),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Dimension, Dimension.FieldNo(Code)));
        Dimension.Rename(Dimension1Code);

        // 3. Verify: Verify error occurs "Dimension is used" on Deleting Dimension.
        AnalysisView.Get(AnalysisViewCode);
        AnalysisView.TestField("Dimension 1 Code", Dimension1Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDimension()
    var
        Dimension: Record Dimension;
    begin
        // Test delete Dimension with no entries.

        // 1. Setup: Create a Dimension.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);

        // 2. Exercise: Delete the created Dimension.
        Dimension.Delete(true);

        // 3. Verify: Checks the Dimension is deleted.
        Assert.IsFalse(Dimension.Get(Dimension.Code), DeleteDimensionError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDimensionWithEntries()
    var
        Dimension: Record Dimension;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Test Delete Dimension with entries.

        // 1. Setup: Find the Shortcut Dimension 3 code.
        Initialize();
        GeneralLedgerSetup.Get();
        Dimension.Get(GeneralLedgerSetup."Shortcut Dimension 3 Code");

        // 2. Exercise: Delete the Dimension.
        asserterror Dimension.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDimensionOfPostedEntry()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
    begin
        // Test Delete Dimension with posted entry.

        // 1. Setup: Create a Dimension, Dimension Value, create a General Journal Line and post it.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateAndPostJournalLineWithDimension(DimensionValue, GLAccount."No.", WorkDate());

        // 2. Exercise: Delete the created dimension.
        asserterror Dimension.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteGlobalDimensionOfGLSetup()
    var
        Dimension: Record Dimension;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Test delete Dimension used as Global Dimension with no entries.

        // 1. Setup: Find a Dimension with Global Dimension 1 code.
        Initialize();
        GeneralLedgerSetup.Get();
        Dimension.Get(GeneralLedgerSetup."Global Dimension 1 Code");

        // 2. Exercise: Delete the created Dimension.
        asserterror Dimension.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockDimension()
    var
        Dimension: Record Dimension;
        Dimension2: Record Dimension;
    begin
        // Test the dimension with block.

        // 1. Setup: Create a dimension code.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);

        // 2. Exercise: Make the created dimension blocked.
        LibraryDimension.BlockDimension(Dimension);

        // 3. Verify: Verify the dimension is blocked.
        Dimension2.Get(Dimension.Code);
        Dimension2.TestField(Blocked, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalOfBlockDimension()
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test the post with block dimension.

        // 1. Setup: Create a dimension code with blocked,
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.BlockDimension(Dimension);
        LibrarySales.CreateCustomer(Customer);

        // 2. Exercise: Make General Journal Line with Blocked Dimension.
        asserterror CreateJournalLineWithDimension(GenJournalLine, DimensionValue, Customer."No.", GenJournalLine."Account Type"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAnalysisViewPostingTrue()
    var
        SalesLine: Record "Sales Line";
        ItemAnalysisView: Record "Item Analysis View";
    begin
        // Check Item Analysis View Entry for Posted Sales Invoice Amount with Global Dimension Values and Update Posting TRUE.

        // Create Item Analysis View with Update Posting TRUE and Sales Invoice.
        Initialize();
        CreateAnalysisAndSalesInvoice(ItemAnalysisView, SalesLine, true);

        // Verify: Verify Sales Amount Actual on Item Analysis View Entry with Sales Line Amount.
        VerifyItemAnalysisViewEntry(SalesLine, ItemAnalysisView.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAnalysisViewPostingFalse()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        SalesLine: Record "Sales Line";
        ItemAnalysisView: Record "Item Analysis View";
    begin
        // Check Item Analysis View Entry for Posted Sales Invoice Amount with Global Dimension Values and Update Posting FALSE.

        // Create Item Analysis View and Sales Invoice.
        Initialize();
        CreateAnalysisAndSalesInvoice(ItemAnalysisView, SalesLine, false);

        // Verify: Verify No. of Entries on Item Analysis View Entry.
        FindItemAnalysisViewEntry(ItemAnalysisViewEntry, SalesLine."Sell-to Customer No.", SalesLine."No.", ItemAnalysisView.Code);
        Assert.IsFalse(ItemAnalysisViewEntry.FindFirst(), 'Item Analysis View Entry must not Exist.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemAnalysisCompressionNone()
    var
        ItemAnalysisView: Record "Item Analysis View";
    begin
        // Check Item Analysis View Entry With NONE Date Compression.
        Initialize();
        ItemAnalysisCompression(ItemAnalysisView."Date Compression"::None);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAnalysisCompressionDay()
    var
        ItemAnalysisView: Record "Item Analysis View";
    begin
        // Check Item Analysis View Entry With Day Date Compression.
        Initialize();
        ItemAnalysisCompression(ItemAnalysisView."Date Compression"::Day);
    end;

    local procedure ItemAnalysisCompression(DateCompression: Option)
    var
        SalesLine: Record "Sales Line";
        ItemAnalysisView: Record "Item Analysis View";
        PostingDate: Date;
    begin
        // Create Item Analysis Entry and Create,Post Sales Invoice.
        PostingDate := CreateAnalysisAndSalesInvoice(ItemAnalysisView, SalesLine, true);

        // Run Item Analysis and Verify Posting Date on Item Analysis View Entry with Different Date Compression.
        RunAndVerifyItemAnalysis(ItemAnalysisView, SalesLine, DateCompression, PostingDate);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemAnalysisCompressionWeek()
    var
        SalesLine: Record "Sales Line";
        ItemAnalysisView: Record "Item Analysis View";
        PostingDate: Date;
    begin
        // Check Item Analysis View Entry With Week Date Compression.

        // Create Item Analysis Entry and Create,Post Sales Invoice.
        Initialize();
        PostingDate := CreateAnalysisAndSalesInvoice(ItemAnalysisView, SalesLine, true);

        // Run Item Analysis and Verify Posting Date on Item Analysis View Entry with Date Compression Week with
        // Customized Formula.
        RunAndVerifyItemAnalysis(
          ItemAnalysisView, SalesLine, ItemAnalysisView."Date Compression"::Week, CalcDate('<CW+1D-1W>', PostingDate));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemAnalysisCompressionMonth()
    var
        SalesLine: Record "Sales Line";
        ItemAnalysisView: Record "Item Analysis View";
        PostingDate: Date;
    begin
        // Check Item Analysis View Entry With Month Date Compression.

        // Create Item Analysis Entry and Create,Post Sales Invoice.
        Initialize();
        PostingDate := CreateAnalysisAndSalesInvoice(ItemAnalysisView, SalesLine, true);

        // Run Item Analysis and Verify Posting Date on Item Analysis View Entry with Date Compression Month with
        // Customized Formula.
        RunAndVerifyItemAnalysis(
          ItemAnalysisView, SalesLine, ItemAnalysisView."Date Compression"::Month, CalcDate('<CM+1D-1M>', PostingDate));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemAnlaysisCompressionQuarter()
    var
        SalesLine: Record "Sales Line";
        ItemAnalysisView: Record "Item Analysis View";
        PostingDate: Date;
    begin
        // Check Item Analysis View Entry With Quarter Date Compression.

        // Create Item Analysis Entry and Create,Post Sales Invoice.
        Initialize();
        PostingDate := CreateAnalysisAndSalesInvoice(ItemAnalysisView, SalesLine, true);

        // Run Item Analysis Code and Verify Posting Date on Item Analysis View Entry with Date Compression Quarter with
        // Customized Formula.
        RunAndVerifyItemAnalysis(
          ItemAnalysisView, SalesLine, ItemAnalysisView."Date Compression"::Quarter, CalcDate('<CQ+1D-1Q>', PostingDate));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemAnlaysisCompressionYear()
    var
        SalesLine: Record "Sales Line";
        ItemAnalysisView: Record "Item Analysis View";
        PostingDate: Date;
    begin
        // Check Item Analysis View Entry With Year Date Compression.

        // Create Item Analysis Entry and Create,Post Sales Invoice.
        Initialize();
        PostingDate := CreateAnalysisAndSalesInvoice(ItemAnalysisView, SalesLine, true);

        // Run Item Analysis and Verify Posting Date on Item Analysis View Entry with Date Compression Year with
        // Customized Formula.
        RunAndVerifyItemAnalysis(
          ItemAnalysisView, SalesLine, ItemAnalysisView."Date Compression"::Year, CalcDate('<CY+1D-1Y>', PostingDate));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemAnlaysisCompressionPeriod()
    var
        SalesLine: Record "Sales Line";
        ItemAnalysisView: Record "Item Analysis View";
        PostingDate: Date;
    begin
        // Check Item Analysis View Entry With Period Date Compression.

        // Create Item Analysis Entry and Create,Post Sales Invoice.
        Initialize();
        PostingDate := CreateAnalysisAndSalesInvoice(ItemAnalysisView, SalesLine, true);

        // Run Item Analysis and Verify Posting Date on Item Analysis View Entry with Date Compression Year with Calculation
        // of Accounting Period Entry.
        RunAndVerifyItemAnalysis(
          ItemAnalysisView, SalesLine, ItemAnalysisView."Date Compression"::Period, LibraryFiscalYear.GetAccountingPeriodDate(PostingDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAnlaysisLineTemplate()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        SalesLine: Record "Sales Line";
        ItemAnalysisView: Record "Item Analysis View";
    begin
        // Check Item Analysis View Entry after Posting Sales Invoice and Updation with Analysis Line Template.

        // Create Item Analysis and Create,Post Sales Invoice.
        Initialize();
        CreateAnalysisAndSalesInvoice(ItemAnalysisView, SalesLine, true);

        // Exercise: Update Analysis Line Template with Item Analysis View Code.
        AnalysisLineTemplate.FindFirst();
        AnalysisLineTemplate.Validate("Item Analysis View Code", ItemAnalysisView.Code);
        AnalysisLineTemplate.Modify(true);

        // Verify: Verify Sales Amount Actual fields on Item Analysis View Entry with Sales Line Amount.
        VerifyItemAnalysisViewEntry(SalesLine, AnalysisLineTemplate."Item Analysis View Code");
    end;

    [Test]
    [HandlerFunctions('GLEntriesDimOvervMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesDimOvervMatrixWithGenLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
        GLEntriesDimensionOverview: TestPage "G/L Entries Dimension Overview";
    begin
        // Check GL Entries Dimension Overview Matrix with Posted General Line.

        // Setup: Create General Line with Random Amount. Assign Value in Global Variable.
        Initialize();
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue(-GenJournalLine.Amount);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL Entries Dimension Overview Matrix Page through GLEntriesDimOvervMatrixPageHandler.
        GeneralLedgerEntries.OpenView();
        GeneralLedgerEntries.FILTER.SetFilter("Document No.", GenJournalLine."Document No.");
        GLEntriesDimensionOverview.Trap();
        GeneralLedgerEntries.GLDimensionOverview.Invoke();
        GLEntriesDimensionOverview.ShowMatrix.Invoke();
    end;

    [Test]
    [HandlerFunctions('GLBalancebyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure GLBalancebyDimMatrixRoundingFactorNone()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check GL Balance By Dimension Matrix with Rounding Factor None on Posted General Lines.

        // Setup: Create General Line with Random Amount.
        Initialize();
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(-GenJournalLine.Amount);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL Entries Dimension Overview Matrix Page through GLEntriesDimOvervMatrixPageHandler.
        VerifyGLBalancebyDimMatrix(GenJournalLine."Bal. Account No.", RoundingFactorOption);
    end;

    [Test]
    [HandlerFunctions('GLBalancebyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure GLBalancebyDimMatrixRoundingFactor1()
    begin
        // Check GL Balance By Dimension Matrix with Rounding Factor 1 with Rounding 1 on Posted General Lines.
        // Rounding Value is required as per Page.
        Initialize();
        OpenAndVerifyGLBalancebyDimMatrix(1, 1);
    end;

    [Test]
    [HandlerFunctions('GLBalancebyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure GLBalancebyDimMatrixRoundingFactor1000()
    begin
        // Check GL Balance By Dimension Matrix with Rounding Factor 1000 with Rounding 0.1 on Posted General Lines.
        // Rounding Value is required as per Page.
        Initialize();
        OpenAndVerifyGLBalancebyDimMatrix(1000, 0.1);
    end;

    [Test]
    [HandlerFunctions('GLBalancebyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure GLBalancebyDimMatrixRoundingFactor1000000()
    begin
        // Check GL Balance By Dimension Matrix with Rounding Factor 1000000 with Rounding 0.1 on Posted General Lines.
        // Rounding Value is required as per Page.
        Initialize();
        OpenAndVerifyGLBalancebyDimMatrix(1000000, 0.1);
    end;

    local procedure OpenAndVerifyGLBalancebyDimMatrix(RoundingFactor: Integer; Precision: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup.
        Initialize();
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(Round(-GenJournalLine.Amount / RoundingFactor, Precision));
        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL Entries Dimension Overview Matrix Page through GLEntriesDimOvervMatrixPageHandler.
        VerifyGLBalancebyDimMatrix(GenJournalLine."Bal. Account No.", Format(RoundingFactor));
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixRoundingFactorNone()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        // Check Analysis By Dimension Matrix with Rounding Factor None.

        // Setup: Create General Line and Analysis View with Dimension.
        Initialize();
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(-GenJournalLine.Amount);
        AnalysisViewCode := CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Analysis View Dimension Matrix for Rounding Factor None with AnalysisByDimensionMatrixPageHandler.
        OpenAnalysisByDimensionMatrix(AnalysisViewCode, false, false, RoundingFactorOption);
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixRoundingFactor1()
    begin
        // Check Analysis By Dimension Matrix with Rounding Factor 1 with Rounding Value 1.
        // Rounding Value is required as per Page.
        Initialize();
        OpenAndVerifyAnalysisByDimensionMatrix(1, 1);
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixRoundingFactor1000()
    begin
        // Check Analysis By Dimension Matrix with Rounding Factor 1000 with Rounding Value 0.1.
        // Rounding Value is required as per Page.
        Initialize();
        OpenAndVerifyAnalysisByDimensionMatrix(1000, 0.1);
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixRoundingFactor1000000()
    begin
        // Check Analysis By Dimension Matrix with Rounding Factor 1000000 with Rounding Value 0.1.
        // Rounding Value is required as per Page.
        Initialize();
        OpenAndVerifyAnalysisByDimensionMatrix(1000000, 0.1);
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrix_ByPeriod_TotalAmountCorrect()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        Initialize();
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(-GenJournalLine.Amount);

        AnalysisViewCode :=
          CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        OpenAnalysisByDimensionMatrixWithLineDimCode(
          AnalysisViewCode, false, false, RoundingFactorOption, PeriodTxt,
          ClosingDateOptions::Include, ShowAmounts::"Actual Amounts", '');
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrix_ByDimension1_TotalAmountCorrect()
    begin
        Initialize();
        OpenAndVerifyAnalysisByDimensionMatrixWithLineDimCode(DimensionCategory::"Dimension 1");
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrix_ByDimension2_TotalAmountCorrect()
    begin
        Initialize();
        OpenAndVerifyAnalysisByDimensionMatrixWithLineDimCode(DimensionCategory::"Dimension 2");
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrix_ByDimension3_TotalAmountCorrect()
    begin
        Initialize();
        OpenAndVerifyAnalysisByDimensionMatrixWithLineDimCode(DimensionCategory::"Dimension 3");
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrix_ByDimension4_TotalAmountCorrect()
    begin
        Initialize();
        OpenAndVerifyAnalysisByDimensionMatrixWithLineDimCode(DimensionCategory::"Dimension 4");
    end;

    local procedure OpenAndVerifyAnalysisByDimensionMatrix(RoundingFactor: Integer; Precision: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        // Setup: Create General Line and Analysis View with Dimension.
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(Round(-GenJournalLine.Amount / RoundingFactor, Precision));
        AnalysisViewCode := CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Analysis View Dimension Matrix for different Rounding Factor with AnalysisByDimensionMatrixPageHandler.
        OpenAnalysisByDimensionMatrix(AnalysisViewCode, false, false, Format(RoundingFactor));
    end;

    local procedure OpenAndVerifyAnalysisByDimensionMatrixWithLineDimCode(LineDimOption: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisView: Record "Analysis View";
        DimensionValue: Record "Dimension Value";
        AnalysisViewCode: Code[10];
        LineDimCode: Text[20];
    begin
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(-GenJournalLine.Amount);

        AnalysisViewCode :=
          CreateAnalysisViewWithCertainDimension(GenJournalLine."Bal. Account No.", LineDimOption);

        AnalysisView.Get(AnalysisViewCode);
        case LineDimOption of
            DimensionCategory::"Dimension 1":
                LineDimCode := AnalysisView."Dimension 1 Code";
            DimensionCategory::"Dimension 2":
                LineDimCode := AnalysisView."Dimension 2 Code";
            DimensionCategory::"Dimension 3":
                LineDimCode := AnalysisView."Dimension 3 Code";
            DimensionCategory::"Dimension 4":
                LineDimCode := AnalysisView."Dimension 4 Code";
        end;

        LibraryDimension.CreateDimensionValue(DimensionValue, LineDimCode);
        GenJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        OpenAnalysisByDimensionMatrixWithLineDimCode(
          AnalysisViewCode, false, false, RoundingFactorOption, LineDimCode,
          ClosingDateOptions::Include, ShowAmounts::"Actual Amounts", '');
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixWithOppositeSign()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        // Check Analysis By Dimension Matrix with Opposite Sign field TRUE.

        // Setup: Create General Line and Analysis View with Dimension.
        Initialize();
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(GenJournalLine.Amount);
        AnalysisViewCode := CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Analysis By Dimension Matrix Set Show Opposite Sign field TRUE with AnalysisByDimensionMatrixPageHandler.
        OpenAnalysisByDimensionMatrix(AnalysisViewCode, true, false, RoundingFactorOption);
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewMatrixGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Account Schedule Overview Matrix with Posted General Line.

        // Setup: Create and Post General Line. Assign Value in Global Variable.
        Initialize();
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Create Account Schedule Name and Verify Account Schedule Overview Matrix page through AccScheduleOverviewPageHandler.
        CreateAccountScheduleAndVerifyAccountScheduleOverviewMatrix(GenJournalLine."Account No.", GenJournalLine.Amount, false);
    end;

    [Test]
    [HandlerFunctions('AccScheduleOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewMatrixGLAccountAndCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Account Schedule Overview Matrix with Posted General Line and Use Additional Currency field TRUE.

        // Setup: Create and Post General Line. Assign Value in Global Variable.
        Initialize();
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Create Account Schedule Name and Verify Account Schedule Overview Matrix page through AccScheduleOverviewPageHandler.
        CreateAccountScheduleAndVerifyAccountScheduleOverviewMatrix(GenJournalLine."Account No.", 0, true);
    end;

    local procedure CreateAccountScheduleAndVerifyAccountScheduleOverviewMatrix(Totaling: Text[250]; ExpectedAmount: Decimal; UseAdditionalCurrency: Boolean)
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
        FinancialReports: TestPage "Financial Reports";
    begin
        // Exercise: Create Account Schedule Name and Line.
        LibraryERM.CreateAccScheduleName(AccScheduleName);
        LibraryERM.CreateAccScheduleLine(AccScheduleLine, AccScheduleName.Name);
        AccScheduleLine.Validate("Row No.", Format(LibraryRandom.RandInt(5)));
        AccScheduleLine.Validate(Totaling, Totaling);
        AccScheduleLine.Modify(true);
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        LibraryVariableStorage.Enqueue(ColumnLayoutName.Name);
        LibraryVariableStorage.Enqueue(AccScheduleLine."Row No.");
        LibraryVariableStorage.Enqueue(UseAdditionalCurrency);
        LibraryVariableStorage.Enqueue(ExpectedAmount);

        // Verify: Open Account Schedule Overview Matrix from Account Schedule Name through AccScheduleOverviewPageHandler.
        FinancialReports.OpenView();
        FinancialReports.FILTER.SetFilter(Name, AccScheduleName.Name);
        FinancialReports.Overview.Invoke();
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimMatrixWithAnalysisViewSalesList()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        ItemAnalysisView: Record "Item Analysis View";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
        Quantity: Decimal;
        Amount: Decimal;
    begin
        // Check Sales Analysis By Dimension Matrix by Sales Person Purchase Filter and Check Values for Posted Sales Order.

        // Setup: Create Dimension for Item Analysis View List with Sales Person Purchase.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Rename(DimensionValue.Code); // Required for Change Code as Dimension Value Code.
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", DimensionValue.Code, Dimension.Code, DimensionValue.Code);
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        ItemAnalysisView.Validate("Dimension 1 Code", Dimension.Code);
        ItemAnalysisView.Modify(true);

        // Exercise.
        CreateAndPostSalesDocument(Customer."No.", CreateItem(), SalespersonPurchaser.Code, Quantity, Amount);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Amount);

        // Verify: Open Analysis View List and Verify Sales Analysis By Dimension matrix Page through SalesAnalysisbyDimMatrixPageHandler.
        AnalysisViewListSales.OpenEdit();
        AnalysisViewListSales.FILTER.SetFilter(Code, ItemAnalysisView.Code);
        AnalysisViewListSales."&Update".Invoke();
        SalesAnalysisbyDimensions.Trap();
        AnalysisViewListSales.EditAnalysisView.Invoke();
        SalesAnalysisbyDimensions.LineDimCode.SetValue(Dimension.Code);
        SalesAnalysisbyDimensions.ShowMatrix_Process.Invoke();
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisByDimMatrixItemWiseMonthly()
    var
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        Dimension2: Record Dimension;
        ItemAnalysisView: Record "Item Analysis View";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
        LineDimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
        ItemNo: Code[20];
        Quantity: Decimal;
        Amount: Decimal;
    begin
        // Check Sales Analysis By Dimension Matrix monthly with Item and different Dimenssion and check values for posted Sales Orders.

        // Setup: Create Customer with dimenssion and create new Dimension as Salesperson/Purchaser and create new Sales Analysis View Card with monthly Date Compression.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code);
        ItemNo := CreateItem();

        LibraryDimension.CreateDimension(Dimension2);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension2.Code);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Rename(DimensionValue2.Code); // Required for Change Code as Dimension Value Code.

        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", DimensionValue2.Code, Dimension2.Code, DimensionValue2.Code);
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        ItemAnalysisView.Validate("Dimension 1 Code", Dimension.Code);
        ItemAnalysisView.Validate("Dimension 2 Code", Dimension2.Code);
        ItemAnalysisView.Validate("Date Compression", ItemAnalysisView."Date Compression"::Month);
        ItemAnalysisView.Modify(true);

        // Exercise: Create and Post Sales documents.
        CreateAndPostSalesDocument(Customer."No.", ItemNo, SalespersonPurchaser.Code, Quantity, Amount);
        CreateAndPostSalesDocument(Customer."No.", ItemNo, SalespersonPurchaser.Code, Quantity, Amount);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Amount);

        // Verify: Open Analysis View List and Verify Sales Analysis By Dimension matrix Page with item filter through SalesAnalysisbyDimMatrixPageHandler.
        AnalysisViewListSales.OpenEdit();
        AnalysisViewListSales.FILTER.SetFilter(Code, ItemAnalysisView.Code);
        AnalysisViewListSales."&Update".Invoke();
        SalesAnalysisbyDimensions.Trap();
        AnalysisViewListSales.EditAnalysisView.Invoke();
        SalesAnalysisbyDimensions.LineDimCode.SetValue(LineDimOption::Item);
        SalesAnalysisbyDimensions.ItemFilter.SetValue(ItemNo);
        SalesAnalysisbyDimensions.ShowMatrix_Process.Invoke();
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixMultiItemsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisByDimMatrixForMultiItems()
    var
        ItemAnalysisView: Record "Item Analysis View";
        Dimension: Record Dimension;
        ItemSetFilter: Text[50];
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENRIO 206788] Sales Anylysis by Dimensions must consider specified Dimension Code as columns

        // [GIVEN] Dimension "D" with dimension value "V"
        // [GIVEN] Item[1] .. Item[33] with dimension value "V"
        // [GIVEN] Posted sales invoice where Item[1].Quantity = 1, Item[1].Amount = 1000 and Item[33].Quantity = 133, Item[33].Amount = 1033
        // [GIVEN] "Sales Analysis by Dimensions" page has settings: "Show as lines" = "D" and "Show as columns" = "Item"
        // [GIVEN] "Sales Analysis by Dimensions" mstrix has 32 data item columns
        // [WHEN] Vew "Sales Analysis by Dimensions" matrix

        // [THEN] 1st set of Matrix shows "Total Amount" = 2033, "Total Quantity" = 134 and Amount = 1000 for Item[1] at 1st column
        // [THEN] 2nd set of Matrix shows "Total Amount" = 2033, "Total Quantity" = 134 and Amount = 1033 and Item[33] at 1st column
        Initialize();
        // Create and post a Sales Order as Ship and Invoice. Create Items more than count of columns. Open Analysis View List Sales page and invoke Update Item Analysis View.
        CreateAndPostMultiLineSalesOrder(Dimension, ItemSetFilter, PostingDate);
        // Create Item Analysis View.
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        ItemAnalysisView.Validate("Dimension 1 Code", Dimension.Code);
        ItemAnalysisView.Modify(true);

        // Verify: Quantity and Amount on Sales Analysis by Dim Matrix page.
        InvokeShowMatrixOnDifferentItemSets(Dimension, ItemAnalysisView.Code, ItemSetFilter, PostingDate);
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixPeriodFiltersPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisByDimMatrixPeriodFilters()
    var
        Customer: Record Customer;
        ItemAnalysisView: Record "Item Analysis View";
        SalesAnalysisByDimensions: TestPage "Sales Analysis by Dimensions";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
        ItemNo: Code[20];
        DimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        Amount: Decimal;
    begin
        // Check Sales Analysis By Dimension Matrix monthly with Item filter and check values for posted Sales Order in future period.

        // Setup: Create Customer and create new Item and create new Sales Analysis View Card with daily Date Compression.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        ItemNo := CreateItem();

        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        ItemAnalysisView.Validate("Date Compression", ItemAnalysisView."Date Compression"::Day);
        ItemAnalysisView.Modify(true);

        // Exercise: Create and Post Sales document
        Amount := CreateAndPostSalesDocumentAtDate(Customer."No.", ItemNo, CalcDate('<+32M>', WorkDate()));

        // Verify: Open Analysis View List and Verify Sales Analysis By Dimension matrix Page with item filter.
        AnalysisViewListSales.OpenEdit();
        AnalysisViewListSales.FILTER.SetFilter(Code, ItemAnalysisView.Code);
        AnalysisViewListSales."&Update".Invoke();
        SalesAnalysisByDimensions.Trap();
        AnalysisViewListSales.EditAnalysisView.Invoke();

        SetFiltersWithItemOnSalesAnalysisDimensionsPage(
          SalesAnalysisByDimensions, Format(DimOption::Item), Format(DimOption::Period), ItemNo);
        SalesAnalysisByDimensions.PeriodType.SetValue(PeriodType::Month);

        SaveValsForAnalysisMarix(0, 1, 1);
        SalesAnalysisByDimensions.ShowMatrix_Process.Invoke();

        SaveValsForAnalysisMarix(Amount, 1, 1);
        SalesAnalysisByDimensions.NextSet.Invoke();
        SalesAnalysisByDimensions.ShowMatrix_Process.Invoke();

        SaveValsForAnalysisMarix(0, 1, 1);
        SalesAnalysisByDimensions.PreviousSet.Invoke();
        SalesAnalysisByDimensions.ShowMatrix_Process.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAnalysisWithTotalingFilter()
    var
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Dimension: Record Dimension;
        ItemAnalysisView: Record "Item Analysis View";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        AnalysisReportMgt: Codeunit "Analysis Report Management";
        StandardDimValueCode: Code[20];
        TotalDimValueCode: Code[20];
        Quantity: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Sales Analysis View]
        // [SCENARIO 170902] The filter on "Totaling" field of Dimension Value with "Total" type should be applied to Item Analysis View Entries if this Dimension Value is selected on Totaling Dimension Filter in Analysis Line.
        Initialize();

        // [GIVEN] Dimension with a standard value "S" and Total value "T".
        // [GIVEN] Salesperson with default dimension = "S".
        CreateGroupOfDimensions(Dimension, StandardDimValueCode, TotalDimValueCode);
        CreateSalespersonWithDefaultDim(SalespersonPurchaser, Dimension.Code, StandardDimValueCode);

        // [GIVEN] Sales Analysis by Dimension.
        // [GIVEN] Totaling dimension filter in Analysis Line = "T".
        LibrarySales.CreateCustomer(Customer);
        CreateItemAnalysisView(ItemAnalysisView, Dimension.Code);
        CreateSalesAnalysisWithDimTotalingFilter(AnalysisLine, AnalysisColumn, ItemAnalysisView.Code, Customer."No.", TotalDimValueCode);

        // [GIVEN] Shipped and invoiced Sales Order with Salesperson and, respectively, document dimension value "S". Sales Amount = "X".
        CreateAndPostSalesDocument(Customer."No.", CreateItem(), SalespersonPurchaser.Code, Quantity, Amount);

        // [WHEN] Update Item Analysis View.
        CODEUNIT.Run(CODEUNIT::"Update Item Analysis View", ItemAnalysisView);

        // [THEN] Sales Amount in Sales Analysis Report is equal to "X".
        AnalysisLine.SetRange("Date Filter", WorkDate());
        Assert.AreEqual(
          Amount, AnalysisReportMgt.CalcCell(AnalysisLine, AnalysisColumn, false), SalesAmountNotMatchAnalysisReportMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAnalysisWithGlobalDimTotalingFilter()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        DimensionValue: Record "Dimension Value";
        AnalysisReportMgt: Codeunit "Analysis Report Management";
        CustomerNo: Code[20];
        TotalDimValueCode: Code[20];
        Quantity: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Sales Analysis View]
        // [SCENARIO 170902] The filter on "Totaling" field of Dimension Value with "Total" type should be applied to Value Entries if this Dimension Value is selected on Totaling Global Dimension Filter in Analysis Line.
        Initialize();

        // [GIVEN] Customer with Global Dimension 1 Code = "G".
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        CustomerNo := CreateCustomerWithDimension(DimensionValue.Code);

        // [GIVEN] Total value for Global Dimension 1 = "T", which includes "G".
        CreateTotalDimensionValue(GeneralLedgerSetup."Global Dimension 1 Code", TotalDimValueCode);

        // [GIVEN] Sales Analysis by Global Dimension 1.
        // [GIVEN] Totaling dimension filter in Analysis Line = "T".
        CreateSalesAnalysisWithDimTotalingFilter(AnalysisLine, AnalysisColumn, '', CustomerNo, TotalDimValueCode);

        // [WHEN] Ship and invoice Sales Document with Customer and, respectively, Global Dimension 1 value "G". Sales Amount = "X".
        CreateAndPostSalesDocument(CustomerNo, CreateItem(), '', Quantity, Amount);

        // [THEN] Sales Amount in Sales Analysis Report is equal to "X".
        AnalysisLine.SetRange("Date Filter", WorkDate());
        Assert.AreEqual(
          Amount, AnalysisReportMgt.CalcCell(AnalysisLine, AnalysisColumn, false), SalesAmountNotMatchAnalysisReportMsg);
    end;

    [Test]
    [HandlerFunctions('PurchAnalysisbyDimMatrixPeriodFiltersPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisByDimMatrixPeriodFilters()
    var
        Vendor: Record Vendor;
        ItemAnalysisView: Record "Item Analysis View";
        PurchAnalysisByDimensions: TestPage "Purch. Analysis by Dimensions";
        AnalysisViewListPurch: TestPage "Analysis View List Purchase";
        ItemNo: Code[20];
        DimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        Amount: Decimal;
    begin
        // Check Sales Analysis By Dimension Matrix monthly with Item filter and check values for posted Sales Order in future period.

        // Setup: Create Customer and create new Item and create new Sales Analysis View Card with daily Date Compression.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        ItemNo := CreateItem();

        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);
        ItemAnalysisView.Validate("Date Compression", ItemAnalysisView."Date Compression"::Day);
        ItemAnalysisView.Modify(true);

        // Exercise: Create and Post Sales document
        Amount := CreateAndPostPurchDocumentAtDate(Vendor."No.", ItemNo, CalcDate('<+32M>', WorkDate()));

        // Verify: Open Analysis View List and Verify Sales Analysis By Dimension matrix Page with item filter.
        AnalysisViewListPurch.OpenEdit();
        AnalysisViewListPurch.FILTER.SetFilter(Code, ItemAnalysisView.Code);
        AnalysisViewListPurch."&Update".Invoke();
        PurchAnalysisByDimensions.Trap();
        AnalysisViewListPurch.EditAnalysisView.Invoke();
        SetFiltersWithItemOnPurchAnalysisDimensionsPage(
          PurchAnalysisByDimensions, Format(DimOption::Item), Format(DimOption::Period), ItemNo);
        PurchAnalysisByDimensions.PeriodType.SetValue(PeriodType::Month);

        SaveValsForAnalysisMarix(0, 1, 1);
        PurchAnalysisByDimensions.ShowMatrix.Invoke();

        SaveValsForAnalysisMarix(Amount, 1, 1);
        PurchAnalysisByDimensions.NextSet.Invoke();
        PurchAnalysisByDimensions.ShowMatrix.Invoke();

        SaveValsForAnalysisMarix(0, 1, 1);
        PurchAnalysisByDimensions.PreviousSet.Invoke();
        PurchAnalysisByDimensions.ShowMatrix.Invoke();
    end;

    [Test]
    [HandlerFunctions('GLEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewEntryDrillDownToGLEntry()
    var
        Customer: Record Customer;
        AnalysisView: Record "Analysis View";
        AnalysisViewEntries: TestPage "Analysis View Entries";
        Quantity: Decimal;
        Amount: Decimal;
    begin
        // Check that Analysis View Entry drilldown shows correct G/L Entry if 'Date Compression' is 'None'.

        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Date Compression", AnalysisView."Date Compression"::None);
        AnalysisView.Modify(true);

        // Exercise.
        CreateAndPostSalesDocument(Customer."No.", CreateItem(), '', Quantity, Amount);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Amount);
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);

        // Verify.
        AnalysisViewEntries.OpenView();
        AnalysisViewEntries.FILTER.SetFilter("Analysis View Code", AnalysisView.Code);
        AnalysisViewEntries.Amount.Lookup();
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimensionsPageHandler')]
    [Scope('OnPrem')]
    procedure CheckColumnSetOnSalesAnalysisByDimension()
    var
        ItemAnalysisView: Record "Item Analysis View";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
    begin
        // Check Sales Analysis by Dimensions shows correct values in the RTC when changing the Dimension in the Show as Columns field.

        // Setup: Create Item Analysis View & Create Dimension.
        Initialize();
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        ItemAnalysisView.Validate("Dimension 2 Code", Dimension.Code);
        ItemAnalysisView.Modify(true);
        LibraryVariableStorage.Enqueue(Dimension.Code);
        LibraryVariableStorage.Enqueue(DimensionValue.Code);

        // Exercise: Open Sales Analysis by Dimension Page.
        AnalysisViewListSales.OpenEdit();
        AnalysisViewListSales.FILTER.SetFilter(Code, ItemAnalysisView.Code);
        AnalysisViewListSales.EditAnalysisView.Invoke();

        // Verify: Verification done in SalesAnalysisbyDimensionsPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckFindRecWithInternalDateFilter()
    var
        ItemAnalysisView: Record "Item Analysis View";
        DimCodeBuf: Record "Dimension Code Buffer";
        Item: Record Item;
        ItemAnalysisMgt: Codeunit "Item Analysis Management";
        DateFilter: Text[30];
        InternalDateFilter: Text[30];
        DimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        PeriodStart: Date;
        PeriodEnd: Date;
        PeriodInitialized: Boolean;
    begin
        // Check that 'FindRec' function in 'Item Analysis Management' returns right period in DimCodeBuf

        // Setup
        ItemAnalysisView.Init();
        PeriodInitialized := true;
        DimOption := DimOption::Period;
        PeriodType := PeriodType::Month;
        PeriodStart := CalcDate('<-CM>', WorkDate());
        PeriodEnd := CalcDate('<+1Y-1D>', PeriodStart);

        DateFilter := '';
        Item.SetRange("Date Filter", PeriodStart, PeriodEnd);
        InternalDateFilter := CopyStr(Item.GetFilter("Date Filter"), 1, MaxStrLen(InternalDateFilter));

        // Exercize
        ItemAnalysisMgt.FindRecord(
          ItemAnalysisView, "Item Analysis Dimension Type".FromInteger(DimOption), DimCodeBuf, '', '', '',
          "Analysis Period Type".FromInteger(PeriodType), DateFilter, PeriodInitialized, InternalDateFilter, '', '', '');

        // Verify
        Assert.AreEqual(PeriodStart, DimCodeBuf."Period Start", StartPeriodErr);
        Assert.AreEqual(CalcDate('<+1M-1D>', PeriodStart), DimCodeBuf."Period End", EndPeriodErr);
    end;

    [HandlerFunctions('GLBudgetNamesHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewWithGLBudgetFilter()
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Check that 'Account Schedule Overview' lets lookup values with max length for 'G/LBudgetFilter' control.

        // Setup.
        Initialize();
        // Exercise.
        GLBudgetName.Init();
        GLBudgetName.Validate(Name, LibraryUtility.GenerateGUID());
        GLBudgetName.Insert();

        // Verify.
        VerifyLookupInAccountScheduleOverview(GLBudgetFilterControlId, GLBudgetName.Name); // G/L Budget Filter
    end;

    [HandlerFunctions('CostBudgetNamesHandler')]
    [Scope('OnPrem')]
    procedure AccountScheduleOverviewWithCostBudgetFilter()
    var
        CostBudgetName: Record "Cost Budget Name";
    begin
        // Check that 'Account Schedule Overview' lets lookup values with max length for 'CostBudgetFilter' control.

        // Setup.
        Initialize();
        // Exercise.
        CostBudgetName.Init();
        CostBudgetName.Validate(Name, LibraryUtility.GenerateGUID());
        CostBudgetName.Insert();

        // Verify.
        VerifyLookupInAccountScheduleOverview(CostBudgetFilterControlId, CostBudgetName.Name); // Cost Budget Filter
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoOfAnalysisViewEntryDateCompressionNone()
    var
        GLAccount: Record "G/L Account";
        AnalysisView: Record "Analysis View";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        NoOfGLEntries: Integer;
    begin
        // Check that Analysis View shows correct number of Analysis Entry if 'Date Compression' is 'None'.

        // Setup.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Date Compression", AnalysisView."Date Compression"::None);
        AnalysisView.Validate("Dimension 1 Code", Dimension.Code);
        AnalysisView.Modify(true);

        // Exercise.
        NoOfGLEntries := LibraryRandom.RandIntInRange(2, 10);
        CreatePostJournalLinesWithDimension(DimensionValue, GLAccount."No.", NoOfGLEntries);
        CODEUNIT.Run(CODEUNIT::"Update Analysis View", AnalysisView);

        // Verify.
        VerifyNoOfAnalysisViewEntry(AnalysisView.Code, DimensionValue.Code, GLAccount."No.", NoOfGLEntries);
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrix_ExcludeClosingEntries_RecordsOnClosingDatesExcluded()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        AnalysisViewCode: Code[10];
    begin
        Initialize();
        LibraryERMCountryData.UpdateLocalData();

        CreateGeneralLineWithGLAccount(GenJournalLine);
        GenJournalLine.Validate("Posting Date", FindLastFYClosingDate());
        GenJournalLine.Modify();
        LibraryVariableStorage.Enqueue(0);

        AnalysisViewCode := CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        OpenAnalysisByDimensionMatrixWithLineDimCode(
          AnalysisViewCode, false, false, RoundingFactorOption, GLAccount.TableCaption(),
          ClosingDateOptions::Exclude, ShowAmounts::"Actual Amounts", '');
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrix_BudgetEntries_AmountCorrect()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        // 1. Setup: Create Dimension, Create New G/L Budget Name, update Dimension as Budget Dimension 1 Code on it.
        Initialize();

        CreateGeneralLineWithGLAccount(GenJournalLine);
        AnalysisViewCode := CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        LibraryVariableStorage.Enqueue(
          CreateAnalysisViewBudgetEntry(WorkDate(), AnalysisViewCode, GenJournalLine."Bal. Account No."));

        OpenAnalysisByDimensionMatrixWithLineDimCode(
          AnalysisViewCode, false, false, RoundingFactorOption, GLAccount.TableCaption(),
          ClosingDateOptions::Include, ShowAmounts::"Budgeted Amounts", '');
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixShowsAmountLCYAfterCurrenyPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        // [SCENARIO 122162] Analysis By Dimension Matrix shows Amounts in LCY after Gen. Journal posting with Currency
        Initialize();

        // [GIVEN] Create and post general journal line with Currency and AmountLCY = "A"
        CreateGeneralLineWithGLAccount(GenJournalLine);
        GenJournalLine.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        GenJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(-GenJournalLine."Amount (LCY)");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create new Analysis View
        AnalysisViewCode := CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        // [WHEN] Open Analysis By Dimension Matrix
        OpenAnalysisByDimensionMatrix(AnalysisViewCode, false, false, RoundingFactorOption);

        // [THEN] Analysis By Dimension Matrix Amount = "A"
        // Verify amount in AnalysisByDimensionMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixShowsAmountACY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
        AddRepCurrencyCode: Code[10];
    begin
        // [SCENARIO 122162] Analysis By Dimension Matrix shows Amounts in ACY when "Show Amounts in Add. Reporting Currency" = TRUE
        Initialize();

        // [GIVEN] Create and setup Additional Currency
        AddRepCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        UpdateGLSetupAddCurrency(AddRepCurrencyCode);

        // [GIVEN] Create and post general journal line with AmountACY = "A"
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(-LibraryERM.ConvertCurrency(GenJournalLine.Amount, '', AddRepCurrencyCode, WorkDate()));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create new Analysis View
        AnalysisViewCode := CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        // [WHEN] Open Analysis By Dimension Matrix with "Show Amounts in Add. Reporting Currency" = TRUE
        OpenAnalysisByDimensionMatrix(AnalysisViewCode, false, true, RoundingFactorOption);

        // [THEN] Analysis By Dimension Matrix Amount = "A"
        // Verify amount in AnalysisByDimensionMatrixPageHandler.

        // Tear Down
        UpdateGLSetupAddCurrency('');
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixFilterDimTotaling()
    var
        AnalysisView: Record "Analysis View";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DimensionValueTotal: Record "Dimension Value";
        GLAccountNo: Code[20];
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Analysis by Dimensions] [UI]
        // [SCENARIO 372110] Filter Dimension Value with type End-Total in the Analysis by Dimension Matrix page
        Initialize();

        // [GIVEN] Analysis View for G/L Account = "G" and "Dimension 1 Code" = new Dimension "Dim"
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        AnalysisView.Get(
          CreateAnalysisViewWithCertainDimension(GLAccountNo, DimensionCategory::"Dimension 1"));

        // [GIVEN] Dimension Values "D1", "D2" Dimension "Dim"
        LibraryDimension.CreateDimensionValue(DimensionValue1, AnalysisView."Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue2, AnalysisView."Dimension 1 Code");

        // [GIVEN] Dimension Value with type End-Total and Totaling = "D1".."D2"
        CreateDimensionValueWithRangeTotaling(
            DimensionValueTotal, AnalysisView."Dimension 1 Code", DimensionValueTotal."Dimension Value Type"::"End-Total",
            DimensionValue1.Code, DimensionValue2.Code);

        // [GIVEN] Posted Entries for G/L Account = "G" with Amounts = "X1" for "D1" dimension, "X2" for "D2" dimension
        TotalAmount :=
          CreateAndPostJournalLineWithDimension(DimensionValue1, GLAccountNo, WorkDate());
        TotalAmount +=
          CreateAndPostJournalLineWithDimension(DimensionValue2, GLAccountNo, WorkDate());
        LibraryVariableStorage.Enqueue(TotalAmount);

        // [WHEN] Open Analysis by Dimension Matrix page
        OpenAnalysisByDimensionMatrixWithLineDimCode(
          AnalysisView.Code, false, false, RoundingFactorOption, Format(LineDimOptionRef::"G/L Account"),
          ClosingDateOptions::Include, ShowAmounts::"Actual Amounts", DimensionValueTotal.Code);

        // [THEN] Analysis By Dimension Matrix Amount = Total Amount = "X1" + "X2"
        // Verification is done in AnalysisByDimensionMatrixPageHandler
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixTwoLinesPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixFilterByCode()
    var
        AnalysisView: Record "Analysis View";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        GLAccountNo: Code[20];
        LineAmount1: array[2] of Decimal;
        LineAmount2: array[2] of Decimal;
    begin
        // [FEATURE] [Analysis by Dimensions] [UI]
        // [SCENARIO 376318] Filter on the Code field in the Analysis by Dimension Matrix page should show records within the filter with correct Amounts.
        Initialize();

        // [GIVEN] Analysis View with "Dimension 1 Code" as Lines and Period as Columns
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        AnalysisView.Get(
          CreateAnalysisViewWithCertainDimension(GLAccountNo, DimensionCategory::"Dimension 1"));

        // [GIVEN] Dimension Values "D1", "D2"
        LibraryDimension.CreateDimensionValue(DimensionValue1, AnalysisView."Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue2, AnalysisView."Dimension 1 Code");

        // [GIVEN] Posted G/L Entries with Amount = "X1" on Date1, Amount = "X2" on Date2 for "D1" dimension
        LineAmount1[1] := CreateAndPostJournalLineWithDimension(DimensionValue1, GLAccountNo, WorkDate());
        LineAmount1[2] := CreateAndPostJournalLineWithDimension(DimensionValue1, GLAccountNo, WorkDate() + 1);

        // [GIVEN] Posted G/L Entries with Amount = "Y1" on Date1, Amount = "Y2" on Date2 for "D2" dimension
        LineAmount2[1] := CreateAndPostJournalLineWithDimension(DimensionValue2, GLAccountNo, WorkDate());
        LineAmount2[2] := CreateAndPostJournalLineWithDimension(DimensionValue2, GLAccountNo, WorkDate() + 1);

        LibraryVariableStorage.Enqueue(LineAmount1[1] + LineAmount1[2]);
        LibraryVariableStorage.Enqueue(LineAmount2[1] + LineAmount2[2]);
        LibraryVariableStorage.Enqueue(DimensionValue1.Code);
        LibraryVariableStorage.Enqueue(LineAmount1[1]);
        LibraryVariableStorage.Enqueue(LineAmount1[2]);

        // [GIVEN] Analysis by Dimension Matrix page has Total Amount = "X1" + "X2" for "D1" dimension
        // [GIVEN] Analysis by Dimension Matrix page has Total Amount = "Y1" + "Y2" for "D2" dimension
        OpenAnalysisByDimensionMatrixWithLineDimCode(
          AnalysisView.Code, false, false, RoundingFactorOption, DimensionValue1."Dimension Code",
          ClosingDateOptions::Include, ShowAmounts::"Actual Amounts", '');

        // [WHEN] Filter Code by "D1" dimension

        // [THEN] Analysis by Dimension Matrix page has Field1 = "X1", Field2 = "X2" for "D1" dimension
        // [THEN] No next record for "D2" dimension on the page
        // Filter and verification is done in AnalysisByDimensionMatrixTwoLinesPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunGLEntriesDimOvervMatrixByDefault()
    var
        GLEntry: Record "G/L Entry";
        GLEntriesDimOvervMatrix: TestPage "G/L Entries Dim. Overv. Matrix";
    begin
        // [FEATURE] [UT] [UI] [G/L Entries Dimension Overview] [Matrix]
        // [SCENARIO 377967] Should be possible to run G/L Entries Dim. Overv. Matrix without calling Load() function
        Initialize();

        // [WHEN] Open G/L Entries Dim. Overv. Matrix
        GLEntriesDimOvervMatrix.OpenView();

        // [THEN] Matrix position is set to the first G/L Entry record
        GLEntry.FindFirst();
        GLEntriesDimOvervMatrix."Entry No.".AssertEquals(GLEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunAnalysisByDimensionMatrixByDefault()
    var
        GLAccount: Record "G/L Account";
        AnalysisbyDimensionsMatrix: TestPage "Analysis by Dimensions Matrix";
    begin
        // [FEATURE] [UT] [UI] [Analysis By Dimensions] [Matrix]
        // [SCENARIO 378415] Should be possible to run Analysis By Dimensions Matrix without calling Load() function
        Initialize();

        // [WHEN] Open Analysis By Dimensions Matrix
        AnalysisbyDimensionsMatrix.OpenView();

        // [THEN] Matrix position is set to the first G/L Account record as default Show as Line option
        GLAccount.FindFirst();
        AnalysisbyDimensionsMatrix.Code.AssertEquals(GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTypeServiceAnalysisViewTwoStepsPosting()
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Non-Inventoriable]
        // [SCENARIO 379776] Item Analysis View Entry Update Posting TRUE for Purchase Order, Item of type Service. Posting in two steps.
        Initialize();

        // [GIVEN] Item Analysis View with Update Posting TRUE. Item of Type::Service.
        ItemNo := CreateItemTypeServiceOrNonStockAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase, true, true);

        CreatePostAndVerifyPurchaseOrderForServiceOrNonStockItem(ItemAnalysisView, ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemTypeNonStockAnalysisViewTwoStepsPosting()
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Non-Inventoriable]
        // [SCENARIO 379776] Item Analysis View Entry Update Posting TRUE for Purchase Order, Item of type Non-Inventory. Posting in two steps.
        Initialize();

        // [GIVEN] Item Analysis View with Update Posting TRUE. Item of Type::Service.
        ItemNo := CreateItemTypeServiceOrNonStockAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase, true, false);

        CreatePostAndVerifyPurchaseOrderForServiceOrNonStockItem(ItemAnalysisView, ItemNo);
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisbyDimMatrixPageDrillDownPageHandler,ItemAnalysisViewEntryPageHandler')]
    [Scope('OnPrem')]
    procedure DrillDownMatrixValueFromSalesAnalysisByDimWithORDimFilter()
    var
        Item: Record Item;
        DimValue: array[3] of Record "Dimension Value";
        ItemAnalysisView: Record "Item Analysis View";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
        SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions";
        ItemNo: Code[20];
        ExpectedAmount: array[2] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 380815] The filter "X|Y" handles correctly when drill-down values on Matrix page for "Sales Analysis by Dimensions" page with "Show Column Name" option

        Initialize();

        // [GIVEN] Dimensions "D1","D2" and "D3" with same Dimension Code "D"
        ItemNo := LibraryInventory.CreateItemNo();
        CreateSetOfDimensions(DimValue);

        // [GIVEN] Item Sales Analysis View with "Dimension 1 Code" = "D"
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        ItemAnalysisView.Validate("Dimension 1 Code", DimValue[1]."Dimension Code");
        ItemAnalysisView.Modify(true);

        // [GIVEN] Item Analysis View Entry "I1" for dimension "D1" with Amount = 100
        // [GIVEN] Item Analysis View Entry "I2" for dimension "D3" with Amount = 50
        ExpectedAmount[1] :=
          MockItemAnalysisViewEntry(ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, ItemNo, DimValue[1].Code);
        ExpectedAmount[2] :=
          MockItemAnalysisViewEntry(ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, ItemNo, DimValue[3].Code);
        LibraryVariableStorage.Enqueue(ExpectedAmount[1]);
        LibraryVariableStorage.Enqueue(ExpectedAmount[2]);

        // [GIVEN] "Sales Analysis by Dimensions" page is opened. Show as Lines - Item, Show as Columns - dimension "D". Dimension filter is "D1|D3"
        AnalysisViewListSales.OpenEdit();
        AnalysisViewListSales.FILTER.SetFilter(Code, ItemAnalysisView.Code);
        SalesAnalysisbyDimensions.Trap();
        AnalysisViewListSales.EditAnalysisView.Invoke();

        SetFiltersWithItemOnSalesAnalysisDimensionsPage(
          SalesAnalysisbyDimensions, Item.TableName, DimValue[1]."Dimension Code", ItemNo);
        SalesAnalysisbyDimensions.ShowColumnName.SetValue(true);

        // [GIVEN] Matrix page is opened from "Sales Analysis by Dimensions" page
        SalesAnalysisbyDimensions.Dim1FilterControl.SetValue(StrSubstNo('%1|%2', DimValue[1].Code, DimValue[3].Code));
        SalesAnalysisbyDimensions.ShowMatrix_Process.Invoke();

        // [WHEN] Drill down "Field 1" and "Field 2" associated with "D1" and "D3" accordingly
        // Done in SalesAnalysisbyDimMatrixPageDrillDownPageHandler

        // [THEN] "Item Analysis View Entry" is shown ("I1" for "D1", Amount = 100; "I2" for "D3", Amount = 50)
        // Done in ItemAnalysisViewEntryPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchAnalysisbyDimMatrixPageDrillDownPageHandler,ItemAnalysisViewEntryPageHandler')]
    [Scope('OnPrem')]
    procedure DrillDownMatrixValueFromPurchAnalysisByDimWithORDimFilter()
    var
        Item: Record Item;
        DimValue: array[3] of Record "Dimension Value";
        ItemAnalysisView: Record "Item Analysis View";
        AnalysisViewListPurchase: TestPage "Analysis View List Purchase";
        PurchAnalysisbyDimensions: TestPage "Purch. Analysis by Dimensions";
        ItemNo: Code[20];
        ExpectedAmount: array[2] of Decimal;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 380815] The filter "X|Y" handles correctly when drill-down values on Matrix page for "Purchase Analysis by Dimensions" page with "Show Column Name" option

        Initialize();

        // [GIVEN] Dimensions "D1","D2" and "D3" with same Dimension Code "D"
        ItemNo := LibraryInventory.CreateItemNo();
        CreateSetOfDimensions(DimValue);

        // [GIVEN] Item Purchase Analysis View with "Dimension 1 Code" = "D"
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);
        ItemAnalysisView.Validate("Dimension 1 Code", DimValue[1]."Dimension Code");
        ItemAnalysisView.Modify(true);

        // [GIVEN] Item Analysis View Entry "I1" for dimension "D1"
        // [GIVEN] Item Analysis View Entry "I2" for dimension "D3"
        ExpectedAmount[1] :=
          MockItemAnalysisViewEntry(ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, ItemNo, DimValue[1].Code);
        ExpectedAmount[2] :=
          MockItemAnalysisViewEntry(ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, ItemNo, DimValue[3].Code);
        LibraryVariableStorage.Enqueue(ExpectedAmount[1]);
        LibraryVariableStorage.Enqueue(ExpectedAmount[2]);

        // [GIVEN] "Purchase Analysis by Dimensions" page is opened. Show as Lines - Item, Show as Columns - dimension "D". Dimension filter is "D1|D3"
        AnalysisViewListPurchase.OpenEdit();
        AnalysisViewListPurchase.FILTER.SetFilter(Code, ItemAnalysisView.Code);
        PurchAnalysisbyDimensions.Trap();
        AnalysisViewListPurchase.EditAnalysisView.Invoke();
        SetFiltersWithItemOnPurchAnalysisDimensionsPage(PurchAnalysisbyDimensions, Item.TableName, DimValue[1]."Dimension Code", ItemNo);
        PurchAnalysisbyDimensions.ShowColumnName.SetValue(true);

        // [GIVEN] Matrix page is opened from "Purchase Analysis by Dimensions" page
        PurchAnalysisbyDimensions.Dim1FilterControl.SetValue(StrSubstNo('%1|%2', DimValue[1].Code, DimValue[3].Code));
        PurchAnalysisbyDimensions.ShowMatrix.Invoke();

        // [WHEN] Drill down "Field 1" and "Field 2" associated with "D1" and "D3" accordingly
        // Done in PurchaseAnalysisbyDimMatrixPageDrillDownPageHandler

        // [THEN] "Item Analysis View Entry" is shown ("I1" for "D1", "I2" for "D3")
        // Done in ItemAnalysisViewEntryPageHandler
    end;

    [Test]
    [HandlerFunctions('AnalysisbyDimensionsMatrixPageHandlerTotalAmountDrill,AnalysisViewPageHandler,GeneralLedgerEntriesPageHandler,GLEntriesDimensionOverviewPageHandler,GLEntriesDimOvervMatrixVerifyCountPageHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesDimOvervMatrixWithGenLinesCheckRecordsQty()
    var
        GLAccount: Record "G/L Account";
        DimensionValue: Record "Dimension Value";
        AnalysisView: Record "Analysis View";
        AnalysisViewList: TestPage "Analysis View List";
        AnalysisbyDimensions: TestPage "Analysis by Dimensions";
        NoOfGLEntries: Integer;
    begin
        // [SCENARIO 381290] Check quantity of records in G/L Entries Dimension Overview Matrix opened for selected Posted General Lines
        Initialize();

        // [GIVEN] G/L Account "GLACC" with a new Dimension "DIM" with a Dimension Value "DV"
        // [GIVEN] Analysis View "AV" with the source of G/L Account and with "DIM" and "GLACC"
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryERM.CreateAnalysisView(AnalysisView);
        UpdateDimensionInAnalysisView(AnalysisView, GLAccount."No.", DimensionValue."Dimension Code");

        // [GIVEN] A 3 Gen. Journal Lines posted with "GLACC" and "DIM"
        NoOfGLEntries := LibraryRandom.RandIntInRange(2, 10);
        LibraryVariableStorage.Enqueue(NoOfGLEntries);
        CreatePostJournalLinesWithDimension(DimensionValue, GLAccount."No.", NoOfGLEntries);

        // [GIVEN] "AV" is updated with codeunit "Update Analysis View"
        LibraryERM.UpdateAnalysisView(AnalysisView);

        // [WHEN] G/L Entries Dimension Overview Matrix Page is opened for Analysis View "AV"
        AnalysisViewList.OpenView();
        AnalysisViewList.GotoRecord(AnalysisView);
        AnalysisbyDimensions.Trap();
        AnalysisViewList.EditAnalysis.Invoke();

        // [THEN] GL Entries Dimension Overview Matrix Page shows 3 entries through GLEntriesDimOvervMatrixVerifyCountPageHandler
        AnalysisbyDimensions.ShowMatrix.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimValidateDim1FilterWithWrongValue()
    var
        ItemAnalysisView: Record "Item Analysis View";
        SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 220371] Test validation error when input wrong value to Dim1Filter on Sales Analysis By Dimension page
        Initialize();
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        SalesAnalysisbyDimensions.Trap();
        OpenEditSalesAnalysisView(AnalysisViewListSales, ItemAnalysisView.Code);
        asserterror SalesAnalysisbyDimensions.Dim1FilterControl.SetValue(LibraryUtility.GenerateGUID() + '|');
        VerifyTestValidationError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimValidateDim2FilterWithWrongValue()
    var
        ItemAnalysisView: Record "Item Analysis View";
        SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 220371] Test validation error when input wrong value to Dim2Filter on Sales Analysis By Dimension page
        Initialize();
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        SalesAnalysisbyDimensions.Trap();
        OpenEditSalesAnalysisView(AnalysisViewListSales, ItemAnalysisView.Code);
        asserterror SalesAnalysisbyDimensions.Dim2FilterControl.SetValue(LibraryUtility.GenerateGUID() + '|');
        VerifyTestValidationError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimValidateDim3FilterWithWrongValue()
    var
        ItemAnalysisView: Record "Item Analysis View";
        SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 220371] Test validation error when input wrong value to Dim3Filter on Sales Analysis By Dimension page
        Initialize();
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        SalesAnalysisbyDimensions.Trap();
        OpenEditSalesAnalysisView(AnalysisViewListSales, ItemAnalysisView.Code);
        asserterror SalesAnalysisbyDimensions.Dim3FilterControl.SetValue(LibraryUtility.GenerateGUID() + '|');
        VerifyTestValidationError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisbyDimValidateDim1FilterWithWrongValue()
    var
        ItemAnalysisView: Record "Item Analysis View";
        PurchAnalysisbyDimensions: TestPage "Purch. Analysis by Dimensions";
        AnalysisViewListPurchase: TestPage "Analysis View List Purchase";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 220371] Test validation error when input wrong value to Dim1Filter on Purchase Analysis By Dimension page
        Initialize();
        PurchAnalysisbyDimensions.Trap();
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);
        OpenEditPurchAnalysisView(AnalysisViewListPurchase, ItemAnalysisView.Code);
        asserterror PurchAnalysisbyDimensions.Dim1FilterControl.SetValue(LibraryUtility.GenerateGUID() + '|');
        VerifyTestValidationError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisbyDimValidateDim2FilterWithWrongValue()
    var
        ItemAnalysisView: Record "Item Analysis View";
        PurchAnalysisbyDimensions: TestPage "Purch. Analysis by Dimensions";
        AnalysisViewListPurchase: TestPage "Analysis View List Purchase";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 220371] Test validation error when input wrong value to Dim2Filter on Purchase Analysis By Dimension page
        Initialize();
        PurchAnalysisbyDimensions.Trap();
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);
        OpenEditPurchAnalysisView(AnalysisViewListPurchase, ItemAnalysisView.Code);
        asserterror PurchAnalysisbyDimensions.Dim2FilterControl.SetValue(LibraryUtility.GenerateGUID() + '|');
        VerifyTestValidationError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisbyDimValidateDim3FilterWithWrongValue()
    var
        ItemAnalysisView: Record "Item Analysis View";
        PurchAnalysisbyDimensions: TestPage "Purch. Analysis by Dimensions";
        AnalysisViewListPurchase: TestPage "Analysis View List Purchase";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 220371] Test validation error when input wrong value to Dim3Filter on Purchase Analysis By Dimension page
        Initialize();
        PurchAnalysisbyDimensions.Trap();
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);
        OpenEditPurchAnalysisView(AnalysisViewListPurchase, ItemAnalysisView.Code);
        asserterror PurchAnalysisbyDimensions.Dim3FilterControl.SetValue(LibraryUtility.GenerateGUID() + '|');
        VerifyTestValidationError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvtAnalysisByDimensionExcelExportWindowsClientUI()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        InvtAnalysisbyDimensions: TestPage "Invt. Analysis by Dimensions";
    begin
        // [FEATURE] [Analysis by Dimensions] [Inventory] [UI] [Windows Client] [Export to Excel]
        // [SCENARIO 216173] "Export To Excel" control visible in Windows client
        Initialize();

        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Windows);

        InvtAnalysisbyDimensions.OpenView();
        Assert.IsTrue(InvtAnalysisbyDimensions.ExportToExcel.Visible(), ExcelControlVisibilityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvtAnalysisByDimensionExcelExportWebClientUI()
    var
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        InvtAnalysisbyDimensions: TestPage "Invt. Analysis by Dimensions";
    begin
        // [FEATURE] [Analysis by Dimensions] [Inventory] [UI] [Web Client] [Export to Excel]
        // [SCENARIO 216173] "Export To Excel" control is visible in Web client
        Initialize();

        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);

        InvtAnalysisbyDimensions.OpenView();
        Assert.IsTrue(InvtAnalysisbyDimensions.ExportToExcel.Visible(), ExcelControlVisibilityErr);
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionsWhenDimContansAmpersandSign()
    var
        AnalysisView: Record "Analysis View";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        GLAccount: Record "G/L Account";
        AnalysisViewList: TestPage "Analysis View List";
        AnalysisbyDimensions: TestPage "Analysis by Dimensions";
        DimensionCode: Code[20];
    begin
        // [FEATURE] [Analysis by Dimensions] [UI]
        // [SCENARIO] Make Analysis by Dimensions Matrix with correct rows/columns when column dimension code contains & sign
        Initialize();

        // [GIVEN] Dimension "TEST & TEST" with value "TEST1"
        DimensionCode := LibraryUtility.GenerateRandomCode(Dimension.FieldNo(Code), DATABASE::Dimension);
        DimensionCode[1 + LibraryRandom.RandInt(StrLen(DimensionCode) - 2)] := '&';
        Dimension.Init();
        Dimension.Validate(Code, DimensionCode);
        Dimension.Insert(true);
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);

        // [GIVEN] Posted Gen. Journal Line with dimension = "TEST & TEST", dimension value = "TEST1", "GL Account" = "GLACC1", Amount = 100
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(CreateAndPostJournalLineWithDimension(DimensionValue, GLAccount."No.", WorkDate()));

        // [GIVEN] Analysis View "AV" by Dimensions with "Dimension 1 Code" = "TEST & TEST", "GAccount Filter" = "GLACC1"
        LibraryERM.CreateAnalysisView(AnalysisView);
        UpdateDimensionInAnalysisView(AnalysisView, GLAccount."No.", DimensionValue."Dimension Code");
        LibraryERM.UpdateAnalysisView(AnalysisView);

        // [GIVEN] Opened "Analysis by Dimensions" page for "AV", "Show as Lines" = "TEST & TEST"
        AnalysisViewList.OpenView();
        AnalysisViewList.GotoRecord(AnalysisView);
        AnalysisbyDimensions.Trap();
        AnalysisViewList.EditAnalysis.Invoke();
        AnalysisbyDimensions.LineDimCode.Value(DimensionCode);

        // [WHEN] Open "Analysis by Dimensions Matrix"
        AnalysisbyDimensions.ShowMatrix.Invoke();

        // [THEN] "Analysis by Dimensions Matrix" opened and contains row with Code = "TEST1", Total Amount = 100
        // [THEN] Verify amount in AnalysisByDimensionMatrixPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimValueValidateDimCodeWhenDimMappedIC()
    var
        ICDimension: Record "IC Dimension";
        DimensionValue: Record "Dimension Value";
        DimCode: Code[20];
    begin
        // [FEATURE] [UT] [Dimension Value] [Dimension Code] [Map-to IC Dimension Code]
        // [SCENARIO 277751] "Map-to IC Dimension Code" = IC Dimension Code for new Dimension Value created for Dimension which was previously mapped to IC Dimension
        Initialize();

        // [GIVEN] IC Dimension
        LibraryDimension.CreateICDimension(ICDimension);

        // [GIVEN] Dimension "D" was mapped to IC Dimension
        DimCode := CreateDimensionWithMapToICDimensionCode(ICDimension.Code);

        // [GIVEN] New Dimension Value
        DimensionValue.Init();

        // [WHEN] Validate "Dimension Code" = "D" in Dimension Value
        DimensionValue.Validate("Dimension Code", DimCode);

        // [THEN] "Map-to IC Dimension Code" = IC Dimension in Dimension Value
        DimensionValue.TestField("Map-to IC Dimension Code", ICDimension.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimValueClearMapToICDimValWhenChangeMapToICDim()
    var
        DimensionValue: Record "Dimension Value";
        ICD1: Code[20];
        ICD2: Code[20];
        ICDV: Code[20];
    begin
        // [FEATURE] [UT] [Dimension Value] [Map-to IC Dimension Code] [Map-to IC Dimension Value Code]
        // [SCENARIO 277751] When "Map-to IC Dimension Code" is changed in Dimension Value, then "Map-to IC Dimension Value Code" is cleared in Dimension Value
        Initialize();

        // [GIVEN] IC Dimension "ICD1" with value
        CreateICDimensionWithValue(ICD1, ICDV);

        // [GIVEN] IC Dimension with value "ICDV"
        CreateICDimensionWithValue(ICD2, ICDV);

        // [GIVEN] Dimension with value, mapped to "ICDV"
        CreateDimensionValueWithMapToICDimensionValueCode(
          DimensionValue, CreateDimensionWithMapToICDimensionCode(ICD2), ICDV);

        // [WHEN] Validate "Map-to IC Dimension Code" = "ICD1" in Dimension Value
        DimensionValue.Validate("Map-to IC Dimension Code", ICD1);

        // [THEN] "Map-to IC Dimension Value Code" is <blank> in Dimension Value
        DimensionValue.TestField("Map-to IC Dimension Value Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimValueDoNotClearMapToICDimValWhenSameMapToICDim()
    var
        DimensionValue: Record "Dimension Value";
        ICD: Code[20];
        ICDV: Code[20];
    begin
        // [FEATURE] [UT] [Dimension Value] [Map-to IC Dimension Code] [Map-to IC Dimension Value Code]
        // [SCENARIO 277751] When "Map-to IC Dimension Code" is validated with same value in Dimension Value, then "Map-to IC Dimension Value Code" is not cleared in Dimension Value
        Initialize();

        // [GIVEN] IC Dimension "ICD" with value "ICDV"
        CreateICDimensionWithValue(ICD, ICDV);

        // [GIVEN] Dimension with value, mapped to "ICDV"
        CreateDimensionValueWithMapToICDimensionValueCode(
          DimensionValue, CreateDimensionWithMapToICDimensionCode(ICD), ICDV);

        // [WHEN] Validate "Map-to IC Dimension Code" = "ICD" in Dimension Value
        DimensionValue.Validate("Map-to IC Dimension Code", ICD);

        // [THEN] "Map-to IC Dimension Value Code" is "ICDV" in Dimension Value
        DimensionValue.TestField("Map-to IC Dimension Value Code", ICDV);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICDimValueValidateICDimCodeWhenDimMapped()
    var
        Dimension: Record Dimension;
        ICDimensionValue: Record "IC Dimension Value";
        ICD: Code[20];
    begin
        // [FEATURE] [UT] [IC Dimension Value] [Dimension Code] [Map-to Dimension Code]
        // [SCENARIO 277751] "Map-to Dimension Code" = Dimension Code for new IC Dimension Value created for IC Dimension which was previously mapped to Dimension
        Initialize();

        // [GIVEN] Dimension
        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] IC Dimension "ICD" was mapped to Dimension
        ICD := CreateICDimensionWithMapToDimensionCode(Dimension.Code);

        // [GIVEN] New IC Dimension Value
        ICDimensionValue.Init();

        // [WHEN] Validate "Dimension Code" = "ICD" in IC Dimension Value
        ICDimensionValue.Validate("Dimension Code", ICD);

        // [THEN] "Map-to Dimension Code" = Dimension in IC Dimension Value
        ICDimensionValue.TestField("Map-to Dimension Code", Dimension.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICDimValueClearMapToDimValWhenChangeMapToDim()
    var
        ICDimensionValue: Record "IC Dimension Value";
        Dim1: Code[20];
        Dim2: Code[20];
        DimVal: Code[20];
    begin
        // [FEATURE] [UT] [IC Dimension Value] [Map-to Dimension Code] [Map-to Dimension Value Code]
        // [SCENARIO 277751] When "Map-to Dimension Code" is changed in IC Dimension Value, then "Map-to Dimension Value Code" is cleared in IC Dimension Value
        Initialize();

        // [GIVEN] Dimension "Dim1" with value
        CreateDimensionWithValue(Dim1, DimVal);

        // [GIVEN] Dimension with value "DimVal"
        CreateDimensionWithValue(Dim2, DimVal);

        // [GIVEN] IC Dimension with value, mapped to "DimVal"
        CreateICDimensionValueWithMapToDimensionValueCode(
          ICDimensionValue, CreateICDimensionWithMapToDimensionCode(Dim2), DimVal);

        // [WHEN] Validate "Map-to Dimension Code" = "Dim1" in IC Dimension Value
        ICDimensionValue.Validate("Map-to Dimension Code", Dim1);

        // [THEN] "Map-to Dimension Value Code" is <blank> in IC Dimension Value
        ICDimensionValue.TestField("Map-to Dimension Value Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICDimValueDoNotClearMapToDimValWhenSameMapToDim()
    var
        ICDimensionValue: Record "IC Dimension Value";
        Dim: Code[20];
        DimVal: Code[20];
    begin
        // [FEATURE] [UT] [IC Dimension Value] [Map-to Dimension Code] [Map-to Dimension Value Code]
        // [SCENARIO 277751] When "Map-to Dimension Code" is validated with same value in IC Dimension Value, then "Map-to Dimension Value Code" is not cleared in IC Dimension Value
        Initialize();

        // [GIVEN] Dimension "Dim" with value "DimVal"
        CreateDimensionWithValue(Dim, DimVal);

        // [GIVEN] IC Dimension with value, mapped to "DimVal"
        CreateICDimensionValueWithMapToDimensionValueCode(
          ICDimensionValue, CreateICDimensionWithMapToDimensionCode(Dim), DimVal);

        // [WHEN] Validate "Map-to Dimension Code" = "Dim" in IC Dimension Value
        ICDimensionValue.Validate("Map-to Dimension Code", Dim);

        // [THEN] "Map-to Dimension Value Code" is "DimVal" in IC Dimension Value
        ICDimensionValue.TestField("Map-to Dimension Value Code", DimVal);
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixFilterMultipleDimTotaling()
    var
        AnalysisView: Record "Analysis View";
        DimensionValue: array[3] of Record "Dimension Value";
        DimensionValueTotal: Record "Dimension Value";
        GLAccountNo: Code[20];
        TotalAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Analysis by Dimensions] [UI]
        // [SCENARIO 351505] Filter Dimension Value with filter using "|" and dimensions with Totaling in the Analysis by Dimension Matrix page
        Initialize();

        // [GIVEN] Analysis View for G/L Account = "G" and "Dimension 1 Code" = new Dimension "Dim"
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        AnalysisView.Get(
          CreateAnalysisViewWithCertainDimension(GLAccountNo, DimensionCategory::"Dimension 1"));

        // [GIVEN] Dimension Values "D1", "D2", "D3" Dimension "Dim"
        // [GIVEN] Posted Entries for G/L Account = "G" with Amounts = "X1" for "D1" dimension, "X2" for "D2" dimension, "X3" for "D3" dimension
        for i := 1 to ArrayLen(DimensionValue) do begin
            LibraryDimension.CreateDimensionValue(DimensionValue[i], AnalysisView."Dimension 1 Code");
            TotalAmount += CreateAndPostJournalLineWithDimension(DimensionValue[i], GLAccountNo, WorkDate());
        end;
        LibraryVariableStorage.Enqueue(TotalAmount);

        // [GIVEN] Dimension Value "DT" with type Total and Totaling = "D1".."D2"
        CreateDimensionValueWithRangeTotaling(
            DimensionValueTotal, AnalysisView."Dimension 1 Code", DimensionValueTotal."Dimension Value Type"::Total,
            DimensionValue[1].Code, DimensionValue[2].Code);

        // [WHEN] Open Analysis by Dimension Matrix page using dimension filter "DT|D3"
        OpenAnalysisByDimensionMatrixWithLineDimCode(
          AnalysisView.Code, false, false, RoundingFactorOption, Format(LineDimOptionRef::"G/L Account"),
          ClosingDateOptions::Include, ShowAmounts::"Actual Amounts", StrSubstNo('%1|%2', DimensionValueTotal.Code, DimensionValue[3].Code));

        // [THEN] Analysis By Dimension Matrix Amount = Total Amount = "X1" + "X2" + "X3"
        // Verification is done in AnalysisByDimensionMatrixPageHandler
    end;

    [Test]
    [HandlerFunctions('GLBalancebyDimMatrixPageHandler')]
    [Scope('OnPrem')]
    procedure OpenGLBalancebyDimMatrixFilterMultipleDimTotaling()
    var
        DimensionValue: array[3] of Record "Dimension Value";
        DimensionValueTotal: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GlobalDim1Code: Code[20];
        GLAccountNo: Code[20];
        TotalAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [GL Balance By Dimension] [UI]
        // [SCENARIO 351505] Filter Dimension Value with filter using "|" and dimensions with Totaling in the Balance by Dim. Matrix page
        Initialize();

        // [GIVEN] G/L Account
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Dimension Values "D1", "D2", "D3" Dimension "Dim"
        // [GIVEN] Posted Entries for G/L Account with Amounts = "X1" for "D1" dimension, "X2" for "D2" dimension, "X3" for "D3" dimension
        GeneralLedgerSetup.Get();
        GlobalDim1Code := GeneralLedgerSetup."Global Dimension 1 Code";
        for i := 1 to ArrayLen(DimensionValue) do begin
            LibraryDimension.CreateDimensionValue(DimensionValue[i], GlobalDim1Code);
            TotalAmount += CreateAndPostJournalLineWithDimension(DimensionValue[i], GLAccountNo, WorkDate());
        end;
        LibraryVariableStorage.Enqueue(TotalAmount);

        // [GIVEN] Dimension Value "DT" with type Total and Totaling = "D1".."D2"
        CreateDimensionValueWithRangeTotaling(
            DimensionValueTotal, GlobalDim1Code, DimensionValueTotal."Dimension Value Type"::Total,
            DimensionValue[1].Code, DimensionValue[2].Code);

        // [WHEN] Open Balance by Dim. Matrix page using dimension filter "DT|D3"
        OpenGLBalancebyDimMatrix(GLAccountNo, GlobalDim1Code, StrSubstNo('%1|%2', DimensionValueTotal.Code, DimensionValue[3].Code));

        // [THEN] Open Balance by Dim. Matrix Amount = Total Amount = "X1" + "X2" + "X3"
        // Verification is done in GLBalancebyDimMatrixPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalancebyDimensionLastUsedValuesSaved()
    var
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
        GLBalancebyDimension: TestPage "G/L Balance by Dimension";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [GL Balance By Dimension] [UI]
        // [SCENARIO 365722] G/L Balance By Dimension page keeps last used parameters values 
        Initialize();

        // [GIVEN] G/L Account "XXX"
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Open G/L Balance By Dimension page
        GLBalancebyDimension.OpenEdit();

        // [GIVEN] Set G/L Account Filter = "XXX"
        GLBalancebyDimension.GLAccFilter.SetValue(GLAccountNo);

        // [WHEN] G/L Balance By Dimension page is being closed
        GLBalancebyDimension.OK().Invoke();

        // [THEN] G/L Account Filter saved to "Analysis by Dim. User Param."
        AnalysisByDimUserParam.Get(UserId(), Page::"G/L Balance by Dimension");
        AnalysisByDimUserParam.TestField("Account Filter", GLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLBalancebyDimensionValuesFromAnalysisByDimUserParam()
    var
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
        GLBalancebyDimension: TestPage "G/L Balance by Dimension";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [GL Balance By Dimension] [UI]
        // [SCENARIO 365722] Page G/L Balance By Dimension uses parameters values from "Analysis by Dim. User Param."
        Initialize();

        // [GIVEN] G/L Account "XXX"
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] "Analysis by Dim. User Param." for current user and page 408 with G/L Account Filter = "XXX"
        AnalysisByDimUserParam.Init();
        AnalysisByDimUserParam."User ID" := UserId();
        AnalysisByDimUserParam."Page ID" := Page::"G/L Balance by Dimension";
        AnalysisByDimUserParam."Account Filter" := GLAccountNo;
        AnalysisByDimUserParam.Insert();

        // [WHEN] Open G/L Balance By Dimension page
        GLBalancebyDimension.OpenEdit();

        // [THEN] G/L Account Filter = "XXX"
        GLBalancebyDimension.GLAccFilter.AssertEquals(GLAccountNo);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure AnalysisbyDimensionsLastUsedValuesSaved()
    var
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
        AnalysisView: Record "Analysis View";
        GLBudgetName: Record "G/L Budget Name";
        AnalysisViewList: TestPage "Analysis View List";
        AnalysisbyDimensions: TestPage "Analysis by Dimensions";
    begin
        // [FEATURE] [GL Balance By Dimension] [UI]
        // [SCENARIO 365722] Analysis by Dimensions page keeps last used parameters values 
        Initialize();

        // [GIVEN] Analysis View "A"
        LibraryERM.CreateAnalysisView(AnalysisView);

        // [GIVEN] G/L Budget "XXX"
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN] Open Analysis by Dimensions page
        AnalysisViewList.OpenView();
        AnalysisViewList.Filter.SetFilter(Code, AnalysisView.Code);
        AnalysisbyDimensions.Trap();
        AnalysisViewList.EditAnalysis.Invoke();

        // [GIVEN] Set G/L Budget Filter = "XXX"
        AnalysisbyDimensions.BudgetFilter.SetValue(GLBudgetName.Name);

        // [WHEN] Analysis by Dimensions page is being closed
        AnalysisbyDimensions.OK().Invoke();

        // [THEN] G/L Budget Filter saved to "Analysis by Dim. User Param."
        AnalysisByDimUserParam.Get(UserId(), Page::"Analysis by Dimensions");
        AnalysisByDimUserParam.TestField("Budget Filter", GLBudgetName.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AnalysisbyDimensionsFromAnalysisViewValuesFromAnalysisByDimUserParam()
    var
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
        AnalysisView: Record "Analysis View";
        GLBudgetName: Record "G/L Budget Name";
        AnalysisViewList: TestPage "Analysis View List";
        AnalysisbyDimensions: TestPage "Analysis by Dimensions";
    begin
        // [FEATURE] [GL Balance By Dimension] [UI]
        // [SCENARIO 365722] Page Analysis by Dimensions uses parameters values from "Analysis by Dim. User Param." when run from Analysis View List page
        Initialize();

        // [GIVEN] Analysis View "A"
        LibraryERM.CreateAnalysisView(AnalysisView);
        // [GIVEN] G/L Budget "XXX"
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN] "Analysis by Dim. User Param." for current user and page 408 with G/L Budget Filter = "XXX"
        AnalysisByDimUserParam.Init();
        AnalysisByDimUserParam."User ID" := UserId();
        AnalysisByDimUserParam."Page ID" := Page::"Analysis by Dimensions";
        AnalysisByDimUserParam."Budget Filter" := GLBudgetName.Name;
        AnalysisByDimUserParam.Insert();

        // [WHEN] Open Analysis by Dimensions page
        AnalysisViewList.OpenView();
        AnalysisViewList.Filter.SetFilter(Code, AnalysisView.Code);
        AnalysisbyDimensions.Trap();
        AnalysisViewList.EditAnalysis.Invoke();

        // [THEN] G/L Budget Filter = "XXX"
        AnalysisbyDimensions.BudgetFilter.AssertEquals(GLBudgetName.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AnalysisbyDimensionsValuesFromAnalysisByDimUserParam()
    var
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
        GLBudgetName: Record "G/L Budget Name";
        AnalysisView: Record "Analysis View";
        AnalysisbyDimensions: TestPage "Analysis by Dimensions";
    begin
        // [FEATURE] [GL Balance By Dimension] [UI]
        // [SCENARIO 365722] Page Analysis by Dimensions uses parameters values from "Analysis by Dim. User Param." when run directly
        Initialize();

        // [GIVEN] Remove existing analysis views to clear dependencies
        AnalysisView.DeleteAll();
        LibraryERM.CreateAnalysisView(AnalysisView);

        // [GIVEN] G/L Budget "XXX"
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // [GIVEN] "Analysis by Dim. User Param." for current user and page 408 with G/L Budget Filter = "XXX"
        AnalysisByDimUserParam.Init();
        AnalysisByDimUserParam."User ID" := UserId();
        AnalysisByDimUserParam."Page ID" := Page::"Analysis by Dimensions";
        AnalysisByDimUserParam."Budget Filter" := GLBudgetName.Name;
        AnalysisByDimUserParam.Insert();

        // [WHEN] Open Analysis by Dimensions page
        AnalysisbyDimensions.OpenEdit();

        // [THEN] G/L Budget Filter = "XXX"
        AnalysisbyDimensions.BudgetFilter.AssertEquals(GLBudgetName.Name);
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixEnqueTotalPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixDecimalPlacesRoundingFactorNone()
    var
        AnalysisView: Record "Analysis View";
        DimensionValue: Record "Dimension Value";
        GLAccountNo: Code[20];
        Amount: Decimal;
        DecimalPlaces: Text[5];
    begin
        // [FEATURE] [Analysis by Dimensions] [UI]
        // [SCENARIO 375411] Amount Decimal Places in General Ledger Setup affects Decimal Places displayed in Analysis by Dimension Matrix page when Rounding Factor = None.
        Initialize();

        // [GIVEN] "Amount Decimal Places" is set to 5:5 in General Ledger Setup.
        DecimalPlaces := StrSubstNo('%1:%1', LibraryRandom.RandIntInRange(3, 5));
        SetAmountDecimalPlaces(DecimalPlaces);

        // [GIVEN] Analysis View for G/L Account and "Dimension 1 Code" = Dimension "Dim".
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        AnalysisView.Get(CreateAnalysisViewWithCertainDimension(GLAccountNo, DimensionCategory::"Dimension 1"));

        // [GIVEN] Dimension Value "DV" for Dimension "Dim".
        LibraryDimension.CreateDimensionValue(DimensionValue, AnalysisView."Dimension 1 Code");

        // [GIVEN] Posted Entry for G/L Account with Amount having 2 decimals places.
        Amount := CreateAndPostJournalLineWithDimension(DimensionValue, GLAccountNo, WorkDate());

        // [WHEN] Open Analysis by Dimension Matrix page using dimension filter "DV" and Rounding Factor = None.
        OpenAnalysisByDimensionMatrixWithLineDimCode(
            AnalysisView.Code, false, false, RoundingFactorOption, Format(LineDimOptionRef::"G/L Account"),
            ClosingDateOptions::Include, ShowAmounts::"Actual Amounts", DimensionValue.Code);

        // [THEN] Analysis By Dimension Matrix Amount displays 5 decimal places.
        Assert.AreEqual(Format(Amount, 0, StrSubstNo(FormatStrTxt, DecimalPlaces)), LibraryVariableStorage.DequeueText(), '');
    end;

    [Test]
    [HandlerFunctions('AnalysisByDimensionMatrixEnqueTotalPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixDecimalPlacesRoundingFactorOne()
    var
        AnalysisView: Record "Analysis View";
        DimensionValue: Record "Dimension Value";
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Analysis by Dimensions] [UI]
        // [SCENARIO 375411] Analysis by Dimension Matrix page shows zero decimal places when Rounding Factor = 1.
        Initialize();

        // [GIVEN] Analysis View for G/L Account and "Dimension 1 Code" = Dimension "Dim".
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        AnalysisView.Get(CreateAnalysisViewWithCertainDimension(GLAccountNo, DimensionCategory::"Dimension 1"));

        // [GIVEN] Dimension Value "DV" for Dimension "Dim".
        LibraryDimension.CreateDimensionValue(DimensionValue, AnalysisView."Dimension 1 Code");

        // [GIVEN] Posted Entry for G/L Account with Amount having 2 decimal places.
        Amount := CreateAndPostJournalLineWithDimension(DimensionValue, GLAccountNo, WorkDate());

        // [WHEN] Open Analysis by Dimension Matrix page using dimension filter "DV" and Rounding Factor = 1.
        OpenAnalysisByDimensionMatrixWithLineDimCode(
            AnalysisView.Code, false, false, Format(1), Format(LineDimOptionRef::"G/L Account"),
            ClosingDateOptions::Include, ShowAmounts::"Actual Amounts", DimensionValue.Code);

        // [THEN] Analysis By Dimension Matrix Amount displays zero decimal places.
        Assert.AreEqual(Format(Amount, 0, StrSubstNo(FormatStrTxt, Format(0))), LibraryVariableStorage.DequeueText(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GLBalanceDimMatrixPageHandler')]
    procedure GLBalancebyDimensionValuesFromAnalysisByDimUserParamDateFilter()
    var
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
        GLBalancebyDimension: TestPage "G/L Balance by Dimension";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [GL Balance By Dimension] [UI]
        // [SCENARIO 385733] G/L Balance by Dim. Matrix shows the periods from saved parameters
        Initialize();

        // [GIVEN] G/L Account "XXX"
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] "Analysis by Dim. User Param." for current user and page 408 with G/L Account Filter = "XXX" and "Date Filter" = '01/01/2021..01/02/2021';
        AnalysisByDimUserParam.Init();
        AnalysisByDimUserParam."User ID" := UserId();
        AnalysisByDimUserParam."Page ID" := Page::"G/L Balance by Dimension";
        AnalysisByDimUserParam."Account Filter" := GLAccountNo;
        AnalysisByDimUserParam."Date Filter" := Format(WorkDate()) + '..' + Format(CalcDate('<1D>', WorkDate()));
        AnalysisByDimUserParam.Insert();

        // [WHEN] Open G/L Balance By Dimension page and invoke "Show Matrix"
        GLBalancebyDimension.OpenEdit();
        GLBalancebyDimension.LineDimCode.SetValue('');
        GLBalancebyDimension.ColumnDimCode.SetValue('');
        GLBalancebyDimension.Close();
        GLBalancebyDimension.OpenEdit();
        GLBalancebyDimension.ShowMatrix.Invoke();

        // [THEN] G/L Balance by Dim. Matrix is showing only Field1 and Field2
        // Verification in GLBalanceDimMatrixPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GLBalanceDimMatrixGlobalDim12ValueAsColumnPageHandler2')]
    procedure GLBalancebyDimensionSaveGlobalDim1Dim2FilterOnReopen()
    var
        Dimension: Array[2] of Record Dimension;
        DimensionValue: Array[4] of Record "Dimension Value";
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
        GLBalancebyDimension: TestPage "G/L Balance by Dimension";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [GL Balance By Dimension] [UI]
        // [SCENARIO 399208] G/L Balance by Dim should save Global Dimensions 1 and 2 filters after reopen
        Initialize();

        // [GIVEN] G/L Account "GL1"
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Global Dimension 1 'GL1' with Dimension Values 'GL1-1' and 'GL1-2'
        LibraryDimension.CreateDimension(Dimension[1]);
        LibraryERM.SetGlobalDimensionCode(1, Dimension[1].Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], Dimension[1].Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension[1].Code);

        // [GIVEN] Global Dimension 2 'GL2' with Dimension Values 'GL2-1' and 'GL2-2'
        LibraryDimension.CreateDimension(Dimension[2]);
        LibraryERM.SetGlobalDimensionCode(2, Dimension[2].Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[3], Dimension[2].Code);
        LibraryDimension.CreateDimensionValue(DimensionValue[4], Dimension[2].Code);

        // [GIVEN] "Analysis by Dim. User Param." for current user and page 408 with G/L Account Filter = "GL1" and "Date Filter" = '01/01/2021..01/02/2021';
        AnalysisByDimUserParam.Init();
        AnalysisByDimUserParam."User ID" := UserId();
        AnalysisByDimUserParam."Page ID" := Page::"G/L Balance by Dimension";
        AnalysisByDimUserParam."Account Filter" := GLAccountNo;
        AnalysisByDimUserParam.Insert();

        // [GIVEN] G/L Balance by Dimension page with Show As Columns = 'GL2' and Global Dimension 2 filter = 'GL2-1'
        GLBalancebyDimension.OpenEdit();
        GLBalancebyDimension.LineDimCode.SetValue('');
        GLBalancebyDimension.ColumnDimCode.SetValue(Dimension[2].Code);
        GLBalancebyDimension.Dim1Filter.SetValue('');
        GLBalancebyDimension.Dim2Filter.SetValue(DimensionValue[3].Code);
        GLBalancebyDimension.Close();

        // [WHEN] G/L Balance by Dimension page is reopended and G/L Balance by Dim. Matrix invoked
        GLBalancebyDimension.OpenEdit();
        GLBalancebyDimension.ShowMatrix.Invoke();
        GLBalancebyDimension.Close();

        // [THEN] G/L Balance by Dim. Matrix is showing only Field1(DimensionValue[3]). Field2(DimensionValue[4].Code) should not be shown
        // Verification in GLBalanceDimMatrixGlobalDim12ValueAsColumnPageHandler2

        // [GIVEN] G/L Balance by Dimension page with Show As Columns = 'GL1' and Global Dimension 1 filter = 'GL1-1'
        GLBalancebyDimension.OpenEdit();
        GLBalancebyDimension.ColumnDimCode.SetValue(Dimension[1].Code);
        GLBalancebyDimension.Dim1Filter.SetValue(DimensionValue[1].Code);
        GLBalancebyDimension.Dim2Filter.SetValue('');
        GLBalancebyDimension.Close();

        // [WHEN] G/L Balance by Dimension page is reopended and G/L Balance by Dim. Matrix invoked
        GLBalancebyDimension.OpenEdit();
        GLBalancebyDimension.ShowMatrix.Invoke();
        GLBalancebyDimension.Close();

        // [THEN] G/L Balance by Dim. Matrix is showing only Field1(DimensionValue[1]). Field2(DimensionValue[2].Code) should not be shown
        // Verification in GLBalanceDimMatrixGlobalDim12ValueAsColumnPageHandler2
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAnalysisViewByWeekWithInternalDateFilter()
    var
        ItemAnalysisView: Record "Item Analysis View";
        DimCodeBuf: Record "Dimension Code Buffer";
        Item: Record Item;
        ItemAnalysisMgt: Codeunit "Item Analysis Management";
        DateFilter: Text[30];
        InternalDateFilter: Text[30];
        DimOption: Option Item,Period,Location,"Dimension 1","Dimension 2","Dimension 3";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        PeriodStart: Date;
        PeriodEnd: Date;
        PeriodInitialized: Boolean;
    begin
        // [Scenario 609713]-Matrix Option View By Week does not work in Sales/Purchase Analysis Views for the Next Set showing the incorrect week filtering.

        // Setup
        ItemAnalysisView.Init();
        PeriodInitialized := true;
        DimOption := DimOption::Period;
        PeriodType := PeriodType::Week;
        PeriodStart := CalcDate('<-CW>', WorkDate());
        PeriodEnd := CalcDate('<+1Y-1D>', PeriodStart);

        DateFilter := '';
        Item.SetRange("Date Filter", PeriodStart, PeriodEnd);
        InternalDateFilter := CopyStr(Item.GetFilter("Date Filter"), 1, MaxStrLen(InternalDateFilter));

        // Exercize
        ItemAnalysisMgt.FindRecord(
          ItemAnalysisView, "Item Analysis Dimension Type".FromInteger(DimOption), DimCodeBuf, '', '', '',
          "Analysis Period Type".FromInteger(PeriodType), DateFilter, PeriodInitialized, InternalDateFilter, '', '', '');

        // Verify
        Assert.AreEqual(PeriodStart, DimCodeBuf."Period Start", StartPeriodErr);
        Assert.AreEqual(CalcDate('<+1W-1D>', PeriodStart), DimCodeBuf."Period End", EndPeriodErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension General Part 2");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        ClearAnalysisByDimUserParam();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension General Part 2");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        GLBudgetFilterControlId := 6;
        CostBudgetFilterControlId := 9;

        Commit();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension General Part 2");
    end;

    local procedure ClearAnalysisByDimUserParam()
    var
        AnalysisByDimUserParam: Record "Analysis by Dim. User Param.";
    begin
        AnalysisByDimUserParam.DeleteAll();
    end;

    local procedure CreateDimensionValueWithRangeTotaling(var DimValTotal: Record "Dimension Value"; DimCode: Code[20]; DimValType: Option; DimValFirstCode: Code[20]; DimValLastCode: Code[20])
    begin
        LibraryDimension.CreateDimensionValue(DimValTotal, DimCode);
        DimValTotal.Validate("Dimension Value Type", DimValType);
        DimValTotal.Validate(Totaling, StrSubstNo('%1..%2', DimValFirstCode, DimValLastCode));
        DimValTotal.Modify(true);
    end;

    local procedure CreateDimensionWithValue(var DimensionCode: Code[20]; var DimensionValueCode: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionCode := Dimension.Code;
        DimensionValueCode := DimensionValue.Code;
    end;

    local procedure CreateICDimensionWithValue(var ICDimensionCode: Code[20]; var ICDimensionValueCode: Code[20])
    var
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
    begin
        LibraryDimension.CreateICDimension(ICDimension);
        LibraryDimension.CreateICDimensionValue(ICDimensionValue, ICDimension.Code);
        ICDimensionCode := ICDimension.Code;
        ICDimensionValueCode := ICDimensionValue.Code;
    end;

    local procedure CreateDimensionWithMapToICDimensionCode(MapToICDimensionCode: Code[20]): Code[20]
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        Dimension.Validate("Map-to IC Dimension Code", MapToICDimensionCode);
        Dimension.Modify(true);
        exit(Dimension.Code);
    end;

    local procedure CreateICDimensionWithMapToDimensionCode(MapToDimensionCode: Code[20]): Code[20]
    var
        ICDimension: Record "IC Dimension";
    begin
        LibraryDimension.CreateICDimension(ICDimension);
        ICDimension.Validate("Map-to Dimension Code", MapToDimensionCode);
        ICDimension.Modify(true);
        exit(ICDimension.Code);
    end;

    local procedure CreateDimensionValueWithMapToICDimensionValueCode(var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20]; MapToICDimensionValueCode: Code[20])
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        DimensionValue.Validate("Map-to IC Dimension Value Code", MapToICDimensionValueCode);
        DimensionValue.Modify(true);
    end;

    local procedure CreateICDimensionValueWithMapToDimensionValueCode(var ICDimensionValue: Record "IC Dimension Value"; ICDimensionCode: Code[20]; MapToDimensionValueCode: Code[20])
    begin
        LibraryDimension.CreateICDimensionValue(ICDimensionValue, ICDimensionCode);
        ICDimensionValue.Validate("Map-to Dimension Value Code", MapToDimensionValueCode);
        ICDimensionValue.Modify(true);
    end;

    local procedure CreateAnalysisViewWithDimension(AccountFilter: Code[250]): Code[10]
    begin
        exit(CreateAnalysisViewWithCertainDimension(AccountFilter, 4));
    end;

    local procedure CreateAnalysisViewWithCertainDimension(AccountFilter: Code[250]; DimensionOption: Option): Code[10]
    var
        AnalysisView: Record "Analysis View";
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Account Source", AnalysisView."Account Source"::"G/L Account");
        AnalysisView.Validate("Account Filter", AccountFilter);
        case DimensionOption of
            DimensionCategory::"Dimension 1":
                AnalysisView.Validate("Dimension 1 Code", Dimension.Code);
            DimensionCategory::"Dimension 2":
                AnalysisView.Validate("Dimension 2 Code", Dimension.Code);
            DimensionCategory::"Dimension 3":
                AnalysisView.Validate("Dimension 3 Code", Dimension.Code);
            DimensionCategory::"Dimension 4":
                AnalysisView.Validate("Dimension 4 Code", Dimension.Code);
        end;
        AnalysisView.Modify(true);
        exit(AnalysisView.Code);
    end;

    local procedure CreateSalesAnalysisWithDimTotalingFilter(var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; ItemAnalysisViewCode: Code[10]; CustomerNo: Code[20]; TotalDimValueCode: Code[20])
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Sales);
        AnalysisLineTemplate.Validate("Item Analysis View Code", ItemAnalysisViewCode);
        AnalysisLineTemplate.Modify(true);
        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisLineTemplate."Analysis Area", AnalysisLineTemplate.Name);
        AnalysisLine.Validate("Row Ref. No.", LibraryUtility.GenerateGUID());
        AnalysisLine.Validate(Type, AnalysisLine.Type::Customer);
        AnalysisLine.Validate(Range, CustomerNo);
        AnalysisLine.Validate("Dimension 1 Totaling", TotalDimValueCode);
        AnalysisLine.Modify(true);

        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisColumnTemplate."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisColumnTemplate."Analysis Area", AnalysisColumnTemplate.Name);
        AnalysisColumn.Validate("Column No.", LibraryUtility.GenerateGUID());
        AnalysisColumn.Validate("Column Type", AnalysisColumn."Column Type"::"Net Change");
        AnalysisColumn.Validate("Ledger Entry Type", AnalysisColumn."Ledger Entry Type"::"Item Entries");
        AnalysisColumn.Validate("Value Type", AnalysisColumn."Value Type"::"Sales Amount");
        AnalysisColumn.Validate(Invoiced, true);
        AnalysisColumn.Modify(true);
    end;

    local procedure CreateAnalysisAndSalesInvoice(var ItemAnalysisView: Record "Item Analysis View"; var SalesLine: Record "Sales Line"; UpdatePosting: Boolean) PostingDate: Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        LibraryDimension: Codeunit "Library - Dimension";
        ItemNo: Code[20];
    begin
        // Setup: Create Item Analysis View with Update Posting TRUE and Sales Invoice.
        GeneralLedgerSetup.Get();
        CreateItemAnalysisViewWithItemFilterAndUpdateOnPostingSetup(
          ItemAnalysisView, false, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");

        // Exercise.
        ItemNo := CopyStr(ItemAnalysisView."Item Filter", 1, LibraryUtility.GetFieldLength(DATABASE::Item, Item.FieldNo("No.")));
        PostingDate := CreateAndPostSalesInvoice(SalesLine, DimensionValue.Code, ItemNo);
        if UpdatePosting then
            CODEUNIT.Run(CODEUNIT::"Update Item Analysis View", ItemAnalysisView);
    end;

    local procedure RunAndVerifyItemAnalysis(ItemAnalysisView: Record "Item Analysis View"; SalesLine: Record "Sales Line"; DateCompression: Option; PostingDate: Date)
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        // Exercise.
        UpdateAndRunItemAnalysisView(ItemAnalysisView, DateCompression);

        FindItemAnalysisViewEntry(ItemAnalysisViewEntry, SalesLine."Sell-to Customer No.", SalesLine."No.", ItemAnalysisView.Code);
        ItemAnalysisViewEntry.FindFirst();
        ItemAnalysisViewEntry.TestField("Posting Date", PostingDate);
    end;

    local procedure UpdateAndRunItemAnalysisView(ItemAnalysisView: Record "Item Analysis View"; DateCompression: Option)
    var
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
    begin
        ItemAnalysisView.Get(ItemAnalysisView."Analysis Area", ItemAnalysisView.Code);
        ItemAnalysisView.Validate("Date Compression", DateCompression);
        ItemAnalysisView.Modify(true);

        UpdateItemAnalysisView.Run(ItemAnalysisView);
    end;

    local procedure CreateAndPostSalesDocument(CustomerNo: Code[20]; ItemNo: Code[20]; SalespersonCode: Code[20]; var Quantity: Decimal; var Amount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Take Random Values for Quantity and Sales Price and Assign Values in Global Variables.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));

        // Amount and Quantity are getting accumulated when calling CreateAndPostSalesDocument multiple times.
        Quantity += SalesLine.Quantity;
        Amount += SalesLine."Line Amount";
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesDocumentAtDate(CustomerNo: Code[20]; ItemNo: Code[20]; DocDate: Date): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Take Random Values for Quantity and Sales Price and Assign Values in Global Variables.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Order Date", DocDate);
        SalesHeader.Validate("Posting Date", DocDate);
        SalesHeader.Validate("Shipment Date", DocDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine."Line Amount");
    end;

    local procedure CreateAndPostPurchDocumentAtDate(VendorNo: Code[20]; ItemNo: Code[20]; DocDate: Date): Decimal
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Take Random Values for Quantity and Sales Price and Assign Values in Global Variables.
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        PurchHeader.Validate("Order Date", DocDate);
        PurchHeader.Validate("Posting Date", DocDate);
        PurchHeader.Validate("Expected Receipt Date", DocDate);
        PurchHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        exit(PurchLine."Line Amount");
    end;

    local procedure CreateGeneralLineWithGLAccount(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        // Using Random Number Generator for Amount.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAnalysisViewDimension(Dimension1Code: Code[20]): Code[10]
    var
        AnalysisView: Record "Analysis View";
    begin
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Dimension 1 Code", Dimension1Code);
        AnalysisView.Modify(true);
        exit(AnalysisView.Code);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"; DimensionValue: Code[20]; ItemNo: Code[20]): Date
    var
        SalesHeader: Record "Sales Header";
    begin
        // Take Random Quantity for Sales Line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithDimension(DimensionValue));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesHeader."Posting Date");
    end;

    local procedure CreateAndPostMultiLineSalesOrder(var Dimension: Record Dimension; var ItemSetFilter: Text[50]; var PostingDate: Date)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        i: Integer;
        NoOfColumns: Integer;
        DimensionSetID: Integer;
        DimSetID: Integer;
        TotalQuantity: array[2] of Decimal;
        TotalAmount: array[2] of Decimal;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        // Set the number of columns in page Sales Analysis by Dim Matrix.
        NoOfColumns := 32;
        // Create dimension for Sale lines.
        DimensionSetID := 0;
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimSetID := LibraryDimension.CreateDimSet(DimensionSetID, DimensionValue."Dimension Code", DimensionValue.Code);
        Item.FindSet();
        Item.Next(1);
        ItemSetFilter := Item."No.";
        GetNextItemDefaultDims(Item, 0);
        CreateSalesLineWithDimForItem(TotalQuantity[1], TotalAmount[1], SalesHeader, DimSetID, Item."No.");
        // Move to the first column of the second columns set.
        GetNextItemDefaultDims(Item, NoOfColumns);
        CreateSalesLineWithDimForItem(TotalQuantity[2], TotalAmount[2], SalesHeader, DimSetID, Item."No.");
        ItemSetFilter := ItemSetFilter + '..' + Item."No.";

        for i := 1 to 2 do begin
            LibraryVariableStorage.Enqueue(TotalQuantity[1] + TotalQuantity[2]); // Matrix's Total Quantity
            LibraryVariableStorage.Enqueue(TotalAmount[1] + TotalAmount[2]); // Matrix's Total Amount
            LibraryVariableStorage.Enqueue(TotalAmount[i]); // Matrix's 1st column amount
        end;

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        PostingDate := SalesHeader."Posting Date";
    end;

    local procedure CreateSalesLineWithDimForItem(var TotalQuantity: Decimal; var TotalAmount: Decimal; SalesHeader: Record "Sales Header"; DimSetId: Integer; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Dimension Set ID", DimSetId);
        SalesLine.Modify(true);
        TotalQuantity := SalesLine.Quantity;
        TotalAmount := SalesLine."Line Amount";
    end;

    local procedure InvokeShowMatrixOnDifferentItemSets(Dimension: Record Dimension; ItemAnalysisViewCode: Code[10]; ItemFilter: Text[50]; DateFilter: Date)
    var
        Item: Record Item;
        SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
        ShowValueAs: Option "Sales Amount","COGS Amount",Quantity;
        ViewBy: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        AnalysisViewListSales.OpenEdit();
        AnalysisViewListSales.FILTER.SetFilter(Code, ItemAnalysisViewCode);
        AnalysisViewListSales."&Update".Invoke();

        SalesAnalysisbyDimensions.Trap();
        AnalysisViewListSales.EditAnalysisView.Invoke();

        SalesAnalysisbyDimensions.DateFilter.SetValue(Format(DateFilter));
        SetFiltersWithItemOnSalesAnalysisDimensionsPage(
          SalesAnalysisbyDimensions, Format(Dimension.Code), Item.TableCaption(), ItemFilter);
        SalesAnalysisbyDimensions.PeriodType.SetValue(ViewBy::Month);
        SalesAnalysisbyDimensions.ValueType.SetValue(ShowValueAs::"Sales Amount");
        // Check the total values with initial set.
        SalesAnalysisbyDimensions.ShowMatrix_Process.Invoke();
        // Here it needs to go to next set and check the total values.
        SalesAnalysisbyDimensions.NextSet.Invoke();
        SalesAnalysisbyDimensions.ShowMatrix_Process.Invoke();
    end;

    local procedure CreateCustomerWithDimension(GlobalDimension1Code: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Global Dimension 1 Code", GlobalDimension1Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLBudgetNameDimension(BudgetDimension1Code: Code[20]): Code[10]
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        GLBudgetName.Validate("Budget Dimension 1 Code", BudgetDimension1Code);
        GLBudgetName.Modify(true);
        exit(GLBudgetName.Name);
    end;

    local procedure CreateJournalLineWithDimension(var GenJournalLine: Record "Gen. Journal Line"; DimensionValue: Record "Dimension Value"; AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FindJournalBatchAndTemplate(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, AccountType, AccountNo);
        GenJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostJournalLineWithDimension(DimensionValue: Record "Dimension Value"; AccountNo: Code[20]; PostingDate: Date): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateJournalLineWithDimension(GenJournalLine, DimensionValue, AccountNo, GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine.Amount);
    end;

    local procedure CreatePostJournalLinesWithDimension(DimensionValue: Record "Dimension Value"; AccountNo: Code[20]; NoOfLines: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Counter: Integer;
    begin
        FindJournalBatchAndTemplate(GenJournalBatch);
        for Counter := 1 to NoOfLines do begin
            CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", AccountNo);
            GenJournalLine.Validate(
              "Dimension Set ID",
              LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
            GenJournalLine.Modify(true);
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateItemAnalysisViewWithItemFilterAndUpdateOnPostingSetup(var ItemAnalysisView: Record "Item Analysis View"; UpdateOnPosting: Boolean; Dimension1Code: Code[20])
    begin
        CreateItemAnalysisView(ItemAnalysisView, Dimension1Code);
        ItemAnalysisView.Validate("Update on Posting", UpdateOnPosting);
        ItemAnalysisView.Validate("Item Filter", CreateItem());
        ItemAnalysisView.Modify(true);
    end;

    local procedure CreateItemAnalysisView(var ItemAnalysisView: Record "Item Analysis View"; Dimension1Code: Code[20])
    begin
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        ItemAnalysisView.Validate("Dimension 1 Code", Dimension1Code);
        ItemAnalysisView.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSetOfDimensions(var DimValue: array[3] of Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue[1], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimValue[2], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimValue[3], Dimension.Code);
    end;

    local procedure MockItemAnalysisViewEntry(ItemAnalysisArea: Enum "Analysis Area Type"; ItemAnalysisViewCode: Code[10]; ItemNo: Code[20]; Dim1ValueCode: Code[20]): Decimal
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        ItemAnalysisViewEntry.Init();
        ItemAnalysisViewEntry."Analysis Area" := ItemAnalysisArea;
        ItemAnalysisViewEntry."Analysis View Code" := ItemAnalysisViewCode;
        ItemAnalysisViewEntry."Item No." := ItemNo;
        ItemAnalysisViewEntry."Posting Date" := WorkDate();
        ItemAnalysisViewEntry."Dimension 1 Value Code" := Dim1ValueCode;
        ItemAnalysisViewEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(ItemAnalysisViewEntry, ItemAnalysisViewEntry.FieldNo("Entry No."));
        ItemAnalysisViewEntry."Sales Amount (Actual)" := LibraryRandom.RandDec(100, 2);
        ItemAnalysisViewEntry.Insert();
        exit(ItemAnalysisViewEntry."Sales Amount (Actual)");
    end;

    local procedure CreateGroupOfDimensions(var Dimension: Record Dimension; var StandardDimValueCode: Code[20]; var TotalDimValueCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);

        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        StandardDimValueCode := DimensionValue.Code;
        CreateTotalDimensionValue(Dimension.Code, TotalDimValueCode);
    end;

    local procedure CreateTotalDimensionValue(DimensionCode: Code[20]; var TotalDimValueCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        FirstDimValueCode: Code[20];
        LastDimValueCode: Code[20];
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        TotalDimValueCode := DimensionValue.Code;

        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.FindFirst();
        FirstDimValueCode := DimensionValue.Code;
        DimensionValue.FindLast();
        LastDimValueCode := DimensionValue.Code;

        DimensionValue.Get(DimensionValue."Dimension Code", TotalDimValueCode);
        DimensionValue.Validate("Dimension Value Type", DimensionValue."Dimension Value Type"::Total);
        DimensionValue.Validate(Totaling, StrSubstNo('%1..%2', FirstDimValueCode, LastDimValueCode));
        DimensionValue.Modify(true);
    end;

    local procedure CreateSalespersonWithDefaultDim(var SalespersonPurchaser: Record "Salesperson/Purchaser"; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.Code, DimensionCode, DimensionValueCode);
    end;

    local procedure UpdateGLSetupAddCurrency(CurrencyCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Additional Reporting Currency" := CurrencyCode;
        GLSetup.Modify(true);
    end;

    local procedure GetNextItemDefaultDims(var Item: Record Item; Steps: Integer)
    var
        DefaultDim: Record "Default Dimension";
    begin
        DefaultDim.SetRange("Table ID", DATABASE::Item);
        Item.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        Item.Next(Steps);
        repeat
            DefaultDim.SetRange("No.", Item."No.");
            if DefaultDim.IsEmpty() then
                exit;
        until Item.Next() = 0;
    end;

    local procedure SaveValsForAnalysisMarix(Amount: Decimal; ColumnNo: Integer; LineNo: Integer)
    begin
        LibraryVariableStorage.Enqueue(Amount);
        LibraryVariableStorage.Enqueue(ColumnNo);
        LibraryVariableStorage.Enqueue(LineNo);
    end;

    local procedure FindJournalBatchAndTemplate(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure FindItemAnalysisViewEntry(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; SourceNo: Code[20]; ItemNo: Code[20]; AnalysisViewCode: Code[10])
    begin
        ItemAnalysisViewEntry.SetRange("Source No.", SourceNo);
        ItemAnalysisViewEntry.SetRange("Item No.", ItemNo);
        ItemAnalysisViewEntry.SetRange("Analysis View Code", AnalysisViewCode);
    end;

    local procedure OpenAnalysisByDimensionMatrix("Code": Code[10]; ShowOppositeSign: Boolean; ShowInAddCurr: Boolean; RoundingFactor: Text[30])
    begin
        OpenAnalysisByDimensionMatrixWithLineDimCode(
          Code, ShowOppositeSign, ShowInAddCurr, RoundingFactor, Format(LineDimOptionRef::"G/L Account"),
          ClosingDateOptions::Include, ShowAmounts::"Actual Amounts", '');
    end;

    local procedure OpenAnalysisByDimensionMatrixWithLineDimCode("Code": Code[10]; ShowOppositeSign: Boolean; ShowInAddCurr: Boolean; RoundingFactor: Text[30]; LineDimCode: Text[30]; ClosingDates: Option; Amounts: Option; Dim1Filter: Code[250])
    var
        AnalysisViewList: TestPage "Analysis View List";
        AnalysisbyDimensions: TestPage "Analysis by Dimensions";
        PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        AnalysisViewList.OpenView();
        AnalysisViewList.FILTER.SetFilter(Code, Code);
        AnalysisViewList."&Update".Invoke();
        AnalysisbyDimensions.Trap();
        AnalysisViewList.EditAnalysis.Invoke();
        AnalysisbyDimensions.RoundingFactor.SetValue(RoundingFactor);
        AnalysisbyDimensions.ShowOppositeSign.SetValue(ShowOppositeSign);
        AnalysisbyDimensions.ShowInAddCurr.SetValue(ShowInAddCurr);
        AnalysisbyDimensions.ColumnDimCode.SetValue(ColumnDimOptionRef::Period);
        AnalysisbyDimensions.PeriodType.SetValue(PeriodType::Day);
        AnalysisbyDimensions.Dim1Filter.SetValue(Dim1Filter);
        AnalysisbyDimensions.LineDimCode.SetValue(LineDimCode);
        AnalysisbyDimensions.ClosingEntryFilter.SetValue(ClosingDates);
        AnalysisbyDimensions.ShowActualBudg.SetValue(Amounts);
        AnalysisbyDimensions.ShowMatrix.Invoke();
    end;

    local procedure OpenEditSalesAnalysisView(var AnalysisViewListSales: TestPage "Analysis View List Sales"; AnalysisViewCode: Code[10])
    begin
        AnalysisViewListSales.OpenEdit();
        AnalysisViewListSales.FILTER.SetFilter(Code, AnalysisViewCode);
        AnalysisViewListSales.EditAnalysisView.Invoke();
    end;

    local procedure OpenEditPurchAnalysisView(var AnalysisViewListPurchase: TestPage "Analysis View List Purchase"; AnalysisViewCode: Code[10])
    begin
        AnalysisViewListPurchase.OpenEdit();
        AnalysisViewListPurchase.FILTER.SetFilter(Code, AnalysisViewCode);
        AnalysisViewListPurchase.EditAnalysisView.Invoke();
    end;

    local procedure OpenGLBalancebyDimMatrix(GLAccountNo: Code[20]; ColumnDimCode: Code[20]; Dim1FilterText: Text)
    var
        GLAccountCard: TestPage "G/L Account Card";
        GLBalancebyDimension: TestPage "G/L Balance by Dimension";
    begin
        GLAccountCard.OpenView();
        GLAccountCard.FILTER.SetFilter("No.", GLAccountNo);
        GLBalancebyDimension.Trap();
        GLAccountCard."G/L Balance by &Dimension".Invoke();
        GLBalancebyDimension.LineDimCode.SetValue('G/L Account');
        GLBalancebyDimension.AmountField.SetValue('Amount');
        GLBalancebyDimension.GLAccFilter.SetValue(GLAccountNo);
        GLBalancebyDimension.ColumnDimCode.SetValue(ColumnDimCode);
        GLBalancebyDimension.DateFilter.SetValue('');
        GLBalancebyDimension.Dim1Filter.SetValue(Dim1FilterText);
        GLBalancebyDimension.ShowMatrix.Invoke();
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure SetAmountDecimalPlaces(DecimalPlaces: Text[5])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Amount Decimal Places", DecimalPlaces);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure SetFiltersWithItemOnSalesAnalysisDimensionsPage(var SalesAnalysisByDimensions: TestPage "Sales Analysis by Dimensions"; LineDimCode: Text[30]; ColumnDimCode: Text[30]; ItemFilter: Text[50])
    begin
        SalesAnalysisByDimensions.LineDimCode.SetValue(LineDimCode);
        SalesAnalysisByDimensions.ItemFilter.SetValue(ItemFilter);
        SalesAnalysisByDimensions.ColumnDimCode.SetValue(ColumnDimCode);
    end;

    local procedure SetFiltersWithItemOnPurchAnalysisDimensionsPage(var PurchAnalysisbyDimensions: TestPage "Purch. Analysis by Dimensions"; LineDimCode: Text[30]; ColumnDimCode: Text[30]; ItemNo: Code[20])
    begin
        PurchAnalysisbyDimensions.LineDimCode.SetValue(LineDimCode);
        PurchAnalysisbyDimensions.ItemFilter.SetValue(ItemNo);
        PurchAnalysisbyDimensions.ColumnDimCode.SetValue(ColumnDimCode);
    end;

    local procedure VerifyGLBalancebyDimMatrix(No: Code[20]; RoundingFactor: Text[30])
    var
        GLAccountCard: TestPage "G/L Account Card";
        GLBalancebyDimension: TestPage "G/L Balance by Dimension";
    begin
        GLAccountCard.OpenView();
        GLAccountCard.FILTER.SetFilter("No.", No);
        GLBalancebyDimension.Trap();
        GLAccountCard."G/L Balance by &Dimension".Invoke();
        GLBalancebyDimension.LineDimCode.SetValue('G/L Account');  // Added string for make sure always Show as Line for G/L Account only.
        GLBalancebyDimension.AmountField.SetValue('Amount');  // Added string for make sure always Show Amount.. as Amount only.
        GLBalancebyDimension.RoundingFactor.SetValue(RoundingFactor);
        GLBalancebyDimension.GLAccFilter.SetValue(No);
        GLBalancebyDimension.ShowMatrix.Invoke();
    end;

    local procedure VerifyItemAnalysisViewEntry(SalesLine: Record "Sales Line"; ItemAnalysisViewCode: Code[10])
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        FindItemAnalysisViewEntry(ItemAnalysisViewEntry, SalesLine."Sell-to Customer No.", SalesLine."No.", ItemAnalysisViewCode);
        ItemAnalysisViewEntry.FindFirst();
        ItemAnalysisViewEntry.TestField("Sales Amount (Actual)", SalesLine."Line Amount");
    end;

    local procedure VerifyLookupInAccountScheduleOverview(LookupControlID: Integer; LookupValue: Code[10])
    var
        FinancialReport: Record "Financial Report";
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
        AccountScheduleNames: TestPage "Financial Reports";
    begin
        // Verify: Open Account Schedule Overview and try to lookup value for control
        FinancialReport.FindFirst();
        AccountScheduleNames.OpenView();
        AccountScheduleNames.FILTER.SetFilter(Name, FinancialReport.Name);
        AccScheduleOverview.Trap();
        AccountScheduleNames.Overview.Invoke();
        LibraryVariableStorage.Enqueue(LookupValue);

        case LookupControlID of
            GLBudgetFilterControlId:
                begin
                    AccScheduleOverview."G/LBudgetFilter".Lookup();
                    Assert.AreEqual(LookupValue, AccScheduleOverview."G/LBudgetFilter".Value, WrongValueAfterLookupErr);
                end;
            CostBudgetFilterControlId:
                begin
                    AccScheduleOverview.CostBudgetFilter.Lookup();
                    Assert.AreEqual(LookupValue, AccScheduleOverview.CostBudgetFilter.Value, WrongValueAfterLookupErr);
                end;
            else
                Assert.Fail(StrSubstNo('Unexpected Lookup control ID - %1', Format(LookupControlID)));
        end;
    end;

    local procedure VerifyNoOfAnalysisViewEntry(AnalysisViewCode: Code[20]; Dimension1Value: Code[20]; AccountNo: Code[20]; ExpectedNoOfEntries: Integer)
    var
        AnalysisViewEntry: Record "Analysis View Entry";
    begin
        AnalysisViewEntry.SetRange("Analysis View Code", AnalysisViewCode);
        AnalysisViewEntry.SetRange("Dimension 1 Value Code", Dimension1Value);
        AnalysisViewEntry.SetRange("Account No.", AccountNo);
        Assert.AreEqual(ExpectedNoOfEntries, AnalysisViewEntry.Count, WrongNumberOfAnalysisViewEntriesErr);
    end;

    local procedure VerifyTestValidationError()
    begin
        Assert.ExpectedErrorCode('TestValidation');
        Assert.ExpectedError('Validation error for Field');
    end;

    [Scope('OnPrem')]
    procedure CreatePostAndVerifyPurchaseOrderForServiceOrNonStockItem(ItemAnalysisView: Record "Item Analysis View"; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        // [GIVEN] Purchase Order. Item of Type::Service.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo);

        // [GIVEN] First step of posting: post receipt and update analysis view
        PostPurchaseDocAndUpdateItemAnalysisView(PurchaseHeader, ItemAnalysisView, true, false); // receipt

        // [WHEN] Second step of posting: post invoice and update analysis view
        PostPurchaseDocAndUpdateItemAnalysisView(PurchaseHeader, ItemAnalysisView, false, true); // invoice

        FindItemAnalysisViewEntry(ItemAnalysisViewEntry, PurchaseLine."Buy-from Vendor No.", PurchaseLine."No.", ItemAnalysisView.Code);
        ItemAnalysisViewEntry.FindFirst();

        // [THEN] "Cost Amount (Non-Invtbl.)" on Item Analysis View Entry is equal to Purchase Line Amount.
        Assert.AreEqual(PurchaseLine.Amount, ItemAnalysisViewEntry."Cost Amount (Non-Invtbl.)", WrongCostAmountNonInvtblErr);
    end;

    local procedure CreateAnalysisViewBudgetEntry(PostingDate: Date; AnalysisViewCode: Code[10]; GLAccountNo: Code[20]): Decimal
    var
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
    begin
        AnalysisViewBudgetEntry.Init();
        AnalysisViewBudgetEntry."Analysis View Code" := AnalysisViewCode;
        AnalysisViewBudgetEntry."G/L Account No." := GLAccountNo;
        AnalysisViewBudgetEntry."Posting Date" := PostingDate;
        AnalysisViewBudgetEntry.Amount := LibraryRandom.RandDec(1000, 2);
        AnalysisViewBudgetEntry.Insert();

        exit(AnalysisViewBudgetEntry.Amount);
    end;

    local procedure FindLastFYClosingDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetCurrentKey("New Fiscal Year");
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.FindLast();
        exit(ClosingDate(AccountingPeriod."Starting Date" - 1));
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        // Take Random Quantity for Purchase Line.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        // Take Random Direct Unit Cost for Purchase Line.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure PostPurchaseDocAndUpdateItemAnalysisView(var PurchaseHeader: Record "Purchase Header"; var ItemAnalysisView: Record "Item Analysis View"; ToShipReceive: Boolean; ToInvoice: Boolean)
    begin
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ToShipReceive, ToInvoice);
        CODEUNIT.Run(CODEUNIT::"Update Item Analysis View", ItemAnalysisView);
    end;

    local procedure CreateItemTypeServiceOrNonStockAnalysisView(var ItemAnalysisView: Record "Item Analysis View"; AnalysisArea: Enum "Analysis Area Type"; UpdateOnPosting: Boolean; IsService: Boolean) ItemNo: Code[20]
    begin
        if IsService then
            ItemNo := CreateItemTypeService()
        else
            ItemNo := CreateItemTypeNonStock();
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, AnalysisArea);
        ItemAnalysisView.Validate("Update on Posting", UpdateOnPosting);
        ItemAnalysisView.Validate("Item Filter", ItemNo);
        ItemAnalysisView.Modify(true);
    end;

    local procedure CreateItemTypeService(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemTypeNonStock(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure UpdateDimensionInAnalysisView(var AnalysisView: Record "Analysis View"; GLAccountNo: Code[20]; DimensionCode: Code[20])
    begin
        AnalysisView.Validate("Account Source", AnalysisView."Account Source"::"G/L Account");
        AnalysisView.Validate("Account Filter", GLAccountNo);
        AnalysisView.Validate("Dimension 1 Code", DimensionCode);
        AnalysisView.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLEntriesPageHandler(var GeneralLedgerEntries: TestPage "General Ledger Entries")
    var
        Counter: Integer;
    begin
        if GeneralLedgerEntries.Last() then
            repeat
                Counter += 1;
            until not GeneralLedgerEntries.Previous();

        Assert.AreNotEqual(0, Counter, WrongGLEntryLinesErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixPageHandler(var AnalysisbyDimensionsMatrix: TestPage "Analysis by Dimensions Matrix")
    begin
        AnalysisbyDimensionsMatrix.TotalAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixEnqueTotalPageHandler(var AnalysisbyDimensionsMatrix: TestPage "Analysis by Dimensions Matrix")
    begin
        LibraryVariableStorage.Enqueue(AnalysisbyDimensionsMatrix.TotalAmount.Value());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionMatrixTwoLinesPageHandler(var AnalysisbyDimensionsMatrix: TestPage "Analysis by Dimensions Matrix")
    begin
        AnalysisbyDimensionsMatrix.TotalAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        AnalysisbyDimensionsMatrix.Next();
        AnalysisbyDimensionsMatrix.TotalAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        AnalysisbyDimensionsMatrix.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        AnalysisbyDimensionsMatrix.First();
        AnalysisbyDimensionsMatrix.Field1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        AnalysisbyDimensionsMatrix.Field2.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Assert.IsFalse(AnalysisbyDimensionsMatrix.Next(), NoLineShouldBeFoundErr);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AccScheduleOverviewPageHandler(var AccScheduleOverview: TestPage "Acc. Schedule Overview")
    var
        RowNo: Variant;
        CurrentColumnName: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrentColumnName);
        LibraryVariableStorage.Dequeue(RowNo);
        AccScheduleOverview.CurrentColumnName.SetValue(CurrentColumnName);
        AccScheduleOverview.UseAmtsInAddCurr.SetValue(LibraryVariableStorage.DequeueBoolean());
        AccScheduleOverview."Row No.".AssertEquals(RowNo);
        AccScheduleOverview.ColumnValues1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        AccScheduleOverview.UseAmtsInAddCurr.SetValue(false);
        AccScheduleOverview.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLBalancebyDimMatrixPageHandler(var GLBalancebyDimMatrix: TestPage "G/L Balance by Dim. Matrix")
    begin
        GLBalancebyDimMatrix.TotalAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLEntriesDimOvervMatrixPageHandler(var GLEntriesDimOvervMatrix: TestPage "G/L Entries Dim. Overv. Matrix")
    begin
        GLEntriesDimOvervMatrix.FILTER.SetFilter("G/L Account No.", LibraryVariableStorage.DequeueText());
        GLEntriesDimOvervMatrix.Amount.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimMatrixPageHandler(var SalesAnalysisbyDimMatrix: TestPage "Sales Analysis by Dim Matrix")
    begin
        SalesAnalysisbyDimMatrix.TotalQuantity.AssertEquals(-LibraryVariableStorage.DequeueDecimal());
        SalesAnalysisbyDimMatrix.TotalInvtValue.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimMatrixMultiItemsPageHandler(var SalesAnalysisbyDimMatrix: TestPage "Sales Analysis by Dim Matrix")
    var
        TotalQuantityVar: Variant;
        TotalAmount: Variant;
        TotalQuantity: Decimal;
    begin
        // Dequeue variable.
        LibraryVariableStorage.Dequeue(TotalQuantityVar);
        LibraryVariableStorage.Dequeue(TotalAmount);
        Evaluate(TotalQuantity, Format(TotalQuantityVar));
        // Verifying the values on Sales Analysis by Dim Matrix page.
        SalesAnalysisbyDimMatrix.TotalQuantity.AssertEquals(-TotalQuantity);
        SalesAnalysisbyDimMatrix.TotalInvtValue.AssertEquals(TotalAmount);
        SalesAnalysisbyDimMatrix.Field1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimMatrixPeriodFiltersPageHandler(var SalesAnalysisbyDimMatrix: TestPage "Sales Analysis by Dim Matrix")
    var
        AmountVar: Variant;
        ColumnNoVar: Variant;
        LineNoVar: Variant;
        Amount: Decimal;
        ColumnNo: Integer;
        LineNo: Integer;
    begin
        // Dequeue variables - Column No. and Amount that should be in that column
        LibraryVariableStorage.Dequeue(AmountVar);
        Evaluate(Amount, Format(AmountVar));
        LibraryVariableStorage.Dequeue(ColumnNoVar);
        Evaluate(ColumnNo, Format(ColumnNoVar));
        LibraryVariableStorage.Dequeue(LineNoVar);
        Evaluate(LineNo, Format(LineNoVar));

        SalesAnalysisbyDimMatrix.First();
        while LineNo > 1 do begin
            SalesAnalysisbyDimMatrix.Next();
            LineNo -= 1;
        end;

        // Verifying the values on Sales Analysis by Dim Matrix page.
        case ColumnNo of
            1:
                SalesAnalysisbyDimMatrix.Field1.AssertEquals(Amount);
            2:
                SalesAnalysisbyDimMatrix.Field2.AssertEquals(Amount);
            3:
                SalesAnalysisbyDimMatrix.Field3.AssertEquals(Amount);
            4:
                SalesAnalysisbyDimMatrix.Field4.AssertEquals(Amount);
            5:
                SalesAnalysisbyDimMatrix.Field5.AssertEquals(Amount);
            6:
                SalesAnalysisbyDimMatrix.Field6.AssertEquals(Amount);
            7:
                SalesAnalysisbyDimMatrix.Field7.AssertEquals(Amount);
            8:
                SalesAnalysisbyDimMatrix.Field8.AssertEquals(Amount);
            9:
                SalesAnalysisbyDimMatrix.Field9.AssertEquals(Amount);
            10:
                SalesAnalysisbyDimMatrix.Field10.AssertEquals(Amount);
            11:
                SalesAnalysisbyDimMatrix.Field11.AssertEquals(Amount);
            12:
                SalesAnalysisbyDimMatrix.Field12.AssertEquals(Amount);
            13:
                SalesAnalysisbyDimMatrix.Field13.AssertEquals(Amount);
            14:
                SalesAnalysisbyDimMatrix.Field14.AssertEquals(Amount);
            15:
                SalesAnalysisbyDimMatrix.Field15.AssertEquals(Amount);
            16:
                SalesAnalysisbyDimMatrix.Field16.AssertEquals(Amount);
            17:
                SalesAnalysisbyDimMatrix.Field17.AssertEquals(Amount);
            18:
                SalesAnalysisbyDimMatrix.Field18.AssertEquals(Amount);
            19:
                SalesAnalysisbyDimMatrix.Field19.AssertEquals(Amount);
            20:
                SalesAnalysisbyDimMatrix.Field20.AssertEquals(Amount);
            21:
                SalesAnalysisbyDimMatrix.Field21.AssertEquals(Amount);
            22:
                SalesAnalysisbyDimMatrix.Field22.AssertEquals(Amount);
            23:
                SalesAnalysisbyDimMatrix.Field23.AssertEquals(Amount);
            24:
                SalesAnalysisbyDimMatrix.Field24.AssertEquals(Amount);
            25:
                SalesAnalysisbyDimMatrix.Field25.AssertEquals(Amount);
            26:
                SalesAnalysisbyDimMatrix.Field26.AssertEquals(Amount);
            27:
                SalesAnalysisbyDimMatrix.Field27.AssertEquals(Amount);
            28:
                SalesAnalysisbyDimMatrix.Field28.AssertEquals(Amount);
            29:
                SalesAnalysisbyDimMatrix.Field29.AssertEquals(Amount);
            30:
                SalesAnalysisbyDimMatrix.Field30.AssertEquals(Amount);
            31:
                SalesAnalysisbyDimMatrix.Field31.AssertEquals(Amount);
            32:
                SalesAnalysisbyDimMatrix.Field32.AssertEquals(Amount);
            else
                Assert.Fail(CheckColIndexErr);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchAnalysisbyDimMatrixPeriodFiltersPageHandler(var PurchAnalysisbyDimMatrix: TestPage "Purch. Analysis by Dim Matrix")
    var
        AmountVar: Variant;
        ColumnNoVar: Variant;
        LineNoVar: Variant;
        Amount: Decimal;
        ColumnNo: Integer;
        LineNo: Integer;
    begin
        // Dequeue variables - Column No. and Amount that should be in that column
        LibraryVariableStorage.Dequeue(AmountVar);
        Evaluate(Amount, Format(AmountVar));
        LibraryVariableStorage.Dequeue(ColumnNoVar);
        Evaluate(ColumnNo, Format(ColumnNoVar));
        LibraryVariableStorage.Dequeue(LineNoVar);
        Evaluate(LineNo, Format(LineNoVar));

        PurchAnalysisbyDimMatrix.First();
        while LineNo > 1 do begin
            PurchAnalysisbyDimMatrix.Next();
            LineNo -= 1;
        end;

        // Verifying the values on Sales Analysis by Dim Matrix page.
        case ColumnNo of
            1:
                PurchAnalysisbyDimMatrix.Field1.AssertEquals(Amount);
            2:
                PurchAnalysisbyDimMatrix.Field2.AssertEquals(Amount);
            3:
                PurchAnalysisbyDimMatrix.Field3.AssertEquals(Amount);
            4:
                PurchAnalysisbyDimMatrix.Field4.AssertEquals(Amount);
            5:
                PurchAnalysisbyDimMatrix.Field5.AssertEquals(Amount);
            6:
                PurchAnalysisbyDimMatrix.Field6.AssertEquals(Amount);
            7:
                PurchAnalysisbyDimMatrix.Field7.AssertEquals(Amount);
            8:
                PurchAnalysisbyDimMatrix.Field8.AssertEquals(Amount);
            9:
                PurchAnalysisbyDimMatrix.Field9.AssertEquals(Amount);
            10:
                PurchAnalysisbyDimMatrix.Field10.AssertEquals(Amount);
            11:
                PurchAnalysisbyDimMatrix.Field11.AssertEquals(Amount);
            12:
                PurchAnalysisbyDimMatrix.Field12.AssertEquals(Amount);
            13:
                PurchAnalysisbyDimMatrix.Field13.AssertEquals(Amount);
            14:
                PurchAnalysisbyDimMatrix.Field14.AssertEquals(Amount);
            15:
                PurchAnalysisbyDimMatrix.Field15.AssertEquals(Amount);
            16:
                PurchAnalysisbyDimMatrix.Field16.AssertEquals(Amount);
            17:
                PurchAnalysisbyDimMatrix.Field17.AssertEquals(Amount);
            18:
                PurchAnalysisbyDimMatrix.Field18.AssertEquals(Amount);
            19:
                PurchAnalysisbyDimMatrix.Field19.AssertEquals(Amount);
            20:
                PurchAnalysisbyDimMatrix.Field20.AssertEquals(Amount);
            21:
                PurchAnalysisbyDimMatrix.Field21.AssertEquals(Amount);
            22:
                PurchAnalysisbyDimMatrix.Field22.AssertEquals(Amount);
            23:
                PurchAnalysisbyDimMatrix.Field23.AssertEquals(Amount);
            24:
                PurchAnalysisbyDimMatrix.Field24.AssertEquals(Amount);
            25:
                PurchAnalysisbyDimMatrix.Field25.AssertEquals(Amount);
            26:
                PurchAnalysisbyDimMatrix.Field26.AssertEquals(Amount);
            27:
                PurchAnalysisbyDimMatrix.Field27.AssertEquals(Amount);
            28:
                PurchAnalysisbyDimMatrix.Field28.AssertEquals(Amount);
            29:
                PurchAnalysisbyDimMatrix.Field29.AssertEquals(Amount);
            30:
                PurchAnalysisbyDimMatrix.Field30.AssertEquals(Amount);
            31:
                PurchAnalysisbyDimMatrix.Field31.AssertEquals(Amount);
            32:
                PurchAnalysisbyDimMatrix.Field32.AssertEquals(Amount);
            else
                Assert.Fail(CheckColIndexErr);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLBalanceDimMatrixPageHandler(var GLBalancebyDimMatrix: TestPage "G/L Balance by Dim. Matrix")
    begin
        Assert.IsTrue(GLBalancebyDimMatrix.Field1.Visible(), FieldMustBeVisibleErr);
        Assert.IsTrue(GLBalancebyDimMatrix.Field2.Visible(), FieldMustBeVisibleErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field3.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field4.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field5.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field6.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field7.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field8.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field9.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field10.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field11.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field12.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field13.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field14.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field15.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field16.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field17.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field18.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field19.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field20.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field21.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field22.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field23.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field24.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field25.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field26.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field27.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field28.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field29.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field30.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field31.Visible(), FieldMustBeHiddenErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field32.Visible(), FieldMustBeHiddenErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLBalanceDimMatrixGlobalDim12ValueAsColumnPageHandler2(var GLBalancebyDimMatrix: TestPage "G/L Balance by Dim. Matrix")
    begin
        Assert.IsTrue(GLBalancebyDimMatrix.Field1.Visible(), FieldMustBeVisibleErr);
        Assert.IsFalse(GLBalancebyDimMatrix.Field2.Visible(), FieldMustBeHiddenErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimMatrixPageDrillDownPageHandler(var SalesAnalysisbyDimMatrix: TestPage "Sales Analysis by Dim Matrix")
    begin
        SalesAnalysisbyDimMatrix.Field1.DrillDown();
        SalesAnalysisbyDimMatrix.Field2.DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchAnalysisbyDimMatrixPageDrillDownPageHandler(var PurchAnalysisbyDimMatrix: TestPage "Purch. Analysis by Dim Matrix")
    begin
        PurchAnalysisbyDimMatrix.Field1.DrillDown();
        PurchAnalysisbyDimMatrix.Field2.DrillDown();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisbyDimensionsPageHandler(var SalesAnalysisbyDimensions: TestPage "Sales Analysis by Dimensions")
    var
        DimensionCode: Variant;
        DimensionValueCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionCode);
        LibraryVariableStorage.Dequeue(DimensionValueCode);
        SalesAnalysisbyDimensions.ColumnDimCode.SetValue(DimensionCode);
        SalesAnalysisbyDimensions.ColumnSet.AssertEquals(DimensionValueCode);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemAnalysisViewEntryPageHandler(var ItemAnalysisViewEntries: TestPage "Item Analysis View Entries")
    begin
        ItemAnalysisViewEntries."Sales Amount (Actual)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLBudgetNamesHandler(var GLBudgetNames: TestPage "G/L Budget Names")
    var
        NameVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(NameVar);
        GLBudgetNames.FILTER.SetFilter(Name, NameVar);
        GLBudgetNames.First();
        GLBudgetNames.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CostBudgetNamesHandler(var CostBudgetNames: TestPage "Cost Budget Names")
    var
        NameVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(NameVar);
        CostBudgetNames.FILTER.SetFilter(Name, NameVar);
        CostBudgetNames.First();
        CostBudgetNames.OK().Invoke();
    end;

    [ModalPageHandler]
    [HandlerFunctions('AnalysisViewPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisbyDimensionsMatrixPageHandlerTotalAmountDrill(var AnalysisbyDimensionsMatrix: TestPage "Analysis by Dimensions Matrix")
    begin
        AnalysisbyDimensionsMatrix.TotalAmount.DrillDown();
    end;

    [PageHandler]
    [HandlerFunctions('GeneralLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewPageHandler(var AnalysisViewEntries: TestPage "Analysis View Entries")
    begin
        AnalysisViewEntries.Amount.Lookup();
    end;

    [ModalPageHandler]
    [HandlerFunctions('GLEntriesDimensionOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure GeneralLedgerEntriesPageHandler(var GeneralLedgerEntries: TestPage "General Ledger Entries")
    begin
        GeneralLedgerEntries.GLDimensionOverview.Invoke();
    end;

    [PageHandler]
    [HandlerFunctions('GLEntriesDimOvervMatrixVerifyCountPageHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesDimensionOverviewPageHandler(var GLEntriesDimensionOverview: TestPage "G/L Entries Dimension Overview")
    begin
        GLEntriesDimensionOverview.ShowMatrix.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLEntriesDimOvervMatrixVerifyCountPageHandler(var GLEntriesDimOvervMatrix: TestPage "G/L Entries Dim. Overv. Matrix")
    var
        Counter: Integer;
    begin
        GLEntriesDimOvervMatrix.Last();
        repeat
            Counter += 1;
        until not GLEntriesDimOvervMatrix.Previous();
        Assert.AreEqual(LibraryVariableStorage.DequeueDecimal(), Counter, WrongGLEntryLinesErr);
    end;
}

