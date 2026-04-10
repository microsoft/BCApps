codeunit 134307 "Workflow Cond. Eval. Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Condition]
    end;

    var
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowManagement: Codeunit "Workflow Management";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        AmountCondXmlTemplateTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Purch. Inv. Event Conditions" id="1502"><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.) WHERE(Amount=FILTER(%1))</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.)</DataItem></DataItems></ReportParameters>', Locked = true;
        VendorNameCondXmlTemplateTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Purch. Inv. Event Conditions" id="1502"><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.) WHERE(Buy-from Vendor Name=FILTER(%1))</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.)</DataItem></DataItems></ReportParameters>', Locked = true;
        VendorNameLocCodeCondXmlTemplateTxt: Label '<?xml version="1.0" standalone="yes"?><ReportParameters name="Purch. Inv. Event Conditions" id="1502"><DataItems><DataItem name="Purchase Header">SORTING(Document Type,No.)</DataItem><DataItem name="Purchase Line">SORTING(Document Type,Document No.,Line No.) WHERE(Location Code=FILTER(%1))</DataItem><DataItem name="Vendor">SORTING(No.) WHERE(Country/Region Code=FILTER(%2))</DataItem></DataItems></ReportParameters>', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure WorkflowInstanceIsCreatedOnlyIfCondOnEntryPointIsMet()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowStepInstance: Record "Workflow Step Instance";
        PurchaseHeader: Record "Purchase Header";
        DifferentPurchaseHeader: Record "Purchase Header";
        Found: Boolean;
        EntryPointEventStep: Integer;
    begin
        // [SCENARIO 1] When a Condition is set on the entry point step, an instance of the
        // workflow is created only if the condition evaluates to true.
        // [GIVEN] Workflow is set up with the entry point event with a condition on vendor name.
        // [WHEN] The Workflow step is executed with the different vendor namecondition.
        // [THEN] The Workflow instance is NOT created.
        // [WHEN] The Workflow step is executed with the same vendor name on the condition.
        // [THEN] The Workflow instance is created.
        Initialize();

        // Setup
        CreatePurchaseInvoice(PurchaseHeader);
        CreatePurchaseInvoice(DifferentPurchaseHeader);

        // Setup - Workflow Types
        CreateAnyPurchaseHeaderEvent(WorkflowEvent);

        // Setup  - Workflow
        LibraryWorkflow.CreateWorkflow(Workflow);
        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent."Function Name");

        LibraryWorkflow.InsertEventArgument(EntryPointEventStep,
          StrSubstNo(VendorNameCondXmlTemplateTxt, PurchaseHeader."Buy-from Vendor Name"));

        EnableWorkflow(Workflow);

        // Exercise - On different purchaseheader
        Found :=
          WorkflowManagement.FindWorkflowStepInstance(DifferentPurchaseHeader, DifferentPurchaseHeader,
            WorkflowStepInstance, WorkflowEvent."Function Name");

        // Verify - Instance not created
        Assert.IsFalse(Found, 'Active Workflow step should not be found');

        // Exercise - On purchaseheader meeting condition
        Found := WorkflowManagement.FindWorkflowStepInstance(PurchaseHeader, PurchaseHeader,
            WorkflowStepInstance, WorkflowEvent."Function Name");

        // Verify - Instance created
        Assert.IsTrue(Found, 'Active Workflow step should be found');
        Assert.AreEqual(Workflow.Code, WorkflowStepInstance."Original Workflow Code", 'Unexpected workflow');
        Assert.AreEqual(EntryPointEventStep, WorkflowStepInstance."Original Workflow Step ID", 'Unexpected workflow step');
        Assert.AreEqual(WorkflowStepInstance.Status::Inactive, WorkflowStepInstance.Status,
          'State should be inactive as workflow is just created');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkflowStepIsExecutedOnlyIfConditionIsMet()
    var
        Workflow: Record Workflow;
        EntryWorkflowEvent: Record "Workflow Event";
        CondWorkflowEvent: Record "Workflow Event";
        WorkflowStepInstance: Record "Workflow Step Instance";
        PurchaseHeader: Record "Purchase Header";
        DifferentPurchaseHeader: Record "Purchase Header";
        Found: Boolean;
        EntryPointEventStep: Integer;
        EventStep2: Integer;
    begin
        // [SCENARIO 2] When a Condition is set on the workflow step, the
        // workflow step is executed only if the condition evaluates to true.
        // [GIVEN] Workflow is set up with the workflow step event with a condition on vendor name.
        // [WHEN] The Workflow step is executed with the different vendor namecondition.
        // [THEN] The Workflow instance is NOT found.
        // [WHEN] The Workflow step is executed with the same vendor name on the condition.
        // [THEN] The Workflow instance is found.
        Initialize();

        // Setup
        CreatePurchaseInvoice(PurchaseHeader);
        DifferentPurchaseHeader.SetRange("VAT Bus. Posting Group", PurchaseHeader."VAT Bus. Posting Group");
        CreatePurchaseInvoice(DifferentPurchaseHeader);

        // Setup - Workflow Types
        CreateAnyPurchaseHeaderEvent(EntryWorkflowEvent);
        CreateAnyPurchaseHeaderEvent(CondWorkflowEvent);

        // Setup  - Workflow
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EntryWorkflowEvent."Function Name");
        EventStep2 := LibraryWorkflow.InsertEventStep(Workflow, CondWorkflowEvent."Function Name", EntryPointEventStep);

        LibraryWorkflow.InsertEventArgument(EventStep2,
          StrSubstNo(VendorNameCondXmlTemplateTxt, PurchaseHeader."Buy-from Vendor Name"));

        EnableWorkflow(Workflow);

        // Setup - Run the first event (any purchaseheader will work here)
        WorkflowManagement.FindWorkflowStepInstance(PurchaseHeader, PurchaseHeader,
          WorkflowStepInstance, EntryWorkflowEvent."Function Name");
        WorkflowStepInstance.MoveForward(PurchaseHeader);

        // Exercise - On different purchaseheader
        Found :=
          WorkflowManagement.FindWorkflowStepInstance(DifferentPurchaseHeader, DifferentPurchaseHeader,
            WorkflowStepInstance, CondWorkflowEvent."Function Name");

        // Verify - Instance not created
        Assert.IsFalse(Found, 'Active Workflow step should not be found');

        // Exercise - On purchaseheader meeting condition
        Found := WorkflowManagement.FindWorkflowStepInstance(PurchaseHeader, PurchaseHeader,
            WorkflowStepInstance, CondWorkflowEvent."Function Name");

        // Verify - Instance created
        Assert.IsTrue(Found, 'Active Workflow step should be found');
        Assert.AreEqual(Workflow.Code, WorkflowStepInstance."Original Workflow Code", 'Unexpected workflow');
        Assert.AreEqual(EventStep2, WorkflowStepInstance."Original Workflow Step ID", 'Unexpected workflow step');
        Assert.AreEqual(WorkflowStepInstance.Status::Active, WorkflowStepInstance.Status, 'State should be active');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkflowInstanceIsCreatedOnlyIfCondOnEntryPointIsMetFlowfield()
    var
        Workflow: Record Workflow;
        WorkflowEvent: Record "Workflow Event";
        WorkflowStepInstance: Record "Workflow Step Instance";
        AmountPurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ZeroAmountPurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Found: Boolean;
        EntryPointEventStep: Integer;
    begin
        // [SCENARIO 3] When a Condition is set on the flowfield on entry point step, an instance of the
        // workflow is created only if the condition evaluates to true.
        // [GIVEN] Workflow is set up with the entry point event with a condition on amount.
        // [WHEN] The Workflow step is executed with a amount = 0.
        // [THEN] The Workflow instance is NOT created.
        // [WHEN] The Workflow step is executed with a amount > 100 on the condition.
        // [THEN] The Workflow instance is created.
        Initialize();

        // Setup
        CreatePurchaseInvoiceWithRelatedRecords(AmountPurchaseHeader, PurchaseLine, Vendor);
        PurchaseLine.Validate("Direct Unit Cost", 50);
        PurchaseLine.Modify();
        ZeroAmountPurchaseHeader.SetRange("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        CreatePurchaseInvoice(ZeroAmountPurchaseHeader);

        // Setup - Workflow Types
        CreateAnyPurchaseHeaderEvent(WorkflowEvent);

        // Setup  - Workflow
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent."Function Name");

        LibraryWorkflow.InsertEventArgument(EntryPointEventStep, StrSubstNo(AmountCondXmlTemplateTxt, '&gt;100'));

        EnableWorkflow(Workflow);

        // Exercise - On different purchaseheader
        Found :=
          WorkflowManagement.FindWorkflowStepInstance(ZeroAmountPurchaseHeader, ZeroAmountPurchaseHeader,
            WorkflowStepInstance, WorkflowEvent."Function Name");

        // Verify - Instance not created
        Assert.IsFalse(Found, 'Active Workflow step should not be found');

        // Exercise - On purchaseheader meeting condition
        Found := WorkflowManagement.FindWorkflowStepInstance(AmountPurchaseHeader, AmountPurchaseHeader,
            WorkflowStepInstance, WorkflowEvent."Function Name");

        // Verify - Instance created
        Assert.IsTrue(Found, 'Active Workflow step should be found');
        Assert.AreEqual(Workflow.Code, WorkflowStepInstance."Original Workflow Code", 'Unexpected workflow');
        Assert.AreEqual(EntryPointEventStep, WorkflowStepInstance."Original Workflow Step ID", 'Unexpected workflow step');
        Assert.AreEqual(WorkflowStepInstance.Status::Inactive, WorkflowStepInstance.Status,
          'State should be inactive as workflow is just created');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure WorkflowStepIsExecutedOnlyIfConditionIsMetComplexFilter()
    var
        Workflow: Record Workflow;
        EntryWorkflowEvent: Record "Workflow Event";
        CondWorkflowEvent: Record "Workflow Event";
        WorkflowStepInstance: Record "Workflow Step Instance";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DifferentPurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Found: Boolean;
        EntryPointEventStep: Integer;
        EventStep2: Integer;
    begin
        // [SCENARIO 4] When a Condition is set on the workflow step, the
        // workflow step is executed only if the complex condition evaluates to true.
        // [GIVEN] Workflow is set up with the workflow step event with a condition on line and vendor fields.
        // [WHEN] The Workflow step is executed with the relational fields not matching.
        // [THEN] The Workflow instance is NOT found.
        // [WHEN] The Workflow step is executed with the relational fields matching the condition.
        // [THEN] The Workflow instance is found.
        Initialize();

        // Setup
        CreatePurchaseInvoiceWithRelatedRecords(PurchaseHeader, PurchaseLine, Vendor);
        DifferentPurchaseHeader.SetRange("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        CreatePurchaseInvoice(DifferentPurchaseHeader);

        // Setup - Workflow Types
        CreateAnyPurchaseHeaderEvent(EntryWorkflowEvent);
        CreateAnyPurchaseHeaderEvent(CondWorkflowEvent);
        CreateWorkflowTableRelations();

        // Setup  - Workflow
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EntryWorkflowEvent."Function Name");
        EventStep2 := LibraryWorkflow.InsertEventStep(Workflow, CondWorkflowEvent."Function Name", EntryPointEventStep);

        LibraryWorkflow.InsertEventArgument(EventStep2,
          StrSubstNo(VendorNameLocCodeCondXmlTemplateTxt, PurchaseLine."Location Code", Vendor."Country/Region Code"));

        EnableWorkflow(Workflow);

        // Setup - Run the first event (any purchaseheader will work here)
        WorkflowManagement.FindWorkflowStepInstance(PurchaseHeader, PurchaseHeader,
          WorkflowStepInstance, EntryWorkflowEvent."Function Name");
        WorkflowStepInstance.MoveForward(PurchaseHeader);

        // Exercise - On different purchaseheader
        Found :=
          WorkflowManagement.FindWorkflowStepInstance(DifferentPurchaseHeader, DifferentPurchaseHeader,
            WorkflowStepInstance, CondWorkflowEvent."Function Name");

        // Verify - Instance not created
        Assert.IsFalse(Found, 'Active Workflow step should not be found');

        // Exercise - On purchaseheader meeting condition
        Found := WorkflowManagement.FindWorkflowStepInstance(PurchaseHeader, PurchaseHeader,
            WorkflowStepInstance, CondWorkflowEvent."Function Name");

        // Verify - Instance created
        Assert.IsTrue(Found, 'Active Workflow step should be found');
        Assert.AreEqual(Workflow.Code, WorkflowStepInstance."Original Workflow Code", 'Unexpected workflow');
        Assert.AreEqual(EventStep2, WorkflowStepInstance."Original Workflow Step ID", 'Unexpected workflow step');
        Assert.AreEqual(WorkflowStepInstance.Status::Active, WorkflowStepInstance.Status, 'State should be active');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectBranchIsSelectedAfterConditionEvaluation()
    var
        Workflow: Record Workflow;
        EntryWorkflowEvent: Record "Workflow Event";
        CondWorkflowEvent: Record "Workflow Event";
        WorkflowStepInstance: Record "Workflow Step Instance";
        PurchaseHeader: Record "Purchase Header";
        Found: Boolean;
        EntryPointEventStep: Integer;
        EventStep2: Integer;
        EventStep3: Integer;
    begin
        // [SCENARIO 5] When there are multiple branches with different conditions set on them, the execution picks up the right
        // workflow step.
        // [GIVEN] Workflow with multiple branches having different conditions set, one random vendor name and the other
        // vendor name matching the condition.
        // [WHEN] Code to find the workflow step is executed.
        // [THEN] The vendor name matched workflow step is selected.
        Initialize();

        // Setup
        CreatePurchaseInvoice(PurchaseHeader);

        // Setup - Workflow Types
        CreateAnyPurchaseHeaderEvent(EntryWorkflowEvent);
        CreateAnyPurchaseHeaderEvent(CondWorkflowEvent);

        // Setup - Workflow Types
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EntryWorkflowEvent."Function Name");
        EventStep2 := LibraryWorkflow.InsertEventStep(Workflow, CondWorkflowEvent."Function Name", EntryPointEventStep);

        LibraryWorkflow.InsertEventArgument(EventStep2,
          StrSubstNo(VendorNameCondXmlTemplateTxt, LibraryUtility.GenerateRandomXMLText(10)));

        EventStep3 := LibraryWorkflow.InsertEventStep(Workflow, CondWorkflowEvent."Function Name", EntryPointEventStep);

        LibraryWorkflow.InsertEventArgument(EventStep3, StrSubstNo(VendorNameCondXmlTemplateTxt, PurchaseHeader."Buy-from Vendor Name"));

        EnableWorkflow(Workflow);

        // Setup - Run the first event (any purchaseheader will work here)
        WorkflowManagement.FindWorkflowStepInstance(PurchaseHeader, PurchaseHeader,
          WorkflowStepInstance, EntryWorkflowEvent."Function Name");
        WorkflowStepInstance.MoveForward(PurchaseHeader);

        // Exercise
        Found := WorkflowManagement.FindWorkflowStepInstance(PurchaseHeader, PurchaseHeader,
            WorkflowStepInstance, CondWorkflowEvent."Function Name");

        // Verify
        Assert.IsTrue(Found, 'Active Workflow step should be found');
        Assert.AreEqual(Workflow.Code, WorkflowStepInstance."Original Workflow Code", 'Unexpected workflow');
        Assert.AreEqual(EventStep3, WorkflowStepInstance."Original Workflow Step ID", 'Unexpected workflow step');
        Assert.AreEqual(WorkflowStepInstance.Status::Active, WorkflowStepInstance.Status, 'State should be active');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectBranchIsSelectedAfterConditionEvaluationRespectingStepOrder()
    var
        Workflow: Record Workflow;
        EntryWorkflowEvent: Record "Workflow Event";
        CondWorkflowEvent: Record "Workflow Event";
        WorkflowStepInstance: Record "Workflow Step Instance";
        PurchaseHeader: Record "Purchase Header";
        Found: Boolean;
        EntryPointEventStep: Integer;
        EventStep2: Integer;
        EventStep3: Integer;
    begin
        // [SCENARIO 5] When there are multiple branches with different conditions set on them, the execution picks up the right
        // workflow step.
        // [GIVEN] Workflow with multiple branches having different conditions one amount < 100 and the other amount < 1000.
        // [WHEN] Code to find the workflow step is executed.
        // [THEN] The Correct workflow step, as both fufill the codition the workflow step with lowest order will be selected.
        Initialize();
        // Setup
        CreatePurchaseInvoice(PurchaseHeader);

        // Setup - Workflow Types
        CreateAnyPurchaseHeaderEvent(EntryWorkflowEvent);
        CreateAnyPurchaseHeaderEvent(CondWorkflowEvent);

        // Setup - Workflow Types
        LibraryWorkflow.CreateWorkflow(Workflow);

        EntryPointEventStep := LibraryWorkflow.InsertEntryPointEventStep(Workflow, EntryWorkflowEvent."Function Name");
        EventStep3 := LibraryWorkflow.InsertEventStep(Workflow, CondWorkflowEvent."Function Name", EntryPointEventStep);
        EventStep2 := LibraryWorkflow.InsertEventStep(Workflow, CondWorkflowEvent."Function Name", EntryPointEventStep);

        LibraryWorkflow.InsertEventArgument(EventStep2, StrSubstNo(AmountCondXmlTemplateTxt, '&lt;100'));
        LibraryWorkflow.InsertEventArgument(EventStep3, StrSubstNo(AmountCondXmlTemplateTxt, '&lt;1000'));

        EnableWorkflow(Workflow);

        // Setup - Run the first event (any purchaseheader will work here)
        WorkflowManagement.FindWorkflowStepInstance(PurchaseHeader, PurchaseHeader,
          WorkflowStepInstance, EntryWorkflowEvent."Function Name");
        WorkflowStepInstance.MoveForward(PurchaseHeader);

        // Exercise
        Found := WorkflowManagement.FindWorkflowStepInstance(PurchaseHeader, PurchaseHeader,
            WorkflowStepInstance, CondWorkflowEvent."Function Name");

        // Verify
        Assert.IsTrue(Found, 'Active Workflow step should be found');
        Assert.AreEqual(Workflow.Code, WorkflowStepInstance."Original Workflow Code", 'Unexpected workflow');
        Assert.AreEqual(EventStep3, WorkflowStepInstance."Original Workflow Step ID", 'Unexpected workflow step');
        Assert.AreEqual(WorkflowStepInstance.Status::Active, WorkflowStepInstance.Status, 'State should be active');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Workflow Cond. Eval. Tests");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Workflow Cond. Eval. Tests");

        LibraryERMCountryData.CreateVATData();

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Workflow Cond. Eval. Tests");
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.CopyFilter("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", '', 0);
    end;

    local procedure CreatePurchaseInvoiceWithRelatedRecords(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var Vendor: Record Vendor)
    var
        Location: Record Location;
        CountryRegion: Record "Country/Region";
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryWarehouse.CreateLocation(Location);
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        Vendor.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Country/Region Code" := CountryRegion.Code;
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 3);
        PurchaseLine."Location Code" := Location.Code;
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAnyPurchaseHeaderEvent(var WorkflowEvent: Record "Workflow Event")
    begin
        WorkflowEvent.Init();
        WorkflowEvent."Function Name" := LibraryUtility.GenerateGUID();
        WorkflowEvent.Description := LibraryUtility.GenerateGUID();
        WorkflowEvent."Table ID" := DATABASE::"Purchase Header";
        WorkflowEvent."Request Page ID" := REPORT::"Workflow Event Simple Args";
        WorkflowEvent.Insert(true);
    end;

    local procedure CreateWorkflowTableRelations()
    var
        WorkflowTableRelation: Record "Workflow - Table Relation";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("Document Type"), DATABASE::"Purchase Line", PurchaseLine.FieldNo("Document Type"));
        LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("No."), DATABASE::"Purchase Line", PurchaseLine.FieldNo("Document No."));
        LibraryWorkflow.CreateWorkflowTableRelation(WorkflowTableRelation, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("Buy-from Vendor No."), DATABASE::Vendor, Vendor.FieldNo("No."));
    end;

    local procedure EnableWorkflow(Workflow: Record Workflow)
    begin
        Workflow.Enabled := true;
        Workflow.Modify(true);
    end;
}

