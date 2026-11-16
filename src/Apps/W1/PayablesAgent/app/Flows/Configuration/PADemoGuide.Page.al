// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN27
#pragma warning disable AS0050
#endif

namespace Microsoft.Agent.PayablesAgent;

using System.Environment;
using System.Environment.Configuration;
using System.Utilities;

page 3307 "PA Demo Guide"
{
    Extensible = false;
    PageType = NavigatePage;
    RefreshOnActivate = true;
    Caption = 'Payables Agent sample invoice guide', Comment = 'Payables Agent is a term, and should not be translated.';
    ApplicationArea = All;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(content)
        {
            group(StandardBanner)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and not FinishActionEnabled;
                field(MediaResourcesStandard; MediaResourcesStd."Media Reference")
                {
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(FinishedBanner)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible and FinishActionEnabled;
                field(MediaResourcesDone; MediaResourcesFinished."Media Reference")
                {
                    Editable = false;
                    ShowCaption = false;
                }
            }

            group(Start)
            {
                Visible = WelcomeStepVisible;
                group(Welcome)
                {
                    Caption = 'Welcome to the Payables Agent sample invoice guide', Comment = 'Payables Agent is a term, and should not be translated.';
                    Visible = WelcomeStepVisible;
                    group(FeatureDescription)
                    {
                        Caption = '';
                        InstructionalText = 'The Payables Agent expects to work with vendor invoices. This guide provides you with some sample vendor invoices you can use to get started.', Comment = 'Payables Agent is a term, and should not be translated.';
                    }
                }
            }

            group(ChooseDemoOption)
            {
                ShowCaption = false;
                Visible = ChooseDemoOption;
                group(ChooseDemoOptionGeneral)
                {
                    Caption = 'Select how to use the sample invoices';
                    InstructionalText = 'Download sample PDF invoices to upload to the Payables Agent. If email monitoring is configured, you can have the system send the invoices to the monitored mailbox instead.';
                    field(DemoOptionField; DemoOption)
                    {
                        ShowCaption = false;
                        ShowMandatory = true;
                        OptionCaption = ' ,Send sample invoices to monitored email,Download sample invoices to use manually';
                        ToolTip = 'Specifies the preferred way to get the invoices';
                    }
                }
            }
            group(ShowDemoFilesToDownload)
            {
                ShowCaption = false;
                Visible = ShowDemoFilesToDownloadVisible;
                group(ShowDemoFilesToDownloadGeneral)
                {
                    Caption = 'Download sample invoices';
                    InstructionalText = 'Select and download sample invoices (PDFs) below. Each PDF represents a scenario for the agent. Upload a PDF from the Payables Agent setup page when available or from the Purchase Invoices list. If email monitoring is configured, you can also send it to the monitored mailbox.';
                }
                group(ShowDemoFilesToDownloadClicker)
                {
                    ShowCaption = false;
                    field(DemoFilesToDownloadControl; DemoFilesToDownloadText)
                    {
                        ShowCaption = false;
                        StyleExpr = true;
                        Style = StandardAccent;
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            PADemoGuide.ShowDemoFilesToDownload();
                        end;
                    }
                }
            }

            group(FinishedStepGeneral)
            {
                ShowCaption = false;
                Visible = FinishActionEnabled;
                group(FinishedHeadlineGroup)
                {
                    ShowCaption = false;
                    field(FinalStepHeadlineField; FinalStepHeadline)
                    {
                        ShowCaption = false;
                        Editable = false;
                        MultiLine = true;
                        StyleExpr = true;
                        Style = Strong;
                    }
                }
                group(FinishedTextGroup)
                {
                    ShowCaption = false;
                    field(FinalStepTextField; FinalStepText)
                    {
                        ShowCaption = false;
                        Editable = false;
                        MultiLine = true;
                    }
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
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;
                trigger OnAction();
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;
                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }
    trigger OnInit();
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage();
    begin
        PATelemetry.LogDemoGuideOpened();
        Commit();
        if not SetupConfigurationProvided then begin
            PATelemetry.LogDemoGuideMissingSetup();
            PASetupUpdateParameters.InitializeFromStoredSetup();
        end;

        Step := Step::Start;
        EnableControls();
        DemoFilesToDownloadText := StrSubstNo(DemoFilesToDownloadLbl, PADemoGuide.GetDemoFilesToDownloadCount());
    end;

    var
        MediaRepositoryDone: Record "Media Repository";
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesFinished: Record "Media Resources";
        MediaResourcesStd: Record "Media Resources";
        PADemoGuide: Codeunit "PA Demo Guide";
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PATelemetry: Codeunit "PA Telemetry";
        DemoOption: Option " ","Send Demo Email","Download Demo PDFs";
        Step: Option Start,ChooseDemoOption,ShowDemoFilesToDownload,Finish;
        BackActionEnabled, FinishActionEnabled, NextActionEnabled, WelcomeStepVisible, ChooseDemoOption, ShowDemoFilesToDownloadVisible, TopBannerVisible : Boolean;
        SetupConfigurationProvided, DemoInvoicesHandled, DemoEmailSent : Boolean;
        DemoFilesToDownloadText, FinalStepHeadline, FinalStepText : Text;
        DemoFilesToDownloadLbl: Label 'Click here to select and download sample invoices (%1 file(s) available)', Comment = '%1 = number of files';
        FinalStepHeadlineEmailLbl: Label 'Sample invoices sent!';
        FinalStepTextEmailLbl: Label 'We have prepared the sample invoices and will send them when the agent is activated. If this is the first time you configure the agent, the agent is activated when you select "Update" on the configuration page. When the agent is activated you should see them appear as tasks on the agent''s avatar in the top right corner of the home screen';
        FinalStepTextEmailSentLbl: Label 'We sent the sample invoices to %1. You should see them appear as tasks on the agent''s avatar in the top right corner of the home screen.', Comment = '%1 = the email address the sample invoices were sent to';
        FinalStepHeadlineDownloadLbl: Label 'Sample invoices downloaded!';
        FinalStepTextDownloadLbl: Label 'You have downloaded sample invoices. Upload a PDF from the Payables Agent setup page when available or from the Purchase Invoices list. If email monitoring is configured, you can also send it to the monitored mailbox.';

    internal procedure SetSetupConfiguration(NewPASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    begin
        PASetupUpdateParameters := NewPASetupUpdateParameters;
        SetupConfigurationProvided := true;
    end;

    local procedure EnableControls();
    begin
        ResetControls();
        case Step of
            Step::Start:
                ShowWelcomeStep();
            Step::ChooseDemoOption:
                ShowChooseDemoOption();
            Step::ShowDemoFilesToDownload:
                ShowDemoFilesToDownloadOption();
            Step::Finish:
                ShowFinish();
        end;
    end;

    local procedure FinishAction();
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        PATelemetry.LogDemoGuideFinished();
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"PA Demo Guide");
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if (Step = Step::ChooseDemoOption) and (not Backwards) then
            RunDemoOption();
        if Backwards then begin
            if Step in [Step::ShowDemoFilesToDownload, Step::Finish] then
                Step := Step::ChooseDemoOption
            else
                Step -= 1
        end else
            if (Step = Step::ChooseDemoOption) and (DemoOption = DemoOption::"Send Demo Email") then
                Step := Step::Finish
            else
                Step += 1;

        EnableControls();
    end;

    local procedure ShowWelcomeStep();
    begin
        WelcomeStepVisible := true;
        ChooseDemoOption := false;
        ShowDemoFilesToDownloadVisible := false;
        BackActionEnabled := false;
        NextActionEnabled := true;
        FinishActionEnabled := false;
    end;

    local procedure ShowChooseDemoOption();
    begin
        WelcomeStepVisible := false;
        ChooseDemoOption := true;
        ShowDemoFilesToDownloadVisible := false;
        BackActionEnabled := true;
        NextActionEnabled := true;
        FinishActionEnabled := false;
    end;

    local procedure ShowDemoFilesToDownloadOption()
    begin
        WelcomeStepVisible := false;
        ChooseDemoOption := false;
        ShowDemoFilesToDownloadVisible := true;
        BackActionEnabled := true;
        NextActionEnabled := true;
        FinishActionEnabled := false;
    end;

    local procedure ShowFinish();
    begin
        WelcomeStepVisible := false;
        ChooseDemoOption := false;
        ShowDemoFilesToDownloadVisible := false;
        BackActionEnabled := true;
        NextActionEnabled := false;
        FinishActionEnabled := true;
    end;

    local procedure ResetControls();
    begin
        FinishActionEnabled := false;
        BackActionEnabled := true;
        NextActionEnabled := true;
        WelcomeStepVisible := false;
        ChooseDemoOption := false;
        ShowDemoFilesToDownloadVisible := false;
    end;

    local procedure LoadTopBanners();
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(CurrentClientType()))
        then
            if MediaResourcesStd.Get(MediaRepositoryStandard."Media Resources Ref") and
                MediaResourcesFinished.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesFinished."Media Reference".HasValue();
    end;

    local procedure RunDemoOption();
    var
        NoOptionChosenErr: Label 'No option chosen. Please select one of the options to continue.';
    begin
        case DemoOption of
            DemoOption::"Send Demo Email":
                SendDemoInvoices();
            DemoOption::"Download Demo PDFs":
                begin
                    FinalStepHeadline := FinalStepHeadlineDownloadLbl;
                    FinalStepText := FinalStepTextDownloadLbl;
                end;
            else
                Error(NoOptionChosenErr);
        end;
    end;

    local procedure SendDemoInvoices()
    var
        EmailNotConfiguredErr: Label 'No email account is configured for the agent. To send sample invoices by email, set up email monitoring on the Payables Agent setup page first, or download the sample invoices and upload a PDF manually.';
    begin
        if not PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters) then
            Error(EmailNotConfiguredErr);
        if not DemoInvoicesHandled then begin
            DemoEmailSent := PADemoGuide.SendDemoInvoicesByEmail(PASetupUpdateParameters);
            DemoInvoicesHandled := true;
            if DemoEmailSent then
                PATelemetry.LogDemoInvoicesSent()
            else
                PATelemetry.LogDemoInvoicesPrepared();
        end;

        FinalStepHeadline := FinalStepHeadlineEmailLbl;
        if DemoEmailSent then
            FinalStepText := StrSubstNo(FinalStepTextEmailSentLbl, PASetupUpdateParameters.GetEmailAccount()."Email Address")
        else
            FinalStepText := FinalStepTextEmailLbl;
    end;
}
#if not CLEAN27
#pragma warning restore AS0050
#endif