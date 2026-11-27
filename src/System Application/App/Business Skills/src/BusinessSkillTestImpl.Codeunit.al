// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Provides record-free skill fixtures with indirect table permissions for the test library.
/// </summary>
codeunit 4165 "Business Skill Test Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Business Skill" = rimd,
                  tabledata "Bus Skill Content Version" = rimd;

    /// <summary>
    /// Deletes all skill history and skills, regardless of status or owner. Use only in an isolated test environment.
    /// </summary>
    procedure DeleteAll()
    var
        BusSkillContentVersion: Record "Bus Skill Content Version";
        BusinessSkill: Record "Business Skill";
    begin
        BusSkillContentVersion.DeleteAll(false);
        BusinessSkill.DeleteAll(false);
    end;

    /// <summary>
    /// Creates an active manual skill with a description and initial content history.
    /// </summary>
    procedure CreateSkill(Name: Text[250]; Description: Text[2048]; SkillContent: SecretText): BigInteger
    var
        BusinessSkillBuilder: Codeunit "Business Skill Builder";
    begin
        exit(BusinessSkillBuilder.Initialize('', Name, SkillContent).SetManual(true).SetDescription(Description).SetActive(true).Create());
    end;

    /// <summary>
    /// Creates an inactive app-owned skill for the calling test library, with initial content history.
    /// </summary>
    procedure CreateAppOwnedSkill(SkillCode: Code[100]; Name: Text[250]; SkillContent: SecretText): BigInteger
    var
        BusinessSkillBuilderImpl: Codeunit "Business Skill Builder Impl.";
        CallerModule: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModule);
        BusinessSkillBuilderImpl.Initialize(CallerModule.Id, SkillCode, Name, SkillContent);
        exit(BusinessSkillBuilderImpl.Create());
    end;

    /// <summary>
    /// Updates manual fixture content through the revision-aware authoring method.
    /// </summary>
    procedure SetNewContentAndUpdateVersion(SkillId: BigInteger; Content: SecretText; ExpectedSystemId: Guid; ExpectedRevision: BigInteger)
    var
        BusinessSkill: Codeunit "Business Skill";
    begin
        BusinessSkill.SetNewContentAndUpdateVersion(SkillId, Content, ExpectedSystemId, ExpectedRevision);
    end;

    /// <summary>
    /// Activates a skill through the shared lifecycle validation.
    /// </summary>
    procedure ActivateSkill(SkillId: BigInteger)
    begin
        BusinessSkillImpl.ActivateSkill(SkillId);
    end;

    /// <summary>
    /// Inactivates a skill without changing its content.
    /// </summary>
    procedure InactivateSkill(SkillId: BigInteger)
    begin
        BusinessSkillImpl.DeactivateSkill(SkillId);
    end;

    /// <summary>
    /// Inactivates all active skills without deleting skills or history. Use only in an isolated test environment.
    /// </summary>
    procedure InactivateAll()
    var
        BusinessSkill: Record "Business Skill";
    begin
        BusinessSkill.SetRange(Status, BusinessSkill.Status::Active);
        if BusinessSkill.FindSet() then
            repeat
                InactivateSkill(BusinessSkill.ID);
            until BusinessSkill.Next() = 0;
    end;

    var
        BusinessSkillImpl: Codeunit "Business Skill Impl.";
}
