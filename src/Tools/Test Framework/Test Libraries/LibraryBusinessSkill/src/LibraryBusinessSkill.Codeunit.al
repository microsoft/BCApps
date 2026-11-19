// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.AI.BusinessSkills;

using System.AI.BusinessSkills;

/// <summary>
/// Standalone test helper library for Business Skill test data creation and cleanup.
/// </summary>
codeunit 130055 "Library - Business Skill"
{
    Access = Public;
    Permissions = tabledata "Business Skill" = rimd,
                  tabledata "Bus Skill Content Version" = rimd;

    /// <summary>
    /// Deletes all skill history and skills. Use only in an isolated test environment.
    /// </summary>
    procedure DeleteAll()
    var
        BusSkillContentVersion: Record "Bus Skill Content Version";
        Skill: Record "Business Skill";
    begin
        BusSkillContentVersion.DeleteAll(false);
        Skill.DeleteAll(false);
    end;

    /// <summary>
    /// Creates an active manual skill with initial content history.
    /// </summary>
    procedure CreateSkill(Title: Text[250]; SkillContent: SecretText): BigInteger
    begin
        exit(CreateSkill(Title, '', SkillContent));
    end;

    /// <summary>
    /// Creates an active manual skill with a description and initial content history.
    /// </summary>
    procedure CreateSkill(Title: Text[250]; Description: Text[2048]; SkillContent: SecretText): BigInteger
    var
        Builder: Codeunit "Business Skill Builder";
    begin
        exit(Builder.Initialize('', Title, SkillContent).SetManual(true).SetDescription(Description).SetActive(true).Create());
    end;

    /// <summary>
    /// Creates an inactive skill owned by this test library rather than its caller.
    /// </summary>
    procedure CreateAppOwnedSkill(SkillCode: Code[100]; Title: Text[250]; SkillContent: SecretText): BigInteger
    var
        Builder: Codeunit "Business Skill Builder";
    begin
        exit(Builder.Initialize(SkillCode, Title, SkillContent).Create());
    end;

    /// <summary>
    /// Activates a skill through the public lifecycle API.
    /// </summary>
    procedure ActivateSkill(SkillId: BigInteger)
    var
        Management: Codeunit "Business Skill";
    begin
        Management.Activate(SkillId);
    end;

    /// <summary>
    /// Inactivates a skill through the public lifecycle API without changing its content.
    /// </summary>
    procedure InactivateSkill(SkillId: BigInteger)
    var
        BusinessSkill: Codeunit "Business Skill";
    begin
        BusinessSkill.Deactivate(SkillId);
    end;

    /// <summary>
    /// Inactivates all active skills without deleting skills or history. Use only in an isolated test environment.
    /// </summary>
    procedure InactivateAll()
    var
        Skill: Record "Business Skill";
    begin
        Skill.SetRange(Status, Skill.Status::Active);
        if Skill.FindSet() then
            repeat
                InactivateSkill(Skill.ID);
            until Skill.Next() = 0;
    end;
}
