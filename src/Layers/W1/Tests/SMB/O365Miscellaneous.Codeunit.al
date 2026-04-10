codeunit 138017 "O365 Miscellaneous"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [SMB]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTemplates: Codeunit "Library - Templates";
        GenProductPostingGroup_Code: Code[10];
        FieldShouldBeVisibleErr: Label 'Field should be visible in On-prem installation';
        FieldVisibleSuiteAreaErr: Label 'Field must be visible for #Suite Application Area.';
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmQuestion')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure DefVatProdPostingGroupOnValidate_GLAcc()
    var
        GLAcc: Record "G/L Account";
    begin
        // Setup
        Initialize();

        GLAcc.Init();
        GLAcc."Gen. Prod. Posting Group" := GenProductPostingGroup_Code;
        GLAcc.Insert();

        GetOnValidateTrigger(GenProductPostingGroup_Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmQuestion')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure DefVatProdPostingGroupOnValidate_Item()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();

        Item.Init();
        Item."Gen. Prod. Posting Group" := GenProductPostingGroup_Code;
        Item.Insert();

        GetOnValidateTrigger(GenProductPostingGroup_Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmQuestion')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure DefVatProdPostingGroupOnValidate_Res()
    var
        Res: Record Resource;
    begin
        // Setup
        Initialize();

        Res.Init();
        Res."Gen. Prod. Posting Group" := GenProductPostingGroup_Code;
        Res.Insert();

        GetOnValidateTrigger(GenProductPostingGroup_Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmQuestion')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure DefVatProdPostingGroupOnValidate_ItemCharge()
    var
        ItemCharge: Record "Item Charge";
    begin
        // Setup
        Initialize();

        ItemCharge.Init();
        ItemCharge."Gen. Prod. Posting Group" := GenProductPostingGroup_Code;
        ItemCharge.Insert();

        GetOnValidateTrigger(GenProductPostingGroup_Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultCostingMethodIsAssignedForNewItems()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        ItemNo: Code[20];
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.AddO365INVSetup();

        InventorySetup.Get();
        InventorySetup."Default Costing Method" := InventorySetup."Default Costing Method"::Standard;
        InventorySetup.Modify(true);

        // Exercise
        LibraryLowerPermissions.SetItemEdit();
        ItemCard.OpenNew();
        ItemCard.Description.Activate();
        ItemNo := ItemCard."No.".Value();
        ItemCard.Close();

        // Verify
        Item.Get(ItemNo);
        Item.TestField("Costing Method", InventorySetup."Default Costing Method");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecificCostCannotBeSetWithoutItemTrackingInFoundation()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetItemEdit();
        Item.Init();
        Item.Insert(true);

        // Execute
        asserterror SetCostingMethodOnItemCard(Item, Item."Costing Method"::Specific);

        // Verify
        Assert.ExpectedError(GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostingMethodLIFOCanBeAssignedOnItemCardInFoundation()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetItemEdit();
        Item.Init();
        Item.Insert(true);

        // Execute
        SetCostingMethodOnItemCard(Item, Item."Costing Method"::LIFO);

        // Verify
        Item.Find();
        Item.TestField("Costing Method", Item."Costing Method"::LIFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostingMethodSpecificCanBeAssignedOnItemCardInFoundation()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();
        Item.Init();
        Item.Insert(true);

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify(true);

        // Execute
        SetCostingMethodOnItemCard(Item, Item."Costing Method"::Specific);

        // Verify
        Item.Find();
        Item.TestField("Costing Method", Item."Costing Method"::Specific);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostingMethodAverageCanBeAssignedOnItemCardInFoundation()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetItemEdit();
        Item.Init();
        Item.Insert(true);

        // Execute
        SetCostingMethodOnItemCard(Item, Item."Costing Method"::Average);

        // Verify
        Item.Find();
        Item.TestField("Costing Method", Item."Costing Method"::Average);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostingMethodStandardCanBeAssignedOnItemCardInFoundation()
    var
        Item: Record Item;
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetItemEdit();
        Item.Init();
        Item.Insert(true);

        // Execute
        SetCostingMethodOnItemCard(Item, Item."Costing Method"::Standard);

        // Verify
        Item.Find();
        Item.TestField("Costing Method", Item."Costing Method"::Standard);
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure CompaniesPageEvaluationCompanyVisibleSaaSClient()
    var
        Companies: TestPage Companies;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 256466] 'Evaluation Company' field is visible for SaaS client
        Initialize();

        Companies.OpenView();
        Assert.IsTrue(Companies."Evaluation Company".Visible(), '');
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure CompaniesPageEvaluationCompanyNotVisibleOnPremClient()
    var
        Companies: TestPage Companies;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 256466] 'Evaluation Company' field is not visible for OnPrem client
        LibraryApplicationArea.DeleteExistingFoundationSetup();

        Companies.OpenView();
        Assert.IsFalse(Companies."Evaluation Company".Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemCardTypeFieldVisibleOnPrem()
    var
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Item] [UI] [UT]
        // [SCENARIO 257573] Field "Type" in the item card should be visible in On-Prem installation

        LibraryLowerPermissions.SetItemView();
        LibraryApplicationArea.DeleteExistingFoundationSetup();

        ItemCard.OpenView();
        Assert.IsTrue(ItemCard.Type.Visible(), FieldShouldBeVisibleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedCostPostingGLFieldVisibleInSuiteAppArea()
    var
        InventorySetup: TestPage "Inventory Setup";
    begin
        // [FEATURE] [Item] [UI] [UT]
        // [SCENARIO 260810] "Expected Cost Posting to G/L" checkbox in Inventory Setup must be enabled for #Suite

        Initialize();

        LibraryLowerPermissions.SetO365INVSetup();
        InventorySetup.OpenView();

        Assert.IsTrue(InventorySetup."Expected Cost Posting to G/L".Visible(), FieldVisibleSuiteAreaErr);

        InventorySetup.Close();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Miscellaneous");
        LibraryApplicationArea.EnableFoundationSetup();

        ClearTables();
        GenProductPostingGroup_Code := 'New Line';
        PrepareVatProductPostingGroup();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Miscellaneous");
        LibraryTemplates.EnableTemplatesFeature();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Miscellaneous");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmQuestion(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    local procedure SetCostingMethodOnItemCard(var Item: Record Item; CostingMethodOption: Enum "Costing Method")
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard."Costing Method".SetValue(CostingMethodOption);
        ItemCard.Close();
    end;

    local procedure ClearTables()
    var
        GLAcc: Record "G/L Account";
        Item: Record Item;
        Res: Record Resource;
        ItemCharge: Record "Item Charge";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        ItemTempl: Record "Item Templ.";
    begin
        GLAcc.DeleteAll();
        Item.DeleteAll();
        Res.DeleteAll();
        ItemCharge.DeleteAll();
        GenProductPostingGroup.DeleteAll();
        ItemTempl.DeleteAll(true);
    end;

    local procedure PrepareVatProductPostingGroup()
    var
        VatProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VatProductPostingGroup.DeleteAll();
        VatProductPostingGroup.Code := 'A';
        VatProductPostingGroup.Insert();
    end;

    local procedure GetOnValidateTrigger(GenProductPostingGroup_Code: Code[10])
    var
        GenProductPostingGroupsPage: TestPage "Gen. Product Posting Groups";
    begin
        GenProductPostingGroupsPage.OpenNew();
        GenProductPostingGroupsPage.Code.Value := GenProductPostingGroup_Code;
        GenProductPostingGroupsPage."Def. VAT Prod. Posting Group".Value := 'A';
        GenProductPostingGroupsPage.Close();
    end;
}

