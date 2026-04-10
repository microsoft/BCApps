// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

page 9193 "Thirty Day Trial Dialog"
{
    Caption = 'Set up a company';
    PageType = NavigatePage;

    layout
    {
        area(content)
        {
            group(Control11)
            {
                ShowCaption = false;
                Visible = FirstStepVisible;
                group("Get started with a free 30-day trial")
                {
                    Caption = 'Try Business Central with your own data';
                    InstructionalText = 'Explore the benefits of Dynamics 365 Business Central with your own company data for 30 days.';
                }
                field(Content1Lbl; Content1Lbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                }
                field(Content2Lbl; Content2Lbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                    Visible = not IsPreview;
                }
                field(Content3Lbl; Content3Lbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                }
            }
            group(Control17)
            {
                ShowCaption = false;
                Visible = FinalStepVisible;
                group("We're ready, let's get started")
                {
                    Caption = 'We''re ready, let''s get started';
                    InstructionalText = 'When the trial ends, you can keep using the Cronus company demo data for evaluation purposes.';
                }
                field(Content4Lbl; Content4Lbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                }
                field(LinkControl; LinkLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        HyperLink(UrlTxt);
                    end;
                }
                field(TermsAndConditionsCheckBox; TermsAndConditionsAccepted)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'I accept the Terms & Conditions';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;
                //The property 'ToolTip' cannot be empty.
                //ToolTip = '';

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Visible = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionStartTrial)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get started';
                Enabled = TermsAndConditionsAccepted;
                Visible = FinalStepVisible;
                Gesture = None;
                Image = NextRecord;
                InFooterBar = true;
                //The property 'ToolTip' cannot be empty.
                //ToolTip = '';

                trigger OnAction()
                begin
                    StartTrialAction();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Step := Step::Start;
        EnableControls();
        OnIsRunningPreview(IsPreview);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::OK then
            if not TrialWizardCompleted then
                if not Confirm(AbortTrialQst, false) then
                    Error('');
    end;

    var
        Step: Option Start,Finish;
        FirstStepVisible: Boolean;
        FinalStepVisible: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        TrialWizardCompleted: Boolean;
        TermsAndConditionsAccepted: Boolean;
        IsPreview: Boolean;
        LinkLbl: Label 'View terms & conditions';
        UrlTxt: Label 'http://go.microsoft.com/fwlink/?LinkId=828977', Locked = true;
        Content1Lbl: Label 'Use the setups that we provide, and import or create items, customers, and vendors to do things like post invoices or use graphs and reports to analyze your finances.';
        Content2Lbl: Label 'If you decide to subscribe to Business Central, you can continue using the data and setup you create during the trial.';
        Content3Lbl: Label 'Choose Next to learn more about how to get started.';
        Content4Lbl: Label 'Please review the terms and conditions for using Business Central with your own company data.';
        AbortTrialQst: Label 'Are you sure that you want to cancel?';

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();
            Step::Finish:
                ShowFinalStep();
        end;
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowStartStep()
    begin
        FirstStepVisible := true;
        BackActionEnabled := false;
    end;

    local procedure ShowFinalStep()
    begin
        FinalStepVisible := true;
        NextActionEnabled := false;
    end;

    local procedure ResetControls()
    begin
        BackActionEnabled := true;
        NextActionEnabled := true;

        FirstStepVisible := false;
        FinalStepVisible := false;
    end;

    local procedure StartTrialAction()
    begin
        TrialWizardCompleted := true;
        CurrPage.Close();
    end;

    procedure Confirmed(): Boolean
    begin
        exit(TermsAndConditionsAccepted and TrialWizardCompleted);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsRunningPreview(var isPreview: Boolean)
    begin
    end;
}

