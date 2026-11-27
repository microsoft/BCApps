// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Provides business skill lifecycle operations, protected content reads, and revision-aware updates.
/// </summary>
codeunit 4160 "Business Skill"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Loads and returns the stored instructions of the skill.
    /// </summary>
    procedure GetContent(var BusinessSkill: Record "Business Skill"): SecretText
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        exit(BusinessSkillImpl.GetContent(BusinessSkill));
    end;

    /// <summary>
    /// Returns the content already loaded or assigned on the record buffer without reloading it.
    /// </summary>
    internal procedure GetContentFromBuffer(var BusinessSkill: Record "Business Skill"): SecretText
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        exit(BusinessSkillImpl.GetContentFromBuffer(BusinessSkill));
    end;

    /// <summary>
    /// Activates a skill after validating its name and content.
    /// </summary>
    procedure Activate(SkillId: BigInteger)
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        BusinessSkillImpl.ActivateSkill(SkillId);
    end;

    /// <summary>
    /// Deactivates a skill without changing its content.
    /// </summary>
    procedure Deactivate(SkillId: BigInteger)
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        BusinessSkillImpl.DeactivateSkill(SkillId);
    end;

    /// <summary>
    /// Deletes an inactive skill and its manual history subject to owning-app and management-permission checks.
    /// </summary>
    procedure Delete(SkillId: BigInteger)
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        BusinessSkillImpl.DeleteSkill(SkillId, CallerModule.Id);
    end;

    /// <summary>
    /// Returns whether the supplied skill is active and available to consumers.
    /// </summary>
    procedure IsAvailable(BusinessSkill: Record "Business Skill"): Boolean
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        exit(BusinessSkillImpl.IsSkillAvailable(BusinessSkill));
    end;

    /// <summary>
    /// Updates manual content only if the expected identity and revision still match, without committing.
    /// Changed content automatically advances the version and appends history. Identical content does not write.
    /// </summary>
    [CommitBehavior(CommitBehavior::Ignore)]
    internal procedure SetNewContentAndUpdateVersion(SkillId: BigInteger; Content: SecretText; ExpectedSystemId: Guid; ExpectedRevision: BigInteger)
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        BusinessSkillImpl.SetContent(SkillId, Content, ExpectedSystemId, ExpectedRevision);
    end;

    /// <summary>
    /// Updates the calling app's skill identified by its code, preserving its status and other metadata.
    /// Changed content requires a nonblank version different from the saved version. Version-only changes fail.
    /// Identical content and version do not write. App-owned content does not create history.
    /// </summary>
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure SetNewContentAndUpdateVersion(SkillCode: Code[100]; Content: SecretText; ContentVersion: Text[50])
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        BusinessSkillImpl.SetNewContentAndUpdateVersion(CallerModule.Id, SkillCode, Content, ContentVersion);
    end;

    /// <summary>
    /// Updates the calling app's skill name and description without changing its content, version, history, status or lock.
    /// Normal table and management permissions apply. Identical metadata does not write.
    /// </summary>
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure UpdateMetadata(SkillCode: Code[100]; Name: Text[250]; Description: Text[2048])
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        BusinessSkillImpl.UpdateMetadata(CallerModule.Id, SkillCode, Name, Description);
    end;
}
