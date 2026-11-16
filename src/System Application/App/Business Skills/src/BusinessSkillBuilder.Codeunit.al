// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Builds one skill owned by the calling app.
/// </summary>
/// <remarks>
/// The platform stamps the calling app as the owner of the skill. AL supplies the skill code.
/// </remarks>
codeunit 4161 "Business Skill Builder"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Initializes a new inactive skill with locked content owned by the calling app. An omitted content version defaults to v1.0 on creation.
    /// </summary>
    procedure Initialize(SkillCode: Code[100]; DisplayName: Text[250]; Content: Text): Codeunit "Business Skill Builder"
    var
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        BuilderImpl.Initialize(CallerModule.Id, SkillCode, DisplayName, Content);
        exit(this);
    end;

    /// <summary>
    /// Sets whether the created skill's content and content version are locked. The default is true.
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
    procedure SetContent(Content: Text): Codeunit "Business Skill Builder"
    begin
        BuilderImpl.SetContent(Content);
        exit(this);
    end;

    /// <summary>
    /// Selects whether the created skill is active. The default is inactive.
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
    /// Creates the skill, or updates the skill of the calling app that has the same skill code, without committing.
    /// Returns the numeric skill ID. Changed content needs a new content version; a content-locked skill cannot change its content or version.
    /// A builder instance can create or update only one skill.
    /// </summary>
    procedure CreateOrUpdate(): BigInteger
    begin
        exit(BuilderImpl.CreateOrUpdate());
    end;

    var
        BuilderImpl: Codeunit "Business Skill Builder Impl.";
}
