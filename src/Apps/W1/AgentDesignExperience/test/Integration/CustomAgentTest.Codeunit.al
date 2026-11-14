// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.Designer.CustomAgent;

using System.Agents;
using System.Agents.Designer;
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
    procedure TestMarkdownEditorSavesAndReopensInstructions()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        InstructionsLog: Record "Custom Agent Instructions Log";
        CustomAgentInstructions: Codeunit "Custom Agent Instructions";
        InstructionsEditor: Page "Agent Instruction Editor";
        Editor: TestPage "Agent Instruction Editor";
        Markdown: Text;
        HistoryCount: Integer;
    begin
        Initialize();
        Markdown := GetMarkdownInstructions();
        InstructionsEditor.SetUserSecurityId(TestAgentId1);
        Editor.Trap();
        InstructionsEditor.Run();

        Assert.IsTrue(Editor.InstructionsPart.InstructionsText.Editable(), 'The test agent instructions must be editable.');
        Editor.InstructionsPart.InstructionsText.SetValue(Markdown);
        Editor.Close();

        CustomAgentSetup.Get(TestAgentId1);
        Assert.AreEqual(Markdown, CustomAgentSetup.GetInstructions(TestAgentId1), 'The native field must save Markdown source without HTML encoding.');
        CustomAgentInstructions.MarkCurrentInstructionsAsReadOnly(CustomAgentSetup);
        InstructionsLog.SetRange("User Security ID", TestAgentId1);
        HistoryCount := InstructionsLog.Count();

        Clear(InstructionsEditor);
        InstructionsEditor.SetUserSecurityId(TestAgentId1);
        Editor.Trap();
        InstructionsEditor.Run();
        Editor.InstructionsPart.InstructionsText.AssertEquals(Markdown);
        Editor.Close();

        Assert.AreEqual(HistoryCount, InstructionsLog.Count(), 'Opening the editor must not rewrite instructions or add history.');
    end;

    [Test]
    [HandlerFunctions('EditTemporaryInstructionsHandler')]
    procedure TestTemporaryInstructionsDialogKeepsChangesLocal()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        InstructionsDialog: Page "Custom Ag. Instructions Dialog";
        OriginalInstructions: Text;
        AcceptedInstructions: Text;
    begin
        Initialize();
        CustomAgentSetup.Get(TestAgentId1);
        OriginalInstructions := CustomAgentSetup.GetInstructions(TestAgentId1);

        InstructionsDialog.SetIsTemporary(true);
        InstructionsDialog.SetUserSecurityId(TestAgentId1);
        InstructionsDialog.SetInstructions('# Staged instructions');
        LibraryVariableStorage.Enqueue('# Staged instructions');
        LibraryVariableStorage.Enqueue(GetMarkdownInstructions());
        LibraryVariableStorage.Enqueue(true);
        InstructionsDialog.RunModal();
        AcceptedInstructions := InstructionsDialog.GetInstructions();
        Assert.AreEqual(GetMarkdownInstructions(), AcceptedInstructions, 'OK must return the edited Markdown to the caller.');
        Assert.AreEqual(OriginalInstructions, CustomAgentSetup.GetInstructions(TestAgentId1), 'Temporary editing must not save before the caller applies the changes.');

        Clear(InstructionsDialog);
        InstructionsDialog.SetIsTemporary(true);
        InstructionsDialog.SetUserSecurityId(TestAgentId1);
        LibraryVariableStorage.Enqueue(OriginalInstructions);
        LibraryVariableStorage.Enqueue('# Cancelled instructions');
        LibraryVariableStorage.Enqueue(false);
        InstructionsDialog.RunModal();
        Assert.AreEqual(OriginalInstructions, CustomAgentSetup.GetInstructions(TestAgentId1), 'Cancelling temporary edits must leave saved instructions unchanged.');

        CustomAgentSetup.SetInstructions(AcceptedInstructions);
        Assert.AreEqual(AcceptedInstructions, CustomAgentSetup.GetInstructions(TestAgentId1), 'The caller must be able to apply the accepted Markdown unchanged.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ReadOnlyInstructionsHandler')]
    procedure TestReadOnlyInstructionPreviewPreservesLongMarkdown()
    var
        InstructionsDialog: Page "Custom Ag. Instructions Dialog";
        Markdown: Text;
    begin
        Markdown := GetMarkdownInstructions() + PadStr('x', 30001, 'x');
        InstructionsDialog.SetReadOnlyMode(true);
        InstructionsDialog.SetInstructions(Markdown);
        LibraryVariableStorage.Enqueue(Markdown);

        InstructionsDialog.RunModal();

        Assert.AreEqual(Markdown, InstructionsDialog.GetInstructions(), 'Previewing instructions must not truncate or rewrite existing source.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RestoreMarkdownHistoryHandler,ConfirmHandler,InstructionsAppliedMessageHandler')]
    procedure TestMarkdownHistoryRestoresFormattingAndRefreshesEditor()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        InstructionsLog: Record "Custom Agent Instructions Log";
        CustomAgentInstructions: Codeunit "Custom Agent Instructions";
        InstructionsEditor: Page "Agent Instruction Editor";
        Editor: TestPage "Agent Instruction Editor";
        Markdown: Text;
    begin
        Initialize();
        Markdown := GetMarkdownInstructions();
        CustomAgentSetup.Get(TestAgentId1);
        InstructionsLog.SetRange("User Security ID", TestAgentId1);
        InstructionsLog.DeleteAll();
        CustomAgentSetup.SetInstructions(Markdown);
        CustomAgentInstructions.MarkCurrentInstructionsAsReadOnly(CustomAgentSetup);
        CustomAgentSetup.SetInstructions('# Latest instructions');
        Commit();

        InstructionsEditor.SetUserSecurityId(TestAgentId1);
        Editor.Trap();
        InstructionsEditor.Run();
        LibraryVariableStorage.Enqueue(Markdown);
        LibraryVariableStorage.Enqueue('This will replace the current instructions.');
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue('The instructions have been successfully applied to the agent.');
        Editor.ViewHistory.Invoke();

        Editor.InstructionsPart.InstructionsText.AssertEquals(Markdown);
        Editor.Close();
        Assert.AreEqual(Markdown, CustomAgentSetup.GetInstructions(TestAgentId1), 'History restore must preserve indentation, line breaks, and trailing spaces.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TestMarkdownLineBreakChangesCreateHistory()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        InstructionsLog: Record "Custom Agent Instructions Log";
        CustomAgentInstructions: Codeunit "Custom Agent Instructions";
        LineFeed: Char;
        Markdown: Text;
    begin
        Initialize();
        LineFeed := 10;
        CustomAgentSetup.Get(TestAgentId1);
        InstructionsLog.SetRange("User Security ID", TestAgentId1);
        InstructionsLog.DeleteAll();
        CustomAgentSetup.SetInstructions('First paragraph' + Format(LineFeed) + 'Second paragraph');
        CustomAgentInstructions.MarkCurrentInstructionsAsReadOnly(CustomAgentSetup);
        Markdown := 'First paragraph' + Format(LineFeed) + Format(LineFeed) + 'Second paragraph';

        CustomAgentSetup.SetInstructions(Markdown);

        Assert.AreEqual(2, InstructionsLog.Count(), 'A Markdown paragraph-break change must create a history entry.');
        InstructionsLog.SetRange("Instruction Version", CustomAgentSetup."Instructions Version");
        InstructionsLog.FindFirst();
        Assert.AreEqual(Markdown, InstructionsLog.GetInstructions(), 'History must preserve the new paragraph break.');
    end;

    [Test]
    procedure TestMarkdownEditorRejectsInvalidInstructions()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        InstructionsEditor: Page "Agent Instruction Editor";
        Editor: TestPage "Agent Instruction Editor";
        MaximumInstructions: Text;
    begin
        Initialize();
        MaximumInstructions := PadStr('x', 30000, 'x');
        InstructionsEditor.SetUserSecurityId(TestAgentId1);
        Editor.Trap();
        InstructionsEditor.Run();
        Editor.InstructionsPart.InstructionsText.SetValue(MaximumInstructions);
        Commit();

        asserterror Editor.InstructionsPart.InstructionsText.SetValue(MaximumInstructions + 'x');
        Assert.ExpectedError(StrSubstNo('Instructions cannot exceed %1 characters.', 30000));
        asserterror Editor.InstructionsPart.InstructionsText.SetValue('   ');
        Assert.ExpectedError('Instructions cannot be empty.');
        Editor.Close();

        CustomAgentSetup.Get(TestAgentId1);
        Assert.AreEqual(MaximumInstructions, CustomAgentSetup.GetInstructions(TestAgentId1), 'Rejected edits must not replace the last valid instructions.');
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

    local procedure GetMarkdownInstructions(): Text
    var
        CarriageReturn: Char;
        LineFeed: Char;
    begin
        CarriageReturn := 13;
        LineFeed := 10;
        exit('    Preserve <tag> & literal text' + Format(CarriageReturn) + Format(LineFeed) +
            '# Instructions' + Format(LineFeed) + Format(LineFeed) +
            '- Review **orders**' + Format(LineFeed) +
            '```al' + Format(LineFeed) + 'Message(''<not-html> & text'');' + Format(LineFeed) +
            '```' + Format(LineFeed) + 'Keep this hard break.  ' + Format(LineFeed) + 'Final instruction.  ');
    end;

    [ModalPageHandler]
    procedure EditTemporaryInstructionsHandler(var InstructionsDialog: TestPage "Custom Ag. Instructions Dialog")
    begin
        InstructionsDialog.InstructionsPart.InstructionsText.AssertEquals(LibraryVariableStorage.DequeueText());
        InstructionsDialog.InstructionsPart.InstructionsText.SetValue(LibraryVariableStorage.DequeueText());
        if LibraryVariableStorage.DequeueBoolean() then
            InstructionsDialog.OK().Invoke()
        else
            InstructionsDialog.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure ReadOnlyInstructionsHandler(var InstructionsDialog: TestPage "Custom Ag. Instructions Dialog")
    begin
        InstructionsDialog.InstructionsPart.InstructionsText.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(InstructionsDialog.InstructionsPart.InstructionsText.Editable(), 'Instruction previews must be read-only.');
        InstructionsDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure RestoreMarkdownHistoryHandler(var InstructionsHistory: TestPage "Cust. Agent Instructions Log")
    begin
        InstructionsHistory.First();
        InstructionsHistory.InstructionsLogPart.InstructionsText.AssertEquals('# Latest instructions');
        Assert.IsFalse(InstructionsHistory.InstructionsLogPart.InstructionsText.Editable(), 'Instruction history must be read-only.');
        InstructionsHistory.Last();
        InstructionsHistory.InstructionsLogPart.InstructionsText.AssertEquals(LibraryVariableStorage.DequeueText());
        InstructionsHistory.ApplyToAgent.Invoke();
    end;

    [MessageHandler]
    procedure InstructionsAppliedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}
