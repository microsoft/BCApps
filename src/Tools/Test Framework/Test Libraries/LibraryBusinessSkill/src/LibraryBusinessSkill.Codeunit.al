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

    /// <summary>
    /// Deletes all skill history and skills. Use only in an isolated test environment.
    /// </summary>
    procedure DeleteAll()
    begin
        BusinessSkillTestImpl.DeleteAll();
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
    begin
        exit(BusinessSkillTestImpl.CreateSkill(Title, Description, SkillContent));
    end;

    /// <summary>
    /// Creates an inactive skill owned by this test library rather than its caller.
    /// </summary>
    procedure CreateAppOwnedSkill(SkillCode: Code[100]; Title: Text[250]; SkillContent: SecretText): BigInteger
    begin
        exit(BusinessSkillTestImpl.CreateAppOwnedSkill(SkillCode, Title, SkillContent));
    end;

    /// <summary>
    /// Activates a skill through the shared lifecycle validation.
    /// </summary>
    procedure ActivateSkill(SkillId: BigInteger)
    begin
        BusinessSkillTestImpl.ActivateSkill(SkillId);
    end;

    /// <summary>
    /// Inactivates a skill through the shared lifecycle implementation without changing its content.
    /// </summary>
    procedure InactivateSkill(SkillId: BigInteger)
    begin
        BusinessSkillTestImpl.InactivateSkill(SkillId);
    end;

    /// <summary>
    /// Inactivates all active skills without deleting skills or history. Use only in an isolated test environment.
    /// </summary>
    procedure InactivateAll()
    begin
        BusinessSkillTestImpl.InactivateAll();
    end;

    var
        BusinessSkillTestImpl: Codeunit "Business Skill Test Impl.";
}
