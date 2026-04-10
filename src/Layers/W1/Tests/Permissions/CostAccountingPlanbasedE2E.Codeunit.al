codeunit 135410 "Cost Accounting Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions] [Cost Accounting Setup] [Cost Accounting Setup] [UI] [User Group Plan]
    end;

    var
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        AdmTok: Label 'ADM', Locked = true;
        SalesTok: Label 'SALES', Locked = true;
        ProdTok: Label 'PROD', Locked = true;
        Main1Tok: Label 'MAIN1', Locked = true;
        Main2Tok: Label 'MAIN2', Locked = true;
        Alloc1Tok: Label 'ALLOC1', Locked = true;
        Alloc2Tok: Label 'ALLOC2', Locked = true;
        Alloc3Tok: Label 'ALLOC3', Locked = true;
        RevenueCostTypeTxt: Label 'REVENUE';
        CogsCostTypeTxt: Label 'COGS';
        ExpensesCostTypeTxt: Label 'EXPENSES';
        NetIncomeCostTypeTxt: Label 'Net Income';
        AllocationAccountCostTypeTxt: Label 'Allocation Account';
        DepartmentTok: Label 'DEPARTMENT', Locked = true;
        CustomerGroupTok: Label 'CUSTOMERGROUP', Locked = true;
        CostCenterOneEntryTxt: Label 'Cost Center shoud contain at least one entry';
        RevenueCostTypeID: Integer;
        CogsCostTypeID: Integer;
        ExpensesCostTypeID: Integer;
        NetIncomeCostTypeID: Integer;
        AllocationCostTypeID: Integer;

    [Test]
    [HandlerFunctions('UpdateCostAcctgDimensionsModalHandlerPage,ConfirmHandlerYes,MessageHandler,CostAllocationModalHandlerPage')]
    [Scope('OnPrem')]
    procedure UsingCostAccountingAsBusinessManager()
    var
        ChartofCostTypes: TestPage "Chart of Cost Types";
    begin
        // [SCENARIO] Setup and use Cost Accounting as Business Manager
        Initialize();

        // [GIVEN] The Business Manager plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [WHEN] Setup up Cost Accounting and invoking CostAccountingSetup.UpdateCostAcctgDimensions
        SetupCostAccounting();

        // [WHEN] Create Cost types and register them by
        CreateCostTypes();
        ChartofCostTypes.OpenEdit();
        ChartofCostTypes.RegCostTypeInChartOfCostType.Invoke();

        // [WHEN] Create Cost Centers
        CreateCostCenters();

        // [WHEN] Create Cost Allocations
        CreateCostAllocations();

        // [WHEN] Create General Journal Lines and post them
        CreateGeneralJournalLines();
        Commit();

        // [WHEN] Invoking CostAllocationSources."Report Cost Allocation".INVOKE (which runs the report)
        REPORT.Run(REPORT::"Cost Allocation");

        // [THEN] Verify that the Cost Centers MAIN1 and MAIN2 have Net Change that is not 0,
        // but ADM,SALES and PROD, all have 0 Net Change
        VerifyCostAllocation();
    end;

    [Test]
    [HandlerFunctions('UpdateCostAcctgDimensionsModalHandlerPage,ConfirmHandlerYes,MessageHandler,CostAllocationModalHandlerPage')]
    [Scope('OnPrem')]
    procedure UsingCostAccountingAsAccountant()
    var
        ChartofCostTypes: TestPage "Chart of Cost Types";
    begin
        // [SCENARIO] Setup and use Cost Accounting as Accountant
        Initialize();

        // [GIVEN] The External Accountant plan
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [WHEN] Setup up Cost Accounting and invoking CostAccountingSetup.UpdateCostAcctgDimensions
        SetupCostAccounting();

        // [WHEN] Create Cost types and register them by
        CreateCostTypes();
        ChartofCostTypes.OpenEdit();
        ChartofCostTypes.RegCostTypeInChartOfCostType.Invoke();

        // [WHEN] Create Cost Centers
        CreateCostCenters();

        // [WHEN] Create Cost Allocations
        CreateCostAllocations();

        // [WHEN] Create General Journal Lines and post them
        CreateGeneralJournalLines();
        Commit();

        // [WHEN] Invoking CostAllocationSources."Report Cost Allocation".INVOKE (which runs the report)
        REPORT.Run(REPORT::"Cost Allocation");

        // [THEN] Verify that the Cost Centers MAIN1 and MAIN2 have Net Change that is not 0,
        // but ADM,SALES and PROD, all have 0 Net Change
        VerifyCostAllocation();
    end;

    [Test]
    [HandlerFunctions('UpdateCostAcctgDimensionsModalHandlerPage,ConfirmHandlerYes,CostAllocationModalHandlerPage')]
    [Scope('OnPrem')]
    procedure UsingCostAccountingAsTeamMember()
    begin
        // [SCENARIO] Setup and use Cost Accounting as Team Member
        Initialize();

        // [GIVEN] The Team Member plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [WHEN] Setup up Cost Accounting and invoking CostAccountingSetup.UpdateCostAcctgDimensions
        SetupCostAccounting();

        // [WHEN] Create Cost types and register them by
        asserterror CreateCostTypes();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        // [WHEN] Create Cost Centers
        asserterror CreateCostCenters();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        // [WHEN] Create Cost Allocations
        asserterror CreateCostAllocations();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        // [WHEN] Create General Journal Lines and post them
        asserterror CreateGeneralJournalLines();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        // [WHEN] Invoking CostAllocationSources."Report Cost Allocation".INVOKE (which runs the report)
        asserterror REPORT.Run(REPORT::"Cost Allocation");
        Assert.ExpectedError('No entries have been created for the selected allocations');

        // [THEN] Nothing succeeded, so nothing to verify.
    end;

    [Test]
    [HandlerFunctions('UpdateCostAcctgDimensionsModalHandlerPage,ConfirmHandlerYes,MessageHandler,CostAllocationModalHandlerPage')]
    [Scope('OnPrem')]
    procedure UsingCostAccountingAsEssentialISVEmb()
    var
        ChartofCostTypes: TestPage "Chart of Cost Types";
    begin
        // [SCENARIO] Setup and use Cost Accounting as Essential ISV Emb User
        Initialize();

        // [GIVEN] The Essential ISV Emb plan
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [WHEN] Setup up Cost Accounting and invoking CostAccountingSetup.UpdateCostAcctgDimensions
        SetupCostAccounting();

        // [WHEN] Create Cost types and register them by
        CreateCostTypes();
        ChartofCostTypes.OpenEdit();
        ChartofCostTypes.RegCostTypeInChartOfCostType.Invoke();

        // [WHEN] Create Cost Centers
        CreateCostCenters();

        // [WHEN] Create Cost Allocations
        CreateCostAllocations();

        // [WHEN] Create General Journal Lines and post them
        CreateGeneralJournalLines();
        Commit();

        // [WHEN] Invoking CostAllocationSources."Report Cost Allocation".INVOKE (which runs the report)
        REPORT.Run(REPORT::"Cost Allocation");

        // [THEN] Verify that the Cost Centers MAIN1 and MAIN2 have Net Change that is not 0,
        // but ADM,SALES and PROD, all have 0 Net Change
        VerifyCostAllocation();
    end;

    [Test]
    [HandlerFunctions('UpdateCostAcctgDimensionsModalHandlerPage,ConfirmHandlerYes,CostAllocationModalHandlerPage')]
    [Scope('OnPrem')]
    procedure UsingCostAccountingAsTeamMemberISVEmb()
    begin
        // [SCENARIO] Setup and use Cost Accounting as Team Member ISV Emb
        Initialize();

        // [GIVEN] The Team Member ISV Emb plan
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        // [WHEN] Setup up Cost Accounting and invoking CostAccountingSetup.UpdateCostAcctgDimensions
        SetupCostAccounting();

        // [WHEN] Create Cost types and register them by
        asserterror CreateCostTypes();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        // [WHEN] Create Cost Centers
        asserterror CreateCostCenters();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        // [WHEN] Create Cost Allocations
        asserterror CreateCostAllocations();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        // [WHEN] Create General Journal Lines and post them
        asserterror CreateGeneralJournalLines();
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        // [WHEN] Invoking CostAllocationSources."Report Cost Allocation".INVOKE (which runs the report)
        asserterror REPORT.Run(REPORT::"Cost Allocation");
        Assert.ExpectedError('No entries have been created for the selected allocations');

        // [THEN] Nothing succeeded, so nothing to verify.
    end;

    [Test]
    [HandlerFunctions('UpdateCostAcctgDimensionsModalHandlerPage,ConfirmHandlerYes,MessageHandler,CostAllocationModalHandlerPage')]
    [Scope('OnPrem')]
    procedure UsingCostAccountingAsDeviceISVEmb()
    var
        ChartofCostTypes: TestPage "Chart of Cost Types";
    begin
        // [SCENARIO] Setup and use Cost Accounting as Device ISV Emb User
        Initialize();

        // [GIVEN] The Device ISV Emb plan
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [WHEN] Setup up Cost Accounting and invoking CostAccountingSetup.UpdateCostAcctgDimensions
        SetupCostAccounting();

        // [WHEN] Create Cost types and register them by
        CreateCostTypes();
        ChartofCostTypes.OpenEdit();
        ChartofCostTypes.RegCostTypeInChartOfCostType.Invoke();

        // [WHEN] Create Cost Centers
        CreateCostCenters();

        // [WHEN] Create Cost Allocations
        CreateCostAllocations();

        // [WHEN] Create General Journal Lines and post them
        CreateGeneralJournalLines();
        Commit();

        // [WHEN] Invoking CostAllocationSources."Report Cost Allocation".INVOKE (which runs the report)
        REPORT.Run(REPORT::"Cost Allocation");

        // [THEN] Verify that the Cost Centers MAIN1 and MAIN2 have Net Change that is not 0,
        // but ADM,SALES and PROD, all have 0 Net Change
        VerifyCostAllocation();
    end;

    local procedure Initialize()
    var
        CostCenter: Record "Cost Center";
        CostType: Record "Cost Type";
        CostRegister: Record "Cost Register";
        CostAllocationSource: Record "Cost Allocation Source";
        CostEntry: Record "Cost Entry";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Cost Accounting Plan-based E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        CostRegister.DeleteAll();
        CostType.DeleteAll();
        CostCenter.DeleteAll();
        CostEntry.DeleteAll();
        CostAllocationSource.DeleteAll();
        Commit();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Cost Accounting Plan-based E2E");

        RevenueCostTypeID := 10000;
        CogsCostTypeID := 20000;
        ExpensesCostTypeID := 30000;
        NetIncomeCostTypeID := 90000;
        AllocationCostTypeID := 97000;

        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Cost Accounting Plan-based E2E");
    end;

    local procedure SetupCostAccounting()
    var
        CostAccountingSetup: TestPage "Cost Accounting Setup";
        StartingDateForGLTransfer: Date;
    begin
        StartingDateForGLTransfer := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
        CostAccountingSetup.OpenEdit();
        CostAccountingSetup."Starting Date for G/L Transfer".SetValue(StartingDateForGLTransfer);
        CostAccountingSetup."Auto Transfer from G/L".SetValue(true);
        Commit();
        // Invoking CostAccountingSetup.UpdateCostAcctgDimensions"
        REPORT.RunModal(REPORT::"Update Cost Acctg. Dimensions");
        CostAccountingSetup.Close();
    end;

    local procedure CreateCostType(CostTypeNo: Integer; CostTypeName: Text[50]; GLAccountRange: Text[20]; CostType: Enum "Cost Account Type")
    var
        CostTypeCard: TestPage "Cost Type Card";
    begin
        CostTypeCard.OpenNew();
        CostTypeCard."No.".SetValue(CostTypeNo);
        CostTypeCard.Name.SetValue(CostTypeName);
        CostTypeCard."G/L Account Range".SetValue(GLAccountRange);
        CostTypeCard.Type.SetValue(CostType);
        CostTypeCard.OK().Invoke();
    end;

    local procedure CreateCostTypes()
    var
        CostType: Record "Cost Type";
        GLAccount: Record "G/L Account";
    begin
        CreateCostType(RevenueCostTypeID, RevenueCostTypeTxt,
          SelectGLAccountNo(GLAccount."Account Category"::Income, GLAccount."Gen. Posting Type"::Sale),
          CostType.Type::"Cost Type");
        CreateCostType(CogsCostTypeID, CogsCostTypeTxt,
          SelectGLAccountNo(GLAccount."Account Category"::"Cost of Goods Sold", GLAccount."Gen. Posting Type"::Sale),
          CostType.Type::"Cost Type");
        CreateCostType(ExpensesCostTypeID,
          ExpensesCostTypeTxt, SelectGLAccountNo(GLAccount."Account Category"::Expense, GLAccount."Gen. Posting Type"::Purchase),
          CostType.Type::"Cost Type");
        CreateCostType(NetIncomeCostTypeID, NetIncomeCostTypeTxt,
          StrSubstNo('%1..%2', RevenueCostTypeID, ExpensesCostTypeID), CostType.Type::Total);
        CreateCostType(AllocationCostTypeID, AllocationAccountCostTypeTxt, '', CostType.Type::"Cost Type");
    end;

    local procedure CreateCostCenter("Code": Code[10]; Name: Text[50]; SortingOrder: Integer; CostSubtype: Enum "Cost Center Subtype")
    var
        CostCenterCard: TestPage "Cost Center Card";
    begin
        CostCenterCard.OpenNew();
        CostCenterCard.Code.SetValue(Code);
        CostCenterCard.Name.SetValue(Name);
        CostCenterCard."Sorting Order".SetValue(SortingOrder);
        CostCenterCard."Cost Subtype".SetValue(CostSubtype);
        CostCenterCard.OK().Invoke();
    end;

    local procedure CreateCostCenters()
    var
        CostCenter: Record "Cost Center";
    begin
        CreateCostCenter(AdmTok, AdmTok, 1, CostCenter."Cost Subtype"::" ");
        CreateCostCenter(SalesTok, SalesTok, 2, CostCenter."Cost Subtype"::" ");
        CreateCostCenter(ProdTok, ProdTok, 3, CostCenter."Cost Subtype"::" ");
        CreateCostCenter(Main1Tok, Main1Tok, 4, CostCenter."Cost Subtype"::"Main Cost Center");
        CreateCostCenter(Main2Tok, Main2Tok, 5, CostCenter."Cost Subtype"::"Main Cost Center");
    end;

    local procedure CreateCostAllocation("Code": Code[10]; Level: Integer; CostCenterCode: Code[10]; CreditToCostType: Integer; TargetCostType: Integer; Share1: Integer; Share2: Integer)
    var
        CostAllocation: TestPage "Cost Allocation";
    begin
        CostAllocation.OpenNew();
        CostAllocation.ID.SetValue(Code);
        CostAllocation.Level.SetValue(Level);
        CostAllocation."Cost Center Code".SetValue(CostCenterCode);
        CostAllocation."Credit to Cost Type".SetValue(CreditToCostType);

        CostAllocation.AllocTarget.New();
        CostAllocation.AllocTarget."Target Cost Type".SetValue(TargetCostType);
        CostAllocation.AllocTarget."Target Cost Center".SetValue(Main1Tok);
        CostAllocation.AllocTarget.Share.SetValue(Share1);

        CostAllocation.AllocTarget.New();
        CostAllocation.AllocTarget."Target Cost Type".SetValue(TargetCostType);
        CostAllocation.AllocTarget."Target Cost Center".SetValue(Main2Tok);
        CostAllocation.AllocTarget.Share.SetValue(Share2);

        CostAllocation.OK().Invoke();
    end;

    local procedure CreateCostAllocations()
    begin
        CreateCostAllocation(Alloc1Tok, 1, AdmTok, AllocationCostTypeID, ExpensesCostTypeID, 55, 45);
        CreateCostAllocation(Alloc2Tok, 2, SalesTok, AllocationCostTypeID, RevenueCostTypeID, 80, 20);
        CreateCostAllocation(Alloc3Tok, 3, ProdTok, AllocationCostTypeID, CogsCostTypeID, 15, 85);
    end;

    local procedure CreateGeneralJournalLine(GenJournalBatch: Record "Gen. Journal Batch"; GLAccountNo: Code[20]; BalGLAccountNo: Code[20]; DepartmentCode: Code[20]; Amount: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account",
          GLAccountNo, GenJournalLine."Bal. Account Type"::"G/L Account", BalGLAccountNo, Amount);
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DepartmentCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        GLBalAccountNo: Code[20];
        Amount: Integer;
    begin
        LibraryERM.SelectLastGenJnBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        GLBalAccountNo := SelectGLAccountNo(GLAccount."Account Category"::Assets, GLAccount."Gen. Posting Type"::Sale);
        Amount := LibraryRandom.RandIntInRange(1000, 10000);
        CreateGeneralJournalLine(GenJournalBatch,
          SelectGLAccountNo(GLAccount."Account Category"::Income, GLAccount."Gen. Posting Type"::Sale),
          GLBalAccountNo, SalesTok, Amount);
        CreateGeneralJournalLine(GenJournalBatch,
          SelectGLAccountNo(GLAccount."Account Category"::"Cost of Goods Sold", GLAccount."Gen. Posting Type"::Sale),
          GLBalAccountNo, ProdTok, Amount * 2);
        CreateGeneralJournalLine(GenJournalBatch,
          SelectGLAccountNo(GLAccount."Account Category"::Expense, GLAccount."Gen. Posting Type"::Purchase),
          GLBalAccountNo, AdmTok, Amount * 3);
    end;

    local procedure SelectGLAccountNo(AccountCategory: Enum "G/L Account Category"; GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.SetFilter("Account Category", Format(AccountCategory));
        GLAccount.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GLAccount.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GLAccount.SetFilter("Gen. Posting Type", Format(GenPostingType));
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        if GLAccount.FindFirst() then
            exit(GLAccount."No.");

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.SetGLAccountDirectPostingFilter(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("Account Category", AccountCategory);
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure VerifyCostAllocation()
    var
        ChartofCostCenters: TestPage "Chart of Cost Centers";
    begin
        ChartofCostCenters.OpenView();
        // Assert ADM,SALES,PROD do NOT have Net Change allocated to them
        ChartofCostCenters.FILTER.SetFilter(Code, AdmTok);
        Assert.IsTrue(ChartofCostCenters.First(), CostCenterOneEntryTxt);
        Assert.AreEqual('', ChartofCostCenters."Net Change".Value, StrSubstNo('%1 Cost Center must be empty in Net Change', AdmTok));
        ChartofCostCenters.FILTER.SetFilter(Code, SalesTok);
        Assert.IsTrue(ChartofCostCenters.First(), CostCenterOneEntryTxt);
        Assert.AreEqual('', ChartofCostCenters."Net Change".Value, StrSubstNo('%1 Cost Center must be empty in Net Change', SalesTok));
        ChartofCostCenters.FILTER.SetFilter(Code, ProdTok);
        Assert.IsTrue(ChartofCostCenters.First(), CostCenterOneEntryTxt);
        Assert.AreEqual('', ChartofCostCenters."Net Change".Value, StrSubstNo('%1 Cost Center must be empty in Net Change', ProdTok));

        // Assert Main1 and Main2 do have Net Change allocated to them
        ChartofCostCenters.FILTER.SetFilter(Code, Main1Tok);
        Assert.IsTrue(ChartofCostCenters.First(), CostCenterOneEntryTxt);
        Assert.AreNotEqual('', ChartofCostCenters."Net Change".Value,
          StrSubstNo('%1 Cost Center must have a non-zero value in Net Change', Main1Tok));
        ChartofCostCenters.FILTER.SetFilter(Code, Main2Tok);
        Assert.IsTrue(ChartofCostCenters.First(), CostCenterOneEntryTxt);
        Assert.AreNotEqual('', ChartofCostCenters."Net Change".Value,
          StrSubstNo('%1 Cost Center must have a non-zero value in Net Change', Main2Tok));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateCostAcctgDimensionsModalHandlerPage(var UpdateCostAcctgDimensions: TestRequestPage "Update Cost Acctg. Dimensions")
    begin
        UpdateCostAcctgDimensions.CostCenterDimension.SetValue(DepartmentTok);
        UpdateCostAcctgDimensions.CostObjectDimension.SetValue(CustomerGroupTok);
        UpdateCostAcctgDimensions.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostAllocationModalHandlerPage(var CostAllocation: TestRequestPage "Cost Allocation")
    begin
        CostAllocation.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}

