// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Creates one skill owned by the calling app.
/// </summary>
/// <remarks>
/// The platform stamps the calling app as the owner. Clear the builder before creating another skill.
/// </remarks>
codeunit 4161 "Business Skill Builder"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Supplies the skill code, display name and content. New app-owned skills default to inactive with locked content and version v1.0.
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
    /// Selects manual ownership for internal authoring. Use an empty code for new manual skills, which default to unlocked content.
    /// This never converts a saved skill's identity.
    /// </summary>
    internal procedure SetManual(Manual: Boolean): Codeunit "Business Skill Builder"
    begin
        BuilderImpl.SetManual(Manual);
        exit(this);
    end;

    /// <summary>
    /// Sets whether content and its version are locked.
    /// </summary>
    procedure SetContentLocked(ContentLocked: Boolean): Codeunit "Business Skill Builder"
    begin
        BuilderImpl.SetContentLocked(ContentLocked);
        exit(this);
    end;

    /// <summary>
    /// Sets the initial content version of the skill, up to 50 characters.
    /// </summary>
    procedure SetContentVersion(ContentVersion: Text): Codeunit "Business Skill Builder"
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
    /// Selects whether the skill is active. Creation defaults to inactive.
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

    var
        BuilderImpl: Codeunit "Business Skill Builder Impl.";
}
