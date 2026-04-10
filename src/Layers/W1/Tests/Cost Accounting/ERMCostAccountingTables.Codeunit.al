codeunit 134819 "ERM Cost Accounting - Tables"
{
    Permissions = TableData "G/L Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting] [Allocation]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        ExpectedValueIsDifferentError: Label 'Expected value of %1 field is different than the actual one.';
        CostAllocTargetCountError: Label 'The number of cost allocation targets is incorrect.';
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        GLAccFilter: Text;
        GLBudgetNameFilter: Text;
        CostBudgetNameFilter: Text;
        CostCenterFilter: Text;
        CostObjectFilter: Text;
        CostTypeFilter: Text;
        InvtPostingGroupFilter: Text;
        ItemFilter: Text;
        CostEntriesCountError: Label 'The number of cost entries is incorrect.';
        CostTypeNotDeleted: Label 'The Cost Type number %1 was not deleted.';
        CostRegisterEntriesNotClosed: Label 'The Cost Register entries were not closed.';
        EntriesWithinOpenFiscalYear: Label 'You cannot delete a cost type with entries in an open fiscal year.';
        IncorrectAddReportingCurrency: Label 'An incorrect value for the Additional Reporting Currency is retrieved.';
        UnexpectedErr: Label 'An unexpected error was thrown.';
        Text000: Label 'Field %1 on Table %2 is not %3 as expected.', Comment = '%1=fieldcaption Entry No.;%2=tablecaption Cost Budget Entry;%3=integer or decimal';
        Text001: Label 'A new record was not inserted in Table %1.', Comment = '%1=tablecaption Cost Budget Register';
        Text002: Label 'The Field %1 was not updated to %2.', Comment = '%1=fieldcaption Last Modified By User or fieldcaption Last Date Modified;%2=USERID or DATE';
        Text003: Label 'GetCostBudgetRegNo did not return the value set.';
        Text005: Label 'This function must be started with a budget name.', Comment = 'error message from CompressBudgetEntries in Table Cost Budget Entry';
        Text007: Label 'The compressed records in Table %1 were not deleted.', Comment = '%1=tablecaption Cost Budget Entry';
        Text008: Label 'The compressed entry does not have the correct sum.';
        Text009: Label 'The compressed %1 does not exist.', Comment = '%1=tablecaption Cost Budget Entry';
        Text010: Label 'The amount on the compressed %1 does not match the sum of the entries.', Comment = '%1=tablecaption Cost Budget Entry';
        Text011: Label 'The %1 to be compressed still exists.', Comment = '%1=tablecaption Cost Budget Entry';
        Text012: Label 'The %1 does not exist.', Comment = '%1=tablecaption Cost Budget Register';
        Text014: Label 'A closed register cannot be reactivated.';
        Text015: Label 'A %1 was not closed.', Comment = '%1=tablecaption Cost Budget Register';
        Text016: Label '%1 must be %2 or %3 in %4 %5.', Comment = '%1=fieldcaption Line Type;%2=tablecaption Cost Center;@3= fieldvalue Line Type;@4=fieldvalue Line Type;@5=Line Type';
        UnexpectedMessageError: Label 'The raised message is not the expected one. The actual message is: [%1], while the expected message is: [%2].';
        IncorrectLineTypeError: Label 'Line Type must not be %1 in %2 %3=''%4''.', Comment = '%1:Field Value;%2:Table Caption;%3:Field Caption;%4:Field Value;';
        CostEntryErr: Label 'There is no Cost Entry within the filter: "G/L Entry No." = ''%1''';
        TestFieldErr: Label '%1 must have a value', Comment = '%1:FieldCaption';
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cost Accounting - Tables");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cost Accounting - Tables");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cost Accounting - Tables");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocSourceCreateWhenLastAllocIDEmpty()
    var
        CostAccSetup: Record "Cost Accounting Setup";
        PrevLastAllocID: Code[10];
    begin
        // Setup:
        Initialize();
        CostAccSetup.Get();
        PrevLastAllocID := CostAccSetup."Last Allocation ID";
        CostAccSetup.Validate("Last Allocation ID", '');
        CostAccSetup.Modify(true);

        // Exercise & Verify:
        asserterror CreateAllocationSource(true);

        // Clean-up:
        CostAccSetup."Last Allocation ID" := PrevLastAllocID;
        CostAccSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocSourceCreateWithAutogeneratedID()
    var
        CostAccSetup: Record "Cost Accounting Setup";
        AllocationID: Code[10];
    begin
        // Setup & Exercise:
        Initialize();
        AllocationID := CreateAllocationSource(true);

        // Verify:
        CostAccSetup.Get();
        CostAccSetup.TestField("Last Allocation ID", AllocationID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocSourceCreateWithCustomID()
    var
        CostAccSetup: Record "Cost Accounting Setup";
        AllocationID: Code[10];
    begin
        // Setup & Exercise:
        Initialize();
        AllocationID := CreateAllocationSource(false);

        CostAccSetup.Get();
        Assert.AreNotEqual(
          CostAccSetup."Last Allocation ID", AllocationID,
          StrSubstNo(ExpectedValueIsDifferentError, CostAccSetup.FieldName("Last Allocation ID")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocSourceCreateWithCustomIDWhenLastAllocIDEmpty()
    var
        CostAccSetup: Record "Cost Accounting Setup";
        PrevLastAllocID: Code[10];
    begin
        // Setup:
        Initialize();
        CostAccSetup.Get();
        PrevLastAllocID := CostAccSetup."Last Allocation ID";
        CostAccSetup.Validate("Last Allocation ID", '');
        CostAccSetup.Modify(true);

        // Exercise:
        CreateAllocationSource(false);

        // Verify:
        CostAccSetup.Get();
        CostAccSetup.TestField("Last Allocation ID", '');

        // Clean-up:
        CostAccSetup."Last Allocation ID" := PrevLastAllocID;
        CostAccSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocSourceDelete()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        AllocationID: Code[10];
        I: Integer;
    begin
        // Setup:
        Initialize();
        AllocationID := CreateAllocationSource(true);
        for I := 1 to LibraryRandom.RandInt(10) do
            CreateAllocationTarget(CostAllocationTarget, AllocationID);

        // Exercise:
        CostAllocationSource.Get(AllocationID);
        CostAllocationSource.Delete(true);

        // Verify:
        CostAllocationTarget.SetFilter(ID, AllocationID);
        Assert.IsTrue(CostAllocationTarget.IsEmpty, CostAllocTargetCountError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocSourceUpdate()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        AllocationID: Code[10];
    begin
        // Setup:
        Initialize();
        AllocationID := CreateAllocationSource(true);

        // Exercise:
        CostAllocationSource.Get(AllocationID);
        CostAllocationSource.Validate("User ID", '');
        CostAllocationSource.Validate("Last Date Modified", 0D);
        CostAllocationSource.Modify(true);

        // Verify:
        CostAllocationSource.TestField("User ID", UpperCase(UserId));
        CostAllocationSource.TestField("Last Date Modified", Today);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocSourceValidateCostCenterField()
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        // Setup:
        Initialize();
        CostAllocationSource.Get(CreateAllocationSource(true));
        CostAllocationSource.Validate("Cost Object Code", CreateCostObject());
        CostAllocationSource.Modify(true);

        // Exercise & Verify:
        asserterror CostAllocationSource.Validate("Cost Center Code", CreateCostCenter());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocSourceValidateCostObjectField()
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        // Setup:
        Initialize();
        CostAllocationSource.Get(CreateAllocationSource(true));
        CostAllocationSource.Validate("Cost Center Code", CreateCostCenter());
        CostAllocationSource.Modify(true);

        // Exercise & Verify:
        asserterror CostAllocationSource.Validate("Cost Object Code", CreateCostObject());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetCalcPercentWhenTotalShareNonZero()
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        AllocationID: Code[10];
        I: Integer;
    begin
        // Setup:
        Initialize();
        AllocationID := CreateAllocationSource(true);
        for I := 1 to LibraryRandom.RandInt(10) do begin
            CreateAllocationTarget(CostAllocationTarget, AllocationID);
            // Exercise:
            CostAllocationTarget.Validate(Share, LibraryRandom.RandDec(100, 2));
            CostAllocationTarget.Modify();
        end;

        // Verify:
        CostAllocationSource.Get(AllocationID);
        LibraryCostAccounting.CheckAllocTargetSharePercent(CostAllocationSource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetCalcPercentWhenTotalShareZero()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
        AllocationID: Code[10];
        I: Integer;
    begin
        // Setup:
        Initialize();
        AllocationID := CreateAllocationSource(true);
        for I := 1 to LibraryRandom.RandInt(10) do
            CreateAllocationTarget(CostAllocationTarget, AllocationID);

        // Exercise:
        CostAllocationTarget.Validate(Share, 0);
        CostAllocationTarget.Modify();

        // Verify:
        CostAllocationTarget.Reset();
        CostAllocationTarget.SetRange(ID, AllocationID);
        CostAllocationTarget.FindSet();
        repeat
            CostAllocationTarget.TestField(Percent, 0);
            CostAllocationTarget.TestField("Share Updated on", Today);
        until CostAllocationTarget.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('RPHandlerChartOfCostCenters')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupCostCenterFilterField()
    var
        CostCenter: Record "Cost Center";
        CostAllocTargetListPage: TestPage "Cost Allocation Target List";
    begin
        // Setup:
        Initialize();
        CostCenter.FindFirst();
        CostCenterFilter := SelectionFilterManagement.AddQuotes(CostCenter.Code);
        CostAllocTargetListPage.OpenEdit();

        // Exercise:
        CostAllocTargetListPage."Cost Center Filter".Lookup();

        // Verify:
        CostAllocTargetListPage."Cost Center Filter".AssertEquals(CostCenterFilter);
    end;

    [Test]
    [HandlerFunctions('RPHandlerChartOfCostObjects')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupCostObjectFilterField()
    var
        CostObject: Record "Cost Object";
        CostAllocTargetListPage: TestPage "Cost Allocation Target List";
    begin
        // Setup:
        Initialize();
        CostObject.FindFirst();
        CostObjectFilter := SelectionFilterManagement.AddQuotes(CostObject.Code);
        CostAllocTargetListPage.OpenEdit();

        // Exercise:
        CostAllocTargetListPage."Cost Object Filter".Lookup();

        // Verify:
        CostAllocTargetListPage."Cost Object Filter".AssertEquals(CostObjectFilter);
    end;

    [Test]
    [HandlerFunctions('RPHandlerCostBudgetNames')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupGroupFilterFieldForCostBudgetEntryBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
        CostBudgetName: Record "Cost Budget Name";
    begin
        Initialize();
        CostBudgetName.FindFirst();
        CostBudgetNameFilter := SelectionFilterManagement.AddQuotes(CostBudgetName.Name);

        LookupGroupFilter(CostAllocTarget.Base::"Cost Budget Entries", CostBudgetNameFilter)
    end;

    [Test]
    [HandlerFunctions('RPHandlerGLBudgetNames')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupGroupFilterFieldForGLBudgetEntryBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
        GLBudgetName: Record "G/L Budget Name";
    begin
        Initialize();
        GLBudgetName.FindFirst();
        GLBudgetNameFilter := SelectionFilterManagement.AddQuotes(GLBudgetName.Name);

        LookupGroupFilter(CostAllocTarget.Base::"G/L Budget Entries", GLBudgetNameFilter)
    end;

    [Test]
    [HandlerFunctions('RPHandlerInvtPostingGroups')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupGroupFilterFieldForItemsPurchasedAmountBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
        InvtPostingGroup: Record "Inventory Posting Group";
    begin
        Initialize();
        InvtPostingGroup.FindFirst();
        InvtPostingGroupFilter := SelectionFilterManagement.AddQuotes(InvtPostingGroup.Code);

        LookupGroupFilter(CostAllocTarget.Base::"Items Purchased (Amount)", InvtPostingGroupFilter)
    end;

    [Test]
    [HandlerFunctions('RPHandlerInvtPostingGroups')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupGroupFilterFieldForItemsPurchasedQtyBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
        InvtPostingGroup: Record "Inventory Posting Group";
    begin
        Initialize();
        InvtPostingGroup.FindFirst();
        InvtPostingGroupFilter := SelectionFilterManagement.AddQuotes(InvtPostingGroup.Code);

        LookupGroupFilter(CostAllocTarget.Base::"Items Purchased (Qty.)", CopyStr(InvtPostingGroupFilter, 1, 30))
    end;

    [Test]
    [HandlerFunctions('RPHandlerInvtPostingGroups')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupGroupFilterFieldForItemsSoldAmountBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
        InvtPostingGroup: Record "Inventory Posting Group";
    begin
        Initialize();
        InvtPostingGroup.FindFirst();
        InvtPostingGroupFilter := SelectionFilterManagement.AddQuotes(InvtPostingGroup.Code);

        LookupGroupFilter(CostAllocTarget.Base::"Items Sold (Amount)", InvtPostingGroupFilter)
    end;

    [Test]
    [HandlerFunctions('RPHandlerInvtPostingGroups')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupGroupFilterFieldForItemsSoldQtyBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
        InvtPostingGroup: Record "Inventory Posting Group";
    begin
        Initialize();
        InvtPostingGroup.FindFirst();
        InvtPostingGroupFilter := SelectionFilterManagement.AddQuotes(InvtPostingGroup.Code);

        LookupGroupFilter(CostAllocTarget.Base::"Items Sold (Qty.)", CopyStr(InvtPostingGroupFilter, 1, 30))
    end;

    [Test]
    [HandlerFunctions('RPHandlerCostTypeList')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupNoFilterFieldForCostBudgetEntryBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
        CostType: Record "Cost Type";
    begin
        Initialize();
        CostType.FindFirst();
        CostTypeFilter := SelectionFilterManagement.AddQuotes(CostType."No.");

        LookupNoFilter(CostAllocTarget.Base::"Cost Budget Entries", CostTypeFilter)
    end;

    [Test]
    [HandlerFunctions('RPHandlerCostTypeList')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupNoFilterFieldForCostEntryBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
        CostType: Record "Cost Type";
    begin
        Initialize();
        CostType.FindFirst();
        CostTypeFilter := SelectionFilterManagement.AddQuotes(CostType."No.");

        LookupNoFilter(CostAllocTarget.Base::"Cost Type Entries", CostTypeFilter)
    end;

    [Test]
    [HandlerFunctions('RPHandlerGLAccList')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupNoFilterFieldForGLBudgetEntryBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
        GLAccount: Record "G/L Account";
    begin
        Initialize();
        // Setup:
        GLAccount.FindFirst();
        GLAccFilter := SelectionFilterManagement.AddQuotes(GLAccount."No.");

        // Exercise & Verify:
        LookupNoFilter(CostAllocTarget.Base::"G/L Budget Entries", GLAccFilter)
    end;

    [Test]
    [HandlerFunctions('RPHandlerGLAccList')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupNoFilterFieldForGLEntryBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
        GLAccount: Record "G/L Account";
    begin
        // Setup:
        Initialize();
        GLAccount.FindFirst();
        GLAccFilter := SelectionFilterManagement.AddQuotes(GLAccount."No.");

        // Exercise & Verify:
        LookupNoFilter(CostAllocTarget.Base::"G/L Entries", GLAccFilter)
    end;

    [Test]
    [HandlerFunctions('RPHandlerItemList')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupNoFilterFieldForItemsPurchasedAmountBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
    begin
        Initialize();
        ItemFilter := SelectionFilterManagement.AddQuotes(LibraryInventory.CreateItemNo());

        LookupNoFilter(CostAllocTarget.Base::"Items Purchased (Amount)", ItemFilter)
    end;

    [Test]
    [HandlerFunctions('RPHandlerItemList')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupNoFilterFieldForItemsPurchasedQtyBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
    begin
        Initialize();
        ItemFilter := SelectionFilterManagement.AddQuotes(LibraryInventory.CreateItemNo());

        LookupNoFilter(CostAllocTarget.Base::"Items Purchased (Qty.)", CopyStr(ItemFilter, 1, 30))
    end;

    [Test]
    [HandlerFunctions('RPHandlerItemList')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupNoFilterFieldForItemsSoldAmountBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
    begin
        Initialize();
        ItemFilter := SelectionFilterManagement.AddQuotes(LibraryInventory.CreateItemNo());

        LookupNoFilter(CostAllocTarget.Base::"Items Sold (Amount)", ItemFilter)
    end;

    [Test]
    [HandlerFunctions('RPHandlerItemList')]
    [Scope('OnPrem')]
    procedure AllocTargetLookupNoFilterFieldForItemsSoldQtyBase()
    var
        CostAllocTarget: Record "Cost Allocation Target";
    begin
        Initialize();
        ItemFilter := SelectionFilterManagement.AddQuotes(LibraryInventory.CreateItemNo());

        LookupNoFilter(CostAllocTarget.Base::"Items Sold (Qty.)", CopyStr(ItemFilter, 1, 30))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetUpdate()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup:
        Initialize();
        CreateAllocationTarget(CostAllocationTarget, CreateAllocationSource(true));

        // Exercise:
        CostAllocationTarget."Last Date Modified" := 0D;
        CostAllocationTarget."User ID" := '';
        CostAllocationTarget.Modify(true);

        // Verify:
        CostAllocationTarget.TestField("Last Date Modified", Today);
        CostAllocationTarget.TestField("User ID", UserId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetValidateAmountPerShareNonZero()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup & Exercise:
        Initialize();
        CostAllocationTarget."Percent per Share" := LibraryRandom.RandInt(10);
        CostAllocationTarget.Validate("Amount per Share", LibraryRandom.RandInt(10));
        CostAllocationTarget.Insert();

        // Verify:
        CostAllocationTarget.TestField("Allocation Target Type", CostAllocationTarget."Allocation Target Type"::"Amount per Share");
        CostAllocationTarget.TestField("Percent per Share", 0);

        // Clean-up:
        CostAllocationTarget.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetValidateAmountPerShareZero()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup & Exercise:
        Initialize();
        CostAllocationTarget."Amount per Share" := LibraryRandom.RandInt(10);
        CostAllocationTarget.Validate("Amount per Share", 0);
        CostAllocationTarget.Insert();

        // Verify:
        CostAllocationTarget.TestField("Allocation Target Type", CostAllocationTarget."Allocation Target Type"::"All Costs");

        // Clean-up:
        CostAllocationTarget.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetValidateCostCenterField()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup:
        Initialize();
        CreateAllocationTarget(CostAllocationTarget, CreateAllocationSource(true));
        CostAllocationTarget.Validate("Target Cost Object", CreateCostObject());
        CostAllocationTarget.Modify(true);

        // Exercise & Verify:
        asserterror CostAllocationTarget.Validate("Target Cost Center", CreateCostCenter());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetValidateCostObjectField()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup:
        Initialize();
        CreateAllocationTarget(CostAllocationTarget, CreateAllocationSource(true));
        CostAllocationTarget.Validate("Target Cost Center", CreateCostCenter());
        CostAllocationTarget.Modify(true);

        // Exercise & Verify:
        asserterror CostAllocationTarget.Validate("Target Cost Object", CreateCostObject());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetValidatePercentPerShareNonZero()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup & Exercise:
        Initialize();
        CostAllocationTarget.Validate("Percent per Share", LibraryRandom.RandInt(10));
        CostAllocationTarget.Insert();

        // Verify:
        CostAllocationTarget.TestField("Allocation Target Type", CostAllocationTarget."Allocation Target Type"::"Percent per Share");
        CostAllocationTarget.TestField("Amount per Share", 0);

        // Clean-up:
        CostAllocationTarget.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetValidatePercentPerShareZero()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup & Exercise:
        Initialize();
        CostAllocationTarget.Validate("Percent per Share", 0);
        CostAllocationTarget.Insert();

        // Verify:
        CostAllocationTarget.TestField("Allocation Target Type", CostAllocationTarget."Allocation Target Type"::"All Costs");

        // Clean-up:
        CostAllocationTarget.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetValidateStaticBaseGreaterThanZeroForDynamicBase()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup:
        Initialize();
        CostAllocationTarget.Base := CostAllocationTarget.Base::"G/L Entries";
        CostAllocationTarget.Insert();

        // Exercise & Verify:
        asserterror CostAllocationTarget.Validate("Static Base", LibraryRandom.RandInt(10));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetValidateStaticBaseZeroForDynamicBase()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup:
        Initialize();
        CostAllocationTarget.Base := CostAllocationTarget.Base::"G/L Entries";
        CostAllocationTarget.Insert();

        // Exercise & Verify:
        CostAllocationTarget.Validate("Static Base", 0);

        // Clean-up:
        CostAllocationTarget.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetValidateStaticWeightingGreaterThanZeroForDynamicBase()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup:
        Initialize();
        CostAllocationTarget.Base := CostAllocationTarget.Base::"G/L Entries";
        CostAllocationTarget.Insert();

        // Exercise & Verify:
        asserterror CostAllocationTarget.Validate("Static Weighting", LibraryRandom.RandInt(10));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetValidateStaticWeightingZeroForDynamicBase()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup:
        Initialize();
        CostAllocationTarget.Base := CostAllocationTarget.Base::"G/L Entries";
        CostAllocationTarget.Insert();

        // Exercise & Verify:
        CostAllocationTarget.Validate("Static Weighting", 0);

        // Clean-up:
        CostAllocationTarget.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocTargetValidateStaticWeighttingForStaticBase()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        // Setup:
        Initialize();
        CostAllocationTarget.Base := CostAllocationTarget.Base::Static;
        CostAllocationTarget.Insert();

        // Exercise:
        CostAllocationTarget.Validate("Static Weighting", LibraryRandom.RandInt(100));
        CostAllocationTarget.Modify();

        // Verify:
        CostAllocationTarget.TestField(Share, CostAllocationTarget."Static Base" * CostAllocationTarget."Static Weighting");

        // Clean-up:
        CostAllocationTarget.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,MessageHandler')]
    [Scope('OnPrem')]
    procedure CostAccSetupValidateAutotransferFromGLConfirmNo()
    var
        CostEntry: Record "Cost Entry";
        GLEntryNo: Integer;
    begin
        // Setup:
        Initialize();
        GLEntryNo := CreateGLEntryWithCostCenterDim();

        // Exercise:
        asserterror UpdateCostAccSetupAutoTransferFromGL(true);

        // Verify:
        CostEntry.SetRange("G/L Entry No.", GLEntryNo);
        Assert.IsTrue(CostEntry.IsEmpty, CostEntriesCountError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CostAccSetupValidateAutotransferFromGLConfirmYes()
    var
        CostEntry: Record "Cost Entry";
        GLEntryNo: Integer;
    begin
        // Setup:
        Initialize();
        GLEntryNo := CreateGLEntryWithCostCenterDim();

        // Exercise:
        UpdateCostAccSetupAutoTransferFromGL(true);

        // Verify:
        CostEntry.SetRange("G/L Entry No.", GLEntryNo);
        Assert.AreEqual(1, CostEntry.Count, CostEntriesCountError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CostAccSetupValidateStartingDateAfterFirstGLTransfer()
    var
        CostAccSetup: Record "Cost Accounting Setup";
        TransferGLEntriesToCA: Codeunit "Transfer GL Entries to CA";
    begin
        // Setup:
        Initialize();
        CreateGLEntryWithCostCenterDim();
        TransferGLEntriesToCA.TransferGLtoCA();

        // Exercise & Verify:
        CostAccSetup.Get();
        asserterror CostAccSetup.Validate("Starting Date for G/L Transfer", WorkDate());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CostAccSetupValidateStartingDateConfirmYes()
    var
        CostRegister: Record "Cost Register";
        CostAccSetup: Record "Cost Accounting Setup";
        PrevStartingDate: Date;
        NewStartingDate: Date;
    begin
        // Setup: delete existing cost register corresponding to prev transfers
        Initialize();
        CostRegister.SetRange(Source, CostRegister.Source::"Transfer from G/L");
        CostRegister.DeleteAll();

        CostAccSetup.Get();
        PrevStartingDate := CostAccSetup."Starting Date for G/L Transfer";
        NewStartingDate := CalcDate('<+1D>', WorkDate());

        // Exercise:
        UpdateCostAccSetupStartingDateForGLTransfer(NewStartingDate);

        // Verify:
        CostAccSetup.Get();
        CostAccSetup.TestField("Starting Date for G/L Transfer", NewStartingDate);

        // Clean-up:
        CostAccSetup."Starting Date for G/L Transfer" := PrevStartingDate;
        CostAccSetup.Modify();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CostAccSetupValidateStartingDateConfirmNo()
    var
        CostRegister: Record "Cost Register";
        CostAccSetup: Record "Cost Accounting Setup";
        PrevStartingDate: Date;
        NewStartingDate: Date;
    begin
        // Setup: delete existing cost register corresponding to prev transfers
        Initialize();
        CostRegister.SetRange(Source, CostRegister.Source::"Transfer from G/L");
        CostRegister.DeleteAll();

        CostAccSetup.Get();
        PrevStartingDate := CostAccSetup."Starting Date for G/L Transfer";
        NewStartingDate := CalcDate('<+1D>', WorkDate());

        // Exercise:
        asserterror UpdateCostAccSetupStartingDateForGLTransfer(NewStartingDate);

        // Verify:
        CostAccSetup.Get();
        CostAccSetup.TestField("Starting Date for G/L Transfer", PrevStartingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostEntryGetCurrencyCode()
    var
        CostEntry: Record "Cost Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Initialize();
        GeneralLedgerSetup.Get();
        Assert.AreEqual(GeneralLedgerSetup."Additional Reporting Currency", CostEntry.GetCurrencyCode(), IncorrectAddReportingCurrency);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CostRegisterClosedMutlipleEntriesClosed()
    var
        CostRegister: Record "Cost Register";
        Index: Integer;
    begin
        // Setup
        Initialize();
        CostRegister.DeleteAll();

        // Exercise
        for Index := 1 to 2 do begin
            CreateCostRegister(CostRegister, Index);
            UpdateCostRegisterClosed(CostRegister, true);
        end;

        // Verify
        Clear(CostRegister);
        CostRegister.SetFilter(Closed, '%1', false);
        Assert.IsTrue(CostRegister.IsEmpty, CostRegisterEntriesNotClosed);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CostRegisterClosedMutlipleEntriesNotClosed()
    var
        CostRegister: Record "Cost Register";
        Index: Integer;
    begin
        // Setup
        Initialize();
        CostRegister.DeleteAll();

        for Index := 1 to 2 do
            CreateCostRegister(CostRegister, Index);

        // Exercise
        CostRegister.FindLast();
        UpdateCostRegisterClosed(CostRegister, true);

        // Verify
        CostRegister.FindFirst();
        repeat
            CostRegister.TestField(Closed, true);
        until CostRegister.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CostRegisterClosedSingleEntry()
    var
        CostRegister: Record "Cost Register";
    begin
        // Setup
        Initialize();
        CostRegister.DeleteAll();
        CreateCostRegister(CostRegister, 1);

        // Exercise
        UpdateCostRegisterClosed(CostRegister, true);

        // Verify
        CostRegister.Get(1);
        CostRegister.TestField(Closed, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostTypeDeleteBalanceNonZero()
    var
        CostEntry: Record "Cost Entry";
        CostType: Record "Cost Type";
        CostTypeNo: Code[20];
    begin
        // Setup
        Initialize();
        CostTypeInsert(CostTypeNo, false);
        CostEntryInsert(CostEntry, CostTypeNo, LibraryRandom.RandInt(1000));

        // Exercise
        CostType.Get(CostTypeNo);
        asserterror CostType.Delete(true);

        // Verify
        Assert.ExpectedTestFieldError(CostType.FieldCaption(Balance), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostTypeDeleteBalanceZero()
    var
        CostEntry: Record "Cost Entry";
        CostType: Record "Cost Type";
        CostTypeNo: Code[20];
    begin
        // Setup
        Initialize();
        CostTypeInsert(CostTypeNo, false);
        CostEntryInsert(CostEntry, CostTypeNo, 0);

        // Exercise
        CostType.Get(CostTypeNo);
        CostType.Delete(true);

        // Verify
        asserterror CostType.Get(CostTypeNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostTypeDeleteCostEntryPostingDateAfter()
    var
        CostEntry: Record "Cost Entry";
        CostType: Record "Cost Type";
        CostTypeNo: Code[20];
    begin
        // Setup
        Initialize();
        CostTypeInsert(CostTypeNo, false);
        CostEntryInsert(CostEntry, CostTypeNo, 0);
        CostEntry.Validate("Posting Date", CalcDate('<+1D>', LibraryFiscalYear.IdentifyOpenAccountingPeriod()));
        CostEntry.Modify(true);

        // Exercise
        CostType.Get(CostTypeNo);
        asserterror CostType.Delete(true);

        // Verify
        Assert.IsTrue(StrPos(GetLastErrorText, EntriesWithinOpenFiscalYear) > 0, UnexpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostTypeDeleteCostEntryPostingDateBefore()
    var
        CostEntry: Record "Cost Entry";
        CostType: Record "Cost Type";
        CostTypeNo: Code[20];
    begin
        // Setup
        Initialize();
        CostTypeInsert(CostTypeNo, false);
        CostEntryInsert(CostEntry, CostTypeNo, 0);
        CostEntry.Validate("Posting Date", CalcDate('<-1D>', LibraryFiscalYear.IdentifyOpenAccountingPeriod()));
        CostEntry.Modify(true);

        // Exercise
        CostType.Get(CostTypeNo);
        CostType.Delete(true);

        // Verify
        if CostType.Get(CostTypeNo) then
            Error(CostTypeNotDeleted, CostTypeNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostTypeDeleteHeadingType()
    var
        CostType: Record "Cost Type";
        CostTypeNo: Code[20];
    begin
        // Setup
        Initialize();
        CostTypeInsert(CostTypeNo, false);
        CostType.Get(CostTypeNo);
        CostType.Validate(Type, CostType.Type::Heading);
        CostType.Modify();

        // Exercise
        CostType.Delete(true);

        // Verify
        asserterror CostType.Get(CostTypeNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostTypeDeleteNoOpenAccountingPeriods()
    var
        CostEntry: Record "Cost Entry";
        CostType: Record "Cost Type";
        CostTypeNo: Code[20];
    begin
        // Setup
        Initialize();
        LibraryFiscalYear.CloseAccountingPeriod();
        CostTypeInsert(CostTypeNo, false);
        CostEntryInsert(CostEntry, CostTypeNo, 0);

        // Exercise
        CostType.Get(CostTypeNo);
        asserterror CostType.Delete(true);

        // Verify
        Assert.IsTrue(StrPos(GetLastErrorText, EntriesWithinOpenFiscalYear) > 0, UnexpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostTypeInsertNoValidation()
    begin
        Initialize();
        ValidateCostTypeInsert(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostTypeInsertWithValidation()
    begin
        Initialize();
        ValidateCostTypeInsert(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostTypeModifyNoValidation()
    begin
        Initialize();
        ValidateCostTypeModify(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostTypeModifyWithValidation()
    begin
        Initialize();
        ValidateCostTypeModify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCheckEntriesCostCenterAndCostObject()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        Initialize();
        CreateCostBudgetEntry(CostBudgetEntry, 0,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Budget Name"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Budget Name")),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Type No."), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Type No.")), WorkDate(),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Center Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Center Code")),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Object Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Object Code")), 0, false);
        asserterror
          CostBudgetEntry.CheckEntries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCheckEntriesMissingBudgetName()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        Initialize();
        CreateCostBudgetEntry(CostBudgetEntry, 0, '',
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Type No."), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Type No.")), WorkDate(),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Center Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Center Code")), '', 0, false);
        asserterror
          CostBudgetEntry.CheckEntries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCheckEntriesMissingCostCenterAndCostObject()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        Initialize();
        CreateCostBudgetEntry(
          CostBudgetEntry, 0,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Budget Name"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Budget Name")),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Type No."), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Type No.")), WorkDate(),
          '', '', 0, false);
        asserterror
          CostBudgetEntry.CheckEntries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCheckEntriesMissingCostTypeNo()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        Initialize();
        CreateCostBudgetEntry(
          CostBudgetEntry, 0,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Budget Name"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Budget Name")),
          '', WorkDate(),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Center Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Center Code")), '', 0, false);
        asserterror
          CostBudgetEntry.CheckEntries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCheckEntriesMissingDate()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        Initialize();
        CreateCostBudgetEntry(
          CostBudgetEntry, 0,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Budget Name"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Budget Name")),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Type No."), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Type No.")), 0D,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Center Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Center Code")), '', 0, false);
        asserterror
          CostBudgetEntry.CheckEntries();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCheckEntriesOKCostCenter()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        Initialize();
        CreateCostBudgetEntry(CostBudgetEntry, 0,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Budget Name"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Budget Name")),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Type No."), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Type No.")), WorkDate(),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Center Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Center Code")), '', 0, false);
        asserterror
        begin
            CostBudgetEntry.CheckEntries();
            Error('')
        end;
        Assert.AreEqual('', GetLastErrorText, UnexpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCheckEntriesOKCostObject()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        Initialize();
        CreateCostBudgetEntry(CostBudgetEntry, 0,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Budget Name"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Budget Name")),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Type No."), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Type No.")), WorkDate(),
          '',
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Object Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Object Code")), 0, false);
        asserterror
        begin
            CostBudgetEntry.CheckEntries();
            Error('')
        end;
        Assert.AreEqual('', GetLastErrorText, UnexpectedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCompressBudgetEntries()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        FromEntryNo: Integer;
        ToEntryNo: Integer;
        TotalAmount: Decimal;
        j: Integer;
    begin
        Initialize();
        // create budget entries
        InsertCostBudgetEntriesToCompress(CostBudgetEntry, FromEntryNo, ToEntryNo, true, TotalAmount);
        // compress budget entries
        CostBudgetEntry.CompressBudgetEntries(CostBudgetEntry."Budget Name");
        // verify entries were deleted
        for j := (FromEntryNo + 1) to ToEntryNo do
            if CostBudgetEntry.Get(j) then
                Error(Text007, CostBudgetEntry.TableCaption());
        // verify the sum matches expected.
        CostBudgetEntry.Get(FromEntryNo);
        Assert.AreEqual(TotalAmount, CostBudgetEntry.Amount, Text008);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCompressBudgetEntriesAmountZeroOneGroup()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        FromEntryNo: Integer;
        ToEntryNo: Integer;
        TotalAmount: Decimal;
        j: Integer;
    begin
        Initialize();
        // create budget entries
        InsertCostBudgetEntriesToCompress(CostBudgetEntry, FromEntryNo, ToEntryNo, false, TotalAmount);
        // compress budget entries
        CostBudgetEntry.CompressBudgetEntries(CostBudgetEntry."Budget Name");
        // verify entries were deleted
        for j := (FromEntryNo + 1) to ToEntryNo do
            if CostBudgetEntry.Get(j) then
                Error(Text007, CostBudgetEntry.TableCaption());
        // verify the sum matches expected.
        CostBudgetEntry.Get(FromEntryNo);
        Assert.AreEqual(TotalAmount, CostBudgetEntry.Amount, Text008);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCompressBudgetEntriesAmountZeroTwoGroups()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        BudgetName: Code[10];
        FromEntryNo: Integer;
        FirstEntryNo: Integer;
        ToEntryNo: Integer;
        TotalAmount: Decimal;
        i: Integer;
    begin
        Initialize();
        InsertCostBudgetEntriesToCompress(CostBudgetEntry, FromEntryNo, ToEntryNo, false, TotalAmount);
        BudgetName := CostBudgetEntry."Budget Name";
        FirstEntryNo := CostBudgetEntry."Entry No.";
        InsertCostBudgetEntriesToCompress(CostBudgetEntry, FromEntryNo, ToEntryNo, false, TotalAmount);
        CostBudgetEntry.SetRange("Entry No.", FromEntryNo, ToEntryNo);
        CostBudgetEntry.ModifyAll("Budget Name", BudgetName);

        CostBudgetEntry.CompressBudgetEntries(BudgetName);

        for i := FirstEntryNo to ToEntryNo do
            if i <> FromEntryNo then
                if CostBudgetEntry.Get(i) then
                    Error(Text007, CostBudgetEntry.TableCaption());
        // verify the sum matches expected.
        CostBudgetEntry.Get(FromEntryNo);
        Assert.AreEqual(TotalAmount, CostBudgetEntry.Amount, Text008);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCompressBudgetEntriesConfirmNo()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        Initialize();
        asserterror CostBudgetEntry.CompressBudgetEntries(
            CopyStr(
              LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Budget Name"), DATABASE::"Cost Budget Entry"), 1,
              MaxStrLen(CostBudgetEntry."Budget Name")));
        Assert.AreEqual('', GetLastErrorText, UnexpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCompressBudgetEntriesMissingBudgetName()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        Initialize();
        asserterror CostBudgetEntry.CompressBudgetEntries('');
        Assert.IsTrue(Text005 = GetLastErrorText, UnexpectedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCompressBudgetEntriesWithDiffCostCenter()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        EntryNos: array[2] of Integer;
        Amounts: array[2] of Integer;
        i: Integer;
    begin
        Initialize();
        CreateRandomCostBudgetEntryWithCostCenter(CostBudgetEntry, false);
        EntryNos[1] := CostBudgetEntry."Entry No.";
        Amounts[1] := CostBudgetEntry.Amount;
        CreateCostBudgetEntryCopy(CostBudgetEntry);
        Amounts[1] += CostBudgetEntry.Amount;
        CreateCostBudgetEntry(CostBudgetEntry, 0, CostBudgetEntry."Budget Name", CostBudgetEntry."Cost Type No.",
          CostBudgetEntry.Date,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Center Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Center Code")),
          CostBudgetEntry."Cost Object Code", 0, false);
        EntryNos[2] := CostBudgetEntry."Entry No.";
        Amounts[2] := CostBudgetEntry.Amount;
        CreateCostBudgetEntryCopy(CostBudgetEntry);
        Amounts[1] += CostBudgetEntry.Amount;

        CostBudgetEntry.CompressBudgetEntries(CostBudgetEntry."Budget Name");
        for i := 1 to ArrayLen(EntryNos) do begin
            Assert.IsTrue(CostBudgetEntry.Get(EntryNos[i]), StrSubstNo(Text009, CostBudgetEntry.TableCaption()));
            Assert.AreEqual(Amounts[i], CostBudgetEntry.Amount, StrSubstNo(Text010, CostBudgetEntry.TableCaption()));
            Assert.IsFalse(CostBudgetEntry.Get(EntryNos[i] + 1), StrSubstNo(Text011, CostBudgetEntry.TableCaption()));
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCompressBudgetEntriesWithDiffCostObject()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        EntryNos: array[2] of Integer;
        Amounts: array[2] of Integer;
        i: Integer;
    begin
        Initialize();
        CreateRandomCostBudgetEntryWithCostObject(CostBudgetEntry, false);
        EntryNos[1] := CostBudgetEntry."Entry No.";
        Amounts[1] := CostBudgetEntry.Amount;
        CreateCostBudgetEntryCopy(CostBudgetEntry);
        Amounts[1] += CostBudgetEntry.Amount;
        CreateCostBudgetEntry(CostBudgetEntry, 0, CostBudgetEntry."Budget Name", CostBudgetEntry."Cost Type No.",
          CostBudgetEntry.Date, CostBudgetEntry."Cost Center Code",
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Object Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Object Code")), 0, false);
        EntryNos[2] := CostBudgetEntry."Entry No.";
        Amounts[2] := CostBudgetEntry.Amount;
        CreateCostBudgetEntryCopy(CostBudgetEntry);
        Amounts[1] += CostBudgetEntry.Amount;

        CostBudgetEntry.CompressBudgetEntries(CostBudgetEntry."Budget Name");
        for i := 1 to ArrayLen(EntryNos) do begin
            Assert.IsTrue(CostBudgetEntry.Get(EntryNos[i]), StrSubstNo(Text009, CostBudgetEntry.TableCaption()));
            Assert.AreEqual(Amounts[i], CostBudgetEntry.Amount, StrSubstNo(Text010, CostBudgetEntry.TableCaption()));
            Assert.IsFalse(CostBudgetEntry.Get(EntryNos[i] + 1), StrSubstNo(Text011, CostBudgetEntry.TableCaption()));
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCompressBudgetEntriesWithDiffCostType()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        EntryNos: array[2] of Integer;
        Amounts: array[2] of Integer;
        i: Integer;
    begin
        Initialize();
        CreateRandomCostBudgetEntryWithCostCenter(CostBudgetEntry, false);
        EntryNos[1] := CostBudgetEntry."Entry No.";
        Amounts[1] := CostBudgetEntry.Amount;
        CreateCostBudgetEntryCopy(CostBudgetEntry);
        Amounts[1] += CostBudgetEntry.Amount;
        CreateCostBudgetEntry(
          CostBudgetEntry, 0, CostBudgetEntry."Budget Name",
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Type No."), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Type No.")),
          CostBudgetEntry.Date, CostBudgetEntry."Cost Center Code", CostBudgetEntry."Cost Object Code", 0, false);
        EntryNos[2] := CostBudgetEntry."Entry No.";
        Amounts[2] := CostBudgetEntry.Amount;
        CreateCostBudgetEntryCopy(CostBudgetEntry);
        Amounts[1] += CostBudgetEntry.Amount;

        CostBudgetEntry.CompressBudgetEntries(CostBudgetEntry."Budget Name");
        for i := 1 to ArrayLen(EntryNos) do begin
            Assert.IsTrue(CostBudgetEntry.Get(EntryNos[i]), StrSubstNo(Text009, CostBudgetEntry.TableCaption()));
            Assert.AreEqual(Amounts[i], CostBudgetEntry.Amount, 'The amount on the compressed entry does not match the sum of the entries');
            Assert.IsFalse(CostBudgetEntry.Get(EntryNos[i] + 1), 'The entry to be compressed still exists');
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryCompressBudgetEntriesWithDiffDate()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        EntryNos: array[2] of Integer;
        Amounts: array[2] of Integer;
        i: Integer;
    begin
        Initialize();
        CreateRandomCostBudgetEntryWithCostCenter(CostBudgetEntry, false);
        EntryNos[1] := CostBudgetEntry."Entry No.";
        Amounts[1] := CostBudgetEntry.Amount;
        CreateCostBudgetEntryCopy(CostBudgetEntry);
        Amounts[1] += CostBudgetEntry.Amount;
        CreateCostBudgetEntry(CostBudgetEntry, 0, CostBudgetEntry."Budget Name", CostBudgetEntry."Cost Type No.",
          CalcDate('<+1M>', CostBudgetEntry.Date), CostBudgetEntry."Cost Center Code", CostBudgetEntry."Cost Object Code", 0, false);
        EntryNos[2] := CostBudgetEntry."Entry No.";
        Amounts[2] := CostBudgetEntry.Amount;
        CreateCostBudgetEntryCopy(CostBudgetEntry);
        Amounts[1] += CostBudgetEntry.Amount;

        CostBudgetEntry.CompressBudgetEntries(CostBudgetEntry."Budget Name");
        for i := 1 to ArrayLen(EntryNos) do begin
            Assert.IsTrue(CostBudgetEntry.Get(EntryNos[i]), StrSubstNo(Text009, CostBudgetEntry.TableCaption()));
            Assert.AreEqual(Amounts[i], CostBudgetEntry.Amount, StrSubstNo(Text010, CostBudgetEntry.TableCaption()));
            Assert.IsFalse(CostBudgetEntry.Get(EntryNos[i] + 1), StrSubstNo(Text011, CostBudgetEntry.TableCaption()));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryGetFirstCostCenter()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostCenter: Record "Cost Center";
        CostCenter2: Record "Cost Center";
    begin
        Initialize();
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostCenter(CostCenter2);
        CostCenter.TestField(Code, CostBudgetEntry.GetFirstCostCenter(CostCenter.Code + '|' + CostCenter2.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryGetFirstCostCenterInvalidFilter()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostCenter: Record "Cost Center";
    begin
        Initialize();
        Assert.AreEqual(
          '', CostBudgetEntry.GetFirstCostCenter(LibraryUtility.GenerateRandomCode(CostCenter.FieldNo(Code), DATABASE::"Cost Center")),
          StrSubstNo(ExpectedValueIsDifferentError, CostCenter.FieldName(Code)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryGetFirstCostObject()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostObject: Record "Cost Object";
        CostObject2: Record "Cost Object";
    begin
        Initialize();
        LibraryCostAccounting.CreateCostObject(CostObject);
        LibraryCostAccounting.CreateCostObject(CostObject2);
        CostObject.TestField(Code, CostBudgetEntry.GetFirstCostObject(CostObject.Code + '|' + CostObject2.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryGetFirstCostObjectInvalidFilter()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostObject: Record "Cost Object";
    begin
        Initialize();
        Assert.AreEqual(
          '', CostBudgetEntry.GetFirstCostObject(LibraryUtility.GenerateRandomCode(CostObject.FieldNo(Code), DATABASE::"Cost Object")),
          StrSubstNo(ExpectedValueIsDifferentError, CostObject.FieldName(Code)));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryGetFirstCostType()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostType: Record "Cost Type";
        CostType2: Record "Cost Type";
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        Initialize();
        LibraryCostAccounting.CreateCostType(CostType);
        LibraryCostAccounting.CreateCostType(CostType2);
        CostType.TestField("No.", CostBudgetEntry.GetFirstCostType(CostType."No." + '|' + CostType2."No."));

        // Tear Down: Reset the value of Align G/L Account in Cost Accounting Setup.
        LibraryCostAccounting.SetAlignment(
          CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account"::"No Alignment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryGetFirstCostTypeInvalidFilter()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostType: Record "Cost Type";
    begin
        Initialize();
        Assert.AreEqual(
          '', CostBudgetEntry.GetFirstCostType(LibraryUtility.GenerateRandomCode(CostType.FieldNo("No."), DATABASE::"Cost Type")),
          StrSubstNo(ExpectedValueIsDifferentError, CostType.FieldName("No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryGetFirstDateHiddenDate()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetName: Record "Cost Budget Name";
        RandomDate: Date;
        RandomDate2: Date;
        RandomDate3: Date;
        DateFormulaMonth: DateFormula;
    begin
        Initialize();
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName.Name);

        Evaluate(DateFormulaMonth, '<1M>');
        RandomDate := LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate(DateFormulaMonth, WorkDate()));
        RandomDate2 := LibraryUtility.GenerateRandomDate(RandomDate, CalcDate(DateFormulaMonth, RandomDate));
        RandomDate3 := LibraryUtility.GenerateRandomDate(RandomDate2, CalcDate(DateFormulaMonth, RandomDate2));
        CostBudgetEntry.FilterGroup := 26;
        CostBudgetEntry.SetFilter(Date, '..' + Format(RandomDate) + '|' + Format(RandomDate2) + '..');
        Assert.AreEqual(
          RandomDate, CostBudgetEntry.GetFirstDate(Format(RandomDate3)),
          StrSubstNo(ExpectedValueIsDifferentError, CostBudgetEntry.FieldName(Date)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryGetFirstDatePeriodDate()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetName: Record "Cost Budget Name";
        RandomDate: Date;
        DateFormulaYear: DateFormula;
    begin
        Initialize();
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName.Name);
        Evaluate(DateFormulaYear, '<1Y>');
        RandomDate := LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate(DateFormulaYear, WorkDate()));
        Assert.AreEqual(
          RandomDate, CostBudgetEntry.GetFirstDate(Format(RandomDate)),
          StrSubstNo(ExpectedValueIsDifferentError, CostBudgetEntry.FieldName(Date)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryGetFirstDateWorkDate()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        Initialize();
        Assert.AreEqual(
          WorkDate(), CostBudgetEntry.GetFirstDate(''), StrSubstNo(ExpectedValueIsDifferentError, CostBudgetEntry.FieldName(Date)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryHandleCostBudgetRegisterInsert()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        Initialize();
        CostBudgetEntry.SetCostBudgetRegNo(0);
        CreateRandomCostBudgetEntryWithCostCenter(CostBudgetEntry, true);
        CostBudgetRegister.FindLast();

        Assert.AreEqual(CostBudgetRegister."No.", CostBudgetEntry.GetCostBudgetRegNo(), StrSubstNo(Text001, CostBudgetRegister.TableCaption()))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryHandleCostBudgetRegisterUpdate()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetRegister: Record "Cost Budget Register";
        OldBudgetRegisterNo: Integer;
    begin
        Initialize();
        // set the current RegNo and set "To Budget Entry No." to a newer entry so a new register entry will be created
        if CostBudgetEntry.FindLast() then;
        if CostBudgetRegister.FindLast() then;
        CostBudgetRegister."To Cost Budget Entry No." := CostBudgetEntry."Entry No." + 1 + LibraryRandom.RandInt(100);
        CostBudgetRegister.Modify();
        OldBudgetRegisterNo := CostBudgetRegister."No.";
        CostBudgetEntry.SetCostBudgetRegNo(OldBudgetRegisterNo);
        CreateRandomCostBudgetEntryWithCostCenter(CostBudgetEntry, true);
        CostBudgetRegister.FindLast();

        Assert.AreEqual(CostBudgetRegister."No.", CostBudgetEntry.GetCostBudgetRegNo(), StrSubstNo(Text001, CostBudgetRegister.TableCaption()));
        Assert.AreNotEqual(OldBudgetRegisterNo, CostBudgetEntry.GetCostBudgetRegNo(), StrSubstNo(Text001, CostBudgetRegister.TableCaption()))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryOnInsertEntryNo()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        i: Integer;
    begin
        Initialize();
        CostBudgetEntry.DeleteAll();
        for i := 1 to 1 + LibraryRandom.RandInt(9) do begin
            FillRandomCostBudgetEntryWithCostCenter(CostBudgetEntry);
            CostBudgetEntry."Entry No." := 0;
            CostBudgetEntry.Insert(true);
            Assert.AreEqual(
              i, CostBudgetEntry."Entry No.", StrSubstNo(Text000, CostBudgetEntry.FieldCaption("Entry No."), CostBudgetEntry.TableCaption(), i))
        end
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryOnModify()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        Initialize();
        CreateRandomCostBudgetEntryWithCostCenter(CostBudgetEntry, false);
        CostBudgetEntry."Last Modified By User" := '';
        CostBudgetEntry."Last Date Modified" := 0D;
        CostBudgetEntry.Modify(true);
        Assert.AreEqual(
          UpperCase(UserId), CostBudgetEntry."Last Modified By User",
          StrSubstNo(Text002, CostBudgetEntry.FieldCaption("Last Modified By User"), UpperCase(UserId)));
        Assert.AreEqual(
          Today, CostBudgetEntry."Last Date Modified", StrSubstNo(Text002, CostBudgetEntry.FieldCaption("Last Date Modified"), Today))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryOnModifyAmount()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetRegister: Record "Cost Budget Register";
        PrevBudgetRegisterTotal: Decimal;
        NewEntryAmount: Decimal;
    begin
        Initialize();
        CreateRandomCostBudgetEntryWithCostCenter(CostBudgetEntry, true);
        CostBudgetRegister.Get(CostBudgetEntry.GetCostBudgetRegNo());
        PrevBudgetRegisterTotal := CostBudgetRegister.Amount;

        NewEntryAmount := LibraryRandom.RandInt(CostBudgetEntry.Amount);
        CostBudgetEntry.Validate(Amount, NewEntryAmount);
        CostBudgetEntry.Modify(true);

        CostBudgetRegister.Get(CostBudgetRegister."No.");
        Assert.AreEqual(
          NewEntryAmount, CostBudgetRegister.Amount,
          StrSubstNo(
            Text000, CostBudgetRegister.FieldCaption(Amount), CostBudgetRegister.TableCaption(), PrevBudgetRegisterTotal + NewEntryAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntryOnModifyNegativeAmount()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetRegister: Record "Cost Budget Register";
        PrevBudgetRegisterTotal: Decimal;
        NewEntryAmount: Decimal;
    begin
        Initialize();
        CreateRandomCostBudgetEntryWithCostCenter(CostBudgetEntry, true);
        CostBudgetRegister.Get(CostBudgetEntry.GetCostBudgetRegNo());
        PrevBudgetRegisterTotal := CostBudgetRegister.Amount;

        NewEntryAmount := LibraryRandom.RandIntInRange(CostBudgetEntry.Amount, 2 * CostBudgetEntry.Amount);
        CostBudgetEntry.Validate(Amount, -NewEntryAmount);
        CostBudgetEntry.Modify(true);

        CostBudgetRegister.Get(CostBudgetRegister."No.");
        Assert.AreEqual(
          -NewEntryAmount, CostBudgetRegister.Amount,
          StrSubstNo(
            Text000, CostBudgetRegister.FieldCaption(Amount), CostBudgetRegister.TableCaption(), PrevBudgetRegisterTotal + NewEntryAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetEntrySetCostBudgetRegNo()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        BudgetRegNo: Integer;
    begin
        Initialize();
        BudgetRegNo := LibraryRandom.RandInt(100);
        CostBudgetEntry.SetCostBudgetRegNo(BudgetRegNo);
        Assert.AreEqual(BudgetRegNo, CostBudgetEntry.GetCostBudgetRegNo(), Text003)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetNameOnDeleteCostBudgetEntry()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetRegister: Record "Cost Budget Register";
        CostBudgetName: Record "Cost Budget Name";
    begin
        Initialize();
        CostBudgetName.Name :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetName.FieldNo(Name), DATABASE::"Cost Budget Name"), 1,
            MaxStrLen(CostBudgetEntry."Budget Name"));
        CostBudgetName.Insert();
        CreateCostBudgetEntry(
          CostBudgetEntry, 0, CostBudgetName.Name,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Type No."), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Type No.")), WorkDate(),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Center Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Center Code")), '', 0, true);
        Assert.IsTrue(CostBudgetRegister.Get(CostBudgetEntry.GetCostBudgetRegNo()), StrSubstNo(Text012, CostBudgetRegister.TableCaption()));
        CostBudgetName.Delete(true);
        asserterror CostBudgetEntry.Get(CostBudgetEntry."Entry No.");
        Assert.ExpectedErrorCannotFind(Database::"Cost Budget Entry");
        asserterror CostBudgetRegister.Get(CostBudgetRegister."No.");
        Assert.ExpectedErrorCannotFind(Database::"Cost Budget Register");
        asserterror CostBudgetName.Get(CostBudgetName.Name);
        Assert.ExpectedErrorCannotFind(Database::"Cost Budget Name");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCostBudgetRegisterOnValidateClosed()
    var
        CostBudgetRegister: Record "Cost Budget Register";
        i: Integer;
    begin
        Initialize();
        // create at least 3 registers. Close the last one -2 and verify all preceding ones are now closed.
        if CostBudgetRegister.Find('+') then;
        for i := 1 to 3 + LibraryRandom.RandInt(7) do begin
            CostBudgetRegister.Init();
            CostBudgetRegister."No." += 1;
            CostBudgetRegister.Insert();
        end;
        CostBudgetRegister.Next(-2);
        CostBudgetRegister.Validate(Closed, true);
        repeat
            Assert.IsTrue(CostBudgetRegister.Closed, StrSubstNo(Text015, CostBudgetRegister.TableCaption()))
        until CostBudgetRegister.Next(-1) = 0
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostBudgetRegisterOnValidateClosedErrorOnConfirmNo()
    var
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        Initialize();
        if CostBudgetRegister.FindLast() then;
        CostBudgetRegister.Closed := false;
        asserterror CostBudgetRegister.Validate(Closed, true);
        Assert.AreEqual('', GetLastErrorText, UnexpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostBudgetRegisterOnValidateClosedErrorOnReOpen()
    var
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        Initialize();
        if CostBudgetRegister.FindLast() then;
        CostBudgetRegister.Closed := true;
        asserterror CostBudgetRegister.Validate(Closed, false);
        Assert.IsTrue(Text014 = GetLastErrorText, UnexpectedErr)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostCenterValidateDeleteCostCenterOnConfirmNo()
    var
        CostCenter: Record "Cost Center";
        CostCenterCode: Code[20];
    begin
        // Unit test - Table 1112-Cost Center-Test Cost Center is not deleted when Confirm is set False.

        // Setup: Create a Cost Center.
        CostCenterCode := CreateCostCenter();
        CreateCostEntriesWithCostCenter(CostCenterCode);

        // Exercise: Delete created Cost Center and Confirm is set to No.
        CostCenter.Get(CostCenterCode);
        asserterror CostCenter.Delete(true); // In the code a blank error is written for confirm No so to handle that error ASSERTERROR has been used.

        // Verify: To check if the created Cost Center is not deleted.
        CostCenter.Get(CostCenterCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCostCenterValidateDeleteCostCenterOnConfirmYes()
    var
        CostCenter: Record "Cost Center";
        CostCenterCode: Code[20];
    begin
        // Unit test - Table 1112-Cost Center-Test Cost Center is deleted successfully when Confirm is set True.

        // Setup: Create a Cost Center.
        CostCenterCode := CreateCostCenter();
        CreateCostEntriesWithCostCenter(CostCenterCode);

        // Exercise: Delete created Cost Center and Confirm is set to Yes.
        CostCenter.Get(CostCenterCode);
        CostCenter.Delete(true);

        // Verify: To check if the created Cost Center is deleted successfully.
        asserterror CostCenter.Get(CostCenterCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostCenterValidateLineTypeConfirmationNo()
    var
        CostCenter: Record "Cost Center";
        CostCenterCode: Code[20];
    begin
        // Unit test - Table 1112-Cost Center-Test that Line Type of Cost Center is not modified when Confirm is No.

        // Setup: Create a Cost center with Cost Entries.
        CostCenterCode := CreateCostCenter();
        CreateCostEntriesWithCostCenter(CostCenterCode);

        // Exercise: Modify the Line Type of Created Cost Center.
        CostCenter.Get(CostCenterCode);
        asserterror UpdateCostCenter(CostCenter); // In the code a blank error is written for confirm No so to handle that error ASSERTERROR has been used.

        // Verify: Check that Line Type and Totaling fields of Cost Center is not modified .
        CostCenter.TestField("Line Type", CostCenter."Line Type"::"Cost Center");
        CostCenter.TestField(Totaling, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCostCenterValidateLineTypeConfirmationYes()
    var
        CostCenter: Record "Cost Center";
        CostCenterCode: Code[20];
    begin
        // Unit test - Table 1112-Cost Center-Test that Line Type of Cost Center is Modified when Confirm is set Yes.

        // Setup: Create a Cost Center.
        CostCenterCode := CreateCostCenter();
        CreateCostEntriesWithCostCenter(CostCenterCode);

        // Exercise: Modify the Line Type of created Cost Center.
        CostCenter.Get(CostCenterCode);
        UpdateCostCenter(CostCenter);

        // Verify: To check that Line Type, Blocked and Cost Subtype Fields are Modified when Confirm is Yes.
        CostCenter.TestField("Line Type", CostCenter."Line Type"::Heading);
        CostCenter.TestField("Cost Subtype", 0);
        CostCenter.TestField(Blocked, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostCenterValidateTotaling()
    var
        CostCenter: Record "Cost Center";
        CostCenterCode: Code[20];
    begin
        // Unit test - Table 1112-Cost Center-Test that error occur when Totaling field value is modified for a Cost Center.

        // Setup: Create a Cost Center with Cost Entries.
        CostCenterCode := CreateCostCenter();
        CreateCostEntriesWithCostCenter(CostCenterCode);

        // Exercise: To get the occured error.
        CostCenter.Get(CostCenterCode);
        asserterror CostCenter.Validate(Totaling, LibraryUtility.GenerateRandomCode(CostCenter.FieldNo(Code), DATABASE::"Cost Center"));

        // Verify: To check that expected error occur when Totaling field value is modified for Cost Center.
        Assert.ExpectedError(
          StrSubstNo(IncorrectLineTypeError, CostCenter."Line Type", CostCenter.TableCaption(), CostCenter.FieldCaption(Code), CostCenter.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalBatchOnDelete()
    var
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        CostJournalBatchName: Code[10];
    begin
        // Unit test - Table 1102 Cost Journal Batch - Verify a Cost Journal Batch deletion
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        CostJournalBatchName := CostJournalBatch.Name;

        CostJournalBatch.Delete(true);
        CostJournalLine.SetRange("Journal Batch Name", CostJournalBatchName);

        Assert.IsTrue(CostJournalLine.IsEmpty, StrSubstNo(ExpectedValueIsDifferentError, CostJournalBatch.TableCaption()));

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalBatchOnValidateBalCostTypeNo()
    var
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostType: Record "Cost Type";
    begin
        // Unit test - Table 1102 Cost Journal Batch - Verify a Bal.Cost Type No. modification
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);

        CreateCostType(CostType);

        CostJournalBatch.Validate("Bal. Cost Type No.", CostType."No.");
        CostJournalBatch.Modify();

        CostJournalBatch.TestField("Bal. Cost Center Code", CostType."Cost Center Code");
        CostJournalBatch.TestField("Bal. Cost Object Code", CostType."Cost Object Code");

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalBatchOnValidateBlockedBalCostTypeNo()
    var
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostType: Record "Cost Type";
    begin
        // Unit test - Table 1102 Cost Journal Batch - Verify a blocked Cost Type entry as a Bal.Cost Type No. in Cost Journal Batch
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);

        CreateCostType(CostType);
        CostType.Validate(Blocked, true);
        CostType.Modify();

        asserterror CostJournalBatch.Validate("Bal. Cost Type No.", CostType."No.");
        Assert.ExpectedTestFieldError(CostType.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineCalculateBalanceWithEmptyBalCostTypeNo()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostType: Record "Cost Type";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        AmountValue: Decimal;
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify that CostTypeNo modification will affect the Bal.Cost Center Code and Bal.Cost Object Code fields. Testcase ("Cost Type No." <> '') and ("Bal. Cost Type No." = ''):
        CreateCostType(CostType);

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        CostJournalLine.Validate("Bal. Cost Type No.", '');
        CostJournalLine.Validate("Cost Type No.", CostType."No.");
        AmountValue := LibraryRandom.RandDec(100, 2);
        CostJournalLine.Validate(Amount, AmountValue);
        CostJournalLine.Modify(true);

        CostJournalLine.TestField(Balance, AmountValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineCalculateBalanceWithEmptyCostTypeNo()
    var
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        CostType: Record "Cost Type";
        AmountValue: Decimal;
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify that CostTypeNo modification will affect the Bal.Cost Center Code and Bal.Cost Object Code fields. Testcase ("Cost Type No." = '') and ("Bal. Cost Type No." <> ''):
        CreateCostType(CostType);

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        CostJournalLine.Validate("Cost Type No.", '');
        CostJournalLine.Validate("Bal. Cost Type No.", CostType."No.");
        AmountValue := LibraryRandom.RandDec(100, 2);
        CostJournalLine.Validate(Amount, AmountValue);
        CostJournalLine.Modify(true);

        CostJournalLine.TestField(Balance, -AmountValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnModify()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify that any Cost Journal modification will change "System-Created Entry" property to FALSE
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);

        CostJournalLine.Validate(Amount, LibraryRandom.RandDec(100, 2));
        CostJournalLine.Modify(true);

        Assert.IsFalse(
          CostJournalLine."System-Created Entry",
          StrSubstNo(ExpectedValueIsDifferentError, CostJournalLine.FieldCaption("System-Created Entry")));

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnValidateBalCostTypeNo()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostType: Record "Cost Type";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify that Bal CostTypeNo modification will affect the Bal.Cost Center Code and Bal.Cost Object Code fields
        CreateCostType(CostType);

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        CostJournalLine.Validate("Bal. Cost Type No.", CostType."No.");
        CostJournalLine.Modify(true);

        CostJournalLine.TestField("Bal. Cost Center Code", CostType."Cost Center Code");
        CostJournalLine.TestField("Bal. Cost Object Code", CostType."Cost Object Code");

        CostJournalTemplate.Delete(true);
        CostType.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnValidateCostCenter()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostCenter: Record "Cost Center";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        RecRef: RecordRef;
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify object behavior in case that Cost Center Code is equal to "Begin-Total" or "Cost Center"
        SetUpCostJournalLineTestCases();

        CostCenter.Init();
        CostCenter.SetFilter("Line Type", '<>%1&<>%2', CostCenter."Line Type"::"Begin-Total", CostCenter."Line Type"::"Cost Center");
        RecRef.GetTable(CostCenter);
        LibraryUtility.FindRecord(RecRef);
        RecRef.SetTable(CostCenter);

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        asserterror CostJournalLine.Validate("Cost Center Code", CostCenter.Code);

        Assert.AreNotEqual(
          StrPos(
            GetLastErrorText,
            StrSubstNo(
              Text016, CostCenter.FieldCaption("Line Type"), CostCenter."Line Type"::"Cost Center", CostCenter."Line Type"::"Begin-Total",
              CostCenter.TableCaption(), CostCenter.Code)), 0, GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnValidateCostObject()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostObject: Record "Cost Object";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        RecRef: RecordRef;
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify object behavior in case that Cost Object Code is equal to "Begin-Total" or "Cost Object"
        SetUpCostJournalLineTestCases();

        CostObject.Init();
        CostObject.SetFilter("Line Type", '<>%1&<>%2', CostObject."Line Type"::"Begin-Total", CostObject."Line Type"::"Cost Object");
        RecRef.GetTable(CostObject);
        LibraryUtility.FindRecord(RecRef);
        RecRef.SetTable(CostObject);

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        asserterror CostJournalLine.Validate("Cost Object Code", CostObject.Code);

        Assert.AreNotEqual(
          StrPos(
            GetLastErrorText,
            StrSubstNo(
              Text016, CostObject.FieldCaption("Line Type"), CostObject."Line Type"::"Cost Object", CostObject."Line Type"::"Begin-Total",
              CostObject.TableCaption(), CostObject.Code)), 0, GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnValidateCostTypeNo()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostType: Record "Cost Type";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify that CostTypeNo modification will affect the Cost Center Code, Description and Cost Object Code fields
        CreateCostType(CostType);

        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        CostJournalLine.Validate("Cost Type No.", CostType."No.");
        CostJournalLine.Modify(true);

        CostJournalLine.TestField("Cost Center Code", CostType."Cost Center Code");
        CostJournalLine.TestField("Cost Object Code", CostType."Cost Object Code");
        CostJournalLine.TestField(Description, CostType.Name);

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnValidateCreditAmount()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        RandomAmountValue: Decimal;
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify that debit amount modification will affect amount field
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);

        RandomAmountValue := LibraryRandom.RandDec(10, 2);
        CostJournalLine.Validate("Credit Amount", RandomAmountValue);

        CostJournalLine.TestField(Amount, -RandomAmountValue);
        CostJournalLine.TestField("Debit Amount", 0);

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnValidateCreditAmountWithDebitAmountEntered()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CreditAmountValue: Decimal;
        DebitAmountValue: Decimal;
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify that Credit amount modification will affect Debit Amount and Amount fields
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);

        DebitAmountValue := LibraryRandom.RandDec(10, 2);
        CostJournalLine.Validate("Debit Amount", DebitAmountValue);

        CreditAmountValue := LibraryRandom.RandDec(10, 2);
        CostJournalLine.Validate("Credit Amount", CreditAmountValue);

        CostJournalLine.TestField(Amount, -CreditAmountValue);
        CostJournalLine.TestField("Debit Amount", 0);
        CostJournalLine.TestField("Credit Amount", CreditAmountValue);

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnValidateDebitAmount()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        RandomAmountValue: Decimal;
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify that debit amount modification will affect amount field
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);

        RandomAmountValue := LibraryRandom.RandDec(10, 2);
        CostJournalLine.Validate("Debit Amount", RandomAmountValue);

        CostJournalLine.TestField(Amount, RandomAmountValue);
        CostJournalLine.TestField("Credit Amount", 0);

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnValidateDebitAmountWithCreditAmountEntered()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CreditAmountValue: Decimal;
        DebitAmountValue: Decimal;
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify that debit amount modification will affect the Credit Amount and Amount fields
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);

        CreditAmountValue := LibraryRandom.RandDec(10, 2);
        CostJournalLine.Validate("Credit Amount", CreditAmountValue);

        DebitAmountValue := LibraryRandom.RandDec(10, 2);
        CostJournalLine.Validate("Debit Amount", DebitAmountValue);

        CostJournalLine.TestField(Amount, DebitAmountValue);
        CostJournalLine.TestField("Debit Amount", DebitAmountValue);
        CostJournalLine.TestField("Credit Amount", 0);

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnValidateEmptySourceCode()
    var
        CostJournalLine: Record "Cost Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify Cost Journal Line with no Source Code entered
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        SourceCodeSetup.Get();

        CostJournalLine.TestField("Source Code", SourceCodeSetup."Cost Journal");

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnValidateNegativeCreditAmount()
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CreditAmountValue: Decimal;
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify that negative Credit amount will affect Debit amount field
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);

        CreditAmountValue := LibraryRandom.RandDec(10, 2);
        CostJournalLine.Validate("Credit Amount", -CreditAmountValue);

        CostJournalLine.TestField(Amount, CreditAmountValue);
        CostJournalLine.TestField("Debit Amount", CreditAmountValue);
        CostJournalLine.TestField("Credit Amount", 0);

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalLineOnValidateReasonCode()
    var
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        ReasonCode: Record "Reason Code";
        CostType: Record "Cost Type";
        BalCostType: Record "Cost Type";
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify that in case of an empty Reason Code, this property will be set to Journal Batch's Reason Code value
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostTypeNoGLRange(BalCostType);
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryERM.CreateReasonCode(ReasonCode);
        CostJournalBatch.Validate("Reason Code", ReasonCode.Code);
        CostJournalBatch.Modify(true);

        LibraryCostAccounting.CreateCostJournalLineBasic(
          CostJournalLine, CostJournalTemplate.Name, CostJournalBatch.Name, WorkDate(), CostType."No.", BalCostType."No.");

        CostJournalLine.TestField("Reason Code", CostJournalBatch."Reason Code");

        CostJournalTemplate.Delete(true)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalTemplateOnCreate()
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        // Unit test Table 1100 - verify a Cost Journal Template creation
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate);

        Assert.AreEqual(
          REPORT::"Cost Register", CostJournalTemplate."Posting Report ID",
          StrSubstNo(UnexpectedMessageError, CostJournalTemplate.FieldCaption("Posting Report ID"), REPORT::"Cost Register"));

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalTemplateOnDelete()
    var
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        Counter: Integer;
    begin
        // Unit test Table 1100 - verify deleting a Cost Journal template (should delete Cost Journal Batch also)
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate);
        for Counter := 1 to LibraryRandom.RandInt(10) do
            LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);

        CostJournalTemplate.Get(CostJournalTemplate.Name);
        CostJournalTemplate.Delete(true);
        CostJournalBatch.SetRange("Journal Template Name", CostJournalTemplate.Name);

        Assert.IsTrue(CostJournalBatch.IsEmpty, StrSubstNo(ExpectedValueIsDifferentError, CostJournalBatch.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostJournalTemplateOnValidateAmountZero()
    var
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        // Unit test - Table 1101 Cost Journal Line - Verify Cost Journal Line with zero amount
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);

        CostJournalLine.Validate(Amount, 0);
        CostJournalLine.Modify(true);

        CostJournalLine.TestField("Debit Amount", 0);
        CostJournalLine.TestField("Credit Amount", 0);

        CostJournalTemplate.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostObjectValidateDeleteCostCenterOnConfirmNo()
    var
        CostObject: Record "Cost Object";
        CostObjectCode: Code[20];
    begin
        // Unit test - Table 1113-Cost Object-Test Cost Object is not deleted when Confirm is set to False.

        // Setup: Create a Cost Object.
        CostObjectCode := CreateCostObject();
        CreateCostEntriesWithCostObject(CostObjectCode);

        // Exercise: Delete created Cost Object and set Confirm to No.
        CostObject.Get(CostObjectCode);
        asserterror CostObject.Delete(true); // In the code a blank error is written for confirm No so to handle that error ASSERTERROR has been used.

        // Verify: To check if the created Cost Object is not deleted.
        CostObject.Get(CostObjectCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCostObjectValidateDeleteCostCenterOnConfirmYes()
    var
        CostObject: Record "Cost Object";
        CostObjectCode: Code[20];
    begin
        // Unit test - Table 1113-Cost Object-Test Cost Object is deleted successfully when Confirm is set to True.

        // Setup: Create a Cost Object.
        CostObjectCode := CreateCostObject();
        CreateCostEntriesWithCostObject(CostObjectCode);

        // Exercise: Delete created Cost Object and set Confirm to Yes.
        CostObject.Get(CostObjectCode);
        CostObject.Delete(true);

        // Verify: To check if the created Cost Object is deleted successfully.
        asserterror CostObject.Get(CostObjectCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestCostObjectValidateLineTypeConfirmationNo()
    var
        CostObject: Record "Cost Object";
        CostObjectCode: Code[20];
    begin
        // Unit test - Table 1113-Cost Object-Test that Line Type of Cost Object is not modified when Confirm is No.

        // Setup: Create a Cost Object with Cost Entries.
        CostObjectCode := CreateCostObject();
        CreateCostEntriesWithCostObject(CostObjectCode);

        // Exercise: Modify the Line Type of Created Cost Object.
        CostObject.Get(CostObjectCode);
        asserterror UpdateCostObject(CostObject); // In the code a blank error is written for confirm No so to handle that error ASSERTERROR has been used.

        // Verify: Check that Line Type and Totaling fields of Cost Object is not modified.
        CostObject.TestField("Line Type", CostObject."Line Type"::"Cost Object");
        CostObject.TestField(Totaling, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCostObjectValidateLineTypeConfirmationYes()
    var
        CostObject: Record "Cost Object";
        CostObjectCode: Code[20];
    begin
        // Unit test - Table 1113-Cost Object-Test that Line Type of Cost Object is Modified when Confirm is set Yes.

        // Setup: Create a Cost Object.
        CostObjectCode := CreateCostObject();
        CreateCostEntriesWithCostObject(CostObjectCode);

        // Exercise: Modify the Line Type of created Cost Object.
        CostObject.Get(CostObjectCode);
        UpdateCostObject(CostObject);

        // Verify: To check that Line Type, Blocked and Cost Subtype Fields are Modified when Confirm is Yes.
        CostObject.TestField("Line Type", CostObject."Line Type"::Heading);
        CostObject.TestField(Blocked, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCostObjectValidateTotaling()
    var
        CostObject: Record "Cost Object";
        CostObjectCode: Code[20];
    begin
        // Unit test - Table 1113-Cost Object-Test that error occur when Totaling field value is modified for a Cost Object.

        // Setup: Create a Cost Object with Cost Entries.
        CostObjectCode := CreateCostObject();
        CreateCostEntriesWithCostObject(CostObjectCode);

        // Exercise: To get the occured error.
        CostObject.Get(CostObjectCode);
        asserterror CostObject.Validate(Totaling, LibraryUtility.GenerateRandomCode(CostObject.FieldNo(Code), DATABASE::"Cost Object"));

        // Verify: To check that expected error occur when Totaling field value is modified for Cost Object.
        Assert.ExpectedError(
          StrSubstNo(IncorrectLineTypeError, CostObject."Line Type", CostObject.TableCaption(), CostObject.FieldCaption(Code), CostObject.Code));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestGLAccLinkToCostTypeWhenAlignGLAccIsPrompt()
    var
        GLAccount: Record "G/L Account";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostType: Record "Cost Type";
        OldGLAccountNo: Code[20];
    begin
        // Unit Test Case: Test that on renaming G/L Account No., its Cost Type No. also get renamed successfully(when Align G/L Account on Cost Accounting Setup is set to Prompt).

        // Setup: Set Align G/L Account to Prompt on Cost Accounting Setup.
        InitializeCostAccountingSetup(CostAccountingSetup, CostAccountingSetup."Align G/L Account"::Prompt);

        // Exercise: Find a G/L Account Linked to Cost Type and rename it.
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        OldGLAccountNo := GLAccount."No.";
        GLAccount.Rename(
          CopyStr(
            LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"G/L Account", GLAccount.FieldNo("No."))));

        // Verify: To check that corresponding Cost Type No. of G/L Account is renamed.
        CostType.Get(GLAccount."No.");
        asserterror CostType.Get(OldGLAccountNo);

        // Tear Down: Reset the value of Align G/L Account on Cost Accounting Setup.
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestGLAccLinkToCostTypeWhenAlignGLAccIsAutomatic()
    var
        GLAccount: Record "G/L Account";
        CostAccountingSetup: Record "Cost Accounting Setup";
        CostType: Record "Cost Type";
        OldGLAccountNo: Code[20];
        NewGLAccountNo: Code[20];
    begin
        // Unit Test Case: Test that on reverse renaming G/L Account No., its Cost Type No. also get reverse renamed successfully(when Align G/L Account on Cost Accounting Setup is set to Automatic).

        // Setup: Rename G/L Account No. to update its corresponding Cost Type No.
        InitializeCostAccountingSetup(CostAccountingSetup, CostAccountingSetup."Align G/L Account"::Automatic);
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        OldGLAccountNo := GLAccount."No.";
        GLAccount.Rename(
          CopyStr(
            LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"G/L Account", GLAccount.FieldNo("No."))));
        NewGLAccountNo := GLAccount."No.";

        // Exercise: Reverse Rename the G/L Account Linked to Cost Type.
        GLAccount.Rename(OldGLAccountNo);

        // Verify: CostType No. of Corresponding G/L Account is reverse renamed successfully.
        CostType.Get(OldGLAccountNo);
        asserterror CostType.Get(NewGLAccountNo);

        // Tear Down: Reset the value of Align G/L Account on Cost Accounting Setup.
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align G/L Account"), CostAccountingSetup."Align G/L Account");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferGLEntriesToCAWithCombinedCostCenterAndCostObjectDimensions()
    var
        TransferGLEntriesToCA: Codeunit "Transfer GL Entries to CA";
        CostCenterDimGLEntryNo: Integer;
        CostObjectDimGLEntryNo: Integer;
    begin
        Initialize();
        // Validate GL entries are inserted to CA in case of combined entry's dimensions
        CostObjectDimGLEntryNo := CreateGLEntryWithCostObjectDim();
        CostCenterDimGLEntryNo := CreateGLEntryWithCostCenterDim();
        TransferGLEntriesToCA.TransferGLtoCA();

        VerifyCostEntry(CostCenterDimGLEntryNo);
        VerifyCostEntry(CostObjectDimGLEntryNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCreateCostJnlTemplateWithBlankName()
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263359] User cannot create Cost Journal Template with blank Name.

        CostJournalTemplate.Init();
        CostJournalTemplate.Description := LibraryUtility.GenerateGUID();

        asserterror CostJournalTemplate.Insert(true);

        Assert.ExpectedError(StrSubstNo(TestFieldErr, CostJournalTemplate.FieldCaption(Name)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCreateCostJnlBatchWithBlankName()
    var
        CostJournalBatch: Record "Cost Journal Batch";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263359] User cannot create Cost Journal Batch with blank Name.

        CostJournalBatch.Init();
        CostJournalBatch.Description := LibraryUtility.GenerateGUID();

        asserterror CostJournalBatch.Insert(true);

        Assert.ExpectedError(StrSubstNo(TestFieldErr, CostJournalBatch.FieldCaption(Name)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCreateCostTypeWithBlankNo()
    var
        CostType: Record "Cost Type";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263359] User cannot create Cost Type with blank No.

        CostType.Init();
        CostType.Name := LibraryUtility.GenerateGUID();

        asserterror CostType.Insert(true);

        Assert.ExpectedError(StrSubstNo(TestFieldErr, CostType.FieldCaption("No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCreateCostBudgetNameWithBlankName()
    var
        CostBudgetName: Record "Cost Budget Name";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263359] User cannot create Cost Budget Name with blank Name.

        CostBudgetName.Init();
        CostBudgetName.Description := LibraryUtility.GenerateGUID();

        asserterror CostBudgetName.Insert(true);

        Assert.ExpectedError(StrSubstNo(TestFieldErr, CostBudgetName.FieldCaption(Name)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCreateCostCenterWithBlankCode()
    var
        CostCenter: Record "Cost Center";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263359] User cannot create Cost Center with blank Code.

        CostCenter.Init();
        CostCenter.Name := LibraryUtility.GenerateGUID();

        asserterror CostCenter.Insert(true);

        Assert.ExpectedError(StrSubstNo(TestFieldErr, CostCenter.FieldCaption(Code)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCreateCostObjectWithBlankCode()
    var
        CostObject: Record "Cost Object";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263359] User cannot create Cost Object with blank Code.

        CostObject.Init();
        CostObject.Name := '';

        asserterror CostObject.Insert(true);

        Assert.ExpectedError(StrSubstNo(TestFieldErr, CostObject.FieldCaption(Code)));
    end;

    local procedure CostEntryInsert(var CostEntry: Record "Cost Entry"; CostTypeNo: Code[20]; Amount: Decimal)
    begin
        CostEntry.Validate("Entry No.", CostEntry.Count + 1);
        CostEntry.Validate("Cost Type No.", CostTypeNo);
        CostEntry.Validate(Amount, Amount);
        CostEntry.Insert();
    end;

    local procedure CostTypeInsert(var CostTypeNo: Code[20]; ValidationStatus: Boolean)
    var
        CostType: Record "Cost Type";
    begin
        CostType.Validate("No.", LibraryUtility.GenerateRandomCode(CostType.FieldNo("No."), DATABASE::"Cost Type"));
        CostType.Validate(Name, LibraryUtility.GenerateRandomCode(CostType.FieldNo(Name), DATABASE::"Cost Type"));
        CostType.Insert(ValidationStatus);
        CostTypeNo := CostType."No.";
    end;

    local procedure CostTypeModifySetup(var CostType: Record "Cost Type"; var ModifiedDate: Date; var ModifiedBy: Code[50]; InvokeOnModify: Boolean)
    var
        CostTypeNo: Code[20];
    begin
        CostTypeInsert(CostTypeNo, false);
        CostType.Get(CostTypeNo);

        if InvokeOnModify then begin
            ModifiedDate := Today;
            ModifiedBy := UpperCase(UserId);
        end else begin
            ModifiedDate := CostType."Modified Date";
            ModifiedBy := CostType."Modified By";
        end;
    end;

    local procedure CreateAllocationSource(AutogeneratedID: Boolean): Code[10]
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        CostAllocationSource.Init();
        if AutogeneratedID then
            CostAllocationSource.Validate(ID, '')
        else
            CostAllocationSource.Validate(
              ID, LibraryUtility.GenerateRandomCode(CostAllocationSource.FieldNo(ID), DATABASE::"Cost Allocation Source"));
        CostAllocationSource.Insert(true);

        exit(CostAllocationSource.ID);
    end;

    local procedure CreateAllocationTarget(var CostAllocationTarget: Record "Cost Allocation Target"; AllocSourceID: Code[10])
    begin
        CostAllocationTarget.Init();
        CostAllocationTarget.ID := AllocSourceID;
        CostAllocationTarget."Line No." := NextAllocTargetLineNo(AllocSourceID);
        CostAllocationTarget.Insert(true);
    end;

    local procedure CreateCostBudgetEntry(var CostBudgetEntry: Record "Cost Budget Entry"; EntryNo: Integer; BudgetName: Code[10]; CostTypeNo: Code[20]; NewDate: Date; CostCenterCode: Code[20]; CostObjectCode: Code[20]; NewAmount: Decimal; OnInsert: Boolean)
    begin
        FillCostBudgetEntry(CostBudgetEntry, EntryNo, BudgetName, CostTypeNo, NewDate, CostCenterCode, CostObjectCode, NewAmount);
        CostBudgetEntry.Insert(OnInsert)
    end;

    local procedure CreateCostBudgetEntryCopy(var CostBudgetEntry: Record "Cost Budget Entry")
    var
        CostBudgetEntry2: Record "Cost Budget Entry";
    begin
        if CostBudgetEntry2.FindLast() then;
        CostBudgetEntry."Entry No." := CostBudgetEntry2."Entry No." + 1;
        CostBudgetEntry.Insert();
    end;

    local procedure CreateCostCenter(): Code[20]
    var
        CostCenter: Record "Cost Center";
    begin
        CostCenter.Validate(Code, LibraryUtility.GenerateRandomCode(CostCenter.FieldNo(Code), DATABASE::"Cost Center"));
        CostCenter.Insert(true);

        exit(CostCenter.Code);
    end;

    local procedure CreateCostEntriesWithCostCenter(CostCenterCode: Code[20])
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
    begin
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        UpdateCostJournalLine(CostJournalLine, CostCenterCode, '');
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
    end;

    local procedure CreateCostEntriesWithCostObject(CostObjectCode: Code[20])
    var
        CostJournalLine: Record "Cost Journal Line";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalBatch: Record "Cost Journal Batch";
    begin
        CreateCostJournalLine(CostJournalLine, CostJournalTemplate, CostJournalBatch);
        UpdateCostJournalLine(CostJournalLine, '', CostObjectCode);
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
    end;

    local procedure CreateCostJournalLine(var CostJournalLine: Record "Cost Journal Line"; var CostJournalTemplate: Record "Cost Journal Template"; var CostJournalBatch: Record "Cost Journal Batch")
    var
        CostType: Record "Cost Type";
        BalCostType: Record "Cost Type";
    begin
        LibraryCostAccounting.CreateCostTypeNoGLRange(CostType);
        LibraryCostAccounting.CreateCostTypeNoGLRange(BalCostType);
        LibraryCostAccounting.CreateCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.CreateCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryCostAccounting.CreateCostJournalLineBasic(
          CostJournalLine, CostJournalTemplate.Name, CostJournalBatch.Name, WorkDate(), CostType."No.", BalCostType."No.");
    end;

    local procedure CreateCostObject(): Code[20]
    var
        CostObject: Record "Cost Object";
    begin
        CostObject.Validate(Code, LibraryUtility.GenerateRandomCode(CostObject.FieldNo(Code), DATABASE::"Cost Object"));
        CostObject.Insert(true);

        exit(CostObject.Code);
    end;

    local procedure CreateCostRegister(var CostRegister: Record "Cost Register"; CostRegisterNo: Integer)
    begin
        Clear(CostRegister);
        CostRegister.Validate("No.", CostRegisterNo);
        CostRegister.Insert();
    end;

    local procedure CreateCostType(var CostType: Record "Cost Type")
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
    begin
        LibraryCostAccounting.CreateCostCenter(CostCenter);
        LibraryCostAccounting.CreateCostObject(CostObject);

        CostType.Validate("No.", LibraryUtility.GenerateRandomCode(CostType.FieldNo("No."), DATABASE::"Cost Type"));
        CostType.Validate(Name, LibraryUtility.GenerateRandomCode(CostType.FieldNo(Name), DATABASE::"Cost Type"));
        CostType.Validate("Cost Center Code", CostCenter.Code);
        CostType.Validate("Cost Object Code", CostObject.Code);
        CostType.Insert();
    end;

    local procedure CreateGLEntryWithCostCenterDim(): Integer
    var
        CostAccSetup: Record "Cost Accounting Setup";
        CostCenter: Record "Cost Center";
        DimSetID: Integer;
    begin
        CostAccSetup.Get();
        LibraryCostAccounting.CreateCostCenterFromDimension(CostCenter);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, CostAccSetup."Cost Center Dimension", CostCenter.Code);
        exit(CreateGLEntry(DimSetID));
    end;

    local procedure CreateGLEntryWithCostObjectDim(): Integer
    var
        CostAccSetup: Record "Cost Accounting Setup";
        CostObject: Record "Cost Object";
        DimSetID: Integer;
    begin
        CostAccSetup.Get();
        LibraryCostAccounting.CreateCostObjectFromDimension(CostObject);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, CostAccSetup."Cost Object Dimension", CostObject.Code);
        exit(CreateGLEntry(DimSetID));
    end;

    local procedure CreateGLEntry(DimSetID: Integer): Integer
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
    begin
        LibraryCostAccounting.FindGLAccLinkedToCostType(GLAccount);
        if GLEntry.FindLast() then
            GLEntry.Init();
        GLEntry."Entry No." += 1;
        GLEntry."G/L Account No." := GLAccount."No.";
        GLEntry."Dimension Set ID" := DimSetID;
        GLEntry."Document No." := GLAccount."No.";
        // Document No just needs to have a value, so it can be the same as G/L Account No.
        GLEntry.Amount := LibraryRandom.RandDec(100, 2);
        GLEntry."Posting Date" := WorkDate();
        GLEntry.Insert();
        exit(GLEntry."Entry No.");
    end;

    local procedure CreateRandomCostBudgetEntryWithCostCenter(var CostBudgetEntry: Record "Cost Budget Entry"; OnInsert: Boolean)
    begin
        FillRandomCostBudgetEntryWithCostCenter(CostBudgetEntry);
        CostBudgetEntry.Insert(OnInsert)
    end;

    local procedure CreateRandomCostBudgetEntryWithCostObject(var CostBudgetEntry: Record "Cost Budget Entry"; OnInsert: Boolean)
    begin
        FillRandomCostBudgetEntryWithCostObject(CostBudgetEntry);
        CostBudgetEntry.Insert(OnInsert)
    end;

    local procedure FillCostBudgetEntry(var CostBudgetEntry: Record "Cost Budget Entry"; EntryNo: Integer; BudgetName: Code[10]; CostTypeNo: Code[20]; NewDate: Date; CostCenterCode: Code[20]; CostObjectCode: Code[20]; NewAmount: Decimal)
    begin
        if EntryNo = 0 then begin
            if CostBudgetEntry.FindLast() then
                CostBudgetEntry.Init();
            CostBudgetEntry."Entry No." += 1;
        end;
        CostBudgetEntry."Budget Name" := BudgetName;
        CostBudgetEntry."Cost Type No." := CostTypeNo;
        CostBudgetEntry.Date := NewDate;
        CostBudgetEntry."Cost Center Code" := CostCenterCode;
        CostBudgetEntry."Cost Object Code" := CostObjectCode;
        CostBudgetEntry.Amount := NewAmount;
    end;

    local procedure FillRandomCostBudgetEntryWithCostCenter(var CostBudgetEntry: Record "Cost Budget Entry")
    begin
        FillCostBudgetEntry(CostBudgetEntry, 0,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Budget Name"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Budget Name")),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Type No."), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Type No.")), WorkDate(),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Center Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Center Code")), '', LibraryRandom.RandInt(1000))
    end;

    local procedure FillRandomCostBudgetEntryWithCostObject(var CostBudgetEntry: Record "Cost Budget Entry")
    begin
        FillCostBudgetEntry(CostBudgetEntry, 0,
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Budget Name"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Budget Name")),
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Type No."), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Type No.")), WorkDate(),
          '',
          CopyStr(
            LibraryUtility.GenerateRandomCode(CostBudgetEntry.FieldNo("Cost Object Code"), DATABASE::"Cost Budget Entry"), 1,
            MaxStrLen(CostBudgetEntry."Cost Object Code")), LibraryRandom.RandInt(1000))
    end;

    local procedure InitializeCostAccountingSetup(var CostAccountingSetup: Record "Cost Accounting Setup"; AlignGLAccount: Option)
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cost Accounting - Tables");
        CostAccountingSetup.Get();
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align G/L Account"), AlignGLAccount);
    end;

    local procedure InsertCostBudgetEntriesToCompress(var CostBudgetEntry: Record "Cost Budget Entry"; var FromEntryNo: Integer; var ToEntryNo: Integer; FillAmount: Boolean; var TotalAmount: Decimal)
    var
        i: Integer;
    begin
        CreateRandomCostBudgetEntryWithCostCenter(CostBudgetEntry, false);
        if not FillAmount then begin
            CostBudgetEntry.Amount := 0;
            CostBudgetEntry.Modify();
        end;
        TotalAmount := CostBudgetEntry.Amount;
        FromEntryNo := CostBudgetEntry."Entry No.";
        for i := 1 to LibraryRandom.RandInt(10) do begin
            CreateCostBudgetEntryCopy(CostBudgetEntry);
            TotalAmount += CostBudgetEntry.Amount;
            CostBudgetEntry.Modify();
        end;
        ToEntryNo := CostBudgetEntry."Entry No."
    end;

    local procedure LookupGroupFilter(BaseType: Enum "Cost Allocation Target Base"; ExpectedGroupFilter: Text[30])
    var
        CostAllocTargetListPage: TestPage "Cost Allocation Target List";
    begin
        // Setup:
        CostAllocTargetListPage.OpenEdit();
        CostAllocTargetListPage.Base.SetValue(BaseType);

        // Exercise:
        CostAllocTargetListPage."Group Filter".Lookup();

        // Verify:
        CostAllocTargetListPage."Group Filter".AssertEquals(ExpectedGroupFilter);
    end;

    local procedure LookupNoFilter(BaseType: Enum "Cost Allocation Target Base"; ExpectedNoFilter: Text[30])
    var
        CostAllocTargetListPage: TestPage "Cost Allocation Target List";
    begin
        // Setup:
        CostAllocTargetListPage.OpenEdit();
        CostAllocTargetListPage.Base.SetValue(BaseType);

        // Exercise:
        CostAllocTargetListPage."No. Filter".Lookup();

        // Verify:
        CostAllocTargetListPage."No. Filter".AssertEquals(ExpectedNoFilter);
    end;

    local procedure NextAllocTargetLineNo(AllocSourceID: Code[10]): Integer
    var
        CostAllocTarget: Record "Cost Allocation Target";
    begin
        CostAllocTarget.SetFilter(ID, AllocSourceID);
        if CostAllocTarget.FindLast() then
            exit(CostAllocTarget."Line No." + 1);

        exit(0);
    end;

    local procedure SetUpCostJournalLineTestCases()
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostObject1: Record "Cost Object";
        CostCenter1: Record "Cost Center";
    begin
        // By the test requirement, it is needed to create two different Cost Type records
        LibraryCostAccounting.CreateCostCenter(CostCenter);

        CostCenter.Validate("Line Type", CostCenter."Line Type"::Heading);
        CostCenter.Modify(true);

        LibraryCostAccounting.CreateCostCenter(CostCenter1);
        CostCenter1.Validate("Line Type", CostCenter1."Line Type"::"Cost Center");
        CostCenter1.Modify(true);

        LibraryCostAccounting.CreateCostObject(CostObject);
        CostObject.Validate("Line Type", CostObject."Line Type"::"Cost Object");
        CostObject.Modify(true);
        CostObject.Reset();

        LibraryCostAccounting.CreateCostObject(CostObject1);
        CostObject1.Validate("Line Type", CostObject1."Line Type"::Heading);
        CostObject1.Modify(true);
    end;

    local procedure UpdateCostCenter(var CostCenter: Record "Cost Center")
    begin
        CostCenter.Validate("Line Type", CostCenter."Line Type"::Heading);
        CostCenter.Modify(true);
    end;

    local procedure UpdateCostJournalLine(var CostJournalLine: Record "Cost Journal Line"; CostCenterCode: Code[20]; CostObjectCode: Code[20])
    begin
        CostJournalLine.Validate("Cost Center Code", CostCenterCode);
        CostJournalLine.Validate("Cost Object Code", CostObjectCode);
        CostJournalLine.Validate("Bal. Cost Center Code", CostCenterCode);
        CostJournalLine.Validate("Bal. Cost Object Code", CostObjectCode);
        CostJournalLine.Modify(true);
    end;

    local procedure UpdateCostObject(var CostObject: Record "Cost Object")
    begin
        CostObject.Validate("Line Type", CostObject."Line Type"::Heading);
        CostObject.Modify(true);
    end;

    local procedure UpdateCostRegisterClosed(var CostRegister: Record "Cost Register"; Closed: Boolean)
    begin
        CostRegister.Validate(Closed, Closed);
        CostRegister.Modify();
    end;

    local procedure ValidateCostTypeInsert(InvokeOnInsert: Boolean)
    var
        CostType: Record "Cost Type";
        CostTypeNo: Code[20];
    begin
        // Setup and Exercise
        CostTypeInsert(CostTypeNo, InvokeOnInsert);

        // Verify
        VerifyCostTypeInsert(CostTypeNo);

        if InvokeOnInsert then
            VerifyCostTypeModifiedFields(CostTypeNo, Today, UpperCase(UserId))
        else
            VerifyCostTypeModifiedFields(CostTypeNo, 0D, '');

        // Cleanup
        CostType.Get(CostTypeNo);
        CostType.Delete(true);
    end;

    local procedure ValidateCostTypeModify(InvokeOnModify: Boolean)
    var
        CostType: Record "Cost Type";
        ModifiedBy: Code[50];
        ModifiedDate: Date;
    begin
        // Setup
        CostTypeModifySetup(CostType, ModifiedDate, ModifiedBy, InvokeOnModify);

        // Exercise
        CostType.Validate("New Page", true);
        CostType.Modify(InvokeOnModify);

        // Verify
        CostType.TestField("New Page", true);

        VerifyCostTypeModifiedFields(CostType."No.", ModifiedDate, ModifiedBy);

        // Cleanup
        CostType.Delete();
    end;

    local procedure VerifyCostTypeInsert(CostTypeNo: Code[20])
    var
        CostType: Record "Cost Type";
    begin
        CostType.Get(CostTypeNo);

        CostType.TestField("Search Name", CostType.Name);
        CostType.TestField(Type, CostType.Type::"Cost Type");
        CostType.TestField("G/L Account Range", '');
    end;

    local procedure VerifyCostTypeModifiedFields(CostTypeNo: Code[20]; ModifiedDate: Date; ModifiedBy: Code[50])
    var
        CostType: Record "Cost Type";
    begin
        CostType.Get(CostTypeNo);
        CostType.TestField("Modified Date", ModifiedDate);
        CostType.TestField("Modified By", ModifiedBy);
    end;

    local procedure VerifyCostEntry(GLEntryNo: Integer)
    var
        CostEntry: Record "Cost Entry";
    begin
        CostEntry.SetRange("G/L Entry No.", GLEntryNo);
        Assert.IsTrue(not CostEntry.IsEmpty, StrSubstNo(CostEntryErr, GLEntryNo));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
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
        // dummy message handler
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerChartOfCostCenters(var ChartOfCostCenters: TestPage "Chart of Cost Centers")
    begin
        ChartOfCostCenters.FILTER.SetFilter(Code, CostCenterFilter);
        ChartOfCostCenters.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerChartOfCostObjects(var ChartOfCostObjects: TestPage "Chart of Cost Objects")
    begin
        ChartOfCostObjects.FILTER.SetFilter(Code, CostObjectFilter);
        ChartOfCostObjects.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerCostBudgetNames(var CostBudgetNames: TestPage "Cost Budget Names")
    begin
        CostBudgetNames.FILTER.SetFilter(Name, CostBudgetNameFilter);
        CostBudgetNames.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerCostTypeList(var CostTypeList: TestPage "Cost Type List")
    begin
        CostTypeList.FILTER.SetFilter("No.", CostTypeFilter);
        CostTypeList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerGLAccList(var GLAccList: TestPage "G/L Account List")
    begin
        GLAccList.FILTER.SetFilter("No.", GLAccFilter);
        GLAccList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerGLBudgetNames(var GLBudgetNames: TestPage "G/L Budget Names")
    begin
        GLBudgetNames.FILTER.SetFilter(Name, GLBudgetNameFilter);
        GLBudgetNames.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerInvtPostingGroups(var InvtPostingGroups: TestPage "Inventory Posting Groups")
    begin
        InvtPostingGroups.FILTER.SetFilter(Code, InvtPostingGroupFilter);
        InvtPostingGroups.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerItemList(var ItemList: TestPage "Item List")
    begin
        ItemList.FILTER.SetFilter("No.", ItemFilter);
        ItemList.OK().Invoke();
    end;

    local procedure UpdateCostAccSetupAutoTransferFromGL(AutoTransferFromGL: Boolean)
    var
        CostAccountingSetup: TestPage "Cost Accounting Setup";
    begin
        CostAccountingSetup.OpenEdit();
        CostAccountingSetup."Auto Transfer from G/L".SetValue(AutoTransferFromGL);
        CostAccountingSetup.OK().Invoke();
    end;

    local procedure UpdateCostAccSetupStartingDateForGLTransfer(StartingDateForGLTransfer: Date)
    var
        CostAccountingSetup: TestPage "Cost Accounting Setup";
    begin
        CostAccountingSetup.OpenEdit();
        CostAccountingSetup."Starting Date for G/L Transfer".SetValue(StartingDateForGLTransfer);
        CostAccountingSetup.OK().Invoke();
    end;
}

