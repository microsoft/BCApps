codeunit 134810 "ERM Cost Accounting Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        CostCenterDim: Code[20];
        CostObjectDim: Code[20];
        CostCenterError: Label 'No Cost Center should be created.';
        CostCenterNotFoundError: Label 'Cost Center with No %1 was not found.';
        CostObjectError: Label 'No Cost Object should be created.';
        CostObjectNotFoundError: Label 'Cost Object with No %1 was not found.';
        CostTypeError: Label 'No Cost Type should be created.';
        CostTypeNotFoundError: Label 'Cost Type with No %1 was not found.';
        EmptyCCDimError: Label '''Cost Center Dimension must be filled in. Enter a value.''';
        EmptyCODimError: Label '''Cost Object Dimension must be filled in. Enter a value.''';
        ExpectedValueIsDifferentError: Label 'Expected value of %1 field is different than the actual one.';
        NoRecordsInFilterError: Label 'There are no records within the filters specified for table %1. The filters are: %2.';
        SameCCAndCODimError: Label 'The dimension values for cost center and cost object cannot be same.';
        UnexpectedErrorMessage: Label 'Unexpected error message.';

    [Test]
    [HandlerFunctions('RPHandlerOKAction,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure AlignCCAndCODimensions()
    begin
        // Verify that Cost Center Dimension and Cost Object Dimension fields can be aligned to different dimensions
        Initialize();

        // Exercise:
        Commit();
        REPORT.Run(REPORT::"Update Cost Acctg. Dimensions");

        // Verify:
        ValidateCCAndCODimensions(CostCenterDim, CostObjectDim);

        // Clean-up:
        Clear(CostCenterDim);
        Clear(CostObjectDim);
    end;

    [Test]
    [HandlerFunctions('RPHandlerSameDimension')]
    [Scope('OnPrem')]
    procedure AlignCCAndCOToSameDimension()
    var
        error: Text[200];
    begin
        // Verify that Cost Center Dimension and Cost Object Dimension fields cannot be set to the same value
        Initialize();

        // Exercise:
        Commit();
        asserterror REPORT.Run(REPORT::"Update Cost Acctg. Dimensions");
        error := GetLastErrorText;
        Assert.IsTrue(StrPos(error, SameCCAndCODimError) > 0, UnexpectedErrorMessage);
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('RPHandlerEmptyCCDimValue')]
    [Scope('OnPrem')]
    procedure AlignCCToEmptyDimensionValue()
    var
        error: Text[200];
    begin
        // Verify that Cost Center Dimension field cannot have an empty value
        Initialize();

        // Exercise:
        Commit();
        asserterror REPORT.Run(REPORT::"Update Cost Acctg. Dimensions");
        error := GetLastErrorText;
        Assert.IsTrue(StrPos(error, EmptyCCDimError) > 0, UnexpectedErrorMessage);
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('RPHandlerEmptyCODimValue')]
    [Scope('OnPrem')]
    procedure AlignCOToEmptyDimensionValue()
    var
        error: Text[200];
    begin
        // Verify that Cost Center Dimension field cannot have an empty value
        Initialize();

        // Exercise:
        Commit();
        asserterror REPORT.Run(REPORT::"Update Cost Acctg. Dimensions");
        error := GetLastErrorText;
        Assert.IsTrue(StrPos(error, EmptyCODimError) > 0, UnexpectedErrorMessage);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalanceSheetAccAlignGLAuto()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        BalanceSheetAccAlignGL(CostAccountingSetup."Align G/L Account"::Automatic);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalanceSheetAccAlignGLPrompt()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        BalanceSheetAccAlignGL(CostAccountingSetup."Align G/L Account"::Prompt);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCancelAction')]
    [Scope('OnPrem')]
    procedure CancelAlignOfCCAndCODimensions()
    var
        PrevCCDimensionCode: Code[20];
        PrevCODimensionCOde: Code[20];
    begin
        // Verify that Cost Center Dimension and Cost Object Dimension fields are not updated if the user cancels the operation
        Initialize();

        // Setup:
        PrevCCDimensionCode := CostCenterDimension();
        PrevCODimensionCOde := CostObjectDimension();

        // Exercise:
        Commit();
        REPORT.Run(REPORT::"Update Cost Acctg. Dimensions");

        // Verify:
        ValidateCCAndCODimensions(PrevCCDimensionCode, PrevCODimensionCOde);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCostTypeChangeName()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
        NewName: Text[100];
    begin
        // Setup:
        Initialize();
        LibraryCostAccounting.CreateCostType(CostType);

        // Exercise:
        NewName := CostType.Name + Format(LibraryRandom.RandInt(100));
        CostType.Validate(Name, NewName);
        CostType.Modify(true);

        // Verify:
        CostType.TestField(Name, NewName);
        GLAccount.Get(CostType."G/L Account Range");
        Assert.AreNotEqual(GLAccount.Name, NewName, StrSubstNo(ExpectedValueIsDifferentError, GLAccount.FieldName(Name)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCostTypeChangeNumber()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
        NewNumber: Code[20];
        OldNumber: Code[20];
    begin
        // Setup:
        Initialize();
        LibraryCostAccounting.CreateCostType(CostType);
        OldNumber := CostType."No.";

        // Exercise:
        NewNumber := IncStr(OldNumber);
        CostType.Rename(NewNumber);

        // Verify:
        CostType.TestField("No.", NewNumber);
        GLAccount.Get(CostType."G/L Account Range");
        Assert.AreNotEqual(GLAccount."No.", NewNumber, StrSubstNo(ExpectedValueIsDifferentError, GLAccount.FieldName("No.")));

        // Cleanup:
        CostType.Rename(OldNumber);
        CostType.TestField("No.", OldNumber);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCostTypeHierarchy()
    var
        BeginCostTypeNo: Code[20];
        EndCostTypeNo: Code[20];
    begin
        // Setup:
        Initialize();
        CreateBeginEndCostTypes(BeginCostTypeNo, EndCostTypeNo);

        // Exercise:
        CostAccountMgt.IndentCostTypes(false);

        // Verify:
        ValidateBeginEndCostTypes(BeginCostTypeNo, EndCostTypeNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndTotalCostCenterHasBlockedOn()
    var
        CostCenter: Record "Cost Center";
        CostCenterCode: Code[20];
    begin
        // Verify that a Cost Center whith Line Type = 'End-Total' has 'Blocked' checkbox checked, by default.

        // Setup:
        Initialize();
        LibraryCostAccounting.CreateCostCenter(CostCenter);

        // Excercise:
        CostCenter.Validate("Line Type", CostCenter."Line Type"::"End-Total");
        CostCenter.Modify(true);

        // Verify:
        CostCenter.TestField(Blocked, true);
        CostCenterCode := CostCenter.Code;

        // Cleanup:
        Clear(CostCenter);
        CostCenter.Get(CostCenterCode);
        CostCenter.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndTotalCostObjectHasBlockedOn()
    var
        CostObject: Record "Cost Object";
        CostObjectCode: Code[20];
    begin
        // Verify that a Cost Object whith Line Type = 'End-Total' has 'Blocked' checkbox checked, by default.

        // Setup:
        Initialize();
        LibraryCostAccounting.CreateCostObject(CostObject);

        // Excercise:
        CostObject.Validate("Line Type", CostObject."Line Type"::"End-Total");
        CostObject.Modify(true);

        // Verify:
        CostObject.TestField(Blocked, true);
        CostObjectCode := CostObject.Code;

        // Cleanup:
        Clear(CostObject);
        CostObject.Get(CostObjectCode);
        CostObject.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndTotalCostTypeHasBlockedOn()
    var
        CostType: Record "Cost Type";
    begin
        // Verify that a Cost Type whith Line Type = 'End-Total' has 'Blocked' checkbox checked, by default.

        Initialize();

        // Setup:
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        // Exercise:
        CostType.Validate(Type, CostType.Type::"End-Total");
        CostType.Modify(true);

        // Verify:
        CostType.TestField(Blocked, true);

        // Cleanup:
        CostType.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure GetIncomeStatementEntriesOnly()
    var
        CostType: Record "Cost Type";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        Initialize();
        LibraryCostAccounting.VerifyCostTypeIntegrity();

        // Setup:
        CostType.SetFilter("G/L Account Range", '<>%1', '');
        CostType.SetFilter("Balance at Date", '%1', 0);
        CostType.SetFilter("Balance to Allocate", '%1', 0);
        if not CostType.FindFirst() then
            Error(NoRecordsInFilterError, CostType.TableCaption(), CostType.GetFilters);
        CostType.Delete(true);

        // Exercise:
        CostAccountMgt.GetCostTypesFromChartOfAccount();

        // Verify:
        Clear(CostType);
        LibraryCostAccounting.GetAllCostTypes(CostType);
        ValidateGLAccountIsIncomeStmt(CostType);
        LibraryCostAccounting.VerifyCostTypeIntegrity();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetCostCentersFromDimension()
    var
        CostCenter: Record "Cost Center";
        CostAccountingSetup: Record "Cost Accounting Setup";
        DimensionValue: Record "Dimension Value";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        Initialize();

        // Setup:
        CostAccountingSetup.Get();
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align Cost Center Dimension"),
          CostAccountingSetup."Align Cost Center Dimension"::"No Alignment");
        LibraryDimension.CreateDimensionValue(DimensionValue, CostAccountingSetup."Cost Center Dimension");

        // Exercise:
        CostAccountMgt.CreateCostCenters();

        // Verify:
        Assert.IsTrue(CostCenter.Get(DimensionValue.Code), StrSubstNo(CostCenterNotFoundError, DimensionValue.Code));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetCostObjetcsFromDimension()
    var
        CostObject: Record "Cost Object";
        CostAccountingSetup: Record "Cost Accounting Setup";
        DimensionValue: Record "Dimension Value";
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        Initialize();

        // Setup:
        CostAccountingSetup.Get();
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align Cost Object Dimension"),
          CostAccountingSetup."Align Cost Object Dimension"::"No Alignment");
        LibraryDimension.CreateDimensionValue(DimensionValue, CostAccountingSetup."Cost Object Dimension");

        // Exercise:
        CostAccountMgt.CreateCostObjects();

        // Verify:
        Assert.IsTrue(CostObject.Get(DimensionValue.Code), StrSubstNo(CostObjectNotFoundError, DimensionValue.Code));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure RegisterCostTypesInGLAccounts()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
    begin
        Initialize();

        // Setup:
        LibraryCostAccounting.CreateCostType(CostType);
        GLAccount.Get(CostType."G/L Account Range");
        GLAccount.Validate("Cost Type No.", '');
        GLAccount.Modify(true);

        // Exercise:
        CostAccountMgt.LinkCostTypesToGLAccountsYN();

        // Verify:
        GLAccount.Get(CostType."G/L Account Range");
        GLAccount.TestField("Cost Type No.", CostType."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RemoveCostTypeNoLink()
    var
        GLAccount: Record "G/L Account";
        CostType: Record "Cost Type";
    begin
        Initialize();

        // Setup:
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        GLAccount.TestField("Cost Type No.", GLAccount."No.");

        // Exercise:
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);

        // Verify:
        GLAccount.TestField("Cost Type No.", '');
        CostType.Get(GLAccount."No.");
        CostType.TestField("G/L Account Range", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAlignDimensionBeginTotalCC()
    var
        CostCenter: Record "Cost Center";
        CostCenterNo: Code[20];
    begin
        // Add a new Cost Center Dimension Value with line type 'Begin-Total' and check that no Cost Center is created (Alignment = Automic)

        CostCenterNo := AlignCostCenters(AlignmentTypeAutomatic(), DimensionValueTypeBeginTotal());

        // Verify:
        Assert.IsFalse(CostCenter.Get(CostCenterNo), CostCenterError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAlignDimensionBeginTotalCO()
    var
        CostObject: Record "Cost Object";
        CostObjectNo: Code[20];
    begin
        // Add a new Cost Object Dimension Value with line type 'Begin-Total' and check that no Cost Object is created (Alignment = Automic)

        CostObjectNo := AlignCostObjects(AlignmentTypeAutomatic(), DimensionValueTypeBeginTotal());

        // Verify:
        Assert.IsFalse(CostObject.Get(CostObjectNo), CostObjectError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAlignDimensionEndTotalCC()
    var
        CostCenter: Record "Cost Center";
        CostCenterNo: Code[20];
    begin
        // Add a new Cost Center Dimension Value with line type 'End-Total' and check that no Cost Center is created (Alignment = Automic)

        CostCenterNo := AlignCostCenters(AlignmentTypeAutomatic(), DimensionValueTypeEndTotal());

        // Verify:
        Assert.IsFalse(CostCenter.Get(CostCenterNo), CostCenterError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAlignDimensionEndTotalCO()
    var
        CostObject: Record "Cost Object";
        CostObjectNo: Code[20];
    begin
        // Add a new Cost Object Dimension Value with line type 'End-Total' and check that no Cost Object is created (Alignment = Automic)

        CostObjectNo := AlignCostObjects(AlignmentTypeAutomatic(), DimensionValueTypeEndTotal());

        // Verify:
        Assert.IsFalse(CostObject.Get(CostObjectNo), CostObjectError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestAutomaticAlignOnChartOfAcc()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
    begin
        // Change Align G/L Account to "Automatic" and verify that when adding a new Income G/L Account,
        // a Cost Type is also created.

        Initialize();

        // Setup:
        LibraryCostAccounting.SetAlignment(AlignGLAccountFieldNo(), AlignmentTypeAutomatic());

        // Excercise:
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);

        // Verify:
        Assert.IsTrue(CostType.Get(GLAccount."Cost Type No."), StrSubstNo(CostTypeNotFoundError, GLAccount."Cost Type No."));
        CostType.TestField("G/L Account Range", GLAccount."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestAutomaticAlignOnCostCenter()
    var
        CostCenter: Record "Cost Center";
        CostCenterNo: Code[20];
    begin
        // Change Align Cost Centers to "Automatic" and verify that when adding a new dimension value to Cost Centers Dimension
        // a Cost Center is also created

        CostCenterNo := AlignCostCenters(AlignmentTypeAutomatic(), DimensionValueTypeStandard());

        // Verify:
        Assert.IsTrue(CostCenter.Get(CostCenterNo), StrSubstNo(CostCenterNotFoundError, CostCenterNo));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestAutomaticAlignOnCostObject()
    var
        CostObject: Record "Cost Object";
        CostObjectNo: Code[20];
    begin
        // Change Align Cost Centers to "Automatic" and verify that when adding a new dimension value to Cost Objects Dimension
        // a Cost Object is also created

        CostObjectNo := AlignCostObjects(AlignmentTypeAutomatic(), DimensionValueTypeStandard());

        // Verify:
        Assert.IsTrue(CostObject.Get(CostObjectNo), StrSubstNo(CostCenterNotFoundError, CostObjectNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoAlignOnChartOfAccounts()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
    begin
        // Change Align G/L Account to "No Alignment" and verify that when adding a new Income G/L Account,
        // no Cost Type id added to the Chart of Cost Types.

        Initialize();

        // Setup:
        LibraryCostAccounting.SetAlignment(AlignGLAccountFieldNo(), AlignmentTypeNoAlignment());

        // Excercise:
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);

        // Verify:
        Assert.IsFalse(CostType.Get(GLAccount."Cost Type No."), CostTypeError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoAlignOnCostCenters()
    var
        CostCenter: Record "Cost Center";
        CostCenterNo: Code[20];
    begin
        // Change Align Cost Centers to "No Alignment" and verify that when adding a new dimension value to Cost Centers Dimension
        // no Cost Center is added to the Chart of Cost Centers.

        CostCenterNo := AlignCostCenters(AlignmentTypeNoAlignment(), DimensionValueTypeStandard());

        // Verify:
        Assert.IsFalse(CostCenter.Get(CostCenterNo), CostCenterError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoAlignOnCostObjects()
    var
        CostObject: Record "Cost Object";
        CostObjectNo: Code[20];
    begin
        // Change Align Cost Objects to "No Alignment" and verify that when adding a new dimension value to Cost Objects Dimension
        // no Cost Object is added to the Chart of Cost Objects.

        CostObjectNo := AlignCostObjects(AlignmentTypeNoAlignment(), DimensionValueTypeStandard());

        // Verify:
        Assert.IsFalse(CostObject.Get(CostObjectNo), CostObjectError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPromptAlignOnChartOfAccY()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
    begin
        // Change Align G/L Account to "Prompt" and verify that when adding a new Income G/L Account,
        // a Cost Type is also created if the user selects "Yes" in the confirmation message.

        Initialize();

        // Setup:
        LibraryCostAccounting.SetAlignment(AlignGLAccountFieldNo(), AlignmentTypePrompt());

        // Excercise:
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);

        // Verify:
        Assert.IsTrue(CostType.Get(GLAccount."Cost Type No."), StrSubstNo(CostTypeNotFoundError, GLAccount."Cost Type No."));
        CostType.TestField("G/L Account Range", GLAccount."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestPromptAlignOnChartOfAccN()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
    begin
        // Change Align G/L Account to "Prompt" and verify that when adding a new Income G/L Account,
        // no Cost Type is created if the user selects "No" in the confirmation message.

        Initialize();

        // Setup:
        LibraryCostAccounting.SetAlignment(AlignGLAccountFieldNo(), AlignmentTypePrompt());

        // Excercise:
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);

        // Verify:
        Assert.IsFalse(CostType.Get(GLAccount."Cost Type No."), CostTypeError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPromptAlignOnCostCentersY()
    var
        CostCenter: Record "Cost Center";
        CostCenterNo: Code[20];
    begin
        // Change Align Cost Centers to "Prompt" and verify that when adding a new dimension value to Cost Centers Dimension
        // a Cost Center is also created if the user selects "Yes" in the confirmation message

        CostCenterNo := AlignCostCenters(AlignmentTypePrompt(), DimensionValueTypeStandard());

        // Verify:
        Assert.IsTrue(CostCenter.Get(CostCenterNo), StrSubstNo(CostCenterNotFoundError, CostCenterNo));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestPromptAlignOnCostCentersN()
    var
        CostCenter: Record "Cost Center";
        CostCenterNo: Code[20];
    begin
        // Change Align Cost Centers to "Prompt" and verify that when adding a new dimension value to Cost Centers Dimension
        // no Cost Center is created if the user selects "No" in the confirmation message

        CostCenterNo := AlignCostCenters(AlignmentTypePrompt(), DimensionValueTypeStandard());

        // Verify:
        Assert.IsFalse(CostCenter.Get(CostCenterNo), CostCenterError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPromptAlignOnCostObjectsY()
    var
        CostObject: Record "Cost Object";
        CostObjectNo: Code[20];
    begin
        // Change Align Cost Objects to "Prompt" and verify that when adding a new dimension value to Cost Objects Dimension
        // a Cost Object is also created if the user selects "Yes" in the confirmation message

        CostObjectNo := AlignCostObjects(AlignmentTypePrompt(), DimensionValueTypeStandard());

        // Verify:
        Assert.IsTrue(CostObject.Get(CostObjectNo), StrSubstNo(CostCenterNotFoundError, CostObjectNo));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestPromptAlignOnCostObjectsN()
    var
        CostObject: Record "Cost Object";
        CostObjectNo: Code[20];
    begin
        // Change Align Cost Objects to "Prompt" and verify that when adding a new dimension value to Cost Objects Dimension
        // no Cost Object is created if the user selects "No" in the confirmation message

        CostObjectNo := AlignCostObjects(AlignmentTypePrompt(), DimensionValueTypeStandard());

        // Verify:
        Assert.IsFalse(CostObject.Get(CostObjectNo), CostObjectError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateCCDimension()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostCenter: Record "Cost Center";
        CostCenterNo: Code[20];
    begin
        // Check that a cost center can be aligned to any dimension

        Initialize();

        // Setup:
        UpdateAlignedDimension(CostAccountingSetup.FieldNo("Cost Center Dimension"));

        // Excercise:
        CostCenterNo := AlignCostCenters(AlignmentTypeAutomatic(), DimensionValueTypeStandard());

        // Verify:
        Assert.IsTrue(CostCenter.Get(CostCenterNo), StrSubstNo(CostCenterNotFoundError, CostCenterNo));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateCODimension()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostObject: Record "Cost Object";
        CostObjectNo: Code[20];
    begin
        // Check that a cost object can be aligned to any dimension

        Initialize();

        // Setup:
        UpdateAlignedDimension(CostAccountingSetup.FieldNo("Cost Object Dimension"));

        // Excercise:
        CostObjectNo := AlignCostObjects(AlignmentTypeAutomatic(), DimensionValueTypeStandard());

        // Verify:
        Assert.IsTrue(CostObject.Get(CostObjectNo), StrSubstNo(CostObjectNotFoundError, CostObjectNo));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateGLRangeAndCostTypeNo()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
        CostTypeNo: Code[20];
    begin
        Initialize();
        LibraryCostAccounting.VerifyCostTypeIntegrity();

        // Setup:
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);

        CostType.SetFilter("G/L Account Range", '%1', GLAccount."No.");
        if not CostType.FindFirst() then
            Error(NoRecordsInFilterError, CostType.TableCaption(), CostType.GetFilters);
        CostTypeNo := CostType."No.";

        CostType.Delete(true);

        // Exercise:
        CostAccountMgt.GetCostTypesFromChartOfAccount();

        // Verify:
        ValidateGLAccountCostTypeRef(CostTypeNo);
        LibraryCostAccounting.VerifyCostTypeIntegrity();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cost Accounting Setup");
        LibraryCostAccounting.InitializeCASetup();
    end;

    [Normal]
    local procedure AlignGLAccountFieldNo(): Integer
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        exit(CostAccountingSetup.FieldNo("Align G/L Account"));
    end;

    [Normal]
    local procedure AlignCostCenters(AlignCostCenters: Option; LineType: Option): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        // Setup:
        Initialize();
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align Cost Center Dimension"), AlignCostCenters);

        // Excercise:
        CreateDimensionValue(DimensionValue, CostCenterDimension(), LineType);
        exit(DimensionValue.Code);
    end;

    [Normal]
    local procedure AlignCostObjects(AlignCostObjects: Option; LineType: Option): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        // Setup:
        Initialize();
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align Cost Object Dimension"), AlignCostObjects);

        // Excercise:
        CreateDimensionValue(DimensionValue, CostObjectDimension(), LineType);
        exit(DimensionValue.Code);
    end;

    [Normal]
    local procedure AlignmentTypeAutomatic(): Integer
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        exit(CostAccountingSetup."Align G/L Account"::Automatic);
    end;

    [Normal]
    local procedure AlignmentTypeNoAlignment(): Integer
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        exit(CostAccountingSetup."Align G/L Account"::"No Alignment");
    end;

    [Normal]
    local procedure AlignmentTypePrompt(): Integer
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        exit(CostAccountingSetup."Align G/L Account"::Prompt);
    end;

    local procedure BalanceSheetAccAlignGL(AlignGLAccount: Option)
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
        GLAccount: Record "G/L Account";
    begin
        Initialize();

        // Setup:
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align G/L Account"), AlignGLAccount);

        // Exercise:
        LibraryCostAccounting.CreateBalanceSheetGLAccount(GLAccount);

        // Verify:
        GLAccount.TestField("Cost Type No.", '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [Normal]
    local procedure CostCenterDimension(): Code[20]
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        exit(CostAccountingSetup."Cost Center Dimension");
    end;

    [Normal]
    local procedure CostObjectDimension(): Code[20]
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        exit(CostAccountingSetup."Cost Object Dimension");
    end;

    [Normal]
    local procedure CreateDimensionValue(var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20]; DimensionValueType: Option)
    begin
        DimensionValue.Init();
        DimensionValue.Validate("Dimension Code", DimensionCode);
        DimensionValue.Validate("Dimension Value Type", DimensionValueType);
        DimensionValue.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(DimensionValue.FieldNo(Code), DATABASE::"Dimension Value"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Dimension Value", DimensionValue.FieldNo(Code))));
        DimensionValue.Insert(true);
    end;

    local procedure CreateBeginEndCostTypes(var BeginTotalNo: Code[20]; var EndTotalNo: Code[20])
    var
        BeginCostType: Record "Cost Type";
        CostType: Record "Cost Type";
        EndCostType: Record "Cost Type";
        Index: Integer;
    begin
        LibraryCostAccounting.CreateCostType(BeginCostType);
        BeginCostType.Validate(Type, BeginCostType.Type::"Begin-Total");
        BeginCostType.Modify(true);
        BeginTotalNo := BeginCostType."No.";

        for Index := 1 to LibraryRandom.RandInt(3) do begin
            Clear(CostType);
            LibraryCostAccounting.CreateCostType(CostType);
        end;

        LibraryCostAccounting.CreateCostType(EndCostType);
        EndCostType.Validate(Type, EndCostType.Type::"End-Total");
        EndCostType.Modify(true);
        EndTotalNo := EndCostType."No.";
    end;

    [Normal]
    local procedure DimensionValueTypeStandard(): Integer
    var
        DimensionValue: Record "Dimension Value";
    begin
        exit(DimensionValue."Dimension Value Type"::Standard);
    end;

    [Normal]
    local procedure DimensionValueTypeBeginTotal(): Integer
    var
        DimensionValue: Record "Dimension Value";
    begin
        exit(DimensionValue."Dimension Value Type"::"Begin-Total");
    end;

    [Normal]
    local procedure DimensionValueTypeEndTotal(): Integer
    var
        DimensionValue: Record "Dimension Value";
    begin
        exit(DimensionValue."Dimension Value Type"::"End-Total");
    end;

    [Normal]
    local procedure FindCCAndCODimensions(var CostCenterDim: Code[20]; var CostObjectDim: Code[20])
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
        Dimension: Record Dimension;
    begin
        CostAccountingSetup.Get();
        Dimension.SetFilter(Code, '<>%1&<>%2', CostAccountingSetup."Cost Center Dimension", CostAccountingSetup."Cost Object Dimension");
        Dimension.Next(LibraryRandom.RandInt(Dimension.Count - 1));
        CostCenterDim := Dimension.Code;
        Dimension.Next();
        CostObjectDim := Dimension.Code;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // dummy message handler
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerCancelAction(var UpdateCCAndCOReqPage: TestRequestPage "Update Cost Acctg. Dimensions")
    var
        NewCCDimensionCode: Code[20];
        NewCODimensionCode: Code[20];
    begin
        FindCCAndCODimensions(NewCCDimensionCode, NewCODimensionCode);
        UpdateCCAndCOReqPage.CostCenterDimension.SetValue(NewCCDimensionCode);
        UpdateCCAndCOReqPage.CostObjectDimension.SetValue(NewCODimensionCode);

        // Exercise:
        UpdateCCAndCOReqPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerEmptyCCDimValue(var UpdateCCAndCOReqPage: TestRequestPage "Update Cost Acctg. Dimensions")
    begin
        UpdateCCAndCOReqPage.CostCenterDimension.SetValue('');

        UpdateCCAndCOReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerEmptyCODimValue(var UpdateCCAndCOReqPage: TestRequestPage "Update Cost Acctg. Dimensions")
    begin
        UpdateCCAndCOReqPage.CostObjectDimension.SetValue('');

        UpdateCCAndCOReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerOKAction(var UpdateCCAndCOReqPage: TestRequestPage "Update Cost Acctg. Dimensions")
    begin
        FindCCAndCODimensions(CostCenterDim, CostObjectDim);
        UpdateCCAndCOReqPage.CostCenterDimension.SetValue(CostCenterDim);
        UpdateCCAndCOReqPage.CostObjectDimension.SetValue(CostObjectDim);

        UpdateCCAndCOReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerSameDimension(var UpdateCCAndCOReqPage: TestRequestPage "Update Cost Acctg. Dimensions")
    begin
        UpdateCCAndCOReqPage.CostCenterDimension.SetValue(UpdateCCAndCOReqPage.CostObjectDimension.Value);

        UpdateCCAndCOReqPage.OK().Invoke();
    end;

    [Normal]
    local procedure UpdateAlignedDimension(FieldNo: Integer)
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
        Dimension: Record Dimension;
        "Field": Record "Field";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        CostAccountingSetup.Get();
        RecordRef.GetTable(CostAccountingSetup);
        FieldRef := RecordRef.Field(FieldNo);
        Field.Get(RecordRef.Number, FieldRef.Number);
        if Field.Type = Field.Type::Code then begin
            LibraryDimension.FindDimension(Dimension);
            Dimension.SetFilter(Code, '<>%1', CostAccountingSetup."Cost Center Dimension");
            Dimension.SetFilter(Code, '<>%1', CostAccountingSetup."Cost Object Dimension");
            Dimension.FindSet();
            Dimension.Next(LibraryRandom.RandInt(Dimension.Count));
            FieldRef.Validate(Dimension.Code);
            RecordRef.Modify(true);
        end;
    end;

    local procedure ValidateBeginEndCostTypes(BeginTotalNo: Code[20]; EndTotalNo: Code[20])
    var
        BeginCostType: Record "Cost Type";
        EndCostType: Record "Cost Type";
    begin
        BeginCostType.Get(BeginTotalNo);
        BeginCostType.TestField(Blocked, true);

        EndCostType.Get(EndTotalNo);
        EndCostType.TestField(Blocked, true);
        EndCostType.TestField(Totaling, BeginTotalNo + '..' + EndTotalNo);
    end;

    local procedure ValidateGLAccountCostTypeRef(CostTypeNo: Code[20])
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
    begin
        // The Cost Type has the G/L Account Range filled in.
        CostType.Get(CostTypeNo);
        CostType.TestField("G/L Account Range");

        // The G/L Accounts have the Cost Type No. filled in.
        LibraryCostAccounting.FindGLAccountsByCostType(GLAccount, CostType."G/L Account Range");
        repeat
            GLAccount.TestField("Cost Type No.", CostType."No.");
        until GLAccount.Next() = 0;
    end;

    local procedure ValidateGLAccountIsIncomeStmt(var CostType: Record "Cost Type")
    var
        GLAccount: Record "G/L Account";
    begin
        repeat
            LibraryCostAccounting.FindGLAccountsByCostType(GLAccount, CostType."G/L Account Range");
            repeat
                GLAccount.TestField("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
            until GLAccount.Next() = 0;
        until CostType.Next() = 0;
    end;

    [Normal]
    local procedure ValidateCCAndCODimensions(ExpectedCCDim: Code[20]; ExpectedCODim: Code[20])
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        CostAccountingSetup.TestField("Cost Center Dimension", ExpectedCCDim);
        CostAccountingSetup.TestField("Cost Object Dimension", ExpectedCODim);
    end;
}

