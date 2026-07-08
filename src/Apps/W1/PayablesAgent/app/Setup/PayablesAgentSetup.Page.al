// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.EServices.EDocumentConnector.Microsoft365;
using System.Agents;
using System.AI;
using System.Email;
using System.Utilities;

page 3304 "Payables Agent Setup"
{
    PageType = ConfigurationDialog;
    Extensible = false;
    ApplicationArea = All;
    Caption = 'Configure Payables Agent', Comment = 'Payables Agent is a term, and should not be translated.';
    SourceTable = "Payables Agent Setup";
    SourceTableTemporary = true;
    RefreshOnActivate = true;
    InherentEntitlements = X;
    InherentPermissions = X;
    HelpLink = 'https://go.microsoft.com/fwlink/?linkid=2304779';

    layout
    {
        area(Content)
        {
            part(AgentSetupPart; "Agent Setup Part")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
            group(TrialAndCostGroup)
            {
                ShowCaption = false;

                group(TryPayablesAgent)
                {
                    Visible = IsEligibleForTrialVisible;
                    Caption = 'Try the Payables Agent';
                    InstructionalText = 'Get help processing your invoices with AI. It''s free and safe to try.';

                    field(Benefit1; BenefitAddInvoiceLbl)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ToolTip = 'Specifies a benefit of trying the Payables Agent.', Comment = 'Payables Agent is a term, and should not be translated.';
                    }
                    field(Benefit2; BenefitDraftReviewLbl)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ToolTip = 'Specifies a benefit of trying the Payables Agent.', Comment = 'Payables Agent is a term, and should not be translated.';
                    }
                    field(Benefit3; BenefitNoAutoPostLbl)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ToolTip = 'Specifies a benefit of trying the Payables Agent.', Comment = 'Payables Agent is a term, and should not be translated.';
                    }
                    field(Benefit4; BenefitNoDisruptionLbl)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ToolTip = 'Specifies a benefit of trying the Payables Agent.', Comment = 'Payables Agent is a term, and should not be translated.';
                    }
                    group(UploadInvoiceGroup)
                    {
                        Caption = 'Upload invoice to try out agent capabilities';

                        field(SelectFile; SelectedFileName)
                        {
                            Caption = 'Select file';
                            ShowMandatory = true;
                            Editable = false;
                            ToolTip = 'Specifies the PDF invoice file to upload for the Payables Agent trial.', Comment = 'Payables Agent is a term, and should not be translated.';

                            trigger OnAssistEdit()
                            begin
                                UploadTrialInvoiceAndActivateAgent();
                            end;
                        }
                        field(TrySampleInvoices; TrySampleInvoicesLbl)
                        {
                            ShowCaption = false;
                            StyleExpr = true;
                            Style = StandardAccent;
                            Editable = false;
                            ToolTip = 'Opens a guide with sample invoices to try the Payables Agent.', Comment = 'Payables Agent is a term, and should not be translated.';

                            trigger OnDrillDown()
                            begin
                                PADemoGuide.OpenGuidePage();
                            end;
                        }
                    }
                }
                group(PayablesAgentTrialMode)
                {
                    Visible = IsInTrialModeVisible;
                    Caption = 'Payables Agent Trial';
                    InstructionalText = 'Payables Agent is in trial mode. In trial mode the agent does not consume billable AI credits. When ending trial mode, Payables Agent will start to consume billable AI credits.';

                    field(TrialProgress; TrialProgressText)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ToolTip = 'Specifies the number of invoices processed during the trial.';
                    }
                    group(UploadInvoiceInTrialGroup)
                    {
                        Caption = 'Upload invoice to try out agent capabilities';

                        field(SelectFileInTrial; SelectedFileName)
                        {
                            Caption = 'Select file';
                            ShowMandatory = true;
                            Editable = false;
                            ToolTip = 'Specifies the PDF invoice file to upload for the Payables Agent trial.', Comment = 'Payables Agent is a term, and should not be translated.';

                            trigger OnAssistEdit()
                            begin
                                UploadTrialInvoiceAndActivateAgent();
                            end;
                        }
                        field(TrySampleInvoicesInTrial; TrySampleInvoicesLbl)
                        {
                            ShowCaption = false;
                            StyleExpr = true;
                            Style = StandardAccent;
                            Editable = false;
                            ToolTip = 'Opens a guide with sample invoices to try the Payables Agent.', Comment = 'Payables Agent is a term, and should not be translated.';

                            trigger OnDrillDown()
                            begin
                                PADemoGuide.OpenGuidePage();
                            end;
                        }
                    }
                }
                group(CostEstimateGroup)
                {
                    Caption = 'Cost';

                    field(CostEstimateValue; CostEstimateText)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ToolTip = 'Specifies the total number of Copilot credits consumed by the Payables Agent.', Comment = 'Payables Agent is a term, and should not be translated.';
                    }
                    field(AgentTasks; AgentTasksText)
                    {
                        ShowCaption = false;
                        Editable = false;
                        StyleExpr = true;
                        Style = StandardAccent;
                        ToolTip = 'Specifies the number of tasks completed by the Payables Agent. Choose this field to open the agent task list.', Comment = 'Payables Agent is a term, and should not be translated.';

                        trigger OnDrillDown()
                        begin
                            DrillDownAgentTasks();
                        end;
                    }
                    field(InboundEDocuments; InboundEDocumentsText)
                    {
                        ShowCaption = false;
                        Editable = false;
                        StyleExpr = true;
                        Style = StandardAccent;
                        ToolTip = 'Specifies the number of inbound e-documents processed by the Payables Agent. Choose this field to open the list of inbound e-documents.', Comment = 'Payables Agent is a term, and should not be translated.';

                        trigger OnDrillDown()
                        begin
                            DrillDownInboundEDocuments();
                        end;
                    }
                    field(LearnMoreCost; LearnMoreCostLbl)
                    {
                        ShowCaption = false;
                        StyleExpr = true;
                        Style = StandardAccent;
                        Editable = false;
                        ToolTip = 'Opens documentation about consumption-based billing for the Payables Agent.', Comment = 'Payables Agent is a term, and should not be translated.';

                        trigger OnDrillDown()
                        begin
                            Hyperlink(PACostEstimate.GetLearnMoreUrl());
                        end;
                    }
                }
            }
            group(MonitorIncomingGroup)
            {
                Caption = 'Monitor incoming information';
                InstructionalText = 'The agent will read messages in these channels:';
                field(MonitorIncomingEmails; Rec."Monitor Outlook")
                {
                    ShowCaption = false;
                    Caption = 'Monitor emails';
                    ToolTip = 'Specifies whether the agent should monitor incoming emails for PDF document attachments for processing.';

                    trigger OnValidate()
                    begin
                        if Rec."Monitor Outlook" then begin
                            CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
                            if TempAgentSetupBuffer.State <> TempAgentSetupBuffer.State::Enabled then
                                TempAgentSetupBuffer.Validate(State, TempAgentSetupBuffer.State::Enabled);
                            TempAgentSetupBuffer.Modify();
                            CurrPage.AgentSetupPart.Page.SetAgentSetupBuffer(TempAgentSetupBuffer);
                            CurrPage.AgentSetupPart.Page.Update();
                        end;
                        SetupChanged := true;
                        CalcOpenAgentDemoGuideVisible();
                        CurrPage.Update();
                    end;
                }
                group(MonitorEmailSettings)
                {
                    Caption = 'Mailbox';
                    field(MailEnabled; Rec."Monitor Outlook")
                    {
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies if the mailbox will be monitored.';
                    }
                    field(Mailbox; MailboxAddress)
                    {
                        Caption = 'Email account';
                        ToolTip = 'Specifies the Microsoft 365 mailbox from which to download PDF document attachments.';
                        Editable = false;
                        ShowMandatory = true;

                        trigger OnAssistEdit()
                        var
                            TempEmailAccount: Record "Email Account" temporary;
                            OutlookIntegration: Codeunit "Outlook Integration Impl.";
                            PrevAccountId: Guid;
                        begin
                            PrevAccountId := TempOutlookSetup."Email Account ID";
                            TempEmailAccount."Account Id" := TempOutlookSetup."Email Account ID";
                            TempEmailAccount.Connector := TempOutlookSetup."Email Connector";
                            if OutlookIntegration.SelectEmailAccount(TempEmailAccount) then begin
                                TempOutlookSetup."Email Account ID" := TempEmailAccount."Account Id";
                                TempOutlookSetup."Email Connector" := TempEmailAccount.Connector;
                                MailboxAddress := TempEmailAccount."Email Address";
                                if PrevAccountId <> TempOutlookSetup."Email Account ID" then begin
                                    Clear(TempOutlookSetup."Email Folder");
                                    Clear(TempOutlookSetup."Email Folder Id");
                                end;
                                SetupChanged := true;
                                CalcOpenAgentDemoGuideVisible();
                                CurrPage.Update();
                            end;
                        end;
                    }
                    field(MailboxFolder; TempOutlookSetup."Email Folder")
                    {
                        Caption = 'Folder';
                        ToolTip = 'Specifies the email folder that the agent monitors. Leave blank to monitor the entire mailbox. When a folder is set and email review is ''Only if untrusted'', every email in it is treated as trusted and skips review, so the known-senders list is not consulted.';
                        Editable = false;

                        trigger OnAssistEdit()
                        var
                            TempEmailFolder: Record "Email Folders" temporary;
                            EmailFolders: Page "Email Account Folders";
                        begin
                            if IsNullGuid(TempOutlookSetup."Email Account ID") then
                                Error(SelectMailboxFirstErr);

                            EmailFolders.LookupMode(true);
                            EmailFolders.SetEmailAccount(TempOutlookSetup."Email Account ID", TempOutlookSetup."Email Connector");
                            if EmailFolders.RunModal() = Action::LookupOK then begin
                                EmailFolders.GetRecord(TempEmailFolder);
                                TempOutlookSetup."Email Folder" := TempEmailFolder."Folder Name";
                                TempOutlookSetup."Email Folder Id" := TempEmailFolder."Id";
                                SetupChanged := true;
                                CurrPage.Update();
                            end;
                        end;
                    }
                    field(Tip; SharedMailboxTipLbl)
                    {
                        Caption = '';
                        ShowCaption = false;
                        MultiLine = true;
                        Editable = false;
                        ToolTip = 'Specifies the tip to use a dedicated shared mailbox.';
                    }
                }
                group(BillingInformationFirstSetup)
                {
                    InstructionalText = 'By enabling the Payables Agent, you understand your organization may be billed for its use when not in trial mode.';
                    Caption = 'Important';
                    field(LearnMoreBilling; LearnMoreTxt)
                    {
                        ShowCaption = false;
                        Editable = false;
                        trigger OnDrillDown()
                        begin
                            Hyperlink(LearnMoreBillingDocumentationLinkTxt);
                        end;
                    }
                }
            }
            group(PayableAgentDemoGuideExperienceGroup)
            {
                Caption = 'Get sample invoices';
                group(DemoGuideExperience)
                {
                    ShowCaption = false;
                    InstructionalText = 'Try the Payables Agent with these sample invoices. Run this guide to get started.';
                    Visible = OpenAgentDemoGuideVisible;
                    field(OpenAgentDemoGuideField; OpenAgentDemoGuideLbl)
                    {
                        ShowCaption = false;
                        StyleExpr = true;
                        Style = StandardAccent;
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            PADemoGuide.OpenGuidePage();
                        end;
                    }
                }
            }
            group(BCDocumentCreation)
            {
                Caption = 'Document processing';
                group(ProcessNewTaskGroup)
                {
                    Caption = 'Email review';
                    InstructionalText = 'Choose when the agent should request a human review before processing an incoming email.';

                    field(ReviewEmailPolicy; Rec."Email Review Policy")
                    {
                        Caption = 'Email review';
                        ShowMandatory = true;
                        ToolTip = 'Specifies when the agent should request human review before processing an incoming email. ''Only if untrusted'' skips review for previously approved senders and any email that arrives in a configured subfolder.';

                        trigger OnValidate()
                        begin
                            SetupChanged := true;
                            CurrPage.Update();
                        end;
                    }
                    field(ManageKnownSenders; ManageKnownSendersLbl)
                    {
                        ShowCaption = false;
                        StyleExpr = true;
                        Style = StandardAccent;
                        Editable = false;
                        ToolTip = 'Opens the list of senders the Payables Agent has previously processed.', Comment = 'Payables Agent is a term, and should not be translated.';

                        trigger OnDrillDown()
                        begin
                            Page.RunModal(Page::"PA Known Senders");
                        end;
                    }
                    field(KnownSendersHint; KnownSendersHintLbl)
                    {
                        ShowCaption = false;
                        MultiLine = true;
                        Editable = false;
                        ToolTip = 'Explains how the known-senders list interacts with the monitored subfolder.';
                    }
                }
                group(AdditionalFields)
                {
                    Caption = 'Configure additional fields';
                    InstructionalText = 'When you turn a draft into an invoice, Payables Agent suggests field values from a matching invoice. You can add more field values if needed.';
                    field("Purchase Line Fields"; AddFieldsLbl)
                    {
                        Caption = '';
                        ShowCaption = false;
                        ToolTip = 'Specifies the additional fields to consider from the purchase lines when creating purchase documents.';
                        Editable = false;

                        trigger OnDrillDown()
                        var
                            PayablesAgentSetup: Codeunit "Payables Agent Setup";
                            EDocAdditionalFieldsSetup: Page "EDoc Additional Fields Setup";
                        begin
                            EDocAdditionalFieldsSetup.SetEDocumentService(PayablesAgentSetup.GetOrCreateAgentEDocumentService());
                            Commit();
                            EDocAdditionalFieldsSetup.LookupMode := true;
                            if EDocAdditionalFieldsSetup.RunModal() = Action::LookupOK then
                                SetupChanged := true;
                        end;
                    }
                }
            }
        }
    }
    actions
    {
        area(SystemActions)
        {
            systemaction(OK)
            {
                Caption = 'Update';
                Enabled = SetupChanged;
                ToolTip = 'Apply the changes to the agent setup.';
            }

            systemaction(Cancel)
            {
                Caption = 'Cancel';
                ToolTip = 'Discard the changes to the agent setup.';
            }
        }
    }

    trigger OnOpenPage()
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
    begin
        if not AzureOpenAI.IsEnabled("Copilot Capability"::"Payables Agent") then
            Error(EnableCapabilityFirstErr);

        PayablesAgentSetup.LoadSetupConfiguration(PASetupConfiguration);
        PASetupConfiguration.GetAgentSetupBuffer(TempAgentSetupBuffer);
        CurrPage.AgentSetupPart.Page.SetAgentSetupBuffer(TempAgentSetupBuffer);
        CurrPage.AgentSetupPart.Page.Update();
        Rec := PASetupConfiguration.GetPayablesAgentSetup();
        TempEDocumentService := PASetupConfiguration.GetEDocumentService();
        TempOutlookSetup := PASetupConfiguration.GetOutlookSetup();
        MailboxAddress := PASetupConfiguration.GetEmailAccount()."Email Address";
        CalcOpenAgentDemoGuideVisible();
        CalcTrialExperienceVisible();
        CalcCostEstimate();
        if TrialExperienceVisible then
            CurrPage.Caption(ExplorePayablesAgentCaptionLbl);
        if Rec.Insert() then;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        SetupChanged := true;
        if xRec."Monitor Outlook" <> Rec."Monitor Outlook" then begin
            CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
            if (not Rec."Monitor Outlook") and (TempAgentSetupBuffer.State = TempAgentSetupBuffer.State::Enabled) then
                SkipAutosetOfMonitorOutlook := true;
        end;
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
        SetupChanged := SetupChanged or AgentSetup.GetChangesMade(TempAgentSetupBuffer);
        if TempAgentSetupBuffer."State Updated" then
            if TempAgentSetupBuffer.State = TempAgentSetupBuffer.State::Enabled then begin
                if not SkipAutosetOfMonitorOutlook then
                    Rec."Monitor Outlook" := true
                else
                    SkipAutosetOfMonitorOutlook := false;
            end
            else
                Rec."Monitor Outlook" := false;

        if (TempAgentSetupBuffer."State Updated") and (TempAgentSetupBuffer.State = TempAgentSetupBuffer.State::Disabled) and (not OCVFeedbackAsked) then begin
            PayablesAgentOCV.TriggerDisableAgentFeedback();
            OCVFeedbackAsked := true;
        end;
        CalcTrialExperienceVisible();
        CalcCostEstimate();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if PASetupConfiguration.GetTrialUploadPending() then begin
            CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
            TempAgentSetupBuffer.Validate(State, TempAgentSetupBuffer.State::Enabled);
            TempAgentSetupBuffer.Modify();
            CurrPage.AgentSetupPart.Page.SetAgentSetupBuffer(TempAgentSetupBuffer);
            ApplySetup();
            ProcessTrialUploadIfPending();
            exit(true);
        end;

        // Save the changes made to the agent setup buffer
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
        SetupChanged := SetupChanged or AgentSetup.GetChangesMade(TempAgentSetupBuffer);

        if (CloseAction = CloseAction::Cancel) or (not SetupChanged) then
            exit(true);

        if not ConfirmPendingChanges() then
            exit(false);

        ApplySetup();
        exit(true);
    end;

    local procedure ConfirmPendingChanges(): Boolean
    var
        Impact: Enum "PA Setup Change Impact";
        SendersCount: Integer;
    begin
        Impact := PayablesAgentSetup.ClassifyKnownSendersUnusedByChange(Rec."Email Review Policy", TempOutlookSetup."Email Folder", SendersCount);
        if SendersCount = 0 then
            exit(true);

        case Impact of
            Impact::KnownSendersIgnoredByFolder:
                exit(Confirm(FolderIgnoresListConfirmLbl, false, SendersCount, TempOutlookSetup."Email Folder"));
            Impact::KnownSendersIgnoredByPolicy:
                exit(Confirm(PolicyIgnoresListConfirmLbl, false, SendersCount, PayablesAgentSetup.PolicyLabel(Rec."Email Review Policy")));
        end;

        exit(true);
    end;

    local procedure ApplySetup()
    begin
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
        PASetupConfiguration.SetAgentSetupBuffer(TempAgentSetupBuffer);
        PASetupConfiguration.SetPayablesAgentSetup(Rec);
        PASetupConfiguration.SetEDocumentService(TempEDocumentService);
        PASetupConfiguration.SetOutlookSetup(TempOutlookSetup);
        PayablesAgentSetup.ApplyPayablesAgentSetup(PASetupConfiguration);
    end;

    local procedure CalcOpenAgentDemoGuideVisible()
    begin
        OpenAgentDemoGuideVisible := PADemoGuide.DemoExperienceAvailable() and not (PATrial.IsEligibleToStart() or PATrial.IsActive());
    end;

    local procedure CalcTrialExperienceVisible()
    begin
        IsEligibleForTrialVisible := PATrial.IsEligibleToStart();
        IsInTrialModeVisible := PATrial.IsActive();
        TrialExperienceVisible := IsEligibleForTrialVisible or IsInTrialModeVisible;
        if IsInTrialModeVisible then
            TrialProgressText := StrSubstNo(TrialProgressLbl, PATrial.GetTrialInvoiceCount(), PATrial.GetTrialInvoiceLimit());

    end;

    local procedure CalcCostEstimate()
    var
        CreditsConsumed: Decimal;
    begin
        CreditsConsumed := PACostEstimate.GetCreditsConsumed();
        CostEstimateText := PACostEstimate.FormatCreditsConsumed(CreditsConsumed);
        CalcAgentTasks();
        CalcInboundEDocuments();
    end;

    local procedure CalcAgentTasks()
    var
        AgentTask: Record "Agent Task";
        PayablesAgentSetupRec: Record "Payables Agent Setup";
        TaskCount: Integer;
    begin
        PayablesAgentSetupRec.GetSetup();
        if IsNullGuid(PayablesAgentSetupRec."User Security Id") then begin
            AgentTasksText := StrSubstNo(AgentTasksLbl, 0);
            exit;
        end;
        AgentTask.SetRange("Agent User Security ID", PayablesAgentSetupRec."User Security Id");
        TaskCount := AgentTask.Count();
        AgentTasksText := StrSubstNo(AgentTasksLbl, TaskCount);
    end;

    local procedure DrillDownAgentTasks()
    var
        AgentTask: Record "Agent Task";
        PayablesAgentSetupRec: Record "Payables Agent Setup";
        AgentTaskList: Page "Agent Task List";
    begin
        PayablesAgentSetupRec.GetSetup();
        if not IsNullGuid(PayablesAgentSetupRec."User Security Id") then
            AgentTask.SetRange("Agent User Security ID", PayablesAgentSetupRec."User Security Id");
        AgentTaskList.SetTableView(AgentTask);
        AgentTaskList.Run();
    end;

    local procedure CalcInboundEDocuments()
    var
        EDocument: Record "E-Document";
        EDocCount: Integer;
    begin
        EDocument.SetRange(Direction, "E-Document Direction"::Incoming);
        EDocument.SetRange(Service, PayablesAgentSetup.GetAgentEDocumentServiceCode());
        EDocCount := EDocument.Count();
        InboundEDocumentsText := StrSubstNo(InboundEDocumentsLbl, EDocCount);
    end;

    local procedure DrillDownInboundEDocuments()
    var
        EDocument: Record "E-Document";
        InboundEDocumentsPage: Page "Inbound E-Documents";
    begin
        EDocument.SetRange(Service, PayablesAgentSetup.GetAgentEDocumentServiceCode());
        InboundEDocumentsPage.SetTableView(EDocument);
        InboundEDocumentsPage.Run();
    end;

    /// <summary>
    /// Process trial invoice
    /// </summary>
    local procedure ProcessTrialUploadIfPending()
    var
        TempBlob: Codeunit "Temp Blob";
        PayablesAgent: Codeunit "Payables Agent";
        FileName: Text;
        InStream: InStream;
    begin
        if not PASetupConfiguration.GetTrialUploadPending() then
            exit;

        FileName := PASetupConfiguration.GetTrialUploadFileName();
        PASetupConfiguration.GetTrialUploadBlob(TempBlob);
        TempBlob.CreateInStream(InStream);
        PayablesAgentSetup.ImportInvoiceFile(FileName, InStream);
        Session.LogMessage('0000SEG', TryWithUploadManuallyTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PayablesAgent.GetCustomDimensions());

        PASetupConfiguration.ClearTrialUpload();
    end;

    /// <summary>
    /// This function uploads an invoice.
    /// When the invoice is loaded, the agent is activated and the curr page is closed.
    /// </summary>
    local procedure UploadTrialInvoiceAndActivateAgent()
    var
        FileName: Text;
        InStream: InStream;
    begin
        if not UploadIntoStream(SelectFileLbl, '', PdfFileFilterLbl, FileName, InStream) then
            exit;
        SelectedFileName := CopyStr(FileName, 1, MaxStrLen(SelectedFileName));

        PASetupConfiguration.SetTrialUpload(FileName, InStream);
        Rec."Monitor Outlook" := false;
        Rec."Review Incoming Invoice" := false;
        SetupChanged := true;
        CurrPage.Close();
    end;



    var
        TempEDocumentService: Record "E-Document Service" temporary;
        TempOutlookSetup: Record "Outlook Setup" temporary;
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        AgentSetup: Codeunit "Agent Setup";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        PASetupConfiguration: Codeunit "PA Setup Configuration";
        PADemoGuide: Codeunit "PA Demo Guide";
        PayablesAgentOCV: Codeunit "Payables Agent OCV";
        PATrial: Codeunit "PA Trial";
        PACostEstimate: Codeunit "PA Cost Estimate";
        SelectedFileName: Text[250];
        MailboxAddress: Text;
        TrialProgressText: Text;
        CostEstimateText: Text;
        AgentTasksText: Text;
        InboundEDocumentsText: Text;
        TrialExperienceVisible: Boolean;
        IsEligibleForTrialVisible: Boolean;
        IsInTrialModeVisible: Boolean;
        SetupChanged, OCVFeedbackAsked : Boolean;
        OpenAgentDemoGuideVisible, SkipAutosetOfMonitorOutlook : Boolean;
        LearnMoreTxt: Label 'Learn more';
        LearnMoreCostLbl: Label 'Learn more about cost';
        AddFieldsLbl: Label 'Add fields';
        LearnMoreBillingDocumentationLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2333517';
        EnableCapabilityFirstErr: Label 'The Payables Agent capability is not configured. Please activate the Copilot capability.', Comment = 'Payables Agent is a term, and should not be translated.';
        SharedMailboxTipLbl: Label 'The agent reads all PDF attachments from the specified mailbox. Therefore, we recommend using a dedicated shared mailbox for receiving payables documents.';
        SelectMailboxFirstErr: Label 'Select an email account before choosing a folder.';
        OpenAgentDemoGuideLbl: Label 'Sample invoice guide';
        TrySampleInvoicesLbl: Label 'Try some sample invoices';
        TryWithUploadManuallyTok: Label 'User uploaded a file to try the agent.', Locked = true;
        TrialProgressLbl: Label 'Invoices processed in trial mode: %1 of %2', Comment = '%1 is current count, %2 is limit';
        ExplorePayablesAgentCaptionLbl: Label 'Explore Payables Agent', Comment = 'Payables Agent is a term, and should not be translated.';
        BenefitAddInvoiceLbl: Label '• Add a PDF invoice to get started';
        BenefitDraftReviewLbl: Label '• The agent creates a draft for your review';
        BenefitNoAutoPostLbl: Label '• Nothing is posted automatically';
        BenefitNoDisruptionLbl: Label '• No disruption to your current process';
        SelectFileLbl: Label 'Select file';
        PdfFileFilterLbl: Label 'PDF Files (*.pdf)|*.pdf';
        InboundEDocumentsLbl: Label 'Based on %1 inbound e-documents', Comment = '%1 is the number of inbound e-documents processed by the agent.';
        AgentTasksLbl: Label '%1 agent tasks', Comment = '%1 is the number of tasks completed by the agent.';
        ManageKnownSendersLbl: Label 'Manage known senders';
        KnownSendersHintLbl: Label 'Add your regular senders and set the review policy for each. Approve emails automatically for senders you trust.';
        FolderIgnoresListConfirmLbl: Label 'You have %1 known senders. With subfolder ''%2'' configured, the agent will process every email there without consulting the list. The list is kept and will be used again if you remove the subfolder. Continue?', Comment = '%1 = number of known senders, %2 = folder name';
        PolicyIgnoresListConfirmLbl: Label 'You have %1 known senders. The list won''t affect processing while review is set to ''%2''. The list is kept and will be used again if you switch back to ''Only if untrusted''. Continue?', Comment = '%1 = number of known senders, %2 = review policy';

}