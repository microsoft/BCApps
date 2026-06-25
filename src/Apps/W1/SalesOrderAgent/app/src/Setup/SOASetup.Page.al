// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
#pragma warning disable AS0032 // TODO: Remove after porting to 27.x

namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.AI;
using System.Email;
using System.Security.AccessControl;
using System.Telemetry;

page 4400 "SOA Setup"
{
    PageType = ConfigurationDialog;
    Extensible = false;
    ApplicationArea = All;
    Caption = 'Configure Sales Order Agent';
    InstructionalText = 'Choose how the agent helps with inquiries, quotes, and orders.';
    AdditionalSearchTerms = 'Sales order agent, Copilot agent, Agent, SOA';
    SourceTable = "SOA Setup";
    SourceTableTemporary = true;
    RefreshOnActivate = true;
    InherentEntitlements = X;
    InherentPermissions = X;
    HelpLink = 'https://go.microsoft.com/fwlink/?linkid=2281481';

    layout
    {
        area(Content)
        {
            part(AgentSetupPart; "Agent Setup Part")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
            group(GeneralCard)
            {
                Caption = 'Identity and monitoring';
                InstructionalText = 'Name the agent and choose initials to distinguish it.';

                field(AgentName; Rec."Agent Name")
                {
                    ApplicationArea = All;
                    Caption = 'Display name';
                    ToolTip = 'Specifies the unique display name for this Sales Order Agent instance.';

                    trigger OnValidate()
                    begin
                        ConfigUpdated();
                    end;
                }
                field(AgentInitials; Rec."Agent Initials")
                {
                    ApplicationArea = All;
                    Caption = 'Initials';
                    ToolTip = 'Specifies the initials for this Sales Order Agent instance. Maximum 4 characters.';

                    trigger OnValidate()
                    begin
                        ConfigUpdated();
                    end;
                }
                group(MailboxGroup)
                {
                    Caption = 'Monitor and process emails';
                    field(MailEnabled; Rec."Email Monitoring")
                    {
                        ShowCaption = false;
                        ToolTip = 'Specifies if the agent should monitor incoming emails and process them.';

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                    field(Mailbox; MailboxName)
                    {
                        Caption = 'Account';
                        ToolTip = 'Specifies the email account that the agent monitors. You need permission to the mailbox to activate the agent.';
                        Editable = false;
                        ShowMandatory = true;

                        trigger OnAssistEdit()
                        begin
                            OnAssistEditMailbox();
                        end;

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                    field(MailboxFolder; MailboxFolder)
                    {
                        Caption = 'Folder';
                        ToolTip = 'Specifies the email folder that the agent monitors. You need permission to the mailbox to activate the agent.';
                        Editable = false;

                        trigger OnAssistEdit()
                        begin
                            OnAssistEditMailboxFolder();
                        end;

                    }
                }
                group(QuickTryAgentTask)
                {
                    Caption = 'Try it out';
                    InstructionalText = 'Create a task to see the agent in action. You choose the sender, message, and attachments; the agent responds.';
                    field(SOACreateTask; SOACreateTaskLbl)
                    {
                        ShowCaption = false;
                        StyleExpr = true;
                        Style = StandardAccent;
                        Editable = false;
                        ToolTip = 'Create a new task for the Sales Order Agent by entering the sender, message text, and any attachments.';

                        trigger OnDrillDown()
                        var
                            SOACreateTask: Page "SOA Create Task";
                        begin
                            CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
                            if (TempAgentSetupBuffer.State <> TempAgentSetupBuffer.State::Enabled) and (Rec."Email Monitoring" or (Rec."Email Address" <> '')) then begin
                                if not Confirm(EnableAgentForTaskQst) then
                                    exit;
                                TempAgentSetupBuffer.Validate(State, TempAgentSetupBuffer.State::Enabled);
                                TempAgentSetupBuffer.Modify();
                                CurrPage.AgentSetupPart.Page.SetAgentSetupBuffer(TempAgentSetupBuffer);
                                CurrPage.AgentSetupPart.Page.Update();
                                Rec."Email Monitoring" := false;
                                Rec."Incoming Monitoring" := false;
                                Rec.Modify();
                            end;

                            if not ApplySetup(true) then
                                exit;

                            CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
                            if IsNullGuid(TempAgentSetupBuffer."User Security ID") then begin
                                TempAgentSetupBuffer.Rename(Rec."User Security ID");
                                CurrPage.AgentSetupPart.Page.SetAgentSetupBuffer(TempAgentSetupBuffer);
                            end;

                            Commit();

                            SOACreateTask.SetAgentUserSecurityID(Rec."User Security ID");
                            SOACreateTask.LookupMode(true);
                            SOACreateTask.RunModal();
                            CurrPage.Update(false);
                        end;
                    }
                }
                group(BillingInformationFirstSetup)
                {
                    Visible = FirstConfig;
                    InstructionalText = 'By activating the agent, you understand your organization may be billed for its use.';
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
                group(BillingInformationSecondSetup)
                {
                    Visible = not FirstConfig;
                    InstructionalText = 'Your organization may be billed for use of the agent';
                    Caption = 'Important';

                    field(LearnMoreBillingSecondSetup; LearnMoreTxt)
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
            group(RespondToInquiriesCard)
            {
                Caption = 'Respond to inquiries';
                InstructionalText = 'Engage in conversations related to price and availability of products and services.';

                group(RegisteredSenderMessages)
                {
                    Caption = 'Messages from already registered senders';
                    field(RegisteredSenderInputMessageReview; Rec."Known Sender In. Msg. Review")
                    {
                        Caption = 'Review';
                        ToolTip = 'Specifies the type of review required for incoming messages from already registered senders.';
                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                }
                group(UnregisteredSenderMessages)
                {
                    Caption = 'Messages from unregistered senders';
                    field(UnregisteredSenderInputMessageReview; Rec."Unknown Sender In. Msg. Review")
                    {
                        Caption = 'Review';
                        ToolTip = 'Specifies the type of review required for incoming messages from unregistered senders.';
                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                }
                group(ItemSearch)
                {
                    Caption = 'Search for requested items';

                    group(SearchOnlyAvailableItemsGrp)
                    {
                        Caption = 'Select only available items';
                        InstructionalText = 'The agent checks availability of requested quantity';

                        field(SearchOnlyAvailableItems; Rec."Search Only Available Items")
                        {
                            ShowCaption = false;
                            ToolTip = 'Specifies if the agent takes item availability into account when searching for matches to the requested items.';
                            trigger OnValidate()
                            begin
                                if not Rec."Search Only Available Items" then
                                    Rec."Incl. Capable to Promise" := false;

                                ConfigUpdated();
                            end;
                        }
                        field(IncludeCapableToPromise; Rec."Incl. Capable to Promise")
                        {
                            Caption = 'Include capable to promise';
                            ToolTip = 'Specifies whether the agent includes in the search results items that are currently unavailable but can be ordered for a later shipment date.';
                            Editable = OnlyAvailableItemsActive;
                            trigger OnValidate()
                            begin
                                ConfigUpdated();
                            end;
                        }
                    }
                }
            }
            group(SOASalesDocConfigCard)
            {
                Caption = 'Create sales documents';
                InstructionalText = 'Create sales quotes and make orders from quotes in response to the incoming requests.';

                group(QuoteSetup)
                {
                    ShowCaption = false;
                    field(RequestQuoteReview; Rec."Quote Review")
                    {
                        Caption = 'Review quotes when created and updated';
                        ToolTip = 'Specifies if the agent requests review when a quote is created and updated.';

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                    field(SendSalesQuote; Rec."Send Sales Quote")
                    {
                        Caption = 'Send quotes for confirmation';
                        ToolTip = 'Specifies if the agent sends sales quotes for confirmation.';

                        trigger OnValidate()
                        begin
                            ConfigUpdated();
                        end;
                    }
                }
                group(OrderSetup)
                {
                    ShowCaption = false;
                    group(CreateOrder)
                    {
                        Caption = 'Make orders from quotes';
                        InstructionalText = 'The agent turns accepted quotes into orders';

                        field(CreateOrderFromQuote; Rec."Create Order from Quote")
                        {
                            Caption = 'Make orders from quotes';
                            ToolTip = 'Specifies if the agent makes orders from quotes.';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                if not Rec."Create Order from Quote" then
                                    Rec."Order Review" := false;
                                ConfigUpdated();
                            end;
                        }
                        field(RequestOrderReview; Rec."Order Review")
                        {
                            Caption = 'Review orders when created and updated';
                            ToolTip = 'Specifies if the agent requests review when an order is created and updated.';
                            Editable = CreateOrderFromQuoteActive;

                            trigger OnValidate()
                            begin
                                ConfigUpdated();
                            end;
                        }
                    }
                }
            }
            group(SOAManageMailboxConfigCard)
            {
                Caption = 'Manage mailbox';

                group(IncomingMail)
                {
                    Caption = 'Incoming mail';
                    InstructionalText = 'Analyze new messages to determine the sender''s intent and how to respond.';

                    group(AnalyzeAttachmentsGrp)
                    {
                        Caption = 'Analyze attachments';
                        InstructionalText = 'Includes attachments when analyzing intent. Supported formats: PDF, PNG, JPG.';

                        field(AnalyzeAttachments; Rec."Analyze Attachments")
                        {
                            Caption = 'Analyze attachments';
                            ToolTip = 'Includes attachments when analyzing intent. Supported formats: PDF, PNG, JPG.';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                ConfigUpdated();
                            end;
                        }
                    }
                    group(MarkEmailAsReadGrp)
                    {
                        Caption = 'Mark email as read';
                        InstructionalText = 'Mark emails as read after the agent processes them.';

                        field(MarkEmailAsRead; Rec."Mark Email As Read")
                        {
                            Caption = 'Mark email as read';
                            ToolTip = 'Specifies whether the agent marks emails as read after processing them.';
                            ShowCaption = false;

                            trigger OnValidate()
                            begin
                                ConfigUpdated();
                            end;
                        }
                    }

                    field(LastSync; LastSync)
                    {
                        Caption = 'Last sync';
                        ToolTip = 'Specifies the date and time of the last sync with the mailbox.';
                        Editable = false;
                        Visible = ShowLastSync;
                    }
                }

                group(ProcessingLimits)
                {
                    Caption = 'Processing limits';
                    InstructionalText = 'Display an alert when the incoming email limit is reached.';

                    field(DailyEmailLimit; DailyEmailLimit)
                    {
                        Caption = 'Daily email limit';
                        ToolTip = 'Specifies the maximum number of emails an agent can process per day.';
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            Rec."Message Limit" := DailyEmailLimit;
                            ConfigUpdated();
                        end;
                    }
                }

            }
            group(OutputMailGroup)
            {
                Caption = 'Format outgoing messages';
                InstructionalText = 'Prepare the content and style of outgoing messages in certain ways.';
                group(EmailTemplateGroup)
                {
                    Caption = 'Mail Signature';

                    group(EmailSignatureGroup)
                    {
                        Caption = 'Include a custom signature in the replies';

                        field(ConfigureEmailSignature; Rec."Configure Email Template")
                        {
                            ShowCaption = false;
                            ToolTip = 'Specifies if the agent includes a custom mail signature below the message body when preparing outgoing mails.';

                            trigger OnValidate()
                            begin
                                IsConfigUpdated := true;
                                MailTemplateEditable := Rec."Configure Email Template";
                            end;
                        }
                        field(EmailTemplate; EmailSignatureModifyLbl)
                        {
                            ShowCaption = false;
                            Enabled = MailTemplateEditable;
                            trigger OnDrillDown()
                            begin
                                UpdateEmailSignature();
                            end;

                        }
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
                Enabled = IsConfigUpdated;
                ToolTip = 'Apply the changes to the agent setup.';
            }
            systemaction(Cancel)
            {
                Caption = 'Cancel';
                ToolTip = 'Discards the changes and closes the setup page.';
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentRec: Record Agent;
        SOASetupRec: Record "SOA Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SOASetupCU: Codeunit "SOA Setup";
        UserSecurityIDFilter: Text;
        UserName: Text[50];
        UserSecurityID: Guid;
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Sales Order Agent") then
            Error('');

        NoFolderInboxWarningThreshold := 5;
        IsConfigUpdated := false;
        FirstConfig := IsFirstConfig();
        UserSecurityIDFilter := Rec.GetFilter("User Security ID");
        if not Evaluate(UserSecurityID, UserSecurityIDFilter) then
            Clear(UserSecurityID);

        if not IsNullGuid(UserSecurityID) then
            if SOASetupRec.GetBasedOnAgentUserSecurityID(UserSecurityID, false) then begin
                Rec."Agent Name" := SOASetupRec."Agent Name";
                Rec."Agent Initials" := SOASetupRec."Agent Initials";
            end;

        if not IsNullGuid(UserSecurityID) then
            if AgentRec.Get(UserSecurityID) then
                UserName := AgentRec."User Name";

        if UserName = '' then
            UserName := SOASetupCU.GetSOAUsername();

        CurrPage.AgentSetupPart.Page.Initialize(UserSecurityID,
           "Agent Metadata Provider"::"SO Agent",
           UserName,
           SOASetupCU.GetSOAUserDisplayName(Rec."Agent Name"),
           SOASetupCU.GetAgentSummary());
        UpdateAgentSetupBuffer();

        InitialState := TempAgentSetupBuffer.State;
        UpdateControls();
        FeatureTelemetry.LogUptake('0000QIK', SOASetupCU.GetFeatureName(), Enum::"Feature Uptake Status"::Discovered);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAgentSetupBuffer();
        IsConfigUpdated := IsConfigUpdated or AgentSetup.GetChangesMade(TempAgentSetupBuffer);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::Cancel then
            exit(true);

        exit(ApplySetup(false));
    end;

    local procedure ApplySetup(CreateTrialTask: Boolean): Boolean
    var
        SOASetupCU: Codeunit "SOA Setup";
        SOASessionEvents: Codeunit "SOA Session Events";
        InboxEmailCount: Integer;
        IsFirstActivation: Boolean;
        ReadyToActivateLbl: Label 'Ready to activate the sales order agent?\\The Copilot agent will run now and until you deactivate it.';
        ActivateWithoutMailboxNameErr: Label 'To activate the agent with the current settings, a mailbox must be selected first.';
        ActivateWithoutMonitoringLbl: Label 'The monitoring of email is not enabled. Are you sure you want to continue?';
        DeactivateWarningLbl: Label 'If you deactivate the agent, you won''t be able to reactivate it because you don''t have permission to the current mail account (activated by %1). Are you sure you want continue?', Comment = '%1=Username of user who activated the agent.';
    begin
        if EnabledAgentFirstConfig() then
            if Confirm(ReadyToActivateLbl) then
                Rec.State := Rec.State::Enabled;

        UpdateAgentSetupBuffer();
        if (TempAgentSetupBuffer.State = TempAgentSetupBuffer.State::Enabled) and (MailboxChanged or StateChanged()) then begin
            SOASessionEvents.BindUserEvents();
            IsFirstActivation := Rec."Activated At" = 0DT;
            if CheckIsValidConfig() then begin
                if Rec."Email Monitoring" and not IsNullGuid(Rec."Email Account ID") and (Rec."Email Folder" = '') and IsFirstActivation then begin
                    SetDefaultInboxFolder();
                    InboxEmailCount := SOASetupCU.GetInboxEmailCount(Rec);
                    if InboxEmailCount > NoFolderInboxWarningThreshold then
                        if not Confirm(StrSubstNo(NoFolderSelectedInboxWarningQst, InboxEmailCount, Format(Rec."Earliest Sync At"))) then
                            exit(false);

                    SOASetupCU.ValidateEmailConnection(StateChanged(), Rec, MailboxChanged, IsFirstActivation);
                end
                else begin
                    if Rec."Email Monitoring" and not IsNullGuid(Rec."Email Account ID") and (Rec."Email Folder" = '') then
                        SetDefaultInboxFolder();
                    SOASetupCU.ValidateEmailConnection(StateChanged(), Rec, MailboxChanged, IsFirstActivation);
                end;
            end
            else begin
                if Rec."Email Monitoring" and (MailboxName = '') then
                    Error(ActivateWithoutMailboxNameErr);

                if not CreateTrialTask and not Rec."Email Monitoring" then
                    if not Confirm(ActivateWithoutMonitoringLbl) then
                        exit(false);
            end;
        end;
        if (Rec."Message Limit" <= 0) then
            Error(DailyEmailLimitErr);

        if ShowDeactivateAgentEmailPermissionsWarning() then
            if not Confirm(StrSubstNo(DeactivateWarningLbl, ConfiguredBy)) then
                exit(false);

        if StateChanged() then
            SOASetupCU.UpdateSOASetupActivationDT(Rec);

        SOASetupCU.ValidateAgentIdentity(Rec);

        SOASetupCU.UpdateAgent(TempAgentSetupBuffer, Rec, ShouldScheduleTask());
        exit(true);
    end;

    local procedure UpdateAgentSetupBuffer()
    begin
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(TempAgentSetupBuffer);
    end;

    local procedure StateChanged(): Boolean
    begin
        exit((TempAgentSetupBuffer.State <> InitialState) or IsFirstConfig());
    end;

    local procedure ShouldScheduleTask(): Boolean
    begin
        exit((TempAgentSetupBuffer.State = TempAgentSetupBuffer.State::Enabled) and (StateChanged() or MailboxChanged));
    end;

    local procedure ShowDeactivateAgentEmailPermissionsWarning(): Boolean
    var
        SOASetupCU: Codeunit "SOA Setup";
    begin
        UpdateAgentSetupBuffer();
        if (TempAgentSetupBuffer.State = TempAgentSetupBuffer.State::Disabled) and StateChanged() and not IsFirstConfig() then
            if not SOASetupCU.ValidateEmailConnectionStatus(Rec) then
                exit(true);
    end;

    local procedure UpdateControls()
    var
        User: Record User;
        SOASetupCU: Codeunit "SOA Setup";
    begin
        if Rec.IsEmpty() or (Rec."User Security ID" <> TempAgentSetupBuffer."User Security ID") then begin
            SOASetupCU.GetSOASetup(Rec, TempAgentSetupBuffer."User Security ID");
            MailboxName := Rec."Email Address";
            if Rec."Email Folder" <> '' then
                MailboxFolder := Rec."Email Folder"
            else
                MailboxFolder := '';
            ShowLastSync := CheckIsValidConfig() and (Rec."Last Sync At" <> 0DT);
            LastSync := Format(Rec."Last Sync At");
        end;

        MailTemplateEditable := Rec."Configure Email Template";

        CreateOrderFromQuoteActive := Rec."Create Order from Quote";
        OnlyAvailableItemsActive := Rec."Search Only Available Items";

        DailyEmailLimit := Rec."Message Limit";
        if DailyEmailLimit = 0 then
            DailyEmailLimit := Rec.GetDefaultMessageLimit();

        if User.Get(TempAgentSetupBuffer."Configured By") then
            ConfiguredBy := User."Full Name";

        CheckIsValidConfig();
    end;

    local procedure ConfigUpdated()
    begin
        IsConfigUpdated := true;
        CheckIsValidConfig();
        CreateOrderFromQuoteActive := Rec."Create Order from Quote";
        OnlyAvailableItemsActive := Rec."Search Only Available Items";

        if EnabledAgentFirstConfig() then
            TempAgentSetupBuffer.State := TempAgentSetupBuffer.State::Enabled;
    end;

    local procedure EnabledAgentFirstConfig(): Boolean
    begin
        exit((TempAgentSetupBuffer.State = TempAgentSetupBuffer.State::Disabled) and IsFirstConfig() and CheckIsValidConfig());
    end;

    local procedure CheckIsValidConfig(): Boolean
    begin
        exit(Rec."Email Monitoring" and (MailboxName <> ''));
    end;

    local procedure IsFirstConfig(): Boolean
    begin
        exit(IsNullGuid(Rec."User Security ID"));
    end;

    local procedure SetDefaultInboxFolder()
    var
        TempEmailFolders: Record "Email Folders" temporary;
        Email: Codeunit "Email";
    begin
        // Use Outlook's well-known inbox folder id as a safe fallback.
        Rec."Email Folder" := InboxFolderNameTok;
        Rec."Email Folder Id" := InboxFolderIdTok;

        if not IsNullGuid(Rec."Email Account ID") then begin
            Email.GetMailFolders(Rec."Email Account ID", Rec."Email Connector", TempEmailFolders);
            if TempEmailFolders.FindSet() then
                repeat
                    if (LowerCase(TempEmailFolders."Id") = InboxFolderIdTok) or
                       (LowerCase(TempEmailFolders."Folder Name") = LowerCase(InboxFolderNameTok))
                    then begin
                        Rec."Email Folder" := TempEmailFolders."Folder Name";
                        Rec."Email Folder Id" := TempEmailFolders."Id";
                        break;
                    end;
                until TempEmailFolders.Next() = 0;
        end;

        MailboxFolder := Rec."Email Folder";
    end;

    local procedure CheckMailboxExists(): Boolean
    var
        TempEmailAccounts: Record "Email Account";
        EmailAccount: Codeunit "Email Account";
        IConnector: Interface "Email Connector";
    begin
        EmailAccount.GetAllAccounts(false, TempEmailAccounts);
        if TempEmailAccounts.IsEmpty() then
            exit(false);

        repeat
            IConnector := TempEmailAccounts.Connector;
#if not CLEAN28
#pragma warning disable AL0432
            if IConnector is "Email Connector v3" or IConnector is "Email Connector v4" then
#pragma warning restore AL0432
#else
            if IConnector is "Email Connector v4" then
#endif
                exit(true);
        until TempEmailAccounts.Next() = 0;
    end;

    local procedure OnAssistEditMailboxFolder()
    var
        TempEmailFolder: Record "Email Folders" temporary;
        EmailFolders: Page "Email Account Folders";
    begin
        if IsNullGuid(Rec."Email Account ID") then begin
            Message(SelectMailboxFirstMsg);
            exit;
        end;

        EmailFolders.LookupMode(true);

        EmailFolders.SetEmailAccount(Rec."Email Account ID", Rec."Email Connector");
        if EmailFolders.RunModal() = Action::LookupOK then begin
            EmailFolders.GetRecord(TempEmailFolder);
            Rec."Email Folder" := TempEmailFolder."Folder Name";
            Rec."Email Folder Id" := TempEmailFolder."Id";
            MailboxFolder := TempEmailFolder."Folder Name";
            ConfigUpdated();
        end;
    end;

    local procedure OnAssistEditMailbox()
    var
        SOASetupCU: Codeunit "SOA Setup";
        EmailAccounts: Page "Email Accounts";
    begin
        if not CheckMailboxExists() then
            Page.RunModal(Page::"Email Account Wizard");

        if not CheckMailboxExists() then
            exit;

        EmailAccounts.EnableLookupMode();
        EmailAccounts.SetShowCreateAccount(true);
        EmailAccounts.FilterConnectorV4Accounts(true);
        if EmailAccounts.RunModal() = Action::LookupOK then begin
            EmailAccounts.GetAccount(TempEmailAccount);
            Rec."Email Account ID" := TempEmailAccount."Account Id";
            Rec."Email Connector" := TempEmailAccount.Connector;
            Rec."Email Address" := TempEmailAccount."Email Address";
            SOASetupCU.CheckMailboxUnique(Rec);
        end;

        if MailboxName <> Rec."Email Address" then begin
            MailboxChanged := true;
            MailboxName := Rec."Email Address";
            ConfigUpdated();

            Clear(Rec."Email Folder");
            Clear(Rec."Email Folder Id");
            MailboxFolder := '';
        end;
    end;

    local procedure UpdateEmailSignature()
    var
        EmailTemplatePage: Page "SOA Email Template";
    begin
        if not Rec."Configure Email Template" then
            exit;
        EmailTemplatePage.SetCurrentSignatureAsTxt(Rec.GetEmailSignatureAsTxt());
        EmailTemplatePage.RunModal();
        if EmailTemplatePage.IsValueUpdated() then begin
            Rec.SetEmailSignature(EmailTemplatePage.GetNewSignatureAsTxt());
            Rec.Modify();
            IsConfigUpdated := true;
        end;
    end;

    var
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        TempEmailAccount: Record "Email Account" temporary;
        AzureOpenAI: Codeunit "Azure OpenAI";
        AgentSetup: Codeunit "Agent Setup";
        MailboxName, MailboxFolder : Text;
        InitialState: Option;
        LastSync: Text;
        ShowLastSync: Boolean;
        FirstConfig: Boolean;
        MailTemplateEditable: Boolean;
        CreateOrderFromQuoteActive: Boolean;
        OnlyAvailableItemsActive: Boolean;
        MailboxChanged: Boolean;
        DailyEmailLimit: Integer;
        NoFolderInboxWarningThreshold: Integer;
        LearnMoreTxt: Label 'Learn more';
        LearnMoreBillingDocumentationLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2333517';
        DailyEmailLimitErr: Label 'The daily email limit must be greater than zero.';
        EmailSignatureModifyLbl: Label 'Edit signature';
        SelectMailboxFirstMsg: Label 'Please select an email account first.';
        ConfiguredBy: Text[80];
        SOACreateTaskLbl: Label 'Create task for the agent';
        EnableAgentForTaskQst: Label 'Trying out the agent will activate it and turn off incoming email monitoring immediately.\\Do you want to continue?';
        IsConfigUpdated: Boolean;
        InboxFolderNameTok: Label 'Inbox', Locked = true;
        InboxFolderIdTok: Label 'inbox', Locked = true;
        NoFolderSelectedInboxWarningQst: Label 'There is no mail folder selected, so the agent will process emails from the inbox (%1 emails since %2). Do you want to continue?', Comment = '%1=email count, %2=start date';
}
