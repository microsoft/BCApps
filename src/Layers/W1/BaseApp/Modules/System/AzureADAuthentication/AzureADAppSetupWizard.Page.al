namespace System.Azure.Identity;

using System.Environment;
using System.Environment.Configuration;
using System.Security.Authentication;
using System.Utilities;

page 6300 "Azure AD App Setup Wizard"
{
    Caption = 'Set Up Microsoft Entra ID';
    PageType = NavigatePage;

    layout
    {
        area(content)
        {
            group(Control14)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not DoneVisible;
                field("<MediaRepositoryStandard>"; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '';
                    Editable = false;
                }
            }
            group(Control4)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and DoneVisible;
                field("<MediaRepositoryDone>"; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '';
                    Editable = false;
                }
            }
            group(Intro)
            {
                Caption = 'Intro';
                Visible = IntroVisible;
                group("Para1.1")
                {
                    Caption = 'Welcome to Microsoft Entra Setup';
                    label("Para1.1.1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'When you register an application in the Azure Portal, it enables on-premises applications to communicate with Power BI, Power Automate, Office 365 Exchange and other Azure services directly.  This registration is only required once for each Business Central instance.';
                    }
                    label(Control24)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Caption = '';
                    }
                    label("Para1.1.2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'This setup guide helps you connect your Business Central on-premises solution with Azure.';
                    }
                    label(Control26)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Caption = '';
                    }
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to step through the process of obtaining the necessary information from Azure to complete this setup.';
                }
            }
            group(Step1)
            {
                Caption = 'Step 1';
                Visible = Step1Visible;
                group("Para2.1")
                {
                    Caption = 'Connect with Azure';
                    label("Para2.1.1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To connect to Azure, enter the Application ID and key that you created in the Azure portal.';
                    }

                    field("Para2.1.2"; RegistrationDocsTxt)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        trigger OnDrillDown()
                        begin
                            Hyperlink(RegistrationDocsLinkTxt);
                        end;
                    }

                    part(AzureAdSetup; "Azure AD App Setup Part")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = ' ', Locked = true;
                        ShowFilter = false;
                    }
                    usercontrol(OAuthIntegration; OAuthIntegration)
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                    }
                }
            }
            group(Done)
            {
                Caption = 'Done';
                Visible = DoneVisible;
                group("Para3.1")
                {
                    Caption = 'That''s it!';
                    group("Para3.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'To begin using the Microsoft Entra services, choose Finish.';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionReset)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset Reply URL';
                Enabled = Step1Visible;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.AzureAdSetup.PAGE.SetReplyURLWithDefault();
                end;
            }
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    GoToNextStep(false);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    GoToNextStep(true);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    CurrPage.AzureAdSetup.PAGE.Save();

                    // notify Assisted Setup that this setup has been completed
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, PAGE::"Azure AD App Setup Wizard");
                    CurrPage.Update(false);
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    var
        AzureADAppSetup: Record "Azure AD App Setup";
    begin
        // Checks user permissions and closes the wizard with an error message if necessary.
        if not AzureADAppSetup.WritePermission then
            Error(PermissionsErr);
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    begin
        // Always start on the introduction step
        SetStep(CurrentStep::Intro);
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        CurrentStep: Option Intro,AzureAD,Done;
        IntroVisible: Boolean;
        Step1Visible: Boolean;
        DoneVisible: Boolean;
        NextEnabled: Boolean;
        BackEnabled: Boolean;
        FinishEnabled: Boolean;
        StepOutOfRangeErr: Label 'Wizard step out of range.';
        PermissionsErr: Label 'Please contact an administrator to set up your Microsoft Entra application.';
        TopBannerVisible: Boolean;
        RegistrationDocsLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862265', Locked = true;
        RegistrationDocsTxt: Label 'Learn more about how to register on Azure';

    local procedure SetStep(NewStep: Option)
    begin
        if (NewStep < CurrentStep::Intro) or (NewStep > CurrentStep::Done) then
            Error(StepOutOfRangeErr);

        ClearStepControls();
        CurrentStep := NewStep;

        case NewStep of
            CurrentStep::Intro:
                begin
                    IntroVisible := true;
                    NextEnabled := true;
                end;
            CurrentStep::AzureAD:
                begin
                    Step1Visible := true;
                    BackEnabled := true;
                    NextEnabled := true;
                end;
            CurrentStep::Done:
                begin
                    DoneVisible := true;
                    BackEnabled := true;
                    FinishEnabled := true;
                end;
        end;

        CurrPage.Update(true);
    end;

    local procedure ClearStepControls()
    begin
        // hide all tabs
        IntroVisible := false;
        Step1Visible := false;
        DoneVisible := false;

        // disable all buttons
        BackEnabled := false;
        NextEnabled := false;
        FinishEnabled := false;
    end;

    local procedure CalculateNextStep(Forward: Boolean) NextStep: Integer
    begin
        // // Calculates the next step and hides steps based on whether the Power BI setup is enabled or not

        // General cases
        if Forward and (CurrentStep < CurrentStep::Done) then
            // move forward 1 step
            NextStep := CurrentStep + 1
        else
            if not Forward and (CurrentStep > CurrentStep::Intro) then
                // move backward 1 step
                NextStep := CurrentStep - 1
            else
                // stay on the current step
                NextStep := CurrentStep;
    end;

    local procedure GoToNextStep(Forward: Boolean)
    begin
        if Forward then
            ValidateStep(CurrentStep);

        SetStep(CalculateNextStep(Forward));
    end;

    local procedure ValidateStep(Step: Option)
    begin
        if Step = CurrentStep::AzureAD then
            CurrPage.AzureAdSetup.PAGE.ValidateFields();
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

