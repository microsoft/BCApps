// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using System.Agents;
using System.Email;
using System.Environment.Configuration;
using System.Security.AccessControl;

codeunit 133723 "PA Setup Tests"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Access = Internal;

    var
        PATestFixtures: Codeunit "PA Test Fixtures";
        Assert: Codeunit Assert;
#if not CLEAN30
        AgentManagement: Codeunit Agent;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
#endif

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

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrepareV2ReconfiguresAnEnabledV1Agent()
    var
        AgentUserId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Preparing V2 reconfigures an enabled V1 agent without replacing its identity.
        Initialize();

        // [GIVEN] Enabled V1 agent "A" with the V1 profile, permissions and instructions.
        AgentUserId := CreateEnabledV1Agent();
        VerifyAgentConfiguration(AgentUserId, 'PAYABLES AGENT', 'PAYABLES AG. - RUN');

        // [WHEN] V2 is prepared.
        PATestFixtures.PrepareEvaluationVersion(2);

        // [THEN] "A" has the V2 configuration and remains enabled without starting a task.
        VerifyV2Configuration(AgentUserId);
        LibrarySetupStorage.Restore();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrepareV2DisablesV1EmailMonitoring()
    var
        Setup: Record "Payables Agent Setup";
        AgentUserId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Preparing V2 disables unsupported mailbox monitoring on an enabled V1 agent.
        Initialize();

        // [GIVEN] Enabled V1 agent "A" with monitoring selected in the stored setup.
        AgentUserId := CreateEnabledV1Agent();
        Setup.GetOrCreateSetup();
        Setup."Monitor Outlook" := true;
        Setup.Modify();

        // [WHEN] V2 is prepared.
        PATestFixtures.PrepareEvaluationVersion(2);

        // [THEN] "A" is configured for V2 with monitoring disabled.
        VerifyV2Configuration(AgentUserId);
        LibrarySetupStorage.Restore();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrepareV2RepairsAnAlreadySelectedV2Version()
    var
        AgentUserId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Preparation repairs V1 configuration even when the version flag already selects V2.
        Initialize();

        // [GIVEN] Enabled V1 agent "A" with only the version flag changed to V2.
        AgentUserId := CreateEnabledV1Agent();
        SelectV2WithoutReconfiguringAgent();

        // [WHEN] V2 is prepared again.
        PATestFixtures.PrepareEvaluationVersion(2);

        // [THEN] "A" has the V2 profile, permissions and instructions.
        VerifyV2Configuration(AgentUserId);
        LibrarySetupStorage.Restore();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrepareV2RepeatedlyPreservesTheAgent()
    var
        AgentUserId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Repeating V2 preparation preserves the configured agent without creating tasks.
        Initialize();

        // [GIVEN] Agent "A" has already been prepared for V2.
        AgentUserId := CreateEnabledV1Agent();
        PATestFixtures.PrepareEvaluationVersion(2);

        // [WHEN] V2 is prepared a second time.
        PATestFixtures.PrepareEvaluationVersion(2);

        // [THEN] The same "A" remains correctly configured and has no tasks.
        VerifyV2Configuration(AgentUserId);
        LibrarySetupStorage.Restore();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrepareV2DoesNotActivateADisabledAgent()
    var
        AgentRecord: Record Agent;
        Setup: Record "Payables Agent Setup";
        UserSettings: Record "User Settings" temporary;
        AgentUserId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Preparing V2 leaves a disabled agent inactive and does not apply its instructions.
        Initialize();

        // [GIVEN] Disabled V1 agent "A".
        AgentUserId := CreateDisabledV1Agent();

        // [WHEN] V2 is prepared.
        PATestFixtures.PrepareEvaluationVersion(2);

        // [THEN] V2 is selected but "A" remains disabled with its previous profile and no applied instructions.
        Setup.GetOrCreateSetup();
        AgentRecord.Get(AgentUserId);
        AgentManagement.GetUserSettings(AgentUserId, UserSettings);
        VerifyDisabledAgent(AgentRecord, Setup, UserSettings);
        LibrarySetupStorage.Restore();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PrepareV2DoesNotCreateAMissingAgent()
    var
        Setup: Record "Payables Agent Setup";
        NullGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Preparing V2 without a stored agent selects the version without creating an agent.
        Initialize();

        // [GIVEN] No agent is associated with the stored setup.
        Setup.GetOrCreateSetup();

        // [WHEN] V2 is prepared.
        PATestFixtures.PrepareEvaluationVersion(2);

        // [THEN] V2 is selected and the setup still has no agent.
        Setup.GetOrCreateSetup();
        VerifyMissingAgent(Setup, NullGuid);
        LibrarySetupStorage.Restore();
    end;

    local procedure Initialize()
    var
        Setup: Record "Payables Agent Setup";
    begin
        Clear(LibrarySetupStorage);
        Setup.GetOrCreateSetup();
        LibrarySetupStorage.Save(Database::"Payables Agent Setup");
        Clear(Setup."User Security Id");
        Clear(Setup."Applied Instr. Config Hash");
        Setup."Monitor Outlook" := false;
        Setup.Modify();
    end;

    local procedure CreateDisabledV1Agent() AgentUserId: Guid
    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        Setup: Record "Payables Agent Setup";
        AgentUserName: Code[50];
    begin
        PATestFixtures.PrepareEvaluationVersion(1);
        AgentUserName := CopyStr('PA-EVAL-' + LibraryUtility.GenerateGUID(), 1, MaxStrLen(AgentUserName));
        AgentUserId := AgentManagement.Create(
            "Agent Metadata Provider"::"Payables Agent", AgentUserName,
            'Payables version preparation test', TempAgentAccessControl);
        Setup.GetOrCreateSetup();
        Setup."User Security Id" := AgentUserId;
        Setup.Modify();
    end;

    local procedure CreateEnabledV1Agent() AgentUserId: Guid
    var
        SetupUpdate: Codeunit "PA Setup Update";
        AlreadyActivated: Boolean;
    begin
        AgentUserId := CreateDisabledV1Agent();
        SetupUpdate.EnsureActivated(AlreadyActivated);
    end;

    local procedure SelectV2WithoutReconfiguringAgent()
    var
        Setup: Record "Payables Agent Setup";
    begin
        Setup.GetOrCreateSetup();
#pragma warning disable AL0432
        Setup."Preview Version" := Setup."Preview Version"::"V2 Preview";
#pragma warning restore AL0432
        Setup.Modify();
    end;

    local procedure VerifyAgentConfiguration(AgentUserId: Guid; ExpectedProfileId: Text; ExpectedPermissionSet: Code[20])
    var
        AgentRecord: Record Agent;
        AgentTask: Record "Agent Task";
        Setup: Record "Payables Agent Setup";
        UserSettings: Record "User Settings" temporary;
        AccessControl: Record "Access Control";
        AgentInstructions: Codeunit "PA Agent Instructions";
    begin
        Setup.GetOrCreateSetup();
        Assert.AreEqual(AgentUserId, Setup."User Security Id", 'Preparation must preserve the agent identity');
        AgentRecord.Get(AgentUserId);
        Assert.AreEqual(AgentRecord.State::Enabled, AgentRecord.State, 'The agent must remain enabled');
        AgentManagement.GetUserSettings(AgentUserId, UserSettings);
        Assert.AreEqual(ExpectedProfileId, UpperCase(UserSettings."Profile ID"), 'The profile must match the prepared version');
        AccessControl.SetRange("User Security ID", AgentUserId);
        Assert.AreEqual(1, AccessControl.Count(), 'The agent must have exactly the selected version permission set');
        Assert.IsTrue(AccessControl.FindFirst(), 'The agent permission set must exist');
        Assert.AreEqual(ExpectedPermissionSet, AccessControl."Role ID", 'The permission set must match the prepared version');
        Assert.AreEqual(CompanyName(), AccessControl."Company Name", 'The permission set must apply to the current company');
        Assert.AreEqual(AgentInstructions.GetInstructionsConfigHash(), Setup."Applied Instr. Config Hash", 'Instructions must match the selected version');
        AgentTask.SetRange("Agent User Security ID", AgentUserId);
        Assert.IsTrue(AgentTask.IsEmpty(), 'Preparing a version must not start agent tasks');
    end;

    local procedure VerifyV2Configuration(AgentUserId: Guid)
    var
        Setup: Record "Payables Agent Setup";
    begin
        VerifyAgentConfiguration(AgentUserId, 'PAYABLES AGENT PROFILE', 'PAYABLES AGENT - RUN');
        Setup.GetOrCreateSetup();
        Assert.AreEqual(2, PATestFixtures.GetPreparedEvaluationVersion(), 'V2 must remain selected');
        Assert.IsFalse(Setup."Monitor Outlook", 'V2 must not retain unsupported mailbox monitoring');
    end;

    local procedure VerifyDisabledAgent(AgentRecord: Record Agent; Setup: Record "Payables Agent Setup"; UserSettings: Record "User Settings" temporary)
    begin
        Assert.AreEqual(2, PATestFixtures.GetPreparedEvaluationVersion(), 'V2 must be selected');
        Assert.AreEqual(AgentRecord."User Security ID", Setup."User Security Id", 'The disabled agent identity must be preserved');
        Assert.AreEqual(AgentRecord.State::Disabled, AgentRecord.State, 'Preparation must not activate a disabled agent');
        Assert.AreEqual('PAYABLES AGENT', UpperCase(UserSettings."Profile ID"), 'A disabled agent must not be reconfigured');
        Assert.AreEqual('', Setup."Applied Instr. Config Hash", 'Instructions must not be applied to a disabled agent');
    end;

    local procedure VerifyMissingAgent(Setup: Record "Payables Agent Setup"; NullGuid: Guid)
    begin
        Assert.AreEqual(2, PATestFixtures.GetPreparedEvaluationVersion(), 'V2 must be selected');
        Assert.AreEqual(NullGuid, Setup."User Security Id", 'Preparation must not create an agent');
        Assert.AreEqual('', Setup."Applied Instr. Config Hash", 'Instructions must not be applied without an agent');
    end;
#endif

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
