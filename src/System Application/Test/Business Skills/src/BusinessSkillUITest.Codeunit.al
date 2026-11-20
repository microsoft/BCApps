// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.AI.BusinessSkills;

using System.AI.BusinessSkills;
using System.TestLibraries.AI.BusinessSkills;
using System.TestLibraries.Utilities;

codeunit 130052 "Business Skill UI Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    trigger OnRun()
    begin
        // [FEATURE] [Business Skills] [UI]
    end;

    /// <summary>
    /// History visibility follows manual ownership as the card switches between skills and new records.
    /// </summary>
    [Test]
    procedure HistoryIsVisibleOnlyForSavedManualSkills()
    var
        ManualSkill: Record "Business Skill";
        AppSkill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [SCENARIO] History visibility follows manual ownership as the card switches between skills and new records.
        Initialize();
        ManualSkill.Get(LibraryBusinessSkill.CreateSkill('Manual skill', SecretStrSubstNo('Manual content')));
        AppSkill.Get(LibraryBusinessSkill.CreateAppOwnedSkill('HISTORY-UI', 'App skill', SecretStrSubstNo('App content')));
        Commit();

        SkillCard.OpenView();
        SkillCard.GoToRecord(ManualSkill);
        Assert.IsTrue(SkillCard.SkillContentEditor.ViewHistory.Visible(), 'Manual skills must expose history.');
        SkillCard.GoToRecord(AppSkill);
        Assert.IsFalse(SkillCard.SkillContentEditor.ViewHistory.Visible(), 'App-owned skills must hide history.');
        Assert.IsTrue(SkillCard.SkillContentEditor.DownloadContent.Visible(), 'Current app-owned content must remain downloadable.');
        SkillCard.SkillContentEditor.SkillContent.AssertEquals('App content');
        SkillCard.GoToRecord(ManualSkill);
        Assert.IsTrue(SkillCard.SkillContentEditor.ViewHistory.Visible(), 'History visibility must refresh on navigation.');
        SkillCard.Close();
        SkillCard.OpenNew();
        Assert.IsFalse(SkillCard.SkillContentEditor.ViewHistory.Visible(), 'Unsaved skills must not expose history.');
        SkillCard.Close();
    end;

    /// <summary>
    /// Directly opening app-owned history is rejected even if historical rows remain.
    /// </summary>
    [Test]
    procedure AppOwnedHistoryCannotBeOpenedDirectly()
    var
        Skill: Record "Business Skill";
        Version: Record "Bus Skill Content Version";
        Versions: Page "Bus Skill Content Versions";
    begin
        // [SCENARIO] Directly opening app-owned history is rejected even if historical rows remain.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateAppOwnedSkill('OLD-HISTORY', 'App skill', SecretStrSubstNo('Current')));
        Version."Skill ID" := Skill.ID;
        Version.SetContent(SecretStrSubstNo('Old content'));
        Version.Insert(true);
        Commit();
        Versions.SetSkillId(Skill.ID);

        asserterror Versions.RunModal();

        Assert.ExpectedError('Manual must be equal to');
        AssertVersionCount(Skill.ID, 1);
        AssertContentEquals(SecretStrSubstNo('Current'), BusinessSkillImpl.GetContent(Skill), 'Rejected history access must preserve current content.');
    end;

    /// <summary>
    /// Verifies card-created skills default inactive and activate only after instructions are supplied.
    /// </summary>
    [Test]
    [HandlerFunctions('DeclineActivationOnClose')]
    procedure SkillCardCreatesInactiveSkill()
    var
        Skill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [SCENARIO] Verifies card-created skills default inactive and activate only after instructions are supplied.
        // [GIVEN] A new skill card.
        Initialize();
        // [WHEN] Metadata is entered, edited, and the new skill is activated.
        SkillCard.OpenNew();
        SkillCard.Title.SetValue('Created from card');
        SkillCard.Description.SetValue('Created description');
        Skill.SetRange(Title, 'Created from card');
        Skill.FindFirst();
        // [THEN] It defaults to inactive until complete text allows activation.
        Assert.AreEqual('Created description', Skill.Description, 'Description validation saves metadata before the text editor can write.');
        SkillCard.Close();
        Skill.SetRange(Title, 'Created from card');
        Assert.AreEqual(1, Skill.Count(), 'The native card must create one canonical skill.');
        Skill.FindFirst();
        Assert.AreEqual(Skill.Status::Inactive, Skill.Status, 'Card-created content stays inactive until activation.');
        Assert.AreEqual('Created description', Skill.Description, 'Card creation persists the description.');
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        SkillCard.Description.SetValue('Edited description');
        Skill.Get(Skill.ID);
        Assert.AreEqual('Edited description', Skill.Description, 'Existing-card metadata is saved before editing text.');
        SkillCard.Close();
        Skill.Get(Skill.ID);
        Assert.AreEqual('Edited description', Skill.Description, 'Native editing must not drop metadata-only changes.');
        AssertContentEquals(SecretStrSubstNo(''), BusinessSkillImpl.GetContent(Skill), 'Description editing does not invent instructions.');
        Commit();
        asserterror BusinessSkillImpl.ActivateSkill(Skill.ID);
        Assert.ExpectedError('title and skill content');
        BusinessSkillImpl.SetContent(Skill.ID, SecretStrSubstNo('Body'));
        BusinessSkillImpl.ActivateSkill(Skill.ID);
        Skill.Get(Skill.ID);
        Assert.AreEqual(Skill.Status::Active, Skill.Status, 'A completed native skill can be activated.');
        AssertVersionCount(Skill.ID, 2);
    end;

    /// <summary>
    /// Verifies confirming activation on card close activates the skill and preserves its metadata and text.
    /// </summary>
    [Test]
    [HandlerFunctions('AcceptActivationOnClose')]
    procedure SkillCardCanActivateOnClose()
    var
        Skill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [SCENARIO] Verifies confirming activation on card close activates the skill and preserves its metadata and text.
        // [GIVEN] A complete inactive skill opened on its card.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateSkill('Activate on close', SecretStrSubstNo('Instructions')));
        BusinessSkillImpl.DeactivateSkill(Skill.ID);
        Skill.Get(Skill.ID);
        Commit();
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        SkillCard.Description.SetValue('Saved before activation');
        // [WHEN] The card closes with activation confirmed.
        SkillCard.Close();
        Skill.Get(Skill.ID);
        // [THEN] The skill becomes active.
        Assert.AreEqual(Skill.Status::Active, Skill.Status, 'Accepting the prompt activates the skill.');
        Assert.AreEqual('Saved before activation', Skill.Description, 'Closing preserves metadata.');
        AssertContentEquals(SecretStrSubstNo('Instructions'), BusinessSkillImpl.GetContent(Skill), 'Closing preserves the instructions.');
    end;

    /// <summary>
    /// Verifies activation on card close fails when the skill has no instructions and leaves it inactive.
    /// </summary>
    [Test]
    [HandlerFunctions('AcceptActivationOnClose')]
    procedure SkillCardActivationOnCloseRequiresText()
    var
        Skill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [SCENARIO] Verifies activation on card close fails when the skill has no instructions and leaves it inactive.
        // [GIVEN] A new skill card without instruction text.
        Initialize();
        SkillCard.OpenNew();
        SkillCard.Title.SetValue('Incomplete on close');
        Commit();
        // [WHEN] Activation is requested on close.
        asserterror SkillCard.Close();
        // [THEN] The incomplete skill cannot be activated.
        Assert.ExpectedError('title and skill content');
        Skill.SetRange(Title, 'Incomplete on close');
        Skill.FindFirst();
        Assert.AreEqual(Skill.Status::Inactive, Skill.Status, 'Failed activation must leave the skill inactive.');
    end;

    /// <summary>
    /// Verifies viewing or closing a blank new card neither activates a skill nor creates an empty record.
    /// </summary>
    [Test]
    procedure SkillCardViewAndEmptyNewCloseWithoutActivationPrompt()
    var
        Skill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [SCENARIO] Verifies viewing or closing a blank new card neither activates a skill nor creates an empty record.
        // [GIVEN] A read-only inactive skill and a blank new card.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateSkill('Read-only inactive', SecretStrSubstNo('Instructions')));
        BusinessSkillImpl.DeactivateSkill(Skill.ID);
        Skill.Get(Skill.ID);
        Commit();
        // [WHEN] Each card is closed.
        SkillCard.OpenView();
        SkillCard.GoToRecord(Skill);
        SkillCard.Close();
        SkillCard.OpenNew();
        SkillCard.Close();
        // [THEN] Neither view triggers an activation prompt.
        Assert.AreEqual(1, Skill.Count(), 'An untouched new card must not create an empty skill.');
        Skill.Get(Skill.ID);
        Assert.AreEqual(Skill.Status::Inactive, Skill.Status, 'Viewing a skill does not activate it.');
    end;

    [ConfirmHandler]
    procedure AcceptActivationOnClose(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual('This skill is inactive. Do you want to activate it before closing?', Question, 'Closing asks about activation.');
        Assert.IsFalse(Reply, 'Activation must be an explicit choice.');
        Reply := true;
    end;

    [ConfirmHandler]
    procedure DeclineActivationOnClose(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual('This skill is inactive. Do you want to activate it before closing?', Question, 'Closing asks about activation.');
        Assert.IsFalse(Reply, 'Activation must be an explicit choice.');
        Reply := false;
    end;

    /// <summary>
    /// Verifies the skill list shows canonical skills regardless of their status.
    /// </summary>
    [Test]
    procedure SkillListShowsCanonicalSkillsRegardlessOfStatus()
    var
        Skill: Record "Business Skill";
        SkillList: TestPage "Business Skills";
        ActiveSkillId: BigInteger;
        InactiveSkillId: BigInteger;
    begin
        // [SCENARIO] Verifies the skill list shows canonical skills regardless of their status.
        // [GIVEN] Skills in different lifecycle states.
        Initialize();
        ActiveSkillId := LibraryBusinessSkill.CreateSkill('Active skill', SecretStrSubstNo('Body'));
        InactiveSkillId := LibraryBusinessSkill.CreateSkill('Inactive skill', SecretStrSubstNo('Body'));
        BusinessSkillImpl.DeactivateSkill(InactiveSkillId);
        Commit();
        // [WHEN] The skill list is opened.
        SkillList.OpenView();
        // [THEN] Canonical rows retain their status.
        Skill.Get(ActiveSkillId);
        SkillList.GoToRecord(Skill);
        SkillList.Title.AssertEquals('Active skill');
        SkillList.Status.AssertEquals(Format(Skill.Status));
        Skill.Get(InactiveSkillId);
        SkillList.GoToRecord(Skill);
        SkillList.Title.AssertEquals('Inactive skill');
        SkillList.Status.AssertEquals(Format(Skill.Status));
        SkillList.Close();
    end;

    /// <summary>
    /// Verifies card activation and deactivation change status without altering stored instructions.
    /// </summary>
    [Test]
    procedure SkillCardActionsChangeStatusWithoutLosingContent()
    var
        Skill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
        SkillId: BigInteger;
    begin
        // [SCENARIO] Verifies card activation and deactivation change status without altering stored instructions.
        // [GIVEN] A skill with persisted instruction text.
        Initialize();
        SkillId := LibraryBusinessSkill.CreateSkill('Lifecycle skill', SecretStrSubstNo('Body'));
        Skill.Get(SkillId);
        Commit();
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        // [WHEN] Card actions activate and deactivate it.
        SkillCard.Deactivate.Invoke();
        // [THEN] Status changes without losing content.
        SkillCard.Status.AssertEquals(Format(Skill.Status::Inactive));
        SkillCard.Activate.Invoke();
        SkillCard.Status.AssertEquals(Format(Skill.Status::Active));
        SkillCard.Close();
        Skill.Get(SkillId);
        AssertContentEquals(SecretStrSubstNo('Body'), BusinessSkillImpl.GetContent(Skill), 'Lifecycle actions must preserve the canonical instructions.');
        Assert.AreEqual(Skill.Status::Active, Skill.Status, 'Activation persists after the card closes.');
    end;

    /// <summary>
    /// Markdown field edits retain source text and keep parent metadata and instruction history synchronized.
    /// </summary>
    [Test]
    procedure MarkdownFieldSavesAndReopensInstructions()
    var
        Skill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
        Markdown: Text;
    begin
        // [SCENARIO] Markdown field edits retain source text and keep parent metadata and instruction history synchronized.
        // [GIVEN] An active skill and Markdown containing headings, tasks, and fenced AL.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateSkill('Markdown skill', SecretStrSubstNo('# Original')));
        Markdown := '# Instructions' + GetLineBreak() + GetLineBreak() +
            '- [ ] Review **orders**' + GetLineBreak() + '```al' + GetLineBreak() +
            'Message(''Review'');' + GetLineBreak() + '```';
        Commit();

        // [WHEN] Instructions and metadata are edited on the same card.
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        SkillCard.SkillContentEditor.SkillContent.AssertEquals('# Original');
        SkillCard.SkillContentEditor.SkillContent.SetValue(Markdown);
        SkillCard.Title.SetValue('Updated Markdown skill');
        SkillCard.SkillContentEditor.SkillContent.SetValue(Markdown + GetLineBreak() + 'Final instruction');
        SkillCard.Close();

        // [THEN] Both edits persist and reopening displays the latest Markdown without adding history.
        Skill.Get(Skill.ID);
        Assert.AreEqual('Updated Markdown skill', Skill.Title, 'Text edits must not overwrite parent metadata.');
        AssertContentEquals(Markdown + GetLineBreak() + 'Final instruction', BusinessSkillImpl.GetContent(Skill), 'The field must persist Markdown, not HTML.');
        AssertVersionCount(Skill.ID, 3);
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        AssertContentEquals(BusinessSkillImpl.GetContent(Skill), SkillCard.SkillContentEditor.SkillContent.Value(), 'Reopening must show the current content.');
        SkillCard.SkillContentEditor.SkillContent.SetValue(Markdown + GetLineBreak() + 'Final instruction');
        SkillCard.Close();
        AssertVersionCount(Skill.ID, 3);
    end;

    /// <summary>
    /// The native Markdown field rejects stale edits without replacing a concurrent revision.
    /// </summary>
    [Test]
    [HandlerFunctions('StaleMarkdownMessageHandler')]
    procedure MarkdownFieldRejectsStaleInstructions()
    var
        Skill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [SCENARIO] The native Markdown field rejects stale edits without replacing a concurrent revision.
        // [GIVEN] An open card whose instructions are subsequently changed by another writer.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateSkill('Concurrent Markdown', SecretStrSubstNo('# Original')));
        Commit();
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        BusinessSkillImpl.SetContent(Skill.ID, SecretStrSubstNo('# Concurrent'));
        Commit();

        // [WHEN] The stale editor attempts to save.
        asserterror SkillCard.SkillContentEditor.SkillContent.SetValue('# Stale');

        // [THEN] The concurrent content and its history remain intact.
        Assert.ExpectedError('changed by another user');
        SkillCard.Close();
        Skill.Get(Skill.ID);
        AssertContentEquals(SecretStrSubstNo('# Concurrent'), BusinessSkillImpl.GetContent(Skill), 'A stale Markdown field must not overwrite newer text.');
        AssertVersionCount(Skill.ID, 2);
    end;

    /// <summary>
    /// Instructions remain read-only on a viewed card and unavailable before a new skill is saved.
    /// </summary>
    [Test]
    procedure MarkdownFieldRespectsReadOnlyAndUnsavedCards()
    var
        Skill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [SCENARIO] Instructions remain read-only on a viewed card and unavailable before a new skill is saved.
        // [GIVEN] A saved skill with Markdown instructions.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateSkill('Read-only Markdown', SecretStrSubstNo('**Instructions**')));
        Commit();

        // [WHEN] Its card is viewed, then an empty new card is opened.
        SkillCard.OpenView();
        SkillCard.GoToRecord(Skill);
        // [THEN] The viewed instructions and the unsaved editor are not editable.
        SkillCard.SkillContentEditor.SkillContent.AssertEquals('**Instructions**');
        Assert.IsFalse(SkillCard.SkillContentEditor.SkillContent.Editable(), 'View mode must not permit Markdown editing.');
        SkillCard.Close();
        SkillCard.OpenNew();
        Assert.IsFalse(SkillCard.SkillContentEditor.SkillContent.Editable(), 'An unsaved skill must not permit instruction edits.');
        SkillCard.Close();
        AssertVersionCount(Skill.ID, 1);
    end;

    /// <summary>
    /// Markdown rendering limits do not reduce the skill content limit or bypass server-side validation.
    /// </summary>
    [Test]
    procedure MarkdownFieldEnforcesSkillContentLimit()
    var
        Skill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
        MaximumText: Text;
    begin
        // [SCENARIO] Markdown rendering limits do not reduce the skill content limit or bypass server-side validation.
        // [GIVEN] An active skill and source beyond the control's rich-rendering limit.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateSkill('Long Markdown', SecretStrSubstNo('Original')));
        MaximumText := PadStr('x', 100000, 'x');
        Commit();
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);

        // [WHEN] The field saves the supported maximum and rejects overlength and empty active text.
        SkillCard.SkillContentEditor.SkillContent.SetValue(MaximumText);
        Commit();
        asserterror SkillCard.SkillContentEditor.SkillContent.SetValue(MaximumText + 'x');
        // [THEN] Validation retains the last valid text and creates no rejected history entries.
        Assert.ExpectedError('100000 characters');
        asserterror SkillCard.SkillContentEditor.SkillContent.SetValue('');
        Assert.ExpectedError('An active skill needs a title and skill content.');
        SkillCard.Close();
        Skill.Get(Skill.ID);
        AssertContentEquals(MaximumText, BusinessSkillImpl.GetContent(Skill), 'Rejected field values must preserve the full supported source.');
        AssertVersionCount(Skill.ID, 2);
    end;

    /// <summary>
    /// History stays scoped to the selected skill when user filters change, and restoring it refreshes the live editor.
    /// </summary>
    [Test]
    [HandlerFunctions('RestoreMarkdownHistoryHandler')]
    procedure MarkdownHistoryPreviewAndRestore()
    var
        Skill: Record "Business Skill";
        OtherSkill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [SCENARIO] History stays scoped to the selected skill when user filters change, and restoring it refreshes the live editor.
        // [GIVEN] A skill with two Markdown instruction versions and another skill with its own history.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateSkill('Markdown history', SecretStrSubstNo('# Original')));
        BusinessSkillImpl.SetContent(Skill.ID, SecretStrSubstNo('**Latest**'));
        OtherSkill.Get(LibraryBusinessSkill.CreateSkill('Other history', SecretStrSubstNo('# Other skill')));
        Skill.Get(Skill.ID);
        Commit();
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);

        // [WHEN] User filters are widened and cleared before restoring the selected skill's older version.
        SkillCard.SkillContentEditor.ViewHistory.Invoke();

        // [THEN] The live field refreshes and restoration appends a new history entry.
        SkillCard.SkillContentEditor.SkillContent.AssertEquals('# Original');
        SkillCard.Close();
        Skill.Get(Skill.ID);
        AssertContentEquals(SecretStrSubstNo('# Original'), BusinessSkillImpl.GetContent(Skill), 'Restoring history must update the live Markdown field.');
        AssertVersionCount(Skill.ID, 3);
        OtherSkill.Get(OtherSkill.ID);
        AssertContentEquals(SecretStrSubstNo('# Other skill'), BusinessSkillImpl.GetContent(OtherSkill), 'Restoration must not change another skill.');
        AssertVersionCount(OtherSkill.ID, 1);
    end;

    [ModalPageHandler]
    procedure RestoreMarkdownHistoryHandler(var Versions: TestPage "Bus Skill Content Versions")
    begin
        Versions.Filter.SetFilter("Skill ID", '<>0');
        Versions.First();
        Versions.ContentPreview.SkillContent.AssertEquals('**Latest**');
        Assert.IsFalse(Versions.ContentPreview.SkillContent.Editable(), 'History must render Markdown read-only.');
        Versions.Filter.SetFilter("Skill ID", '');
        Versions.First();
        Versions.ContentPreview.SkillContent.AssertEquals('**Latest**');
        Versions.Last();
        Versions.ContentPreview.SkillContent.AssertEquals('# Original');
        Versions.SetAsCurrent.Invoke();
    end;

    [MessageHandler]
    procedure StaleMarkdownMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, 'changed by another user') > 0, 'Closing the rejected draft must report the concurrency conflict.');
    end;

    /// <summary>
    /// Copy opens editable content while the protected source stays read-only and unchanged.
    /// </summary>
    [Test]
    [HandlerFunctions('DeclineCopyActivation')]
    procedure CardCopiesProtectedSkillToEditableContent()
    var
        Source: Record "Business Skill";
        SkillCopy: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        SkillCard: TestPage "Business Skill Card";
        CopyCard: TestPage "Business Skill Card";
    begin
        // [SCENARIO] Copy opens editable content while the protected source stays read-only and unchanged.
        // [GIVEN] An active protected skill with a known version and owning app.
        Initialize();
        Source.Get(Builder.Initialize('CARD', 'Protected source', SecretStrSubstNo('Original')).SetContentVersion('2.4').SetActive(true).Create());
        Commit();
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Source);
        Assert.IsTrue(SkillCard.Title.Editable(), 'Read-only instructions must not disable title editing.');
        Assert.IsTrue(SkillCard.Description.Editable(), 'Read-only instructions must not disable description editing.');
        Assert.IsFalse(SkillCard.SkillContentEditor.SkillContent.Editable(), 'Protected instructions must not be editable.');
        SkillCard."Read-Only".AssertEquals(true);
        Assert.IsFalse(SkillCard."Read-Only".Editable(), 'Protection must not be unlocked from the card.');
        Assert.IsTrue(SkillCard.Activate.Enabled(), 'Protected skills must still allow activation.');
        Assert.IsTrue(SkillCard.Deactivate.Enabled(), 'Protected skills must still allow deactivation.');
        Assert.IsFalse(SkillCard.Export.Enabled(), 'An app-owned skill must not offer export.');
        SkillCard.Version.AssertEquals('2.4');
        Assert.IsFalse(SkillCard.Version.Editable(), 'App-owned versions must not be editable.');

        // [WHEN] Copy is invoked and the resulting manual copy is edited.
        CopyCard.Trap();
        SkillCard.CopyToEdit.Invoke();
        Assert.IsTrue(CopyCard.Title.Editable(), 'A copied title must be editable.');
        Assert.IsTrue(CopyCard.SkillContentEditor.SkillContent.Editable(), 'Copied instructions must be editable.');
        CopyCard."Read-Only".AssertEquals(false);
        Assert.IsTrue(CopyCard.Export.Enabled(), 'A manual copy must offer export.');
        CopyCard.Version.AssertEquals('v1.0');
        Assert.IsTrue(CopyCard.Version.Editable(), 'Manual copies must allow version edits.');
        CopyCard.Title.SetValue('Edited copy');
        CopyCard.SkillContentEditor.SkillContent.SetValue('Changed copy');
        CopyCard.Close();
        SkillCard.Close();

        // [THEN] Only the copy changes, and its first instruction edit advances its version.
        SkillCopy.FindLast();
        Assert.AreEqual('Edited copy', SkillCopy.Title, 'The copied title must persist.');
        Assert.AreEqual('v1.1', SkillCopy.Version, 'The first copy edit must advance its own initial version.');
        Source.Get(Source.ID);
        AssertContentEquals(SecretStrSubstNo('Original'), BusinessSkillImpl.GetContent(Source), 'Editing a copy must not change the source.');
        Assert.AreEqual('2.4', Source.Version, 'Editing a copy must not change the source version.');
    end;

    [ConfirmHandler]
    procedure DeclineCopyActivation(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(Question.Contains('activate it'), 'Only the inactive-copy activation prompt is expected.');
        Reply := false;
    end;

    /// <summary>
    /// Manual version edits persist through the card without creating instruction history.
    /// </summary>
    [Test]
    procedure ManualCardVersionEditPersistsWithoutContentHistory()
    var
        Skill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [SCENARIO] Manual version edits persist through the card without creating instruction history.
        // [GIVEN] Active manual content with one instruction history entry.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateSkill('Manual version', SecretStrSubstNo('Instructions')));
        BusSkillContentVersion.SetRange("Skill ID", Skill.ID);
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        Assert.IsTrue(SkillCard.Version.Editable(), 'Manual versions must be editable on the card.');

        // [WHEN] Only the version is changed.
        SkillCard.Version.SetValue('release-7');
        SkillCard.Close();

        // [THEN] The value persists independently of instructions and becomes the next edit baseline.
        Skill.Get(Skill.ID);
        Assert.AreEqual('release-7', Skill.Version, 'The optimistic card save must persist version-only changes.');
        AssertContentEquals(SecretStrSubstNo('Instructions'), BusinessSkillImpl.GetContent(Skill), 'A version edit must not change instructions.');
        Assert.AreEqual(1, BusSkillContentVersion.Count(), 'A version edit must not append instruction history.');
        BusSkillContentVersion.FindFirst();
        Assert.AreEqual('v1.0', BusSkillContentVersion."Content Version", 'Changing the current version must not rewrite the historical version.');
        BusinessSkillImpl.SetContent(Skill.ID, SecretStrSubstNo('Changed instructions'));
        Skill.Get(Skill.ID);
        Assert.AreEqual('release-8', Skill.Version, 'Instruction edits must advance the manually selected version.');
        BusSkillContentVersion.FindLast();
        Assert.AreEqual('release-8', BusSkillContentVersion."Content Version", 'History must capture the automatically advanced version.');
    end;

    /// <summary>
    /// Editable app-owned content gets its versions from the app and cannot edit them directly.
    /// </summary>
    [Test]
    procedure AppOwnedVersionsAreSuppliedByApp()
    var
        Skill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        Builder: Codeunit "Business Skill Builder";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [SCENARIO] Editable app-owned content gets its versions from the app and cannot edit them directly.
        // [GIVEN] App-owned content that permits instruction edits.
        Initialize();
        Skill.Get(Builder.Initialize('APP-VERSION', 'App version', SecretStrSubstNo('Original'))
            .SetContentLocked(false).SetActive(true).SetContentVersion('1.0').Create());
        BusSkillContentVersion.SetRange("Skill ID", Skill.ID);
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'App-owned creation must not record history.');
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        Assert.IsFalse(SkillCard.Version.Editable(), 'Editable app content must still have a protected version field.');
        Assert.IsFalse(SkillCard.SkillContentEditor.SkillContent.Editable(), 'The native editor cannot supply an app-owned instruction version.');
        SkillCard.Close();
        Commit();

        // [WHEN] Directly overriding the app-owned version through management.
        Skill.Get(Skill.ID);
        Skill.Version := 'manual-release';
        asserterror BusinessSkillImpl.UpdateSkillRecord(Skill.ID, Skill, BusinessSkillImpl.GetContent(Skill));

        // [THEN] Direct edits fail, while text changes with a version from the app persist.
        Assert.ExpectedError('Only manually owned skills can change the version directly.');
        Skill.Get(Skill.ID);
        Assert.AreEqual('1.0', Skill.Version, 'Rejected overrides must leave the app version unchanged.');
        BusinessSkillImpl.SetContent(Skill.ID, SecretStrSubstNo('Updated'), '1.1');
        Skill.Get(Skill.ID);
        Assert.AreEqual('1.1', Skill.Version, 'The version supplied by the app must persist.');
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'App-owned version updates must not record history.');
    end;

    local procedure Initialize()
    begin
        LibraryBusinessSkill.DeleteAll();
        // Expected errors must not roll back the cleanup to a previous test's fixture.
        Commit();
    end;

    local procedure AssertContentEquals(Expected: SecretText; Actual: SecretText; Message: Text)
    begin
        Assert.IsTrue(BusinessSkillImpl.ContentEquals(Expected, Actual), Message);
    end;

    local procedure AssertVersionCount(SkillId: BigInteger; ExpectedCount: Integer)
    var
        Version: Record "Bus Skill Content Version";
    begin
        Version.SetRange("Skill ID", SkillId);
        Assert.AreEqual(ExpectedCount, Version.Count(), 'Unexpected number of canonical content versions.');
    end;

    local procedure GetLineBreak(): Text
    var
        Builder: TextBuilder;
    begin
        Builder.AppendLine('');
        exit(Builder.ToText());
    end;

    var
        Assert: Codeunit "Library Assert";
        LibraryBusinessSkill: Codeunit "Library - Business Skill";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
}
