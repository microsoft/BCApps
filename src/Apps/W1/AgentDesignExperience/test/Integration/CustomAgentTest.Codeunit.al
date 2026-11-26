// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.Designer.CustomAgent;

using System.Agents;
using System.Agents.Designer;
using System.Agents.Designer.CustomAgent;
using System.Agents.Internal;
using System.Test.Agents.Designer;
using System.TestLibraries.Utilities;

codeunit 133754 "Custom Agent Test"
// [FEATURE] [Custom Agent] [Manual Task Creation]
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
        DraftTaskTitleTxt: Label 'Task draft', Locked = true;
        DraftMessageTxt: Label 'Draft message', Locked = true;

    local procedure Initialize()
    var
        AgentRec: Record Agent;
        CustomAgentSetup: Record "Custom Agent Setup";
    begin
        LibraryVariableStorage.Clear();
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
        // [SCENARIO] Opening the editor for an inactive agent requires confirmation.
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
        // [SCENARIO] Archived agents cannot open the instruction editor.
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
    [HandlerFunctions('TaskCreationMenuHandler,AgentInstructionEditorPageHandler')]
    procedure TestCreateManualAgentTaskCanOpenTestAgent()
    var
        ManualTaskCreation: Interface IAgentManualTaskCreation;
        Files: List of [FileUpload];
    begin
        // [SCENARIO] The timeline task menu can open Test Agent for the selected custom agent.
        // [GIVEN] An active custom agent and the Test Agent menu option
        Initialize();
        ManualTaskCreation := Enum::"Agent Metadata Provider"::"Custom Agent";
        LibraryVariableStorage.Enqueue(2);

        // [WHEN] Manual task creation is invoked through the metadata provider interface
        ManualTaskCreation.CreateManualAgentTask(TestAgentId1, Files);

        // [THEN] The page handler verifies the expected agent context and all inputs are consumed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TaskCreationMenuHandler')]
    procedure TestCancelManualTaskCreationMenuDoesNothing()
    var
        AgentTask: Record "Agent Task";
        ManualTaskCreation: Interface IAgentManualTaskCreation;
        Files: List of [FileUpload];
        TaskCount: Integer;
    begin
        // [SCENARIO] Cancelling the timeline task menu opens no page and creates no task.
        // [GIVEN] A custom agent and a cancelled menu choice
        Initialize();
        ManualTaskCreation := Enum::"Agent Metadata Provider"::"Custom Agent";
        AgentTask.SetRange("Agent User Security ID", TestAgentId1);
        TaskCount := AgentTask.Count();
        LibraryVariableStorage.Enqueue(0);

        // [WHEN] Manual task creation is invoked
        ManualTaskCreation.CreateManualAgentTask(TestAgentId1, Files);

        // [THEN] No page is opened and the task count is unchanged
        LibraryVariableStorage.AssertEmpty();
        Assert.AreEqual(TaskCount, AgentTask.Count(), 'Canceling the task creation menu must not create a task or open a page.');
    end;

    [Test]
    [HandlerFunctions('TaskCreationMenuHandler,AgentNewTaskMessagePageHandler')]
    procedure TestCreateManualAgentTaskOpensNewTaskPage()
    var
        AgentTask: Record "Agent Task";
        ManualTaskCreation: Interface IAgentManualTaskCreation;
        Files: List of [FileUpload];
        TaskCount: Integer;
    begin
        // [SCENARIO] The Create task option opens the simple task page without submitting on cancellation.
        // [GIVEN] A custom agent and the Create task menu option
        Initialize();
        ManualTaskCreation := Enum::"Agent Metadata Provider"::"Custom Agent";
        AgentTask.SetRange("Agent User Security ID", TestAgentId1);
        TaskCount := AgentTask.Count();
        LibraryVariableStorage.Enqueue(1);

        // [WHEN] Manual task creation opens the task page and its handler cancels
        ManualTaskCreation.CreateManualAgentTask(TestAgentId1, Files);

        // [THEN] The custom-agent navigation action is visible and no task is created
        LibraryVariableStorage.AssertEmpty();
        Assert.AreEqual(TaskCount, AgentTask.Count(), 'Canceling the new task page must not create a task.');
    end;

    [Test]
    [HandlerFunctions('TaskCreationMenuHandler,OpenTestAgentFromTaskPageHandler,AgentInstructionEditorPageHandler')]
    procedure TestNewTaskPageOpensTestAgentWithoutSubmittingDraft()
    var
        AgentTask: Record "Agent Task";
        ManualTaskCreation: Interface IAgentManualTaskCreation;
        Files: List of [FileUpload];
        TaskCount: Integer;
    begin
        // [SCENARIO] Opening Test Agent from the simple task page preserves the unsubmitted draft.
        // [GIVEN] A custom agent and the Create task menu option
        Initialize();
        ManualTaskCreation := Enum::"Agent Metadata Provider"::"Custom Agent";
        AgentTask.SetRange("Agent User Security ID", TestAgentId1);
        TaskCount := AgentTask.Count();
        LibraryVariableStorage.Enqueue(1);

        // [WHEN] The task-page handler enters a draft and opens Test Agent
        ManualTaskCreation.CreateManualAgentTask(TestAgentId1, Files);

        // [THEN] The editor has the expected agent context, the draft is preserved, and no task is submitted
        LibraryVariableStorage.AssertEmpty();
        Assert.AreEqual(TaskCount, AgentTask.Count(), 'Opening Test agent must not submit the task draft.');
    end;

    [Test]
    [HandlerFunctions('OtherAgentNewTaskPageHandler')]
    procedure TestNewTaskPageHidesTestAgentForOtherProviders()
    var
        OtherAgent: Record Agent;
        AgentTask: Record "Agent Task";
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        Agent: Codeunit Agent;
        AgentNewTaskMessage: Page "Agent New Task Message";
    begin
        // [SCENARIO] The simple task page hides Test Agent navigation for other metadata providers.
        // [GIVEN] An agent using a non-custom metadata provider
        Initialize();
        AgentTask."Agent User Security ID" := Agent.Create(
            Enum::"Agent Metadata Provider"::"Designer Test Agent",
            CopyStr(Any.AlphanumericText(50), 1, 50),
            CopyStr(Any.AlphanumericText(80), 1, 80),
            TempAgentAccessControl);
        AgentNewTaskMessage.SetAgentTask(AgentTask, true);
        AgentNewTaskMessage.LookupMode(true);

        // [WHEN] The simple task page is opened for that agent
        AgentNewTaskMessage.RunModal();

        // [THEN] The page handler verifies that the Test Agent action is hidden
        OtherAgent.Get(AgentTask."Agent User Security ID");
        OtherAgent.Delete();
    end;

    [Test]
    [HandlerFunctions('TaskCreationMenuHandler,ConfirmHandler')]
    procedure TestCreateManualAgentTaskForInactiveAgentShowsConfirmation()
    var
        Agent: Codeunit Agent;
        ManualTaskCreation: Interface IAgentManualTaskCreation;
        Files: List of [FileUpload];
    begin
        // [SCENARIO] Creating a simple task for an inactive agent requires confirmation.
        // [GIVEN] An inactive custom agent and a declined confirmation
        Initialize();
        Agent.Deactivate(TestAgentId1);
        ManualTaskCreation := Enum::"Agent Metadata Provider"::"Custom Agent";
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue('inactive');
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] The Create task menu option is selected
        ManualTaskCreation.CreateManualAgentTask(TestAgentId1, Files);

        // [THEN] The confirmation is shown and no task page is opened
        LibraryVariableStorage.AssertEmpty();
        Agent.Activate(TestAgentId1);
    end;

    [Test]
    [HandlerFunctions('TaskCreationMenuHandler')]
    procedure TestCreateManualAgentTaskForArchivedAgentIsBlocked()
    var
        Agent: Codeunit Agent;
        ManualTaskCreation: Interface IAgentManualTaskCreation;
        Files: List of [FileUpload];
    begin
        // [SCENARIO] Archived agents cannot create manual tasks.
        // [GIVEN] An archived custom agent and the Create task menu option
        Initialize();
        Agent.Deactivate(TestAgentId2);
        Agent.Archive(TestAgentId2);
        ManualTaskCreation := Enum::"Agent Metadata Provider"::"Custom Agent";
        LibraryVariableStorage.Enqueue(1);

        // [WHEN] Manual task creation is invoked
        asserterror ManualTaskCreation.CreateManualAgentTask(TestAgentId2, Files);

        // [THEN] The archived-agent error is raised and no task page is opened
        Assert.ExpectedError(ArchivedAgentCannotBeTestedErr);
        LibraryVariableStorage.AssertEmpty();
        Initialized := false;
    end;

    [Test]
    procedure TestBusinessSkillsOptInFollowsAgentConfiguration()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        MetadataProvider: Enum "Agent Metadata Provider";
        AgentExperimental: Interface IAgentExperimental;
    begin
        // [SCENARIO] New agents use Business Skills by default and honor independent saved settings.
        // [GIVEN] Two new custom agents
        Initialize();
        MetadataProvider := MetadataProvider::"Custom Agent";
        AgentExperimental := MetadataProvider;
        Assert.IsTrue(AgentExperimental.IsOptInFeatureEnabled(TestAgentId1, Enum::"Agent Opt In Feature"::BusinessIQ), 'Business Skills must be enabled by default for new agents.');
        Assert.IsTrue(AgentExperimental.IsOptInFeatureEnabled(TestAgentId2, Enum::"Agent Opt In Feature"::BusinessIQ), 'Business Skills must be enabled by default for each new agent.');

        // [WHEN] Business Skills are disabled for the first agent
        CustomAgentSetup.Get(TestAgentId1);
        CustomAgentSetup."Use Business Skills" := false;
        CustomAgentSetup.Modify(true);

        // [THEN] The saved value is used without affecting other agents
        Assert.IsFalse(AgentExperimental.IsOptInFeatureEnabled(TestAgentId1, Enum::"Agent Opt In Feature"::BusinessIQ), 'The saved disabled setting must override the default.');
        Assert.IsTrue(AgentExperimental.IsOptInFeatureEnabled(TestAgentId2, Enum::"Agent Opt In Feature"::BusinessIQ), 'Disabling Business Skills must not affect other agents.');

        // [WHEN] Business Skills are enabled again
        CustomAgentSetup."Use Business Skills" := true;
        CustomAgentSetup.Modify(true);

        // [THEN] The configured agent opts in, while missing agents do not
        Assert.IsTrue(AgentExperimental.IsOptInFeatureEnabled(TestAgentId1, Enum::"Agent Opt In Feature"::BusinessIQ), 'Enabling Business Skills must opt the configured agent in.');
        Assert.IsFalse(AgentExperimental.IsOptInFeatureEnabled(CreateGuid(), Enum::"Agent Opt In Feature"::BusinessIQ), 'Agents without configuration must not opt in to Business Skills.');
    end;

    [Test]
    procedure TestMarkdownEditorSavesAndReopensInstructions()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        InstructionsLog: Record "Custom Agent Instructions Log";
        InstructionsEditor: Page "Agent Instruction Editor";
        Editor: TestPage "Agent Instruction Editor";
        OriginalInstructions: Text;
        OriginalVersion: Text[100];
        Markdown: Text;
        HistoryCount: Integer;
    begin
        // [SCENARIO] Editing instructions preserves the previous version and reopening adds no history.
        // [GIVEN] A custom agent with saved instructions and history
        Initialize();
        CustomAgentSetup.Get(TestAgentId1);
        OriginalInstructions := CustomAgentSetup.GetInstructions(TestAgentId1);
        OriginalVersion := CustomAgentSetup."Instructions Version";
        InstructionsLog.SetRange("User Security ID", TestAgentId1);
        HistoryCount := InstructionsLog.Count();
        Markdown := GetMarkdownInstructions();
        InstructionsEditor.SetUserSecurityId(TestAgentId1);
        Editor.Trap();
        InstructionsEditor.Run();

        // [WHEN] Instructions are edited in the Test Agent page
        Assert.IsTrue(Editor.InstructionsPart.InstructionsText.Editable(), 'The test agent instructions must be editable.');
        Editor.InstructionsPart.InstructionsText.SetValue(Markdown);
        Editor.Close();

        // [THEN] The new instructions are saved without overwriting the previous history entry
        CustomAgentSetup.Get(TestAgentId1);
        Assert.AreEqual(Markdown, CustomAgentSetup.GetInstructions(TestAgentId1), 'The native field must save Markdown source without HTML encoding.');
        Assert.AreEqual(HistoryCount + 1, InstructionsLog.Count(), 'Editing instructions must create a new history entry automatically.');
        InstructionsLog.SetRange("Instruction Version", OriginalVersion);
        InstructionsLog.FindFirst();
        Assert.AreEqual(OriginalInstructions, InstructionsLog.GetInstructions(), 'Editing instructions must preserve the previous version.');
        Assert.IsTrue(InstructionsLog."Read-Only Instructions", 'The previous version must be read-only.');
        InstructionsLog.SetRange("Instruction Version");
        HistoryCount := InstructionsLog.Count();

        // [WHEN] The editor is reopened without changing instructions
        Clear(InstructionsEditor);
        InstructionsEditor.SetUserSecurityId(TestAgentId1);
        Editor.Trap();
        InstructionsEditor.Run();
        Editor.InstructionsPart.InstructionsText.AssertEquals(Markdown);
        Editor.Close();

        // [THEN] Reopening does not create a duplicate history entry
        Assert.AreEqual(HistoryCount, InstructionsLog.Count(), 'Opening the editor must not rewrite instructions or add history.');
    end;

    [Test]
    [HandlerFunctions('EditAgentSetupInstructionsHandler,EditTemporaryInstructionsHandler')]
    procedure TestSetupInstructionChangesCreateHistoryOnlyOnUpdate()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        InstructionsLog: Record "Custom Agent Instructions Log";
        SetupPage: Page "Custom Agent Setup";
        OriginalInstructions: Text;
        OriginalVersion: Text[100];
        Markdown: Text;
        HistoryCount: Integer;
    begin
        // [SCENARIO] Updating setup records instruction history, while cancelling discards staged edits.
        // [GIVEN] A configured agent with existing instructions and history
        Initialize();
        CustomAgentSetup.Get(TestAgentId1);
        OriginalInstructions := CustomAgentSetup.GetInstructions(TestAgentId1);
        OriginalVersion := CustomAgentSetup."Instructions Version";
        InstructionsLog.SetRange("User Security ID", TestAgentId1);
        HistoryCount := InstructionsLog.Count();
        Markdown := GetMarkdownInstructions();

        // [WHEN] Edited instructions are accepted in the dialog and the setup is updated
        CustomAgentSetup.SetRange("User Security ID", TestAgentId1);
        SetupPage.SetTableView(CustomAgentSetup);
        LibraryVariableStorage.Enqueue(OriginalInstructions);
        LibraryVariableStorage.Enqueue(Markdown);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        SetupPage.RunModal();

        // [THEN] The new instructions are saved and the previous version is preserved
        Assert.AreEqual(Markdown, CustomAgentSetup.GetInstructions(TestAgentId1), 'Updating setup must save the accepted instructions.');
        Assert.AreEqual(HistoryCount + 1, InstructionsLog.Count(), 'Updating setup must create a new history entry.');
        InstructionsLog.SetRange("Instruction Version", OriginalVersion);
        InstructionsLog.FindFirst();
        Assert.AreEqual(OriginalInstructions, InstructionsLog.GetInstructions(), 'Updating setup must preserve the previous instructions.');
        Assert.IsTrue(InstructionsLog."Read-Only Instructions", 'The previous version must be read-only.');
        InstructionsLog.SetRange("Instruction Version");
        HistoryCount := InstructionsLog.Count();

        // [WHEN] Another edit is accepted in the dialog but the setup is cancelled
        Clear(SetupPage);
        SetupPage.SetTableView(CustomAgentSetup);
        LibraryVariableStorage.Enqueue(Markdown);
        LibraryVariableStorage.Enqueue('# Cancelled setup instructions');
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        SetupPage.RunModal();

        // [THEN] Neither saved instructions nor history change
        Assert.AreEqual(Markdown, CustomAgentSetup.GetInstructions(TestAgentId1), 'Cancelling setup must discard staged instruction edits.');
        Assert.AreEqual(HistoryCount, InstructionsLog.Count(), 'Cancelling setup must not create history.');
        LibraryVariableStorage.AssertEmpty();
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
        // [SCENARIO] Temporary instruction edits are saved only when the caller applies them.
        // [GIVEN] A custom agent with saved instructions
        Initialize();
        CustomAgentSetup.Get(TestAgentId1);
        OriginalInstructions := CustomAgentSetup.GetInstructions(TestAgentId1);

        // [WHEN] New instructions are accepted in a temporary dialog
        InstructionsDialog.SetIsTemporary(true);
        InstructionsDialog.SetUserSecurityId(TestAgentId1);
        InstructionsDialog.SetInstructions('# Staged instructions');
        LibraryVariableStorage.Enqueue('# Staged instructions');
        LibraryVariableStorage.Enqueue(GetMarkdownInstructions());
        LibraryVariableStorage.Enqueue(true);
        InstructionsDialog.RunModal();
        // [THEN] The edited text is returned without changing persistent instructions
        AcceptedInstructions := InstructionsDialog.GetInstructions();
        Assert.AreEqual(GetMarkdownInstructions(), AcceptedInstructions, 'OK must return the edited Markdown to the caller.');
        Assert.AreEqual(OriginalInstructions, CustomAgentSetup.GetInstructions(TestAgentId1), 'Temporary editing must not save before the caller applies the changes.');

        // [WHEN] Another temporary edit is cancelled
        Clear(InstructionsDialog);
        InstructionsDialog.SetIsTemporary(true);
        InstructionsDialog.SetUserSecurityId(TestAgentId1);
        LibraryVariableStorage.Enqueue(OriginalInstructions);
        LibraryVariableStorage.Enqueue('# Cancelled instructions');
        LibraryVariableStorage.Enqueue(false);
        InstructionsDialog.RunModal();
        // [THEN] Saved instructions remain unchanged
        Assert.AreEqual(OriginalInstructions, CustomAgentSetup.GetInstructions(TestAgentId1), 'Cancelling temporary edits must leave saved instructions unchanged.');

        // [WHEN] The caller applies the previously accepted instructions
        CustomAgentSetup.SetInstructions(AcceptedInstructions);
        // [THEN] The accepted Markdown is saved unchanged
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
        // [SCENARIO] Read-only previews preserve long Markdown without allowing edits.
        // [GIVEN] Instructions longer than the native editor limit
        Initialize();
        Markdown := GetMarkdownInstructions() + PadStr('x', 30001, 'x');
        InstructionsDialog.SetReadOnlyMode(true);
        InstructionsDialog.SetInstructions(Markdown);
        LibraryVariableStorage.Enqueue(Markdown);

        // [WHEN] The instructions are previewed
        InstructionsDialog.RunModal();

        // [THEN] The complete source is retained
        Assert.AreEqual(Markdown, InstructionsDialog.GetInstructions(), 'Previewing instructions must not truncate or rewrite existing source.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('RestoreMarkdownHistoryHandler,ConfirmHandler,InstructionsAppliedMessageHandler')]
    procedure TestMarkdownHistoryRestoresFormattingAndRefreshesEditor()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        InstructionsLog: Record "Custom Agent Instructions Log";
        InstructionsEditor: Page "Agent Instruction Editor";
        Editor: TestPage "Agent Instruction Editor";
        Markdown: Text;
    begin
        // [SCENARIO] Restoring an earlier version preserves Markdown and refreshes the editor.
        // [GIVEN] An agent with two different instruction versions
        Initialize();
        Markdown := GetMarkdownInstructions();
        CustomAgentSetup.Get(TestAgentId1);
        InstructionsLog.SetRange("User Security ID", TestAgentId1);
        InstructionsLog.DeleteAll();
        CustomAgentSetup.SetInstructions(Markdown);
        CustomAgentSetup.SetInstructions('# Latest instructions');
        Commit();

        InstructionsEditor.SetUserSecurityId(TestAgentId1);
        Editor.Trap();
        InstructionsEditor.Run();
        LibraryVariableStorage.Enqueue(Markdown);
        LibraryVariableStorage.Enqueue('This will replace the current instructions.');
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue('The instructions have been successfully applied to the agent.');
        // [WHEN] The earlier version is restored from history
        Editor.ViewHistory.Invoke();

        // [THEN] Both the editor and saved instructions contain the restored Markdown
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
        ExpectedInstructions: TextBuilder;
        Markdown: Text;
        InstructionsVersion: Text[100];
    begin
        // [SCENARIO] Paragraph-break changes create history, but unchanged text does not.
        // [GIVEN] Instructions containing one line break
        Initialize();
        LineFeed := 10;
        CustomAgentSetup.Get(TestAgentId1);
        InstructionsLog.SetRange("User Security ID", TestAgentId1);
        InstructionsLog.DeleteAll();
        CustomAgentSetup.SetInstructions('First paragraph' + Format(LineFeed) + 'Second paragraph');
        Markdown := 'First paragraph' + Format(LineFeed) + Format(LineFeed) + 'Second paragraph';
        ExpectedInstructions.AppendLine('First paragraph');
        ExpectedInstructions.AppendLine();
        ExpectedInstructions.Append('Second paragraph');

        // [WHEN] A paragraph break is added
        CustomAgentSetup.SetInstructions(Markdown);

        // [THEN] A new history entry preserves the paragraph break
        Assert.AreEqual(2, InstructionsLog.Count(), 'A Markdown paragraph-break change must create a history entry.');
        InstructionsLog.SetRange("Instruction Version", CustomAgentSetup."Instructions Version");
        InstructionsLog.FindFirst();
        Assert.AreEqual(ExpectedInstructions.ToText(), InstructionsLog.GetInstructions(), 'History must preserve the new paragraph break.');
        InstructionsLog.SetRange("Instruction Version");
        InstructionsVersion := CustomAgentSetup."Instructions Version";

        // [WHEN] The current version is marked read-only and the same LF source is saved again
        CustomAgentInstructions.MarkCurrentInstructionsAsReadOnly(CustomAgentSetup);
        CustomAgentSetup.SetInstructions(Markdown);

        // [THEN] Neither the history count nor the current version changes
        Assert.AreEqual(2, InstructionsLog.Count(), 'Reading LF text with normalized line endings must not create duplicate history.');
        Assert.AreEqual(InstructionsVersion, CustomAgentSetup."Instructions Version", 'Saving unchanged instructions must retain the current version.');

        // [WHEN] The same instructions are saved with normalized line endings
        CustomAgentSetup.SetInstructions(ExpectedInstructions.ToText());

        // [THEN] Line-ending normalization does not create another version
        Assert.AreEqual(2, InstructionsLog.Count(), 'Normalizing line endings must not create duplicate history.');
        Assert.AreEqual(InstructionsVersion, CustomAgentSetup."Instructions Version", 'Normalizing line endings must retain the current version.');
    end;

    [Test]
    procedure TestMarkdownEditorRejectsEmptyInstructions()
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        InstructionsEditor: Page "Agent Instruction Editor";
        Editor: TestPage "Agent Instruction Editor";
        Instructions: Text;
    begin
        // [SCENARIO] Empty instruction edits are rejected without losing the previous valid source.
        // [GIVEN] An editor containing long valid Markdown
        Initialize();
        Instructions := GetMarkdownInstructions() + PadStr('x', 30001, 'x');
        InstructionsEditor.SetUserSecurityId(TestAgentId1);
        Editor.Trap();
        InstructionsEditor.Run();
        Editor.InstructionsPart.InstructionsText.SetValue(Instructions);
        Commit();

        // [WHEN] Instructions are replaced with whitespace
        asserterror Editor.InstructionsPart.InstructionsText.SetValue('   ');
        // [THEN] The edit is rejected and the last valid instructions remain saved
        Assert.ExpectedError('Instructions cannot be empty.');
        Editor.Close();

        CustomAgentSetup.Get(TestAgentId1);
        Assert.AreEqual(Instructions, CustomAgentSetup.GetInstructions(TestAgentId1), 'AL validation must not duplicate the control limit, and rejected empty edits must preserve the last valid instructions.');
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

    [PageHandler]
    procedure AgentInstructionEditorPageHandler(var AgentInstructionEditor: TestPage "Agent Instruction Editor")
    var
        CustomAgentSetup: Record "Custom Agent Setup";
    begin
        CustomAgentSetup.Get(TestAgentId1);
        Assert.IsTrue(AgentInstructionEditor.GoToRecord(CustomAgentSetup), 'The instruction editor must show the selected agent setup.');
        CustomAgentSetup.Get(TestAgentId2);
        Assert.IsFalse(AgentInstructionEditor.GoToRecord(CustomAgentSetup), 'The instruction editor must exclude other agents from its context.');
        AgentInstructionEditor.Close();
    end;

    [StrMenuHandler]
    procedure TaskCreationMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    procedure AgentNewTaskMessagePageHandler(var AgentNewTaskMessage: TestPage "Agent New Task Message")
    begin
        Assert.IsTrue(AgentNewTaskMessage.TestAgent.Visible(), 'The Test agent action must be visible for custom agents.');
        AgentNewTaskMessage.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure OpenTestAgentFromTaskPageHandler(var AgentNewTaskMessage: TestPage "Agent New Task Message")
    begin
        AgentNewTaskMessage.TitleText.SetValue(DraftTaskTitleTxt);
        AgentNewTaskMessage.MessageText.SetValue(DraftMessageTxt);

        AgentNewTaskMessage.TestAgent.Invoke();

        AgentNewTaskMessage.TitleText.AssertEquals(DraftTaskTitleTxt);
        AgentNewTaskMessage.MessageText.AssertEquals(DraftMessageTxt);
        AgentNewTaskMessage.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure OtherAgentNewTaskPageHandler(var AgentNewTaskMessage: TestPage "Agent New Task Message")
    begin
        Assert.IsFalse(AgentNewTaskMessage.TestAgent.Visible(), 'The Test agent action must be hidden for other agent providers.');
        AgentNewTaskMessage.Cancel().Invoke();
    end;

    local procedure GetMarkdownInstructions(): Text
    var
        Instructions: TextBuilder;
    begin
        Instructions.AppendLine('    Preserve <tag> & literal text');
        Instructions.AppendLine('# Instructions');
        Instructions.AppendLine();
        Instructions.AppendLine('- Review **orders**');
        Instructions.AppendLine('```al');
        Instructions.AppendLine('Message(''<not-html> & text'');');
        Instructions.AppendLine('```');
        Instructions.AppendLine('Keep this hard break.  ');
        Instructions.Append('Final instruction.  ');
        exit(Instructions.ToText());
    end;

    [ModalPageHandler]
    procedure EditAgentSetupInstructionsHandler(var SetupPage: TestPage "Custom Agent Setup")
    var
        CustomAgentSetup: Record "Custom Agent Setup";
        InstructionsLog: Record "Custom Agent Instructions Log";
        OriginalInstructions: Text;
        HistoryCount: Integer;
    begin
        CustomAgentSetup.Get(TestAgentId1);
        OriginalInstructions := CustomAgentSetup.GetInstructions(TestAgentId1);
        InstructionsLog.SetRange("User Security ID", TestAgentId1);
        HistoryCount := InstructionsLog.Count();

        SetupPage.EditInstructions.DrillDown();

        Assert.AreEqual(OriginalInstructions, CustomAgentSetup.GetInstructions(TestAgentId1), 'Accepting the instruction dialog must not save before setup is updated.');
        Assert.AreEqual(HistoryCount, InstructionsLog.Count(), 'Accepting the instruction dialog must not create history before setup is updated.');
        if LibraryVariableStorage.DequeueBoolean() then
            SetupPage.OK().Invoke()
        else
            SetupPage.Cancel().Invoke();
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
