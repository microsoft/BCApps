namespace System.Automation;

using System.Environment;
using System.Environment.Configuration;
using System.Utilities;

page 1815 "Pmt. App. Workflow Setup Wzrd."
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
                    Caption = 'Welcome to Payment Journal Line Approval Workflow Setup';
                    group("Para1.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'You can create approval workflow that notifies an approver when a user sends payment journal lines for approval.';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to specify the approver and other basic settings.';
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = ApproverSelectionVisible;
                group("Para2.1")
                {
                    Caption = ' ';
                    InstructionalText = 'Choose who is authorized to approve or reject the payment journal lines.';
                    field("Approver ID"; Rec."Approver ID")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Approver';
                        LookupPageID = "Approval User Setup";

                        trigger OnValidate()
                        begin
                            CanEnableNext();
                        end;
                    }
                }
                group("Para2.2")
                {
                    Caption = ' ';
                    InstructionalText = 'Choose if the approval workflow applies to all journal batches or to the current journal batch only.';
                    field(BatchSelection; BatchSelection)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Approval workflow applies to';

                        trigger OnValidate()
                        begin
                            Rec."For All Batches" := BatchSelection = BatchSelection::"All Batches";
                            ShowCurrentBatch := not Rec."For All Batches";
                        end;
                    }
                    group(Control3)
                    {
                        ShowCaption = false;
                        Visible = ShowCurrentBatch;
                        field(CurrentBatchIsLabel; CurrentBatchIsLabel)
                        {
                            ApplicationArea = Suite;
                            DrillDown = true;
                            Editable = false;
                            ShowCaption = false;
                            Style = StandardAccent;
                            StyleExpr = true;

                            trigger OnDrillDown()
                            begin
                                CurrPage.Update();
                            end;
                        }
                    }
                }
            }
            group(Step10)
            {
                Caption = '';
                Visible = DoneVisible;
                group("Para10.1")
                {
                    Caption = 'Payment Journal Approval Workflow Overview';
                    field(Overview; SummaryText)
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        MultiLine = true;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = true;
                    }
                }
                group("Para10.2")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'Choose Finish to enable the workflow with the specified settings.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PreviousPage)
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
            action(NextPage)
            {
                ApplicationArea = Suite;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
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
                    ApprovalWorkflowSetupMgt: Codeunit "Approval Workflow Setup Mgt.";
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    ApprovalWorkflowSetupMgt.ApplyPaymantJrnlWizardUserInput(Rec);
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Pmt. App. Workflow Setup Wzrd.");

                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        LoadTopBanners();
        CurrentBatchIsLabel := StrSubstNo(CurrentBatchTxt, Rec."Journal Batch Name");
    end;

    trigger OnOpenPage()
    begin
        ShowIntroStep();
        if Rec."For All Batches" then
            BatchSelection := BatchSelection::"All Batches"
        else
            BatchSelection := BatchSelection::"Current Batch Only";

        ShowCurrentBatch := not Rec."For All Batches";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if CloseAction = ACTION::OK then
            if GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, PAGE::"Pmt. App. Workflow Setup Wzrd.") then
                if not Confirm(NAVNotSetUpQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Intro,"Approver Selection",Done;
        BatchSelection: Option "Current Batch Only","All Batches";
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        TopBannerVisible: Boolean;
        IntroVisible: Boolean;
        ApproverSelectionVisible: Boolean;
        BatchSelectionVisible: Boolean;
        DoneVisible: Boolean;
        NAVNotSetUpQst: Label 'Payment Journal Approval has not been set up.\\Are you sure that you want to exit?';
        MandatoryApproverErr: Label 'You must select an approver before continuing.', Comment = '%1 = User Name';
        MandatoryBatchErr: Label 'You must select a batch before continuing.', Comment = '%1 = User Name';
        CurrentBatchTxt: Label 'Current Batch is %1.', Comment = '%1 = Batch name. Example - Current Batch is BANK.';
        ShowCurrentBatch: Boolean;
        CurrentBatchIsLabel: Text;
        SummaryText: Text;
        OverviewTemplateTxt: Label 'An approval request will be sent to the user %1 for approving journal lines in %2.', Comment = '%1 = User Name, %2 = batch name or all batches. Example - An approval request will be sent to the user NAVUSER when the approval request is snt to all batches. ';
        AllBatchesTxt: Label 'all batches';
        BatchNameTxt: Label 'batch %1', Comment = '%1 = Batch name';

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else begin
            if ApproverSelectionVisible then
                ValidateApprover();
            if BatchSelectionVisible then
                ValidateBatchSelection();
            Step := Step + 1;
        end;

        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::"Approver Selection":
                ShowApprovalUserSelectionStep();
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

    local procedure ShowApprovalUserSelectionStep()
    begin
        ResetWizardControls();
        ApproverSelectionVisible := true;
    end;

    local procedure ShowDoneStep()
    begin
        ResetWizardControls();
        DoneVisible := true;
        NextEnabled := false;
        FinishEnabled := true;

        if Rec."For All Batches" then
            SummaryText := StrSubstNo(OverviewTemplateTxt, Rec."Approver ID", AllBatchesTxt)
        else
            SummaryText := StrSubstNo(OverviewTemplateTxt, Rec."Approver ID", StrSubstNo(BatchNameTxt, Rec."Journal Batch Name"));

        SummaryText := ConvertStr(SummaryText, '\', '/');
    end;

    local procedure ResetWizardControls()
    begin
        // Buttons
        BackEnabled := true;
        NextEnabled := true;
        FinishEnabled := false;

        // Tabs
        IntroVisible := false;
        ApproverSelectionVisible := false;
        BatchSelectionVisible := false;
        DoneVisible := false;
    end;

    local procedure ValidateApprover()
    begin
        if Rec."Approver ID" = '' then
            Error(MandatoryApproverErr);
    end;

    local procedure ValidateBatchSelection()
    begin
        if not Rec."For All Batches" then
            if Rec."Journal Batch Name" = '' then
                Error(MandatoryBatchErr);
    end;

    local procedure CanEnableNext()
    begin
        NextEnabled := true;
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

