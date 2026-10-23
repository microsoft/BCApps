// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using System.Agents;
using System.Email;
using System.Privacy;
using System.TestLibraries.Utilities;

codeunit 133700 "PA Setup Tests"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Access = Internal;

    var
        PATestFixtures: Codeunit "PA Test Fixtures";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [HandlerFunctions('ConsentHandler')]
    [Test]
    procedure E2EActivatingPayablesAgent()
    var
        Agent: Record Agent;
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PASetup: Codeunit "PA Setup";
        MailboxId: Guid;
    begin
        // [GIVEN] The Payables Agent was never configured, and a mailbox is available
        PATestFixtures.Reset();
        MailboxId := RegisterMailbox();

        // [WHEN] Activating the Payables Agent monitoring the mailbox
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, true);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, true, MailboxId, "PA Email Review Policy"::Always);
        PATestFixtures.Activate(PASetupUpdateParameters);

        // [THEN] The agent is enabled and monitors the mailbox, with the consent that was given
        PASetup.GetSetup();
        Assert.IsTrue(Agent.Get(PASetup.GetUserSecurityId()), 'The agent user should exist');
        Assert.AreEqual(Agent.State::Enabled, Agent.State, 'The agent should be enabled');
        Assert.IsTrue(PASetup.GetMonitorOutlook(), 'The agent should monitor the mailbox');
        Assert.AreEqual(MailboxId, PASetup.GetEmailAccountId(), 'The agent should monitor the configured mailbox');
        Assert.IsTrue(PASetup.GetEmailMonitoringConsent(), 'The consent to monitor the mailbox should be recorded');

        PATestFixtures.Reset();
    end;

    [HandlerFunctions('ConsentHandler')]
    [Test]
    procedure E2EProcessingInvoiceWithReviewRequested()
    var
        AgentTaskMessage: Record "Agent Task Message";
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PASetup: Codeunit "PA Setup";
        PATask: Codeunit "Payables Agent Task";
        PATaskSource: Codeunit "PA Task Source";
    begin
        // [GIVEN] The Payables Agent monitors a mailbox, and every email it receives needs review
        PATestFixtures.Reset();
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, true);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, true, RegisterMailbox(), "PA Email Review Policy"::Always);
        PATestFixtures.Activate(PASetupUpdateParameters);

        // [WHEN] An email with an invoice is received and handed to the agent
        Assert.IsTrue(PATestFixtures.ReceiveEmail('vendor@contoso.com', 'Invoice', PATaskSource), 'The email should be received as a source');
        Assert.IsTrue(PATestFixtures.StartSource(PATaskSource, PATask), 'The source should be handed to the agent');

        // [THEN] The agent is given the task, and its message requires review
        PASetup.GetSetup();
        AgentTaskMessage.SetRange("Task ID", PATask.GetAgentTaskId());
        Assert.IsTrue(AgentTaskMessage.FindFirst(), 'The agent task should have a message');
        Assert.IsTrue(AgentTaskMessage."Requires Review", 'The Agent Task Message should require review');
        Assert.AreEqual(PASetup.GetUserSecurityId(), AgentTaskMessage."Agent User Security ID", 'The Agent Task Message should be assigned to the Payables Agent User Security ID');
        Assert.AreEqual(PATask.GetAgentTaskExternalId(), AgentTaskMessage."External ID", 'The Agent Task Message should reference the task it was created for');

        PATestFixtures.Reset();
    end;

    [HandlerFunctions('PayablesAgentSetupHandler')]
    [Test]
    procedure OpenSetupPageSucceedsForPayablesAgentUserSecurityIdField()
    var
        Agent: Record Agent;
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PASetup: Codeunit "PA Setup";
        AgentCU: Codeunit Agent;
    begin
        // [GIVEN] The Payables Agent is active
        PATestFixtures.Reset();
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, true);
        PATestFixtures.Activate(PASetupUpdateParameters);
        PASetup.GetSetup();

        // [WHEN] Opening the setup page through the generic agent framework.
        AgentCU.OpenSetupPageId("Agent Metadata Provider"::"Payables Agent", PASetup.GetUserSecurityId());

        // [THEN] The setup page opens instead of failing required-field validation, showing the agent that matches the provided User Security ID.
        Agent.Get(PASetup.GetUserSecurityId());
        Assert.AreEqual(Agent."Display Name", LibraryVariableStorage.DequeueText(), 'The setup page should show the configured Payables Agent.');
        LibraryVariableStorage.AssertEmpty();

        PATestFixtures.Reset();
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsTrueWhenConfigured()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PADemoGuide: Codeunit "PA Demo Guide";
    begin
        // [GIVEN] Email monitoring is enabled and a valid mailbox is configured
        PATestFixtures.Reset();
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, true, RegisterMailbox(), "PA Email Review Policy"::Always);

        // [WHEN] Checking whether email is configured for the demo email
        // [THEN] It returns true
        Assert.IsTrue(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters), 'Email should be configured when monitoring is on and a mailbox is set');
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsFalseWhenMonitoringDisabled()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PADemoGuide: Codeunit "PA Demo Guide";
    begin
        // [GIVEN] A valid mailbox is configured but email monitoring is disabled
        PATestFixtures.Reset();
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, false, RegisterMailbox(), "PA Email Review Policy"::Always);

        // [WHEN] Checking whether email is configured for the demo email
        // [THEN] It returns false
        Assert.IsFalse(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters), 'Email should not be configured when monitoring is disabled');
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsFalseWhenNoAccount()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PADemoGuide: Codeunit "PA Demo Guide";
        NullGuid: Guid;
    begin
        // [GIVEN] Email monitoring is enabled but no mailbox is configured
        PATestFixtures.Reset();
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, true, NullGuid, "PA Email Review Policy"::Always);

        // [WHEN] Checking whether email is configured for the demo email
        // [THEN] It returns false
        Assert.IsFalse(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters), 'Email should not be configured when no mailbox is set');
    end;

    /// <summary>
    /// Registers a Microsoft 365 mailbox, the kind of mailbox the agent monitors.
    /// </summary>
    local procedure RegisterMailbox(): Guid
    var
        EmailOutlookAccount: Record "Email - Outlook Account";
    begin
        EmailOutlookAccount.Id := CreateGuid();
        EmailOutlookAccount.Name := 'Payables';
        EmailOutlookAccount."Email Address" := 'payables@contoso.com';
        EmailOutlookAccount."Outlook API Email Connector" := "Email Connector"::"Microsoft 365";
        EmailOutlookAccount.Insert();
        exit(EmailOutlookAccount.Id);
    end;

    [ModalPageHandler]
    procedure ConsentHandler(var Page: TestPage "Consent Microsoft Confirm")
    begin
        Page.Accept.Invoke();
    end;

    [ModalPageHandler]
    procedure PayablesAgentSetupHandler(var PayablesAgentSetupPage: TestPage "Payables Agent Setup")
    begin
        LibraryVariableStorage.Enqueue(PayablesAgentSetupPage.AgentSetupPart.Name.Value());
    end;

}
