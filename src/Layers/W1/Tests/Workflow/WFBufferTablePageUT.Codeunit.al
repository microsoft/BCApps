codeunit 134340 "WF Buffer Table/Page UT"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Workflow Buffer]
    end;

    var
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        QueryClosePageLookupErr: Label 'Select a workflow template to continue, or choose Cancel to close the page.';

    [Test]
    [Scope('OnPrem')]
    procedure TestCategoryLineCreatedWhenInitBuffer()
    var
        Workflow: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
    begin
        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);

        // Exercise
        TempWorkflowBuffer.InitBufferForWorkflows(TempWorkflowBuffer);

        // Verify
        TempWorkflowBuffer.Get(Workflow.Category, '');
        TempWorkflowBuffer.Get(Workflow.Category, Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCategoryLinesCreatedWhenInitBuffer()
    var
        Workflow1: Record Workflow;
        Workflow2: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
        WorkflowCategory: Record "Workflow Category";
    begin
        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow1);
        LibraryWorkflow.CreateWorkflow(Workflow2);

        // Exercise
        TempWorkflowBuffer.InitBufferForWorkflows(TempWorkflowBuffer);

        // Verify
        Assert.AreEqual(4, TempWorkflowBuffer.Count, 'An incorrect number of lines was created in the temp workflow buffer table');

        TempWorkflowBuffer.Get(Workflow1.Category, '');
        WorkflowCategory.Get(Workflow1.Category);
        Assert.AreEqual(WorkflowCategory.Description, TempWorkflowBuffer.Description, 'Wrong category');

        TempWorkflowBuffer.Get(Workflow1.Category, Workflow1.Code);
        Assert.AreEqual(Workflow1.Description, TempWorkflowBuffer.Description, 'Wrong workflow');

        TempWorkflowBuffer.Get(Workflow2.Category, '');
        WorkflowCategory.Get(Workflow2.Category);
        Assert.AreEqual(WorkflowCategory.Description, TempWorkflowBuffer.Description, 'Wrong category');

        TempWorkflowBuffer.Get(Workflow2.Category, Workflow2.Code);
        Assert.AreEqual(Workflow2.Description, TempWorkflowBuffer.Description, 'Wrong workflow');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteAWorkflowFromBufferTable()
    var
        Workflow1: Record Workflow;
        Workflow2: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
    begin
        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow1);
        LibraryWorkflow.CreateWorkflow(Workflow2);
        Workflow2.Category := Workflow1.Category;
        Workflow2.Modify();
        TempWorkflowBuffer.InitBufferForWorkflows(TempWorkflowBuffer);

        // Exercise
        TempWorkflowBuffer.Get(Workflow2.Category, Workflow2.Code);
        TempWorkflowBuffer.Delete(true);

        // Verify
        Assert.IsFalse(TempWorkflowBuffer.IsEmpty, 'Temp Workflow Buffer table is empty');
        Assert.AreEqual(2, TempWorkflowBuffer.Count, 'Temp Workflow Buffer does not have a Workflow and Category record');
        TempWorkflowBuffer.Get(Workflow1.Category, '');
        TempWorkflowBuffer.Get(Workflow1.Category, Workflow1.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteLastWorkflowFromBufferTable()
    var
        Workflow: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
    begin
        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        TempWorkflowBuffer.InitBufferForWorkflows(TempWorkflowBuffer);

        // Exercise
        TempWorkflowBuffer.Get(Workflow.Category, Workflow.Code);
        TempWorkflowBuffer.Delete(true);

        // Verify
        Assert.IsTrue(TempWorkflowBuffer.IsEmpty, 'Temp Workflow Buffer table is not empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteEnabledWorkflowFromBufferTableErr()
    var
        Workflow: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
    begin
        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        Workflow.Enabled := true;
        Workflow.Modify();
        TempWorkflowBuffer.InitBufferForWorkflows(TempWorkflowBuffer);

        // Exercise
        TempWorkflowBuffer.Get(Workflow.Category, Workflow.Code);
        asserterror TempWorkflowBuffer.Delete(true);

        // Verify
        Assert.ExpectedError('Enabled workflows cannot be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteCategoryFromBufferTableNoErr()
    var
        Workflow: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
    begin
        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        TempWorkflowBuffer.InitBufferForWorkflows(TempWorkflowBuffer);

        // Exercise
        ClearLastError();
        TempWorkflowBuffer.Get(Workflow.Category, '');
        asserterror TempWorkflowBuffer.Delete(true);

        // Verify
        Assert.AreEqual(2, TempWorkflowBuffer.Count, 'Temp Workflow Buffer does not have a Workflow and Category record');
        Assert.AreEqual('', GetLastErrorText, 'An unexpected error was thrown');
        TempWorkflowBuffer.Get(Workflow.Category, '');
        TempWorkflowBuffer.Get(Workflow.Category, Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitBufferForTemplates()
    var
        Workflow: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
    begin
        // Setup
        Initialize();
        LibraryWorkflow.CreateTemplateWorkflow(Workflow);

        // Exercise
        TempWorkflowBuffer.InitBufferForTemplates(TempWorkflowBuffer);

        // Verify
        TempWorkflowBuffer.Get(Workflow.Category, '');
        TempWorkflowBuffer.Get(Workflow.Category, Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteTemplateFromBufferNoErr()
    var
        Workflow: Record Workflow;
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
    begin
        // Setup
        Initialize();
        LibraryWorkflow.CreateTemplateWorkflow(Workflow);
        TempWorkflowBuffer.InitBufferForTemplates(TempWorkflowBuffer);

        // Exercise
        ClearLastError();
        TempWorkflowBuffer.Get(Workflow.Category, Workflow.Code);
        asserterror TempWorkflowBuffer.Delete(true);

        // Verify
        Assert.AreEqual(2, TempWorkflowBuffer.Count, 'Temp Workflow Buffer does not have a Workflow and Category record');
        Assert.AreEqual('', GetLastErrorText, 'An unexpected error was thrown');
        TempWorkflowBuffer.Get(Workflow.Category, '');
        TempWorkflowBuffer.Get(Workflow.Category, Workflow.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestViewWorkflowAction()
    var
        Workflow: Record Workflow;
        WorkflowsPage: TestPage Workflows;
        WorkflowPage: TestPage Workflow;
    begin
        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowsPage.OpenView();
        WorkflowsPage.FILTER.SetFilter("Workflow Code", Workflow.Code);
        WorkflowsPage.First();

        // Exercise
        WorkflowPage.Trap();
        WorkflowsPage.ViewAction.Invoke();

        // Verify
        Assert.IsFalse(WorkflowPage.Editable(), 'The view action opened the page in editable mode');
        Assert.AreEqual(Workflow.Code, WorkflowPage.Code.Value, 'The view action opened a wrong record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEditWorkflowAction()
    var
        Workflow: Record Workflow;
        WorkflowsPage: TestPage Workflows;
        WorkflowPage: TestPage Workflow;
    begin
        // Setup
        Initialize();
        SetApplicationArea();
        LibraryWorkflow.CreateWorkflow(Workflow);
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowsPage.OpenView();
        WorkflowsPage.FILTER.SetFilter("Workflow Code", Workflow.Code);
        WorkflowsPage.First();

        // Exercise
        WorkflowPage.Trap();
        WorkflowsPage.EditAction.Invoke();

        // Verify
        Assert.IsTrue(WorkflowPage.Editable(), 'The view action did not open the page in editable mode');
        Assert.AreEqual(Workflow.Code, WorkflowPage.Code.Value, 'The view action opened a wrong record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFirstNewWorkflowAction()
    var
        Workflow: Record Workflow;
        WorkflowsPage: TestPage Workflows;
        WorkflowPage: TestPage Workflow;
        WorkflowCode: Code[20];
    begin
        // Setup
        Initialize();
        SetApplicationArea();
        WorkflowCode := LibraryUtility.GenerateRandomCode(Workflow.FieldNo(Code), DATABASE::Workflow);
        WorkflowsPage.OpenView();

        // Exercise
        WorkflowPage.Trap();
        WorkflowsPage.NewAction.Invoke();

        // Verify
        Assert.IsTrue(WorkflowPage.Editable(), 'The view action did not open the page in editable mode');
        Assert.AreEqual('', WorkflowPage.Code.Value, 'The view action opened a wrong record');

        // Verify create record
        WorkflowPage.Code.SetValue(WorkflowCode);
        WorkflowPage.OK().Invoke();
        Workflow.Get(WorkflowCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewWorkflowAction()
    var
        Workflow: Record Workflow;
        WorkflowsPage: TestPage Workflows;
        WorkflowPage: TestPage Workflow;
        WorkflowCode: Code[20];
    begin
        // Setup
        Initialize();
        SetApplicationArea();
        LibraryWorkflow.CreateWorkflow(Workflow);
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowCode := LibraryUtility.GenerateRandomCode(Workflow.FieldNo(Code), DATABASE::Workflow);
        WorkflowsPage.OpenView();

        // Exercise
        WorkflowPage.Trap();
        WorkflowsPage.NewAction.Invoke();

        // Verify
        Assert.IsTrue(WorkflowPage.Editable(), 'The view action did not open the page in editable mode');
        Assert.AreEqual('', WorkflowPage.Code.Value, 'The view action opened a wrong record');

        // Verify create record
        WorkflowPage.Code.SetValue(WorkflowCode);
        WorkflowPage.OK().Invoke();
        Workflow.Get(WorkflowCode);
    end;

    [Test]
    [HandlerFunctions('WorkflowTemplatePageHandlerLookupOKPass')]
    [Scope('OnPrem')]
    procedure TestWorkflowTemplatesLookup()
    var
        Workflow: Record Workflow;
    begin
        // setup
        Initialize();
        LibraryWorkflow.CreateTemplateWorkflow(Workflow);

        // Exercise
        ClearLastError();
        Clear(Workflow);
        WorkflowTemplateLookup(Workflow);

        // Verify
        Assert.AreNotEqual('', Workflow.Code, 'Lookup did not work');
    end;

    [Test]
    [HandlerFunctions('WorkflowTemplatePageHandlerLookupCancel')]
    [Scope('OnPrem')]
    procedure TestWorkflowTemplatesLookupQueryCloseCancelNoErr()
    var
        Workflow: Record Workflow;
    begin
        // setup
        Initialize();
        LibraryWorkflow.CreateTemplateWorkflow(Workflow);

        // Exercise
        WorkflowTemplateLookup(Workflow);

        // Verify
        Assert.AreEqual('', Workflow.Code, 'Lookup did not work');
    end;

    [Test]
    [HandlerFunctions('WorkflowTemplatePageHandlerLookupOKFail,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestWorkflowTemplatesLookupQueryCloseLookupOKErr()
    var
        Workflow: Record Workflow;
    begin
        // setup
        Initialize();
        LibraryWorkflow.CreateTemplateWorkflow(Workflow);

        // Exercise
        ClearLastError();
        Clear(Workflow);
        WorkflowTemplateLookup(Workflow);

        // Verify
        Assert.ExpectedError(QueryClosePageLookupErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestViewTemplateAction()
    var
        Workflow: Record Workflow;
        WorkflowTemplatesPage: TestPage "Workflow Templates";
        WorkflowPage: TestPage Workflow;
    begin
        // Setup
        Initialize();
        LibraryWorkflow.CreateTemplateWorkflow(Workflow);
        LibraryWorkflow.CreateTemplateWorkflow(Workflow);
        WorkflowTemplatesPage.OpenView();
        WorkflowTemplatesPage.FILTER.SetFilter("Workflow Code", Workflow.Code);
        WorkflowTemplatesPage.First();

        // Exercise
        WorkflowPage.Trap();
        WorkflowTemplatesPage.ViewAction.Invoke();

        // Verify
        Assert.IsFalse(WorkflowPage.Editable(), 'The view action opened the page in editable mode');
        Assert.AreEqual(Workflow.Code, WorkflowPage.Code.Value, 'The view action opened a wrong record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeWorkflowDescription()
    var
        Workflow: Record Workflow;
        WorkflowsPage: TestPage Workflows;
        WorkflowPage: TestPage Workflow;
        NewDescription: Text;
    begin
        // Setup
        Initialize();
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowsPage.OpenView();
        // Place focus to the Workflow
        WorkflowsPage.Last();

        // Exercise
        WorkflowPage.Trap();
        WorkflowsPage.EditAction.Invoke();

        NewDescription := LibraryUtility.GenerateGUID();
        WorkflowPage.Description.SetValue(NewDescription);
        WorkflowPage.OK().Invoke();

        // Verify
        // Move to the catagory line and back to the workflow line.
        // This will activate the update of the line.
        WorkflowsPage.First();
        WorkflowsPage.Last();

        Assert.AreEqual(NewDescription, WorkflowsPage.Description.Value, 'Descrition should get updated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkflowCategoryCodeCannotBeBlank()
    var
        WorkflowCategories: TestPage "Workflow Categories";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 235022] You cannot create Workflow Category with blank Code.
        Initialize();

        WorkflowCategories.OpenNew();
        asserterror WorkflowCategories.Code.SetValue('');

        Assert.ExpectedErrorCode('TestValidation');
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Buffer Table/Page UT");
        Workflow.DeleteAll();
    end;

    local procedure WorkflowTemplateLookup(var Workflow: Record Workflow)
    var
        TempWorkflowBuffer: Record "Workflow Buffer" temporary;
    begin
        if ACTION::LookupOK = PAGE.RunModal(PAGE::"Workflow Templates", TempWorkflowBuffer) then
            Workflow.Get(TempWorkflowBuffer."Workflow Code")
        else
            Clear(Workflow);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkflowTemplatePageHandlerLookupOKPass(var WorkflowTemplatesPage: TestPage "Workflow Templates")
    begin
        WorkflowTemplatesPage.FILTER.SetFilter("Workflow Code", '<>''''');
        WorkflowTemplatesPage.First();
        WorkflowTemplatesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkflowTemplatePageHandlerLookupOKFail(var WorkflowTemplatesPage: TestPage "Workflow Templates")
    begin
        WorkflowTemplatesPage.FILTER.SetFilter("Workflow Code", '');
        WorkflowTemplatesPage.First();
        WorkflowTemplatesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkflowTemplatePageHandlerLookupCancel(var WorkflowTemplatesPage: TestPage "Workflow Templates")
    begin
        WorkflowTemplatesPage.FILTER.SetFilter("Workflow Code", '''''');
        WorkflowTemplatesPage.First();
        WorkflowTemplatesPage.Cancel().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure SetApplicationArea()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        // Set ApplicationArea to Essential since Workflow page is read-only in Basic.
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
    end;
}

