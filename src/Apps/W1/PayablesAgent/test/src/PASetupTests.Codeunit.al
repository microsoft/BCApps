// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using System.Agents;
using System.Email;

codeunit 133723 "PA Setup Tests"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Access = Internal;

    var
        PATestFixtures: Codeunit "PA Test Fixtures";
        Assert: Codeunit Assert;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsTrueWhenConfigured()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PADemoGuide: Codeunit "PA Demo Guide";
    begin
        // [SCENARIO] Email is configured for the demo email when monitoring is on and a mailbox is selected.
        // [GIVEN] A setup proposal with monitoring on and a registered mailbox.
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, true, RegisterMailbox(), "PA Email Review Policy"::Always);

        // [WHEN] The demo guide checks the email configuration.
        // [THEN] Email is reported as configured.
        Assert.IsTrue(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters), 'Email should be configured when monitoring is on and a mailbox is set');
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsFalseWhenMonitoringDisabled()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PADemoGuide: Codeunit "PA Demo Guide";
    begin
        // [SCENARIO] Email is not configured for the demo email when monitoring is off.
        // [GIVEN] A setup proposal with a registered mailbox but monitoring off.
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, false, RegisterMailbox(), "PA Email Review Policy"::Always);

        // [WHEN] The demo guide checks the email configuration.
        // [THEN] Email is reported as not configured.
        Assert.IsFalse(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters), 'Email should not be configured when monitoring is disabled');
    end;

    [Test]
    procedure IsEmailConfiguredForDemoEmailReturnsFalseWhenNoAccount()
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
        PADemoGuide: Codeunit "PA Demo Guide";
        NullGuid: Guid;
    begin
        // [SCENARIO] Email is not configured for the demo email when no mailbox is selected.
        // [GIVEN] A setup proposal with monitoring on but no mailbox.
        PATestFixtures.LoadConfiguration(PASetupUpdateParameters, false);
        PATestFixtures.SetEmailMonitoring(PASetupUpdateParameters, true, NullGuid, "PA Email Review Policy"::Always);

        // [WHEN] The demo guide checks the email configuration.
        // [THEN] Email is reported as not configured.
        Assert.IsFalse(PADemoGuide.IsEmailConfiguredForDemoEmail(PASetupUpdateParameters), 'Email should not be configured when no mailbox is set');
    end;

    [Test]
    procedure AgentFoundOnlyByUserNameIsNotSetUpUntilSetupLinksIt()
    var
        Agent: Record Agent;
        PASetup: Codeunit "PA Setup";
        AgentUserId: Guid;
    begin
        // [SCENARIO] An agent user left behind by a deleted company with the same name isn't set up in the recreated company, and setup reuses it
        // [GIVEN] An agent user with this company's user name, and no Payables Agent setup in the company
        AgentUserId := GetOrCreateAgentWithCompanyUserName();
        PASetup.DeleteSetup(CopyStr(CompanyName(), 1, 30));

        // [THEN] The agent isn't set up in the company
        Assert.IsFalse(PASetup.TryGetStoredAgent(Agent), 'An agent found only by its user name must not count as set up');

        // [WHEN] Setup looks for the agent
        // [THEN] It finds the same agent user by its user name and links it
        Assert.IsTrue(PASetup.FindAgentAndReconcileSetup(Agent), 'Setup must find the agent by its user name');
        Assert.AreEqual(AgentUserId, Agent."User Security ID", 'Setup must reuse the existing agent user');

        // [THEN] The linked agent is set up in the company
        Assert.IsTrue(PASetup.TryGetStoredAgent(Agent), 'The agent linked by the setup must count as set up');
        Assert.AreEqual(AgentUserId, Agent."User Security ID", 'The setup must link the existing agent user');
    end;

    local procedure GetOrCreateAgentWithCompanyUserName(): Guid
    var
        Agent: Record Agent;
        TempAgentSetupBuffer: Record "Agent Setup Buffer" temporary;
        AgentSetup: Codeunit "Agent Setup";
        PASetup: Codeunit "PA Setup";
        NullGuid: Guid;
    begin
        Agent.SetRange("User Name", PASetup.AgentUserName());
        if Agent.FindFirst() then
            exit(Agent."User Security ID");

        AgentSetup.GetSetupRecord(TempAgentSetupBuffer, NullGuid, "Agent Metadata Provider"::"Payables Agent", PASetup.AgentUserName(), 'Payables Agent', '');
        exit(AgentSetup.SaveChanges(TempAgentSetupBuffer));
    end;

    local procedure RegisterMailbox(): Guid
    var
        EmailOutlookAccount: Record "Email - Outlook Account";
    begin
        EmailOutlookAccount.Id := CreateGuid();
        EmailOutlookAccount.Name := 'Payables';
        EmailOutlookAccount."Email Address" := LowerCase(DelChr(Format(EmailOutlookAccount.Id), '=', '{}-')) + '@contoso.com';
        EmailOutlookAccount."Outlook API Email Connector" := "Email Connector"::"Microsoft 365";
        EmailOutlookAccount.Insert();
        exit(EmailOutlookAccount.Id);
    end;
}
