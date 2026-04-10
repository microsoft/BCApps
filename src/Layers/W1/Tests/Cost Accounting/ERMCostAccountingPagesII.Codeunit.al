codeunit 134823 "ERM Cost Accounting - Pages II"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting] [UI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        IndentBeginEndError: Label 'End-Total %1 does not belong to the corresponding Begin-Total.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryDimension: Codeunit "Library - Dimension";
        IsInitialized: Boolean;
        IndentationError: Label 'Indentation must be correct.';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestChartOfCostTypeEndTotalTypeCostType()
    var
        CostType: Record "Cost Type";
        ChartOfCostTypePage: TestPage "Chart of Cost Types";
        Type: Option "Cost Type",Heading,Total,"Begin-Total","End-Total";
    begin
        // [FEATURE] [Indent Cost Type]
        // [SCENARIO] error is displayed on invoking Indent Cost Type Action when there is no corresponding Begin-Total for a given End-Total.

        // [GIVEN] Initialize and Create Cost Type.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);

        LibraryLowerPermissions.SetCostAccountingEdit();
        // [WHEN] Modify Type of Cost Type and invoke Indent Cost Type Action on Chart Of Cost Type Page.
        UpdateCostType(CostType, Type::"End-Total", '');
        ChartOfCostTypePage.OpenEdit();
        asserterror ChartOfCostTypePage.IndentCostType.Invoke();

        // [THEN] To check error is diplayed when there is no corresponding 'Begin-Total' type Cost Type for every 'End-Total' type Cost Type.
        Assert.ExpectedError(StrSubstNo(IndentBeginEndError, CostType."No."));

        // Tear Down.
        ChartOfCostTypePage.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestChartOfCostTypeIndentCostTypeAction()
    var
        CostType: array[4] of Record "Cost Type";
        ChartOfCostTypePage: TestPage "Chart of Cost Types";
        Type: Option "Cost Type",Heading,Total,"Begin-Total","End-Total";
        i: Integer;
    begin
        // [FEATURE] [Indent Cost Type]
        // [SCENARIO] Indent Cost Type Action on Chart Of Cost Type is working successfully or not.

        // [GIVEN] Create four Cost Type of four different Type i.e; Heading,Begin-Total,Cost Type, End-Total.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingSetup();
        LibraryLowerPermissions.AddCostAccountingEdit();
        for i := 1 to 4 do
            LibraryCostAccounting.CreateCostType(CostType[i]);

        UpdateCostType(CostType[1], Type::Heading, '');
        UpdateCostType(CostType[2], Type::"Begin-Total", '');
        UpdateCostType(CostType[3], Type::"Cost Type", '');
        UpdateCostType(CostType[4], Type::"End-Total", '');

        LibraryLowerPermissions.SetCostAccountingEdit();
        // [WHEN] To open Chart of Cost Type Page and invoke Indent Cost Type Action.
        ChartOfCostTypePage.OpenEdit();
        ChartOfCostTypePage.IndentCostType.Invoke();

        // [THEN] To verify the indentation of created Cost Type after invoking Indent Cost Type Action.
        for i := 1 to 4 do
            VerifyIndentationOfChartofCostType(CostType[i]);

        // Tear Down.
        ChartOfCostTypePage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionFilteringInCostCenter()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
        Dimension: array[2] of Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        CostCenterCard: TestPage "Cost Center Card";
        DimValList: TestPage "Dimension Value List";
    begin
        // [FEATURE] [Cost Center]
        // [SCENARIO 280745] In the Cost Center Card page dimensions must be filtered according to Cost Accounting Setup.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingSetup();
        LibraryLowerPermissions.AddCostAccountingEdit();

        // [GIVEN] Dimension codes "X" and "Y" with values "X1" and "Y1"
        CreateDimensionsForFilteringTest(Dimension, DimensionValue);
        // [GIVEN] "Cost Center Dimension" is "X" in "Cost Accounting Setup"
        ModifyCostAccSetup(CostAccountingSetup.FieldNo("Cost Center Dimension"), Dimension[1].Code);
        // [GIVEN] Cost Center Card page is opened
        CreateOpenCostCenterCard(CostCenterCard);

        // [WHEN] Invoke "Dimension Values" action on "Cost Center Card" page
        DimValList.Trap();
        CostCenterCard.PageDimensionValues.Invoke();

        // [THEN] Only dimension value "X1" shown on "Dimension Values" page
        DimValList.Code.AssertEquals(DimensionValue[1].Code);
        Assert.IsFalse(DimValList.Next(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionFilteringInChartOfCostCenters()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
        Dimension: array[2] of Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        CostCenterChart: TestPage "Chart of Cost Centers";
        DimValList: TestPage "Dimension Value List";
    begin
        // [FEATURE] [Chart of Cost Centers]
        // [SCENARIO 280745] In the Chart of Cost Centers page dimensions must be filtered according to Cost Accounting Setup.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingSetup();
        LibraryLowerPermissions.AddCostAccountingEdit();

        // [GIVEN] Dimension codes "X" and "Y" with values "X1" and "Y1"
        CreateDimensionsForFilteringTest(Dimension, DimensionValue);
        // [GIVEN] "Cost Center Dimension" is "X" in "Cost Accounting Setup"
        ModifyCostAccSetup(CostAccountingSetup.FieldNo("Cost Center Dimension"), Dimension[1].Code);
        // [GIVEN] Chart of Cost Centers page is opened
        CreateOpenCostCenterChart(CostCenterChart);

        // [WHEN] Invoke "Dimension Values" action on "Chart of Cost Centers" page
        DimValList.Trap();
        CostCenterChart.PageDimensionValues.Invoke();

        // [THEN] Only dimension value "X1" shown on "Dimension Values" page
        DimValList.Code.AssertEquals(DimensionValue[1].Code);
        Assert.IsFalse(DimValList.Next(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionFilteringInCostObject()
    var
        Dimension: array[2] of Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        CostAccountingSetup: Record "Cost Accounting Setup";
        DimValList: TestPage "Dimension Value List";
        CostObjectCard: TestPage "Cost Object Card";
    begin
        // [FEATURE] [Cost Object]
        // [SCENARIO 280745] In the Cost Object Card page dimensions must be filtered according to Cost Accounting Setup.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingSetup();
        LibraryLowerPermissions.AddCostAccountingEdit();

        // [GIVEN] Dimension codes "X" and "Y" with values "X1" and "Y1"
        CreateDimensionsForFilteringTest(Dimension, DimensionValue);
        // [GIVEN] "Cost Object Dimension" is "X" in "Cost Accounting Setup"
        ModifyCostAccSetup(CostAccountingSetup.FieldNo("Cost Object Dimension"), Dimension[1].Code);
        // [GIVEN] Cost Object Card page is opened
        CreateOpenCostObjectCard(CostObjectCard);

        // [WHEN] Invoke "Dimension Values" action on "Cost Object Card" page
        DimValList.Trap();
        CostObjectCard.PageDimensionValues.Invoke();

        // [THEN] Only dimension value "X1" shown on "Dimension Values" page
        DimValList.Code.AssertEquals(DimensionValue[1].Code);
        Assert.IsFalse(DimValList.Next(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionFilteringInChartOfCostObjects()
    var
        Dimension: array[2] of Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        CostAccountingSetup: Record "Cost Accounting Setup";
        DimValList: TestPage "Dimension Value List";
        CostObjectChart: TestPage "Chart of Cost Objects";
    begin
        // [FEATURE] [Chart of Cost Objects]
        // [SCENARIO 280745] In the Chart of Cost Objects page dimensions must be filtered according to Cost Accounting Setup.
        Initialize();

        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddCostAccountingSetup();
        LibraryLowerPermissions.AddCostAccountingEdit();

        // [GIVEN] Dimension codes "X" and "Y" with values "X1" and "Y1"
        CreateDimensionsForFilteringTest(Dimension, DimensionValue);
        // [GIVEN] "Cost Object Dimension" is "X" in "Cost Accounting Setup"
        ModifyCostAccSetup(CostAccountingSetup.FieldNo("Cost Object Dimension"), Dimension[1].Code);
        // [GIVEN] Chart of Cost Objects page is opened
        CreateOpenCostObjectChart(CostObjectChart);

        // [WHEN] Invoke "Dimension Values" action on "Chart of Cost Objects" page
        DimValList.Trap();
        CostObjectChart.PageDimensionValues.Invoke();

        // [THEN] Only dimension value "X1" shown on "Dimension Values" page
        DimValList.Code.AssertEquals(DimensionValue[1].Code);
        Assert.IsFalse(DimValList.Next(), '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cost Accounting - Pages II");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cost Accounting - Pages II");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cost Accounting - Pages II");
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

    local procedure UpdateCostType(var CostType: Record "Cost Type"; Type: Option "Cost Type",Heading,Total,"Begin-Total","End-Total"; GLAccountNo2: Code[20])
    begin
        CostType.Validate(Type, Type);
        CostType.Validate("G/L Account Range", GLAccountNo2);
        CostType.Modify(true);
    end;

    [Normal]
    local procedure VerifyIndentationOfChartofCostType(ActualCostType: Record "Cost Type")
    var
        CostType: Record "Cost Type";
    begin
        CostType.SetFilter("No.", '%1', ActualCostType."No.");
        if CostType.FindFirst() then
            case ActualCostType.Type of
                ActualCostType.Type::"Cost Type":
                    Assert.AreEqual(CostType.Indentation, 1, IndentationError);
                ActualCostType.Type::Heading:
                    Assert.AreEqual(CostType.Indentation, 0, IndentationError);
                ActualCostType.Type::"Begin-Total":
                    Assert.AreEqual(CostType.Indentation, 0, IndentationError);
                ActualCostType.Type::"End-Total":
                    Assert.AreEqual(CostType.Indentation, 0, IndentationError);
            end;
    end;

    local procedure CreateDimensionsForFilteringTest(var Dimension: array[2] of Record Dimension; var DimensionValue: array[2] of Record "Dimension Value")
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(Dimension) do begin
            LibraryDimension.CreateDimension(Dimension[i]);
            LibraryDimension.CreateDimensionValue(DimensionValue[i], Dimension[i].Code);
        end;
    end;

    local procedure ModifyCostAccSetup(FieldNo: Integer; Value: Code[20])
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(DATABASE::"Cost Accounting Setup");
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Value := Value;
        RecRef.Modify(true);
    end;

    local procedure CreateOpenCostCenterCard(var CostCenterCard: TestPage "Cost Center Card")
    var
        CostCenter: Record "Cost Center";
    begin
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CostCenterCard.OpenEdit();
        CostCenterCard.GotoRecord(CostCenter);
    end;

    local procedure CreateOpenCostCenterChart(var CostCenterChart: TestPage "Chart of Cost Centers")
    var
        CostCenter: Record "Cost Center";
    begin
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        CostCenterChart.OpenEdit();
        CostCenterChart.GotoRecord(CostCenter);
    end;

    local procedure CreateOpenCostObjectCard(var CostObjectCard: TestPage "Cost Object Card")
    var
        CostObject: Record "Cost Object";
    begin
        LibraryCostAccounting.CreateCostObject(CostObject);
        CostObjectCard.OpenEdit();
        CostObjectCard.GotoRecord(CostObject);
    end;

    local procedure CreateOpenCostObjectChart(var CostObjectChart: TestPage "Chart of Cost Objects")
    var
        CostObject: Record "Cost Object";
    begin
        LibraryCostAccounting.CreateCostObject(CostObject);
        CostObjectChart.OpenEdit();
        CostObjectChart.GotoRecord(CostObject);
    end;
}

