codeunit 135403 "Assembly BOM Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly BOM] [UI] [User Group Plan]
    end;

    var
        Customer: Record Customer;
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryResource: Codeunit "Library - Resource";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        CreateBOMTok: Label 'CREATEBOM', Locked = true;
        ShowBOMTok: Label 'SHOWBOM', Locked = true;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Assembly BOM Plan-based E2E");

        LibraryVariableStorage.Clear();

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        // Lazy Setup
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Assembly BOM Plan-based E2E");

        CreateCustomer();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Assembly BOM Plan-based E2E");
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMPageHandler,BOMStructurePageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyBOMCreateShowStructureAndExplodeAsViralSignup()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ComponentResource: Record Resource;
    begin
        // [E2E] Scenario creating an Item with BOM and showing the structure

        // [GIVEN] Given two Items and one Resource
        // [GIVEN] A user with a Viral Signup Plan
        Initialize();
        CreateParentItemAndComponents(ParentItem, ComponentItem, ComponentResource);

        LibraryE2EPlanPermissions.SetViralSignupPlan();

        // [WHEN] Create a BOM with one of the Item and the Resource as Components
        CreateItemWithBOM(ParentItem, ComponentItem, ComponentResource);
        // [WHEN] Show the BOM structure of the BOM Item
        ShowItemBOMStructure(ParentItem);

        // [THEN] Test suceeds, if no other errors are encountered and all verifications passed.
        VerifyItemBOMComponents(ParentItem, 2);
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMPageHandler,BOMStructurePageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyBOMCreateShowStructureAndExplodeAsBusinessManager()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ComponentResource: Record Resource;
    begin
        // [E2E] Scenario creating an Item with BOM and showing the structure

        // [GIVEN] Given two Items and one Resource
        // [GIVEN] A user with a Business Manager Plan
        Initialize();
        CreateParentItemAndComponents(ParentItem, ComponentItem, ComponentResource);

        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [WHEN] Create a BOM with one of the Item and the Resource as Components
        CreateItemWithBOM(ParentItem, ComponentItem, ComponentResource);
        // [WHEN] Show the BOM structure of the BOM Item
        ShowItemBOMStructure(ParentItem);

        // [THEN] Test suceeds, if no other errors are encountered and all verifications passed.
        VerifyItemBOMComponents(ParentItem, 2);
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMPageHandler,BOMStructurePageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyBOMCreateShowStructureAndExplodeAsExternalAccountant()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ComponentResource: Record Resource;
    begin
        // [E2E] Scenario creating an Item with BOM and showing the structure

        // [GIVEN] Given two Items and one Resource
        // [GIVEN] A user with a External Accountant Plan
        Initialize();
        CreateParentItemAndComponents(ParentItem, ComponentItem, ComponentResource);

        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [WHEN] Create a BOM with one of the Item and the Resource as Components
        CreateItemWithBOM(ParentItem, ComponentItem, ComponentResource);
        // [WHEN] Show the BOM structure of the BOM Item
        ShowItemBOMStructure(ParentItem);

        // [THEN] Test suceeds, if no other errors are encountered and all verifications passed.
        VerifyItemBOMComponents(ParentItem, 2);
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMPageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyBOMCreateShowStructureAndExplodeAsTeamMember()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ComponentResource: Record Resource;
    begin
        // [E2E] Scenario creating an Item with BOM and showing the structure

        // [GIVEN] Given two Items and one Resource
        // [GIVEN] A user with a Team Member Plan
        Initialize();
        CreateParentItemAndComponents(ParentItem, ComponentItem, ComponentResource);

        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [WHEN] Create a BOM with one of the Item and the Resource as Components
        asserterror CreateItemWithBOM(ParentItem, ComponentItem, ComponentResource);

        // [THEN] Test suceeds, if no other errors are encountered and all verifications passed.
        VerifyItemBOMComponents(ParentItem, 0);
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMPageHandler,BOMStructurePageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyBOMCreateShowStructureAndExplodeAsEssentialISVEmbUser()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ComponentResource: Record Resource;
    begin
        // [E2E] Scenario creating an Item with BOM and showing the structure

        // [GIVEN] Given two Items and one Resource
        // [GIVEN] A user with a Essential ISV Emb plan
        Initialize();
        CreateParentItemAndComponents(ParentItem, ComponentItem, ComponentResource);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [WHEN] Create a BOM with one of the Item and the Resource as Components
        CreateItemWithBOM(ParentItem, ComponentItem, ComponentResource);
        // [WHEN] Show the BOM structure of the BOM Item
        ShowItemBOMStructure(ParentItem);

        // [THEN] Test succeeds, if no other errors are encountered and all verifications passed.
        VerifyItemBOMComponents(ParentItem, 2);
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMPageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyBOMCreateShowStructureAndExplodeAsTeamMemberISVEmb()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ComponentResource: Record Resource;
    begin
        // [E2E] Scenario creating an Item with BOM and showing the structure

        // [GIVEN] Given two Items and one Resource
        // [GIVEN] A user with a Team Member ISV Emb Plan
        Initialize();
        CreateParentItemAndComponents(ParentItem, ComponentItem, ComponentResource);

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        // [WHEN] Create a BOM with one of the Item and the Resource as Components
        asserterror CreateItemWithBOM(ParentItem, ComponentItem, ComponentResource);

        // [THEN] Test succeeds, if no other errors are encountered and all verifications passed.
        VerifyItemBOMComponents(ParentItem, 0);
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMPageHandler,BOMStructurePageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyBOMCreateShowStructureAndExplodeAsDeviceISVEmbUser()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ComponentResource: Record Resource;
    begin
        // [E2E] Scenario creating an Item with BOM and showing the structure

        // [GIVEN] Given two Items and one Resource
        // [GIVEN] A user with a Device ISV Emb plan
        Initialize();
        CreateParentItemAndComponents(ParentItem, ComponentItem, ComponentResource);

        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [WHEN] Create a BOM with one of the Item and the Resource as Components
        CreateItemWithBOM(ParentItem, ComponentItem, ComponentResource);
        // [WHEN] Show the BOM structure of the BOM Item
        ShowItemBOMStructure(ParentItem);

        // [THEN] Test succeeds, if no other errors are encountered and all verifications passed.
        VerifyItemBOMComponents(ParentItem, 2);
    end;

    local procedure CreateParentItemAndComponents(var ParentItem: Record Item; var ComponentItem: Record Item; var ComponentResource: Record Resource)
    begin
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(ComponentItem);
        LibraryResource.CreateResourceNew(ComponentResource);
    end;

    local procedure CreateItemWithBOM(ParentItem: Record Item; ComponentItem: Record Item; ComponentResource: Record Resource)
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(ParentItem);
        LibraryVariableStorage.Enqueue(CreateBOMTok);
        LibraryVariableStorage.Enqueue(ComponentItem."No.");
        LibraryVariableStorage.Enqueue(ComponentResource."No.");
        ItemCard."Assembly BOM".Invoke();
    end;

    local procedure ShowItemBOMStructure(ParentItem: Record Item)
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(ParentItem);
        LibraryVariableStorage.Enqueue(ShowBOMTok);
        ItemCard."Assembly BOM".Invoke();
    end;

    local procedure CreateCustomer()
    begin
        LibrarySales.CreateCustomer(Customer);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AssemblyBOMPageHandler(var AssemblyBOM: TestPage "Assembly BOM")
    var
        BOMComponent: Record "BOM Component";
    begin
        case LibraryVariableStorage.DequeueText() of
            CreateBOMTok:
                begin
                    AssemblyBOM.Type.SetValue(BOMComponent.Type::Item);
                    AssemblyBOM."No.".SetValue(LibraryVariableStorage.DequeueText());
                    AssemblyBOM."Quantity per".SetValue(LibraryRandom.RandIntInRange(1, 100));
                    AssemblyBOM.Next();
                    AssemblyBOM.Type.SetValue(BOMComponent.Type::Resource);
                    AssemblyBOM."No.".SetValue(LibraryVariableStorage.DequeueText());
                    AssemblyBOM."Quantity per".SetValue(LibraryRandom.RandIntInRange(1, 100));
                    AssemblyBOM.OK().Invoke();
                end;
            ShowBOMTok:
                begin
                    AssemblyBOM."Show BOM".Invoke();
                    AssemblyBOM.OK().Invoke();
                end;
        end;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMStructurePageHandler(var BOMStructure: TestPage "BOM Structure")
    begin
        BOMStructure.Close();
    end;

    local procedure VerifyItemBOMComponents(Item: Record Item; ComponentCount: Integer)
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.SetRange("Parent Item No.", Item."No.");
        Assert.RecordCount(BOMComponent, ComponentCount);
    end;
}

