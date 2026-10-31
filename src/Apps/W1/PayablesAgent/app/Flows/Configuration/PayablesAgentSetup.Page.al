// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.AI;
using System.Email;

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
                                OpenDemoGuide();
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
                                OpenDemoGuide();
                            end;
                        }
                    }
                }
#if not CLEAN29
                group(CostEstimateGroup)
                {
                    Caption = 'Cost';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The consumed credits information is no longer available.';
                    ObsoleteTag = '29.0';

                    field(CostEstimateValue; CostEstimateText)
                    {
                        ShowCaption = false;
                        Editable = false;
                        ToolTip = 'Specifies the total number of Copilot credits consumed by the Payables Agent.', Comment = 'Payables Agent is a term, and should not be translated.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'The consumed credits information is no longer available.';
                        ObsoleteTag = '29.0';
                    }
                    field(LearnMoreCost; LearnMoreCostLbl)
                    {
                        ShowCaption = false;
                        StyleExpr = true;
                        Style = StandardAccent;
                        Editable = false;
                        ToolTip = 'Opens documentation about consumption-based billing for the Payables Agent.', Comment = 'Payables Agent is a term, and should not be translated.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'The consumed credits information is no longer available.';
                        ObsoleteTag = '29.0';
                    }
                }
#endif
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
                            SelectedAccountId: Guid;
                            SelectedAddress: Text;
                            PrevAccountId: Guid;
                        begin
                            PrevAccountId := Rec."Email Account Id";
                            SelectedAccountId := Rec."Email Account Id";
                            if SelectEmailAccount(SelectedAccountId, SelectedAddress) then begin
                                Rec."Email Account Id" := SelectedAccountId;
                                MailboxAddress := SelectedAddress;
                                if PrevAccountId <> Rec."Email Account Id" then begin
                                    Clear(Rec."Email Folder");
                                    Clear(Rec."Email Folder Id");
                                end;
                                SetupChanged := true;
                                CalcOpenAgentDemoGuideVisible();
                                CurrPage.Update();
                            end;
                        end;
                    }
                    field(MailboxFolder; Rec."Email Folder")
                    {
                        Caption = 'Folder';
                        ToolTip = 'Specifies the email folder that the agent monitors. Leave blank to monitor the entire mailbox. When a folder is set and email review is ''Manage per sender'', every email in it is treated as trusted and skips review, so the known-senders list is not consulted.';
                        Editable = false;

                        trigger OnAssistEdit()
                        var
                            TempEmailFolder: Record "Email Folders" temporary;
                            EmailFolders: Page "Email Account Folders";
                        begin
                            if IsNullGuid(Rec."Email Account Id") then
                                Error(SelectMailboxFirstErr);

                            EmailFolders.LookupMode(true);
                            EmailFolders.SetEmailAccount(Rec."Email Account Id", "Email Connector"::"Microsoft 365");
                            if EmailFolders.RunModal() = Action::LookupOK then begin
                                EmailFolders.GetRecord(TempEmailFolder);
                                Rec."Email Folder" := TempEmailFolder."Folder Name";
                                Rec."Email Folder Id" := TempEmailFolder."Id";
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
                            OpenDemoGuide();
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
                        ToolTip = 'Specifies when the agent should request human review before processing an incoming email. ''Manage per sender'' skips review for previously approved senders and any email that arrives in a configured subfolder.';

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
                    Visible = AdditionalFieldsSetupVisible;

                    field("Purchase Line Fields"; AddFieldsLbl)
                    {
                        Caption = '';
                        ShowCaption = false;
                        ToolTip = 'Specifies the additional fields to consider from the purchase lines when creating purchase documents.';
                        Editable = false;

                        trigger OnDrillDown()
                        begin
                            if PASetupPresentation.OpenAdditionalFieldsSetup() then
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

        PASetupUpdateParameters.InitializeFromStoredSetup();
        PASetupUpdateParameters.GetAgentSetupBuffer(TempAgentSetupBuffer);
        CurrPage.AgentSetupPart.Page.SetAgentSetupBuffer(TempAgentSetupBuffer);
        CurrPage.AgentSetupPart.Page.Update();
        PASetupUpdateParameters.GetDesiredSetup(PASetup);
        Rec := PASetup.GetPageRecord();
        AdditionalFieldsSetupVisible := PASetup.SupportsAdditionalFields();
        MailboxAddress := PASetupUpdateParameters.GetEmailAccount()."Email Address";
        CalcOpenAgentDemoGuideVisible();
        CalcTrialExperienceVisible();
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
                    Rec."Monitor Outlook" := PASetup.SupportsEmailMonitoring()
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
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if PASetupUpdateParameters.GetTrialUploadPending() then begin
            CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
            TempAgentSetupBuffer.Validate(State, TempAgentSetupBuffer.State::Enabled);
            TempAgentSetupBuffer.Modify();
            CurrPage.AgentSetupPart.Page.SetAgentSetupBuffer(TempAgentSetupBuffer);
            // Applying the setup also hands the pending trial upload to the agent.
            ApplySetup();
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

    var
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        AgentSetup: Codeunit "Agent Setup";
        PASetupPresentation: Codeunit "PA Setup Presentation";
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PASetup: Codeunit "PA Setup";
        PASetupUpdate: Codeunit "PA Setup Update";
        PADemoGuide: Codeunit "PA Demo Guide";
        PayablesAgentOCV: Codeunit "Payables Agent OCV";
        PATrial: Codeunit "PA Trial";
        SelectedFileName: Text[250];
        MailboxAddress: Text;
        TrialProgressText: Text;
#if not CLEAN29
        CostEstimateText: Text;
#endif
        AdditionalFieldsSetupVisible: Boolean;
        TrialExperienceVisible: Boolean;
        IsEligibleForTrialVisible: Boolean;
        IsInTrialModeVisible: Boolean;
        SetupChanged, OCVFeedbackAsked : Boolean;
        OpenAgentDemoGuideVisible, SkipAutosetOfMonitorOutlook : Boolean;
        LearnMoreTxt: Label 'Learn more';
#if not CLEAN29
        LearnMoreCostLbl: Label 'Learn more about cost';
#endif
        AddFieldsLbl: Label 'Add fields';
        LearnMoreBillingDocumentationLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2333517';
        EnableCapabilityFirstErr: Label 'The Payables Agent capability is not configured. Please activate the Copilot capability.', Comment = 'Payables Agent is a term, and should not be translated.';
        SharedMailboxTipLbl: Label 'The agent reads all PDF attachments from the specified mailbox. Therefore, we recommend using a dedicated shared mailbox for receiving payables documents.';
        SelectMailboxFirstErr: Label 'Select an email account before choosing a folder.';
        OpenAgentDemoGuideLbl: Label 'Sample invoice guide';
        TrySampleInvoicesLbl: Label 'Try some sample invoices';
        TrialProgressLbl: Label 'Invoices processed in trial mode: %1 of %2', Comment = '%1 is current count, %2 is limit';
        ExplorePayablesAgentCaptionLbl: Label 'Explore Payables Agent', Comment = 'Payables Agent is a term, and should not be translated.';
        BenefitAddInvoiceLbl: Label '• Add a PDF invoice to get started';
        BenefitDraftReviewLbl: Label '• The agent creates a draft for your review';
        BenefitNoAutoPostLbl: Label '• Nothing is posted automatically';
        BenefitNoDisruptionLbl: Label '• No disruption to your current process';
        SelectFileLbl: Label 'Select file';
        PdfFileFilterLbl: Label 'PDF Files (*.pdf)|*.pdf';
        ManageKnownSendersLbl: Label 'Manage known senders';
        KnownSendersHintLbl: Label 'Add your regular senders and set the review policy for each. Approve emails automatically for senders you trust.';
        FolderIgnoresListConfirmLbl: Label 'You have %1 known senders. With subfolder ''%2'' configured, the agent will process every email there without consulting the list. The list is kept and will be used again if you remove the subfolder. Continue?', Comment = '%1 = number of known senders, %2 = folder name';
        PolicyIgnoresListConfirmLbl: Label 'You have %1 known senders. The list won''t affect processing while review is set to ''%2''. The list is kept and will be used again if you switch back to ''Manage per sender''. Continue?', Comment = '%1 = number of known senders, %2 = review policy';


    local procedure ConfirmPendingChanges(): Boolean
    var
        Impact: Enum "PA Setup Change Impact";
        SendersCount: Integer;
    begin
        Impact := PASetupPresentation.ClassifyKnownSendersUnusedByChange(Rec."Email Review Policy", Rec."Email Folder", SendersCount);
        if SendersCount = 0 then
            exit(true);
        case Impact of
            Impact::KnownSendersIgnoredByFolder:
                exit(Confirm(FolderIgnoresListConfirmLbl, false, SendersCount, Rec."Email Folder"));
            Impact::KnownSendersIgnoredByPolicy:
                exit(Confirm(PolicyIgnoresListConfirmLbl, false, SendersCount, PASetupPresentation.PolicyLabel(Rec."Email Review Policy")));
        end;

        exit(true);
    end;

    local procedure ApplySetup()
    begin
        BuildSetupConfiguration();
        PASetupUpdate.Update(PASetupUpdateParameters);
    end;

    local procedure BuildSetupConfiguration()
    begin
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
        PASetupUpdateParameters.SetAgentSetupBuffer(TempAgentSetupBuffer);
        PASetupUpdateParameters.SetMonitorEmail(Rec."Monitor Outlook");
        PASetupUpdateParameters.SetEmailReviewPolicy(Rec."Email Review Policy");
        PASetupUpdateParameters.SetMailboxSelection(Rec."Email Account Id", Rec."Email Folder", Rec."Email Folder Id");
    end;

    local procedure SelectEmailAccount(var EmailAccountId: Guid; var EmailAddress: Text): Boolean
    var
        TempEmailAccount: Record "Email Account" temporary;
        EmailAccounts: Page "Email Accounts";
        Microsoft365AccountRequiredErr: Label 'Select a Microsoft 365 email account.';
    begin
        if not HasMicrosoft365EmailAccount() then begin
            Page.RunModal(Page::"Email Account Wizard");
            if not HasMicrosoft365EmailAccount() then
                exit(false);
        end;

        EmailAccounts.SetShowCreateAccount(true);
        EmailAccounts.EnableLookupMode();
        EmailAccounts.FilterConnectorV4Accounts(true);
        if EmailAccounts.RunModal() <> Action::LookupOK then
            exit(false);

        EmailAccounts.GetAccount(TempEmailAccount);
        if IsNullGuid(TempEmailAccount."Account Id") then
            exit(false);
        if TempEmailAccount.Connector <> "Email Connector"::"Microsoft 365" then
            Error(Microsoft365AccountRequiredErr);
        EmailAccountId := TempEmailAccount."Account Id";
        EmailAddress := TempEmailAccount."Email Address";
        exit(true);
    end;

    local procedure HasMicrosoft365EmailAccount(): Boolean
    var
        TempEmailAccounts: Record "Email Account" temporary;
        EmailAccount: Codeunit "Email Account";
    begin
        EmailAccount.GetAllAccounts(false, TempEmailAccounts);
        TempEmailAccounts.SetRange(Connector, "Email Connector"::"Microsoft 365");
        exit(not TempEmailAccounts.IsEmpty());
    end;

    local procedure OpenDemoGuide()
    begin
        BuildSetupConfiguration();
        PADemoGuide.OpenGuidePage(PASetupUpdateParameters);
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

        PASetupUpdateParameters.SetTrialUpload(FileName, InStream);
        Rec."Monitor Outlook" := false;
        SetupChanged := true;
        CurrPage.Close();
    end;


}