// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.AI.BusinessSkills;

using System.AI.BusinessSkills;
using System.TestLibraries.AI.BusinessSkills;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>
/// Exercises skill lifecycle and availability, instruction history, and portable skill exchange.
/// Verifies that temporary buffers retain canonical metadata and complete instruction text where requested.
/// </summary>
codeunit 130050 "Business Skill Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;
    EventSubscriberInstance = Manual;

    /// <summary>
    /// Verifies reading empty or single-line BLOB text does not add a leading line break.
    /// </summary>
    [Test]
    procedure BlobTextReadDoesNotPrependLineBreak()
    begin
        // [GIVEN] Empty and single-line BLOB text.
        // [WHEN] Text is read back from the BLOB.
        // [THEN] No leading line break is introduced.
        AssertBlobTextRead('', '');
        AssertBlobTextRead('Single line', 'Single line');
    end;

    /// <summary>
    /// Verifies BLOB text reading retains separators between the second and later lines.
    /// </summary>
    [Test]
    procedure BlobTextReadSeparatesSecondAndSubsequentLines()
    var
        LineBreak: Text;
    begin
        // [GIVEN] A BLOB containing three nonempty lines.
        LineBreak := GetLineBreak();
        // [WHEN] The BLOB text is read by the assertion helper.
        // [THEN] Every line after the first retains its separator.
        AssertBlobTextRead('First' + LineBreak + 'Second' + LineBreak + 'Third',
            'First' + LineBreak + 'Second' + LineBreak + 'Third');
    end;

    /// <summary>
    /// Verifies BLOB text reading preserves leading and internal blank lines.
    /// </summary>
    [Test]
    procedure BlobTextReadPreservesLeadingAndInternalBlankLines()
    var
        LineBreak: Text;
    begin
        // [GIVEN] Text with leading and internal empty lines.
        LineBreak := GetLineBreak();
        // [WHEN] The text round-trips through the assertion helper.
        // [THEN] Blank lines remain in their original positions.
        AssertBlobTextRead(LineBreak + LineBreak + 'First' + LineBreak + LineBreak + 'Second',
            LineBreak + LineBreak + 'First' + LineBreak + LineBreak + 'Second');
    end;

    /// <summary>
    /// Verifies LF-separated BLOB text is rebuilt with the expected line separators and spaces.
    /// </summary>
    [Test]
    procedure BlobTextReadRebuildsLfSeparators()
    var
        LF: Char;
        LineBreak: Text;
    begin
        // [GIVEN] BLOB text containing LF separators and trailing spaces.
        LF := 10;
        LineBreak := GetLineBreak();
        // [WHEN] The LF-separated text is read by the assertion helper.
        // [THEN] Separators are rebuilt using the expected line break.
        AssertBlobTextRead(Format(LF) + 'First' + Format(LF) + Format(LF) + 'Second  ',
            LineBreak + 'First' + LineBreak + LineBreak + 'Second  ');
    end;

    /// <summary>
    /// Verifies reading BLOB text does not restore its final line terminator.
    /// </summary>
    [Test]
    procedure BlobTextReadDoesNotRestoreFinalTerminator()
    var
        LineBreak: Text;
    begin
        // [GIVEN] Text ending in one or two line terminators.
        LineBreak := GetLineBreak();
        // [WHEN] The terminated text is read by the assertion helper.
        // [THEN] The final terminator is not restored.
        AssertBlobTextRead('First' + LineBreak, 'First');
        AssertBlobTextRead('First' + LineBreak + LineBreak, 'First' + LineBreak);
    end;

    /// <summary>
    /// Verifies bare carriage returns follow the text reader's removal behavior.
    /// </summary>
    [Test]
    procedure BlobTextReadUsesReadTextCarriageReturnBehavior()
    var
        CR: Char;
    begin
        // [GIVEN] Text containing bare carriage returns.
        CR := 13;
        // [WHEN] The text is read by the BLOB assertion helper.
        // [THEN] Bare carriage returns follow ReadText's removal behavior.
        AssertBlobTextRead(Format(CR) + 'First' + Format(CR) + 'Second', 'FirstSecond');
    end;

    /// <summary>
    /// Verifies management creation initializes canonical identity, the generated manual skill ID, audit fields, version, and Active status.
    /// </summary>
    [Test]
    procedure CreateSkillSetsActiveIdentityAndAudit()
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
        NextId: BigInteger;
    begin
        // [GIVEN] A clean skill catalog.
        Initialize();
        // [WHEN] Skills are created by management.
        SkillId := Management.CreateSkill('Net 30 Policy', 'All invoices net 30.');
        NextId := Management.CreateSkill('Another skill', 'Body');
        Skill.Get(SkillId);
        // [THEN] Identity, audit fields, version, and status are initialized.
        Assert.IsTrue((SkillId > 0) and (NextId > SkillId), 'Skills must have positive, increasing canonical IDs.');
        Assert.IsFalse(IsNullGuid(Skill.SystemId), 'Skills must have a system identity.');
        Assert.AreEqual('Net 30 Policy', Skill.Title, 'The title must persist.');
        Assert.AreEqual(Skill.Status::Active, Skill.Status, 'New skills must be Active.');
        Assert.AreEqual(UserSecurityId(), Skill.SystemCreatedBy, 'The creating user must be recorded.');
        Assert.AreEqual(UserSecurityId(), Skill.SystemModifiedBy, 'The modifying user must be recorded.');
        Assert.IsTrue(Skill.Manual, 'Management must create an explicitly manual skill.');
        Assert.AreEqual(Format(Skill.ID, 0, '<Integer,20><Filler Character,0>'), Skill."Skill ID", 'Manual skill IDs must equal the numeric record ID padded to 20 digits.');
        Assert.AreEqual('v1.0', Skill.Version, 'A new manual skill must start at version v1.0.');
        AssertVersionCount(SkillId, 1);
    end;

    /// <summary>
    /// Verifies inserting a page-entered record preserves an explicitly inactive skill, its instructions, and its first text version.
    /// </summary>
    [Test]
    procedure InsertSkillRecordCanCreateInactiveSkill()
    var
        Skill: Record "Business Skill";
    begin
        // [GIVEN] A skill record explicitly marked inactive.
        Initialize();
        Skill.Title := 'Direct inactive insert';
        SkillText.SetSkillText(Skill, 'Body');
        Skill.Status := Skill.Status::Inactive;
        // [WHEN] It is inserted through management.
        Management.InsertSkillRecord(Skill);
        // [THEN] The inactive state, its text, and its first text version persist.
        Assert.AreEqual(Skill.Status::Inactive, Skill.Status, 'Native authoring may save an inactive skill before activation.');
        Assert.AreEqual(Format(Skill.ID, 0, '<Integer,20><Filler Character,0>'), Skill."Skill ID", 'Insertion must return the final manual identifier without rereading.');
        Assert.IsTrue(Skill.Get(Skill.ID), 'The inactive skill must persist.');
        Assert.AreEqual('Body', SkillText.GetSkillText(Skill), 'The instructions must persist.');
        AssertVersionCount(Skill.ID, 1);
    end;

    /// <summary>
    /// Verifies activating and deactivating a skill controls its inclusion in discovery.
    /// </summary>
    [Test]
    procedure LifecycleActiveInactiveControlsDiscovery()
    var
        Skill: Record "Business Skill";
        Results: JsonArray;
        SkillId: BigInteger;
    begin
        // [GIVEN] A created skill.
        Initialize();
        SkillId := Management.CreateSkill('Lifecycle', 'Body');
        Results := Management.GetAllActiveSkills();
        Assert.AreEqual(1, Results.Count(), 'New active applicable skills must be discoverable.');
        // [WHEN] Its active status changes through lifecycle operations.
        Management.DeactivateSkill(SkillId);
        Skill.Get(SkillId);
        // [THEN] Discovery includes it only while active.
        Assert.AreEqual(Skill.Status::Inactive, Skill.Status, 'Deactivation must set Inactive.');
        Results := Management.GetAllActiveSkills();
        Assert.AreEqual(0, Results.Count(), 'Inactive skills must not be discoverable.');
        Management.ActivateSkill(SkillId);
        Skill.Get(SkillId);
        Assert.AreEqual(Skill.Status::Active, Skill.Status, 'Inactive content can be activated again.');
        AssertVersionCount(SkillId, 1);
    end;

    /// <summary>
    /// Verifies an inactive skill missing a title or nonblank instructions cannot be activated.
    /// </summary>
    [Test]
    procedure IncompleteInactiveSkillCannotBeActivated()
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
    begin
        // [GIVEN] An inactive skill made incomplete.
        Initialize();
        SkillId := Management.CreateSkill('Title', 'Body');
        Management.DeactivateSkill(SkillId);
        Skill.Get(SkillId);
        Skill.Title := '';
        Skill.Modify(true);
        Commit();
        // [WHEN] Activation is attempted.
        asserterror Management.ActivateSkill(SkillId);
        // [THEN] Validation rejects the incomplete skill.
        Assert.ExpectedError('needs a title and skill text');
        Management.UpdateSkill(SkillId, 'Title', '   ');
        asserterror Management.ActivateSkill(SkillId);
        Assert.ExpectedError('needs a title and skill text');
    end;

    /// <summary>
    /// Verifies an active skill cannot be saved with empty instructions or lose its existing text.
    /// </summary>
    [Test]
    procedure ActiveSkillCannotBeSavedWithEmptyText()
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
    begin
        // [GIVEN] An active skill with nonempty instructions.
        Initialize();
        SkillId := Management.CreateSkill('Active', 'Keep body');
        Management.ActivateSkill(SkillId);
        Commit();
        // [WHEN] Its text is cleared and saved.
        asserterror Management.SetSkillText(SkillId, '');
        // [THEN] Validation prevents an active skill with empty text.
        Assert.ExpectedError('needs a title and skill text');
        Skill.Get(SkillId);
        Assert.AreEqual('Keep body', SkillText.GetSkillText(Skill), 'Rejected edits must leave the active content intact.');
        AssertVersionCount(SkillId, 1);
    end;

    /// <summary>
    /// Verifies ordinary record filters cannot widen the mandatory active and applicable discovery result set.
    /// </summary>
    [Test]
    procedure DiscoveryFilterCannotBeWidenedByStandardFilters()
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
    begin
        // [GIVEN] Active and inactive skills with standard record filters.
        Initialize();
        SkillId := Management.CreateSkill('Active skill', 'Body');
        Management.ActivateSkill(SkillId);
        SkillId := Management.CreateSkill('Inactive skill', 'Body');
        Management.DeactivateSkill(SkillId);

        Skill.FilterGroup(10);
        Management.SetAvailableSKillsFilter(Skill);
        Skill.FilterGroup(0);
        // [WHEN] The discovery eligibility filter is applied.
        Skill.SetRange(Status, Skill.Status::Inactive);
        // [THEN] Caller filters cannot broaden the eligible result set.
        Assert.IsTrue(Skill.IsEmpty(), 'A standard status filter must not widen the mandatory Active restriction.');
        Skill.SetRange(Status);
        Assert.AreEqual(1, Skill.Count(), 'Clearing the standard filter must retain the discovery restrictions.');
    end;

    /// <summary>
    /// Verifies skill JSON exposes canonical identity, text, and status.
    /// </summary>
    [Test]
    procedure JsonUsesCanonicalIdentity()
    var
        Result: JsonObject;
        Token: JsonToken;
        SkillId: BigInteger;
    begin
        // [GIVEN] An active canonical skill.
        Initialize();
        SkillId := Management.CreateSkill('Specific Skill', GetMultilineText());
        Management.ActivateSkill(SkillId);
        // [WHEN] The skill is serialized to JSON.
        Result := Management.GetSkillById(SkillId);
        Result.Get('id', Token);
        // [THEN] Canonical identity is represented.
        Assert.AreEqual(SkillId, Token.AsValue().AsBigInteger(), 'JSON must retain canonical identity.');
        Result.Get('title', Token);
        Assert.AreEqual('Specific Skill', Token.AsValue().AsText(), 'JSON must preserve the title.');
        Result.Get('skillText', Token);
        Assert.AreEqual(GetMultilineText(), Token.AsValue().AsText(), 'JSON must preserve full multiline text.');
        Result.Get('status', Token);
        Assert.AreEqual('Active', Token.AsValue().AsText(), 'JSON must expose the retained lifecycle vocabulary.');
        Assert.IsFalse(Result.Contains('companyNames'), 'Skills are tenant-wide, so JSON has no company selections.');
        AssertDiscoveryTimestamp(Result);
        Assert.IsTrue(Result.Contains('systemId'), 'JSON must expose the system identity.');
    end;

    /// <summary>
    /// Verifies search matches skill titles and descriptions but not instruction text.
    /// </summary>
    [Test]
    procedure SearchMatchesOnlyTitleAndDescription()
    var
        Skill: Record "Business Skill";
        SkillJson: JsonObject;
        Token: JsonToken;
        Results: JsonArray;
        SkillId: BigInteger;
    begin
        // [GIVEN] A skill with distinct title, description, and body text.
        Initialize();
        SkillId := Management.CreateSkill('Payment policy', GetMultilineText());
        Skill.Get(SkillId);
        Skill.Description := 'Invoice approval guidance';
        Management.UpdateSkillRecord(Skill.ID, Skill, GetMultilineText());
        Management.ActivateSkill(SkillId);
        // [WHEN] Skill search queries each kind of text.
        Results := Management.SearchSkills('payment');
        // [THEN] Only title and skill description participate in matching.
        Assert.AreEqual(1, Results.Count(), 'Search must match titles without case sensitivity.');
        Results := Management.SearchSkills('APPROVAL');
        Assert.AreEqual(1, Results.Count(), 'Descriptions are matched without case sensitivity.');
        SkillJson := Results.GetObject(0);
        AssertDiscoveryTimestamp(SkillJson);
        SkillJson.Get('description', Token);
        Assert.AreEqual('Invoice approval guidance', Token.AsValue().AsText(), 'Discovery exposes the persisted description.');
        SkillJson.Get('skillText', Token);
        Assert.AreEqual(GetMultilineText(), Token.AsValue().AsText(), 'Selected skills still return complete instructions.');
        Results := Management.SearchSkills('Second line');
        Assert.AreEqual(0, Results.Count(), 'Body-only matches must not select skills.');
    end;

    /// <summary>
    /// Verifies search treats filter metacharacters as literal title or description text.
    /// </summary>
    [Test]
    procedure SearchTreatsFilterMetacharactersAsLiteralText()
    var
        Results: JsonArray;
        SkillId: BigInteger;
    begin
        // [GIVEN] Skill metadata containing search-filter metacharacters.
        Initialize();
        SkillId := Management.CreateSkill('Literal A|B filter', 'Use * as a literal', 'Instructions are not searched');
        Management.ActivateSkill(SkillId);
        Management.ActivateSkill(Management.CreateSkill('Other', 'Unrelated'));
        // [WHEN] Those characters are searched as text.
        Results := Management.SearchSkills('A|B');
        // [THEN] Matching is literal rather than interpreted as a filter.
        Assert.AreEqual(1, Results.Count(), 'Filter metacharacters must not broaden title search.');
        Results := Management.SearchSkills('*');
        Assert.AreEqual(1, Results.Count(), 'Asterisk must match literal content, not every skill.');
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
        Assert.AreEqual('', SkillText.GetSkillText(Skill), 'Description editing does not invent instructions.');
        Commit();
        asserterror Management.ActivateSkill(Skill.ID);
        Assert.ExpectedError('title and skill text');
        Management.SetSkillText(Skill.ID, 'Body');
        Management.ActivateSkill(Skill.ID);
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
        // [GIVEN] A complete inactive skill opened on its card.
        Initialize();
        Skill.Get(Management.CreateSkill('Activate on close', 'Instructions'));
        Management.DeactivateSkill(Skill.ID);
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
        Assert.AreEqual('Instructions', SkillText.GetSkillText(Skill), 'Closing preserves the instructions.');
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
        // [GIVEN] A new skill card without instruction text.
        Initialize();
        SkillCard.OpenNew();
        SkillCard.Title.SetValue('Incomplete on close');
        Commit();
        // [WHEN] Activation is requested on close.
        asserterror SkillCard.Close();
        // [THEN] The incomplete skill cannot be activated.
        Assert.ExpectedError('title and skill text');
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
        // [GIVEN] A read-only inactive skill and a blank new card.
        Initialize();
        Skill.Get(Management.CreateSkill('Read-only inactive', 'Instructions'));
        Management.DeactivateSkill(Skill.ID);
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
        // [GIVEN] Skills in different lifecycle states.
        Initialize();
        ActiveSkillId := Management.CreateSkill('Active skill', 'Body');
        InactiveSkillId := Management.CreateSkill('Inactive skill', 'Body');
        Management.DeactivateSkill(InactiveSkillId);
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
        // [GIVEN] A skill with persisted instruction text.
        Initialize();
        SkillId := Management.CreateSkill('Lifecycle skill', 'Body');
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
        Assert.AreEqual('Body', SkillText.GetSkillText(Skill), 'Lifecycle actions must preserve the canonical instructions.');
        Assert.AreEqual(Skill.Status::Active, Skill.Status, 'Activation persists after the card closes.');
    end;

    /// <summary>
    /// Verifies description updates preserve text history, advance revisions, and reject stale records.
    /// </summary>
    [Test]
    procedure DescriptionUpdatesPreserveHistoryAndDetectStaleEdits()
    var
        Original: Record "Business Skill";
        Skill: Record "Business Skill";
        SkillId: BigInteger;
        Results: JsonArray;
    begin
        // [GIVEN] A skill with instruction history and a searchable description.
        Initialize();
        SkillId := Management.CreateSkill('Existing title', 'Body');
        Skill.Get(SkillId);
        Assert.AreEqual('', Skill.Description, 'Description is optional for existing authoring paths.');
        Results := Management.SearchSkills('Existing title');
        Assert.AreEqual(1, Results.Count(), 'Skills without descriptions remain discoverable by title.');
        Original := Skill;
        Skill.Description := CopyStr(PadStr('Description ', 2048, 'x'), 1, 2048);
        // [WHEN] Its description changes and an older record is edited.
        Management.UpdateSkillRecord(SkillId, Skill, 'Body');
        Commit();
        Skill.Get(SkillId);
        // [THEN] History is preserved and stale edits are rejected.
        Assert.AreEqual(2048, StrLen(Skill.Description), 'The entire supported description is persisted.');
        Assert.AreNotEqual(Original.SystemRowVersion, Skill.SystemRowVersion, 'Description changes advance the canonical revision.');
        AssertVersionCount(SkillId, 1);
        asserterror Management.UpdateSkillRecord(SkillId, Original, 'Stale body');
        Assert.ExpectedError('changed by another user');
        Original := Skill;
        Management.UpdateSkillRecord(SkillId, Skill, 'Body');
        Skill.Get(SkillId);
        Assert.AreEqual(Original.SystemRowVersion, Skill.SystemRowVersion, 'Unchanged metadata saves remain no-ops.');
        Management.SetSkillText(SkillId, 'New body');
        Skill.Get(SkillId);
        Assert.AreEqual(Original.Description, Skill.Description, 'Body-only operations preserve descriptions.');
        Skill.Description := '';
        Management.UpdateSkillRecord(SkillId, Skill, 'New body');
        Skill.Get(SkillId);
        Assert.AreEqual('', Skill.Description, 'An explicit metadata edit can clear the description.');
        AssertVersionCount(SkillId, 2);
    end;

    /// <summary>
    /// Verifies multiline Unicode text round-trips through canonical skill content and its history.
    /// </summary>
    [Test]
    procedure MultilineUnicodeTextRoundTripsThroughSkillAndHistory()
    var
        Skill: Record "Business Skill";
        Version: Record "Business Skill Text Version";
        SkillId: BigInteger;
        Value: Text;
    begin
        // [GIVEN] Multiline Unicode instruction text.
        Initialize();
        Value := GetMultilineText();
        // [WHEN] A skill and its history persist and retrieve the text.
        SkillId := Management.CreateSkill('Unicode', Value);
        Skill.Get(SkillId);
        // [THEN] All characters and line breaks round-trip.
        Assert.AreEqual(Value, SkillText.GetSkillText(Skill), 'The canonical BLOB must preserve line endings and Unicode.');
        Version.SetRange("Skill ID", SkillId);
        Version.FindFirst();
        Assert.AreEqual(Value, Version.GetText(), 'History must preserve exactly the same text.');
        Assert.AreEqual(Value, History.GetSkillText(SkillId), 'The text reader must return canonical content.');
    end;

    /// <summary>
    /// Verifies a skill accepts and returns the full 100,000-character instruction limit.
    /// </summary>
    [Test]
    procedure MaximumLengthTextIsAccepted()
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
        Value: Text;
    begin
        // [GIVEN] A 100000-character instruction body.
        Initialize();
        Value := PadStr('x', 100000, 'x');
        // [WHEN] It is saved to a skill.
        SkillId := Management.CreateSkill('Maximum', Value);
        Skill.Get(SkillId);
        // [THEN] The full supported length is retained.
        Assert.AreEqual(Value, SkillText.GetSkillText(Skill), 'Exactly 100000 characters must round-trip.');
    end;

    /// <summary>
    /// Verifies text exceeding the limit after line-separator expansion is rejected without insertion.
    /// </summary>
    [Test]
    procedure ExpandedLineSeparatorsCannotExceedTextLimit()
    var
        Skill: Record "Business Skill";
        LF: Char;
        Value: Text;
    begin
        // [GIVEN] Input whose normalized line separators exceed the text limit.
        Initialize();
        LF := 10;
        Value := PadStr('First' + Format(LF) + 'Second', 100000, 'x');
        Commit();
        // [WHEN] The text is saved.
        asserterror Management.CreateSkill('Expanded separators', Value);
        // [THEN] The expanded body is rejected.
        Assert.ExpectedError('100000 characters');
        Assert.IsTrue(Skill.IsEmpty(), 'An overlength reconstructed body must be rejected without inserting a skill.');
    end;

    /// <summary>
    /// Verifies overlength skill creation and updates fail without inserting or changing persisted text.
    /// </summary>
    [Test]
    procedure OversizedCreateAndUpdateAreRejectedWithoutChanges()
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
        Value: Text;
    begin
        // [GIVEN] A body exceeding the maximum supported length.
        Initialize();
        Value := PadStr('x', 100001, 'x');
        Commit();
        // [WHEN] Skill creation or update uses that body.
        asserterror Management.CreateSkill('Too long', Value);
        // [THEN] Validation rejects it without altering persisted content.
        Assert.ExpectedError('100000 characters');
        Assert.IsTrue(Skill.IsEmpty(), 'Rejected creation must not insert a skill.');
        SkillId := Management.CreateSkill('Keep', 'Original');
        Commit();
        asserterror Management.SetSkillText(SkillId, Value);
        Assert.ExpectedError('100000 characters');
        Skill.Get(SkillId);
        Assert.AreEqual('Original', SkillText.GetSkillText(Skill), 'Rejected updates must preserve the prior text.');
        AssertVersionCount(SkillId, 1);
    end;

    /// <summary>
    /// Verifies shorter and empty inactive text replaces prior BLOB content without stale data.
    /// </summary>
    [Test]
    procedure ShorterAndEmptyInactiveTextDoNotLeaveStaleData()
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
    begin
        // [GIVEN] A skill with a long instruction body.
        Initialize();
        SkillId := Management.CreateSkill('Long', PadStr('x', 5000, 'x'));
        // [WHEN] Its body becomes shorter and then empty while inactive.
        Management.UpdateSkill(SkillId, 'Short', 'new');
        Skill.Get(SkillId);
        // [THEN] No stale text remains in the skill or history.
        Assert.AreEqual('Short', Skill.Title, 'Title updates must persist.');
        Assert.AreEqual('new', SkillText.GetSkillText(Skill), 'Shorter text must replace the full previous BLOB.');
        Management.DeactivateSkill(SkillId);
        Management.SetSkillText(SkillId, '');
        Skill.Get(SkillId);
        Assert.AreEqual('', SkillText.GetSkillText(Skill), 'An Inactive skill may explicitly clear its text.');
        AssertVersionCount(SkillId, 3);
    end;

    /// <summary>
    /// Verifies no-op skill saves preserve the current revision and do not append text history.
    /// </summary>
    [Test]
    procedure UnchangedSavePreservesRevisionAndHistory()
    var
        Original: Record "Business Skill";
        Skill: Record "Business Skill";
        SkillId: BigInteger;
    begin
        // [GIVEN] An existing skill and its revision history.
        Initialize();
        SkillId := Management.CreateSkill('Unchanged', 'Body');
        Original.Get(SkillId);
        // [WHEN] The same metadata and text are saved again.
        Management.UpdateSkill(SkillId, 'Unchanged', 'Body');
        Skill.Get(SkillId);
        // [THEN] Neither the revision nor history changes.
        Assert.AreEqual(Original.SystemRowVersion, Skill.SystemRowVersion, 'A no-op save must not create a false concurrency conflict.');
        AssertVersionCount(SkillId, 1);
        Management.UpdateSkill(SkillId, 'Title only', 'Body');
        AssertVersionCount(SkillId, 1);
    end;

    /// <summary>
    /// Verifies stale text and record updates are rejected without overwriting the latest revision.
    /// </summary>
    [Test]
    procedure StaleTextAndRecordUpdatesAreRejected()
    var
        Original: Record "Business Skill";
        Skill: Record "Business Skill";
        SkillId: BigInteger;
    begin
        // [GIVEN] A skill record read before a concurrent edit.
        Initialize();
        SkillId := Management.CreateSkill('Original', 'Original text');
        Original.Get(SkillId);
        Management.UpdateSkill(SkillId, 'Concurrent title', 'Concurrent text');
        Commit();
        // [WHEN] Stale text or record updates are attempted.
        asserterror Management.SetSkillText(SkillId, 'Stale text', Original.SystemId, Original.SystemRowVersion);
        // [THEN] Concurrency checks reject them.
        Assert.ExpectedError('changed by another user');
        Original.Title := 'Stale title';
        asserterror Management.UpdateSkillRecord(SkillId, Original, 'Stale record text');
        Assert.ExpectedError('changed by another user');
        Skill.Get(SkillId);
        Assert.AreEqual('Concurrent title', Skill.Title, 'Stale edits must not overwrite the latest title.');
        Assert.AreEqual('Concurrent text', SkillText.GetSkillText(Skill), 'Stale edits must not overwrite the latest text.');
        AssertVersionCount(SkillId, 2);
    end;

    /// <summary>
    /// Verifies updates with the current revision succeed while a mismatched system identity is rejected.
    /// </summary>
    [Test]
    procedure CurrentRevisionUpdateSucceedsButWrongIdentityFails()
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
    begin
        // [GIVEN] A current skill revision and a mismatched record identity.
        Initialize();
        SkillId := Management.CreateSkill('Original', 'Original text');
        Skill.Get(SkillId);
        Commit();
        // [WHEN] Record updates are attempted with each.
        asserterror Management.SetSkillText(SkillId, 'Wrong identity', CreateGuid(), Skill.SystemRowVersion);
        // [THEN] The current revision succeeds and the wrong identity fails.
        Assert.ExpectedError('changed by another user');
        Skill.Title := 'Updated title';
        Management.UpdateSkillRecord(SkillId, Skill, 'Updated text');
        Skill.Get(SkillId);
        Assert.AreEqual('Updated title', Skill.Title, 'A current record revision must be accepted.');
        Assert.AreEqual('Updated text', SkillText.GetSkillText(Skill), 'A current record revision must update text.');
        AssertVersionCount(SkillId, 2);
    end;

    /// <summary>
    /// Verifies restoring an earlier text version appends a new latest version instead of changing history.
    /// </summary>
    [Test]
    procedure RestoringHistoryCreatesNewLatestVersion()
    var
        Version: Record "Business Skill Text Version";
        Skill: Record "Business Skill";
        SkillId: BigInteger;
        FirstEntryNo: Integer;
    begin
        // [GIVEN] A skill with successive instruction versions.
        Initialize();
        SkillId := Management.CreateSkill('History', 'First');
        Version.SetRange("Skill ID", SkillId);
        Version.FindFirst();
        FirstEntryNo := Version."Entry No.";
        History.SetSkillText(SkillId, 'Second');
        // [WHEN] An earlier version is restored.
        History.RestoreVersion(FirstEntryNo);
        Skill.Get(SkillId);
        // [THEN] A new latest version records the restored text.
        Assert.AreEqual('First', SkillText.GetSkillText(Skill), 'Restore must update canonical text.');
        Assert.AreEqual('v1.2', Skill.Version, 'Restoring different text must advance the current skill version.');
        AssertVersionCount(SkillId, 3);
        Version.FindLast();
        Assert.AreEqual('First', Version.GetText(), 'Restore must append a new latest version.');
        Assert.IsTrue(Version."Entry No." <> FirstEntryNo, 'Restore must not mutate the historical entry.');
    end;

    /// <summary>
    /// Verifies historical text versions are immutable and the latest version cannot be deleted.
    /// </summary>
    [Test]
    procedure HistoryIsImmutableAndLatestCannotBeDeleted()
    var
        Version: Record "Business Skill Text Version";
        SkillId: BigInteger;
    begin
        // [GIVEN] A skill with multiple historical text versions.
        Initialize();
        SkillId := Management.CreateSkill('History', 'First');
        Management.SetSkillText(SkillId, 'Second');
        Version.SetRange("Skill ID", SkillId);
        Version.FindFirst();
        Commit();
#pragma warning disable AA0214 // Even a no-op modify must reject immutable history.
        // [WHEN] Old history is changed or the latest version is deleted.
        asserterror Version.Modify(true);
#pragma warning restore AA0214
        // [THEN] Version immutability and latest-version protection apply.
        Assert.ExpectedError('immutable');
        History.DeleteVersion(Version);
        AssertVersionCount(SkillId, 1);
        Version.FindLast();
        Commit();
        asserterror History.DeleteVersion(Version);
        Assert.ExpectedError('latest');
        AssertVersionCount(SkillId, 1);
    end;

    /// <summary>
    /// Verifies deleting an inactive skill removes its text history.
    /// </summary>
    [Test]
    procedure DeletingSkillRemovesHistory()
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
    begin
        // [GIVEN] An inactive skill with history records.
        Initialize();
        SkillId := Management.CreateSkill('Delete', 'Body');
        Management.DeactivateSkill(SkillId);
        // [WHEN] The skill is deleted.
        Management.DeleteSkill(SkillId);
        // [THEN] The skill and its history are removed.
        Assert.IsFalse(Skill.Get(SkillId), 'The canonical skill must be removed.');
        AssertVersionCount(SkillId, 0);
    end;

    /// <summary>
    /// Filtered bulk deletion without triggers removes only the selected skills and their history.
    /// </summary>
    [Test]
    procedure FilteredDeleteAllRemovesOnlySelectedHistory()
    var
        Skill: Record "Business Skill";
        FirstId: BigInteger;
        SecondId: BigInteger;
        RetainedId: BigInteger;
    begin
        // [GIVEN] Three skills, including multiple versions for a selected and a retained skill.
        Initialize();
        FirstId := Management.CreateSkill('First selected', 'First');
        SecondId := Management.CreateSkill('Second selected', 'Second');
        RetainedId := Management.CreateSkill('Retained', 'Original');
        Management.SetSkillText(FirstId, 'Updated first');
        Management.SetSkillText(RetainedId, 'Updated retained');

        // [WHEN] Two skills are deleted through the filtered bulk path without table triggers.
        Skill.SetFilter(ID, '%1|%2', FirstId, SecondId);
        Skill.DeleteAll(false);

        // [THEN] Their history is removed without touching the other skill or its versions.
        Skill.Reset();
        Assert.AreEqual(1, Skill.Count(), 'Only the selected skills must be deleted.');
        Skill.Get(RetainedId);
        Assert.AreEqual('Updated retained', SkillText.GetSkillText(Skill), 'Unselected instructions must remain unchanged.');
        AssertVersionCount(FirstId, 0);
        AssertVersionCount(SecondId, 0);
        AssertVersionCount(RetainedId, 2);
    end;

    /// <summary>
    /// A failed history cleanup rolls back the persisted skill deletion.
    /// </summary>
    [Test]
    procedure FailedHistoryCleanupRollsBackSkillDeletion()
    var
        Skill: Record "Business Skill";
        CleanupFailure: Codeunit "Business Skill Test";
        SkillId: BigInteger;
        SystemId: Guid;
    begin
        // [GIVEN] A committed skill with two history entries and a failing history delete subscriber.
        Initialize();
        SkillId := Management.CreateSkill('Cleanup failure', 'Original');
        Management.SetSkillText(SkillId, 'Current');
        Skill.Get(SkillId);
        SystemId := Skill.SystemId;
        Commit();
        BindSubscription(CleanupFailure);

        // [WHEN] Deletion reaches history cleanup after removing the stored skill.
        asserterror Skill.Delete(false);
        UnbindSubscription(CleanupFailure);

        // [THEN] The failure propagates and both the skill and its history remain.
        Assert.ExpectedError(CleanupFailureErr);
        Skill.Get(SkillId);
        Assert.AreEqual(SystemId, Skill.SystemId, 'Cleanup failure must restore the same skill.');
        Assert.AreEqual('Current', SkillText.GetSkillText(Skill), 'Cleanup failure must preserve instructions.');
        AssertVersionCount(SkillId, 2);
    end;

    /// <summary>
    /// A later cleanup failure rolls back earlier skill and history deletions in the bulk operation.
    /// </summary>
    [Test]
    procedure LaterHistoryCleanupFailureRollsBackBulkDeletion()
    var
        Skill: Record "Business Skill";
        CleanupFailure: Codeunit "Business Skill Test";
        FirstId: BigInteger;
        SecondId: BigInteger;
        RetainedId: BigInteger;
        FirstSystemId: Guid;
        SecondSystemId: Guid;
    begin
        // [GIVEN] Two selected skills with history and an unselected skill.
        Initialize();
        FirstId := Management.CreateSkill('First selected', 'Original first');
        Management.SetSkillText(FirstId, 'Updated first');
        SecondId := Management.CreateSkill('Second selected', 'Original second');
        Management.SetSkillText(SecondId, 'Updated second');
        RetainedId := Management.CreateSkill('Retained', 'Retained instructions');
        Skill.Get(FirstId);
        FirstSystemId := Skill.SystemId;
        Skill.Get(SecondId);
        SecondSystemId := Skill.SystemId;
        Commit();
        CleanupFailure.SetCleanupFailureAfterDeletion(FirstId, SecondId);
        BindSubscription(CleanupFailure);

        // [WHEN] Cleanup fails for the second skill after the first skill and its history were deleted.
        Skill.SetFilter(ID, '%1|%2', FirstId, SecondId);
        asserterror Skill.DeleteAll(false);
        UnbindSubscription(CleanupFailure);

        // [THEN] All original skills and history are intact.
        Assert.ExpectedError(CleanupFailureErr);
        Skill.Reset();
        Assert.AreEqual(3, Skill.Count(), 'A later cleanup failure must roll back every selected deletion.');
        Skill.Get(FirstId);
        Assert.AreEqual(FirstSystemId, Skill.SystemId, 'The first deleted skill must be restored.');
        Assert.AreEqual('Updated first', SkillText.GetSkillText(Skill), 'The first skill instructions must be restored.');
        Skill.Get(SecondId);
        Assert.AreEqual(SecondSystemId, Skill.SystemId, 'The failing skill must be restored.');
        Assert.AreEqual('Updated second', SkillText.GetSkillText(Skill), 'The second skill instructions must be restored.');
        Skill.Get(RetainedId);
        Assert.AreEqual('Retained instructions', SkillText.GetSkillText(Skill), 'Unselected instructions must remain unchanged.');
        AssertVersionCount(FirstId, 2);
        AssertVersionCount(SecondId, 2);
        AssertVersionCount(RetainedId, 1);
    end;

    /// <summary>
    /// Verifies skill history encodes HTML markup, quotes and ampersands.
    /// </summary>
    [Test]
    procedure HtmlEncodingEscapesMarkupAndQuotes()
    var
        Value: Text;
        Encoded: Text;
    begin
        // [GIVEN] HTML-special characters in instruction text.
        Value := '<script>alert("x" & ''y'')</script>';
        // [WHEN] Skill history encodes the value.
        Encoded := History.EncodeContent(Value);
        // [THEN] HTML-special characters are escaped rather than interpreted as markup.
        Assert.AreEqual('&lt;script&gt;alert(&quot;x&quot; &amp; &#39;y&#39;)&lt;/script&gt;', Encoded, 'Skill text must be safe to render as HTML text.');
    end;

    /// <summary>
    /// Verifies XML skill export and import preserve content while creating independent records.
    /// </summary>
    [Test]
    procedure XmlSingleSkillExportImportPreservesContent()
    var
        Original: Record "Business Skill";
        Imported: Record "Business Skill";
        Selection: Record "Business Skill";
        XmlText: Text;
    begin
        // [GIVEN] A skill with content.
        Initialize();
        Original.Get(Management.CreateSkill('Single <&" skill', 'Description <&" with spaces  ', GetMultilineText()));
        Selection.SetRange(ID, Original.ID);
        XmlText := Port.BuildExportXml(Selection);
        // [WHEN] The skill is exported and imported through XML.
        Port.ImportFromXml(XmlText);

        Imported.SetFilter(ID, '>%1', Original.ID);
        // [THEN] Content survives the round trip.
        Assert.AreEqual(1, Imported.Count(), 'Import creates exactly one independent skill.');
        Imported.FindFirst();
        AssertPortableSkillMatches(Original, Imported);

        Selection.SetRange(ID, Imported.ID);
        XmlText := Port.BuildExportXml(Selection);
        Imported.SetFilter(ID, '>%1', Imported.ID);
        Port.ImportFromXml(XmlText);
        Assert.AreEqual(1, Imported.Count(), 'Re-exporting and importing the copy creates exactly one further copy.');
        Imported.FindFirst();
        AssertPortableSkillMatches(Original, Imported);
    end;

    /// <summary>
    /// Verifies exporting selected skills preserves each skill's content.
    /// </summary>
    [Test]
    procedure XmlMultipleSkillsExportImportPreservesEachSkill()
    var
        Original: Record "Business Skill";
        Imported: Record "Business Skill";
        Selection: Record "Business Skill";
        FirstId: BigInteger;
        SecondId: BigInteger;
        ThirdId: BigInteger;
        ExcludedId: BigInteger;
        SkillId: BigInteger;
        SelectedIds: List of [BigInteger];
        XmlText: Text;
    begin
        // [GIVEN] Multiple skills with distinct content.
        Initialize();
        FirstId := Management.CreateSkill('First portable skill', 'First description <&"', GetMultilineText());
        SecondId := Management.CreateSkill('Second portable skill', '', 'Second body with literal <tag> & text');
        ThirdId := Management.CreateSkill('Third portable skill', 'Third description', 'Third independent body');
        ExcludedId := Management.CreateSkill('Not selected for export', 'Excluded body');
        Selection.SetFilter(ID, '%1|%2|%3', FirstId, SecondId, ThirdId);
        XmlText := Port.BuildExportXml(Selection);
        // [WHEN] They are exported and imported together.
        Port.ImportFromXml(XmlText);

        Imported.SetFilter(ID, '>%1', ExcludedId);
        // [THEN] Each skill retains its own content.
        SelectedIds.Add(FirstId);
        SelectedIds.Add(SecondId);
        SelectedIds.Add(ThirdId);
        foreach SkillId in SelectedIds do begin
            Original.Get(SkillId);
            Imported.SetRange(Title, Original.Title);
            Assert.AreEqual(1, Imported.Count(), 'Each selected skill has exactly one imported counterpart.');
            Imported.FindFirst();
            AssertPortableSkillMatches(Original, Imported);
        end;
        Imported.SetRange(Title, 'Not selected for export');
        Assert.IsTrue(Imported.IsEmpty(), 'Unselected skills must not leak into the export.');
    end;

    local procedure AssertPortableSkillMatches(Original: Record "Business Skill"; Imported: Record "Business Skill")
    begin
        Assert.AreNotEqual(Original.ID, Imported.ID, 'Import creates an independent record.');
        Assert.IsTrue(Original.SystemId <> Imported.SystemId, 'The imported identity is new.');
        Assert.AreNotEqual(Original."Skill ID", Imported."Skill ID", 'Import gets a new generated skill ID.');
        Assert.IsTrue(Imported.Manual, 'Imported skills must be explicitly manual.');
        Assert.AreEqual(Format(Imported.ID, 0, '<Integer,20><Filler Character,0>'), Imported."Skill ID", 'Imported manual identifiers must equal the numeric record ID padded to 20 digits.');
        Assert.AreEqual(Original.Title, Imported.Title, 'The title round-trips exactly.');
        Assert.AreEqual(Original.Description, Imported.Description, 'The description round-trips exactly.');
        Assert.AreEqual(SkillText.GetSkillText(Original), SkillText.GetSkillText(Imported), 'Complete instructions round-trip exactly.');
        Assert.AreEqual(Imported.Status::Active, Imported.Status, 'Imported skills start Active.');
        AssertVersionCount(Imported.ID, 1);
    end;

    /// <summary>
    /// Verifies XML round-tripping preserves maximum-length instruction text and description without truncation.
    /// </summary>
    [Test]
    procedure XmlMaximumLengthTextRoundTripsWithoutTruncation()
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
        Value: Text;
        XmlText: Text;
    begin
        // [GIVEN] A skill with maximum-length text and description.
        Initialize();
        Value := PadStr('Beginning ', 99996, 'x') + ' end';
        SkillId := Management.CreateSkill('Large portable text', CopyStr(PadStr('description', 2048, 'x'), 1, 2048), Value);
        Skill.SetRange(ID, SkillId);
        XmlText := Port.BuildExportXml(Skill);
        LibraryBusinessSkill.CleanAll();
        // [WHEN] It is exported and imported through XML.
        Port.ImportFromXml(XmlText);
        Skill.Reset();
        Skill.FindFirst();
        // [THEN] Neither field is truncated.
        Assert.AreEqual(Value, SkillText.GetSkillText(Skill), 'The complete maximum-length payload, including its tail, must round-trip.');
        Assert.AreEqual(PadStr('description', 2048, 'x'), Skill.Description, 'Maximum-length descriptions round-trip without truncation.');
        AssertVersionCount(Skill.ID, 1);
    end;

    /// <summary>
    /// Verifies XML normalizes line endings while preserving literal markup, entities, and trailing spaces.
    /// </summary>
    [Test]
    procedure XmlNormalizesLineEndingsAndPreservesLiteralText()
    var
        Skill: Record "Business Skill";
        CR: Char;
        LF: Char;
        Value: Text;
        ExpectedText: Text;
        XmlText: Text;
        SkillId: BigInteger;
    begin
        // [GIVEN] Mixed line endings and XML-looking literal text.
        Initialize();
        CR := 13;
        LF := 10;
        Value := Format(CR) + 'CRLF' + Format(CR) + Format(LF) + 'LF' + Format(LF) + 'Literal &#xD; <SkillText> & spaces  ';
        ExpectedText := 'CRLF' + GetLineBreak() + 'LF' + GetLineBreak() + 'Literal &#xD; <SkillText> & spaces  ';
        SkillId := Management.CreateSkill('Mixed line endings', Value);
        Skill.SetRange(ID, SkillId);
        XmlText := Port.BuildExportXml(Skill);
        LibraryBusinessSkill.CleanAll();
        // [WHEN] Skill content round-trips through XML.
        Port.ImportFromXml(XmlText);
        Skill.Reset();
        Skill.FindFirst();
        // [THEN] Line endings normalize while literal content survives.
        Assert.AreEqual(StrLen(ExpectedText), StrLen(SkillText.GetSkillText(Skill)), 'BLOB reads discard standalone CR characters and restore platform line separators.');
        Assert.AreEqual(ExpectedText, SkillText.GetSkillText(Skill), 'The line-based XML round trip preserves literal entities, markup and trailing spaces.');
    end;

    /// <summary>
    /// Verifies importing the same XML twice creates separate active skills with independent identities.
    /// </summary>
    [Test]
    procedure XmlImportCreatesIndependentActiveSkillOnEachImport()
    var
        Skill: Record "Business Skill";
        SkillId: BigInteger;
        XmlText: Text;
    begin
        // [GIVEN] An exported canonical skill.
        Initialize();
        SkillId := Management.CreateSkill('Independent copies', 'Body');
        Skill.SetRange(ID, SkillId);
        XmlText := Port.BuildExportXml(Skill);
        LibraryBusinessSkill.CleanAll();
        // [WHEN] The same XML is imported twice.
        Port.ImportFromXml(XmlText);
        Port.ImportFromXml(XmlText);
        Skill.Reset();
        // [THEN] Each import creates an independent active skill.
        Assert.AreEqual(2, Skill.Count(), 'Document-local references must create independent skills across imports.');
        Skill.SetRange(Status, Skill.Status::Active);
        Assert.AreEqual(2, Skill.Count(), 'Every imported copy must be Active.');
    end;

    /// <summary>
    /// Verifies an omitted legacy skill description does not inherit the preceding skill's description.
    /// </summary>
    [Test]
    procedure XmlOptionalDescriptionsDoNotLeakBetweenSkills()
    var
        Skill: Record "Business Skill";
        XmlText: Text;
    begin
        // [GIVEN] XML with a described skill followed by one without a description.
        Initialize();
        XmlText :=
            '<BusinessSkill><Skills>' +
            '<Skill><Reference>1</Reference><Title>Described</Title><Description>Search me</Description><SkillText>First body</SkillText></Skill>' +
            '<Skill><Reference>2</Reference><Title>Legacy</Title><SkillText>Second body</SkillText></Skill>' +
            '</Skills></BusinessSkill>';
        // [WHEN] Both skills are imported.
        Port.ImportFromXml(XmlText);
        Skill.SetRange(Title, 'Described');
        Skill.FindFirst();
        // [THEN] Optional description values do not carry over.
        Assert.AreEqual('Search me', Skill.Description, 'Import supplied descriptions.');
        Skill.SetRange(Title, 'Legacy');
        Skill.FindFirst();
        Assert.AreEqual('', Skill.Description, 'Old documents without descriptions must not inherit the preceding skill description.');
        Assert.AreEqual('Second body', SkillText.GetSkillText(Skill), 'Legacy instructions remain unchanged.');
    end;

    /// <summary>
    /// Verifies importing an oversized description fails instead of truncating or persisting partial content.
    /// </summary>
    [Test]
    procedure XmlRejectsOversizedDescriptionWithoutTruncation()
    var
        Skill: Record "Business Skill";
        XmlText: Text;
    begin
        // [GIVEN] XML containing a description beyond the allowed length.
        Initialize();
        XmlText :=
            '<BusinessSkill><Skills><Skill><Reference>1</Reference><Title>Too long</Title><Description>' +
            PadStr('x', 2049, 'x') +
            '</Description><SkillText>Body</SkillText></Skill></Skills></BusinessSkill>';
        Commit();
        // [WHEN] The XML is imported.
        asserterror Port.ImportFromXml(XmlText);
        // [THEN] Import fails rather than truncating the description.
        Assert.ExpectedError('2048');
        Assert.IsTrue(Skill.IsEmpty(), 'Invalid metadata must not create a truncated skill.');
    end;

    /// <summary>
    /// Verifies importing overlength skill instructions fails without creating a partial skill.
    /// </summary>
    [Test]
    procedure XmlOversizedSkillTextIsRejected()
    var
        Skill: Record "Business Skill";
        XmlText: Text;
    begin
        // [GIVEN] XML containing overlong skill instructions.
        Initialize();
        XmlText :=
            '<BusinessSkill><Skills><Skill><Reference>1</Reference><Title>Too long</Title><SkillText>' +
            PadStr('x', 100001, 'x') +
            '</SkillText></Skill></Skills></BusinessSkill>';
        Commit();
        // [WHEN] The skill is imported.
        asserterror Port.ImportFromXml(XmlText);
        // [THEN] Import rejects the body without persisting it.
        Assert.ExpectedError('100000 characters');
        Assert.IsTrue(Skill.IsEmpty(), 'Oversized portable text must not create a partial skill.');
    end;

    /// <summary>
    /// Verifies portable skill reference zero is rejected before an auto-incremented skill is created.
    /// </summary>
    [Test]
    procedure XmlZeroSkillReferenceIsRejectedBeforeAutoIncrement()
    begin
        // [GIVEN] XML using zero as a portable skill reference.
        // [WHEN] Import validates the reference.
        // [THEN] It fails before creating an auto-incremented skill.
        AssertInvalidPortableSkillReference(0);
    end;

    /// <summary>
    /// Verifies a negative portable skill reference rolls back the import.
    /// </summary>
    [Test]
    procedure XmlNegativeSkillReferenceRollsBackImport()
    begin
        // [GIVEN] XML using a negative portable skill reference.
        // [WHEN] The XML is imported.
        // [THEN] The invalid reference rolls back the import.
        AssertInvalidPortableSkillReference(-1);
    end;

    /// <summary>
    /// Verifies duplicate portable skill references roll back the import.
    /// </summary>
    [Test]
    procedure XmlDuplicateSkillReferenceRollsBackImport()
    begin
        // [GIVEN] XML with duplicate portable skill references.
        // [WHEN] The XML is imported.
        // [THEN] The duplicate reference rolls back the import.
        AssertInvalidPortableSkillReference(1);
    end;

    local procedure AssertInvalidPortableSkillReference(Reference: BigInteger)
    var
        Skill: Record "Business Skill";
        Version: Record "Business Skill Text Version";
        XmlText: Text;
    begin
        Initialize();
        XmlText :=
            '<BusinessSkill><Skills><Skill><Reference>1</Reference><Title>First</Title><SkillText>Body</SkillText></Skill>' +
            '<Skill><Reference>' + Format(Reference, 0, 9) + '</Reference><Title>Invalid</Title><SkillText>Body</SkillText></Skill>' +
            '</Skills></BusinessSkill>';
        Commit();
        asserterror Port.ImportFromXml(XmlText);
        Assert.ExpectedError('reference');
        Assert.IsTrue(Skill.IsEmpty(), 'Invalid portable references must roll back earlier skills.');
        Assert.IsTrue(Version.IsEmpty(), 'Invalid portable references must roll back earlier history.');
    end;

    local procedure AssertDiscoveryTimestamp(SkillJson: JsonObject)
    var
        Skill: Record "Business Skill";
        Token: JsonToken;
    begin
        SkillJson.Get('id', Token);
        Skill.Get(Token.AsValue().AsBigInteger());
        Assert.AreNotEqual(0DT, Skill.SystemModifiedAt, 'The canonical skill must have a persisted modification timestamp.');
        Assert.IsTrue(SkillJson.Get('lastModifiedDateTime', Token), 'Discovery JSON must expose lastModifiedDateTime.');
        Assert.AreEqual(Skill.SystemModifiedAt, Token.AsValue().AsDateTime(), 'Discovery must return the canonical modification timestamp, not temporary-buffer metadata.');
        Assert.IsFalse(SkillJson.Contains('revision'), 'Consumer-facing discovery JSON must not expose the internal row version.');
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
        // [GIVEN] An active skill and Markdown containing headings, tasks, and fenced AL.
        Initialize();
        Skill.Get(Management.CreateSkill('Markdown skill', '# Original'));
        Markdown := '# Instructions' + GetLineBreak() + GetLineBreak() +
            '- [ ] Review **orders**' + GetLineBreak() + '```al' + GetLineBreak() +
            'Message(''Review'');' + GetLineBreak() + '```';
        Commit();

        // [WHEN] Instructions and metadata are edited on the same card.
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        SkillCard.SkillTextEditor.SkillText.AssertEquals('# Original');
        SkillCard.SkillTextEditor.SkillText.SetValue(Markdown);
        SkillCard.Title.SetValue('Updated Markdown skill');
        SkillCard.SkillTextEditor.SkillText.SetValue(Markdown + GetLineBreak() + 'Final instruction');
        SkillCard.Close();

        // [THEN] Both edits persist and reopening displays the latest Markdown without adding history.
        Skill.Get(Skill.ID);
        Assert.AreEqual('Updated Markdown skill', Skill.Title, 'Text edits must not overwrite parent metadata.');
        Assert.AreEqual(Markdown + GetLineBreak() + 'Final instruction', SkillText.GetSkillText(Skill), 'The field must persist Markdown, not HTML.');
        AssertVersionCount(Skill.ID, 3);
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        SkillCard.SkillTextEditor.SkillText.AssertEquals(SkillText.GetSkillText(Skill));
        SkillCard.SkillTextEditor.SkillText.SetValue(SkillText.GetSkillText(Skill));
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
        // [GIVEN] An open card whose instructions are subsequently changed by another writer.
        Initialize();
        Skill.Get(Management.CreateSkill('Concurrent Markdown', '# Original'));
        Commit();
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        Management.SetSkillText(Skill.ID, '# Concurrent');
        Commit();

        // [WHEN] The stale editor attempts to save.
        asserterror SkillCard.SkillTextEditor.SkillText.SetValue('# Stale');

        // [THEN] The concurrent content and its history remain intact.
        Assert.ExpectedError('changed by another user');
        SkillCard.Close();
        Skill.Get(Skill.ID);
        Assert.AreEqual('# Concurrent', SkillText.GetSkillText(Skill), 'A stale Markdown field must not overwrite newer text.');
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
        // [GIVEN] A saved skill with Markdown instructions.
        Initialize();
        Skill.Get(Management.CreateSkill('Read-only Markdown', '**Instructions**'));
        Commit();

        // [WHEN] Its card is viewed, then an empty new card is opened.
        SkillCard.OpenView();
        SkillCard.GoToRecord(Skill);
        // [THEN] The viewed instructions and the unsaved editor are not editable.
        SkillCard.SkillTextEditor.SkillText.AssertEquals('**Instructions**');
        Assert.IsFalse(SkillCard.SkillTextEditor.SkillText.Editable(), 'View mode must not permit Markdown editing.');
        SkillCard.Close();
        SkillCard.OpenNew();
        Assert.IsFalse(SkillCard.SkillTextEditor.SkillText.Editable(), 'An unsaved skill must not permit instruction edits.');
        SkillCard.Close();
        AssertVersionCount(Skill.ID, 1);
    end;

    /// <summary>
    /// Markdown rendering limits do not reduce the skill text limit or bypass server-side validation.
    /// </summary>
    [Test]
    procedure MarkdownFieldEnforcesSkillTextLimit()
    var
        Skill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
        MaximumText: Text;
    begin
        // [GIVEN] An active skill and source beyond the control's rich-rendering limit.
        Initialize();
        Skill.Get(Management.CreateSkill('Long Markdown', 'Original'));
        MaximumText := PadStr('x', 100000, 'x');
        Commit();
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);

        // [WHEN] The field saves the supported maximum and rejects overlength and empty active text.
        SkillCard.SkillTextEditor.SkillText.SetValue(MaximumText);
        Commit();
        asserterror SkillCard.SkillTextEditor.SkillText.SetValue(MaximumText + 'x');
        // [THEN] Validation retains the last valid text and creates no rejected history entries.
        Assert.ExpectedError('100000 characters');
        asserterror SkillCard.SkillTextEditor.SkillText.SetValue('');
        Assert.ExpectedError('An active skill needs a title and skill text.');
        SkillCard.Close();
        Skill.Get(Skill.ID);
        Assert.AreEqual(MaximumText, SkillText.GetSkillText(Skill), 'Rejected field values must preserve the full supported source.');
        AssertVersionCount(Skill.ID, 2);
    end;

    /// <summary>
    /// History renders the selected Markdown read-only and restoring it refreshes the live editor.
    /// </summary>
    [Test]
    [HandlerFunctions('RestoreMarkdownHistoryHandler')]
    procedure MarkdownHistoryPreviewAndRestore()
    var
        Skill: Record "Business Skill";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [GIVEN] A skill with two Markdown instruction versions.
        Initialize();
        Skill.Get(Management.CreateSkill('Markdown history', '# Original'));
        Management.SetSkillText(Skill.ID, '**Latest**');
        Skill.Get(Skill.ID);
        Commit();
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);

        // [WHEN] The older version is previewed and restored in the history dialog.
        SkillCard.SkillTextEditor.ViewHistory.Invoke();

        // [THEN] The live field refreshes and restoration appends a new history entry.
        SkillCard.SkillTextEditor.SkillText.AssertEquals('# Original');
        SkillCard.Close();
        Skill.Get(Skill.ID);
        Assert.AreEqual('# Original', SkillText.GetSkillText(Skill), 'Restoring history must update the live Markdown field.');
        AssertVersionCount(Skill.ID, 3);
    end;

    [ModalPageHandler]
    procedure RestoreMarkdownHistoryHandler(var Versions: TestPage "Business Skill Text Versions")
    begin
        Versions.First();
        Versions.TextPreview.SkillText.AssertEquals('**Latest**');
        Assert.IsFalse(Versions.TextPreview.SkillText.Editable(), 'History must render Markdown read-only.');
        Versions.Last();
        Versions.TextPreview.SkillText.AssertEquals('# Original');
        Versions.SetAsCurrent.Invoke();
    end;

    [MessageHandler]
    procedure StaleMarkdownMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, 'changed by another user') > 0, 'Closing the rejected draft must report the concurrency conflict.');
    end;

    local procedure Initialize()
    begin
        LibraryBusinessSkill.CleanAll();
    end;

    /// <summary>
    /// Configures the bound subscriber to fail only after an earlier skill and its history have been deleted.
    /// </summary>
    procedure SetCleanupFailureAfterDeletion(DeletedSkillId: BigInteger; FailingSkillId: BigInteger)
    begin
        DeletedSkillIdBeforeFailure := DeletedSkillId;
        CleanupFailureSkillId := FailingSkillId;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Business Skill Text Version", OnBeforeDeleteEvent, '', false, false)]
    local procedure FailHistoryCleanup(var Rec: Record "Business Skill Text Version"; RunTrigger: Boolean)
    var
        Skill: Record "Business Skill";
    begin
        if Rec.IsTemporary() then
            exit;

        if (CleanupFailureSkillId <> 0) and (Rec."Skill ID" <> CleanupFailureSkillId) then
            exit;

        if DeletedSkillIdBeforeFailure <> 0 then begin
            Assert.IsFalse(Skill.Get(DeletedSkillIdBeforeFailure), 'The earlier skill must be deleted before the cleanup failure.');
            AssertVersionCount(DeletedSkillIdBeforeFailure, 0);
        end;

        Error(CleanupFailureErr);
    end;

    local procedure AssertVersionCount(SkillId: BigInteger; ExpectedCount: Integer)
    var
        Version: Record "Business Skill Text Version";
    begin
        Version.SetRange("Skill ID", SkillId);
        Assert.AreEqual(ExpectedCount, Version.Count(), 'Unexpected number of canonical text versions.');
    end;

    local procedure AssertBlobTextRead(Value: Text; Expected: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        TextHelper: Codeunit "Business Skill Text";
        Input: InStream;
        Output: OutStream;
    begin
        TempBlob.CreateOutStream(Output, TextHelper.GetEncoding());
        Output.WriteText(Value);
        TempBlob.CreateInStream(Input, TextHelper.GetEncoding());
        Assert.AreEqual(Expected, TextHelper.ReadText(Input), 'BLOB text reads must only add separators between lines.');
    end;

    local procedure GetLineBreak(): Text
    var
        Builder: TextBuilder;
    begin
        Builder.AppendLine('');
        exit(Builder.ToText());
    end;

    local procedure GetMultilineText(): Text
    var
        Builder: TextBuilder;
    begin
        Builder.AppendLine();
        Builder.Append('First line');
        Builder.AppendLine();
        Builder.AppendLine();
        Builder.Append('Second line');
        Builder.AppendLine();
        Builder.Append('UTF-8: æøå Ω 漢字 € 🙂 <&"');
        exit(Builder.ToText());
    end;

    var
        Assert: Codeunit "Library Assert";
        LibraryBusinessSkill: Codeunit "Library - Business Skill";
        Management: Codeunit "Business Skill Management";
        History: Codeunit "Business Skill Text History";
        Port: Codeunit "Business Skill Port";
        SkillText: Codeunit "Business Skill Text";
        CleanupFailureSkillId: BigInteger;
        DeletedSkillIdBeforeFailure: BigInteger;
        CleanupFailureErr: Label 'Skill history cleanup failed.', Locked = true;
}
