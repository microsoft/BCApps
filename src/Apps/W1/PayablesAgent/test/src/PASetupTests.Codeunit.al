// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using System.Agents;
using System.Email;
using System.Privacy;
using System.TestLibraries.Email;
using System.TestLibraries.Utilities;

codeunit 133700 "PA Setup Tests"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Access = Internal;

    var
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        PAEDocTestGlue: Codeunit "PA EDoc Unit Test Glue";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [HandlerFunctions('ConsentHandler')]
    [Test]
    procedure E2EActivatingPayablesAgent()
    var
        PASetup: Record "Payables Agent Setup";
    begin
        // [GIVEN] The Payables Agent is inactive and its intake is not configured
        ResetPayablesAgent();
        SetupPayablesAgent(PASetup);
        // [THEN] The agent's intake is configured to monitor the mailbox
        PAEDocTestGlue.AssertAgentIntakeMonitorsMailbox(PASetup);
        ResetPayablesAgent();
    end;

    [HandlerFunctions('ConsentHandler')]
    [Test]
    procedure E2EProcessingInvoiceWithReviewRequested()
    var
        Agent: Record Agent;
        AgentTaskMessage: Record "Agent Task Message";
        PASetup: Record "Payables Agent Setup";
        AgentCU: Codeunit Agent;
        PASetupConfiguration: Codeunit "PA Setup Configuration";
        ExpectedExternalId: Text;
    begin
        // [GIVEN] The Payables Agent is inactive and its intake is not configured
        ResetPayablesAgent();
        SetupPayablesAgent(PASetup);
        PASetupConfiguration := GetPASetupConfigs();
        AgentCU.Activate(PASetup."User Security Id");
        Agent."User Security ID" := PASetup."User Security Id";
        ExpectedExternalId := PAEDocTestGlue.CreateAgentTaskForInvoice(PASetup, Agent);

        AgentTaskMessage.FindLast();
        Assert.IsTrue(AgentTaskMessage."Requires Review", 'The last Agent Task Message should require review');
        Assert.AreEqual(PASetup."User Security Id", AgentTaskMessage."Agent User Security ID", 'The Agent Task Message should be assigned to the Payables Agent User Security ID');
        Assert.AreEqual(ExpectedExternalId, AgentTaskMessage."External ID", 'The Agent Task Message should reference the task it was created for');

        AgentCU.Deactivate(PASetup."User Security Id");

        ResetPayablesAgent();
    end;

    [HandlerFunctions('ConsentHandler,PayablesAgentSetupHandler')]
    [Test]
    procedure OpenSetupPageSucceedsForPayablesAgentUserSecurityIdField()
    var
        Agent: Record Agent;
        PASetup: Record "Payables Agent Setup";
        AgentCU: Codeunit Agent;
        ExpectedAgentDisplayName: Text;
    begin
        // [GIVEN] Payables Agent has been configured with a setup table containing "User Security Id" field casing.
        ResetPayablesAgent();
        SetupPayablesAgent(PASetup);

        // [WHEN] Opening the setup page through the generic agent framework.
        AgentCU.OpenSetupPageId("Agent Metadata Provider"::"Payables Agent", PASetup."User Security Id");

        // [THEN] The setup page opens instead of failing required-field validation, showing the agent that matches the provided User Security ID.
        Agent.Get(PASetup."User Security Id");
        ExpectedAgentDisplayName := Agent."Display Name";
        Assert.AreEqual(ExpectedAgentDisplayName, LibraryVariableStorage.DequeueText(), 'The setup page should show the configured Payables Agent.');
        LibraryVariableStorage.AssertEmpty();

        ResetPayablesAgent();
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsTrueWhenConfigured()
    var
        EmailAccount: Record "Email Account";
        PADemoGuide: Codeunit "PA Demo Guide";
        PASetupConfiguration: Codeunit "PA Setup Configuration";
    begin
        // [GIVEN] Monitor Outlook is enabled and a valid email account is configured
        ResetEmailDemoSetup();
        RegisterMockEmailAccount(EmailAccount);
        SetMonitorOutlook(true);
        PAEDocTestGlue.SetMonitoredEmailAccount(EmailAccount."Account Id", EmailAccount.Connector);

        // [WHEN] Checking whether email is configured for the demo email
        // [THEN] It returns true
        PASetupConfiguration := GetPASetupConfigs();
        PayablesAgentSetup.LoadSetupConfiguration(PASetupConfiguration);
        Assert.IsTrue(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupConfiguration), 'Email should be configured when Monitor Outlook is on and an email account is set');
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsFalseWhenMonitoringDisabled()
    var
        EmailAccount: Record "Email Account";
        PADemoGuide: Codeunit "PA Demo Guide";
        PASetupConfiguration: Codeunit "PA Setup Configuration";
    begin
        // [GIVEN] A valid email account is configured but Monitor Outlook is disabled
        ResetEmailDemoSetup();
        RegisterMockEmailAccount(EmailAccount);
        SetMonitorOutlook(false);
        PAEDocTestGlue.SetMonitoredEmailAccount(EmailAccount."Account Id", EmailAccount.Connector);

        // [WHEN] Checking whether email is configured for the demo email
        // [THEN] It returns false
        PASetupConfiguration := GetPASetupConfigs();
        PayablesAgentSetup.LoadSetupConfiguration(PASetupConfiguration);
        Assert.IsFalse(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupConfiguration), 'Email should not be configured when Monitor Outlook is disabled');
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsFalseWhenNoAccount()
    var
        PADemoGuide: Codeunit "PA Demo Guide";
        PASetupConfiguration: Codeunit "PA Setup Configuration";
    begin
        // [GIVEN] Monitor Outlook is enabled but no email account is configured
        ResetEmailDemoSetup();
        SetMonitorOutlook(true);

        // [WHEN] Checking whether email is configured for the demo email
        // [THEN] It returns false
        PASetupConfiguration := GetPASetupConfigs();
        PayablesAgentSetup.LoadSetupConfiguration(PASetupConfiguration);
        Assert.IsFalse(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupConfiguration), 'Email should not be configured when no email account is set');
    end;

    local procedure ResetEmailDemoSetup()
    var
        PASetup: Record "Payables Agent Setup";
    begin
        PASetup.DeleteAll();
        PAEDocTestGlue.DeleteEmailMonitoringSetup();
    end;

    local procedure RegisterMockEmailAccount(var EmailAccount: Record "Email Account")
    var
        EmailConnectorMock: Codeunit "Connector Mock";
    begin
        EmailConnectorMock.Initialize();
        EmailConnectorMock.AddAccount(EmailAccount);
    end;

    local procedure SetMonitorOutlook(MonitorOutlook: Boolean)
    var
        PASetup: Record "Payables Agent Setup";
    begin
        PASetup.GetSetup();
        PASetup."Monitor Outlook" := MonitorOutlook;
        PASetup.Modify();
    end;

    local procedure SetupPayablesAgent(var PASetup: Record "Payables Agent Setup")
    var
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        PASetupConfiguration: Codeunit "PA Setup Configuration";
    begin
        PASetupConfiguration := GetPASetupConfigs();
        PayablesAgentSetup.LoadSetupConfiguration(PASetupConfiguration);
        // [WHEN] Activating the Payables Agent and configuring "Monitor Outlook"
        TempAgentSetupBuffer := PASetupConfiguration.GetAgentSetupBuffer();
        PASetup := PASetupConfiguration.GetPayablesAgentSetup();
        TempAgentSetupBuffer.State := TempAgentSetupBuffer.State::Enabled;
        PASetup."Monitor Outlook" := true;
        PASetupConfiguration.SetAgentSetupBuffer(TempAgentSetupBuffer);
        // [GIVEN] An email account is configured for the Payables Agent
        PAEDocTestGlue.SetMonitoredEmailAccount(PASetupConfiguration, CreateGuid());
        PASetupConfiguration.SetPayablesAgentSetup(PASetup);
        PayablesAgentSetup.ApplyPayablesAgentSetup(PASetupConfiguration);
        // [THEN] The applied setup is reloaded
        PayablesAgentSetup.LoadSetupConfiguration(PASetupConfiguration);
        PASetup := PASetupConfiguration.GetPayablesAgentSetup();
    end;

    local procedure ResetPayablesAgent()
    var
        Agent: Record Agent;
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        PASetup: Record "Payables Agent Setup";
        PASetupConfigs: Codeunit "PA Setup Configuration";
    begin
        PASetupConfigs := GetPASetupConfigs();
        PayablesAgentSetup.LoadSetupConfiguration(PASetupConfigs);
        TempAgentSetupBuffer := PASetupConfigs.GetAgentSetupBuffer();
        TempAgentSetupBuffer.State := TempAgentSetupBuffer.State::Disabled;
        PASetupConfigs.SetAgentSetupBuffer(TempAgentSetupBuffer);
        PayablesAgentSetup.ApplyPayablesAgentSetup(PASetupConfigs);
        if not IsNullGuid(TempAgentSetupBuffer."User Security ID") then
            if Agent.Get(TempAgentSetupBuffer."User Security ID") then
                Agent.Delete();
        PASetup.DeleteAll();
        PAEDocTestGlue.DeleteAgentIntake();
    end;

    local procedure GetPASetupConfigs() PASetupConfigs: Codeunit "PA Setup Configuration"
    begin
        // Tests don't run with the agents enabled
        PASetupConfigs.SetSkipAgentConfiguration(false);
        PASetupConfigs.SetSkipEmailVerification(true);
        exit(PASetupConfigs);
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
