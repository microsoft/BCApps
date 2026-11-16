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
    procedure GetRelevantSkills(Query: Text): Text
    var
        Management: Codeunit "Business Skill Management";
        Skills: JsonArray;
        Result: Text;
    begin
        Skills := Management.SearchSkills(Query);
        Skills.WriteTo(Result);
        exit(Result);
    end;

    /// <summary>
    /// Returns an active skill by its internal numeric identifier.
    /// </summary>
    /// <param name="SkillId">Internal numeric identifier of the skill.</param>
    /// <returns>A JSON object containing the skill.</returns>
    /// <remarks>An error is raised when the skill does not exist or is inactive.</remarks>
    procedure GetSkill(SkillId: BigInteger): JsonObject
    var
        Management: Codeunit "Business Skill Management";
    begin
        exit(Management.GetSkillById(SkillId));
    end;

    /// <summary>Creates an active manual skill and its initial text history without committing.</summary>
    procedure CreateSkill(Title: Text[250]; SkillText: Text): BigInteger
    var
        Management: Codeunit "Business Skill Management";
    begin
        exit(Management.CreateSkill(Title, SkillText));
    end;

    /// <summary>Creates an active manual skill with a description and initial text history without committing.</summary>
    procedure CreateSkill(Title: Text[250]; Description: Text[2048]; SkillText: Text): BigInteger
    var
        Management: Codeunit "Business Skill Management";
    begin
        exit(Management.CreateSkill(Title, Description, SkillText));
    end;

    /// <summary>Updates manual skill metadata and text using the supplied record's identity and revision.</summary>
    procedure UpdateSkillRecord(SkillId: BigInteger; var SourceSkill: Record "Business Skill"; SkillText: Text): Boolean
    var
        Management: Codeunit "Business Skill Management";
    begin
        exit(Management.UpdateSkillRecord(SkillId, SourceSkill, SkillText));
    end;

    /// <summary>Creates an active manual skill from the supplied metadata and text without committing.</summary>
    procedure CreateSkillRecord(var SourceSkill: Record "Business Skill"; SkillText: Text): BigInteger
    var
        Management: Codeunit "Business Skill Management";
    begin
        exit(Management.CreateSkillRecord(SourceSkill, SkillText));
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

    /// <summary>Updates manual skill text and its history only if the expected identity and revision still match.</summary>
    procedure SetSkillText(SkillId: BigInteger; SkillText: Text; ExpectedSystemId: Guid; ExpectedRevision: BigInteger)
    var
        Management: Codeunit "Business Skill Management";
    begin
        Management.SetSkillText(SkillId, SkillText, ExpectedSystemId, ExpectedRevision);
    end;
}
