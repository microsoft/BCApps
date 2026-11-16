// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.AI.BusinessSkills;

using System.AI.BusinessSkills;

/// <summary>
/// Test helper library for Business Skill test data creation and cleanup.
/// </summary>
codeunit 130055 "Library - Business Skill"
{
    Access = Public;
    Permissions = tabledata "Business Skill" = rimd,
                  tabledata "Business Skill Text Version" = rimd;

    /// <summary>Deletes all skill history and skills. Use only in an isolated test environment.</summary>
    procedure CleanAll()
    var
        TextVersion: Record "Business Skill Text Version";
        Skill: Record "Business Skill";
    begin
        TextVersion.DeleteAll(false);
        Skill.DeleteAll(false);
    end;

    /// <summary>Creates an active manual skill with initial text history.</summary>
    procedure CreateSkill(Title: Text[250]; SkillText: Text): BigInteger
    var
        Management: Codeunit "Business Skill";
    begin
        exit(Management.CreateSkill(Title, SkillText));
    end;

    /// <summary>Creates an inactive skill owned by this test library rather than its caller.</summary>
    procedure CreateAppOwnedSkill(SkillCode: Code[100]; Title: Text[250]; SkillText: Text): BigInteger
    var
        Builder: Codeunit "Business Skill Builder";
    begin
        exit(Builder.Initialize(SkillCode, Title, SkillText).Create());
    end;

    /// <summary>Activates a skill through the public lifecycle API.</summary>
    procedure ActivateSkill(SkillId: BigInteger)
    var
        Management: Codeunit "Business Skill";
    begin
        Management.ActivateSkill(SkillId);
    end;
}
