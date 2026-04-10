codeunit 134236 "ERM Analysis View Excel Export"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Analysis View] [Excel]
    end;

    var
        ExcelBuffer: Record "Excel Buffer";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCashFlow: Codeunit "Library - Cash Flow";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Assert: Codeunit Assert;
        ClosingEntryFilter: Option Include,Exclude;
        IncorrectValueInCellOnWorksheetErr: Label 'Incorrect value on worksheet %1 in cell R%2 C%3', Comment = '%1 - row % 2 - column';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AnalysisViewGeneralInfo()
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        DimensionValue: array[4] of Record "Dimension Value";
        ServerFileName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Verification of exported general info sheet data

        // [GIVEN] 4 new dimensions with values
        CreateDimsWithValuesForAnalysisView(DimensionValue);
        // [GIVEN] Analysis View with 4 dimensions
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account", DimensionValue);

        // [GIVEN] Mock last date updated
        AnalysisView."Last Date Updated" := Today;
        AnalysisView.Modify();

        // [GIVEN] Mock analysis view entry
        CreateAnalysisViewEntryWithDimension(
          AnalysisView, AnalysisViewEntry, LibraryERM.CreateGLAccountNo(), DimensionValue,
          WorkDate());

        // [GIVEN] Use 4 dimensions values as a filters
        // [WHEN] Analisys View is being exported
        ServerFileName :=
          AnalysisViewExportToExcelGeneral(
            AnalysisView, "Analysis Show Amount Field"::Amount, '', '', '',
            DimensionValue[1].Code, DimensionValue[2].Code, DimensionValue[3].Code, DimensionValue[4].Code,
            "Analysis Amount Type"::"Balance at Date", ClosingEntryFilter::Exclude, "Analysis Show Amount Type"::"Actual Amounts", '');

        // [THEN] Analysis View general info exported to sheet "General Info"
        VerifyAnalysisVeiwGeneralInfoSheet(ServerFileName, AnalysisViewEntry, DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AnalysisViewDataSheetColumnCaptions()
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        DimensionValue: array[4] of Record "Dimension Value";
        GLAccountNo: array[5] of Code[20];
        DimValueCode: array[5] of Code[20];
        ServerFileName: Text;
        GLAccountFilter: Text;
        MaxGLAccountLevel: Integer;
        MaxDimLevel: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Export with indented G/L Account and indented dimensions makes proper column captions on data sheet

        // [GIVEN] G/L Account with indentation MaxLevel
        GLAccount.DeleteAll();
        MaxGLAccountLevel := LibraryRandom.RandIntInRange(2, 5);
        GLAccountFilter := CreateIndentedGLAccount(MaxGLAccountLevel, GLAccountNo);

        // [GIVEN] New dimension DIM with intended values
        MaxDimLevel := LibraryRandom.RandIntInRange(2, 5);
        CreateIndentedDimension(Dimension, MaxDimLevel, DimValueCode);

        // [GIVEN] Analysis View with dimension DIM
        DimensionValue[1].Get(Dimension.Code, DimValueCode[3]);
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account", DimensionValue);

        // [GIVEN] Mock analysis view entry
        CreateAnalysisViewEntryWithDimension(
          AnalysisView, AnalysisViewEntry, GLAccountNo[3], DimensionValue,
          WorkDate());

        // [WHEN] Analisys View is being exported
        ServerFileName :=
          AnalysisViewExportToExcelGeneral(
            AnalysisView, "Analysis Show Amount Field"::Amount, '', GLAccountFilter, '', '', '', '', '',
            "Analysis Amount Type"::"Balance at Date", ClosingEntryFilter::Exclude, "Analysis Show Amount Type"::"Actual Amounts", '');

        // [THEN] Excel data sheet contains proper columns captions
        VerifyAnalysisViewColumnCaptions(ServerFileName, MaxGLAccountLevel, MaxDimLevel, Dimension.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ZeroIdentationGLAccountFourSimpleDimensions()
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        DimensionValue: array[4] of Record "Dimension Value";
        GLAccountNo: Code[20];
        ServerFileName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Export analysis view entry with zero identation G/L Account and 4 single-level-dimentions

        // [GIVEN] Single-level G/L Account
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] 4 new dimensions with values
        CreateDimsWithValuesForAnalysisView(DimensionValue);
        // [GIVEN] Analysis View with 4 dimensions
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account", DimensionValue);

        // [GIVEN] Mock analysis view entry
        CreateAnalysisViewEntryWithDimension(
          AnalysisView, AnalysisViewEntry, GLAccountNo, DimensionValue,
          WorkDate());

        // [WHEN] Analisys View is being exported
        ServerFileName :=
          AnalysisViewExportToExcelGeneral(
            AnalysisView, "Analysis Show Amount Field"::Amount, '', GLAccountNo, '', '', '', '', '',
            "Analysis Amount Type"::"Balance at Date", ClosingEntryFilter::Exclude, "Analysis Show Amount Type"::"Actual Amounts", '');

        // [THEN] Analysis View Entry exported to excel
        VerifyExportedAnalysisEntryWithSimpleDimensions(ServerFileName, AnalysisViewEntry, GLAccountNo, DimensionValue);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure MultiLevelGLAccountFourSimpleDimensions()
    var
        GLAccount: Record "G/L Account";
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        DimensionValue: array[4] of Record "Dimension Value";
        GLAccountNo: array[5] of Code[20];
        ServerFileName: Text;
        MaxGLAccountLevel: Integer;
        GLAccountFilter: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Export analysis view entry with multi-level G/L Account and 4 single-level-dimentions

        // [GIVEN] G/L Account with indentation MaxLevel
        GLAccount.DeleteAll();
        MaxGLAccountLevel := LibraryRandom.RandIntInRange(2, 5);
        GLAccountFilter := CreateIndentedGLAccount(MaxGLAccountLevel, GLAccountNo);

        // [GIVEN] 4 new dimensions with values
        CreateDimsWithValuesForAnalysisView(DimensionValue);
        // [GIVEN] Analysis View with 4 dimensions
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account", DimensionValue);

        // [GIVEN] Mock analysis view entry
        CreateAnalysisViewEntryWithDimension(
          AnalysisView, AnalysisViewEntry, GLAccountNo[MaxGLAccountLevel + 1], DimensionValue,
          WorkDate());

        // [WHEN] Analisys View is being exported
        ServerFileName :=
          AnalysisViewExportToExcelGeneral(
            AnalysisView, "Analysis Show Amount Field"::Amount, '', GLAccountFilter, '', '', '', '', '',
            "Analysis Amount Type"::"Balance at Date", ClosingEntryFilter::Exclude, "Analysis Show Amount Type"::"Actual Amounts", '');

        // [THEN] Analysis View Entry exported to excel with all parent accounts
        VerifyIndentedGLAccountSimpleDimensions(
          ServerFileName, AnalysisViewEntry, MaxGLAccountLevel, GLAccountNo, DimensionValue);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DifferentLevelGLAccounts()
    var
        GLAccount: Record "G/L Account";
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        DimensionValue: array[4] of Record "Dimension Value";
        GLAccountNo: array[4] of Code[20];
        ServerFileName: Text;
        GLAccountFilter: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Export analysis view entry with different identation level G/L Accounts and 4 single-level-dimentions

        // [GIVEN] Intermediate-level G/L Account with MaxLevel = n
        GLAccount.DeleteAll();
        GLAccountFilter := CreateDifferentLevelGLAccounts(GLAccountNo);

        // [GIVEN] 4 new dimensions with values
        CreateDimsWithValuesForAnalysisView(DimensionValue);
        // [GIVEN] Analysis View with 4 dimensions
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account", DimensionValue);

        // [GIVEN] Mock analysis view entry
        CreateAnalysisViewEntryWithDimension(
          AnalysisView, AnalysisViewEntry, GLAccountNo[2], DimensionValue,
          WorkDate());

        // [WHEN] Analisys View is being exported
        ServerFileName :=
          AnalysisViewExportToExcelGeneral(
            AnalysisView, "Analysis Show Amount Field"::Amount, '', GLAccountFilter, '', '', '', '', '',
            "Analysis Amount Type"::"Balance at Date", ClosingEntryFilter::Exclude, "Analysis Show Amount Type"::"Actual Amounts", '');

        // [THEN] Analysis View Entry exported to excel
        VerifyDIffIndentedAccountSimpleDimensions(
          ServerFileName, AnalysisViewEntry, GLAccountNo, DimensionValue, GLAccountFilter);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DifferentLevelCFAccounts()
    var
        CashFlowAccount: Record "Cash Flow Account";
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        DimensionValue: array[4] of Record "Dimension Value";
        CFAccountNo: array[4] of Code[20];
        ServerFileName: Text;
        CFAccountFilter: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Export analysis view entry with different identation level Cash Flow Accounts and 4 single-level-dimentions

        // [GIVEN] Intermediate-level G/L Account with MaxLevel = n
        CashFlowAccount.DeleteAll();
        CFAccountFilter := CreateDifferentLevelCFAccounts(CFAccountNo);

        // [GIVEN] 4 new dimensions with values
        CreateDimsWithValuesForAnalysisView(DimensionValue);
        // [GIVEN] Analysis View with 4 dimensions
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"Cash Flow Account", DimensionValue);

        // [GIVEN] Mock analysis view entry
        CreateAnalysisViewCFEntryWithDimension(
          AnalysisView, AnalysisViewEntry, CFAccountNo[2], DimensionValue,
          WorkDate());

        // [WHEN] Analisys View is being exported
        ServerFileName :=
          AnalysisViewExportToExcelGeneral(
            AnalysisView, "Analysis Show Amount Field"::Amount, '', CFAccountFilter, '', '', '', '', '',
            "Analysis Amount Type"::"Balance at Date", ClosingEntryFilter::Exclude, "Analysis Show Amount Type"::"Actual Amounts", '');

        // [THEN] Analysis View Entry exported to excel
        VerifyDIffIndentedAccountSimpleDimensions(
          ServerFileName, AnalysisViewEntry, CFAccountNo, DimensionValue, CFAccountFilter);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SimpleGLAccountIndentedDimension()
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        Dimension: Record Dimension;
        DimensionValue: array[4] of Record "Dimension Value";
        GLAccountNo: Code[20];
        DimValueCode: array[5] of Code[20];
        ServerFileName: Text;
        MaxDimLevel: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Export analysis view entry with zero identation G/L Account and indented dimention

        // [GIVEN] Single-level G/L Account
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] New dimension DIM with intended values
        MaxDimLevel := LibraryRandom.RandIntInRange(2, 5);
        CreateIndentedDimension(Dimension, MaxDimLevel, DimValueCode);

        // [GIVEN] Analysis View with dimension DIM
        DimensionValue[1].Get(Dimension.Code, DimValueCode[3]);
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account", DimensionValue);

        // [GIVEN] Mock analysis view entry
        CreateAnalysisViewEntryWithDimension(
          AnalysisView, AnalysisViewEntry, GLAccountNo, DimensionValue,
          WorkDate());

        // [WHEN] Analisys View is being exported
        ServerFileName :=
          AnalysisViewExportToExcelGeneral(
            AnalysisView, "Analysis Show Amount Field"::Amount, '', GLAccountNo, '', '', '', '', '',
            "Analysis Amount Type"::"Balance at Date", ClosingEntryFilter::Exclude, "Analysis Show Amount Type"::"Actual Amounts", '');

        // [THEN] Analysis View Entry exported to excel
        VerifyEntryWithIntededDimensions(ServerFileName, AnalysisViewEntry, GLAccountNo, DimValueCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SimpleGLAccountFourSimpleDimensionsBudgetEntry()
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
        DimensionValue: array[4] of Record "Dimension Value";
        GLAccountNo: Code[20];
        ServerFileName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Export analysis view budget entry with zero identation G/L Account and 4 single-level-dimentions

        // [GIVEN] Single-level G/L Account
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] 4 new dimensions with values
        CreateDimsWithValuesForAnalysisView(DimensionValue);
        // [GIVEN] Analysis View with 4 dimensions
        CreateAnalysisViewWithDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account", DimensionValue);

        // [GIVEN] Mock analysis view entry
        CreateAnalysisViewEntryWithDimension(
          AnalysisView, AnalysisViewEntry, GLAccountNo, DimensionValue,
          WorkDate());

        // [GIVEN] Mock analysis view budget entry
        CreateAnalysisViewBudgetEntryWithDimension(
          AnalysisView, AnalysisViewBudgetEntry, GLAccountNo, DimensionValue,
          WorkDate());

        // [WHEN] Analisys View is being exported
        ServerFileName :=
          AnalysisViewExportToExcelGeneral(
            AnalysisView, "Analysis Show Amount Field"::Amount, '', GLAccountNo, '', '', '', '', '',
            "Analysis Amount Type"::"Balance at Date", ClosingEntryFilter::Exclude, "Analysis Show Amount Type"::"Actual Amounts", '');

        // [THEN] Analysis View Budget Entry exported to excel
        VerifyBudgetEntryWithSimpleDimensions(ServerFileName, AnalysisViewBudgetEntry, GLAccountNo, DimensionValue);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ItemAnalysisViewGeneralInfo()
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        ServerFileName: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Verification of item analysis view exported general info sheet data

        // [GIVEN] 3 new dimensions with values
        CreateDimsWithValuesForItemAnalysisView(DimensionValue);
        // [GIVEN] Item Analysis View with 3 dimensions
        CreateItemAnalysisViewWithDimensions(ItemAnalysisView, DimensionValue);

        // [GIVEN] Mock last date updated
        ItemAnalysisView."Last Date Updated" := Today;
        ItemAnalysisView.Modify();

        // [GIVEN] Mock item analysis view entry
        CreateItemAnalysisViewEntryWithDimension(
          ItemAnalysisView, ItemAnalysisViewEntry, LibraryInventory.CreateItemNo(), DimensionValue,
          WorkDate(), CreateLocationCode());

        // [GIVEN] Use 3 dimensions values as a filters
        // [WHEN] Ietm Analisys View is being exported
        ServerFileName :=
          ItemAnalysisViewExportToExcelGeneral(
            ItemAnalysisView, '', '', '',
            DimensionValue[1].Code, DimensionValue[2].Code, DimensionValue[3].Code,
            ItemAnalysisViewEntry."Location Code");

        // [THEN] Item Analysis View general info exported to sheet "General Info"
        VerifyItemAnalysisViewGeneralInfoSheet(ServerFileName, ItemAnalysisViewEntry, DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ItemAnalysisViewDataSheetColumnCaptions()
    var
        Dimension: Record Dimension;
        ItemAnalysisView: Record "Item Analysis View";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        DimensionValue: array[3] of Record "Dimension Value";
        ItemNo: Code[20];
        DimValueCode: array[5] of Code[20];
        ServerFileName: Text;
        MaxDimLevel: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Export with indented G/L Account and indented dimensions makes proper column captions on data sheet

        // [GIVEN] New item
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] New dimension DIM with intended values
        MaxDimLevel := LibraryRandom.RandIntInRange(2, 5);
        CreateIndentedDimension(Dimension, MaxDimLevel, DimValueCode);

        // [GIVEN] Item Analysis View with dimension DIM
        DimensionValue[1].Get(Dimension.Code, DimValueCode[3]);
        CreateItemAnalysisViewWithDimensions(ItemAnalysisView, DimensionValue);

        // [GIVEN] Mock item analysis view entry
        CreateItemAnalysisViewEntryWithDimension(
          ItemAnalysisView, ItemAnalysisViewEntry, ItemNo, DimensionValue,
          WorkDate(), CreateLocationCode());

        // [WHEN] Item Analisys View is being exported
        ServerFileName :=
          ItemAnalysisViewExportToExcelGeneral(
            ItemAnalysisView, '', ItemNo, '',
            DimensionValue[1].Code, DimensionValue[2].Code, DimensionValue[3].Code,
            ItemAnalysisViewEntry."Location Code");

        // [THEN] Excel data sheet contains proper columns captions
        VerifyItemAnalysisViewColumnCaptions(ServerFileName, MaxDimLevel, Dimension.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ItemAnalysisViewEntryWithIndentedDimension()
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        Dimension: Record Dimension;
        DimensionValue: array[4] of Record "Dimension Value";
        ItemNo: Code[20];
        DimValueCode: array[5] of Code[20];
        ServerFileName: Text;
        MaxDimLevel: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Export item analysis view entry with indented dimention

        // [GIVEN] New item
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] New dimension DIM with intended values
        MaxDimLevel := LibraryRandom.RandIntInRange(2, 5);
        CreateIndentedDimension(Dimension, MaxDimLevel, DimValueCode);

        // [GIVEN] Item Analysis View with dimension DIM
        DimensionValue[1].Get(Dimension.Code, DimValueCode[3]);
        CreateItemAnalysisViewWithDimensions(ItemAnalysisView, DimensionValue);

        // [GIVEN] Mock item analysis view entry
        CreateItemAnalysisViewEntryWithDimension(
          ItemAnalysisView, ItemAnalysisViewEntry, ItemNo, DimensionValue,
          WorkDate(), CreateLocationCode());

        // [WHEN] Item Analisys View is being exported
        ServerFileName :=
          ItemAnalysisViewExportToExcelGeneral(
            ItemAnalysisView, '', ItemNo, '',
            DimensionValue[1].Code, DimensionValue[2].Code, DimensionValue[3].Code,
            ItemAnalysisViewEntry."Location Code");

        // [THEN] Analysis View Entry exported to excel
        VerifyExportedItemAnalysisEntryWithIntededDimensions(ServerFileName, ItemAnalysisViewEntry, DimValueCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ItemAnalysisViewBudgEntryWithIndentedDimension()
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        Dimension: Record Dimension;
        DimensionValue: array[4] of Record "Dimension Value";
        ItemNo: Code[20];
        DimValueCode: array[5] of Code[20];
        ServerFileName: Text;
        MaxDimLevel: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Export item analysis view budget entry with indented dimention

        // [GIVEN] New item
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] New dimension DIM with intended values
        MaxDimLevel := LibraryRandom.RandIntInRange(2, 5);
        CreateIndentedDimension(Dimension, MaxDimLevel, DimValueCode);

        // [GIVEN] Item Analysis View with dimension DIM
        DimensionValue[1].Get(Dimension.Code, DimValueCode[3]);
        CreateItemAnalysisViewWithDimensions(ItemAnalysisView, DimensionValue);

        // [GIVEN] Mock item analysis view entry
        CreateItemAnalysisViewEntryWithDimension(
          ItemAnalysisView, ItemAnalysisViewEntry, ItemNo, DimensionValue,
          WorkDate(), CreateLocationCode());

        // [GIVEN] Mock analysis view budget entry
        CreateItemAnalysisViewBudgetEntryWithDimension(
          ItemAnalysisView, ItemAnalysisViewBudgEntry, ItemNo, ItemAnalysisViewEntry."Location Code", DimensionValue, WorkDate());

        // [WHEN] Item Analisys View is being exported
        ServerFileName :=
          ItemAnalysisViewExportToExcelGeneral(
            ItemAnalysisView, '', ItemNo, '',
            DimensionValue[1].Code, DimensionValue[2].Code, DimensionValue[3].Code,
            ItemAnalysisViewEntry."Location Code");

        // [THEN] Analysis View Entry exported to excel
        VerifyExportedItemAnalysisBudgEntryWithIntededDimensions(ServerFileName, ItemAnalysisViewBudgEntry, DimValueCode);
    end;

    local procedure AnalysisViewExportToExcelGeneral(AnalysisView: Record "Analysis View"; AmountField: Enum "Analysis Show Amount Field"; DateFilter: Text; AccFilter: Text; BudgetFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; Dim4Filter: Text; AmountType: Enum "Analysis Amount Type"; ClosingEntryFilter: Option; ShowActualBudg: Enum "Analysis Show Amount Type"; BusUnitFilter: Text): Text
    var
        AnalysisViewEntry: Record "Analysis View Entry";
        AnalysisByDimParameters: Record "Analysis by Dim. Parameters";
        ExportAnalysisView: Codeunit "Export Analysis View";
    begin
        SetCommonFiltersAnalysisViewEntry(
          AnalysisView, AnalysisViewEntry, DateFilter, AccFilter,
          Dim1Filter, Dim2Filter, Dim3Filter, Dim4Filter, BusUnitFilter);
        AnalysisViewEntry.FindFirst();
        ExportAnalysisView.SetSkipDownload();
        MakeAnalysisByDimParameters(AnalysisByDimParameters, AmountField, DateFilter, AccFilter, BudgetFilter, Dim1Filter, Dim2Filter, Dim3Filter,
          Dim4Filter, AmountType, ClosingEntryFilter, ShowActualBudg, BusUnitFilter, AnalysisView);
        ExportAnalysisView.ExportData(AnalysisViewEntry, AnalysisByDimParameters);

        exit(ExportAnalysisView.GetServerFileName());
    end;

    local procedure MakeAnalysisByDimParameters(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; AmountField: Enum "Analysis Show Amount Field"; DateFilter: Text; AccFilter: Text; BudgetFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; Dim4Filter: Text; AmountType: Enum "Analysis Amount Type"; ClosingEntryFilter: Option; ShowActualBudg: Enum "Analysis Show Amount Type"; BusUnitFilter: Text; AnalysisView: Record "Analysis View")
    begin
        AnalysisByDimParameters."Show Amount Field" := AmountField;
        AnalysisByDimParameters."Analysis View Code" := AnalysisView.Code;
        AnalysisByDimParameters."Date Filter" := DateFilter;
        AnalysisByDimParameters."Account Filter" := AccFilter;
        AnalysisByDimParameters."Budget Filter" := BudgetFilter;
        AnalysisByDimParameters."Dimension 1 Filter" := Dim1Filter;
        AnalysisByDimParameters."Dimension 2 Filter" := Dim2Filter;
        AnalysisByDimParameters."Dimension 3 Filter" := Dim3Filter;
        AnalysisByDimParameters."Dimension 4 Filter" := Dim4Filter;
        AnalysisByDimParameters."Amount Type" := AmountType;
        AnalysisByDimParameters."Closing Entries" := ClosingEntryFilter;
        AnalysisByDimParameters."Show Actual/Budgets" := ShowActualBudg;
        AnalysisByDimParameters."Analysis Account Source" := AnalysisView."Account Source";
        AnalysisByDimParameters."Bus. Unit Filter" := BusUnitFilter;
    end;

    local procedure CreateAnalysisView(var AnalysisView: Record "Analysis View"; AccountSource: Enum "Analysis Account Source")
    begin
        AnalysisView.Init();
        AnalysisView.Code := Format(LibraryRandom.RandIntInRange(1, 10000));
        AnalysisView.Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(AnalysisView.Name)), 1, MaxStrLen(AnalysisView.Name));
        AnalysisView."Account Source" := AccountSource;
        if not AnalysisView.Insert() then
            AnalysisView.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateAnalysisViewWithDimensions(var AnalysisView: Record "Analysis View"; AccountSource: Enum "Analysis Account Source"; DimensionValue: array[4] of Record "Dimension Value")
    begin
        CreateAnalysisView(AnalysisView, AccountSource);
        AnalysisView."Update on Posting" := false;
        AnalysisView."Dimension 1 Code" := DimensionValue[1]."Dimension Code";
        AnalysisView."Dimension 2 Code" := DimensionValue[2]."Dimension Code";
        AnalysisView."Dimension 3 Code" := DimensionValue[3]."Dimension Code";
        AnalysisView."Dimension 4 Code" := DimensionValue[4]."Dimension Code";
        AnalysisView.Modify();
    end;

    local procedure CreateAnalysisViewEntryWithDimension(AnalysisView: Record "Analysis View"; var AnalysisViewEntry: Record "Analysis View Entry"; AccountNo: Code[20]; DimensionValue: array[4] of Record "Dimension Value"; PostingDate: Date)
    begin
        AnalysisViewEntry."Analysis View Code" := AnalysisView.Code;
        AnalysisViewEntry."Account No." := AccountNo;
        AnalysisViewEntry."Dimension 1 Value Code" := DimensionValue[1].Code;
        AnalysisViewEntry."Dimension 2 Value Code" := DimensionValue[2].Code;
        AnalysisViewEntry."Dimension 3 Value Code" := DimensionValue[3].Code;
        AnalysisViewEntry."Dimension 4 Value Code" := DimensionValue[4].Code;
        AnalysisViewEntry."Posting Date" := PostingDate;
        AnalysisViewEntry.Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        AnalysisViewEntry.Insert();
    end;

    local procedure CreateAnalysisViewCFEntryWithDimension(AnalysisView: Record "Analysis View"; var AnalysisViewEntry: Record "Analysis View Entry"; AccountNo: Code[20]; DimensionValue: array[4] of Record "Dimension Value"; PostingDate: Date)
    begin
        AnalysisViewEntry."Analysis View Code" := AnalysisView.Code;
        AnalysisViewEntry."Account Source" := AnalysisViewEntry."Account Source"::"Cash Flow Account";
        AnalysisViewEntry."Account No." := AccountNo;
        AnalysisViewEntry."Dimension 1 Value Code" := DimensionValue[1].Code;
        AnalysisViewEntry."Dimension 2 Value Code" := DimensionValue[2].Code;
        AnalysisViewEntry."Dimension 3 Value Code" := DimensionValue[3].Code;
        AnalysisViewEntry."Dimension 4 Value Code" := DimensionValue[4].Code;
        AnalysisViewEntry."Posting Date" := PostingDate;
        AnalysisViewEntry.Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        AnalysisViewEntry.Insert();
    end;

    local procedure CreateAnalysisViewBudgetEntryWithDimension(AnalysisView: Record "Analysis View"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry"; AccountNo: Code[20]; DimensionValue: array[4] of Record "Dimension Value"; PostingDate: Date)
    begin
        AnalysisViewBudgetEntry."Analysis View Code" := AnalysisView.Code;
        AnalysisViewBudgetEntry."G/L Account No." := AccountNo;
        AnalysisViewBudgetEntry."Dimension 1 Value Code" := DimensionValue[1].Code;
        AnalysisViewBudgetEntry."Dimension 2 Value Code" := DimensionValue[2].Code;
        AnalysisViewBudgetEntry."Dimension 3 Value Code" := DimensionValue[3].Code;
        AnalysisViewBudgetEntry."Dimension 4 Value Code" := DimensionValue[4].Code;
        AnalysisViewBudgetEntry."Posting Date" := PostingDate;
        AnalysisViewBudgetEntry.Amount := LibraryRandom.RandDecInRange(1, 1000, 2);
        AnalysisViewBudgetEntry.Insert();
    end;

    local procedure CreateDimWithValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateDimsWithValuesForAnalysisView(var DimensionValue: array[4] of Record "Dimension Value")
    var
        i: Integer;
    begin
        for i := 1 to 4 do
            CreateDimWithValue(DimensionValue[i]);
    end;

    local procedure CreateDimsWithValuesForItemAnalysisView(var DimensionValue: array[3] of Record "Dimension Value")
    var
        i: Integer;
    begin
        for i := 1 to 3 do
            CreateDimWithValue(DimensionValue[i]);
    end;

    local procedure CreateDifferentLevelGLAccounts(var GLAccountNo: array[4] of Code[20]): Text
    var
        GLAccountIndent: Codeunit "G/L Account-Indent";
        EndAccountNo: Code[20];
    begin
        GLAccountNo[1] := CreateBeginTotalGLAccountNo();
        GLAccountNo[2] := LibraryERM.CreateGLAccountNo();
        GLAccountNo[3] := CreateBeginTotalGLAccountNo();
        GLAccountNo[4] := LibraryERM.CreateGLAccountNo();
        CreateEndTotalGLAccountNo();
        EndAccountNo := CreateEndTotalGLAccountNo();
        GLAccountIndent.Indent();
        exit(StrSubstNo('%1..%2', GLAccountNo[1], EndAccountNo));
    end;

    local procedure CreateDifferentLevelCFAccounts(var CFAccountNo: array[4] of Code[20]): Text
    var
        EndAccountNo: Code[20];
    begin
        CFAccountNo[1] := CreateBeginTotalCFAccountNo();
        CFAccountNo[2] := CreateCFAccountNo();
        CFAccountNo[3] := CreateBeginTotalCFAccountNo();
        CFAccountNo[4] := CreateCFAccountNo();
        CreateEndTotalCFAccountNo();
        EndAccountNo := CreateEndTotalCFAccountNo();
        CODEUNIT.Run(CODEUNIT::"Cash Flow Account - Indent");
        exit(StrSubstNo('%1..%2', CFAccountNo[1], EndAccountNo));
    end;

    local procedure CreateIndentedGLAccount(MaxLevel: Integer; var GLAccountNo: array[5] of Code[20]): Text
    var
        GLAccountIndent: Codeunit "G/L Account-Indent";
        i: Integer;
        EndAccountNo: Code[20];
    begin
        for i := 1 to MaxLevel do
            GLAccountNo[i] := CreateBeginTotalGLAccountNo();

        GLAccountNo[MaxLevel + 1] := LibraryERM.CreateGLAccountNo();

        for i := 1 to MaxLevel do
            EndAccountNo := CreateEndTotalGLAccountNo();

        GLAccountIndent.Indent();
        exit(StrSubstNo('%1..%2', GLAccountNo[1], EndAccountNo));
    end;

    local procedure CreateBeginTotalGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Account Type" := GLAccount."Account Type"::"Begin-Total";
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateCFAccountNo(): Code[20]
    var
        CashFlowAccount: Record "Cash Flow Account";
    begin
        LibraryCashFlow.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
        exit(CashFlowAccount."No.");
    end;

    local procedure CreateEndTotalGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Account Type" := GLAccount."Account Type"::"End-Total";
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateBeginTotalCFAccountNo(): Code[20]
    var
        CashFlowAccount: Record "Cash Flow Account";
    begin
        LibraryCashFlow.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::"Begin-Total");
        exit(CashFlowAccount."No.");
    end;

    local procedure CreateEndTotalCFAccountNo(): Code[20]
    var
        CashFlowAccount: Record "Cash Flow Account";
    begin
        LibraryCashFlow.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::"End-Total");
        exit(CashFlowAccount."No.");
    end;

    local procedure CreateIndentedDimension(var Dimension: Record Dimension; MaxLevel: Integer; var DimValueCode: array[5] of Code[20])
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);

        for i := 1 to MaxLevel do
            DimValueCode[i] := CreateBeginTotalDimension(Dimension.Code);

        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimValueCode[MaxLevel + 1] := DimensionValue.Code;

        for i := 1 to MaxLevel do
            CreateEndTotalDimension(Dimension.Code);

        CODEUNIT.Run(CODEUNIT::"Dimension Value-Indent", DimensionValue);
    end;

    local procedure CreateBeginTotalDimension(DimCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimCode);
        DimensionValue."Dimension Value Type" := DimensionValue."Dimension Value Type"::"Begin-Total";
        DimensionValue.Modify();
        exit(DimensionValue.Code);
    end;

    local procedure CreateEndTotalDimension(DimCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, DimCode);
        DimensionValue."Dimension Value Type" := DimensionValue."Dimension Value Type"::"End-Total";
        DimensionValue.Modify();
        exit(DimensionValue.Code);
    end;

    local procedure CreateItemAnalysisView(var ItemAnalysisView: Record "Item Analysis View")
    begin
        ItemAnalysisView.Init();
        ItemAnalysisView.Code := Format(LibraryRandom.RandIntInRange(1, 10000));
        ItemAnalysisView.Name := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ItemAnalysisView.Name)), 1, MaxStrLen(ItemAnalysisView.Name));
        if not ItemAnalysisView.Insert() then
            ItemAnalysisView.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateItemAnalysisViewWithDimensions(var ItemAnalysisView: Record "Item Analysis View"; DimensionValue: array[3] of Record "Dimension Value")
    begin
        CreateItemAnalysisView(ItemAnalysisView);
        ItemAnalysisView."Update on Posting" := false;
        ItemAnalysisView."Dimension 1 Code" := DimensionValue[1]."Dimension Code";
        ItemAnalysisView."Dimension 2 Code" := DimensionValue[2]."Dimension Code";
        ItemAnalysisView."Dimension 3 Code" := DimensionValue[3]."Dimension Code";
        ItemAnalysisView.Modify();
    end;

    local procedure CreateItemAnalysisViewEntryWithDimension(ItemAnalysisView: Record "Item Analysis View"; var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; ItemNo: Code[20]; DimensionValue: array[3] of Record "Dimension Value"; PostingDate: Date; LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        ItemAnalysisViewEntry."Analysis View Code" := ItemAnalysisView.Code;
        ItemAnalysisViewEntry."Item No." := ItemNo;
        ItemAnalysisViewEntry."Dimension 1 Value Code" := DimensionValue[1].Code;
        ItemAnalysisViewEntry."Dimension 2 Value Code" := DimensionValue[2].Code;
        ItemAnalysisViewEntry."Dimension 3 Value Code" := DimensionValue[3].Code;
        ItemAnalysisViewEntry."Posting Date" := PostingDate;
        ItemAnalysisViewEntry."Sales Amount (Actual)" := LibraryRandom.RandDecInRange(1, 1000, 2);
        ItemAnalysisViewEntry."Cost Amount (Actual)" := LibraryRandom.RandDecInRange(1, 1000, 2);
        ItemAnalysisViewEntry.Quantity := LibraryRandom.RandDecInRange(1, 1000, 2);
        ItemAnalysisViewEntry."Location Code" := LocationCode;
        ItemAnalysisViewEntry.Insert();
    end;

    local procedure CreateItemAnalysisViewBudgetEntryWithDimension(ItemAnalysisView: Record "Item Analysis View"; var ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry"; ItemNo: Code[20]; LocationCode: Code[10]; DimensionValue: array[4] of Record "Dimension Value"; PostingDate: Date)
    begin
        ItemAnalysisViewBudgEntry."Analysis Area" := ItemAnalysisView."Analysis Area";
        ItemAnalysisViewBudgEntry."Analysis View Code" := ItemAnalysisView.Code;
        ItemAnalysisViewBudgEntry."Item No." := ItemNo;
        ItemAnalysisViewBudgEntry."Location Code" := LocationCode;
        ItemAnalysisViewBudgEntry."Dimension 1 Value Code" := DimensionValue[1].Code;
        ItemAnalysisViewBudgEntry."Dimension 2 Value Code" := DimensionValue[2].Code;
        ItemAnalysisViewBudgEntry."Dimension 3 Value Code" := DimensionValue[3].Code;
        ItemAnalysisViewBudgEntry."Posting Date" := PostingDate;
        ItemAnalysisViewBudgEntry.Quantity := LibraryRandom.RandDecInRange(1, 1000, 2);
        ItemAnalysisViewBudgEntry."Sales Amount" := LibraryRandom.RandDecInRange(1, 1000, 2);
        ItemAnalysisViewBudgEntry."Cost Amount" := LibraryRandom.RandDecInRange(1, 1000, 2);
        ItemAnalysisViewBudgEntry.Insert();
    end;

    local procedure CreateLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    local procedure GetDimValueTotaling(DimValueFilter: Text; DimensionCode: Code[20]): Text
    var
        DimensionValue: Record "Dimension Value";
    begin
        if DimensionCode <> '' then begin
            DimensionValue.SetRange("Dimension Code", DimensionCode);
            DimensionValue.SetFilter(Code, DimValueFilter);
            if DimensionValue.FindFirst() then
                if DimensionValue.Totaling <> '' then
                    exit(DimensionValue.Totaling);
        end;
        exit(DimValueFilter);
    end;

    local procedure ItemAnalysisViewExportToExcelGeneral(ItemAnalysisView: Record "Item Analysis View"; DateFilter: Text; ItemFilter: Text; BudgetFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; LocationFilter: Text): Text
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ExportItemAnalysisView: Codeunit "Export Item Analysis View";
    begin
        SetCommonFiltersItemAnalysisViewEntry(
          ItemAnalysisView, ItemAnalysisViewEntry, DateFilter, ItemFilter,
          Dim1Filter, Dim2Filter, Dim3Filter, LocationFilter);
        ItemAnalysisViewEntry.FindFirst();
        ExportItemAnalysisView.SetSkipDownload();
        ExportItemAnalysisView.ExportData(
          ItemAnalysisViewEntry, false,
          DateFilter, ItemFilter, BudgetFilter,
          Dim1Filter, Dim2Filter, Dim3Filter, 0, LocationFilter, false);

        exit(ExportItemAnalysisView.GetServerFileName());
    end;

    local procedure SetCommonFiltersAnalysisViewEntry(AnalysisView: Record "Analysis View"; var AnalysisViewEntry: Record "Analysis View Entry"; DateFilter: Text; AccountFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; Dim4Filter: Text; BusUnitFilter: Text)
    begin
        AnalysisViewEntry.Reset();

        AnalysisViewEntry.SetRange("Analysis View Code", AnalysisView.Code);
        if BusUnitFilter <> '' then
            AnalysisViewEntry.SetFilter("Business Unit Code", BusUnitFilter);

        if AccountFilter <> '' then
            AnalysisViewEntry.SetFilter("Account No.", AccountFilter);

        AnalysisViewEntry.SetRange("Account Source", AnalysisView."Account Source");

        AnalysisViewEntry.SetFilter("Posting Date", DateFilter);
        if Dim1Filter <> '' then
            AnalysisViewEntry.SetFilter("Dimension 1 Value Code", GetDimValueTotaling(Dim1Filter, AnalysisView."Dimension 1 Code"));
        if Dim2Filter <> '' then
            AnalysisViewEntry.SetFilter("Dimension 2 Value Code", GetDimValueTotaling(Dim2Filter, AnalysisView."Dimension 2 Code"));
        if Dim3Filter <> '' then
            AnalysisViewEntry.SetFilter("Dimension 3 Value Code", GetDimValueTotaling(Dim3Filter, AnalysisView."Dimension 3 Code"));
        if Dim4Filter <> '' then
            AnalysisViewEntry.SetFilter("Dimension 4 Value Code", GetDimValueTotaling(Dim4Filter, AnalysisView."Dimension 4 Code"));
    end;

    local procedure SetCommonFiltersItemAnalysisViewEntry(ItemAnalysisView: Record "Item Analysis View"; var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; DateFilter: Text; ItemFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; LocationFilter: Text)
    begin
        ItemAnalysisViewEntry.Reset();

        ItemAnalysisViewEntry.SetRange("Analysis View Code", ItemAnalysisView.Code);

        if ItemFilter <> '' then
            ItemAnalysisViewEntry.SetFilter("Item No.", ItemFilter);
        if LocationFilter <> '' then
            ItemAnalysisViewEntry.SetFilter("Location Code", LocationFilter);

        ItemAnalysisViewEntry.SetFilter("Posting Date", DateFilter);
        if Dim1Filter <> '' then
            ItemAnalysisViewEntry.SetFilter("Dimension 1 Value Code", GetDimValueTotaling(Dim1Filter, ItemAnalysisView."Dimension 1 Code"));
        if Dim2Filter <> '' then
            ItemAnalysisViewEntry.SetFilter("Dimension 2 Value Code", GetDimValueTotaling(Dim2Filter, ItemAnalysisView."Dimension 2 Code"));
        if Dim3Filter <> '' then
            ItemAnalysisViewEntry.SetFilter("Dimension 3 Value Code", GetDimValueTotaling(Dim3Filter, ItemAnalysisView."Dimension 3 Code"));
    end;

    local procedure VerifyAnalysisVeiwGeneralInfoSheet(ServerFileName: Text; var AnalysisViewEntry: Record "Analysis View Entry"; DimensionValue: array[4] of Record "Dimension Value")
    var
        AnalysisView: Record "Analysis View";
        DateDec: Decimal;
    begin
        LibraryReportValidation.SetFullFileName(ServerFileName);
        LibraryReportValidation.OpenFile();

        AnalysisView.Get(AnalysisViewEntry."Analysis View Code");
        // Analysis View part
        LibraryReportValidation.VerifyCellValue(2, 3, AnalysisView.Code);
        LibraryReportValidation.VerifyCellValue(3, 3, AnalysisView.Name);
        LibraryReportValidation.VerifyCellValue(4, 3, Format(AnalysisView."Date Compression"));
        Evaluate(DateDec, LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(1, 5, 3));
        Assert.AreEqual(
          AnalysisView."Last Date Updated",
          DT2Date(ExcelBuffer.ConvertDateTimeDecimalToDateTime(DateDec)),
          '');

        // Analysis By Dimension part
        LibraryReportValidation.VerifyCellValue(8, 2, DimensionValue[1]."Dimension Code");
        LibraryReportValidation.VerifyCellValue(8, 3, DimensionValue[1].Code);
        LibraryReportValidation.VerifyCellValue(9, 2, DimensionValue[2]."Dimension Code");
        LibraryReportValidation.VerifyCellValue(9, 3, DimensionValue[2].Code);
        LibraryReportValidation.VerifyCellValue(10, 2, DimensionValue[3]."Dimension Code");
        LibraryReportValidation.VerifyCellValue(10, 3, DimensionValue[3].Code);
        LibraryReportValidation.VerifyCellValue(11, 2, DimensionValue[4]."Dimension Code");
        LibraryReportValidation.VerifyCellValue(11, 3, DimensionValue[4].Code);
    end;

    local procedure VerifyItemAnalysisViewGeneralInfoSheet(ServerFileName: Text; var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; DimensionValue: array[4] of Record "Dimension Value")
    var
        ItemAnalysisView: Record "Item Analysis View";
        DateDec: Decimal;
    begin
        LibraryReportValidation.SetFullFileName(ServerFileName);
        LibraryReportValidation.OpenFile();

        ItemAnalysisView.Get(ItemAnalysisViewEntry."Analysis Area", ItemAnalysisViewEntry."Analysis View Code");
        // Analysis View part
        LibraryReportValidation.VerifyCellValue(2, 3, ItemAnalysisView.Code);
        LibraryReportValidation.VerifyCellValue(3, 3, ItemAnalysisView.Name);
        LibraryReportValidation.VerifyCellValue(4, 3, Format(ItemAnalysisView."Date Compression"));
        Evaluate(DateDec, LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(1, 5, 3));
        Assert.AreEqual(
          ItemAnalysisView."Last Date Updated",
          DT2Date(ExcelBuffer.ConvertDateTimeDecimalToDateTime(DateDec)),
          '');

        // Analysis By Dimension part
        LibraryReportValidation.VerifyCellValue(8, 3, ItemAnalysisViewEntry."Location Code");
        LibraryReportValidation.VerifyCellValue(9, 2, DimensionValue[1]."Dimension Code");
        LibraryReportValidation.VerifyCellValue(9, 3, DimensionValue[1].Code);
        LibraryReportValidation.VerifyCellValue(10, 2, DimensionValue[2]."Dimension Code");
        LibraryReportValidation.VerifyCellValue(10, 3, DimensionValue[2].Code);
        LibraryReportValidation.VerifyCellValue(11, 2, DimensionValue[3]."Dimension Code");
        LibraryReportValidation.VerifyCellValue(11, 3, DimensionValue[3].Code);
    end;

    local procedure VerifyExportedAnalysisEntryWithSimpleDimensions(ServerFileName: Text; var AnalysisViewEntry: Record "Analysis View Entry"; GLAccountNo: Code[20]; DimensionValue: array[4] of Record "Dimension Value")
    var
        DateDec: Decimal;
    begin
        LibraryReportValidation.SetFullFileName(ServerFileName);
        LibraryReportValidation.OpenFile();

        VerifyCellValueOnWorksheet(2, 2, 1, GLAccountNo);
        VerifyCellValueOnWorksheet(2, 2, 2, DimensionValue[1].Code);
        VerifyCellValueOnWorksheet(2, 2, 3, DimensionValue[2].Code);
        VerifyCellValueOnWorksheet(2, 2, 4, DimensionValue[3].Code);
        VerifyCellValueOnWorksheet(2, 2, 5, DimensionValue[4].Code);
        Evaluate(DateDec, LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(2, 2, 6));
        Assert.AreEqual(
          AnalysisViewEntry."Posting Date",
          DT2Date(ExcelBuffer.ConvertDateTimeDecimalToDateTime(DateDec)),
          '');
        VerifyCellValueOnWorksheet(2, 2, 12, Format(AnalysisViewEntry.Amount, 0, 9));
    end;

    local procedure VerifyIndentedGLAccountSimpleDimensions(ServerFileName: Text; var AnalysisViewEntry: Record "Analysis View Entry"; MaxGLAccountLevel: Integer; GLAccountNo: array[5] of Code[20]; DimensionValue: array[4] of Record "Dimension Value")
    var
        DateDec: Decimal;
        i: Integer;
    begin
        LibraryReportValidation.SetFullFileName(ServerFileName);
        LibraryReportValidation.OpenFile();

        for i := 1 to MaxGLAccountLevel + 1 do
            VerifyCellValueOnWorksheet(2, 2, i, GLAccountNo[i]);
        VerifyCellValueOnWorksheet(2, 2, MaxGLAccountLevel + 2, DimensionValue[1].Code);
        VerifyCellValueOnWorksheet(2, 2, MaxGLAccountLevel + 3, DimensionValue[2].Code);
        VerifyCellValueOnWorksheet(2, 2, MaxGLAccountLevel + 4, DimensionValue[3].Code);
        VerifyCellValueOnWorksheet(2, 2, MaxGLAccountLevel + 5, DimensionValue[4].Code);
        Evaluate(DateDec, LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(2, 2, MaxGLAccountLevel + 6));
        Assert.AreEqual(
          AnalysisViewEntry."Posting Date",
          DT2Date(ExcelBuffer.ConvertDateTimeDecimalToDateTime(DateDec)),
          '');
        VerifyCellValueOnWorksheet(2, 2, MaxGLAccountLevel + 12, Format(AnalysisViewEntry.Amount, 0, 9));
    end;

    local procedure VerifyDIffIndentedAccountSimpleDimensions(ServerFileName: Text; var AnalysisViewEntry: Record "Analysis View Entry"; GLAccountNo: array[4] of Code[20]; DimensionValue: array[4] of Record "Dimension Value"; AccFilter: Text)
    var
        DateDec: Decimal;
    begin
        LibraryReportValidation.SetFullFileName(ServerFileName);
        LibraryReportValidation.OpenFile();

        // (TFS ID: 324810): verify account filter formatting
        Assert.AreEqual(AccFilter, LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(1, 8, 3), '');

        VerifyCellValueOnWorksheet(2, 2, 1, GLAccountNo[1]);
        VerifyCellValueOnWorksheet(2, 2, 2, GLAccountNo[2]);
        VerifyCellValueOnWorksheet(2, 2, 3, GLAccountNo[2]);  // same value as for column 2
        VerifyCellValueOnWorksheet(2, 2, 4, DimensionValue[1].Code);
        VerifyCellValueOnWorksheet(2, 2, 5, DimensionValue[2].Code);
        VerifyCellValueOnWorksheet(2, 2, 6, DimensionValue[3].Code);
        VerifyCellValueOnWorksheet(2, 2, 7, DimensionValue[4].Code);
        Evaluate(DateDec, LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(2, 2, 8));
        Assert.AreEqual(
          AnalysisViewEntry."Posting Date",
          DT2Date(ExcelBuffer.ConvertDateTimeDecimalToDateTime(DateDec)),
          '');
        VerifyCellValueOnWorksheet(2, 2, 14, Format(AnalysisViewEntry.Amount, 0, 9));
    end;

    local procedure VerifyEntryWithIntededDimensions(ServerFileName: Text; var AnalysisViewEntry: Record "Analysis View Entry"; GLAccountNo: Code[20]; DimValueCode: array[5] of Code[20])
    var
        DateDec: Decimal;
    begin
        LibraryReportValidation.SetFullFileName(ServerFileName);
        LibraryReportValidation.OpenFile();

        VerifyCellValueOnWorksheet(2, 2, 1, GLAccountNo);
        VerifyCellValueOnWorksheet(2, 2, 2, DimValueCode[1]);
        VerifyCellValueOnWorksheet(2, 2, 3, DimValueCode[2]);
        VerifyCellValueOnWorksheet(2, 2, 4, DimValueCode[3]);
        Evaluate(DateDec, LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(2, 2, 5));
        Assert.AreEqual(
          AnalysisViewEntry."Posting Date",
          DT2Date(ExcelBuffer.ConvertDateTimeDecimalToDateTime(DateDec)),
          '');
        VerifyCellValueOnWorksheet(2, 2, 11, Format(AnalysisViewEntry.Amount, 0, 9));
    end;

    local procedure VerifyBudgetEntryWithSimpleDimensions(ServerFileName: Text; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry"; GLAccountNo: Code[20]; DimensionValue: array[4] of Record "Dimension Value")
    var
        DateDec: Decimal;
    begin
        LibraryReportValidation.SetFullFileName(ServerFileName);
        LibraryReportValidation.OpenFile();

        VerifyCellValueOnWorksheet(2, 3, 1, GLAccountNo);
        VerifyCellValueOnWorksheet(2, 3, 2, DimensionValue[1].Code);
        VerifyCellValueOnWorksheet(2, 3, 3, DimensionValue[2].Code);
        VerifyCellValueOnWorksheet(2, 3, 4, DimensionValue[3].Code);
        VerifyCellValueOnWorksheet(2, 3, 5, DimensionValue[4].Code);
        Evaluate(DateDec, LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(2, 3, 6));
        Assert.AreEqual(
          AnalysisViewBudgetEntry."Posting Date",
          DT2Date(ExcelBuffer.ConvertDateTimeDecimalToDateTime(DateDec)),
          '');
        VerifyCellValueOnWorksheet(2, 3, 15, Format(AnalysisViewBudgetEntry.Amount, 0, 9));
    end;

    local procedure VerifyAnalysisViewColumnCaptions(ServerFileName: Text; MaxGLAccountLevel: Integer; MaxDimLevel: Integer; DimCode: Code[20])
    var
        i: Integer;
    begin
        LibraryReportValidation.SetFullFileName(ServerFileName);
        LibraryReportValidation.OpenFile();

        for i := 1 to MaxGLAccountLevel do
            VerifyCellValueOnWorksheet(2, 1, i, StrSubstNo('G/L Account Level %1', i - 1));

        for i := 1 to MaxDimLevel do
            VerifyCellValueOnWorksheet(2, 1, MaxGLAccountLevel + i + 1, StrSubstNo('%1 Level %2', DimCode, i - 1));

        VerifyCellValueOnWorksheet(2, 1, MaxGLAccountLevel + MaxDimLevel + 3, 'Day');
        VerifyCellValueOnWorksheet(2, 1, MaxGLAccountLevel + MaxDimLevel + 4, 'Week');
        VerifyCellValueOnWorksheet(2, 1, MaxGLAccountLevel + MaxDimLevel + 5, 'Month');
        VerifyCellValueOnWorksheet(2, 1, MaxGLAccountLevel + MaxDimLevel + 6, 'Quarter');
        VerifyCellValueOnWorksheet(2, 1, MaxGLAccountLevel + MaxDimLevel + 7, 'Year');
        VerifyCellValueOnWorksheet(2, 1, MaxGLAccountLevel + MaxDimLevel + 8, 'Accounting Period');
        VerifyCellValueOnWorksheet(2, 1, MaxGLAccountLevel + MaxDimLevel + 9, 'Amount');
        VerifyCellValueOnWorksheet(2, 1, MaxGLAccountLevel + MaxDimLevel + 10, 'Debit Amount');
        VerifyCellValueOnWorksheet(2, 1, MaxGLAccountLevel + MaxDimLevel + 11, 'Credit Amount');
        VerifyCellValueOnWorksheet(2, 1, MaxGLAccountLevel + MaxDimLevel + 12, 'Budgeted Amount');
    end;

    local procedure VerifyItemAnalysisViewColumnCaptions(ServerFileName: Text; MaxDimLevel: Integer; DimCode: Code[20])
    var
        i: Integer;
    begin
        LibraryReportValidation.SetFullFileName(ServerFileName);
        LibraryReportValidation.OpenFile();

        VerifyCellValueOnWorksheet(2, 1, 1, 'Item Level 0');

        for i := 1 to MaxDimLevel do
            VerifyCellValueOnWorksheet(2, 1, i + 1, StrSubstNo('%1 Level %2', DimCode, i - 1));

        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 3, 'Day');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 4, 'Week');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 5, 'Month');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 6, 'Quarter');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 7, 'Year');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 8, 'Accounting Period');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 9, 'Sales Amount');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 10, 'Cost Amount');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 11, 'Quantity');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 12, 'Location');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 13, 'Budg. Sales Amount');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 14, 'Budg. Cost Amount');
        VerifyCellValueOnWorksheet(2, 1, MaxDimLevel + 15, 'Budg. Quantity');
    end;

    local procedure VerifyExportedItemAnalysisEntryWithIntededDimensions(ServerFileName: Text; var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; DimValueCode: array[5] of Code[20])
    var
        DateDec: Decimal;
    begin
        LibraryReportValidation.SetFullFileName(ServerFileName);
        LibraryReportValidation.OpenFile();

        VerifyCellValueOnWorksheet(2, 2, 1, ItemAnalysisViewEntry."Item No.");
        VerifyCellValueOnWorksheet(2, 2, 2, DimValueCode[1]);
        VerifyCellValueOnWorksheet(2, 2, 3, DimValueCode[2]);
        VerifyCellValueOnWorksheet(2, 2, 4, DimValueCode[3]);
        Evaluate(DateDec, LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(2, 2, 5));
        Assert.AreEqual(
          ItemAnalysisViewEntry."Posting Date",
          DT2Date(ExcelBuffer.ConvertDateTimeDecimalToDateTime(DateDec)),
          '');
        VerifyCellValueOnWorksheet(2, 2, 11, Format(ItemAnalysisViewEntry."Sales Amount (Actual)", 0, 1));
        VerifyCellValueOnWorksheet(2, 2, 12, Format(ItemAnalysisViewEntry."Cost Amount (Actual)", 0, 1));
        VerifyCellValueOnWorksheet(2, 2, 13, Format(ItemAnalysisViewEntry.Quantity, 0, 1));
        VerifyCellValueOnWorksheet(2, 2, 14, ItemAnalysisViewEntry."Location Code");
    end;

    local procedure VerifyExportedItemAnalysisBudgEntryWithIntededDimensions(ServerFileName: Text; var ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry"; DimValueCode: array[5] of Code[20])
    var
        DateDec: Decimal;
    begin
        LibraryReportValidation.SetFullFileName(ServerFileName);
        LibraryReportValidation.OpenFile();

        VerifyCellValueOnWorksheet(2, 3, 1, ItemAnalysisViewBudgEntry."Item No.");
        VerifyCellValueOnWorksheet(2, 3, 2, DimValueCode[1]);
        VerifyCellValueOnWorksheet(2, 3, 3, DimValueCode[2]);
        VerifyCellValueOnWorksheet(2, 3, 4, DimValueCode[3]);
        Evaluate(DateDec, LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(2, 3, 5));
        Assert.AreEqual(
          ItemAnalysisViewBudgEntry."Posting Date",
          DT2Date(ExcelBuffer.ConvertDateTimeDecimalToDateTime(DateDec)),
          '');
        VerifyCellValueOnWorksheet(2, 3, 14, ItemAnalysisViewBudgEntry."Location Code");
        VerifyCellValueOnWorksheet(2, 3, 15, Format(ItemAnalysisViewBudgEntry."Sales Amount", 0, 1));
        VerifyCellValueOnWorksheet(2, 3, 16, Format(ItemAnalysisViewBudgEntry."Cost Amount", 0, 1));
        VerifyCellValueOnWorksheet(2, 3, 17, Format(ItemAnalysisViewBudgEntry.Quantity, 0, 1));
    end;

    local procedure VerifyCellValueOnWorksheet(WorksheetNo: Integer; RowId: Integer; ColumnId: Integer; ExpectedValue: Text)
    begin
        Assert.AreEqual(
          ExpectedValue,
          LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(WorksheetNo, RowId, ColumnId),
          StrSubstNo(IncorrectValueInCellOnWorksheetErr, WorksheetNo, RowId, ColumnId));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

