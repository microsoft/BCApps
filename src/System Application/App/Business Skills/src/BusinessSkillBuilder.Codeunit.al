// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Creates or updates one manual skill or a skill owned by the calling app.
/// </summary>
/// <remarks>
/// The platform assigns manual skill codes and stamps the calling app as the owner of app-owned skills.
/// </remarks>
codeunit 4161 "Business Skill Builder"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Supplies the skill code, display name and content. New app-owned skills default to inactive with locked content and version v1.0.
    /// Use SetManual(true) and an empty code to create a manual skill, or its saved code to update it.
    /// </summary>
    procedure Initialize(SkillCode: Code[100]; DisplayName: Text[250]; Content: SecretText): Codeunit "Business Skill Builder"
    var
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        BuilderImpl.Initialize(CallerModule.Id, SkillCode, DisplayName, Content);
        exit(this);
    end;

    /// <summary>
    /// Selects manual ownership. New manual skills default to unlocked content; this never converts a saved skill's identity.
    /// </summary>
    procedure SetManual(Manual: Boolean): Codeunit "Business Skill Builder"
    begin
        BuilderImpl.SetManual(Manual);
        exit(this);
    end;

    /// <summary>
    /// Sets whether content and its version are locked. Omitted on update, the saved value is preserved.
    /// </summary>
    procedure SetContentLocked(ContentLocked: Boolean): Codeunit "Business Skill Builder"
    begin
        BuilderImpl.SetContentLocked(ContentLocked);
        exit(this);
    end;

    /// <summary>
    /// Sets the content version of the skill. Supply a new version whenever existing content changes.
    /// </summary>
    procedure SetContentVersion(ContentVersion: Text[50]): Codeunit "Business Skill Builder"
    begin
        BuilderImpl.SetContentVersion(ContentVersion);
        exit(this);
    end;

    /// <summary>
    /// Sets the skill display name.
    /// </summary>
    procedure SetDisplayName(DisplayName: Text[250]): Codeunit "Business Skill Builder"
    begin
        BuilderImpl.SetDisplayName(DisplayName);
        exit(this);
    end;

    /// <summary>
    /// Sets the searchable description.
    /// </summary>
    procedure SetDescription(Description: Text[2048]): Codeunit "Business Skill Builder"
    begin
        BuilderImpl.SetDescription(Description);
        exit(this);
    end;

    /// <summary>
    /// Sets the skill content.
    /// </summary>
    procedure SetContent(Content: SecretText): Codeunit "Business Skill Builder"
    begin
        BuilderImpl.SetContent(Content);
        exit(this);
    end;

    /// <summary>
    /// Selects whether the skill is active. Creation defaults to inactive; omission on update preserves the saved status.
    /// </summary>
    procedure SetActive(Active: Boolean): Codeunit "Business Skill Builder"
    begin
        BuilderImpl.SetActive(Active);
        exit(this);
    end;

    /// <summary>
    /// Creates a new skill without committing. Returns the numeric skill ID.
    /// A builder instance can create only one skill.
    /// </summary>
    procedure Create(): BigInteger
    begin
        exit(BuilderImpl.Create());
    end;

    /// <summary>
    /// Creates an app-owned skill or updates its matching code, or creates/updates a manual skill selected by SetManual.
    /// A supplied manual code must already exist. Omitted optional setters preserve saved values.
    /// Changed app-owned content needs a new version; content-locked skills cannot change content or version.
    /// A builder instance can create or update only one skill.
    /// </summary>
    procedure CreateOrUpdate(): BigInteger
    begin
        exit(BuilderImpl.CreateOrUpdate());
    end;

    /// <summary>
    /// Updates an existing skill by numeric ID without committing. A supplied code and the selected ownership must match.
    /// Missing IDs are errors, never requests to allocate a new identity. Omitted optional setters preserve saved values.
    /// </summary>
    procedure CreateOrUpdate(SkillId: BigInteger): BigInteger
    begin
        exit(BuilderImpl.CreateOrUpdate(SkillId));
    end;

    var
        BuilderImpl: Codeunit "Business Skill Builder Impl.";
}
