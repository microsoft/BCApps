namespace System.Automation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Security.AccessControl;
using System.Security.User;

codeunit 1804 "Approval Workflow Setup Mgt."
{
    // // This codeunit creates and edits purchase invoice and sales invoice approval workflows.
    // // In addition, user setup can be created for all users in the system based on the user input from wizard.


    trigger OnRun()
    begin
    end;

    var
        OneWeekDueDateFormulaTxt: Label '<1W>', Locked = true;
        CustomerApprWorkflowDescTxt: Label 'Customer Approval Workflow';
        ItemApprWorkflowDescTxt: Label 'Item Approval Workflow';
        SalesMktCategoryTxt: Label 'SALES', Locked = true;
        ItemChangeApprWorkflowDescTxt: Label 'Item Change Approval Workflow';
        CustomerChangeApprWorkflowDescTxt: Label 'Customer Change Approval Workflow';
        GeneralJournalLineApprWorkflowDescTxt: Label 'General Journal Line Approval Workflow';
        FinCategoryDescTxt: Label 'FIN', Locked = true;

    [Scope('OnPrem')]
    procedure ApplyInitialWizardUserInput(TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary)
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        if TempApprovalWorkflowWizard."Purch Invoice App. Workflow" then
            CreatePurchaseDocumentApprovalWorkflow(PurchaseHeader."Document Type"::Invoice.AsInteger());

        if TempApprovalWorkflowWizard."Sales Invoice App. Workflow" then
            CreateSalesDocumentApprovalWorkflow(SalesHeader."Document Type"::Invoice.AsInteger());

        CreateApprovalSetup(TempApprovalWorkflowWizard);
    end;

    [Scope('OnPrem')]
    procedure ApplyCustomerWizardUserInput(TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary)
    var
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        EventConditions: Text;
    begin
        case TempApprovalWorkflowWizard."App. Trigger" of
            TempApprovalWorkflowWizard."App. Trigger"::"The user sends an approval requests manually":
                begin
                    EventConditions := WorkflowSetup.BuildCustomerTypeConditions();
                    CreateCustomerOrItemApprovalWorkflow(Workflow, TempApprovalWorkflowWizard, DATABASE::Customer,
                      WorkflowSetup.CustomerWorkflowCode(), CustomerApprWorkflowDescTxt, EventConditions,
                      WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode(),
                      WorkflowEventHandling.RunWorkflowOnCancelCustomerApprovalRequestCode());
                end;
            TempApprovalWorkflowWizard."App. Trigger"::"The user changes a specific field":
                CreateCustomerOrItemChangeApprovalWorkflow(Workflow, TempApprovalWorkflowWizard, DATABASE::Customer,
                  WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode(), CustomerChangeApprWorkflowDescTxt,
                  WorkflowEventHandling.RunWorkflowOnCustomerChangedCode());
        end;

        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure ApplyItemWizardUserInput(TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary)
    var
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        EventConditions: Text;
    begin
        case TempApprovalWorkflowWizard."App. Trigger" of
            TempApprovalWorkflowWizard."App. Trigger"::"The user sends an approval requests manually":
                begin
                    EventConditions := WorkflowSetup.BuildItemTypeConditions();
                    CreateCustomerOrItemApprovalWorkflow(Workflow, TempApprovalWorkflowWizard, DATABASE::Item,
                      WorkflowSetup.ItemWorkflowCode(), ItemApprWorkflowDescTxt, EventConditions,
                      WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode(),
                      WorkflowEventHandling.RunWorkflowOnCancelItemApprovalRequestCode());
                end;
            TempApprovalWorkflowWizard."App. Trigger"::"The user changes a specific field":
                CreateCustomerOrItemChangeApprovalWorkflow(Workflow, TempApprovalWorkflowWizard, DATABASE::Item,
                  WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode(), ItemChangeApprWorkflowDescTxt,
                  WorkflowEventHandling.RunWorkflowOnItemChangedCode());
        end;

        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure CreateCustomerOrItemApprovalWorkflow(var Workflow: Record Workflow; var TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary; TableNo: Integer; InitialWorkflowCode: Code[20]; WorkflowDescription: Text[100]; EventConditions: Text; StartEvent: Code[128]; CancelEvent: Code[128])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        DisableWorkflowWithEntryPointEventConditions(TableNo,
          StartEvent, EventConditions);
        InsertWorkflow(Workflow, GenerateWorkflowCode(InitialWorkflowCode),
          WorkflowDescription, SalesMktCategoryTxt);
        WorkflowSetup.InsertRecApprovalWorkflowSteps(Workflow, EventConditions,
          StartEvent, WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          CancelEvent, WorkflowStepArgument, true, true);

        ChangeWorkflowStepArgument(WorkflowStepArgument, Workflow.Code, TempApprovalWorkflowWizard."Approver ID");
    end;

    local procedure CreateCustomerOrItemChangeApprovalWorkflow(var Workflow: Record Workflow; var TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary; TableNo: Integer; InitialWorkflowCode: Code[20]; WorkflowDescription: Text[100]; StartEvent: Code[128])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        DisableWorkflowWithEntryPointRules(TableNo, StartEvent, TempApprovalWorkflowWizard.Field);
        InsertWorkflow(Workflow, GenerateWorkflowCode(InitialWorkflowCode),
          WorkflowDescription, SalesMktCategoryTxt);
        WorkflowSetup.InsertRecChangedApprovalWorkflowSteps(Workflow, TempApprovalWorkflowWizard."Field Operator",
          StartEvent, WorkflowResponseHandling.CreateApprovalRequestsCode(),
          WorkflowResponseHandling.SendApprovalRequestForApprovalCode(),
          WorkflowStepArgument, TableNo, TempApprovalWorkflowWizard.Field, TempApprovalWorkflowWizard."Custom Message");

        ChangeWorkflowStepArgument(WorkflowStepArgument, Workflow.Code, TempApprovalWorkflowWizard."Approver ID");
    end;

    [Scope('OnPrem')]
    procedure ApplyPaymantJrnlWizardUserInput(TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if not TempApprovalWorkflowWizard."For All Batches" then
            GenJournalLine.SetRange("Journal Batch Name", TempApprovalWorkflowWizard."Journal Batch Name");

        GenJournalLine.SetRange("Journal Template Name", TempApprovalWorkflowWizard."Journal Template Name");
        CreateGenJnlLineApprovalWorkflow(GenJournalLine, TempApprovalWorkflowWizard."Approver ID");
    end;

    procedure CreateApprovalSetup(TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary)
    begin
        if TempApprovalWorkflowWizard."Use Exist. Approval User Setup" then
            exit;

        // User setup for admin
        CreateUnlimitedApprover(TempApprovalWorkflowWizard);

        // User setup for all other users
        CreateLimitedAmountApprovers(TempApprovalWorkflowWizard);
    end;

    [Scope('OnPrem')]
    procedure CreateGenJnlLineApprovalWorkflow(var GenJournalLine: Record "Gen. Journal Line"; ApproverId: Code[50]): Code[20]
    var
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
        OneWeekDateFormula: DateFormula;
        WizardWorkflowCode: Code[20];
        EventConditions: Text;
    begin
        // Specific Workflow code is used: WZ-****
        WizardWorkflowCode := WorkflowSetup.GetWorkflowWizardCode(WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());
        EventConditions := WorkflowSetup.BuildGeneralJournalLineTypeConditions(GenJournalLine);
        DisableWorkflowWithEntryPointEventConditions(DATABASE::"Gen. Journal Batch",
          WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode(), EventConditions);
        InsertWorkflow(Workflow, GenerateWorkflowCode(WizardWorkflowCode),
          GeneralJournalLineApprWorkflowDescTxt, FinCategoryDescTxt);

        Evaluate(OneWeekDateFormula, OneWeekDueDateFormulaTxt);
        WorkflowSetup.InsertGenJnlLineApprovalWorkflowSteps(
            Workflow, EventConditions, WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Specific Approver", '', ApproverId, OneWeekDateFormula);

        // Enable workflow
        Workflow.Validate(Enabled, true);
        Workflow.Modify();

        exit(WizardWorkflowCode);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesDocumentApprovalWorkflow(DocumentType: Option): Code[20]
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
        BlankDateFormula: DateFormula;
        WizardWorkflowCode: Code[20];
        EventConditions: Text;
    begin
        // Specific Workflow code is used: WZ-SIAPW
        WizardWorkflowCode := WorkflowSetup.GetWorkflowWizardCode(WorkflowSetup.SalesInvoiceApprovalWorkflowCode());
        if Workflow.Get(WizardWorkflowCode) then
            UpdateWorkflow(Workflow, DATABASE::"Sales Header", BlankDateFormula)
        else begin
            EventConditions :=
                WorkflowSetup.BuildSalesHeaderTypeConditionsText(Enum::"Sales Document Type".FromInteger(DocumentType), SalesHeader.Status::Open);
            DisableWorkflowWithEntryPointEventConditions(
                DATABASE::"Sales Header", WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode(), EventConditions);

            WorkflowSetup.InsertSalesDocumentApprovalWorkflowSteps(
                Workflow, Enum::"Sales Document Type".FromInteger(DocumentType), WorkflowStepArgument."Approver Type"::Approver,
                WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", '', BlankDateFormula);

            if Workflow.Rename(WizardWorkflowCode) then;
        end;

        // Enable workflow
        Workflow.Validate(Enabled, true);
        Workflow.Modify();

        exit(WizardWorkflowCode);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchaseDocumentApprovalWorkflow(DocumentType: Option): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        BlankDateFormula: DateFormula;
        WizardWorkflowCode: Code[20];
        EventConditions: Text;
    begin
        // Specific Workflow code is used: WZ-PIAPW
        WizardWorkflowCode := WorkflowSetup.GetWorkflowWizardCode(WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        if Workflow.Get(WizardWorkflowCode) then
            UpdateWorkflow(Workflow, DATABASE::"Purchase Header", BlankDateFormula)
        else begin
            EventConditions :=
                WorkflowSetup.BuildPurchHeaderTypeConditionsText("Purchase Document Type".FromInteger(DocumentType), PurchaseHeader.Status::Open);
            DisableWorkflowWithEntryPointEventConditions(
                DATABASE::"Purchase Header", WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode(), EventConditions);

            WorkflowSetup.InsertPurchaseDocumentApprovalWorkflowSteps(
                Workflow, "Purchase Document Type".FromInteger(DocumentType), WorkflowStepArgument."Approver Type"::Approver,
                WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", '', BlankDateFormula);

            if Workflow.Rename(WizardWorkflowCode) then;
        end;

        // Enable workflow
        Workflow.Validate(Enabled, true);
        Workflow.Modify();

        exit(WizardWorkflowCode);
    end;

    local procedure CreateUnlimitedApprover(TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary)
    var
        ApprovalUserSetup: Record "User Setup";
        User: Record User;
    begin
        // Set admin as approval user
        if not ApprovalUserSetup.Get(TempApprovalWorkflowWizard."Approver ID") then begin
            ApprovalUserSetup.Init();
            ApprovalUserSetup.Validate("User ID", TempApprovalWorkflowWizard."Approver ID");
            ApprovalUserSetup.Insert();
        end;

        User.SetRange("User Name", TempApprovalWorkflowWizard."Approver ID");
        User.FindFirst();
        if TempApprovalWorkflowWizard."Sales Invoice App. Workflow" then
            ApprovalUserSetup.Validate("Unlimited Sales Approval", TempApprovalWorkflowWizard."Sales Invoice App. Workflow");
        if TempApprovalWorkflowWizard."Purch Invoice App. Workflow" then
            ApprovalUserSetup.Validate("Unlimited Purchase Approval", TempApprovalWorkflowWizard."Purch Invoice App. Workflow");
        ApprovalUserSetup.Validate("Approver ID", ''); // Reset Approver ID
        if ApprovalUserSetup."E-Mail" = '' then
            ApprovalUserSetup.Validate("E-Mail", User."Contact Email");
        ApprovalUserSetup.Modify();
    end;

    local procedure CreateLimitedAmountApprovers(TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary)
    var
        ApprovalUserSetup: Record "User Setup";
        User: Record User;
    begin
        User.SetFilter("User Name", '<>%1', TempApprovalWorkflowWizard."Approver ID");

        if User.FindSet() then
            repeat
                if not ApprovalUserSetup.Get(User."User Name") then begin
                    ApprovalUserSetup.Init();
                    ApprovalUserSetup.Validate("User ID", User."User Name");
                    ApprovalUserSetup.Insert();
                end;

                ApprovalUserSetup.Validate("Approver ID", TempApprovalWorkflowWizard."Approver ID");
                if ApprovalUserSetup."E-Mail" = '' then
                    ApprovalUserSetup.Validate("E-Mail", User."Contact Email");
                ApprovalUserSetup.Validate("Unlimited Sales Approval", false);
                if TempApprovalWorkflowWizard."Sales Invoice App. Workflow" then
                    ApprovalUserSetup.Validate("Sales Amount Approval Limit", TempApprovalWorkflowWizard."Sales Amount Approval Limit");
                ApprovalUserSetup.Validate("Unlimited Purchase Approval", false);
                if TempApprovalWorkflowWizard."Purch Invoice App. Workflow" then
                    ApprovalUserSetup.Validate("Purchase Amount Approval Limit", TempApprovalWorkflowWizard."Purch Amount Approval Limit");
                ApprovalUserSetup.Modify();
            until User.Next() = 0;
    end;

    local procedure PopulateSendApprovalWorkflowStepArgument(WorkflowCode: Code[20]; ApproverType: Enum "Workflow Approver Type"; ApproverLimitType: Enum "Workflow Approver Limit Type"; ApprovalEntriesPage: Integer; WorkflowUserGroupCode: Code[20]; DueDateFormula: DateFormula; ShowConfirmationMessage: Boolean)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        if FindWorkflowStepArgument(WorkflowStepArgument, WorkflowCode, WorkflowResponseHandling.CreateApprovalRequestsCode()) then begin
            // User input
            WorkflowStepArgument."Approver Type" := ApproverType;
            WorkflowStepArgument."Approver Limit Type" := ApproverLimitType;
            WorkflowStepArgument."Workflow User Group Code" := WorkflowUserGroupCode;
            WorkflowStepArgument."Due Date Formula" := DueDateFormula;
            WorkflowStepArgument."Link Target Page" := ApprovalEntriesPage;
            WorkflowStepArgument."Show Confirmation Message" := ShowConfirmationMessage;
            WorkflowStepArgument.Modify();
        end;
    end;

    procedure FindWorkflowStepArgument(var WorkflowStepArgument: Record "Workflow Step Argument"; WorkflowCode: Code[50]; FunctionName: Code[128]): Boolean
    var
        WorkflowStep: Record "Workflow Step";
    begin
        // Get the step
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::Response);
        WorkflowStep.SetRange("Function Name", FunctionName);
        if WorkflowStep.FindFirst() then
            // Get the step arguments
            exit(WorkflowStepArgument.Get(WorkflowStep.Argument));

        exit(false);
    end;

    local procedure WorkflowWithEntryPointEventConditionsExists(TableID: Integer; FunctionName: Code[128]; EventFilters: Text; var Workflow: Record Workflow): Boolean
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowDefinition: Query "Workflow Definition";
    begin
        WorkflowDefinition.SetRange(Table_ID, TableID);
        WorkflowDefinition.SetRange(Entry_Point, true);
        WorkflowDefinition.SetRange(Enabled, true);
        WorkflowDefinition.SetRange(Type, WorkflowDefinition.Type::"Event");
        WorkflowDefinition.SetRange(Function_Name, FunctionName);
        WorkflowDefinition.Open();
        while WorkflowDefinition.Read() do begin
            WorkflowStepArgument.Get(WorkflowDefinition.Argument);
            if WorkflowStepArgument.GetEventFilters() = EventFilters then begin
                Workflow.Get(WorkflowDefinition.Code);
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure DisableWorkflowWithEntryPointEventConditions(TableID: Integer; FunctionName: Code[128]; EventConditions: Text)
    var
        Workflow: Record Workflow;
    begin
        if WorkflowWithEntryPointEventConditionsExists(TableID, FunctionName, EventConditions, Workflow) then begin
            Workflow.Validate(Enabled, false);
            Workflow.Modify();
        end;
    end;

    local procedure WorkflowWithEntryPointRulesExists(TableID: Integer; FunctionName: Code[128]; FieldNo: Integer; var Workflow: Record Workflow): Boolean
    var
        WorkflowRule: Record "Workflow Rule";
        WorkflowDefinition: Query "Workflow Definition";
    begin
        WorkflowDefinition.SetRange(Table_ID, TableID);
        WorkflowDefinition.SetRange(Entry_Point, true);
        WorkflowDefinition.SetRange(Enabled, true);
        WorkflowDefinition.SetRange(Type, WorkflowDefinition.Type::"Event");
        WorkflowDefinition.SetRange(Function_Name, FunctionName);
        WorkflowDefinition.Open();
        while WorkflowDefinition.Read() do begin
            WorkflowRule.SetRange("Workflow Code", WorkflowDefinition.Code);
            if WorkflowRule.FindFirst() then
                if WorkflowRule."Field No." = FieldNo then begin
                    Workflow.Get(WorkflowDefinition.Code);
                    exit(true);
                end;
        end;

        exit(false);
    end;

    local procedure DisableWorkflowWithEntryPointRules(TableID: Integer; FunctionName: Code[128]; FieldNo: Integer)
    var
        Workflow: Record Workflow;
    begin
        if WorkflowWithEntryPointRulesExists(TableID, FunctionName, FieldNo, Workflow) then begin
            Workflow.Validate(Enabled, false);
            Workflow.Modify();
        end;
    end;

    local procedure UpdateWorkflow(var Workflow: Record Workflow; TableID: Integer; DueDateFormula: DateFormula)
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        EventConditions: Text;
    begin
        if Workflow.Enabled then begin
            Workflow.Validate(Enabled, false);
            Workflow.Modify();
        end else begin
            WorkflowStep.SetRange("Workflow Code", Workflow.Code);
            WorkflowStep.SetRange("Previous Workflow Step ID", 0);
            WorkflowStep.FindFirst();
            WorkflowStepArgument.Get(WorkflowStep.Argument);
            EventConditions := WorkflowStepArgument.GetEventFilters();
            DisableWorkflowWithEntryPointEventConditions(TableID, WorkflowStep."Function Name", EventConditions);
        end;

        PopulateSendApprovalWorkflowStepArgument(Workflow.Code, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver", 0, '', DueDateFormula, true);
    end;

    local procedure InsertWorkflow(var Workflow: Record Workflow; WorkflowCode: Code[20]; WorkflowDescription: Text[100]; CategoryCode: Code[20])
    begin
        Workflow.Init();
        Workflow.Code := WorkflowCode;
        Workflow.Description := WorkflowDescription;
        Workflow.Category := CategoryCode;
        Workflow.Enabled := false;
        Workflow.Insert();
    end;

    local procedure GenerateWorkflowCode(WorkflowCode: Code[20]): Code[20]
    var
        Workflow: Record Workflow;
    begin
        if IncStr(WorkflowCode) = '' then
            WorkflowCode := CopyStr(WorkflowCode, 1, MaxStrLen(WorkflowCode) - 3) + '-01';
        while Workflow.Get(WorkflowCode) do
            WorkflowCode := IncStr(WorkflowCode);
        exit(WorkflowCode);
    end;

    local procedure ChangeWorkflowStepArgument(var WorkflowStepArgument: Record "Workflow Step Argument"; WorkflowCode: Code[20]; ApproverID: Code[50])
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        if WorkflowStep.FindFirst() then begin
            WorkflowStepArgument.Get(WorkflowStep.Argument);
            WorkflowStepArgument."Approver Type" := WorkflowStepArgument."Approver Type"::Approver;
            WorkflowStepArgument."Approver Limit Type" := WorkflowStepArgument."Approver Limit Type"::"Specific Approver";
            WorkflowStepArgument."Approver User ID" := ApproverID;
            Evaluate(WorkflowStepArgument."Due Date Formula", OneWeekDueDateFormulaTxt);
            WorkflowStepArgument.Modify(true);
        end;
    end;
}

