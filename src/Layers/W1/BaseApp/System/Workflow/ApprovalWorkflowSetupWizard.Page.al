namespace System.Automation;

using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;

page 1804 "Approval Workflow Setup Wizard"
{
    Caption = 'Approval Workflow Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    SourceTable = "Approval Workflow Wizard";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not DoneVisible;
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and DoneVisible;
#pragma warning disable AA0100
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Caption = '';
                Visible = IntroVisible;
                group("Para1.1")
                {
                    Caption = 'Welcome to Approval Workflow Setup';
                    group("Para1.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'You can create approval workflows that automatically notify an approver when a user tries to create or change certain values on documents, journal lines, or cards, such as an amount above a specified limit.';
                    }
                    group("Para1.1.2")
                    {
                        Caption = '';
                        InstructionalText = 'To enable typical approval workflows, such as for amounts on purchase invoices, you must specify basic settings, such as the approver, the amount limit and when the approval is due. More advanced settings are preset on the related approval workflow, which you can modify later.';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to select from a list of typical approval workflows and then start specifying basic settings for each workflow.';
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = ApprovalDocumentTypesVisible;
                group("Para2.1")
                {
                    Caption = 'Which approval workflow do you want to set up?';
                    field("Purchase Invoice Approval"; Rec."Purch Invoice App. Workflow")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purchase Invoice Approval';

                        trigger OnValidate()
                        begin
                            NextEnabled := Rec."Purch Invoice App. Workflow" or Rec."Sales Invoice App. Workflow"
                        end;
                    }
                    field("Sales Invoice Approval"; Rec."Sales Invoice App. Workflow")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Sales Invoice Approval';

                        trigger OnValidate()
                        begin
                            NextEnabled := Rec."Purch Invoice App. Workflow" or Rec."Sales Invoice App. Workflow"
                        end;
                    }
                }
            }
            group(Step3)
            {
                Caption = '';
                Visible = UseExistingApprovalSetupVisible;
                group("Para3.1")
                {
                    Caption = 'An approval user setup already exists.';
                    field("Use Exist. Approval User Setup"; Rec."Use Exist. Approval User Setup")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Use the existing setup';
                    }
                    field(ApprovalUserSetupLabel; ApprovalUserSetupLabel)
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            PAGE.RunModal(PAGE::"Approval User Setup");
                        end;
                    }
                }
            }
            group(Step4)
            {
                Caption = '';
                Visible = ApprovalUserSetupVisible;
                group("Para4.1")
                {
                    Caption = 'To set up the approval users, answer the following questions.';
                    Visible = PurchInvoiceApprovalDetailsVisible or SalesInvoiceApprovalDetailsVisible;
                    field("Who is the approver?"; Rec."Approver ID")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Who is the approver?';
                        Enabled = Rec."Purch Invoice App. Workflow" or Rec."Sales Invoice App. Workflow";
                        TableRelation = User."User Name";
                    }
                }
                group("Para4.2")
                {
                    Caption = '';
                    InstructionalText = 'Which amount can the user enter on purchase invoices before the invoice requires approval?';
                    Visible = PurchInvoiceApprovalDetailsVisible;
                    field("Purch Amount Approval Limit"; Rec."Purch Amount Approval Limit")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Amount Limit';
                    }
                }
                group("Para4.3")
                {
                    Caption = '';
                    InstructionalText = 'Which amount can the user enter on sales invoices before the invoice requires approval?';
                    Visible = SalesInvoiceApprovalDetailsVisible;
                    field("Sales Amount Approval Limit"; Rec."Sales Amount Approval Limit")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Amount Limit';
                    }
                }
            }
            group(Step5)
            {
                Caption = '';
                Visible = DoneVisible;
                group("Para5.1")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'Choose Finish to enable the selected approval workflows with the specified settings.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Back)
            {
                ApplicationArea = Suite;
                Caption = 'Back';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(Next)
            {
                ApplicationArea = Suite;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    if Step = Step::"Approval User Setup" then
                        ValidateApproverUserSetup(Rec."Approver ID");
                    NextStep(false);
                end;
            }
            action(Finish)
            {
                ApplicationArea = Suite;
                Caption = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                    ApprovalWorkflowSetupMgt: Codeunit "Approval Workflow Setup Mgt.";
                begin
                    ApprovalWorkflowSetupMgt.ApplyInitialWizardUserInput(Rec);
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Approval Workflow Setup Wizard");

                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec."Use Exist. Approval User Setup" := true;
            SetDefaultValues();
            Rec.Insert();
        end;
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    var
        ApprovalUserSetup: Page "Approval User Setup";
    begin
        ShowIntroStep();
        ApprovalUserSetupLabel := StrSubstNo(OpenPageTxt, ApprovalUserSetup.Caption);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if CloseAction = ACTION::OK then
            if GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, Page::"Approval Workflow Setup Wizard") then
                if not Confirm(NAVNotSetUpQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Intro,"Approval Document Types","Use Existing Approval User Setup","Approval User Setup",Done;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        TopBannerVisible: Boolean;
        IntroVisible: Boolean;
        ApprovalDocumentTypesVisible: Boolean;
        UseExistingApprovalSetupVisible: Boolean;
        ApprovalUserSetupVisible: Boolean;
        SalesInvoiceApprovalDetailsVisible: Boolean;
        PurchInvoiceApprovalDetailsVisible: Boolean;
        DoneVisible: Boolean;
        NAVNotSetUpQst: Label 'Document Approval has not been set up.\\Are you sure that you want to exit?';
        NoUnlimitedApproverErr: Label 'Select a user that has unlimited approval rights.';
        OpenPageTxt: Label 'Open %1', Comment = '%1 is the page that will be opened when clicking the control';
        ApprovalUserSetupLabel: Text;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::"Approval Document Types":
                ShowApprovalDocumentTypesStep();
            Step::"Use Existing Approval User Setup":
                begin
                    ShowUseExistingApprovalSetupQstStep();
                    if not UseExistingApprovalSetupVisible then
                        NextStep(Backwards)
                end;
            Step::"Approval User Setup":
                if not Rec."Use Exist. Approval User Setup" then
                    ShowApprovalUserSetupDetailsStep()
                else
                    NextStep(Backwards);
            Step::Done:
                ShowDoneStep();
        end;
        CurrPage.Update(true);
    end;

    local procedure ShowIntroStep()
    begin
        ResetWizardControls();
        IntroVisible := true;
        BackEnabled := false;
    end;

    local procedure ShowApprovalDocumentTypesStep()
    begin
        ResetWizardControls();
        ApprovalDocumentTypesVisible := true;
        NextEnabled := Rec."Purch Invoice App. Workflow" or Rec."Sales Invoice App. Workflow";
    end;

    local procedure ShowApprovalUserSetupDetailsStep()
    begin
        ResetWizardControls();
        ApprovalUserSetupVisible := not Rec."Use Exist. Approval User Setup";
        SalesInvoiceApprovalDetailsVisible := not Rec."Use Exist. Approval User Setup" and Rec."Sales Invoice App. Workflow";
        PurchInvoiceApprovalDetailsVisible := not Rec."Use Exist. Approval User Setup" and Rec."Purch Invoice App. Workflow";
    end;

    local procedure ShowUseExistingApprovalSetupQstStep()
    var
        ApprovalUserSetup: Record "User Setup";
    begin
        ResetWizardControls();
        UseExistingApprovalSetupVisible := not ApprovalUserSetup.IsEmpty();
        if not UseExistingApprovalSetupVisible then
            Rec."Use Exist. Approval User Setup" := false;
    end;

    local procedure ShowDoneStep()
    begin
        ResetWizardControls();
        DoneVisible := true;
        NextEnabled := false;
        FinishEnabled := true;
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;

        // Tabs
        IntroVisible := false;
        ApprovalDocumentTypesVisible := false;
        UseExistingApprovalSetupVisible := false;
        ApprovalUserSetupVisible := false;
        PurchInvoiceApprovalDetailsVisible := false;
        SalesInvoiceApprovalDetailsVisible := false;
        DoneVisible := false;
    end;

    local procedure ValidateApproverUserSetup(UserName: Code[50])
    begin
        if UserName = '' then
            Error(NoUnlimitedApproverErr);
    end;

    local procedure SetDefaultValues()
    var
        ApprovalUserSetup: Record "User Setup";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowCode: Code[20];
    begin
        // Specific Purchase Invoice Approval Workflow: WZ-PIAPW
        WorkflowCode := WorkflowSetup.GetWorkflowWizardCode(WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        if Workflow.Get(WorkflowCode) then
            Rec."Purch Invoice App. Workflow" := true;

        // Specific Sales Invoice Approval Workflow: WZ-SIAPW
        WorkflowCode := WorkflowSetup.GetWorkflowWizardCode(WorkflowSetup.SalesInvoiceApprovalWorkflowCode());
        if Workflow.Get(WorkflowCode) then
            Rec."Sales Invoice App. Workflow" := true;

        ApprovalUserSetup.SetRange("Unlimited Sales Approval", true);
        ApprovalUserSetup.SetRange("Unlimited Purchase Approval", true);
        if ApprovalUserSetup.FindFirst() then
            Rec."Approver ID" := ApprovalUserSetup."User ID";

        Rec."Purch Amount Approval Limit" := ApprovalUserSetup.GetDefaultPurchaseAmountApprovalLimit();
        Rec."Sales Amount Approval Limit" := ApprovalUserSetup.GetDefaultSalesAmountApprovalLimit();
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;
}

