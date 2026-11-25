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

    trigger OnRun()
    begin
        // [FEATURE] [Business Skills] [Builder]
    end;

    // TODO: Restore PublicContentUpdateUsesCallingAppIdentity, ReadOnlySkillAllowsOwnerContentChangesAndUnlock,
    // and UpsertRejectsVersionOnlyAndAllowsOwnerUnlock after uptake of the native owner-lock policy fix.
    // Restore from commit 7b6ed794dd, preserving all behavioral assertions.

    /// <summary>
    /// Creation allocates an inactive read-only skill owned by the calling app.
    /// </summary>
    [Test]
    procedure CreateDefaultsToInactive()
    var
        Skill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        Builder: Codeunit "Business Skill Builder";
        History: Codeunit "Business Skill Content History";
        CurrentModule: ModuleInfo;
        SkillId: BigInteger;
    begin
        // [SCENARIO] Creation allocates an inactive read-only skill owned by the calling app.
        // [GIVEN] A fresh builder with overridden content and an explicit version.
        Initialize();
        Builder.Initialize('TEST', 'Initial title', SecretStrSubstNo('Initial instructions'))
            .SetDisplayName('New skill')
            .SetDescription('Search description')
            .SetContent(SecretStrSubstNo('Instructions'))
            .SetContentVersion('v1');
        Assert.IsTrue(Skill.IsEmpty(), 'Initialization must not persist a skill.');

        // [WHEN] Creating the skill.
        SkillId := Builder.Create();

        // [THEN] Content changes persist with the builder defaults.
        Skill.Get(SkillId);
        Assert.AreEqual(Skill.Status::Inactive, Skill.Status, 'The default must be inactive.');
        Assert.AreEqual('New skill', Skill.Title, 'The title override must persist.');
        Assert.AreEqual('Search description', Skill.Description, 'Description must persist.');
        AssertContentEquals(SecretStrSubstNo('Instructions'), BusinessSkillImpl.GetContent(Skill), 'Instructions must persist.');
        NavApp.GetCurrentModuleInfo(CurrentModule);
        Assert.AreEqual(CurrentModule.Id, Skill."Owning App ID", 'Ownership must be the calling test app, not the skill implementation app.');
        Assert.AreEqual('TEST', Skill."Skill ID", 'The explicit skill ID must persist.');
        Assert.AreEqual('v1', Skill.Version, 'The version supplied by the app must persist.');
        Assert.IsTrue(Skill."Read-Only", 'The builder must default to read-only.');
        Assert.IsTrue(BusinessSkillImpl.IsSkillAvailableForCurrentCompany(SkillId), 'The skill must apply to the current company.');
        History.RecordContentVersion(Skill);
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'Neither creation nor explicit history capture may record app-owned history.');
    end;

    /// <summary>
    /// Deletion denied by an installed owning app identifies the extension and the available alternatives.
    /// </summary>
    [Test]
    procedure InstalledOwnerDeletionExplainsRestriction()
    var
        Skill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        BusinessSkill: Codeunit "Business Skill";
        OwningModule: ModuleInfo;
        LibraryAppId: Guid;
        DeleteError: Text;
        ExpectedDeleteErrorLbl: Label 'You cannot delete this skill because its owning extension, ''%1'', is still installed. Uninstall the extension to delete the skill, or deactivate the skill to stop it being used.', Locked = true;
    begin
        // [SCENARIO] Deletion denied by an installed owning app identifies the extension and the available alternatives.
        // [GIVEN] A skill owned by the installed test library, not the calling test app.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateAppOwnedSkill('FOREIGN-OWNER', 'Foreign skill', SecretStrSubstNo('Instructions')));
        Evaluate(LibraryAppId, 'bebde88d-6846-479d-8b30-b9f8940fdcf8');
        Assert.AreEqual(LibraryAppId, Skill."Owning App ID", 'The internal helper must retain the test library as owner, not System Application or the calling test app.');
        NavApp.GetModuleInfo(Skill."Owning App ID", OwningModule);
        Commit();

        // [WHEN] Checking deletion from a different app.
        Assert.IsFalse(BusinessSkillImpl.CanDeleteSkill(Skill, DeleteError), 'Only the installed owning app may delete its skill.');
        asserterror BusinessSkill.Delete(Skill.ID);
        Assert.ExpectedError(StrSubstNo(ExpectedDeleteErrorLbl, OwningModule.Name));

        // [THEN] The denial names the extension and explains uninstalling or deactivating.
        Assert.AreEqual(
            StrSubstNo(ExpectedDeleteErrorLbl, OwningModule.Name),
            DeleteError, 'An installed owner must not be reported as a missing user permission.');
        Assert.IsFalse(BusinessSkillImpl.CanDeleteSkill(Skill), 'Both permission-check overloads must reject the same caller.');
        Assert.IsTrue(Skill.Get(Skill.ID), 'A foreign caller must not delete the skill through the public facade.');
        BusSkillContentVersion.SetRange("Skill ID", Skill.ID);
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'Rejected app-owned deletion must not create history.');
    end;

    /// <summary>
    /// The public facade preserves the calling app identity when deleting its skill without history.
    /// </summary>
    [Test]
    procedure PublicFacadeDeletesCallingAppsSkill()
    var
        Skill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        Builder: Codeunit "Business Skill Builder";
        BusinessSkill: Codeunit "Business Skill";
        CurrentModule: ModuleInfo;
        SkillId: BigInteger;
    begin
        // [SCENARIO] The public facade preserves the calling app identity when deleting its skill without history.
        // [GIVEN] An inactive skill owned by the calling test app.
        Initialize();
        SkillId := Builder.Initialize('OWNER-DELETE', 'Owned skill', SecretStrSubstNo('Instructions')).Create();
        Skill.Get(SkillId);
        NavApp.GetCurrentModuleInfo(CurrentModule);
        Assert.AreEqual(CurrentModule.Id, Skill."Owning App ID", 'The builder must retain the calling app identity.');
        BusSkillContentVersion.SetRange("Skill ID", SkillId);
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'App-owned creation must not record history.');

        // [WHEN] The owning app deletes through the public facade.
        BusinessSkill.Delete(SkillId);

        // [THEN] The additional implementation frame does not replace the caller.
        Assert.IsFalse(Skill.Get(SkillId), 'The owning app must be able to delete its skill.');
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'The deleted skill must have no remaining history.');
    end;

    /// <summary>
    /// Metadata updates select the calling app's skill and preserve its definition, history and lifecycle state.
    /// </summary>
    [Test]
    procedure MetadataUpdatePreservesContentAndCallerIdentity()
    var
        Skill: Record "Business Skill";
        OriginalSkill: Record "Business Skill";
        ForeignSkill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        Builder: Codeunit "Business Skill Builder";
        BusinessSkill: Codeunit "Business Skill";
        Revision: BigInteger;
        ForeignRevision: BigInteger;
    begin
        // [SCENARIO] Metadata updates select the calling app's skill and preserve its definition, history and lifecycle state.
        // [GIVEN] Locked inactive skills with the same code owned by different apps.
        Initialize();
        Skill.Get(Builder.Initialize('METADATA', 'Original title', SecretStrSubstNo('Instructions')).SetDescription('Original description').Create());
        OriginalSkill := Skill;
        ForeignSkill.Get(LibraryBusinessSkill.CreateAppOwnedSkill('METADATA', 'Foreign title', SecretStrSubstNo('Foreign instructions')));
        ForeignRevision := ForeignSkill.SystemRowVersion;

        // [WHEN] The calling app changes its display name and clears its description.
        BusinessSkill.UpdateMetadata('METADATA', 'Updated title', '');

        // [THEN] Only metadata changes, including on locked inactive skills.
        Skill.Get(Skill.ID);
        Assert.AreEqual('Updated title', Skill.Title, 'The display name must be updated.');
        Assert.AreEqual('', Skill.Description, 'An empty description must clear the saved value.');
        Assert.AreEqual(OriginalSkill.SystemId, Skill.SystemId, 'Metadata must preserve the system identity.');
        Assert.AreEqual(OriginalSkill."Owning App ID", Skill."Owning App ID", 'Metadata must preserve the owning app.');
        Assert.AreEqual(OriginalSkill.Version, Skill.Version, 'Metadata must preserve the content version.');
        Assert.AreEqual(OriginalSkill.Status, Skill.Status, 'Metadata must not activate the skill.');
        Assert.IsTrue(Skill."Read-Only", 'Metadata must preserve the content lock.');
        AssertContentEquals(SecretStrSubstNo('Instructions'), BusinessSkill.GetContent(Skill), 'Metadata must preserve content.');
        BusSkillContentVersion.SetRange("Skill ID", Skill.ID);
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'App-owned metadata must not create content history.');
        ForeignSkill.Get(ForeignSkill.ID);
        Assert.AreEqual(ForeignRevision, ForeignSkill.SystemRowVersion, 'A matching code in another app must not be modified.');

        Revision := Skill.SystemRowVersion;
        BusinessSkill.UpdateMetadata('METADATA', 'Updated title', '');
        Skill.Get(Skill.ID);
        Assert.AreEqual(Revision, Skill.SystemRowVersion, 'Identical metadata must not write.');
    end;

    /// <summary>
    /// Metadata updates reject missing, foreign and manual targets and cannot invalidate an active skill.
    /// </summary>
    [Test]
    procedure MetadataUpdateRejectsInvalidTargets()
    var
        Skill: Record "Business Skill";
        ManualSkill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        BusinessSkill: Codeunit "Business Skill";
        Revision: BigInteger;
    begin
        // [SCENARIO] Metadata updates reject missing, foreign and manual targets and cannot invalidate an active skill.
        // [GIVEN] An active owned skill, a foreign skill and a manual skill.
        Initialize();
        Skill.Get(Builder.Initialize('ACTIVE-METADATA', 'Active title', SecretStrSubstNo('Instructions')).SetActive(true).Create());
        Revision := Skill.SystemRowVersion;
        LibraryBusinessSkill.CreateAppOwnedSkill('FOREIGN-METADATA', 'Foreign title', SecretStrSubstNo('Foreign instructions'));
        ManualSkill.Get(LibraryBusinessSkill.CreateSkill('Manual title', SecretStrSubstNo('Manual instructions')));
        Commit();

        // [WHEN] The caller selects an unavailable target or supplies a blank active title.
        asserterror BusinessSkill.UpdateMetadata('MISSING-METADATA', 'Changed', '');
        Assert.ExpectedError('was not found among the calling app');
        asserterror BusinessSkill.UpdateMetadata('FOREIGN-METADATA', 'Changed', '');
        Assert.ExpectedError('was not found among the calling app');
        asserterror BusinessSkill.UpdateMetadata(ManualSkill."Skill ID", 'Changed', '');
        Assert.ExpectedError('was not found among the calling app');
        asserterror BusinessSkill.UpdateMetadata('ACTIVE-METADATA', '   ', 'Changed');
        Assert.ExpectedError('An active skill needs a title and skill content');

        // [THEN] Rejection preserves the active skill and its revision.
        Skill.Get(Skill.ID);
        Assert.AreEqual('Active title', Skill.Title, 'Invalid metadata must not be saved.');
        Assert.AreEqual(Revision, Skill.SystemRowVersion, 'Rejected updates must not write.');
    end;

    /// <summary>
    /// The installed owning app can still delete its skill and receives no stale denial message.
    /// </summary>
    [Test]
    procedure OwningAppDeletionHasNoRestriction()
    var
        TempSkill: Record "Business Skill" temporary;
        CurrentModule: ModuleInfo;
        DeleteError: Text;
    begin
        // [SCENARIO] The installed owning app can still delete its skill and receives no stale denial message.
        // [GIVEN] A skill owned by the calling test app and a previous denial message.
        NavApp.GetCurrentModuleInfo(CurrentModule);
        TempSkill."Owning App ID" := CurrentModule.Id;
        DeleteError := 'Previous denial';

        // [WHEN] The owning app checks deletion.
        Assert.IsTrue(BusinessSkillImpl.CanDeleteSkill(TempSkill, DeleteError), 'The installed owning app must retain deletion access.');

        // [THEN] No error is returned for the permitted operation.
        Assert.AreEqual('', DeleteError, 'An allowed deletion must clear the previous denial.');
        Assert.IsTrue(BusinessSkillImpl.CanDeleteSkill(TempSkill), 'Both permission-check overloads must allow the owning app.');
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
        // [SCENARIO] Uninitialized and consumed builders fail explicitly and can be reused only after Clear.
        // [GIVEN] An uninitialized builder.
        Initialize();
        asserterror Builder.Create();
        Assert.ExpectedError('Initialize');
        asserterror Builder.SetDisplayName('Title');
        Assert.ExpectedError('Initialize');

        // [WHEN] Initializing and consuming the builder.
        Builder.Initialize('FIRST', 'Title', SecretStrSubstNo('Instructions')).SetContentVersion('1');
        asserterror Builder.Initialize('OTHER', 'Other title', SecretStrSubstNo('Other instructions'));
        Assert.ExpectedError('only one skill');
        Builder.Create();
        Commit();

        // [THEN] Neither mutation nor another creation is allowed after success.
        asserterror Builder.Create();
        Assert.ExpectedError('only one skill');
        asserterror Builder.SetActive(true);
        Assert.ExpectedError('only one skill');
        Clear(Builder);
        Builder.Initialize('SECOND', 'Second title', SecretStrSubstNo('Instructions')).SetContentVersion('1').Create();
        Assert.AreEqual(2, Skill.Count(), 'Clear permits an independent creation.');
    end;

    /// <summary>
    /// App-owned skills default an omitted creation version to v1.0.
    /// </summary>
    [Test]
    procedure CreateDefaultsMissingVersion()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
    begin
        // [SCENARIO] App-owned skills default an omitted creation version to v1.0.
        // [GIVEN] A builder without a version.
        Initialize();
        Builder.Initialize('TEST', 'Title', SecretStrSubstNo('Instructions'));
        // [WHEN] Creating the skill.
        Skill.Get(Builder.Create());

        // [THEN] Creation supplies the default without changing app ownership.
        Assert.AreEqual('v1.0', Skill.Version, 'An omitted version must default on creation.');
        Assert.IsFalse(Skill.Manual, 'Defaulting the version must not make the skill manual.');
    end;

    /// <summary>
    /// Manual builders create generated identities and reuse saved skills by code or numeric ID.
    /// </summary>
    [Test]
    procedure ManualBuilderCreatesAndUpdatesSavedIdentity()
    var
        Skill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        Builder: Codeunit "Business Skill Builder";
        BuilderImpl: Codeunit "Business Skill Builder Impl.";
        SkillId: BigInteger;
        SystemId: Guid;
    begin
        // [SCENARIO] Manual builders create generated identities and reuse saved skills by code or numeric ID.
        // [GIVEN] A new manual skill with no caller-supplied code.
        Initialize();
        SkillId := Builder.Initialize('', 'Manual skill', SecretStrSubstNo('First')).SetManual(true).Create();
        Skill.Get(SkillId);
        SystemId := Skill.SystemId;
        AssertManualSkillIdentifier(Skill);
        Assert.IsTrue(Skill.Manual, 'The builder must create a manual skill.');
        Assert.IsTrue(IsNullGuid(Skill."Owning App ID"), 'Manual skills must have no owning app.');
        Assert.AreEqual('', Skill."Owning App Publisher", 'Manual skills must have no owning publisher.');
        Assert.IsFalse(Skill."Read-Only", 'Manual content must default to unlocked.');
        Assert.AreEqual(Skill.Status::Inactive, Skill.Status, 'Manual creation must default to inactive.');

        // [WHEN] Updating the saved manual code, then selecting the same row by numeric ID.
        BuilderImpl.Initialize(Skill."Owning App ID", Skill."Skill ID", 'Updated skill', SecretStrSubstNo('Second'));
        BuilderImpl.SetManual(true);
        Assert.AreEqual(SkillId, BuilderImpl.CreateOrUpdate(), 'A saved manual code must resolve the existing row.');
        Clear(BuilderImpl);
        BuilderImpl.Initialize(Skill."Owning App ID", '', 'Updated skill', SecretStrSubstNo('Second'));
        BuilderImpl.SetManual(true);
        BuilderImpl.SetActive(true);
        Assert.AreEqual(SkillId, BuilderImpl.CreateOrUpdate(SkillId), 'An ID selector must resolve the same row.');

        // [THEN] Identity is stable and only changed content adds history and advances the manual version.
        Skill.Get(SkillId);
        Assert.AreEqual(SystemId, Skill.SystemId, 'Updates must preserve the system identity.');
        Assert.AreEqual('v1.1', Skill.Version, 'Changed manual content must advance the default version.');
        AssertContentEquals(SecretStrSubstNo('Second'), BusinessSkillImpl.GetContent(Skill), 'The updated content must persist.');
        Assert.AreEqual(Skill.Status::Active, Skill.Status, 'Explicit activation must be honored.');
        BusSkillContentVersion.SetRange("Skill ID", SkillId);
        Assert.AreEqual(2, BusSkillContentVersion.Count(), 'Only changed content must add history.');
    end;

    /// <summary>
    /// A missing saved selector cannot silently create a different manual identity.
    /// </summary>
    [Test]
    procedure MissingManualTargetsDoNotCreateSkills()
    var
        Skill: Record "Business Skill";
        BuilderImpl: Codeunit "Business Skill Builder Impl.";
    begin
        // [SCENARIO] A missing saved selector cannot silently create a different manual identity.
        // [GIVEN] An empty catalog and a builder targeting a saved manual code.
        Initialize();
        BuilderImpl.Initialize(Skill."Owning App ID", 'MISSING', 'Manual skill', SecretStrSubstNo('Instructions'));
        BuilderImpl.SetManual(true);

        // [WHEN] Looking up nonexistent saved identities.
        asserterror BuilderImpl.CreateOrUpdate();
        Assert.ExpectedError('manual skill was not found');
        Clear(BuilderImpl);
        BuilderImpl.Initialize(Skill."Owning App ID", '', 'Manual skill', SecretStrSubstNo('Instructions'));
        BuilderImpl.SetManual(true);
        asserterror BuilderImpl.CreateOrUpdate(-1);
        Assert.ExpectedError('does not exist');

        // [THEN] Neither selector allocates a different identity.
        Assert.IsTrue(Skill.IsEmpty(), 'A missing saved selector must not create a new skill.');
    end;

    /// <summary>
    /// A zero numeric selector creates a manual skill with generated identity and initial history.
    /// </summary>
    [Test]
    procedure ZeroIdCreatesManualSkill()
    var
        Skill: Record "Business Skill";
        Version: Record "Bus Skill Content Version";
        BuilderImpl: Codeunit "Business Skill Builder Impl.";
        SkillId: BigInteger;
    begin
        // [SCENARIO] A zero numeric selector creates a manual skill with generated identity and initial history.
        Initialize();
        BuilderImpl.Initialize(Skill."Owning App ID", '', 'New manual skill', SecretStrSubstNo('Instructions'));
        BuilderImpl.SetManual(true);

        SkillId := BuilderImpl.CreateOrUpdate(0);

        Assert.AreNotEqual(0, SkillId, 'Creation must return the generated numeric ID.');
        Skill.Get(SkillId);
        AssertManualSkillIdentifier(Skill);
        AssertContentEquals(SecretStrSubstNo('Instructions'), BusinessSkillImpl.GetContent(Skill), 'Creation must persist content.');
        Version.SetRange("Skill ID", SkillId);
        Assert.AreEqual(1, Version.Count(), 'Manual creation must record initial history.');
        Commit();
        asserterror BuilderImpl.CreateOrUpdate(0);
        Assert.ExpectedError('only one skill');
        Assert.AreEqual(1, Skill.Count(), 'A consumed builder must not create another skill.');
    end;

    /// <summary>
    /// A zero numeric selector creates app-owned content, never updating an existing code.
    /// </summary>
    [Test]
    procedure ZeroIdCreatesAppOwnedSkillInsteadOfUpserting()
    var
        Skill: Record "Business Skill";
        Version: Record "Bus Skill Content Version";
        BuilderImpl: Codeunit "Business Skill Builder Impl.";
        CurrentModule: ModuleInfo;
        SkillId: BigInteger;
    begin
        // [SCENARIO] A zero numeric selector creates app-owned content, never updating an existing code.
        Initialize();
        NavApp.GetCurrentModuleInfo(CurrentModule);
        BuilderImpl.Initialize(CurrentModule.Id, 'ZERO-ID', 'Original title', SecretStrSubstNo('Original'));

        SkillId := BuilderImpl.CreateOrUpdate(0);

        Skill.Get(SkillId);
        Assert.IsFalse(Skill.Manual, 'Creation must preserve app ownership.');
        Assert.AreEqual(CurrentModule.Id, Skill."Owning App ID", 'Creation must retain the calling app.');
        Assert.IsTrue(Version.IsEmpty(), 'App-owned creation must not record history.');
        Commit();
        Clear(BuilderImpl);
        BuilderImpl.Initialize(CurrentModule.Id, 'ZERO-ID', 'Changed title', SecretStrSubstNo('Original'));
        asserterror BuilderImpl.CreateOrUpdate(0);
        Assert.ExpectedError('already exists');
        Skill.Get(SkillId);
        Assert.AreEqual('Original title', Skill.Title, 'A zero selector must not upsert an existing code.');
        Assert.AreEqual(1, Skill.Count(), 'Duplicate creation must not add another skill.');
        asserterror BuilderImpl.CreateOrUpdate(-1);
        Assert.ExpectedError('does not exist');
    end;

    /// <summary>
    /// Manual creation rejects caller-supplied codes and explicitly locked content.
    /// </summary>
    [Test]
    procedure ManualBuilderRejectsInvalidCreation()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
    begin
        // [SCENARIO] Manual creation rejects caller-supplied codes and explicitly locked content.
        // [GIVEN] A manual builder with a code that only the platform may generate.
        Initialize();
        Builder.Initialize('SUPPLIED', 'Manual skill', SecretStrSubstNo('Instructions')).SetManual(true);

        // [WHEN] Creating with an explicit code or locked content.
        asserterror Builder.Create();
        Assert.ExpectedError('Skill ID');
        Clear(Builder);
        Builder.Initialize('', 'Manual skill', SecretStrSubstNo('Instructions')).SetManual(true).SetContentLocked(true);
        asserterror Builder.Create();
        Assert.ExpectedError('cannot be read-only');

        // [THEN] Invalid creation leaves the catalog empty.
        Assert.IsTrue(Skill.IsEmpty(), 'Invalid manual creation must not persist a skill.');
    end;

    /// <summary>
    /// Omitted optional setters preserve saved values, while explicit empty and false values are applied.
    /// </summary>
    [Test]
    procedure UpsertAppliesOnlySuppliedProperties()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        BuilderImpl: Codeunit "Business Skill Builder Impl.";
        SkillId: BigInteger;
        OriginalRevision: BigInteger;
    begin
        // [SCENARIO] Omitted optional setters preserve saved values, while explicit empty and false values are applied.
        // [GIVEN] An active unlocked skill with optional metadata.
        Initialize();
        SkillId := Builder.Initialize('OPTIONAL', 'Title', SecretStrSubstNo('Instructions')).SetDescription('Description')
            .SetContentLocked(false).SetContentVersion('release-1').SetActive(true).Create();
        Skill.Get(SkillId);
        OriginalRevision := Skill.SystemRowVersion;

        // [WHEN] Reapplying only the required values.
        BuilderImpl.Initialize(Skill."Owning App ID", 'OPTIONAL', 'Title', SecretStrSubstNo('Instructions'));
        BuilderImpl.CreateOrUpdate();

        // [THEN] Omitted defaults do not change the stored record or its revision.
        Skill.Get(SkillId);
        Assert.AreEqual(OriginalRevision, Skill.SystemRowVersion, 'An identical upsert must not write.');
        Assert.AreEqual('Description', Skill.Description, 'Omitted description must be preserved.');
        Assert.AreEqual('release-1', Skill.Version, 'Omitted version must be preserved.');
        Assert.IsFalse(Skill."Read-Only", 'Omitted lock must be preserved.');
        Assert.AreEqual(Skill.Status::Active, Skill.Status, 'Omitted status must be preserved.');
        Clear(BuilderImpl);
        BuilderImpl.Initialize(Skill."Owning App ID", 'OPTIONAL', 'Title', SecretStrSubstNo('Instructions'));
        BuilderImpl.SetDescription('');
        BuilderImpl.SetActive(false);
        BuilderImpl.CreateOrUpdate();
        Skill.Get(SkillId);
        Assert.AreEqual('', Skill.Description, 'An explicit empty description must be applied.');
        Assert.AreEqual(Skill.Status::Inactive, Skill.Status, 'An explicit false status must be applied.');
        Clear(BuilderImpl);
        BuilderImpl.Initialize(Skill."Owning App ID", 'OPTIONAL', 'New title', SecretStrSubstNo('Instructions'));
        BuilderImpl.CreateOrUpdate();
        Skill.Get(SkillId);
        Assert.AreEqual(Skill.Status::Inactive, Skill.Status, 'An omitted status must not reactivate an existing skill.');
    end;

    /// <summary>
    /// Metadata-only upserts preserve the version, while changed instructions require an explicit new version.
    /// </summary>
    [Test]
    procedure UpsertSeparatesMetadataAndInstructionVersions()
    var
        Skill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        Builder: Codeunit "Business Skill Builder";
        BuilderImpl: Codeunit "Business Skill Builder Impl.";
        SkillId: BigInteger;
    begin
        // [SCENARIO] Metadata-only upserts preserve the version, while changed instructions require an explicit new version.
        // [GIVEN] An app-owned editable skill with an explicit release version.
        Initialize();
        SkillId := Builder.Initialize('UPSERT', 'Original title', SecretStrSubstNo('Original instructions'))
            .SetContentLocked(false).SetContentVersion('release-1').Create();
        Skill.Get(SkillId);

        // [WHEN] Metadata changes without supplying a version.
        BuilderImpl.Initialize(Skill."Owning App ID", 'UPSERT', 'Updated title', SecretStrSubstNo('Original instructions'));
        BuilderImpl.SetDescription('Updated description');
        BuilderImpl.SetContentLocked(false);
        Assert.AreEqual(SkillId, BuilderImpl.CreateOrUpdate(), 'An upsert must retain the existing identity.');

        // [THEN] Metadata changes without resetting the version or appending history.
        Skill.Get(SkillId);
        Assert.AreEqual('Updated title', Skill.Title, 'The title must be updated.');
        Assert.AreEqual('Updated description', Skill.Description, 'The description must be updated.');
        Assert.AreEqual('release-1', Skill.Version, 'Metadata must not default or replace an existing version.');
        BusSkillContentVersion.SetRange("Skill ID", SkillId);
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'App-owned metadata must not create history.');
        Commit();
        Clear(BuilderImpl);

        // [WHEN] Instructions change without a version.
        BuilderImpl.Initialize(Skill."Owning App ID", 'UPSERT', 'Updated title', SecretStrSubstNo('Changed instructions'));
        BuilderImpl.SetContentLocked(false);
        asserterror BuilderImpl.CreateOrUpdate();

        // [THEN] The intended validation fails without changing instructions or history.
        Assert.ExpectedError('Set a new version of the skill before changing its instructions.');
        Skill.Get(SkillId);
        AssertContentEquals(SecretStrSubstNo('Original instructions'), BusinessSkillImpl.GetContent(Skill), 'Rejected instructions must not persist.');
        Assert.AreEqual('release-1', Skill.Version, 'Rejected instructions must not change the version.');
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'Rejected app-owned instructions must not create history.');
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
        // [SCENARIO] App-owned identifiers do not use a reserved manual prefix.
        // [GIVEN] An app-owned skill whose identifier starts with M-.
        Initialize();
        Builder.Initialize('M-1', 'Title', SecretStrSubstNo('Instructions')).SetContentVersion('1');
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
        // [SCENARIO] Active content validation rejects incomplete instructions without creating a skill.
        // [GIVEN] An active skill without instructions.
        Initialize();
        Builder.Initialize('TEST', 'Title', SecretStrSubstNo('')).SetContentVersion('1').SetActive(true);
        Commit();

        // [WHEN] Creating invalid active content.
        asserterror Builder.Create();

        // [THEN] Governed content validation rejects the operation before any creation.
        Assert.ExpectedError('An active skill needs a title and skill content.');
        Assert.IsTrue(Skill.IsEmpty(), 'Invalid active content must not create a skill.');
    end;

    /// <summary>
    /// Creation does not commit the caller's transaction.
    /// </summary>
    [Test]
    procedure CallerFailureRollsBackSkill()
    var
        Skill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
    begin
        // [SCENARIO] Creation does not commit the caller's transaction.
        // [GIVEN] An empty committed fixture.
        Initialize();
        Commit();

        // [WHEN] The caller fails after successful creation.
        asserterror CreateThenFail();

        // [THEN] The skill and its history remain part of the caller's transaction.
        Assert.ExpectedError('Caller rollback');
        Assert.IsTrue(Skill.IsEmpty(), 'The skill must roll back.');
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'The content history must roll back.');
    end;

    /// <summary>
    /// Content protection does not restrict activation or deactivation.
    /// </summary>
    [Test]
    procedure ReadOnlySkillAllowsLifecycle()
    var
        Skill: Record "Business Skill";
        Builder: Codeunit "Business Skill Builder";
        SkillId: BigInteger;
    begin
        // [SCENARIO] Content protection does not restrict activation or deactivation.
        // [GIVEN] An inactive read-only skill.
        Initialize();
        SkillId := Builder.Initialize('LOCKED', 'Title', SecretStrSubstNo('Instructions')).SetContentVersion('1').Create();

        // [WHEN] Changing status without editing content.
        BusinessSkillImpl.ActivateSkill(SkillId);
        BusinessSkillImpl.DeactivateSkill(SkillId);

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
        BusSkillContentVersion: Record "Bus Skill Content Version";
        Builder: Codeunit "Business Skill Builder";
        SkillId: BigInteger;
    begin
        // [SCENARIO] Editable app-owned skills change their text only together with a new version supplied by the app.
        // [GIVEN] Explicitly editable app content with a dotted initial version.
        Initialize();
        SkillId := Builder.Initialize('EDITABLE', 'Title', SecretStrSubstNo('First instructions'))
            .SetContentLocked(false).SetContentVersion('1.0').Create();
        BusSkillContentVersion.SetRange("Skill ID", SkillId);

        // [WHEN] Editing metadata and saving unchanged instructions.
        Skill.Get(SkillId);
        Skill.Description := 'New description';
        BusinessSkillImpl.UpdateSkillRecord(SkillId, Skill, BusinessSkillImpl.GetContent(Skill));
        BusinessSkillImpl.UpdateSkill(SkillId, 'New title', SecretStrSubstNo('First instructions'));
        BusinessSkillImpl.SetContent(SkillId, SecretStrSubstNo('First instructions'));

        // [THEN] Metadata and no-op saves change neither the version nor the history.
        Skill.Get(SkillId);
        Assert.IsFalse(Skill."Read-Only", 'Explicit editable creation must persist.');
        Assert.AreEqual('1.0', Skill.Version, 'Metadata and unchanged instructions must not change Version.');
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'App-owned metadata and no-op saves must not create history.');
        Commit();

        // [WHEN] Instructions change without a new version.
        asserterror BusinessSkillImpl.SetContent(SkillId, SecretStrSubstNo('Second instructions'));

        // [THEN] The app must supply the new version.
        Assert.ExpectedError('Specify a new version');

        // [WHEN] Instructions change together with a new version.
        BusinessSkillImpl.SetContent(SkillId, SecretStrSubstNo('Second instructions'), '1.1');
        Skill.Get(SkillId);
        Assert.AreEqual('1.1', Skill.Version, 'The version supplied by the app must persist.');
        AssertContentEquals(SecretStrSubstNo('Second instructions'), BusinessSkillImpl.GetContent(Skill), 'Changed instructions must persist.');
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'App-owned instruction changes must not create history.');
    end;

    /// <summary>
    /// Versions use the full field length and longer versions are rejected.
    /// </summary>
    [Test]
    procedure VersionFitsTheField()
    var
        Skill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        Builder: Codeunit "Business Skill Builder";
        SkillId: BigInteger;
        InitialVersion: Text[50];
        NextVersion: Text[50];
        OversizedVersion: Text;
    begin
        // [SCENARIO] Versions use the full field length and longer versions are rejected.
        // [GIVEN] An app-owned skill with a version occupying the entire field.
        Initialize();
        InitialVersion := CopyStr(PadStr('release', 50, 'x'), 1, 50);
        SkillId := Builder.Initialize('VERSION', 'Title', SecretStrSubstNo('First')).SetContentLocked(false).SetContentVersion(InitialVersion).Create();
        Skill.Get(SkillId);
        Assert.AreEqual(InitialVersion, Skill.Version, 'A version of the full field length must persist.');

        // [WHEN] The app changes the text with another version of the full field length.
        NextVersion := CopyStr(PadStr('next', 50, 'y'), 1, 50);
        BusinessSkillImpl.SetContent(SkillId, SecretStrSubstNo('Second'), NextVersion);

        // [THEN] The skill keeps the full version without creating app-owned history.
        Skill.Get(SkillId);
        Assert.AreEqual(NextVersion, Skill.Version, 'The new version must persist without truncation.');
        BusSkillContentVersion.SetRange("Skill ID", SkillId);
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'App-owned version changes must not create history.');

        Clear(Builder);
        Skill.Get(Builder.Initialize('', 'Manual version', SecretStrSubstNo('Manual content')).SetManual(true).SetContentVersion(NextVersion).Create());
        BusSkillContentVersion.SetRange("Skill ID", Skill.ID);
        BusSkillContentVersion.FindFirst();
        Assert.AreEqual(NextVersion, BusSkillContentVersion."Content Version", 'Manual history must retain the full version without truncation.');
        Commit();

        // [WHEN] A version exceeds the field length.
        Clear(Builder);
        OversizedVersion := PadStr('', 51, '9');
        Builder.Initialize('OVERSIZED', 'Title', SecretStrSubstNo('First'));

        // [THEN] The builder rejects it.
        asserterror Builder.SetContentVersion(OversizedVersion);
        Assert.ExpectedError('The content version cannot exceed 50 characters.');
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
        // [SCENARIO] The skill ID of an app-owned skill is unique within its owning app.
        // [GIVEN] One app-owned skill under a known skill ID.
        Initialize();
        Builder.Initialize('SHARED', 'Title', SecretStrSubstNo('Instructions')).SetContentVersion('1').Create();
        Commit();

        // [WHEN] Creating the same app/skill ID pair again.
        SecondBuilder.Initialize('SHARED', 'Another title', SecretStrSubstNo('Instructions')).SetContentVersion('1');
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
        SkillIds: List of [BigInteger];
        SkillId: BigInteger;
    begin
        // [SCENARIO] Manual and editable app-owned identities cannot be changed after creation.
        // [GIVEN] A manual skill and an explicitly editable app-owned skill.
        Initialize();
        SkillIds.Add(LibraryBusinessSkill.CreateSkill('Manual identity', SecretStrSubstNo('Instructions')));
        SkillIds.Add(Builder.Initialize('APP-IDENTITY', 'App identity', SecretStrSubstNo('Instructions')).SetContentLocked(false).SetContentVersion('1').Create());
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
            AssertContentEquals(SecretStrSubstNo('Instructions'), BusinessSkillImpl.GetContent(Skill), 'Rejected identity edits must not change instructions.');
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
    begin
        // [SCENARIO] Manual creation derives padded identifiers from record IDs and cannot claim programmatic read-only protection.
        // [GIVEN] No skills.
        Initialize();

        // [WHEN] Creating skills through normal management instead of an app builder.
        FirstSkill.Get(LibraryBusinessSkill.CreateSkill('First', SecretStrSubstNo('Instructions')));
        Skill.Get(LibraryBusinessSkill.CreateSkill('Second', SecretStrSubstNo('Instructions')));

        // [THEN] Skill IDs match their numeric record IDs and protection cannot be enabled on manual content.
        AssertManualSkillIdentifier(FirstSkill);
        AssertManualSkillIdentifier(Skill);
        Assert.AreNotEqual(FirstSkill."Skill ID", Skill."Skill ID", 'Manual skill IDs must be unique.');
        Assert.AreEqual('v1.0', Skill.Version, 'Manual skills must start at the initial version.');
        Assert.IsTrue(IsNullGuid(Skill."Owning App ID"), 'Management creation must remain manually owned.');
        Assert.IsFalse(Skill."Read-Only", 'Manual content is editable.');
        Assert.AreEqual('Created manually', BusinessSkillImpl.GetAppName(Skill."Owning App ID"), 'Manual ownership must have a friendly label.');
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
    begin
        // [SCENARIO] Repeated copies retain content, but start fresh manual versions and independent identities.
        // [GIVEN] Protected app content with explicit version and description.
        Initialize();
        SourceSkill.Get(Builder.Initialize('SOURCE', 'Title', SecretStrSubstNo('Original instructions'))
            .SetContentVersion('2.7').SetDescription('Description').SetActive(true).Create());

        // [WHEN] Copying, editing, and copying the editable copy again.
        FirstCopy.Get(BusinessSkillImpl.CopySkill(SourceSkill.ID));
        Assert.AreEqual('v1.0', FirstCopy.Version, 'A copy must start a new manual version.');
        BusinessSkillImpl.SetContent(FirstCopy.ID, SecretStrSubstNo('Customized instructions'));
        SecondCopy.Get(BusinessSkillImpl.CopySkill(FirstCopy.ID));

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
        AssertContentEquals(SecretStrSubstNo('Customized instructions'), BusinessSkillImpl.GetContent(SecondCopy), 'Copies must retain the current content.');
        SourceSkill.Get(SourceSkill.ID);
        AssertContentEquals(SecretStrSubstNo('Original instructions'), BusinessSkillImpl.GetContent(SourceSkill), 'Copy edits must leave the original unchanged.');
        Assert.AreEqual('2.7', SourceSkill.Version, 'Copy edits must leave the original version unchanged.');
    end;

    /// <summary>
    /// A copy takes current app-owned content even if stale history remains, and starts its own manual history.
    /// </summary>
    [Test]
    procedure CopyUsesLatestContentVersion()
    var
        Copy: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        Builder: Codeunit "Business Skill Builder";
        SourceId: BigInteger;
    begin
        // [SCENARIO] A copy takes current app-owned content even if stale history remains, and starts its own manual history.
        // [GIVEN] App-owned content updated without history, with a stale historical row.
        Initialize();
        SourceId := Builder.Initialize('HISTORY', 'Title', SecretStrSubstNo('First')).SetContentLocked(false).SetContentVersion('1').Create();
        BusinessSkillImpl.SetContent(SourceId, SecretStrSubstNo('Second'), '2');
        Assert.IsTrue(BusSkillContentVersion.IsEmpty(), 'App-owned creation and updates must not create history.');
        BusSkillContentVersion."Skill ID" := SourceId;
        BusSkillContentVersion."Content Version" := '1';
        BusSkillContentVersion.SetContent(SecretStrSubstNo('First'));
        BusSkillContentVersion.Insert(true);

        // [WHEN] Copying the skill.
        Copy.Get(BusinessSkillImpl.CopySkill(SourceId));

        // [THEN] The copy holds the latest content under its own initial version and history.
        AssertContentEquals(SecretStrSubstNo('Second'), BusinessSkillImpl.GetContent(Copy), 'The copy must take the latest content.');
        Assert.AreEqual('v1.0', Copy.Version, 'The copy must start at the initial manual version.');
        BusSkillContentVersion.SetRange("Skill ID", Copy.ID);
        Assert.AreEqual(1, BusSkillContentVersion.Count(), 'The copy must start its own history with one content version.');
        BusSkillContentVersion.FindFirst();
        AssertContentEquals(SecretStrSubstNo('Second'), BusSkillContentVersion.GetContent(), 'The first content version of the copy must hold the latest content.');
        Assert.AreEqual('v1.0', BusSkillContentVersion."Content Version", 'The copy history must use its own initial version.');
    end;

    /// <summary>
    /// Copying manual content preserves instructions without claiming app ownership.
    /// </summary>
    [Test]
    procedure ManualCopyRetainsContentAndManualOwnership()
    var
        Copy: Record "Business Skill";
        SourceId: BigInteger;
    begin
        // [SCENARIO] Copying manual content preserves instructions without claiming app ownership.
        // [GIVEN] Manually created content.
        Initialize();
        SourceId := LibraryBusinessSkill.CreateSkill('Manual title', SecretStrSubstNo('Manual instructions'));

        // [WHEN] Copying it for independent editing.
        Copy.Get(BusinessSkillImpl.CopySkill(SourceId));

        // [THEN] The independent copy retains instructions and remains manually owned.
        Assert.AreNotEqual(SourceId, Copy.ID, 'The copy must have an independent identity.');
        AssertContentEquals(SecretStrSubstNo('Manual instructions'), BusinessSkillImpl.GetContent(Copy), 'Manual instructions must be retained.');
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
        Port: Codeunit "Business Skill Port";
        Xml: SecretText;
    begin
        // [SCENARIO] Manual copies round-trip their version through XML and receive a new identity.
        // [GIVEN] An exportable copy of read-only app content.
        Initialize();
        SourceSkill.Get(Builder.Initialize('SOURCE', 'Title', SecretStrSubstNo('Instructions')).SetContentVersion('release').Create());
        Copy.Get(BusinessSkillImpl.CopySkill(SourceSkill.ID));
        Copy.Version := 'manual-release';
        BusinessSkillImpl.UpdateSkillRecord(Copy.ID, Copy, BusinessSkillImpl.GetContent(Copy));
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
        Port: Codeunit "Business Skill Port";
        AppSkillId: BigInteger;
    begin
        // [SCENARIO] App-owned content cannot be exported by a mixed skill selection.
        // [GIVEN] A mixed selection of app-owned and manual content.
        Initialize();
        AppSkillId := Builder.Initialize('APP', 'App skill', SecretStrSubstNo('Instructions')).SetContentLocked(false).SetContentVersion('1').Create();
        LibraryBusinessSkill.CreateSkill('Manual skill', SecretStrSubstNo('Instructions'));
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
        // [SCENARIO] XML cannot carry an owning app, and preceding manual imports roll back with the invalid row.
        // [GIVEN] A document with a manual row followed by a row that names an owning app.
        Initialize();
        Xml := '<BusinessSkill><Skills>' +
            '<Skill><Reference>1</Reference><Title>Manual</Title><Content>Instructions</Content></Skill>' +
            '<Skill><Reference>2</Reference><Title>App</Title><OwningAppId>' + Format(CreateGuid(), 0, 4) +
            '</OwningAppId><Content>Instructions</Content></Skill>' +
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
        // [SCENARIO] A caller failure after copying rolls back the copy.
        // [GIVEN] A committed protected source.
        Initialize();
        SourceId := Builder.Initialize('SOURCE', 'Title', SecretStrSubstNo('Instructions')).SetContentVersion('1').Create();
        Commit();

        // [WHEN] The caller fails after the Ignore-protected copy returns.
        asserterror CopyThenFail(SourceId);

        // [THEN] Only the committed source remains.
        Assert.ExpectedError('Caller rollback');
        Assert.AreEqual(1, Skill.Count(), 'The copy must roll back.');
    end;

    /// <summary>
    /// App-owned history left by an earlier implementation cannot be restored.
    /// </summary>
    [Test]
    procedure AppOwnedHistoryRestorationIsRejected()
    var
        Skill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
        Builder: Codeunit "Business Skill Builder";
        BusinessSkillContentHistory: Codeunit "Business Skill Content History";
        EarlierEntryNo: Integer;
    begin
        // [SCENARIO] App-owned history left by an earlier implementation cannot be restored.
        // [GIVEN] A protected skill with an earlier instruction entry.
        Initialize();
        Skill.Get(Builder.Initialize('HISTORY', 'Protected history', SecretStrSubstNo('Current')).SetContentVersion('4').Create());
        BusSkillContentVersion."Skill ID" := Skill.ID;
        BusSkillContentVersion.SetContent(SecretStrSubstNo('Earlier'));
        BusSkillContentVersion.Insert(true);
        EarlierEntryNo := BusSkillContentVersion."Entry No.";
        BusSkillContentVersion.Init();
        BusSkillContentVersion."Entry No." := 0;
        BusSkillContentVersion."Skill ID" := Skill.ID;
        BusSkillContentVersion.SetContent(SecretStrSubstNo('Current'));
        BusSkillContentVersion.Insert(true);
        Commit();

        // [WHEN] An earlier instruction entry is restored.
        asserterror BusinessSkillContentHistory.RestoreVersion(EarlierEntryNo);

        // [THEN] The manual-only guard retains the current instructions and version.
        Assert.ExpectedError('Manual must be equal to');
        Skill.Get(Skill.ID);
        AssertContentEquals(SecretStrSubstNo('Current'), BusinessSkillImpl.GetContent(Skill), 'Rejected restoration must not change protected instructions.');
        Assert.AreEqual('4', Skill.Version, 'Rejected restoration must not change the version.');
        BusSkillContentVersion.SetRange("Skill ID", Skill.ID);
        Assert.AreEqual(2, BusSkillContentVersion.Count(), 'Rejection must neither purge nor append historical rows.');
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
        // [SCENARIO] XML omitting optional metadata receives defaults, not values from the preceding skill.
        // [GIVEN] One manual skill with a version followed by a row without a version.
        Initialize();
        Xml := '<BusinessSkill><Skills>' +
            '<Skill><Reference>1</Reference><Title>First</Title><Version>7</Version><Content>First instructions</Content></Skill>' +
            '<Skill><Reference>2</Reference><Title>Second</Title><Content>Second instructions</Content></Skill>' +
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
    /// Explicit manual versions survive an atomic save together with changed instructions.
    /// </summary>
    [Test]
    procedure ManualVersionAndTextSaveRetainsExplicitVersion()
    var
        Skill: Record "Business Skill";
        BusSkillContentVersion: Record "Bus Skill Content Version";
    begin
        // [SCENARIO] Explicit manual versions survive an atomic save together with changed instructions.
        // [GIVEN] A current manual skill snapshot.
        Initialize();
        Skill.Get(LibraryBusinessSkill.CreateSkill('Combined edit', SecretStrSubstNo('Original instructions')));
        Skill.Version := 'custom-release';

        // [WHEN] Explicit version and instruction changes are saved atomically.
        BusinessSkillImpl.UpdateSkillRecord(Skill.ID, Skill, SecretStrSubstNo('Changed instructions'));

        // [THEN] The explicit version wins without losing the instruction history.
        Skill.Get(Skill.ID);
        Assert.AreEqual('custom-release', Skill.Version, 'An explicit manual version must not be discarded by automatic incrementing.');
        AssertContentEquals(SecretStrSubstNo('Changed instructions'), BusinessSkillImpl.GetContent(Skill), 'The instruction edit must also persist.');
        BusSkillContentVersion.SetRange("Skill ID", Skill.ID);
        Assert.AreEqual(2, BusSkillContentVersion.Count(), 'A real instruction change must append exactly one history row.');
        BusSkillContentVersion.FindFirst();
        Assert.AreEqual('v1.0', BusSkillContentVersion."Content Version", 'The original history entry must retain its original version.');
        BusSkillContentVersion.FindLast();
        Assert.AreEqual('custom-release', BusSkillContentVersion."Content Version", 'History must capture the explicit version saved with the instructions.');
    end;

    local procedure AssertManualSkillIdentifier(Skill: Record "Business Skill")
    begin
        Assert.IsTrue(Skill.Manual, 'The creation path must explicitly mark a manual skill.');
        Assert.AreEqual(Format(Skill.ID, 0, '<Integer,20><Filler Character,0>'), Skill."Skill ID", 'Manual identifiers must equal the numeric record ID padded to 20 digits.');
        Assert.IsTrue(IsNullGuid(Skill."Owning App ID"), 'Manual skills must have no owning app.');
        Assert.AreEqual('', Skill."Owning App Publisher", 'Manual skills must have no owning publisher.');
    end;

    local procedure CopyThenFail(SourceId: BigInteger)
    begin
        BusinessSkillImpl.CopySkill(SourceId);
        Error(CallerRollbackErr);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure CreateThenFail()
    var
        Builder: Codeunit "Business Skill Builder";
    begin
        Builder.Initialize('TEST', 'Title', SecretStrSubstNo('Instructions')).SetContentVersion('1').Create();
        Error(CallerRollbackErr);
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

    var
        Assert: Codeunit "Library Assert";
        LibraryBusinessSkill: Codeunit "Library - Business Skill";
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        CallerRollbackErr: Label 'Caller rollback', Locked = true;
}
