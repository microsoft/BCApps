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
    procedure GetSkillText(var Skill: Record "Business Skill"): SecretText
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        exit(BusinessSkillImpl.GetSkillText(Skill));
    end;

    /// <summary>
    /// Returns the instructions of the skill, optionally loading them from the database first.
    /// </summary>
    procedure GetSkillText(var Skill: Record "Business Skill"; LoadFromDatabase: Boolean): SecretText
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        exit(BusinessSkillImpl.GetSkillText(Skill, LoadFromDatabase));
    end;

    /// <summary>
    /// Activates a skill after validating its title and text.
    /// </summary>
    procedure ActivateSkill(SkillId: BigInteger): Boolean
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        exit(BusinessSkillImpl.ActivateSkill(SkillId));
    end;

    /// <summary>
    /// Deactivates a skill without changing its content.
    /// </summary>
    procedure DeactivateSkill(SkillId: BigInteger): Boolean
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        exit(BusinessSkillImpl.DeactivateSkill(SkillId));
    end;

    /// <summary>
    /// Deletes an inactive skill subject to owning-app and management-permission checks.
    /// </summary>
    procedure DeleteSkill(SkillId: BigInteger)
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
    procedure IsSkillAvailable(Skill: Record "Business Skill"): Boolean
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        exit(BusinessSkillImpl.IsSkillAvailable(Skill));
    end;

    /// <summary>
    /// Updates manual content and its version/history only if the expected identity and revision still match, without committing.
    /// </summary>
    [CommitBehavior(CommitBehavior::Error)]
    procedure SetNewContentAndUpdateVersion(SkillId: BigInteger; Content: SecretText; ExpectedSystemId: Guid; ExpectedRevision: BigInteger)
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
    begin
        BusinessSkillImpl.SetSkillText(SkillId, Content, ExpectedSystemId, ExpectedRevision);
    end;

    /// <summary>
    /// Updates the calling app's skill identified by its code, preserving its status and other metadata.
    /// Changed content requires a nonblank version different from the saved version. Version-only changes fail.
    /// </summary>
    [CommitBehavior(CommitBehavior::Error)]
    procedure SetNewContentAndUpdateVersion(SkillCode: Code[100]; Content: SecretText; ContentVersion: Text[50])
    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        BusinessSkillImpl.SetNewContentAndUpdateVersion(CallerModule.Id, SkillCode, Content, ContentVersion);
    end;
}
