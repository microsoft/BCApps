// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.AI.BusinessSkills;

using System.AI.BusinessSkills;
using System.TestLibraries.AI.BusinessSkills;
using System.TestLibraries.Utilities;

codeunit 130051 "Business Skill Builder Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    /// <summary>
    /// Creation allocates an inactive read-only skill owned by the calling app.
    /// </summary>
    [Test]
    procedure CreateDefaultsToInactive()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        Management: Codeunit "Business Skill Management";
        CurrentModule: ModuleInfo;
        SkillId: BigInteger;
    begin
        // [GIVEN] A fresh builder with overridden content and an explicit version.
        Initialize();
        Builder.Initialize('TEST', 'Initial title', 'Initial instructions')
            .SetDisplayName('New skill')
            .SetDescription('Search description')
            .SetContent('Instructions')
            .SetContentVersion('v1');
        Assert.IsTrue(Skill.IsEmpty(), 'Initialization must not persist a skill.');

        // [WHEN] Creating the skill.
        SkillId := Builder.Create();

        // [THEN] Content changes persist with the builder defaults.
        Skill.Get(SkillId);
        Assert.AreEqual(Skill.Status::Inactive, Skill.Status, 'The default must be inactive.');
        Assert.AreEqual('New skill', Skill.Title, 'The title override must persist.');
        Assert.AreEqual('Search description', Skill.Description, 'Description must persist.');
        Assert.AreEqual('Instructions', SkillText.GetSkillText(Skill), 'Instructions must persist.');
        NavApp.GetCurrentModuleInfo(CurrentModule);
        Assert.AreEqual(CurrentModule.Id, Skill."Owning App ID", 'Ownership must be the calling test app, not the skill implementation app.');
        Assert.AreEqual('TEST', Skill."Skill ID", 'The explicit skill ID must persist.');
        Assert.AreEqual('v1', Skill.Version, 'The version supplied by the app must persist.');
        Assert.IsTrue(Skill."Read-Only", 'The builder must default to read-only.');
        Assert.IsTrue(Management.IsSkillAvailableForCurrentCompany(SkillId), 'The skill must apply to the current company.');
    end;

    /// <summary>
    /// Deletion denied by an installed owning app identifies the extension and the available alternatives.
    /// </summary>
    [Test]
    procedure InstalledOwnerDeletionExplainsRestriction()
    var
        Skill: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
        BusinessSkill: Codeunit "Business Skill";
        Management: Codeunit "Business Skill Management";
        OwningModule: ModuleInfo;
        DeleteError: Text;
        ExpectedDeleteErrorLbl: Label 'You cannot delete this skill because its owning extension, ''%1'', is still installed. Uninstall the extension to delete the skill, or deactivate the skill to stop it being used.', Locked = true;
    begin
        // [GIVEN] A skill owned by the installed test library, not the calling test app.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateAppOwnedSkill('FOREIGN-OWNER', 'Foreign skill', 'Instructions'));
        NavApp.GetModuleInfo(Skill."Owning App ID", OwningModule);
        Commit();

        // [WHEN] Checking deletion from a different app.
        Assert.IsFalse(Management.CanDeleteSkill(Skill, DeleteError), 'Only the installed owning app may delete its skill.');
        asserterror BusinessSkill.DeleteSkill(Skill.ID);
        Assert.ExpectedError(StrSubstNo(ExpectedDeleteErrorLbl, OwningModule.Name));

        // [THEN] The denial names the extension and explains uninstalling or deactivating.
        Assert.AreEqual(
            StrSubstNo(ExpectedDeleteErrorLbl, OwningModule.Name),
            DeleteError, 'An installed owner must not be reported as a missing user permission.');
        Assert.IsFalse(Management.CanDeleteSkill(Skill), 'Both permission-check overloads must reject the same caller.');
        Assert.IsTrue(Skill.Get(Skill.ID), 'A foreign caller must not delete the skill through the public facade.');
        TextVersion.SetRange("Skill ID", Skill.ID);
        Assert.AreEqual(1, TextVersion.Count(), 'Rejected deletion must preserve the skill history.');
    end;

    /// <summary>
    /// The public facade preserves the calling app identity and deletes its skill and history together.
    /// </summary>
    [Test]
    procedure PublicFacadeDeletesCallingAppsSkill()
    var
        Skill: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
        Builder: Codeunit "Business Skill Builder";
        BusinessSkill: Codeunit "Business Skill";
        CurrentModule: ModuleInfo;
        SkillId: BigInteger;
    begin
        // [GIVEN] An inactive skill and history owned by the calling test app.
        Initialize();
        SkillId := Builder.Initialize('OWNER-DELETE', 'Owned skill', 'Instructions').Create();
        Skill.Get(SkillId);
        NavApp.GetCurrentModuleInfo(CurrentModule);
        Assert.AreEqual(CurrentModule.Id, Skill."Owning App ID", 'The builder must retain the calling app identity.');
        TextVersion.SetRange("Skill ID", SkillId);
        Assert.AreEqual(1, TextVersion.Count(), 'Creation must record the initial text history.');

        // [WHEN] The owning app deletes through the public facade.
        BusinessSkill.DeleteSkill(SkillId);

        // [THEN] The additional implementation frame does not replace the caller or skip history cleanup.
        Assert.IsFalse(Skill.Get(SkillId), 'The owning app must be able to delete its skill.');
        Assert.IsTrue(TextVersion.IsEmpty(), 'The deleted skill must have no remaining history.');
    end;

    /// <summary>
    /// The installed owning app can still delete its skill and receives no stale denial message.
    /// </summary>
    [Test]
    procedure OwningAppDeletionHasNoRestriction()
    var
        TempSkill: Record "Business Skill" temporary;
        Management: Codeunit "Business Skill Management";
        CurrentModule: ModuleInfo;
        DeleteError: Text;
    begin
        // [GIVEN] A skill owned by the calling test app and a previous denial message.
        NavApp.GetCurrentModuleInfo(CurrentModule);
        TempSkill."Owning App ID" := CurrentModule.Id;
        DeleteError := 'Previous denial';

        // [WHEN] The owning app checks deletion.
        Assert.IsTrue(Management.CanDeleteSkill(TempSkill, DeleteError), 'The installed owning app must retain deletion access.');

        // [THEN] No error is returned for the permitted operation.
        Assert.AreEqual('', DeleteError, 'An allowed deletion must clear the previous denial.');
        Assert.IsTrue(Management.CanDeleteSkill(TempSkill), 'Both permission-check overloads must allow the owning app.');
    end;

    /// <summary>
    /// Uninitialized and consumed builders fail explicitly and can be reused only after Clear.
    /// </summary>
    [Test]
    procedure BuilderIsOneShot()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
    begin
        // [GIVEN] An uninitialized builder.
        Initialize();
        asserterror Builder.Create();
        Assert.ExpectedError('Initialize');
        asserterror Builder.SetDisplayName('Title');
        Assert.ExpectedError('Initialize');

        // [WHEN] Initializing and consuming the builder.
        Builder.Initialize('FIRST', 'Title', 'Instructions').SetContentVersion('1');
        asserterror Builder.Initialize('OTHER', 'Other title', 'Other instructions');
        Assert.ExpectedError('only one skill');
        Builder.Create();
        Commit();

        // [THEN] Neither mutation nor another creation is allowed after success.
        asserterror Builder.Create();
        Assert.ExpectedError('only one skill');
        asserterror Builder.SetActive(true);
        Assert.ExpectedError('only one skill');
        Clear(Builder);
        Builder.Initialize('SECOND', 'Second title', 'Instructions').SetContentVersion('1').Create();
        Assert.AreEqual(2, Skill.Count(), 'Clear permits an independent creation.');
    end;

    /// <summary>
    /// App-owned skills default an omitted creation version to v1.0.
    /// </summary>
    [Test]
    procedure CreateOrUpdateDefaultsMissingVersion()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
    begin
        // [GIVEN] A builder without a version.
        Initialize();
        Builder.Initialize('TEST', 'Title', 'Instructions');
        // [WHEN] Creating the skill.
        Skill.Get(Builder.CreateOrUpdate());

        // [THEN] Creation supplies the default without changing app ownership.
        Assert.AreEqual('v1.0', Skill.Version, 'An omitted version must default on creation.');
        Assert.IsFalse(Skill.Manual, 'Defaulting the version must not make the skill manual.');
    end;

    /// <summary>
    /// Metadata-only upserts preserve the version, while changed instructions require an explicit new version.
    /// </summary>
    [Test]
    procedure UpsertSeparatesMetadataAndInstructionVersions()
    var
        Skill: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
        Builder: Codeunit "Business Skill Builder";
        SkillId: BigInteger;
    begin
        // [GIVEN] An app-owned editable skill with an explicit release version.
        Initialize();
        SkillId := Builder.Initialize('UPSERT', 'Original title', 'Original instructions')
            .SetContentLocked(false).SetContentVersion('release-1').Create();
        Clear(Builder);

        // [WHEN] Metadata changes without supplying a version.
        Assert.AreEqual(SkillId, Builder.Initialize('UPSERT', 'Updated title', 'Original instructions')
            .SetDescription('Updated description').SetContentLocked(false).CreateOrUpdate(), 'An upsert must retain the existing identity.');

        // [THEN] Metadata changes without resetting the version or appending history.
        Skill.Get(SkillId);
        Assert.AreEqual('Updated title', Skill.Title, 'The title must be updated.');
        Assert.AreEqual('Updated description', Skill.Description, 'The description must be updated.');
        Assert.AreEqual('release-1', Skill.Version, 'Metadata must not default or replace an existing version.');
        TextVersion.SetRange("Skill ID", SkillId);
        Assert.AreEqual(1, TextVersion.Count(), 'Metadata must not append instruction history.');
        Commit();
        Clear(Builder);

        // [WHEN] Instructions change without a version.
        Builder.Initialize('UPSERT', 'Updated title', 'Changed instructions').SetContentLocked(false);
        asserterror Builder.CreateOrUpdate();

        // [THEN] The intended validation fails without changing instructions or history.
        Assert.ExpectedError('Set a new version of the skill before changing its instructions.');
        Skill.Get(SkillId);
        Assert.AreEqual('Original instructions', SkillText.GetSkillText(Skill), 'Rejected instructions must not persist.');
        Assert.AreEqual('release-1', Skill.Version, 'Rejected instructions must not change the version.');
        Assert.AreEqual(1, TextVersion.Count(), 'Rejected instructions must not append history.');
    end;

    /// <summary>
    /// App-owned identifiers do not use a reserved manual prefix.
    /// </summary>
    [Test]
    procedure BuilderAllowsAppSuppliedPrefix()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
    begin
        // [GIVEN] An app-owned skill whose identifier starts with M-.
        Initialize();
        Builder.Initialize('M-1', 'Title', 'Instructions').SetContentVersion('1');
        // [WHEN] Creating the skill.
        Skill.Get(Builder.Create());

        // [THEN] Manual is determined by the stored flag, not the identifier.
        Assert.AreEqual('M-1', Skill."Skill ID", 'An app-supplied identifier must persist.');
        Assert.IsFalse(Skill.Manual, 'The identifier prefix must not imply manual ownership.');
    end;

    /// <summary>
    /// Active content validation rejects incomplete instructions without creating a skill.
    /// </summary>
    [Test]
    procedure InvalidActiveContentDoesNotCreateData()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
    begin
        // [GIVEN] An active skill without instructions.
        Initialize();
        Builder.Initialize('TEST', 'Title', '').SetContentVersion('1').SetActive(true);
        Commit();

        // [WHEN] Creating invalid active content.
        asserterror Builder.Create();

        // [THEN] Governed content validation rejects the operation before any creation.
        Assert.ExpectedError('An active skill needs a title and skill text.');
        Assert.IsTrue(Skill.IsEmpty(), 'Invalid active content must not create a skill.');
    end;

    /// <summary>
    /// Creation does not commit the caller's transaction.
    /// </summary>
    [Test]
    procedure CallerFailureRollsBackSkill()
    var
        Skill: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
    begin
        // [GIVEN] An empty committed fixture.
        Initialize();
        Commit();

        // [WHEN] The caller fails after successful creation.
        asserterror CreateThenFail();

        // [THEN] The skill and its history remain part of the caller's transaction.
        Assert.ExpectedError('Caller rollback');
        Assert.IsTrue(Skill.IsEmpty(), 'The skill must roll back.');
        Assert.IsTrue(TextVersion.IsEmpty(), 'The text history must roll back.');
    end;

    /// <summary>
    /// Read-only content and unlocking are rejected without changing the source or its version.
    /// </summary>
    [Test]
    procedure ReadOnlySkillRejectsContentChanges()
    var
        Skill: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
        Builder: Codeunit "Business Skill Builder";
        Management: Codeunit "Business Skill Management";
        SkillId: BigInteger;
    begin
        // [GIVEN] A published-content style skill protected by the builder default.
        Initialize();
        SkillId := Builder.Initialize('LOCKED', 'Original title', 'Original instructions')
            .SetDescription('Original description').SetContentVersion('2.0').SetActive(true).Create();
        Commit();

        // [WHEN] Mutations arrive through normal management and record modification.
        Management.UpdateSkill(SkillId, 'Changed title', 'Original instructions');
        Skill.Get(SkillId);
        Skill.Description := 'Changed description';
        Management.UpdateSkillRecord(SkillId, Skill, SkillText.GetSkillText(Skill));
        Commit();
        Skill.Get(SkillId);
        asserterror Management.SetSkillText(SkillId, 'Changed instructions', Skill.SystemId, Skill.SystemRowVersion);
        Assert.ExpectedError('read-only');
        Skill.Get(SkillId);
        Skill."Read-Only" := false;
        asserterror Skill.Modify(true);
        Assert.ExpectedError('read-only');

        // [THEN] Failed writes leave all protected values and history unchanged.
        Skill.Get(SkillId);
        Assert.AreEqual('Changed title', Skill.Title, 'Read-only instructions must not prevent metadata edits.');
        Assert.AreEqual('Changed description', Skill.Description, 'Read-only instructions must not prevent metadata edits.');
        Assert.AreEqual('Original instructions', SkillText.GetSkillText(Skill), 'Instructions must not change.');
        Assert.AreEqual('2.0', Skill.Version, 'Failed changes must not change Version.');
        Assert.IsTrue(Skill."Read-Only", 'An existing protected skill cannot be unlocked.');
        TextVersion.SetRange("Skill ID", SkillId);
        Assert.AreEqual(1, TextVersion.Count(), 'Rejected changes must not append history.');
    end;

    /// <summary>
    /// Content protection does not restrict activation or deactivation.
    /// </summary>
    [Test]
    procedure ReadOnlySkillAllowsLifecycle()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        Management: Codeunit "Business Skill Management";
        SkillId: BigInteger;
    begin
        // [GIVEN] An inactive read-only skill.
        Initialize();
        SkillId := Builder.Initialize('LOCKED', 'Title', 'Instructions').SetContentVersion('1').Create();

        // [WHEN] Changing status without editing content.
        Management.ActivateSkill(SkillId);
        Management.DeactivateSkill(SkillId);

        // [THEN] Protection and content version are unchanged.
        Skill.Get(SkillId);
        Assert.IsTrue(Skill."Read-Only", 'Lifecycle changes must not remove protection.');
        Assert.AreEqual('1', Skill.Version, 'Lifecycle changes must not change Version.');
        Assert.AreEqual(Skill.Status::Inactive, Skill.Status, 'Deactivation remains available.');
    end;

    /// <summary>
    /// Editable app-owned skills change their text only together with a new version supplied by the app.
    /// </summary>
    [Test]
    procedure EditableSkillVersionsOnlyInstructionChanges()
    var
        Skill: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
        Builder: Codeunit "Business Skill Builder";
        Management: Codeunit "Business Skill Management";
        SkillId: BigInteger;
        OriginalEntryNo: Integer;
    begin
        // [GIVEN] Explicitly editable app content with a dotted initial version.
        Initialize();
        SkillId := Builder.Initialize('EDITABLE', 'Title', 'First instructions')
            .SetContentLocked(false).SetContentVersion('1.0').Create();
        TextVersion.SetRange("Skill ID", SkillId);
        TextVersion.FindFirst();
        OriginalEntryNo := TextVersion."Entry No.";

        // [WHEN] Editing metadata and saving unchanged instructions.
        Skill.Get(SkillId);
        Skill.Description := 'New description';
        Management.UpdateSkillRecord(SkillId, Skill, SkillText.GetSkillText(Skill));
        Management.UpdateSkill(SkillId, 'New title', 'First instructions');
        Management.SetSkillText(SkillId, 'First instructions');

        // [THEN] Metadata and no-op saves change neither the version nor the history.
        Skill.Get(SkillId);
        Assert.IsFalse(Skill."Read-Only", 'Explicit editable creation must persist.');
        Assert.AreEqual('1.0', Skill.Version, 'Metadata and unchanged instructions must not change Version.');
        Assert.AreEqual(1, TextVersion.Count(), 'Metadata and no-op saves must not append history.');
        Commit();

        // [WHEN] Instructions change without a new version.
        asserterror Management.SetSkillText(SkillId, 'Second instructions');

        // [THEN] The app must supply the new version.
        Assert.ExpectedError('Specify a new version');

        // [WHEN] Instructions change together with a new version.
        Management.SetSkillText(SkillId, 'Second instructions', '1.1');
        Skill.Get(SkillId);
        Assert.AreEqual('1.1', Skill.Version, 'The version supplied by the app must persist.');
        Commit();

        // [THEN] Restoring history is an instruction change that also needs a version from the app.
        asserterror Management.RestoreTextVersion(OriginalEntryNo);
        Assert.ExpectedError('Specify a new version');
        Skill.Get(SkillId);
        Assert.AreEqual('Second instructions', SkillText.GetSkillText(Skill), 'Rejected restoration must keep the current text.');
        Assert.AreEqual(2, TextVersion.Count(), 'Each real instruction change must append one history row.');
    end;

    /// <summary>
    /// Versions use the full field length and longer versions are rejected.
    /// </summary>
    [Test]
    procedure VersionFitsTheField()
    var
        Skill: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
        Builder: Codeunit "Business Skill Builder";
        Management: Codeunit "Business Skill Management";
        SkillId: BigInteger;
        InitialVersion: Text[50];
        NextVersion: Text[50];
        OversizedVersion: Text;
    begin
        // [GIVEN] An app-owned skill with a version occupying the entire field.
        Initialize();
        InitialVersion := CopyStr(PadStr('release', 50, 'x'), 1, 50);
        SkillId := Builder.Initialize('VERSION', 'Title', 'First').SetContentLocked(false).SetContentVersion(InitialVersion).Create();
        Skill.Get(SkillId);
        Assert.AreEqual(InitialVersion, Skill.Version, 'A version of the full field length must persist.');

        // [WHEN] The app changes the text with another version of the full field length.
        NextVersion := CopyStr(PadStr('next', 50, 'y'), 1, 50);
        Management.SetSkillText(SkillId, 'Second', NextVersion);

        // [THEN] The skill and its history keep the full version.
        Skill.Get(SkillId);
        Assert.AreEqual(NextVersion, Skill.Version, 'The new version must persist without truncation.');
        TextVersion.SetRange("Skill ID", SkillId);
        TextVersion.FindLast();
        Assert.AreEqual(NextVersion, TextVersion.Version, 'History must capture the full version.');

        // [WHEN] A version exceeds the field length.
        Clear(Builder);
        OversizedVersion := PadStr('', 51, '9');
        Builder.Initialize('OVERSIZED', 'Title', 'First');

        // [THEN] The builder rejects it.
        asserterror Builder.SetContentVersion(OversizedVersion);
        Assert.ExpectedError('50');
    end;

    /// <summary>
    /// The skill ID of an app-owned skill is unique within its owning app.
    /// </summary>
    [Test]
    procedure AppSkillIdIsUniqueWithinItsOwner()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        SecondBuilder: Codeunit "Business Skill Builder";
    begin
        // [GIVEN] One app-owned skill under a known skill ID.
        Initialize();
        Builder.Initialize('SHARED', 'Title', 'Instructions').SetContentVersion('1').Create();
        Commit();

        // [WHEN] Creating the same app/skill ID pair again.
        SecondBuilder.Initialize('SHARED', 'Another title', 'Instructions').SetContentVersion('1');
        asserterror SecondBuilder.Create();

        // [THEN] The original is kept and no duplicate is created.
        Assert.ExpectedError('already exists');
        Assert.AreEqual(1, Skill.Count(), 'A rejected duplicate must not create another skill.');
    end;

    /// <summary>
    /// Manual and editable app-owned identities cannot be changed after creation.
    /// </summary>
    [Test]
    procedure SkillIdentityCannotBeChanged()
    var
        Skill: Record "Business Skill";
        OriginalSkill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        Management: Codeunit "Business Skill Management";
        SkillIds: List of [BigInteger];
        SkillId: BigInteger;
    begin
        // [GIVEN] A manual skill and an explicitly editable app-owned skill.
        Initialize();
        SkillIds.Add(Management.CreateSkill('Manual identity', 'Instructions'));
        SkillIds.Add(Builder.Initialize('APP-IDENTITY', 'App identity', 'Instructions').SetContentLocked(false).SetContentVersion('1').Create());
        Commit();

        foreach SkillId in SkillIds do begin
            OriginalSkill.Get(SkillId);

            // [WHEN] A caller changes either identity component.
            Skill.Get(SkillId);
            Skill."Skill ID" := 'CHANGED';
            asserterror Skill.Modify(true);
            Assert.ExpectedError('cannot be changed');
            Skill.Get(SkillId);
            Skill."Owning App ID" := CreateGuid();
            asserterror Skill.Modify(true);
            Assert.ExpectedError('cannot be changed');
            Skill.Get(SkillId);
            Skill.Manual := not Skill.Manual;
            asserterror Skill.Modify(true);
            Assert.ExpectedError('cannot be changed');
            Skill.Get(SkillId);
            Skill."Owning App Publisher" := 'Changed publisher';
            asserterror Skill.Modify(true);
            Assert.ExpectedError('cannot be changed');

            // [THEN] Rejected writes preserve both identity components and the content.
            Skill.Get(SkillId);
            Assert.AreEqual(OriginalSkill."Skill ID", Skill."Skill ID", 'The original skill ID must remain unchanged.');
            Assert.AreEqual(OriginalSkill."Owning App ID", Skill."Owning App ID", 'The original owner must remain unchanged.');
            Assert.AreEqual(OriginalSkill.Manual, Skill.Manual, 'The original manual flag must remain unchanged.');
            Assert.AreEqual(OriginalSkill."Owning App Publisher", Skill."Owning App Publisher", 'The original publisher must remain unchanged.');
            Assert.AreEqual('Instructions', SkillText.GetSkillText(Skill), 'Rejected identity edits must not change instructions.');
        end;
    end;

    /// <summary>
    /// Manual creation derives padded identifiers from record IDs and cannot claim programmatic read-only protection.
    /// </summary>
    [Test]
    procedure ManualSkillsReceiveIdsAndRejectReadOnly()
    var
        FirstSkill: Record "Business Skill";
        Skill: Record "Business Skill";
        Management: Codeunit "Business Skill Management";
    begin
        // [GIVEN] No skills.
        Initialize();

        // [WHEN] Creating skills through normal management instead of an app builder.
        FirstSkill.Get(Management.CreateSkill('First', 'Instructions'));
        Skill.Get(Management.CreateSkill('Second', 'Instructions'));

        // [THEN] Skill IDs match their numeric record IDs and protection cannot be enabled on manual content.
        AssertManualSkillIdentifier(FirstSkill);
        AssertManualSkillIdentifier(Skill);
        Assert.AreNotEqual(FirstSkill."Skill ID", Skill."Skill ID", 'Manual skill IDs must be unique.');
        Assert.AreEqual('v1.0', Skill.Version, 'Manual skills must start at the initial version.');
        Assert.IsTrue(IsNullGuid(Skill."Owning App ID"), 'Management creation must remain manually owned.');
        Assert.IsFalse(Skill."Read-Only", 'Manual content is editable.');
        Assert.AreEqual('Created manually', Management.GetAppName(Skill."Owning App ID"), 'Manual ownership must have a friendly label.');
        Commit();
        Skill."Read-Only" := true;
        asserterror Skill.Modify(true);
        Assert.ExpectedError('cannot be read-only');
    end;

    /// <summary>
    /// Repeated copies retain content, but start fresh manual versions and independent identities.
    /// </summary>
    [Test]
    procedure CopyChainRetainsContentWithFreshVersions()
    var
        SourceSkill: Record "Business Skill";
        FirstCopy: Record "Business Skill";
        SecondCopy: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        Management: Codeunit "Business Skill Management";
    begin
        // [GIVEN] Protected app content with explicit version and description.
        Initialize();
        SourceSkill.Get(Builder.Initialize('SOURCE', 'Title', 'Original instructions')
            .SetContentVersion('2.7').SetDescription('Description').SetActive(true).Create());

        // [WHEN] Copying, editing, and copying the editable copy again.
        FirstCopy.Get(Management.CopySkill(SourceSkill.ID));
        Assert.AreEqual('v1.0', FirstCopy.Version, 'A copy must start a new manual version.');
        Management.SetSkillText(FirstCopy.ID, 'Customized instructions');
        SecondCopy.Get(Management.CopySkill(FirstCopy.ID));

        // [THEN] Identity is local and editable while content is retained.
        Assert.AreNotEqual(FirstCopy.ID, SecondCopy.ID, 'Repeated copies need independent IDs.');
        Assert.AreNotEqual(FirstCopy.SystemId, SecondCopy.SystemId, 'Repeated copies need independent SystemIds.');
        Assert.AreNotEqual(FirstCopy."Skill ID", SecondCopy."Skill ID", 'Repeated copies need unique manual skill IDs.');
        AssertManualSkillIdentifier(SecondCopy);
        Assert.IsTrue(IsNullGuid(SecondCopy."Owning App ID"), 'Copies must be manually owned.');
        Assert.IsFalse(SecondCopy."Read-Only", 'Copies must be editable.');
        Assert.AreEqual(SecondCopy.Status::Inactive, SecondCopy.Status, 'Copies must start inactive.');
        Assert.AreEqual('v1.0', SecondCopy.Version, 'Every copy must start a new manual version.');
        Assert.AreEqual('Description', SecondCopy.Description, 'Copies must retain descriptions.');
        Assert.AreEqual('Customized instructions', SkillText.GetSkillText(SecondCopy), 'Copies must retain the current text.');
        SourceSkill.Get(SourceSkill.ID);
        Assert.AreEqual('Original instructions', SkillText.GetSkillText(SourceSkill), 'Copy edits must leave the original unchanged.');
        Assert.AreEqual('2.7', SourceSkill.Version, 'Copy edits must leave the original version unchanged.');
    end;

    /// <summary>
    /// A copy takes the latest text version of the source and starts its own history.
    /// </summary>
    [Test]
    procedure CopyUsesLatestTextVersion()
    var
        Copy: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
        Builder: Codeunit "Business Skill Builder";
        Management: Codeunit "Business Skill Management";
        SourceId: BigInteger;
    begin
        // [GIVEN] An app-owned skill with two text versions.
        Initialize();
        SourceId := Builder.Initialize('HISTORY', 'Title', 'First').SetContentLocked(false).SetContentVersion('1').Create();
        Management.SetSkillText(SourceId, 'Second', '2');

        // [WHEN] Copying the skill.
        Copy.Get(Management.CopySkill(SourceId));

        // [THEN] The copy holds the latest text under its own initial version and history.
        Assert.AreEqual('Second', SkillText.GetSkillText(Copy), 'The copy must take the latest text.');
        Assert.AreEqual('v1.0', Copy.Version, 'The copy must start at the initial manual version.');
        TextVersion.SetRange("Skill ID", Copy.ID);
        Assert.AreEqual(1, TextVersion.Count(), 'The copy must start its own history with one text version.');
        TextVersion.FindFirst();
        Assert.AreEqual('Second', TextVersion.GetText(), 'The first text version of the copy must hold the latest text.');
        Assert.AreEqual('v1.0', TextVersion.Version, 'The copy history must use its own initial version.');
    end;

    /// <summary>
    /// Copying manual content preserves instructions without claiming app ownership.
    /// </summary>
    [Test]
    procedure ManualCopyRetainsContentAndManualOwnership()
    var
        Copy: Record "Business Skill";
        Management: Codeunit "Business Skill Management";
        SourceId: BigInteger;
    begin
        // [GIVEN] Manually created content.
        Initialize();
        SourceId := Management.CreateSkill('Manual title', 'Manual instructions');

        // [WHEN] Copying it for independent editing.
        Copy.Get(Management.CopySkill(SourceId));

        // [THEN] The independent copy retains instructions and remains manually owned.
        Assert.AreNotEqual(SourceId, Copy.ID, 'The copy must have an independent identity.');
        Assert.AreEqual('Manual instructions', SkillText.GetSkillText(Copy), 'Manual instructions must be retained.');
        Assert.IsTrue(IsNullGuid(Copy."Owning App ID"), 'A manual copy must not claim app ownership.');
    end;

    /// <summary>
    /// Manual copies round-trip their version through XML and receive a new identity.
    /// </summary>
    [Test]
    procedure ManualCopyXmlRetainsVersion()
    var
        SourceSkill: Record "Business Skill";
        Copy: Record "Business Skill";
        Imported: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        Management: Codeunit "Business Skill Management";
        Port: Codeunit "Business Skill Port";
        Xml: Text;
    begin
        // [GIVEN] An exportable copy of read-only app content.
        Initialize();
        SourceSkill.Get(Builder.Initialize('SOURCE', 'Title', 'Instructions').SetContentVersion('release').Create());
        Copy.Get(Management.CopySkill(SourceSkill.ID));
        Copy.Version := 'manual-release';
        Management.UpdateSkillRecord(Copy.ID, Copy, SkillText.GetSkillText(Copy));
        Copy.SetRange(ID, Copy.ID);
        Xml := Port.BuildExportXml(Copy);
        Copy.Delete(true);

        // [WHEN] Importing that manual copy.
        Port.ImportFromXml(Xml);

        // [THEN] Import creates a new manual skill with the exported content version.
        Imported.FindLast();
        Assert.AreNotEqual(Copy.ID, Imported.ID, 'Import must allocate a new ID.');
        AssertManualSkillIdentifier(Imported);
        Assert.IsTrue(IsNullGuid(Imported."Owning App ID"), 'Import must not claim exporting-app ownership.');
        Assert.IsFalse(Imported."Read-Only", 'Imported manual content must remain editable.');
        Assert.AreEqual('manual-release', Imported.Version, 'Import is not an instruction edit and must retain Version.');
        Assert.AreEqual(Imported.Status::Active, Imported.Status, 'Import must retain its existing Active-creation contract.');
    end;

    /// <summary>
    /// App-owned content cannot be exported by a mixed skill selection.
    /// </summary>
    [Test]
    procedure MixedExportsRejectAppOwnedSkills()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        Management: Codeunit "Business Skill Management";
        Port: Codeunit "Business Skill Port";
        AppSkillId: BigInteger;
    begin
        // [GIVEN] A mixed selection of app-owned and manual content.
        Initialize();
        AppSkillId := Builder.Initialize('APP', 'App skill', 'Instructions').SetContentLocked(false).SetContentVersion('1').Create();
        Management.CreateSkill('Manual skill', 'Instructions');
        Commit();

        // [WHEN] Exporting the mixed selection or only the app-owned skill.
        asserterror Port.BuildExportXml(Skill);
        Assert.ExpectedError('Only manually owned skills');
        Skill.SetRange(ID, AppSkillId);
        asserterror Port.BuildExportXml(Skill);

        // [THEN] Read-Only false never makes app-owned content portable.
        Assert.ExpectedError('Only manually owned skills');
        Skill.Reset();
        Assert.AreEqual(2, Skill.Count(), 'Failed exports must not delete any skills.');
    end;

    /// <summary>
    /// XML cannot carry an owning app, and preceding manual imports roll back with the invalid row.
    /// </summary>
    [Test]
    procedure AppOwnedXmlRollsBackImport()
    var
        Skill: Record "Business Skill";
        Port: Codeunit "Business Skill Port";
        Xml: Text;
    begin
        // [GIVEN] A document with a manual row followed by a row that names an owning app.
        Initialize();
        Xml := '<BusinessSkill><Skills>' +
            '<Skill><Reference>1</Reference><Title>Manual</Title><SkillText>Instructions</SkillText></Skill>' +
            '<Skill><Reference>2</Reference><Title>App</Title><OwningAppId>' + Format(CreateGuid(), 0, 4) +
            '</OwningAppId><SkillText>Instructions</SkillText></Skill>' +
            '</Skills></BusinessSkill>';
        Commit();

        // [WHEN] Importing the document.
        asserterror Port.ImportFromXml(Xml);

        // [THEN] The complete document rolls back rather than importing a partial catalog.
        Assert.ExpectedError('OwningAppId');
        Assert.IsTrue(Skill.IsEmpty(), 'An owning app element must roll back all preceding skill creation.');
    end;

    /// <summary>
    /// A caller failure after copying rolls back the copy.
    /// </summary>
    [Test]
    procedure CallerFailureRollsBackCopy()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        SourceId: BigInteger;
    begin
        // [GIVEN] A committed protected source.
        Initialize();
        SourceId := Builder.Initialize('SOURCE', 'Title', 'Instructions').SetContentVersion('1').Create();
        Commit();

        // [WHEN] The caller fails after the Ignore-protected copy returns.
        asserterror CopyThenFail(SourceId);

        // [THEN] Only the committed source remains.
        Assert.ExpectedError('Caller rollback');
        Assert.AreEqual(1, Skill.Count(), 'The copy must roll back.');
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
        // [GIVEN] An active protected skill with a known version and owning app.
        Initialize();
        Source.Get(Builder.Initialize('CARD', 'Protected source', 'Original').SetContentVersion('2.4').SetActive(true).Create());
        Commit();
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Source);
        Assert.IsTrue(SkillCard.Title.Editable(), 'Read-only instructions must not disable title editing.');
        Assert.IsTrue(SkillCard.Description.Editable(), 'Read-only instructions must not disable description editing.');
        Assert.IsFalse(SkillCard.SkillTextEditor.SkillText.Editable(), 'Protected instructions must not be editable.');
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
        Assert.IsTrue(CopyCard.SkillTextEditor.SkillText.Editable(), 'Copied instructions must be editable.');
        CopyCard."Read-Only".AssertEquals(false);
        Assert.IsTrue(CopyCard.Export.Enabled(), 'A manual copy must offer export.');
        CopyCard.Version.AssertEquals('v1.0');
        Assert.IsTrue(CopyCard.Version.Editable(), 'Manual copies must allow version edits.');
        CopyCard.Title.SetValue('Edited copy');
        CopyCard.SkillTextEditor.SkillText.SetValue('Changed copy');
        CopyCard.Close();
        SkillCard.Close();

        // [THEN] Only the copy changes, and its first instruction edit advances its version.
        SkillCopy.FindLast();
        Assert.AreEqual('Edited copy', SkillCopy.Title, 'The copied title must persist.');
        Assert.AreEqual('v1.1', SkillCopy.Version, 'The first copy edit must advance its own initial version.');
        Source.Get(Source.ID);
        Assert.AreEqual('Original', SkillText.GetSkillText(Source), 'Editing a copy must not change the source.');
        Assert.AreEqual('2.4', Source.Version, 'Editing a copy must not change the source version.');
    end;

    [ConfirmHandler]
    procedure DeclineCopyActivation(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(Question.Contains('activate it'), 'Only the inactive-copy activation prompt is expected.');
        Reply := false;
    end;

    /// <summary>
    /// History restoration uses the same protection as all other instruction changes.
    /// </summary>
    [Test]
    procedure ReadOnlySkillRejectsHistoryRestoration()
    var
        Skill: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
        Builder: Codeunit "Business Skill Builder";
        TextHistory: Codeunit "Business Skill Text History";
        EarlierEntryNo: Integer;
    begin
        // [GIVEN] A protected skill with an earlier instruction entry.
        Initialize();
        Skill.Get(Builder.Initialize('HISTORY', 'Protected history', 'Current').SetContentVersion('4').Create());
        TextVersion."Skill ID" := Skill.ID;
        TextVersion.SetText('Earlier');
        TextVersion.Insert(true);
        EarlierEntryNo := TextVersion."Entry No.";
        TextVersion.Init();
        TextVersion."Entry No." := 0;
        TextVersion."Skill ID" := Skill.ID;
        TextVersion.SetText('Current');
        TextVersion.Insert(true);
        Commit();

        // [WHEN] An earlier instruction entry is restored.
        asserterror TextHistory.RestoreVersion(EarlierEntryNo);

        // [THEN] Protection retains the current instructions and version.
        Assert.ExpectedError('read-only');
        Skill.Get(Skill.ID);
        Assert.AreEqual('Current', SkillText.GetSkillText(Skill), 'Rejected restoration must not change protected instructions.');
        Assert.AreEqual('4', Skill.Version, 'Rejected restoration must not change the version.');
    end;

    /// <summary>
    /// XML omitting optional metadata receives defaults, not values from the preceding skill.
    /// </summary>
    [Test]
    procedure ManualXmlDefaultsMissingMetadataPerSkill()
    var
        Skill: Record "Business Skill";
        Port: Codeunit "Business Skill Port";
        Xml: Text;
    begin
        // [GIVEN] One manual skill with a version followed by a row without a version.
        Initialize();
        Xml := '<BusinessSkill><Skills>' +
            '<Skill><Reference>1</Reference><Title>First</Title><Version>7</Version><SkillText>First instructions</SkillText></Skill>' +
            '<Skill><Reference>2</Reference><Title>Second</Title><SkillText>Second instructions</SkillText></Skill>' +
            '</Skills></BusinessSkill>';

        // [WHEN] Both rows are imported in the same document.
        Port.ImportFromXml(Xml);

        // [THEN] Present metadata survives while omissions independently default.
        Skill.FindFirst();
        Assert.AreEqual('7', Skill.Version, 'An explicit imported version must persist.');
        AssertManualSkillIdentifier(Skill);
        Skill.FindLast();
        Assert.AreEqual('Second', Skill.Title, 'The row without a version must import.');
        Assert.AreEqual('v1.0', Skill.Version, 'An omitted version must independently default to the initial version.');
        Assert.IsFalse(Skill."Read-Only", 'XML must create editable manual content.');
        AssertManualSkillIdentifier(Skill);
    end;

    /// <summary>
    /// Manual version edits persist through the card without creating instruction history.
    /// </summary>
    [Test]
    procedure ManualCardVersionEditPersistsWithoutTextHistory()
    var
        Skill: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
        Management: Codeunit "Business Skill Management";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [GIVEN] Active manual content with one instruction history entry.
        Initialize();
        Skill.Get(Management.CreateSkill('Manual version', 'Instructions'));
        TextVersion.SetRange("Skill ID", Skill.ID);
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        Assert.IsTrue(SkillCard.Version.Editable(), 'Manual versions must be editable on the card.');

        // [WHEN] Only the version is changed.
        SkillCard.Version.SetValue('release-7');
        SkillCard.Close();

        // [THEN] The value persists independently of instructions and becomes the next edit baseline.
        Skill.Get(Skill.ID);
        Assert.AreEqual('release-7', Skill.Version, 'The optimistic card save must persist version-only changes.');
        Assert.AreEqual('Instructions', SkillText.GetSkillText(Skill), 'A version edit must not change instructions.');
        Assert.AreEqual(1, TextVersion.Count(), 'A version edit must not append instruction history.');
        TextVersion.FindFirst();
        Assert.AreEqual('v1.0', TextVersion.Version, 'Changing the current version must not rewrite the historical version.');
        Management.SetSkillText(Skill.ID, 'Changed instructions');
        Skill.Get(Skill.ID);
        Assert.AreEqual('release-8', Skill.Version, 'Instruction edits must advance the manually selected version.');
        TextVersion.FindLast();
        Assert.AreEqual('release-8', TextVersion.Version, 'History must capture the automatically advanced version.');
    end;

    /// <summary>
    /// Explicit manual versions survive an atomic save together with changed instructions.
    /// </summary>
    [Test]
    procedure ManualVersionAndTextSaveRetainsExplicitVersion()
    var
        Skill: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
        Management: Codeunit "Business Skill Management";
    begin
        // [GIVEN] A current manual skill snapshot.
        Initialize();
        Skill.Get(Management.CreateSkill('Combined edit', 'Original instructions'));
        Skill.Version := 'custom-release';

        // [WHEN] Explicit version and instruction changes are saved atomically.
        Management.UpdateSkillRecord(Skill.ID, Skill, 'Changed instructions');

        // [THEN] The explicit version wins without losing the instruction history.
        Skill.Get(Skill.ID);
        Assert.AreEqual('custom-release', Skill.Version, 'An explicit manual version must not be discarded by automatic incrementing.');
        Assert.AreEqual('Changed instructions', SkillText.GetSkillText(Skill), 'The instruction edit must also persist.');
        TextVersion.SetRange("Skill ID", Skill.ID);
        Assert.AreEqual(2, TextVersion.Count(), 'A real instruction change must append exactly one history row.');
        TextVersion.FindFirst();
        Assert.AreEqual('v1.0', TextVersion.Version, 'The original history entry must retain its original version.');
        TextVersion.FindLast();
        Assert.AreEqual('custom-release', TextVersion.Version, 'History must capture the explicit version saved with the instructions.');
    end;

    /// <summary>
    /// Editable app-owned content gets its versions from the app and cannot edit them directly.
    /// </summary>
    [Test]
    procedure AppOwnedVersionsAreSuppliedByApp()
    var
        Skill: Record "Business Skill";
        TextVersion: Record "Business Skill Text Version";
        Builder: Codeunit "Business Skill Builder";
        Management: Codeunit "Business Skill Management";
        SkillCard: TestPage "Business Skill Card";
    begin
        // [GIVEN] App-owned content that permits instruction edits.
        Initialize();
        Skill.Get(Builder.Initialize('APP-VERSION', 'App version', 'Original')
            .SetContentLocked(false).SetActive(true).SetContentVersion('1.0').Create());
        TextVersion.SetRange("Skill ID", Skill.ID);
        TextVersion.FindFirst();
        Assert.AreEqual('1.0', TextVersion.Version, 'Initial app-owned history must capture the builder version.');
        SkillCard.OpenEdit();
        SkillCard.GoToRecord(Skill);
        Assert.IsFalse(SkillCard.Version.Editable(), 'Editable app content must still have a protected version field.');
        Assert.IsFalse(SkillCard.SkillTextEditor.SkillText.Editable(), 'The native editor cannot supply an app-owned instruction version.');
        SkillCard.Close();
        Commit();

        // [WHEN] Directly overriding the app-owned version through management.
        Skill.Get(Skill.ID);
        Skill.Version := 'manual-release';
        asserterror Management.UpdateSkillRecord(Skill.ID, Skill, SkillText.GetSkillText(Skill));

        // [THEN] Direct edits fail, while text changes with a version from the app persist.
        Assert.ExpectedError('Only manually owned skills can change the version directly.');
        Skill.Get(Skill.ID);
        Assert.AreEqual('1.0', Skill.Version, 'Rejected overrides must leave the app version unchanged.');
        Management.SetSkillText(Skill.ID, 'Updated', '1.1');
        Skill.Get(Skill.ID);
        Assert.AreEqual('1.1', Skill.Version, 'The version supplied by the app must persist.');
        TextVersion.FindLast();
        Assert.AreEqual('1.1', TextVersion.Version, 'App-owned history must capture the version supplied by the app.');
    end;

    local procedure AssertManualSkillIdentifier(Skill: Record "Business Skill")
    begin
        Assert.IsTrue(Skill.Manual, 'The creation path must explicitly mark a manual skill.');
        Assert.AreEqual(Format(Skill.ID, 0, '<Integer,20><Filler Character,0>'), Skill."Skill ID", 'Manual identifiers must equal the numeric record ID padded to 20 digits.');
        Assert.IsTrue(IsNullGuid(Skill."Owning App ID"), 'Manual skills must have no owning app.');
        Assert.AreEqual('', Skill."Owning App Publisher", 'Manual skills must have no owning publisher.');
    end;

    local procedure CopyThenFail(SourceId: BigInteger)
    var
        Management: Codeunit "Business Skill Management";
    begin
        Management.CopySkill(SourceId);
        Error(CallerRollbackErr);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure CreateThenFail()
    var
        Builder: Codeunit "Business Skill Builder";
    begin
        Builder.Initialize('TEST', 'Title', 'Instructions').SetContentVersion('1').Create();
        Error(CallerRollbackErr);
    end;

    local procedure Initialize()
    begin
        LibraryBusinessSkill.CleanAll();
        // Expected errors must not roll back the cleanup to a previous test's fixture.
        Commit();
    end;

    var
        Assert: Codeunit "Library Assert";
        LibraryBusinessSkill: Codeunit "Library - Business Skill";
        SkillText: Codeunit "Business Skill Text";
        CallerRollbackErr: Label 'Caller rollback', Locked = true;
}
