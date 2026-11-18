// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Provides business skill lifecycle operations, revision-aware updates, and active-skill discovery.
/// Discovery uses literal title/description matching and retrieves canonical skill details, including instruction text.
/// </summary>
codeunit 4160 "Business Skill" implements IBusinessSkillDiscovery
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Returns a serialized JSON array containing active skills matching the query.
    /// </summary>
    /// <param name="Query">Literal, case-insensitive text matched against active skill titles and descriptions only.</param>
    /// <returns>A serialized JSON array of matching skills.</returns>
    procedure GetRelevantSkills(Query: Text): SecretText
    var
        Management: Codeunit "Business Skill Management";
    begin
        exit(Management.SearchSkills(Query));
    end;

    /// <summary>
    /// Returns an active skill by its internal numeric identifier.
    /// </summary>
    /// <param name="SkillId">Internal numeric identifier of the skill.</param>
    /// <returns>A protected serialized JSON object containing the skill.</returns>
    /// <remarks>An error is raised when the skill does not exist or is inactive.</remarks>
    procedure GetSkill(SkillId: BigInteger): SecretText
    var
        Management: Codeunit "Business Skill Management";
    begin
        exit(Management.GetSkillById(SkillId));
    end;

    /// <summary>Updates manual skill metadata and text using the supplied record's identity and revision.</summary>
    procedure UpdateSkillRecord(SkillId: BigInteger; var SourceSkill: Record "Business Skill"; SkillText: SecretText): Boolean
    var
        Management: Codeunit "Business Skill Management";
    begin
        exit(Management.UpdateSkillRecord(SkillId, SourceSkill, SkillText));
    end;

    /// <summary>Activates a skill after validating its title and text.</summary>
    procedure ActivateSkill(SkillId: BigInteger): Boolean
    var
        Management: Codeunit "Business Skill Management";
    begin
        exit(Management.ActivateSkill(SkillId));
    end;

    /// <summary>Deactivates a skill without changing its content.</summary>
    procedure DeactivateSkill(SkillId: BigInteger): Boolean
    var
        Management: Codeunit "Business Skill Management";
    begin
        exit(Management.DeactivateSkill(SkillId));
    end;

    /// <summary>Deletes an inactive skill subject to owning-app and management-permission checks.</summary>
    procedure DeleteSkill(SkillId: BigInteger)
    var
        Management: Codeunit "Business Skill Management";
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        Management.DeleteSkill(SkillId, CallerModule.Id);
    end;

    /// <summary>Returns whether the supplied skill is active and available to consumers.</summary>
    procedure IsSkillAvailable(Skill: Record "Business Skill"): Boolean
    var
        Management: Codeunit "Business Skill Management";
    begin
        exit(Management.IsSkillAvailable(Skill));
    end;

    /// <summary>Filters the record to active skills, preserving its other filters.</summary>
    procedure SetAvailableSkillsFilter(var Skill: Record "Business Skill")
    var
        Management: Codeunit "Business Skill Management";
    begin
        Management.SetAvailableSkillsFilter(Skill);
    end;

    /// <summary>
    /// Updates manual content and its version/history only if the expected identity and revision still match, without committing.
    /// </summary>
    [CommitBehavior(CommitBehavior::Error)]
    procedure SetNewContentAndUpdateVersion(SkillId: BigInteger; Content: SecretText; ExpectedSystemId: Guid; ExpectedRevision: BigInteger)
    var
        Management: Codeunit "Business Skill Management";
    begin
        Management.SetSkillText(SkillId, Content, ExpectedSystemId, ExpectedRevision);
    end;

    /// <summary>
    /// Updates the calling app's skill identified by its code, preserving its status and other metadata.
    /// Changed content requires a nonblank version different from the saved version. Version-only changes fail.
    /// </summary>
    [CommitBehavior(CommitBehavior::Error)]
    procedure SetNewContentAndUpdateVersion(SkillCode: Code[100]; Content: SecretText; ContentVersion: Text[50])
    var
        Management: Codeunit "Business Skill Management";
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        Management.SetNewContentAndUpdateVersion(CallerModule.Id, SkillCode, Content, ContentVersion);
    end;
}
