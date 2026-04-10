codeunit 134208 "Workflow Imp./Exp. Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow]
    end;

    var
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
    begin
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();

        UserSetup.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSingleWorkflow()
    var
        Workflow: Record Workflow;
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO] Test that a single workflow can be exported.
        // [GIVEN] A workflow that needs to be exported.
        // [WHEN] The export action is called.
        // [THEN] An xml file is created to contains the workflow details.

        // Setup - Create a Workflow
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());

        // Excercise - Export the Workflow
        Workflow.SetRecFilter();
        Workflow.ExportToBlob(TempBlob);

        // Verify
        VerifyWorkflows(Workflow, TempBlob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleWorkflows()
    var
        Workflow: Record Workflow;
        Workflow1: Record Workflow;
        Workflow2: Record Workflow;
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO] Test that more than one workflow can be exported at a time.
        // [GIVEN] Workflows that needs to be exported.
        // [WHEN] The export action is called.
        // [THEN] An xml file is created to contains the details of all the selected workflows.

        // Setup - Create 2 Workflows
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow1, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(Workflow2, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());

        // Excercise - Export the selected workflows
        Workflow.SetFilter(Code, '%1|%2', Workflow1.Code, Workflow2.Code);
        Workflow.ExportToBlob(TempBlob);

        // Verify
        VerifyWorkflows(Workflow, TempBlob);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ImportSingleWorkflow()
    var
        Workflow: Record Workflow;
        TempBlob: Codeunit "Temp Blob";
        WorkflowCode: Code[20];
    begin
        // [SCENARIO] Test that a workflow can be imported.
        // [GIVEN] An xml file that contains the workflow definition.
        // [WHEN] The import action is called.
        // [THEN] The xml file is imported and the workflow is created.

        // Setup - Create a Workflow and export it to a file
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
        WorkflowCode := Workflow.Code;
        Workflow.SetRecFilter();
        Workflow.ExportToBlob(TempBlob);
        Workflow.DeleteAll(true);

        // Excercise
        asserterror Workflow.Get(WorkflowCode);
        Workflow.ImportFromBlob(TempBlob);

        // Verify that the workflow is created
        CheckWorkflowStepsAreEqual(WorkflowCode, 'MS-' + WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ImportMultipleWorkflows()
    var
        Workflow: Record Workflow;
        Workflow1: Record Workflow;
        Workflow2: Record Workflow;
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO] Test that multiple workflows can be imported.
        // [GIVEN] An xml file that contains multiple workflow definition.
        // [WHEN] The import action is called.
        // [THEN] The xml file is imported and the workflows are created.

        // Setup - Create a Workflow and export it to a file
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow1, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(Workflow2, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
        Workflow.SetFilter(Code, '%1|%2', Workflow1.Code, Workflow2.Code);
        Workflow.ExportToBlob(TempBlob);
        Workflow.DeleteAll(true);

        // Excercise
        asserterror Workflow.Get(Workflow1.Code);
        asserterror Workflow.Get(Workflow2.Code);
        Workflow.ImportFromBlob(TempBlob);

        // Verify
        CheckWorkflowStepsAreEqual(Workflow1.Code, 'MS-' + WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        CheckWorkflowStepsAreEqual(Workflow2.Code, 'MS-' + WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ReplaceWorkflowWithSteps()
    var
        Workflow: Record Workflow;
        TempBlob: Codeunit "Temp Blob";
        WorkflowImpExpMgt: Codeunit "Workflow Imp. / Exp. Mgt";
        WorkflowCode: Code[20];
    begin
        // [SCENARIO] Test that replacing a workflow that has steps shows a confirmation message.
        // [GIVEN] An xml file that contains the workflow definition.
        // [WHEN] The import action is called.
        // [THEN] The xml file is imported and the current workflow name and description is saved.

        // Setup - Create a Workflow and export it to a file
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
        WorkflowCode := Workflow.Code;
        Workflow.SetRecFilter();
        Workflow.ExportToBlob(TempBlob);

        // Excercise
        WorkflowImpExpMgt.ReplaceWorkflow(Workflow, TempBlob);

        // Verify that the workflow is created
        CheckWorkflowStepsAreEqual(WorkflowCode, 'MS-' + WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ReplaceWorkflowWithWithoutSteps()
    var
        Workflow: Record Workflow;
        TempBlob: Codeunit "Temp Blob";
        WorkflowImpExpMgt: Codeunit "Workflow Imp. / Exp. Mgt";
        WorkflowCode: Code[20];
    begin
        // [SCENARIO] Test that replacing a workflow that does not have steps does not confirm and the import is successful.
        // [GIVEN] An xml file that contains the workflow definition.
        // [WHEN] The import action is called.
        // [THEN] The xml file is imported and the workflow and workflow steps are created.

        // Setup - Create a Workflow and export it to a file
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
        Workflow.SetRecFilter();
        Workflow.ExportToBlob(TempBlob);
        Workflow.DeleteAll(true);
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkflowCode := Workflow.Code;

        // Excercise
        WorkflowImpExpMgt.ReplaceWorkflow(Workflow, TempBlob);

        // Verify that the workflow is created
        CheckWorkflowStepsAreEqual(WorkflowCode, 'MS-' + WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ReplaceMultipleWorkflowsThrowsError()
    var
        Workflow: Record Workflow;
        Workflow1: Record Workflow;
        Workflow2: Record Workflow;
        TempBlob: Codeunit "Temp Blob";
        WorkflowImpExpMgt: Codeunit "Workflow Imp. / Exp. Mgt";
    begin
        // [SCENARIO] Test that trying to replace a workflow by importing an xml that has multiple workflows
        // throws an error.
        // [GIVEN] An xml file that contains the workflow definition.
        // [WHEN] The import action is called.
        // [THEN] The xml file is imported and the workflow is created.

        // Setup - Create a Workflow and export it to a file
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow1, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(Workflow2, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        Workflow.SetFilter(Code, '%1|%2', Workflow1.Code, Workflow2.Code);
        Workflow.ExportToBlob(TempBlob);
        Workflow.DeleteAll(true);
        LibraryWorkflow.CreateWorkflow(Workflow);

        // Excercise
        asserterror WorkflowImpExpMgt.ReplaceWorkflow(Workflow, TempBlob);

        // Verify that the workflow is created
        Assert.ExpectedError('You cannot import more than one workflow.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ExportImportWorkflowWithApproverUserID()
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [UT] [User Setup]
        // [SCENARIO 304701] Workflow with Specific Approver exported and imported when User Setup contains User ID for Specific Approver
        Initialize();

        // [GIVEN] User Setup for "User"
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);

        // [GIVEN] Workflow with setup for Specific Approver assigned to "User"
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        LibraryWorkflow.SetWorkflowSpecificApprover(Workflow.Code, UserSetup."User ID");

        // [GIVEN] Workflow exported and deleted from database
        Workflow.SetRecFilter();
        Workflow.ExportToBlob(TempBlob);
        Workflow.Delete(true);

        // [WHEN] Workflow imported to database
        Workflow.ImportFromBlob(TempBlob);

        // [THEN] Workflow contains setup for Specific Approver assigned to "User"
        LibraryWorkflow.FindWorkflowStepForCreateApprovalRequests(WorkflowStep, Workflow.Code);
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.TestField("Approver Type", WorkflowStepArgument."Approver Type"::Approver);
        WorkflowStepArgument.TestField("Approver Limit Type", WorkflowStepArgument."Approver Limit Type"::"Specific Approver");
        WorkflowStepArgument.TestField("Approver User ID", UserSetup."User ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ExportImportWorkflowWithNonExistingApproverUserID()
    var
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [UT] [User Setup]
        // [SCENARIO 304701] Workflow with Specific Approver exported and imported when User Setup does not contain User ID for Specific Approver
        Initialize();

        // [GIVEN] User Setup for "User"
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);

        // [GIVEN] Workflow with setup for Specific Approver assigned to "User"
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        LibraryWorkflow.SetWorkflowSpecificApprover(Workflow.Code, UserSetup."User ID");

        // [GIVEN] Workflow exported and deleted from database
        Workflow.SetRecFilter();
        Workflow.ExportToBlob(TempBlob);
        Workflow.Delete(true);

        // [GIVEN] User Setup deleted.
        UserSetup.Delete();

        // [WHEN] Workflow imported to database
        Workflow.ImportFromBlob(TempBlob);

        // [THEN] Workflow contains setup for Specific Approver but not assigned to any user
        LibraryWorkflow.FindWorkflowStepForCreateApprovalRequests(WorkflowStep, Workflow.Code);
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.TestField("Approver Type", WorkflowStepArgument."Approver Type"::Approver);
        WorkflowStepArgument.TestField("Approver Limit Type", WorkflowStepArgument."Approver Limit Type"::"Specific Approver");
        WorkflowStepArgument.TestField("Approver User ID", '');
    end;

    [Test]
    procedure ImportWorkflowWithEmptyCode();
    var
        Workflow: Record Workflow;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 309205] Workflow XML file with empty Workflow Code is not imported with error
        Initialize();

        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(
            '<?xml version="1.0" encoding="UTF-8" standalone="no"?><Root><Workflow Code="" Category=""></Workflow></Root>');

        asserterror Workflow.ImportFromBlob(TempBlob);
        Assert.ExpectedError('The file could not be imported because a blank Workflow Code tag was found in the file.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ExportImportWorkflowWithSendingNotification1()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO][Bug 525946] Test that when exporting a workflow: 
        // If "Notify Sender" set as true and "Notification Entry Type" is not default value, they should also be exported to the xml.
        // When import the workflow, all the configurations should be imported correctly.
        // Otherwise when user import, they will be incorrect.

        // [GIVEN] Create a Workflow
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseBlanketOrderApprovalWorkflowCode());
        // [GIVEN] Find the step that creates approval requests
        LibraryWorkflow.FindWorkflowStepForCreateApprovalRequests(WorkflowStep, Workflow.Code);
        WorkflowStep.Get(Workflow.Code, WorkflowStep.ID);
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        // [GIVEN] Set the "Notify Sender" of the found step to true
        WorkflowStepArgument.Validate("Notify Sender", true);
        // [GIVEN] Set the "Notification Entry Type" of the found step to "Approval"
        WorkflowStepArgument.Validate("Notification Entry Type", WorkflowStepArgument."Notification Entry Type"::Approval);
        // [GIVEN] Set the "Link Target Page" of the found step to "Customer List"
        WorkflowStepArgument.Validate("Link Target Page", Page::"Customer List");
        // [GIVEN] Set the "Custom Link" of a test link
        WorkflowStepArgument.Validate("Custom Link", 'https://www.example.com');
        WorkflowStepArgument.Modify();

        // [GIVEN] Workflow exported and deleted from database
        Workflow.SetRecFilter();
        Workflow.ExportToBlob(TempBlob);
        Workflow.Delete(true);

        // [WHEN] Workflow imported to database
        Workflow.ImportFromBlob(TempBlob);

        // [THEN] Workflow contains all the setup from the exported workflow
        LibraryWorkflow.FindWorkflowStepForCreateApprovalRequests(WorkflowStep, Workflow.Code);
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.TestField("Notify Sender", true);
        WorkflowStepArgument.TestField("Notification Entry Type", WorkflowStepArgument."Notification Entry Type"::Approval);
        WorkflowStepArgument.TestField("Link Target Page", Page::"Customer List");
        WorkflowStepArgument.TestField("Custom Link", 'https://www.example.com');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ExportImportWorkflowWithSendingNotification2()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        TempBlob: Codeunit "Temp Blob";
        UserIDLbl: Label 'User01';
    begin
        // [SCENARIO][Bug 525946] Test that when exporting a workflow:
        // If "Notify Sender" set as false, "Recipient User ID" is set and "Notification Entry Type" is not default value, they should also be exported to the xml. 
        // When import the workflow, all the configurations should be imported correctly.
        // Otherwise when user import, they will be incorrect.

        // [GIVEN] Create a Workflow and a user setup
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseBlanketOrderApprovalWorkflowCode());
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserIDLbl, '');

        // [GIVEN] Find the step that creates approval requests
        LibraryWorkflow.FindWorkflowStepForCreateApprovalRequests(WorkflowStep, Workflow.Code);
        WorkflowStep.Get(Workflow.Code, WorkflowStep.ID);
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        // [GIVEN] Set the "Notify Sender" of the found step to false
        WorkflowStepArgument.Validate("Notify Sender", false);
        // [GIVEN] Set the "Notification User ID" of the found step to "User01"
        WorkflowStepArgument.Validate("Notification User ID", UserIDLbl);
        // [GIVEN] Set the "Notification Entry Type" of the found step to "Approval"
        WorkflowStepArgument.Validate("Notification Entry Type", WorkflowStepArgument."Notification Entry Type"::Approval);
        // [GIVEN] Set the "Link Target Page" of the found step to "Customer List"
        WorkflowStepArgument.Validate("Link Target Page", Page::"Customer List");
        // [GIVEN] Set the "Custom Link" of a test link
        WorkflowStepArgument.Validate("Custom Link", 'https://www.example.com');
        WorkflowStepArgument.Modify();

        // [GIVEN] Workflow exported and deleted from database
        Workflow.SetRecFilter();
        Workflow.ExportToBlob(TempBlob);
        Workflow.Delete(true);

        // [WHEN] Workflow imported to database
        Workflow.ImportFromBlob(TempBlob);

        // [THEN] Workflow contains all the setup from the exported workflow
        LibraryWorkflow.FindWorkflowStepForCreateApprovalRequests(WorkflowStep, Workflow.Code);
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.TestField("Notify Sender", false);
        WorkflowStepArgument.TestField("Notification User ID", UserIDLbl);
        WorkflowStepArgument.TestField("Notification Entry Type", WorkflowStepArgument."Notification Entry Type"::Approval);
        WorkflowStepArgument.TestField("Link Target Page", Page::"Customer List");
        WorkflowStepArgument.TestField("Custom Link", 'https://www.example.com');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure ImportWorkflowWithNotificationUserID()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        UserSetup: Record "User Setup";
        TempBlob: Codeunit "Temp Blob";
        InvalidUserIDLbl: Label 'InvalidUserID';
    begin
        // [SCENARIO][Bug 525946] Test that when exporting a workflow:
        // If "Notify Sender" set as false, "Recipient User ID" is set with a valid value for company A, they should also be exported to the xml. 
        // But when import the workflow, if the "Recipient User ID" is not found in the User Setup for company B, it should be empty.
        // Otherwise when user import, they will be incorrect.

        // [GIVEN] Create a Workflow and the User Setup. But the User Setup will be removed after the workflow is exported. 
        Initialize();
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseBlanketOrderApprovalWorkflowCode());
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, InvalidUserIDLbl, '');

        // [GIVEN] Find the step that creates approval requests
        LibraryWorkflow.FindWorkflowStepForCreateApprovalRequests(WorkflowStep, Workflow.Code);
        WorkflowStep.Get(Workflow.Code, WorkflowStep.ID);
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        // [GIVEN] Set the "Notify Sender" of the found step to false
        WorkflowStepArgument.Validate("Notify Sender", false);
        // [GIVEN] Set the "Notification User ID" of the found step to "Invalid"
        WorkflowStepArgument."Notification User ID" := InvalidUserIDLbl;
        WorkflowStepArgument.Modify();

        // [GIVEN] Workflow exported and deleted from database
        Workflow.SetRecFilter();
        Workflow.ExportToBlob(TempBlob);
        Workflow.Delete(true);
        // [GIVEN] User Setup deleted.
        UserSetup.Delete(true);

        // [WHEN] Workflow imported to database
        Workflow.ImportFromBlob(TempBlob);

        // [THEN] Workflow contains all the setup from the exported workflow
        LibraryWorkflow.FindWorkflowStepForCreateApprovalRequests(WorkflowStep, Workflow.Code);
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.TestField("Notify Sender", false);
        WorkflowStepArgument.TestField("Notification User ID", '');
    end;

    local procedure VerifyWorkflows(var Workflow: Record Workflow; var TempBlob: Codeunit "Temp Blob")
    var
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        NodeList: DotNet XmlNodeList;
        Node: DotNet XmlNode;
        NodeIndex: Integer;
    begin
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, '');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/Root/Workflow', Workflow.Count);
        LibraryXPathXMLReader.GetNodeList('/Root/Workflow', NodeList);

        NodeIndex := 0;
        if Workflow.FindSet() then
            repeat
                Node := NodeList.Item(NodeIndex);
                NodeIndex += 1;
                VerifyWorkflow(Workflow, Node);
            until Workflow.Next() = 0;
    end;

    local procedure VerifyWorkflow(Workflow: Record Workflow; CurrNode: DotNet XmlNode)
    var
        WorkflowStep: Record "Workflow Step";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        NodeList: DotNet XmlNodeList;
        Node: DotNet XmlNode;
        NodeIndex: Integer;
    begin
        LibraryXPathXMLReader.VerifyAttributeFromNode(CurrNode, Workflow.FieldName(Code), Workflow.Code);
        LibraryXPathXMLReader.VerifyAttributeFromNode(CurrNode, Workflow.FieldName(Description), Workflow.Description);
        LibraryXPathXMLReader.VerifyAttributeAbsenceFromNode(CurrNode, Workflow.FieldName(Enabled));
        LibraryXPathXMLReader.VerifyAttributeFromNode(CurrNode, Workflow.FieldName(Category), Workflow.Category);

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.GetNodeListInCurrNode(CurrNode, './/WorkflowStep', NodeList);
        Assert.AreEqual(WorkflowStep.Count, NodeList.Count, 'Expected number of workflow steps not found.');
        NodeIndex := 0;
        if WorkflowStep.FindSet() then
            repeat
                Node := NodeList.Item(NodeIndex);
                NodeIndex += 1;
                VerifyWorkflowStep(WorkflowStep, Node);
            until WorkflowStep.Next() = 0;
    end;

    local procedure VerifyWorkflowStep(WorkflowStep: Record "Workflow Step"; CurrNode: DotNet XmlNode)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowRule: Record "Workflow Rule";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        NodeList: DotNet XmlNodeList;
        Node: DotNet XmlNode;
        NodeIndex: Integer;
    begin
        LibraryXPathXMLReader.VerifyAttributeFromNode(CurrNode, 'StepID', Format(WorkflowStep.ID));
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'StepDescription', WorkflowStep.Description);
        if WorkflowStep."Entry Point" then
            LibraryXPathXMLReader.VerifyAttributeFromNode(CurrNode, 'EntryPoint', Format(WorkflowStep."Entry Point", 0, 2))
        else
            LibraryXPathXMLReader.VerifyAttributeAbsenceFromNode(CurrNode, 'EntryPoint');
        LibraryXPathXMLReader.VerifyAttributeFromNode(CurrNode, 'PreviousStepID', Format(WorkflowStep."Previous Workflow Step ID"));
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'NextStepID', Format(WorkflowStep."Next Workflow Step ID"));
        LibraryXPathXMLReader.VerifyAttributeFromNode(CurrNode, 'Type', Format(WorkflowStep.Type, 0, 2));
        LibraryXPathXMLReader.VerifyAttributeFromNode(CurrNode, 'FunctionName', WorkflowStep."Function Name");
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'SequenceNo', Format(WorkflowStep."Sequence No."));

        if not IsNullGuid(WorkflowStep.Argument) then begin
            WorkflowStepArgument.Get(WorkflowStep.Argument);
            LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
            LibraryXPathXMLReader.GetElementInCurrNode(CurrNode, 'WorkflowStepArgument', Node);
            VerifyWorkflowStepArgument(WorkflowStepArgument, Node);
        end;

        WorkflowRule.SetRange("Workflow Code", WorkflowStep."Workflow Code");
        WorkflowRule.SetRange("Workflow Step ID", WorkflowStep.ID);
        NodeIndex := 0;
        if WorkflowRule.FindSet() then begin
            LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
            LibraryXPathXMLReader.GetNodeListInCurrNode(CurrNode, '/Root/Workflow/WorkflowStep/WorkflowRule', NodeList);
            repeat
                Node := NodeList.Item(NodeIndex);
                NodeIndex += 1;
                VerifyWorkflowStepRule(WorkflowRule, Node);
            until WorkflowRule.Next() = 0;
        end;
    end;

    local procedure VerifyWorkflowStepArgument(WorkflowStepArgument: Record "Workflow Step Argument"; CurrNode: DotNet XmlNode)
    var
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
    begin
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'GeneralJournalTemplateName',
          WorkflowStepArgument."General Journal Template Name");
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'GeneralJournalBatchName',
          WorkflowStepArgument."General Journal Batch Name");
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'NotificationUserID',
          WorkflowStepArgument."Notification User ID");
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'ResponseFunctionName',
          WorkflowStepArgument."Response Function Name");
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'LinkTargetPage',
          Format(WorkflowStepArgument."Link Target Page"));
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'CustomLink',
          WorkflowStepArgument."Custom Link");
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'ApproverType',
          Format(WorkflowStepArgument."Approver Type", 0, 2));
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'ApproverLimitType',
          Format(WorkflowStepArgument."Approver Limit Type", 0, 2));
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'WorkflowUserGroupCode',
          WorkflowStepArgument."Workflow User Group Code");
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'DueDateFormula',
          Format(WorkflowStepArgument."Due Date Formula"));
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'Message',
          WorkflowStepArgument.Message);
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'DelegateAfter',
          Format(WorkflowStepArgument."Delegate After", 0, 2));
        if WorkflowStepArgument."Show Confirmation Message" then
            LibraryXPathXMLReader.VerifyAttributeFromNode(CurrNode, 'ShowConfirmationMessage',
              Format(WorkflowStepArgument."Show Confirmation Message"))
        else
            LibraryXPathXMLReader.VerifyAttributeAbsenceFromNode(CurrNode, 'ShowConfirmationMessage');
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'TableNumber',
          Format(WorkflowStepArgument."Table No."));
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'FieldNumber',
          Format(WorkflowStepArgument."Field No."));
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'ResponseOptionGroup',
          WorkflowStepArgument."Response Option Group");
    end;

    local procedure VerifyWorkflowStepRule(WorkflowRule: Record "Workflow Rule"; CurrNode: DotNet XmlNode)
    var
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
    begin
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'RuleID',
          Format(WorkflowRule.ID));
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'RuleTableNumber',
          Format(WorkflowRule."Table ID"));
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(CurrNode, 'RuleFieldNumber',
          Format(WorkflowRule."Field No."));
        LibraryXPathXMLReader.VerifyAttributeFromNode(CurrNode, 'Operator',
          Format(WorkflowRule.Operator, 0, 2));
    end;

    local procedure CheckWorkflowStepsAreEqual(WorkflowCode: Code[20]; CompareToWorkflowCode: Code[20])
    var
        Workflow: Record Workflow;
        CompareToWorkflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        CompareToWorkflowStep: Record "Workflow Step";
    begin
        Workflow.Get(WorkflowCode);
        CompareToWorkflow.Get(CompareToWorkflowCode);
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        CompareToWorkflowStep.SetRange("Workflow Code", CompareToWorkflow.Code);
        Assert.AreEqual(WorkflowStep.Count, CompareToWorkflowStep.Count, 'Number of workflow steps are not same');

        if WorkflowStep.FindSet() then begin
            CompareToWorkflowStep.FindSet();
            repeat
                if not IsNullGuid(WorkflowStep.Argument) then begin
                    Assert.AreNotEqual(WorkflowStep.Argument, CompareToWorkflowStep.Argument, 'Arguments are equal');
                    CheckWorkflowStepArgumentsAreEqual(WorkflowStep.Argument, CompareToWorkflowStep.Argument)
                end else
                    Assert.AreEqual(WorkflowStep.Argument, CompareToWorkflowStep.Argument, 'Arguments are not equal');
                Assert.AreEqual(WorkflowStep.Description, CompareToWorkflowStep.Description, 'Descriptions are not equal');
                Assert.AreEqual(WorkflowStep."Entry Point", CompareToWorkflowStep."Entry Point", 'Entry Points are not equal');
                Assert.AreEqual(WorkflowStep."Function Name", CompareToWorkflowStep."Function Name", 'Function Name are not equal');
                Assert.AreEqual(
                  WorkflowStep."Next Workflow Step ID", CompareToWorkflowStep."Next Workflow Step ID", 'Next Workflow Step ID are not equal');
                Assert.AreEqual(
                  WorkflowStep."Previous Workflow Step ID", CompareToWorkflowStep."Previous Workflow Step ID",
                  'Previous Workflow Step ID are not equal');
                Assert.AreEqual(WorkflowStep.Type, CompareToWorkflowStep.Type, 'Types are not equal');
                Assert.AreNotEqual(WorkflowStep."Workflow Code", CompareToWorkflowStep."Workflow Code", 'Workflow Code are equal');
                CheckWorkflowRulesAreEqual(WorkflowStep."Workflow Code", WorkflowStep.ID,
                  CompareToWorkflowStep."Workflow Code", CompareToWorkflowStep.ID);
            until (WorkflowStep.Next() = 0) or (CompareToWorkflowStep.Next() = 0);
        end;
    end;

    local procedure CheckWorkflowStepArgumentsAreEqual(WorkflowStepArgumentGuid: Guid; CompareToWorkflowStepArgumentGuid: Guid)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        CompareToWorkflowStepArgument: Record "Workflow Step Argument";
    begin
        WorkflowStepArgument.Get(WorkflowStepArgumentGuid);
        CompareToWorkflowStepArgument.Get(CompareToWorkflowStepArgumentGuid);

        Assert.AreEqual(WorkflowStepArgument."Approver Limit Type", CompareToWorkflowStepArgument."Approver Limit Type",
          'Approver Limit Types are not equal');
        Assert.AreEqual(WorkflowStepArgument."Approver Type", CompareToWorkflowStepArgument."Approver Type",
          'Approver Types are different');
        Assert.AreEqual(WorkflowStepArgument."Custom Link", CompareToWorkflowStepArgument."Custom Link",
          'Custom Links are different');
        Assert.AreEqual(WorkflowStepArgument."Delegate After", CompareToWorkflowStepArgument."Delegate After",
          'Delegate After are different');
        Assert.AreEqual(WorkflowStepArgument."Due Date Formula", CompareToWorkflowStepArgument."Due Date Formula",
          'Due Data Formula are different');
        Assert.AreEqual(WorkflowStepArgument."Field No.", CompareToWorkflowStepArgument."Field No.",
          'Field No. are different');
        Assert.AreEqual(WorkflowStepArgument."General Journal Batch Name", CompareToWorkflowStepArgument."General Journal Batch Name",
          'Batch Names are different');
        Assert.AreEqual(
          WorkflowStepArgument."General Journal Template Name", CompareToWorkflowStepArgument."General Journal Template Name",
          'Template Names are different');
        Assert.AreEqual(WorkflowStepArgument."Approver Type", CompareToWorkflowStepArgument."Approver Type",
          'Approver Types are different');
        Assert.AreEqual(WorkflowStepArgument."Link Target Page", CompareToWorkflowStepArgument."Link Target Page",
          'Link Targets are different');
        Assert.AreEqual(WorkflowStepArgument.Message, CompareToWorkflowStepArgument.Message, 'Message values are not equal');
        Assert.AreEqual(WorkflowStepArgument."Notification User ID", CompareToWorkflowStepArgument."Notification User ID",
          'Notification User ID are different');
        Assert.AreEqual(WorkflowStepArgument."Response Function Name", CompareToWorkflowStepArgument."Response Function Name",
          'Response Function Name are different');
        Assert.AreEqual(WorkflowStepArgument."Response Option Group", CompareToWorkflowStepArgument."Response Option Group",
          'Response Option Group are different');
        Assert.AreEqual(WorkflowStepArgument."Show Confirmation Message", CompareToWorkflowStepArgument."Show Confirmation Message",
          'Show Confirmation Message are different');
        Assert.AreEqual(WorkflowStepArgument."Table No.", CompareToWorkflowStepArgument."Table No.", 'Table No. are different');
        Assert.AreEqual(WorkflowStepArgument.Type, CompareToWorkflowStepArgument.Type, 'Type are different');
        Assert.AreEqual(WorkflowStepArgument."Workflow User Group Code", CompareToWorkflowStepArgument."Workflow User Group Code",
          'Workflow group code are different');
    end;

    local procedure CheckWorkflowRulesAreEqual(WorkflowCode: Code[20]; WorkflowStepId: Integer; CompareToWorkflowCode: Code[20]; CompareToWorkflowStepId: Integer)
    var
        WorkflowRule: Record "Workflow Rule";
        CompareToWorkflowRule: Record "Workflow Rule";
    begin
        WorkflowRule.SetRange("Workflow Code", WorkflowCode);
        WorkflowRule.SetRange("Workflow Step ID", WorkflowStepId);
        CompareToWorkflowRule.SetRange("Workflow Code", CompareToWorkflowCode);
        CompareToWorkflowRule.SetRange("Workflow Step ID", CompareToWorkflowStepId);
        Assert.AreEqual(WorkflowRule.Count, CompareToWorkflowRule.Count, 'Number of rules are different');

        if WorkflowRule.FindSet() then begin
            CompareToWorkflowRule.FindSet();
            repeat
                Assert.AreEqual(WorkflowRule."Field No.", CompareToWorkflowRule."Field No.", 'Field No. are different');
                Assert.AreEqual(WorkflowRule.Operator, CompareToWorkflowRule.Operator, 'Operator is different');
                Assert.AreEqual(WorkflowRule."Table ID", CompareToWorkflowRule."Table ID", 'Function Name are not equal');
            until (WorkflowRule.Next() = 0) or (CompareToWorkflowRule.Next() = 0);
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
