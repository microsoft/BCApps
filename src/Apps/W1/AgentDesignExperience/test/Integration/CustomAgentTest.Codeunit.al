// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.Designer.CustomAgent;

using System.Agents;
using System.Agents.Designer.CustomAgent;
using System.Test.Agents.Designer;
using System.TestLibraries.Utilities;

codeunit 133754 "Custom Agent Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        AgentDesignerTestLib: Codeunit "Agent Designer Test Lib.";
        Any: Codeunit Any;
        Assert: Codeunit "Library Assert";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        TestAgentUserName1: Code[50];
        TestAgentUserName2: Code[50];
        TestAgentId1: Guid;
        TestAgentId2: Guid;
        Initialized: Boolean;
        TestAgentPrefixTxt: Label 'TEST_AGENT', Locked = true;
        ArchivedAgentCannotBeTestedErr: Label 'archived and can no longer be tested', Locked = true;

    local procedure Initialize()
    var
        AgentRec: Record Agent;
        CustomAgentSetup: Record "Custom Agent Setup";
    begin
        AgentRec.SetRange("Agent Metadata Provider", AgentRec."Agent Metadata Provider"::"Custom Agent");
        AgentRec.SetFilter("User Name", TestAgentPrefixTxt + '*');
        if (AgentRec.Count() = 2) and Initialized then
            exit;

        // Create test agent names
        TestAgentUserName1 := TestAgentPrefixTxt + CopyStr(Any.AlphanumericText(MaxStrLen(TestAgentUserName1) - StrLen(TestAgentPrefixTxt)), 1, MaxStrLen(TestAgentUserName1) - StrLen(TestAgentPrefixTxt));
        TestAgentUserName2 := TestAgentPrefixTxt + CopyStr(Any.AlphanumericText(MaxStrLen(TestAgentUserName2) - StrLen(TestAgentPrefixTxt)), 1, MaxStrLen(TestAgentUserName2) - StrLen(TestAgentPrefixTxt));

        // Clean up any existing test agents created by this test
        AgentRec.SetRange("Agent Metadata Provider", AgentRec."Agent Metadata Provider"::"Custom Agent");
        AgentRec.SetFilter("User Name", TestAgentPrefixTxt + '*');
        if AgentRec.FindSet() then begin
            repeat
                if CustomAgentSetup.Get(AgentRec."User Security ID") then
                    CustomAgentSetup.Delete();
            until AgentRec.Next() = 0;
            AgentRec.DeleteAll();
        end;

        // Create test agents

        TestAgentId1 := AgentDesignerTestLib.GetOrCreateDefaultAgent(
            AgentRec,
            TestAgentUserName1,
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(4), 1, 4),
            CopyStr(Any.AlphanumericText(250), 1, 250),
            CopyStr(Any.AlphanumericText(2048), 1, 2048)
        );

        TestAgentId2 := AgentDesignerTestLib.GetOrCreateDefaultAgent(
            AgentRec,
            TestAgentUserName2,
            CopyStr(Any.AlphanumericText(80), 1, 80),
            CopyStr(Any.AlphanumericText(4), 1, 4),
            CopyStr(Any.AlphanumericText(250), 1, 250),
            CopyStr(Any.AlphanumericText(2048), 1, 2048)
        );

        Commit();
        Initialized := true;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestOpenEditInstructionsPageForInactiveAgentShowsConfirmation()
    var
        Agent: Codeunit Agent;
        CustomAgentSetup: Codeunit "Custom Agent Setup";
    begin
        // [GIVEN] An inactive custom agent
        Initialize();
        Agent.Deactivate(TestAgentId1);
        LibraryVariableStorage.Enqueue('inactive'); // expected confirmation message
        LibraryVariableStorage.Enqueue(false); // decline the confirmation

        // [WHEN] Opening the edit instructions page for the inactive agent
        CustomAgentSetup.OpenEditInstructionsPage(TestAgentId1);

        // [THEN] Exactly one confirmation was shown
        LibraryVariableStorage.AssertEmpty();

        Agent.Activate(TestAgentId1);
    end;

    [Test]
    procedure TestOpenEditInstructionsPageForArchivedAgentIsBlocked()
    var
        Agent: Codeunit Agent;
        CustomAgentSetup: Codeunit "Custom Agent Setup";
    begin
        // [GIVEN] An archived custom agent
        Initialize();
        Agent.Deactivate(TestAgentId2);
        Agent.Archive(TestAgentId2);

        // [WHEN] Opening the edit instructions page for the archived agent
        asserterror CustomAgentSetup.OpenEditInstructionsPage(TestAgentId2);

        // [THEN] The agent cannot be tested, and no inactive confirmation is shown
        Assert.ExpectedError(ArchivedAgentCannotBeTestedErr);

        // Archiving is terminal, so the shared test agents must be recreated
        Initialized := false;
    end;

    [Test]
    procedure TestGetDescriptionReturnsEachAgentsCurrentSavedText()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        AgentMetadata: Interface IAgentMetadata;
        FirstDescription: Text;
        SecondDescription: Text;
    begin
        // [SCENARIO] Discovery returns the latest saved description for each agent instance.
        // [GIVEN] Two agents with different descriptions share the same metadata provider.
        Initialize();
        AgentMetadata := Enum::"Agent Metadata Provider"::"Custom Agent";

        // [WHEN] Both descriptions are requested from that provider.
        FirstDescription := AgentMetadata.GetDescription(TestAgentId1);
        SecondDescription := AgentMetadata.GetDescription(TestAgentId2);

        // [THEN] Each result matches the setup for the requested agent.
        CustomAgentSetup.Get(TestAgentId1);
        Assert.AreEqual(CustomAgentSetup.Description, FirstDescription, 'The first agent should return its own description.');
        CustomAgentSetup.Get(TestAgentId2);
        Assert.AreEqual(CustomAgentSetup.Description, SecondDescription, 'The second agent should return its own description.');

        // [WHEN] An edit is saved after the first lookup.
        CustomAgentSetup.Description := 'Updated description';
        CustomAgentSetup.Modify(true);

        // [THEN] The same provider returns the edit on the next lookup.
        Assert.AreEqual(CustomAgentSetup.Description, AgentMetadata.GetDescription(TestAgentId2), 'The next read should return the saved edit.');
    end;

    [Test]
    procedure TestGetDescriptionReturnsEmptyForMissingOrClearedData()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        AgentMetadata: Interface IAgentMetadata;
        EmptyGuid: Guid;
    begin
        // [SCENARIO] Discovery returns an empty string when no saved description is available.
        // [GIVEN] Two agents have saved setup records.
        Initialize();
        AgentMetadata := Enum::"Agent Metadata Provider"::"Custom Agent";

        // [WHEN] One description is cleared and the other agent's setup record is deleted.
        CustomAgentSetup.Get(TestAgentId1);
        Clear(CustomAgentSetup.Description);
        CustomAgentSetup.Modify(true);
        CustomAgentSetup.Get(TestAgentId2);
        CustomAgentSetup.Delete(true);
        Initialized := false;

        // [THEN] Neither agent has a description, and neither does a null or unknown agent ID.
        Assert.AreEqual('', AgentMetadata.GetDescription(TestAgentId1), 'A cleared description should remain empty.');
        Assert.AreEqual('', AgentMetadata.GetDescription(TestAgentId2), 'An agent without a setup record should have no description.');
        Assert.AreEqual('', AgentMetadata.GetDescription(EmptyGuid), 'A null agent ID should have no description.');
        Assert.AreEqual('', AgentMetadata.GetDescription(CreateGuid()), 'An unknown agent should have no description.');
    end;

    [Test]
    procedure TestGetDescriptionRequiresAgentAccessToCurrentCompany()
    var
        AgentRecord: Record Agent;
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        CustomAgentSetup: Record "Custom Agent Setup";
        Agent: Codeunit Agent;
        AgentMetadata: Interface IAgentMetadata;
        AgentUserName: Code[50];
        Description: Text;
    begin
        // [SCENARIO] A direct metadata lookup must not disclose a description across companies.
        // [GIVEN] The creator can use the agent, but no permission set gives the agent access to this company.
        AgentUserName := CopyStr(Any.AlphanumericText(MaxStrLen(AgentUserName)), 1, MaxStrLen(AgentUserName));
        CustomAgentSetup."User Security ID" := Agent.Create(Enum::"Agent Metadata Provider"::"Custom Agent", AgentUserName, 'Agent without company access', TempAgentAccessControl);
        CustomAgentSetup.Description := 'Description outside the current company';
        CustomAgentSetup.Insert(true);

        AgentRecord.Get(CustomAgentSetup."User Security ID");
        Assert.IsTrue(AgentRecord."Can Current User Use Agent", 'The caller should have use access to the agent.');
        Assert.IsFalse(AgentRecord."Can Access Current Company", 'The agent should have no access to the current company.');

        // [WHEN] The creator asks the agent's provider directly for the description.
        AgentMetadata := AgentRecord."Agent Metadata Provider";
        Description := AgentMetadata.GetDescription(AgentRecord."User Security ID");

        // [THEN] The saved description is not returned in this company.
        Assert.AreEqual('', Description, 'A direct metadata call must not disclose a description across companies.');
    end;

    [Test]
    procedure TestGetCustomAgents_ReturnsAllAgents()
    var
        TempAgentInfo: Record "Custom Agent Info" temporary;
        CustomAgent: Codeunit "Custom Agent";
    begin
        // [GIVEN] Multiple custom agents exist
        Initialize();

        // [WHEN] Getting all custom agents
        CustomAgent.GetCustomAgents(TempAgentInfo);

        // [THEN] All agents are returned
        Assert.IsTrue(TempAgentInfo.Count >= 2, 'At least 2 custom agents should be returned');

        // Verify the test agents are in the result
        TempAgentInfo.SetRange("User Security ID", TestAgentId1);
        Assert.IsTrue(TempAgentInfo.FindFirst(), 'Test agent 1 should be in the results');
        Assert.AreEqual(TestAgentUserName1, TempAgentInfo."User Name", 'User name should match for agent 1');

        TempAgentInfo.SetRange("User Security ID", TestAgentId2);
        Assert.IsTrue(TempAgentInfo.FindFirst(), 'Test agent 2 should be in the results');
        Assert.AreEqual(TestAgentUserName2, TempAgentInfo."User Name", 'User name should match for agent 2');
    end;

    [Test]
    procedure TestGetUserAccessibleCustomAgents_ReturnsAccessibleAgents()
    var
        TempAgentInfo: Record "Custom Agent Info" temporary;
        CustomAgent: Codeunit "Custom Agent";
    begin
        // [GIVEN] Multiple custom agents exist
        Initialize();

        // [WHEN] Getting user accessible custom agents
        CustomAgent.GetUserAccessibleCustomAgents(TempAgentInfo);

        // [THEN] Accessible agents are returned
        Assert.IsTrue(TempAgentInfo.Count >= 2, 'At least 2 accessible agents should be returned');

        // Verify agents have required fields populated
        TempAgentInfo.FindFirst();
        Assert.IsFalse(IsNullGuid(TempAgentInfo."User Security ID"), 'User Security ID should not be null');
        Assert.AreNotEqual('', TempAgentInfo."User Name", 'User Name should not be empty');
    end;

    [Test]
    procedure TestGetCustomAgentById_ValidId_ReturnsAgent()
    var
        TempAgentInfo: Record "Custom Agent Info" temporary;
        CustomAgent: Codeunit "Custom Agent";
        Result: Boolean;
    begin
        // [GIVEN] A custom agent exists
        Initialize();

        // [WHEN] Getting agent by valid ID
        Result := CustomAgent.GetCustomAgentById(TestAgentId1, TempAgentInfo);

        // [THEN] Agent is found and returned correctly
        Assert.IsTrue(Result, 'Should return true for valid agent ID');
        Assert.AreEqual(TestAgentId1, TempAgentInfo."User Security ID", 'User Security ID should match');
        Assert.AreEqual(TestAgentUserName1, TempAgentInfo."User Name", 'User Name should match');
    end;

    [Test]
    procedure TestGetCustomAgentById_InvalidId_ReturnsFalse()
    var
        TempAgentInfo: Record "Custom Agent Info" temporary;
        CustomAgent: Codeunit "Custom Agent";
        InvalidGuid: Guid;
        Result: Boolean;
    begin
        // [GIVEN] An invalid agent ID
        Initialize();
        InvalidGuid := CreateGuid();

        // [WHEN] Getting agent by invalid ID
        Result := CustomAgent.GetCustomAgentById(InvalidGuid, TempAgentInfo);

        // [THEN] False is returned
        Assert.IsFalse(Result, 'Should return false for invalid agent ID');
    end;

    [Test]
    procedure TestGetCustomAgentByName_ValidName_ReturnsAgent()
    var
        TempAgentInfo: Record "Custom Agent Info" temporary;
        CustomAgent: Codeunit "Custom Agent";
        Result: Boolean;
    begin
        // [GIVEN] A custom agent exists
        Initialize();

        // [WHEN] Getting agent by valid name
        Result := CustomAgent.GetCustomAgentByName(TestAgentUserName1, TempAgentInfo);

        // [THEN] Agent is found and returned correctly
        Assert.IsTrue(Result, 'Should return true for valid agent name');
        Assert.AreEqual(TestAgentId1, TempAgentInfo."User Security ID", 'User Security ID should match');
        Assert.AreEqual(TestAgentUserName1, TempAgentInfo."User Name", 'User Name should match');
    end;

    [Test]
    procedure TestGetCustomAgentByName_InvalidName_ReturnsFalse()
    var
        TempAgentInfo: Record "Custom Agent Info" temporary;
        CustomAgent: Codeunit "Custom Agent";
        Result: Boolean;
    begin
        // [GIVEN] An invalid agent name
        Initialize();

        // [WHEN] Getting agent by invalid name
        Result := CustomAgent.GetCustomAgentByName(CopyStr(Any.AlphanumericText(50), 1, 50), TempAgentInfo);

        // [THEN] False is returned
        Assert.IsFalse(Result, 'Should return false for invalid agent name');
    end;

    [Test]
    procedure TestGetCustomAgents_EmptyBuffer_ClearsExistingData()
    var
        TempAgentInfo: Record "Custom Agent Info" temporary;
        CustomAgent: Codeunit "Custom Agent";
        OldUserName: Code[50];
    begin
        // [GIVEN] Buffer has existing data
        Initialize();
        TempAgentInfo."User Security ID" := CreateGuid();
        OldUserName := CopyStr(Any.AlphanumericText(50), 1, 50);
        TempAgentInfo."User Name" := OldUserName;
        TempAgentInfo.Insert();

        // [WHEN] Getting custom agents
        CustomAgent.GetCustomAgents(TempAgentInfo);

        // [THEN] Old data is cleared and new data is loaded
        TempAgentInfo.SetRange("User Name", OldUserName);
        Assert.IsTrue(TempAgentInfo.IsEmpty(), 'Old data should be cleared');

        TempAgentInfo.Reset();
        Assert.IsFalse(TempAgentInfo.IsEmpty(), 'New data should be loaded');
    end;

    [Test]
    procedure TestGetUserAccessibleCustomAgents_EmptyBuffer_ClearsExistingData()
    var
        TempAgentInfo: Record "Custom Agent Info" temporary;
        CustomAgent: Codeunit "Custom Agent";
        OldUserName: Code[50];
    begin
        // [GIVEN] Buffer has existing data
        Initialize();
        TempAgentInfo."User Security ID" := CreateGuid();
        OldUserName := CopyStr(Any.AlphanumericText(50), 1, 50);
        TempAgentInfo."User Name" := OldUserName;
        TempAgentInfo.Insert();

        // [WHEN] Getting user accessible custom agents
        CustomAgent.GetUserAccessibleCustomAgents(TempAgentInfo);

        // [THEN] Old data is cleared and new data is loaded
        TempAgentInfo.SetRange("User Name", OldUserName);
        Assert.IsTrue(TempAgentInfo.IsEmpty(), 'Old data should be cleared');

        TempAgentInfo.Reset();
        Assert.IsFalse(TempAgentInfo.IsEmpty(), 'New data should be loaded');
    end;

    [Test]
    procedure TestGetCustomAgents_NoAgents_ReturnsEmpty()
    var
        TempAgentInfo: Record "Custom Agent Info" temporary;
        CustomAgentSetup: Record "Custom Agent Setup";
        CustomAgent: Codeunit "Custom Agent";
    begin
        Initialize();

        // [GIVEN] No custom agents exist
        CustomAgentSetup.DeleteAll();

        // [WHEN] Getting custom agents
        CustomAgent.GetCustomAgents(TempAgentInfo);

        // [THEN] Empty result is returned
        Assert.IsTrue(TempAgentInfo.IsEmpty(), 'Should return empty when no agents exist');
    end;

    [Test]
    procedure TestGetUserAccessibleCustomAgents_NoAgents_ReturnsEmpty()
    var
        AgentRec: Record Agent;
        TempAgentInfo: Record "Custom Agent Info" temporary;
        CustomAgent: Codeunit "Custom Agent";
    begin
        Initialize();

        // [GIVEN] No custom agents exist
        AgentRec.SetRange("Agent Metadata Provider", AgentRec."Agent Metadata Provider"::"Custom Agent");
        if AgentRec.FindSet() then
            repeat
                AgentRec.Delete();
            until AgentRec.Next() = 0;

        // [WHEN] Getting user accessible custom agents
        CustomAgent.GetUserAccessibleCustomAgents(TempAgentInfo);

        // [THEN] Empty result is returned
        Assert.IsTrue(TempAgentInfo.IsEmpty(), 'Should return empty when no agents exist');
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}
