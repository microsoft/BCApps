codeunit 134821 "ERM Cost Accounting - Pages"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        LibraryDimension: Codeunit "Library - Dimension";
        NotEditable: Label '%1 field property should not be editable.';
        Enabled: Label 'Control property should be enabled.';
        Visible: Label 'Control property should be visible.';
        DateFilterError: Label 'The date filter is incorrect.';
        ExpectedValueDifferent: Label 'Expected value of %1 field is different than the actual one.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        CostCenterFilter: Code[20];
        CostObjectFilter: Code[20];
        ViewAsError: Label 'Set View As to Net Change before you edit entries.';
        EmptyFiltersError: Label '%1 or %2 must not be blank.', Comment = '%1=fieldcaption Cost Center,%2=fieldcaption Cost Object';
        InvalidColumnIndex: Label 'The ColumnNo param is outside the permitted range.';
        WrongCaptionError: Label 'The caption for column no. %1 is wrong.';
        NextSetNotAvailableError: Label 'The next set could not be initialized.';
        CostJournalBatchName: Code[10];
        CostJnlLineError: Label '%1 must exist.';
        PostingDateError: Label '%1 must be equal to Workdate.';
        CostBudgetAmountError: Label 'The amount for %1 %2 for column %3 is not equal to the amount on the %4 %5.', Comment = '%1:Table Caption;%2:Field Value;%3:Column Caption;%4:Table Caption;%5:Field Value;';
        ColumnDateError: Label 'The column captions (dates) were not updated after invoking the %1 action.';
        GLAccountNo: Code[20];
        CostJournalAmountError: Label 'The amount that was posted from %1 must be equal to amount in %2.';
        InvalidColumnCaptionError: Label 'Period in columns caption were not updated according to the view by filter.';
        CostTypeNo: Code[20];
        ActionFilter: Option SetValue,Verify;
        EntryNo: Integer;
        FailedToGetTheExpectedValidationError: Label 'Failed to get the expected validation error.';
        TestValidation: Label 'TestValidation';
        CostTypeFilterDefinition: Label '%1..%2', Comment = '%1 - Field Value;%2 - Field Value', Locked = true;
        WrongFlowFilterValueErr: Label 'Wrong FLowFilter''s value on the page';

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAcctgSetupCostCenterField()
    var
        CostAccSetup: Record "Cost Accounting Setup";
        CostAccSetupPage: TestPage "Cost Accounting Setup";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingSetup();
        CostAccSetup.Get();

        CostAccSetupPage.OpenEdit();
        CostAccSetupPage."Cost Center Dimension".AssertEquals(CostAccSetup."Cost Center Dimension");
        Assert.IsFalse(
          CostAccSetupPage."Cost Center Dimension".Editable(), StrSubstNo(NotEditable, CostAccSetup.FieldCaption("Cost Center Dimension")));

        CostAccSetupPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAcctgSetupCostObjectField()
    var
        CostAccSetup: Record "Cost Accounting Setup";
        CostAccSetupPage: TestPage "Cost Accounting Setup";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingSetup();
        CostAccSetup.Get();

        CostAccSetupPage.OpenEdit();
        CostAccSetupPage."Cost Object Dimension".AssertEquals(CostAccSetup."Cost Object Dimension");
        Assert.IsFalse(
          CostAccSetupPage."Cost Object Dimension".Editable(), StrSubstNo(NotEditable, CostAccSetup.FieldCaption("Cost Object Dimension")));

        CostAccSetupPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAllocationSourcesAllocateCostsActionIsAvailable()
    var
        CostAllocationSourcesPage: TestPage "Cost Allocation Sources";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        CostAllocationSourcesPage.OpenView();

        Assert.IsTrue(CostAllocationSourcesPage.Allocations.Enabled(), Enabled);
        Assert.IsTrue(CostAllocationSourcesPage.Allocations.Visible(), Visible);

        CostAllocationSourcesPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostAllocationSourcesCalculateAllocKeysActionIsAvailable()
    var
        CostAllocationSourcesPage: TestPage "Cost Allocation Sources";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        CostAllocationSourcesPage.OpenView();

        Assert.IsTrue(CostAllocationSourcesPage."&Calculate Allocation Keys".Enabled(), Enabled);
        Assert.IsTrue(CostAllocationSourcesPage."&Calculate Allocation Keys".Visible(), Visible);

        CostAllocationSourcesPage."&Calculate Allocation Keys".Invoke();
        CostAllocationSourcesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetNamesTransferBudgetToActualActionIsAvailable()
    var
        CostBudgetNamesPage: TestPage "Cost Budget Names";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetNamesPage.OpenView();

        Assert.IsTrue(CostBudgetNamesPage."Transfer Budget to Actual".Enabled(), Enabled);
        Assert.IsTrue(CostBudgetNamesPage."Transfer Budget to Actual".Visible(), Visible);

        CostBudgetNamesPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostRegisterDeleteOldCostEntriesIsAvailable()
    var
        CostRegisterPage: TestPage "Cost Registers";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        CostRegisterPage.OpenView();

        Assert.IsTrue(CostRegisterPage."&Delete Old Cost Entries".Enabled(), Enabled);
        Assert.IsTrue(CostRegisterPage."&Delete Old Cost Entries".Visible(), Visible);

        CostRegisterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerCostCenterMatrixValidateFiltersForAmountTypeNetChange()
    var
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetByCostCenterPage.OpenEdit();
        ExpectedDate := GetCurrentDate(CostBudgetByCostCenterPage.FILTER.GetFilter("Date Filter"));
        SetFieldsOnCostBudgetByCostCenterPage(CostBudgetByCostCenterPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '');

        VerifyFiltersOnCostBudgetByCostCenterMatrixPage(CostBudgetByCostCenterPage, Format(ExpectedDate));

        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerCostCenterMatrixValidateFiltersForAmountTypeBalanceAtDate()
    var
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetByCostCenterPage.OpenEdit();
        ExpectedDate := GetCurrentDate(CostBudgetByCostCenterPage.FILTER.GetFilter("Date Filter"));
        SetFieldsOnCostBudgetByCostCenterPage(
          CostBudgetByCostCenterPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Day), '');

        VerifyFiltersOnCostBudgetByCostCenterMatrixPage(CostBudgetByCostCenterPage, StrSubstNo('''''..%1', ExpectedDate));

        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerCostCenterUpdateAmountCellForAmountTypeBalanceAtDate()
    var
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Setup:
        CostBudgetByCostCenterPage.OpenEdit();
        SetFieldsOnCostBudgetByCostCenterPage(
          CostBudgetByCostCenterPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Day), '');

        // Exercise & Verify:
        asserterror CostBudgetByCostCenterPage.MatrixForm.Column1.SetValue(LibraryRandom.RandDec(100, 2));
        Assert.ExpectedError(ViewAsError);

        // Tear-down
        CostBudgetByCostCenterPage.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerCostCenterMatrixUpdateAmountCellForRandomColumn()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostCenter: Record "Cost Center";
        CostType: Record "Cost Type";
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        ColumnNo: Integer;
        Amount: Decimal;
        PrevAmount: Decimal;
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Setup page:
        CostBudgetByCostCenterPage.OpenEdit();

        CostType.SetRange(Totaling, '');
        CostType.FindFirst();
        CostBudgetByCostCenterPage.MatrixForm.GotoRecord(CostType);

        ExpectedDate := GetCurrentDate(CostBudgetByCostCenterPage.FILTER.GetFilter("Date Filter"));
        SetFieldsOnCostBudgetByCostCenterPage(
          CostBudgetByCostCenterPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), CostBudgetName.Name);

        CostCenter.SetRange("Line Type", CostCenter."Line Type"::"Cost Center");
        if CostCenter.Count > 12 then // 12 is Max number of columns on the matrix page
            ColumnNo := LibraryRandom.RandInt(12)
        else
            ColumnNo := LibraryRandom.RandInt(CostCenter.Count);
        Amount := LibraryRandom.RandDec(100, 2);
        if GetCellValueOnCostBudgetByCostCenterPage(CostBudgetByCostCenterPage, ColumnNo) = '' then
            PrevAmount := 0
        else
            Evaluate(PrevAmount, GetCellValueOnCostBudgetByCostCenterPage(CostBudgetByCostCenterPage, ColumnNo));

        // Exercise:
        SetCellValueOnCostBudgetByCostCenterPage(CostBudgetByCostCenterPage, ColumnNo, Amount);

        // Verify:
        VerifyCostBudgetEntry(
          CostBudgetName.Name, GetColumnCaptionOnCostBudgetByCostCenterPage(CostBudgetByCostCenterPage, ColumnNo), '',
          CostBudgetByCostCenterPage.MatrixForm."No.".Value, ExpectedDate, Amount - PrevAmount);

        // Tear-down
        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerCostObjectMatrixValidateFiltersForAmountTypeNetChange()
    var
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        ExpectedDate :=
          OpenCostBudgetByCostObjectPage(CostBudgetByCostObjectPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '');
        VerifyFiltersOnCostBudgetByCostObjectMatrixPage(CostBudgetByCostObjectPage, Format(ExpectedDate));

        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerCostObjectMatrixValidateFiltersForAmountTypeBalanceAtDate()
    var
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        ExpectedDate :=
          OpenCostBudgetByCostObjectPage(CostBudgetByCostObjectPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Day), '');
        VerifyFiltersOnCostBudgetByCostObjectMatrixPage(CostBudgetByCostObjectPage, StrSubstNo('''''..%1', ExpectedDate));

        CostBudgetByCostObjectPage.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerCostObjectUpdateAmountCellForAmountTypeBalanceAtDate()
    var
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Setup:
        CostBudgetByCostObjectPage.OpenEdit();
        SetFieldsOnCostBudgetByCostObjectPage(
          CostBudgetByCostObjectPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Day), '');

        // Exercise & Verify:
        asserterror CostBudgetByCostObjectPage.MatrixForm.Column1.SetValue(LibraryRandom.RandDec(100, 2));
        Assert.ExpectedError(ViewAsError);

        // Tear-down
        CostBudgetByCostObjectPage.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerCostObjectMatrixUpdateAmountCellForRandomColumn()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostObject: Record "Cost Object";
        CostType: Record "Cost Type";
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        ColumnNo: Integer;
        Amount: Decimal;
        PrevAmount: Decimal;
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Setup page:
        CostBudgetByCostObjectPage.OpenEdit();

        CostType.SetRange(Totaling, '');
        CostType.FindFirst();
        CostBudgetByCostObjectPage.MatrixForm.GotoRecord(CostType);

        ExpectedDate := GetCurrentDate(CostBudgetByCostObjectPage.FILTER.GetFilter("Date Filter"));
        SetFieldsOnCostBudgetByCostObjectPage(
          CostBudgetByCostObjectPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), CostBudgetName.Name);

        CostObject.SetRange("Line Type", CostObject."Line Type"::"Cost Object");
        if CostObject.Count > 12 then // 12 is Max number of columns on the matrix page
            ColumnNo := LibraryRandom.RandInt(12)
        else
            ColumnNo := LibraryRandom.RandInt(CostObject.Count);
        Amount := LibraryRandom.RandDec(100, 2);
        if GetCellValueOnCostBudgetByCostObjectPage(CostBudgetByCostObjectPage, ColumnNo) = '' then
            PrevAmount := 0
        else
            Evaluate(PrevAmount, GetCellValueOnCostBudgetByCostObjectPage(CostBudgetByCostObjectPage, ColumnNo));

        // Exercise:
        SetCellValueOnCostBudgetByCostObjectPage(CostBudgetByCostObjectPage, ColumnNo, Amount);

        // Verify:
        VerifyCostBudgetEntry(
          CostBudgetName.Name, '', GetColumnCaptionOnCostBudgetByCostObjectPage(CostBudgetByCostObjectPage, ColumnNo),
          CostBudgetByCostObjectPage.MatrixForm."No.".Value, ExpectedDate, Amount - PrevAmount);

        // Tear-down
        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodMatrixValidateFiltersForAmountTypeNetChange()
    var
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
        ExpectedDateFilter: Text;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetPerPeriodPage.OpenEdit();
        SetFieldsOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '', '', '');

        ExpectedDateFilter := Format(CalcDate('<11D>', WorkDate()));  // 12 matrix columns
        VerifyFiltersOnCostBudgetPerPeriodMatrixPage(CostBudgetPerPeriodPage, ExpectedDateFilter);

        CostBudgetPerPeriodPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodMatrixValidateFiltersForAmountTypeBalanceAtDate()
    var
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetPerPeriodPage.OpenEdit();
        SetFieldsOnCostBudgetPerPeriodPage(
          CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Day), '', '', '');

        VerifyFiltersOnCostBudgetPerPeriodMatrixPage(CostBudgetPerPeriodPage, StrSubstNo('''''..%1', CalcDate('<11D>', WorkDate()))); // 12 matrix columns

        CostBudgetPerPeriodPage.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodMatrixUpdateAmountCellForAmountTypeBalanceAtDate()
    var
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Setup:
        CostBudgetPerPeriodPage.OpenEdit();
        SetFieldsOnCostBudgetPerPeriodPage(
          CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Day), '', '', '');

        // Exercise & Verify:
        asserterror CostBudgetPerPeriodPage.MatrixForm.Column1.SetValue(LibraryRandom.RandDec(100, 2));
        Assert.ExpectedError(ViewAsError);

        // Tear-down
        CostBudgetPerPeriodPage.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodMatrixUpdateAmountCellForCCorCOFiltersEmpty()
    var
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Setup:
        CostBudgetPerPeriodPage.OpenEdit();
        SetFieldsOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '', '', '');

        // Exercise & Verify:
        asserterror CostBudgetPerPeriodPage.MatrixForm.Column1.SetValue(LibraryRandom.RandDec(100, 2));
        Assert.ExpectedError(
          StrSubstNo(EmptyFiltersError, CostBudgetPerPeriodPage.CostCenterFilter.Caption, CostBudgetPerPeriodPage.CostObjectFilter.Caption));

        // Tear-down
        CostBudgetPerPeriodPage.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodMatrixUpdateAmountCellForRandomColumn()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostCenter: Record "Cost Center";
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
        ColumnNo: Integer;
        Amount: Decimal;
        PrevAmount: Decimal;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostCenter(CostCenter);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Setup page:
        CostBudgetPerPeriodPage.OpenEdit();
        SetFieldsOnCostBudgetPerPeriodPage(
          CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), CostBudgetName.Name, CostCenter.Code, '');

        ColumnNo := LibraryRandom.RandInt(12); // pick a random column for the matrix page
        Amount := LibraryRandom.RandDec(100, 2);
        if GetCellValueOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, ColumnNo) = '' then
            PrevAmount := 0
        else
            Evaluate(PrevAmount, GetCellValueOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, ColumnNo));

        // Exercise:
        SetCellValueOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, ColumnNo, Amount);

        // Verify:
        VerifyCostBudgetEntry(
          CostBudgetName.Name, CostCenter.Code, '', CostBudgetPerPeriodPage.MatrixForm."No.".Value,
          CalcDate(StrSubstNo('<%1 D>', ColumnNo - 1), WorkDate()), Amount - PrevAmount);

        // Tear-down
        CostBudgetPerPeriodPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectFirstSet()
    var
        CostObject: Record "Cost Object";
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        i: Integer;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        // we need at least 24 cost objects
        CheckCreateCostObjects();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetByCostObjectPage.OpenEdit();
        CostObject.SetCurrentKey("Sorting Order");
        CostObject.SetRange("Line Type", CostObject."Line Type"::"Cost Object");
        CostObject.FindSet();
        for i := 1 to 12 do begin
            VerifyCostBudgetByCostObjectCaption(CostBudgetByCostObjectPage, i, CostObject.Code);
            CostObject.Next();
        end;
        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectPrevSetNoError()
    var
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
    begin
        // No error when the previous set doesn't exist
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetByCostObjectPage.OpenEdit();
        CostBudgetByCostObjectPage.PreviousSet.Invoke();
        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectPrevSetNoErrorIfPrevSetLessMaximumSetLength()
    var
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
    begin
        // [SCENARIO 414679] No error when previous set exists and step is less than MaximumSetLength
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CheckCreateCostObjects();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetByCostObjectPage.OpenEdit();
        CostBudgetByCostObjectPage.NextColumn.Invoke();
        CostBudgetByCostObjectPage.PreviousSet.Invoke();
        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectPrevSetOK()
    var
        CostObject: Record "Cost Object";
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        i: Integer;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CheckCreateCostObjects();

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetByCostObjectPage.OpenEdit();
        // get the next set
        CostBudgetByCostObjectPage.NextSet.Invoke();
        // verify that the current set is the next one (check just 1 column)
        VerifyCostBudgetByCostObjectCaptionOffset(CostBudgetByCostObjectPage, 12, CostObject);
        // get the previous set:
        CostBudgetByCostObjectPage.PreviousSet.Invoke();
        CostObject.Next(-12);
        // verify the full set
        for i := 1 to 12 do begin
            VerifyCostBudgetByCostObjectCaption(CostBudgetByCostObjectPage, i, CostObject.Code);
            CostObject.Next();
        end;
        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectPrevColumn()
    var
        CostObject: Record "Cost Object";
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        i: Integer;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CheckCreateCostObjects();

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetByCostObjectPage.OpenEdit();
        // get the next set
        CostBudgetByCostObjectPage.NextSet.Invoke();
        // verify that the current set is the next one (check just 1 column)
        VerifyCostBudgetByCostObjectCaptionOffset(CostBudgetByCostObjectPage, 12, CostObject);
        // get the previous Column:
        CostBudgetByCostObjectPage.PreviousColumn.Invoke();
        CostObject.Next(-1);
        // verify the full set
        for i := 1 to 12 do begin
            VerifyCostBudgetByCostObjectCaption(CostBudgetByCostObjectPage, i, CostObject.Code);
            CostObject.Next();
        end;
        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectNextSet()
    var
        CostObject: Record "Cost Object";
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        i: Integer;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CheckCreateCostObjects();

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetByCostObjectPage.OpenEdit();
        // get the next set
        CostBudgetByCostObjectPage.NextSet.Invoke();
        // verify that the current set is the next one (check just 1 column)
        VerifyCostBudgetByCostObjectCaptionOffset(CostBudgetByCostObjectPage, 12, CostObject);
        CostObject.Next();
        // verify the full set
        for i := 2 to 12 do begin
            VerifyCostBudgetByCostObjectCaption(CostBudgetByCostObjectPage, i, CostObject.Code);
            CostObject.Next()
        end;
        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectNextSetToEnd()
    var
        CostObject: Record "Cost Object";
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        i: Integer;
        NoOfSets: Integer;
        NoInLastSet: Integer;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CheckCreateCostObjects();

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetByCostObjectPage.OpenEdit();
        // get the last set
        CostObject.SetCurrentKey("Sorting Order");
        CostObject.SetRange("Line Type", CostObject."Line Type"::"Cost Object");
        CostObject.FindSet();
        NoOfSets := CostObject.Count div 12;
        NoInLastSet := CostObject.Count mod 12;
        for i := 1 to NoOfSets do begin
            CostBudgetByCostObjectPage.NextSet.Invoke();
            CostObject.Next(12)
        end;
        // verify the full set
        for i := 1 to NoInLastSet do begin
            VerifyCostBudgetByCostObjectCaption(CostBudgetByCostObjectPage, i, CostObject.Code);
            CostObject.Next();
        end;
        // Verify the rest of the columns is blank
        if NoInLastSet <> 0 then
            for i := NoInLastSet + 1 to 12 do begin
                VerifyCostBudgetByCostObjectCaption(CostBudgetByCostObjectPage, i, ' ');
                CostObject.Next();
            end;
        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectNextColumn()
    var
        CostObject: Record "Cost Object";
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        i: Integer;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CheckCreateCostObjects();

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetByCostObjectPage.OpenEdit();
        // get the next set
        CostBudgetByCostObjectPage.NextColumn.Invoke();
        // verify that the current set is the next one (check just 1 column)
        VerifyCostBudgetByCostObjectCaptionOffset(CostBudgetByCostObjectPage, 1, CostObject);
        CostObject.Next();
        // verify the full set
        for i := 2 to 12 do begin
            VerifyCostBudgetByCostObjectCaption(CostBudgetByCostObjectPage, i, CostObject.Code);
            CostObject.Next();
        end;
        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectAmountTypeNetChangeForPeriodDay()
    var
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetByCostObjectPage.OpenEdit();
        SetFieldsOnCostBudgetByCostObjectPage(CostBudgetByCostObjectPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '');

        Assert.AreEqual(Format(WorkDate()), CostBudgetByCostObjectPage.FILTER.GetFilter("Date Filter"), DateFilterError);
        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectAmountTypeBalanceAtDateForPeriodDay()
    var
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        ExpectedDate := OpenCostBudgetByCostObjectPage(
            CostBudgetByCostObjectPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Day), '');
        Assert.AreEqual(StrSubstNo('''''..%1', ExpectedDate), CostBudgetByCostObjectPage.FILTER.GetFilter("Date Filter"), DateFilterError);

        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectAmountTypeNetChangeForPeriodMonth()
    var
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        ExpectedDate := OpenCostBudgetByCostObjectPage(
            CostBudgetByCostObjectPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Month), '');
        Assert.AreEqual(
          StrSubstNo('''''..%1', CalcDate('<CM>', ExpectedDate)), CostBudgetByCostObjectPage.FILTER.GetFilter("Date Filter"),
          DateFilterError);

        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectAmountTypeBalanceAtDatePeriodMonth()
    var
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        ExpectedDate := OpenCostBudgetByCostObjectPage(
            CostBudgetByCostObjectPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Month), '');

        Assert.AreEqual(
          StrSubstNo('''''..%1', CalcDate('<CM>', ExpectedDate)), CostBudgetByCostObjectPage.FILTER.GetFilter("Date Filter"),
          DateFilterError);

        CostBudgetByCostObjectPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostObjectValidateBudgetFilter()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostType: Record "Cost Type";
        CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object";
        BudgetFilter: Text;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetByCostObjectPage.OpenEdit();
        BudgetFilter := CopyStr(LibraryUtility.GenerateRandomCode(CostBudgetName.FieldNo(Name), DATABASE::"Cost Budget Name"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Budget Name", CostBudgetName.FieldNo(Name)));
        CostBudgetByCostObjectPage.BudgetFilter.SetValue(BudgetFilter);

        Assert.AreNotEqual(BudgetFilter, CostType."Budget Filter", StrSubstNo(ExpectedValueDifferent, CostType.FieldName("Budget Filter")));

        CostBudgetByCostObjectPage.Close();
        CostType.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterFirstSet()
    var
        CostCenter: Record "Cost Center";
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        i: Integer;
    begin
        Initialize();
        // we need at least 24 cost objects
        CheckCreateCostCenters();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetByCostCenterPage.OpenEdit();
        CostCenter.SetCurrentKey("Sorting Order");
        CostCenter.SetRange("Line Type", CostCenter."Line Type"::"Cost Center");
        CostCenter.FindSet();
        for i := 1 to 12 do begin
            VerifyCostBudgetByCostCenterCaption(CostBudgetByCostCenterPage, i, CostCenter.Code);
            CostCenter.Next();
        end;
        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCosCenterPrevSetNoError()
    var
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
    begin
        // No error when the previous set doesn't exist
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetByCostCenterPage.OpenEdit();
        CostBudgetByCostCenterPage.PreviousSet.Invoke();
        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterPrevSetNoErrorIfPrevSetLessMaximumSetLength()
    var
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
    begin
        // [SCENARIO 414679] No error when previous set exists and step is less than MaximumSetLength
        Initialize();
        CheckCreateCostCenters();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetByCostCenterPage.OpenEdit();
        CostBudgetByCostCenterPage.NextColumn.Invoke();
        CostBudgetByCostCenterPage.PreviousSet.Invoke();
        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterPrevSetOK()
    var
        CostCenter: Record "Cost Center";
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        i: Integer;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CheckCreateCostCenters();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetByCostCenterPage.OpenEdit();
        // get the next set
        CostBudgetByCostCenterPage.NextSet.Invoke();
        // verify that the current set is the next one (check just 1 column)
        VerifyCostBudgetByCostCenterCaptionOffset(CostBudgetByCostCenterPage, 12, CostCenter);
        // get the previous set:
        CostBudgetByCostCenterPage.PreviousSet.Invoke();
        CostCenter.Next(-12);
        // verify the full set
        for i := 1 to 12 do begin
            VerifyCostBudgetByCostCenterCaption(CostBudgetByCostCenterPage, i, CostCenter.Code);
            CostCenter.Next();
        end;
        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterPrevColumn()
    var
        CostCenter: Record "Cost Center";
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        i: Integer;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CheckCreateCostCenters();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetByCostCenterPage.OpenEdit();
        // get the next set
        CostBudgetByCostCenterPage.NextSet.Invoke();
        // verify that the current set is the next one (check just 1 column)
        VerifyCostBudgetByCostCenterCaptionOffset(CostBudgetByCostCenterPage, 12, CostCenter);
        // get the previous Column:
        CostBudgetByCostCenterPage.PreviousColumn.Invoke();
        CostCenter.Next(-1);
        // verify the full set
        for i := 1 to 12 do begin
            VerifyCostBudgetByCostCenterCaption(CostBudgetByCostCenterPage, i, CostCenter.Code);
            CostCenter.Next();
        end;
        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterNextSet()
    var
        CostCenter: Record "Cost Center";
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        i: Integer;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CheckCreateCostCenters();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetByCostCenterPage.OpenEdit();
        // get the next set
        CostBudgetByCostCenterPage.NextSet.Invoke();
        // verify that the current set is the next one (check just 1 column)
        VerifyCostBudgetByCostCenterCaptionOffset(CostBudgetByCostCenterPage, 12, CostCenter);
        CostCenter.Next();
        // verify the full set
        for i := 2 to 12 do begin
            VerifyCostBudgetByCostCenterCaption(CostBudgetByCostCenterPage, i, CostCenter.Code);
            CostCenter.Next();
        end;
        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterNextSetToEnd()
    var
        CostCenter: Record "Cost Center";
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        i: Integer;
        NoOfSets: Integer;
        NoInLastSet: Integer;
    begin
        Initialize();
        CheckCreateCostCenters();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetByCostCenterPage.OpenEdit();
        // get the last set
        CostCenter.SetCurrentKey("Sorting Order");
        CostCenter.SetRange("Line Type", CostCenter."Line Type"::"Cost Center");
        CostCenter.FindSet();
        NoOfSets := CostCenter.Count div 12;
        NoInLastSet := CostCenter.Count mod 12;
        for i := 1 to NoOfSets do begin
            CostBudgetByCostCenterPage.NextSet.Invoke();
            CostCenter.Next(12)
        end;
        // verify the full set
        for i := 1 to NoInLastSet do begin
            VerifyCostBudgetByCostCenterCaption(CostBudgetByCostCenterPage, i, CostCenter.Code);
            CostCenter.Next();
        end;
        // Verify the rest of the columns is blank
        if NoInLastSet <> 0 then
            for i := NoInLastSet + 1 to 12 do begin
                VerifyCostBudgetByCostCenterCaption(CostBudgetByCostCenterPage, i, ' ');
                CostCenter.Next();
            end;
        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterNextColumn()
    var
        CostCenter: Record "Cost Center";
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        i: Integer;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CheckCreateCostCenters();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetByCostCenterPage.OpenEdit();
        // get the next set
        CostBudgetByCostCenterPage.NextColumn.Invoke();
        // verify that the current set is the next one (check just 1 column)
        VerifyCostBudgetByCostCenterCaptionOffset(CostBudgetByCostCenterPage, 1, CostCenter);
        CostCenter.Next();
        // verify the full set
        for i := 2 to 12 do begin
            VerifyCostBudgetByCostCenterCaption(CostBudgetByCostCenterPage, i, CostCenter.Code);
            CostCenter.Next();
        end;
        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterAmountTypeNetChangeForPeriodDay()
    var
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetByCostCenterPage.OpenEdit();
        SetFieldsOnCostBudgetByCostCenterPage(CostBudgetByCostCenterPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '');

        Assert.AreEqual(Format(WorkDate()), CostBudgetByCostCenterPage.FILTER.GetFilter("Date Filter"), DateFilterError);
        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterAmountTypeBalanceAtDateForPeriodDay()
    var
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        ExpectedDate :=
          OpenCostBudgetByCostCenterPage(CostBudgetByCostCenterPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Day), '');
        Assert.AreEqual(StrSubstNo('''''..%1', ExpectedDate), CostBudgetByCostCenterPage.FILTER.GetFilter("Date Filter"), DateFilterError);

        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterAmountTypeNetChangeForPeriodMonth()
    var
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        ExpectedDate :=
          OpenCostBudgetByCostCenterPage(CostBudgetByCostCenterPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Month), '');
        Assert.AreEqual(
          StrSubstNo('%1..%2', CalcDate('<CM-30D>', ExpectedDate), CalcDate('<CM>', ExpectedDate)),
          CostBudgetByCostCenterPage.FILTER.GetFilter("Date Filter"), DateFilterError);

        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterAmountTypeBalanceAtDatePeriodMonth()
    var
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        ExpectedDate :=
          OpenCostBudgetByCostCenterPage(CostBudgetByCostCenterPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Month), '');
        Assert.AreEqual(
          StrSubstNo('''''..%1', CalcDate('<CM>', ExpectedDate)), CostBudgetByCostCenterPage.FILTER.GetFilter("Date Filter"),
          DateFilterError);

        CostBudgetByCostCenterPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetByCostCenterValidateBudgetFilter()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostType: Record "Cost Type";
        CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center";
        BudgetFilter: Text;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostBudgetByCostCenterPage.OpenEdit();
        BudgetFilter := CopyStr(LibraryUtility.GenerateRandomCode(CostBudgetName.FieldNo(Name), DATABASE::"Cost Budget Name"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Budget Name", CostBudgetName.FieldNo(Name)));
        CostBudgetByCostCenterPage.BudgetFilter.SetValue(BudgetFilter);

        Assert.AreNotEqual(BudgetFilter, CostType."Budget Filter", StrSubstNo(ExpectedValueDifferent, CostType.FieldName("Budget Filter")));

        CostBudgetByCostCenterPage.Close();
        CostType.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetAmountTypeNetChangeForPeriodDay()
    var
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        ExpectedDate: Date;
    begin
        // [FEATURE] [Date Filter]
        // [SCENARIO 210915] "Date Filter" is equal Work Date on "Cost Type Balance/Budget" page when "Amount Type" = "Net Change" and "Period Type" = Day

        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        // [GIVEN] Work Date = 01.01.2017
        // [GIVEN] "Cost Type Balance/Budget" page is opened
        CostTypeBalanceBudgetPage.OpenEdit();
        ExpectedDate := GetCurrentDate(CostTypeBalanceBudgetPage.FILTER.GetFilter("Date Filter"));

        // [WHEN] Set "Amount Type" = "Net Change" and "Period Type" = Day on "Cost Type Balance/Budget" page
        SetFieldsOnCostTypeBalanceBudgetPage(
          CostTypeBalanceBudgetPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '', '', '');

        // [THEN] "Date Filter" is 01.01.2017 on "Cost Type Balance/Budget" page
        CostTypeBalanceBudgetPage.DateFilter.AssertEquals(ExpectedDate);

        CostTypeBalanceBudgetPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetAmountTypeBalanceAtDateForPeriodDay()
    var
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        ExpectedDate: Date;
    begin
        // [FEATURE] [Date Filter]
        // [SCENARIO 210915] "Date Filter" is filter "up to date" on "Cost Type Balance/Budget" page when "Amount Type" = "Balance at Date" and "Period Type" = Day

        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        // [GIVEN] Work Date = 01.01.2017
        // [GIVEN] "Cost Type Balance/Budget" page is opened
        CostTypeBalanceBudgetPage.OpenEdit();
        ExpectedDate := GetCurrentDate(CostTypeBalanceBudgetPage.FILTER.GetFilter("Date Filter"));

        // [WHEN] Set "Amount Type" = "Balance at Date" and "Period Type" = Day on "Cost Type Balance/Budget" page
        SetFieldsOnCostTypeBalanceBudgetPage(
          CostTypeBalanceBudgetPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Day), '', '', '');

        // [THEN] "Date Filter" is "..01.01.2017" on "Cost Type Balance/Budget" page
        CostTypeBalanceBudgetPage.DateFilter.AssertEquals(StrSubstNo('''''..%1', ExpectedDate));

        CostTypeBalanceBudgetPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetAmountTypeNetChangeForPeriodMonth()
    var
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        ExpectedDate: Date;
    begin
        // [FEATURE] [Date Filter]
        // [SCENARIO 210915] "Date Filter" is filter from beginning of month to the end of month according to Work Date on "Cost Type Balance/Budget" page when "Amount Type" = "Net Change" and "Period Type" = Month

        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        // [GIVEN] Work Date = 01.01.2017
        // [GIVEN] "Cost Type Balance/Budget" page is opened
        CostTypeBalanceBudgetPage.OpenEdit();
        ExpectedDate := GetCurrentDate(CostTypeBalanceBudgetPage.FILTER.GetFilter("Date Filter"));

        // [WHEN] Set "Amount Type" = "Net Change" and "Period Type" = Month on "Cost Type Balance/Budget" page
        SetFieldsOnCostTypeBalanceBudgetPage(
          CostTypeBalanceBudgetPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Month), '', '', '');

        // [THEN] "Date Filter" is "01.01.2017..31.01.2017" on "Cost Type Balance/Budget" page
        CostTypeBalanceBudgetPage.DateFilter.AssertEquals(
          StrSubstNo('%1..%2', CalcDate('<-CM>', ExpectedDate), CalcDate('<CM>', ExpectedDate)));

        CostTypeBalanceBudgetPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetAmountTypeBalanceAtDatePeriodMonth()
    var
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        ExpectedDate: Date;
    begin
        // [FEATURE] [Date Filter]
        // [SCENARIO 210915] "Date Filter" is filter "up to the end of month" according to Work Date on "Cost Type Balance/Budget" page when "Amount Type" = "Balance at Date" and "Period Type" = Month

        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        // [GIVEN] Work Date = 01.01.2017
        // [GIVEN] "Cost Type Balance/Budget" page is opened
        CostTypeBalanceBudgetPage.OpenEdit();
        ExpectedDate := GetCurrentDate(CostTypeBalanceBudgetPage.FILTER.GetFilter("Date Filter"));

        // [WHEN] Set "Amount Type" = "Balance at Date" and "Period Type" = Month on "Cost Type Balance/Budget" page
        SetFieldsOnCostTypeBalanceBudgetPage(
          CostTypeBalanceBudgetPage, Format("Analysis Amount Type"::"Balance at Date"), Format("Analysis Period Type"::Month), '', '', '');

        // [THEN] "Date Filter" is "..31.01.2017" on "Cost Type Balance/Budget" page
        CostTypeBalanceBudgetPage.DateFilter.AssertEquals(StrSubstNo('''''..%1', CalcDate('<CM>', ExpectedDate)));

        CostTypeBalanceBudgetPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetAmountNextPeriodAction()
    var
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        ExpectedDate: Date;
    begin
        // [FEATURE] [Date Filter]
        // [SCENARIO 210915] "Date Filter" is changed to next period on "Cost Type Balance/Budget" page when press "Next Period"

        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        // [GIVEN] Work Date = 01.01.2017
        // [GIVEN] "Cost Type Balance/Budget" page is opened
        // [GIVEN] "Amount Type" = "Net Change" and "Period Type" = Month on "Cost Type Balance/Budget" page
        ExpectedDate :=
          CalcDate('<1M>', OpenCostTypeBalanceBudgetPage(
              CostTypeBalanceBudgetPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Month), '', '', ''));

        // [WHEN] Press "Next Period" on "Cost Type Balance/Budget" page
        CostTypeBalanceBudgetPage.NextPeriod.Invoke();

        // [THEN] "Date Filter" is "01.02.2017..28.02.2017" on "Cost Type Balance/Budget" page
        CostTypeBalanceBudgetPage.DateFilter.AssertEquals(
          StrSubstNo('%1..%2', CalcDate('<-CM>', ExpectedDate), CalcDate('<CM>', ExpectedDate)));

        CostTypeBalanceBudgetPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetAmountPreviousPeriodAction()
    var
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        ExpectedDate: Date;
    begin
        // [FEATURE] [Date Filter]
        // [SCENARIO 210915] "Date Filter" is changed to previous period on "Cost Type Balance/Budget" page when press "Previous Period"

        Initialize();

        LibraryLowerPermissions.SetCostAccountingEdit();
        // [GIVEN] Work Date = 01.01.2017
        // [GIVEN] "Cost Type Balance/Budget" page is opened
        // [GIVEN] "Amount Type" = "Net Change" and "Period Type" = Month on "Cost Type Balance/Budget" page
        ExpectedDate :=
          CalcDate('<-1M>', OpenCostTypeBalanceBudgetPage(
              CostTypeBalanceBudgetPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Month), '', '', ''));

        // [WHEN] Press "Previous Period" on "Cost Type Balance/Budget" page
        CostTypeBalanceBudgetPage.PreviousPeriod.Invoke();

        // [THEN] "Date Filter" is "01.12.2016..31.12.2016" on "Cost Type Balance/Budget" page
        CostTypeBalanceBudgetPage.DateFilter.AssertEquals(
          StrSubstNo('%1..%2', CalcDate('<-CM>', ExpectedDate), CalcDate('<CM>', ExpectedDate)));

        CostTypeBalanceBudgetPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetCalcBudgetPctForBudgetAmountNonZero()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostCenter: Record "Cost Center";
        CostType: Record "Cost Type";
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        NetChange: Decimal;
        BudgetAmount: Decimal;
        PostingDate: Date;
    begin
        Initialize();

        // Setup:
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Exercise:
        CostTypeBalanceBudgetPage.OpenEdit();
        SetFieldsOnCostTypeBalanceBudgetPage(
          CostTypeBalanceBudgetPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), CostBudgetName.Name, '', '');
        Evaluate(PostingDate, CostTypeBalanceBudgetPage.FILTER.GetFilter("Date Filter"));
        NetChange := PostCostJournalLine(CostType."No.", CostCenter.Code, '', PostingDate);
        BudgetAmount := CreateBudgetEntry(CostBudgetName.Name, CostType."No.", PostingDate);
        CostTypeBalanceBudgetPage.GotoRecord(CostType);

        // Verify:
        CostTypeBalanceBudgetPage.BudgetPct.AssertEquals(Round(NetChange / BudgetAmount * 100));

        // Clean-up:
        CostType.Delete();
        CostBudgetName.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetCalcBudgetPctForBudgetAmountZero()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostCenter: Record "Cost Center";
        CostType: Record "Cost Type";
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        PostingDate: Date;
    begin
        Initialize();

        // Setup:
        // Create Net Change and Create Budget
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Exercise:
        CostTypeBalanceBudgetPage.OpenEdit();
        SetFieldsOnCostTypeBalanceBudgetPage(
          CostTypeBalanceBudgetPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), CostBudgetName.Name, '', '');
        Evaluate(PostingDate, CostTypeBalanceBudgetPage.FILTER.GetFilter("Date Filter"));
        PostCostJournalLine(CostType."No.", CostCenter.Code, '', PostingDate);
        CostTypeBalanceBudgetPage.GotoRecord(CostType);

        // Verify:
        CostTypeBalanceBudgetPage.BudgetPct.AssertEquals(0);

        // Clean-up:
        CostBudgetName.Delete(true);
        CostType.Delete();
    end;

    [Test]
    [HandlerFunctions('MFHandlerChartOfCostCenters')]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetLookupCostCenter()
    var
        CostCenter: Record "Cost Center";
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Setup:
        CostCenter.FindFirst();
        CostCenterFilter := SelectionFilterManagement.AddQuotes(CostCenter.Code);
        CostTypeBalanceBudgetPage.OpenEdit();

        // Exercise:
        CostTypeBalanceBudgetPage.CostCenterFilter.Lookup();

        // Verify:
        CostTypeBalanceBudgetPage.CostCenterFilter.AssertEquals(CostCenterFilter);
    end;

    [Test]
    [HandlerFunctions('MFHandlerChartOfCostObjects')]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetLookupCostObject()
    var
        CostObject: Record "Cost Object";
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Setup:
        CostObject.FindFirst();
        CostObjectFilter := SelectionFilterManagement.AddQuotes(CostObject.Code);
        CostTypeBalanceBudgetPage.OpenEdit();

        // Exercise:
        CostTypeBalanceBudgetPage.CostObjectFilter.Lookup();

        // Verify:
        CostTypeBalanceBudgetPage.CostObjectFilter.AssertEquals(CostObjectFilter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetNextPeriodAction()
    var
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Setup:
        ExpectedDate :=
          OpenCostTypeBalanceBudgetPage(CostTypeBalanceBudgetPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '', '', '');

        // Exercise:
        CostTypeBalanceBudgetPage.NextPeriod.Invoke();

        // Verify:
        Assert.AreEqual(Format(CalcDate('<1D>', ExpectedDate)), CostTypeBalanceBudgetPage.FILTER.GetFilter("Date Filter"), DateFilterError);

        // Clean-up:
        CostTypeBalanceBudgetPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetPreviousPeriodAction()
    var
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        ExpectedDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Setup:
        ExpectedDate :=
          OpenCostTypeBalanceBudgetPage(CostTypeBalanceBudgetPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '', '', '');

        // Exercise:
        CostTypeBalanceBudgetPage.PreviousPeriod.Invoke();

        // Verify:
        Assert.AreEqual(
          Format(CalcDate('<-1D>', ExpectedDate)), CostTypeBalanceBudgetPage.FILTER.GetFilter("Date Filter"), DateFilterError);

        // Clean-up:
        CostTypeBalanceBudgetPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetUpdateBudgetAmount()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostCenter: Record "Cost Center";
        CostType: Record "Cost Type";
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        BudgetAmount: Decimal;
        NetChange: Decimal;
        PostingDate: Date;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        // Setup:
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Setup Cost Type Balance/Budget page:
        CostTypeBalanceBudgetPage.OpenEdit();
        SetFieldsOnCostTypeBalanceBudgetPage(
          CostTypeBalanceBudgetPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), CostBudgetName.Name, CostCenter.Code, '');
        Evaluate(PostingDate, CostTypeBalanceBudgetPage.FILTER.GetFilter("Date Filter"));
        NetChange := PostCostJournalLine(CostType."No.", CostCenter.Code, '', PostingDate);
        CostTypeBalanceBudgetPage.GotoRecord(CostType);

        // Exercise:
        BudgetAmount := LibraryRandom.RandDec(100, 2);
        CostTypeBalanceBudgetPage."Budget Amount".SetValue(BudgetAmount);

        // Verify:
        CostTypeBalanceBudgetPage.BudgetPct.AssertEquals(Round(NetChange / BudgetAmount * 100));

        // Clean-up:
        CostType.Delete();
        CostBudgetName.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetValidateBudgetFilter()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostType: Record "Cost Type";
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        BudgetFilter: Text;
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostTypeBalanceBudgetPage.OpenEdit();
        BudgetFilter := CopyStr(LibraryUtility.GenerateRandomCode(CostBudgetName.FieldNo(Name), DATABASE::"Cost Budget Name"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Budget Name", CostBudgetName.FieldNo(Name)));
        CostTypeBalanceBudgetPage.BudgetFilter.SetValue(BudgetFilter);

        Assert.AreNotEqual(BudgetFilter, CostType."Budget Filter", StrSubstNo(ExpectedValueDifferent, CostType.FieldName("Budget Filter")));

        CostTypeBalanceBudgetPage.Close();
        CostType.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetValidateCostCenterFilter()
    var
        CostCenter: Record "Cost Center";
        CostType: Record "Cost Type";
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        CostCenterCode: Code[20];
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostTypeBalanceBudgetPage.OpenEdit();
        CostCenterCode := CopyStr(LibraryUtility.GenerateRandomCode(CostCenter.FieldNo(Code), DATABASE::"Cost Center"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Center", CostCenter.FieldNo(Code)));

        CostTypeBalanceBudgetPage.CostCenterFilter.SetValue(CostCenterCode);

        Assert.AreNotEqual(
          CostCenterCode, CostType."Cost Center Filter", StrSubstNo(ExpectedValueDifferent, CostType.FieldName("Cost Center Filter")));

        CostTypeBalanceBudgetPage.Close();
        CostType.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceBudgetValidateCostObjectFilter()
    var
        CostObject: Record "Cost Object";
        CostType: Record "Cost Type";
        CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget";
        CostObjectCode: Code[20];
    begin
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostTypeBalanceBudgetPage.OpenView();
        CostObjectCode := CopyStr(LibraryUtility.GenerateRandomCode(CostObject.FieldNo(Code), DATABASE::"Cost Object"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Cost Object", CostObject.FieldNo(Code)));
        CostTypeBalanceBudgetPage.CostObjectFilter.SetValue(CostObjectCode);

        Assert.AreNotEqual(
          CostObjectCode, CostType."Cost Object Filter", StrSubstNo(ExpectedValueDifferent, CostType.FieldName("Cost Object Filter")));

        CostTypeBalanceBudgetPage.Close();
        CostType.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceAmountTypeBalanceAtDate()
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        ValidateCostTypeBalanceAmountType("Analysis Amount Type"::"Balance at Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceAmountTypeNetChange()
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        ValidateCostTypeBalanceAmountType("Analysis Amount Type"::"Net Change");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceUpdateCostCenterFilter()
    var
        CostType: Record "Cost Type";
        CostTypeBalance: TestPage "Cost Type Balance";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Setup
        CostType.SetFilter("Cost Center Code", '<>%1', '');
        CostType.FindFirst();

        // Exercise
        CostTypeBalance.OpenEdit();
        UpdateCostTypeBalanceFilters(
          CostTypeBalance, CostType."Cost Center Code", '', "Analysis Period Type"::Day, "Analysis Amount Type"::"Balance at Date", "Analysis Rounding Factor"::None);

        // Verify
        CostType.TestField("Cost Center Code", Format(CostTypeBalance.MatrixForm.FILTER.GetFilter("Cost Center Filter")));

        // Cleanup
        CostTypeBalance.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceUpdateCostObjectFilter()
    var
        CostType: Record "Cost Type";
        CostTypeBalance: TestPage "Cost Type Balance";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Setup
        CostType.SetFilter("Cost Object Code", '<>%1', '');
        CostType.FindFirst();

        // Exercise
        CostTypeBalance.OpenEdit();
        UpdateCostTypeBalanceFilters(
          CostTypeBalance, '', CostType."Cost Object Code", "Analysis Period Type"::Day, "Analysis Amount Type"::"Balance at Date", "Analysis Rounding Factor"::None);

        // Verify
        CostType.TestField("Cost Object Code", Format(CostTypeBalance.MatrixForm.FILTER.GetFilter("Cost Object Filter")));

        // Cleanup
        CostTypeBalance.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceRoundingFactor()
    var
        CostType: Record "Cost Type";
        CostTypeBalance: TestPage "Cost Type Balance";
        SelectedRoundingFactor: Enum "Analysis Rounding Factor";
    begin
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Setup
        LibraryCostAccounting.GetAllCostTypes(CostType);

        // Pre-Setup
        CostType.SetFilter("Date Filter", '%1', WorkDate());
        CostType.CalcFields("Balance at Date");
        SelectedRoundingFactor := "Analysis Rounding Factor".FromInteger(LibraryRandom.RandInt(4) - 1);

        // Exercise
        CostTypeBalance.OpenEdit();
        CostTypeBalance.FILTER.SetFilter("Date Filter", Format(WorkDate()));
        UpdateCostTypeBalanceFilters(
            CostTypeBalance, '', '', "Analysis Period Type"::Day, "Analysis Amount Type"::"Balance at Date", SelectedRoundingFactor);

        // Verify
        CostType.SetFilter("Balance at Date", '<>%1', 0);
        CostType.FindFirst();
        CostTypeBalance.MatrixForm.GotoRecord(CostType);
        CostTypeBalance.MatrixForm.Column1.AssertEquals(
          CostTypeBalanceWithRoundingFactor(CostType."Balance at Date", SelectedRoundingFactor));

        // Cleanup
        CostTypeBalance.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodPageValidateCostCenter()
    var
        CostCenter: Record "Cost Center";
        CostType: Record "Cost Type";
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
        CostBudgetAmount: Text[30];
        ExpectedAmount: Decimal;
    begin
        // Check that the OnValidate of Cost Center Filter field on Cost Budget Per Period Page works correctly.

        // Setup: Create new Cost Type, Cost Center and Cost Budget Name.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Exercise: Creating Cost Budget Entry and setting the filters on Cost Budget Per Period page.
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName.Name);
        UpdateCostBudgetEntry(CostBudgetEntry, CostType."No.", CostCenter.Code, '');
        ExpectedAmount := CostBudgetEntry.Amount;

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetPerPeriodPage.OpenEdit();
        SetFieldsOnCostBudgetPerPeriodPage(
          CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), CostBudgetName.Name, CostCenter.Code, '');
        CostBudgetAmount := GetColumnAmountOnCostBudgetPerPeriodChange(CostBudgetPerPeriodPage, CostType."No.");

        // Verify: Verify the Expected Amount with the column value of matrix page.
        Assert.AreEqual(Format(ExpectedAmount, 0, '<Precision,2><Standard Format,1>'), CostBudgetAmount,
          StrSubstNo(
            CostBudgetAmountError, CostType.TableCaption(), CostType."No.", CostBudgetPerPeriodPage.MatrixForm.Column1.Caption,
            CostBudgetEntry.TableCaption(), CostBudgetEntry."Entry No."));

        // Tear Down.
        CostBudgetPerPeriodPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodPageValidateCostObject()
    var
        CostObject: Record "Cost Object";
        CostType: Record "Cost Type";
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
        CostBudgetAmount: Text[30];
        ExpectedAmount: Decimal;
    begin
        // Check that the OnValidate of Cost Object Filter field on Cost Budget Per Period Page works correctly.

        // Setup: Create new Cost Type, Cost Object and Cost Budget Name.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostObject(CostObject);
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Exercise: Creating Cost Budget Entry and setting the filters on Cost Budget Per Period page.
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName.Name);
        UpdateCostBudgetEntry(CostBudgetEntry, CostType."No.", '', CostObject.Code);
        ExpectedAmount := CostBudgetEntry.Amount;

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetPerPeriodPage.OpenEdit();
        SetFieldsOnCostBudgetPerPeriodPage(
          CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), CostBudgetName.Name, '', CostObject.Code);
        CostBudgetAmount := GetColumnAmountOnCostBudgetPerPeriodChange(CostBudgetPerPeriodPage, CostType."No.");

        // Verify: Verify the Expected Amount with the column value of matrix page.
        Assert.AreEqual(Format(ExpectedAmount, 0, '<Precision,2><Standard Format,1>'), CostBudgetAmount,
          StrSubstNo(
            CostBudgetAmountError, CostType.TableCaption(), CostType."No.", CostBudgetPerPeriodPage.MatrixForm.Column1.Caption,
            CostBudgetEntry.TableCaption(), CostBudgetEntry."Entry No."));

        // Tear Down.
        CostBudgetPerPeriodPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodNextSetAction()
    var
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
        ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set";
        DateBeforeInvokingAction: Date;
        DateAfterInvokingAction: Date;
    begin
        // Check that the OnValidate of Action Next Set is properly working or not.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetPerPeriodPage.OpenEdit();

        // Exercise: Get the Date caption of the Matrix Form before invoking the Next Set and after invoking the Next Set.
        SetFieldsOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '', '', '');
        GetColumnDatesOnCostBudgetPerPeriodPage(
          CostBudgetPerPeriodPage, DateBeforeInvokingAction, DateAfterInvokingAction, ActionItem::"Next Set");

        // Verify: Verify that after invoking the Next Set the Date Caption of MatrixForm is added by 12D.
        Assert.AreEqual(
          CalcDate('<12D>', DateBeforeInvokingAction), DateAfterInvokingAction, StrSubstNo(ColumnDateError, ActionItem::"Next Set"));

        // Tear Down.
        CostBudgetPerPeriodPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodPreviousSetAction()
    var
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
        ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set";
        DateBeforeInvokingAction: Date;
        DateAfterInvokingAction: Date;
    begin
        // Check that the OnValidate of Action Previous Set is properly working or not.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetPerPeriodPage.OpenEdit();

        // Exercise: Get the Date caption of the Matrix Form before invoking the Previous Set and after invoking the Previous Set.
        SetFieldsOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '', '', '');
        GetColumnDatesOnCostBudgetPerPeriodPage(
          CostBudgetPerPeriodPage, DateBeforeInvokingAction, DateAfterInvokingAction, ActionItem::"Previous Set");

        // Verify: Verify that after invoking the Previous Set the Date Caption of MatrixForm is subtracted by 12D.
        Assert.AreEqual(
          CalcDate('<-12D>', DateBeforeInvokingAction), DateAfterInvokingAction, StrSubstNo(ColumnDateError, ActionItem::"Previous Set"));

        // Tear Down.
        CostBudgetPerPeriodPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodPreviousColumnAction()
    var
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
        ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set";
        DateBeforeInvokingAction: Date;
        DateAfterInvokingAction: Date;
    begin
        // Check that the OnValidate of Action Previous Column is properly working or not.

        // Setup:
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetPerPeriodPage.OpenEdit();

        // Exercise: Get the Date caption of the Matrix Form before invoking the Previous Column and after invoking the Previous Column.
        SetFieldsOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '', '', '');
        GetColumnDatesOnCostBudgetPerPeriodPage(
          CostBudgetPerPeriodPage, DateBeforeInvokingAction, DateAfterInvokingAction, ActionItem::"Previous Column");

        // Verify: Verify that after invoking the Previous Column the Date Caption of MatrixForm is subtracted by 1D.
        Assert.AreEqual(
          CalcDate('<-1D>', DateBeforeInvokingAction), DateAfterInvokingAction, StrSubstNo(ColumnDateError, ActionItem::"Previous Column"));

        // Tear Down.
        CostBudgetPerPeriodPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodNextColumnAction()
    var
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
        ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set";
        DateBeforeInvokingAction: Date;
        DateAfterInvokingAction: Date;
    begin
        // Check that the OnValidate of Action Next Column is properly working or not.

        // Setup:
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        CostBudgetPerPeriodPage.OpenEdit();

        // Exercise: Get the Date caption of the Matrix Form before invoking the Next Column and after invoking the Next Column.
        SetFieldsOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), '', '', '');
        GetColumnDatesOnCostBudgetPerPeriodPage(
          CostBudgetPerPeriodPage, DateBeforeInvokingAction, DateAfterInvokingAction, ActionItem::"Next Column");

        // Verify: Verify that after invoking the Next Column the Date Caption of MatrixForm is added by 1D.
        Assert.AreEqual(
          CalcDate('<1D>', DateBeforeInvokingAction), DateAfterInvokingAction, StrSubstNo(ColumnDateError, ActionItem::"Next Column"));

        // Tear Down.
        CostBudgetPerPeriodPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalBatchNameError()
    var
        CostJournalPage: TestPage "Cost Journal";
    begin
        // Check that the Error is coming when we insert the wrong value in CostJnlBatchName field.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: Open Cost Journal Page and Set wrong value in CostJnlBatchName field.
        CostJournalPage.OpenEdit();
        asserterror CostJournalPage.CostJnlBatchName.SetValue(LibraryRandom.RandInt(10));  // To Set any random value so that it will give error.

        // Verify: Verify that the expected error is coming or not.
        Assert.VerifyFailure(TestValidation, FailedToGetTheExpectedValidationError);

        // Tear Down.
        CostJournalPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalBatchNameField()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalTemplate: Record "Cost Journal Template";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        CostJournalPage: TestPage "Cost Journal";
        i: Integer;
    begin
        // Check that the OnValidate of CostJnlBatchName field on Cost Journal Page works correctly.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        // Exercise: Create Cost Journal Batch and Cost Journal Line and set the vaule of Name to CostJnlBatchName.
        LibraryCostAccounting.FindCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);

        LibraryLowerPermissions.SetCostAccountingView();
        CostJournalPage.OpenEdit();
        CostJournalPage.CostJnlBatchName.SetValue(CostJournalBatch.Name);

        // Verify: Verify that OnValidate of CostJnlBatchName field on Cost Journal Page works correctly."
        while CostJournalPage.Next() do
            i := i + 1;
        Assert.AreEqual(1, i, StrSubstNo(CostJnlLineError, CostJournalLine.TableCaption()));

        // Tear Down.
        CostJournalPage.Close();
    end;

    [Test]
    [HandlerFunctions('CostJournalBatchPageHandler')]
    [Scope('OnPrem')]
    procedure TestCostJournalBatchNameLookupField()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalPage: TestPage "Cost Journal";
    begin
        // Check that the OnLookup of CostJnlBatchName field on Cost Journal Page works correctly.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        // Exercise: Creating Cost Journal Batch and Looup up the CostJnlBatchName of Cost Journal Line page and setting the newly created batch name.
        LibraryCostAccounting.FindCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);

        LibraryLowerPermissions.SetCostAccountingView();
        CostJournalBatchName := CostJournalBatch.Name;
        CostJournalPage.OpenEdit();
        CostJournalPage.CostJnlBatchName.Lookup();

        // Verify: Verify that OnLookup of CostJnlBatchName field on Cost Journal Page works correctly.
        CostJournalPage.CostJnlBatchName.AssertEquals(CostJournalBatchName);

        // Tear Down.
        CostJournalPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalValidateOnNewRecordWithoutBalCostType()
    var
        CostType: Record "Cost Type";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalPage: TestPage "Cost Journal";
    begin
        // Check that the code on OnNewRecord is suceesfully working or not.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        // Exercise: Open cost journal page and set the values on the page.
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.FindCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostJournalPage.OpenEdit();
        SetValuesOnCostJournalPage(CostJournalPage, CostJournalBatch.Name, CostType."No.", '');

        // Verify: Verify the values in the Cost Journal page.
        VerifyCostJournalLineWithoutBalCostType(CostJournalPage);

        // Tear Down.
        CostJournalPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalValidateOnNewRecordWithBalCostType()
    var
        CostType: Record "Cost Type";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalPage: TestPage "Cost Journal";
    begin
        // Check that the code on OnNewRecord is suceesfully working or not.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        // Exercise: Open cost journal page and set the values on the page.
        LibraryCostAccounting.FindCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryLowerPermissions.SetCostAccountingEdit();
        CostJournalPage.OpenEdit();
        SetValuesOnCostJournalPage(CostJournalPage, CostJournalBatch.Name, CostType."No.", CostType."No.");

        // Verify: Verify the values in the Cost Journal page.
        VerifyCostJournalLineWithBalCostType(CostJournalPage);

        // Tear Down.
        CostJournalPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceValidateCostCenter()
    var
        CostCenter: Record "Cost Center";
        CostType: Record "Cost Type";
        CostEntry: Record "Cost Entry";
        CostJournalLine: Record "Cost Journal Line";
        CostTypeBalancePage: TestPage "Cost Type Balance";
        CostTypeBalanceAmount: Text[30];
        CostJournalLineAmount: Decimal;
        CostJournaLinePostingDate: Date;
        ColoumnNo: Integer;
    begin
        // Test Amount in columns as per the Cost Center filter field on Cost Type Balance Page.

        // Setup: Create a new Cost Type and Cost Center.
        Initialize();

        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostCenter(CostCenter);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Exercise: Posting the Cost Journal Line and setting filters on Cost Type Balance Page.
        ColoumnNo := LibraryRandom.RandInt(11);
        CostJournaLinePostingDate := CalcDate(StrSubstNo('<%1D>', ColoumnNo), WorkDate());
        CostJournalLineAmount := PostCostJournalLine(CostType."No.", CostCenter.Code, '', CostJournaLinePostingDate);
        CostTypeBalanceAmount :=
          OpenCostTypeBalancePage(
            CostTypeBalancePage, Format("Analysis Period Type"::Day), Format("Analysis Amount Type"::"Balance at Date"), CostCenter.Code, '', CostType."No.",
            ColoumnNo);

        // Verify: Verify Posted Amount with the value in the Matrix form.
        Assert.AreEqual(
          Format(CostJournalLineAmount, 0, '<Precision,2><Standard Format,1>'), CostTypeBalanceAmount,
          StrSubstNo(CostJournalAmountError, CostJournalLine.TableCaption(), CostEntry.TableCaption()));

        // Tear Down.
        CostTypeBalancePage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceValidateCostObject()
    var
        CostObject: Record "Cost Object";
        CostType: Record "Cost Type";
        CostJournalLine: Record "Cost Journal Line";
        CostEntry: Record "Cost Entry";
        CostTypeBalancePage: TestPage "Cost Type Balance";
        CostTypeBalanceAmount: Text[30];
        CostJournalLineAmount: Decimal;
        CostJournaLinePostingDate: Date;
        ColoumnNo: Integer;
    begin
        // Test Amount in columns as per the Cost Object filter field on Cost Type Balance Page.

        // Setup: Create a new Cost Type and Cost Object.
        Initialize();
        LibraryCostAccounting.CreateCostObject(CostObject);
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Exercise: Posting the Cost Journal Line and setting filters on Cost Type Balance Page.
        ColoumnNo := LibraryRandom.RandInt(11);
        CostJournaLinePostingDate := CalcDate(StrSubstNo('<%1D>', ColoumnNo), WorkDate());
        CostJournalLineAmount := PostCostJournalLine(CostType."No.", '', CostObject.Code, CostJournaLinePostingDate);
        CostTypeBalanceAmount :=
          OpenCostTypeBalancePage(
            CostTypeBalancePage, Format("Analysis Period Type"::Day), Format("Analysis Amount Type"::"Balance at Date"), '', CostObject.Code, CostType."No.",
            ColoumnNo);

        // Verify: Verify Posted Amount with the value in the Matrix form.
        Assert.AreEqual(
          Format(CostJournalLineAmount, 0, '<Precision,2><Standard Format,1>'), CostTypeBalanceAmount,
          StrSubstNo(CostJournalAmountError, CostJournalLine.TableCaption(), CostEntry.TableCaption()));

        // Tear Down.
        CostTypeBalancePage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceValidateViewWeek()
    var
        CostTypeBalancePage: TestPage "Cost Type Balance";
        ActualDate: Date;
        i: Integer;
    begin
        // Test caption in columns with respect to the View by Week Filter on Cost Type Balance Page.

        // Setup
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: Setting values on CostType Balance Page.
        CostTypeBalancePage.OpenEdit();
        SetFieldsOnCostTypeBalancePage(CostTypeBalancePage, Format("Analysis Period Type"::Week), Format("Analysis Amount Type"::"Balance at Date"), '', '');

        // Verify: To Verify value of each column with respect to the ViewBy week filter.
        ActualDate := WorkDate();
        for i := 1 to 12 do begin
            VerifyFiltersOnCostTypeBalanceByViewMatrixPage(CostTypeBalancePage, "Analysis Period Type"::Week, ActualDate, i);
            ActualDate := CalcDate('<1W>', ActualDate);
        end;

        // Tear Down
        CostTypeBalancePage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceValidateViewMonth()
    var
        CostTypeBalancePage: TestPage "Cost Type Balance";
        ActualDate: Date;
        i: Integer;
    begin
        // Test caption in columns with respect to the View by  Month Filter on Cost Type Balance Page.

        // Setup
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: Setting values on CostType Balance Page.
        CostTypeBalancePage.OpenEdit();
        SetFieldsOnCostTypeBalancePage(CostTypeBalancePage, Format("Analysis Period Type"::Month), Format("Analysis Amount Type"::"Balance at Date"), '', '');

        // Verify: To Verify value of each column with respect to the ViewBy Month filter.
        ActualDate := WorkDate();
        for i := 1 to 12 do begin
            VerifyFiltersOnCostTypeBalanceByViewMatrixPage(CostTypeBalancePage, "Analysis Period Type"::Month, ActualDate, i);
            ActualDate := CalcDate('<1M>', ActualDate);
        end;

        // Tear Down
        CostTypeBalancePage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceValidateViewYear()
    var
        CostTypeBalancePage: TestPage "Cost Type Balance";
        ActualDate: Date;
        i: Integer;
    begin
        // Test caption in columns with respect to the View by Year Filter on Cost Type Balance Page.

        // Setup
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: Setting values on CostType Balance Page.
        CostTypeBalancePage.OpenEdit();
        SetFieldsOnCostTypeBalancePage(CostTypeBalancePage, Format("Analysis Period Type"::Year), Format("Analysis Amount Type"::"Balance at Date"), '', '');

        // Verify: To Verify value of each column with respect to the ViewBy Year filter.
        ActualDate := WorkDate();
        for i := 1 to 12 do begin
            VerifyFiltersOnCostTypeBalanceByViewMatrixPage(CostTypeBalancePage, "Analysis Period Type"::Year, ActualDate, i);
            ActualDate := CalcDate('<1Y>', ActualDate);
        end;

        // Tear Down
        CostTypeBalancePage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceNextColumnAction()
    var
        CostTypeBalancePage: TestPage "Cost Type Balance";
        ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set";
        DateBeforeInvokingAction: Date;
        DateAfterInvokingAction: Date;
    begin
        // Test caption value of column on invoking Next Column Action on Cost Type Balance Page.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: Evaluating Caption of Matrix form before and after invoking Next Column action.
        CostTypeBalancePage.OpenEdit();
        SetFieldsOnCostTypeBalancePage(CostTypeBalancePage, Format("Analysis Period Type"::Day), Format("Analysis Amount Type"::"Balance at Date"), '', '');
        GetColumnDatesOnCostTypeBalancePage(
          CostTypeBalancePage, DateBeforeInvokingAction, DateAfterInvokingAction, ActionItem::"Next Column");

        // Verify: Verify caption value of column on invoking Next Column Action.
        Assert.AreEqual(
          CalcDate('<1D>', DateBeforeInvokingAction), DateAfterInvokingAction, StrSubstNo(ColumnDateError, ActionItem::"Next Column"));

        // Tear Down.
        CostTypeBalancePage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalanceNextSetAction()
    var
        CostTypeBalancePage: TestPage "Cost Type Balance";
        ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set";
        DateBeforeInvokingAction: Date;
        DateAfterInvokingAction: Date;
    begin
        // Test caption value of column on invoking of Next Set Action on Cost Type Balance Page.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: Evaluating Caption of Matrix form before and after invoking Next Set action.
        CostTypeBalancePage.OpenEdit();
        SetFieldsOnCostTypeBalancePage(CostTypeBalancePage, Format("Analysis Period Type"::Day), Format("Analysis Amount Type"::"Balance at Date"), '', '');
        GetColumnDatesOnCostTypeBalancePage(CostTypeBalancePage, DateBeforeInvokingAction, DateAfterInvokingAction, ActionItem::"Next Set");

        // Verify: Verify caption value of column on invoking Next Set Action.
        Assert.AreEqual(
          CalcDate('<12D>', DateBeforeInvokingAction), DateAfterInvokingAction, StrSubstNo(ColumnDateError, ActionItem::"Next Set"));

        // Tear Down.
        CostTypeBalancePage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalancePreviousSetAction()
    var
        CostTypeBalancePage: TestPage "Cost Type Balance";
        ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set";
        DateBeforeInvokingAction: Date;
        DateAfterInvokingAction: Date;
    begin
        // Test caption value of column on invoking of Previous Set Action on Cost Type Balance Page.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: Evaluating Caption of Matrix form before and after invoking Previous Set action.
        CostTypeBalancePage.OpenEdit();
        SetFieldsOnCostTypeBalancePage(CostTypeBalancePage, Format("Analysis Period Type"::Day), Format("Analysis Amount Type"::"Balance at Date"), '', '');
        GetColumnDatesOnCostTypeBalancePage(
          CostTypeBalancePage, DateBeforeInvokingAction, DateAfterInvokingAction, ActionItem::"Previous Set");

        // Verify: Verify caption value of column on invoking Previous Set Action.
        Assert.AreEqual(
          CalcDate('<-12D>', DateBeforeInvokingAction), DateAfterInvokingAction, StrSubstNo(ColumnDateError, ActionItem::"Previous Set"));

        // Tear Down.
        CostTypeBalancePage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostTypeBalancePreviousColumnAction()
    var
        CostTypeBalancePage: TestPage "Cost Type Balance";
        ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set";
        DateBeforeInvokingAction: Date;
        DateAfterInvokingAction: Date;
    begin
        // Test caption value of column on invoking of Previous Column Action on Cost Type Balance Page.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: Evaluating Caption of Matrix form before and after invoking Previous Column action.
        CostTypeBalancePage.OpenEdit();
        SetFieldsOnCostTypeBalancePage(CostTypeBalancePage, Format("Analysis Period Type"::Day), Format("Analysis Amount Type"::"Balance at Date"), '', '');
        GetColumnDatesOnCostTypeBalancePage(
          CostTypeBalancePage, DateBeforeInvokingAction, DateAfterInvokingAction, ActionItem::"Previous Column");

        // Verify: Verify caption value of column on invoking Previous Column Action.
        Assert.AreEqual(
          CalcDate('<-1D>', DateBeforeInvokingAction), DateAfterInvokingAction, StrSubstNo(ColumnDateError, ActionItem::"Previous Column"));

        // Tear Down.
        CostTypeBalancePage.Close();
    end;

    [Test]
    [HandlerFunctions('MFHandlerChartOfCostAccountOk,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestChartOfCostTypeCorrespondingGLAccountActionOnCostTypeGLRange()
    var
        CostType: Record "Cost Type";
        ChartOfCostTypePage: TestPage "Chart of Cost Types";
    begin
        // Test Corresponding G/L Account Action on Cost Type Balance Page for the Cost Type with Single G/L Account.

        // Setup: Initialize and create a Cost Type with single G/L Account.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingSetup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostType(CostType);

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: Filter the created Cost Type on Chart of Cost Type and invoke Corresponding G/L Account Action for that Cost Type.
        ChartOfCostTypePage.OpenEdit();
        ChartOfCostTypePage.FILTER.SetFilter("No.", CostType."No.");
        ChartOfCostTypePage.CorrespondingGLAccounts.Invoke();

        // Verify: To check G/L Account exist on Chart of Accounts for Cost Type with single G/L Account.
        ChartOfCostTypePage."G/L Account Range".AssertEquals(GLAccountNo);

        // Tear Down.
        ChartOfCostTypePage.Close();
    end;

    [Test]
    [HandlerFunctions('MFHandlerChartOfCostAccountCancel')]
    [Scope('OnPrem')]
    procedure TestChartOfCostTypeCorrespondingGLAccountActionOnCostTypeNoGLRange()
    var
        CostType: Record "Cost Type";
        ChartOfCostTypePage: TestPage "Chart of Cost Types";
    begin
        // Test Corresponding G/L Account Action on Cost Type Balance Page for Cost Type with no G/L Account.

        // Setup: Initialize and Create a Cost Type with no G/L Account.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: Filter the created Cost Type on Chart of Cost Type and invoke Corresponding G/L Account Action for that Cost Type.
        ChartOfCostTypePage.OpenEdit();
        ChartOfCostTypePage.FILTER.SetFilter("No.", CostType."No.");
        ChartOfCostTypePage.CorrespondingGLAccounts.Invoke();

        // Verify: To check no G/L account exist on Chart of Accounts for Cost Type without G/L Account.
        ChartOfCostTypePage."G/L Account Range".AssertEquals(GLAccountNo);

        // Tear Down.
        ChartOfCostTypePage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestChartOfCostTypeGetCostTypesFromChartOfAccountsAction()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
        GLAccount: Record "G/L Account";
        ChartOfCostTypePage: TestPage "Chart of Cost Types";
        OldAlignmentValue: Option;
    begin
        // Test Get Cost Types from Chart Of Account Action On Chart of Cost Type.

        // Setup: Set Alignment and Create a G/L account.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingSetup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CostAccountingSetup.Get();
        OldAlignmentValue := CostAccountingSetup."Align G/L Account";
        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);

        LibraryLowerPermissions.AddO365BusFull();
        // Exercise: Invoking Get Cost Types form Chart of Accounts Action and set filters on Chart of Cost Type Page.
        ChartOfCostTypePage.OpenEdit();
        ChartOfCostTypePage.GetCostTypesFromChartOfAccounts.Invoke();
        ChartOfCostTypePage.FILTER.SetFilter("No.", GLAccount."No.");

        LibraryLowerPermissions.SetCostAccountingView();
        LibraryLowerPermissions.AddCostAccountingSetup();
        // Verify: To check that created G/L Account is extracted to Chart of Cost Tyep Page on invoking Chart of Account Action.
        ChartOfCostTypePage."No.".AssertEquals(GLAccount."No.");

        // Tear Down: Reset the value of Align G/L Account on Cost Accounting Setup.
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align G/L Account"), OldAlignmentValue);
        ChartOfCostTypePage.Close();
    end;

    [Test]
    [HandlerFunctions('MFHandlerCostBudgetEntries')]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryValidateOnNewRecordForCostCenterCode()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
    begin
        // Check that the Code on OnNewRecord with cost center is working successfully or not.

        // Setup: Creating new Cost budget name, cost type and cost center.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostCenter(CostCenter);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Exercise: Open Cost Budget Per period page and setting the filters on the page.
        CostTypeNo := CostType."No.";
        CostCenterFilter := CostCenter.Code;
        SetFiltersOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, CostBudgetName.Name);
        ActionFilter := ActionFilter::Verify;

        // Verify: Verify that the cost budget entry page opens up with correct filters on drilldown. Verification has been done in handler MFHandlerCostBudgetEntries.
        CostBudgetPerPeriodPage.MatrixForm.Column1.DrillDown();

        // Tear Down.
        CostBudgetPerPeriodPage.Close();
    end;

    [Test]
    [HandlerFunctions('MFHandlerCostBudgetEntries')]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryValidateOnInsertRecordForCostObjectCode()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostType: Record "Cost Type";
        CostObject: Record "Cost Object";
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
    begin
        // Check that the Code on OnInsertRecord with cost object is working successfully or not.

        // Setup: Creating new Cost budget name, cost type and cost object.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostObject(CostObject);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Exercise: Open Cost Budget Per period page and setting the filters on the page and setting the value of Amount on cost budget entry page in handler MFHandlerCostBudgetEntries.
        CostTypeNo := CostType."No.";
        CostObjectFilter := CostObject.Code;
        SetFiltersOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, CostBudgetName.Name);
        EntryNo := GetNextEntryNo();
        CostBudgetPerPeriodPage.MatrixForm.Column1.DrillDown();
        ActionFilter := ActionFilter::Verify;

        // Verify: Verify that the record has been inserted on the cost budget entry page. Verification has been done in handler MFHandlerCostBudgetEntries.
        CostBudgetPerPeriodPage.MatrixForm.Column1.DrillDown();

        // Tear Down.
        CostBudgetPerPeriodPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestChartOfCostTypeRegisterCostTypesInChartOfAccounts()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
        CostAccountingSetup: Record "Cost Accounting Setup";
        ChartOfCostTypePage: TestPage "Chart of Cost Types";
        ChartOfAccountsPage: TestPage "Chart of Accounts";
        Type: Option "Cost Type",Heading,Total,"Begin-Total","End-Total";
    begin
        // Test that Action item 'Register Cost Types In Chart Of Accounts'on Chart Of Cost Type page is working successfullty or not.

        // Setup: To set Align G/L Account to No alignment and Create G/L Account and Cost Type.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingSetup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // Exercise: Update Cost type and invoke register Cost Type in Chart Of Accounts Action On Chart Of Cost Type Page.
        UpdateCostType(CostType, Type::"Cost Type", GLAccount."No.");

        ChartOfAccountsPage.OpenView();
        ChartOfAccountsPage.FILTER.SetFilter("No.", GLAccount."No.");

        LibraryLowerPermissions.SetO365BusFull();
        ChartOfCostTypePage.OpenView();
        ChartOfCostTypePage.RegCostTypeInChartOfCostType.Invoke();
        // Verify: To check that after invoking Action item 'Register Cost Types In Chart Of Accounts' Cost Type No. gets in G/L Account.
        ChartOfAccountsPage."Cost Type No.".AssertEquals(CostType."No.");

        // Tear Down.
        ChartOfCostTypePage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostAllocationTargetValidateCostAllocationTargetAction()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostAllocationPage: TestPage "Cost Allocation";
        CostAllocationTargetCardPage: TestPage "Cost Allocation Target Card";
        TypeOfId: Option "Auto Generated",Custom;
    begin
        // Test whether the Cost Allocation Card is opening for that particular Cost Allocation.

        // Setup: Create a Cost Allocation Source and Cost Allocation Target.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingSetup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateAllocSource(CostAllocationSource, TypeOfId::"Auto Generated");
        LibraryCostAccounting.CreateAllocTarget(
          CostAllocationTarget, CostAllocationSource, LibraryRandom.RandDec(1000, 2), "Cost Allocation Target Base"::Static, "Cost Allocation Target Type"::"All Costs");

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: Filter created Cost Allocation on Cost Allocation Page and Invoke the Cost Allocation Target Card Action.
        CostAllocationPage.OpenEdit();
        CostAllocationPage.FILTER.SetFilter(ID, CostAllocationSource.ID);
        CostAllocationTargetCardPage.Trap();
        CostAllocationPage.AllocTarget.AllocationTargetCard.Invoke();

        // Verify: Check whether ID On Cost Allocation Target Card is equal to the ID on Cost Allocation Page
        CostAllocationPage.AllocTarget."Target Cost Type".AssertEquals(CostAllocationTargetCardPage."Target Cost Type");

        // Tear Down.
        CostAllocationPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrespondingCostTypesForAllocation()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostType: Record "Cost Type";
        CostAllocationSourcePage: TestPage "Cost Allocation Sources";
        ChartOfCostTypePage: TestPage "Chart of Cost Types";
        i: Integer;
        TotalNumberOfCostTypes: Integer;
        CostTypeNo: Code[20];
        TypeOfID: Option "Auto Generated",Custom;
    begin
        // Test that Corresponding Cost Types for an Allocation Source are Displayed.

        // Setup: Create multiple cost type and link it with newly created cost allocation source.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingSetup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        TotalNumberOfCostTypes := 1 + LibraryRandom.RandInt(4);
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        CostTypeNo := CostType."No.";
        for i := 2 to TotalNumberOfCostTypes do
            LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryCostAccounting.CreateAllocSource(CostAllocationSource, TypeOfID::"Auto Generated");
        UpdateCostAllocationSource(CostAllocationSource, StrSubstNo(CostTypeFilterDefinition, CostTypeNo, CostType."No."));

        LibraryLowerPermissions.SetCostAccountingView();
        // Exercise: To open Cost Allocation Source page set filter and then invoke Page Chart of Cost Types.
        CostAllocationSourcePage.OpenView();
        CostAllocationSourcePage.FILTER.SetFilter(ID, CostAllocationSource.ID);
        ChartOfCostTypePage.Trap();
        CostAllocationSourcePage.PageChartOfCostTypes.Invoke();

        // Verify that Corresponding Cost Types for an Allocation Source are Displayed.
        CostAllocationSource.TestField("Cost Type Range", ChartOfCostTypePage.FILTER.GetFilter("No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerPeriodPageValidateBudgetFilter()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetName2: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetPerPeriodPage: TestPage "Cost Budget per Period";
    begin
        // Test that Changing the View Reflects in Displaying the Correct Data.

        // Setup.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        // Exercise: Create two cost budget name and one cost budget entry.
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName.Name);
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName2);
        CostBudgetPerPeriodPage.OpenEdit();

        LibraryLowerPermissions.SetCostAccountingView();
        // Verify that Changing the View Reflects in Displaying the Correct Data.
        VerifyCostBudgetPerPeriodMatrixPage(
          CostBudgetPerPeriodPage, CostBudgetName.Name, CostBudgetEntry, Format(CostBudgetEntry.Amount, 0, '<Precision,2><Standard Format,1>'));
        VerifyCostBudgetPerPeriodMatrixPage(CostBudgetPerPeriodPage, CostBudgetName2.Name, CostBudgetEntry, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerCostCenterMatrixShowsCostCenter()
    var
        CostCenter: Record "Cost Center";
        CostCenter2: array[12] of Record "Cost Center";
        TempCostCenter: Record "Cost Center" temporary;
        CostBudgetbyCostCenterPage: TestPage "Cost Budget by Cost Center";
        i: Integer;
    begin
        // Test that Page Cost Bdgt. per Center Matrix is shown correctly.

        // Setup: Save copy and delete all the cost centers.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CopyCostCenters(CostCenter, TempCostCenter);
        CostCenter.DeleteAll();

        // Create 12 new cost centers and open the page cost budget by cost center page.
        for i := 1 to 12 do
            LibraryCostAccounting.CreateCostCenter(CostCenter2[i]);
        CostBudgetbyCostCenterPage.OpenEdit();

        // Verify that column captions are correcly shown in the page according to newly created cost centers.
        for i := 1 to 12 do
            Assert.AreEqual(
              Format(CostCenter2[i].Code), GetColumnCaptionOnCostBudgetByCostCenterPage(CostBudgetbyCostCenterPage, i),
              StrSubstNo(WrongCaptionError, i));

        // Tear Down.
        CopyCostCenters(TempCostCenter, CostCenter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetPerCostObjectMatrixShowsCostObject()
    var
        CostObject: Record "Cost Object";
        CostObject2: array[12] of Record "Cost Object";
        TempCostObject: Record "Cost Object" temporary;
        CostBudgetbyCostObjectPage: TestPage "Cost Budget by Cost Object";
        i: Integer;
    begin
        // Test that Page Cost Bdgt. per Object Matrix is shown correctly.

        // Setup: Save copy and delete all the cost objects.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        CopyCostObjects(CostObject, TempCostObject);
        CostObject.DeleteAll();

        // Create 12 new cost objects and open the page cost budget by cost object page.
        for i := 1 to 12 do
            LibraryCostAccounting.CreateCostObject(CostObject2[i]);
        CostBudgetbyCostObjectPage.OpenEdit();

        // Verify that column captions are correcly shown in the page according to newly created cost objects.
        for i := 1 to 12 do
            Assert.AreEqual(
              Format(CostObject2[i].Code), GetColumnCaptionOnCostBudgetByCostObjectPage(CostBudgetbyCostObjectPage, i),
              StrSubstNo(WrongCaptionError, i));

        // Tear Down.
        CopyCostObjects(TempCostObject, CostObject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartOfAccountFlowFiltersOnActionGLBalance()
    var
        ChartOfAccounts: TestPage "Chart of Accounts";
        GLBalance: TestPage "G/L Balance";
        GlobalDimensionCodeValue: array[2] of Code[20];
        BusinessUnitFilterValue: Code[10];
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365BusFull();
        LibraryLowerPermissions.AddCostAccountingEdit();

        // Verify flowfilters are transfered when opening "G/L Balance" from "Chart Of Accounts" page
        GlobalDimensionCodeValue[1] := GetGlobalDimensionCodeValue(1);
        GlobalDimensionCodeValue[2] := GetGlobalDimensionCodeValue(2);
        BusinessUnitFilterValue := GetBusinessUnitFilterValue();

        ChartOfAccounts.OpenView();
        ChartOfAccounts.FILTER.SetFilter("Global Dimension 1 Filter", GlobalDimensionCodeValue[1]);
        ChartOfAccounts.FILTER.SetFilter("Global Dimension 2 Filter", GlobalDimensionCodeValue[2]);
        ChartOfAccounts.FILTER.SetFilter("Business Unit Filter", BusinessUnitFilterValue);
        GLBalance.Trap();
        ChartOfAccounts."G/L &Balance".Invoke();

        LibraryLowerPermissions.SetCostAccountingView();
        Assert.AreEqual(GlobalDimensionCodeValue[1], GLBalance.FILTER.GetFilter("Global Dimension 1 Filter"), WrongFlowFilterValueErr);
        Assert.AreEqual(GlobalDimensionCodeValue[2], GLBalance.FILTER.GetFilter("Global Dimension 2 Filter"), WrongFlowFilterValueErr);
        Assert.AreEqual(BusinessUnitFilterValue, GLBalance.FILTER.GetFilter("Business Unit Filter"), WrongFlowFilterValueErr);

        GLBalance.Close();
        ChartOfAccounts.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartOfAccountFlowFiltersOnActionGLBalanceBudget()
    var
        ChartOfAccounts: TestPage "Chart of Accounts";
        GLBalanceBudget: TestPage "G/L Balance/Budget";
        GlobalDimensionCodeValue: array[2] of Code[20];
        BusinessUnitFilterValue: Code[10];
        BudgetFilterValue: Code[10];
    begin
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddO365BusFull();
        LibraryLowerPermissions.AddCostAccountingEdit();

        // Verify flowfilters are transfered when opening "G/L Balance/Budget" from "Chart Of Accounts" page
        GlobalDimensionCodeValue[1] := GetGlobalDimensionCodeValue(1);
        GlobalDimensionCodeValue[2] := GetGlobalDimensionCodeValue(2);
        BusinessUnitFilterValue := GetBusinessUnitFilterValue();
        BudgetFilterValue := GetBudgetFilterValue();

        ChartOfAccounts.OpenView();
        ChartOfAccounts.FILTER.SetFilter("Global Dimension 1 Filter", GlobalDimensionCodeValue[1]);
        ChartOfAccounts.FILTER.SetFilter("Global Dimension 2 Filter", GlobalDimensionCodeValue[2]);
        ChartOfAccounts.FILTER.SetFilter("Business Unit Filter", BusinessUnitFilterValue);
        ChartOfAccounts.FILTER.SetFilter("Budget Filter", BudgetFilterValue);
        GLBalanceBudget.Trap();
        ChartOfAccounts."G/L Balance/B&udget".Invoke();

        Assert.AreEqual(
          GlobalDimensionCodeValue[1], GLBalanceBudget.FILTER.GetFilter("Global Dimension 1 Filter"), WrongFlowFilterValueErr);
        Assert.AreEqual(
          GlobalDimensionCodeValue[2], GLBalanceBudget.FILTER.GetFilter("Global Dimension 2 Filter"), WrongFlowFilterValueErr);
        Assert.AreEqual(BusinessUnitFilterValue, GLBalanceBudget.FILTER.GetFilter("Business Unit Filter"), WrongFlowFilterValueErr);
        Assert.AreEqual(BudgetFilterValue, GLBalanceBudget.FILTER.GetFilter("Budget Filter"), WrongFlowFilterValueErr);

        GLBalanceBudget.Close();
        ChartOfAccounts.Close();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cost Accounting - Pages");
        InitializeGlobalVariables();
    end;

    local procedure InitializeGlobalVariables()
    begin
        CostCenterFilter := '';
        CostObjectFilter := '';
        CostJournalBatchName := '';
        GLAccountNo := '';
        CostTypeNo := '';
        EntryNo := 0;
        Clear(ActionFilter);
    end;

    local procedure CostTypeBalanceWithRoundingFactor(CurrentValue: Decimal; SelectedRoundingFactor: Enum "Analysis Rounding Factor") RoundedValue: Decimal
    begin
        case SelectedRoundingFactor of
            "Analysis Rounding Factor"::None:
                RoundedValue := CurrentValue;
            "Analysis Rounding Factor"::"1":
                RoundedValue := Round(CurrentValue, 1);
            "Analysis Rounding Factor"::"1000":
                RoundedValue := Round(CurrentValue / 1000, 0.1);
            "Analysis Rounding Factor"::"1000000":
                RoundedValue := Round(CurrentValue / 1000000, 0.1);
        end;
    end;

    local procedure CreateBudgetEntry(CostBudgetName: Code[10]; CostTypeNo: Code[20]; Date: Date): Decimal
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName);
        CostBudgetEntry."Cost Type No." := CostTypeNo;
        CostBudgetEntry.Date := Date;
        CostBudgetEntry.Modify();

        exit(CostBudgetEntry.Amount);
    end;

    local procedure CreateCostType(var CostType: Record "Cost Type")
    var
        CostCenter: Record "Cost Center";
    begin
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CostType."Cost Center Code" := CostCenter.Code;
        CostType.Modify();
    end;

    local procedure FindCostJournalBatch(var CostJournalBatch: Record "Cost Journal Batch")
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        LibraryCostAccounting.FindCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.FindCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryCostAccounting.ClearCostJournalLines(CostJournalBatch);
    end;

    local procedure GetCurrentDate(DateFilter: Text[35]) Date: Date
    var
        DateString: Text;
        Position: Integer;
    begin
        Position := StrPos(DateFilter, '..');
        if Position = 0 then
            DateString := DateFilter
        else
            DateString := CopyStr(DateFilter, Position + 2);

        Evaluate(Date, DateString);
    end;

    local procedure GetCellValueOnCostBudgetPerPeriodPage(var CostBudgetPerPeriodPage: TestPage "Cost Budget per Period"; ColumnNo: Integer) Value: Text
    begin
        case ColumnNo of
            1:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column1.Value();
            2:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column2.Value();
            3:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column3.Value();
            4:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column4.Value();
            5:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column5.Value();
            6:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column6.Value();
            7:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column7.Value();
            8:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column8.Value();
            9:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column9.Value();
            10:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column10.Value();
            11:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column11.Value();
            12:
                Value := CostBudgetPerPeriodPage.MatrixForm.Column12.Value();
            else
                Error(InvalidColumnIndex)
        end;
    end;

    local procedure GetCellValueOnCostBudgetByCostCenterPage(var CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center"; ColumnNo: Integer) Value: Text
    begin
        case ColumnNo of
            1:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column1.Value();
            2:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column2.Value();
            3:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column3.Value();
            4:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column4.Value();
            5:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column5.Value();
            6:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column6.Value();
            7:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column7.Value();
            8:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column8.Value();
            9:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column9.Value();
            10:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column10.Value();
            11:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column11.Value();
            12:
                Value := CostBudgetByCostCenterPage.MatrixForm.Column12.Value();
            else
                Error(InvalidColumnIndex)
        end;
    end;

    local procedure GetCellValueOnCostBudgetByCostObjectPage(CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object"; ColumnNo: Integer) Value: Text
    begin
        case ColumnNo of
            1:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column1.Value();
            2:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column2.Value();
            3:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column3.Value();
            4:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column4.Value();
            5:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column5.Value();
            6:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column6.Value();
            7:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column7.Value();
            8:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column8.Value();
            9:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column9.Value();
            10:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column10.Value();
            11:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column11.Value();
            12:
                Value := CostBudgetByCostObjectPage.MatrixForm.Column12.Value();
            else
                Error(InvalidColumnIndex)
        end;
    end;

    local procedure GetColumnCaptionOnCostBudgetByCostObjectPage(CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object"; ColumnNo: Integer) Caption: Text
    begin
        case ColumnNo of
            1:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column1.Caption;
            2:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column2.Caption;
            3:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column3.Caption;
            4:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column4.Caption;
            5:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column5.Caption;
            6:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column6.Caption;
            7:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column7.Caption;
            8:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column8.Caption;
            9:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column9.Caption;
            10:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column10.Caption;
            11:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column11.Caption;
            12:
                Caption := CostBudgetByCostObjectPage.MatrixForm.Column12.Caption;
            else
                Error(InvalidColumnIndex)
        end;
    end;

    local procedure GetColumnCaptionOnCostBudgetByCostCenterPage(CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center"; ColumnNo: Integer) Caption: Text
    begin
        case ColumnNo of
            1:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column1.Caption;
            2:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column2.Caption;
            3:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column3.Caption;
            4:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column4.Caption;
            5:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column5.Caption;
            6:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column6.Caption;
            7:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column7.Caption;
            8:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column8.Caption;
            9:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column9.Caption;
            10:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column10.Caption;
            11:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column11.Caption;
            12:
                Caption := CostBudgetByCostCenterPage.MatrixForm.Column12.Caption;
            else
                Error(InvalidColumnIndex)
        end;
    end;

    local procedure GetColumnCaptionOnCostBudgetPerPeriodPage(var CostBudgetPerPeriodPage: TestPage "Cost Budget per Period"; ColumnNo: Integer) Caption: Text[30]
    begin
        case ColumnNo of
            1:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column1.Caption;
            2:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column2.Caption;
            3:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column3.Caption;
            4:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column4.Caption;
            5:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column5.Caption;
            6:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column6.Caption;
            7:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column7.Caption;
            8:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column8.Caption;
            9:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column9.Caption;
            10:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column10.Caption;
            11:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column11.Caption;
            12:
                Caption := CostBudgetPerPeriodPage.MatrixForm.Column12.Caption;
            else
                Error(InvalidColumnIndex)
        end;
    end;

    local procedure GetColumnAmountOnCostBudgetPerPeriodChange(CostBudgetPerPeriodPage: TestPage "Cost Budget per Period"; CostTypeNo: Code[20]) Value: Text[30]
    begin
        CostBudgetPerPeriodPage.MatrixForm.FILTER.SetFilter("No.", CostTypeNo);
        Value := GetCellValueOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, 1);
    end;

    local procedure GetColumnDatesOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage: TestPage "Cost Budget per Period"; var DateBeforeInvokingAction: Date; var DateAfterInvokingAction: Date; ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set")
    var
        ColumnNo: Integer;
    begin
        ColumnNo := LibraryRandom.RandInt(12); // Pick a random column for the matrix page.
        Evaluate(DateBeforeInvokingAction, GetColumnCaptionOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, ColumnNo));
        InvokeActionOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, ActionItem);
        Evaluate(DateAfterInvokingAction, GetColumnCaptionOnCostBudgetPerPeriodPage(CostBudgetPerPeriodPage, ColumnNo));
    end;

    local procedure GetNextEntryNo(): Integer
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        CostBudgetEntry.SetCurrentKey("Entry No.");
        if CostBudgetEntry.FindLast() then
            exit(CostBudgetEntry."Entry No." + 1);
        exit(1);
    end;

    [Normal]
    local procedure InvokeActionOnCostBudgetPerPeriodPage(var CostBudgetPerPeriodPage: TestPage "Cost Budget per Period"; ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set")
    begin
        case ActionItem of
            ActionItem::"Previous Set":
                CostBudgetPerPeriodPage.PreviousSet.Invoke();
            ActionItem::"Previous Column":
                CostBudgetPerPeriodPage.PreviousColumn.Invoke();
            ActionItem::"Next Column":
                CostBudgetPerPeriodPage.NextColumn.Invoke();
            ActionItem::"Next Set":
                CostBudgetPerPeriodPage.NextSet.Invoke();
        end;
    end;

    local procedure PostAmountForCostType(CostTypeNo: Code[20]; BalCostTypeNo: Code[20]) Amount: Decimal
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        FindCostJournalBatch(CostJournalBatch);
        LibraryCostAccounting.CreateCostJournalLineBasic(
          CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name, WorkDate(), CostTypeNo, BalCostTypeNo);
        Amount := CostJournalLine.Amount;
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
    end;

    local procedure PostCostJournalLine(CostTypeNo: Code[20]; CostCenterCode: Code[20]; CostObjectCode: Code[20]; PostingDate: Date) Amount: Decimal
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        FindCostJournalBatch(CostJournalBatch);

        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine."Posting Date" := PostingDate;
        CostJournalLine."Cost Type No." := CostTypeNo;
        CostJournalLine."Cost Center Code" := CostCenterCode;
        CostJournalLine."Cost Object Code" := CostObjectCode;
        CostJournalLine.Modify();
        Amount := CostJournalLine.Amount;

        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
    end;

    local procedure SetFieldsOnCostBudgetByCostObjectPage(var CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object"; AmountTypeOption: Text[30]; PeriodTypeOption: Text[30]; CostBudgetName: Text[10])
    begin
        CostBudgetByCostObjectPage.AmountType.SetValue(AmountTypeOption);
        CostBudgetByCostObjectPage.PeriodType.SetValue(PeriodTypeOption);

        CostBudgetByCostObjectPage.BudgetFilter.SetValue(CostBudgetName);
    end;

    local procedure SetFieldsOnCostTypeBalanceBudgetPage(var CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget"; AmountTypeOption: Text[30]; PeriodTypeOption: Text[30]; CostBudgetName: Text[10]; CostCenterCode: Text[20]; CostObjectCode: Text[20])
    begin
        CostTypeBalanceBudgetPage.AmountType.SetValue(AmountTypeOption);
        CostTypeBalanceBudgetPage.PeriodType.SetValue(PeriodTypeOption);

        CostTypeBalanceBudgetPage.BudgetFilter.SetValue(CostBudgetName);
        CostTypeBalanceBudgetPage.CostCenterFilter.SetValue(CostCenterCode);
        CostTypeBalanceBudgetPage.CostObjectFilter.SetValue(CostObjectCode);
    end;

    local procedure SetFieldsOnCostBudgetPerPeriodPage(var CostBudgetPerPeriodPage: TestPage "Cost Budget per Period"; AmountTypeOption: Text[30]; PeriodTypeOption: Text[30]; CostBudgetName: Text[10]; CostCenterCode: Text[20]; CostObjectCode: Text[20])
    begin
        CostBudgetPerPeriodPage.AmountType.SetValue(AmountTypeOption);
        CostBudgetPerPeriodPage.PeriodType.SetValue(PeriodTypeOption);

        CostBudgetPerPeriodPage.BudgetFilter.SetValue(CostBudgetName);
        CostBudgetPerPeriodPage.CostCenterFilter.SetValue(CostCenterCode);
        CostBudgetPerPeriodPage.CostObjectFilter.SetValue(CostObjectCode);
    end;

    local procedure SetCellValueOnCostBudgetPerPeriodPage(var CostBudgetPerPeriodPage: TestPage "Cost Budget per Period"; ColumnNo: Integer; Value: Decimal)
    begin
        case ColumnNo of
            1:
                CostBudgetPerPeriodPage.MatrixForm.Column1.SetValue(Value);
            2:
                CostBudgetPerPeriodPage.MatrixForm.Column2.SetValue(Value);
            3:
                CostBudgetPerPeriodPage.MatrixForm.Column3.SetValue(Value);
            4:
                CostBudgetPerPeriodPage.MatrixForm.Column4.SetValue(Value);
            5:
                CostBudgetPerPeriodPage.MatrixForm.Column5.SetValue(Value);
            6:
                CostBudgetPerPeriodPage.MatrixForm.Column6.SetValue(Value);
            7:
                CostBudgetPerPeriodPage.MatrixForm.Column7.SetValue(Value);
            8:
                CostBudgetPerPeriodPage.MatrixForm.Column8.SetValue(Value);
            9:
                CostBudgetPerPeriodPage.MatrixForm.Column9.SetValue(Value);
            10:
                CostBudgetPerPeriodPage.MatrixForm.Column10.SetValue(Value);
            11:
                CostBudgetPerPeriodPage.MatrixForm.Column11.SetValue(Value);
            12:
                CostBudgetPerPeriodPage.MatrixForm.Column12.SetValue(Value);
            else
                Error(InvalidColumnIndex)
        end;
    end;

    local procedure SetFieldsOnCostBudgetByCostCenterPage(var CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center"; AmountTypeOption: Text[30]; PeriodTypeOption: Text[30]; CostBudgetName: Text[10])
    begin
        CostBudgetByCostCenterPage.AmountType.SetValue(AmountTypeOption);
        CostBudgetByCostCenterPage.PeriodType.SetValue(PeriodTypeOption);
        CostBudgetByCostCenterPage.BudgetFilter.SetValue(CostBudgetName);
    end;

    local procedure SetFiltersOnCostBudgetPerPeriodPage(var CostBudgetPerPeriodPage: TestPage "Cost Budget per Period"; CostBudgetName: Code[10])
    begin
        CostBudgetPerPeriodPage.OpenEdit();
        SetFieldsOnCostBudgetPerPeriodPage(
          CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), CostBudgetName, CostCenterFilter,
          CostObjectFilter);
        CostBudgetPerPeriodPage.MatrixForm.FILTER.SetFilter("No.", CostTypeNo);
    end;

    local procedure SetCellValueOnCostBudgetByCostCenterPage(var CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center"; ColumnNo: Integer; Value: Decimal)
    begin
        case ColumnNo of
            1:
                CostBudgetByCostCenterPage.MatrixForm.Column1.SetValue(Value);
            2:
                CostBudgetByCostCenterPage.MatrixForm.Column2.SetValue(Value);
            3:
                CostBudgetByCostCenterPage.MatrixForm.Column3.SetValue(Value);
            4:
                CostBudgetByCostCenterPage.MatrixForm.Column4.SetValue(Value);
            5:
                CostBudgetByCostCenterPage.MatrixForm.Column5.SetValue(Value);
            6:
                CostBudgetByCostCenterPage.MatrixForm.Column6.SetValue(Value);
            7:
                CostBudgetByCostCenterPage.MatrixForm.Column7.SetValue(Value);
            8:
                CostBudgetByCostCenterPage.MatrixForm.Column8.SetValue(Value);
            9:
                CostBudgetByCostCenterPage.MatrixForm.Column9.SetValue(Value);
            10:
                CostBudgetByCostCenterPage.MatrixForm.Column10.SetValue(Value);
            11:
                CostBudgetByCostCenterPage.MatrixForm.Column11.SetValue(Value);
            12:
                CostBudgetByCostCenterPage.MatrixForm.Column12.SetValue(Value);
            else
                Error(InvalidColumnIndex)
        end;
    end;

    local procedure SetCellValueOnCostBudgetByCostObjectPage(var CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object"; ColumnNo: Integer; Value: Decimal)
    begin
        case ColumnNo of
            1:
                CostBudgetByCostObjectPage.MatrixForm.Column1.SetValue(Value);
            2:
                CostBudgetByCostObjectPage.MatrixForm.Column2.SetValue(Value);
            3:
                CostBudgetByCostObjectPage.MatrixForm.Column3.SetValue(Value);
            4:
                CostBudgetByCostObjectPage.MatrixForm.Column4.SetValue(Value);
            5:
                CostBudgetByCostObjectPage.MatrixForm.Column5.SetValue(Value);
            6:
                CostBudgetByCostObjectPage.MatrixForm.Column6.SetValue(Value);
            7:
                CostBudgetByCostObjectPage.MatrixForm.Column7.SetValue(Value);
            8:
                CostBudgetByCostObjectPage.MatrixForm.Column8.SetValue(Value);
            9:
                CostBudgetByCostObjectPage.MatrixForm.Column9.SetValue(Value);
            10:
                CostBudgetByCostObjectPage.MatrixForm.Column10.SetValue(Value);
            11:
                CostBudgetByCostObjectPage.MatrixForm.Column11.SetValue(Value);
            12:
                CostBudgetByCostObjectPage.MatrixForm.Column12.SetValue(Value);
            else
                Error(InvalidColumnIndex)
        end;
    end;

    local procedure SetValuesOnCostJournalPage(var CostJournalPage: TestPage "Cost Journal"; CostJournalBatchName: Code[10]; CostTypeNo: Code[20]; BalCostTypeNo: Code[20])
    begin
        CostJournalPage.CostJnlBatchName.SetValue(CostJournalBatchName);
        CostJournalPage."Document No.".SetValue(LibraryRandom.RandInt(100));
        CostJournalPage."Cost Type No.".SetValue(CostTypeNo);
        CostJournalPage.Amount.SetValue(LibraryRandom.RandDec(100, 2));
        CostJournalPage."Bal. Cost Type No.".SetValue(BalCostTypeNo);
    end;

    local procedure UpdateCostAllocationSource(var CostAllocationSource: Record "Cost Allocation Source"; CostTypeFilter: Code[30])
    begin
        CostAllocationSource.Validate("Cost Type Range", CostTypeFilter);
        CostAllocationSource.Modify(true);
    end;

    local procedure UpdateCostBudgetEntry(var CostBudgetEntry: Record "Cost Budget Entry"; CostTypeNo: Code[20]; CostCenterCode: Code[20]; CostObjectCode: Code[20])
    begin
        CostBudgetEntry.Validate("Cost Type No.", CostTypeNo);
        CostBudgetEntry.Validate("Cost Center Code", CostCenterCode);
        CostBudgetEntry.Validate("Cost Object Code", CostObjectCode);
        CostBudgetEntry.Modify(true);
    end;

    local procedure UpdateCostTypeBalanceFilters(var CostTypeBalance: TestPage "Cost Type Balance"; CostCenterFilter: Code[20]; CostObjectFilter: Code[20]; PeriodType: Enum "Analysis Period Type"; AmountType: Enum "Analysis Amount Type"; RoundingFactor: Enum "Analysis Rounding Factor")
    begin
        CostTypeBalance.CostCenterFilter.SetValue(CostCenterFilter);
        CostTypeBalance.CostObjectFilter.SetValue(CostObjectFilter);
        CostTypeBalance.PeriodType.SetValue(PeriodType);
        CostTypeBalance.AmountType.SetValue(AmountType);
        CostTypeBalance.RoundingFactor.SetValue(RoundingFactor);
    end;

    local procedure ValidateCostTypeBalanceAmountType(AmountType: Enum "Analysis Amount Type")
    var
        BalCostType: Record "Cost Type";
        CostType: Record "Cost Type";
        CostTypeBalance: TestPage "Cost Type Balance";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCostType(CostType);
        CreateCostType(BalCostType);
        Amount := PostAmountForCostType(CostType."No.", BalCostType."No.");

        // Exercise
        CostTypeBalance.OpenEdit();
        CostTypeBalance.FILTER.SetFilter("Date Filter", Format(WorkDate()));
        UpdateCostTypeBalanceFilters(CostTypeBalance, '', '', "Analysis Period Type"::Day, AmountType, "Analysis Rounding Factor"::None);

        // Verify
        CostTypeBalance.MatrixForm.GotoRecord(CostType);
        CostTypeBalance.MatrixForm.Column1.AssertEquals(Amount);

        // Cleanup
        CostTypeBalance.Close();
    end;

    local procedure VerifyFiltersOnCostBudgetPerPeriodMatrixPage(CostBudgetPerPeriodPage: TestPage "Cost Budget per Period"; ExpectedDateFilter: Text)
    var
        ActualCostCenterFilter: Text;
        ActualCostObjectFilter: Text;
        ActualBudgetFilter: Text;
        ActualDateFilter: Text;
    begin
        ActualDateFilter := CostBudgetPerPeriodPage.MatrixForm.FILTER.GetFilter("Date Filter");
        ActualCostCenterFilter := CostBudgetPerPeriodPage.MatrixForm.FILTER.GetFilter("Cost Center Filter");
        ActualCostObjectFilter := CostBudgetPerPeriodPage.MatrixForm.FILTER.GetFilter("Cost Object Filter");
        ActualBudgetFilter := CostBudgetPerPeriodPage.MatrixForm.FILTER.GetFilter("Budget Filter");

        Assert.AreEqual(ExpectedDateFilter, ActualDateFilter, DateFilterError);
        CostBudgetPerPeriodPage.CostCenterFilter.AssertEquals(ActualCostCenterFilter);
        CostBudgetPerPeriodPage.CostObjectFilter.AssertEquals(ActualCostObjectFilter);
        CostBudgetPerPeriodPage.BudgetFilter.AssertEquals(ActualBudgetFilter);
    end;

    local procedure VerifyFiltersOnCostBudgetByCostCenterMatrixPage(CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center"; ExpectedDateFilter: Text)
    var
        ActualBudgetFilter: Text;
        ActualDateFilter: Text;
    begin
        ActualDateFilter := CostBudgetByCostCenterPage.MatrixForm.FILTER.GetFilter("Date Filter");
        ActualBudgetFilter := CostBudgetByCostCenterPage.MatrixForm.FILTER.GetFilter("Budget Filter");

        Assert.AreEqual(ExpectedDateFilter, ActualDateFilter, DateFilterError);
        CostBudgetByCostCenterPage.BudgetFilter.AssertEquals(ActualBudgetFilter);
    end;

    local procedure VerifyFiltersOnCostBudgetByCostObjectMatrixPage(CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object"; ExpectedDateFilter: Text)
    var
        ActualBudgetFilter: Text;
        ActualDateFilter: Text;
    begin
        ActualDateFilter := CostBudgetByCostObjectPage.MatrixForm.FILTER.GetFilter("Date Filter");
        ActualBudgetFilter := CostBudgetByCostObjectPage.MatrixForm.FILTER.GetFilter("Budget Filter");

        Assert.AreEqual(ExpectedDateFilter, ActualDateFilter, DateFilterError);
        CostBudgetByCostObjectPage.BudgetFilter.AssertEquals(ActualBudgetFilter);
    end;

    local procedure VerifyCostBudgetEntry(ExpectedBudgetName: Text[10]; ExpectedCostCenterCode: Text[20]; ExpectedCostObjectCode: Text[20]; ExpectedCostTypeNo: Code[20]; ExpectedDate: Date; ExpectedAmount: Decimal)
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        CostBudgetEntry.FindLast();

        CostBudgetEntry.TestField("Budget Name", ExpectedBudgetName);
        CostBudgetEntry.TestField("Cost Center Code", ExpectedCostCenterCode);
        CostBudgetEntry.TestField("Cost Object Code", ExpectedCostObjectCode);
        CostBudgetEntry.TestField("Cost Type No.", ExpectedCostTypeNo);
        CostBudgetEntry.TestField(Date, ExpectedDate);
        CostBudgetEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyCostBudgetByCostObjectCaption(var CostBudgetByCostObject: TestPage "Cost Budget by Cost Object"; ColumnNo: Integer; Caption: Text[20])
    begin
        case ColumnNo of
            1:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column1.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            2:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column2.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            3:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column3.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            4:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column4.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            5:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column5.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            6:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column6.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            7:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column7.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            8:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column8.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            9:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column9.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            10:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column10.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            11:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column11.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            12:
                Assert.AreEqual(Caption, CostBudgetByCostObject.MatrixForm.Column12.Caption, StrSubstNo(WrongCaptionError, ColumnNo))
            else
                Error(InvalidColumnIndex)
        end
    end;

    local procedure VerifyCostBudgetByCostCenterCaption(var CostBudgetByCostCenter: TestPage "Cost Budget by Cost Center"; ColumnNo: Integer; Caption: Text[20])
    begin
        case ColumnNo of
            1:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column1.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            2:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column2.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            3:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column3.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            4:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column4.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            5:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column5.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            6:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column6.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            7:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column7.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            8:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column8.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            9:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column9.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            10:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column10.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            11:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column11.Caption, StrSubstNo(WrongCaptionError, ColumnNo));
            12:
                Assert.AreEqual(Caption, CostBudgetByCostCenter.MatrixForm.Column12.Caption, StrSubstNo(WrongCaptionError, ColumnNo))
            else
                Error(InvalidColumnIndex)
        end
    end;

    local procedure VerifyCostBudgetPerPeriodMatrixPage(var CostBudgetPerPeriodPage: TestPage "Cost Budget per Period"; CostBudgetName: Code[10]; CostBudgetEntry: Record "Cost Budget Entry"; Amount: Text)
    var
        CostType: Record "Cost Type";
        CostBudgetAmount: Text;
    begin
        SetFieldsOnCostBudgetPerPeriodPage(
          CostBudgetPerPeriodPage, Format("Analysis Amount Type"::"Net Change"), Format("Analysis Period Type"::Day), CostBudgetName,
          CostBudgetEntry."Cost Center Code", '');
        CostBudgetAmount := GetColumnAmountOnCostBudgetPerPeriodChange(CostBudgetPerPeriodPage, CostBudgetEntry."Cost Type No.");
        Assert.AreEqual(Amount, CostBudgetAmount,
          StrSubstNo(
            CostBudgetAmountError, CostType.TableCaption(), CostBudgetEntry."Cost Type No.",
            CostBudgetPerPeriodPage.MatrixForm.Column1.Caption, CostBudgetEntry.TableCaption(), CostBudgetEntry."Entry No."));
    end;

    local procedure VerifyCostJournalLineWithoutBalCostType(CostJournalPage: TestPage "Cost Journal")
    var
        CostType: Record "Cost Type";
    begin
        CostType.Get(CostJournalPage."Cost Type No.".Value());
        CostJournalPage.Next();
        CostJournalPage.Previous();
        Assert.AreEqual(
          WorkDate(), CostJournalPage."Posting Date".AsDate(), StrSubstNo(PostingDateError, CostJournalPage."Posting Date".Caption));
        Assert.AreEqual(
          CostJournalPage.Balance.Value, CostJournalPage.Amount.Value, StrSubstNo(ExpectedValueDifferent, CostJournalPage.Balance.Caption));
        Assert.AreEqual(
          CostJournalPage.TotalBalance.Value, CostJournalPage.Amount.Value,
          StrSubstNo(ExpectedValueDifferent, CostJournalPage.TotalBalance.Caption));
        Assert.AreEqual(
          CostJournalPage.CostTypeName.Value, CostType.Name, StrSubstNo(ExpectedValueDifferent, CostJournalPage.CostTypeName.Caption));
    end;

    local procedure VerifyCostJournalLineWithBalCostType(CostJournalPage: TestPage "Cost Journal")
    var
        CostType: Record "Cost Type";
    begin
        CostType.Get(CostJournalPage."Cost Type No.".Value());
        CostJournalPage.Next();
        CostJournalPage.Previous();
        Assert.AreEqual(
          WorkDate(), CostJournalPage."Posting Date".AsDate(), StrSubstNo(PostingDateError, CostJournalPage."Posting Date".Caption));
        Assert.AreEqual(CostJournalPage.Balance.AsDecimal(), 0, StrSubstNo(ExpectedValueDifferent, CostJournalPage.Balance.Caption));
        Assert.AreEqual(
          CostJournalPage.TotalBalance.AsDecimal(), 0, StrSubstNo(ExpectedValueDifferent, CostJournalPage.TotalBalance.Caption));
        Assert.AreEqual(
          CostJournalPage.CostTypeName.Value, CostType.Name, StrSubstNo(ExpectedValueDifferent, CostJournalPage.CostTypeName.Caption));
        Assert.AreEqual(
          CostJournalPage.BalCostTypeName.Value, CostType.Name, StrSubstNo(ExpectedValueDifferent, CostJournalPage.BalCostTypeName.Caption));
    end;

    local procedure CheckCreateCostObjects()
    var
        CostObject: Record "Cost Object";
        i: Integer;
    begin
        CostObject.SetRange("Line Type", CostObject."Line Type"::"Cost Object");
        for i := CostObject.Count to 24 do
            LibraryCostAccounting.CreateCostObject(CostObject);
    end;

    local procedure CheckCreateCostCenters()
    var
        CostCenter: Record "Cost Center";
        i: Integer;
    begin
        CostCenter.SetRange("Line Type", CostCenter."Line Type"::"Cost Center");
        for i := CostCenter.Count to 24 do
            LibraryCostAccounting.CreateCostCenter(CostCenter);
    end;

    local procedure VerifyCostBudgetByCostObjectCaptionOffset(var CostBudgetByCostObjectPage: TestPage "Cost Budget by Cost Object"; Offset: Integer; var CostObject: Record "Cost Object")
    begin
        // verify that the current set is the next one (check just 1 column)
        CostObject.SetCurrentKey("Sorting Order");
        CostObject.SetRange("Line Type", CostObject."Line Type"::"Cost Object");
        CostObject.FindSet();
        CostObject.Next(Offset);
        Commit();
        asserterror
        begin
            VerifyCostBudgetByCostObjectCaption(CostBudgetByCostObjectPage, 1, CostObject.Code);
            Error('')
        end;
        if GetLastErrorText <> '' then
            Error(NextSetNotAvailableError);
    end;

    local procedure VerifyCostBudgetByCostCenterCaptionOffset(var CostBudgetByCostCenterPage: TestPage "Cost Budget by Cost Center"; Offset: Integer; var CostCenter: Record "Cost Center")
    begin
        // verify that the current set is the next one (check just 1 column)
        CostCenter.SetCurrentKey("Sorting Order");
        CostCenter.SetRange("Line Type", CostCenter."Line Type"::"Cost Center");
        CostCenter.FindSet();
        CostCenter.Next(Offset);
        Commit();
        asserterror
        begin
            VerifyCostBudgetByCostCenterCaption(CostBudgetByCostCenterPage, 1, CostCenter.Code);
            Error('')
        end;
        if GetLastErrorText <> '' then
            Error(NextSetNotAvailableError);
    end;

    local procedure VerifyFiltersOnCostTypeBalanceByViewMatrixPage(CostTypeBalancePage: TestPage "Cost Type Balance"; Period: Enum "Analysis Period Type"; Date: Date; Counter: Integer)
    var
        ColumnDate: Text[30];
        ColumnCaption: Text[30];
    begin
        ColumnDate := CreatePeriodFormat(Period, Date);
        ColumnCaption := GetColumnCaptionOnCostTypeBalancePage(CostTypeBalancePage, Counter);
        Assert.AreEqual(ColumnDate, ColumnCaption, InvalidColumnCaptionError);
    end;

    local procedure CreatePeriodFormat(PeriodType: Enum "Analysis Period Type"; Date: Date): Text[30]
    begin
        case PeriodType of
            "Analysis Period Type"::Day:
                exit(Format(Date));
            "Analysis Period Type"::Week:
                begin
                    if Date2DWY(Date, 2) = 1 then
                        Date := Date + 7 - Date2DWY(Date, 1);
                    exit(Format(Date, 0, '<Week>.<Year4>'));
                end;
            "Analysis Period Type"::Month:
                exit(Format(Date, 0, '<Month Text,3> <Year4>'));
            "Analysis Period Type"::Quarter:
                exit(Format(Date, 0, '<Quarter>/<Year4>'));
            "Analysis Period Type"::Year:
                exit(Format(Date, 0, '<Year4>'));
            "Analysis Period Type"::"Accounting Period":
                exit(Format(Date));
        end;
    end;

    local procedure GetCellValueOnCostTypeBalancePage(var CostTypeBalancePage: TestPage "Cost Type Balance"; ColumnNo: Integer) Value: Text[30]
    begin
        case ColumnNo of
            1:
                Value := CostTypeBalancePage.MatrixForm.Column1.Value();
            2:
                Value := CostTypeBalancePage.MatrixForm.Column2.Value();
            3:
                Value := CostTypeBalancePage.MatrixForm.Column3.Value();
            4:
                Value := CostTypeBalancePage.MatrixForm.Column4.Value();
            5:
                Value := CostTypeBalancePage.MatrixForm.Column5.Value();
            6:
                Value := CostTypeBalancePage.MatrixForm.Column6.Value();
            7:
                Value := CostTypeBalancePage.MatrixForm.Column7.Value();
            8:
                Value := CostTypeBalancePage.MatrixForm.Column8.Value();
            9:
                Value := CostTypeBalancePage.MatrixForm.Column9.Value();
            10:
                Value := CostTypeBalancePage.MatrixForm.Column10.Value();
            11:
                Value := CostTypeBalancePage.MatrixForm.Column11.Value();
            12:
                Value := CostTypeBalancePage.MatrixForm.Column12.Value();
            else
                Error(InvalidColumnIndex)
        end;
    end;

    local procedure GetColumnAmountOnCostTypeBalancePage(CostTypeBalancePage: TestPage "Cost Type Balance"; CostTypeNo: Code[30]; NewColoumnNo: Integer) Value: Text[30]
    begin
        CostTypeBalancePage.MatrixForm.FILTER.SetFilter("No.", CostTypeNo);
        Value := GetCellValueOnCostTypeBalancePage(CostTypeBalancePage, NewColoumnNo + 1);
    end;

    local procedure GetColumnCaptionOnCostTypeBalancePage(var CostTypeBalancePage: TestPage "Cost Type Balance"; ColumnNo: Integer) Caption: Text[30]
    begin
        case ColumnNo of
            1:
                Caption := CostTypeBalancePage.MatrixForm.Column1.Caption;
            2:
                Caption := CostTypeBalancePage.MatrixForm.Column2.Caption;
            3:
                Caption := CostTypeBalancePage.MatrixForm.Column3.Caption;
            4:
                Caption := CostTypeBalancePage.MatrixForm.Column4.Caption;
            5:
                Caption := CostTypeBalancePage.MatrixForm.Column5.Caption;
            6:
                Caption := CostTypeBalancePage.MatrixForm.Column6.Caption;
            7:
                Caption := CostTypeBalancePage.MatrixForm.Column7.Caption;
            8:
                Caption := CostTypeBalancePage.MatrixForm.Column8.Caption;
            9:
                Caption := CostTypeBalancePage.MatrixForm.Column9.Caption;
            10:
                Caption := CostTypeBalancePage.MatrixForm.Column10.Caption;
            11:
                Caption := CostTypeBalancePage.MatrixForm.Column11.Caption;
            12:
                Caption := CostTypeBalancePage.MatrixForm.Column12.Caption;
            else
                Error(InvalidColumnIndex)
        end;
    end;

    local procedure GetColumnDatesOnCostTypeBalancePage(CostTypeBalancePage: TestPage "Cost Type Balance"; var DateBeforeInvokingAction: Date; var DateAfterInvokingAction: Date; ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set")
    var
        ColumnNo: Integer;
    begin
        ColumnNo := LibraryRandom.RandInt(12); // Pick a random column for the matrix page.
        Evaluate(DateBeforeInvokingAction, GetColumnCaptionOnCostTypeBalancePage(CostTypeBalancePage, ColumnNo));
        InvokeActionOnCostTypeBalancePage(CostTypeBalancePage, ActionItem);
        Evaluate(DateAfterInvokingAction, GetColumnCaptionOnCostTypeBalancePage(CostTypeBalancePage, ColumnNo));
    end;

    local procedure GetGlobalDimensionCodeValue(DimNo: Integer): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(DimNo));
        exit(DimensionValue.Code);
    end;

    local procedure GetBusinessUnitFilterValue(): Code[10]
    var
        BusinessUnit: Record "Business Unit";
    begin
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        exit(BusinessUnit.Code);
    end;

    local procedure GetBudgetFilterValue(): Code[10]
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        exit(GLBudgetName.Name);
    end;

    local procedure InvokeActionOnCostTypeBalancePage(var CostTypeBalancePage: TestPage "Cost Type Balance"; ActionItem: Option "Previous Set","Previous Column","Next Column","Next Set")
    begin
        case ActionItem of
            ActionItem::"Previous Set":
                CostTypeBalancePage.PreviousSet.Invoke();
            ActionItem::"Previous Column":
                CostTypeBalancePage.PreviousColumn.Invoke();
            ActionItem::"Next Column":
                CostTypeBalancePage.NextColumn.Invoke();
            ActionItem::"Next Set":
                CostTypeBalancePage.NextSet.Invoke();
        end;
    end;

    local procedure SetFieldsOnCostTypeBalancePage(var CostTypeBalancePage: TestPage "Cost Type Balance"; PeriodTypeOption: Text[30]; AmountTypeOption: Text[30]; CostCenterCode: Code[20]; CostObjectCode: Code[20])
    begin
        CostTypeBalancePage.AmountType.SetValue(AmountTypeOption);
        CostTypeBalancePage.PeriodType.SetValue(PeriodTypeOption);
        CostTypeBalancePage.CostCenterFilter.SetValue(CostCenterCode);
        CostTypeBalancePage.CostObjectFilter.SetValue(CostObjectCode);
    end;

    local procedure OpenCostBudgetByCostCenterPage(var CostBudgetByCostCenter: TestPage "Cost Budget by Cost Center"; AmountTypeOption: Text[30]; PeriodTypeOption: Text[30]; CostBudgetName: Text[10]) ExpectedDate: Date
    begin
        CostBudgetByCostCenter.OpenEdit();
        ExpectedDate := GetCurrentDate(CostBudgetByCostCenter.FILTER.GetFilter("Date Filter"));
        SetFieldsOnCostBudgetByCostCenterPage(CostBudgetByCostCenter, AmountTypeOption, PeriodTypeOption, CostBudgetName);
    end;

    local procedure OpenCostBudgetByCostObjectPage(var CostBudgetbyCostObject: TestPage "Cost Budget by Cost Object"; AmountTypeOption: Text[30]; PeriodTypeOption: Text[30]; CostBudgetName: Text[10]) ExpectedDate: Date
    begin
        CostBudgetbyCostObject.OpenEdit();
        ExpectedDate := GetCurrentDate(CostBudgetbyCostObject.FILTER.GetFilter("Date Filter"));
        SetFieldsOnCostBudgetByCostObjectPage(CostBudgetbyCostObject, AmountTypeOption, PeriodTypeOption, CostBudgetName);
    end;

    local procedure OpenCostTypeBalanceBudgetPage(var CostTypeBalanceBudgetPage: TestPage "Cost Type Balance/Budget"; AmountTypeOption: Text[30]; PeriodTypeOption: Text[30]; CostBudgetName: Text[10]; CostCenterCode: Text[20]; CostObjectCode: Text[20]) ExpectedDate: Date
    begin
        CostTypeBalanceBudgetPage.OpenEdit();
        ExpectedDate := GetCurrentDate(CostTypeBalanceBudgetPage.FILTER.GetFilter("Date Filter"));
        SetFieldsOnCostTypeBalanceBudgetPage(
          CostTypeBalanceBudgetPage, AmountTypeOption, PeriodTypeOption, CostBudgetName, CostCenterCode, CostObjectCode);
    end;

    local procedure OpenCostTypeBalancePage(var CostTypeBalancePage: TestPage "Cost Type Balance"; PeriodTypeOption: Text[30]; AmountTypeOption: Text[30]; CostCenterCode: Code[20]; CostObjectCode: Code[20]; CostTypeNo: Code[20]; ColoumnNo: Integer) CostTypeBalanceAmount: Text[30]
    begin
        CostTypeBalancePage.OpenEdit();
        SetFieldsOnCostTypeBalancePage(
          CostTypeBalancePage, PeriodTypeOption, AmountTypeOption, CostCenterCode, CostObjectCode);
        CostTypeBalanceAmount := GetColumnAmountOnCostTypeBalancePage(CostTypeBalancePage, CostTypeNo, ColoumnNo);
    end;

    local procedure UpdateCostType(var CostType: Record "Cost Type"; Type: Option "Cost Type",Heading,Total,"Begin-Total","End-Total"; GLAccountNo2: Code[20])
    begin
        CostType.Validate(Type, Type);
        CostType.Validate("G/L Account Range", GLAccountNo2);
        CostType.Modify(true);
    end;

    local procedure CopyCostCenters(var FromCostCenter: Record "Cost Center"; var ToCostCenter: Record "Cost Center")
    begin
        ToCostCenter.DeleteAll();
        if FromCostCenter.FindSet() then
            repeat
                ToCostCenter.Init();
                ToCostCenter := FromCostCenter;
                ToCostCenter.Insert();
            until FromCostCenter.Next() = 0;
    end;

    local procedure CopyCostObjects(var FromCostObject: Record "Cost Object"; var ToCostObject: Record "Cost Object")
    begin
        ToCostObject.DeleteAll();
        if FromCostObject.FindSet() then
            repeat
                ToCostObject.Init();
                ToCostObject := FromCostObject;
                ToCostObject.Insert();
            until FromCostObject.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MFHandlerChartOfCostCenters(var ChartOfCostCenters: TestPage "Chart of Cost Centers")
    begin
        ChartOfCostCenters.FILTER.SetFilter(Code, CostCenterFilter);
        ChartOfCostCenters.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MFHandlerChartOfCostObjects(var ChartOfCostObjects: TestPage "Chart of Cost Objects")
    begin
        ChartOfCostObjects.FILTER.SetFilter(Code, CostObjectFilter);
        ChartOfCostObjects.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CostJournalBatchPageHandler(var CostJournalBatches: TestPage "Cost Journal Batches")
    begin
        CostJournalBatches.FILTER.SetFilter(Name, CostJournalBatchName);
        CostJournalBatches.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MFHandlerChartOfCostAccountOk(var ChartOfAccounts: TestPage "Chart of Accounts")
    begin
        GLAccountNo := ChartOfAccounts."No.".Value();
        ChartOfAccounts.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MFHandlerChartOfCostAccountCancel(var ChartOfAccounts: TestPage "Chart of Accounts")
    begin
        GLAccountNo := ChartOfAccounts."No.".Value();
        ChartOfAccounts.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MFHandlerCostBudgetEntries(var CostBudgetEntries: TestPage "Cost Budget Entries")
    begin
        case ActionFilter of
            ActionFilter::SetValue:
                CostBudgetEntries.Amount.SetValue(LibraryRandom.RandDec(100, 2));
            ActionFilter::Verify:
                begin
                    CostBudgetEntries."Last Modified By User".AssertEquals(UpperCase(UserId));
                    CostBudgetEntries.Date.AssertEquals(WorkDate());
                    CostBudgetEntries."Cost Type No.".AssertEquals(CostTypeNo);
                    CostBudgetEntries."Cost Center Code".AssertEquals(CostCenterFilter);
                    CostBudgetEntries."Cost Object Code".AssertEquals(CostObjectFilter);
                    CostBudgetEntries."Entry No.".AssertEquals(EntryNo);
                end;
        end;
        CostBudgetEntries.OK().Invoke();
    end;
}

