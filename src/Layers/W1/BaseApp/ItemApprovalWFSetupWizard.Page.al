// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using Microsoft.Inventory.Item;
using System.Environment;
using System.Environment.Configuration;
using System.Reflection;
using System.Utilities;

page 1812 "Item Approval WF Setup Wizard"
{
    Caption = 'Item Approval Workflow Setup';
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
                    Caption = 'Welcome to Item Approval Workflow Setup';
                    group("Para1.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'You can create approval workflows that automatically notify an approver when a user tries to create or change an item card.';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to specify basic approval workflow settings for changing an item card.';
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = ItemApproverSetupVisible;
                group("Para2.1")
                {
                    Caption = '';
                    group("Para2.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'Choose who is authorized to approve or reject new or changed item cards.';
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
                }
                group("Para2.2")
                {
                    Caption = '';
                    group("Para2.2.1")
                    {
                        Caption = '';
                        InstructionalText = 'Choose if the approval process starts automatically or if the user must start the process.';
                    }
                    field("App. Trigger"; Rec."App. Trigger")
                    {
                        ApplicationArea = Suite;
                        Caption = 'The workflow starts when';

                        trigger OnValidate()
                        begin
                            CanEnableNext();
                        end;
                    }
                }
            }
            group(Step3)
            {
                Caption = '';
                Visible = ItemAutoAppDetailsVisible;
                group("Para3.1")
                {
                    Caption = '';
                    InstructionalText = 'Choose criteria for when the approval process starts automatically.';
                    grid("Para3.1.1")
                    {
                        Caption = '';
                        GridLayout = Rows;
                        group("Para3.1.1.1")
                        {
                            Caption = '';
                            InstructionalText = 'The workflow starts when:';
                            field(ItemFieldCap; ItemFieldCaption)
                            {
                                ApplicationArea = Suite;
                                Caption = 'Field';
                                ShowCaption = false;

                                trigger OnLookup(var Text: Text): Boolean
                                var
                                    FieldRec: Record "Field";
                                    FieldSelection: Codeunit "Field Selection";
                                begin
                                    FindAndFilterToField(FieldRec, Text);

                                    if FieldSelection.Open(FieldRec) then
                                        SetItemField(FieldRec."No.");
                                end;

                                trigger OnValidate()
                                var
                                    FieldRec: Record "Field";
                                    FieldSelection: Codeunit "Field Selection";
                                begin
                                    if ItemFieldCaption = '' then begin
                                        SetItemField(0);
                                        exit;
                                    end;

                                    if not FindAndFilterToField(FieldRec, ItemFieldCaption) then
                                        Error(FieldNotExistErr, ItemFieldCaption);

                                    if FieldRec.Count = 1 then begin
                                        SetItemField(FieldRec."No.");
                                        exit;
                                    end;

                                    if FieldSelection.Open(FieldRec) then
                                        SetItemField(FieldRec."No.")
                                    else
                                        Error(FieldNotExistErr, ItemFieldCaption);
                                end;
                            }
                            label(is)
                            {
                                ApplicationArea = Suite;
                                Caption = 'is';
                                ShowCaption = false;
                            }
                            field("Field Operator"; Rec."Field Operator")
                            {
                                ApplicationArea = Suite;
                                Caption = 'Operator';
                                ShowCaption = false;
                            }
                        }
                    }
                    group("Para3.1.2")
                    {
                        Caption = 'Specify the message to display when the workflow starts.';
                        field("Custom Message"; Rec."Custom Message")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Message';
                            ShowCaption = false;
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
                    Caption = '';
                    InstructionalText = 'Item Approval Workflow Overview';
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
                    GuidedExperience: Codeunit "Guided Experience";
                    ApprovalWorkflowSetupMgt: Codeunit "Approval Workflow Setup Mgt.";
                begin
                    ApprovalWorkflowSetupMgt.ApplyItemWizardUserInput(Rec);
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Item Approval WF Setup Wizard");

                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            SetDefaultValues();
            Rec.Insert();
        end;
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    begin
        ShowIntroStep();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if CloseAction = ACTION::OK then
            if GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, PAGE::"Item Approval WF Setup Wizard") then
                if not Confirm(NAVNotSetUpQst, false) then
                    Error('');
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Intro,"Item Approver Setup","Automatic Approval Setup",Done;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        TopBannerVisible: Boolean;
        IntroVisible: Boolean;
        ItemApproverSetupVisible: Boolean;
        ItemAutoAppDetailsVisible: Boolean;
        DoneVisible: Boolean;
        NAVNotSetUpQst: Label 'Item Approval has not been set up.\\Are you sure that you want to exit?';
        MandatoryApproverErr: Label 'You must select an approver before continuing.', Comment = '%1 = User Name';
        ItemFieldCaption: Text[250];
        FieldNotExistErr: Label 'Field %1 does not exist.', Comment = '%1 = Field Caption';
        SummaryText: Text;
        ManualTriggerTxt: Label 'An approval request will be sent to the user %1 when the user sends the request manually.', Comment = '%1 = User Name (eg. An approval request will be sent to the user Domain/Username when the user sends the request manually.)';
        AutoTriggerTxt: Label 'An approval request will be sent to the user %1 when the value in the %2 field is %3.', Comment = '%1 = User Name, %2 = Field caption, %3 = Of of this 3 values: Increased, Decreased, Changed (eg. An approval request will be sent to the user Domain/Username when the value in the Credit Limit (LCY) field is Increased.)';

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else begin
            if ItemApproverSetupVisible then
                ValidateApprover();
            if ItemAutoAppDetailsVisible then
                ValidateFieldSelection();
            Step := Step + 1;
        end;

        case Step of
            Step::Intro:
                ShowIntroStep();
            Step::"Item Approver Setup":
                ShowApprovalUserSetupDetailsStep();
            Step::"Automatic Approval Setup":
                if Rec."App. Trigger" = Rec."App. Trigger"::"The user changes a specific field" then
                    ShowItemApprovalDetailsStep()
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

    local procedure ShowApprovalUserSetupDetailsStep()
    begin
        ResetWizardControls();
        ItemApproverSetupVisible := true;
    end;

    local procedure ShowItemApprovalDetailsStep()
    begin
        ResetWizardControls();
        ItemAutoAppDetailsVisible := true;
        SetItemField(Rec.Field);
    end;

    local procedure ShowDoneStep()
    begin
        ResetWizardControls();
        DoneVisible := true;
        NextEnabled := false;
        FinishEnabled := true;

        if Rec."App. Trigger" = Rec."App. Trigger"::"The user sends an approval requests manually" then
            SummaryText := StrSubstNo(ManualTriggerTxt, Rec."Approver ID");
        if Rec."App. Trigger" = Rec."App. Trigger"::"The user changes a specific field" then begin
            Rec.CalcFields("Field Caption");
            SummaryText := StrSubstNo(AutoTriggerTxt, Rec."Approver ID", Rec."Field Caption", Rec."Field Operator");
        end;

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
        ItemApproverSetupVisible := false;
        ItemAutoAppDetailsVisible := false;
        DoneVisible := false;
    end;

    local procedure SetDefaultValues()
    var
        Workflow: Record Workflow;
        WorkflowRule: Record "Workflow Rule";
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowCode: Code[20];
    begin
        Rec.TableNo := DATABASE::Item;
        WorkflowCode := WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.ItemUnitPriceChangeApprovalWorkflowCode());
        if Workflow.Get(WorkflowCode) then begin
            WorkflowRule.SetRange("Workflow Code", WorkflowCode);
            if WorkflowRule.FindFirst() then begin
                Rec.Field := WorkflowRule."Field No.";
                Rec."Field Operator" := WorkflowRule.Operator;
            end;
            WorkflowStep.SetRange("Workflow Code", WorkflowCode);
            WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.ShowMessageCode());
            if WorkflowStep.FindFirst() then begin
                WorkflowStepArgument.Get(WorkflowStep.Argument);
                Rec."Custom Message" := WorkflowStepArgument.Message;
            end;
        end;
    end;

    local procedure ValidateApprover()
    begin
        if Rec."Approver ID" = '' then
            Error(MandatoryApproverErr);
    end;

    local procedure ValidateFieldSelection()
    begin
    end;

    local procedure CanEnableNext()
    begin
        NextEnabled := true;
    end;

    local procedure SetItemField(FieldNo: Integer)
    begin
        Rec.Field := FieldNo;
        Rec.CalcFields("Field Caption");
        ItemFieldCaption := Rec."Field Caption";
    end;

    local procedure FindAndFilterToField(var FieldRec: Record "Field"; CaptionToFind: Text): Boolean
    begin
        FieldRec.FilterGroup(2);
        FieldRec.SetRange(TableNo, DATABASE::Item);
        FieldRec.SetFilter(Type, StrSubstNo('%1|%2|%3|%4|%5|%6|%7|%8|%9|%10|%11|%12|%13',
            FieldRec.Type::Boolean,
            FieldRec.Type::Text,
            FieldRec.Type::Code,
            FieldRec.Type::Decimal,
            FieldRec.Type::Integer,
            FieldRec.Type::BigInteger,
            FieldRec.Type::Date,
            FieldRec.Type::Time,
            FieldRec.Type::DateTime,
            FieldRec.Type::DateFormula,
            FieldRec.Type::Option,
            FieldRec.Type::Duration,
            FieldRec.Type::RecordID));
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);

        if CaptionToFind = Rec."Field Caption" then
            FieldRec.SetRange("No.", Rec.Field)
        else
            if CaptionToFind = 'Blocked' then
                FieldRec.SetFilter("Field Caption", '%1', '@' + CaptionToFind)
            else
                FieldRec.SetFilter("Field Caption", '%1', '@' + CaptionToFind + '*');

        exit(FieldRec.FindFirst());
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

